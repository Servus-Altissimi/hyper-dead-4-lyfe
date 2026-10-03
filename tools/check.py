import subprocess
import sys

from . import config


def report(output):
    for line in output.splitlines():
        if not line.startswith("  ok"):
            print(line)


def test():
    ok = True
    static = subprocess.run([sys.executable, str(config.TESTS / "static.py")], capture_output=True, text=True)
    report(static.stdout + static.stderr)
    ok &= static.returncode == 0
    for suite in sorted((config.TESTS / "unit").glob("test_*.nut")):
        unit = subprocess.run([config.tool("sq"), str(suite), str(config.ROOT)], capture_output=True, text=True)
        out = unit.stdout + unit.stderr
        report(out)
        ok &= any(l.startswith("RESULT ") and l.endswith(" fail=0") for l in out.splitlines())
    print("ALL PASS" if ok else "FAILURES")
    return ok
