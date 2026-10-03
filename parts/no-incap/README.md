# No Incap

Human survivors die instead of going down; bots still get incapped.

Owns the one `AllowTakeDamage` wrapper. In order it lets Fort pieces take their hits, holds bullet hits for projectiles, cancels prop crush, runs door-blast, armour and arsenal, and only then judges lethality on the real number: a defib burns, else a bot is hijacked, else the hit kills. Do not add a second wrapper; add a call here.

**Modes:** `hd4l`, `hd4lversus`, `hd4lsurvival`, `hd4lfort`, `hd4lfreebuild`

**Code:** `addon/scripts/vscripts/no_incap.nut`. Knobs sit at the top of each script.
