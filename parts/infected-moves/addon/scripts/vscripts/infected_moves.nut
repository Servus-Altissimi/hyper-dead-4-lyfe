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

function InfectedMoves::OnGameEvent_player_death(params) {
	if (!BoomerPop || !ModeAllowed() || !("userid" in params))
		return;
	local boomer = null;
	try { boomer = GetPlayerFromUserID(params.userid); } catch (e) { return; }
	if (boomer == null || !boomer.IsValid() || NetProps.GetPropInt(boomer, "m_iTeamNum") != TEAM_INFECTED || boomer.GetZombieType() != ZOMBIE_BOOMER)
		return;
	Pop(boomer.GetOrigin());
}

function InfectedMoves::Pop(pos) {
	Particle("tank_ground_pound", pos, 1.0);
	ScreenShake(pos, 6.0, 30.0, 0.5, PopRadius * 2.0, 0, false);
	local push = SpawnEntityFromTable("env_physexplosion", { magnitude = "600", radius = PopRadius.tostring(), spawnflags = "1", origin = pos });
	if (push != null) {
		DoEntFire("!self", "Explode", "", 0, null, push);
		DoEntFire("!self", "Kill", "", 0.1, null, push);
	}
	local ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "infected", pos, PopRadius)) != null) {
		if (ent.GetHealth() <= 0)
			continue;
		ent.TakeDamage(0, DMG_STAGGER, Entities.First());
		ent.ApplyAbsVelocityImpulse(Flat(ent.GetOrigin() - pos) * PopPush + Vector(0, 0, PopLift));
	}
	local speaker = SpawnEntityFromTable("info_target", { origin = pos });
	if (speaker != null) {
		Loud(PopSound, speaker, 105, 70);
		DoEntFire("!self", "Kill", "", 2.0, null, speaker);
	}
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

function InfectedMoves::StopTank(index) {
	if (index in Charging)
		delete Charging[index];
	if (!(index in Tanks))
		return;
	delete Tanks[index];
}

function InfectedMoves::OnGameEvent_tank_killed(params) {
	local tank = null;
	if ("userid" in params)
		try { tank = GetPlayerFromUserID(params.userid); } catch (e) {}
	if (tank == null || !tank.IsValid())
		return;
	StopTank(tank.GetEntityIndex());
}

function InfectedMoves::Step(tank, t) {
	local pos = tank.GetOrigin();
	if (!("stepFrom" in t))
		t.stepFrom <- pos;
	local d = Vector(pos.x - t.stepFrom.x, pos.y - t.stepFrom.y, 0).Length();
	if (d < StepStride)
		return;
	t.stepFrom = pos;
	Particle("hunter_leap_dust", pos, 1.0);
	ScreenShake(pos, StepShake, 20.0, 0.25, StepShakeRadius, 0, false);
	try { EmitAmbientSoundOn(StepSound, 0.45, 85, 55, tank); } catch (e) {}
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

function InfectedMoves::TankState(tank) {
	local index = tank.GetEntityIndex();
	if (!(index in Tanks))
		Tanks[index] <- { ent = tank, phase = "", until = 0.0, rushAt = Time() + 2.0, slamAt = Time() + 3.0, dir = null, hit = {}, wave = 0, falling = false, fallSpeed = 0.0, lockUntil = 0.0, human = !IsPlayerABot(tank) };
	return Tanks[index];
}

function InfectedMoves::Knob(t, name) {
	if (t.human && (name in HumanKnobs))
		return HumanKnobs[name];
	if (Amped(t) && (name in AmpKnobs))
		return AmpKnobs[name];
	return this[name];
}

function InfectedMoves::Amped(t) {
	if (!("Escalation" in getroottable()) || !("IsAmped" in ::Escalation))
		return false;
	try { return ::Escalation.IsAmped(t.ent); } catch (e) { return false; }
}

function InfectedMoves::TankCooldown(t, seconds) {
	return Cooldown(seconds) * (Amped(t) ? AmpCooldown : 1.0);
}

function InfectedMoves::TankTick(tank, now) {
	local t = TankState(tank);
	local grounded = (NetProps.GetPropInt(tank, "m_fFlags") & FL_ONGROUND) != 0;

	if (!grounded) {
		t.falling = true;
		local vz = tank.GetVelocity().z;
		if (vz < t.fallSpeed) t.fallSpeed = vz;
	} else if (t.falling) {
		t.falling = false;
		if (t.fallSpeed <= -FallSpeed && t.phase == "") {
			Impact(tank.GetOrigin(), SlamRadius, SlamDamage, tank, "tank_ground_pound");
		}
		t.fallSpeed = 0.0;
	}
	if (TankSteps && grounded)
		Step(tank, t);

	if (t.phase != "") {
		TankPhase(tank, t, now);
		return;
	}
	if (tank.IsIncapacitated() || tank.IsStaggering())
		return;
	if (!IsPlayerABot(tank)) {
		if (HumanTank)
			TankInput(tank, t, now);
		return;
	}
	local near = Nearest(tank, Survivors());
	if (near.ent == null)
		return;
	local d = near.dist;
	if (d <= SlamRange && now >= t.slamAt) {
		TankBegin(tank, t, "slam", near.ent, now);
		return;
	}
	if (d >= SuperMin && d <= SuperMax && now >= t.slamAt && RandomInt(1, 100) <= SuperChance) {
		TankBegin(tank, t, "super", near.ent, now);
		return;
	}
	if (d >= RushMin && d <= RushMax && now >= t.rushAt)
		TankBegin(tank, t, "rush", near.ent, now);
}

function InfectedMoves::RushTick(index, generation) {
	if (generation != Generation || !(index in Tanks))
		return;
	local t = Tanks[index];
	local tank = t.ent;
	if (Dying(tank)) {
		StopTank(index);
		return;
	}
	if (t.phase != "rush_run")
		return;
	tank.SetVelocity(t.dir * Knob(t, "RushSpeed") + Vector(0, 0, 20));
	foreach (s in Survivors()) {
		local si = s.GetEntityIndex();
		if ((si in t.hit) || (s.GetOrigin() - tank.GetOrigin()).Length() > RushHitRange)
			continue;
		t.hit[si] <- true;
		s.ApplyAbsVelocityImpulse(t.dir * Knob(t, "RushKnock") + Vector(0, 0, 200));
		try { s.Stagger(tank.GetOrigin()); } catch (e) {}
		s.TakeDamage(Knob(t, "RushDamage"), DMG_CLUB, tank);
		Sound(s, Sounds.tank_hit);
	}
	DoEntFire("!self", "RunScriptCode", "::InfectedMoves.RushTick(" + index + ", " + generation + ")", 0.015, null, Entities.First());
}

function InfectedMoves::Retarget(tank) {
	local near = Nearest(tank, Survivors());
	if (near.ent == null)
		return;
	try { CommandABot({ cmd = 0, target = near.ent, bot = tank }); } catch (e) { return; }
	DoEntFire("!self", "RunScriptCode", "try { CommandABot({ cmd = 3, bot = self }); } catch (e) {}", RetargetSeconds, null, tank);
}

function InfectedMoves::TankInput(tank, t, now) {
	local buttons = 0;
	local pressed = 0;
	try { buttons = NetProps.GetPropInt(tank, "m_nButtons"); pressed = NetProps.GetPropInt(tank, "m_afButtonPressed"); } catch (e) { return; }
	if (!("prev" in t)) t.prev <- 0;
	pressed = pressed | (buttons & ~t.prev);
	t.prev = buttons;
	local view = Flat(tank.EyeAngles().Forward());
	if ((pressed & SuperKey) && now >= t.slamAt)
		TankBegin(tank, t, "super", null, now, view);
	else if (pressed & RushKey) {
		if (buttons & 4) {
			if (now >= t.slamAt)
				TankBegin(tank, t, "slam", null, now, view);
		} else if (now >= t.rushAt)
			TankBegin(tank, t, "rush", null, now, view);
	}
}

function InfectedMoves::TankBegin(tank, t, move, target, now, dir = null) {
	t.phase = move + "_windup";
	t.dir = dir != null ? dir : Flat(target.GetOrigin() - tank.GetOrigin());
	t.origin <- tank.GetOrigin();
	t.hit = {};
	t.wave = 0;
	Freeze(tank, true);
	Sound(tank, Sounds.tank_yell);
	Particle("tank_breath", tank.GetOrigin() + Vector(0, 0, 70), 1.0);
	local length = 0.0;
	if (move == "rush") {
		t.until = now + Knob(t, "RushWindup");
		length = Knob(t, "RushWindup") + Knob(t, "RushTime") + 0.4;
		Gesture(tank, "ACT_HULK_ATTACK_LOW");
	} else if (move == "slam") {
		t.until = now + Knob(t, "SlamWindup");
		length = Knob(t, "SlamWindup") + SlamLock + 0.4;
		Gesture(tank, "ACT_HULK_ATTACK_LOW");
	} else {
		t.until = now + Knob(t, "SuperWindup");
		length = Knob(t, "SuperWindup") + Knob(t, "SuperWaves") * Knob(t, "SuperDelay") + SuperLock + 0.4;
		Gesture(tank, "Attack_Incap_03");
	}
	if (t.human && HumanThirdPerson)
		try { NetProps.SetPropFloat(tank, "m_TimeForceExternalView", now + length); } catch (e) {}
}

function InfectedMoves::TankPhase(tank, t, now) {
	if (Dying(tank)) {
		StopTank(tank.GetEntityIndex());
		return;
	}
	if (now < t.until) {
		return;
	}

	if (t.phase == "rush_windup") {
		Freeze(tank, false);
		if (t.human)
			t.dir = Flat(tank.EyeAngles().Forward());
		t.phase = "rush_run";
		t.until = now + Knob(t, "RushTime");
		try { tank.OverrideFriction(Knob(t, "RushTime") + 0.1, 0.05); } catch (e) {}
		if (TankRushFire)
			Charging[tank.GetEntityIndex()] <- { ent = tank, last = tank.GetOrigin() };
		RushTick(tank.GetEntityIndex(), Generation);
	} else if (t.phase == "rush_run") {
		local index = tank.GetEntityIndex();
		if (index in Charging)
			delete Charging[index];
		tank.SetVelocity(t.dir * RushCarry);
		if (t.hit.len() == 0)
			try { tank.Stagger(tank.GetOrigin() - t.dir * 50); } catch (e) {}
		t.phase = "";
		t.rushAt = now + TankCooldown(t, RushCooldown);
		if (!t.human)
			Retarget(tank);
	} else if (t.phase == "slam_windup") {
		local pos = Ground(tank.GetOrigin(), tank);
		if (pos == null) pos = tank.GetOrigin();
		Impact(pos, Knob(t, "SlamRadius"), Knob(t, "SlamDamage"), tank, "tank_ground_pound");
		Sound(tank, Sounds.rock);
		t.phase = "slam_lock";
		t.until = now + SlamLock;
		t.lockUntil = t.until;
	} else if (t.phase == "super_windup") {
		if (t.human)
			t.dir = Flat(tank.EyeAngles().Forward());
		t.phase = "super_wave";
		t.until = now;
	} else if (t.phase == "super_wave") {
		t.wave++;
		local along = t.origin + t.dir * (100.0 + t.wave * Knob(t, "SuperSpacing"));
		local pos = Ground(along, tank);
		if (pos != null) {
			Impact(pos, Knob(t, "SuperRadius"), Knob(t, "SlamDamage"), tank, "tank_rock_throw_impact");
			Particle("tank_ground_pound", pos, 1.0);
			Sound(tank, Sounds.rock);
		}
		if (t.wave >= Knob(t, "SuperWaves")) {
			t.phase = "super_lock";
			t.until = now + SuperLock;
			t.lockUntil = t.until;
		} else
			t.until = now + Knob(t, "SuperDelay");
	} else if (t.phase == "slam_lock" || t.phase == "super_lock") {
		Freeze(tank, false);
		t.phase = "";
		t.slamAt = now + TankCooldown(t, SlamCooldown);
	}
}

function InfectedMoves::OnGameEvent_witch_harasser_set(params) {
	if (!Witch || !ModeAllowed() || !("witchid" in params) || !("userid" in params))
		return;
	local witch = EntIndexToHScript(params.witchid);
	local harasser = null;
	try { harasser = GetPlayerFromUserID(params.userid); } catch (e) {}
	if (witch == null || !witch.IsValid() || harasser == null || !harasser.IsValid())
		return;
	Witches[params.witchid] <- { ent = witch, target = harasser, phase = "", until = 0.0, leapAt = Time() + 1.5, spot = null };
}

function InfectedMoves::WitchTick(w, index, now) {
	local witch = w.ent;
	if (!Alive(witch)) {
		delete Witches[index];
		return;
	}
	if (w.phase == "windup") {
		if (now < w.until)
			return;

		local to = w.spot - witch.GetOrigin();
		local flat = Flat(to);
		witch.ApplyAbsVelocityImpulse(flat * LeapSpeed + Vector(0, 0, LeapLift));
		w.phase = "air";
		w.until = now + LeapAir;
		return;
	}
	if (w.phase == "air") {
		if (now < w.until)
			return;

		local pos = witch.GetOrigin();
		Particle("hunter_leap_dust", pos, 1.0);
		local hit = false;
		foreach (s in Survivors()) {
			if ((s.GetOrigin() - pos).Length() > LeapHitRange)
				continue;
			hit = true;
			s.ApplyAbsVelocityImpulse(Flat(s.GetOrigin() - pos) * LeapKnock + Vector(0, 0, 150));
			try { s.Stagger(pos); } catch (e) {}
			s.TakeDamage(LeapDamage, DMG_CLUB, witch);
		}
		if (!hit)
			try { witch.Stagger(pos + Vector(RandomInt(-10, 10), RandomInt(-10, 10), 0)); } catch (e) {}
		w.phase = "";
		w.leapAt = now + LeapCooldown;
		return;
	}
	if (now < w.leapAt)
		return;
	local target = w.target;
	if (target == null || !target.IsValid() || target.IsDead()) {
		local near = Nearest(witch, Survivors());
		target = near.ent;
		w.target = target;
		if (target == null)
			return;
	}
	local d = (target.GetOrigin() - witch.GetOrigin()).Length();
	if (d < LeapMin || d > LeapMax)
		return;
	w.phase = "windup";
	w.until = now + LeapWindup;
	w.spot = target.GetOrigin();
	Sound(witch, Sounds.witch);
}

function InfectedMoves::TongueLost(smokerUserid) {
	if (!Smoker || !ModeAllowed())
		return;
	DoEntFire("!self", "RunScriptCode", "::InfectedMoves.Phantom(" + smokerUserid + ")", PhantomDelay, null, Entities.First());
}

function InfectedMoves::OnGameEvent_tongue_release(params) {
	if ("userid" in params)
		TongueLost(params.userid);
}

function InfectedMoves::OnGameEvent_tongue_broke_bent(params) {
	if ("userid" in params)
		TongueLost(params.userid);
}

function InfectedMoves::HiddenSpot(ent, survivors, min, max) {
	local origin = ent.GetOrigin();
	local areas = {};
	try { NavMesh.GetNavAreasInRadius(origin, max, areas); } catch (e) { Log("no navmesh: " + e); return null; }
	local best = null;
	foreach (name, area in areas) {
		local c = null;
		try { c = area.GetCenter(); } catch (e) { continue; }
		local d = (c - origin).Length();
		if (d < min * 0.5 || d > max)
			continue;
		local isBlocked = false;
		try { isBlocked = area.IsBlocked(TEAM_INFECTED, false); } catch (e) {}
		if (isBlocked)
			continue;
		local up = { start = c + Vector(0, 0, 20), end = c + Vector(0, 0, 76), ignore = ent };
		TraceLine(up);
		if (up.hit)
			continue;
		local ok = true;
		foreach (s in survivors) {
			if ((s.GetOrigin() - c).Length() < min) {
				ok = false;
				break;
			}
			local look = { start = s.EyePosition(), end = c + Vector(0, 0, 40), ignore = s };
			TraceLine(look);
			if (!look.hit || look.fraction > 0.98) {
				ok = false;
				break;
			}
		}
		if (ok && (best == null || c.z > best.z))
			best = c;
	}
	return best;
}

function InfectedMoves::Phantom(userid) {
	local smoker = null;
	try { smoker = GetPlayerFromUserID(userid); } catch (e) { return; }
	if (!IsSpecial(smoker, ZOMBIE_SMOKER) || !IsPlayerABot(smoker))
		return;
	local spot = HiddenSpot(smoker, Survivors(), PhantomMin, PhantomMax);
	if (spot == null)
		return;
	local from = smoker.GetOrigin();
	Particle("smoker_smokecloud", from, 3.0);
	Sound(smoker, Sounds.smoker);
	smoker.SetOrigin(spot);
	Particle("smoker_smokecloud", spot, 3.0);
	smoker.SetHealth(smoker.GetMaxHealth());
}

function InfectedMoves::BoomerTick(boomer, now) {
	local index = boomer.GetEntityIndex();
	if (!(index in Boomers))
		Boomers[index] <- { ent = boomer, near = 0.0, phase = "", until = 0.0, nextDrip = 0.0 };
	local b = Boomers[index];
	if (b.phase == "retch") {
		if (now >= b.nextDrip) {
			Particle("boomer_vomit", boomer.GetOrigin() + Vector(0, 0, 50), 0.6);
			b.nextDrip = now + 0.5;
		}
		if (now < b.until)
			return;

		local inner = Convars.GetFloat("z_exploding_inner_radius");
		local outer = Convars.GetFloat("z_exploding_outer_radius");
		Convars.SetValue("z_exploding_inner_radius", BurstRadius * 0.5);
		Convars.SetValue("z_exploding_outer_radius", BurstRadius);
		boomer.TakeDamage(boomer.GetHealth() + 100, DMG_BLAST, Entities.First());
		DoEntFire("!self", "RunScriptCode", "Convars.SetValue(\"z_exploding_inner_radius\", " + inner + "); Convars.SetValue(\"z_exploding_outer_radius\", " + outer + ")", 0.3, null, Entities.First());
		b.phase = "burst";
		return;
	}
	if (b.phase != "")
		return;
	local near = Nearest(boomer, Survivors());
	if (near.ent != null && near.dist <= SwellRange)
		b.near += 0.1;
	if (b.near < SwellSeconds)
		return;
	b.phase = "retch";
	b.until = now + RetchSeconds;
	Freeze(boomer, true);
	Sound(boomer, Sounds.boomer);
}

function InfectedMoves::StartTrail(userid) {
	if (!Spitter || !ModeAllowed())
		return;
	local ent = null;
	try { ent = GetPlayerFromUserID(userid); } catch (e) { return; }
	if (!IsSpecial(ent, ZOMBIE_SPITTER))
		return;
	local index = ent.GetEntityIndex();
	if (index in Trailing)
		return;
	Trailing[index] <- { ent = ent, until = Time() + TrailSeconds, next = Time() + TrailStep };
}

function InfectedMoves::OnGameEvent_spit_burst(params) {
	if ("userid" in params)
		StartTrail(params.userid);
}

function InfectedMoves::OnGameEvent_ability_use(params) {
	if (!("userid" in params) || !("ability" in params))
		return;
	if (params.ability == "ability_spit")
		StartTrail(params.userid);
}

function InfectedMoves::Pool(pos, spitter, now) {
	Particle(TrailEffect, pos + Vector(0, 0, 4), TrailLife);
	Trails.append({ pos = pos, until = now + TrailLife });
}

function InfectedMoves::TrailTick(now) {
	foreach (index, tr in clone Trailing) {
		if (!Alive(tr.ent) || now >= tr.until) {
			delete Trailing[index];
			continue;
		}
		if (now < tr.next)
			continue;
		tr.next = now + TrailStep;
		local pos = Ground(tr.ent.GetOrigin(), tr.ent);
		if (pos == null)
			continue;
		Pool(pos, tr.ent, now);
	}
	if (now - LastTrailTick < TrailPeriod)
		return;
	LastTrailTick = now;
	local keep = [];
	foreach (pool in Trails) {
		if (now >= pool.until)
			continue;
		keep.append(pool);
		foreach (s in Survivors())
			if ((s.GetOrigin() - pool.pos).Length() <= TrailRadius && !s.IsIncapacitated())
				s.TakeDamage(TrailDamage, 0, Entities.First());
	}
	Trails = keep;
}

function InfectedMoves::ChargeStart(userid) {
	if (!Charger || !ModeAllowed())
		return;
	local ent = null;
	try { ent = GetPlayerFromUserID(userid); } catch (e) { return; }
	if (!IsSpecial(ent, ZOMBIE_CHARGER))
		return;
	Charging[ent.GetEntityIndex()] <- { ent = ent, last = ent.GetOrigin() };
}

function InfectedMoves::ChargeStop(userid) {
	local ent = null;
	try { ent = GetPlayerFromUserID(userid); } catch (e) { return; }
	if (ent == null || !ent.IsValid())
		return;
	local index = ent.GetEntityIndex();
	if (index in Charging)
		delete Charging[index];
}

function InfectedMoves::OnGameEvent_charger_charge_start(params) {
	if ("userid" in params)
		ChargeStart(params.userid);
}

function InfectedMoves::OnGameEvent_charger_charge_end(params) {
	if ("userid" in params)
		ChargeStop(params.userid);
}

function InfectedMoves::OnGameEvent_charger_carry_start(params) {
	if ("userid" in params)
		ChargeStop(params.userid);
}

function InfectedMoves::Fire(pos, charger, now) {
	local gfx = SpawnEntityFromTable("info_particle_system", { effect_name = FireEffect, origin = pos + Vector(0, 0, 2), start_active = 1 });
	if (gfx != null) {
		DoEntFire("!self", "Stop", "", FireSeconds, null, gfx);
		DoEntFire("!self", "Kill", "", FireSeconds + 2.0, null, gfx);
	}
	Fires.append({ pos = pos, until = now + FireSeconds, owner = charger });
}

function InfectedMoves::ChargerTick(now) {
	foreach (index, c in clone Charging) {
		if (!Alive(c.ent)) {
			delete Charging[index];
			continue;
		}

		local pos = c.ent.GetOrigin();
		local dir = pos - c.last;
		local dist = dir.Length();
		if (dist < FireStep)
			continue;
		dir = dir * (1.0 / dist);
		while (dist >= FireStep) {
			c.last = c.last + dir * FireStep;
			dist -= FireStep;
			local ground = Ground(c.last, c.ent);
			if (ground != null)
				Fire(ground, c.ent, now);
		}
	}
	if (now - LastFireTick < FirePeriod)
		return;
	LastFireTick = now;
	local keep = [];
	foreach (fire in Fires) {
		if (now >= fire.until)
			continue;
		keep.append(fire);
		local attacker = (fire.owner != null && fire.owner.IsValid()) ? fire.owner : Entities.First();
		foreach (s in Survivors())
			if ((s.GetOrigin() - fire.pos).Length() <= FireRadius && !s.IsIncapacitated())
				s.TakeDamage(FireDamage, DMG_BURN, attacker);
	}
	Fires = keep;
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

InfectedMoves.Precache();
InfectedMoves.Hook();

if (!("HD4L_Parts" in getroottable()))
	::HD4L_Parts <- {};
::HD4L_Parts["infected_moves"] <- "0.1";
