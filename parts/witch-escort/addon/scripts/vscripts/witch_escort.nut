const ZOMBIE_COMMON = 0;
const DMG_BULLET = 2;
const TWO_PI = 6.28318;

::WitchEscort <- {
	Versus = true,
	Survival = true,
	Stock = false,

	GuardsMin = 3,
	GuardsMax = 5,
	RadiusMin = 80.0,
	RadiusMax = 220.0,

	Tries = 6,

	Delay = 0.5,

	MaxHit = 350,
	WitchHealth = 1500,

	Temper = {
		z_witch_anger_rate = 0.4,
		z_witch_relax_rate = 2.0,
		z_witch_personal_space = 0.45,
		z_witch_threat_normal_range = 0.5,
		z_witch_threat_hostile_range = 0.6,
		z_witch_flashlight_range = 0.4,
		z_witch_hostile_at_me_anger = 0.5,
		z_witch_wander_personal_space = 0.45,
		z_witch_wander_hear_radius = 0.4
	},

	Defaults = null,

	DieAfterKill = true,

	IncludeBots = true,

	KillWindow = 3.0,

	DieDelay = 0.25,

	Installed = {},
	Previous = {},
	InHook = false,

	Struck = {},

	Eyes = true,
	CalmEyes = "hd4l_eyes_red",
	RageEyes = "hd4l_eyes_rage",
	RageSound = "npc/witch/voice/attack/female_shriek_1.wav",
	RagePitch = 70,
	Fx = {},

	Spent = {}
}

function WitchEscort::DamageHook(scopeName, damageTable) {
	local allow = true;
	if (!InHook && (scopeName in Previous) && Previous[scopeName] != null) {
		InHook = true;
		try { allow = Previous[scopeName].call(getroottable()[scopeName], damageTable); } catch (e) { Log("previous " + scopeName + " damage hook failed: " + e); }
		InHook = false;
	}
	if (InHook || allow == false || !ModeAllowed() || !("Victim" in damageTable) || !("DamageDone" in damageTable))
		return allow;
	local victim = damageTable.Victim;
	if (victim == null || !victim.IsValid())
		return allow;
	if (victim.GetClassname() != "witch") {
		NoteWitchHit(victim, damageTable);
		return allow;
	}
	if (victim.GetEntityIndex() in Spent)
		return allow;
	if (damageTable.DamageDone > MaxHit) {
		damageTable.DamageDone = MaxHit;
	}
	return allow;
}

function WitchEscort::NoteWitchHit(victim, damageTable) {
	if (!DieAfterKill || victim.GetClassname() != "player" || !victim.IsSurvivor())
		return;
	if (!("Attacker" in damageTable))
		return;
	local attacker = damageTable.Attacker;
	if (attacker == null || !attacker.IsValid() || attacker.GetClassname() != "witch")
		return;
	Struck[victim.GetPlayerUserId()] <- { ent = attacker, at = Time() };
}

function WitchEscort::OnGameEvent_player_death(params) {
	if (!DieAfterKill || !ModeAllowed() || !("userid" in params))
		return;
	local victim = null;
	try { victim = GetPlayerFromUserID(params.userid); } catch (e) { return; }
	if (victim == null || !victim.IsValid() || victim.GetClassname() != "player" || !victim.IsSurvivor())
		return;
	if (!IncludeBots && IsPlayerABot(victim))
		return;

	local witch = Killer(params, victim);
	if (witch == null)
		return;
	local index = witch.GetEntityIndex();
	if (index in Spent)
		return;
	Spent[index] <- true;
	DoEntFire("!self", "RunScriptCode", "::WitchEscort.WitchDie(" + index + ")", DieDelay, null, Entities.First());
}

function WitchEscort::Killer(params, victim) {
	if ("attackerentid" in params) {
		local ent = null;
		try { ent = EntIndexToHScript(params.attackerentid); } catch (e) { ent = null; }
		if (ent != null && ent.IsValid() && ent.GetClassname() == "witch")
			return ent;
	}
	local id = victim.GetPlayerUserId();
	if (!(id in Struck))
		return null;
	local hit = Struck[id];
	if (Time() - hit.at > KillWindow) {
		delete Struck[id];
		return null;
	}
	if (hit.ent == null || !hit.ent.IsValid() || hit.ent.GetClassname() != "witch")
		return null;
	return hit.ent;
}

function WitchEscort::WitchDie(index) {
	local witch = null;
	try { witch = EntIndexToHScript(index); } catch (e) { witch = null; }
	if (witch == null || !witch.IsValid() || witch.GetClassname() != "witch") {
		if (index in Spent)
			delete Spent[index];
		return;
	}
	local health = witch.GetHealth();
	if (health > 0)
		witch.TakeDamage(health + 1000, DMG_BULLET, Entities.First());
	if (index in Spent)
		delete Spent[index];
}

function WitchEscort::SetWitchCvars() {
	if (!ModeAllowed())
		return;
	Convars.SetValue("z_witch_damage_per_kill_hit", MaxHit);
	Convars.SetValue("z_witch_health", WitchHealth);
	SetTemper();
}

function WitchEscort::SetTemper() {
	if (Temper == null)
		return;
	if (Defaults == null) {
		Defaults = {};
		foreach (name, factor in Temper) {
			local value = null;
			try { value = Convars.GetFloat(name); } catch (e) { value = null; }
			if (value == null) {
				Log("no convar " + name + ", skipped");
				continue;
			}
			Defaults[name] <- value;
		}
	}
	foreach (name, vanilla in Defaults)
		Convars.SetValue(name, vanilla * Temper[name]);
}

function WitchEscort::OnGameEvent_round_start(params) {
	Struck = {};
	Spent = {};
	Fx = {};
	try { PrecacheSound(RageSound); } catch (e) {}
	SetWitchCvars();
}

function WitchEscort::InstallDamageHook() {
	local root = getroottable();
	foreach (scopeName in [ "g_ModeScript", "g_MapScript" ]) {
		if (!(scopeName in root) || typeof root[scopeName] != "table")
			continue;
		local scope = root[scopeName];
		if (("AllowTakeDamage" in scope) && (scopeName in Installed) && scope.AllowTakeDamage == Installed[scopeName])
			continue;
		Previous[scopeName] <- ("AllowTakeDamage" in scope) ? scope.AllowTakeDamage : null;
		local name = scopeName;
		Installed[scopeName] <- function(damageTable) { return ::WitchEscort.DamageHook(name, damageTable); };
		scope.AllowTakeDamage <- Installed[scopeName];
	}
}

function WitchEscort::Log(msg) {
	printl("[WitchEscort] " + msg);
}

function WitchEscort::ModeAllowed() {
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

function WitchEscort::HasFx() {
	return ("HD4L" in getroottable()) && ("Eyes" in ::HD4L);
}

function WitchEscort::SetEyes(index, look) {
	if (!Eyes || !HasFx())
		return;
	local witch = EntIndexToHScript(index);
	if (witch == null || !witch.IsValid() || witch.GetClassname() != "witch")
		return;
	if (index in Fx)
		::HD4L.Unfx(Fx[index]);
	Fx[index] <- ::HD4L.Eyes(witch, look, 48.0);
}

function WitchEscort::OnGameEvent_witch_harasser_set(params) {
	if (!ModeAllowed() || !("witchid" in params))
		return;
	try { SetEyes(params.witchid, RageEyes); } catch (e) { Log("rage eyes failed: " + e); }
	local witch = EntIndexToHScript(params.witchid);
	if (witch != null && witch.IsValid() && HasFx())
		try { ::HD4L.Loud(RageSound, witch, 110, RagePitch); } catch (e) {}
}

function WitchEscort::OnGameEvent_witch_killed(params) {
	if (!("witchid" in params) || !(params.witchid in Fx))
		return;
	if (HasFx())
		::HD4L.Unfx(Fx[params.witchid], 0.4);
	delete Fx[params.witchid];
}

function WitchEscort::OnGameEvent_witch_spawn(params) {
	if (!ModeAllowed() || !("witchid" in params))
		return;
	DoEntFire("!self", "RunScriptCode", "::WitchEscort.SetEyes(" + params.witchid + ", ::WitchEscort.CalmEyes)", 0.2, null, Entities.First());
	DoEntFire("!self", "RunScriptCode", "::WitchEscort.Place(" + params.witchid + ")", Delay, null, Entities.First());
}

function WitchEscort::Place(index) {
	local witch = EntIndexToHScript(index);
	if (witch == null || !witch.IsValid())
		return;
	local centre = witch.GetOrigin();
	local wanted = RandomInt(GuardsMin, GuardsMax);
	local placed = 0;
	for (local i = 0; i < wanted; i++) {
		for (local attempt = 0; attempt < Tries; attempt++) {
			local angle = RandomFloat(0.0, TWO_PI);
			local radius = RandomFloat(RadiusMin, RadiusMax);
			local spot = Ground(centre + Vector(cos(angle) * radius, sin(angle) * radius, 0), witch);
			if (spot == null)
				continue;
			local guard = ZSpawn({ type = ZOMBIE_COMMON, pos = spot, ang = QAngle(0, RandomInt(0, 359), 0) });
			if (guard != null) {
				placed++;
				break;
			}
		}
	}
}

function WitchEscort::Ground(pos, ignore) {
	local trace = { start = Vector(pos.x, pos.y, pos.z + 60.0), end = Vector(pos.x, pos.y, pos.z - 120.0), ignore = ignore };
	TraceLine(trace);
	if (!trace.hit || ("startsolid" in trace && trace.startsolid))
		return null;
	return trace.pos;
}

function WitchEscort::Hook() {
	if (("GameEventCallbacks" in getroottable()) && ("hd4l_witch_escort" in ::GameEventCallbacks))
		return;
	__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
	::GameEventCallbacks["hd4l_witch_escort"] <- true;
	InstallDamageHook();
	SetWitchCvars();
}

WitchEscort.Hook();

if (!("HD4L_Parts" in getroottable()))
	::HD4L_Parts <- {};
::HD4L_Parts["witch_escort"] <- "0.1";
