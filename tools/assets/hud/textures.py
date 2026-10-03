from PIL import Image, ImageDraw

from ...util import game_file, vtf, vtf_to_png, workdir, write
from ... import config
from ..palette import AMBER, ASH, BLOOD, BONE
from ..svg import render

ART = config.part("hyper-feedback") / "art" / "hud"

PANEL = (16, 14, 12)
HOT = (255, 196, 96)
WHITE = (255, 248, 235)

RAIL = 64
LEFT_W = 342
RIGHT_W = 200
WEAPON_W, WEAPON_H = 100, 140
FEED_W, FEED_H = 78, 24

FLASH_SECONDS = 0.35
CELLS, CELL_GAP = 10, 4
LIT_GAIN, HALO = 1.1, 0
GLOW_UNITS, GLOW_EDGE = 4.0, 0.0

FLAGS = '\t"$translucent" "1"\n\t"$vertexcolor" "1"\n\t"$vertexalpha" "1"\n\t"$ignorez" "1"\n\t"$no_fullbright" "1"\n\t"$nomip" "1"\n\t"$nolod" "1"\n'
PULSE = '\t"$alpha" "1"\n\t"Proxies"\n\t{\n\t\t"Sine" { "sineperiod" "0.6" "sinemin" "0.55" "sinemax" "1.0" "resultVar" "$alpha" }\n\t}\n'

PLATES = {
    "scalablepanel_bgmidgrey": "ScalablePanel_bgMidGrey",
    "scalablepanel_bgmidgrey_outlinegrey": "ScalablePanel_bgMidGrey_outlineGrey",
    "scalablepanel_bgmidgrey_glow": "ScalablePanel_bgMidGrey_glow",
    "scalablepanel_bgmidgrey_outlinegreen_glow": "ScalablePanel_bgMidGrey_outlineGreen_glow",
    "scalablepanel_bgblack_outlinegrey": "ScalablePanel_bgBlack_outlineGrey",
    "scalablepanel_bgblack": "ScalablePanel_bgBlack",
}
UNLESS_FULL_HUD = ('\t"$alpha" "1"\n\t"$v" "0" "$lastv" "0" "$armed" "0" "$dv" "0" "$vgo" "0" "$time" "0" "$vstart" "-1000" "$vage" "0" "$live" "0"\n'
               '\t"$zero" "0" "$one" "1" "$two" "2" "$my_live" "3.0"\n'
               '\t"$guard" "50000" "$million" "1000000" "$full_div" "16200"\n'
               '\t"$t" "0" "$tag" "0" "$tagbase" "0" "$payload" "0" "$hit" "0" "$q" "0" "$q2" "0" "$fnew" "0" "$full" "0"\n'
               '\t"Proxies"\n\t{\n'
               '\t\t"ConVar" { "convar" "name2" "resultVar" "$v" }\n'
               '\t\t"Add" { "srcVar1" "$v" "srcVar2" "$guard" "resultVar" "$t" }\n'
               '\t\t"Divide" { "srcVar1" "$t" "srcVar2" "$million" "resultVar" "$t" }\n'
               '\t\t"Int" { "srcVar1" "$t" "resultVar" "$tag" }\n'
               '\t\t"Multiply" { "srcVar1" "$tag" "srcVar2" "$million" "resultVar" "$tagbase" }\n'
               '\t\t"Subtract" { "srcVar1" "$v" "srcVar2" "$tagbase" "resultVar" "$payload" }\n'
               '\t\t"Subtract" { "srcVar1" "$tag" "srcVar2" "$one" "resultVar" "$hit" }\n'
               '\t\t"Abs" { "srcVar1" "$hit" "resultVar" "$hit" }\n'
               '\t\t"Divide" { "srcVar1" "$payload" "srcVar2" "$full_div" "resultVar" "$q" }\n'
               '\t\t"Int" { "srcVar1" "$q" "resultVar" "$q" }\n'
               '\t\t"Divide" { "srcVar1" "$q" "srcVar2" "$two" "resultVar" "$q2" }\n'
               '\t\t"Int" { "srcVar1" "$q2" "resultVar" "$q2" }\n'
               '\t\t"Multiply" { "srcVar1" "$q2" "srcVar2" "$two" "resultVar" "$q2" }\n'
               '\t\t"Subtract" { "srcVar1" "$q" "srcVar2" "$q2" "resultVar" "$fnew" }\n'
               '\t\t"LessOrEqual" { "srcVar1" "$hit" "srcVar2" "$zero" "resultVar" "$full" "LessEqualVar" "$fnew" "greaterVar" "$full" }\n'
               '\t\t"CurrentTime" { "resultVar" "$time" }\n'
               '\t\t"Subtract" { "srcVar1" "$v" "srcVar2" "$lastv" "resultVar" "$dv" }\n'
               '\t\t"Abs" { "srcVar1" "$dv" "resultVar" "$dv" }\n'
               '\t\t"Multiply" { "srcVar1" "$dv" "srcVar2" "$armed" "resultVar" "$vgo" }\n'
               '\t\t"LessOrEqual" { "srcVar1" "$vgo" "srcVar2" "$zero" "resultVar" "$vstart" "LessEqualVar" "$vstart" "greaterVar" "$time" }\n'
               '\t\t"Equals" { "srcVar1" "$v" "resultVar" "$lastv" }\n'
               '\t\t"Equals" { "srcVar1" "$one" "resultVar" "$armed" }\n'
               '\t\t"Subtract" { "srcVar1" "$time" "srcVar2" "$vstart" "resultVar" "$vage" }\n'
               '\t\t"LessOrEqual" { "srcVar1" "$vage" "srcVar2" "$my_live" "resultVar" "$live" "LessEqualVar" "$one" "greaterVar" "$zero" }\n'
               '\t\t"Multiply" { "srcVar1" "$live" "srcVar2" "$full" "resultVar" "$live" }\n'
               '\t\t"Subtract" { "srcVar1" "$one" "srcVar2" "$live" "resultVar" "$alpha" }\n'
               '\t}\n')
DOT_VMT = ('"patch"\n{\n\t"include" "materials/hd4l/pn_shared_t.vmt"\n\t"insert"\n\t{\n\t\t"$basetexture" "hd4l/dot"\n'
           '\t\t"$my_tag" "1"\n\t\t"$my_div" "16200"\n\t\t"$my_radix" "2"\n\t\t"$my_value" "1"\n'
           '\t\t"$my_seqdiv" "1"\n\t\t"$my_seqradix" "1"\n\t\t"$my_duration" "1000000"\n\t}\n}\n')
ICONS = {"eq_molotov": ("iconsheet", 0, 320), "eq_adrenaline": ("iconsheet2", 384, 0), "eq_medkit": ("iconsheet", 128, 320)}


def vmt(name, extra=""):
    return f'"UnlitGeneric"\n{{\n\t"$basetexture" "hd4l/{name}"\n{FLAGS}{extra}}}\n'


def scroll(rate, axis):
    return ('\t"$sx" "0"\n\t"$off" "[0 0]"\n\t"Proxies"\n\t{\n'
            f'\t\t"LinearRamp" {{ "rate" "{rate}" "initialValue" "0" "resultVar" "$sx" }}\n'
            f'\t\t"Equals" {{ "srcVar1" "$sx" "resultVar" "$off[{axis}]" }}\n'
            '\t\t"TextureTransform" { "translateVar" "$off" "resultVar" "$basetexturetransform" }\n\t}\n')


def scrolling(var, rate, angle=0):
    return f'\t\t"TextureScroll" {{ "texturescrollvar" "{var}" "texturescrollrate" "{rate}" "texturescrollangle" "{angle}" }}\n'


def flat(rgb, a=255, size=(32, 8)):
    return Image.new("RGBA", size, (*rgb, a))


def reactive_consts(rest, hot):
    n = lambda c: [round(v / 255.0 * LIT_GAIN, 4) for v in c]
    r, h, b, w = n(rest), n(hot), n(BLOOD), n(WHITE)
    k = {"dur": FLASH_SECONDS}
    for i in range(3):
        k[f"r{i}"] = r[i]
        k[f"dh{i}"] = round(h[i] - r[i], 4)
        k[f"bl{i}"] = b[i]
        k[f"wb{i}"] = round(w[i] - b[i], 4)
    return k


REACTIVE = {"bone": (BONE, HOT, False), "amber": (AMBER, HOT, False), "blood": (BLOOD, BLOOD, True)}


class Textures:
    def __init__(self, mat, vgui_hud):
        self.mat = mat
        self.vgui_hud = vgui_hud

    def tex(self, name, img, extra="", shader=None):
        vtf(img, self.mat / f"{name}.vtf", fmt="dxt5")
        body = vmt(name, extra)
        if shader:
            body = body.replace('"UnlitGeneric"', f'"{shader}"', 1)
        write(self.mat / f"{name}.vmt", body)

    def build(self):
        self.bars()
        self.player_bar()
        self.reactive_bars()
        self.rail()
        self.sheen("sheen", 0, 0.08)
        self.sheen("sheen_tall", 90, 0.06)
        self.ticks_and_segments()
        self.plates()
        self.stock_plates()
        self.item_icons()
        self.marks()
        print("textures written")

    def bars(self):
        e = Image.new("RGBA", (128, 8), (255, 255, 255, 255))
        px = e.load()
        for x in range(128):
            v = int(255 * (0.72 + 0.28 * ((x % 32) / 31.0)))
            for y in range(8):
                px[x, y] = (v, v, v, 255)
        self.tex("energy", e)
        self.tex("bar_bone", flat(BONE))
        self.tex("bar_amber", flat(AMBER))
        self.tex("bar_dim", flat(ASH))
        self.tex("bar_blood", flat(BLOOD), PULSE)
        self.tex("bar_bg", flat(PANEL, 215))
        self.tex("bar_line", flat(BONE, 130))
        self.tex("bar_white", flat((255, 255, 255)))

    def player_bar(self):
        self.tex("bar_me_cell", lit_cells())
        self.tex("bar_me_bg", cells((255, 255, 255), 55, 55))
        mask = Image.new("RGBA", (512, 16), (255, 255, 255, 255))
        d = ImageDraw.Draw(mask)
        for e in [512 * i // CELLS for i in range(1, CELLS)]:
            d.rectangle([e - CELL_GAP // 2, 0, e + CELL_GAP // 2 - 1, 15], fill=(0, 0, 0, 0))
        self.tex("bar_me_mask", mask)
        write(self.mat / "bar_me_ticks.vmt",
              '"UnlitTwoTexture"\n{\n\t"$basetexture" "hd4l/bar_ticks"\n\t"$texture2" "hd4l/bar_me_mask"\n' + FLAGS
              + scroll(0.35, 0) + '}\n')

    def reactive_bars(self):
        for tone, (rest, hot, pulse) in REACTIVE.items():
            write(self.mat / f"bar_me_{tone}.vmt", reactive_vmt(rest, hot, pulse))

    def rail(self):
        r = Image.new("RGBA", (512, 8), (*AMBER, 220))
        d = ImageDraw.Draw(r)
        for x in range(512):
            dist = min(abs(x - 96), 512 - abs(x - 96))
            if dist < 48:
                k = 1.0 - dist / 48.0
                c = tuple(int(AMBER[i] + (BONE[i] - AMBER[i]) * k) for i in range(3))
                d.line([(x, 0), (x, 7)], fill=(*c, int(220 + 35 * k)))
        motion = ('\t"$alpha" "1"\n\t"$basetexturetransform" "center .5 .5 scale 1 1 rotate 0 translate 0 0"\n\t"Proxies"\n\t{\n'
                  + scrolling("$basetexturetransform", 0.3) +
                  '\t\t"Sine" { "sineperiod" "2.4" "sinemin" "0.75" "sinemax" "1.0" "resultVar" "$alpha" }\n\t}\n')
        self.tex("rail", r, motion)

    def sheen(self, name, angle, rate):
        n = 256
        im = Image.new("RGBA", (n, n), (0, 0, 0, 0))
        px = im.load()
        for y in range(n):
            for x in range(n):
                u = ((x + y * 0.35) % n) / n
                k = max(0.0, 1.0 - abs(u - 0.5) / 0.12)
                b = 0.19 * k * k
                px[x, y] = (int(BONE[0] * b), int(BONE[1] * b), int(BONE[2] * b), 255)
        motion = ('\t"$basetexturetransform" "center .5 .5 scale 1 1 rotate 0 translate 0 0"\n\t"Proxies"\n\t{\n'
                  + scrolling("$basetexturetransform", rate, angle) + '\t}\n')
        self.tex(name, im, motion)
        path = self.mat / f"{name}.vmt"
        write(path, path.read_text().replace('"$translucent" "1"', '"$additive" "1"'))

    def ticks_and_segments(self):
        h = Image.new("RGBA", (64, 8), (0, 0, 0, 0))
        px = h.load()
        for y in range(8):
            for x in range(64):
                if ((x + y) // 3) % 2 == 0:
                    px[x, y] = (*AMBER, 255)
        self.tex("bar_ticks", h, scroll(0.35, 0))
        s = Image.new("RGBA", (512, 16), (0, 0, 0, 0))
        d = ImageDraw.Draw(s)
        for i in range(1, 10):
            x = 512 * i // 10
            d.rectangle([x - 2, 0, x + 1, 15], fill=(*PANEL, 255))
        self.tex("seg", s)

    def plates(self):
        self.tex("plate_left", plate(LEFT_W, RAIL - 1, 1024, 128, 18, ("tr",), fill_a=235))
        self.tex("plate_right", plate(RIGHT_W, RAIL - 1, 512, 128, 18, ("tl",), fill_a=235))
        self.tex("plate_weapon", plate(WEAPON_W, WEAPON_H, 256, 512, 14, ("tl",), fill_a=225))
        self.tex("plate_feed", plate(FEED_W, FEED_H, 256, 64, 6, ("tl", "bl"), fill_a=205))

    def stock_plates(self):
        for name, stock in PLATES.items():
            (self.vgui_hud / f"{name}.vtf").unlink(missing_ok=True)
            write(self.vgui_hud / f"{name}.vmt",
                  f'"UnlitGeneric"\n{{\n\t"$basetexture" "vgui/hud/{stock}"\n\t"$translucent" "1"\n\t"$vertexalpha" "1"\n'
                  f'\t"$vertexcolor" "1"\n\t"$ignorez" "1"\n\t"$no_fullbright" "1"\n' + UNLESS_FULL_HUD + '}\n')

    def item_icons(self):
        with workdir() as tmp:
            sheets = {}
            for sheet in ("iconsheet", "iconsheet2"):
                src = game_file(f"materials/vgui/hud/{sheet}.vtf", tmp, sources=("left4dead2",))
                sheets[sheet] = Image.open(vtf_to_png(src, tmp)).convert("RGBA")
            for name, (sheet, x, y) in ICONS.items():
                self.tex(name, sheets[sheet].crop((x, y, x + 64, y + 64)))

    def marks(self):
        for name in ("dot", "ring", "arrow", "arrow_head"):
            self.tex(name, render(ART / f"{name}.svg"))
        write(self.mat / "dot.vmt", DOT_VMT)


def cells(rgb, lit, dim, size=(512, 16)):
    w, h = size
    im = Image.new("RGBA", size, (0, 0, 0, 0))
    px = im.load()
    edges = [w * i // CELLS for i in range(1, CELLS)]
    for x in range(w):
        if any(abs(x - e) < CELL_GAP // 2 for e in edges):
            continue
        for y in range(h):
            px[x, y] = (*rgb, lit if y % 4 < 2 else dim)
    return im


def lit_cells(w=512, body=16, bar_w=180.0, bar_h=8.0):
    h = body + 2 * HALO
    ux, uy = bar_w / w, bar_h / body
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = im.load()
    spans = [(w * i // CELLS + (CELL_GAP // 2 if i else 0), w * (i + 1) // CELLS - (CELL_GAP // 2 if i < CELLS - 1 else 0)) for i in range(CELLS)]
    mid = HALO + (body - 1) / 2.0
    for x in range(w):
        dx = min(0 if a <= x < b else (a - x if x < a else x - b + 1) for a, b in spans) * ux
        for y in range(h):
            dy = (0 if HALO <= y < HALO + body else (HALO - y if y < HALO else y - HALO - body + 1)) * uy
            if dx == 0 and dy == 0:
                d = abs(y - mid) / (body / 2.0)
                v = (1.0 - 0.45 * d * d) * (1.0 if (y - HALO) % 4 < 2 else 0.82)
            else:
                dist = (dx * dx + dy * dy) ** 0.5
                v = GLOW_EDGE * max(0.0, 1.0 - dist / GLOW_UNITS) ** 2
            g = int(255 * v)
            px[x, y] = (g, g, g, 255)
    return im


def reactive_vmt(rest, hot, pulse):
    k = reactive_consts(rest, hot)
    consts = "".join(f'\t"$r{i}" "{k[f"r{i}"]}" "$dh{i}" "{k[f"dh{i}"]}" "$bl{i}" "{k[f"bl{i}"]}" "$wb{i}" "{k[f"wb{i}"]}"\n' for i in range(3))
    chan = ""
    for i in range(3):
        chan += (f'\t\t"Multiply" {{ "srcVar1" "$hyp" "srcVar2" "$dh{i}" "resultVar" "$rc" }}\n'
                 f'\t\t"Add" {{ "srcVar1" "$rc" "srcVar2" "$r{i}" "resultVar" "$rc" }}\n'
                 f'\t\t"Subtract" {{ "srcVar1" "$bl{i}" "srcVar2" "$rc" "resultVar" "$x" }}\n'
                 f'\t\t"Multiply" {{ "srcVar1" "$x" "srcVar2" "$b" "resultVar" "$x" }}\n'
                 f'\t\t"Multiply" {{ "srcVar1" "$wb{i}" "srcVar2" "$w" "resultVar" "$y" }}\n'
                 f'\t\t"Add" {{ "srcVar1" "$rc" "srcVar2" "$x" "resultVar" "$rc" }}\n'
                 f'\t\t"Add" {{ "srcVar1" "$rc" "srcVar2" "$y" "resultVar" "$color[{i}]" }}\n')
    flicker = ('\t\t"Sine" { "sineperiod" "0.6" "sinemin" "0.55" "sinemax" "1.0" "resultVar" "$alpha" }\n' if pulse
               else '\t\t"UniformNoise" { "minVal" "0.94" "maxVal" "1.0" "resultVar" "$alpha" }\n')
    return ('"UnlitGeneric"\n{\n\t"$basetexture" "hd4l/bar_me_cell"\n' + FLAGS.replace('"$translucent"', '"$additive"') +
            '\t"$color" "[1 1 1]"\n\t"$alpha" "1"\n' + consts +
            f'\t"$dur" "{FLASH_SECONDS}"\n'
            '\t"$zero" "0" "$one" "1" "$two" "2" "$guard" "50000" "$million" "1000000"\n'
            '\t"$sdiv" "270" "$srad" "5" "$hdiv" "1350" "$hrad" "12"\n'
            '\t"$v" "0" "$t" "0" "$tag" "0" "$tagbase" "0" "$payload" "0" "$hit" "0"\n'
            '\t"$s" "0" "$s2" "0" "$snew" "0" "$seq" "0" "$lastseq" "0" "$chg" "0" "$time" "0" "$start" "0" "$age" "0"\n'
            '\t"$f" "0" "$f2" "0" "$fnew" "0" "$stam" "0" "$hq" "0" "$hyp" "0"\n'
            '\t"$pt" "0" "$tc" "1" "$k" "0" "$w" "0" "$b" "0" "$rc" "0" "$x" "0" "$y" "0"\n'
            '\t"Proxies"\n\t{\n'
            '\t\t"ConVar" { "convar" "name2" "resultVar" "$v" }\n'
            '\t\t"Add" { "srcVar1" "$v" "srcVar2" "$guard" "resultVar" "$t" }\n'
            '\t\t"Divide" { "srcVar1" "$t" "srcVar2" "$million" "resultVar" "$t" }\n'
            '\t\t"Int" { "srcVar1" "$t" "resultVar" "$tag" }\n'
            '\t\t"Multiply" { "srcVar1" "$tag" "srcVar2" "$million" "resultVar" "$tagbase" }\n'
            '\t\t"Subtract" { "srcVar1" "$v" "srcVar2" "$tagbase" "resultVar" "$payload" }\n'
            '\t\t"Subtract" { "srcVar1" "$tag" "srcVar2" "$one" "resultVar" "$hit" }\n'
            '\t\t"Abs" { "srcVar1" "$hit" "resultVar" "$hit" }\n'
            '\t\t"Divide" { "srcVar1" "$payload" "srcVar2" "$sdiv" "resultVar" "$s" }\n'
            '\t\t"Int" { "srcVar1" "$s" "resultVar" "$s" }\n'
            '\t\t"Divide" { "srcVar1" "$s" "srcVar2" "$srad" "resultVar" "$s2" }\n'
            '\t\t"Int" { "srcVar1" "$s2" "resultVar" "$s2" }\n'
            '\t\t"Multiply" { "srcVar1" "$s2" "srcVar2" "$srad" "resultVar" "$s2" }\n'
            '\t\t"Subtract" { "srcVar1" "$s" "srcVar2" "$s2" "resultVar" "$snew" }\n'
            '\t\t"LessOrEqual" { "srcVar1" "$hit" "srcVar2" "$zero" "resultVar" "$seq" "LessEqualVar" "$snew" "greaterVar" "$seq" }\n'
            '\t\t"Divide" { "srcVar1" "$payload" "srcVar2" "$hdiv" "resultVar" "$f" }\n'
            '\t\t"Int" { "srcVar1" "$f" "resultVar" "$f" }\n'
            '\t\t"Divide" { "srcVar1" "$f" "srcVar2" "$hrad" "resultVar" "$f2" }\n'
            '\t\t"Int" { "srcVar1" "$f2" "resultVar" "$f2" }\n'
            '\t\t"Multiply" { "srcVar1" "$f2" "srcVar2" "$hrad" "resultVar" "$f2" }\n'
            '\t\t"Subtract" { "srcVar1" "$f" "srcVar2" "$f2" "resultVar" "$fnew" }\n'
            '\t\t"LessOrEqual" { "srcVar1" "$hit" "srcVar2" "$zero" "resultVar" "$stam" "LessEqualVar" "$fnew" "greaterVar" "$stam" }\n'
            '\t\t"Divide" { "srcVar1" "$stam" "srcVar2" "$two" "resultVar" "$hq" }\n'
            '\t\t"Int" { "srcVar1" "$hq" "resultVar" "$hq" }\n'
            '\t\t"Multiply" { "srcVar1" "$hq" "srcVar2" "$two" "resultVar" "$hq" }\n'
            '\t\t"Subtract" { "srcVar1" "$stam" "srcVar2" "$hq" "resultVar" "$hyp" }\n'
            '\t\t"CurrentTime" { "resultVar" "$time" }\n'
            '\t\t"Subtract" { "srcVar1" "$seq" "srcVar2" "$lastseq" "resultVar" "$chg" }\n'
            '\t\t"Abs" { "srcVar1" "$chg" "resultVar" "$chg" }\n'
            '\t\t"LessOrEqual" { "srcVar1" "$chg" "srcVar2" "$zero" "resultVar" "$start" "LessEqualVar" "$start" "greaterVar" "$time" }\n'
            '\t\t"Equals" { "srcVar1" "$seq" "resultVar" "$lastseq" }\n'
            '\t\t"Subtract" { "srcVar1" "$time" "srcVar2" "$start" "resultVar" "$age" }\n'
            '\t\t"Divide" { "srcVar1" "$age" "srcVar2" "$dur" "resultVar" "$pt" }\n'
            '\t\t"LessOrEqual" { "srcVar1" "$pt" "srcVar2" "$one" "resultVar" "$tc" "LessEqualVar" "$pt" "greaterVar" "$one" }\n'
            '\t\t"Subtract" { "srcVar1" "$one" "srcVar2" "$tc" "resultVar" "$k" }\n'
            '\t\t"Multiply" { "srcVar1" "$k" "srcVar2" "$two" "resultVar" "$b" }\n'
            '\t\t"Subtract" { "srcVar1" "$b" "srcVar2" "$one" "resultVar" "$w" }\n'
            '\t\t"LessOrEqual" { "srcVar1" "$w" "srcVar2" "$zero" "resultVar" "$w" "LessEqualVar" "$zero" "greaterVar" "$w" }\n'
            '\t\t"LessOrEqual" { "srcVar1" "$b" "srcVar2" "$one" "resultVar" "$b" "LessEqualVar" "$b" "greaterVar" "$one" }\n'
            + chan + flicker + '\t}\n}\n')


def plate(w_units, h_units, tw, th, chamfer, corners, fill_a=215, edge=True):
    sx, sy = tw / w_units, th / h_units
    img = Image.new("RGBA", (tw, th), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = chamfer
    pts = [(c * sx, 0) if "tl" in corners else (0, 0), (tw - c * sx, 0) if "tr" in corners else (tw, 0)]
    if "tr" in corners:
        pts.append((tw, c * sy))
    pts.append((tw, th - c * sy) if "br" in corners else (tw, th))
    if "br" in corners:
        pts.append((tw - c * sx, th))
    pts.append((c * sx, th) if "bl" in corners else (0, th))
    if "bl" in corners:
        pts.append((0, th - c * sy))
    if "tl" in corners:
        pts.append((0, c * sy))
    d.polygon(pts, fill=(*PANEL, fill_a))
    if edge:
        inset = 3
        inner = [(min(max(x, inset * sx), tw - inset * sx), min(max(y, inset * sy), th - inset * sy)) for x, y in pts]
        d.line(inner + [inner[0]], fill=(*BONE, 55), width=max(1, int(0.8 * sy)))
        top = sorted((p for p in pts if p[1] <= c * sy + 1), key=lambda p: p[0])
        d.line(top, fill=(*AMBER, 240), width=int(2.5 * sy + 0.5))
    return img

