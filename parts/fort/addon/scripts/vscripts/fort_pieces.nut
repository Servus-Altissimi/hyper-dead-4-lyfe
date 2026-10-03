function Fort::StageOf(piece) {
	local stage = 0;
	foreach (i, s in Stages)
		if (piece.health <= piece.max * s.at)
			stage = i + 1;
	return stage;
}

function Fort::Infected(pos, radius) {
	local out = { commons = [], specials = [], tanks = [] };
	local ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "infected", pos, radius)) != null)
		if (ent.GetHealth() > 0)
			out.commons.append(ent);
	ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "player", pos, radius)) != null) {
		if (NetProps.GetPropInt(ent, "m_iTeamNum") != FORT_TEAM_INFECTED || ent.IsDead() || ent.IsGhost())
			continue;
		if (ent.GetZombieType() == FORT_ZOMBIE_TANK)
			out.tanks.append(ent);
		else
			out.specials.append(ent);
	}
	return out;
}

function Fort::WearTick(now) {
	local dt = now - LastWear;
	if (dt < WearInterval)
		return;
	LastWear = now;
	if (dt > 1.0)
		dt = WearInterval;
	foreach (index, piece in clone Pieces) {
		if (!piece.ent.IsValid()) {
			Unfx(piece);
			delete Pieces[index];
			continue;
		}
		if (piece.wrecked) {
			Break(index, piece);
			continue;
		}
		if (piece.kind == "mine") {
			Mine(index, piece);
			continue;
		}
		local near = Infected(piece.pos, piece.radius + Reach);
		local dps = near.specials.len() * SpecialDps + near.tanks.len() * TankDps;
		if (piece.kind == "wire")
			Trap(piece, now, WireEvery, WireDamage, FORT_DMG_SLASH, WireWear, Blood, 0.0);
		else if (piece.kind == "fire") {
			Trap(piece, now, FireEvery, FireDamage, FORT_DMG_BURN, FireWear, null, Reach);
			dps += near.commons.len() * CommonDps;
		} else
			dps += near.commons.len() * CommonDps;
		if (dps > 0.0 && index in Pieces)
			Hurt(index, piece, dps * dt);
	}
}

function Fort::PieceHit(damageTable) {
	if (Phase == "off" || !("Victim" in damageTable) || !("DamageDone" in damageTable))
		return false;
	local victim = damageTable.Victim;
	if (victim == null || !victim.IsValid())
		return false;
	local index = victim.GetEntityIndex();
	local attacker = ("Attacker" in damageTable) ? damageTable.Attacker : null;
	if (Phase != "wave" && !(index in Pieces) && attacker != null && attacker.IsValid() && attacker.GetClassname() == "player"
	    && NetProps.GetPropInt(attacker, "m_iTeamNum") == 2 && Salvageable(victim))
		return true;
	if (!(index in Pieces) || Pieces[index].ent != victim)
		return false;
	local piece = Pieces[index];
	if (Phase == "wave" && Hostile(attacker) && damageTable.DamageDone > 0) {
		if (attacker.GetClassname() == "player" && attacker.GetZombieType() == 8) {
			local dir = attacker.EyeAngles().Forward();
			piece.push <- Vector(dir.x, dir.y, 0) * TankThrow + Vector(0, 0, TankThrow * 0.4);
		}
		Hurt(index, piece, damageTable.DamageDone * HitScale);
		if (index in Pieces && RandomInt(1, 3) == 1)
			Particle(Dust, piece.pos + Vector(0, 0, 32), 0.6);
	}
	return true;
}

function Fort::Hostile(ent) {
	if (ent == null || !ent.IsValid())
		return false;
	local cls = ent.GetClassname();
	if (cls == "infected" || cls == "witch" || cls == "tank_rock")
		return true;
	return cls == "player" && NetProps.GetPropInt(ent, "m_iTeamNum") == FORT_TEAM_INFECTED;
}

function Fort::Trap(piece, now, every, damage, type, wear, fx, reach) {
	if (now < piece.trapAt)
		return;
	piece.trapAt = now + every;
	local victims = [];
	local ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "infected", piece.pos, piece.radius + reach)) != null)
		if (ent.GetHealth() > 0)
			victims.append(ent);
	local cut = 0;
	foreach (z in victims) {
		if (!z.IsValid())
			continue;
		z.TakeDamage(damage, type, Entities.First());
		if (fx != null)
			Particle(fx, z.GetOrigin() + Vector(0, 0, 30), 0.5);
		cut++;
	}
	if (cut > 0)
		Hurt(piece.ent.GetEntityIndex(), piece, cut * wear);
}

function Fort::Mine(index, piece) {
	local near = Infected(piece.pos, MineReach);
	if (near.commons.len() + near.specials.len() + near.tanks.len() == 0)
		return;
	local hit = Infected(piece.pos, MineRadius);
	local world = Entities.First();
	foreach (z in hit.commons)
		if (z.IsValid())
			z.TakeDamage(MineDamage.common, FORT_DMG_BLAST, world);
	foreach (s in hit.specials)
		if (s.IsValid())
			s.TakeDamage(MineDamage.special, FORT_DMG_BLAST, world);
	foreach (t in hit.tanks)
		if (t.IsValid())
			t.TakeDamage(MineDamage.tank, FORT_DMG_BLAST, world);
	Particle(MineEffect, piece.pos + Vector(0, 0, 8), 2.0);
	SoundAt(Sounds.Mine, piece.pos);
	ScreenShake(piece.pos, 10.0, 40.0, 0.8, MineRadius * 3.0, 0, false);
	local push = SpawnEntityFromTable("env_physexplosion", { magnitude = "700", radius = MineRadius.tostring(), spawnflags = "1", origin = piece.pos });
	if (push != null) {
		DoEntFire("!self", "Explode", "", 0, null, push);
		DoEntFire("!self", "Kill", "", 0.1, null, push);
	}
	piece.ent.Kill();
	delete Pieces[index];
	Fall(piece, false);
}

function Fort::Drop(piece) {
	if (piece.kind == "gun")
		return;
	local ents = [ piece.ent ];
	foreach (fx in piece.fx)
		if (fx != null && fx.IsValid() && fx.GetClassname().find("prop_") == 0)
			ents.append(fx);
	local list = [];
	foreach (e in ents)
		if (e != null && e.IsValid()) {
			local to = e.GetOrigin();
			list.append({ ent = e, to = to });
			e.SetOrigin(to + Vector(0, 0, DropHeight));
		}
	piece.drop <- { start = Time(), ents = list };
	Dropping.append(piece);
}

function Fort::DropTick(now) {
	foreach (piece in clone Dropping) {
		local t = (now - piece.drop.start) / DropTime;
		local done = t >= 1.0;
		local h = done ? 0.0 : DropHeight * (1.0 - t * t);
		foreach (d in piece.drop.ents)
			if (d.ent.IsValid())
				d.ent.SetOrigin(d.to + Vector(0, 0, h));
		if (!done)
			continue;
		Dropping.remove(Dropping.find(piece));
		delete piece.drop;
		ScreenShake(piece.pos, 2.0, 20.0, 0.25, 220.0, 0, false);
		Particle(Dust, piece.pos, 0.8);
	}
}

function Fort::Loose(piece) {
	if (!Collapse || !Solid(piece.bp) || piece.kind == "gun")
		return;
	local push = ("push" in piece) ? piece.push : Vector(RandomFloat(-FallPush, FallPush), RandomFloat(-FallPush, FallPush), FallPush);
	local ents = [ piece.ent ];
	foreach (fx in piece.fx)
		if (fx != null && fx.IsValid() && fx.GetClassname().find("prop_") == 0)
			ents.append(fx);
	local now = Time();
	local shots = [];
	foreach (e in ents)
		if (e != null && e.IsValid()) {
			shots.append({ model = e.GetModelName(), origin = e.GetOrigin(), angles = e.GetAngles() });
			e.Kill();
		}
	foreach (shot in shots) {
		local d = SpawnEntityFromTable("prop_physics_override", { model = shot.model, origin = shot.origin,
			angles = AnglesText(shot.angles), targetname = FORT_DEBRIS_NAME, nodamageforces = 0 });
		if (d == null || !d.IsValid())
			continue;
		try { d.ApplyAbsVelocityImpulse(push); } catch (e2) {}
		Debris.append({ ent = d, until = now + DebrisLife, last = d.GetOrigin(), hit = {} });
	}
	while (Debris.len() > MaxDebris) {
		local old = Debris.remove(0);
		if (old.ent != null && old.ent.IsValid())
			old.ent.Kill();
	}
}

function Fort::DebrisTick(now, dt) {
	foreach (i, d in clone Debris) {
		if (d.ent == null || !d.ent.IsValid() || now >= d.until) {
			if (d.ent != null && d.ent.IsValid())
				d.ent.Kill();
			local at = Debris.find(d);
			if (at != null)
				Debris.remove(at);
			continue;
		}
		local pos = d.ent.GetOrigin();
		local speed = dt > 0.0 ? (pos - d.last).Length() / dt : 0.0;
		d.last = pos;
		if (speed < CrushSpeed)
			continue;
		local centre = pos;
		try { centre = d.ent.GetCenter(); } catch (e) {}
		foreach (cls in [ "infected", "player" ]) {
			local z = null;
			while ((z = Entities.FindByClassnameWithin(z, cls, centre, CrushRadius)) != null) {
				if (cls == "player" && NetProps.GetPropInt(z, "m_iTeamNum") != FORT_TEAM_INFECTED)
					continue;
				local idx = z.GetEntityIndex();
				if (idx in d.hit)
					continue;
				d.hit[idx] <- true;
				z.TakeDamage(cls == "player" ? CrushSpecial : CrushDamage, 1, d.ent);
			}
		}
	}
}

function Fort::Hurt(index, piece, amount) {
	piece.health -= amount;
	if (piece.health <= 0.0) {
		Break(index, piece);
		return;
	}
	local stage = StageOf(piece);
	if (stage != piece.stage) {
		piece.stage = stage;
		DoEntFire("!self", "Color", Tint(piece), 0, null, piece.ent);
		SoundAt(Sounds.Crack, piece.pos);
		Particle(Dust, piece.pos + Vector(0, 0, 24), 1.0);
	}
}

function Fort::Break(index, piece) {
	if (piece.kind == "gun") {
		local user = null;
		try { user = NetProps.GetPropEntity(piece.ent, "m_owner"); } catch (e) {}
		if (user != null && user.IsValid()) {
			piece.wrecked = true;
			return;
		}
	}
	SoundAt(Sounds.Break, piece.pos);
	Particle(Dust, piece.pos, 1.5);
	Particle(Dust, piece.pos + Vector(0, 0, 32), 1.5);
	ScreenShake(piece.pos, 6.0, 30.0, 0.5, 400.0, 0, false);
	if (Phase == "wave")
		try { Loose(piece); } catch (e) { Log("collapse failed: " + e); }
	Unfx(piece);
	if (piece.ent.IsValid())
		piece.ent.Kill();
	if (index in Pieces)
		delete Pieces[index];
	Fall(piece, false);
}
