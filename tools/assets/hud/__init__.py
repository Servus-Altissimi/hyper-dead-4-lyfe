from ... import config
from . import scheme
from .panels import Panels
from .textures import Textures


def build(out=config.ROOT):
    addon = out / "parts/hyper-feedback/addon"
    Textures(addon / "materials/hd4l", addon / "materials/vgui/hud").build()
    Panels(out).build()
    scheme.build(out)
