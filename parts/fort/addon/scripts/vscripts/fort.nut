const FORT_IN_DUCK = 4;
const FORT_IN_USE = 32;
const FORT_IN_ATTACK2 = 2048;
const FORT_IN_RELOAD = 8192;
const FORT_IN_SPEED = 131072;
const FORT_IN_ZOOM = 524288;
const FORT_TEAM_INFECTED = 3;
const FORT_ZOMBIE_TANK = 8;
const FORT_ZOMBIE_WITCH = 7;
const FORT_DMG_SLASH = 4;
const FORT_DMG_BURN = 8;
const FORT_DMG_BLAST = 64;
const FORT_PIECE_NAME = "hd4l_fort_piece";
const FORT_GHOST_NAME = "hd4l_fort_ghost";
const FORT_DEBRIS_NAME = "hd4l_fort_debris";
const FORT_ITEM_NAME = "hd4l_fort_item";
const FORT_LOOT_NAME = "hd4l_fort_loot";

::Fort <- {
	Versus = false,
	Survival = true,
	Stock = true,
	Files = [ "fort_scrap", "fort_build", "fort_grid", "fort_pieces", "fort_waves" ],

	StartScrap = 60,
	ScrapCap = 9999,

	HammerRange = 110.0,
	HammerDelay = 0.2,
	ScrapPerHit = 12,
	MaxHits = 6,
	Knock = 80.0,
	SwingGap = 0.25,
	BreakMax = 200.0,
	Explosive = [ "propane", "oxygen", "gascan", "explosive", "firework", "canister", "fuel_barrel" ],
	TickEvery = 0.3,
	ScrapMin = 2,
	ScrapMax = 120,
	VolumeScale = 0.0065,
	VolumePower = 0.7,
	ScrapFallback = 10,
	ScrapByModel = [ [ "car", 90 ], [ "truck", 110 ], [ "van", 100 ], [ "dumpster", 75 ], [ "forklift", 80 ],
	                 [ "trashcan", 10 ], [ "trash", 8 ], [ "barrel", 14 ], [ "pallet", 6 ], [ "crate", 12 ], [ "chair", 5 ] ],
	SalvageClasses = { prop_physics = true, prop_physics_override = true, prop_physics_multiplayer = true, prop_car_alarm = true,
	                   prop_dynamic = true, prop_dynamic_override = true, prop_door_rotating = true, func_breakable = true,
	                   func_breakable_surf = true, prop_fuel_barrel = true },
	KeepHints = [],
	Children = [ "prop_car_glass", "prop_dynamic", "prop_dynamic_override", "beam", "env_sprite" ],

	LootProps = {
		meds = [ "models/props_junk/cardboard_box03.mdl", "models/props_junk/cardboard_box04.mdl",
		         "models/props_junk/cardboard_box05.mdl", "models/props_junk/plasticcrate01a.mdl" ],
		thrown = [ "models/props_junk/metal_paintcan001a.mdl", "models/props_junk/metalbucket01a.mdl",
		          "models/props_junk/metalbucket02a.mdl" ],
		light = [ "models/props_junk/wood_crate001a.mdl", "models/props_junk/wood_pallet001a.mdl",
		          "models/props_junk/cardboard_box07.mdl" ],
		gun = [ "models/props_junk/wood_crate001a.mdl", "models/props_junk/wood_crate002a.mdl",
		        "models/props_crates/static_crate_40.mdl" ],
		heavy = [ "models/props_crates/supply_crate01.mdl", "models/props_crates/supply_crate02.mdl" ],
		fuel = [ "models/props_c17/oildrum001.mdl", "models/props_urban/oil_drum001.mdl",
		         "models/props_fairgrounds/traffic_barrel.mdl", "models/props_urban/highway_barrel001.mdl" ]
	},
	LootKind = {
		first_aid_kit = "meds", defibrillator = "meds", adrenaline = "meds", pain_pills = "meds",
		upgradepack_incendiary = "meds", upgradepack_explosive = "meds",
		molotov = "thrown", pipe_bomb = "thrown", vomitjar = "thrown",
		pistol = "light", pistol_magnum = "light", melee = "light",
		smg = "gun", smg_silenced = "gun", smg_mp5 = "gun", pumpshotgun = "gun", shotgun_chrome = "gun",
		rifle = "heavy", rifle_ak47 = "heavy", rifle_desert = "heavy", rifle_sg552 = "heavy", autoshotgun = "heavy",
		shotgun_spas = "heavy", hunting_rifle = "heavy", sniper_military = "heavy", sniper_scout = "heavy",
		sniper_awp = "heavy", rifle_m60 = "heavy", grenade_launcher = "heavy", chainsaw = "heavy",
		gascan = "fuel", propanetank = "fuel", oxygentank = "fuel", fireworkcrate = "fuel"
	},
	LootOther = "meds",
	LootDrop = 16.0,
	Carryables = { gascan = true, propanetank = true, oxygentank = true, fireworkcrate = true, cola_bottles = true, gnome = true },
	CarryFirst = 5.0,
	LootStack = 36.0,
	LootSpread = 64.0,
	LootEvery = 1.0,
	LootKeep = { weapon_ammo_spawn = true, upgrade_ammo_incendiary = true, upgrade_ammo_explosive = true },
	LootValue = {
		first_aid_kit = 30, defibrillator = 60, adrenaline = 12, pain_pills = 10,
		molotov = 15, pipe_bomb = 15, vomitjar = 18,
		upgradepack_incendiary = 20, upgradepack_explosive = 20,
		pistol = 5, pistol_magnum = 10, melee = 10, chainsaw = 20,
		smg = 15, smg_silenced = 15, smg_mp5 = 15, pumpshotgun = 15, shotgun_chrome = 15,
		rifle = 25, rifle_ak47 = 25, rifle_desert = 25, rifle_sg552 = 25, autoshotgun = 25, shotgun_spas = 25,
		hunting_rifle = 25, sniper_military = 25, sniper_scout = 25, sniper_awp = 25,
		rifle_m60 = 35, grenade_launcher = 30,
		gascan = 20, propanetank = 20, oxygentank = 20, fireworkcrate = 20, cola_bottles = 10, gnome = 10,
		upgrade = 15, item = 10
	},
	LootDefault = 10,

	BuildKey = FORT_IN_SPEED,
	PlaceKey = 1,
	NextKey = FORT_IN_ATTACK2,
	PrevKey = FORT_IN_RELOAD,
	ListKey = FORT_IN_ZOOM,
	TapTime = 0.3,
	UpTicks = 2,
	HandsLock = 0.3,
	StandProbe = 52.0,
	PlaceGap = 0.25,
	BuildRange = 300.0,
	FloorProbe = 220.0,
	Clearance = 40.0,
	MaxPieces = 300,
	MaxItems = 80,
	Refund = 1.0,
	ItemPick = 20.0,
	GhostAlpha = 130,
	GhostOk = "225 215 195",
	GhostNo = "215 45 35",
	AimColor = "255 176 60",

	Cell = 32.0,
	StructCell = 128.0,
	StructHeight = 128.0,
	StairPitch = 45.0,
	MaxCells = 16,
	BuildAbove = 32.0,
	BuildBelow = 600.0,
	SideBelow = 8.0,
	Sizes = {},
	FloorReach = 160.0,
	FloorDrop = 24.0,

	RepairRate = 0.25,

	Cats = [ "build", "prop", "item" ],
	DownPitch = 55.0,
	LevelPitch = [ -25.0, -50.0, -65.0, -75.0 ],
	FaceHold = 55.0,
	CellHold = 16.0,
	LevelHold = 4.0,
	WallGap = 24.0,
	ClipMargin = 8.0,
	ClipGround = 20.0,
	ClipWorld = false,
	Collapse = true,
	DebrisLife = 12.0,
	MaxDebris = 60,
	CrushSpeed = 150.0,
	CrushRadius = 56.0,
	CrushDamage = 150,
	CrushSpecial = 60,
	TankThrow = 700.0,
	FallPush = 60.0,
	Board = "models/props_debris/wood_board05a.mdl",
	DoorWidth = 58.0,
	ClimbHeight = 56.0,
	ClimbReach = 260.0,
	ClimbClear = 40.0,
	ClimbSpeed = 320.0,
	ClimbCooldown = 1.5,
	ClimbMax = 6,
	ClimbEvery = 0.25,
	Gravity = 800.0,
	BotLiftHeight = 96.0,
	BotLiftReach = 700.0,
	BotLiftAfter = 3.0,
	DropHeight = 24.0,
	DropTime = 0.12,
	PropStep = 45,
	PropHold = 30.0,
	Blueprints = [
		{ name = "wall", cat = "build", kind = "struct", shape = "wall", model = "models/props_update/wood_128.mdl", normal = "z", box = [ -64.2, -64.2, -4.2, 64.2, 64.2, 4.2 ], cost = 25, health = 900 },
		{ name = "floor", cat = "build", kind = "struct", shape = "floor", model = "models/props_update/wood_128.mdl", normal = "z", box = [ -64.2, -64.2, -4.2, 64.2, 64.2, 4.2 ], cost = 20, health = 900 },
		{ name = "stairs", cat = "build", kind = "struct", shape = "stairs", model = "models/props_update/wood_128.mdl", normal = "z", box = [ -64.2, -64.2, -4.2, 64.2, 64.2, 4.2 ], cost = 40, health = 1200 },
		{ name = "roof", cat = "build", kind = "struct", shape = "roof", model = "models/props_update/wood_128.mdl", normal = "z", box = [ -64.2, -64.2, -4.2, 64.2, 64.2, 4.2 ], cost = 20, health = 900 },
		{ name = "door", cat = "build", kind = "struct", shape = "wall", door = true, model = "models/props_doors/doormain_rural01.mdl", cost = 35, health = 700 },
		{ name = "grate wall", cat = "build", kind = "struct", shape = "wall", model = "models/props_urban/fence001_128.mdl", normal = "x", box = [ -1.8, -66.5, -0.3, 3.4, 62.0, 128.2 ], cost = 45, health = 800 },
		{ name = "grate floor", cat = "build", kind = "struct", shape = "floor", model = "models/props_urban/fence001_128.mdl", normal = "x", box = [ -1.8, -66.5, -0.3, 3.4, 62.0, 128.2 ], cost = 35, health = 800 },
		{ name = "grate stairs", cat = "build", kind = "struct", shape = "stairs", model = "models/props_urban/fence001_128.mdl", normal = "x", box = [ -1.8, -66.5, -0.3, 3.4, 62.0, 128.2 ], cost = 60, health = 1000 },
		{ name = "grate roof", cat = "build", kind = "struct", shape = "roof", model = "models/props_urban/fence001_128.mdl", normal = "x", box = [ -1.8, -66.5, -0.3, 3.4, 62.0, 128.2 ], cost = 35, health = 800 },
		{ name = "sandbags", cat = "prop", kind = "wall", model = "models/props_fortifications/sandbags_line2.mdl", cost = 30, health = 900, yaw = 0 },
		{ name = "barricade", cat = "prop", kind = "wall", model = "models/props_fortifications/barricade001_128_reference.mdl", cost = 20, health = 500, yaw = 0 },
		{ name = "barrier", cat = "prop", kind = "wall", model = "models/props_fortifications/concrete_barrier001_128_reference.mdl", cost = 45, health = 1400, yaw = 0 },
		{ name = "dumpster", cat = "prop", kind = "wall", model = "models/props_junk/dumpster.mdl", cost = 60, health = 1800, yaw = 0 },
		{ name = "concrete wall", cat = "prop", kind = "wall", model = "models/props_fortifications/concrete_wall001_96_reference.mdl", cost = 80, health = 2200, yaw = 0 },
		{ name = "car wreck", cat = "prop", kind = "wall", model = "models/props_vehicles/cara_95sedan_wrecked.mdl", cost = 120, health = 3500, yaw = 0 },
		{ name = "container", cat = "prop", kind = "wall", model = "models/props_equipment/cargo_container01.mdl", cost = 300, health = 8000, yaw = 0 },
		{ name = "guard tower", cat = "prop", kind = "wall", model = "models/props_fortifications/guard_tower.mdl", cost = 400, health = 5000, yaw = 0 },
		{ name = "wood stairs", cat = "prop", kind = "wall", model = "models/props_exteriors/wood_stairs_120.mdl", cost = 60, health = 1200, yaw = 0 },
		{ name = "scaffold", cat = "prop", kind = "wall", model = "models/props_equipment/scaffolding.mdl", cost = 150, health = 2500, yaw = 0 },
		{ name = "razorwire", cat = "prop", kind = "wire", model = "models/props_fortifications/barricade_razorwire001_128_reference.mdl", cost = 35, health = 600, yaw = 0 },
		{ name = "fire barricade", cat = "prop", kind = "fire", model = "models/props_fortifications/barricade_burning_01.mdl", cost = 60, health = 800, yaw = 0 },
		{ name = "mine", cat = "prop", kind = "mine", model = "models/props_buildables/mine.mdl", cost = 40, health = 1, yaw = 0 },
		{ name = "gas can", cat = "prop", kind = "item", classname = "weapon_gascan", model = "models/props_junk/gascan001a.mdl", cost = 25, yaw = 0 },
		{ name = "propane tank", cat = "prop", kind = "item", classname = "weapon_propanetank", model = "models/props_junk/propanecanister001a.mdl", cost = 35, yaw = 0 },
		{ name = "oxygen tank", cat = "prop", kind = "item", classname = "weapon_oxygentank", model = "models/props_equipment/oxygentank01.mdl", cost = 30, yaw = 0 },
		{ name = "fireworks", cat = "prop", kind = "item", classname = "weapon_fireworkcrate", model = "models/props_junk/explosive_box001.mdl", cost = 40, yaw = 0 },
		{ name = "floodlight", cat = "prop", kind = "light", model = "models/props_equipment/light_floodlight.mdl", cost = 30, health = 400, yaw = 0 },
		{ name = "minigun", cat = "prop", kind = "gun", classname = "prop_minigun", model = "models/w_models/weapons/w_minigun.mdl", cost = 1000, health = 1500, yaw = 0 },
		{ name = "50 cal", cat = "prop", kind = "gun", classname = "prop_mounted_machine_gun", model = "models/w_models/weapons/50cal.mdl", cost = 1200, health = 1800, yaw = 0 },
		{ name = "ammo", cat = "item", kind = "item", classname = "weapon_ammo_spawn", model = "models/props/terror/ammo_stack.mdl", cost = 40, yaw = 0 },
		{ name = "medkit", cat = "item", kind = "item", classname = "weapon_first_aid_kit_spawn", model = "models/w_models/weapons/w_eq_medkit.mdl", cost = 60, yaw = 0 },
		{ name = "adrenaline", cat = "item", kind = "item", classname = "weapon_adrenaline_spawn", model = "models/w_models/weapons/w_eq_adrenaline.mdl", cost = 25, yaw = 0 },
		{ name = "molotov", cat = "item", kind = "item", classname = "weapon_molotov_spawn", model = "models/w_models/weapons/w_eq_molotov.mdl", cost = 30, yaw = 0 },
		{ name = "pipe bomb", cat = "item", kind = "item", classname = "weapon_pipe_bomb_spawn", model = "models/w_models/weapons/w_eq_pipebomb.mdl", cost = 30, yaw = 0 },
		{ name = "flashbang", cat = "item", kind = "item", classname = "weapon_vomitjar_spawn", model = "models/w_models/weapons/w_eq_bile_flask.mdl", cost = 35, yaw = 0 },
		{ name = "incendiary ammo", cat = "item", kind = "item", classname = "weapon_upgradepack_incendiary_spawn", model = "models/w_models/weapons/w_eq_incendiary_ammopack.mdl", cost = 50, yaw = 0 },
		{ name = "explosive ammo", cat = "item", kind = "item", classname = "weapon_upgradepack_explosive_spawn", model = "models/w_models/weapons/w_eq_explosive_ammopack.mdl", cost = 60, yaw = 0 },
		{ name = "gnome", cat = "item", kind = "item", classname = "weapon_gnome", model = "models/props_junk/gnome.mdl", cost = 15, yaw = 0 },
		{ name = "defibrillator", cat = "item", kind = "item", classname = "weapon_defibrillator_spawn", model = "models/w_models/weapons/w_eq_defibrillator.mdl", cost = 750, yaw = 0 }
	],

	WaveBase = 90.0,
	WaveGrow = 45.0,
	BreakSeconds = 75.0,
	BonusPerWave = 150,
	TankFrom = 4,
	TankEvery = 2,
	KillScrap = { common = 1, special = 6, tank = 80, witch = 25 },
	WaveWeapons = [ "smg", "smg_silenced", "smg_mp5", "pumpshotgun", "shotgun_chrome", "rifle", "rifle_ak47", "rifle_desert",
	                "rifle_sg552", "autoshotgun", "shotgun_spas", "hunting_rifle", "sniper_military", "sniper_scout",
	                "sniper_awp", "rifle_m60", "grenade_launcher" ],
	LaserBit = 4,
	Axe = [ "fireaxe", "crowbar", "machete", "katana", "baseball_bat" ],
	CalmEvery = 0.5,
	BeepFrom = 10,

	Breakable = true,
	PropHealth = 100000,
	HitScale = 3.0,

	WearInterval = 0.25,
	Reach = 24.0,
	CommonDps = 8.0,
	SpecialDps = 40.0,
	TankDps = 300.0,
	WireEvery = 0.5,
	WireDamage = 20,
	WireWear = 25,
	FireEvery = 0.5,
	FireDamage = 12,
	FireWear = 15,
	FireEffect = "fire_small_01",
	MineReach = 64.0,
	MineRadius = 250.0,
	MineDamage = { common = 500, special = 300, tank = 400 },
	MineEffect = "gas_explosion_initialburst_blast",
	LightColor = "255 236 210 255",
	LightDistance = 700,
	LightHeight = 90.0,
	Stages = [ { at = 0.66, color = "235 205 185" }, { at = 0.33, color = "215 130 110" } ],

	ChatHelp = true,
	HelpDelay = 3.0,
	StripDelay = 2.0,

	Sounds = {
		Tick = "physics/metal/metal_box_impact_hard1.wav",
		Salvaged = "physics/metal/metal_box_break1.wav",
		Place = "physics/concrete/concrete_block_impact_hard1.wav",
		Remove = "physics/wood/wood_box_break1.wav",
		Crack = "physics/concrete/concrete_impact_hard2.wav",
		Break = "physics/concrete/concrete_break2.wav",
		Cycle = "ui/menu_click04.wav",
		Deny = "momentum/deny.mp3",
		Loot = "ui/littlereward.wav",
		Mine = "weapons/grenade_launcher/grenadefire/grenade_launcher_explode_1.wav",
		Beep = "ui/beep07.wav",
		WaveOver = "ui/bigreward.wav"
	},
	Dust = "hunter_leap_dust",
	Blood = "blood_impact_red_01",

	Phase = "off",
	Wave = 0,
	PhaseUntil = 0.0,
	Scrap = 0,
	Pieces = {},
	Supplies = {},
	Parts = {},
	Slots = {},
	Loot = {},
	Dents = {},
	Quiet = {},
	Debris = [],
	Dropping = [],
	Climbed = {},
	LastClimb = 0.0,
	LastLift = 0.0,
	Stranded = {},
	LastDebris = 0.0,
	Held = {},
	Tanks = [],
	Players = {},
	LastWear = 0.0,
	LastLoot = 0.0,
	LastCalm = 0.0,
	LastBeep = -1,
	StartedAt = 0.0,
	NextPanic = 0.0,
	NextSpecial = 0.0,
	SpecialEvery = 2.0,
	AllSpecials = [ 1, 2, 3, 4, 5, 6 ],
	StockSpecials = [ 2, 4 ],
	StockDominators = 2,
	Generation = 0
}

function Fort::Log(msg) {
	printl("[Fort] " + msg);
}

function Fort::ModeAllowed() {
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

function Fort::InSurvival() {
	local mode = "";
	try { mode = Director.GetGameMode(); } catch (e) {}
	return (mode == "hd4lsurvival" || (mode == "hd4lfort" || mode == "hd4lfreebuild")) && ModeAllowed();
}

function Fort::Building() {
	return Phase == "prep" || Phase == "break";
}

function Fort::Precache() {
	foreach (name, path in Sounds)
		PrecacheSound(path);
	foreach (bp in Blueprints)
		try { PrecacheModel(bp.model); } catch (e) {}
	foreach (kind, models in LootProps)
		foreach (model in models)
			try { PrecacheModel(model); } catch (e) {}
	foreach (effect in [ Dust, Blood, FireEffect, MineEffect ])
		PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = effect, origin = Vector(0, 0, 0), start_active = 1 });
}

function Fort::Particle(effect, pos, life) {
	local gfx = SpawnEntityFromTable("info_particle_system", { effect_name = effect, origin = pos, start_active = 1 });
	if (gfx != null && life > 0.0)
		DoEntFire("!self", "Kill", "", life, null, gfx);
	return gfx;
}

function Fort::Sound(sound, ent) {
	if (ent == null || !ent.IsValid())
		return;
	if (("HD4L" in getroottable()) && ("Loud" in ::HD4L))
		try { ::HD4L.Loud(sound, ent, 90); return; } catch (e) {}
	EmitSoundOn(sound, ent);
}

function Fort::SoundAt(sound, pos) {
	local speaker = SpawnEntityFromTable("info_target", { origin = pos });
	if (speaker == null)
		return;
	Sound(sound, speaker);
	DoEntFire("!self", "Kill", "", 3.0, null, speaker);
}

function Fort::ToAll(sound) {
	foreach (p in Humans())
		try { EmitSoundOnClient(sound, p); } catch (e) {}
}

function Fort::Mark(p, name) {
	if (p == null || !p.IsValid() || IsPlayerABot(p))
		return;
	if (("HyperFeedback" in getroottable()) && ("FlashFor" in ::HyperFeedback))
		try { ::HyperFeedback.FlashFor(p, name); } catch (e) {}
}

function Fort::Spike() {
	if (("HyperFeedback" in getroottable()) && ("Spike" in ::HyperFeedback))
		try { ::HyperFeedback.Spike(); } catch (e) {}
}

function Fort::AddScrap(n) {
	Scrap += n;
	if (Scrap > ScrapCap)
		Scrap = ScrapCap;
}

function Fort::StateOf(p) {
	local id = p.GetPlayerUserId();
	if (!(id in Players))
		Players[id] <- { p = p, prev = 0, cat = 0, pick = [ 0, 0, 0 ], down = {}, nextAt = -10.0, prevAt = -10.0, nextUsed = false, prevUsed = false, nextWas = false, prevWas = false, placedAt = -10.0, spotOk = true, faceYaw = null, propYaw = null, cellX = null, cellY = null, lastLevel = 0, lastOwn = false, clipKey = "", clipBlocked = false, turn = 0, buildMode = false, ghost = null, ghostModel = "",
		                 ghostColor = "", ghostParts = [], aim = null, look = null, swingWeapon = null, swingNext = 0.0, swungAt = -10.0, lookColor = null, value = -1,
		                 repairAt = 0.0, debt = 0.0 };
	local st = Players[id];
	st.p = p;
	return st;
}

function Fort::Hud(p) {
	if (Phase == "off" || p == null || !p.IsValid() || !p.IsSurvivor())
		return null;
	local st = StateOf(p);
	if (!Building())
		return { scrap = Scrap, cost = -1, ok = true };
	if (st.value >= 0)
		return { scrap = Scrap, cost = st.value, ok = true };
	local bp = Pick(st);
	return { scrap = Scrap, cost = st.buildMode ? bp.cost : -1, ok = Scrap >= bp.cost && st.spotOk };
}

function Fort::WaveHud(p) {
	if (Phase == "off")
		return null;
	local left = (PhaseUntil - Time() + 0.99).tointeger();
	if (left < 0)
		left = 0;
	if (Phase == "wave")
		return { state = 1, wave = Wave, seconds = left };
	if (Phase == "break")
		return { state = 2, wave = Wave + 1, seconds = left };
	return { state = 2, wave = 1, seconds = -1 };
}

function Fort::Look(st, ent, value) {
	if (st.look == ent) {
		st.value = value;
		return;
	}
	Unlook(st);
	if (ent == null || !ent.IsValid())
		return;
	st.look = ent;
	st.value = value;
	try { st.lookColor = NetProps.GetPropInt(ent, "m_clrRender"); } catch (e) { st.lookColor = null; }
	DoEntFire("!self", "Color", AimColor, 0, null, ent);
}

function Fort::Unlook(st) {
	if (st.look != null && st.look.IsValid() && st.lookColor != null)
		try { NetProps.SetPropInt(st.look, "m_clrRender", st.lookColor); } catch (e) {}
	st.look = null;
	st.lookColor = null;
	st.value = -1;
}

function Fort::Humans() {
	local list = [];
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null)
		if (p.IsSurvivor() && !IsPlayerABot(p) && !p.IsDead())
			list.append(p);
	return list;
}

function Fort::Survivors() {
	local list = [];
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null)
		if (p.IsSurvivor() && !p.IsDead())
			list.append(p);
	return list;
}

function Fort::Aim(p, range) {
	local eye = p.EyePosition();
	local tr = { start = eye, end = eye + p.EyeAngles().Forward() * range, ignore = p };
	TraceLine(tr);
	if (!("pos" in tr))
		tr.pos <- tr.end;
	return tr;
}

function Fort::Hit(tr) {
	if (!("hit" in tr) || !tr.hit || !("enthit" in tr) || tr.enthit == null)
		return null;
	return tr.enthit.IsValid() ? tr.enthit : null;
}

function Fort::OffRay(p, point) {
	local eye = p.EyePosition();
	local dir = p.EyeAngles().Forward();
	local to = point - eye;
	local along = to.Dot(dir);
	if (along < 0.0)
		return { off = 1.0e9, along = along };
	return { off = (to - dir * along).Length(), along = along };
}

function Fort::Help() {
	if (!ChatHelp || Phase != "prep")
		return;
	ClientPrint(null, 3, "[Fort] Hit amber stuff with your axe for scrap. WALK: build mode. LMB place, RMB / R cycle, MMB next list, look up to build higher. Hold R: take back. Hold RMB: repair. Press the survival button when ready.");
}

function Fort::PlayerTick(p, now) {
	local st = StateOf(p);
	local buttons = 0;
	local pressed = 0;
	try { buttons = NetProps.GetPropInt(p, "m_nButtons"); } catch (e) { return; }
	foreach (key in [ BuildKey, PlaceKey, NextKey, PrevKey, ListKey ]) {
		if (buttons & key) {
			if (!(key in st.down) || st.down[key] < 0)
				pressed = pressed | key;
			st.down[key] <- UpTicks;
		} else if ((key in st.down) && st.down[key] >= 0) {
			st.down[key]--;
			if (st.down[key] == 0)
				st.down[key] = -1;
		}
	}
	st.prev = buttons;
	if (pressed & BuildKey)
		Toggle(p, st);
	if (st.buildMode) {
		BuildTick(p, st, buttons, pressed);
	} else {
		HideGhost(st);
		ClearAim(st);
		HammerTick(p, st);
	}
}

function Fort::Tick(generation) {
	if (generation != Generation)
		return;
	if (Phase != "off") {
		local now = Time();
		if (Free())
			Scrap = ScrapCap;
		if (now - LastLoot >= LootEvery) {
			LastLoot = now;
			try { ConvertLoot(); } catch (e) { Log("loot failed: " + e); }
			try { QuietAlarms(); } catch (e) { Log("alarms failed: " + e); }
			if (now - StartedAt > StripDelay + 0.5)
				AxeAll();
		}
		try { LootTick(now); } catch (e) { Log("loot tick failed: " + e); }
		if (Debris.len() > 0)
			try { DebrisTick(now, now - LastDebris); } catch (e) { Log("debris failed: " + e); }
		if (Dropping.len() > 0)
			try { DropTick(now); } catch (e) { Log("drop failed: " + e); }
		if (now - LastLift >= ClimbEvery) {
			LastLift = now;
			try { BotLift(now); } catch (e) { Log("bot lift failed: " + e); }
		}
		LastDebris = now;
		if (Building()) {
			local seen = {};
			foreach (p in Humans()) {
				seen[p.GetPlayerUserId()] <- true;
				try { PlayerTick(p, now); } catch (e) { Log("player tick failed for " + p.GetPlayerName() + ": " + e); }
			}
			foreach (id, st in clone Players)
				if (!(id in seen)) {
					HideGhost(st);
					ClearAim(st);
					Unlook(st);
					delete Players[id];
				}
			if (Phase == "break")
				BreakTick(now);
		} else if (Phase == "wave")
			WaveTick(now);
	}
	DoEntFire("!self", "RunScriptCode", "::Fort.Tick(" + generation + ")", 0.03, null, Entities.First());
}

function Fort::OnGameEvent_round_start(params) {
	Generation++;
	Pieces = {};
	Supplies = {};
	Parts = {};
	Slots = {};
	Loot = {};
	Dents = {};
	Quiet = {};
	Debris = [];
	Dropping = [];
	Climbed = {};
	Stranded = {};
	LastClimb = 0.0;
	LastCalm = 0.0;
	LastLift = 0.0;
	LastDebris = 0.0;
	Held = {};
	Tanks = [];
	Players = {};
	Wave = 0;
	PhaseUntil = 0.0;
	LastLoot = 0.0;
	StartedAt = Time();
	Scrap = Free() ? ScrapCap : StartScrap;
	Phase = InSurvival() ? "prep" : "off";
	if (Phase == "prep") {
		try { Direct(Calm()); } catch (e) { Log("calm failed: " + e); }
		DoEntFire("!self", "RunScriptCode", "::Fort.Help()", HelpDelay, null, Entities.First());
		DoEntFire("!self", "RunScriptCode", "::Fort.StripStart(" + Generation + ")", StripDelay, null, Entities.First());
	}
	Tick(Generation);
}

function Fort::Hook() {
	if (("GameEventCallbacks" in getroottable()) && ("hd4l_fort" in ::GameEventCallbacks))
		return;
	__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
	::GameEventCallbacks["hd4l_fort"] <- true;
}

foreach (file in Fort.Files)
	try { IncludeScript(file, getroottable()); } catch (e) { Fort.Log("could not include " + file + ": " + e); }

Fort.Precache();
Fort.Hook();

if (!("HD4L_Parts" in getroottable()))
	::HD4L_Parts <- {};
::HD4L_Parts["fort"] <- "0.1";
