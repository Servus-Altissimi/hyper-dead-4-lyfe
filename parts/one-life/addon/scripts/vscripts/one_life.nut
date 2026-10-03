const DMG_FALL = 32;
const SAVE_TABLE = "OneLifeDead";

::OneLife <- {
	Versus = true,
	Survival = false,
	Stock = false,

	Permawipe = true,

	CarryDeaths = true,

	CarryDelay = 2.0,
	CarryAttempts = 30,
	Carried = {},

	CondemnSeconds = 1.0,
	Condemned = {},

	Generation = 0
}

function OneLife::Log(msg) {
	printl("[OneLife] " + msg);
}

function OneLife::ModeAllowed() {
	local mode = "";
	try { mode = Director.GetGameMode(); } catch (e) {}
	if ((mode == "hd4lfort" || mode == "hd4lfreebuild"))
		return Stock;
	if (mode == "hd4lsurvival")
		return Survival;
	if (mode != "hd4l" && mode != "hd4lversus")
		return false;
	return Versus || mode == "hd4l";
}

function OneLife::InVersus() {
	local mode = "";
	try { mode = Director.GetGameMode(); } catch (e) {}
	return mode == "hd4lversus";
}

function OneLife::ApplyRules() {
	Convars.SetValue("sv_rescue_disabled", 1);
	Convars.SetValue("sv_permawipe", (Permawipe && !InVersus()) ? 1 : 0);
	local root = getroottable();
	if (!("SessionOptions" in root))
		root.SessionOptions <- {};
	root.SessionOptions.cm_AllowSurvivorRescue <- 0;
	if ("DirectorScript" in root && "DirectorOptions" in root.DirectorScript)
		root.DirectorScript.DirectorOptions.cm_AllowSurvivorRescue <- 0;
}

function OneLife::Survivors() {
	local list = [];
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null)
		if (p.IsSurvivor())
			list.append(p);
	return list;
}

function OneLife::OnGameEvent_map_transition(params) {
	if (!ModeAllowed() || !CarryDeaths || InVersus() || !("SaveTable" in getroottable()))
		return;
	local dead = {};
	foreach (p in Survivors())
		if (p.IsDead() || p.IsDying())
			dead["c" + NetProps.GetPropInt(p, "m_survivorCharacter")] <- true;
	SaveTable(SAVE_TABLE, dead);
}

function OneLife::OnGameEvent_round_start(params) {
	Generation++;
	Condemned = {};
	if (!ModeAllowed())
		return;
	ApplyRules();
	if (CarryDeaths && !InVersus() && "RestoreTable" in getroottable())
		DoEntFire("!self", "RunScriptCode", "::OneLife.ApplyCarriedDeaths(" + Generation + ")", CarryDelay, null, Entities.First());
}

function OneLife::ApplyCarriedDeaths(generation) {
	if (generation != Generation)
		return;
	local first = false;
	try { first = Director.IsFirstMapInScenario(); } catch (e) {}
	local dead = {};
	RestoreTable(SAVE_TABLE, dead);
	if (first || dead.len() == 0) {
		SaveTable(SAVE_TABLE, {});
		return;
	}
	SaveTable(SAVE_TABLE, dead);
	Carried = dead;
	TryCarriedDeaths(generation, 0);
}

function OneLife::TryCarriedDeaths(generation, attempt) {
	if (generation != Generation)
		return;
	local targets = [];
	foreach (p in Survivors()) {
		if (p.IsDead() || p.IsDying())
			continue;
		if (!(("c" + NetProps.GetPropInt(p, "m_survivorCharacter")) in Carried))
			continue;
		targets.append(p);
	}
	if (targets.len() < Carried.len() && attempt < CarryAttempts) {
		DoEntFire("!self", "RunScriptCode", "::OneLife.TryCarriedDeaths(" + generation + ", " + (attempt + 1) + ")", 1.0, null, Entities.First());
		return;
	}
	foreach (p in targets) {
		if (!IsPlayerABot(p))
			Condemned[p.GetPlayerUserId()] <- Time();
		p.TakeDamage(99999, DMG_FALL, Entities.First());
		if (!p.IsDead())
			p.TakeDamage(99999, 0, Entities.First());
	}
	SaveTable(SAVE_TABLE, {});
	Carried = {};
}

function OneLife::IsCondemned(p) {
	if (p == null || !p.IsValid())
		return false;
	local id = p.GetPlayerUserId();
	return (id in Condemned) && Time() - Condemned[id] <= CondemnSeconds;
}

function OneLife::Hook() {
	if (("GameEventCallbacks" in getroottable()) && ("hd4l_one_life" in ::GameEventCallbacks))
		return;
	__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
	::GameEventCallbacks["hd4l_one_life"] <- true;
}

OneLife.Hook();

if (!("HD4L_Parts" in getroottable()))
	::HD4L_Parts <- {};
::HD4L_Parts["one_life"] <- "0.1";
