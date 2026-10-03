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

function Fort::Salvageable(ent) {
	if (ent == null || !ent.IsValid() || !(ent.GetClassname() in SalvageClasses))
		return false;
	if (ent.GetHealth() < 0)
		return false;
	local name = "";
	try { name = ent.GetName(); } catch (e) {}
	if (name != "")
		return false;
	try { if (ent.GetMoveParent() != null) return false; } catch (e) {}
	local model = "";
	try { model = ent.GetModelName().tolower(); } catch (e) {}
	foreach (hint in KeepHints)
		if (model.find(hint) != null)
			return false;
	local cls = ent.GetClassname();
	if (cls == "prop_dynamic" || cls == "prop_dynamic_override") {
		try {
			local size = ent.GetBoundingMaxs() - ent.GetBoundingMins();
			if (size.x > BreakMax || size.y > BreakMax || size.z > BreakMax)
				return false;
		} catch (e) {}
	}
	return true;
}

function Fort::IsExplosive(ent) {
	if (ent.GetClassname() == "prop_fuel_barrel")
		return true;
	local model = "";
	try { model = ent.GetModelName().tolower(); } catch (e) {}
	foreach (hint in Explosive)
		if (model.find(hint) != null)
			return true;
	return false;
}

function Fort::Free() {
	local mode = "";
	try { mode = Director.GetGameMode(); } catch (e) {}
	return mode == "hd4lfreebuild";
}

function Fort::ScrapOf(ent) {
	local scrap = -1;
	try {
		local lo = ent.GetBoundingMins();
		local hi = ent.GetBoundingMaxs();
		local volume = fabs((hi.x - lo.x) * (hi.y - lo.y) * (hi.z - lo.z));
		if (volume > 1.0)
			scrap = (VolumeScale * pow(volume, VolumePower) + 0.5).tointeger();
	} catch (e) {}
	if (scrap < 0) {
		scrap = ScrapFallback;
		local model = "";
		try { model = ent.GetModelName().tolower(); } catch (e) {}
		foreach (pair in ScrapByModel)
			if (model.find(pair[0]) != null) {
				scrap = pair[1];
				break;
			}
	}
	if (scrap < ScrapMin) scrap = ScrapMin;
	if (scrap > ScrapMax) scrap = ScrapMax;
	local index = ent.GetEntityIndex();
	if ((index in Loot) && Loot[index].ent == ent)
		return Loot[index].value;
	return scrap;
}

function Fort::Target(p) {
	local tr = Aim(p, HammerRange);
	local ent = Hit(tr);
	if (Salvageable(ent))
		return ent;
	local best = null, off = 24.0;
	foreach (i, l in Loot) {
		if (l.ent == null || !l.ent.IsValid())
			continue;
		local r = OffRay(p, l.ent.GetOrigin());
		if (r.along > 0.0 && r.along <= HammerRange && r.off < off) {
			best = l.ent;
			off = r.off;
		}
	}
	return best;
}

function Fort::Worth(ent) {
	local index = ent.GetEntityIndex();
	if ((index in Dents) && Dents[index].ent == ent)
		return Dents[index].left;
	return ScrapOf(ent);
}

function Fort::HammerTick(p, st) {
	local ent = Target(p);
	if (ent != null)
		Look(st, ent, Worth(ent));
	else
		Unlook(st);
	local w = null;
	try { w = p.GetActiveWeapon(); } catch (e) {}
	if (w == null || !w.IsValid() || w.GetClassname() != "weapon_melee") {
		st.swingWeapon = null;
		return;
	}
	local next = 0.0;
	try { next = NetProps.GetPropFloat(w, "m_flNextPrimaryAttack"); } catch (e) { return; }
	local shoving = false;
	try { shoving = (NetProps.GetPropInt(p, "m_nButtons") & FORT_IN_ATTACK2) != 0; } catch (e) {}
	if (st.swingWeapon == w && next > st.swingNext + 0.05 && !shoving)
		Swing(p, st);
	st.swingWeapon = w;
	st.swingNext = next;
}

function Fort::Swing(p, st) {
	local now = Time();
	if (now - st.swungAt < SwingGap)
		return;
	st.swungAt = now;
	DoEntFire("!self", "RunScriptCode", "::Fort.Whack(" + p.GetPlayerUserId() + ")", HammerDelay, null, Entities.First());
}

function Fort::OnGameEvent_break_prop(params) {
	Broke(params);
}

function Fort::OnGameEvent_break_breakable(params) {
	Broke(params);
}

function Fort::Broke(params) {
	if (!InSurvival() || !Building() || !("entindex" in params) || !("userid" in params))
		return;
	local p = null;
	try { p = GetPlayerFromUserID(params.userid); } catch (e) {}
	if (p == null || !p.IsValid() || NetProps.GetPropInt(p, "m_iTeamNum") != 2)
		return;
	local index = params.entindex;
	local ent = null;
	try { ent = EntIndexToHScript(index); } catch (e) {}
	local worth = -1;
	if ((index in Dents) && (ent == null || Dents[index].ent == ent)) {
		if (Dents[index].broken)
			return;
		worth = Dents[index].left;
		Dents[index].broken = true;
	} else if (index in Loot)
		worth = Loot[index].value;
	else if (ent != null && ent.IsValid() && Salvageable(ent))
		worth = ScrapOf(ent);
	if (index in Loot)
		delete Loot[index];
	if (worth <= 0)
		return;
	if (!(index in Dents) || Dents[index].ent != ent)
		Dents[index] <- { ent = ent, left = 0, hits = 0, broken = true };
	AddScrap(worth);
	Mark(p, "kill");
}

function Fort::OnGameEvent_weapon_fire(params) {
	if (!InSurvival() || !Building() || !("userid" in params))
		return;
	local p = null;
	try { p = GetPlayerFromUserID(params.userid); } catch (e) { return; }
	if (p == null || !p.IsValid() || IsPlayerABot(p))
		return;
	local st = StateOf(p);
	if (st.buildMode)
		return;
	local w = null;
	try { w = p.GetActiveWeapon(); } catch (e) {}
	if ((("weapon" in params) && params.weapon == "melee") || (w != null && w.IsValid() && w.GetClassname() == "weapon_melee"))
		Swing(p, st);
}

function Fort::Whack(userid) {
	local p = null;
	try { p = GetPlayerFromUserID(userid); } catch (e) {}
	if (p == null || !p.IsValid() || p.IsDead() || !Building())
		return;
	local ent = Target(p);
	if (ent == null)
		return;
	local index = ent.GetEntityIndex();
	if (!(index in Dents) || Dents[index].ent != ent) {
		local scrap = ScrapOf(ent);
		local hits = ((scrap + ScrapPerHit - 1) / ScrapPerHit).tointeger();
		Dents[index] <- { ent = ent, left = scrap, hits = hits < 1 ? 1 : (hits > MaxHits ? MaxHits : hits), broken = false };
	}
	local dent = Dents[index];
	if (dent.broken)
		return;
	local pos = ent.GetOrigin();
	try { pos = ent.GetCenter(); } catch (e) {}
	local pay = dent.hits <= 1 ? dent.left : (dent.left / dent.hits).tointeger();
	dent.left -= pay;
	dent.hits--;
	AddScrap(pay);
	if (dent.hits > 0) {
		local push = p.EyeAngles().Forward() * Knock + Vector(0, 0, Knock * 0.4);
		local cls = ent.GetClassname();
		if (cls.find("prop_physics") == 0 || cls == "prop_car_alarm")
			try { ent.ApplyAbsVelocityImpulse(push); } catch (e) {}
		Particle(Dust, pos, 1.0);
		Sound(Sounds.Tick, ent);
		Mark(p, "hit");
		return;
	}
	dent.broken = true;
	RemoveChildren(ent);
	if (index in Loot)
		delete Loot[index];
	if (index in Pieces)
		return;
	if (IsExplosive(ent))
		DoEntFire("!self", "Kill", "", 0, null, ent);
	else {
		DoEntFire("!self", "Break", "", 0, null, ent);
		DoEntFire("!self", "Kill", "", 0.1, null, ent);
	}
	Particle(Dust, pos, 1.5);
	SoundAt(Sounds.Salvaged, pos);
	Mark(p, "kill");
}

function Fort::RemoveChildren(ent) {
	local found = [];
	foreach (cls in Children) {
		local c = null;
		while ((c = Entities.FindByClassnameWithin(c, cls, ent.GetOrigin(), 400.0)) != null) {
			local parent = null;
			try { parent = c.GetMoveParent(); } catch (e) {}
			if (parent == ent)
				found.append(c);
		}
	}
	foreach (c in found)
		if (c.IsValid())
			c.Kill();
}

function Fort::LootName(cls) {
	local name = cls;
	if (name.len() > 7 && name.slice(0, 7) == "weapon_")
		name = name.slice(7);
	if (name.len() > 6 && name.slice(name.len() - 6) == "_spawn")
		name = name.slice(0, name.len() - 6);
	return name;
}

function Fort::LootWorth(ent) {
	local name = LootName(ent.GetClassname());
	local value = (name in LootValue) ? LootValue[name] : LootDefault;
	local count = 1;
	try { count = NetProps.GetPropInt(ent, "m_itemCount"); } catch (e) { count = 1; }
	if (count < 1 || count > 16)
		count = 1;
	return value * count;
}

function Fort::Lootable(ent) {
	if (ent == null || !ent.IsValid())
		return false;
	local cls = ent.GetClassname();
	if (cls in LootKeep)
		return false;
	if (!(cls.len() > 7 && cls.slice(0, 7) == "weapon_") && !(cls.len() > 8 && cls.slice(0, 8) == "upgrade_"))
		return false;
	local name = "";
	try { name = ent.GetName(); } catch (e) {}
	if (name == FORT_ITEM_NAME)
		return false;
	local owner = null;
	try { owner = NetProps.GetPropEntity(ent, "m_hOwner"); } catch (e) {}
	local index = ent.GetEntityIndex();
	if (owner != null) {
		Held[index] <- ent;
		return false;
	}
	if ((index in Held) && Held[index] == ent)
		return false;
	if ((LootName(cls) in Carryables) && Time() - StartedAt > CarryFirst)
		return false;
	try { if (ent.GetMoveParent() != null) return false; } catch (e) {}
	return true;
}

function Fort::QuietAlarms() {
	local ent = null;
	while ((ent = Entities.FindByClassname(ent, "prop_car_alarm")) != null) {
		local index = ent.GetEntityIndex();
		if ((index in Quiet) && Quiet[index] == ent)
			continue;
		Quiet[index] <- ent;
		DoEntFire("!self", "Disable", "", 0, null, ent);
	}
}

function Fort::ConvertLoot() {
	local found = [];
	foreach (pattern in [ "weapon_*", "upgrade_*" ]) {
		local ent = null;
		while ((ent = Entities.FindByClassname(ent, pattern)) != null)
			if (Lootable(ent))
				found.append(ent);
	}
	local placed = [];
	foreach (ent in found) {
		if (!ent.IsValid())
			continue;
		local pos = ent.GetOrigin();
		local name = LootName(ent.GetClassname());
		local value = LootWorth(ent);
		ent.Kill();
		SpawnLoot(pos, name, value, placed);
	}
}

function Fort::SpawnLoot(pos, name, value, placed = null) {
	local kind = (name in LootKind) ? LootKind[name] : LootOther;
	local models = LootProps[kind];
	local model = models[RandomInt(0, models.len() - 1)];
	local stack = 0;
	if (placed != null)
		foreach (at in placed)
			if (Vector(at.x - pos.x, at.y - pos.y, 0).Length() < LootSpread)
				stack++;
	local drop = pos + Vector(0, 0, LootDrop + LootStack * stack);
	local angles = "0 " + RandomInt(0, 359) + " 0";
	local ent = SpawnEntityFromTable("prop_physics_override", { model = model, origin = drop, angles = angles });
	if (ent == null)
		return null;
	if (placed != null)
		placed.append(pos);
	Loot[ent.GetEntityIndex()] <- { ent = ent, value = value, kind = kind, model = model, pos = drop, angles = angles };
	DoEntFire("!self", "RunScriptCode", "::Fort.LootRecheck(" + ent.GetEntityIndex() + ")", 0.1, null, Entities.First());
	return ent;
}

function Fort::LootRecheck(index) {
	if (!(index in Loot))
		return;
	local loot = Loot[index];
	if (loot.ent != null && loot.ent.IsValid())
		return;
	delete Loot[index];
	local ent = SpawnEntityFromTable("prop_dynamic_override", { model = loot.model, origin = loot.pos - Vector(0, 0, LootDrop),
		angles = loot.angles, solid = 6 });
	if (ent == null)
		return;
	loot.ent = ent;
	Loot[ent.GetEntityIndex()] <- loot;
}

function Fort::LootTick(now) {
	foreach (index, loot in clone Loot)
		if (!loot.ent.IsValid())
			delete Loot[index];
	foreach (index, ent in clone Held)
		if (ent == null || !ent.IsValid())
			delete Held[index];
}

function Fort::OnGameEvent_weapon_drop(params) {
	if (Phase == "off" || !("propid" in params))
		return;
	local ent = EntIndexToHScript(params.propid);
	if (ent != null && ent.IsValid())
		Held[params.propid] <- ent;
}

function Fort::Strip(p, everything) {
	local inv = {};
	try { GetInvTable(p, inv); } catch (e) { return; }
	foreach (slot, w in inv) {
		if (w == null || !w.IsValid())
			continue;
		if (!everything && slot != "slot0")
			continue;
		w.Kill();
	}
}

function Fort::StripAll(everything) {
	foreach (p in Survivors())
		Strip(p, everything);
}

function Fort::StripStart(generation) {
	if (generation != Generation || !Building())
		return;
	StripAll(true);
	foreach (p in Survivors())
		Arm2(p);
}

function Fort::MeleeName(w) {
	local name = "";
	try { name = NetProps.GetPropString(w, "m_strMapSetScriptName").tolower(); } catch (e) {}
	return name;
}

function Fort::Arm2(p) {
	local inv = {};
	try { GetInvTable(p, inv); } catch (e) { return; }
	local w = ("slot1" in inv) ? inv.slot1 : null;
	if (w != null && w.IsValid() && w.GetClassname() == "weapon_melee" && MeleeName(w) == Axe[0])
		return;
	if (w != null && w.IsValid())
		w.Kill();
	foreach (melee in Axe) {
		try { p.GiveItem(melee); } catch (e) { continue; }
		local now = {};
		try { GetInvTable(p, now); } catch (e) {}
		if (("slot1" in now) && now.slot1 != null && now.slot1.IsValid())
			return;
	}
}

function Fort::AxeAll() {
	foreach (p in Survivors()) {
		local id = p.GetPlayerUserId();
		if ((id in Players) && Players[id].buildMode)
			continue;
		local inv = {};
		try { GetInvTable(p, inv); } catch (e) { continue; }
		local w = ("slot1" in inv) ? inv.slot1 : null;
		if (w == null || !w.IsValid() || w.GetClassname() != "weapon_melee")
			try { Arm2(p); } catch (e) { Log("axe failed for " + p.GetPlayerName() + ": " + e); }
	}
}

function Fort::Arm(p) {
	local gun = WaveWeapons[RandomInt(0, WaveWeapons.len() - 1)];
	try { p.GiveItem(gun); } catch (e) { Log("could not give " + gun + ": " + e); return; }
	DoEntFire("!self", "RunScriptCode", "::Fort.Laser(" + p.GetPlayerUserId() + ")", 0.1, null, Entities.First());
}

function Fort::Laser(userid) {
	local p = null;
	try { p = GetPlayerFromUserID(userid); } catch (e) { return; }
	if (p == null || !p.IsValid())
		return;
	local inv = {};
	try { GetInvTable(p, inv); } catch (e) { return; }
	if (!("slot0" in inv) || inv.slot0 == null || !inv.slot0.IsValid())
		return;
	try {
		local bits = NetProps.GetPropInt(inv.slot0, "m_upgradeBitVec");
		NetProps.SetPropInt(inv.slot0, "m_upgradeBitVec", bits | LaserBit);
	} catch (e) {}
}

function Fort::PieceOf(ent) {
	if (ent == null || !ent.IsValid())
		return null;
	local index = ent.GetEntityIndex();
	if ((index in Pieces) && Pieces[index].ent == ent)
		return Pieces[index];
	if ((index in Parts) && Parts[index].ent == ent) {
		local piece = Parts[index].piece;
		foreach (i, pc in Pieces)
			if (pc == piece)
				return piece;
	}
	return null;
}

function Fort::AimedPiece(p, tr) {
	local piece = PieceOf(Hit(tr));
	if (piece != null)
		return piece;
	local best = null;
	local bestAlong = BuildRange;
	foreach (index, pc in Pieces) {
		if (!pc.ent.IsValid())
			continue;
		local r = OffRay(p, pc.pos + Vector(0, 0, 16));
		local reach = pc.radius * 0.5;
		if (reach < 16.0) reach = 16.0;
		if (reach > 48.0) reach = 48.0;
		if (r.off <= reach && r.along < bestAlong) {
			best = pc;
			bestAlong = r.along;
		}
	}
	return best;
}

function Fort::AimedSupply(p) {
	local best = null;
	local bestAlong = BuildRange;
	foreach (index, s in Supplies) {
		if (!s.ent.IsValid())
			continue;
		local r = OffRay(p, s.ent.GetOrigin());
		if (r.off <= ItemPick && r.along < bestAlong) {
			best = s;
			bestAlong = r.along;
		}
	}
	return best;
}

function Fort::Structures() {
	return Pieces.len();
}

function Fort::Items() {
	foreach (index, s in clone Supplies)
		if (!s.ent.IsValid())
			delete Supplies[index];
	return Supplies.len();
}

function Fort::Spot(p, tr) {
	local pos = tr.pos;
	if (("hit" in tr) && tr.hit)
		pos = pos - p.EyeAngles().Forward() * 16.0;
	local down = { start = pos + Vector(0, 0, 8), end = pos - Vector(0, 0, FloorProbe), ignore = p };
	TraceLine(down);
	if (!("hit" in down) || !down.hit || !("pos" in down))
		return null;
	if (("enthit" in down) && down.enthit != null && down.enthit.IsValid() && down.enthit.GetClassname() == "player")
		return null;
	return down.pos;
}

function Fort::Solid(bp) {
	return bp.kind == "wall" || bp.kind == "fire" || bp.kind == "light" || bp.kind == "gun" || bp.kind == "floor" || bp.kind == "struct";
}

function Fort::CanPlace(bp, pos) {
	if (bp.kind == "item")
		return Items() < MaxItems;
	if (Structures() >= MaxPieces)
		return false;
	if (!Solid(bp) || bp.kind == "floor" || bp.kind == "struct")
		return true;
	foreach (s in Survivors()) {
		local d = s.GetOrigin() - pos;
		if (Vector(d.x, d.y, 0).Length() < Clearance && fabs(d.z) < 80.0)
			return false;
	}
	return true;
}

function Fort::HideGhost(st) {
	if (st.ghost != null && st.ghost.IsValid())
		st.ghost.Kill();
	foreach (g in st.ghostParts)
		if (g != null && g.IsValid())
			g.Kill();
	st.ghostParts = [];
	st.ghost = null;
	st.ghostModel = "";
	st.ghostColor = "";
}

function Fort::GhostEnt(model, origin, angles, color) {
	local g = SpawnEntityFromTable("prop_dynamic_override", { model = model, origin = origin, angles = AnglesText(angles),
		solid = 0, rendermode = 1, renderamt = GhostAlpha, rendercolor = color, disableshadows = 1, targetname = FORT_GHOST_NAME });
	if (g != null)
		DoEntFire("!self", "DisableCollision", "", 0, null, g);
	return g;
}

function Fort::ShowGhost(st, bp, origins, angles, ok) {
	local color = ok ? GhostOk : GhostNo;
	local want = origins.len() - 1;
	if (st.ghost == null || !st.ghost.IsValid() || st.ghostModel != bp.model || st.ghostParts.len() != want) {
		HideGhost(st);
		st.ghost = GhostEnt(bp.model, origins[0], angles, color);
		st.ghostModel = bp.model;
		st.ghostColor = color;
		if (st.ghost == null)
			return;
		Learn(bp, st.ghost);
		for (local i = 0; i < want; i++) {
			local g = GhostEnt(bp.model, origins[i + 1], angles, color);
			if (g != null)
				st.ghostParts.append(g);
		}
	}
	st.ghost.SetOrigin(origins[0]);
	st.ghost.SetAngles(angles);
	foreach (i, g in st.ghostParts)
		if (g.IsValid() && i + 1 < origins.len()) {
			g.SetOrigin(origins[i + 1]);
			g.SetAngles(angles);
		}
	if (color != st.ghostColor) {
		st.ghostColor = color;
		DoEntFire("!self", "Color", color, 0, null, st.ghost);
		foreach (g in st.ghostParts)
			if (g.IsValid())
				DoEntFire("!self", "Color", color, 0, null, g);
	}
}

function Fort::Tint(piece) {
	local color = "255 255 255";
	foreach (stage in Stages)
		if (piece.health <= piece.max * stage.at)
			color = stage.color;
	return color;
}

function Fort::SetAim(st, piece) {
	if (st.aim == piece)
		return;
	ClearAim(st);
	st.aim = piece;
	if (piece != null && piece.ent.IsValid())
		DoEntFire("!self", "Color", AimColor, 0, null, piece.ent);
}

function Fort::ClearAim(st) {
	if (st.aim != null && st.aim.ent.IsValid())
		DoEntFire("!self", "Color", Tint(st.aim), 0, null, st.aim.ent);
	st.aim = null;
}

function Fort::List(cat) {
	local out = [];
	foreach (i, bp in Blueprints)
		if (bp.cat == cat)
			out.append(i);
	return out;
}

function Fort::Pick(st) {
	local list = List(Cats[st.cat]);
	if (list.len() == 0)
		return Blueprints[0];
	return Blueprints[list[st.pick[st.cat] % list.len()]];
}

function Fort::Cycle(p, st, step) {
	if (step == 0)
		st.cat = (st.cat + 1) % Cats.len();
	else {
		local n = List(Cats[st.cat]).len();
		st.pick[st.cat] = n > 0 ? (st.pick[st.cat] + step + n) % n : 0;
	}
	try { EmitSoundOnClient(Sounds.Cycle, p); } catch (e) {}
}

function Fort::Clipped(p, st, bp, plan) {
	if (bp.kind == "item")
		return false;
	local box = ("box" in bp) ? bp.box : null;
	if (box == null && st.ghost != null && st.ghost.IsValid() && st.ghostModel == bp.model) {
		try {
			local lo = st.ghost.GetBoundingMins(), hi = st.ghost.GetBoundingMaxs();
			box = [ lo.x, lo.y, lo.z, hi.x, hi.y, hi.z ];
		} catch (e) {}
	}
	if (box == null)
		return false;
	local key = bp.name + "@" + AnglesText(plan.angles);
	foreach (o in plan.origins)
		key += "@" + o.x.tointeger() + ":" + o.y.tointeger() + ":" + o.z.tointeger();
	if (key == st.clipKey)
		return st.clipBlocked;
	st.clipKey = key;
	st.clipBlocked = Blocked(p, box, plan.origins, plan.angles, Solid(bp), plan.grounded || plan.supports.len() > 0, ClipWorld);
	return st.clipBlocked;
}

function Fort::NoShove(p, on) {
	try { NetProps.SetPropFloat(p, "m_flNextShoveTime", on ? Time() + 3600.0 : Time()); } catch (e) {}
}

function Fort::Toggle(p, st) {
	st.buildMode = !st.buildMode;
	if (st.buildMode) {
		local inv = {};
		try { GetInvTable(p, inv); } catch (e) {}
		if (("slot1" in inv) && inv.slot1 != null && inv.slot1.IsValid())
			inv.slot1.Kill();
		NoShove(p, true);
	} else {
		NoShove(p, false);
		HideGhost(st);
		ClearAim(st);
		Unlook(st);
		Arm2(p);
	}
	try { EmitSoundOnClient(Sounds.Cycle, p); } catch (e) {}
}

function Fort::BuildTick(p, st, buttons, pressed) {
	local now = Time();
	if (pressed & ListKey)
		Cycle(p, st, 0);
	if (pressed & NextKey) {
		st.nextAt = now;
		st.nextUsed = false;
	}
	if (pressed & PrevKey) {
		st.prevAt = now;
		st.prevUsed = false;
	}
	local nextDown = (NextKey in st.down) && st.down[NextKey] >= 0;
	local prevDown = (PrevKey in st.down) && st.down[PrevKey] >= 0;
	if (!nextDown && st.nextWas && !st.nextUsed)
		Cycle(p, st, 1);
	if (!prevDown && st.prevWas && !st.prevUsed)
		Cycle(p, st, -1);
	st.nextWas = nextDown;
	st.prevWas = prevDown;
	local repairing = nextDown && now - st.nextAt >= TapTime;
	local taking = prevDown && now - st.prevAt >= TapTime && !st.prevUsed;
	local hands = null;
	try { hands = p.GetActiveWeapon(); } catch (e) {}
	if (hands != null && hands.IsValid())
		try {
			NetProps.SetPropFloat(hands, "m_flNextPrimaryAttack", now + HandsLock);
			NetProps.SetPropFloat(hands, "m_flNextSecondaryAttack", now + HandsLock);
		} catch (e) {}
	try {
		if (now >= NetProps.GetPropFloat(p, "m_flNextShoveTime") - 60.0)
			NoShove(p, true);
	} catch (e) {}

	local tr = Aim(p, BuildRange);
	local piece = AimedPiece(p, tr);
	if (piece != null) {
		Unlook(st);
		SetAim(st, piece);
		st.value = (piece.bp.cost * Refund * piece.health / piece.max + 0.5).tointeger();
		if (taking) {
			st.prevUsed = true;
			HideGhost(st);
			Remove(p, st, piece);
			return;
		}
		if (repairing) {
			st.nextUsed = true;
			HideGhost(st);
			Repair(p, st, piece, now);
			return;
		}
	} else {
		ClearAim(st);
		local supply = AimedSupply(p);
		if (supply != null) {
			Look(st, supply.ent, supply.bp.cost);
			if (taking) {
				st.prevUsed = true;
				HideGhost(st);
				TakeSupply(p, st, supply);
				return;
			}
		} else
			Unlook(st);
	}

	local bp = Pick(st);
	local plan = Plan(p, st, bp, tr, piece);
	st.spotOk = plan != null && !("taken" in plan) && CanPlace(bp, plan.pos) && !Clipped(p, st, bp, plan);
	local ok = st.spotOk && Scrap >= bp.cost;
	if (plan != null)
		ShowGhost(st, bp, plan.origins, plan.angles, ok);
	else
		ShowGhost(st, bp, [ tr.pos ], QAngle(0, GridYaw(p, st), 0), false);
	if (!(pressed & PlaceKey))
		return;
	if (now - st.placedAt < PlaceGap)
		return;
	if (!ok) {
		EmitSoundOn(Sounds.Deny, p);
		return;
	}
	st.placedAt = now;
	Place(p, bp, plan);
}

function Fort::AnglesText(a) {
	return a.x + " " + a.y + " " + a.z;
}

function Fort::Basis(a) {
	local r = 0.0174533;
	local sp = sin(a.x * r), cp = cos(a.x * r);
	local sy = sin(a.y * r), cy = cos(a.y * r);
	local sr = sin(a.z * r), cr = cos(a.z * r);
	local right = Vector(-sr * sp * cy + cr * sy, -sr * sp * sy - cr * cy, -sr * cp);
	return { f = Vector(cp * cy, cp * sy, -sp), l = right * -1.0, u = Vector(cr * sp * cy + sr * sy, cr * sp * sy - sr * cy, cr * cp) };
}

function Fort::Local(b, v) {
	return b.f * v.x + b.l * v.y + b.u * v.z;
}

function Fort::Facing(p, st = null) {
	local face = p.EyeAngles().y;
	local yaw = ((face / 90.0 + (face < 0.0 ? -0.5 : 0.5)).tointeger() * 90) % 360;
	if (yaw < 0)
		yaw += 360;
	if (st != null) {
		if (st.faceYaw != null) {
			local off = face - st.faceYaw;
			while (off > 180.0) off -= 360.0;
			while (off < -180.0) off += 360.0;
			if (fabs(off) <= FaceHold)
				yaw = st.faceYaw;
		}
		st.faceYaw = yaw;
	}
	local dirs = { [0] = Vector(1, 0, 0), [90] = Vector(0, 1, 0), [180] = Vector(-1, 0, 0), [270] = Vector(0, -1, 0) };
	return { yaw = yaw.tofloat(), dir = dirs[yaw] };
}

function Fort::GridYaw(p, st) {
	local face = p.EyeAngles().y;
	local step = PropStep.tofloat();
	local yaw = ((face / step + (face < 0.0 ? -0.5 : 0.5)).tointeger() * PropStep) % 360;
	if (yaw < 0)
		yaw += 360;
	if (st.propYaw != null) {
		local off = face - st.propYaw;
		while (off > 180.0) off -= 360.0;
		while (off < -180.0) off += 360.0;
		if (fabs(off) <= PropHold)
			yaw = st.propYaw;
	}
	st.propYaw = yaw;
	return yaw.tofloat();
}

function Fort::Surface(p, x, y) {
	local eye = p.EyePosition();
	local down = { start = Vector(x, y, eye.z + BuildAbove), end = Vector(x, y, eye.z - BuildBelow), ignore = p };
	TraceLine(down);
	if (("startsolid" in down) && down.startsolid)
		return null;
	if (!("hit" in down) || !down.hit || !("pos" in down))
		return null;
	local under = ("enthit" in down) ? down.enthit : null;
	if (under != null && under.IsValid() && under.GetClassname() == "player")
		return null;
	local piece = PieceOf(under);
	return { z = down.pos.z, under = piece, grounded = piece == null };
}

function Fort::Plan(p, st, bp, tr, piece) {
	if (bp.kind == "struct")
		return StructPlan(p, st, bp, tr, piece);
	local g = GridSpot(p, st, bp, tr, piece);
	if (g == null)
		return null;
	local key = bp.kind + ":" + g.pos.x.tointeger() + ":" + g.pos.y.tointeger() + ":" + (g.pos.z / 8.0).tointeger();
	return { origins = Origins(bp, g.pos, g.yaw), angles = QAngle(0, g.yaw, 0), pos = g.pos, yaw = g.yaw,
	         spot = bp.kind + ":" + g.pos.x.tointeger() + ":" + g.pos.y.tointeger(), supports = g.support != null ? [ g.support ] : [], grounded = g.support == null, key = key, slot = null };
}

function Fort::SlotZ(z) {
	return (z / 8.0 + (z < 0.0 ? -0.5 : 0.5)).tointeger();
}

function Fort::WallKey(x, y, z) {
	return "W:" + (x + 0.5).tointeger() + ":" + (y + 0.5).tointeger() + ":" + SlotZ(z);
}

function Fort::FloorKey(ix, iy, z) {
	return "F:" + ix + ":" + iy + ":" + SlotZ(z);
}

function Fort::Slotted(key) {
	if (!(key in Slots))
		return null;
	local pc = Slots[key];
	foreach (i, q in Pieces)
		if (q == pc)
			return pc;
	delete Slots[key];
	return null;
}

function Fort::StructPlan(p, st, bp, tr, piece) {
	local face = Facing(p, st);
	local d = face.dir;
	local yaw = face.yaw;
	local sc = StructCell, sh = StructHeight;
	local shape = bp.shape;
	local feet = p.GetOrigin();
	local pitch = p.EyeAngles().x;

	local ox = floor(feet.x / sc).tointeger(), oy = floor(feet.y / sc).tointeger();
	if (st.cellX != null && feet.x >= st.cellX * sc - CellHold && feet.x <= (st.cellX + 1) * sc + CellHold
	    && feet.y >= st.cellY * sc - CellHold && feet.y <= (st.cellY + 1) * sc + CellHold) {
		ox = st.cellX;
		oy = st.cellY;
	}
	st.cellX = ox;
	st.cellY = oy;
	local dx = d.x.tointeger(), dy = d.y.tointeger();
	local down = DownPitch - (st.lastOwn ? LevelHold : 0.0);
	local own = (shape == "floor" || shape == "roof") && pitch >= down;
	if (shape == "floor" || shape == "roof")
		st.lastOwn = own;
	local ix = own ? ox : ox + dx, iy = own ? oy : oy + dy;
	local cx = (ix + 0.5) * sc, cy = (iy + 0.5) * sc;
	local spot = Vector(cx, cy, 0);
	local wa = 0, wb = 0;
	if (shape == "wall") {
		local sign = dx != 0 ? dx : dy;
		local q = (dx != 0 ? feet.x : feet.y) * sign + WallGap;
		local at = ((floor(q / sc).tointeger() + 1) * sign).tofloat() * sc;
		spot = dx != 0 ? Vector(at, (oy + 0.5) * sc, 0) : Vector((ox + 0.5) * sc, at, 0);
		wa = floor(at / sc + 0.5).tointeger();
		wb = wa - 1;
	}

	local z = feet.z, under = Standing(p), grounded = false;
	local surf = Surface(p, spot.x, spot.y);
	if (under != null && ("shape" in under.bp)) {
		z = under.pos.z;
		if (under.bp.shape == "wall" || (under.bp.shape == "stairs" && feet.z > z + sh * 0.5))
			z += sh;
	} else if (surf != null && fabs(surf.z - feet.z) <= FloorDrop) {
		z = surf.z;
		under = surf.under;
		grounded = surf.grounded;
	}
	local level = 0;
	if (!own && shape != "stairs") {
		foreach (i, up in LevelPitch)
			if (pitch <= up + (st.lastLevel > i ? LevelHold : -LevelHold))
				level++;
		st.lastLevel = level;
	}
	if (shape == "roof")
		level++;
	local Z = z + level * sh;
	if (level > 0) {
		under = null;
		grounded = false;
	}

	local tile = !("normal" in bp) || bp.normal == "z";
	local box = ("box" in bp) ? bp.box : [ 0, 0, 0, 0, 0, 0 ];
	local mid = Vector((box[0] + box[3]) * 0.5, (box[1] + box[4]) * 0.5, (box[2] + box[5]) * 0.5);
	local thick = tile ? box[5] - box[2] : box[3] - box[0];
	local supports = [];
	if (under != null)
		supports.append(under);
	local plan = { yaw = yaw, grounded = grounded, supports = supports, key = "", slot = null, radius = sc * 0.5 };
	local key = "";
	local angles = null;
	local centres = [];
	if (shape == "wall" && ("door" in bp)) {
		key = WallKey(spot.x, spot.y, Z);
		angles = QAngle(0, yaw, 0);
		local left = Basis(angles).l;
		local foot = Vector(spot.x, spot.y, Z);
		local half = DoorWidth * 0.5;
		centres.append(foot - left * half + Vector(0, 0, 54.6));
		local parts = [];
		foreach (lat in [ -sc * 0.5 + 11.5, -half - 11.5, half + 11.5, sc * 0.5 - 11.5 ])
			parts.append({ model = Board, origin = foot + left * lat + Vector(0, 0, sh * 0.5), angles = angles });
		parts.append({ model = Board, origin = foot + Vector(0, 0, 119.5), angles = QAngle(0, yaw, 90) });
		plan.parts <- parts;
		local below = Slotted(WallKey(spot.x, spot.y, Z - sh));
		if (below != null)
			supports.append(below);
		plan.pos <- Vector(spot.x, spot.y, Z);
		plan.top <- Z + sh;
		plan.origins <- centres;
		plan.angles <- angles;
		if (Slotted(key) != null)
			plan.taken <- true;
		plan.key = key;
		plan.slot = key;
		return plan;
	} else if (shape == "wall") {
		key = WallKey(spot.x, spot.y, Z);
		angles = tile ? QAngle(90, yaw, 0) : QAngle(0, yaw, 0);
		centres.append(Vector(spot.x, spot.y, Z + sh * 0.5));
		local below = Slotted(WallKey(spot.x, spot.y, Z - sh));
		if (below != null)
			supports.append(below);
		local fa = dx != 0 ? FloorKey(wa, oy, Z) : FloorKey(ox, wa, Z);
		local fb = dx != 0 ? FloorKey(wb, oy, Z) : FloorKey(ox, wb, Z);
		foreach (k in [ fa, fb ]) {
			local fl = Slotted(k);
			if (fl != null)
				supports.append(fl);
		}
		plan.pos <- Vector(spot.x, spot.y, Z);
		plan.top <- Z + sh;
	} else if (shape == "floor" || shape == "roof") {
		key = FloorKey(ix, iy, Z);
		angles = tile ? QAngle(0, yaw, 0) : QAngle(90, yaw, 0);
		centres.append(Vector(cx, cy, Z - thick * 0.5));
		foreach (e in [ Vector(1, 0, 0), Vector(-1, 0, 0), Vector(0, 1, 0), Vector(0, -1, 0) ]) {
			local wall = Slotted(WallKey(cx + e.x * sc * 0.5, cy + e.y * sc * 0.5, Z - sh));
			if (wall != null)
				supports.append(wall);
			local next = Slotted(FloorKey(ix + e.x.tointeger(), iy + e.y.tointeger(), Z));
			if (next != null)
				supports.append(next);
		}
		plan.pos <- Vector(cx, cy, Z);
		plan.top <- Z;
	} else {
		key = "S:" + ix + ":" + iy + ":" + SlotZ(Z);
		angles = tile ? QAngle(-StairPitch, yaw, 0) : QAngle(StairPitch, yaw, 0);
		local r = 0.7071;
		local slope = Vector(d.x * r, d.y * r, r);
		local up = Vector(-d.x * r, -d.y * r, r);
		local foot = Vector(cx - d.x * sc * 0.5, cy - d.y * sc * 0.5, Z);
		local run = sqrt(sc * sc + sh * sh);
		local half = (tile ? box[3] - box[0] : box[5] - box[2]) * 0.5;
		centres.append(foot + slope * half - up * (thick * 0.5));
		centres.append(foot + slope * (run - half) - up * (thick * 0.5 + 0.5));
		foreach (k in [ FloorKey(ix, iy, Z), FloorKey(ix + dx, iy + dy, Z + sh) ]) {
			local fl = Slotted(k);
			if (fl != null && supports.find(fl) == null)
				supports.append(fl);
		}
		plan.pos <- Vector(cx, cy, Z);
		plan.top <- Z + sh;
	}
	local b = Basis(angles);
	plan.origins <- [];
	foreach (c in centres)
		plan.origins.append(c - Local(b, mid));
	plan.angles <- angles;
	if (Slotted(key) != null)
		plan.taken <- true;
	plan.key = key;
	plan.slot = key;
	return plan;
}

function Fort::Blocked(p, box, origins, angles, solid, low, world) {
	local b = Basis(angles);
	local axes = [ b.f, b.l, b.u ];
	local lo = [ box[0], box[1], box[2] ], hi = [ box[3], box[4], box[5] ];
	foreach (o in origins) {
		if (solid) {
			local centre = o + Local(b, Vector((lo[0] + hi[0]) * 0.5, (lo[1] + hi[1]) * 0.5, (lo[2] + hi[2]) * 0.5));
			foreach (s in Survivors()) {
				local v = s.GetOrigin() + Vector(0, 0, 45) - centre;
				local apart = false;
				foreach (i, ax in axes) {
					local reach = (hi[i] - lo[i]) * 0.5 + 16.0 * (fabs(ax.x) + fabs(ax.y)) + 27.0 * fabs(ax.z) - 2.0;
					if (fabs(v.Dot(ax)) > reach) {
						apart = true;
						break;
					}
				}
				if (!apart)
					return true;
			}
		}
		if (!world)
			continue;
		local a = [], z = [];
		for (local i = 0; i < 3; i++) {
			local m = (lo[i] + hi[i]) * 0.5;
			local h = (hi[i] - lo[i]) * 0.5 - ClipMargin;
			if (h < 0.0)
				h = 0.0;
			a.append(m - h);
			z.append(m + h);
		}
		local corners = [];
		for (local c = 0; c < 8; c++)
			corners.append(o + Local(b, Vector((c & 1) ? z[0] : a[0], (c & 2) ? z[1] : a[1], (c & 4) ? z[2] : a[2])));
		if (low) {
			local floorZ = corners[0].z, topZ = corners[0].z;
			foreach (c in corners) {
				if (c.z < floorZ) floorZ = c.z;
				if (c.z > topZ) topZ = c.z;
			}
			local lift = floorZ + ClipGround < topZ ? floorZ + ClipGround : topZ;
			foreach (i, c in corners)
				if (c.z < lift)
					corners[i] = Vector(c.x, c.y, lift);
		}
		local lines = [ [0, 1], [2, 3], [4, 5], [6, 7], [0, 2], [1, 3], [4, 6], [5, 7], [0, 4], [1, 5], [2, 6], [3, 7],
		                [0, 7], [1, 6], [2, 5], [3, 4] ];
		foreach (l in lines) {
			local from = corners[l[0]], to = corners[l[1]];
			if ((to - from).Length() < 1.0)
				continue;
			local dir = to - from;
			dir.Norm();
			for (local k = 0; k < 6; k++) {
				local tr = { start = from, end = to, ignore = p, clip = true };
				TraceLine(tr);
				if (!("hit" in tr) || !tr.hit)
					break;
				local pc = ("enthit" in tr) ? PieceOf(tr.enthit) : null;
				if (pc == null || pc.bp.kind != "struct")
					return true;
				from = (("pos" in tr) ? tr.pos : from) + dir * 2.0;
				if ((to - from).Dot(dir) <= 0.0)
					break;
			}
		}
	}
	return false;
}

function Fort::Dims(bp) {
	if ("size" in bp)
		return { sx = bp.size[0], sy = bp.size[1] };
	if (bp.model in Sizes)
		return Sizes[bp.model];
	return { sx = Cell, sy = Cell };
}

function Fort::Learn(bp, ent) {
	if (bp.model in Sizes || bp.kind == "struct")
		return;
	try {
		local lo = ent.GetBoundingMins();
		local hi = ent.GetBoundingMaxs();
		if (hi.x - lo.x > 0.5 && hi.y - lo.y > 0.5)
			Sizes[bp.model] <- { sx = hi.x - lo.x, sy = hi.y - lo.y, cx = (hi.x + lo.x) * 0.5, cy = (hi.y + lo.y) * 0.5, known = true };
	} catch (e) {}
}

function Fort::Origins(bp, pos, yaw) {
	if (!("parts" in bp))
		return [ Anchor(bp, pos, yaw) ];
	local r = yaw * 0.0174533;
	local out = [];
	foreach (part in bp.parts) {
		local at = pos + Vector(part[0] * cos(r) - part[1] * sin(r), part[0] * sin(r) + part[1] * cos(r), 0);
		out.append(Anchor(bp, at, yaw));
	}
	return out;
}

function Fort::Cells(size) {
	local n = (size / Cell + 0.5).tointeger();
	return n < 1 ? 1 : (n > MaxCells ? MaxCells : n);
}

function Fort::Snap(v) {
	return floor(v / Cell).tointeger();
}

function Fort::GridSpot(p, st, bp, tr, piece) {
	local yaw = GridYaw(p, st);
	local d = Dims(bp);
	local sx = d.sx, sy = d.sy;
	if ((yaw.tointeger() / 90) % 2 == 1) {
		local t = sx; sx = sy; sy = t;
	}
	local w = Cells(sx), h = Cells(sy);
	if (yaw.tointeger() % 90 != 0) {
		w = Cells((d.sx + d.sy) * 0.7071);
		h = w;
	}
	local aim = tr.pos;
	if (piece != null && Hit(tr) == piece.ent && aim.z < piece.top - SideBelow) {
		local back = p.EyeAngles().Forward();
		back = Vector(back.x, back.y, 0);
		if (back.Length() > 0.01)
			back.Norm();
		aim = aim - back * (Cell * 0.5);
	}
	local feet = p.GetOrigin();
	local reach = bp.kind == "floor" ? FloorReach : BuildRange;
	local out = Vector(aim.x - feet.x, aim.y - feet.y, 0);
	if (out.Length() > reach)
		aim = Vector(feet.x, feet.y, aim.z) + out * (reach / out.Length());
	local x0 = Snap(aim.x) - (w - 1) / 2;
	local y0 = Snap(aim.y) - (h - 1) / 2;
	local cx = (x0 + w * 0.5) * Cell;
	local cy = (y0 + h * 0.5) * Cell;
	local surf = Surface(p, cx, cy);
	if (surf == null)
		return null;
	local z = surf.z;
	local support = surf.under;
	if (bp.kind == "floor" && z < feet.z - FloorDrop) {
		z = feet.z - 1.0;
		support = Standing(p);
	}
	return { pos = Vector(cx, cy, z), yaw = yaw, support = support };
}

function Fort::Anchor(bp, pos, yaw) {
	local ox = 0.0, oy = 0.0;
	if (bp.model in Sizes) {
		ox = Sizes[bp.model].cx; oy = Sizes[bp.model].cy;
	} else if ("offset" in bp) {
		ox = bp.offset[0]; oy = bp.offset[1];
	}
	if (ox == 0.0 && oy == 0.0)
		return pos;
	local r = yaw * 0.0174533;
	return pos - Vector(ox * cos(r) - oy * sin(r), ox * sin(r) + oy * cos(r), 0);
}

function Fort::Standing(p) {
	local ground = null;
	try { ground = NetProps.GetPropEntity(p, "m_hGroundEntity"); } catch (e) {}
	local piece = PieceOf(ground);
	if (piece != null)
		return piece;
	local feet = p.GetOrigin();
	local tr = { start = feet + Vector(0, 0, 4), end = feet - Vector(0, 0, StandProbe), ignore = p };
	TraceLine(tr);
	if (("hit" in tr) && tr.hit && ("enthit" in tr))
		return PieceOf(tr.enthit);
	return null;
}

function Fort::Place(p, bp, plan) {
	local angles = AnglesText(plan.angles);
	local origins = plan.origins;
	local origin = origins[0];
	local pos = plan.pos;
	local ent = null;
	if (bp.kind == "item") {
		ent = SpawnEntityFromTable(bp.classname, { origin = pos + Vector(0, 0, 2), angles = angles, count = 1, model = bp.model,
			solid = 6, targetname = FORT_ITEM_NAME });
		if (ent == null) {
			EmitSoundOn(Sounds.Deny, p);
			Log(bp.name + " did not spawn");
			return;
		}
		Supplies[ent.GetEntityIndex()] <- { ent = ent, bp = bp };
	} else {
		if ("door" in bp)
			ent = SpawnEntityFromTable("prop_door_rotating", { model = bp.model, origin = origin, angles = angles,
				spawnflags = 8192, speed = 200, distance = 90, opendir = 0, returndelay = -1, forceclosed = 0,
				hardware = 1, health = 0, spawnpos = 0, disableshadows = 1, targetname = FORT_PIECE_NAME });
		else if (bp.kind == "gun")
			ent = SpawnEntityFromTable(bp.classname, { model = bp.model, origin = origin, angles = angles, targetname = FORT_PIECE_NAME,
				MaxYaw = "90", MinPitch = "-30", MaxPitch = "50" });
		else if (Breakable && Solid(bp)) {
			ent = SpawnEntityFromTable("prop_physics_override", { model = bp.model, origin = origin, angles = angles,
				spawnflags = 8, health = PropHealth, nodamageforces = 1, targetname = FORT_PIECE_NAME });
			if (ent != null && !ent.IsValid())
				ent = null;
			if (ent == null)
				Log(bp.name + ": no physics model, unbreakable");
		}
		if (ent == null && bp.kind != "gun" && !("door" in bp))
			ent = SpawnEntityFromTable("prop_dynamic_override", { model = bp.model, origin = origin, angles = angles,
				solid = Solid(bp) ? 6 : 0, targetname = FORT_PIECE_NAME });
		if (ent == null) {
			EmitSoundOn(Sounds.Deny, p);
			Log(bp.name + " did not spawn");
			return;
		}
		local piece = { ent = ent, bp = bp, kind = bp.kind, health = bp.health.tofloat(), max = bp.health.tofloat(),
		                pos = pos, radius = ("radius" in plan) ? plan.radius : Radius(ent), stage = 0, trapAt = 0.0, wrecked = false,
		                fx = [], angles = angles, supports = plan.supports, grounded = plan.grounded, slot = plan.slot,
		                top = ("top" in plan) ? plan.top : Top(ent, origin, pos), yaw = plan.yaw.tofloat(), origin = origin };
		if (plan.slot != null)
			Slots[plan.slot] <- piece;
		if (ent.GetClassname() == "prop_physics_override")
			DoEntFire("!self", "RunScriptCode", "::Fort.Recheck(" + ent.GetEntityIndex() + ")", 0.1, null, Entities.First());
		if ("parts" in plan)
			foreach (pt in plan.parts) {
				local part = SpawnEntityFromTable("prop_dynamic_override", { model = pt.model, origin = pt.origin,
					angles = AnglesText(pt.angles), solid = 6, targetname = FORT_PIECE_NAME });
				if (part != null) {
					piece.fx.append(part);
					Parts[part.GetEntityIndex()] <- { ent = part, piece = piece };
				}
			}
		for (local i = 1; i < origins.len(); i++) {
			local part = SpawnEntityFromTable("prop_dynamic_override", { model = bp.model, origin = origins[i], angles = angles,
				solid = 6, targetname = FORT_PIECE_NAME });
			if (part != null) {
				piece.fx.append(part);
				Parts[part.GetEntityIndex()] <- { ent = part, piece = piece };
			}
		}
		if (bp.kind == "fire") {
			local fire = Particle(FireEffect, pos + Vector(0, 0, 8), 0.0);
			if (fire != null)
				piece.fx.append(fire);
		} else if (bp.kind == "light") {
			local light = SpawnEntityFromTable("light_dynamic", { origin = pos + Vector(0, 0, LightHeight), _light = LightColor,
				brightness = 3, distance = LightDistance, spotlight_radius = 0, style = 0 });
			if (light != null) {
				DoEntFire("!self", "TurnOn", "", 0, null, light);
				piece.fx.append(light);
			}
		}
		Pieces[ent.GetEntityIndex()] <- piece;
		Drop(piece);
	}
	Scrap -= bp.cost;
	Particle(Dust, pos, 1.0);
	SoundAt(Sounds.Place, pos);
	Mark(p, "hit_head");
}

function Fort::Recheck(index) {
	if (!(index in Pieces))
		return;
	local piece = Pieces[index];
	if (piece.ent != null && piece.ent.IsValid())
		return;
	delete Pieces[index];
	local ent = SpawnEntityFromTable("prop_dynamic_override", { model = piece.bp.model, origin = piece.origin, angles = piece.angles,
		solid = 6, targetname = FORT_PIECE_NAME });
	if (ent == null) {
		Unfx(piece);
		Unslot(piece);
		AddScrap(piece.bp.cost);
		Log(piece.bp.name + " failed, refunded");
		return;
	}
	piece.ent = ent;
	Pieces[ent.GetEntityIndex()] <- piece;
	Log(piece.bp.name + ": no physics model, unbreakable");
}

function Fort::Top(ent, origin, pos) {
	local top = pos.z + 48.0;
	try {
		local hi = ent.GetBoundingMaxs();
		if (hi.z > 0.5)
			top = origin.z + hi.z;
	} catch (e) {}
	local tr = { start = Vector(pos.x, pos.y, top + 64.0), end = Vector(pos.x, pos.y, pos.z - 4.0) };
	try {
		TraceLine(tr);
		if (("hit" in tr) && tr.hit && ("enthit" in tr) && tr.enthit == ent && ("pos" in tr))
			top = tr.pos.z;
	} catch (e) {}
	return top;
}

function Fort::Unslot(piece) {
	if (piece.slot != null && (piece.slot in Slots) && Slots[piece.slot] == piece)
		delete Slots[piece.slot];
}

function Fort::Fall(gone, refund) {
	Unslot(gone);
	foreach (index, pc in clone Pieces) {
		if (!(index in Pieces))
			continue;
		local at = pc.supports.find(gone);
		if (at == null)
			continue;
		pc.supports.remove(at);
		if (pc.supports.len() > 0 || pc.grounded)
			continue;
		if (refund) {
			AddScrap((pc.bp.cost * Refund * pc.health / pc.max + 0.5).tointeger());
			Unfx(pc);
			if (pc.ent.IsValid())
				pc.ent.Kill();
			delete Pieces[index];
			Fall(pc, true);
		} else
			Break(index, pc);
	}
}

function Fort::Radius(ent) {
	try {
		local lo = ent.GetBoundingMins();
		local hi = ent.GetBoundingMaxs();
		local r = fabs(hi.x - lo.x) > fabs(hi.y - lo.y) ? fabs(hi.x - lo.x) : fabs(hi.y - lo.y);
		if (r > 8.0)
			return r * 0.5;
	} catch (e) {}
	return 48.0;
}

function Fort::Unfx(piece) {
	foreach (fx in piece.fx)
		if (fx != null && fx.IsValid())
			fx.Kill();
	piece.fx = [];
}

function Fort::Remove(p, st, piece) {
	local index = piece.ent.GetEntityIndex();
	local give = (piece.bp.cost * Refund * piece.health / piece.max + 0.5).tointeger();
	st.aim = null;
	st.value = -1;
	SoundAt(Sounds.Remove, piece.pos);
	Particle(Dust, piece.pos, 1.0);
	Unfx(piece);
	piece.ent.Kill();
	delete Pieces[index];
	AddScrap(give);
	Fall(piece, true);
}

function Fort::TakeSupply(p, st, supply) {
	local index = supply.ent.GetEntityIndex();
	local pos = supply.ent.GetOrigin();
	Unlook(st);
	supply.ent.Kill();
	delete Supplies[index];
	AddScrap(supply.bp.cost);
	SoundAt(Sounds.Remove, pos);
	Particle(Dust, pos, 1.0);
}

function Fort::Repair(p, st, piece, now) {
	if (piece.health >= piece.max || piece.kind == "mine")
		return;
	local dt = now - st.repairAt;
	st.repairAt = now;
	if (dt <= 0.0 || dt > 0.25)
		return;
	local heal = piece.max * RepairRate * dt;
	if (heal > piece.max - piece.health)
		heal = piece.max - piece.health;
	st.debt += piece.bp.cost * heal / piece.max;
	local pay = st.debt.tointeger();
	if (pay > Scrap) {
		EmitSoundOn(Sounds.Deny, p);
		st.debt = 0.0;
		return;
	}
	Scrap -= pay;
	st.debt -= pay;
	piece.health += heal;
	if (((now / TickEvery).tointeger() != ((now - dt) / TickEvery).tointeger())) {
		Sound(Sounds.Tick, piece.ent);
		Mark(p, "hit");
	}
	local stage = StageOf(piece);
	if (stage != piece.stage) {
		piece.stage = stage;
		DoEntFire("!self", "Color", AimColor, 0, null, piece.ent);
	}
}

function Fort::StageOf(piece) {
	local stage = 0;
	foreach (i, s in Stages)
		if (piece.health <= piece.max * s.at)
			stage = i + 1;
	return stage;
}

function Fort::Infected(pos, radius) {
	local out = { commons = [], specials = [], tanks = [] };
	local ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "infected", pos, radius)) != null)
		if (ent.GetHealth() > 0)
			out.commons.append(ent);
	ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "player", pos, radius)) != null) {
		if (NetProps.GetPropInt(ent, "m_iTeamNum") != FORT_TEAM_INFECTED || ent.IsDead() || ent.IsGhost())
			continue;
		if (ent.GetZombieType() == FORT_ZOMBIE_TANK)
			out.tanks.append(ent);
		else
			out.specials.append(ent);
	}
	return out;
}

function Fort::WearTick(now) {
	local dt = now - LastWear;
	if (dt < WearInterval)
		return;
	LastWear = now;
	if (dt > 1.0)
		dt = WearInterval;
	foreach (index, piece in clone Pieces) {
		if (!piece.ent.IsValid()) {
			Unfx(piece);
			delete Pieces[index];
			continue;
		}
		if (piece.wrecked) {
			Break(index, piece);
			continue;
		}
		if (piece.kind == "mine") {
			Mine(index, piece);
			continue;
		}
		local near = Infected(piece.pos, piece.radius + Reach);
		local dps = near.specials.len() * SpecialDps + near.tanks.len() * TankDps;
		if (piece.kind == "wire")
			Trap(piece, now, WireEvery, WireDamage, FORT_DMG_SLASH, WireWear, Blood, 0.0);
		else if (piece.kind == "fire") {
			Trap(piece, now, FireEvery, FireDamage, FORT_DMG_BURN, FireWear, null, Reach);
			dps += near.commons.len() * CommonDps;
		} else
			dps += near.commons.len() * CommonDps;
		if (dps > 0.0 && index in Pieces)
			Hurt(index, piece, dps * dt);
	}
}

function Fort::PieceHit(damageTable) {
	if (Phase == "off" || !("Victim" in damageTable) || !("DamageDone" in damageTable))
		return false;
	local victim = damageTable.Victim;
	if (victim == null || !victim.IsValid())
		return false;
	local index = victim.GetEntityIndex();
	local attacker = ("Attacker" in damageTable) ? damageTable.Attacker : null;
	if (Phase != "wave" && !(index in Pieces) && attacker != null && attacker.IsValid() && attacker.GetClassname() == "player"
	    && NetProps.GetPropInt(attacker, "m_iTeamNum") == 2 && Salvageable(victim))
		return true;
	if (!(index in Pieces) || Pieces[index].ent != victim)
		return false;
	local piece = Pieces[index];
	if (Phase == "wave" && Hostile(attacker) && damageTable.DamageDone > 0) {
		if (attacker.GetClassname() == "player" && attacker.GetZombieType() == 8) {
			local dir = attacker.EyeAngles().Forward();
			piece.push <- Vector(dir.x, dir.y, 0) * TankThrow + Vector(0, 0, TankThrow * 0.4);
		}
		Hurt(index, piece, damageTable.DamageDone * HitScale);
		if (index in Pieces && RandomInt(1, 3) == 1)
			Particle(Dust, piece.pos + Vector(0, 0, 32), 0.6);
	}
	return true;
}

function Fort::Hostile(ent) {
	if (ent == null || !ent.IsValid())
		return false;
	local cls = ent.GetClassname();
	if (cls == "infected" || cls == "witch" || cls == "tank_rock")
		return true;
	return cls == "player" && NetProps.GetPropInt(ent, "m_iTeamNum") == FORT_TEAM_INFECTED;
}

function Fort::Trap(piece, now, every, damage, type, wear, fx, reach) {
	if (now < piece.trapAt)
		return;
	piece.trapAt = now + every;
	local victims = [];
	local ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "infected", piece.pos, piece.radius + reach)) != null)
		if (ent.GetHealth() > 0)
			victims.append(ent);
	local cut = 0;
	foreach (z in victims) {
		if (!z.IsValid())
			continue;
		z.TakeDamage(damage, type, Entities.First());
		if (fx != null)
			Particle(fx, z.GetOrigin() + Vector(0, 0, 30), 0.5);
		cut++;
	}
	if (cut > 0)
		Hurt(piece.ent.GetEntityIndex(), piece, cut * wear);
}

function Fort::Mine(index, piece) {
	local near = Infected(piece.pos, MineReach);
	if (near.commons.len() + near.specials.len() + near.tanks.len() == 0)
		return;
	local hit = Infected(piece.pos, MineRadius);
	local world = Entities.First();
	foreach (z in hit.commons)
		if (z.IsValid())
			z.TakeDamage(MineDamage.common, FORT_DMG_BLAST, world);
	foreach (s in hit.specials)
		if (s.IsValid())
			s.TakeDamage(MineDamage.special, FORT_DMG_BLAST, world);
	foreach (t in hit.tanks)
		if (t.IsValid())
			t.TakeDamage(MineDamage.tank, FORT_DMG_BLAST, world);
	Particle(MineEffect, piece.pos + Vector(0, 0, 8), 2.0);
	SoundAt(Sounds.Mine, piece.pos);
	ScreenShake(piece.pos, 10.0, 40.0, 0.8, MineRadius * 3.0, 0, false);
	local push = SpawnEntityFromTable("env_physexplosion", { magnitude = "700", radius = MineRadius.tostring(), spawnflags = "1", origin = piece.pos });
	if (push != null) {
		DoEntFire("!self", "Explode", "", 0, null, push);
		DoEntFire("!self", "Kill", "", 0.1, null, push);
	}
	piece.ent.Kill();
	delete Pieces[index];
	Fall(piece, false);
}

function Fort::Drop(piece) {
	if (piece.kind == "gun")
		return;
	local ents = [ piece.ent ];
	foreach (fx in piece.fx)
		if (fx != null && fx.IsValid() && fx.GetClassname().find("prop_") == 0)
			ents.append(fx);
	local list = [];
	foreach (e in ents)
		if (e != null && e.IsValid()) {
			local to = e.GetOrigin();
			list.append({ ent = e, to = to });
			e.SetOrigin(to + Vector(0, 0, DropHeight));
		}
	piece.drop <- { start = Time(), ents = list };
	Dropping.append(piece);
}

function Fort::DropTick(now) {
	foreach (piece in clone Dropping) {
		local t = (now - piece.drop.start) / DropTime;
		local done = t >= 1.0;
		local h = done ? 0.0 : DropHeight * (1.0 - t * t);
		foreach (d in piece.drop.ents)
			if (d.ent.IsValid())
				d.ent.SetOrigin(d.to + Vector(0, 0, h));
		if (!done)
			continue;
		Dropping.remove(Dropping.find(piece));
		delete piece.drop;
		ScreenShake(piece.pos, 2.0, 20.0, 0.25, 220.0, 0, false);
		Particle(Dust, piece.pos, 0.8);
	}
}

function Fort::Loose(piece) {
	if (!Collapse || !Solid(piece.bp) || piece.kind == "gun")
		return;
	local push = ("push" in piece) ? piece.push : Vector(RandomFloat(-FallPush, FallPush), RandomFloat(-FallPush, FallPush), FallPush);
	local ents = [ piece.ent ];
	foreach (fx in piece.fx)
		if (fx != null && fx.IsValid() && fx.GetClassname().find("prop_") == 0)
			ents.append(fx);
	local now = Time();
	local shots = [];
	foreach (e in ents)
		if (e != null && e.IsValid()) {
			shots.append({ model = e.GetModelName(), origin = e.GetOrigin(), angles = e.GetAngles() });
			e.Kill();
		}
	foreach (shot in shots) {
		local d = SpawnEntityFromTable("prop_physics_override", { model = shot.model, origin = shot.origin,
			angles = AnglesText(shot.angles), targetname = FORT_DEBRIS_NAME, nodamageforces = 0 });
		if (d == null || !d.IsValid())
			continue;
		try { d.ApplyAbsVelocityImpulse(push); } catch (e2) {}
		Debris.append({ ent = d, until = now + DebrisLife, last = d.GetOrigin(), hit = {} });
	}
	while (Debris.len() > MaxDebris) {
		local old = Debris.remove(0);
		if (old.ent != null && old.ent.IsValid())
			old.ent.Kill();
	}
}

function Fort::DebrisTick(now, dt) {
	foreach (i, d in clone Debris) {
		if (d.ent == null || !d.ent.IsValid() || now >= d.until) {
			if (d.ent != null && d.ent.IsValid())
				d.ent.Kill();
			local at = Debris.find(d);
			if (at != null)
				Debris.remove(at);
			continue;
		}
		local pos = d.ent.GetOrigin();
		local speed = dt > 0.0 ? (pos - d.last).Length() / dt : 0.0;
		d.last = pos;
		if (speed < CrushSpeed)
			continue;
		local centre = pos;
		try { centre = d.ent.GetCenter(); } catch (e) {}
		foreach (cls in [ "infected", "player" ]) {
			local z = null;
			while ((z = Entities.FindByClassnameWithin(z, cls, centre, CrushRadius)) != null) {
				if (cls == "player" && NetProps.GetPropInt(z, "m_iTeamNum") != FORT_TEAM_INFECTED)
					continue;
				local idx = z.GetEntityIndex();
				if (idx in d.hit)
					continue;
				d.hit[idx] <- true;
				z.TakeDamage(cls == "player" ? CrushSpecial : CrushDamage, 1, d.ent);
			}
		}
	}
}

function Fort::Hurt(index, piece, amount) {
	piece.health -= amount;
	if (piece.health <= 0.0) {
		Break(index, piece);
		return;
	}
	local stage = StageOf(piece);
	if (stage != piece.stage) {
		piece.stage = stage;
		DoEntFire("!self", "Color", Tint(piece), 0, null, piece.ent);
		SoundAt(Sounds.Crack, piece.pos);
		Particle(Dust, piece.pos + Vector(0, 0, 24), 1.0);
	}
}

function Fort::Break(index, piece) {
	if (piece.kind == "gun") {
		local user = null;
		try { user = NetProps.GetPropEntity(piece.ent, "m_owner"); } catch (e) {}
		if (user != null && user.IsValid()) {
			piece.wrecked = true;
			return;
		}
	}
	SoundAt(Sounds.Break, piece.pos);
	Particle(Dust, piece.pos, 1.5);
	Particle(Dust, piece.pos + Vector(0, 0, 32), 1.5);
	ScreenShake(piece.pos, 6.0, 30.0, 0.5, 400.0, 0, false);
	if (Phase == "wave")
		try { Loose(piece); } catch (e) { Log("collapse failed: " + e); }
	Unfx(piece);
	if (piece.ent.IsValid())
		piece.ent.Kill();
	if (index in Pieces)
		delete Pieces[index];
	Fall(piece, false);
}

function Fort::WaveLength(n) {
	return WaveBase + WaveGrow * (n - 1);
}

function Fort::TankCount(n) {
	if (n < TankFrom)
		return 0;
	return 1 + (n - TankFrom) / TankEvery;
}

function Fort::Clamp(v, lo, hi) {
	return v < lo ? lo : (v > hi ? hi : v);
}

function Fort::Options(n) {
	local c = n - 1;
	return {
		CommonLimit = Clamp(60 + 30 * c, 60, 150), MegaMobSize = Clamp(60 + 30 * c, 60, 150),
		MobMinSize = Clamp(25 + 10 * c, 25, 80), MobMaxSize = Clamp(40 + 15 * c, 40, 120), MobMaxPending = Clamp(50 + 20 * c, 50, 150),
		MobSpawnMinTime = Clamp(12 - 3 * c, 2, 12), MobSpawnMaxTime = Clamp(20 - 4 * c, 4, 20),
		MaxSpecials = Clamp(4 + 4 * c, 4, 20), SpecialRespawnInterval = Clamp(12 - 3 * c, 2, 12),
		DominatorLimit = Dominators(n), ProhibitBosses = true, TankLimit = 0, WitchLimit = 0
	};
}

function Fort::StockMode() {
	local mode = "";
	try { mode = Director.GetGameMode(); } catch (e) {}
	return (mode == "hd4lfort" || mode == "hd4lfreebuild");
}

function Fort::Dominators(n) {
	return StockMode() ? Clamp(1 + (n - 1) / 3, 1, StockDominators) : Clamp(3 + (n - 1), 3, 8);
}

function Fort::PanicEvery(n) {
	return Clamp(30.0 - 6.0 * (n - 1), 6.0, 30.0);
}

function Fort::Keep(n) {
	return Clamp(2 + 2 * (n - 1), 2, 16);
}

function Fort::Specials() {
	local n = 0;
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null)
		if (NetProps.GetPropInt(p, "m_iTeamNum") == FORT_TEAM_INFECTED && !p.IsDead() && !p.IsGhost() && p.GetZombieType() != FORT_ZOMBIE_TANK)
			n++;
	return n;
}

function Fort::Pressure(now) {
	if (now >= NextPanic) {
		NextPanic = now + PanicEvery(Wave);
		try { Director.ForcePanicEvent(); } catch (e) {}
	}
	if (now < NextSpecial)
		return;
	NextSpecial = now + SpecialEvery;
	if (Specials() >= Keep(Wave))
		return;
	local survivors = Survivors();
	if (survivors.len() == 0)
		return;
	local s = survivors[RandomInt(0, survivors.len() - 1)];
	local spot = null;
	if (("InfectedMoves" in getroottable()) && ("HiddenSpot" in ::InfectedMoves))
		try { spot = ::InfectedMoves.HiddenSpot(s, survivors, 500.0, 1100.0); } catch (e) { spot = null; }
	local kinds = StockMode() ? StockSpecials : AllSpecials;
	local kind = kinds[RandomInt(0, kinds.len() - 1)];
	try {
		if (spot != null)
			ZSpawn({ type = kind, pos = spot, ang = QAngle(0, RandomInt(0, 359), 0) });
		else
			ZSpawn({ type = kind });
	} catch (e) {}
}

function Fort::Calm() {
	return {
		CommonLimit = 0, MegaMobSize = 0, MobMinSize = 0, MobMaxSize = 0, MobMaxPending = 0,
		MobSpawnMinTime = 9999, MobSpawnMaxTime = 9999, MaxSpecials = 0, SpecialRespawnInterval = 9999,
		DominatorLimit = 0, ProhibitBosses = true, TankLimit = 0, WitchLimit = 0
	};
}

function Fort::Direct(options) {
	local root = getroottable();
	if (!("SessionOptions" in root))
		root.SessionOptions <- {};
	local director = null;
	if (("DirectorScript" in root) && ("DirectorOptions" in root.DirectorScript))
		director = root.DirectorScript.DirectorOptions;
	foreach (key, value in options) {
		root.SessionOptions[key] <- value;
		root.SessionOptions["cm_" + key] <- value;
		if (director != null)
			director[key] <- value;
	}
}

function Fort::Clear() {
	local commons = [];
	local ent = null;
	while ((ent = Entities.FindByClassname(ent, "infected")) != null)
		commons.append(ent);
	foreach (z in commons)
		if (z.IsValid())
			z.Kill();
	local world = Entities.First();
	ent = null;
	while ((ent = Entities.FindByClassname(ent, "player")) != null)
		if (NetProps.GetPropInt(ent, "m_iTeamNum") == FORT_TEAM_INFECTED && !ent.IsDead() && !ent.IsGhost())
			ent.TakeDamage(ent.GetHealth() + 10000, 0, world);
	ent = null;
	local witches = [];
	while ((ent = Entities.FindByClassname(ent, "witch")) != null)
		witches.append(ent);
	foreach (w in witches)
		if (w.IsValid())
			w.Kill();
}

function Fort::StartWave(n) {
	Wave = n;
	Phase = "wave";
	local now = Time();
	PhaseUntil = now + WaveLength(n);
	LastWear = now;
	LastBeep = -1;
	foreach (id, st in Players) {
		HideGhost(st);
		ClearAim(st);
		Unlook(st);
		if (st.p != null && st.p.IsValid() && st.buildMode)
			NoShove(st.p, false);
		st.buildMode = false;
	}
	Direct(Options(n));
	try { Director.ResetMobTimer(); } catch (e) {}
	NextPanic = now + 3.0;
	NextSpecial = now + 2.0;
	foreach (p in Survivors())
		Arm(p);
	Tanks = [];
	local tanks = TankCount(n);
	for (local i = 0; i < tanks; i++)
		Tanks.append(now + WaveLength(n) * (0.25 + 0.5 * i / (tanks > 1 ? tanks - 1 : 1)));
	Spike();
}

function Fort::EndWave() {
	local bonus = BonusPerWave * Wave;
	Clear();
	AddScrap(bonus);
	StripAll(false);
	Direct(Calm());
	Phase = "break";
	PhaseUntil = Time() + BreakSeconds;
	LastBeep = -1;
	ToAll(Sounds.WaveOver);
	Spike();
}

function Fort::SpawnTank() {
	local survivors = Survivors();
	if (survivors.len() == 0)
		return;
	local s = survivors[RandomInt(0, survivors.len() - 1)];
	local spot = null;
	if (("InfectedMoves" in getroottable()) && ("HiddenSpot" in ::InfectedMoves))
		try { spot = ::InfectedMoves.HiddenSpot(s, survivors, 700.0, 1400.0); } catch (e) { spot = null; }
	local spawned = null;
	if (spot != null)
		try { spawned = ZSpawn({ type = FORT_ZOMBIE_TANK, pos = spot, ang = QAngle(0, RandomInt(0, 359), 0) }); } catch (e) {}
	if (spawned == null)
		try { spawned = ZSpawn({ type = FORT_ZOMBIE_TANK }); } catch (e) { Log("tank spawn failed: " + e); }
}

function Fort::WaveTick(now) {
	try { WearTick(now); } catch (e) { Log("wear failed: " + e); }
	if (now - LastClimb >= ClimbEvery) {
		LastClimb = now;
		try { ClimbTick(now); } catch (e) { Log("climb failed: " + e); }
	}
	try { Pressure(now); } catch (e) { Log("pressure failed: " + e); }
	foreach (i, at in clone Tanks)
		if (now >= at) {
			Tanks.remove(Tanks.find(at));
			SpawnTank();
			break;
		}
	Beeps(now);
	if (now >= PhaseUntil)
		EndWave();
}

function Fort::Up() {
	local out = [];
	foreach (s in Survivors()) {
		local feet = s.GetOrigin();
		local tr = { start = feet + Vector(0, 0, 4), end = feet - Vector(0, 0, 2000), ignore = s };
		TraceLine(tr);
		local ground = ("pos" in tr) ? tr.pos.z : feet.z;
		local hit = ("enthit" in tr) ? PieceOf(tr.enthit) : null;
		if (hit != null || feet.z - ground >= ClimbHeight)
			out.append(s);
	}
	return out;
}

function Fort::Arc(a, b) {
	local rise = b.z - a.z + ClimbClear;
	if (rise < ClimbClear)
		rise = ClimbClear;
	local up = sqrt(2.0 * Gravity * rise);
	local t = up / Gravity + sqrt(2.0 * ClimbClear / Gravity);
	local flat = Vector(b.x - a.x, b.y - a.y, 0);
	local d = flat.Length();
	local across = d / t;
	if (across > ClimbSpeed)
		across = ClimbSpeed;
	if (d > 0.01)
		flat = flat * (1.0 / d);
	return flat * across + Vector(0, 0, up);
}

function Fort::ClimbTick(now) {
	local up = Up();
	if (up.len() == 0)
		return;
	local n = 0;
	foreach (s in up) {
		local feet = s.GetOrigin();
		foreach (cls in [ "infected", "player" ]) {
			local z = null;
			while ((z = Entities.FindByClassnameWithin(z, cls, feet, ClimbReach + ClimbHeight * 4.0)) != null) {
				if (n >= ClimbMax)
					return;
				if (cls == "player" && (NetProps.GetPropInt(z, "m_iTeamNum") != FORT_TEAM_INFECTED || z.IsDead() || z.IsGhost()))
					continue;
				if (cls == "infected" && z.GetHealth() <= 0)
					continue;
				local at = z.GetOrigin();
				if (feet.z - at.z < ClimbHeight)
					continue;
				if (Vector(feet.x - at.x, feet.y - at.y, 0).Length() > ClimbReach)
					continue;
				local idx = z.GetEntityIndex();
				if ((idx in Climbed) && now - Climbed[idx] < ClimbCooldown)
					continue;
				Climbed[idx] <- now;
				local vel = Arc(at, feet);
				if (cls == "player")
					z.SetVelocity(vel);
				else
					z.ApplyAbsVelocityImpulse(vel);
				n++;
			}
		}
	}
}

function Fort::BotLift(now) {
	local humans = [];
	foreach (s in Up())
		if (!IsPlayerABot(s))
			humans.append(s);
	foreach (b in Survivors()) {
		if (!IsPlayerABot(b))
			continue;
		local idx = b.GetEntityIndex();
		local near = null;
		foreach (h in humans) {
			local d = h.GetOrigin() - b.GetOrigin();
			if (d.z >= BotLiftHeight && Vector(d.x, d.y, 0).Length() <= BotLiftReach)
				near = h;
		}
		if (near == null) {
			if (idx in Stranded)
				delete Stranded[idx];
			continue;
		}
		if (!(idx in Stranded)) {
			Stranded[idx] <- now;
			continue;
		}
		if (now - Stranded[idx] < BotLiftAfter)
			continue;
		delete Stranded[idx];
		local f = near.EyeAngles().Forward();
		local side = Vector(-f.y, f.x, 0);
		if (side.Length() < 0.01)
			side = Vector(1, 0, 0);
		side.Norm();
		b.SetOrigin(near.GetOrigin() + side * 40.0 + Vector(0, 0, 8));
		b.SetVelocity(Vector(0, 0, 0));
	}
}

function Fort::KeepCalm(now) {
	if (now - LastCalm < CalmEvery)
		return;
	LastCalm = now;
	Clear();
}

function Fort::BreakTick(now) {
	KeepCalm(now);
	Beeps(now);
	if (now >= PhaseUntil)
		StartWave(Wave + 1);
}

function Fort::Beeps(now) {
	local left = (PhaseUntil - now + 0.99).tointeger();
	if (left > BeepFrom || left <= 0 || left == LastBeep)
		return;
	LastBeep = left;
	ToAll(Sounds.Beep);
}

function Fort::OnGameEvent_infected_death(params) {
	if (Phase == "wave")
		AddScrap(KillScrap.common);
}

function Fort::OnGameEvent_player_death(params) {
	if (Phase != "wave" || !("userid" in params))
		return;
	local victim = null;
	try { victim = GetPlayerFromUserID(params.userid); } catch (e) { return; }
	if (victim == null || !victim.IsValid() || NetProps.GetPropInt(victim, "m_iTeamNum") != FORT_TEAM_INFECTED)
		return;
	AddScrap(victim.GetZombieType() == FORT_ZOMBIE_TANK ? KillScrap.tank : KillScrap.special);
}

function Fort::OnGameEvent_witch_killed(params) {
	if (Phase == "wave")
		AddScrap(KillScrap.witch);
}

function Fort::OnGameEvent_survival_round_start(params) {
	if (InSurvival() && Phase == "prep")
		StartWave(1);
}

function Fort::OnGameEvent_create_panic_event(params) {
	if (InSurvival() && Phase == "prep")
		StartWave(1);
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

Fort.Precache();
Fort.Hook();

if (!("HD4L_Parts" in getroottable()))
	::HD4L_Parts <- {};
::HD4L_Parts["fort"] <- "0.1";
