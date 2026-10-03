function Momentum::StartMove(p, s, buttons, now, move) {
	if (s.move != "")
		return;
	if (!Spend(p, s, move))
		return;
	local dir = MoveDir(p, buttons);
	if (dir == null)
		dir = Flat(p.EyeAngles().Forward());
	local speed = move == "heavy" ? HeavySpeed : (move == "slide" ? SlideSpeed : DashSpeed);
	local time = move == "heavy" ? HeavyTime : (move == "slide" ? SlideTime : DashTime);

	s.move = move;
	s.moveDir = dir;
	s.moveUntil = now + time;
	s.moveHits = {};
	if (move == "dash")
		s.dashCooldownUntil = now + DashCooldown;

	local vel = p.GetVelocity();
	vel.x = dir.x * speed;
	vel.y = dir.y * speed;
	p.SetVelocity(vel);
	if (move == "slide")
		try { p.SetFriction(SlideFriction); } catch (e) {}

	if (move == "heavy") {
		HeavyCheck(p, s);
		Boom(Sounds.Heavy, p);
	} else {
		ShoveCheck(p, s);
		EmitSoundOn(Sounds.Dash, p);
	}
}

function Momentum::EndMove(p, s) {
	if (s.move == "")
		return;
	local was = s.move;
	s.move = "";
	if (was == "slide")
		try { p.SetFriction(1.0); } catch (e) {}
}

function Momentum::ShoveCheck(p, s) {
	local centre = p.GetOrigin() + Vector(0, 0, 32);
	local ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "infected", centre, ShoveRange + 40)) != null) {
		if (!Near(centre, ent, ShoveRange) || !Facing(centre, s.moveDir, ent, ShoveDot) || !MarkOnce(s.moveHits, ent))
			continue;
		if (Boosted(p, s) && ent.GetHealth() > 0) {
			ent.ApplyAbsVelocityImpulse(s.moveDir * LaunchCommon + Vector(0, 0, LaunchUp));
			Credit(p, "dash");
			SuperKill(ent, p);
			Boom(Sounds.Kill, p, RandomInt(82, 96));
			continue;
		}
		ent.TakeDamage(0, DMG_STAGGER, p);
		ent.ApplyAbsVelocityImpulse(s.moveDir * ShovePush + Vector(0, 0, 50));
		EmitSoundOn(Sounds.Shove, p);
	}
	ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "player", centre, ShoveRange + 40)) != null) {
		if (NetProps.GetPropInt(ent, "m_iTeamNum") != TEAM_INFECTED || ent.IsDead() || ent.IsGhost() || ent.GetZombieType() == ZOMBIE_TANK)
			continue;
		if (!Near(centre, ent, ShoveRange) || !Facing(centre, s.moveDir, ent, ShoveDot) || !MarkOnce(s.moveHits, ent))
			continue;
		if (GloryFinish(ent, p, "dash"))
			continue;
		ent.Stagger(p.GetOrigin());
		EmitSoundOn(Sounds.Shove, p);
	}
}

function Momentum::SuperKill(ent, p) {
	local origin = ent.GetOrigin() + Vector(0, 0, 40);
	if (SuperGib) {
		ent.TakeDamage(1000, DMG_CLUB | DMG_BLAST | DMG_ALWAYSGIB, p);
		local fx = SpawnEntityFromTable("info_particle_system", { origin = origin, effect_name = "boomer_explode_D", start_active = 1 });
		if (fx != null)
			DoEntFire("!self", "Kill", "", 2.0, null, fx);
	} else
		ent.TakeDamage(1000, DMG_CLUB | DMG_BLAST, p);
}

function Momentum::HeavyCheck(p, s) {
	local centre = p.GetOrigin() + Vector(0, 0, 32);
	local ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "infected", centre, HeavyRange + 40)) != null) {
		if (ent.GetHealth() <= 0 || !Near(centre, ent, HeavyRange) || !Facing(centre, s.moveDir, ent, HeavyDot) || !MarkOnce(s.moveHits, ent))
			continue;
		ent.ApplyAbsVelocityImpulse(s.moveDir * HeavyLaunch + Vector(0, 0, HeavyLift));
		Credit(p, "heavy");
		SuperKill(ent, p);
		Boom(Sounds.Kill, p, RandomInt(82, 96));
	}
	ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "player", centre, HeavyRange + 40)) != null) {
		if (NetProps.GetPropInt(ent, "m_iTeamNum") != TEAM_INFECTED || ent.IsDead() || ent.IsGhost())
			continue;
		if (!Near(centre, ent, HeavyRange) || !Facing(centre, s.moveDir, ent, HeavyDot) || !MarkOnce(s.moveHits, ent))
			continue;
		if (GloryFinish(ent, p, "dash"))
			continue;
		if (ent.GetZombieType() != ZOMBIE_TANK) {
			ent.Stagger(p.GetOrigin());
			ent.ApplyAbsVelocityImpulse(s.moveDir * (HeavyLaunch * 0.5) + Vector(0, 0, 100));
		}
		ent.TakeDamage(HeavyDamageSpecial, DMG_CLUB, p);
		EmitSoundOn(Sounds.Shove, p);
	}
	foreach (cls in [ "prop_door_rotating", "prop_door_rotating_checkpoint" ]) {
		ent = null;
		while ((ent = Entities.FindByClassnameWithin(ent, cls, centre, HeavyDoorRange)) != null) {
			if (!Facing(centre, s.moveDir, ent, 0.5) || !MarkOnce(s.moveHits, ent))
				continue;
			BreakDoor(ent, p);
		}
	}
	ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "prop_physics", centre, HeavyRange + 40)) != null) {
		if (!Near(centre, ent, HeavyRange + 20) || !Facing(centre, s.moveDir, ent, HeavyDot) || !MarkOnce(s.moveHits, ent))
			continue;
		ent.ApplyAbsVelocityImpulse(s.moveDir * PropLaunch + Vector(0, 0, PropLift));
		ArmExplosive(ent, p);
	}

	ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "witch", centre, HeavyRange + 40)) != null) {
		if (ent.GetHealth() <= 0 || !Near(centre, ent, HeavyRange) || !Facing(centre, s.moveDir, ent, HeavyDot) || !MarkOnce(s.moveHits, ent))
			continue;
		ent.TakeDamage(WitchTackleDamage, DMG_CLUB, p);
		try { ent.Stagger(p.GetOrigin()); } catch (e) {}
		ent.ApplyAbsVelocityImpulse(s.moveDir * (HeavyLaunch * 0.4) + Vector(0, 0, 80));
		Boom(Sounds.Kill, p, RandomInt(82, 96));
	}
}

function Momentum::BreakDoor(door, p) {
	if (door.GetClassname() == "prop_door_rotating_checkpoint" && !BreakCheckpointDoors)
		return;
	if (door.GetHealth() <= 0)
		return;
	local model = "";
	try { model = door.GetModelName().tolower(); } catch (e) {}
	local wood = false;
	foreach (hint in [ "wood", "plank", "doormain", "farm", "mill", "residential", "restaurant", "interior" ])
		if (model.find(hint) != null)
			wood = true;
	EmitSoundOn(wood ? Sounds.DoorWood : Sounds.DoorMetal, p);
	door.TakeDamage(door.GetHealth() + 1000, DMG_CLUB, p);
}

function Momentum::OnGameEvent_player_shoved(params) {
	if (!TeammateShove || !ModeAllowed() || !("userid" in params) || !("attacker" in params))
		return;
	local shoved = null;
	local shover = null;
	try { shoved = GetPlayerFromUserID(params.userid); shover = GetPlayerFromUserID(params.attacker); } catch (e) { return; }
	if (shoved == null || shover == null || !shoved.IsValid() || !shover.IsValid() || shoved == shover)
		return;
	if (!shoved.IsSurvivor() || !shover.IsSurvivor() || shoved.IsDead())
		return;
	if (!BotsShoveTeammates && IsPlayerABot(shover))
		return;
	if (Blocked(shoved))
		return;
	local weapon = null;
	try { weapon = shover.GetActiveWeapon(); } catch (e) {}
	if (weapon != null && weapon.IsValid() && (weapon.GetClassname() in ItemWeapons))
		return;
	local dir = Flat(shoved.GetOrigin() - shover.GetOrigin());
	if (dir.Length() < 0.1)
		dir = Flat(shover.EyeAngles().Forward());
	shoved.ApplyAbsVelocityImpulse(dir * TeammateShovePush + Vector(0, 0, TeammateShoveLift));
	ResetFall(shoved);
	try { shoved.Stagger(shover.GetOrigin()); } catch (e) {}
	try {
		NetProps.SetPropIntArray(shoved, "m_NetGestureSequence", shoved.LookupSequence("ACT_TERROR_FLINCH"), 6);
		NetProps.SetPropIntArray(shoved, "m_NetGestureActivity", shoved.LookupActivity("ACT_TERROR_FLINCH"), 6);
		NetProps.SetPropFloatArray(shoved, "m_NetGestureStartTime", Time(), 6);
	} catch (e) {}
	local damage = TeammateShoveDamage;
	if (shoved.GetHealth() - damage < 1)
		damage = shoved.GetHealth() - 1;
	if (damage > 0)
		shoved.TakeDamage(damage, DMG_CLUB, shover);
	EmitSoundOn(Sounds.Shove, shoved);
}

function Momentum::OnGameEvent_entity_shoved(params) {
	if (!ShoveBreaksDoors || !ModeAllowed() || !("entityid" in params) || !("attacker" in params))
		return;
	local door = EntIndexToHScript(params.entityid);
	if (door == null || !door.IsValid())
		return;
	local cls = door.GetClassname();
	if (cls != "prop_door_rotating" && cls != "prop_door_rotating_checkpoint")
		return;
	local p = null;
	try { p = GetPlayerFromUserID(params.attacker); } catch (e) { return; }
	if (p == null || !p.IsValid() || !p.IsSurvivor())
		return;
	BreakDoor(door, p);
}

function Momentum::ArmExplosive(prop, p) {
	local model = "";
	try { model = prop.GetModelName().tolower(); } catch (e) { return; }
	foreach (hint in ExplosiveHints) {
		if (model.find(hint) != null) {
			DoEntFire("!self", "RunScriptCode", "self.TakeDamage(500, 64, Entities.First())", ExplosiveFuse, p, prop);
			return;
		}
	}
}

function Momentum::OpenDoors(p, s) {
	local centre = p.GetOrigin() + Vector(0, 0, 32);
	foreach (cls in [ "prop_door_rotating", "prop_door_rotating_checkpoint" ]) {
		local door = null;
		while ((door = Entities.FindByClassnameWithin(door, cls, centre, DoorOpenRange)) != null) {
			if (!Facing(centre, s.moveDir, door, 0.5) || !MarkOnce(s.moveHits, door))
				continue;
			local state = 1;
			try { state = NetProps.GetPropInt(door, "m_eDoorState"); } catch (e) {}
			if (state == 0)
				DoEntFire("!self", "OpenAwayFrom", "!activator", 0, p, door);
		}
	}
}

function Momentum::StartKick(p, s, now) {
	if (!Spend(p, s, "kick"))
		return;
	local dir = p.EyeAngles().Forward();
	if (dir.z < -0.6) {
		dir.z = -0.6;
		dir.Norm();
	}
	local pitch = p.EyeAngles().x;
	if (pitch > 180.0) pitch -= 360.0;
	local level = 1.0 - fabs(pitch) / 90.0;
	if (level < 0.0) level = 0.0;
	local launch = s.wallRun || now - s.wallRunAt <= WallKickGrace;

	EndMove(p, s);
	EndWallRun(p, s);
	s.wallRunAt = -10.0;
	p.SetVelocity(dir * (launch ? KickSpeed * WallKickSpeed : KickSpeed) + Vector(0, 0, KickLift * level));
	ResetFall(p);
	SetGravity(p, KickGravity);
	s.kick = true;
	s.kickUntil = now + KickTime;
	s.kickDir = dir;
	s.kickHits = {};
	s.kickLaunch = launch;
	s.kicks--;
	EmitSoundOn(Sounds.Kick, p);
}

function Momentum::EndKick(p, s, hit) {
	if (!s.kick)
		return;
	s.kick = false;
	SetGravity(p, 1.0);
	if (!hit && Boosted(p, s))
		s.kicks = AirKicks;
}

function Momentum::KickCheck(p, s) {
	local centre = p.GetOrigin() + Vector(0, 0, 36);
	local hit = false;
	local kills = 0;
	local solid = false;
	local ent = null;

	while ((ent = Entities.FindByClassnameWithin(ent, "prop_physics", centre, KickRange + 40)) != null) {
		if (!Near(centre, ent, KickRange + 20) || !Facing(centre, s.kickDir, ent, KickDot) || !MarkOnce(s.kickHits, ent))
			continue;
		ent.ApplyAbsVelocityImpulse(s.kickDir * PropLaunch + Vector(0, 0, PropLift));
		ArmExplosive(ent, p);
		EmitSoundOn(Sounds.Shove, p);
		solid = true;
	}
	ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "tank_rock", centre, KickRange + 60)) != null) {
		if (!MarkOnce(s.kickHits, ent))
			continue;
		ent.TakeDamage(1000, DMG_CLUB, p);
		Boom(Sounds.Kill, p, RandomInt(82, 96));
		solid = true;
	}
	ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "infected", centre, KickRange + KickBodyHigh)) != null) {
		if (ent.GetHealth() <= 0 || !KickReach(centre, s.kickDir, ent) || !MarkOnce(s.kickHits, ent))
			continue;
		hit = true;
		ent.ApplyAbsVelocityImpulse(s.kickDir * LaunchCommon + Vector(0, 0, LaunchUp));
		Credit(p, "kick");
		SuperKill(ent, p);
		Boom(Sounds.Kill, p, RandomInt(82, 96));
		kills++;
	}
	ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "witch", centre, KickRange + KickBodyHigh)) != null) {
		if (ent.GetHealth() <= 0 || !KickReach(centre, s.kickDir, ent) || !MarkOnce(s.kickHits, ent))
			continue;
		ent.TakeDamage(KickDamageWitch, DMG_CLUB, p);
		try { ent.Stagger(p.GetOrigin()); } catch (e) {}
		EmitSoundOn(Sounds.Shove, p);
		hit = true;
	}
	ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "player", centre, KickRange + KickBodyHigh)) != null) {
		if (NetProps.GetPropInt(ent, "m_iTeamNum") != TEAM_INFECTED || ent.IsDead() || ent.IsGhost())
			continue;
		if (!KickReach(centre, s.kickDir, ent) || !MarkOnce(s.kickHits, ent))
			continue;
		hit = true;
		if (GloryFinish(ent, p, "kick")) {
			kills++;
			continue;
		}
		local scale = s.kickLaunch ? WallKickDamage : 1.0;
		local amount = (ent.GetZombieType() == ZOMBIE_TANK ? KickDamageTank : KickDamageSpecial) * scale;
		ent.TakeDamage(amount, KickDamageType, p);
		if (ent.GetZombieType() != ZOMBIE_TANK)
			ent.Stagger(p.GetOrigin());
		EmitSoundOn(Sounds.Shove, p);
	}
	if (hit) {
		Bounce(p, s, kills);
		return;
	}
	if (!solid) {
		local trace = { start = centre, end = centre + s.kickDir * WallKickReach, ignore = p };
		TraceLine(trace);
		if (trace.hit && (!("enthit" in trace) || trace.enthit == null || trace.enthit.GetClassname() != "player"))
			solid = true;
	}
	if (solid)
		WallBounce(p, s);
}

function Momentum::WallBounce(p, s) {
	local back = Flat(s.kickDir) * -1.0;
	p.SetVelocity(back * BounceBack + Vector(0, 0, BounceUp));
	ResetFall(p);
	EndKick(p, s, true);
	s.kicks = AirKicks;
	EmitSoundOn(Sounds.Dash, p);
}

function Momentum::Bounce(p, s, kills) {
	local back = Flat(s.kickDir) * -1.0;
	p.SetVelocity(back * BounceBack + Vector(0, 0, BounceUp));
	ResetFall(p);
	EndKick(p, s, true);
	if (RefundOnHit) {
		s.kicks = AirKicks;
		Refund(p, s, Cost.kick);
	}
	if (kills > 0) {
		s.chain += kills;
		s.stacks += kills;
		if (s.stacks > StackMax)
			s.stacks = StackMax;
		s.stackUntil = Time() + StackSeconds;
		Boom(Sounds.Chain, p);
		if (s.chain >= HyperChain && s.hyperUntil <= 0.0)
			StartHyper(p, s);
	}
}

function Momentum::StartHyper(p, s) {
	s.hyperUntil = Time() + HyperSeconds;
	Refill(p);
	HyperBang(p);
}

function Momentum::StartDive(p, s, side, now) {
	if (now < s.diveCooldownUntil || !Spend(p, s, "dive"))
		return;
	local yaw = p.EyeAngles().y * DEG;
	local right = Vector(sin(yaw), -cos(yaw), 0);
	local vel = p.GetVelocity();
	vel.x = right.x * DiveSpeed * side;
	vel.y = right.y * DiveSpeed * side;
	p.SetVelocity(vel);
	s.dive = "dash";
	s.diveUntil = now + DiveTime;
	s.diveCooldownUntil = now + DiveCooldown;
	try {
		if (NetProps.GetPropInt(p, "m_takedamage") == 2) {
			NetProps.SetPropInt(p, "m_takedamage", 0);
			s.diveGod = true;
		}
	} catch (e) {}
	EmitSoundOn(Sounds.Dash, p);
}

function Momentum::DiveUpdate(p, s, now) {
	if (now < s.diveUntil)
		return;
	if (s.dive == "dash") {
		DiveVulnerable(p, s);
		s.dive = "slow";
		s.diveUntil = now + DiveSlowTime;
	} else
		EndDive(p, s);
}

function Momentum::DiveVulnerable(p, s) {
	if (!s.diveGod)
		return;
	s.diveGod = false;
	try { if (NetProps.GetPropInt(p, "m_takedamage") == 0) NetProps.SetPropInt(p, "m_takedamage", 2); } catch (e) {}
}

function Momentum::EndDive(p, s) {
	if (s.dive == "")
		return;
	s.dive = "";
	DiveVulnerable(p, s);
}
