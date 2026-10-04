from PIL import Image

from .. import config
from ..util import vtf, write

ART = config.part("core") / "art"
NAMES = ("menu_mode_hd4l", "menu_mode_fort")

VMT = """UnlitGeneric
{{
	$translucent 1
	$basetexture "VGUI\\{name}"
	$vertexcolor 1
	$vertexalpha 1
	$no_fullbright 1
	$ignorez 1
	$additive 0
}}
"""


def build(out=config.ROOT):
    dest = out / "parts/core/addon/materials/vgui"
    for name in NAMES:
        vtf(Image.open(ART / f"{name}.png"), dest / f"{name}.vtf", fmt="dxt5", mips=False)
        write(dest / f"{name}.vmt", VMT.format(name=name))
        print(f"{name}.vtf from art/{name}.png")
