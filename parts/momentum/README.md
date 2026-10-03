# Momentum

The survivor movement kit, all on one stamina bar (100, regen 30/s after 0.6 s, triple while boosted).

- Double tap forward: dash (20), or heavy push when standing still (35, kills commons, breaks doors, 300 to a witch), or slide while crouched (15). In the air: flying kick (25); a hit refunds it and gives the kick back, a wall hit gives the kick back.
- Double jump, wall run (hold forward against a wall, drains stamina), wall jump, and a kick within 0.35 s of a wall run is 1.5x faster and hits twice as hard.
- Double tap left or right: side dive with 0.2 s of invulnerability, then a short slow.
- Shoving costs 12 and opens a 0.2 s parry: rocks fly back at their tank (400 damage and a stumble, the tank can bat them back), spit bursts on the spitter.
- Run-up (+25% after 4 s of running), kill stacks (+5% each, up to 6), base speed 1.2x. Hard landings slow and cost stamina unless you roll (crouch before landing).
- HYPER: 3 kick kills in one airtime gives 5 s of boost, refill, and white eyes. Last one standing gets permanent boost and a heartbeat.
- Break free of a pin: 6 forward taps within 1.5 s, costs 60; one failed try locks you out for that pin.
- Teammate shove, ledge vault, doors open on a dash, kicks launch props and arm explosives.
- Infected kit (versus): smoker vanish (reload), hunter wall run, jockey air dash, tank rock parry.

`HyperAnyone()` and `LastStandAnyone()` feed escalation.

**Modes:** `hd4l`, `hd4lversus`, `hd4lsurvival`

**Code:** `addon/scripts/vscripts/momentum.nut` (knobs, stamina, input, the per-player update and the tick) includes `momentum_moves.nut` (dash, heavy, slide, kicks, dive, HYPER), `momentum_wall.nut` (wall run and vault), `momentum_hurt.nut` (hit slow, last stand, pins and break free), `momentum_parry.nut` (rock, spit and tank parries), `momentum_infected.nut` (the versus infected kit) and `momentum_fx.nut` (effects). Knobs sit at the top of each script.
