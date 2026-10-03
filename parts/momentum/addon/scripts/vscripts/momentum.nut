const IN_JUMP = 2;
const IN_DUCK = 4;
const IN_FORWARD = 8;
const IN_BACK = 16;
const IN_ATTACK2 = 2048;
const IN_RELOAD = 8192;
const IN_ATTACK = 1;
const IN_MOVELEFT = 512;
const IN_MOVERIGHT = 1024;
const IN_SPEED = 131072;
const FL_ONGROUND = 1;
const MOVETYPE_LADDER = 9;
const TEAM_INFECTED = 3;
const ZOMBIE_TANK = 8;
const DMG_CLUB = 128;
const DMG_BLAST = 64;
const DMG_STAGGER = 33554432;
const DMG_ALWAYSGIB = 8192;
const DEG = 0.0174533;

::Momentum <- {
	Versus = true,
	Survival = true,
	Stock = false,

	TapKeys = [ IN_FORWARD ],
	TapWindow = 0.3,

	Key = 32768,

	StaminaMax = 100.0,
	StaminaRegen = 30.0,
	StaminaDelay = 0.6,
	Cost = { dash = 20.0, slide = 15.0, heavy = 35.0, kick = 25.0, jump = 15.0, dive = 30.0, breakfree = 60.0, roll = 10.0, shove = 12.0, blink = 40.0 },

	ShoveStamina = true,
	ShoveInterval = 0.4,

	DashSpeed = 600.0,
	DashBoost = 2.2,
	DashTime = 0.25,
	DashCooldown = 0.6,
	ShoveRange = 80.0,
	ShoveDot = 0.4,
	ShovePush = 250.0,

	SlideSpeed = 520.0,
	SlideBoost = 1.6,
	SlideTime = 0.8,
	SlideFriction = 0.15,

	HeavyStillSpeed = 60.0,
	HeavySpeed = 850.0,
	HeavyBoost = 3.2,
	HeavyTime = 0.45,
	HeavyRange = 110.0,
	HeavyDot = 0.3,
	HeavyDamageSpecial = 120,
	HeavyLaunch = 700.0,
	HeavyLift = 300.0,
	HeavyDoorRange = 120.0,

	ShoveBreaksDoors = true,
	BreakCheckpointDoors = false,

	ExtraJumps = 1,

	AirKicks = 1,
	KickSpeed = 560.0,
	KickLift = 90.0,
	KickGravity = 0.45,
	KickTime = 0.4,
	KickRange = 72.0,
	KickDot = 0.2,
	KickBodyLow = 12.0,
	KickBodyHigh = 64.0,
	KickDamageSpecial = 150,
	KickDamageWitch = 150,
	KickDamageTank = 100,
	KickDamageType = 0,
	LaunchCommon = 1200.0,
	LaunchUp = 250.0,

	SuperGib = true,
	BounceBack = 180.0,
	BounceUp = 240.0,
	RefundOnHit = true,

	HyperChain = 3,
	HyperSeconds = 5.0,
	HyperBoost = 1.3,

	RunBuild = 0.25,
	RunRamp = 4.0,
	RunMinSpeed = 150.0,

	BaseSpeed = 1.2,

	StackBonus = 0.05,
	StackMax = 6,
	StackSeconds = 10.0,

	BreakFreeTaps = 6,
	BreakFreeWindow = 1.5,
	BreakFreeDelay = 0.6,
	BreakFreeCost = 60.0,
	BreakFreeDamage = 50,
	BreakFreeChargerDamage = 250,
	BreakFreeSelfDamage = 8,

	RollFallSpeed = 500.0,
	RollReach = 60.0,
	RollCost = 10.0,

	HardFall = 15,
	LightLandSlow = 0.7,
	LightLandSeconds = 0.35,
	HardLandSlow = 0.45,
	HardLandSeconds = 0.9,
	LightFallStamina = 5.0,
	HardFallStamina = 20.0,
	HardLandingRadius = 120.0,
	LandingParticles = { ground = "tank_ground_pound", water = "weapon_pipebomb_water_splash" },
	LandingSounds = { ground = "player/tank/fall/tank_death_bodyfall_01.wav",
	                  water = [ "ambient/water/water_splash1.wav", "ambient/water/water_splash2.wav", "ambient/water/water_splash3.wav" ] },

	ExplosiveFuse = 1.0,
	ExplosiveHints = [ "propane", "gascan", "gas_can", "oxygen", "fuel", "barrel" ],

	WitchTackleDamage = 300,

	Dive = true,
	DiveKeys = [ IN_MOVELEFT, IN_MOVERIGHT ],
	DiveSpeed = 450.0,
	DiveBoost = 1.8,
	DiveTime = 0.2,
	DiveSlow = 0.6,
	DiveSlowTime = 0.5,
	DiveCooldown = 0.8,

	WallKickReach = 48.0,

	PropLaunch = 900.0,
	PropLift = 200.0,

	DashOpensDoors = true,
	DoorOpenRange = 110.0,

	LedgeVault = true,

	WallRun = true,
	WallRunReach = 40.0,
	WallRunMinSpeed = 150.0,
	WallRunGravity = 0.12,
	WallRunHop = 70.0,
	WallRunDrain = 25.0,
	WallRunRoll = 12.0,
	WallJumpForward = 360.0,
	WallJumpAway = 220.0,
	WallJumpUp = 300.0,
	WallKickSpeed = 1.5,
	WallKickDamage = 2.0,
	WallKickGrace = 0.35,

	LastStand = true,
	JockeySway = true,
	SwayRoll = 10.0,
	SwayLurch = 3.0,
	SwayPitch = 2.0,
	Heartbeat = "hyper/heartbeat.mp3",
	BeatPeriod = 0.85,
	BeatFast = 0.55,
	BeatLowHealth = 40,
	BeatLayers = 3,

	HitSlowKeep = 0.4,

	TeammateShove = true,
	TeammateShovePush = 420.0,
	TeammateShoveLift = 180.0,
	TeammateShoveDamage = 5,
	BotsShoveTeammates = false,
	ItemWeapons = { weapon_molotov = true, weapon_pipe_bomb = true, weapon_vomitjar = true, weapon_first_aid_kit = true, weapon_defibrillator = true,
	                weapon_upgradepack_explosive = true, weapon_upgradepack_incendiary = true, weapon_pain_pills = true, weapon_adrenaline = true },

	RockParry = true,
	SpitParry = true,
	ParryWindow = 0.2,
	ParryRange = 150.0,
	ParryDot = 0.0,
	ParryAssist = 0.9,
	ParrySpeed = 1500.0,
	ParrySpeedScale = 1.5,
	ParryLift = 60.0,
	ParryFlash = 45,
	SpitBurstRadius = 160.0,
	SpitBurstDamage = 250,
	SpitBurstSpecial = 120,
	SpitBurstEffect = "spitter_areaofdenial_spot",
	ParryDamage = 400,
	TankStumbleSeconds = 1.4,
	TankStumbleAnim = "Shoved_Backward",
	TankParryRange = 130.0,
	TankParryDot = 0.3,
	AiParryChance = 35,
	AiParryCooldown = 1.0,
	ParryCue = true,

	InfectedKit = true,
	BlinkKey = IN_RELOAD,
	JockeyDashSpeed = 650.0,
	JockeyDashLift = 220.0,
	BlinkMin = 350.0,
	BlinkMax = 800.0,
	BlinkCooldown = 1.0,
	BlinkCloud = "smoker_smokecloud",

	SurvivorEyes = true,
	EyeColor = "255 250 240",
	HyperEyes = "hd4l_eyes_hyper",
	BoostEyes = "hd4l_eyes_white",
	Afterimages = true,
	GhostEvery = 0.06,
	GhostMax = 4,
	GhostLife = 0.35,
	GhostColor = "225 215 195",
	GhostAlpha = 150,
	GhostBack = 56.0,
	StreakColor = "255 176 60",
	StreakLife = 0.3,
	StreakWidth = 14.0,
	StreakAlpha = 160,
	HyperFlash = 70,
	HyperBurst = [ "tank_ground_pound", "electrical_arc_01" ],

	Sounds = {
		Dash = "player/survivor/swing/swing_miss2.wav",
		Kick = "player/survivor/swing/swish_weaponswing_swipe5.wav",
		Jump = "player/jumplanding_zombie.wav",
		Shove = "player/survivor/hit/rifle_swing_hit_infected10.wav",
		Kill = "player/tank/hit/hulk_punch_1.wav",
		Heavy = "momentum/heavy.mp3",
		Deny = "momentum/deny.mp3",
		Chain = "momentum/chain.mp3",
		Stamina = "momentum/stamina.mp3",
		Parry = "momentum/parry.mp3",
		DoorWood = "physics/wood/wood_plank_break1.wav",
		DoorMetal = "physics/metal/metal_sheet_impact_hard6.wav"
	},

	State = {},

	Rocks = {},
	Spits = {},
	Generation = 0
}

function Momentum::Log(msg) {
	printl("[Momentum] " + msg);
}

function Momentum::ModeAllowed() {
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

function Momentum::Precache() {
	foreach (name, path in Sounds)
		PrecacheSound(path);
	if (Heartbeat != "")
		PrecacheSound(Heartbeat);
	PrecacheSound(LandingSounds.ground);
	foreach (path in LandingSounds.water)
		PrecacheSound(path);
	foreach (kind, effect in LandingParticles)
		PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = effect, origin = Vector(0, 0, 0), start_active = 1 });
	PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = BlinkCloud, origin = Vector(0, 0, 0), start_active = 1 });
	PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = "tank_rock_throw_impact", origin = Vector(0, 0, 0), start_active = 1 });
	PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = SpitBurstEffect, origin = Vector(0, 0, 0), start_active = 1 });
	foreach (effect in HyperBurst)
		PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = effect, origin = Vector(0, 0, 0), start_active = 1 });
}

function Momentum::Fx() {
	return ("HD4L" in getroottable()) && ("Eyes" in ::HD4L);
}

function Momentum::Boom(sound, ent, pitch = 100) {
	if (Fx())
		try { ::HD4L.Loud(sound, ent, 100, pitch); return; } catch (e) {}
	EmitSoundOn(sound, ent);
}

function Momentum::Aura(p, s) {
	if (!SurvivorEyes || !Fx())
		return;
	local kind = "";
	if (Time() < s.hyperUntil || s.lastStand)
		kind = "hyper";
	else if (Boosted(p, s))
		kind = "boost";
	if (kind == s.eyesKind)
		return;
	::HD4L.Unfx(s.eyes, 0.3);
	s.eyes = null;
	s.eyesKind = kind;
	if (kind == "")
		return;
	s.eyes = ::HD4L.Eyes(p, kind == "hyper" ? HyperEyes : BoostEyes, 64.0);
}

function Momentum::Streak(p, s, on) {
	if (!Fx())
		return;
	if (s.streak != null) {
		::HD4L.Unfx([ s.streak ], StreakLife);
		s.streak = null;
	}
	if (!on)
		return;
	s.streak = ::HD4L.Trail(p.GetOrigin() + Vector(0, 0, 36), StreakColor, StreakLife, StreakWidth, StreakAlpha);
	if (s.streak != null)
		::HD4L.Attach(s.streak, p, "");
}

function Momentum::Ghost(p, s, now) {
	s.ghostAt = now + GhostEvery;
	s.ghosts++;
	local model = p.GetModelName();
	if (model == "")
		return;
	local ang = p.GetAngles();
	local vel = p.GetVelocity();
	local dir = Vector(vel.x, vel.y, 0);
	if (dir.Length() < 50.0)
		dir = s.kick && s.kickDir != null ? Flat(s.kickDir) : (s.moveDir != null ? s.moveDir : Flat(p.EyeAngles().Forward()));
	dir = Flat(dir);
	local ghost = SpawnEntityFromTable("prop_dynamic_override", { model = model, origin = p.GetOrigin() - dir * GhostBack, angles = "0 " + ang.y + " 0",
		solid = 0, disableshadows = 1, rendermode = 5, renderamt = GhostAlpha, rendercolor = GhostColor, DefaultAnim = "" });
	if (ghost == null)
		return;
	try {
		NetProps.SetPropInt(ghost, "m_nSequence", NetProps.GetPropInt(p, "m_nSequence"));
		NetProps.SetPropFloat(ghost, "m_flCycle", NetProps.GetPropFloat(p, "m_flCycle"));
		NetProps.SetPropFloat(ghost, "m_flPlaybackRate", 0.0);
	} catch (e) {}
	DoEntFire("!self", "DisableCollision", "", 0, null, ghost);
	local steps = 3;
	for (local i = 1; i <= steps; i++)
		DoEntFire("!self", "Alpha", (GhostAlpha * (steps - i) / steps).tostring(), GhostLife * i / (steps + 1), null, ghost);
	DoEntFire("!self", "Kill", "", GhostLife, null, ghost);
}

function Momentum::ClearFx(s) {
	if (!Fx())
		return;
	::HD4L.Unfx(s.eyes, 0.3);
	if (s.streak != null)
		::HD4L.Unfx([ s.streak ], 0.3);
	s.eyes = null;
	s.eyesKind = "";
	s.streak = null;
}

function Momentum::HyperBang(p) {
	local origin = p.GetOrigin();
	foreach (effect in HyperBurst) {
		local gfx = SpawnEntityFromTable("info_particle_system", { effect_name = effect, origin = origin + Vector(0, 0, 8), start_active = 1 });
		if (gfx != null)
			DoEntFire("!self", "Kill", "", 1.5, null, gfx);
	}
	ScreenShake(origin, 10.0, 40.0, 0.6, 300.0, 0, false);
	if (Fx())
		::HD4L.Flash(origin + Vector(0, 0, 48), EyeColor, 1.5, 0.25);
	local fade = SpawnEntityFromTable("env_fade", { spawnflags = "5", duration = "0.4", holdtime = "0.05", renderamt = HyperFlash.tostring(), rendercolor = "255 250 240" });
	if (fade != null) {
		DoEntFire("!self", "Fade", "", 0, p, fade);
		DoEntFire("!self", "Kill", "", 1.0, null, fade);
	}
	Boom(Sounds.Chain, p, 80);
	Boom(Sounds.Heavy, p, 115);
}

function Momentum::OnGameEvent_round_start(params) {
	Generation++;
	State.clear();
	Rocks.clear();
	Spits.clear();
	if (ModeAllowed())
		Tick(Generation);
}

function Momentum::Tick(generation) {
	if (generation != Generation)
		return;
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null) {
		if (p.IsDead() || p.IsDying())
			continue;
		if (IsPlayerABot(p)) {
			if (p.IsSurvivor())
				try { Aura(p, StateOf(p)); } catch (e) { Log("bot eyes failed for " + p.GetPlayerName() + ": " + e); }
			continue;
		}
		if (p.IsSurvivor()) {
			try { Update(p); } catch (e) { Log("update failed for " + p.GetPlayerName() + ": " + e); }
		} else if (InfectedKit && NetProps.GetPropInt(p, "m_iTeamNum") == 3 && !p.IsGhost()) {
			try { UpdateInfected(p); } catch (e) { Log("infected update failed for " + p.GetPlayerName() + ": " + e); }
		}
	}
	if ((RockParry || SpitParry) && (Rocks.len() > 0 || Spits.len() > 0)) {
		try { RockTick(); } catch (e) { Log("rock tick failed: " + e); }
	}
	DoEntFire("!self", "RunScriptCode", "::Momentum.Tick(" + generation + ")", 0.01, null, Entities.First());
}

function Momentum::StateOf(p) {
	local id = p.GetPlayerUserId();
	if (!(id in State))
		State[id] <- { prev = 0, ground = true, tapAt = -1.0, tapKey = 0,
		               stamina = StaminaMax, spentAt = -10.0, lastCost = 0.0,
		               move = "", moveUntil = 0.0, moveDir = null, moveHits = {}, dashCooldownUntil = 0.0,
		               jumps = ExtraJumps, kicks = AirKicks, kick = false, kickUntil = 0.0, kickDir = null, kickHits = {},
		               chain = 0, hyperUntil = 0.0, lastStand = false, vaultAt = 0.0, vaultRevives = 0,
		               wallRun = false, wallSide = 0, wallRunAt = -10.0, kickLaunch = false,
		               engineLag = 1.0, appliedLag = 1.0, stacks = 0, stackUntil = 0.0,
		               blinkAt = 0.0, fxOn = false,
		               pinnedAt = 0.0, breakTaps = 0, breakFirst = 0.0, breakFailed = false, rolled = false, struggle = "",
		               runSince = -1.0, nextShove = 0.0, shoveLock = 0.0,
		               tapAtSide = -1.0, tapKeySide = 0, dive = "", diveUntil = 0.0, diveCooldownUntil = 0.0,
		               diveGod = false, swayRoll = 0.0, swaying = false, ghostAt = 0.0, ghosts = 0, beatAt = 0.0, slowMult = 1.0, slowUntil = 0.0, parryUntil = 0.0, parried = {}, eyes = null, eyesKind = "", streak = null };
	return State[id];
}

function Momentum::Boosted(p, s) {
	if (Time() < s.hyperUntil || s.lastStand)
		return true;
	try { return NetProps.GetPropInt(p, "m_bAdrenalineActive") != 0; } catch (e) { return false; }
}

function Momentum::Regen(p, s, now) {
	if (s.stamina >= StaminaMax)
		return;
	local boosted = Boosted(p, s);
	if (!boosted && now - s.spentAt < StaminaDelay)
		return;
	local rate = boosted ? StaminaRegen * 3.0 : StaminaRegen;
	local before = s.stamina;
	s.stamina += rate * 0.0333;
	if (s.stamina > StaminaMax)
		s.stamina = StaminaMax;
	if (before < StaminaMax && s.stamina >= StaminaMax)
		EmitSoundOn(Sounds.Stamina, p);
}

function Momentum::Spend(p, s, move) {
	local cost = Cost[move];
	if (s.stamina < cost) {
		EmitSoundOn(Sounds.Deny, p);
		return false;
	}
	s.stamina -= cost;
	s.spentAt = Time();
	s.lastCost = cost;
	return true;
}

function Momentum::Refund(p, s, amount) {
	s.stamina += amount;
	if (s.stamina > StaminaMax)
		s.stamina = StaminaMax;
}

function Momentum::Refill(p) {
	if (p == null || !p.IsValid())
		return;
	local s = StateOf(p);
	s.stamina = StaminaMax;
}

function Momentum::ShoveStaminaCheck(p, s, buttons, pressed, now) {
	local next = 0.0;
	try { next = NetProps.GetPropFloat(p, "m_flNextShoveTime"); } catch (e) { return; }
	try { NetProps.SetPropInt(p, "m_iShovePenalty", 0); } catch (e) {}
	local swinging = (buttons & IN_ATTACK2) != 0;
	if (next > s.nextShove + 0.01 && next > now && next != s.shoveLock && swinging) {
		s.stamina -= Cost.shove;
		if (s.stamina < 0.0)
			s.stamina = 0.0;
		s.spentAt = now;
		s.lastCost = Cost.shove;
		next = now + ShoveInterval;
		NetProps.SetPropFloat(p, "m_flNextShoveTime", next);
		if (RockParry || SpitParry) {
			s.parryUntil = now + ParryWindow;
			s.parried = {};
		}
	}
	local short = s.stamina < Cost.shove;
	if (short && next <= now + 0.05) {
		s.shoveLock = now + 0.15;
		NetProps.SetPropFloat(p, "m_flNextShoveTime", s.shoveLock);
		next = s.shoveLock;
	}
	if (short && (pressed & IN_ATTACK2))
		EmitSoundOn(Sounds.Deny, p);
	s.nextShove = next;
}

function Momentum::Update(p) {
	local s = StateOf(p);
	local now = Time();
	local buttons = Buttons(p);
	local pressed = 0;
	try { pressed = NetProps.GetPropInt(p, "m_afButtonPressed"); } catch (e) {}
	pressed = pressed | (buttons & ~s.prev);
	s.prev = buttons;

	Regen(p, s, now);
	if (ShoveStamina)
		ShoveStaminaCheck(p, s, buttons, pressed, now);
	if (now < s.parryUntil)
		ParryCheck(p, s);
	if (s.hyperUntil > 0.0 && now >= s.hyperUntil)
		s.hyperUntil = 0.0;
	if (s.stacks > 0 && now >= s.stackUntil)
		s.stacks = 0;
	if (LastStand) {
		CheckLastStand(p, s);
		if (s.lastStand && Heartbeat != "" && now >= s.beatAt)
			Beat(p, s, now);
	}
	TrackRun(p, s, now);
	ApplyLag(p, s, now);
	SpeedFx(p, s);
	Aura(p, s);
	if (Afterimages && (s.move != "" || s.kick || s.dive == "dash") && s.ghosts < GhostMax && now >= s.ghostAt)
		Ghost(p, s, now);

	if (JockeySway)
		Sway(p, s, now);
	if (Blocked(p)) {
		EndKick(p, s, false);
		EndMove(p, s);
		EndWallRun(p, s);
		EndDive(p, s);
		BreakFree(p, s, pressed, now);
		return;
	}
	if (s.pinnedAt > 0.0) {
		s.pinnedAt = 0.0;
		s.breakTaps = 0;
		s.breakFailed = false;
	}
	if (s.struggle != "")
		Struggle(p, s, "");

	local onGround = (NetProps.GetPropInt(p, "m_fFlags") & FL_ONGROUND) != 0;
	if (onGround && !s.ground)
		Land(p, s);
	s.ground = onGround;
	if (!onGround)
		RollCheck(p, s, buttons);
	else
		s.rolled = false;

	local side = DiveTriggered(s, pressed, now);
	if (s.dive != "")
		DiveUpdate(p, s, now);
	if (s.dive == "dash")
		return;
	if (Dive && side != 0 && s.dive == "" && onGround && s.move == "" && !s.kick) {
		StartDive(p, s, side, now);
		return;
	}

	if (s.move != "") {
		local over = now >= s.moveUntil;
		if (s.move == "slide" && (!(buttons & IN_DUCK) || !onGround))
			over = true;
		if (over)
			EndMove(p, s);
		else if (s.move == "heavy")
			HeavyCheck(p, s);
		else {
			ShoveCheck(p, s);
			if (DashOpensDoors)
				OpenDoors(p, s);
		}
	}
	if (s.kick) {
		if (onGround || now > s.kickUntil)
			EndKick(p, s, false);
		else
			KickCheck(p, s);
	}

	if (WallRun && !onGround && !s.kick)
		WallRunUpdate(p, s, buttons, pressed, now);
	else if (s.wallRun)
		EndWallRun(p, s);

	if (Triggered(s, pressed, now) && s.dive == "") {
		if (onGround) {
			local vel = p.GetVelocity();
			local speed = Vector(vel.x, vel.y, 0).Length();
			if (buttons & IN_DUCK)
				StartMove(p, s, buttons, now, "slide");
			else if (speed < HeavyStillSpeed)
				StartMove(p, s, buttons, now, "heavy");
			else if (now >= s.dashCooldownUntil || Boosted(p, s))
				StartMove(p, s, buttons, now, "dash");
		} else if (s.kicks > 0)
			StartKick(p, s, now);
		else
			EmitSoundOn(Sounds.Deny, p);
	}
}

function Momentum::Buttons(p) {
	local b = 0;
	try { b = p.GetButtonMask(); } catch (e) {}
	try { b = b | NetProps.GetPropInt(p, "m_nButtons"); } catch (e) {}
	return b;
}

function Momentum::ApplyLag(p, s, now) {
	local cur = GetLag(p);
	if (fabs(cur - s.appliedLag) > 0.001)
		s.engineLag = cur;
	local mult = BaseSpeed;
	if (s.move == "dash") mult *= DashBoost;
	else if (s.move == "slide") mult *= SlideBoost;
	else if (s.move == "heavy") mult *= HeavyBoost;
	if (now < s.slowUntil) mult *= s.slowMult;
	if (s.dive == "dash") mult *= DiveBoost;
	else if (s.dive == "slow") mult *= DiveSlow;
	if (now < s.hyperUntil || s.lastStand)
		mult *= HyperBoost;
	if (s.stacks > 0 && now < s.stackUntil)
		mult *= 1.0 + StackBonus * s.stacks;
	if (s.runSince >= 0.0) {
		local build = (now - s.runSince) / RunRamp;
		if (build > 1.0) build = 1.0;
		mult *= 1.0 + RunBuild * build;
	}
	local want = s.engineLag * mult;
	if (fabs(want - cur) > 0.001) {
		SetLag(p, want);
		s.appliedLag = want;
	}
}

function Momentum::TrackRun(p, s, now) {
	local vel = p.GetVelocity();
	local speed = Vector(vel.x, vel.y, 0).Length();
	if (speed >= RunMinSpeed) {
		if (s.runSince < 0.0)
			s.runSince = now;
	} else
		s.runSince = -1.0;
}

function Momentum::OnGameEvent_player_hurt(params) {
	if (!("userid" in params))
		return;
	local p = null;
	try { p = GetPlayerFromUserID(params.userid); } catch (e) { return; }
	if (p == null || !p.IsValid() || !p.IsSurvivor())
		return;
	if (HitSlowKeep < 1.0 && ByInfected(params)) {
		EaseHitSlow(p);
		DoEntFire("!self", "RunScriptCode", "::Momentum.EaseHitSlowId(" + params.userid + ")", 0.0, null, Entities.First());
	}
	if (IsPlayerABot(p))
		return;
	StateOf(p).runSince = -1.0;
}

function Momentum::ByInfected(params) {
	if ("attacker" in params && params.attacker != 0) {
		local a = null;
		try { a = GetPlayerFromUserID(params.attacker); } catch (e) {}
		if (a != null && a.IsValid())
			return NetProps.GetPropInt(a, "m_iTeamNum") == TEAM_INFECTED;
	}
	if ("attackerentid" in params && params.attackerentid > 0) {
		local e = EntIndexToHScript(params.attackerentid);
		if (e != null && e.IsValid()) {
			local cls = e.GetClassname();
			return cls == "infected" || cls == "witch";
		}
	}
	return false;
}

function Momentum::EaseHitSlow(p) {
	if (!NetProps.HasProp(p, "m_flVelocityModifier"))
		return;
	local v = NetProps.GetPropFloat(p, "m_flVelocityModifier");
	if (v < 1.0)
		NetProps.SetPropFloat(p, "m_flVelocityModifier", 1.0 - (1.0 - v) * HitSlowKeep);
}

function Momentum::EaseHitSlowId(userid) {
	local p = null;
	try { p = GetPlayerFromUserID(userid); } catch (e) { return; }
	if (p != null && p.IsValid() && !p.IsDead())
		try { EaseHitSlow(p); } catch (e) {}
}

function Momentum::OnGameEvent_player_death(params) {
	if (!("userid" in params))
		return;
	local p = null;
	try { p = GetPlayerFromUserID(params.userid); } catch (e) { return; }
	if (p == null || !p.IsValid() || !p.IsSurvivor() || !(params.userid in State))
		return;
	EndDive(p, State[params.userid]);
	ClearFx(State[params.userid]);
}

function Momentum::SpeedFx(p, s) {
	local on = s.move != "" || s.kick || s.wallRun;
	if (on == s.fxOn)
		return;
	s.fxOn = on;
	s.ghosts = 0;
	Streak(p, s, on);
}

function Momentum::Triggered(s, pressed, now) {
	if (Key != 0 && (pressed & Key))
		return true;
	foreach (key in TapKeys) {
		if (!(pressed & key))
			continue;
		if (s.tapKey == key && now - s.tapAt <= TapWindow) {
			s.tapAt = -1.0;
			return true;
		}
		s.tapKey = key;
		s.tapAt = now;
	}
	return false;
}

function Momentum::DiveTriggered(s, pressed, now) {
	foreach (key in DiveKeys) {
		if (!(pressed & key))
			continue;
		if (s.tapKeySide == key && now - s.tapAtSide <= TapWindow) {
			s.tapAtSide = -1.0;
			return key == IN_MOVERIGHT ? 1 : -1;
		}
		s.tapKeySide = key;
		s.tapAtSide = now;
	}
	return 0;
}

function Momentum::Blocked(p) {
	if (NetProps.GetPropInt(p, "m_MoveType") == MOVETYPE_LADDER || p.IsIncapacitated() || p.IsHangingFromLedge())
		return true;
	foreach (prop in [ "m_tongueOwner", "m_pounceAttacker", "m_jockeyAttacker", "m_carryAttacker", "m_pummelAttacker" ]) {
		try { if (NetProps.GetPropEntity(p, prop) != null) return true; } catch (e) {}
	}
	return false;
}

function Momentum::Land(p, s) {
	s.jumps = ExtraJumps;
	s.kicks = AirKicks;
	s.chain = 0;
	EndKick(p, s, false);
	EndWallRun(p, s);
}

function Momentum::MoveDir(p, buttons) {
	local yaw = p.EyeAngles().y * DEG;
	local forward = Vector(cos(yaw), sin(yaw), 0);
	local right = Vector(sin(yaw), -cos(yaw), 0);
	local dir = Vector(0, 0, 0);
	if (buttons & IN_FORWARD) dir = dir + forward;
	if (buttons & IN_BACK) dir = dir - forward;
	if (buttons & IN_MOVERIGHT) dir = dir + right;
	if (buttons & IN_MOVELEFT) dir = dir - right;
	if (dir.Length() < 0.1)
		return null;
	dir.Norm();
	return dir;
}

function Momentum::Flat(v) {
	local f = Vector(v.x, v.y, 0);
	if (f.Length() < 0.001)
		return Vector(1, 0, 0);
	f.Norm();
	return f;
}

function Momentum::ResetFall(p) {
	try { NetProps.SetPropFloat(p, "m_Local.m_flFallVelocity", 0.0); return; } catch (e) {}
	try { NetProps.SetPropFloat(p, "localdata.m_Local.m_flFallVelocity", 0.0); } catch (e) {}
}

function Momentum::SetGravity(p, g) {
	try { if (NetProps.GetPropFloat(p, "m_flGravity") != g) NetProps.SetPropFloat(p, "m_flGravity", g); } catch (e) {}
}

function Momentum::GetLag(p) {
	local lag = 1.0;
	try { lag = NetProps.GetPropFloat(p, "m_flLaggedMovementValue"); } catch (e) {}
	return lag <= 0.0 ? 1.0 : lag;
}

function Momentum::SetLag(p, value) {
	try { NetProps.SetPropFloat(p, "m_flLaggedMovementValue", value); } catch (e) {}
}

function Momentum::StartMove(p, s, buttons, now, move) {
	if (s.move != "")
		return;
	if (!Spend(p, s, move))
		return;
	local dir = MoveDir(p, buttons);
	if (dir == null)
		dir = Flat(p.EyeAngles().Forward());
	local speed = move == "heavy" ? HeavySpeed : (move == "slide" ? SlideSpeed : DashSpeed);
	local time = move == "heavy" ? HeavyTime : (move == "slide" ? SlideTime : DashTime);

	s.move = move;
	s.moveDir = dir;
	s.moveUntil = now + time;
	s.moveHits = {};
	if (move == "dash")
		s.dashCooldownUntil = now + DashCooldown;

	local vel = p.GetVelocity();
	vel.x = dir.x * speed;
	vel.y = dir.y * speed;
	p.SetVelocity(vel);
	if (move == "slide")
		try { p.SetFriction(SlideFriction); } catch (e) {}

	if (move == "heavy") {
		HeavyCheck(p, s);
		Boom(Sounds.Heavy, p);
	} else {
		ShoveCheck(p, s);
		EmitSoundOn(Sounds.Dash, p);
	}
}

function Momentum::EndMove(p, s) {
	if (s.move == "")
		return;
	local was = s.move;
	s.move = "";
	if (was == "slide")
		try { p.SetFriction(1.0); } catch (e) {}
}

function Momentum::ShoveCheck(p, s) {
	local centre = p.GetOrigin() + Vector(0, 0, 32);
	local ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "infected", centre, ShoveRange + 40)) != null) {
		if (!Near(centre, ent, ShoveRange) || !Facing(centre, s.moveDir, ent, ShoveDot) || !MarkOnce(s.moveHits, ent))
			continue;
		if (Boosted(p, s) && ent.GetHealth() > 0) {
			ent.ApplyAbsVelocityImpulse(s.moveDir * LaunchCommon + Vector(0, 0, LaunchUp));
			Credit(p, "dash");
			SuperKill(ent, p);
			Boom(Sounds.Kill, p, RandomInt(82, 96));
			continue;
		}
		ent.TakeDamage(0, DMG_STAGGER, p);
		ent.ApplyAbsVelocityImpulse(s.moveDir * ShovePush + Vector(0, 0, 50));
		EmitSoundOn(Sounds.Shove, p);
	}
	ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "player", centre, ShoveRange + 40)) != null) {
		if (NetProps.GetPropInt(ent, "m_iTeamNum") != TEAM_INFECTED || ent.IsDead() || ent.IsGhost() || ent.GetZombieType() == ZOMBIE_TANK)
			continue;
		if (!Near(centre, ent, ShoveRange) || !Facing(centre, s.moveDir, ent, ShoveDot) || !MarkOnce(s.moveHits, ent))
			continue;
		if (GloryFinish(ent, p, "dash"))
			continue;
		ent.Stagger(p.GetOrigin());
		EmitSoundOn(Sounds.Shove, p);
	}
}

function Momentum::SuperKill(ent, p) {
	local origin = ent.GetOrigin() + Vector(0, 0, 40);
	if (SuperGib) {
		ent.TakeDamage(1000, DMG_CLUB | DMG_BLAST | DMG_ALWAYSGIB, p);
		local fx = SpawnEntityFromTable("info_particle_system", { origin = origin, effect_name = "boomer_explode_D", start_active = 1 });
		if (fx != null)
			DoEntFire("!self", "Kill", "", 2.0, null, fx);
	} else
		ent.TakeDamage(1000, DMG_CLUB | DMG_BLAST, p);
}

function Momentum::HeavyCheck(p, s) {
	local centre = p.GetOrigin() + Vector(0, 0, 32);
	local ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "infected", centre, HeavyRange + 40)) != null) {
		if (ent.GetHealth() <= 0 || !Near(centre, ent, HeavyRange) || !Facing(centre, s.moveDir, ent, HeavyDot) || !MarkOnce(s.moveHits, ent))
			continue;
		ent.ApplyAbsVelocityImpulse(s.moveDir * HeavyLaunch + Vector(0, 0, HeavyLift));
		Credit(p, "heavy");
		SuperKill(ent, p);
		Boom(Sounds.Kill, p, RandomInt(82, 96));
	}
	ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "player", centre, HeavyRange + 40)) != null) {
		if (NetProps.GetPropInt(ent, "m_iTeamNum") != TEAM_INFECTED || ent.IsDead() || ent.IsGhost())
			continue;
		if (!Near(centre, ent, HeavyRange) || !Facing(centre, s.moveDir, ent, HeavyDot) || !MarkOnce(s.moveHits, ent))
			continue;
		if (GloryFinish(ent, p, "dash"))
			continue;
		if (ent.GetZombieType() != ZOMBIE_TANK) {
			ent.Stagger(p.GetOrigin());
			ent.ApplyAbsVelocityImpulse(s.moveDir * (HeavyLaunch * 0.5) + Vector(0, 0, 100));
		}
		ent.TakeDamage(HeavyDamageSpecial, DMG_CLUB, p);
		EmitSoundOn(Sounds.Shove, p);
	}
	foreach (cls in [ "prop_door_rotating", "prop_door_rotating_checkpoint" ]) {
		ent = null;
		while ((ent = Entities.FindByClassnameWithin(ent, cls, centre, HeavyDoorRange)) != null) {
			if (!Facing(centre, s.moveDir, ent, 0.5) || !MarkOnce(s.moveHits, ent))
				continue;
			BreakDoor(ent, p);
		}
	}
	ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "prop_physics", centre, HeavyRange + 40)) != null) {
		if (!Near(centre, ent, HeavyRange + 20) || !Facing(centre, s.moveDir, ent, HeavyDot) || !MarkOnce(s.moveHits, ent))
			continue;
		ent.ApplyAbsVelocityImpulse(s.moveDir * PropLaunch + Vector(0, 0, PropLift));
		ArmExplosive(ent, p);
	}

	ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "witch", centre, HeavyRange + 40)) != null) {
		if (ent.GetHealth() <= 0 || !Near(centre, ent, HeavyRange) || !Facing(centre, s.moveDir, ent, HeavyDot) || !MarkOnce(s.moveHits, ent))
			continue;
		ent.TakeDamage(WitchTackleDamage, DMG_CLUB, p);
		try { ent.Stagger(p.GetOrigin()); } catch (e) {}
		ent.ApplyAbsVelocityImpulse(s.moveDir * (HeavyLaunch * 0.4) + Vector(0, 0, 80));
		Boom(Sounds.Kill, p, RandomInt(82, 96));
	}
}

function Momentum::BreakDoor(door, p) {
	if (door.GetClassname() == "prop_door_rotating_checkpoint" && !BreakCheckpointDoors)
		return;
	if (door.GetHealth() <= 0)
		return;
	local model = "";
	try { model = door.GetModelName().tolower(); } catch (e) {}
	local wood = false;
	foreach (hint in [ "wood", "plank", "doormain", "farm", "mill", "residential", "restaurant", "interior" ])
		if (model.find(hint) != null)
			wood = true;
	EmitSoundOn(wood ? Sounds.DoorWood : Sounds.DoorMetal, p);
	door.TakeDamage(door.GetHealth() + 1000, DMG_CLUB, p);
}

function Momentum::OnGameEvent_player_shoved(params) {
	if (!TeammateShove || !ModeAllowed() || !("userid" in params) || !("attacker" in params))
		return;
	local shoved = null;
	local shover = null;
	try { shoved = GetPlayerFromUserID(params.userid); shover = GetPlayerFromUserID(params.attacker); } catch (e) { return; }
	if (shoved == null || shover == null || !shoved.IsValid() || !shover.IsValid() || shoved == shover)
		return;
	if (!shoved.IsSurvivor() || !shover.IsSurvivor() || shoved.IsDead())
		return;
	if (!BotsShoveTeammates && IsPlayerABot(shover))
		return;
	if (Blocked(shoved))
		return;
	local weapon = null;
	try { weapon = shover.GetActiveWeapon(); } catch (e) {}
	if (weapon != null && weapon.IsValid() && (weapon.GetClassname() in ItemWeapons))
		return;
	local dir = Flat(shoved.GetOrigin() - shover.GetOrigin());
	if (dir.Length() < 0.1)
		dir = Flat(shover.EyeAngles().Forward());
	shoved.ApplyAbsVelocityImpulse(dir * TeammateShovePush + Vector(0, 0, TeammateShoveLift));
	ResetFall(shoved);
	try { shoved.Stagger(shover.GetOrigin()); } catch (e) {}
	try {
		NetProps.SetPropIntArray(shoved, "m_NetGestureSequence", shoved.LookupSequence("ACT_TERROR_FLINCH"), 6);
		NetProps.SetPropIntArray(shoved, "m_NetGestureActivity", shoved.LookupActivity("ACT_TERROR_FLINCH"), 6);
		NetProps.SetPropFloatArray(shoved, "m_NetGestureStartTime", Time(), 6);
	} catch (e) {}
	local damage = TeammateShoveDamage;
	if (shoved.GetHealth() - damage < 1)
		damage = shoved.GetHealth() - 1;
	if (damage > 0)
		shoved.TakeDamage(damage, DMG_CLUB, shover);
	EmitSoundOn(Sounds.Shove, shoved);
}

function Momentum::OnGameEvent_entity_shoved(params) {
	if (!ShoveBreaksDoors || !ModeAllowed() || !("entityid" in params) || !("attacker" in params))
		return;
	local door = EntIndexToHScript(params.entityid);
	if (door == null || !door.IsValid())
		return;
	local cls = door.GetClassname();
	if (cls != "prop_door_rotating" && cls != "prop_door_rotating_checkpoint")
		return;
	local p = null;
	try { p = GetPlayerFromUserID(params.attacker); } catch (e) { return; }
	if (p == null || !p.IsValid() || !p.IsSurvivor())
		return;
	BreakDoor(door, p);
}

function Momentum::HyperAnyone() {
	local now = Time();
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null) {
		if (!p.IsSurvivor() || p.IsDead() || IsPlayerABot(p))
			continue;
		local id = p.GetPlayerUserId();
		if (!(id in State))
			continue;
		local s = State[id];
		if (now < s.hyperUntil || s.lastStand)
			return true;
	}
	return false;
}

function Momentum::LastStandAnyone() {
	foreach (id, s in State)
		if (s.lastStand) {
			local p = null;
			try { p = GetPlayerFromUserID(id); } catch (e) {}
			if (p != null && p.IsValid() && p.IsSurvivor() && !p.IsDead() && !IsPlayerABot(p))
				return true;
		}
	return false;
}

function Momentum::CheckLastStand(p, s) {
	local alone = true;
	local q = null;
	while ((q = Entities.FindByClassname(q, "player")) != null)
		if (q != p && q.IsSurvivor() && !q.IsDead())
			alone = false;
	if (alone && !s.lastStand) {
		s.lastStand = true;
		Refill(p);
		HyperBang(p);
	} else if (!alone && s.lastStand)
		s.lastStand = false;
}

function Momentum::Beat(p, s, now) {
	local health = p.GetHealth() + p.GetHealthBuffer();
	s.beatAt = now + (health < BeatLowHealth ? BeatFast : BeatPeriod);
	for (local i = 0; i < BeatLayers; i++)
		try { EmitSoundOnClient(Heartbeat, p); } catch (e) { EmitSoundOn(Heartbeat, p); }
}

function Momentum::Sway(p, s, now) {
	local jockey = null;
	try { jockey = NetProps.GetPropEntity(p, "m_jockeyAttacker"); } catch (e) {}
	if (jockey == null || !jockey.IsValid()) {
		if (s.swaying) {
			s.swaying = false;
			s.swayRoll = 0.0;
			SetRoll(p, 0.0);
		}
		return;
	}
	s.swaying = true;
	local yaw = p.EyeAngles().y * DEG;
	local right = Vector(sin(yaw), -cos(yaw), 0);
	local lateral = p.GetVelocity().Dot(right);
	local want = lateral / 200.0 * SwayRoll;
	if (want > SwayRoll) want = SwayRoll;
	if (want < -SwayRoll) want = -SwayRoll;
	s.swayRoll += (want - s.swayRoll) * 0.25;
	local roll = s.swayRoll + sin(now * 7.0) * SwayLurch;
	try {
		NetProps.SetPropVector(p, "m_Local.m_vecPunchAngle", Vector(sin(now * 5.0) * SwayPitch, 0, roll));
		NetProps.SetPropVector(p, "m_Local.m_vecPunchAngleVel", Vector(0, 0, 0));
	} catch (e) {}
}

function Momentum::Pinner(p) {
	foreach (prop, kind in { m_pounceAttacker = "hunter", m_jockeyAttacker = "jockey", m_tongueOwner = "smoker", m_pummelAttacker = "charger" }) {
		local ent = null;
		try { ent = NetProps.GetPropEntity(p, prop); } catch (e) {}
		if (ent != null && ent.IsValid())
			return { ent = ent, kind = kind };
	}
	return null;
}

function Momentum::Struggle(p, s, state) {
	if (state == s.struggle)
		return;
	s.struggle = state;
	if (("HyperFeedback" in getroottable()) && ("Struggle" in ::HyperFeedback) && !IsPlayerABot(p))
		try { ::HyperFeedback.Struggle(state, p); } catch (e) {}
}

function Momentum::BreakFree(p, s, pressed, now) {
	local pin = Pinner(p);
	if (pin == null) {
		s.pinnedAt = 0.0;
		s.breakTaps = 0;
		s.breakFailed = false;
		Struggle(p, s, "");
		return;
	}
	if (s.pinnedAt <= 0.0) {
		s.pinnedAt = now;
		s.breakTaps = 0;
		s.breakFailed = false;
	}
	if (s.breakFailed) {
		Struggle(p, s, "fail");
		return;
	}
	if (now - s.pinnedAt < BreakFreeDelay) {
		Struggle(p, s, "wait");
		return;
	}
	if (pressed & IN_FORWARD) {
		if (s.breakTaps == 0)
			s.breakFirst = now;
		s.breakTaps++;
	}
	if (s.breakTaps > 0 && now - s.breakFirst > BreakFreeWindow) {
		s.breakTaps = 0;
		s.breakFailed = true;
		Struggle(p, s, "fail");
		EmitSoundOn(Sounds.Deny, p);
		return;
	}
	if (s.breakTaps < BreakFreeTaps) {
		Struggle(p, s, s.breakTaps.tostring());
		return;
	}
	s.breakTaps = 0;
	s.breakFailed = true;
	if (s.stamina < BreakFreeCost) {
		Struggle(p, s, "fail");
		EmitSoundOn(Sounds.Deny, p);
		return;
	}
	Struggle(p, s, "");
	Spend(p, s, "breakfree");
	local ent = pin.ent;
	if (pin.kind == "charger")
		ent.TakeDamage(BreakFreeChargerDamage, DMG_CLUB, p);
	else {
		ent.TakeDamage(BreakFreeDamage, DMG_CLUB, p);
		try { ent.Stagger(p.GetOrigin()); } catch (e) {}
	}
	if (BreakFreeSelfDamage > 0)
		p.TakeDamage(BreakFreeSelfDamage, 0, Entities.First());
	Boom(Sounds.Heavy, p);
	Scored(p, "breakfree");
}

function Momentum::RollCheck(p, s, buttons) {
	if (s.rolled || !(buttons & IN_DUCK) || s.kick || s.wallRun)
		return;
	local vel = p.GetVelocity();
	if (vel.z > -RollFallSpeed)
		return;
	local feet = p.GetOrigin();
	local trace = { start = feet, end = feet - Vector(0, 0, RollReach), ignore = p };
	TraceLine(trace);
	if (!trace.hit)
		return;
	if (s.stamina < RollCost)
		return;
	Spend(p, s, "roll");
	ResetFall(p);
	s.rolled = true;
	EmitSoundOn(Sounds.Dash, p);
}

function Momentum::OnGameEvent_player_hurt_concise(params) {
	if (!ModeAllowed() || !("userid" in params) || !("type" in params) || !("dmg_health" in params) || params.type != 32)
		return;
	local p = null;
	try { p = GetPlayerFromUserID(params.userid); } catch (e) { return; }
	if (p == null || !p.IsValid() || !p.IsSurvivor() || IsPlayerABot(p) || p.IsDead())
		return;
	local s = StateOf(p);
	local boosted = Boosted(p, s);
	if (params.dmg_health < HardFall) {
		s.stamina -= LightFallStamina;
		if (s.stamina < 0.0) s.stamina = 0.0;
		if (!boosted)
			Slow(s, LightLandSlow, LightLandSeconds);
		return;
	}
	s.stamina -= HardFallStamina;
	if (s.stamina < 0.0) s.stamina = 0.0;
	LandingFx(p);
	KnockDownAround(p);
	if (boosted || p.IsIncapacitated() || p.IsDominatedBySpecialInfected() || LaunchedBySpecial(p))
		return;
	Slow(s, HardLandSlow, HardLandSeconds);
}

function Momentum::Slow(s, mult, seconds) {
	local until = Time() + seconds;
	if (Time() < s.slowUntil && s.slowMult <= mult && s.slowUntil >= until)
		return;
	s.slowMult = mult;
	s.slowUntil = until;
}

function Momentum::LandingFx(p) {
	local origin = p.GetOrigin();
	ScreenShake(origin, 8.0, 16.0, 0.5, 125.0, 0, false);
	local water = false;
	try { water = NetProps.GetPropInt(p, "m_nWaterLevel") != 0; } catch (e) {}
	local sound = water ? LandingSounds.water[RandomInt(0, LandingSounds.water.len() - 1)] : LandingSounds.ground;
	EmitSoundOn(sound, p);
	EmitSoundOn(sound, p);
	local dust = SpawnEntityFromTable("info_particle_system", { effect_name = water ? LandingParticles.water : LandingParticles.ground,
		origin = water ? origin - Vector(0, 0, 32) : origin, start_active = 1 });
	if (dust != null)
		DoEntFire("!self", "Kill", "", 1.0, null, dust);
}

function Momentum::KnockDownAround(p) {
	local origin = p.GetOrigin();
	local ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "infected", origin, HardLandingRadius)) != null) {
		if (ent.GetHealth() <= 0)
			continue;
		local away = ent.GetOrigin() - origin;
		away.z = 0;
		if (away.Length() < 1.0)
			away = Vector(1, 0, 0);
		away.Norm();
		ent.TakeDamage(0, DMG_STAGGER, p);
		ent.ApplyAbsVelocityImpulse(away * 200 + Vector(0, 0, 60));
	}
}

function Momentum::LaunchedBySpecial(p) {
	local seq = p.GetSequence();
	foreach (name in [ "ACT_TERROR_IDLE_FALL_FROM_TANKPUNCH", "ACT_TERROR_TANKPUNCH_LAND", "ACT_TERROR_IDLE_FALL_FROM_CHARGERHIT", "ACT_TERROR_CHARGERHIT_LAND_SLOW" ])
		if (seq == p.LookupSequence(name))
			return true;
	return false;
}

function Momentum::ArmExplosive(prop, p) {
	local model = "";
	try { model = prop.GetModelName().tolower(); } catch (e) { return; }
	foreach (hint in ExplosiveHints) {
		if (model.find(hint) != null) {
			DoEntFire("!self", "RunScriptCode", "self.TakeDamage(500, 64, Entities.First())", ExplosiveFuse, p, prop);
			return;
		}
	}
}

function Momentum::OpenDoors(p, s) {
	local centre = p.GetOrigin() + Vector(0, 0, 32);
	foreach (cls in [ "prop_door_rotating", "prop_door_rotating_checkpoint" ]) {
		local door = null;
		while ((door = Entities.FindByClassnameWithin(door, cls, centre, DoorOpenRange)) != null) {
			if (!Facing(centre, s.moveDir, door, 0.5) || !MarkOnce(s.moveHits, door))
				continue;
			local state = 1;
			try { state = NetProps.GetPropInt(door, "m_eDoorState"); } catch (e) {}
			if (state == 0)
				DoEntFire("!self", "OpenAwayFrom", "!activator", 0, p, door);
		}
	}
}

function Momentum::OnGameEvent_player_ledge_grab(params) {
	if (!LedgeVault || !ModeAllowed() || !("userid" in params))
		return;
	local p = null;
	try { p = GetPlayerFromUserID(params.userid); } catch (e) { return; }
	if (p == null || !p.IsValid() || !p.IsSurvivor() || IsPlayerABot(p))
		return;
	local s = StateOf(p);
	s.vaultRevives = NetProps.GetPropInt(p, "m_currentReviveCount");
	DoEntFire("!self", "RunScriptCode", "::Momentum.Vault(" + params.userid + ")", 0.15, null, Entities.First());
}

function Momentum::Vault(userid) {
	local p = null;
	try { p = GetPlayerFromUserID(userid); } catch (e) { return; }
	if (p == null || !p.IsValid() || p.IsDead() || !p.IsHangingFromLedge())
		return;
	local s = StateOf(p);
	try { p.ReviveFromIncap(); } catch (e) {}
	NetProps.SetPropInt(p, "m_currentReviveCount", s.vaultRevives);
	NetProps.SetPropInt(p, "m_bIsOnThirdStrike", 0);
	if (p.IsHangingFromLedge()) {
		local up = Flat(p.EyeAngles().Forward());
		p.SetOrigin(p.GetOrigin() + up * 40 + Vector(0, 0, 70));
		p.SetVelocity(Vector(0, 0, 150));
	}
	ResetFall(p);
	EmitSoundOn(Sounds.Jump, p);
}

function Momentum::SolidAt(p, from, dir, reach) {
	local trace = { start = from, end = from + dir * reach, ignore = p };
	TraceLine(trace);
	if (!trace.hit)
		return false;
	if (("enthit" in trace) && trace.enthit != null) {
		local cls = trace.enthit.GetClassname();
		if (cls == "player" || cls == "infected" || cls == "witch")
			return false;
	}
	return true;
}

function Momentum::WallAt(p, centre, dir) {
	local feet = p.GetOrigin();
	if (!SolidAt(p, feet + Vector(0, 0, 20), dir, WallRunReach))
		return false;
	if (!SolidAt(p, feet + Vector(0, 0, 60), dir, WallRunReach))
		return false;
	local ahead = Flat(p.EyeAngles().Forward()) * 0.8 + dir;
	ahead.Norm();
	return SolidAt(p, centre, ahead, WallRunReach * 1.7);
}

function Momentum::SetRoll(p, roll) {
	try {
		NetProps.SetPropVector(p, "m_Local.m_vecPunchAngle", Vector(0, 0, roll));
		NetProps.SetPropVector(p, "m_Local.m_vecPunchAngleVel", Vector(0, 0, 0));
	} catch (e) {}
}

function Momentum::WallRunUpdate(p, s, buttons, pressed, now) {
	local holding = (buttons & IN_FORWARD) != 0;
	if (!holding || s.stamina <= 0.0) {
		EndWallRun(p, s);
		return false;
	}
	local yaw = p.EyeAngles().y * DEG;
	local right = Vector(sin(yaw), -cos(yaw), 0);
	local centre = p.GetOrigin() + Vector(0, 0, 36);

	if (!s.wallRun) {
		local vel = p.GetVelocity();
		if (Vector(vel.x, vel.y, 0).Length() < WallRunMinSpeed || s.stamina < 5.0)
			return false;
		local side = 0;
		if (WallAt(p, centre, right))
			side = 1;
		else if (WallAt(p, centre, right * -1.0))
			side = -1;
		if (side == 0)
			return false;
		s.wallRun = true;
		s.wallSide = side;
		EndMove(p, s);
		SetGravity(p, WallRunGravity);
		if (vel.z < WallRunHop) {
			vel.z = WallRunHop;
			p.SetVelocity(vel);
		}
		ResetFall(p);
		EmitSoundOn(Sounds.Dash, p);
		return false;
	}

	if (!WallAt(p, centre, right * s.wallSide.tofloat())) {
		EndWallRun(p, s);
		return false;
	}
	if (pressed & IN_JUMP) {
		WallJump(p, s, right);
		return true;
	}
	s.stamina -= WallRunDrain * 0.0333;
	if (s.stamina < 0.0)
		s.stamina = 0.0;
	s.spentAt = now;
	SetRoll(p, -s.wallSide * WallRunRoll);
	return false;
}

function Momentum::WallJump(p, s, right) {
	local away = right * (-s.wallSide.tofloat());
	local forward = Flat(p.EyeAngles().Forward());
	p.SetVelocity(forward * WallJumpForward + away * WallJumpAway + Vector(0, 0, WallJumpUp));
	ResetFall(p);
	EndWallRun(p, s);
	s.jumps = ExtraJumps;
	EmitSoundOn(Sounds.Jump, p);
}

function Momentum::EndWallRun(p, s) {
	if (!s.wallRun)
		return;
	s.wallRun = false;
	s.wallSide = 0;
	s.wallRunAt = Time();
	if (!s.kick)
		SetGravity(p, 1.0);
	SetRoll(p, 0.0);
}

function Momentum::StartKick(p, s, now) {
	if (!Spend(p, s, "kick"))
		return;
	local dir = p.EyeAngles().Forward();
	if (dir.z < -0.6) {
		dir.z = -0.6;
		dir.Norm();
	}
	local pitch = p.EyeAngles().x;
	if (pitch > 180.0) pitch -= 360.0;
	local level = 1.0 - fabs(pitch) / 90.0;
	if (level < 0.0) level = 0.0;
	local launch = s.wallRun || now - s.wallRunAt <= WallKickGrace;

	EndMove(p, s);
	EndWallRun(p, s);
	s.wallRunAt = -10.0;
	p.SetVelocity(dir * (launch ? KickSpeed * WallKickSpeed : KickSpeed) + Vector(0, 0, KickLift * level));
	ResetFall(p);
	SetGravity(p, KickGravity);
	s.kick = true;
	s.kickUntil = now + KickTime;
	s.kickDir = dir;
	s.kickHits = {};
	s.kickLaunch = launch;
	s.kicks--;
	EmitSoundOn(Sounds.Kick, p);
}

function Momentum::EndKick(p, s, hit) {
	if (!s.kick)
		return;
	s.kick = false;
	SetGravity(p, 1.0);
	if (!hit && Boosted(p, s))
		s.kicks = AirKicks;
}

function Momentum::KickCheck(p, s) {
	local centre = p.GetOrigin() + Vector(0, 0, 36);
	local hit = false;
	local kills = 0;
	local solid = false;
	local ent = null;

	while ((ent = Entities.FindByClassnameWithin(ent, "prop_physics", centre, KickRange + 40)) != null) {
		if (!Near(centre, ent, KickRange + 20) || !Facing(centre, s.kickDir, ent, KickDot) || !MarkOnce(s.kickHits, ent))
			continue;
		ent.ApplyAbsVelocityImpulse(s.kickDir * PropLaunch + Vector(0, 0, PropLift));
		ArmExplosive(ent, p);
		EmitSoundOn(Sounds.Shove, p);
		solid = true;
	}
	ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "tank_rock", centre, KickRange + 60)) != null) {
		if (!MarkOnce(s.kickHits, ent))
			continue;
		ent.TakeDamage(1000, DMG_CLUB, p);
		Boom(Sounds.Kill, p, RandomInt(82, 96));
		solid = true;
	}
	ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "infected", centre, KickRange + KickBodyHigh)) != null) {
		if (ent.GetHealth() <= 0 || !KickReach(centre, s.kickDir, ent) || !MarkOnce(s.kickHits, ent))
			continue;
		hit = true;
		ent.ApplyAbsVelocityImpulse(s.kickDir * LaunchCommon + Vector(0, 0, LaunchUp));
		Credit(p, "kick");
		SuperKill(ent, p);
		Boom(Sounds.Kill, p, RandomInt(82, 96));
		kills++;
	}
	ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "witch", centre, KickRange + KickBodyHigh)) != null) {
		if (ent.GetHealth() <= 0 || !KickReach(centre, s.kickDir, ent) || !MarkOnce(s.kickHits, ent))
			continue;
		ent.TakeDamage(KickDamageWitch, DMG_CLUB, p);
		try { ent.Stagger(p.GetOrigin()); } catch (e) {}
		EmitSoundOn(Sounds.Shove, p);
		hit = true;
	}
	ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "player", centre, KickRange + KickBodyHigh)) != null) {
		if (NetProps.GetPropInt(ent, "m_iTeamNum") != TEAM_INFECTED || ent.IsDead() || ent.IsGhost())
			continue;
		if (!KickReach(centre, s.kickDir, ent) || !MarkOnce(s.kickHits, ent))
			continue;
		hit = true;
		if (GloryFinish(ent, p, "kick")) {
			kills++;
			continue;
		}
		local scale = s.kickLaunch ? WallKickDamage : 1.0;
		local amount = (ent.GetZombieType() == ZOMBIE_TANK ? KickDamageTank : KickDamageSpecial) * scale;
		ent.TakeDamage(amount, KickDamageType, p);
		if (ent.GetZombieType() != ZOMBIE_TANK)
			ent.Stagger(p.GetOrigin());
		EmitSoundOn(Sounds.Shove, p);
	}
	if (hit) {
		Bounce(p, s, kills);
		return;
	}
	if (!solid) {
		local trace = { start = centre, end = centre + s.kickDir * WallKickReach, ignore = p };
		TraceLine(trace);
		if (trace.hit && (!("enthit" in trace) || trace.enthit == null || trace.enthit.GetClassname() != "player"))
			solid = true;
	}
	if (solid)
		WallBounce(p, s);
}

function Momentum::WallBounce(p, s) {
	local back = Flat(s.kickDir) * -1.0;
	p.SetVelocity(back * BounceBack + Vector(0, 0, BounceUp));
	ResetFall(p);
	EndKick(p, s, true);
	s.kicks = AirKicks;
	EmitSoundOn(Sounds.Dash, p);
}

function Momentum::Bounce(p, s, kills) {
	local back = Flat(s.kickDir) * -1.0;
	p.SetVelocity(back * BounceBack + Vector(0, 0, BounceUp));
	ResetFall(p);
	EndKick(p, s, true);
	if (RefundOnHit) {
		s.kicks = AirKicks;
		Refund(p, s, Cost.kick);
	}
	if (kills > 0) {
		s.chain += kills;
		s.stacks += kills;
		if (s.stacks > StackMax)
			s.stacks = StackMax;
		s.stackUntil = Time() + StackSeconds;
		Boom(Sounds.Chain, p);
		if (s.chain >= HyperChain && s.hyperUntil <= 0.0)
			StartHyper(p, s);
	}
}

function Momentum::StartHyper(p, s) {
	s.hyperUntil = Time() + HyperSeconds;
	Refill(p);
	HyperBang(p);
}

function Momentum::StartDive(p, s, side, now) {
	if (now < s.diveCooldownUntil || !Spend(p, s, "dive"))
		return;
	local yaw = p.EyeAngles().y * DEG;
	local right = Vector(sin(yaw), -cos(yaw), 0);
	local vel = p.GetVelocity();
	vel.x = right.x * DiveSpeed * side;
	vel.y = right.y * DiveSpeed * side;
	p.SetVelocity(vel);
	s.dive = "dash";
	s.diveUntil = now + DiveTime;
	s.diveCooldownUntil = now + DiveCooldown;
	try {
		if (NetProps.GetPropInt(p, "m_takedamage") == 2) {
			NetProps.SetPropInt(p, "m_takedamage", 0);
			s.diveGod = true;
		}
	} catch (e) {}
	EmitSoundOn(Sounds.Dash, p);
}

function Momentum::DiveUpdate(p, s, now) {
	if (now < s.diveUntil)
		return;
	if (s.dive == "dash") {
		DiveVulnerable(p, s);
		s.dive = "slow";
		s.diveUntil = now + DiveSlowTime;
	} else
		EndDive(p, s);
}

function Momentum::DiveVulnerable(p, s) {
	if (!s.diveGod)
		return;
	s.diveGod = false;
	try { if (NetProps.GetPropInt(p, "m_takedamage") == 0) NetProps.SetPropInt(p, "m_takedamage", 2); } catch (e) {}
}

function Momentum::EndDive(p, s) {
	if (s.dive == "")
		return;
	s.dive = "";
	DiveVulnerable(p, s);
}

function Momentum::AbilityFlag(p, prop) {
	try {
		local ability = NetProps.GetPropEntity(p, "m_customAbility");
		if (ability == null)
			return false;
		return NetProps.GetPropInt(ability, prop) != 0;
	} catch (e) { return false; }
}

function Momentum::UpdateInfected(p) {
	local s = StateOf(p);
	local now = Time();
	local buttons = NetProps.GetPropInt(p, "m_nButtons");
	local pressed = 0;
	try { pressed = NetProps.GetPropInt(p, "m_afButtonPressed"); } catch (e) {}
	pressed = pressed | (buttons & ~s.prev);
	s.prev = buttons;
	Regen(p, s, now);

	local onGround = (NetProps.GetPropInt(p, "m_fFlags") & FL_ONGROUND) != 0;
	if (onGround && !s.ground) {
		s.jumps = ExtraJumps;
		EndWallRun(p, s);
	}
	s.ground = onGround;
	if (p.IsIncapacitated() || p.IsStaggering()) {
		EndWallRun(p, s);
		return;
	}

	local zt = p.GetZombieType();
	if (zt == 8) {
		if (RockParry && (pressed & IN_ATTACK))
			TankParryCheck(p, false);
		return;
	}
	if (zt == 1)
		BlinkCheck(p, s, pressed, now);
	else if (zt == 3) {
		local held = null;
		try { held = NetProps.GetPropEntity(p, "m_pounceVictim"); } catch (e) {}
		local lunging = AbilityFlag(p, "m_isLunging");
		if (held != null || lunging)
			EndWallRun(p, s);
		else if (!onGround)
			WallRunUpdate(p, s, buttons, pressed, now);
		else if (s.wallRun)
			EndWallRun(p, s);
	} else if (zt == 5) {
		local riding = null;
		try { riding = NetProps.GetPropEntity(p, "m_jockeyVictim"); } catch (e) {}
		if ((pressed & IN_JUMP) && riding == null && !onGround && s.jumps > 0)
			JockeyDash(p, s, buttons);
	}
}

function Momentum::JockeyDash(p, s, buttons) {
	if (!Spend(p, s, "jump"))
		return;
	local dir = MoveDir(p, buttons);
	if (dir == null)
		dir = Flat(p.EyeAngles().Forward());
	local vel = p.GetVelocity();
	p.SetVelocity(Vector(dir.x * JockeyDashSpeed, dir.y * JockeyDashSpeed, (vel.z > 0 ? vel.z : 0) + JockeyDashLift));
	ResetFall(p);
	s.jumps--;
	EmitSoundOn(Sounds.Dash, p);
}

function Momentum::BlinkCheck(p, s, pressed, now) {
	if (!(pressed & BlinkKey))
		return;
	local tongue = null;
	try { tongue = NetProps.GetPropEntity(p, "m_tongueVictim"); } catch (e) {}
	if (tongue != null || now < s.blinkAt)
		return;
	if (s.stamina < Cost.blink) {
		EmitSoundOn(Sounds.Deny, p);
		return;
	}
	local survivors = [];
	local q = null;
	while ((q = Entities.FindByClassname(q, "player")) != null)
		if (q.IsSurvivor() && !q.IsDead())
			survivors.append(q);

	local spot = null;
	if (("InfectedMoves" in getroottable()) && ("HiddenSpot" in ::InfectedMoves))
		try { spot = ::InfectedMoves.HiddenSpot(p, survivors, BlinkMin, BlinkMax); } catch (e) { spot = null; }
	if (spot == null) {
		EmitSoundOn(Sounds.Deny, p);
		return;
	}
	Spend(p, s, "blink");
	local origin = p.GetOrigin();
	foreach (at in [ origin, spot ]) {
		local cloud = SpawnEntityFromTable("info_particle_system", { effect_name = BlinkCloud, start_active = 1, origin = at + Vector(0, 0, 30) });
		if (cloud != null)
			DoEntFire("!self", "Kill", "", 2.0, null, cloud);
	}
	p.SetOrigin(spot);
	p.SetVelocity(Vector(0, 0, 0));
	s.blinkAt = now + BlinkCooldown;
	EmitSoundOn(Sounds.Dash, p);
}

function Momentum::RockThrower(rock) {
	local tank = null;
	try { tank = NetProps.GetPropEntity(rock, "m_hThrower"); } catch (e) {}
	if (tank == null)
		try { tank = NetProps.GetPropEntity(rock, "m_hOwnerEntity"); } catch (e) {}
	if (tank == null || !tank.IsValid() || tank.GetClassname() != "player" || tank.IsDead())
		return null;
	return tank;
}

function Momentum::Deflect(ent, dir, speed) {
	local want = dir * speed + Vector(0, 0, ParryLift);
	try { ent.SetVelocity(want); } catch (e) {}
	local left = want - ent.GetVelocity();
	if (left.Length() > 1.0)
		try { ent.ApplyAbsVelocityImpulse(left); } catch (e) {}
}

function Momentum::Aim(view, from, target, height) {
	if (target == null || !target.IsValid() || target.IsDead())
		return view;
	local to = (target.GetOrigin() + Vector(0, 0, height)) - from;
	if (to.Length() < 1.0)
		return view;
	to.Norm();
	return view.Dot(to) >= ParryAssist ? to : view;
}

function Momentum::InFront(eye, view, ent) {
	local to = ent.GetOrigin() - eye;
	if (to.Length() < 1.0)
		return true;
	to.Norm();
	return view.Dot(to) >= ParryDot;
}

function Momentum::Parried(p) {
	if (ParryFlash > 0 && !IsPlayerABot(p)) {
		local fade = SpawnEntityFromTable("env_fade", { spawnflags = "5", duration = "0.15", holdtime = "0", renderamt = ParryFlash.tostring(), rendercolor = "255 250 240" });
		if (fade != null) {
			DoEntFire("!self", "Fade", "", 0, p, fade);
			DoEntFire("!self", "Kill", "", 1.0, null, fade);
		}
	}
	Boom(Sounds.Parry, p);
	Flash(p, "parry");
	Scored(p, "parry");
}

function Momentum::Flash(p, name) {
	if (p == null || !p.IsValid() || IsPlayerABot(p))
		return;
	if (("HyperFeedback" in getroottable()) && ("FlashFor" in ::HyperFeedback))
		try { ::HyperFeedback.FlashFor(p, name); } catch (e) {}
}

function Momentum::ParryCheck(p, s) {
	local eye = p.EyePosition();
	local view = p.EyeAngles().Forward();
	foreach (cls in [ "tank_rock", "spitter_projectile" ]) {
		if ((cls == "tank_rock" && !RockParry) || (cls == "spitter_projectile" && !SpitParry))
			continue;
		local ent = null;
		while ((ent = Entities.FindByClassnameWithin(ent, cls, eye, ParryRange)) != null) {
			if (!InFront(eye, view, ent) || !MarkOnce(s.parried, ent))
				continue;
			if (cls == "tank_rock")
				ParryRock(p, ent, view);
			else
				ParrySpit(p, ent, view);
		}
	}
}

function Momentum::ParryRock(p, rock, view) {
	local index = rock.GetEntityIndex();
	local tank = (index in Rocks) ? Rocks[index].tank : RockThrower(rock);
	local speed = rock.GetVelocity().Length() * ParrySpeedScale;
	Deflect(rock, Aim(view, rock.GetOrigin(), tank, 60.0), speed > ParrySpeed ? speed : ParrySpeed);
	try { NetProps.SetPropEntity(rock, "m_hThrower", p); } catch (e) {}
	local volley = (index in Rocks) ? Rocks[index].volley + 1 : 1;
	Rocks[index] <- { ent = rock, tank = tank, by = p, volley = volley, tankTried = 0.0, back = false };
	Parried(p);
}

function Momentum::ParrySpit(p, spit, view) {
	local spitter = null;
	try { spitter = NetProps.GetPropEntity(spit, "m_hThrower"); } catch (e) {}
	if (spitter != null && (!spitter.IsValid() || spitter.GetClassname() != "player" || spitter.IsSurvivor()))
		spitter = null;
	local speed = spit.GetVelocity().Length() * ParrySpeedScale;
	Deflect(spit, Aim(view, spit.GetOrigin(), spitter, 40.0), speed > ParrySpeed ? speed : ParrySpeed);
	try { NetProps.SetPropEntity(spit, "m_hThrower", p); } catch (e) {}
	Spits[spit.GetEntityIndex()] <- { ent = spit, by = p, pos = spit.GetOrigin() };
	Parried(p);
}

function Momentum::OnGameEvent_spit_burst(params) {
	if (!SpitParry || Spits.len() == 0 || !("subject" in params))
		return;
	local at = null;
	local subject = null;
	try { subject = EntIndexToHScript(params.subject); } catch (e) {}
	if (subject != null && subject.IsValid())
		at = subject.GetOrigin();
	foreach (index, sp in clone Spits) {
		local pos = (sp.ent != null && sp.ent.IsValid()) ? sp.ent.GetOrigin() : sp.pos;
		if (index != params.subject && (at == null || (pos - at).Length() > 96.0))
			continue;
		delete Spits[index];
		SpitBurst(sp.by, at != null ? at : pos);
		return;
	}
}

function Momentum::SpitBurst(by, pos) {
	local gfx = SpawnEntityFromTable("info_particle_system", { effect_name = SpitBurstEffect, origin = pos + Vector(0, 0, 4), start_active = 1 });
	if (gfx != null)
		DoEntFire("!self", "Kill", "", 1.5, null, gfx);
	ScreenShake(pos, 8.0, 40.0, 0.5, SpitBurstRadius * 2.0, 0, false);
	local attacker = (by != null && by.IsValid()) ? by : Entities.First();
	local ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "infected", pos, SpitBurstRadius)) != null)
		if (ent.GetHealth() > 0)
			ent.TakeDamage(SpitBurstDamage, DMG_BLAST, attacker);
	ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "player", pos, SpitBurstRadius)) != null) {
		if (NetProps.GetPropInt(ent, "m_iTeamNum") != TEAM_INFECTED || ent.IsDead() || ent.IsGhost())
			continue;
		ent.TakeDamage(SpitBurstSpecial, DMG_BLAST, attacker);
		if (ent.GetZombieType() != ZOMBIE_TANK)
			try { ent.Stagger(pos); } catch (e) {}
	}
	if (by != null && by.IsValid()) {
		Boom(Sounds.Parry, by, 70);
		Flash(by, "kill");
	}
	DoEntFire("!self", "RunScriptCode", "::Momentum.DrainPool(Vector(" + pos.x + "," + pos.y + "," + pos.z + "))", 0.1, null, Entities.First());
}

function Momentum::DrainPool(pos) {
	local found = [];
	local pool = null;
	while ((pool = Entities.FindByClassnameWithin(pool, "insect_swarm", pos, SpitBurstRadius)) != null)
		found.append(pool);
	foreach (pool in found)
		if (pool.IsValid())
			pool.Kill();
}

function Momentum::TankParryCheck(tank, ai) {
	local eye = tank.EyePosition();
	local view = tank.EyeAngles().Forward();
	local hit = false;
	foreach (index, r in clone Rocks) {
		if (r.tank != tank || r.back || r.ent == null || !r.ent.IsValid())
			continue;
		if ((r.ent.GetOrigin() - eye).Length() > TankParryRange || !Facing(eye, view, r.ent, TankParryDot))
			continue;
		if (r.by == null || !r.by.IsValid() || r.by.IsDead())
			continue;
		local to = (r.by.GetOrigin() + Vector(0, 0, 50)) - r.ent.GetOrigin();
		to.Norm();
		Deflect(r.ent, to, ParrySpeed);
		try { NetProps.SetPropEntity(r.ent, "m_hThrower", tank); } catch (e) {}
		r.back = true;
		Boom(Sounds.Parry, tank);
		if (ParryCue && !IsPlayerABot(r.by) && ("HyperFeedback" in getroottable()) && ("Cue" in ::HyperFeedback))
			try { ::HyperFeedback.Cue("front", r.by); } catch (e) {}
		hit = true;
	}
	if (hit && ai) {
		try {
			NetProps.SetPropIntArray(tank, "m_NetGestureSequence", tank.LookupSequence("ACT_HULK_ATTACK_LOW"), 5);
			NetProps.SetPropFloatArray(tank, "m_NetGestureStartTime", Time(), 5);
		} catch (e) {}
	}
}

function Momentum::RockTick() {
	local now = Time();
	foreach (index, sp in clone Spits) {
		if (sp.ent != null && sp.ent.IsValid())
			sp.pos = sp.ent.GetOrigin();
		else if (!("goneAt" in sp))
			sp.goneAt <- now;
		else if (now - sp.goneAt > 0.5)
			delete Spits[index];
	}
	foreach (index, r in clone Rocks) {
		if (r.ent == null || !r.ent.IsValid()) {
			delete Rocks[index];
			continue;
		}
		local tank = r.tank;
		if (tank == null || !tank.IsValid() || tank.IsDead()) {
			delete Rocks[index];
			continue;
		}
		if (r.back)
			continue;
		local d = (r.ent.GetOrigin() - (tank.GetOrigin() + Vector(0, 0, 40))).Length();
		if (IsPlayerABot(tank) && d <= TankParryRange && now - r.tankTried >= AiParryCooldown) {
			r.tankTried = now;
			if (RandomInt(1, 100) <= AiParryChance) {
				TankParryCheck(tank, true);
				continue;
			}
		}
		if (d <= 80.0) {
			local attacker = (r.by != null && r.by.IsValid()) ? r.by : Entities.First();
			tank.TakeDamage(ParryDamage, DMG_CLUB | DMG_BLAST, attacker);
			try { TankStumble(tank, r.ent.GetOrigin()); } catch (e) { Log("tank stumble failed: " + e); }
			local gfx = SpawnEntityFromTable("info_particle_system", { effect_name = "tank_rock_throw_impact", start_active = 1, origin = r.ent.GetOrigin() });
			if (gfx != null)
				DoEntFire("!self", "Kill", "", 1.5, null, gfx);
			Boom(Sounds.Kill, tank, RandomInt(82, 96));
			Flash(r.by, "kill");
			r.ent.Kill();
			delete Rocks[index];
		}
	}
}

function Momentum::TankStumble(tank, from) {
	try { tank.Stagger(from); } catch (e) {}
	if (tank.IsDead() || tank.GetHealth() <= 0)
		return;
	local now = Time();
	local seq = tank.LookupSequence(TankStumbleAnim);
	local seconds = TankStumbleSeconds;
	if (seq >= 0) {
		try {
			local length = tank.GetSequenceDuration(seq);
			if (length > 0.2 && length < seconds)
				seconds = length;
		} catch (e) {}
		NetProps.SetPropFloatArray(tank, "m_NetGestureStartTime", now, 5);
		NetProps.SetPropIntArray(tank, "m_NetGestureSequence", seq, 5);
		NetProps.SetPropIntArray(tank, "m_NetGestureActivity", 1, 5);
	}
	tank.SetVelocity(Vector(0, 0, 0));
	NetProps.SetPropInt(tank, "m_MoveType", 0);
	NetProps.SetPropInt(tank, "m_afButtonDisabled", NetProps.GetPropInt(tank, "m_afButtonDisabled") | IN_ATTACK | IN_ATTACK2);
	DoEntFire("!self", "RunScriptCode", "::Momentum.TankRecover(self)", seconds, null, tank);
}

function Momentum::TankRecover(tank) {
	if (tank == null || !tank.IsValid())
		return;
	if (NetProps.GetPropInt(tank, "m_MoveType") == 0)
		NetProps.SetPropInt(tank, "m_MoveType", 2);
	NetProps.SetPropInt(tank, "m_afButtonDisabled", NetProps.GetPropInt(tank, "m_afButtonDisabled") & ~(IN_ATTACK | IN_ATTACK2));
}

function Momentum::Credit(p, method) {
	if (("ChapterStats" in getroottable()) && ("Note" in ::ChapterStats))
		try { ::ChapterStats.Note(p, method); } catch (e) {}
}

function Momentum::Scored(p, kind) {
	if (("ChapterStats" in getroottable()) && ("Event" in ::ChapterStats))
		try { ::ChapterStats.Event(p, kind); } catch (e) {}
}

function Momentum::GloryFinish(ent, p, kind) {
	if (!("GloryKill2" in getroottable()))
		return false;
	try { return ::GloryKill2.TryFinish(ent, p, kind); } catch (e) { return false; }
}

function Momentum::Near(from, ent, range) {
	return ((ent.GetOrigin() + Vector(0, 0, 32)) - from).Length() <= range;
}

function Momentum::KickReach(from, dir, ent) {
	local foot = ent.GetOrigin();
	local z = from.z;
	if (z < foot.z + KickBodyLow)
		z = foot.z + KickBodyLow;
	else if (z > foot.z + KickBodyHigh)
		z = foot.z + KickBodyHigh;
	local to = Vector(foot.x, foot.y, z) - from;
	local dist = to.Length();
	if (dist > KickRange)
		return false;
	if (dist < 1.0)
		return true;
	to.Norm();
	return dir.Dot(to) >= KickDot;
}

function Momentum::Facing(from, dir, ent, minDot) {
	local to = (ent.GetOrigin() + Vector(0, 0, 32)) - from;
	if (to.Length() < 1.0)
		return true;
	to.Norm();
	return dir.Dot(to) >= minDot;
}

function Momentum::MarkOnce(set, ent) {
	local index = ent.GetEntityIndex();
	if (index in set)
		return false;
	set[index] <- true;
	return true;
}

function Momentum::Hook() {
	if (("GameEventCallbacks" in getroottable()) && ("hd4l_momentum" in ::GameEventCallbacks))
		return;
	__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
	::GameEventCallbacks["hd4l_momentum"] <- true;
}

Momentum.Precache();
Momentum.Hook();

if (!("HD4L_Parts" in getroottable()))
	::HD4L_Parts <- {};
::HD4L_Parts["momentum"] <- "0.1";
