::AdrenalineSupply <- {
	Versus = true,
	Survival = true,
	Stock = false,

	Convert = { weapon_pain_pills_spawn = "weapon_adrenaline_spawn", weapon_pain_pills = "weapon_adrenaline" },

	Installed = {},
	Previous = {},
	InHook = false
}

function AdrenalineSupply::Log(msg) {
	printl("[AdrenalineSupply] " + msg);
}

function AdrenalineSupply::ModeAllowed() {
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

function AdrenalineSupply::ConvertHook(scopeName, classname) {
	local result = 0;
	if (!InHook && (scopeName in Previous) && Previous[scopeName] != null) {
		InHook = true;
		try { result = Previous[scopeName].call(getroottable()[scopeName], classname); } catch (e) { Log("previous " + scopeName + " convert hook failed: " + e); }
		InHook = false;
	}
	if (InHook || !ModeAllowed())
		return result;

	if (result != 0 && result != null && result != classname)
		return result;
	if (classname in Convert)
		return Convert[classname];
	return result;
}

function AdrenalineSupply::InstallHook() {
	local root = getroottable();
	local found = false;
	foreach (scopeName in [ "g_ModeScript", "g_MapScript" ]) {
		if (!(scopeName in root) || typeof root[scopeName] != "table")
			continue;
		found = true;
		local scope = root[scopeName];
		if (("ConvertWeaponSpawn" in scope) && (scopeName in Installed) && scope.ConvertWeaponSpawn == Installed[scopeName])
			continue;
		Previous[scopeName] <- ("ConvertWeaponSpawn" in scope) ? scope.ConvertWeaponSpawn : null;
		local name = scopeName;
		Installed[scopeName] <- function(classname) { return ::AdrenalineSupply.ConvertHook(name, classname); };
		scope.ConvertWeaponSpawn <- Installed[scopeName];
	}
	if (!found)
		Log("no mode scope, no conversions");
}

function AdrenalineSupply::Hook() {
	InstallHook();
}

AdrenalineSupply.Hook();

if (!("HD4L_Parts" in getroottable()))
	::HD4L_Parts <- {};
::HD4L_Parts["adrenaline_supply"] <- "0.1";
