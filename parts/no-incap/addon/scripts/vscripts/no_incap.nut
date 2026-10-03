const DMG_GENERIC = 0;
const DMG_FALL = 32;
const DMG_CRUSH = 1;

::NoIncap <- {
	Versus = true,
	Survival = true,
	Stock = true,

	HumansOnly = true,

	PropSafe = true,

	FlagSeconds = 0.1,

	Installed = {},
	Previous = {},
	InHook = false
}

function NoIncap::Log(msg) {
	printl("[NoIncap] " + msg);
}

function NoIncap::ModeAllowed() {
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

function NoIncap::Applies(player) {
	if (player == null || !player.IsValid() || player.GetClassname() != "player" || !player.IsSurvivor() || player.IsDead())
		return false;
	return !(HumansOnly && IsPlayerABot(player));
}

function NoIncap::Lethal(player) {
	local buffer = 0.0;
	try {
		buffer = player.GetHealthBuffer();
		local since = Time() - NetProps.GetPropFloat(player, "m_healthBufferTime");
		buffer -= since * Convars.GetFloat("pain_pills_decay_rate");
		if (buffer < 0.0)
			buffer = 0.0;
	} catch (e) { try { buffer = player.GetHealthBuffer(); } catch (e2) { buffer = 0.0; } }
	return player.GetHealth() + buffer;
}

function NoIncap::DamageHook(scopeName, damageTable) {
	local allow = true;
	if (!InHook && (scopeName in Previous) && Previous[scopeName] != null) {
		InHook = true;
		try { allow = Previous[scopeName].call(getroottable()[scopeName], damageTable); } catch (e) { Log("previous " + scopeName + " damage hook failed: " + e); }
		InHook = false;
	}
	if (InHook || allow == false || !ModeAllowed() || !("Victim" in damageTable) || !("DamageDone" in damageTable))
		return allow;

	local victim = damageTable.Victim;

	if (("Fort" in getroottable()) && ("PieceHit" in ::Fort)) {
		local piece = false;
		try { piece = ::Fort.PieceHit(damageTable); } catch (e) { Log("fort piece hit failed: " + e); }
		if (piece)
			return false;
	}

	if (("Projectiles" in getroottable()) && ("Intercept" in ::Projectiles)) {
		local held = false;
		try { held = ::Projectiles.Intercept(damageTable); } catch (e) { Log("projectile intercept failed: " + e); }
		if (held)
			return false;
	}

	if (PropSafe && PropCrush(damageTable))
		return false;
	if (("DoorBlast" in getroottable()) && ("Harmless" in ::DoorBlast)) {
		local harmless = false;
		try { harmless = ::DoorBlast.Harmless(damageTable); } catch (e) { harmless = false; }
		if (harmless)
			return false;
	}
	if (("Armour" in getroottable()) && ("Scale" in ::Armour))
		try { ::Armour.Scale(damageTable); } catch (e) { Log("armour failed: " + e); }
	if (("Arsenal" in getroottable()) && ("MeleeHit" in ::Arsenal))
		try { ::Arsenal.MeleeHit(damageTable); } catch (e) { Log("blunt melee failed: " + e); }
	if (("Arsenal" in getroottable()) && ("ScaleDamage" in ::Arsenal))
		try { ::Arsenal.ScaleDamage(damageTable); } catch (e) { Log("pistol damage failed: " + e); }
	if (!Applies(victim) || victim.IsIncapacitated() || victim.IsHangingFromLedge())
		return allow;
	if (damageTable.DamageDone < Lethal(victim))
		return allow;

	local condemned = false;
	if (("OneLife" in getroottable()) && ("IsCondemned" in ::OneLife))
		try { condemned = ::OneLife.IsCondemned(victim); } catch (e) { condemned = false; }

	if (!condemned && ("SelfDefib" in getroottable()) && ("CanRevive" in ::SelfDefib)) {
		local can = false;
		try { can = ::SelfDefib.CanRevive(victim); } catch (e) { can = false; }
		if (can) {
			local revived = false;
			try { revived = ::SelfDefib.Revive(victim); } catch (e) { Log("self defib failed: " + e); }
			if (revived) {
				return false;
			}
		}
	}

	if (!condemned && !IsPlayerABot(victim) && ("BotTakeover" in getroottable()) && ("CanHijack" in ::BotTakeover)) {
		local can = false;
		try { can = ::BotTakeover.CanHijack(victim); } catch (e) { can = false; }
		if (can) {
			try { ::BotTakeover.Hijack(victim); } catch (e) { Log("hijack failed: " + e); }
			return false;
		}
	}

	local maxIncaps = 2;
	try { maxIncaps = Convars.GetFloat("survivor_max_incapacitated_count").tointeger(); } catch (e) {}
	local count = 0;
	try { count = NetProps.GetPropInt(victim, "m_currentReviveCount"); } catch (e) {}
	NetProps.SetPropInt(victim, "m_bIsOnThirdStrike", 1);
	if (count < maxIncaps)
		NetProps.SetPropInt(victim, "m_currentReviveCount", maxIncaps);
	DoEntFire("!self", "RunScriptCode", "::NoIncap.ClearFlag(" + victim.GetPlayerUserId() + ", " + count + ")", FlagSeconds, null, Entities.First());
	return allow;
}

function NoIncap::PropCrush(damageTable) {
	local victim = damageTable.Victim;
	if (victim == null || !victim.IsValid() || victim.GetClassname() != "player" || !victim.IsSurvivor())
		return false;
	if (!("DamageType" in damageTable) || !(damageTable.DamageType & DMG_CRUSH) || !("Inflictor" in damageTable))
		return false;
	local prop = damageTable.Inflictor;
	if (prop == null || !prop.IsValid() || prop.GetClassname().find("prop_") != 0)
		return false;
	local attacker = ("Attacker" in damageTable) ? damageTable.Attacker : null;
	if (attacker != null && attacker.IsValid() && attacker.GetClassname() == "player" && NetProps.GetPropInt(attacker, "m_iTeamNum") == 3)
		return false;
	local thrower = null;
	try { thrower = NetProps.GetPropEntity(prop, "m_hPhysicsAttacker"); } catch (e) {}
	if (thrower != null && thrower.IsValid() && thrower.GetClassname() == "player" && NetProps.GetPropInt(thrower, "m_iTeamNum") == 3)
		return false;
	return true;
}

function NoIncap::ClearFlag(userid, count) {
	local player = null;
	try { player = GetPlayerFromUserID(userid); } catch (e) { return; }
	if (player != null && player.IsValid() && !player.IsDead()) {
		NetProps.SetPropInt(player, "m_bIsOnThirdStrike", 0);
		NetProps.SetPropInt(player, "m_currentReviveCount", count);
	}
}

function NoIncap::InstallDamageHook() {
	local root = getroottable();
	local found = false;
	foreach (scopeName in [ "g_ModeScript", "g_MapScript" ]) {
		if (!(scopeName in root) || typeof root[scopeName] != "table")
			continue;
		found = true;
		local scope = root[scopeName];
		if (("AllowTakeDamage" in scope) && (scopeName in Installed) && scope.AllowTakeDamage == Installed[scopeName])
			continue;
		Previous[scopeName] <- ("AllowTakeDamage" in scope) ? scope.AllowTakeDamage : null;
		local name = scopeName;
		Installed[scopeName] <- function(damageTable) { return ::NoIncap.DamageHook(name, damageTable); };
		scope.AllowTakeDamage <- Installed[scopeName];
	}
	if (!found)
		Log("no mode scope, catching incaps instead");
}

function NoIncap::OnGameEvent_player_incapacitated(params) {
	if (!("userid" in params) || !ModeAllowed())
		return;
	local player = null;
	try { player = GetPlayerFromUserID(params.userid); } catch (e) { return; }
	if (!Applies(player) || !player.IsIncapacitated() || player.IsHangingFromLedge())
		return;
	Kill(player);
}

function NoIncap::Kill(player) {
	local world = Entities.First();
	player.TakeDamage(99999, DMG_FALL, world);
	if (!player.IsDead())
		player.TakeDamage(99999, DMG_GENERIC, world);
}

function NoIncap::Hook() {
	if (("GameEventCallbacks" in getroottable()) && ("hd4l_no_incap" in ::GameEventCallbacks))
		return;
	__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
	::GameEventCallbacks["hd4l_no_incap"] <- true;
	InstallDamageHook();
}

NoIncap.Hook();

if (!("HD4L_Parts" in getroottable()))
	::HD4L_Parts <- {};
::HD4L_Parts["no_incap"] <- "0.1";
