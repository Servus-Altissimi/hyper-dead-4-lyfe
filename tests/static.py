import os, re, subprocess, sys, glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GAME = os.path.dirname(os.path.expanduser(os.environ.get("L4D2", "~/.local/share/Steam/steamapps/common/Left 4 Dead 2/left4dead2")))
sys.path.insert(0, ROOT)

passed = failed = 0

def check(ok, what, detail=""):
    global passed, failed
    if ok:
        passed += 1
        print("  ok   " + what)
    else:
        failed += 1
        print("  FAIL " + what + (": " + detail if detail else ""))

def rel(p):
    return os.path.relpath(p, ROOT)

def pak_listing(paks, prefix):
    listed = set()
    for pak in paks:
        r = subprocess.run(["vpk", "-l", pak], capture_output=True, text=True)
        listed |= {l.strip().lower() for l in r.stdout.splitlines() if l.startswith(prefix)}
    return listed

def part_scripts():
    out = []
    for p in sorted(glob.glob(os.path.join(ROOT, "parts/*/addon/scripts/vscripts/*.nut"))):
        if "/more-survivors/" in p:
            continue
        out.append(p)
    return out

SCRIPTS = part_scripts()
LOADERS = [p for p in SCRIPTS if os.path.basename(p) in ("mapspawn_addon.nut", "director_base_addon.nut")]
LOGIC = [p for p in SCRIPTS if p not in LOADERS]
SOURCE = {p: open(p, encoding="utf-8", errors="replace").read() for p in LOGIC}

print("== syntax")
for p in SCRIPTS + glob.glob(os.path.join(ROOT, "pack/**/*.nut"), recursive=True) + glob.glob(os.path.join(ROOT, "tests/**/*.nut"), recursive=True):
    r = subprocess.run(["sq", "-c", "-o", "/dev/null", p], capture_output=True, text=True)
    check(r.returncode == 0, "compiles " + rel(p), (r.stdout + r.stderr).strip()[:200])

print("== style")
code = [p for p in glob.glob(os.path.join(ROOT, "**/*"), recursive=True)
        if os.path.isfile(p) and re.search(r"\.(nut|py|sh|res|vmt|txt|cfg)$", p)
        and "/workshop/" not in p and "/build/" not in p and "/legacy/" not in p and "/__pycache__/" not in p and not p.endswith("/OFL.txt")]
dashes = [rel(p) for p in code if re.search("[" + chr(0x2013) + chr(0x2014) + "]", open(p, encoding="utf-8", errors="replace").read())]
check(not dashes, "no em or en dashes in code", ", ".join(dashes[:10]))
allman = [rel(p) for p, s in SOURCE.items() if re.search(r"^function [^\n]*\)\n\{", s, re.M)]
check(not allman, "same-line braces on functions", ", ".join(allman[:10]))

print("== pack wiring")
core = SOURCE[os.path.join(ROOT, "parts/core/addon/scripts/vscripts/hd4l_core.nut")]
required = re.findall(r"(\w+) = (true|false)", core[core.index("Required = {"):core.index("},", core.index("Required = {"))])
tables = dict(re.findall(r"(\w+) = \"(\w+)\"", core[core.index("Tables = {"):core.index("},", core.index("Tables = {"))]))
registered = {}
for p, s in SOURCE.items():
    for name in re.findall(r"::HD4L_Parts\[\"(\w+)\"\] <-", s):
        registered[name] = p
for name, _ in required:
    check(name in registered, "part registers: " + name)
    check(name in tables, "part has a table name: " + name)
    if name in registered and name in tables:
        s = SOURCE[registered[name]]
        t = tables[name]
        check(re.search(r"::%s <- \{" % t, s) is not None, "table ::%s defined in %s" % (t, rel(registered[name])))
        check(re.search(r"function %s::Hook\(\)" % t, s) is not None, "%s has Hook()" % t)
        if "OnGameEvent_" in s:
            check(re.search(r"GameEventCallbacks\[\"hd4l_\w+\"\] <- true", s) is not None, "%s sets its callback marker" % t)
        check("function %s::ModeAllowed()" % t in s or t == "HD4L", "%s gates on ModeAllowed" % t)
markers = {}
for p, s in SOURCE.items():
    for m in re.findall(r"GameEventCallbacks\[\"(hd4l_\w+)\"\] <- true", s):
        markers.setdefault(m, []).append(rel(p))
dupes = {m: ps for m, ps in markers.items() if len(set(ps)) > 1}
check(not dupes, "callback markers unique", str(dupes))

print("== one damage wrapper")
wrappers = [rel(p) for p, s in SOURCE.items() if "scope.AllowTakeDamage <-" in s]
check(sorted(wrappers) == sorted(["parts/no-incap/addon/scripts/vscripts/no_incap.nut", "parts/witch-escort/addon/scripts/vscripts/witch_escort.nut"]),
      "only no-incap and witch-escort wrap AllowTakeDamage", ", ".join(wrappers))

print("== no stock outline glows on infected")
glows = [rel(p) for p, s in SOURCE.items() if re.search(r"m_Glow|SetGlow|m_iGlowType", s) and "door_blast" not in p]
check(not glows, "no glow outline props outside the door blast", ", ".join(glows))

print("== particles")
try:
    from tools.assets import dmx
    systems = set()
    for pcf in glob.glob(os.path.join(ROOT, "parts/*/addon/particles/*.pcf")):
        _, els, _, _ = dmx.load(pcf)
        systems |= {e["name"].decode() for e in els if e["type"] == b"DmeParticleSystemDefinition"}
    used = set()
    for s in SOURCE.values():
        used |= set(re.findall(r"\"(hd4l_[a-z_]+)\"", s)) & {n for n in re.findall(r"\"(hd4l_[a-z_]+)\"", s) if n.startswith(("hd4l_eyes", "hd4l_charger"))}
    for name in sorted(used):
        check(name in systems, "particle exists: " + name)
    for name in ("hd4l_eyes_red", "hd4l_eyes_rage", "hd4l_eyes_white", "hd4l_eyes_hyper"):
        check(name in systems, "eye particle built: " + name)
except Exception as e:
    check(False, "pcf files readable", str(e))
manifest = open(os.path.join(ROOT, "parts/core/addon/particles/particles_manifest.txt")).read()
for pcf in ("hd4l_fx.pcf", "hd4l_eyes.pcf"):
    check("!particles/" + pcf in manifest, "core manifest lists " + pcf)
    check(bool(glob.glob(os.path.join(ROOT, "parts/*/addon/particles/" + pcf))), pcf + " built")

print("== sounds")
custom = set()
stock = set()
for s in SOURCE.values():
    for snd in re.findall(r"\"([\w/]+\.(?:mp3|wav))\"", s):
        (custom if snd.split("/")[0] in ("hyper", "momentum", "glory2") else stock).add(snd)
for snd in sorted(custom):
    check(os.path.isfile(os.path.join(ROOT, "parts/core/sounds/sound", snd)), "custom sound exists: " + snd)
untagged = []
for mp3 in glob.glob(os.path.join(ROOT, "parts/core/sounds/sound/**/*.mp3"), recursive=True):
    r = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format_tags=comment", "-of", "default=nw=1:nk=1", mp3], capture_output=True, text=True)
    if r.stdout.strip() != "hd4l-punch":
        untagged.append(rel(mp3))
check(not untagged, "every custom MP3 went through the sound punch", ", ".join(untagged))
paks = [os.path.join(GAME, d, "pak01_dir.vpk") for d in ("left4dead2", "update", "left4dead2_dlc1", "left4dead2_dlc2", "left4dead2_dlc3")]
paks = [p for p in paks if os.path.isfile(p)]
if paks:
    listed = pak_listing(paks, "sound/")
    for snd in sorted(stock):
        loose = os.path.isfile(os.path.join(GAME, "left4dead2/sound", snd)) or os.path.isfile(os.path.join(GAME, "update/sound", snd))
        check(loose or ("sound/" + snd).lower() in listed, "stock sound exists: " + snd)
else:
    print("  skip stock sounds: game not found")

print("== fort blueprints use stock models")
fort = SOURCE.get(os.path.join(ROOT, "parts/fort/addon/scripts/vscripts/fort.nut"), "")
models = re.findall(r'"(models/[\w/]+\.mdl)"', fort)
check(len(models) > 0, "fort blueprints found")
if paks:
    listed = pak_listing(paks, "models/")
    for m in sorted(set(models)):
        check(m.lower() in listed, "stock model exists: " + m)
else:
    print("  skip fort models: game not found")

print("== per-mode HUD: generator and script agree")
sp = open(os.path.join(ROOT, "tools/assets/hud/panels.py")).read()
hf = open(os.path.join(ROOT, "parts/hyper-feedback/addon/scripts/vscripts/hyper_feedback.nut")).read()
tags = re.search(r"^T_ME, T_MATES = (\d+), \((\d+), (\d+), (\d+)\)", sp, re.M)
me_tag = re.search(r"\tMeTag = (\d+),", hf)
mates = re.search(r"\tMateTags = \[ (\d+), (\d+), (\d+) \],", hf)
if tags and me_tag and mates:
    g = [int(x) for x in tags.groups()]
    check(g[0] == int(me_tag.group(1)) and g[1:4] == [int(x) for x in mates.groups()],
          "team channel tags match between the HUD generator and hyper_feedback.nut")
else:
    check(False, "team channel tags found in both files")

print("== channel tags fit the float")
tags = set()
for vmt in glob.glob(os.path.join(ROOT, "parts/hyper-feedback/addon/materials/hd4l/pn_*.vmt")):
    for t in re.findall(r'"\$my_tag" "(\d+)"', open(vmt).read()):
        tags.add(int(t))
check(bool(tags) and max(tags) * 1000000 + 900000 < 2 ** 24, "every panel tag fits the float (highest %s)" % (max(tags) if tags else "none"))

print("== projectiles: tracer speed and script speed agree")
mk = open(os.path.join(ROOT, "tools/assets/particles.py")).read()
pn = open(os.path.join(ROOT, "parts/projectiles/addon/scripts/vscripts/projectiles.nut")).read()
a_ = re.search(r"^TRACER_SPEED = ([\d.]+)", mk, re.M)
b_ = re.search(r"\tSpeed = ([\d.]+),", pn)
check(bool(a_ and b_) and float(a_.group(1)) == float(b_.group(1)), "the tracer generator's speed equals Projectiles.Speed",
      "%s vs %s" % (a_ and a_.group(1), b_ and b_.group(1)))
sa = re.search(r"^TRACER_SPEEDS = \[([\d, ]+)\]", mk, re.M)
sb = re.search(r"\tTracerSpeeds = \[ ([\d, ]+) \],", pn)
check(bool(sa and sb) and sa.group(1).replace(" ", "") == sb.group(1).replace(" ", ""), "tracer speeds match between the tracer generator and projectiles.nut")
tr = re.search(r'\tTracer = "hd4l_projectile_tracer_(\d+)",', pn)
check(bool(tr and b_) and float(tr.group(1)) == float(b_.group(1)), "default tracer is the default speed's")
check("!particles/hd4l_projectiles.pcf" in manifest, "core manifest lists hd4l_projectiles.pcf")
check(os.path.isfile(os.path.join(ROOT, "parts/projectiles/addon/particles/hd4l_projectiles.pcf")), "hd4l_projectiles.pcf built")

print("RESULT static pass=%d fail=%d" % (passed, failed))
sys.exit(1 if failed else 0)
