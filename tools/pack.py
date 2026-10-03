import shutil
from pathlib import Path

from . import config
from .util import run

OUT = config.BUILD / "hd4l.vpk"
TREE = config.BUILD / "tree"
SOUNDS = config.part("core") / "sounds" / "sound"


def sources():
    files = [p for part in config.parts() for p in (part / "addon").rglob("*") if p.is_file()]
    files += [p for p in config.PACK.rglob("*") if p.is_file()]
    files += [p for p in SOUNDS.rglob("*") if p.is_file()]
    return files


def stale():
    if not OUT.is_file():
        return True
    built = OUT.stat().st_mtime
    return any(p.stat().st_mtime > built for p in sources())


def build(force=False):
    if not force and not stale():
        print(f"{OUT.relative_to(config.ROOT)} is up to date")
        return OUT
    shutil.rmtree(TREE, ignore_errors=True)
    OUT.unlink(missing_ok=True)
    TREE.mkdir(parents=True)
    for part in config.parts():
        shutil.copytree(part / "addon", TREE, dirs_exist_ok=True)
    shutil.copytree(SOUNDS, TREE / "sound", dirs_exist_ok=True)
    shutil.copytree(config.PACK, TREE, dirs_exist_ok=True)
    run(config.tool("vpk"), OUT, "-c", TREE, "-cv", "1")
    count = sum(1 for p in TREE.rglob("*") if p.is_file())
    print(f"{OUT.relative_to(config.ROOT)}: {count} files, {OUT.stat().st_size / 1e6:.1f} MB")
    return OUT


def addons():
    path = config.l4d2() / "addons"
    if not path.is_dir():
        raise SystemExit(f"no addons folder at {path}; set L4D2 to the game's left4dead2 folder")
    return path


def install():
    vpk = build()
    dest = addons()
    shutil.copy(vpk, dest / "hd4l.vpk")
    shutil.copy(config.PACK / "addonimage.jpg", dest / "hd4l.jpg")
    print(f"installed to {dest}")


def uninstall():
    dest = addons()
    for name in ("hd4l.vpk", "hd4l.jpg"):
        (dest / name).unlink(missing_ok=True)
    print(f"removed from {dest}")


def install_tests():
    game = config.l4d2()
    for pattern, sub in (("*.nut", "scripts/vscripts"), ("*.cfg", "cfg")):
        dest = game / sub
        dest.mkdir(parents=True, exist_ok=True)
        for f in (config.TESTS / "game").glob(pattern):
            shutil.copy(f, dest / f.name)
    print("installed: exec hd4l_test_map, then exec hd4l_test, then condump")


def clean():
    shutil.rmtree(config.BUILD, ignore_errors=True)
