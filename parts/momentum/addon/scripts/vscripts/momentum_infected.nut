function Momentum::AbilityFlag(p, prop) {
	try {
		local ability = NetProps.GetPropEntity(p, "m_customAbility");
		if (ability == null)
			return false;
		return NetProps.GetPropInt(ability, prop) != 0;
	} catch (e) { return false; }
}

function Momentum::UpdateInfected(p) {
	local s = StateOf(p);
	local now = Time();
	local buttons = NetProps.GetPropInt(p, "m_nButtons");
	local pressed = 0;
	try { pressed = NetProps.GetPropInt(p, "m_afButtonPressed"); } catch (e) {}
	pressed = pressed | (buttons & ~s.prev);
	s.prev = buttons;
	Regen(p, s, now);

	local onGround = (NetProps.GetPropInt(p, "m_fFlags") & FL_ONGROUND) != 0;
	if (onGround && !s.ground) {
		s.jumps = ExtraJumps;
		EndWallRun(p, s);
	}
	s.ground = onGround;
	if (p.IsIncapacitated() || p.IsStaggering()) {
		EndWallRun(p, s);
		return;
	}

	local zt = p.GetZombieType();
	if (zt == 8) {
		if (RockParry && (pressed & IN_ATTACK))
			TankParryCheck(p, false);
		return;
	}
	if (zt == 1)
		BlinkCheck(p, s, pressed, now);
	else if (zt == 3) {
		local held = null;
		try { held = NetProps.GetPropEntity(p, "m_pounceVictim"); } catch (e) {}
		local lunging = AbilityFlag(p, "m_isLunging");
		if (held != null || lunging)
			EndWallRun(p, s);
		else if (!onGround)
			WallRunUpdate(p, s, buttons, pressed, now);
		else if (s.wallRun)
			EndWallRun(p, s);
	} else if (zt == 5) {
		local riding = null;
		try { riding = NetProps.GetPropEntity(p, "m_jockeyVictim"); } catch (e) {}
		if ((pressed & IN_JUMP) && riding == null && !onGround && s.jumps > 0)
			JockeyDash(p, s, buttons);
	}
}

function Momentum::JockeyDash(p, s, buttons) {
	if (!Spend(p, s, "jump"))
		return;
	local dir = MoveDir(p, buttons);
	if (dir == null)
		dir = Flat(p.EyeAngles().Forward());
	local vel = p.GetVelocity();
	p.SetVelocity(Vector(dir.x * JockeyDashSpeed, dir.y * JockeyDashSpeed, (vel.z > 0 ? vel.z : 0) + JockeyDashLift));
	ResetFall(p);
	s.jumps--;
	EmitSoundOn(Sounds.Dash, p);
}

function Momentum::BlinkCheck(p, s, pressed, now) {
	if (!(pressed & BlinkKey))
		return;
	local tongue = null;
	try { tongue = NetProps.GetPropEntity(p, "m_tongueVictim"); } catch (e) {}
	if (tongue != null || now < s.blinkAt)
		return;
	if (s.stamina < Cost.blink) {
		EmitSoundOn(Sounds.Deny, p);
		return;
	}
	local survivors = [];
	local q = null;
	while ((q = Entities.FindByClassname(q, "player")) != null)
		if (q.IsSurvivor() && !q.IsDead())
			survivors.append(q);

	local spot = null;
	if (("InfectedMoves" in getroottable()) && ("HiddenSpot" in ::InfectedMoves))
		try { spot = ::InfectedMoves.HiddenSpot(p, survivors, BlinkMin, BlinkMax); } catch (e) { spot = null; }
	if (spot == null) {
		EmitSoundOn(Sounds.Deny, p);
		return;
	}
	Spend(p, s, "blink");
	local origin = p.GetOrigin();
	foreach (at in [ origin, spot ]) {
		local cloud = SpawnEntityFromTable("info_particle_system", { effect_name = BlinkCloud, start_active = 1, origin = at + Vector(0, 0, 30) });
		if (cloud != null)
			DoEntFire("!self", "Kill", "", 2.0, null, cloud);
	}
	p.SetOrigin(spot);
	p.SetVelocity(Vector(0, 0, 0));
	s.blinkAt = now + BlinkCooldown;
	EmitSoundOn(Sounds.Dash, p);
}
