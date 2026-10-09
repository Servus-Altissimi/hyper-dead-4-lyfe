const MOVETYPE_LADDER = 9;
const BODYGUARD_FL_ONGROUND = 1;

::Bodyguard <- {
	Versus = true,
	Survival = true,
	Stock = false,

	Interval = 0.25,
	BotSpeed = 1.3,
	CatchUp = 2.0,
	CatchUpRamp = 0.15,
	CatchUpMax = 2.8,
	Leash = 300.0,
	Release = 150.0,
	Warp = 1200.0,
	WarpSeconds = 4.0,
	WarpProgress = 150.0,

	HordeWarp = 700.0,
	HordeRange = 250.0,
	HordeCount = 4,

	TrailStep = 40.0,
	TrailMax = 32,
	WarpMinBack = 60.0,
	WarpMaxBack = 600.0,
	GroundProbe = 72.0,
	BrushOnly = 81931,
	HazardRange = 160.0,
	Hazards = [ "inferno", "insect_swarm", "fire_cracker_blast" ],
	Trails = {},
	ReviveSeconds = 0.0,

	Cvars = {
		sb_friend_immobilized_reaction_time_normal = 0,
		sb_friend_immobilized_reaction_time_hard = 0,
		sb_friend_immobilized_reaction_time_expert = 0,
		sb_allow_shoot_through_survivors = 1,
		sb_combat_saccade_speed = 2000,
		sb_dont_bash = 0
	},

	Bots = {},
	Generation = 0
}

function Bodyguard::Log(msg) {
	printl("[Bodyguard] " + msg);
}

function Bodyguard::ModeAllowed() {
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

function Bodyguard::Held(p) {
	if (p.IsIncapacitated() || p.IsHangingFromLedge() || NetProps.GetPropInt(p, "m_MoveType") == MOVETYPE_LADDER)
		return true;
	foreach (prop in [ "m_tongueOwner", "m_pounceAttacker", "m_jockeyAttacker", "m_carryAttacker", "m_pummelAttacker" ]) {
		try { if (NetProps.GetPropEntity(p, prop) != null) return true; } catch (e) {}
	}
	return false;
}

function Bodyguard::StateOf(bot) {
	local id = bot.GetPlayerUserId();
	if (!(id in Bots))
		Bots[id] <- { far = -1.0, stuckAt = -1.0, stuckDist = 0.0, applied = 0.0, engine = 1.0 };
	return Bots[id];
}

function Bodyguard::Pace(bot, b, mult) {
	local cur = 1.0;
	try { cur = NetProps.GetPropFloat(bot, "m_flLaggedMovementValue"); } catch (e) { return; }
	local engine = (fabs(cur - b.applied) < 0.001) ? b.engine : cur;
	b.engine = engine;
	local want = engine * mult;
	if (fabs(want - cur) > 0.001) {
		NetProps.SetPropFloat(bot, "m_flLaggedMovementValue", want);
		b.applied = want;
	}
}

function Bodyguard::Tick(generation) {
	if (generation != Generation)
		return;
	if (ModeAllowed()) {
		try { Herd(); } catch (e) { Log("herd failed: " + e); }
	}
	DoEntFire("!self", "RunScriptCode", "::Bodyguard.Tick(" + generation + ")", Interval, null, Entities.First());
}

function Bodyguard::Herd() {
	local now = Time();
	local humans = [];
	local bots = [];
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null) {
		if (!p.IsSurvivor() || p.IsDead() || p.IsDying())
			continue;
		if (IsPlayerABot(p))
			bots.append(p);
		else {
			try { Record(p); } catch (e) {}
			if (!Held(p))
				humans.append(p);
		}
	}
	if (humans.len() == 0)
		return;

	foreach (bot in bots) {
		local b = StateOf(bot);
		local nearest = null;
		local best = 999999.0;
		foreach (h in humans) {
			local d = (h.GetOrigin() - bot.GetOrigin()).Length();
			if (d < best) {
				best = d;
				nearest = h;
			}
		}
		if (best > Leash && b.far < 0.0)
			b.far = now;
		else if (best < Release)
			b.far = -1.0;
		if (best > Warp) {
			if (b.stuckAt < 0.0 || best < b.stuckDist - WarpProgress) {
				b.stuckAt = now;
				b.stuckDist = best;
			}
		} else
			b.stuckAt = -1.0;

		if (Held(bot)) {
			b.stuckAt = -1.0;
			continue;
		}
		try { if (NetProps.GetPropInt(bot, "m_currentReviveCount") > 0) bot.SetReviveCount(0); } catch (e) {}
		local mult = BotSpeed;
		if (b.far >= 0.0) {
			mult = CatchUp + CatchUpRamp * ((best - Leash) / 100.0);
			if (mult > CatchUpMax)
				mult = CatchUpMax;
		}
		Pace(bot, b, mult);
		local swarmed = best > HordeWarp && Swarmed(bot);
		if (swarmed || (b.stuckAt >= 0.0 && now - b.stuckAt >= WarpSeconds)) {
			local spot = SafeSpot(nearest);
			if (spot == null) {
				if (b.stuckAt >= 0.0)
					b.stuckAt = now - WarpSeconds + 1.0;
				continue;
			}
			bot.SetOrigin(spot);
			bot.SetVelocity(Vector(0, 0, 0));
			b.stuckAt = -1.0;
			b.far = -1.0;
		}
	}
}

function Bodyguard::Grounded(p) {
	return (NetProps.GetPropInt(p, "m_fFlags") & BODYGUARD_FL_ONGROUND) != 0
		&& NetProps.GetPropInt(p, "m_MoveType") != MOVETYPE_LADDER
		&& !Held(p);
}

function Bodyguard::Record(h) {
	if (!Grounded(h))
		return;
	local id = h.GetPlayerUserId();
	if (!(id in Trails))
		Trails[id] <- [];
	local trail = Trails[id];
	local pos = h.GetOrigin();
	if (trail.len() > 0 && (trail[trail.len() - 1] - pos).Length() < TrailStep)
		return;
	trail.append(pos);
	if (trail.len() > TrailMax)
		trail.remove(0);
}

function Bodyguard::SafeSpot(h) {
	local id = h.GetPlayerUserId();
	if (!(id in Trails))
		return null;
	local here = h.GetOrigin();
	local trail = Trails[id];
	for (local i = trail.len() - 1; i >= 0; i--) {
		local pos = trail[i];
		local d = (pos - here).Length();
		if (d < WarpMinBack || d > WarpMaxBack)
			continue;
		if (Safe(pos))
			return pos + Vector(0, 0, 4);
	}
	return null;
}

function Bodyguard::Safe(pos) {
	local down = { start = pos + Vector(0, 0, 32), end = pos - Vector(0, 0, GroundProbe), mask = BrushOnly };
	TraceLine(down);
	if (!down.hit || down.fraction >= 1.0)
		return false;
	local up = { start = pos + Vector(0, 0, 8), end = pos + Vector(0, 0, 64), mask = BrushOnly };
	TraceLine(up);
	if (up.hit && up.fraction < 1.0)
		return false;
	foreach (cls in Hazards)
		if (Entities.FindByClassnameWithin(null, cls, pos, HazardRange) != null)
			return false;
	local area = null;
	try { area = NavMesh.GetNearestNavArea(pos, 120.0, false, false); } catch (e) {}
	if (area != null)
		try { if (area.IsDamaging()) return false; } catch (e) {}
	return true;
}

function Bodyguard::Swarmed(bot) {
	local origin = bot.GetOrigin();
	local n = 0;
	local ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "infected", origin, HordeRange)) != null) {
		if (ent.GetHealth() > 0 && ++n >= HordeCount)
			return true;
	}
	return false;
}

function Bodyguard::OnGameEvent_round_start(params) {
	Bots = {};
	Trails = {};
	Generation++;
	if (ModeAllowed()) {
		foreach (name, value in Cvars)
			Convars.SetValue(name, value);
		Convars.SetValue("survivor_revive_duration", ReviveSeconds);
	}
	Tick(Generation);
}

function Bodyguard::Hook() {
	if (("GameEventCallbacks" in getroottable()) && ("hd4l_bodyguard" in ::GameEventCallbacks))
		return;
	__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
	::GameEventCallbacks["hd4l_bodyguard"] <- true;
}

Bodyguard.Hook();

if (!("HD4L_Parts" in getroottable()))
	::HD4L_Parts <- {};
::HD4L_Parts["bodyguard"] <- "0.1";
