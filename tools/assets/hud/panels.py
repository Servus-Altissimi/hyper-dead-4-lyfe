from PIL import Image, ImageDraw, ImageFont

from ... import config
from ...util import vtf, write
from ..palette import AMBER, ASH, BLOOD, BONE, SHADE, drawcolor
from ..svg import render
from . import chan
from . import draw as M
from .textures import REACTIVE, reactive_consts

HUD = config.part("hyper-feedback")
ART = HUD / "art" / "icons"
ICON = 128
FONT = str(HUD / "addon" / "resource" / "Poppins-700.ttf")

UX, UY = 853.333 / 1024.0, 480.0 / 512.0
RAIL = 64
IMGKV = dict(visible=1, enabled=1, scaleImage=1, autoResize=0, pinCorner=0, drawcolor="255 255 255 255")

T_ME, T_MATES = 14, (15, 16, 0)
ME_HP = 50
MATE_HP = 25
SURVIVORS = ["gambler", "producer", "coach", "mechanic", "namvet", "teenangst", "biker", "manager"]
SURVIVOR_NAMES = ["Nick", "Rochelle", "Coach", "Ellis", "Bill", "Zoey", "Francis", "Louis"]
SPECIALS = ["hunter", "smoker", "boomer", "spitter", "jockey", "charger", "tank"]
INCAP = {"$color": "[1.0 0.22 0.16]"}
HOLD = {"hit": 0.10, "hit_head": 0.16, "kill": 0.22, "headshot": 0.30, "parry": 0.45}
DIGIT_W, DIGIT_H = 18, 30
CH_H = 34
CH_W = 20
ST_X, ST_Y, ST_ROW, ST_ICON = 14, 14, 30, 24
ST_W, ST_H, ST_NX = 14, 24, 46
TINTED = ["icon_" + n for n in (
    "pumpshotgun", "shotgun_chrome", "autoshotgun", "shotgun_spas", "smg", "smg_silenced", "smg_mp5", "rifle", "rifle_ak47",
    "rifle_desert", "rifle_sg552", "rifle_m60", "hunting_rifle", "sniper_military", "sniper_awp", "sniper_scout",
    "grenade_launcher", "pistol", "pistol_magnum", "chainsaw", "baseball_bat", "cricket_bat", "crowbar", "electric_guitar",
    "fireaxe", "frying_pan", "golfclub", "katana", "knife", "machete", "pitchfork", "shovel", "tonfa", "molotov",
    "pipebomb", "vomitjar", "first_aid_kit", "defibrillator", "upgradepack_incendiary", "upgradepack_explosive",
    "painpills", "adrenaline")] + ["progressbar_fill"]


def layout(fields):
    out = {}
    div = 1
    for name, radix in fields:
        out[name] = (div, radix)
        div *= radix
    assert div < 900000, div
    return out


TAG1 = layout([("mark", 6), ("mseq", 5), ("arc", 9), ("aseq", 5), ("stam", 12), ("dot", 2)])
TAG2 = layout([("tank", 21), ("struggle", 10), ("spike", 5), ("cue", 6), ("cseq", 5), ("hook", 2)])
FEED = layout([("k1", 18), ("v1", 18), ("h1", 2), ("k2", 18), ("v2", 18), ("h2", 2)])
DIGITS = layout([("d1", 11), ("d2", 11), ("d3", 11), ("d4", 11), ("tone", 2)])
TAG6 = layout([("c1", 11), ("c2", 11), ("live", 2)])
TAG11 = layout([("m1", 11), ("m2", 11), ("s1", 7), ("s2", 11), ("shown", 2)])
TAG12 = layout([("k1", 11), ("k2", 11), ("k3", 11), ("k4", 11), ("k5", 11)])
TAG13 = layout([("c1", 11), ("c2", 11), ("c3", 11)])
TAG17 = layout([("p1", 11), ("p2", 11), ("p3", 11), ("p4", 11), ("shown", 2)])
TAG18 = layout([("c1", 21), ("c2", 21), ("c3", 21), ("c4", 21), ("shown", 2)])
TAG19 = layout([("w1", 11), ("w2", 11), ("t1", 11), ("t2", 11), ("t3", 11), ("state", 3)])
TAG_ME = layout([("who", 9), ("hp", ME_HP + 1), ("total", ME_HP + 1), ("tone", 3), ("crouch", 2), ("on", 2)])
TAG_MATE = layout([("who", 9), ("hp", MATE_HP + 1), ("total", MATE_HP + 1), ("tone", 3), ("alive", 2), ("incap", 2),
                   ("nade", 2), ("kit", 2), ("pills", 2)])

SHARED = '''"UnlitGeneric"
{
	"$basetexture" ""
	"$additive" "1"
	"$ignorez" "1"
	"$nocull" "1"
	"$nomip" "1"
	"$nolod" "1"
	"$vertexcolor" "1"
	"$vertexalpha" "1"

	"$my_tag" "1"
	"$my_div" "1"
	"$my_radix" "6"
	"$my_value" "1"
	"$my_seqdiv" "1"
	"$my_seqradix" "1"
	"$my_duration" "1000000"

	"$zero" "0"
	"$one" "1"
	"$guard" "50000"
	"$million" "1000000"
	"$v" "0" "$t" "0" "$tag" "0" "$tagbase" "0" "$payload" "0" "$hit" "0"
	"$q" "0" "$q2" "0" "$fnew" "0" "$field" "0"
	"$s" "0" "$s2" "0" "$snew" "0" "$seq" "0" "$lastseq" "0" "$chg" "0"
	"$time" "0" "$start" "0" "$age" "0" "$fresh" "1" "$d" "0" "$show" "0"

	"Proxies"
	{
		"ConVar" { "convar" "name2" "resultVar" "$v" }
		"Multiply" { "srcVar1" "$v" "srcVar2" "$one" "resultVar" "$v" }
		"Add" { "srcVar1" "$v" "srcVar2" "$guard" "resultVar" "$t" }
		"Divide" { "srcVar1" "$t" "srcVar2" "$million" "resultVar" "$t" }
		"Int" { "srcVar1" "$t" "resultVar" "$tag" }
		"Multiply" { "srcVar1" "$tag" "srcVar2" "$million" "resultVar" "$tagbase" }
		"Subtract" { "srcVar1" "$v" "srcVar2" "$tagbase" "resultVar" "$payload" }
		"Subtract" { "srcVar1" "$tag" "srcVar2" "$my_tag" "resultVar" "$hit" }
		"Abs" { "srcVar1" "$hit" "resultVar" "$hit" }
		"Divide" { "srcVar1" "$payload" "srcVar2" "$my_div" "resultVar" "$q" }
		"Int" { "srcVar1" "$q" "resultVar" "$q" }
		"Divide" { "srcVar1" "$q" "srcVar2" "$my_radix" "resultVar" "$q2" }
		"Int" { "srcVar1" "$q2" "resultVar" "$q2" }
		"Multiply" { "srcVar1" "$q2" "srcVar2" "$my_radix" "resultVar" "$q2" }
		"Subtract" { "srcVar1" "$q" "srcVar2" "$q2" "resultVar" "$fnew" }
		"LessOrEqual" { "srcVar1" "$hit" "srcVar2" "$zero" "resultVar" "$field" "LessEqualVar" "$fnew" "greaterVar" "$field" }
		"Divide" { "srcVar1" "$payload" "srcVar2" "$my_seqdiv" "resultVar" "$s" }
		"Int" { "srcVar1" "$s" "resultVar" "$s" }
		"Divide" { "srcVar1" "$s" "srcVar2" "$my_seqradix" "resultVar" "$s2" }
		"Int" { "srcVar1" "$s2" "resultVar" "$s2" }
		"Multiply" { "srcVar1" "$s2" "srcVar2" "$my_seqradix" "resultVar" "$s2" }
		"Subtract" { "srcVar1" "$s" "srcVar2" "$s2" "resultVar" "$snew" }
		"LessOrEqual" { "srcVar1" "$hit" "srcVar2" "$zero" "resultVar" "$seq" "LessEqualVar" "$snew" "greaterVar" "$seq" }
		"CurrentTime" { "resultVar" "$time" }
		"Subtract" { "srcVar1" "$seq" "srcVar2" "$lastseq" "resultVar" "$chg" }
		"Abs" { "srcVar1" "$chg" "resultVar" "$chg" }
		"LessOrEqual" { "srcVar1" "$chg" "srcVar2" "$zero" "resultVar" "$start" "LessEqualVar" "$start" "greaterVar" "$time" }
		"Equals" { "srcVar1" "$seq" "resultVar" "$lastseq" }
		"Subtract" { "srcVar1" "$time" "srcVar2" "$start" "resultVar" "$age" }
		"LessOrEqual" { "srcVar1" "$age" "srcVar2" "$my_duration" "resultVar" "$fresh" "LessEqualVar" "$one" "greaterVar" "$zero" }
		"Subtract" { "srcVar1" "$field" "srcVar2" "$my_value" "resultVar" "$d" }
		"Abs" { "srcVar1" "$d" "resultVar" "$d" }
		"LessOrEqual" { "srcVar1" "$d" "srcVar2" "$zero" "resultVar" "$show" "LessEqualVar" "$one" "greaterVar" "$zero" }
		"Multiply" { "srcVar1" "$show" "srcVar2" "$fresh" "resultVar" "$alpha" }
	}
}
'''
POP_VARS = ('\t"$my_pop" "0.15" "$my_popamt" "0.25"\n'
            '\t"$pt" "0" "$tc" "1" "$k" "0" "$sc" "1" "$sv" "[1 1]" "$half" "[0.5 0.5 0]"\n')
POP_CHAIN = ('\t\t"Divide" { "srcVar1" "$age" "srcVar2" "$my_pop" "resultVar" "$pt" }\n'
             '\t\t"LessOrEqual" { "srcVar1" "$pt" "srcVar2" "$one" "resultVar" "$tc" "LessEqualVar" "$pt" "greaterVar" "$one" }\n'
             '\t\t"Subtract" { "srcVar1" "$one" "srcVar2" "$tc" "resultVar" "$k" }\n'
             '\t\t"Multiply" { "srcVar1" "$k" "srcVar2" "$my_popamt" "resultVar" "$k" }\n'
             '\t\t"Subtract" { "srcVar1" "$one" "srcVar2" "$k" "resultVar" "$sc" }\n'
             '\t\t"Equals" { "srcVar1" "$sc" "resultVar" "$sv[0]" }\n'
             '\t\t"Equals" { "srcVar1" "$sc" "resultVar" "$sv[1]" }\n'
             '\t\t"TextureTransform" { "scaleVar" "$sv" "centerVar" "$half" "resultVar" "$basetexturetransform" }\n'
             '\t\t"Multiply" { "srcVar1" "$show" "srcVar2" "$tc" "resultVar" "$show" }\n')
FINAL = '\t\t"Multiply" { "srcVar1" "$show" "srcVar2" "$fresh" "resultVar" "$alpha" }\n'
LIVE_VARS = f'\t"$lastv" "0" "$armed" "0" "$dv" "0" "$vgo" "0" "$vstart" "-1000" "$vage" "0" "$live" "0" "$my_live" "{chan.LIVE}"\n'
LIVE_CHAIN = ('\t\t"Subtract" { "srcVar1" "$v" "srcVar2" "$lastv" "resultVar" "$dv" }\n'
              '\t\t"Abs" { "srcVar1" "$dv" "resultVar" "$dv" }\n'
              '\t\t"Multiply" { "srcVar1" "$dv" "srcVar2" "$armed" "resultVar" "$vgo" }\n'
              '\t\t"LessOrEqual" { "srcVar1" "$vgo" "srcVar2" "$zero" "resultVar" "$vstart" "LessEqualVar" "$vstart" "greaterVar" "$time" }\n'
              '\t\t"Equals" { "srcVar1" "$v" "resultVar" "$lastv" }\n'
              '\t\t"Equals" { "srcVar1" "$one" "resultVar" "$armed" }\n'
              '\t\t"Subtract" { "srcVar1" "$time" "srcVar2" "$vstart" "resultVar" "$vage" }\n'
              '\t\t"LessOrEqual" { "srcVar1" "$vage" "srcVar2" "$my_live" "resultVar" "$live" "LessEqualVar" "$one" "greaterVar" "$zero" }\n')
LIVE_MUL = '\t\t"Multiply" { "srcVar1" "$alpha" "srcVar2" "$live" "resultVar" "$alpha" }\n'
EQ = ('\t\t"Subtract" { "srcVar1" "$field" "srcVar2" "$my_value" "resultVar" "$d" }\n'
      '\t\t"Abs" { "srcVar1" "$d" "resultVar" "$d" }\n'
      '\t\t"LessOrEqual" { "srcVar1" "$d" "srcVar2" "$zero" "resultVar" "$show" "LessEqualVar" "$one" "greaterVar" "$zero" }')
ANY = '\t\t"LessOrEqual" { "srcVar1" "$field" "srcVar2" "$zero" "resultVar" "$show" "LessEqualVar" "$zero" "greaterVar" "$one" }'
TONE_VARS = '\t"$my_tonediv" "1" "$my_toneradix" "2" "$my_tone" "0"\n\t"$tq" "0" "$tq2" "0" "$tnew" "0" "$tone" "0" "$td" "0" "$tshow" "0"\n'
TONE_CHAIN = ('\t\t"Divide" { "srcVar1" "$payload" "srcVar2" "$my_tonediv" "resultVar" "$tq" }\n'
              '\t\t"Int" { "srcVar1" "$tq" "resultVar" "$tq" }\n'
              '\t\t"Divide" { "srcVar1" "$tq" "srcVar2" "$my_toneradix" "resultVar" "$tq2" }\n'
              '\t\t"Int" { "srcVar1" "$tq2" "resultVar" "$tq2" }\n'
              '\t\t"Multiply" { "srcVar1" "$tq2" "srcVar2" "$my_toneradix" "resultVar" "$tq2" }\n'
              '\t\t"Subtract" { "srcVar1" "$tq" "srcVar2" "$tq2" "resultVar" "$tnew" }\n'
              '\t\t"LessOrEqual" { "srcVar1" "$hit" "srcVar2" "$zero" "resultVar" "$tone" "LessEqualVar" "$tnew" "greaterVar" "$tone" }\n'
              '\t\t"Subtract" { "srcVar1" "$tone" "srcVar2" "$my_tone" "resultVar" "$td" }\n'
              '\t\t"Abs" { "srcVar1" "$td" "resultVar" "$td" }\n'
              '\t\t"LessOrEqual" { "srcVar1" "$td" "srcVar2" "$zero" "resultVar" "$tshow" "LessEqualVar" "$one" "greaterVar" "$zero" }\n'
              '\t\t"Multiply" { "srcVar1" "$show" "srcVar2" "$tshow" "resultVar" "$show" }\n'
              '\t\t"Multiply" { "srcVar1" "$show" "srcVar2" "$fresh" "resultVar" "$alpha" }\n')


def shared_materials():
    live = SHARED.replace('\t"$zero" "0"\n', LIVE_VARS + '\t"$zero" "0"\n', 1).replace(FINAL, LIVE_CHAIN + FINAL + LIVE_MUL, 1)
    base = live.replace('\t"$zero" "0"\n', POP_VARS + '\t"$zero" "0"\n', 1).replace(FINAL, POP_CHAIN + FINAL, 1)
    translucent = base.replace('"$additive" "1"', '"$translucent" "1"')
    tone = base.replace('\t"$zero" "0"\n', TONE_VARS + '\t"$zero" "0"\n', 1).replace(FINAL, TONE_CHAIN, 1)
    return {
        "pn_shared": base,
        "pn_shared_t": translucent,
        "pn_shared_any": translucent.replace(EQ, ANY),
        "pn_shared_tone": tone,
        "pn_shared_any_tone": tone.replace(EQ, ANY).replace('"$additive" "1"', '"$translucent" "1"'),
        "pn_shared_any_add": base.replace(EQ, ANY),
    }


def pot(n):
    p = 1
    while p < n:
        p *= 2
    return p


def cx(n):
    return f"c{n}" if n < 0 else f"c+{n}"


def coord(v):
    v = int(round(v))
    return f"c{v}" if v < 0 else f"c+{v}"


def centre_text(img, text, size, colour):
    d = ImageDraw.Draw(img)
    f = ImageFont.truetype(FONT, size)
    bb = d.textbbox((0, 0), text, font=f)
    d.text(((img.width - (bb[2] - bb[0])) / 2 - bb[0], (img.height - (bb[3] - bb[1])) / 2 - bb[1]), text, font=f, fill=colour)
    return img


def tone_extra(div, radix, tone):
    return f'\t\t"$my_tonediv" "{div}"\n\t\t"$my_toneradix" "{radix}"\n\t\t"$my_tone" "{tone}"\n'


def image_panel(name, kvs):
    return ([f'\t"{name}"', '\t{', '\t\t"ControlName"\t"ImagePanel"', f'\t\t"fieldName"\t"{name}"']
            + [f'\t\t"{k}"\t"{v}"' for k, v in kvs.items()] + ['\t}'])


def drawn(x, y, z, w, h, image):
    return dict(xpos=x, ypos=y, zpos=z, wide=w, tall=h, visible=1, enabled=1, scaleImage=1, autoResize=0, pinCorner=0,
                image=image, drawcolor="255 255 255 255")


def patch(shared, texture, tag, div, radix, value, sdiv, sradix, duration=1000000, extra=""):
    return ('"patch"\n{\n\t"include" "materials/hd4l/%s.vmt"\n\t"insert"\n\t{\n' % shared +
            f'\t\t"$basetexture" "{texture}"\n\t\t"$my_tag" "{tag}"\n\t\t"$my_div" "{div}"\n\t\t"$my_radix" "{radix}"\n'
            f'\t\t"$my_value" "{value}"\n\t\t"$my_seqdiv" "{sdiv}"\n\t\t"$my_seqradix" "{sradix}"\n\t\t"$my_duration" "{duration}"\n'
            + extra + '\t}\n}\n')


class Panels:
    def __init__(self, out):
        self.mat = out / "parts/hyper-feedback/addon/materials/hd4l"
        self.vgui_hud = out / "parts/hyper-feedback/addon/materials/vgui/hud"
        self.res = out / "parts/hyper-feedback/addon/resource/ui/hud/itempickup.res"
        self.panels = []
        self.literal = []

    def build(self):
        for name, text in shared_materials().items():
            write(self.mat / f"{name}.vmt", text)
        self.marks()
        self.feed()
        self.health_digits()
        self.chain()
        self.stats()
        self.fort()
        self.me()
        self.mates()
        self.tinted_icons()
        self.write_res()
        print(f"panels: {len(self.panels)} drawn, {len(self.literal)} literal")

    def tex(self, name, img, fmt="dxt1", clamp=False):
        vtf(img, self.mat / f"{name}.vtf", fmt=fmt, clamp=clamp)

    def lit(self, name, **kv):
        self.literal.append((name, kv))

    def place(self, name, x, y, w, h, z, **kv):
        self.lit(f"hd4l_{name}", xpos=x, ypos=y, wide=w, tall=h, zpos=z, image=f"../hd4l/pn_{name}", **{**IMGKV, **kv})

    def from_art(self, name, fmt="dxt1"):
        png, svg = ART / f"{name}.png", ART / f"{name}.svg"
        if png.exists():
            img = Image.open(png)
        elif svg.exists():
            img = render(svg)
            if img.width > ICON:
                img = img.resize((ICON, ICON), Image.LANCZOS)
        else:
            return False
        if fmt == "dxt1":
            rgba = img.convert("RGBA")
            flat = Image.new("RGBA", rgba.size, (0, 0, 0, 255))
            flat.alpha_composite(rgba)
            img = flat.convert("RGB")
        self.tex(name, img, fmt)
        return True

    def panel(self, name, img, tag, fields, field, value, seq=None, duration=1000000):
        img = M.finish(img)
        bbox = img.convert("L").point(lambda v: 255 if v > 6 else 0).getbbox()
        if bbox is None:
            return
        x0, y0, x1, y1 = bbox
        x0 -= 6
        y0 -= 6
        x1 += 6
        y1 += 6
        w, h = x1 - x0, y1 - y0
        pw, ph = pot(w), pot(h)
        crop = Image.new("RGB", (pw, ph), (0, 0, 0))
        crop.paste(img.crop((x0, y0, x1, y1)), ((pw - w) // 2, (ph - h) // 2))
        self.tex(f"pn_{name}", crop)
        div, radix = fields[field]
        sdiv, sradix = fields[seq] if seq else (1, 1)
        write(self.mat / f"pn_{name}.vmt", patch("pn_shared", f"hd4l/pn_{name}", tag, div, radix, value, sdiv, sradix, duration))
        x = (x0 + x1) / 2 - 512
        y = (y0 + y1) / 2 - 256
        self.panels.append((name, x * UX - pw * UX / 2, y * UY - ph * UY / 2, pw * UX, ph * UY))

    def slot(self, name, texture, shared, tag, fields, field, value, x, y, w, h, z=6, seq=None):
        div, radix = fields[field]
        sdiv, sradix = fields[seq] if seq else (div, radix)
        write(self.mat / f"pn_{name}.vmt", patch(shared, texture, tag, div, radix, value, sdiv, sradix))
        self.place(name, x, y, w, h, z)

    def digits_row(self, prefix, tag, fields, names, xs, y, w, h, tex="dg_a"):
        for field, x in zip(names, xs):
            for v in range(10):
                self.slot(f"{prefix}_{field}_{v}", f"hd4l/{tex}{v}", "pn_shared", tag, fields, field, v, x, y, w, h)

    def digit_tex(self, ch, colour, name):
        big = Image.new("RGB", (DIGIT_W * 16, DIGIT_H * 16), (0, 0, 0))
        self.tex(name, centre_text(big, ch, int(DIGIT_H * 16 * 0.86), colour).resize((64, 128), Image.LANCZOS))

    def text_tex(self, name, text, colour, tw, th, frac=0.78):
        big = Image.new("RGB", (tw * 8, th * 8), (0, 0, 0))
        self.tex(name, centre_text(big, text, int(th * 8 * frac), colour).resize((tw, th), Image.LANCZOS))

    def icon(self, name, fmt="dxt1"):
        if not self.from_art(name, fmt):
            raise FileNotFoundError(f"no {name}.png or {name}.svg in {ART}")

    def label_tex(self, name, text, colour, box_w, box_h, cap, align="west", top=None, tw=1024, th=64):
        w, h = int(box_w * 10), int(box_h * 10)
        img = Image.new("RGB", (w, h), (0, 0, 0))
        d = ImageDraw.Draw(img)
        font = ImageFont.truetype(FONT, int(cap * 10 / 0.72))
        bb = d.textbbox((0, 0), text, font=font)
        x = -bb[0] if align == "west" else (w - (bb[2] - bb[0])) / 2 - bb[0]
        y = (top * 10 if top is not None else (h - (bb[3] - bb[1])) / 2) - bb[1]
        d.text((x, y), text, font=font, fill=colour)
        self.tex(name, img.resize((tw, th), Image.LANCZOS))

    def marks(self):
        for i, name in enumerate(M.MARKS, 1):
            self.panel(f"mark_{name}", M.mark(name), 1, TAG1, "mark", i, "mseq", HOLD[name])
        for i, dn in enumerate(M.DIRS, 1):
            self.panel(f"arc_{dn}", M.damage_arc(dn), 1, TAG1, "arc", i, "aseq", 0.5)
        for s in range(6):
            for h in range(2):
                if s == 5 and h == 0:
                    continue
                self.panel(f"stam_s{s}_h{h}", M.stamina_bar(s, h == 1), 1, TAG1, "stam", s * 2 + h)
        for t in range(M.TANK_LEVELS):
            self.panel(f"tank_t{t}", M.tank_bar(t), 2, TAG2, "tank", t + 1)
        self.panel("break_wait", M.struggle(0, SHADE, SHADE), 2, TAG2, "struggle", 1)
        for n in range(7):
            self.panel(f"break_{n}", M.struggle(n, BONE, AMBER), 2, TAG2, "struggle", 2 + n)
        self.panel("break_fail", M.struggle(0, BLOOD, BLOOD), 2, TAG2, "struggle", 9)
        for k in range(1, 5):
            self.panel(f"spike_{k}", M.spike_mark(), 2, TAG2, "spike", k, "spike", 0.6)
        for i, side in enumerate(M.SIDES, 1):
            self.panel(f"cue_{side}", M.side_cue(side), 2, TAG2, "cue", i, "cseq", 0.5)
        self.panel("cue_jump", M.jump_cue(), 2, TAG2, "cue", 5, "cseq", 0.6)

    def feed_panel(self, name, texture, shared, tag, field, value, x, y, w, t, tone=None):
        div, radix = FEED[field]
        sdiv, sradix = FEED["k" + field[1]]
        extra = "" if tone is None else tone_extra(*FEED[tone[0]], tone[1])
        write(self.mat / f"pn_{name}.vmt", patch(shared, texture, tag, div, radix, value, sdiv, sradix, extra=extra))
        self.place(name, x, y, w, t, 0)

    def feed(self):
        for name in ("common", "witch", "world"):
            self.icon(f"ic_{name}", "dxt5")
        killer, victim = {}, {}
        for i, n in enumerate(SURVIVORS, 1):
            killer[i] = victim[i] = (f"vgui/s_panel_{n}", "pn_shared_t")
        for i, n in enumerate(SPECIALS, 9):
            killer[i] = victim[i] = (f"vgui/hud/zombieteamimage_{n}", "pn_shared_t")
        killer[16] = ("hd4l/ic_common", "pn_shared_t")
        killer[17] = ("hd4l/ic_world", "pn_shared_t")
        victim[16] = ("hd4l/ic_witch", "pn_shared_t")
        victim[17] = ("hd4l/ic_common", "pn_shared_t")
        for r in range(4):
            tag = 3 + r // 2
            n = r % 2 + 1
            y = 26 + 26 * r
            for code, (texture, shared) in killer.items():
                self.feed_panel(f"feed{r + 1}_k{code}", texture, shared, tag, f"k{n}", code, "r86", y + 1, 22, 22)
            self.feed_panel(f"feed{r + 1}_arrow", "hd4l/arrow", "pn_shared_any_tone", tag, f"k{n}", 0, "r62", y + 5, 14, 14, tone=(f"h{n}", 0))
            self.feed_panel(f"feed{r + 1}_arrow_head", "hd4l/arrow_head", "pn_shared_any_tone", tag, f"k{n}", 0, "r62", y + 5, 14, 14, tone=(f"h{n}", 1))
            for code, (texture, shared) in victim.items():
                self.feed_panel(f"feed{r + 1}_v{code}", texture, shared, tag, f"v{n}", code, "r46", y + 1, 22, 22)

    def health_digits(self):
        for v in range(10):
            self.digit_tex(str(v), AMBER, f"dg_a{v}")
            self.digit_tex(str(v), BLOOD, f"dg_b{v}")
        tdiv, tradix = DIGITS["tone"]
        for i, field in enumerate(["d1", "d2", "d3", "d4"]):
            div, radix = DIGITS[field]
            x = f"r{150 - i * DIGIT_W}"
            for v in range(10):
                for kind, tone in (("a", 0), ("b", 1)):
                    name = f"num{i + 1}_{kind}{v}"
                    write(self.mat / f"pn_{name}.vmt", patch("pn_shared_tone", f"hd4l/dg_{kind}{v}", 5, div, radix, v, div, radix,
                                                            extra=tone_extra(tdiv, tradix, tone)))
                    self.place(name, x, f"r{RAIL - 4}", DIGIT_W, DIGIT_H, 5)

    def chain(self):
        self.text_tex("bd_x", "x", AMBER, 32, 64, 0.62)
        self.slot("chain_x", "hd4l/bd_x", "pn_shared_any_add", 6, TAG6, "live", 0, cx(100), cx(-70), 16, CH_H)
        self.digits_row("chain", 6, TAG6, ["c1", "c2"], [cx(118), cx(140)], cx(-70), CH_W, CH_H)

    def stats(self):
        for v in range(10):
            self.digit_tex(str(v), BONE, f"dg_w{v}")
        self.icon("st_clock")
        self.text_tex("st_colon", ":", BONE, 32, 64, 0.62)
        self.slot("stat_icon0", "hd4l/st_clock", "pn_shared_any_add", 11, TAG11, "shown", 0, ST_X, ST_Y, ST_ICON, ST_ICON, seq="shown")
        if self.from_art("st_skull"):
            self.slot("stat_icon1", "hd4l/st_skull", "pn_shared_any_add", 11, TAG11, "shown", 0, ST_X, ST_Y + ST_ROW, ST_ICON, ST_ICON, seq="shown")
        else:
            self.slot("stat_icon1", "sprites/skull_icon", "pn_shared_any", 11, TAG11, "shown", 0, ST_X, ST_Y + ST_ROW, ST_ICON, ST_ICON, seq="shown")
        if self.from_art("st_chain"):
            self.slot("stat_icon2", "hd4l/st_chain", "pn_shared_any_add", 11, TAG11, "shown", 0, ST_X, ST_Y + 2 * ST_ROW, ST_ICON, ST_ICON, seq="shown")
        else:
            self.slot("stat_icon2", "hd4l/bd_x", "pn_shared_any_add", 11, TAG11, "shown", 0, ST_X + 6, ST_Y + 2 * ST_ROW, ST_ICON // 2, ST_ICON, seq="shown")
        x = ST_NX
        self.digits_row("stat", 11, TAG11, ["m1"], [x], ST_Y, ST_W, ST_H, "dg_w")
        self.digits_row("stat", 11, TAG11, ["m2"], [x + ST_W], ST_Y, ST_W, ST_H, "dg_w")
        self.slot("stat_colon", "hd4l/st_colon", "pn_shared_any_add", 11, TAG11, "shown", 0, x + 2 * ST_W, ST_Y, 6, ST_H, seq="shown")
        for v in range(6):
            self.slot(f"stat_s1_{v}", f"hd4l/dg_w{v}", "pn_shared", 11, TAG11, "s1", v, x + 2 * ST_W + 6, ST_Y, ST_W, ST_H)
        self.digits_row("stat", 11, TAG11, ["s2"], [x + 3 * ST_W + 6], ST_Y, ST_W, ST_H, "dg_w")
        self.digits_row("stat", 12, TAG12, ["k1", "k2", "k3", "k4", "k5"], [x + ST_W * i for i in range(5)], ST_Y + ST_ROW, ST_W, ST_H, "dg_w")
        self.digits_row("stat", 13, TAG13, ["c1", "c2", "c3"], [x + ST_W * i for i in range(3)], ST_Y + 2 * ST_ROW, ST_W, ST_H, "dg_w")

    def fort(self):
        self.icon("st_wave")
        self.icon("st_scrap")
        self.icon("st_build")
        x = ST_NX
        fw, fs, fc = ST_Y + 3 * ST_ROW, ST_Y + 4 * ST_ROW, ST_Y + 5 * ST_ROW
        self.slot("stat_icon5", "hd4l/st_wave", "pn_shared", 10, TAG19, "state", 1, ST_X, fw, ST_ICON, ST_ICON)
        self.slot("stat_icon6", "hd4l/st_build", "pn_shared", 10, TAG19, "state", 2, ST_X, fw, ST_ICON, ST_ICON)
        for i, field in enumerate(["w1", "w2"]):
            for v in range(10):
                self.slot(f"fort_{field}_{v}", f"hd4l/dg_a{v}", "pn_shared", 10, TAG19, field, v + 1, x + ST_W * i, fw, ST_W, ST_H)
        for i, field in enumerate(["t1", "t2", "t3"]):
            for v in range(10):
                self.slot(f"fort_{field}_{v}", f"hd4l/dg_w{v}", "pn_shared", 10, TAG19, field, v + 1, x + ST_W * (i + 2) + 12, fw, ST_W, ST_H)
        self.slot("stat_icon3", "hd4l/st_scrap", "pn_shared_any_add", 8, TAG17, "shown", 0, ST_X, fs, ST_ICON, ST_ICON, seq="shown")
        self.slot("stat_icon4", "hd4l/st_build", "pn_shared_any_add", 9, TAG18, "shown", 0, ST_X, fc, ST_ICON, ST_ICON, seq="shown")
        for i, field in enumerate(["p1", "p2", "p3", "p4"]):
            for v in range(10):
                self.slot(f"fort_{field}_{v}", f"hd4l/dg_w{v}", "pn_shared", 8, TAG17, field, v + 1, x + ST_W * i, fs, ST_W, ST_H)
        for i, field in enumerate(["c1", "c2", "c3", "c4"]):
            for v in range(10):
                self.slot(f"fort_{field}_{v}", f"hd4l/dg_w{v}", "pn_shared", 9, TAG18, field, v + 1, x + ST_W * i, fc, ST_W, ST_H)
                self.slot(f"fort_{field}_{v}_no", f"hd4l/dg_b{v}", "pn_shared", 9, TAG18, field, v + 11, x + ST_W * i, fc, ST_W, ST_H)

    def put(self, name, mat, x, y, w, h, z, colour="255 255 255 255"):
        write(self.mat / f"pn_{name}.vmt", mat.text())
        self.place(name, x, y, w, h, z, drawcolor=colour)

    def simple(self, name, base, tag, fields, cond, x, y, w, h, z, colour="255 255 255 255", blend="translucent", params=None):
        m = chan.Mat(base, blend, params=params)
        m.show(cond(m, lambda f: m.field(tag, fields, f)))
        self.put(name, m, x, y, w, h, z, colour)

    def bar(self, name, base, tag, fields, lo, hi, cond, x, y, w, h, z, blend="translucent", scroll=None, colour="255 255 255 255"):
        m = chan.Mat(base, blend, shader="UnlitTwoTexture", texture2="hd4l/band")
        get = lambda f: m.field(tag, fields, f)
        lo_v, hi_v = lo(m, get), hi(m, get)
        m.band(lo_v, hi_v)
        if scroll:
            m.scroll(scroll)
        m.show(cond(m, get))
        self.put(name, m, x, y, w, h, z, colour)

    def me(self):
        band = Image.new("RGBA", (128, 4), (0, 0, 0, 0))
        ImageDraw.Draw(band).rectangle([32, 0, 95, 3], fill=(255, 255, 255, 255))
        vtf(band, self.mat / "band.vtf", fmt="rgba8888", clamp=True)
        frac = lambda field, top: lambda m, get: m.scale(get(field), 1.0 / top)
        for i, n in enumerate(SURVIVORS, 1):
            self.simple(f"me_head{i}", f"vgui/s_panel_{n}", T_ME, TAG_ME, lambda m, g, i=i: m.eq(g("who"), i), "r190", "r55", 34, 34, 2)
        self.simple("me_crouch", "vgui/hud/crouch_survivor", T_ME, TAG_ME, lambda m, g: m.eq(g("crouch"), 1), "r32", "r55", 20, 20, 2, drawcolor(BONE))
        self.simple("me_bg", "hd4l/bar_me_bg", T_ME, TAG_ME, lambda m, g: m.eq(g("on"), 1), "r190", "r17", 180, 8, 0)
        self.bar("me_temp", "hd4l/bar_ticks", T_ME, TAG_ME, frac("hp", ME_HP), frac("total", ME_HP), lambda m, g: m.eq(g("on"), 1),
                 "r190", "r17", 180, 8, 1, scroll=0.35)
        for i, (tone, (rest, hot, pulse)) in enumerate(REACTIVE.items()):
            k = reactive_consts(rest, hot)
            m = chan.Mat("hd4l/bar_me_cell", "translucent", shader="UnlitTwoTexture", texture2="hd4l/band", params={"$color": "[1 1 1]"})
            get = lambda f, m=m: m.field(T_ME, TAG_ME, f)
            m.band(m.zero, m.scale(get("hp"), 1.0 / ME_HP))
            tag1 = {"aseq": (270, 5), "hyp": (1350, 2)}
            seq = m.field(1, tag1, "aseq")
            hyp = m.field(1, tag1, "hyp")
            pt = m.new()
            m.op("Divide", m.age(seq), m.const(k["dur"]), pt)
            tc = m.clamp01(pt)
            kk = m.new()
            m.op("Subtract", m.one, tc, kk)
            bb = m.scale(kk, 2)
            w = m.new()
            m.op("Subtract", bb, m.one, w)
            w = m.clamp01(w)
            bb = m.clamp01(bb)
            for c in range(3):
                rc = m.add(m.scale(hyp, k[f"dh{c}"]), m.const(k[f"r{c}"]))
                x = m.new()
                m.op("Subtract", m.const(k[f"bl{c}"]), rc, x)
                x = m.mul(x, bb)
                y = m.scale(w, k[f"wb{c}"])
                m.op("Add", m.add(rc, x), y, f"$color[{c}]")
            flick = m.new("1")
            if pulse:
                m.p('"Sine" { "sineperiod" "0.6" "sinemin" "0.55" "sinemax" "1.0" "resultVar" "%s" }' % flick)
            else:
                m.p('"UniformNoise" { "minVal" "0.94" "maxVal" "1.0" "resultVar" "%s" }' % flick)
            m.show(m.mul(m.eq(get("on"), 1), m.eq(get("tone"), i)), extra=flick)
            self.put(f"me_fill{i}", m, "r190", "r17", 180, 8, 3)
            colour = "[%s %s %s]" % (chan.fmt(min(k["r0"], 1.0)), chan.fmt(min(k["r1"], 1.0)), chan.fmt(min(k["r2"], 1.0)))
            p = chan.Mat("hd4l/bar_me_cell", "translucent", shader="UnlitTwoTexture", texture2="hd4l/band", params={"$color": colour})
            getp = lambda f, p=p: p.field(T_ME, TAG_ME, f)
            p.band(p.zero, p.scale(getp("hp"), 1.0 / ME_HP))
            p.show(p.mul(p.eq(getp("on"), 1), p.eq(getp("tone"), i)))
            self.put(f"me_plain{i}", p, "r190", "r17", 180, 8, 2)

    def mates(self):
        frac = lambda field, top: lambda m, get: m.scale(get(field), 1.0 / top)
        zero = lambda m, get: m.zero
        for i, n in enumerate(SURVIVOR_NAMES, 1):
            self.label_tex(f"nm_{i}", n, BONE, 68, 12, 5.4, top=2.2, tw=512, th=128)
        for r in range(3):
            tag = T_MATES[r]
            x = 6 + 110 * r
            present = lambda m, g: m.ge(g("who"), 1)
            for i, n in enumerate(SURVIVORS, 1):
                self.simple(f"mate{r + 1}_head{i}", f"vgui/s_panel_{n}", tag, TAG_MATE,
                            lambda m, g, i=i: m.mul(m.eq(g("who"), i), m.eq(g("incap"), 0)), x, "r54", 34, 34, 2)
                self.simple(f"mate{r + 1}_headx{i}", f"vgui/s_panel_{n}", tag, TAG_MATE,
                            lambda m, g, i=i: m.mul(m.eq(g("who"), i), m.eq(g("incap"), 1)), x, "r54", 34, 34, 2, params=INCAP)
                self.simple(f"mate{r + 1}_name{i}", f"hd4l/nm_{i}", tag, TAG_MATE, lambda m, g, i=i: m.eq(g("who"), i),
                            x + 38, "r56", 68, 12, 3, blend="additive")
            self.simple(f"mate{r + 1}_bg", "hd4l/bar_bg", tag, TAG_MATE, present, x + 38, "r34", 66, 6, 0)
            self.bar(f"mate{r + 1}_temp", "hd4l/bar_ticks", tag, TAG_MATE, frac("hp", MATE_HP), frac("total", MATE_HP), present,
                     x + 38, "r34", 66, 6, 1, scroll=0.35)
            for i, tone in enumerate(("bone", "amber", "blood")):
                self.bar(f"mate{r + 1}_fill{i}", f"hd4l/bar_{tone}", tag, TAG_MATE, zero, frac("hp", MATE_HP),
                         lambda m, g, i=i: m.mul(m.ge(g("who"), 1), m.eq(g("tone"), i)), x + 38, "r34", 66, 6, 2)
            self.simple(f"mate{r + 1}_seg", "hd4l/seg", tag, TAG_MATE, present, x + 38, "r34", 66, 6, 4)
            self.simple(f"mate{r + 1}_line", "hd4l/bar_line", tag, TAG_MATE, present, x + 38, "r27", 66, 1, 0)
            self.simple(f"mate{r + 1}_dead", "hd4l/bar_blood", tag, TAG_MATE, lambda m, g: m.mul(m.ge(g("who"), 1), m.eq(g("alive"), 0)),
                        x + 38, "r34", 66, 6, 5)
            for j, (field, icon) in enumerate((("nade", "eq_molotov"), ("kit", "eq_medkit"), ("pills", "eq_adrenaline"))):
                self.simple(f"mate{r + 1}_g{field}", f"hd4l/{icon}", tag, TAG_MATE, present, x + 38 + 12 * j, "r22", 10, 10, 1, drawcolor(ASH, 90))
                self.simple(f"mate{r + 1}_{field}", f"hd4l/{icon}", tag, TAG_MATE, lambda m, g, f=field: m.eq(g(f), 1),
                            x + 38 + 12 * j, "r22", 10, 10, 2, drawcolor(BONE))

    def tinted_icons(self):
        for n in TINTED:
            m = chan.Mat(f"vgui/hud/{n}", "translucent", params={"$color": "[1 1 1]", "$no_fullbright": "1"})
            m.var("$alpha", "1")
            on = m.full_hud()
            for c in range(3):
                m.op("Add", m.scale(on, AMBER[c] / 255 - 1.0), m.one, f"$color[{c}]")
            write(self.vgui_hud / f"{n}.vmt", m.text())

    def write_res(self):
        res = ['"Resource/UI/HUD/ItemPickup.res"', '{']
        for name, x, y, w, h in self.panels:
            res += image_panel(f"hd4l_{name}", drawn(coord(x), coord(y), -1, int(round(w)), int(round(h)), f"../hd4l/pn_{name}"))
        for name, kvs in self.literal:
            res += image_panel(name, kvs)
        res += image_panel("hd4l_dot", drawn("c-4", "c-4", 2, 8, 8, "../hd4l/dot"))
        for i in (1, 2, 3):
            res += [f'\t"image{i}"', '\t{', '\t\t"ControlName"\t"IconPanel"', f'\t\t"fieldName"\t\t"image{i}"', '\t\t"xpos"\t\t\t"0"', '\t\t"ypos"\t\t\t"0"',
                    '\t\t"wide"\t\t\t"24"', '\t\t"tall"\t\t\t"24"', '\t\t"visible"\t\t"0"', '\t\t"enabled"\t\t"1"', '\t\t"zpos"\t\t\t"1"', '\t\t"icon"\t\t\t"icon_painpills"', '\t\t"scaleImage"\t"1"', '\t}',
                    f'\t"bg{i}"', '\t{', '\t\t"ControlName"\t"IconPanel"', f'\t\t"fieldName"\t\t"bg{i}"', '\t\t"xpos"\t\t\t"0"', '\t\t"ypos"\t\t\t"0"',
                    '\t\t"wide"\t\t\t"28"', '\t\t"tall"\t\t\t"28"', '\t\t"visible"\t\t"0"', '\t\t"enabled"\t\t"1"', '\t\t"zpos"\t\t\t"0"', '\t\t"icon"\t\t\t"itempickup_background"', '\t\t"scaleImage"\t"1"', '\t}']
        res.append('}')
        write(self.res, "\n".join(res) + "\n")

