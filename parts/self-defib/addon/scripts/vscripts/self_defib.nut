const SELFDEFIB_MAX_WEAPONS = 5;

::SelfDefib <- {
	Versus = true,
	Survival = true,
	Stock = true,

	ReviveHealth = 50,
	ReviveTemp = 25,

	GraceSeconds = 1.5,

	Density = 1.0,
	ConvertChance = 50,
	ConvertFrom = {
		weapon_upgradepack_explosive_spawn = "weapon_defibrillator_spawn",
		weapon_upgradepack_incendiary_spawn = "weapon_defibrillator_spawn",
		weapon_upgradepack_explosive = "weapon_defibrillator",
		weapon_upgradepack_incendiary = "weapon_defibrillator"
	},

	Effect = "electrical_arc_01",
	ShakeAmplitude = 8.0,

	Installed = {},
	Previous = {},
	InHook = false
}

function SelfDefib::Log(msg) {
	printl("[SelfDefib] " + msg);
}

function SelfDefib::ModeAllowed() {
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

function SelfDefib::Precache() {
	PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = Effect, origin = Vector(0, 0, 0), start_active = 1 });
}

function SelfDefib::Held(player) {
	for (local i = 0; i < SELFDEFIB_MAX_WEAPONS; i++) {
		local weapon = null;
		try { weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i); } catch (e) { continue; }
		if (weapon != null && weapon.IsValid() && weapon.GetClassname() == "weapon_defibrillator")
			return weapon;
	}
	return null;
}

function SelfDefib::CanRevive(player) {
	if (!ModeAllowed() || player == null || !player.IsValid())
		return false;
	if (player.GetClassname() != "player" || !player.IsSurvivor() || player.IsDead())
		return false;
	return Held(player) != null;
}

function SelfDefib::Revive(player) {
	local defib = Held(player);
	if (defib == null)
		return false;
	try { defib.Kill(); } catch (e) { Log("defib not removed: " + e); }

	player.SetHealth(ReviveHealth);
	try {
		NetProps.SetPropInt(player, "m_bIsOnThirdStrike", 0);
		NetProps.SetPropInt(player, "m_currentReviveCount", 0);
	} catch (e) {}
	if (ReviveTemp > 0) {
		try {
			NetProps.SetPropFloat(player, "m_healthBuffer", ReviveTemp.tofloat());
			NetProps.SetPropFloat(player, "m_healthBufferTime", Time());
		} catch (e) {}
	}

	local origin = player.GetOrigin();
	local gfx = SpawnEntityFromTable("info_particle_system", { effect_name = Effect, origin = origin + Vector(0, 0, 40), start_active = 1 });
	if (gfx != null)
		DoEntFire("!self", "Kill", "", 2.0, null, gfx);
	local shake = SpawnEntityFromTable("env_shake", { amplitude = ShakeAmplitude.tostring(), radius = "600", duration = "0.5", frequency = "40", spawnflags = "4", origin = origin });
	if (shake != null) {
		DoEntFire("!self", "StartShake", "", 0, null, shake);
		DoEntFire("!self", "Kill", "", 1.0, null, shake);
	}

	if (GraceSeconds > 0.0) {
		try { NetProps.SetPropInt(player, "m_takedamage", 0); } catch (e) {}
		DoEntFire("!self", "RunScriptCode", "::SelfDefib.EndGrace(" + player.GetPlayerUserId() + ")", GraceSeconds, null, Entities.First());
	}
	return true;
}

function SelfDefib::EndGrace(userid) {
	local player = null;
	try { player = GetPlayerFromUserID(userid); } catch (e) { return; }
	if (player != null && player.IsValid())
		try { NetProps.SetPropInt(player, "m_takedamage", 2); } catch (e) {}
}

function SelfDefib::ApplyDensity() {
	if (Density <= 0.0 || !ModeAllowed())
		return;
	local root = getroottable();
	if (!("SessionOptions" in root))
		::SessionOptions <- {};
	::SessionOptions.DefibrillatorDensity <- Density;
	if (("DirectorScript" in root) && ("DirectorOptions" in ::DirectorScript))
		::DirectorScript.DirectorOptions.DefibrillatorDensity <- Density;
}

function SelfDefib::ConvertHook(scopeName, classname) {
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
	if (ConvertChance > 0 && (classname in ConvertFrom) && RandomInt(1, 100) <= ConvertChance)
		return ConvertFrom[classname];
	return result;
}

function SelfDefib::InstallHook() {
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
		Installed[scopeName] <- function(classname) { return ::SelfDefib.ConvertHook(name, classname); };
		scope.ConvertWeaponSpawn <- Installed[scopeName];
	}
	if (!found)
		Log("no mode scope, density only");
}

function SelfDefib::OnGameEvent_round_start(params) {
	ApplyDensity();
}

function SelfDefib::Hook() {
	InstallHook();
	ApplyDensity();

	if (("GameEventCallbacks" in getroottable()) && ("hd4l_self_defib" in ::GameEventCallbacks))
		return;
	__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
	::GameEventCallbacks["hd4l_self_defib"] <- true;
}

SelfDefib.Precache();
SelfDefib.Hook();

if (!("HD4L_Parts" in getroottable()))
	::HD4L_Parts <- {};
::HD4L_Parts["self_defib"] <- "0.1";
