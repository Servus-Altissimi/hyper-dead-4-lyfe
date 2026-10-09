# Infected Moves

A committed move with a windup and a miss state for every special.

- Tank: rush (0.6 s windup, misses stagger it), slam (200u ring, only hits survivors on the ground), super (four shockwaves in a line), a slam when it lands from a fall, footstep shakes, a fire trail on the rush. Faster windups for a human tank, which goes third person during them. Amped finale tanks (escalation) cool down twice as fast.
- Witch: leaps at the spot her target stood on (0.8 s windup); a miss staggers her.
- Smoker: when the tongue breaks it vanishes to a hidden spot at full health (`HiddenSpot`).
- Boomer: swells after 10 s near survivors, freezes, then bursts in a 300u radius; dying pushes commons away.
- Spitter: leaves a trail of pools after spitting. Charger: leaves fire while charging, 1.3x speed. Hunter: higher pounces, pounce impacts shake.
- Bot specials cannot claw while staggered or in the air. Speeds: specials 1.1x, commons 290, tank 260.

Cooldowns shrink with escalation's progress.

**Modes:** `hd4l`, `hd4lversus`, `hd4lsurvival`

**Code:** `addon/scripts/vscripts/infected_moves.nut` (knobs, shared helpers, the hunter, claw locks and the tick) includes `infected_moves_tank.nut`, `infected_moves_witch.nut`, `infected_moves_smoker.nut`, `infected_moves_boomer.nut`, `infected_moves_spitter.nut` and `infected_moves_charger.nut` (the charger's and the rushing tank's fire). Knobs sit at the top of each script.
