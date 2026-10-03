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
	Files = [ "momentum_moves", "momentum_wall", "momentum_hurt", "momentum_parry", "momentum_infected", "momentum_fx" ],

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

foreach (file in Momentum.Files)
	try { IncludeScript(file, getroottable()); } catch (e) { Momentum.Log("could not include " + file + ": " + e); }

Momentum.Precache();
Momentum.Hook();

if (!("HD4L_Parts" in getroottable()))
	::HD4L_Parts <- {};
::HD4L_Parts["momentum"] <- "0.1";
