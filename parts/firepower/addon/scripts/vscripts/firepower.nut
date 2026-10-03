::Firepower <- {
	Versus = true,
	Survival = true,
	Stock = true,

	RateMult = 1.2,
	ReloadMult = 1.25,
	ReloadAdrenaline = 1.6,
	ClipMult = 1.25,
	ReserveMult = 1.3,

	RateSkip = { melee = true, chainsaw = true, pipe_bomb = true, molotov = true, vomitjar = true, first_aid_kit = true, defibrillator = true, pain_pills = true, adrenaline = true, upgradepack_explosive = true, upgradepack_incendiary = true },

	ReserveConvars = [ "ammo_assaultrifle_max", "ammo_smg_max", "ammo_shotgun_max", "ammo_autoshotgun_max", "ammo_huntingrifle_max",
	                   "ammo_sniperrifle_max", "ammo_grenadelauncher_max", "ammo_m60_max" ],

	NoOverheat = true,
	HeatConvars = {
		z_minigun_overheat_time = 100000,
		z_minigun_cooldown_time = 0,
		mounted_gun_overheat_time = 100000,
		mounted_gun_cooldown_time = 0,
		mounted_gun_overheat_penalty_time = 0
	},
	MountedGuns = [ "prop_minigun", "prop_mounted_machine_gun" ],

	Interval = 0.1,
	Clips = {},
	ReservesSet = false,
	Generation = 0
}

function Firepower::Log(msg) {
	printl("[Firepower] " + msg);
}

function Firepower::ModeAllowed() {
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

function Firepower::Human(userid) {
	local p = null;
	try { p = GetPlayerFromUserID(userid); } catch (e) { return null; }
	if (p == null || !p.IsValid() || !p.IsSurvivor() || IsPlayerABot(p) || p.IsDead())
		return null;
	return p;
}

function Firepower::OnGameEvent_weapon_fire(params) {
	if (!ModeAllowed() || !("userid" in params))
		return;
	if (("weapon" in params) && (params.weapon in RateSkip))
		return;
	local p = Human(params.userid);
	if (p == null)
		return;
	local wep = p.GetActiveWeapon();
	if (wep == null || !wep.IsValid())
		return;
	local now = Time();
	local next = NetProps.GetPropFloat(wep, "m_flNextPrimaryAttack");
	if (next <= now)
		return;
	NetProps.SetPropFloat(wep, "m_flNextPrimaryAttack", now + (next - now) / RateMult);
}

function Firepower::OnGameEvent_weapon_reload(params) {
	if (!ModeAllowed() || !("userid" in params))
		return;
	local p = Human(params.userid);
	if (p == null)
		return;
	local wep = p.GetActiveWeapon();
	if (wep == null || !wep.IsValid())
		return;
	local factor = ReloadMult;
	try { if (p.IsAdrenalineActive()) factor = ReloadAdrenaline; } catch (e) {}
	local now = Time();
	local next = NetProps.GetPropFloat(wep, "m_flNextPrimaryAttack");
	if (next > now) {
		local done = now + (next - now) / factor;
		NetProps.SetPropFloat(wep, "m_flNextPrimaryAttack", done);
		NetProps.SetPropFloat(p, "m_flNextAttack", done);
	}
	NetProps.SetPropFloat(wep, "m_flPlaybackRate", factor);
}

function Firepower::Tick(generation) {
	if (generation != Generation)
		return;
	if (ModeAllowed()) {
		try { WatchClips(); } catch (e) { Log("clip watch failed: " + e); }
		if (NoOverheat)
			try { NoHeat(); } catch (e) { Log("heat reset failed: " + e); }
	}
	DoEntFire("!self", "RunScriptCode", "::Firepower.Tick(" + generation + ")", Interval, null, Entities.First());
}

function Firepower::WatchClips() {
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null) {
		if (!p.IsSurvivor() || IsPlayerABot(p) || p.IsDead())
			continue;
		local wep = p.GetActiveWeapon();
		if (wep == null || !wep.IsValid())
			continue;
		local max = 0;
		try { max = wep.GetMaxClip1(); } catch (e) { continue; }
		if (max <= 1)
			continue;
		local index = wep.GetEntityIndex();
		local clip = NetProps.GetPropInt(wep, "m_iClip1");
		local last = (index in Clips) ? Clips[index] : clip;
		Clips[index] <- clip;
		if (clip != max || last >= clip || NetProps.GetPropInt(wep, "m_bInReload") != 0)
			continue;
		local extra = (max * (ClipMult - 1.0) + 0.5).tointeger();
		local ammoType = NetProps.GetPropInt(wep, "m_iPrimaryAmmoType");
		if (ammoType >= 0) {
			local reserve = NetProps.GetPropIntArray(p, "m_iAmmo", ammoType);
			if (reserve < extra)
				extra = reserve;
			if (extra <= 0)
				continue;
			NetProps.SetPropIntArray(p, "m_iAmmo", reserve - extra, ammoType);
		}
		NetProps.SetPropInt(wep, "m_iClip1", clip + extra);
		Clips[index] <- clip + extra;
	}
}

function Firepower::NoHeat() {
	foreach (classname in MountedGuns) {
		local gun = null;
		while ((gun = Entities.FindByClassname(gun, classname)) != null) {
			if (!gun.IsValid())
				continue;
			try {
				if (NetProps.GetPropFloat(gun, "m_heat") > 0.0)
					NetProps.SetPropFloat(gun, "m_heat", 0.0);
			} catch (e) {}
		}
	}
}

function Firepower::SetHeatConvars() {
	if (!NoOverheat)
		return;
	foreach (name, value in HeatConvars)
		try { Convars.SetValue(name, value); } catch (e) { Log("no convar " + name); }
}

function Firepower::SetReserves() {
	if (ReservesSet)
		return;
	ReservesSet = true;
	foreach (name in ReserveConvars) {
		local value = 0.0;
		try { value = Convars.GetFloat(name); } catch (e) { continue; }
		if (value <= 0)
			continue;
		Convars.SetValue(name, (value * ReserveMult).tointeger());
	}
}

function Firepower::OnGameEvent_round_start(params) {
	Generation++;
	Clips = {};
	if (ModeAllowed()) {
		SetReserves();
		SetHeatConvars();
		Tick(Generation);
	}
}

function Firepower::Hook() {
	if (("GameEventCallbacks" in getroottable()) && ("hd4l_firepower" in ::GameEventCallbacks))
		return;
	__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
	::GameEventCallbacks["hd4l_firepower"] <- true;
}

Firepower.Hook();

if (!("HD4L_Parts" in getroottable()))
	::HD4L_Parts <- {};
::HD4L_Parts["firepower"] <- "0.1";
