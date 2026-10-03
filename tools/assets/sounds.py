import wave

import numpy as np

from .. import config
from ..util import run, workdir

CORE = config.part("core")
SHIPPED = CORE / "sounds" / "sound"
ORIGINALS = CORE / "sounds-src" / "sound"
TONES = CORE / "sounds-tones"
RATE = 44100
TAG = "hd4l-punch"

PUNCH = "player/tank/hit/hulk_punch_1.wav"
POUND1 = "player/tank/hit/pound_victim_1.wav"
POUND2 = "player/tank/hit/pound_victim_2.wav"
BODYFALL = "player/tank/fall/tank_death_bodyfall_01.wav"
CRUNCH2 = "physics/body/body_medium_break2.wav"
CRUNCH3 = "physics/body/body_medium_break3.wav"
CRUNCH4 = "physics/body/body_medium_break4.wav"
SOFT2 = "physics/body/body_medium_impact_soft2.wav"
SOFT5 = "physics/body/body_medium_impact_soft5.wav"
BAT1 = "weapons/bat/bat_impact_world1.wav"
BAT2 = "weapons/bat/bat_impact_world2.wav"
CLANG = "physics/metal/metal_solid_impact_hard1.wav"
PAN = "weapons/pan/melee_frying_pan_01.wav"
DRYFIRE = "weapons/clipempty_pistol.wav"
SHELL = "weapons/shotgun/gunother/shotgun_load_shell_2.wav"
PUMP = "weapons/shotgun/gunother/shotgun_pump_1.wav"

LAYERS = {
    "hit": ([(SOFT2, 0, 0, 1.15, 0.10, 2500), (PUNCH, -14, 0, 1.3, 0.06, 1200)], False),
    "hit_head": ([(SOFT5, 0, 0, 1.1, 0.12, 2800), (BAT1, -6, 0, 0.9, 0.10, 3000)], False),
    "kill": ([(CRUNCH2, 0, 0, 1.0, 0.30, 3500), (PUNCH, -3, 0, 0.9, 0.25, 1500)], True),
    "headshot": ([(BAT2, -3, 0, 0.85, 0.15, 3200), (CRUNCH3, 0, 10, 0.95, 0.35, 3500), (PUNCH, -2, 0, 0.85, 0.3, 1500)], True),
    "glory": ([(PUNCH, 0, 0, 0.8, 0.4, 1800), (POUND2, -2, 0, 0.85, 0.45, 2500), (CRUNCH4, -1, 20, 0.9, 0.45, 3500),
               (BODYFALL, -3, 90, 0.9, 0.6, 1200)], True),
    "heavy": ([(POUND1, 0, 0, 0.85, 0.4, 2500), (CRUNCH2, -4, 10, 0.9, 0.3, 3000), (BODYFALL, -4, 40, 1.0, 0.5, 1200)], True),
    "parry": ([(CLANG, 0, 0, 0.8, 0.45, 4000), (PAN, -6, 0, 0.7, 0.4, 3000), (PUNCH, -6, 0, 0.9, 0.25, 1500)], False),
    "chain": ([(PUMP, 0, 0, 0.95, 0.28, 4000)], False),
    "deny": ([(DRYFIRE, 0, 0, 0.85, 0.15, 3500)], False),
    "stamina": ([(SHELL, -2, 0, 0.9, 0.25, 3500)], False),
}

TARGETS = {
    "hit": ["hyper/hit"], "hit_head": ["hyper/hit_head"], "kill": ["hyper/kill"], "headshot": ["hyper/headshot"],
    "glory": ["hyper/glory", "glory2/finisher"], "heavy": ["hyper/heavy", "momentum/heavy"],
    "parry": ["hyper/parry", "momentum/parry"], "chain": ["hyper/chain", "momentum/chain"],
    "deny": ["hyper/deny", "momentum/deny"], "stamina": ["hyper/stamina", "momentum/stamina"],
}

KICK = {
    "hit": (0.0, 0.14, None), "hit_head": (0.2, 0.16, 4), "kill": (0.7, 0.35, 4), "headshot": (0.8, 0.4, 4),
    "glory": (0.9, 0.75, 1), "finisher": (0.9, 0.75, 1), "heavy": (0.9, 0.55, 1), "parry": (0.5, 0.5, 4),
    "chain": (0.0, 0.32, None), "deny": (0.0, 0.18, None), "stamina": (0.0, 0.3, None), "heartbeat": (0.0, 0.6, None),
}
KICK_DEFAULT = (0.5, 0.3, None)
UNDER = 9


def ffmpeg(*args):
    run(config.tool("ffmpeg"), "-v", "error", "-y", *args)


def forge(game, name, layers, grit, out):
    inputs = []
    chains, labels = [], []
    for i, (path, gain, delay, rate, trim, lowpass) in enumerate(layers):
        inputs += ["-i", game / path]
        chains.append(f"[{i}:a]aformat=channel_layouts=mono,aresample={RATE},asetrate={RATE}*{rate},aresample={RATE},"
                      f"atrim=0:{trim},afade=t=out:st={max(0.0, trim - 0.04)}:d=0.04,lowpass=f={lowpass},"
                      f"volume={gain}dB,adelay={delay}[l{i}]")
        labels.append(f"[l{i}]")
    mix = "".join(labels) + f"amix=inputs={len(layers)}:duration=longest:normalize=0"
    if grit:
        mix += ",asoftclip=type=tanh:threshold=0.7"
    out.parent.mkdir(parents=True, exist_ok=True)
    ffmpeg(*inputs, "-filter_complex", ";".join(chains) + ";" + mix + ",alimiter=limit=0.95:level=disabled",
           "-codec:a", "libmp3lame", "-b:a", "160k", out)


def originals(out=config.ROOT):
    game = config.l4d2() / "sound"
    dest = out / ORIGINALS.relative_to(config.ROOT)
    for name, (layers, grit) in LAYERS.items():
        for target in TARGETS[name]:
            forge(game, name, layers, grit, dest / f"{target}.mp3")
            print(f"forged {target}")


def peak(path):
    r = run(config.tool("ffmpeg"), "-hide_banner", "-nostats", "-i", path, "-af", "volumedetect", "-f", "null", "-", text=True)
    for line in r.stderr.splitlines():
        if "max_volume:" in line:
            return float(line.split("max_volume:")[1].split("dB")[0])
    raise RuntimeError(f"no peak for {path}")


def punch(src, tone, out, tmp):
    name = src.stem
    weight, tail, lift = KICK.get(name, KICK_DEFAULT)
    body = tmp / "body.mp3"
    kick = f"aevalsrc='{weight}*sin(2*PI*(45*t+65*0.06*(1-exp(-t/0.06))))*exp(-t/0.09)':s={RATE}:d=0.4"
    ffmpeg("-i", src, "-f", "lavfi", "-i", kick, "-filter_complex",
           f"[0:a]aformat=sample_rates={RATE}:channel_layouts=mono,asetrate={RATE}*0.85,aresample={RATE},lowpass=f=4500,"
           f"equalizer=f=90:t=q:w=1:g=8,atrim=0:{tail},afade=t=out:st={max(0.0, tail - 0.08)}:d=0.08[body];"
           f"[1:a]aformat=sample_rates={RATE}:channel_layouts=mono[sub];"
           "[body][sub]amix=inputs=2:duration=longest:weights='1 1':normalize=0,volume=10dB,"
           "alimiter=limit=0.95:attack=1:release=40:level=disabled",
           "-codec:a", "libmp3lame", "-b:a", "128k", "-metadata", f"comment={TAG}", body)
    out.parent.mkdir(parents=True, exist_ok=True)
    if lift is None or not tone.is_file():
        body.replace(out)
        return
    gain = -1.0 - peak(tone) + lift
    ffmpeg("-i", body, "-i", tone, "-filter_complex",
           f"[0:a]volume=-{UNDER}dB[b];[1:a]aformat=sample_rates={RATE}:channel_layouts=mono,volume={gain}dB[t];"
           "[b][t]amix=inputs=2:duration=longest:normalize=0,alimiter=limit=0.95:level=disabled",
           "-codec:a", "libmp3lame", "-b:a", "128k", "-metadata", f"comment={TAG}", out)


def shipped(out=config.ROOT):
    dest = out / SHIPPED.relative_to(config.ROOT)
    with workdir() as tmp:
        for src in sorted(ORIGINALS.rglob("*.mp3")):
            rel = src.relative_to(ORIGINALS)
            tone = TONES / ("glory.mp3" if src.stem == "finisher" else f"{src.stem}.mp3")
            punch(src, tone, dest / rel, tmp)
            print(f"punched {rel}")


def seconds(ms):
    return np.arange(int(RATE * ms / 1000)) / RATE


def envelope(x, attack=0.001, decay=0.05):
    return np.minimum(1, x / attack) * np.exp(-(x - attack).clip(0) / decay)


def sweep(ms, f0, f1=None, decay=0.05, shape="sine"):
    x = seconds(ms)
    f1 = f0 if f1 is None else f1
    phase = 2 * np.pi * np.cumsum(f0 + (f1 - f0) * (x / x[-1])) / RATE
    wave_ = np.sin(phase) if shape == "sine" else np.sign(np.sin(phase)) * 0.5
    return wave_ * envelope(x, decay=decay)


def noise(ms, decay=0.004, lp=0.5):
    x = seconds(ms)
    n = np.random.default_rng(7).standard_normal(len(x))
    for _ in range(3):
        n = np.convolve(n, [lp, 1 - lp], "same")
    return n * envelope(x, decay=decay)


def later(ms, sig):
    return np.concatenate([np.zeros(int(RATE * ms / 1000)), sig])


def mix(*parts):
    out = np.zeros(max(len(p) for p in parts))
    for p in parts:
        out[:len(p)] += p
    return out


SYNTH = {
    "hit": (lambda: mix(noise(40, 0.003), sweep(50, 1500, 1200, 0.012)), 0.5),
    "hit_head": (lambda: mix(noise(40, 0.003), sweep(45, 1900, decay=0.012), later(35, sweep(60, 2600, decay=0.02))), 0.55),
    "kill": (lambda: mix(noise(60, 0.006, 0.8), sweep(140, 130, 60, 0.06), sweep(30, 3000, 1500, 0.006) * 0.4), 0.8),
    "headshot": (lambda: mix(noise(60, 0.006, 0.8), sweep(140, 130, 60, 0.06), later(20, sweep(220, 2637, 2637, 0.09) * 0.6),
                             later(20, sweep(220, 3951, 3951, 0.05) * 0.25)), 0.85),
    "glory": (lambda: mix(noise(120, 0.02, 0.9), sweep(320, 90, 40, 0.12), sweep(300, 880, 830, 0.18, "square") * 0.25,
                          later(60, sweep(240, 1760, 1740, 0.12) * 0.35)), 0.9),
    "heavy": (lambda: mix(noise(80, 0.012, 0.9), sweep(200, 110, 45, 0.09), sweep(40, 600, 200, 0.02) * 0.5), 0.85),
    "deny": (lambda: mix(sweep(50, 320, 300, 0.03, "square"), later(60, sweep(50, 260, 240, 0.03, "square"))), 0.4),
    "chain": (lambda: mix(sweep(60, 1200, 1500, 0.04), later(50, sweep(90, 1800, 2400, 0.05))), 0.5),
    "stamina": (lambda: mix(sweep(80, 900, 1400, 0.05), noise(20, 0.003) * 0.3), 0.35),
    "parry": (lambda: mix(noise(30, 0.004, 0.9), sweep(260, 1320, 1290, 0.10) * 0.6, sweep(220, 2094, 2060, 0.07) * 0.35,
                          sweep(120, 420, 380, 0.05) * 0.5), 0.8),
}


def tones(out=config.ROOT):
    dest = out / TONES.relative_to(config.ROOT)
    dest.mkdir(parents=True, exist_ok=True)
    with workdir() as tmp:
        for name, (make, gain) in SYNTH.items():
            sig = make()
            sig = sig / max(1e-6, np.abs(sig).max()) * gain
            wav = tmp / f"{name}.wav"
            with wave.open(str(wav), "wb") as w:
                w.setnchannels(1)
                w.setsampwidth(2)
                w.setframerate(RATE)
                w.writeframes((sig * 32767).astype("<i2").tobytes())
            ffmpeg("-i", wav, "-codec:a", "libmp3lame", "-b:a", "96k", "-ar", str(RATE), "-ac", "1", dest / f"{name}.mp3")
            print(f"tone {name}: {len(sig) / RATE * 1000:.0f} ms")
