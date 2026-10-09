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
