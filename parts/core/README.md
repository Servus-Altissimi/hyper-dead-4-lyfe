# Core

The modes, the menu entry and the glue every other part leans on.

- `hd4l_core.nut`: the mode table, `Required` (which parts each mode needs), `Skip` (parts a mode leaves out), `LoadParts()` (includes missing parts and arms every part's hooks), `RearmTick` (re-arms after a director init wipes the callbacks), the pack check that prints missing parts 3 s after round start, the weapon conversions per mode, and shared effects (`Loud`, `Eyes`, `Trail`, `Glow`, `Flash`, `Unfx`). Turns the crosshair and the stock kill feed off for the dot crosshair, except in the plain Fort modes (`Plain()`).
- `last_stand.nut`: The Last Stand maps (`c14m*`) are cursed on purpose: a witch every 10 s (cap 8), a panic every 20 s, pitchfork rain, lightning strikes with a warning arc, an AWP for everyone.
- `hd4l*.nut`, `modes/*.txt`: the five mutations; each mode script calls `LoadParts()` and converts weapon spawns.
- `resource/ui/l4d360ui/*.res`: the main menu entry and the HD4L, Fort and settings flyouts.
- `cfg/hd4l.cfg`: optional client settings (`exec hd4l`). `cfg/addonconfig.cfg`: keeps addons mounted in the HD4L versus modes.
- `particles/`: `hd4l_eyes.pcf` (glowing eyes) and `hd4l_gore.pcf` (red mist), plus the manifest that loads every HD4L pcf.
- `sounds/sound/`: every custom sound, shipped. `sounds-src/` holds the originals (layered from the game's recordings, plus the heartbeat), `sounds-tones/` the synthesized cues; `python3 -m tools assets originals tones sounds` rebuilds them.
- `art/`: the logo, the Workshop image, the menu tile and the outro logo, the sources for `python3 -m tools assets outro menu`.

**Modes:** `hd4l`, `hd4lversus`, `hd4lsurvival`, `hd4lfort`, `hd4lfreebuild`

**Code:** `addon/scripts/vscripts/hd4l.nut`, `addon/scripts/vscripts/hd4l_core.nut`, `addon/scripts/vscripts/hd4lfort.nut`, `addon/scripts/vscripts/hd4lfreebuild.nut`, `addon/scripts/vscripts/hd4lsurvival.nut`, `addon/scripts/vscripts/hd4lversus.nut`, `addon/scripts/vscripts/last_stand.nut`. Knobs sit at the top of each script.
