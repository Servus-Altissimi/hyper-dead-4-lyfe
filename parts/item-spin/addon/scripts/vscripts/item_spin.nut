const ITEMSPIN_TWO_PI = 6.28318;
const ITEMSPIN_MOVETYPE_NONE = 0;

::ItemSpin <- {
	Versus = true,
	Survival = true,
	Stock = false,

	Spin = 110.0,
	Lift = 14.0,
	BobHeight = 3.5,
	BobPeriod = 2.2,

	Tilt = 12.0,

	Range = 1400.0,
	MaxActive = 48,

	MinLift = 4.0,

	Pop = true,
	PopEffect = "",
	PopSound = "physics/metal/metal_solid_impact_bullet1.wav",

	Match = "_spawn",
	Classnames =
	[
		"weapon_pistol_spawn", "weapon_pistol_magnum_spawn", "weapon_smg_spawn", "weapon_smg_silenced_spawn",
		"weapon_smg_mp5_spawn", "weapon_pumpshotgun_spawn", "weapon_shotgun_chrome_spawn", "weapon_autoshotgun_spawn",
		"weapon_shotgun_spas_spawn", "weapon_rifle_spawn", "weapon_rifle_ak47_spawn", "weapon_rifle_desert_spawn",
		"weapon_rifle_sg552_spawn", "weapon_rifle_m60_spawn", "weapon_hunting_rifle_spawn",
		"weapon_sniper_military_spawn", "weapon_sniper_scout_spawn", "weapon_sniper_awp_spawn",
		"weapon_grenade_launcher_spawn", "weapon_chainsaw_spawn", "weapon_melee_spawn",
		"weapon_first_aid_kit_spawn", "weapon_defibrillator_spawn", "weapon_pain_pills_spawn",
		"weapon_adrenaline_spawn", "weapon_molotov_spawn", "weapon_pipe_bomb_spawn", "weapon_vomitjar_spawn",
		"weapon_upgradepack_explosive_spawn", "weapon_upgradepack_incendiary_spawn",
		"weapon_item_spawn", "upgrade_spawn", "upgrade_laser_sight"
	],
	Extra = { upgrade_laser_sight = true },

	LooseClassnames =
	[
		"weapon_adrenaline", "weapon_pain_pills", "weapon_first_aid_kit", "weapon_defibrillator",
		"weapon_molotov", "weapon_pipe_bomb", "weapon_vomitjar",
		"weapon_upgradepack_explosive", "weapon_upgradepack_incendiary", "weapon_melee", "weapon_chainsaw"
	],

	Skip = {
		weapon_ammo_spawn = true, weapon_ammo_pack_spawn = true, weapon_gascan_spawn = true,
		weapon_propanetank_spawn = true, weapon_oxygentank_spawn = true, weapon_cola_bottles_spawn = true,
		weapon_fireworkcrate_spawn = true, weapon_gnome_spawn = true, weapon_scavenge_item_spawn = true,
		weapon_gascan = true, weapon_propanetank = true, weapon_oxygentank = true, weapon_fireworkcrate = true,
		weapon_gnome = true, weapon_cola_bottles = true, weapon_ammo_pack = true
	},

	Loose = true,

	MoveInterval = 0.01,

	SelectInterval = 0.25,
	ScanInterval = 1.0,
	Items = {},
	Owned = {},
	Active = [],
	LastScan = 0.0,
	LastSelect = -100.0,
	Generation = 0
}

function ItemSpin::Log(msg) {
	printl("[ItemSpin] " + msg);
}

function ItemSpin::ModeAllowed() {
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

function ItemSpin::Precache() {
	if (PopSound != "")
		PrecacheSound(PopSound);
	if (PopEffect != "")
		PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = PopEffect, origin = Vector(0, 0, 0), start_active = 1 });
}

function ItemSpin::Survivors() {
	local list = [];
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null)
		if (p.IsSurvivor() && !p.IsDead())
			list.append(p);
	return list;
}

function ItemSpin::Owner(ent) {
	local owner = null;
	try { owner = NetProps.GetPropEntity(ent, "m_hOwner"); } catch (e) {}
	return owner;
}

function ItemSpin::Spawner(classname) {
	return classname.len() > Match.len() && classname.slice(classname.len() - Match.len()) == Match;
}

function ItemSpin::Loose(ent) {
	local index = ent.GetEntityIndex();
	if ((index in Owned) && Owned[index] == ent)
		return false;
	if (Owner(ent) != null) {
		Owned[index] <- ent;
		return false;
	}
	return true;
}

function ItemSpin::Wanted(ent) {
	local classname = ent.GetClassname();
	if (classname in Skip)
		return false;
	if (classname in Extra)
		return true;
	if (classname.slice(0, 7) != "weapon_" && classname.slice(0, 8) != "upgrade_")
		return false;
	if (Spawner(classname))
		return true;
	return Loose && classname.slice(0, 7) == "weapon_" && Loose(ent);
}

function ItemSpin::Headroom(ent, rest) {
	local from = rest + Vector(0, 0, 2.0);
	local reach = Lift + 6.0;
	local trace = { start = from, end = from + Vector(0, 0, reach), ignore = ent };
	try { TraceLine(trace); } catch (e) { return MinLift; }
	if (!("fraction" in trace) || !trace.hit)
		return Lift;
	if (("startsolid" in trace) && trace.startsolid)
		return MinLift;
	local room = reach * trace.fraction - 4.0;
	if (room < MinLift)
		return MinLift;
	return room > Lift ? Lift : room;
}

function ItemSpin::Scan(now) {
	local seen = {};
	local ent = null;

	local names = clone Classnames;
	if (Loose)
		names.extend(LooseClassnames);
	foreach (classname in names) {
		if (classname in Skip)
			continue;
		ent = null;
		while ((ent = Entities.FindByClassname(ent, classname)) != null) {
			if (!ent.IsValid() || !Wanted(ent))
				continue;
			seen[ent.GetEntityIndex()] <- true;
			Learn(ent);
		}
	}

	ent = null;
	while ((ent = Entities.FindByClassname(ent, "weapon_*")) != null) {
		if (!ent.IsValid() || !Wanted(ent))
			continue;
		seen[ent.GetEntityIndex()] <- true;
		Learn(ent);
	}
	foreach (index, item in clone Items) {
		if ((index in seen) && item.ent.IsValid() && !(item.plain && Owner(item.ent) != null))
			continue;
		if (item.plain && item.ent.IsValid()) {
			Owned[index] <- item.ent;
			item.active = false;
		}

		if (Pop && item.active)
			Burst(item.rest + Vector(0, 0, item.lift));
		delete Items[index];
	}
}

function ItemSpin::Learn(ent) {
	local index = ent.GetEntityIndex();
	if (index in Items)
		return;
	try { if (ent.GetMoveParent() != null) return; } catch (e) {}
	local rest = ent.GetOrigin();
	local lift = Headroom(ent, rest);
	if (lift < MinLift)
		return;

	Items[index] <- { ent = ent, rest = rest, lift = lift, phase = (index % 16) / 16.0, active = false, movetype = null,
	                  plain = !Spawner(ent.GetClassname()) };
}

function ItemSpin::Burst(pos) {
	if (PopEffect != "") {
		local gfx = SpawnEntityFromTable("info_particle_system", { effect_name = PopEffect, origin = pos, start_active = 1 });
		if (gfx != null)
			DoEntFire("!self", "Kill", "", 2.0, null, gfx);
	}
	if (PopSound == "")
		return;
	local speaker = SpawnEntityFromTable("info_target", { origin = pos });
	if (speaker != null) {
		try { EmitSoundOn(PopSound, speaker); } catch (e) {}
		DoEntFire("!self", "Kill", "", 2.0, null, speaker);
	}
}

function ItemSpin::Rest(item) {
	if (!item.active)
		return;
	item.active = false;
	if (item.ent == null || !item.ent.IsValid())
		return;
	try { item.ent.SetOrigin(item.rest); } catch (e) {}
	try { item.ent.SetAngles(QAngle(0, 0, 0)); } catch (e) {}
	if (item.movetype != null) {
		try { NetProps.SetPropInt(item.ent, "m_MoveType", item.movetype); } catch (e) {}
		item.movetype = null;
	}
}

function ItemSpin::Tick(generation) {
	if (generation != Generation)
		return;
	if (ModeAllowed()) {
		local now = Time();
		try {
			if (now - LastScan >= ScanInterval) {
				LastScan = now;
				Scan(now);
			}
			if (now - LastSelect >= SelectInterval) {
				LastSelect = now;
				Select(now);
			}
			Drive(now);
		} catch (e) { Log("tick failed: " + e); }
	}
	DoEntFire("!self", "RunScriptCode", "::ItemSpin.Tick(" + generation + ")", MoveInterval, null, Entities.First());
}

function ItemSpin::Select(now) {
	local survivors = Survivors();

	local near = [];
	foreach (index, item in Items) {
		if (item.ent == null || !item.ent.IsValid())
			continue;
		local best = 999999.0;
		foreach (s in survivors) {
			local d = (s.GetOrigin() - item.rest).Length();
			if (d < best)
				best = d;
		}
		if (best <= Range)
			near.append({ item = item, dist = best });
		else
			Rest(item);
	}
	near.sort(function (a, b) { return a.dist <=> b.dist; });

	Active = [];
	foreach (entry in near) {
		if (Active.len() >= MaxActive) {
			Rest(entry.item);
			continue;
		}
		local item = entry.item;
		if (!item.active) {
			item.active = true;

			try {
				item.movetype = NetProps.GetPropInt(item.ent, "m_MoveType");
				NetProps.SetPropInt(item.ent, "m_MoveType", ITEMSPIN_MOVETYPE_NONE);
			} catch (e) { item.movetype = null; }
		}
		Active.append(item);
	}
}

function ItemSpin::Drive(now) {
	foreach (item in Active) {
		if (item.ent == null || !item.ent.IsValid() || !item.active)
			continue;
		if (item.plain && Owner(item.ent) != null) {
			item.active = false;
			item.movetype = null;
			local index = item.ent.GetEntityIndex();
			Owned[index] <- item.ent;
			if (index in Items)
				delete Items[index];
			if (Pop)
				Burst(item.rest + Vector(0, 0, item.lift));
			continue;
		}
		local t = now + item.phase * BobPeriod;
		local yaw = (now * Spin + item.phase * 360.0) % 360.0;
		local z = item.lift + sin(t * ITEMSPIN_TWO_PI / BobPeriod) * BobHeight;
		try {
			item.ent.SetOrigin(item.rest + Vector(0, 0, z));
			item.ent.SetAngles(QAngle(Tilt, yaw, 0));
		} catch (e) {}
	}
}

function ItemSpin::OnGameEvent_round_start(params) {
	Items = {};
	Owned = {};
	Active = [];
	LastScan = 0.0;
	LastSelect = -100.0;
	Generation++;
	Tick(Generation);
}

function ItemSpin::Hook() {
	if (("GameEventCallbacks" in getroottable()) && ("hd4l_item_spin" in ::GameEventCallbacks))
		return;
	__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
	::GameEventCallbacks["hd4l_item_spin"] <- true;
}

ItemSpin.Precache();
ItemSpin.Hook();

if (!("HD4L_Parts" in getroottable()))
	::HD4L_Parts <- {};
::HD4L_Parts["item_spin"] <- "0.1";
