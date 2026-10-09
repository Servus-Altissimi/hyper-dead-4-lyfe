function InfectedMoves::StopTank(index) {
	if (index in Charging)
		delete Charging[index];
	if (!(index in Tanks))
		return;
	delete Tanks[index];
}

function InfectedMoves::OnGameEvent_tank_killed(params) {
	local tank = null;
	if ("userid" in params)
		try { tank = GetPlayerFromUserID(params.userid); } catch (e) {}
	if (tank == null || !tank.IsValid())
		return;
	StopTank(tank.GetEntityIndex());
}

function InfectedMoves::Step(tank, t) {
	local pos = tank.GetOrigin();
	if (!("stepFrom" in t))
		t.stepFrom <- pos;
	local d = Vector(pos.x - t.stepFrom.x, pos.y - t.stepFrom.y, 0).Length();
	if (d < StepStride)
		return;
	t.stepFrom = pos;
	Particle("hunter_leap_dust", pos, 1.0);
	ScreenShake(pos, StepShake, 20.0, 0.25, StepShakeRadius, 0, false);
	try { EmitAmbientSoundOn(StepSound, 0.45, 85, 55, tank); } catch (e) {}
}

function InfectedMoves::TankState(tank) {
	local index = tank.GetEntityIndex();
	if (!(index in Tanks))
		Tanks[index] <- { ent = tank, phase = "", until = 0.0, rushAt = Time() + 2.0, slamAt = Time() + 3.0, dir = null, hit = {}, wave = 0, falling = false, fallSpeed = 0.0, lockUntil = 0.0, human = !IsPlayerABot(tank) };
	return Tanks[index];
}

function InfectedMoves::Knob(t, name) {
	if (t.human && (name in HumanKnobs))
		return HumanKnobs[name];
	if (Amped(t) && (name in AmpKnobs))
		return AmpKnobs[name];
	return this[name];
}

function InfectedMoves::Amped(t) {
	if (!("Escalation" in getroottable()) || !("IsAmped" in ::Escalation))
		return false;
	try { return ::Escalation.IsAmped(t.ent); } catch (e) { return false; }
}

function InfectedMoves::TankCooldown(t, seconds) {
	return Cooldown(seconds) * (Amped(t) ? AmpCooldown : 1.0);
}

function InfectedMoves::TankTick(tank, now) {
	local t = TankState(tank);
	local grounded = (NetProps.GetPropInt(tank, "m_fFlags") & FL_ONGROUND) != 0;

	if (!grounded) {
		t.falling = true;
		local vz = tank.GetVelocity().z;
		if (vz < t.fallSpeed) t.fallSpeed = vz;
	} else if (t.falling) {
		t.falling = false;
		if (t.fallSpeed <= -FallSpeed && t.phase == "") {
			Impact(tank.GetOrigin(), SlamRadius, SlamDamage, tank, "tank_ground_pound");
		}
		t.fallSpeed = 0.0;
	}
	if (TankSteps && grounded)
		Step(tank, t);

	if (t.phase != "") {
		TankPhase(tank, t, now);
		return;
	}
	if (tank.IsIncapacitated() || tank.IsStaggering())
		return;
	if (!IsPlayerABot(tank)) {
		if (HumanTank)
			TankInput(tank, t, now);
		return;
	}
	local near = Nearest(tank, Survivors());
	if (near.ent == null)
		return;
	local d = near.dist;
	if (d <= SlamRange && now >= t.slamAt) {
		TankBegin(tank, t, "slam", near.ent, now);
		return;
	}
	if (d >= SuperMin && d <= SuperMax && now >= t.slamAt && RandomInt(1, 100) <= SuperChance) {
		TankBegin(tank, t, "super", near.ent, now);
		return;
	}
	if (d >= RushMin && d <= RushMax && now >= t.rushAt)
		TankBegin(tank, t, "rush", near.ent, now);
}

function InfectedMoves::RushTick(index, generation) {
	if (generation != Generation || !(index in Tanks))
		return;
	local t = Tanks[index];
	local tank = t.ent;
	if (Dying(tank)) {
		StopTank(index);
		return;
	}
	if (t.phase != "rush_run")
		return;
	tank.SetVelocity(t.dir * Knob(t, "RushSpeed") + Vector(0, 0, 20));
	foreach (s in Survivors()) {
		local si = s.GetEntityIndex();
		if ((si in t.hit) || (s.GetOrigin() - tank.GetOrigin()).Length() > RushHitRange)
			continue;
		t.hit[si] <- true;
		s.ApplyAbsVelocityImpulse(t.dir * Knob(t, "RushKnock") + Vector(0, 0, 200));
		try { s.Stagger(tank.GetOrigin()); } catch (e) {}
		s.TakeDamage(Knob(t, "RushDamage"), DMG_CLUB, tank);
		Sound(s, Sounds.tank_hit);
	}
	DoEntFire("!self", "RunScriptCode", "::InfectedMoves.RushTick(" + index + ", " + generation + ")", 0.015, null, Entities.First());
}

function InfectedMoves::Retarget(tank) {
	local near = Nearest(tank, Survivors());
	if (near.ent == null)
		return;
	try { CommandABot({ cmd = 0, target = near.ent, bot = tank }); } catch (e) { return; }
	DoEntFire("!self", "RunScriptCode", "try { CommandABot({ cmd = 3, bot = self }); } catch (e) {}", RetargetSeconds, null, tank);
}

function InfectedMoves::TankInput(tank, t, now) {
	local buttons = 0;
	local pressed = 0;
	try { buttons = NetProps.GetPropInt(tank, "m_nButtons"); pressed = NetProps.GetPropInt(tank, "m_afButtonPressed"); } catch (e) { return; }
	if (!("prev" in t)) t.prev <- 0;
	pressed = pressed | (buttons & ~t.prev);
	t.prev = buttons;
	local view = Flat(tank.EyeAngles().Forward());
	if ((pressed & SuperKey) && now >= t.slamAt)
		TankBegin(tank, t, "super", null, now, view);
	else if (pressed & RushKey) {
		if (buttons & 4) {
			if (now >= t.slamAt)
				TankBegin(tank, t, "slam", null, now, view);
		} else if (now >= t.rushAt)
			TankBegin(tank, t, "rush", null, now, view);
	}
}

function InfectedMoves::TankBegin(tank, t, move, target, now, dir = null) {
	t.phase = move + "_windup";
	t.dir = dir != null ? dir : Flat(target.GetOrigin() - tank.GetOrigin());
	t.origin <- tank.GetOrigin();
	t.hit = {};
	t.wave = 0;
	Freeze(tank, true);
	Sound(tank, Sounds.tank_yell);
	Particle("tank_breath", tank.GetOrigin() + Vector(0, 0, 70), 1.0);
	local length = 0.0;
	if (move == "rush") {
		t.until = now + Knob(t, "RushWindup");
		length = Knob(t, "RushWindup") + Knob(t, "RushTime") + 0.4;
		Gesture(tank, "ACT_HULK_ATTACK_LOW");
	} else if (move == "slam") {
		t.until = now + Knob(t, "SlamWindup");
		length = Knob(t, "SlamWindup") + SlamLock + 0.4;
		Gesture(tank, "ACT_HULK_ATTACK_LOW");
	} else {
		t.until = now + Knob(t, "SuperWindup");
		length = Knob(t, "SuperWindup") + Knob(t, "SuperWaves") * Knob(t, "SuperDelay") + SuperLock + 0.4;
		Gesture(tank, "Attack_Incap_03");
	}
	if (t.human && HumanThirdPerson)
		try { NetProps.SetPropFloat(tank, "m_TimeForceExternalView", now + length); } catch (e) {}
}

function InfectedMoves::TankPhase(tank, t, now) {
	if (Dying(tank)) {
		StopTank(tank.GetEntityIndex());
		return;
	}
	if (now < t.until) {
		return;
	}

	if (t.phase == "rush_windup") {
		Freeze(tank, false);
		if (t.human)
			t.dir = Flat(tank.EyeAngles().Forward());
		t.phase = "rush_run";
		t.until = now + Knob(t, "RushTime");
		try { tank.OverrideFriction(Knob(t, "RushTime") + 0.1, 0.05); } catch (e) {}
		if (TankRushFire)
			Charging[tank.GetEntityIndex()] <- { ent = tank, last = tank.GetOrigin() };
		RushTick(tank.GetEntityIndex(), Generation);
	} else if (t.phase == "rush_run") {
		local index = tank.GetEntityIndex();
		if (index in Charging)
			delete Charging[index];
		tank.SetVelocity(t.dir * RushCarry);
		if (t.hit.len() == 0)
			try { tank.Stagger(tank.GetOrigin() - t.dir * 50); } catch (e) {}
		t.phase = "";
		t.rushAt = now + TankCooldown(t, RushCooldown);
		if (!t.human)
			Retarget(tank);
	} else if (t.phase == "slam_windup") {
		local pos = Ground(tank.GetOrigin(), tank);
		if (pos == null) pos = tank.GetOrigin();
		Impact(pos, Knob(t, "SlamRadius"), Knob(t, "SlamDamage"), tank, "tank_ground_pound");
		Sound(tank, Sounds.rock);
		t.phase = "slam_lock";
		t.until = now + SlamLock;
		t.lockUntil = t.until;
	} else if (t.phase == "super_windup") {
		if (t.human)
			t.dir = Flat(tank.EyeAngles().Forward());
		t.phase = "super_wave";
		t.until = now;
	} else if (t.phase == "super_wave") {
		t.wave++;
		local along = t.origin + t.dir * (100.0 + t.wave * Knob(t, "SuperSpacing"));
		local pos = Ground(along, tank);
		if (pos != null) {
			Impact(pos, Knob(t, "SuperRadius"), Knob(t, "SlamDamage"), tank, "tank_rock_throw_impact");
			Particle("tank_ground_pound", pos, 1.0);
			Sound(tank, Sounds.rock);
		}
		if (t.wave >= Knob(t, "SuperWaves")) {
			t.phase = "super_lock";
			t.until = now + SuperLock;
			t.lockUntil = t.until;
		} else
			t.until = now + Knob(t, "SuperDelay");
	} else if (t.phase == "slam_lock" || t.phase == "super_lock") {
		Freeze(tank, false);
		t.phase = "";
		t.slamAt = now + TankCooldown(t, SlamCooldown);
	}
}
