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
