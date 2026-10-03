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
