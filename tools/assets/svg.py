import subprocess
import xml.etree.ElementTree as ET
from io import BytesIO

from PIL import Image

from .. import config

NS = "http://www.w3.org/2000/svg"
ET.register_namespace("", NS)


def element(path, eid):
    for el in ET.parse(path).getroot().iter():
        if el.get("id") == eid:
            return el
    raise KeyError(f"no #{eid} in {path}")


def render(path, show=None, edit=None):
    root = ET.parse(path).getroot()
    if show is not None:
        groups = root.findall(f"{{{NS}}}g")
        if show not in [g.get("id") for g in groups]:
            raise KeyError(f"no group #{show} in {path}")
        for g in groups:
            if g.get("id") != show:
                root.remove(g)
    for el in root.iter():
        for k, v in (edit or {}).get(el.get("id"), {}).items():
            el.set(k, str(v))
    png = subprocess.run([config.tool("rsvg-convert"), "-f", "png"], input=ET.tostring(root), capture_output=True, check=True).stdout
    return Image.open(BytesIO(png)).convert("RGBA")
