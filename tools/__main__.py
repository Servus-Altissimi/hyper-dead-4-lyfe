import argparse
import sys
from pathlib import Path

from . import check, config, pack


def assets(names, out):
    from .assets import ASSETS, DEFAULT, generator
    for name in names or DEFAULT:
        if name not in ASSETS:
            raise SystemExit(f"unknown asset {name!r}; one of: {', '.join(ASSETS)}")
        print(f"== {name}")
        generator(name)(out)


def describe():
    from .assets import ASSETS, DEFAULT
    for name, (_, _, what) in ASSETS.items():
        print(f"  {name:10} {what}{'' if name in DEFAULT else '  (not in the default set)'}")


def main(argv=None):
    p = argparse.ArgumentParser(prog="python3 -m tools", description="Build, install and test Hyper Dead 4 Lyfe.")
    sub = p.add_subparsers(dest="command", required=True)
    b = sub.add_parser("build", help="merge every part into build/hd4l.vpk")
    b.add_argument("-f", "--force", action="store_true", help="rebuild even if up to date")
    sub.add_parser("install", help="build and copy hd4l.vpk into the game's addons folder")
    sub.add_parser("uninstall", help="remove hd4l.vpk from the game's addons folder")
    sub.add_parser("test", help="static checks and unit suites")
    sub.add_parser("install-tests", help="copy the in-game test scripts and configs into the game")
    sub.add_parser("clean", help="delete build/")
    a = sub.add_parser("assets", help="regenerate built assets (needs the game, vtex2, ffmpeg, rsvg-convert)")
    a.add_argument("names", nargs="*", help="which assets; default: hud particles outro menu sounds")
    a.add_argument("--out", type=Path, default=config.ROOT, help="write into a copy of the repo tree instead")
    a.add_argument("--list", action="store_true", help="list the assets")
    args = p.parse_args(argv)

    if args.command == "build":
        pack.build(args.force)
    elif args.command == "install":
        pack.install()
    elif args.command == "uninstall":
        pack.uninstall()
    elif args.command == "test":
        return 0 if check.test() else 1
    elif args.command == "install-tests":
        pack.install_tests()
    elif args.command == "clean":
        pack.clean()
    elif args.command == "assets":
        if args.list:
            describe()
        else:
            assets(args.names, args.out.resolve())
    return 0


sys.exit(main())
