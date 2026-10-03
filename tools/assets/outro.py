import shutil

from PIL import Image, ImageChops, ImageFilter, ImageOps

from .. import config
from ..util import run, vtf, workdir, write
from .palette import BONE

ART = config.part("core") / "art"
SVG = ART / "hd4l_logo.svg"
LOGO = ART / "outro_logo.png"
WIDTH, HEIGHT, PAD = 1024, 256, 12
OUTLINE = 3

CAMPAIGNS = [
    "bloodharvest", "coldstream", "crashcourse", "darkcarnival", "deadair", "deadcenter", "deathtoll",
    "hardrain", "lighthouse", "nomercy", "sacrifice", "swampfever", "theparish", "thepassing",
]

VMT = """UnlitGeneric
{
$translucent 1
$basetexture "vgui/hd4l_outro"
$vertexcolor 1
$vertexalpha 1
$no_fullbright 1
$ignorez 1
$additive 0
}
"""


def ink(img):
    rgba = img.convert("RGBA")
    white = Image.new("RGBA", rgba.size, (255, 255, 255, 255))
    flat = Image.alpha_composite(white, rgba).convert("L")
    alpha = ImageChops.multiply(ImageOps.invert(flat), rgba.getchannel("A"))
    box = alpha.point(lambda v: 255 if v > 24 else 0).getbbox()
    return alpha.crop(box) if box else alpha


def art(img):
    rgba = img.convert("RGBA")
    if rgba.getchannel("A").getextrema()[0] < 250:
        box = rgba.getchannel("A").point(lambda v: 255 if v > 24 else 0).getbbox()
        return rgba.crop(box) if box else rgba
    out = Image.new("RGBA", ink(rgba).size, BONE + (0,))
    out.putalpha(ink(rgba))
    return out


def render_logo():
    if SVG.exists() and shutil.which(config.tool("inkscape")):
        run(config.tool("inkscape"), SVG, "--export-area-drawing", "--export-type=png",
            f"--export-filename={LOGO}", "--export-width=2000")
    return Image.open(LOGO)


def title(logo):
    logo = art(logo)
    scale = min((WIDTH - 2 * PAD) / logo.width, (HEIGHT - 2 * PAD) / logo.height)
    logo = logo.resize((max(1, round(logo.width * scale)), max(1, round(logo.height * scale))), Image.LANCZOS)
    img = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    at = ((WIDTH - logo.width) // 2, (HEIGHT - logo.height) // 2)
    if OUTLINE > 0:
        edge = Image.new("L", (WIDTH, HEIGHT), 0)
        edge.paste(logo.getchannel("A"), at)
        edge = edge.filter(ImageFilter.MaxFilter(OUTLINE * 2 + 1))
        halo = Image.new("RGBA", (WIDTH, HEIGHT), BONE + (0,))
        halo.putalpha(edge)
        img.alpha_composite(halo)
    img.alpha_composite(logo, at)
    return img


def build(out=config.ROOT):
    dest = out / "parts/core/addon/materials/vgui"
    vtf(title(render_logo()), dest / "hd4l_outro.vtf", fmt="dxt5", mips=False, clamp=True)
    for name in CAMPAIGNS:
        write(dest / f"outrotitle_{name}.vmt", VMT)
    print(f"hd4l_outro.vtf {WIDTH}x{HEIGHT}, {len(CAMPAIGNS)} outro titles pointed at it")
