::HD4L <- {
	Version = "0.1",
	Modes = { hd4l = "coop", hd4lversus = "versus", hd4lsurvival = "survival", hd4lfort = "survival", hd4lfreebuild = "survival" },

	Required = {
		momentum = true, hyper_feedback = true, glory_kill2 = true, firepower = true, adrenaline_supply = true,
		witch_escort = true, bodyguard = true, infected_moves = true,
		no_incap = true, one_life = true, self_defib = true, bile_flash = true, item_spin = true, arsenal = true, door_blast = true, armour = true,
		bot_takeover = false, death_shockwave = false, escalation = false,
		chapter_stats = true, projectiles = true, fort = false
	},

	Skip = {
		hd4l = { fort = true },
		hd4lversus = { fort = true },
		hd4lsurvival = { escalation = true, one_life = true, door_blast = true },
		hd4lfort = { momentum = true, glory_kill2 = true, adrenaline_supply = true, witch_escort = true, bodyguard = true,
		             infected_moves = true, one_life = true, bile_flash = true, item_spin = true, door_blast = true,
		             armour = true, escalation = true, projectiles = true },
		hd4lfreebuild = { momentum = true, glory_kill2 = true, adrenaline_supply = true, witch_escort = true, bodyguard = true,
		                  infected_moves = true, one_life = true, bile_flash = true, item_spin = true, door_blast = true,
		                  armour = true, escalation = true, projectiles = true }
	},

	Tables = {
		momentum = "Momentum", hyper_feedback = "HyperFeedback", glory_kill2 = "GloryKill2", firepower = "Firepower",
		adrenaline_supply = "AdrenalineSupply", witch_escort = "WitchEscort", bodyguard = "Bodyguard",
		infected_moves = "InfectedMoves", no_incap = "NoIncap", bot_takeover = "BotTakeover",
		death_shockwave = "DeathShockwave", escalation = "Escalation", one_life = "OneLife",
		self_defib = "SelfDefib", bile_flash = "BileFlash", item_spin = "ItemSpin", arsenal = "Arsenal", door_blast = "DoorBlast", armour = "Armour",
		chapter_stats = "ChapterStats", projectiles = "Projectiles", fort = "Fort"
	},
	RearmInterval = 0.1,

	WeaponsCoop = {
		weapon_sniper_scout = "weapon_hunting_rifle",
		weapon_sniper_awp = "weapon_sniper_military",
		weapon_smg_mp5 = "weapon_smg_silenced",
		weapon_rifle_sg552 = "weapon_rifle_desert",
		weapon_pain_pills = "weapon_adrenaline"
	},

	WeaponsVersus = {
		weapon_sniper_scout = "weapon_smg_silenced",
		weapon_sniper_awp = "weapon_smg",
		weapon_smg_mp5 = "weapon_smg_silenced",
		weapon_rifle_sg552 = "weapon_smg",
		weapon_pain_pills = "weapon_adrenaline",
		weapon_rifle = "weapon_smg",
		weapon_rifle_ak47 = "weapon_smg_silenced",
		weapon_rifle_desert = "weapon_smg",
		weapon_rifle_m60 = "weapon_shotgun_chrome",
		weapon_autoshotgun = "weapon_pumpshotgun",
		weapon_shotgun_spas = "weapon_shotgun_chrome",
		weapon_hunting_rifle = "weapon_smg_silenced",
		weapon_sniper_military = "weapon_smg",
		weapon_grenade_launcher = "weapon_pumpshotgun"
	},

	TrailSprite = "sprites/laserbeam.vmt",
	GlowSprite = "sprites/glow01.vmt",
	EyeAttachments = [ "eyes", "eye", "head", "forward" ],
	EyeEffects = [ "hd4l_eyes_red", "hd4l_eyes_rage", "hd4l_eyes_white", "hd4l_eyes_hyper", "hd4l_eyes_tank" ],
	EyeSpread = 1.4,
	EyeRigs = {
		"models/infected/hulk.mdl": { attachment = "mouth", forward = 2.5, up = 3.0, spread = 2.0 },
		"models/infected/hulk_dlc3.mdl": { attachment = "forward", forward = 0.0, up = 1.0, spread = 2.0 },
		"models/infected/hulk_l4d1.mdl": { attachment = "forward", forward = 0.0, up = 1.0, spread = 2.0 }
	},
	LoudLevel = 95,
	EyesLogged = {},

	CrosshairOff = true,
	CrosshairInterval = 0.2,
	HIDEHUD_CROSSHAIR = 256,

	Generation = 0
}

if (!("HD4L_Parts" in getroottable()))
	::HD4L_Parts <- {};

function HD4L::Log(msg) {
	printl("[HD4L] " + msg);
}

function HD4L::Mode() {
	local mode = "";
	try { mode = Director.GetGameMode(); } catch (e) {}
	return mode;
}

function HD4L::Active() {
	return Mode() in Modes;
}

function HD4L::Versus() {
	return Mode() == "hd4lversus";
}

function HD4L::Plain() {
	return Mode() == "hd4lfort" || Mode() == "hd4lfreebuild";
}

function HD4L::Survival() {
	return Mode() == "hd4lsurvival" || Mode() == "hd4lfort" || Mode() == "hd4lfreebuild";
}

function HD4L::Wanted(name) {
	local mode = Mode();
	if ((mode in Skip) && (name in Skip[mode]))
		return false;
	return Required[name] || !Versus();
}

function HD4L::ConvertWeapon(classname, table) {
	local name = classname;
	local spawn = false;
	if (name.len() > 6 && name.slice(name.len() - 6) == "_spawn") {
		name = name.slice(0, name.len() - 6);
		spawn = true;
	}
	if (!(name in table))
		return 0;
	return table[name] + (spawn ? "_spawn" : "");
}

function HD4L::ConvertTable(table) {
	local both = {};
	foreach (name, to in table) {
		both[name] <- to;
		both[name + "_spawn"] <- to + "_spawn";
	}
	return both;
}

function HD4L::Verify(generation) {
	if (generation != Generation || !Active())
		return;
	local missing = [];
	local count = 0;
	foreach (name, inVersus in Required) {
		if (!Wanted(name))
			continue;
		if (name in ::HD4L_Parts)
			count++;
		else
			missing.append(name);
	}
	if (missing.len() == 0) {
		Log("pack complete, " + count + " parts, " + Mode());
		return;
	}
	local list = "";
	foreach (i, name in missing)
		list += (i > 0 ? ", " : "") + name;
	Log("missing parts: " + list);
	ClientPrint(null, 3, "[HD4L] missing parts: " + list);
}

function HD4L::LoadParts() {
	local root = getroottable();
	local loaded = 0;
	foreach (name, inVersus in Required) {
		if (!Wanted(name))
			continue;
		if (Tables[name] in root)
			continue;
		try { IncludeScript(name, root); loaded++; } catch (e) { Log("could not include " + name + ": " + e); }
	}
	ArmAll();
	Log("included " + loaded + " parts");
}

function HD4L::ArmAll() {
	local root = getroottable();
	foreach (name, table in Tables) {
		if (!(table in root) || !("Hook" in root[table]))
			continue;
		try { root[table].Hook(); } catch (e) { Log("hook failed for " + name + ": " + e); }
	}
	Hook();
}

function HD4L::RearmTick(generation) {
	if (generation != Generation || !Active())
		return;
	if (!("GameEventCallbacks" in getroottable()) || !("hd4l_core" in ::GameEventCallbacks)) {
		ArmAll();
	}
	DoEntFire("!self", "RunScriptCode", "::HD4L.RearmTick(" + generation + ")", RearmInterval, null, Entities.First());
}

function HD4L::Precache() {
	foreach (model in [ TrailSprite, GlowSprite ])
		try { PrecacheModel(model); } catch (e) {}
	foreach (effect in EyeEffects)
		try { PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = effect, origin = Vector(0, 0, 0), start_active = 1 }); } catch (e) {}
}

function HD4L::Loud(sound, ent, level = null, pitch = 100, volume = 1.0) {
	if (ent == null || !ent.IsValid())
		return;
	try {
		EmitAmbientSoundOn(sound, volume, level == null ? LoudLevel : level, pitch, ent);
		return;
	} catch (e) {}
	EmitSoundOn(sound, ent);
	EmitSoundOn(sound, ent);
}

function HD4L::Speaker(pos, seconds) {
	local speaker = SpawnEntityFromTable("info_target", { origin = pos });
	if (speaker != null)
		DoEntFire("!self", "Kill", "", seconds, null, speaker);
	return speaker;
}

function HD4L::Trail(pos, color, life, width, alpha = 255) {
	return SpawnEntityFromTable("env_spritetrail", { origin = pos, spritename = TrailSprite, lifetime = life,
		startwidth = width, endwidth = 0.0, rendermode = 5, renderamt = alpha, rendercolor = color });
}

function HD4L::Glow(pos, color, scale, alpha = 255) {
	return SpawnEntityFromTable("env_sprite", { origin = pos, model = GlowSprite, scale = format("%.3f", scale),
		rendermode = 9, renderamt = alpha, rendercolor = color, spawnflags = 1, GlowProxySize = "2" });
}

function HD4L::Flash(pos, color, scale, seconds) {
	local glow = Glow(pos, color, scale);
	if (glow != null)
		DoEntFire("!self", "Kill", "", seconds, null, glow);
	return glow;
}

function HD4L::Attach(child, parent, attachment) {
	DoEntFire("!self", "SetParent", "!activator", 0, parent, child);
	if (attachment != "")
		DoEntFire("!self", "SetParentAttachmentMaintainOffset", attachment, 0.01, null, child);
}

function HD4L::Eyes(ent, effect, fallbackHeight = 64.0) {
	local out = [];
	if (ent == null || !ent.IsValid())
		return out;
	local name = "";
	local pos = null;
	local side = null;
	local spread = EyeSpread;
	local model = "";
	try { model = ent.GetModelName().tolower(); } catch (e) {}
	if (model in EyeRigs) {
		local rig = EyeRigs[model];
		local id = 0;
		try { id = ent.LookupAttachment(rig.attachment); } catch (e) { id = 0; }
		if (id > 0) {
			local yaw = ent.GetAngles().y * 0.0174533;
			local fwd = Vector(cos(yaw), sin(yaw), 0);
			name = rig.attachment;
			pos = ent.GetAttachmentOrigin(id) + fwd * rig.forward + Vector(0, 0, rig.up);
			side = Vector(-sin(yaw), cos(yaw), 0);
			spread = rig.spread;
		}
	}
	if (pos == null) foreach (candidate in EyeAttachments) {
		local id = 0;
		try { id = ent.LookupAttachment(candidate); } catch (e) { id = 0; }
		if (id <= 0)
			continue;
		name = candidate;
		pos = ent.GetAttachmentOrigin(id);
		try { side = ent.GetAttachmentAngles(id).Left(); } catch (e) { side = null; }
		break;
	}
	if (pos == null)
		pos = ent.GetOrigin() + Vector(0, 0, fallbackHeight);
	if (side == null) {
		local yaw = ent.GetAngles().y * 0.0174533;
		side = Vector(-sin(yaw), cos(yaw), 0);
	}
	foreach (sign in [ -1.0, 1.0 ]) {
		local fx = SpawnEntityFromTable("info_particle_system", { origin = pos + side * (spread * sign), effect_name = effect, start_active = 1 });
		if (fx == null)
			continue;
		Attach(fx, ent, name);
		out.append(fx);
	}
	local key = ent.GetClassname() + (model in EyeRigs ? " " + model : "");
	if (!(key in EyesLogged)) {
		EyesLogged[key] <- true;
		Log("eyes on " + key + " at attachment '" + (name == "" ? "none, origin + " + fallbackHeight : name) + "'");
	}
	return out;
}

function HD4L::Unfx(list, delay = 0.0) {
	if (list == null)
		return;
	foreach (fx in list) {
		if (fx == null || !fx.IsValid())
			continue;
		if (fx.GetClassname() == "info_particle_system") {
			DoEntFire("!self", "Stop", "", delay, null, fx);
			DoEntFire("!self", "Kill", "", delay + 1.5, null, fx);
		} else
			DoEntFire("!self", "Kill", "", delay, null, fx);
	}
}

function HD4L::ClientCommandEntity() {
	local ent = Entities.FindByName(null, "hd4l_clientcmd");
	if (ent != null && ent.IsValid())
		return ent;
	return SpawnEntityFromTable("point_clientcommand", { targetname = "hd4l_clientcmd" });
}

function HD4L::Humans() {
	local list = [];
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null)
		if (!IsPlayerABot(p) && p.IsValid())
			list.append(p);
	return list;
}

function HD4L::SendCrosshair() {
	if (!CrosshairOff)
		return;
	local ent = ClientCommandEntity();
	if (ent == null)
		return;
	local hd4l = Active() && !Plain();
	local cmd = hd4l ? "crosshair 0" : "crosshair 1";
	foreach (p in Humans()) {
		DoEntFire("!self", "Command", cmd, 0, p, ent);

		local notices = hd4l ? "0" : "1";
		DoEntFire("!self", "Command", "hud_deathnotice_bots " + notices, 0.1, p, ent);
		DoEntFire("!self", "Command", "hud_deathnotice_threats " + notices, 0.2, p, ent);
	}
}

function HD4L::CrosshairTick(generation) {
	if (generation != Generation || !Active() || !CrosshairOff)
		return;
	foreach (p in Humans()) {
		try {
			local flags = NetProps.GetPropInt(p, "m_Local.m_iHideHUD");
			local want = Plain() ? (flags & ~HIDEHUD_CROSSHAIR) : (flags | HIDEHUD_CROSSHAIR);
			if (want != flags)
				NetProps.SetPropInt(p, "m_Local.m_iHideHUD", want);
		} catch (e) {}
	}
	DoEntFire("!self", "RunScriptCode", "::HD4L.CrosshairTick(" + generation + ")", CrosshairInterval, null, Entities.First());
}

function HD4L::OnGameEvent_player_activate(params) {
	DoEntFire("!self", "RunScriptCode", "::HD4L.SendCrosshair()", 1.0, null, Entities.First());
}

function HD4L::OnGameEvent_round_start(params) {
	Generation++;
	DoEntFire("!self", "RunScriptCode", "::HD4L.SendCrosshair()", 1.0, null, Entities.First());
	if (Active()) {
		DoEntFire("!self", "RunScriptCode", "::HD4L.Verify(" + Generation + ")", 3.0, null, Entities.First());
		CrosshairTick(Generation);
		RearmTick(Generation);
	}
}

function HD4L::Hook() {
	if (("GameEventCallbacks" in getroottable()) && ("hd4l_core" in ::GameEventCallbacks))
		return;
	__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
	::GameEventCallbacks["hd4l_core"] <- true;
	if ("LastStand" in getroottable())
		try { ::LastStand.Hook(); } catch (e) { Log("last stand hook failed: " + e); }
}

if (!("LastStand" in getroottable()))
	try { IncludeScript("last_stand", getroottable()); } catch (e) { HD4L.Log("could not include last_stand: " + e); }
HD4L.Precache();
HD4L.Hook();
HD4L.Log("core loaded, mode " + HD4L.Mode() + (HD4L.Active() ? "" : ", inactive"));
