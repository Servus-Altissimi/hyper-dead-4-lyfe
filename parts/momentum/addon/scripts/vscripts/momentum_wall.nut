function Momentum::OnGameEvent_player_ledge_grab(params) {
	if (!LedgeVault || !ModeAllowed() || !("userid" in params))
		return;
	local p = null;
	try { p = GetPlayerFromUserID(params.userid); } catch (e) { return; }
	if (p == null || !p.IsValid() || !p.IsSurvivor() || IsPlayerABot(p))
		return;
	local s = StateOf(p);
	s.vaultRevives = NetProps.GetPropInt(p, "m_currentReviveCount");
	DoEntFire("!self", "RunScriptCode", "::Momentum.Vault(" + params.userid + ")", 0.15, null, Entities.First());
}

function Momentum::Vault(userid) {
	local p = null;
	try { p = GetPlayerFromUserID(userid); } catch (e) { return; }
	if (p == null || !p.IsValid() || p.IsDead() || !p.IsHangingFromLedge())
		return;
	local s = StateOf(p);
	try { p.ReviveFromIncap(); } catch (e) {}
	NetProps.SetPropInt(p, "m_currentReviveCount", s.vaultRevives);
	NetProps.SetPropInt(p, "m_bIsOnThirdStrike", 0);
	if (p.IsHangingFromLedge()) {
		local up = Flat(p.EyeAngles().Forward());
		p.SetOrigin(p.GetOrigin() + up * 40 + Vector(0, 0, 70));
		p.SetVelocity(Vector(0, 0, 150));
	}
	ResetFall(p);
	EmitSoundOn(Sounds.Jump, p);
}

function Momentum::SolidAt(p, from, dir, reach) {
	local trace = { start = from, end = from + dir * reach, ignore = p };
	TraceLine(trace);
	if (!trace.hit)
		return false;
	if (("enthit" in trace) && trace.enthit != null) {
		local cls = trace.enthit.GetClassname();
		if (cls == "player" || cls == "infected" || cls == "witch")
			return false;
	}
	return true;
}

function Momentum::WallAt(p, centre, dir) {
	local feet = p.GetOrigin();
	if (!SolidAt(p, feet + Vector(0, 0, 20), dir, WallRunReach))
		return false;
	if (!SolidAt(p, feet + Vector(0, 0, 60), dir, WallRunReach))
		return false;
	local ahead = Flat(p.EyeAngles().Forward()) * 0.8 + dir;
	ahead.Norm();
	return SolidAt(p, centre, ahead, WallRunReach * 1.7);
}

function Momentum::SetRoll(p, roll) {
	try {
		NetProps.SetPropVector(p, "m_Local.m_vecPunchAngle", Vector(0, 0, roll));
		NetProps.SetPropVector(p, "m_Local.m_vecPunchAngleVel", Vector(0, 0, 0));
	} catch (e) {}
}

function Momentum::WallRunUpdate(p, s, buttons, pressed, now) {
	local holding = (buttons & IN_FORWARD) != 0;
	if (!holding || s.stamina <= 0.0) {
		EndWallRun(p, s);
		return false;
	}
	local yaw = p.EyeAngles().y * DEG;
	local right = Vector(sin(yaw), -cos(yaw), 0);
	local centre = p.GetOrigin() + Vector(0, 0, 36);

	if (!s.wallRun) {
		local vel = p.GetVelocity();
		if (Vector(vel.x, vel.y, 0).Length() < WallRunMinSpeed || s.stamina < 5.0)
			return false;
		local side = 0;
		if (WallAt(p, centre, right))
			side = 1;
		else if (WallAt(p, centre, right * -1.0))
			side = -1;
		if (side == 0)
			return false;
		s.wallRun = true;
		s.wallSide = side;
		EndMove(p, s);
		SetGravity(p, WallRunGravity);
		if (vel.z < WallRunHop) {
			vel.z = WallRunHop;
			p.SetVelocity(vel);
		}
		ResetFall(p);
		EmitSoundOn(Sounds.Dash, p);
		return false;
	}

	if (!WallAt(p, centre, right * s.wallSide.tofloat())) {
		EndWallRun(p, s);
		return false;
	}
	if (pressed & IN_JUMP) {
		WallJump(p, s, right);
		return true;
	}
	s.stamina -= WallRunDrain * 0.0333;
	if (s.stamina < 0.0)
		s.stamina = 0.0;
	s.spentAt = now;
	SetRoll(p, -s.wallSide * WallRunRoll);
	return false;
}

function Momentum::WallJump(p, s, right) {
	local away = right * (-s.wallSide.tofloat());
	local forward = Flat(p.EyeAngles().Forward());
	p.SetVelocity(forward * WallJumpForward + away * WallJumpAway + Vector(0, 0, WallJumpUp));
	ResetFall(p);
	EndWallRun(p, s);
	s.jumps = ExtraJumps;
	EmitSoundOn(Sounds.Jump, p);
}

function Momentum::EndWallRun(p, s) {
	if (!s.wallRun)
		return;
	s.wallRun = false;
	s.wallSide = 0;
	s.wallRunAt = Time();
	if (!s.kick)
		SetGravity(p, 1.0);
	SetRoll(p, 0.0);
}
