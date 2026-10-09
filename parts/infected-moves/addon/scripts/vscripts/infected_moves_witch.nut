function InfectedMoves::OnGameEvent_witch_harasser_set(params) {
	if (!Witch || !ModeAllowed() || !("witchid" in params) || !("userid" in params))
		return;
	local witch = EntIndexToHScript(params.witchid);
	local harasser = null;
	try { harasser = GetPlayerFromUserID(params.userid); } catch (e) {}
	if (witch == null || !witch.IsValid() || harasser == null || !harasser.IsValid())
		return;
	Witches[params.witchid] <- { ent = witch, target = harasser, phase = "", until = 0.0, leapAt = Time() + 1.5, spot = null };
}

function InfectedMoves::WitchTick(w, index, now) {
	local witch = w.ent;
	if (!Alive(witch)) {
		delete Witches[index];
		return;
	}
	if (w.phase == "windup") {
		if (now < w.until)
			return;

		local to = w.spot - witch.GetOrigin();
		local flat = Flat(to);
		witch.ApplyAbsVelocityImpulse(flat * LeapSpeed + Vector(0, 0, LeapLift));
		w.phase = "air";
		w.until = now + LeapAir;
		return;
	}
	if (w.phase == "air") {
		if (now < w.until)
			return;

		local pos = witch.GetOrigin();
		Particle("hunter_leap_dust", pos, 1.0);
		local hit = false;
		foreach (s in Survivors()) {
			if ((s.GetOrigin() - pos).Length() > LeapHitRange)
				continue;
			hit = true;
			s.ApplyAbsVelocityImpulse(Flat(s.GetOrigin() - pos) * LeapKnock + Vector(0, 0, 150));
			try { s.Stagger(pos); } catch (e) {}
			s.TakeDamage(LeapDamage, DMG_CLUB, witch);
		}
		if (!hit)
			try { witch.Stagger(pos + Vector(RandomInt(-10, 10), RandomInt(-10, 10), 0)); } catch (e) {}
		w.phase = "";
		w.leapAt = now + LeapCooldown;
		return;
	}
	if (now < w.leapAt)
		return;
	local target = w.target;
	if (target == null || !target.IsValid() || target.IsDead()) {
		local near = Nearest(witch, Survivors());
		target = near.ent;
		w.target = target;
		if (target == null)
			return;
	}
	local d = (target.GetOrigin() - witch.GetOrigin()).Length();
	if (d < LeapMin || d > LeapMax)
		return;
	w.phase = "windup";
	w.until = now + LeapWindup;
	w.spot = target.GetOrigin();
	Sound(witch, Sounds.witch);
}
