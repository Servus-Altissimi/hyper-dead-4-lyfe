import hashlib
import struct

from .. import config
from ..util import game_file, strip_kv_comments, workdir, write
from . import dmx

SYSTEM = b"DmeParticleSystemDefinition"
CHILD = b"DmeParticleChild"

FIRE_TINTS = {
    b"env_fire_small": [(176, 28, 30, 255), (140, 18, 24, 255)],
    b"env_fire_small_b": [(170, 26, 28, 255), (132, 16, 22, 255)],
    b"env_fire_random_puff": [(150, 20, 24, 255)],
    b"env_fire_small_glow": [(120, 14, 16, 255), (96, 10, 12, 255)],
    b"env_embers_small": [(150, 12, 12, 255), (205, 36, 22, 255)],
    b"env_fire_small_smoke": [(44, 12, 12, 255), (30, 8, 9, 255)],
}
FIRE_FADE = {b"env_fire_small_smoke": (8, 6, 6, 50)}

EYES = {
    b"hd4l_eyes_red": ((230, 40, 26), (255, 52, 19), 512.0, 0.6, 200, 1.0),
    b"hd4l_eyes_rage": ((255, 36, 20), (255, 60, 24), 1024.0, 1.2, 255, 1.6),
    b"hd4l_eyes_white": ((255, 250, 240), (255, 240, 220), 1024.0, 1.0, 255, 2.4),
    b"hd4l_eyes_hyper": ((255, 255, 250), (255, 230, 190), 1024.0, 1.5, 255, 3.2),
    b"hd4l_eyes_tank": ((255, 30, 16), (255, 70, 30), 2048.0, 1.8, 255, 5.0),
}
EYE_LOCK = b"Movement Lock to Control Point"

GORE_RED = (1.0, 0.1, 0.08)

TRACER_SPEED = 4000.0
TRACER_SPEEDS = [1000, 1500, 2000, 3000, 4000, 6000, 8000, 12000]
TRACER_MOVE = b"move particles between 2 control points"

MANIFEST_ADD = ("hd4l_fx", "hd4l_eyes", "hd4l_gore", "hd4l_projectiles")


def guid(*key):
    return hashlib.md5(b"/".join(k if isinstance(k, bytes) else str(k).encode() for k in key)).digest()


def attr(el, name):
    for a in el["attrs"]:
        if a[0] == name:
            return a
    return None


def refs(el, skip=()):
    for name, t, v in el["attrs"]:
        if name in skip:
            continue
        if t == 1 and isinstance(v, int) and v >= 0:
            yield v
        elif t == 15:
            yield from (x for x in v if isinstance(x, int) and x >= 0)


def walk(els, start, skip=()):
    order = []
    stack = [start]
    while stack:
        i = stack.pop()
        if i in order:
            continue
        order.append(i)
        stack.extend(reversed(list(refs(els[i], skip))))
    return order


def function_name(el):
    a = attr(el, b"functionName")
    return a[2] if a else None


def is_ref(t, v):
    return (t == 1 and isinstance(v, int) and v >= 0) or t == 15


def owners(els, systems_, groups):
    owner = {}
    for i in systems_:
        for group in groups:
            a = attr(els[i], group)
            for x in (a[2] if a else []):
                owner[x] = i
    return owner


def clone_name(els, el, rename):
    if el["type"] == SYSTEM:
        return rename[el["name"]]
    if el["type"] == CHILD:
        return rename[els[attr(el, b"child")[2]]["name"]]
    return el["name"]


def relink(t, v, index):
    if t == 1 and isinstance(v, int) and v >= 0:
        return index[v]
    if t == 15:
        return [index[x] if isinstance(x, int) and x >= 0 else x for x in v]
    return v


def systems(els):
    return {e["name"]: i for i, e in enumerate(els) if e["type"] == SYSTEM}


def root(name, children):
    return {"type": b"DmeElement", "name": b"untitled", "guid": guid(name, b"root"),
            "attrs": [[b"particleSystemDefinitions", 15, children]]}


def save(path, header, elements, indexed):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(dmx.write(header, elements, indexed))
    _, back, _, _ = dmx.load(path)
    names = ", ".join(e["name"].decode() for e in back if e["type"] == SYSTEM)
    print(f"{path.name}: {len(back)} elements, {names}")


def fire(src, out):
    top = b"hd4l_charger_fire"
    header, els, indexed, _ = dmx.load(src)
    order = walk(els, systems(els)[b"env_fire_small_smoke"])
    index = {old: n + 1 for n, old in enumerate(order)}
    rename = {els[i]["name"]: top if els[i]["name"] == b"env_fire_small_smoke" else top + b"_" + els[i]["name"].replace(b"env_", b"")
              for i in order if els[i]["type"] == SYSTEM}
    owner = owners(els, [i for i in order if els[i]["type"] == SYSTEM], (b"initializers", b"operators"))
    clones = []
    for i in order:
        e = els[i]
        fn = function_name(e)
        system = els[owner[i]]["name"] if i in owner else None
        c = {"type": e["type"], "name": clone_name(els, e, rename), "guid": guid(top, i), "attrs": []}
        for n, t, v in e["attrs"]:
            v = relink(t, v, index)
            if t == 8 and fn == b"Color Random" and system in FIRE_TINTS:
                tints = FIRE_TINTS[system]
                v = bytes(tints[0] if n == b"color1" or len(tints) == 1 else tints[1])
            elif t == 8 and fn == b"Color Fade" and system in FIRE_FADE:
                v = bytes(FIRE_FADE[system])
            c["attrs"].append([n, t, v])
        clones.append(c)
    top_level = [n + 1 for n, c in enumerate(clones) if c["type"] == SYSTEM]
    save(out, header, [root(top, top_level)] + clones, indexed)


def eyes(src, out):
    elements = [root(b"hd4l_eyes", [])]
    header = indexed = None
    for top, (main_tint, child_tint, rate, life, alpha, size) in EYES.items():
        header, els, indexed, _ = dmx.load(src)
        defs = systems(els)
        main, child = defs[b"witch_eye_glow"], defs[b"witch_eye_glow_b"]
        ops = attr(els[main], b"operators")
        ops[2] = [x for x in ops[2] if attr(els[x], b"functionName")[2] != EYE_LOCK]
        order = walk(els, main)
        base = len(elements)
        index = {old: base + n for n, old in enumerate(order)}
        owner = owners(els, (main, child), (b"initializers", b"operators", b"renderers", b"emitters"))
        rename = {b"witch_eye_glow": top, b"witch_eye_glow_b": top + b"_glow"}
        for i in order:
            e = els[i]
            name = rename.get(e["name"], e["name"])
            if e["type"] == CHILD:
                name = rename[els[attr(e, b"child")[2]]["name"]]
            fn = function_name(e)
            is_main = owner.get(i) == main
            tint = main_tint if is_main else child_tint
            c = {"type": e["type"], "name": name, "guid": guid(top, i), "attrs": []}
            for n, t, v in e["attrs"]:
                if is_ref(t, v):
                    v = relink(t, v, index)
                elif fn == b"Color Random" and n in (b"color1", b"color2"):
                    v = bytes(tint) + b"\xff"
                elif is_main and fn == b"emit_continuously" and n == b"emission_rate":
                    v = struct.pack("<f", rate)
                elif is_main and fn == b"Lifetime Random" and n in (b"lifetime_min", b"lifetime_max"):
                    v = struct.pack("<f", life)
                elif is_main and fn == b"Alpha Random" and n in (b"alpha_min", b"alpha_max"):
                    v = struct.pack("<i", alpha)
                elif fn == b"Radius Random" and n in (b"radius_min", b"radius_max"):
                    v = struct.pack("<f", struct.unpack("<f", v)[0] * size)
                elif i == main and n == b"max_particles":
                    v = struct.pack("<i", int(rate * life) + 64)
                elif i == main and n == b"maximum draw distance":
                    v = struct.pack("<f", 3000.0)
                c["attrs"].append([n, t, v])
            elements.append(c)
        elements[0]["attrs"][0][2] += [index[main], index[child]]
    save(out, header, elements, indexed)


def gore(src, out):
    top, new = b"boomer_explode", b"hd4l_red_mist"
    header, els, indexed, _ = dmx.load(src)
    order = walk(els, systems(els)[top])
    index = {old: n + 1 for n, old in enumerate(order)}
    rename = {}
    for i in order:
        name = els[i]["name"]
        if els[i]["type"] == SYSTEM:
            rename[name] = new if name == top else new + b"_" + name.replace(b"boomer_explode_", b"").replace(b"boomer_", b"")

    def red(v):
        lum = max(v[0], v[1], v[2])
        return bytes([min(255, int(lum * GORE_RED[0])), int(lum * GORE_RED[1]), int(lum * GORE_RED[2]), v[3]])

    clones = []
    for i in order:
        e = els[i]
        c = {"type": e["type"], "name": clone_name(els, e, rename), "guid": guid(new, i), "attrs": []}
        for n, t, v in e["attrs"]:
            if is_ref(t, v):
                v = relink(t, v, index)
            elif t == 8 and isinstance(v, (bytes, bytearray)) and len(v) == 4:
                v = red(v)
            c["attrs"].append([n, t, v])
        clones.append(c)
    top_level = [n + 1 for n, c in enumerate(clones) if c["type"] == SYSTEM]
    save(out, header, [root(new, top_level)] + clones, indexed)


def tracers(src, out):
    assert int(TRACER_SPEED) in TRACER_SPEEDS
    elements = [root(b"hd4l_projectile_tracer", [])]
    header = indexed = None
    for speed in TRACER_SPEEDS:
        name = b"hd4l_projectile_tracer_%d" % speed
        header, els, indexed, _ = dmx.load(src)
        start = systems(els)[b"weapon_tracers"]
        order = walk(els, start, skip=(b"children",))
        base = len(elements)
        index = {old: base + k for k, old in enumerate(order)}
        for i in order:
            e = els[i]
            fn = function_name(e)
            c = {"type": e["type"], "name": name if i == start else e["name"], "guid": guid(name, i), "attrs": []}
            for n, t, v in e["attrs"]:
                if i == start and n == b"children":
                    v = []
                elif is_ref(t, v):
                    v = relink(t, v, index)
                elif fn == TRACER_MOVE and n in (b"minimum speed", b"maximum speed"):
                    v = struct.pack("<f", float(speed))
                c["attrs"].append([n, t, v])
            elements.append(c)
        elements[0]["attrs"][0][2].append(index[start])
    save(out, header, elements, indexed)


def manifest(src, out):
    text = strip_kv_comments(src.read_text(errors="replace").replace("\r", ""))
    cut = text.rindex("}")
    add = "".join(f'\t"file"\t\t"!particles/{n}.pcf"\n' for n in MANIFEST_ADD)
    write(out, text[:cut] + add + text[cut:])
    print(f"{out.name}: stock plus {', '.join(MANIFEST_ADD)}")


def build(out=config.ROOT):
    parts = out / "parts"
    with workdir() as tmp:
        fire(game_file("particles/fire_01.pcf", tmp), parts / "infected-moves/addon/particles/hd4l_fx.pcf")
        eyes(game_file("particles/witch_fx.pcf", tmp), parts / "core/addon/particles/hd4l_eyes.pcf")
        gore(game_file("particles/boomer_fx.pcf", tmp), parts / "core/addon/particles/hd4l_gore.pcf")
        tracers(game_file("particles/weapon_fx.pcf", tmp), parts / "projectiles/addon/particles/hd4l_projectiles.pcf")
        manifest(game_file("particles/particles_manifest.txt", tmp), parts / "core/addon/particles/particles_manifest.txt")
