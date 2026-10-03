import os
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PARTS = ROOT / "parts"
PACK = ROOT / "pack"
BUILD = ROOT / "build"
TESTS = ROOT / "tests"

SKIP_PARTS = set()

DEFAULT_L4D2 = Path.home() / ".local/share/Steam/steamapps/common/Left 4 Dead 2/left4dead2"


def l4d2():
    return Path(os.environ.get("L4D2", DEFAULT_L4D2)).expanduser()


def game_root():
    return l4d2().parent


def tool(name):
    return os.environ.get(name.upper().replace("-", "_"), name)


def part(name):
    return PARTS / name


def parts():
    return sorted(p for p in PARTS.iterdir() if (p / "addon").is_dir() and p.name not in SKIP_PARTS)
