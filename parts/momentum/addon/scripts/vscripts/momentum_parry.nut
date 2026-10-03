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
