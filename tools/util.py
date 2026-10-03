import shutil
import subprocess
import tempfile
from contextlib import contextmanager
from pathlib import Path

from . import config


def run(*cmd, quiet=True, text=False):
    return subprocess.run([str(c) for c in cmd], check=True, capture_output=quiet, text=text)


@contextmanager
def workdir():
    path = Path(tempfile.mkdtemp(prefix="hd4l-"))
    try:
        yield path
    finally:
        shutil.rmtree(path, ignore_errors=True)


def write(path, text):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


def game_file(rel, dest, sources=("left4dead2", "update")):
    out = Path(dest) / rel
    for src in sources:
        pak = config.game_root() / src / "pak01_dir.vpk"
        if pak.is_file():
            subprocess.run([config.tool("vpk"), "-x", str(dest), "-f", rel, str(pak)], capture_output=True)
    if not out.is_file():
        raise FileNotFoundError(f"{rel} not found in the game's paks under {config.game_root()}")
    return out


def vtf(image, out, fmt="dxt1", mips=True, clamp=False, normal=False):
    out = Path(out)
    out.parent.mkdir(parents=True, exist_ok=True)
    with workdir() as tmp:
        png = tmp / (out.stem + ".png")
        image.save(png)
        cmd = [config.tool("vtex2"), "convert"]
        if normal:
            cmd.append("-n")
        cmd += ["-f", fmt]
        if mips:
            cmd += ["-m", "1"]
        cmd += ["-q", "-o", str(out)]
        if clamp:
            cmd += ["--clamps", "--clampt"]
        run(*cmd, png)


def vtf_to_png(path, dest):
    path = Path(path)
    copy = Path(dest) / path.name
    shutil.copy(path, copy)
    run(config.tool("vtex2"), "extract", "-f", "png", copy)
    return copy.with_suffix(".png")


def strip_kv_comments(text):
    out = []
    for line in text.split("\n"):
        quoted = False
        cut = None
        for k, ch in enumerate(line):
            if ch == '"':
                quoted = not quoted
            elif not quoted and line.startswith("//", k):
                cut = k
                break
        if cut is None:
            out.append(line.rstrip())
        elif line[:cut].strip():
            out.append(line[:cut].rstrip())
    tidy = []
    for line in out:
        if line == "" and (not tidy or tidy[-1] == ""):
            continue
        tidy.append(line)
    while tidy and tidy[-1] == "":
        tidy.pop()
    return "\n".join(tidy) + "\n"
