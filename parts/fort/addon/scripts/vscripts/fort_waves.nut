function Fort::Strip(p, everything) {
	local inv = {};
	try { GetInvTable(p, inv); } catch (e) { return; }
	foreach (slot, w in inv) {
		if (w == null || !w.IsValid())
			continue;
		if (!everything && slot != "slot0")
			continue;
		w.Kill();
	}
}

function Fort::StripAll(everything) {
	foreach (p in Survivors())
		Strip(p, everything);
}

function Fort::StripStart(generation) {
	if (generation != Generation || !Building())
		return;
	StripAll(true);
	foreach (p in Survivors())
		Arm2(p);
}

function Fort::MeleeName(w) {
	local name = "";
	try { name = NetProps.GetPropString(w, "m_strMapSetScriptName").tolower(); } catch (e) {}
	return name;
}

function Fort::Arm2(p) {
	local inv = {};
	try { GetInvTable(p, inv); } catch (e) { return; }
	local w = ("slot1" in inv) ? inv.slot1 : null;
	if (w != null && w.IsValid() && w.GetClassname() == "weapon_melee" && MeleeName(w) == Axe[0])
		return;
	if (w != null && w.IsValid())
		w.Kill();
	foreach (melee in Axe) {
		try { p.GiveItem(melee); } catch (e) { continue; }
		local now = {};
		try { GetInvTable(p, now); } catch (e) {}
		if (("slot1" in now) && now.slot1 != null && now.slot1.IsValid())
			return;
	}
}

function Fort::AxeAll() {
	foreach (p in Survivors()) {
		local id = p.GetPlayerUserId();
		if ((id in Players) && Players[id].buildMode)
			continue;
		local inv = {};
		try { GetInvTable(p, inv); } catch (e) { continue; }
		local w = ("slot1" in inv) ? inv.slot1 : null;
		if (w == null || !w.IsValid() || w.GetClassname() != "weapon_melee")
			try { Arm2(p); } catch (e) { Log("axe failed for " + p.GetPlayerName() + ": " + e); }
	}
}

function Fort::Arm(p) {
	local gun = WaveWeapons[RandomInt(0, WaveWeapons.len() - 1)];
	try { p.GiveItem(gun); } catch (e) { Log("could not give " + gun + ": " + e); return; }
	DoEntFire("!self", "RunScriptCode", "::Fort.Laser(" + p.GetPlayerUserId() + ")", 0.1, null, Entities.First());
}

function Fort::Laser(userid) {
	local p = null;
	try { p = GetPlayerFromUserID(userid); } catch (e) { return; }
	if (p == null || !p.IsValid())
		return;
	local inv = {};
	try { GetInvTable(p, inv); } catch (e) { return; }
	if (!("slot0" in inv) || inv.slot0 == null || !inv.slot0.IsValid())
		return;
	try {
		local bits = NetProps.GetPropInt(inv.slot0, "m_upgradeBitVec");
		NetProps.SetPropInt(inv.slot0, "m_upgradeBitVec", bits | LaserBit);
	} catch (e) {}
}

function Fort::WaveLength(n) {
	return WaveBase + WaveGrow * (n - 1);
}

function Fort::TankCount(n) {
	if (n < TankFrom)
		return 0;
	return 1 + (n - TankFrom) / TankEvery;
}

function Fort::Clamp(v, lo, hi) {
	return v < lo ? lo : (v > hi ? hi : v);
}

function Fort::Options(n) {
	local c = n - 1;
	return {
		CommonLimit = Clamp(60 + 30 * c, 60, 150), MegaMobSize = Clamp(60 + 30 * c, 60, 150),
		MobMinSize = Clamp(25 + 10 * c, 25, 80), MobMaxSize = Clamp(40 + 15 * c, 40, 120), MobMaxPending = Clamp(50 + 20 * c, 50, 150),
		MobSpawnMinTime = Clamp(12 - 3 * c, 2, 12), MobSpawnMaxTime = Clamp(20 - 4 * c, 4, 20),
		MaxSpecials = Clamp(4 + 4 * c, 4, 20), SpecialRespawnInterval = Clamp(12 - 3 * c, 2, 12),
		DominatorLimit = Dominators(n), ProhibitBosses = true, TankLimit = 0, WitchLimit = 0
	};
}

function Fort::StockMode() {
	local mode = "";
	try { mode = Director.GetGameMode(); } catch (e) {}
	return (mode == "hd4lfort" || mode == "hd4lfreebuild");
}

function Fort::Dominators(n) {
	return StockMode() ? Clamp(1 + (n - 1) / 3, 1, StockDominators) : Clamp(3 + (n - 1), 3, 8);
}

function Fort::PanicEvery(n) {
	return Clamp(30.0 - 6.0 * (n - 1), 6.0, 30.0);
}

function Fort::Keep(n) {
	return Clamp(2 + 2 * (n - 1), 2, 16);
}

function Fort::Specials() {
	local n = 0;
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null)
		if (NetProps.GetPropInt(p, "m_iTeamNum") == FORT_TEAM_INFECTED && !p.IsDead() && !p.IsGhost() && p.GetZombieType() != FORT_ZOMBIE_TANK)
			n++;
	return n;
}

function Fort::Pressure(now) {
	if (now >= NextPanic) {
		NextPanic = now + PanicEvery(Wave);
		try { Director.ForcePanicEvent(); } catch (e) {}
	}
	if (now < NextSpecial)
		return;
	NextSpecial = now + SpecialEvery;
	if (Specials() >= Keep(Wave))
		return;
	local survivors = Survivors();
	if (survivors.len() == 0)
		return;
	local s = survivors[RandomInt(0, survivors.len() - 1)];
	local spot = null;
	if (("InfectedMoves" in getroottable()) && ("HiddenSpot" in ::InfectedMoves))
		try { spot = ::InfectedMoves.HiddenSpot(s, survivors, 500.0, 1100.0); } catch (e) { spot = null; }
	local kinds = StockMode() ? StockSpecials : AllSpecials;
	local kind = kinds[RandomInt(0, kinds.len() - 1)];
	try {
		if (spot != null)
			ZSpawn({ type = kind, pos = spot, ang = QAngle(0, RandomInt(0, 359), 0) });
		else
			ZSpawn({ type = kind });
	} catch (e) {}
}

function Fort::Calm() {
	return {
		CommonLimit = 0, MegaMobSize = 0, MobMinSize = 0, MobMaxSize = 0, MobMaxPending = 0,
		MobSpawnMinTime = 9999, MobSpawnMaxTime = 9999, MaxSpecials = 0, SpecialRespawnInterval = 9999,
		DominatorLimit = 0, ProhibitBosses = true, TankLimit = 0, WitchLimit = 0
	};
}

function Fort::Direct(options) {
	local root = getroottable();
	if (!("SessionOptions" in root))
		root.SessionOptions <- {};
	local director = null;
	if (("DirectorScript" in root) && ("DirectorOptions" in root.DirectorScript))
		director = root.DirectorScript.DirectorOptions;
	foreach (key, value in options) {
		root.SessionOptions[key] <- value;
		root.SessionOptions["cm_" + key] <- value;
		if (director != null)
			director[key] <- value;
	}
}

function Fort::Clear() {
	local commons = [];
	local ent = null;
	while ((ent = Entities.FindByClassname(ent, "infected")) != null)
		commons.append(ent);
	foreach (z in commons)
		if (z.IsValid())
			z.Kill();
	local world = Entities.First();
	ent = null;
	while ((ent = Entities.FindByClassname(ent, "player")) != null)
		if (NetProps.GetPropInt(ent, "m_iTeamNum") == FORT_TEAM_INFECTED && !ent.IsDead() && !ent.IsGhost())
			ent.TakeDamage(ent.GetHealth() + 10000, 0, world);
	ent = null;
	local witches = [];
	while ((ent = Entities.FindByClassname(ent, "witch")) != null)
		witches.append(ent);
	foreach (w in witches)
		if (w.IsValid())
			w.Kill();
}

function Fort::StartWave(n) {
	Wave = n;
	Phase = "wave";
	local now = Time();
	PhaseUntil = now + WaveLength(n);
	LastWear = now;
	LastBeep = -1;
	foreach (id, st in Players) {
		HideGhost(st);
		ClearAim(st);
		Unlook(st);
		if (st.p != null && st.p.IsValid() && st.buildMode)
			NoShove(st.p, false);
		st.buildMode = false;
	}
	Direct(Options(n));
	try { Director.ResetMobTimer(); } catch (e) {}
	NextPanic = now + 3.0;
	NextSpecial = now + 2.0;
	foreach (p in Survivors())
		Arm(p);
	Tanks = [];
	local tanks = TankCount(n);
	for (local i = 0; i < tanks; i++)
		Tanks.append(now + WaveLength(n) * (0.25 + 0.5 * i / (tanks > 1 ? tanks - 1 : 1)));
	Spike();
}

function Fort::EndWave() {
	local bonus = BonusPerWave * Wave;
	Clear();
	AddScrap(bonus);
	StripAll(false);
	Direct(Calm());
	Phase = "break";
	PhaseUntil = Time() + BreakSeconds;
	LastBeep = -1;
	ToAll(Sounds.WaveOver);
	Spike();
}

function Fort::SpawnTank() {
	local survivors = Survivors();
	if (survivors.len() == 0)
		return;
	local s = survivors[RandomInt(0, survivors.len() - 1)];
	local spot = null;
	if (("InfectedMoves" in getroottable()) && ("HiddenSpot" in ::InfectedMoves))
		try { spot = ::InfectedMoves.HiddenSpot(s, survivors, 700.0, 1400.0); } catch (e) { spot = null; }
	local spawned = null;
	if (spot != null)
		try { spawned = ZSpawn({ type = FORT_ZOMBIE_TANK, pos = spot, ang = QAngle(0, RandomInt(0, 359), 0) }); } catch (e) {}
	if (spawned == null)
		try { spawned = ZSpawn({ type = FORT_ZOMBIE_TANK }); } catch (e) { Log("tank spawn failed: " + e); }
}

function Fort::WaveTick(now) {
	try { WearTick(now); } catch (e) { Log("wear failed: " + e); }
	if (now - LastClimb >= ClimbEvery) {
		LastClimb = now;
		try { ClimbTick(now); } catch (e) { Log("climb failed: " + e); }
	}
	try { Pressure(now); } catch (e) { Log("pressure failed: " + e); }
	foreach (i, at in clone Tanks)
		if (now >= at) {
			Tanks.remove(Tanks.find(at));
			SpawnTank();
			break;
		}
	Beeps(now);
	if (now >= PhaseUntil)
		EndWave();
}

function Fort::Up() {
	local out = [];
	foreach (s in Survivors()) {
		local feet = s.GetOrigin();
		local tr = { start = feet + Vector(0, 0, 4), end = feet - Vector(0, 0, 2000), ignore = s };
		TraceLine(tr);
		local ground = ("pos" in tr) ? tr.pos.z : feet.z;
		local hit = ("enthit" in tr) ? PieceOf(tr.enthit) : null;
		if (hit != null || feet.z - ground >= ClimbHeight)
			out.append(s);
	}
	return out;
}

function Fort::Arc(a, b) {
	local rise = b.z - a.z + ClimbClear;
	if (rise < ClimbClear)
		rise = ClimbClear;
	local up = sqrt(2.0 * Gravity * rise);
	local t = up / Gravity + sqrt(2.0 * ClimbClear / Gravity);
	local flat = Vector(b.x - a.x, b.y - a.y, 0);
	local d = flat.Length();
	local across = d / t;
	if (across > ClimbSpeed)
		across = ClimbSpeed;
	if (d > 0.01)
		flat = flat * (1.0 / d);
	return flat * across + Vector(0, 0, up);
}

function Fort::ClimbTick(now) {
	local up = Up();
	if (up.len() == 0)
		return;
	local n = 0;
	foreach (s in up) {
		local feet = s.GetOrigin();
		foreach (cls in [ "infected", "player" ]) {
			local z = null;
			while ((z = Entities.FindByClassnameWithin(z, cls, feet, ClimbReach + ClimbHeight * 4.0)) != null) {
				if (n >= ClimbMax)
					return;
				if (cls == "player" && (NetProps.GetPropInt(z, "m_iTeamNum") != FORT_TEAM_INFECTED || z.IsDead() || z.IsGhost()))
					continue;
				if (cls == "infected" && z.GetHealth() <= 0)
					continue;
				local at = z.GetOrigin();
				if (feet.z - at.z < ClimbHeight)
					continue;
				if (Vector(feet.x - at.x, feet.y - at.y, 0).Length() > ClimbReach)
					continue;
				local idx = z.GetEntityIndex();
				if ((idx in Climbed) && now - Climbed[idx] < ClimbCooldown)
					continue;
				Climbed[idx] <- now;
				local vel = Arc(at, feet);
				if (cls == "player")
					z.SetVelocity(vel);
				else
					z.ApplyAbsVelocityImpulse(vel);
				n++;
			}
		}
	}
}

function Fort::BotLift(now) {
	local humans = [];
	foreach (s in Up())
		if (!IsPlayerABot(s))
			humans.append(s);
	foreach (b in Survivors()) {
		if (!IsPlayerABot(b))
			continue;
		local idx = b.GetEntityIndex();
		local near = null;
		foreach (h in humans) {
			local d = h.GetOrigin() - b.GetOrigin();
			if (d.z >= BotLiftHeight && Vector(d.x, d.y, 0).Length() <= BotLiftReach)
				near = h;
		}
		if (near == null) {
			if (idx in Stranded)
				delete Stranded[idx];
			continue;
		}
		if (!(idx in Stranded)) {
			Stranded[idx] <- now;
			continue;
		}
		if (now - Stranded[idx] < BotLiftAfter)
			continue;
		delete Stranded[idx];
		local f = near.EyeAngles().Forward();
		local side = Vector(-f.y, f.x, 0);
		if (side.Length() < 0.01)
			side = Vector(1, 0, 0);
		side.Norm();
		b.SetOrigin(near.GetOrigin() + side * 40.0 + Vector(0, 0, 8));
		b.SetVelocity(Vector(0, 0, 0));
	}
}

function Fort::KeepCalm(now) {
	if (now - LastCalm < CalmEvery)
		return;
	LastCalm = now;
	Clear();
}

function Fort::BreakTick(now) {
	KeepCalm(now);
	Beeps(now);
	if (now >= PhaseUntil)
		StartWave(Wave + 1);
}

function Fort::Beeps(now) {
	local left = (PhaseUntil - now + 0.99).tointeger();
	if (left > BeepFrom || left <= 0 || left == LastBeep)
		return;
	LastBeep = left;
	ToAll(Sounds.Beep);
}

function Fort::OnGameEvent_infected_death(params) {
	if (Phase == "wave")
		AddScrap(KillScrap.common);
}

function Fort::OnGameEvent_player_death(params) {
	if (Phase != "wave" || !("userid" in params))
		return;
	local victim = null;
	try { victim = GetPlayerFromUserID(params.userid); } catch (e) { return; }
	if (victim == null || !victim.IsValid() || NetProps.GetPropInt(victim, "m_iTeamNum") != FORT_TEAM_INFECTED)
		return;
	AddScrap(victim.GetZombieType() == FORT_ZOMBIE_TANK ? KillScrap.tank : KillScrap.special);
}

function Fort::OnGameEvent_witch_killed(params) {
	if (Phase == "wave")
		AddScrap(KillScrap.witch);
}

function Fort::OnGameEvent_survival_round_start(params) {
	if (InSurvival() && Phase == "prep")
		StartWave(1);
}

function Fort::OnGameEvent_create_panic_event(params) {
	if (InSurvival() && Phase == "prep")
		StartWave(1);
}
