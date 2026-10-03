function Momentum::Fx() {
	return ("HD4L" in getroottable()) && ("Eyes" in ::HD4L);
}

function Momentum::Boom(sound, ent, pitch = 100) {
	if (Fx())
		try { ::HD4L.Loud(sound, ent, 100, pitch); return; } catch (e) {}
	EmitSoundOn(sound, ent);
}

function Momentum::Aura(p, s) {
	if (!SurvivorEyes || !Fx())
		return;
	local kind = "";
	if (Time() < s.hyperUntil || s.lastStand)
		kind = "hyper";
	else if (Boosted(p, s))
		kind = "boost";
	if (kind == s.eyesKind)
		return;
	::HD4L.Unfx(s.eyes, 0.3);
	s.eyes = null;
	s.eyesKind = kind;
	if (kind == "")
		return;
	s.eyes = ::HD4L.Eyes(p, kind == "hyper" ? HyperEyes : BoostEyes, 64.0);
}

function Momentum::Streak(p, s, on) {
	if (!Fx())
		return;
	if (s.streak != null) {
		::HD4L.Unfx([ s.streak ], StreakLife);
		s.streak = null;
	}
	if (!on)
		return;
	s.streak = ::HD4L.Trail(p.GetOrigin() + Vector(0, 0, 36), StreakColor, StreakLife, StreakWidth, StreakAlpha);
	if (s.streak != null)
		::HD4L.Attach(s.streak, p, "");
}

function Momentum::Ghost(p, s, now) {
	s.ghostAt = now + GhostEvery;
	s.ghosts++;
	local model = p.GetModelName();
	if (model == "")
		return;
	local ang = p.GetAngles();
	local vel = p.GetVelocity();
	local dir = Vector(vel.x, vel.y, 0);
	if (dir.Length() < 50.0)
		dir = s.kick && s.kickDir != null ? Flat(s.kickDir) : (s.moveDir != null ? s.moveDir : Flat(p.EyeAngles().Forward()));
	dir = Flat(dir);
	local ghost = SpawnEntityFromTable("prop_dynamic_override", { model = model, origin = p.GetOrigin() - dir * GhostBack, angles = "0 " + ang.y + " 0",
		solid = 0, disableshadows = 1, rendermode = 5, renderamt = GhostAlpha, rendercolor = GhostColor, DefaultAnim = "" });
	if (ghost == null)
		return;
	try {
		NetProps.SetPropInt(ghost, "m_nSequence", NetProps.GetPropInt(p, "m_nSequence"));
		NetProps.SetPropFloat(ghost, "m_flCycle", NetProps.GetPropFloat(p, "m_flCycle"));
		NetProps.SetPropFloat(ghost, "m_flPlaybackRate", 0.0);
	} catch (e) {}
	DoEntFire("!self", "DisableCollision", "", 0, null, ghost);
	local steps = 3;
	for (local i = 1; i <= steps; i++)
		DoEntFire("!self", "Alpha", (GhostAlpha * (steps - i) / steps).tostring(), GhostLife * i / (steps + 1), null, ghost);
	DoEntFire("!self", "Kill", "", GhostLife, null, ghost);
}

function Momentum::ClearFx(s) {
	if (!Fx())
		return;
	::HD4L.Unfx(s.eyes, 0.3);
	if (s.streak != null)
		::HD4L.Unfx([ s.streak ], 0.3);
	s.eyes = null;
	s.eyesKind = "";
	s.streak = null;
}

function Momentum::HyperBang(p) {
	local origin = p.GetOrigin();
	foreach (effect in HyperBurst) {
		local gfx = SpawnEntityFromTable("info_particle_system", { effect_name = effect, origin = origin + Vector(0, 0, 8), start_active = 1 });
		if (gfx != null)
			DoEntFire("!self", "Kill", "", 1.5, null, gfx);
	}
	ScreenShake(origin, 10.0, 40.0, 0.6, 300.0, 0, false);
	if (Fx())
		::HD4L.Flash(origin + Vector(0, 0, 48), EyeColor, 1.5, 0.25);
	local fade = SpawnEntityFromTable("env_fade", { spawnflags = "5", duration = "0.4", holdtime = "0.05", renderamt = HyperFlash.tostring(), rendercolor = "255 250 240" });
	if (fade != null) {
		DoEntFire("!self", "Fade", "", 0, p, fade);
		DoEntFire("!self", "Kill", "", 1.0, null, fade);
	}
	Boom(Sounds.Chain, p, 80);
	Boom(Sounds.Heavy, p, 115);
}

function Momentum::SpeedFx(p, s) {
	local on = s.move != "" || s.kick || s.wallRun;
	if (on == s.fxOn)
		return;
	s.fxOn = on;
	s.ghosts = 0;
	Streak(p, s, on);
}

function Momentum::LandingFx(p) {
	local origin = p.GetOrigin();
	ScreenShake(origin, 8.0, 16.0, 0.5, 125.0, 0, false);
	local water = false;
	try { water = NetProps.GetPropInt(p, "m_nWaterLevel") != 0; } catch (e) {}
	local sound = water ? LandingSounds.water[RandomInt(0, LandingSounds.water.len() - 1)] : LandingSounds.ground;
	EmitSoundOn(sound, p);
	EmitSoundOn(sound, p);
	local dust = SpawnEntityFromTable("info_particle_system", { effect_name = water ? LandingParticles.water : LandingParticles.ground,
		origin = water ? origin - Vector(0, 0, 32) : origin, start_active = 1 });
	if (dust != null)
		DoEntFire("!self", "Kill", "", 1.0, null, dust);
}
