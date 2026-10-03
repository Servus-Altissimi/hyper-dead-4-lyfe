from PIL import Image

from .. import config
from ..util import vtf, write

ART = config.part("core") / "art" / "menu_mode_hd4l.png"

VMT = """UnlitGeneric
{
	$translucent 1
	$basetexture "VGUI\\menu_mode_hd4l"
	$vertexcolor 1
	$vertexalpha 1
	$no_fullbright 1
	$ignorez 1
	$additive 0
}
"""


def build(out=config.ROOT):
    dest = out / "parts/core/addon/materials/vgui"
    vtf(Image.open(ART), dest / "menu_mode_hd4l.vtf", fmt="dxt5", mips=False)
    write(dest / "menu_mode_hd4l.vmt", VMT)
    print("menu_mode_hd4l.vtf from art/menu_mode_hd4l.png")
