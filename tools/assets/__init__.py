import importlib

ASSETS = {
    "hud": ("hud", "build", "HUD textures, panel materials, itempickup.res, clientscheme.res"),
    "particles": ("particles", "build", "red fire, eyes, red mist, tracers and the particle manifest"),
    "outro": ("outro", "build", "the end credits title"),
    "menu": ("menu", "build", "the main menu tile"),
    "tones": ("sounds", "tones", "synthesized cue tones (parts/core/sounds-tones)"),
    "originals": ("sounds", "originals", "sounds layered from the game's recordings (parts/core/sounds-src)"),
    "sounds": ("sounds", "shipped", "the shipped sounds: originals with weight and tones (parts/core/sounds/sound)"),
}
DEFAULT = ["hud", "particles", "outro", "menu", "sounds"]


def generator(name):
    module, func, _ = ASSETS[name]
    return getattr(importlib.import_module(f"{__name__}.{module}"), func)
