const ARSENAL_IN_ATTACK = 1;
const ARSENAL_DMG_CLUB = 128;
const ARSENAL_DMG_BLAST = 64;
const ARSENAL_DMG_STAGGER = 33554432;
const ARSENAL_TEAM_INFECTED = 3;
const ARSENAL_ZOMBIE_TANK = 8;
const ARSENAL_DMG_BULLET = 2;
const ARSENAL_MASK_SHOT = 1174421515;

::Arsenal <- {
	Versus = true,
	Survival = true,
	Stock = true,

	M60Burst = true,
	M60Volleys = 4,
	M60Pause = 0.35,
	M60Reset = 0.3,

	M60Pellets = 7,
	M60PelletDamage = 20.0,
	M60StockDamage = 50.0,
	M60StockFalloff = 0.97,
	M60Falloff = 0.8,
	M60Range = 2500.0,
	M60ScatterPitch = 4.0,
	M60ScatterYaw = 6.0,
	M60Clip = 125,
	M60Impact = "impact_concrete_cheap",
	M60Blood = "blood_impact_red_01_cheap",
	InPellet = false,

	PistolAuto = true,
	PistolDamage = 0.7,
	Pistols = { weapon_pistol = true, weapon_pistol_magnum = true },

	DualFast = true,
	DualRate = 2.0,

	MeleeSwap = true,
	MeleeFrom = { pitchfork = true, shovel = true },
	MeleeTo = "fireaxe",
	MeleeModels = { ["models/weapons/melee/w_pitchfork.mdl"] = "pitchfork", ["models/weapons/melee/w_shovel.mdl"] = "shovel", ["models/weapons/melee/w_crowbar.mdl"] = "crowbar" },
	MeleePrecache = [ "models/weapons/melee/w_fireaxe.mdl", "models/weapons/melee/v_fireaxe.mdl" ],
	SwapInterval = 1.0,

	GoldRemove = true,

	Blunt = true,
	BluntCommonLaunch = 650.0,
	BluntCommonLift = 260.0,
	BluntSpecialPush = 420.0,
	BluntSpecialLift = 160.0,
	BluntTankPush = 120.0,
	BluntShake = 6.0,
	BluntSound = "player/tank/hit/hulk_punch_1.wav",
	BluntSoundGap = 0.12,

	CorpsePush = 2.5,

	TickInterval = 0.01,

	Shooters = {},
	Failed = {},
	AutoMode = "",
	LastSwap = 0.0,
	Generation = 0
}

function Arsenal::Log(msg) {
	printl("[Arsenal] " + msg);
}

function Arsenal::ModeAllowed() {
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

function Arsenal::Precache() {
	foreach (model in MeleePrecache)
		try { PrecacheModel(model); } catch (e) {}
	try { PrecacheSound(BluntSound); } catch (e) {}
}

function Arsenal::State(p) {
	local userid = p.GetPlayerUserId();
	if (!(userid in Shooters))
		Shooters[userid] <- { volleys = 0, lastM60 = -100.0, released = false, lastThud = -100.0 };
	return Shooters[userid];
}

function Arsenal::Survivor(userid) {
	local p = null;
	try { p = GetPlayerFromUserID(userid); } catch (e) { return null; }
	if (p == null || !p.IsValid() || !p.IsSurvivor() || p.IsDead())
		return null;
	return p;
}

function Arsenal::Hold(wep, seconds) {
	local until = Time() + seconds;
	if (NetProps.GetPropFloat(wep, "m_flNextPrimaryAttack") < until)
		NetProps.SetPropFloat(wep, "m_flNextPrimaryAttack", until);
}

function Arsenal::M60Fired(p, st, now) {
	if (now - st.lastM60 > M60Reset)
		st.volleys = 0;
	st.lastM60 = now;
	st.volleys++;
	if (st.volleys < M60Volleys)
		return;
	st.volleys = 0;
	local wep = p.GetActiveWeapon();
	if (wep != null && wep.IsValid())
		Hold(wep, M60Pause);
}

function Arsenal::Buttons(p, name, set, bits) {
	local cur = NetProps.GetPropInt(p, name);
	local want = set ? (cur | bits) : (cur & ~bits);
	if (want != cur)
		NetProps.SetPropInt(p, name, want);
}

function Arsenal::Dual(wep) {
	local dual = 0;
	try { dual = NetProps.GetPropInt(wep, "m_isDualWielding"); } catch (e) {}
	return dual > 0;
}

function Arsenal::DualFired(wep, now) {
	local next = NetProps.GetPropFloat(wep, "m_flNextPrimaryAttack");
	if (next > now)
		NetProps.SetPropFloat(wep, "m_flNextPrimaryAttack", now + (next - now) / DualRate);
}

function Arsenal::PistolFired(p, st, now) {
	local wep = p.GetActiveWeapon();
	if (DualFast && wep != null && wep.IsValid() && Dual(wep))
		DualFired(wep, now);
}

function Arsenal::AutoStep(p, st, now) {
	local wep = p.GetActiveWeapon();
	if (wep == null || !wep.IsValid() || !(wep.GetClassname() in Pistols)) {
		if (st.released) {
			Buttons(p, "m_afButtonDisabled", false, ARSENAL_IN_ATTACK);
			st.released = false;
		}
		return;
	}
	if (AutoMode == "")
		PickAuto(wep);
	if (AutoMode == "prop") {
		if (NetProps.GetPropInt(p, "m_nButtons") & ARSENAL_IN_ATTACK)
			NetProps.SetPropInt(wep, "m_isHoldingFireButton", 0);
		return;
	}
	if (st.released) {
		Buttons(p, "m_afButtonDisabled", false, ARSENAL_IN_ATTACK);
		st.released = false;
		return;
	}
	if (!(NetProps.GetPropInt(p, "m_nButtons") & ARSENAL_IN_ATTACK))
		return;
	if (NetProps.GetPropFloat(wep, "m_flNextPrimaryAttack") > now || NetProps.GetPropInt(wep, "m_iClip1") <= 0 || NetProps.GetPropInt(wep, "m_bInReload") != 0)
		return;
	Buttons(p, "m_afButtonDisabled", true, ARSENAL_IN_ATTACK);
	st.released = true;
}

function Arsenal::Falloff(modifier, dist) {
	return pow(modifier, dist / 500.0);
}

function Arsenal::PelletFx(effect, pos) {
	local fx = SpawnEntityFromTable("info_particle_system", { origin = pos, effect_name = effect, start_active = 1 });
	if (fx != null)
		DoEntFire("!self", "Kill", "", 1.0, null, fx);
}

function Arsenal::M60Scatter(p) {
	local eye = p.EyePosition();
	local ang = p.EyeAngles();
	for (local i = 1; i < M60Pellets; i++) {
		local a = QAngle(ang.x + RandomFloat(-M60ScatterPitch, M60ScatterPitch), ang.y + RandomFloat(-M60ScatterYaw, M60ScatterYaw), 0);
		local tr = { start = eye, end = eye + a.Forward() * M60Range, ignore = p, mask = ARSENAL_MASK_SHOT };
		TraceLine(tr);
		if (("Projectiles" in getroottable()) && ("AddRay" in ::Projectiles)) {
			local flown = false;
			try { flown = ::Projectiles.AddRay(p, ("pos" in tr) ? tr.pos : tr.end, M60PelletDamage, M60Falloff); } catch (e) {}
			if (flown)
				continue;
		}
		if (!("hit" in tr) || !tr.hit || !("pos" in tr))
			continue;
		local ent = ("enthit" in tr) ? tr.enthit : null;
		local cls = (ent != null && ent.IsValid()) ? ent.GetClassname() : "worldspawn";
		local flesh = cls == "infected" || cls == "witch"
			|| (cls == "player" && NetProps.GetPropInt(ent, "m_iTeamNum") == ARSENAL_TEAM_INFECTED && !ent.IsGhost());
		if (cls == "player" && !flesh)
			continue;
		if (flesh) {
			local damage = M60PelletDamage * Falloff(M60Falloff, (tr.pos - eye).Length());
			InPellet = true;
			try { ent.TakeDamage(damage, ARSENAL_DMG_BULLET, p); } catch (e) {}
			InPellet = false;
			PelletFx(M60Blood, tr.pos);
		} else
			PelletFx(M60Impact, tr.pos);
	}
}

function Arsenal::M60ClipCap(p) {
	local inv = {};
	try { GetInvTable(p, inv); } catch (e) { return; }
	if (!("slot0" in inv) || inv.slot0 == null || !inv.slot0.IsValid() || inv.slot0.GetClassname() != "weapon_rifle_m60")
		return;
	local wep = inv.slot0;
	if (NetProps.GetPropInt(wep, "m_bInReload") != 0)
		return;
	local clip = NetProps.GetPropInt(wep, "m_iClip1");
	if (clip <= M60Clip)
		return;
	local type = NetProps.GetPropInt(wep, "m_iPrimaryAmmoType");
	if (type >= 0)
		NetProps.SetPropIntArray(p, "m_iAmmo", NetProps.GetPropIntArray(p, "m_iAmmo", type) + clip - M60Clip, type);
	NetProps.SetPropInt(wep, "m_iClip1", M60Clip);
}

function Arsenal::OnGameEvent_weapon_fire(params) {
	if (!ModeAllowed() || !("userid" in params) || !("weapon" in params))
		return;
	local weapon = params.weapon;
	if (weapon != "rifle_m60" && weapon != "pistol")
		return;
	local p = Survivor(params.userid);
	if (p == null)
		return;
	local st = State(p);
	local now = Time();
	try {
		if (weapon == "rifle_m60") {
			if (M60Burst)
				M60Fired(p, st, now);
			if (M60Pellets > 1)
				M60Scatter(p);
		} else if (weapon == "pistol")
			PistolFired(p, st, now);
	} catch (e) { Log("fire failed: " + e); }
}

function Arsenal::MeleeName(ent) {
	local name = "";
	try { name = NetProps.GetPropString(ent, "m_strMapSetScriptName"); } catch (e) {}
	if (name != "")
		return name.tolower();
	local model = "";
	try { model = ent.GetModelName().tolower(); } catch (e) {}
	return (model in MeleeModels) ? MeleeModels[model] : "";
}

function Arsenal::SwapSpawn(ent) {
	local origin = ent.GetOrigin();
	local angles = ent.GetAngles();
	local fresh = SpawnEntityFromTable("weapon_melee_spawn", {
		melee_weapon = MeleeTo,
		origin = origin,
		angles = angles.x + " " + angles.y + " " + angles.z,
		spawnflags = NetProps.GetPropInt(ent, "m_spawnflags"),
		count = 1
	});
	if (fresh == null || !fresh.IsValid() || fresh.GetModelName().tolower().find(MeleeTo) == null) {
		if (fresh != null && fresh.IsValid())
			fresh.Kill();
		return false;
	}
	ent.Kill();
	return true;
}

function Arsenal::SwapWorld() {
	local swapped = 0;
	local failed = 0;
	foreach (classname in [ "weapon_melee_spawn", "weapon_melee" ]) {
		local ent = null;
		local found = [];
		while ((ent = Entities.FindByClassname(ent, classname)) != null) {
			if (!ent.IsValid() || (ent.GetEntityIndex() in Failed) || !(MeleeName(ent) in MeleeFrom))
				continue;
			local owner = null;
			try { owner = NetProps.GetPropEntity(ent, "m_hOwner"); } catch (e) {}
			if (owner == null)
				found.append(ent);
		}
		foreach (e in found) {
			if (SwapSpawn(e))
				swapped++;
			else {
				Failed[e.GetEntityIndex()] <- true;
				failed++;
			}
		}
	}
}

function Arsenal::Golden(ent) {
	return MeleeName(ent) == "crowbar" && NetProps.GetPropInt(ent, "m_nSkin") != 0;
}

function Arsenal::RemoveGold() {
	local found = [];
	foreach (classname in [ "weapon_melee_spawn", "weapon_melee" ]) {
		local ent = null;
		while ((ent = Entities.FindByClassname(ent, classname)) != null) {
			if (!ent.IsValid() || !Golden(ent))
				continue;
			local owner = null;
			try { owner = NetProps.GetPropEntity(ent, "m_hOwner"); } catch (e) {}
			if (owner == null)
				found.append(ent);
		}
	}
	foreach (e in found)
		e.Kill();
}

function Arsenal::DegildHeld(p) {
	local inv = {};
	try { GetInvTable(p, inv); } catch (e) { return; }
	local wep = ("slot1" in inv) ? inv.slot1 : null;
	if (wep == null || !wep.IsValid() || wep.GetClassname() != "weapon_melee" || !Golden(wep))
		return;
	NetProps.SetPropInt(wep, "m_nSkin", 0);
	local vm = null;
	try { vm = NetProps.GetPropEntity(p, "m_hViewModel"); } catch (e) {}
	if (vm != null && vm.IsValid())
		NetProps.SetPropInt(vm, "m_nSkin", 0);
}

function Arsenal::SwapHeld(p) {
	local inv = {};
	try { GetInvTable(p, inv); } catch (e) { return; }
	local wep = ("slot1" in inv) ? inv.slot1 : null;
	if (wep == null || !wep.IsValid() || wep.GetClassname() != "weapon_melee" || !(MeleeName(wep) in MeleeFrom))
		return;
	wep.Kill();
	p.GiveItem(MeleeTo);
}

function Arsenal::OnGameEvent_item_pickup(params) {
	if (!ModeAllowed() || !("userid" in params))
		return;
	local p = Survivor(params.userid);
	if (p == null)
		return;
	if (GoldRemove)
		try { DegildHeld(p); } catch (e) { Log("held gold failed: " + e); }
	if (MeleeSwap)
		try { SwapHeld(p); } catch (e) { Log("held swap failed: " + e); }
}

function Arsenal::Tick(generation) {
	if (generation != Generation)
		return;
	if (ModeAllowed()) {
		local now = Time();
		try {
			local p = null;
			while ((p = Entities.FindByClassname(p, "player")) != null) {
				if (!p.IsSurvivor() || p.IsDead())
					continue;
				if (M60Pellets > 1)
					M60ClipCap(p);
				if (PistolAuto && !IsPlayerABot(p))
					AutoStep(p, State(p), now);
			}
			if (now - LastSwap >= SwapInterval) {
				LastSwap = now;
				if (GoldRemove)
					RemoveGold();
				if (MeleeSwap)
					SwapWorld();
			}
		} catch (e) { Log("tick failed: " + e); }
	}
	DoEntFire("!self", "RunScriptCode", "::Arsenal.Tick(" + generation + ")", TickInterval, null, Entities.First());
}

function Arsenal::CheckAuto() {
	AutoMode = "";
}

function Arsenal::PickAuto(wep) {
	local prop = false;
	try { prop = NetProps.HasProp(wep, "m_isHoldingFireButton"); } catch (e) {}
	AutoMode = prop ? "prop" : "toggle";
}

function Arsenal::SetCorpses() {
	if (CorpsePush <= 0.0)
		return;
	try { Convars.SetValue("phys_pushscale", CorpsePush); } catch (e) { Log("no phys_pushscale: " + e); return; }
}

function Arsenal::Loud(sound, ent, level, pitch = 100) {
	if (("HD4L" in getroottable()) && ("Loud" in ::HD4L))
		try { ::HD4L.Loud(sound, ent, level, pitch); return; } catch (e) {}
	EmitSoundOn(sound, ent);
}

function Arsenal::ScaleDamage(damageTable) {
	if (!ModeAllowed() || !("Attacker" in damageTable) || !("DamageDone" in damageTable))
		return;
	local p = damageTable.Attacker;
	if (p == null || !p.IsValid() || p.GetClassname() != "player" || !p.IsSurvivor())
		return;
	if (("DamageType" in damageTable) && !(damageTable.DamageType & ARSENAL_DMG_BULLET))
		return;
	local wep = ("Weapon" in damageTable) ? damageTable.Weapon : null;
	if (wep == null || !wep.IsValid())
		wep = p.GetActiveWeapon();
	if (wep == null || !wep.IsValid())
		return;
	local cls = wep.GetClassname();
	if (cls == "weapon_rifle_m60" && M60Pellets > 1 && !InPellet) {
		local dist = 0.0;
		if ("Victim" in damageTable && damageTable.Victim != null && damageTable.Victim.IsValid())
			dist = (damageTable.Victim.GetOrigin() - p.GetOrigin()).Length();
		damageTable.DamageDone = damageTable.DamageDone * (M60PelletDamage / M60StockDamage)
			* Falloff(M60Falloff, dist) / Falloff(M60StockFalloff, dist);
		return;
	}
	if (PistolDamage != 1.0 && cls == "weapon_pistol")
		damageTable.DamageDone = damageTable.DamageDone * PistolDamage;
}

function Arsenal::MeleeHit(damageTable) {
	if (!Blunt || !ModeAllowed() || !("Victim" in damageTable) || !("Attacker" in damageTable) || !("DamageType" in damageTable))
		return;
	local type = damageTable.DamageType;
	if (!(type & ARSENAL_DMG_CLUB) || (type & (ARSENAL_DMG_BLAST | ARSENAL_DMG_STAGGER)))
		return;
	local p = damageTable.Attacker;
	local victim = damageTable.Victim;
	if (p == null || victim == null || !p.IsValid() || !victim.IsValid() || p.GetClassname() != "player" || !p.IsSurvivor())
		return;
	local melee = false;
	foreach (key in [ "Weapon", "Inflictor" ]) {
		if (!(key in damageTable))
			continue;
		local ent = damageTable[key];
		if (ent != null && ent.IsValid() && ent.GetClassname() == "weapon_melee")
			melee = true;
	}
	if (!melee) {
		local held = p.GetActiveWeapon();
		if (held == null || !held.IsValid() || held.GetClassname() != "weapon_melee")
			return;
		if (("Momentum" in getroottable()) && ("StateOf" in ::Momentum)) {
			local s = null;
			try { s = ::Momentum.StateOf(p); } catch (e) {}
			if (s != null && (s.kick || s.move != "" || s.dive != ""))
				return;
		}
	}

	local away = victim.GetOrigin() - p.GetOrigin();
	away.z = 0.0;
	if (away.Length() < 1.0)
		away = p.EyeAngles().Forward();
	away.z = 0.0;
	away.Norm();
	local cls = victim.GetClassname();
	if (cls == "infected")
		victim.ApplyAbsVelocityImpulse(away * BluntCommonLaunch + Vector(0, 0, BluntCommonLift));
	else if (cls == "player" && NetProps.GetPropInt(victim, "m_iTeamNum") == ARSENAL_TEAM_INFECTED && !victim.IsGhost()) {
		if (victim.GetZombieType() == ARSENAL_ZOMBIE_TANK)
			victim.ApplyAbsVelocityImpulse(away * BluntTankPush);
		else {
			try { victim.Stagger(p.GetOrigin()); } catch (e) {}
			victim.ApplyAbsVelocityImpulse(away * BluntSpecialPush + Vector(0, 0, BluntSpecialLift));
		}
	} else
		return;

	local st = State(p);
	local now = Time();
	if (now - st.lastThud < BluntSoundGap)
		return;
	st.lastThud = now;
	Loud(BluntSound, p, 95, RandomInt(80, 95));
	ScreenShake(victim.GetOrigin(), BluntShake, 30.0, 0.25, 120.0, 0, false);
}

function Arsenal::OnGameEvent_round_start(params) {
	Shooters = {};
	Failed = {};
	LastSwap = 0.0;
	Generation++;
	CheckAuto();
	if (ModeAllowed())
		SetCorpses();
	Tick(Generation);
}

function Arsenal::Hook() {
	if (("GameEventCallbacks" in getroottable()) && ("hd4l_arsenal" in ::GameEventCallbacks))
		return;
	__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
	::GameEventCallbacks["hd4l_arsenal"] <- true;
}

Arsenal.Precache();
Arsenal.Hook();

if (!("HD4L_Parts" in getroottable()))
	::HD4L_Parts <- {};
::HD4L_Parts["arsenal"] <- "0.1";
