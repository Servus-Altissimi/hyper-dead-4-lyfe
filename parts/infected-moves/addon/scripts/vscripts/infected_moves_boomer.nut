function InfectedMoves::OnGameEvent_player_death(params) {
	if (!BoomerPop || !ModeAllowed() || !("userid" in params))
		return;
	local boomer = null;
	try { boomer = GetPlayerFromUserID(params.userid); } catch (e) { return; }
	if (boomer == null || !boomer.IsValid() || NetProps.GetPropInt(boomer, "m_iTeamNum") != TEAM_INFECTED || boomer.GetZombieType() != ZOMBIE_BOOMER)
		return;
	Pop(boomer.GetOrigin());
}

function InfectedMoves::Pop(pos) {
	Particle("tank_ground_pound", pos, 1.0);
	ScreenShake(pos, 6.0, 30.0, 0.5, PopRadius * 2.0, 0, false);
	local push = SpawnEntityFromTable("env_physexplosion", { magnitude = "600", radius = PopRadius.tostring(), spawnflags = "1", origin = pos });
	if (push != null) {
		DoEntFire("!self", "Explode", "", 0, null, push);
		DoEntFire("!self", "Kill", "", 0.1, null, push);
	}
	local ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "infected", pos, PopRadius)) != null) {
		if (ent.GetHealth() <= 0)
			continue;
		ent.TakeDamage(0, DMG_STAGGER, Entities.First());
		ent.ApplyAbsVelocityImpulse(Flat(ent.GetOrigin() - pos) * PopPush + Vector(0, 0, PopLift));
	}
	local speaker = SpawnEntityFromTable("info_target", { origin = pos });
	if (speaker != null) {
		Loud(PopSound, speaker, 105, 70);
		DoEntFire("!self", "Kill", "", 2.0, null, speaker);
	}
}

function InfectedMoves::BoomerTick(boomer, now) {
	local index = boomer.GetEntityIndex();
	if (!(index in Boomers))
		Boomers[index] <- { ent = boomer, near = 0.0, phase = "", until = 0.0, nextDrip = 0.0 };
	local b = Boomers[index];
	if (b.phase == "retch") {
		if (now >= b.nextDrip) {
			Particle("boomer_vomit", boomer.GetOrigin() + Vector(0, 0, 50), 0.6);
			b.nextDrip = now + 0.5;
		}
		if (now < b.until)
			return;

		local inner = Convars.GetFloat("z_exploding_inner_radius");
		local outer = Convars.GetFloat("z_exploding_outer_radius");
		Convars.SetValue("z_exploding_inner_radius", BurstRadius * 0.5);
		Convars.SetValue("z_exploding_outer_radius", BurstRadius);
		boomer.TakeDamage(boomer.GetHealth() + 100, DMG_BLAST, Entities.First());
		DoEntFire("!self", "RunScriptCode", "Convars.SetValue(\"z_exploding_inner_radius\", " + inner + "); Convars.SetValue(\"z_exploding_outer_radius\", " + outer + ")", 0.3, null, Entities.First());
		b.phase = "burst";
		return;
	}
	if (b.phase != "")
		return;
	local near = Nearest(boomer, Survivors());
	if (near.ent != null && near.dist <= SwellRange)
		b.near += 0.1;
	if (b.near < SwellSeconds)
		return;
	b.phase = "retch";
	b.until = now + RetchSeconds;
	Freeze(boomer, true);
	Sound(boomer, Sounds.boomer);
}
