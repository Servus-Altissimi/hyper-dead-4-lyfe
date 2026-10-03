# Projectiles

Bullets fly instead of hitting at once: the stock hit is held and lands when a projectile at 4000 u/s reaches the victim; a victim that moved off the line is missed, anything that steps in takes a fresh hit.

Bullet parry: shove within 0.1 s of a shot from a single-shot gun and its projectiles speed up and explode where they land (80 damage, 160u, infected only), for one extra round.

`python3 -m tools assets particles` builds the tracer particles, one per speed (`TRACER_SPEEDS` in `tools/assets/particles.py` must match `TracerSpeeds`).

**Modes:** `hd4l`, `hd4lversus`, `hd4lsurvival`

**Code:** `addon/scripts/vscripts/projectiles.nut`. Knobs sit at the top of each script.
