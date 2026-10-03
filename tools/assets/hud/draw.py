from PIL import ImageChops, ImageFilter

from ... import config
from ..palette import BONE, EMBER, SHADE
from ..svg import element, render

ART = config.part("hyper-feedback") / "art" / "hud"
TANK_LEVELS = 20

DIRS = ["front", "frontright", "right", "backright", "back", "backleft", "left", "frontleft"]
SIDES = ["left", "right", "front", "back"]
MARKS = ["hit", "hit_head", "kill", "headshot", "parry"]


def hexc(rgb):
    return "#%02x%02x%02x" % rgb


def screen(name, show=None, edit=None):
    return render(ART / f"{name}.svg", show, edit).convert("RGB")


def finish(img):
    halo = img.filter(ImageFilter.GaussianBlur(7)).point(lambda v: min(255, int(v * 0.9)))
    return ImageChops.add(img, halo)


def mark(name):
    return screen(f"mark_{name}")


def damage_arc(direction):
    return screen("arcs", show=direction)


def stamina_bar(filled, hyper):
    edit = {f"seg{i + 1}": {"fill": hexc((EMBER if hyper else BONE) if i < filled else SHADE)} for i in range(5)}
    for bracket in ("bracket1", "bracket2"):
        edit[bracket] = {"display": "inline" if hyper else "none"}
    return screen("stamina", edit=edit)


def tank_bar(level):
    fill = element(ART / "tank.svg", "fill")
    width = float(fill.get("width")) * (level + 1) / TANK_LEVELS
    end = float(fill.get("x")) + width
    return screen("tank", edit={"fill": {"width": width}, "marker": {"x1": end, "x2": end}})


def struggle(taps, colour, chevron_colour):
    edit = {f"chevron{i}": {"stroke": hexc(chevron_colour)} for i in range(1, 5)}
    edit.update({f"seg{i + 1}": {"fill": hexc(colour if i < taps else SHADE)} for i in range(6)})
    return screen("struggle", edit=edit)


def side_cue(side):
    return screen("cues", show=side)


def jump_cue():
    return screen("cues", show="jump")


def spike_mark():
    return screen("spike")
