const ZOMBIE_WITCH = 7;
const ZOMBIE_TANK = 8;
const EXTRA_TANK_NAME = "escalation_extra_tank";

::Escalation <- {
	Versus = false,
	Survival = false,
	Stock = false,

	MapsToPeak = 5,
	RampSeconds = 480.0,

	Start = {
		CommonLimit = 55, MegaMobSize = 57, MobMinSize = 16, MobMaxSize = 40, MobMaxPending = 44,
		PreTankMobMax = 40, BileMobSize = 30, MobSpawnMinTime = 38, MobSpawnMaxTime = 75,
		WanderingZombieDensityModifier = 1.75,
		MaxSpecials = 6, SpecialRespawnInterval = 25, SpecialInitialSpawnDelayMin = 10, SpecialInitialSpawnDelayMax = 30,
		SmokerLimit = 2, BoomerLimit = 2, HunterLimit = 2, SpitterLimit = 2, JockeyLimit = 2, ChargerLimit = 2,
		DominatorLimit = 4,
		ShouldAllowSpecialsWithTank = true, ShouldAllowMobsWithTank = true
	},
	Peak = {
		CommonLimit = 90, MegaMobSize = 76, MobMinSize = 21, MobMaxSize = 51, MobMaxPending = 76,
		PreTankMobMax = 51, BileMobSize = 43, MobSpawnMinTime = 20, MobSpawnMaxTime = 45,
		WanderingZombieDensityModifier = 2.0,
		MaxSpecials = 10, SpecialRespawnInterval = 8, SpecialInitialSpawnDelayMin = 3, SpecialInitialSpawnDelayMax = 10,
		SmokerLimit = 3, BoomerLimit = 3, HunterLimit = 3, SpitterLimit = 3, JockeyLimit = 3, ChargerLimit = 3,
		DominatorLimit = 5
	},

	Pacing = { MegaMobSize = true, MobMinSize = true, MobMaxSize = true, MobSpawnMinTime = true, MobSpawnMaxTime = true,
	           SpecialInitialSpawnDelayMin = true, SpecialInitialSpawnDelayMax = true },

	TankHealth = 6000,
	FinaleTanks = 1,
	LoneFinaleTanks = true,
	AmpFinaleTank = true,
	AmpHealth = 1.5,
	AmpSpeed = 1.2,
	AmpEyes = "hd4l_eyes_tank",
	AmpEyeHeight = 80.0,
	Amps = {},
	TankGroupAtPeak = 2,
	TankGroupRound = 0.25,
	TankEveryMap = true,
	TankDelayMin = 90.0,
	TankDelayMax = 180.0,

	WitchesPerMap = 3,
	WitchFlowStart = 5000.0,
	WitchFlowPeak = 3000.0,
	WitchMinDist = 700.0,
	WitchMaxDist = 1400.0,

	SkipFirstMap = true,

	Spikes = [ 0.25, 0.5, 0.75, 1.0 ],
	SpikeLevel = 0,

	Merciless = {
		MobSpawnMinTime = 10, MobSpawnMaxTime = 18, MobMinSize = 13, MobMaxSize = 21, MobMaxPending = 30,
		SpecialRespawnInterval = 6, SpecialInitialSpawnDelayMin = 2, SpecialInitialSpawnDelayMax = 5,
		RelaxMinInterval = 4, RelaxMaxInterval = 8, IntensityRelaxThreshold = 0.9, SustainPeakMinTime = 45,
		SpecialInfectedAssault = true
	},
	MercilessSpecials = 1.25,

	LastStandCap = {
		CommonLimit = 35, MegaMobSize = 25, MobMinSize = 8, MobMaxSize = 15, MobMaxPending = 15,
		PreTankMobMax = 15, BileMobSize = 15,
		SmokerLimit = 1, HunterLimit = 1, JockeyLimit = 1, ChargerLimit = 1, DominatorLimit = 1
	},
	LastStandFloor = { MobSpawnMinTime = 25, MobSpawnMaxTime = 40 },

	SpecialRate = 0.67,
	RateKeys = { SpecialRespawnInterval = true, SpecialInitialSpawnDelayMin = true, SpecialInitialSpawnDelayMax = true },

	FinaleEase = 0.6,
	EaseCounts = { MaxSpecials = true, SmokerLimit = true, BoomerLimit = true, HunterLimit = true,
	               SpitterLimit = true, JockeyLimit = true, ChargerLimit = true, DominatorLimit = true },
	MercilessPanic = false,
	MercilessPanicCooldown = 20.0,
	MercilessInterval = 0.5,

	Interval = 10.0,

	HardCommonLimit = 100,

	Generation = 0,
	LeftSaferoomAt = -1.0,
	TankSeen = false,
	TankDue = -1.0,
	PendingTanks = 0,
	WitchesSpawned = 0,
	LastWitchFlow = 0.0,
	Hyper = false,
	LastStand = false,
	LastPanic = -1000.0
}

function Escalation::Log(msg) {
	printl("[Escalation] " + msg);
}

function Escalation::ModeAllowed() {
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

function Escalation::ResetRound() {
	LeftSaferoomAt = -1.0;
	TankSeen = false;
	TankDue = -1.0;
	PendingTanks = 0;
	WitchesSpawned = 0;
	LastWitchFlow = 0.0;
	SpikeLevel = 0;
}

function Escalation::Clamp(x, lo, hi) {
	return x < lo ? lo : (x > hi ? hi : x);
}

function Escalation::Progress() {
	local map = 1;
	try { map = Director.GetMapNumber(); } catch (e) {}
	local timeFrac = LeftSaferoomAt < 0 ? 0.0 : Clamp((Time() - LeftSaferoomAt) / RampSeconds, 0.0, 1.0);
	return Clamp((map - 1 + timeFrac) / MapsToPeak, 0.0, 1.0);
}

function Escalation::Lerp(a, b, p) {
	if (typeof a == "bool")
		return a;
	local v = a + (b - a) * p;
	return typeof a == "integer" ? (v + 0.5).tointeger() : v;
}

function Escalation::ApplyOptions(p) {
	local root = getroottable();
	if (!("SessionOptions" in root))
		root.SessionOptions <- {};
	local director = null;
	if ("DirectorScript" in root && "DirectorOptions" in root.DirectorScript)
		director = root.DirectorScript.DirectorOptions;

	local merciless = Hyper && !LastStand;
	local held = Hyper || LastStand;
	local applied = {};
	foreach (key, start in Start) {
		local value = (key in Peak) ? Lerp(start, Peak[key], p) : start;
		if (merciless && key == "MaxSpecials")
			value = (value * MercilessSpecials + 0.5).tointeger();
		applied[key] <- value;
	}
	if (merciless)
		foreach (key, value in Merciless)
			applied[key] <- value;
	if (LastStand) {
		foreach (key, value in LastStandCap)
			if (key in applied && applied[key] > value)
				applied[key] <- value;
		foreach (key, value in LastStandFloor)
			if (key in applied && applied[key] < value)
				applied[key] <- value;
	}

	if (FinaleEase > 0.0 && FinaleEase != 1.0 && InFinale()) {
		foreach (key, on in EaseCounts)
			if (key in applied) {
				local eased = (applied[key] * FinaleEase + 0.5).tointeger();
				applied[key] <- eased < 1 ? 1 : eased;
			}
		foreach (key, on in RateKeys)
			if (key in applied) {
				local seconds = applied[key] / FinaleEase;
				applied[key] <- (typeof applied[key] == "integer") ? (seconds + 0.5).tointeger() : seconds;
			}
	}

	if (SpecialRate > 0.0 && SpecialRate != 1.0)
		foreach (key, on in RateKeys)
			if (key in applied) {
				local seconds = applied[key] / SpecialRate;
				applied[key] <- (typeof applied[key] == "integer") ? (seconds + 0.5).tointeger() : seconds;
			}
	foreach (key, value in applied) {
		if (!(key in Pacing) || held)
			root.SessionOptions[key] <- value;
		else if (key in root.SessionOptions)
			delete root.SessionOptions[key];
		if (director != null)
			director[key] <- value;
	}
	if (!merciless)
		foreach (key, value in Merciless)
			if (!(key in Start)) {
				if (key in root.SessionOptions) delete root.SessionOptions[key];
				if (director != null && key in director) delete director[key];
			}

}

function Escalation::MercilessTick(generation) {
	if (generation != Generation || !ModeAllowed())
		return;
	local hyper = false;
	local last = false;
	if (("Momentum" in getroottable()) && ("HyperAnyone" in ::Momentum))
		try { hyper = ::Momentum.HyperAnyone(); } catch (e) {}
	if (("Momentum" in getroottable()) && ("LastStandAnyone" in ::Momentum))
		try { last = ::Momentum.LastStandAnyone(); } catch (e) {}
	if (last != LastStand) {
		LastStand = last;
		Hyper = hyper;
		ApplyOptions(Progress());
	} else if (hyper != Hyper && !last) {
		Hyper = hyper;
		ApplyOptions(Progress());
		if (hyper) {
			try { Director.ResetMobTimer(); } catch (e) {}
			if (MercilessPanic && Time() - LastPanic >= MercilessPanicCooldown) {
				LastPanic = Time();
				try { Director.PlayMegaMobWarningSounds(); } catch (e) {}
				try { Director.ForcePanicEvent(); } catch (e) { Log("panic event failed: " + e); }
			}
		}
	}
	try { CapCommons(); } catch (e) { Log("common cap failed: " + e); }
	try { AmpTick(); } catch (e) { Log("amp tick failed: " + e); }
	DoEntFire("!self", "RunScriptCode", "::Escalation.MercilessTick(" + generation + ")", MercilessInterval, null, Entities.First());
}

function Escalation::CapCommons() {
	if (HardCommonLimit <= 0)
		return;
	local commons = [];
	local z = null;
	while ((z = Entities.FindByClassname(z, "infected")) != null)
		if (z.IsValid() && z.GetHealth() > 0)
			commons.append(z);
	local excess = commons.len() - HardCommonLimit;
	if (excess <= 0)
		return;

	local survivors = [];
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null)
		if (p.IsSurvivor() && !p.IsDead())
			survivors.append(p.GetOrigin());

	local ranked = [];
	foreach (c in commons) {
		local origin = c.GetOrigin();
		local nearest = 1.0e9;
		foreach (s in survivors) {
			local d = (s - origin).Length();
			if (d < nearest)
				nearest = d;
		}
		ranked.append({ ent = c, dist = nearest });
	}
	ranked.sort(function(a, b) { return b.dist <=> a.dist; });
	for (local i = 0; i < excess; i++)
		ranked[i].ent.Kill();
}

function Escalation::TankGroup(p) {
	return (1 + (TankGroupAtPeak - 1) * p + TankGroupRound).tointeger();
}

function Escalation::Tick(generation) {
	if (generation != Generation || !ModeAllowed())
		return;

	local left = false;
	try { left = Director.HasAnySurvivorLeftSafeArea(); } catch (e) {}
	if (left && LeftSaferoomAt < 0) {
		LeftSaferoomAt = Time();
		TankDue = Time() + TankDelayMin + RandomFloat(0.0, TankDelayMax - TankDelayMin);
		try { LastWitchFlow = Director.GetFurthestSurvivorFlow(); } catch (e) {}
	}

	local p = Progress();
	ApplyOptions(p);
	if (left) {
		try { MaybeForceTank(); } catch (e) { Log("forced tank failed: " + e); }
		try { MaybeSpawnWitch(p); } catch (e) { Log("witch failed: " + e); }
		try { MaybeSpike(p); } catch (e) { Log("spike failed: " + e); }
	} else {
		while (SpikeLevel < Spikes.len() && p >= Spikes[SpikeLevel])
			SpikeLevel++;
	}

	DoEntFire("!self", "RunScriptCode", "::Escalation.Tick(" + generation + ")", Interval, null, Entities.First());
}

function Escalation::MaybeSpike(p) {
	if (SpikeLevel >= Spikes.len() || p < Spikes[SpikeLevel])
		return;
	SpikeLevel++;
	try { Director.PlayMegaMobWarningSounds(); } catch (e) {}
	try { Director.ResetMobTimer(); } catch (e) {}
	if ("HyperFeedback" in getroottable() && ("Spike" in ::HyperFeedback))
		::HyperFeedback.Spike();
}

function Escalation::FirstMap() {
	try { return Director.IsFirstMapInScenario(); } catch (e) { return false; }
}

function Escalation::InFinale() {
	local on = false;
	try { on = Director.IsFinale(); } catch (e) { return false; }
	return on && Entities.FindByClassname(null, "trigger_finale") != null;
}

function Escalation::FinaleMap() {
	return Entities.FindByClassname(null, "trigger_finale") != null;
}

function Escalation::OtherTankAlive(tank) {
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null) {
		if (p == tank || p.IsDead() || p.GetHealth() <= 0)
			continue;
		try { if (p.GetZombieType() == ZOMBIE_TANK) return true; } catch (e) {}
	}
	return false;
}

function Escalation::MaybeForceTank() {
	if (!TankEveryMap || TankSeen || TankDue < 0 || Time() < TankDue)
		return;
	if ((SkipFirstMap && FirstMap()) || FinaleMap() || Director.IsTankInPlay()) {
		TankDue = -1.0;
		return;
	}
	TankDue = -1.0;
	EntFire("info_director", "scriptedpanicevent", "escalation_tank");
}

function Escalation::OnGameEvent_tank_spawn(params) {
	if (!ModeAllowed() || !("tankid" in params))
		return;
	local tank = EntIndexToHScript(params.tankid);
	if (tank == null || !tank.IsValid())
		return;

	local ours = false;
	try { ours = tank.GetName() == EXTRA_TANK_NAME; } catch (e) {}
	if (ours || PendingTanks > 0) {
		if (PendingTanks > 0)
			PendingTanks--;
		return;
	}
	if (LoneFinaleTanks && ("userid" in params) && FinaleMap() && IsPlayerABot(tank) && OtherTankAlive(tank)) {
		SendToServerConsole("kickid " + params.userid);
		return;
	}
	TankSeen = true;
	if (AmpFinaleTank && InFinale())
		DoEntFire("!self", "RunScriptCode", "::Escalation.Amp(" + params.tankid + ")", 0.2, null, Entities.First());

	local group = FinaleMap() ? FinaleTanks : TankGroup(Progress());
	if (group <= 1)
		return;
	for (local i = 1; i < group; i++)
		DoEntFire("!self", "RunScriptCode", "::Escalation.SpawnTankNear(" + params.tankid + ")", 1.5 * i, null, Entities.First());
}

function Escalation::Amp(index) {
	local tank = EntIndexToHScript(index);
	if (tank == null || !tank.IsValid() || tank.IsDead())
		return;
	local health = (tank.GetMaxHealth() * AmpHealth).tointeger();
	tank.SetMaxHealth(health);
	tank.SetHealth(health);
	local fx = [];
	if (("HD4L" in getroottable()) && ("Eyes" in ::HD4L))
		try { fx = ::HD4L.Eyes(tank, AmpEyes, AmpEyeHeight); } catch (e) { Log("amp eyes failed: " + e); }
	Amps[index] <- { ent = tank, fx = fx, applied = 0.0, engine = 1.0 };
	AmpPace(Amps[index]);
}

function Escalation::IsAmped(tank) {
	if (tank == null || !tank.IsValid())
		return false;
	local index = tank.GetEntityIndex();
	return (index in Amps) && Amps[index].ent == tank;
}

function Escalation::AmpPace(a) {
	local cur = NetProps.GetPropFloat(a.ent, "m_flLaggedMovementValue");
	if (fabs(cur - a.applied) >= 0.001)
		a.engine = cur;
	local want = a.engine * AmpSpeed;
	if (fabs(want - cur) > 0.001) {
		NetProps.SetPropFloat(a.ent, "m_flLaggedMovementValue", want);
		a.applied = want;
	}
}

function Escalation::AmpTick() {
	foreach (index, a in clone Amps) {
		if (!a.ent.IsValid() || a.ent.IsDead() || a.ent.GetHealth() <= 0) {
			Unamp(index);
			continue;
		}
		try { AmpPace(a); } catch (e) {}
	}
}

function Escalation::Unamp(index) {
	if (!(index in Amps))
		return;
	if (("HD4L" in getroottable()) && ("Unfx" in ::HD4L))
		try { ::HD4L.Unfx(Amps[index].fx); } catch (e) {}
	delete Amps[index];
}

function Escalation::OnGameEvent_tank_killed(params) {
	local tank = null;
	if ("userid" in params)
		try { tank = GetPlayerFromUserID(params.userid); } catch (e) {}
	if (tank != null && tank.IsValid())
		Unamp(tank.GetEntityIndex());
}

function Escalation::SpawnTankNear(index) {
	local tank = EntIndexToHScript(index);
	local pos = null;
	if (tank != null && tank.IsValid()) {
		try { pos = tank.TryGetPathableLocationWithin(250.0); } catch (e) {}
		if (pos == null)
			pos = tank.GetOrigin();
	}
	if (pos == null) {
		return;
	}
	PendingTanks++;
	local spawned = ZSpawn({ type = ZOMBIE_TANK, pos = pos, ang = QAngle(0, RandomInt(0, 359), 0), targetname = EXTRA_TANK_NAME });
	if (spawned == null) {
		PendingTanks--;
		Log("extra tank ZSpawn failed");
	}
}

function Escalation::MaybeSpawnWitch(p) {
	if (WitchesSpawned >= WitchesPerMap || (SkipFirstMap && FirstMap()) || InFinale() || Director.IsTankInPlay())
		return;
	local flow = Director.GetFurthestSurvivorFlow();
	local interval = WitchFlowStart + (WitchFlowPeak - WitchFlowStart) * p;
	if (flow - LastWitchFlow < interval)
		return;
	local pos = FindHiddenSpot(flow);
	if (pos == null)
		return;
	LastWitchFlow = flow;
	WitchesSpawned++;
	ZSpawn({ type = ZOMBIE_WITCH, pos = pos, ang = QAngle(0, RandomInt(0, 359), 0) });
}

function Escalation::FindHiddenSpot(flow) {
	local leader = Director.GetHighestFlowSurvivor();
	if (leader == null || !leader.IsValid())
		return null;
	local survivors = [];
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null)
		if (p.IsSurvivor() && !p.IsDead())
			survivors.append(p);

	local fallback = null;
	for (local i = 0; i < 40; i++) {
		local spot = leader.TryGetPathableLocationWithin(WitchMaxDist);
		if (spot == null || !Hidden(spot, survivors))
			continue;
		if (GetFlowDistanceForPosition(spot) > flow)
			return spot;
		if (fallback == null)
			fallback = spot;
	}
	return fallback;
}

function Escalation::Hidden(spot, survivors) {
	local target = spot + Vector(0, 0, 40);
	foreach (s in survivors) {
		if ((s.GetOrigin() - spot).Length() < WitchMinDist)
			return false;
		local trace = { start = s.EyePosition(), end = target, ignore = s };
		TraceLine(trace);
		if (!trace.hit || trace.fraction > 0.98)
			return false;
	}
	return true;
}

function Escalation::OnGameEvent_round_start(params) {
	ResetRound();

	while (SpikeLevel < Spikes.len() && Progress() >= Spikes[SpikeLevel])
		SpikeLevel++;
	Generation++;
	Hyper = false;
	LastStand = false;
	foreach (index, a in clone Amps)
		Unamp(index);
	if (ModeAllowed()) {
		Convars.SetValue("z_tank_health", TankHealth);
	}
	Tick(Generation);
	MercilessTick(Generation);
}

PrecacheModel("models/infected/witch.mdl");

function Escalation::Hook() {
	if (("GameEventCallbacks" in getroottable()) && ("hd4l_escalation" in ::GameEventCallbacks))
		return;
	__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
	::GameEventCallbacks["hd4l_escalation"] <- true;
}

Escalation.Hook();

if (!("HD4L_Parts" in getroottable()))
	::HD4L_Parts <- {};
::HD4L_Parts["escalation"] <- "0.1";
