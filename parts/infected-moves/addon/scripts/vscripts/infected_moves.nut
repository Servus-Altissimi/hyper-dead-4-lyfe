const TEAM_INFECTED = 3;
const ZOMBIE_SMOKER = 1;
const ZOMBIE_BOOMER = 2;
const ZOMBIE_HUNTER = 3;
const ZOMBIE_SPITTER = 4;
const ZOMBIE_CHARGER = 6;
const ZOMBIE_TANK = 8;
const FL_ONGROUND = 1;
const DMG_CLUB = 128;
const DMG_BLAST = 64;
const DMG_BURN = 8;
const DMG_STAGGER = 33554432;
const IN_ATTACK2 = 2048;
const ZOMBIE_JOCKEY = 5;

::InfectedMoves <- {
	Versus = true,
	Survival = true,
	Stock = false,
	Files = [ "infected_moves_tank", "infected_moves_witch", "infected_moves_smoker", "infected_moves_boomer", "infected_moves_spitter", "infected_moves_charger" ],

	Tank = true,
	Witch = true,
	Smoker = true,
	Boomer = true,
	Spitter = true,
	Hunter = true,
	Charger = true,

	TankRushFire = true,

	RushMin = 500.0, RushMax = 1200.0, RushCooldown = 5.0, RushWindup = 0.6, RushSpeed = 1100.0, RushTime = 0.9,
	RushHitRange = 100.0, RushCarry = 250.0, RushDamage = 25, RushKnock = 350.0, RushStagger = 1.0,
	SlamRange = 250.0, SlamCooldown = 4.0, SlamWindup = 0.7, SlamRadius = 200.0, SlamDamage = 15, SlamLock = 0.5,
	SuperMin = 350.0, SuperMax = 1000.0, SuperChance = 60, SuperWindup = 0.6, SuperWaves = 4, SuperSpacing = 140.0,
	SuperDelay = 0.5, SuperRadius = 150.0, SuperLock = 0.6,
	FallSpeed = 400.0,

	ThreatCooldown = 0.6,

	RetargetSeconds = 2.0,

	TankCvars = { z_tank_speed = 260, z_tank_throw_interval = 3.5 },

	SpecialSpeed = 1.1,
	ClassSpeed = { [6] = 1.3 },
	SpecialCvars = { z_charge_max_speed = 750 },
	CommonCvars = { z_speed = 290 },

	HumanTank = true,
	RushKey = 8192,
	SuperKey = 32,

	HumanKnobs = { RushWindup = 0.25, RushSpeed = 1900.0, RushTime = 0.75, RushDamage = 35, RushKnock = 500.0,
	               SlamWindup = 0.4, SlamRadius = 240.0, SlamDamage = 25,
	               SuperWindup = 0.35, SuperRadius = 130.0, SuperDelay = 0.12, SuperWaves = 8, SuperSpacing = 110.0 },

	HumanThirdPerson = true,

	AmpCooldown = 0.5,
	AmpKnobs = { RushWindup = 0.4, RushSpeed = 1400.0, RushDamage = 30, RushKnock = 450.0,
	             SlamWindup = 0.5, SlamRadius = 240.0, SlamDamage = 20, SuperWaves = 6, SuperDelay = 0.35 },

	LeapMin = 250.0, LeapMax = 700.0, LeapCooldown = 4.0, LeapWindup = 0.8, LeapSpeed = 700.0, LeapLift = 300.0,
	LeapHitRange = 80.0, LeapDamage = 20, LeapKnock = 300.0, LeapAir = 0.7,

	PhantomMin = 400.0, PhantomMax = 800.0, PhantomDelay = 0.3,

	TankSteps = true, StepStride = 90.0, StepShake = 2.5, StepShakeRadius = 450.0,
	StepSound = "physics/concrete/boulder_impact_hard1.wav",

	BoomerPop = true, PopRadius = 260.0, PopPush = 450.0, PopLift = 150.0,
	PopSound = "physics/concrete/boulder_impact_hard2.wav",
	PounceScars = true, ScarSound = "player/tank/fall/tank_death_bodyfall_01.wav",

	SwellSeconds = 10.0, SwellRange = 400.0, RetchSeconds = 2.0, BurstRadius = 300.0,

	TrailSeconds = 3.0, TrailStep = 0.6, TrailLife = 5.0, TrailRadius = 70.0, TrailDamage = 1, TrailPeriod = 0.3,

	TrailEffect = "spitter_areaofdenial",

	LungePower = 900, LungeUp = 220,

	FireSeconds = 8.0, FireStep = 24.0, FireRadius = 40.0, FirePeriod = 0.3,
	StaggerLock = true,
	LockInterval = 0.03,
	LockRelease = 0.5,

	FireDamage = 2,
	FireEffect = "hd4l_charger_fire",

	Sounds = {
		tank_yell = [ "player/tank/voice/yell/tank_yell_01.wav", "player/tank/voice/yell/tank_yell_02.wav", "player/tank/voice/yell/tank_yell_03.wav" ],
		tank_hit = [ "player/tank/hit/pound_victim_1.wav", "player/tank/hit/pound_victim_2.wav" ],
		rock = [ "physics/concrete/boulder_impact_hard1.wav", "physics/concrete/boulder_impact_hard2.wav" ],
		witch = [ "npc/witch/voice/attack/female_shriek_1.wav", "npc/witch/voice/attack/female_shriek_2.wav" ],
		smoker = [ "player/smoker/voice/warn/smoker_warn_01.wav", "player/smoker/voice/warn/smoker_warn_03.wav" ],
		boomer = [ "player/boomer/voice/warn/male_boomer_warning_01.wav", "player/boomer/voice/warn/male_boomer_warning_12.wav" ]
	},
	Particles = [ "tank_ground_pound", "tank_rock_throw_impact", "tank_breath", "smoker_smokecloud", "boomer_vomit", "spitter_areaofdenial_spot", "spitter_areaofdenial", "hunter_leap_dust" ],

	Tanks = {},
	Witches = {},
	Boomers = {},
	Trails = [],
	Trailing = {},
	Fires = [],
	Charging = {},
	LastFireTick = 0.0,
	Paced = {},
	ClawLocks = {},
	LastTrailTick = 0.0,
	Generation = 0
}

function InfectedMoves::Log(msg) {
	printl("[InfectedMoves] " + msg);
}

function InfectedMoves::ModeAllowed() {
	local mode = "";
	try { mode = Director.GetGameMode(); } catch (e) {}
	if ((mode == "hd4lfort" || mode == "hd4lfreebuild"))
		return Stock;
	if (mode == "hd4lsurvival")
		return Survival;
	if (mode != "hd4l" && mode != "hd4lversus")
		return false;
	return Versus || mode == "hd4l";
}

function InfectedMoves::Precache() {
	foreach (name, list in Sounds)
		foreach (path in list)
			PrecacheSound(path);
	foreach (effect in Particles)
		PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = effect, origin = Vector(0, 0, 0), start_active = 1 });
	PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = FireEffect, origin = Vector(0, 0, 0), start_active = 1 });
	foreach (snd in [ PopSound, ScarSound, StepSound ])
		PrecacheSound(snd);
}

function InfectedMoves::OnGameEvent_lunge_pounce(params) {
	if (!PounceScars || !ModeAllowed() || !("victim" in params))
		return;
	local victim = null;
	try { victim = GetPlayerFromUserID(params.victim); } catch (e) { return; }
	if (victim == null || !victim.IsValid())
		return;
	local pos = victim.GetOrigin();
	Particle("hunter_leap_dust", pos, 1.5);
	Particle("hunter_leap_dust", pos + Vector(0, 0, 8), 1.5);
	ScreenShake(pos, 5.0, 30.0, 0.35, 300.0, 0, false);
	Loud(ScarSound, victim, 100, 115);
}

function InfectedMoves::Pick(list) {
	return list[RandomInt(0, list.len() - 1)];
}

function InfectedMoves::Sound(ent, list) {
	Loud(Pick(list), ent, 110, RandomInt(85, 97));
}

function InfectedMoves::Loud(sound, ent, level, pitch = 100) {
	if (("HD4L" in getroottable()) && ("Loud" in ::HD4L))
		try { ::HD4L.Loud(sound, ent, level, pitch); return; } catch (e) {}
	EmitSoundOn(sound, ent);
}

function InfectedMoves::Particle(effect, pos, life) {
	local gfx = SpawnEntityFromTable("info_particle_system", { effect_name = effect, origin = pos, start_active = 1 });
	if (gfx != null)
		DoEntFire("!self", "Kill", "", life, null, gfx);
	return gfx;
}

function InfectedMoves::Alive(ent) {
	if (ent == null || !ent.IsValid() || ent.GetHealth() <= 0)
		return false;
	try { return !ent.IsDead(); } catch (e) { return true; }
}

function InfectedMoves::Dying(ent) {
	if (!Alive(ent))
		return true;
	try { return ent.IsIncapacitated() || ent.IsDying(); } catch (e) { return false; }
}

function InfectedMoves::IsSpecial(ent, zombieType) {
	return Alive(ent) && ent.GetClassname() == "player" && NetProps.GetPropInt(ent, "m_iTeamNum") == TEAM_INFECTED
		&& !ent.IsGhost() && (zombieType < 0 || ent.GetZombieType() == zombieType);
}

function InfectedMoves::Survivors() {
	local list = [];
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null)
		if (p.IsSurvivor() && !p.IsDead())
			list.append(p);
	return list;
}

function InfectedMoves::Nearest(ent, list) {
	local best = null;
	local bestDist = 999999.0;
	foreach (s in list) {
		local d = (s.GetOrigin() - ent.GetOrigin()).Length();
		if (d < bestDist) {
			bestDist = d;
			best = s;
		}
	}
	return { ent = best, dist = bestDist };
}

function InfectedMoves::Flat(v) {
	local f = Vector(v.x, v.y, 0);
	if (f.Length() < 0.001)
		return Vector(1, 0, 0);
	f.Norm();
	return f;
}

function InfectedMoves::Ground(pos, ignore) {
	local trace = { start = pos + Vector(0, 0, 60), end = pos - Vector(0, 0, 300) };
	if (ignore != null)
		trace.ignore <- ignore;
	TraceLine(trace);
	return trace.hit ? trace.pos : null;
}

function InfectedMoves::Threat() {
	if (("Escalation" in getroottable()) && ("Progress" in ::Escalation))
		try { return ::Escalation.Progress(); } catch (e) {}
	return 0.0;
}

function InfectedMoves::Cooldown(seconds) {
	return seconds * (1.0 - (1.0 - ThreatCooldown) * Threat());
}

function InfectedMoves::Freeze(ent, on) {
	try { NetProps.SetPropInt(ent, "m_MoveType", on ? 0 : 2); } catch (e) {}
	if (on)
		try { ent.SetVelocity(Vector(0, 0, 0)); } catch (e) {}
}

function InfectedMoves::Gesture(ent, name) {
	try {
		local seq = ent.LookupSequence(name);
		if (seq < 0)
			return;
		NetProps.SetPropFloatArray(ent, "m_NetGestureStartTime", Time(), 5);
		NetProps.SetPropIntArray(ent, "m_NetGestureSequence", seq, 5);
		NetProps.SetPropIntArray(ent, "m_NetGestureActivity", 1, 5);
	} catch (e) {}
}

function InfectedMoves::Impact(pos, radius, damage, attacker, effect) {
	Particle(effect, pos, 1.0);
	ScreenShake(pos, 12.0, 40.0, 1.0, radius * 2.0, 0, false);
	local push = SpawnEntityFromTable("env_physexplosion", { magnitude = "800", radius = radius.tostring(), spawnflags = "1", origin = pos });
	if (push != null) {
		DoEntFire("!self", "Explode", "", 0, null, push);
		DoEntFire("!self", "Kill", "", 0.1, null, push);
	}
	foreach (s in Survivors()) {
		if ((s.GetOrigin() - pos).Length() > radius || fabs(s.GetOrigin().z - pos.z) > 60.0)
			continue;
		if (!(NetProps.GetPropInt(s, "m_fFlags") & FL_ONGROUND))
			continue;
		try { s.Stagger(pos); } catch (e) {}
		s.TakeDamage(damage, DMG_CLUB, attacker != null && attacker.IsValid() ? attacker : Entities.First());
		Sound(s, Sounds.tank_hit);
	}
	local ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "infected", pos, radius)) != null) {
		if (ent.GetHealth() <= 0)
			continue;
		local away = Flat(ent.GetOrigin() - pos);
		ent.ApplyAbsVelocityImpulse(away * 400 + Vector(0, 0, 300));
		ent.TakeDamage(0, DMG_STAGGER, Entities.First());
	}
}

function InfectedMoves::HighPounce() {
	if (!Hunter)
		return;
	Convars.SetValue("z_lunge_power", LungePower);
	Convars.SetValue("z_lunge_up", LungeUp);
}

function InfectedMoves::Pace(p) {
	local index = p.GetEntityIndex();
	if (!(index in Paced))
		Paced[index] <- { applied = 0.0, engine = 1.0 };
	local b = Paced[index];
	local cur = 1.0;
	try { cur = NetProps.GetPropFloat(p, "m_flLaggedMovementValue"); } catch (e) { return; }
	if (fabs(cur - b.applied) >= 0.001)
		b.engine = cur;
	local zt = p.GetZombieType();
	local want = b.engine * ((zt in ClassSpeed) ? ClassSpeed[zt] : SpecialSpeed);
	if (fabs(want - cur) > 0.001) {
		NetProps.SetPropFloat(p, "m_flLaggedMovementValue", want);
		b.applied = want;
	}
}

function InfectedMoves::Tick(generation) {
	if (generation != Generation)
		return;
	if (ModeAllowed()) {
		local now = Time();
		try {
			local p = null;
			while ((p = Entities.FindByClassname(p, "player")) != null) {
				if (Tank && IsSpecial(p, ZOMBIE_TANK)) {
					if (Dying(p))
						StopTank(p.GetEntityIndex());
					else
						TankTick(p, now);
				}
				else if (Boomer && IsSpecial(p, ZOMBIE_BOOMER) && IsPlayerABot(p))
					BoomerTick(p, now);
				if (SpecialSpeed != 1.0 && IsSpecial(p, -1) && p.GetZombieType() != ZOMBIE_TANK)
					Pace(p);
			}
			foreach (index, w in clone Witches)
				WitchTick(w, index, now);
			if (Spitter)
				TrailTick(now);
			if (Charger || TankRushFire)
				ChargerTick(now);
		} catch (e) { Log("tick failed: " + e); }
	}
	DoEntFire("!self", "RunScriptCode", "::InfectedMoves.Tick(" + generation + ")", 0.1, null, Entities.First());
}

function InfectedMoves::ClawLocked(p) {
	local stagger = -1.0;
	try { stagger = NetProps.GetPropFloatArray(p, "m_staggerTimer", 1); } catch (e) {}
	if (stagger > -1.0)
		return true;
	local zt = p.GetZombieType();
	return (zt == ZOMBIE_HUNTER || zt == ZOMBIE_JOCKEY) && !(NetProps.GetPropInt(p, "m_fFlags") & FL_ONGROUND);
}

function InfectedMoves::LockClaw(p, on) {
	local bits = NetProps.GetPropInt(p, "m_afButtonDisabled");
	local want = on ? (bits | IN_ATTACK2) : (bits & ~IN_ATTACK2);
	if (want != bits)
		NetProps.SetPropInt(p, "m_afButtonDisabled", want);
}

function InfectedMoves::LockTick(generation) {
	if (generation != Generation)
		return;
	if (ModeAllowed() && StaggerLock) {
		local now = Time();
		try {
			local seen = {};
			local p = null;
			while ((p = Entities.FindByClassname(p, "player")) != null) {
				if (!IsPlayerABot(p) || !IsSpecial(p, -1) || p.GetZombieType() == ZOMBIE_TANK)
					continue;
				local index = p.GetEntityIndex();
				seen[index] <- true;
				if (ClawLocked(p)) {
					ClawLocks[index] <- now + LockRelease;
					LockClaw(p, true);
				} else if ((index in ClawLocks) && now >= ClawLocks[index]) {
					delete ClawLocks[index];
					LockClaw(p, false);
				}
			}
			foreach (index, until in clone ClawLocks)
				if (!(index in seen)) {
					delete ClawLocks[index];
					local ent = EntIndexToHScript(index);
					if (ent != null && ent.IsValid())
						LockClaw(ent, false);
				}
		} catch (e) { Log("claw lock failed: " + e); }
	}
	DoEntFire("!self", "RunScriptCode", "::InfectedMoves.LockTick(" + generation + ")", LockInterval, null, Entities.First());
}

function InfectedMoves::OnGameEvent_round_start(params) {
	Tanks = {};
	Witches = {};
	Boomers = {};
	Trails = [];
	Trailing = {};
	Fires = [];
	Charging = {};
	Paced = {};
	ClawLocks = {};
	Generation++;
	if (ModeAllowed()) {
		HighPounce();
		if (Tank)
			foreach (name, value in TankCvars)
				Convars.SetValue(name, value);
		foreach (name, value in SpecialCvars)
			Convars.SetValue(name, value);
		foreach (name, value in CommonCvars)
			Convars.SetValue(name, value);
	}
	Tick(Generation);
	LockTick(Generation);
}

function InfectedMoves::Hook() {
	if (("GameEventCallbacks" in getroottable()) && ("hd4l_infected_moves" in ::GameEventCallbacks))
		return;
	__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
	::GameEventCallbacks["hd4l_infected_moves"] <- true;
}

foreach (file in InfectedMoves.Files)
	try { IncludeScript(file, getroottable()); } catch (e) { InfectedMoves.Log("could not include " + file + ": " + e); }

InfectedMoves.Precache();
InfectedMoves.Hook();

if (!("HD4L_Parts" in getroottable()))
	::HD4L_Parts <- {};
::HD4L_Parts["infected_moves"] <- "0.1";
