::HD4LTest <- { pass = 0, fail = 0, witch = null, hunter = null };

function HD4LTest::Say(line) {
	printl("[HD4L test] " + line);
}

function HD4LTest::Check(ok, what) {
	if (ok) {
		pass++;
		Say("ok   " + what);
	} else {
		fail++;
		Say("FAIL " + what);
	}
}

function HD4LTest::Human() {
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null)
		if (p.IsSurvivor() && !IsPlayerABot(p) && !p.IsDead())
			return p;
	return null;
}

function HD4LTest::Ahead(p, dist) {
	local fwd = p.EyeAngles().Forward();
	fwd.z = 0.0;
	fwd.Norm();
	return p.GetOrigin() + fwd * dist;
}

function HD4LTest::Particles(effect) {
	local n = 0;
	local e = null;
	while ((e = Entities.FindByClassname(e, "info_particle_system")) != null) {
		local name = "";
		try { name = NetProps.GetPropString(e, "m_iszEffectName"); } catch (x) {}
		if (name == effect)
			n++;
	}
	return n;
}

function HD4LTest::Start() {
	pass = 0;
	fail = 0;
	Say("start, mode " + Director.GetGameMode());
	Check(Director.GetGameMode() == "hd4l", "running in hd4l mode");
	local root = getroottable();
	Check("HD4L" in root, "core loaded");
	if ("HD4L" in root) {
		foreach (name, inVersus in ::HD4L.Required)
			Check(name in ::HD4L_Parts, "part present: " + name);
		local markers = 0;
		if ("GameEventCallbacks" in root)
			foreach (key, value in ::GameEventCallbacks)
				if (typeof key == "string" && key.find("hd4l_") == 0)
					markers++;
		Check(markers >= ::HD4L.Required.len(), "hooks armed: " + markers + " hd4l markers");
	}
	Check(Convars.GetFloat("phys_pushscale") == 2.5, "corpses lighter: phys_pushscale 2.5 (got " + Convars.GetFloat("phys_pushscale") + ")");
	Check(Convars.GetFloat("z_witch_health") == 1500, "witch health 1500");
	Check(Convars.GetFloat("z_tank_speed") == 260, "tank speed 260");
	Check(Convars.GetFloat("vomitjar_radius") == 0, "bile jar is a flashbang");

	local p = Human();
	Check(p != null, "a human survivor to test with");
	if (p == null)
		return Finish();
	witch = ZSpawn({ type = 7, pos = Ahead(p, 500), ang = QAngle(0, 0, 0) });
	hunter = ZSpawn({ type = 3, pos = Ahead(p, 200), ang = QAngle(0, 0, 0) });
	try { p.UseAdrenaline(15.0); } catch (e) { NetProps.SetPropInt(p, "m_bAdrenalineActive", 1); }
	p.GiveItem("pistol");
	try { IncludeScript("hd4l_testbots"); } catch (e) { Check(false, "bot test loads: " + e); }
	DoEntFire("!self", "RunScriptCode", "::HD4LTest.Later()", 1.5, null, Entities.First());
}

function HD4LTest::Later() {
	local p = Human();
	Check(Particles("hd4l_eyes_red") >= 2, "witch has red eyes (" + Particles("hd4l_eyes_red") + " particles)");
	Check(Particles("hd4l_eyes_white") >= 2 || Particles("hd4l_eyes_hyper") >= 2, "adrenaline gives white eyes");
	if (("Arsenal" in getroottable()) && p != null) {
		local st = ::Arsenal.State(p);
		::Arsenal.AutoStep(p, st, Time());
		Check(::Arsenal.AutoMode != "", "pistol autofire route picked: " + ::Arsenal.AutoMode);
	}
	if (hunter == null) {
		local e = null;
		while ((e = Entities.FindByClassname(e, "player")) != null)
			if (NetProps.GetPropInt(e, "m_iTeamNum") == 3 && !e.IsDead() && e.GetZombieType() == 3)
				hunter = e;
	}
	Check(hunter != null && hunter.IsValid(), "hunter spawned");
	if (hunter != null && hunter.IsValid() && p != null && ("GloryKill2" in getroottable())) {
		::GloryKill2.OpenWindow(hunter, p);
		Check(::GloryKill2.IsOpen(hunter), "glory window opens on the hunter");
		Check(::GloryKill2.TryFinish(hunter, p, "shove"), "shove finishes it");
		DoEntFire("!self", "RunScriptCode", "::HD4LTest.Check(!::HD4LTest.hunter.IsValid() || ::HD4LTest.hunter.IsDead(), \"hunter dead after the finisher\"); ::HD4LTest.Finish()", 0.5, null, Entities.First());
		return;
	}
	Finish();
}

function HD4LTest::Finish() {
	Say("RESULT pass=" + pass + " fail=" + fail);
}

HD4LTest.Start();
