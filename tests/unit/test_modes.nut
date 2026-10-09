::ROOT <- vargv.len() > 0 ? vargv[0] : ".";
dofile(::ROOT + "/tests/unit/mock.nut");
Suite("modes");

function Dir(name) {
	if (name == "glory_kill2")
		return "glory-kill";
	local out = "";
	foreach (i, word in split(name, "_"))
		out += (i > 0 ? "-" : "") + word;
	return out;
}

Load("parts/core/addon/scripts/vscripts/hd4l_core.nut");
foreach (name, table in ::HD4L.Tables) {
	local dir = "parts/" + Dir(name) + "/addon/scripts/vscripts/";
	Load(dir + name + ".nut");
	if ("Files" in getroottable()[table])
		foreach (file in getroottable()[table].Files)
			Load(dir + file + ".nut");
}

function Parts() {
	local out = { core = ::HD4L };
	foreach (name, table in ::HD4L.Tables)
		out[name] <- getroottable()[table];
	return out;
}

function Round(mode) {
	Reset();
	::T.mode = mode;
	::GameEventCallbacks.clear();
	MakeSurvivor("Nick", 1);
	MakeSurvivor("Ellis", 2);
	MakeSpecial(8, 4000, 50);
	local errors = [];
	foreach (name, part in Parts())
		if ("OnGameEvent_round_start" in part)
			try { part.OnGameEvent_round_start({}); } catch (e) { errors.append(name + ": " + e); }
	foreach (f in clone ::T.fired)
		if (f.input == "RunScriptCode")
			try { compilestring(f.param)(); } catch (e) { errors.append(f.param + ": " + e); }
	return errors;
}

function Report(errors) {
	foreach (e in errors)
		print("    " + e + "\n");
	return errors.len() == 0;
}

foreach (mode in [ "hd4l", "hd4lversus", "hd4lsurvival", "hd4lfort", "hd4lfreebuild" ]) {
	Check(Report(Round(mode)), mode + ": round start and the first ticks never throw");
	local off = [];
	foreach (name, skip in ::HD4L.Skip[mode])
		if (skip && name != "fort" && Parts()[name].ModeAllowed())
			off.append(name);
	Check(Report(off), mode + ": every skipped part stays off");
}

local stock = { violence_hblood = 1, violence_ablood = 1 };
foreach (mode in [ "coop", "realism", "versus", "survival", "scavenge", "mutation4" ]) {
	Check(Report(Round(mode)), mode + ": round start and the first ticks never throw");
	local on = [];
	foreach (name, part in Parts())
		if ("ModeAllowed" in part && part.ModeAllowed())
			on.append(name);
	Check(Report(on), mode + ": every part stays off");
	local changed = [];
	foreach (name, value in ::T.cvars)
		if (!(name in stock) || stock[name] != value)
			changed.append(name + " = " + value);
	Check(Report(changed), mode + ": cvars only go back to stock");
	local spawned = [];
	foreach (e in ::T.spawned)
		if (e.cls != "point_clientcommand")
			spawned.append(e.cls);
	Check(Report(spawned) && ::T.sounds.len() == 0, mode + ": nothing spawns or plays but the stock HUD restore");
	local touched = [];
	foreach (e in ::T.ents)
		if (e.cls == "player" && (e.props.m_flLaggedMovementValue != 1.0 || e.props.m_afButtonDisabled != 0 || e.events.len() > 0))
			touched.append(e.name);
	Check(Report(touched), mode + ": players keep stock speed, buttons and health");
}

Done();
