::ROOT <- vargv.len() > 0 ? vargv[0] : ".";
dofile(::ROOT + "/tests/unit/mock.nut");
Suite("fort");

::Aimed <- null;
::AimedAt <- null;
::Boxes <- [];
::ClipHit <- false;
::ClipEnt <- null;
function TraceLine(t) {
	t.fraction <- 1.0;
	if ("clip" in t) {
		local through = ::ClipEnt != null && ("clipSeen" in ::ClipEnt.props);
		t.hit <- ::ClipHit && !through; t.pos <- t.start;
		if (t.hit && ::ClipEnt != null) {
			t.enthit <- ::ClipEnt;
			::ClipEnt.props.clipSeen <- true;
		}
		return;
	}
	if (t.end.z < t.start.z - 50.0) {
		local best = null;
		foreach (b in ::Boxes)
			if (b.ent.valid && t.start.x >= b.lo.x && t.start.x <= b.hi.x && t.start.y >= b.lo.y && t.start.y <= b.hi.y
				&& b.hi.z < t.start.z && (best == null || b.hi.z > best.hi.z))
				best = b;
		t.hit <- true;
		if (best != null) {
			t.pos <- Vector(t.start.x, t.start.y, best.hi.z); t.enthit <- best.ent;
		} else {
			t.pos <- Vector(t.start.x, t.start.y, 0); t.enthit <- Entities.First();
		}
		return;
	}
	if (::Aimed != null) {
		t.hit <- true; t.pos <- (::AimedAt != null ? ::AimedAt : ::Aimed.GetOrigin()); t.enthit <- ::Aimed;
		return;
	}
	t.hit <- false; t.pos <- t.end;
}

::Inv <- {};
function GetInvTable(p, t) {
	if (p.userid in ::Inv)
		foreach (k, v in ::Inv[p.userid])
			t[k] <- v;
}

class BoxEnt extends Ent {
	lo = null; hi = null;
	function GetBoundingMins() { return lo; }
	function GetBoundingMaxs() { return hi; }
}
function Box(cls, dx, dy, dz) {
	local e = BoxEnt(cls);
	e.lo = Vector(-dx / 2.0, -dy / 2.0, 0); e.hi = Vector(dx / 2.0, dy / 2.0, dz);
	return e;
}

Load("parts/fort/addon/scripts/vscripts/fort.nut");

function Survival() {
	Reset();
	::T.mode = "hd4lsurvival";
	::Aimed = null;
	::AimedAt = null;
	::Boxes.clear();
	::Inv.clear();
	::Fort.OnGameEvent_round_start({});
}

function Press(p, buttons, pressed) {
	if ((pressed & 1) && ::Fort.StateOf(p).buildMode)
		::T.now += 0.3;
	p.props.m_nButtons <- buttons;
	p.props.m_afButtonPressed <- pressed;
	::Fort.PlayerTick(p, Time());
	if (buttons == 0)
		::Fort.PlayerTick(p, Time());
	p.props.m_afButtonPressed <- 0;
}

const ATTACK0 = 1;
function FiredOn(ent, input) {
	foreach (f in ::T.fired)
		if (f.ent == ent && f.input == input)
			return true;
	return false;
}
function Smash(p, ent) {
	local was = ::Aimed;
	::Aimed = ent;
	for (local i = 0; i < 10 && !FiredOn(ent, "Break"); i++)
		::Fort.Whack(p.userid);
	::Aimed = was;
}

function LookAt(p, x, z) {
	p.angles = QAngle(atan2(64.0 - z, x) * 57.29578, 0, 0);
}

function Bp(name) {
	foreach (i, bp in ::Fort.Blueprints)
		if (bp.name == name)
			return i;
	return -1;
}

const WALK = 131072;
function PlaceAt(p, bp, pos, yaw = 0, support = null) {
	::Fort.Place(p, bp, { origins = ::Fort.Origins(bp, pos, yaw), angles = QAngle(0, yaw, 0), pos = pos, yaw = yaw,
	                      supports = support != null ? [ support ] : [], grounded = support == null, key = "", slot = null });
}
const USE = 32;
const RELOAD = 8192;
const SHOVE = 2048;
const DUCK = 4;

Survival();
Check(::Fort.Phase == "prep" && ::Fort.Wave == 0, "survival: round starts in prep, no wave");
Check(::Fort.Scrap == ::Fort.StartScrap, "survival: starting scrap");
Check(::Fort.Building(), "prep: building open");
Reset();
::T.mode = "hd4l";
::Fort.OnGameEvent_round_start({});
Check(::Fort.Phase == "off", "coop: off");
::T.mode = "hd4lversus";
::Fort.OnGameEvent_round_start({});
Check(::Fort.Phase == "off", "versus: off");

Survival();
local nick = MakeSurvivor();
local pistol = Ent("weapon_pistol");
local kit = Ent("weapon_first_aid_kit");
::Inv[1] <- { slot1 = pistol, slot3 = kit };
::Fort.StripStart(::Fort.Generation);
Check(!pistol.valid && !kit.valid, "prep: everyone starts holding nothing");
local gives = Events(nick, "give");
Check(gives.len() >= 1 && gives[0].name == "fireaxe", "prep: but for a fire axe");

Survival();
nick = MakeSurvivor();
local axe = Ent("weapon_melee");
axe.props.m_strMapSetScriptName <- "fireaxe";
::Inv[1] <- { slot1 = axe };
::Fort.Arm2(nick);
Check(axe.valid && Events(nick, "give").len() == 0, "axe: an axe is kept");
local magnum = Ent("weapon_pistol_magnum");
::Inv[1] <- { slot1 = magnum };
::Fort.Arm2(nick);
Check(!magnum.valid && Events(nick, "give")[0].name == "fireaxe", "axe: a pistol becomes an axe");

Check(::Fort.Blueprints[Bp("minigun")].cost >= 1000 && ::Fort.Blueprints[Bp("50 cal")].cost >= 1000, "price: mounted guns 1000+");
Check(::Fort.Blueprints[Bp("defibrillator")].cost >= 700, "price: a defib 700+");

Survival();
nick = MakeSurvivor();
local rifle = Ent("weapon_rifle_spawn");
rifle.origin = Vector(60, 0, 0);
local medkits = Ent("weapon_first_aid_kit_spawn");
medkits.origin = Vector(400, 0, 0);
medkits.props.m_itemCount <- 3;
local gas = Ent("weapon_gascan");
gas.origin = Vector(800, 0, 0);
local ammo = Ent("weapon_ammo_spawn");
local held = Ent("weapon_smg");
held.props.m_hOwner <- nick;
local deployed = Ent("upgrade_ammo_incendiary");
local laser = Ent("upgrade_laser_sight");
laser.origin = Vector(1200, 0, 0);
::Fort.ConvertLoot();
Check(!rifle.valid && !medkits.valid && !gas.valid && !laser.valid, "loot: weapons, items and upgrades replaced");
Check(ammo.valid && held.valid && deployed.valid, "loot: ammo piles, held guns and deployed ammo stay");
Check(::Fort.Loot.len() == 4, "loot: four junk props");
function LootAt(x) {
	foreach (i, l in ::Fort.Loot)
		if (fabs(l.ent.GetOrigin().x - x) < 1.0 && fabs(l.ent.GetOrigin().y) < 1.0)
			return l;
	return null;
}
local r = LootAt(60), m = LootAt(400), g = LootAt(800), u = LootAt(1200);
Check(r.kind == "heavy" && ::Fort.LootProps.heavy.find(r.ent.kv.model) != null, "loot: a rifle becomes heavy junk (" + r.ent.kv.model + ")");
Check(m.kind == "meds" && ::Fort.LootProps.meds.find(m.ent.kv.model) != null, "loot: medkits become boxes");
Check(g.kind == "fuel" && ::Fort.LootProps.fuel.find(g.ent.kv.model) != null, "loot: a gas can becomes a drum");
Check(u.kind == ::Fort.LootOther, "loot: anything else is the default junk");
Check(r.ent.cls == "prop_physics_override" && !("targetname" in r.ent.kv), "loot: a physics prop, nothing to pick up");
Check(r.value == ::Fort.LootValue.rifle && m.value == 3 * ::Fort.LootValue.first_aid_kit, "loot: worth its item, stacks count");
Check(::Fort.Salvageable(r.ent) && ::Fort.ScrapOf(r.ent) == ::Fort.LootValue.rifle, "loot: salvaged for its item's worth");
::Aimed = r.ent;
Press(nick, 0, 0);
Check(::Fort.Hud(nick).cost == ::Fort.LootValue.rifle, "loot: amber, its worth on the HUD");
Smash(nick, r.ent);
Check(::Fort.Scrap == ::Fort.StartScrap + ::Fort.LootValue.rifle && ::Fort.Loot.len() == 3 && FiredOn(r.ent, "Break"), "loot: whacked to pieces for its worth");

Survival();
local p1 = Ent("weapon_pain_pills_spawn");
p1.origin = Vector(0, 0, 0);
local p2 = Ent("weapon_rifle_spawn");
p2.origin = Vector(30, 0, 0);
local p3 = Ent("weapon_molotov_spawn");
p3.origin = Vector(0, 40, 0);
local apart = Ent("weapon_smg_spawn");
apart.origin = Vector(500, 0, 0);
::Fort.ConvertLoot();
Check(::Fort.Loot.len() == 4, "spread: one junk prop per item, no merging");
local zs = [];
foreach (i, l in ::Fort.Loot) {
	Check(l.ent.cls == "prop_physics_override", "spread: a physics prop (" + l.kind + ")");
	if (l.ent.GetOrigin().x < 100.0)
		zs.append(l.ent.GetOrigin().z);
}
zs.sort();
Check(zs.len() == 3 && zs[0] >= ::Fort.LootDrop && zs[1] >= zs[0] + ::Fort.LootStack && zs[2] >= zs[1] + ::Fort.LootStack, "spread: the close ones stacked, none inside another or the floor");
local alone = null;
foreach (i, l in ::Fort.Loot)
	if (l.ent.GetOrigin().x > 400.0)
		alone = l;
Check(alone.ent.GetOrigin().z == ::Fort.LootDrop, "spread: a lone item just drops from LootDrop");
local lostIdx = null;
foreach (i, l in ::Fort.Loot)
	if (l.ent == alone.ent)
		lostIdx = i;
alone.ent.valid = false;
::Fort.LootRecheck(lostIdx);
local back = false;
foreach (i, l in ::Fort.Loot)
	if (l.ent.valid && l.ent.cls == "prop_dynamic_override")
		back = true;
Check(back, "spread: a model that will not be physics comes back plain");

Survival();
nick = MakeSurvivor();
local can2 = Ent("weapon_gascan");
can2.props.m_hOwner <- nick;
::Fort.ConvertLoot();
Check(can2.valid, "held: a carried gas can is left alone");
can2.props.m_hOwner <- null;
::Fort.ConvertLoot();
Check(can2.valid && ::Fort.Loot.len() == 0, "held: thrown, it is still a gas can");
local can3 = Ent("weapon_gascan");
::Fort.OnGameEvent_weapon_drop({ userid = 1, propid = can3.index });
::Fort.ConvertLoot();
Check(can3.valid, "held: a dropped gas can, never seen held, stays");
Survival();
local early = Ent("weapon_propanetank");
::Fort.ConvertLoot();
Check(!early.valid, "carry: the map's propane turns to junk at the start");
::T.now += ::Fort.CarryFirst + 1.0;
local late = Ent("weapon_gascan");
::Fort.ConvertLoot();
Check(late.valid, "carry: a gas can that turns up later stays a gas can");

Survival();
local car = Box("prop_car_alarm", 200, 80, 60);
local can = Box("prop_physics", 30, 30, 40);
local named = Box("prop_physics", 30, 30, 40);
named.kv.targetname <- "finale_prop";
local propane = Box("prop_physics", 20, 20, 30);
propane.model = "models/props_junk/propanecanister001a.mdl";
local door = Box("prop_door_rotating", 8, 56, 100);
local board = Box("func_breakable", 60, 8, 60);
Check(::Fort.Salvageable(car) && ::Fort.Salvageable(can) && ::Fort.Salvageable(propane), "salvage: cars, cans, explosives");
Check(::Fort.Salvageable(door) && ::Fort.Salvageable(board), "salvage: doors and breakables");
Check(!::Fort.Salvageable(named), "salvage: named props are map logic");
Check(!::Fort.Salvageable(Ent("prop_door_rotating_checkpoint")), "salvage: saferoom doors stay");
local carScrap = ::Fort.ScrapOf(car);
local canScrap = ::Fort.ScrapOf(can);
Check(carScrap >= 80 && canScrap >= 6 && canScrap <= 14, "salvage: a car about ten cans (" + carScrap + ", " + canScrap + ")");

nick = MakeSurvivor();
can.origin = Vector(60, 0, 0);
::Aimed = can;
Press(nick, 0, 0);
Check(::Fort.Hud(nick).cost == canScrap, "look: the HUD shows what the prop is worth");
Press(nick, USE, USE);
::T.now += 5.0;
Press(nick, USE, 0);
Check(can.valid && ::Fort.Scrap == ::Fort.StartScrap, "whack: holding USE does nothing any more");
local axe = Ent("weapon_melee");
nick.weapon = axe;
axe.props.m_flNextPrimaryAttack <- 0.0;
Press(nick, 0, 0);
::T.fired.clear();
axe.props.m_flNextPrimaryAttack <- 1.0;
Press(nick, ATTACK0, ATTACK0);
local swing = ::T.fired.filter(@(i, f) f.input == "RunScriptCode" && f.param.find("::Fort.Whack(") == 0);
Check(swing.len() == 1 && swing[0].delay == ::Fort.HammerDelay, "whack: a swing lands HammerDelay later");
Press(nick, ATTACK0, 0);
Check(::T.fired.filter(@(i, f) f.input == "RunScriptCode" && f.param.find("::Fort.Whack(") == 0).len() == 1, "whack: one hit per swing");
::Fort.Whack(nick.userid);
Check(Bp("gnome") >= 0 && ::Fort.Blueprints[Bp("gnome")].cat == "item" && ::Fort.Blueprints[Bp("gnome")].classname == "weapon_gnome", "gnome: an item you can build");
foreach (kind, models in ::Fort.LootProps)
	foreach (m in models)
		Check(m.find("generator") == null, "loot: no generators (" + kind + ")");
Check(::Fort.Scrap == ::Fort.StartScrap + canScrap && FiredOn(can, "Break") && FiredOn(can, "Kill"), "whack: a can breaks in one hit, all its scrap");
::Fort.Scrap = 0;
car.origin = Vector(60, 0, 0);
::Aimed = car;
local hits = 0;
while (!FiredOn(car, "Break") && hits < 20) {
	::Fort.Whack(nick.userid);
	hits++;
}
Check(hits == ::Fort.MaxHits && ::Fort.Scrap == carScrap, "whack: a car takes " + ::Fort.MaxHits + " hits (" + hits + "), all its scrap in the end");
Check(Events(car, "impulse").len() == ::Fort.MaxHits - 1, "whack: every hit but the last knocks it");
Press(nick, 0, 0);
nick.weapon = null;
::Aimed = null;

{
Survival();
nick = MakeSurvivor();
local alarm = Box("prop_car_alarm", 200, 80, 60);
::T.now += ::Fort.LootEvery + 0.1;
::Fort.Tick(::Fort.Generation);
Check(FiredOn(alarm, "Disable"), "alarm: car alarms disabled");
local again = ::T.fired.len();
::T.now += ::Fort.LootEvery + 0.1;
::Fort.Tick(::Fort.Generation);
Check(::T.fired.filter(@(i, f) f.input == "Disable").len() == 1, "alarm: once per car");
local tank = Box("prop_physics", 20, 20, 40);
tank.model = "models/props_junk/propanecanister001a.mdl";
tank.origin = Vector(60, 0, 0);
::T.fired.clear();
Smash(nick, tank);
Check(!FiredOn(tank, "Break") && FiredOn(tank, "Kill"), "whack: a propane tank vanishes, it never goes off");
local wallProp = Box("prop_dynamic", 400, 16, 300);
local sign = Box("prop_dynamic", 60, 8, 80);
Check(!::Fort.Salvageable(wallProp) && ::Fort.Salvageable(sign), "whack: big scenery stays, small scenery breaks");
local bigBarrel = Box("prop_physics", 400, 400, 40);
Check(::Fort.Salvageable(bigBarrel), "whack: physics props break at any size");
local hit = { Victim = sign, Attacker = nick, DamageDone = 20.0 };
Check(::Fort.PieceHit(hit) == true, "refuse: a survivor's hit on a prop in the prep");
local zombieHit = { Victim = sign, Attacker = Ent("infected"), DamageDone = 20.0 };
Check(::Fort.PieceHit(zombieHit) == false, "refuse: anyone else's hit goes through");
::Fort.StartWave(1);
Check(::Fort.PieceHit(hit) == false, "refuse: in a wave, shooting props is stock");
{
}

Survival();
nick = MakeSurvivor();
local crate = Box("prop_physics", 30, 30, 30);
local crateWorth = ::Fort.ScrapOf(crate);
::Fort.OnGameEvent_break_prop({ entindex = crate.index, userid = nick.userid });
Check(::Fort.Scrap == ::Fort.StartScrap + crateWorth, "broke: an engine break pays the prop's worth");
::Fort.OnGameEvent_break_prop({ entindex = crate.index, userid = nick.userid });
Check(::Fort.Scrap == ::Fort.StartScrap + crateWorth, "broke: once");
local dented = Box("prop_car_alarm", 200, 80, 60);
dented.origin = Vector(60, 0, 0);
::Aimed = dented;
::Fort.Whack(nick.userid);
local afterHit = ::Fort.Scrap;
local leftOver = ::Fort.Dents[dented.index].left;
::Fort.OnGameEvent_break_prop({ entindex = dented.index, userid = nick.userid });
Check(::Fort.Scrap == afterHit + leftOver && leftOver > 0, "broke: a dented prop pays what is left");
local smashed = Box("prop_physics", 30, 30, 30);
smashed.origin = Vector(60, 0, 0);
Smash(nick, smashed);
local afterSmash = ::Fort.Scrap;
::Fort.OnGameEvent_break_prop({ entindex = smashed.index, userid = 0 });
::Fort.OnGameEvent_break_prop({ entindex = smashed.index, userid = nick.userid });
Check(::Fort.Scrap == afterSmash, "broke: the whack's own break pays nothing more");
::Aimed = null;
::Fort.StartWave(1);
local waveCrate = Box("prop_physics", 30, 30, 30);
local inWave = ::Fort.Scrap;
::Fort.OnGameEvent_break_prop({ entindex = waveCrate.index, userid = nick.userid });
Check(::Fort.Scrap == inWave, "broke: not in a wave");
}

Survival();
nick = MakeSurvivor();
local axe2 = Ent("weapon_melee");
nick.weapon = axe2;
axe2.props.m_flNextPrimaryAttack <- 0.0;
Press(nick, 0, 0);
::T.fired.clear();
::Fort.OnGameEvent_weapon_fire({ userid = nick.userid, weapon = "melee" });
axe2.props.m_flNextPrimaryAttack <- 1.0;
Press(nick, ATTACK0, ATTACK0);
Check(::T.fired.filter(@(i, f) f.input == "RunScriptCode" && f.param.find("::Fort.Whack(") == 0).len() == 1, "swing: event and attack time, one hit");
::T.now += 1.0;
::T.fired.clear();
axe2.props.m_flNextPrimaryAttack <- 3.0;
Press(nick, SHOVE, SHOVE);
Check(::T.fired.filter(@(i, f) f.input == "RunScriptCode" && f.param.find("::Fort.Whack(") == 0).len() == 0, "swing: a shove is not a hit");
Press(nick, 0, 0);
nick.weapon = null;

const ATTACK = 1;
function Choose(p, name) {
	local st = ::Fort.StateOf(p);
	local want = ::Fort.Blueprints[Bp(name)];
	foreach (ci, cat in ::Fort.Cats)
		if (cat == want.cat) {
			st.cat = ci;
			foreach (k, idx in ::Fort.List(cat))
				if (idx == Bp(name))
					st.pick[ci] = k;
		}
}
function TakeBack(p) {
	Press(p, RELOAD, RELOAD);
	::T.now += ::Fort.TapTime;
	Press(p, RELOAD, 0);
	Press(p, 0, 0);
}
function Tap(p, key) {
	Press(p, key, key);
	Press(p, 0, 0);
}
function Newest() {
	local best = null, at = -1;
	foreach (i, pc in ::Fort.Pieces)
		if (i > at) { at = i; best = pc; }
	return best;
}
Survival();
nick = MakeSurvivor();
local axe0 = Ent("weapon_melee");
::Inv[1] <- { slot1 = axe0 };
Press(nick, 0, 0);
Check(::Fort.Players[1].ghost == null, "mode: no blueprint outside build mode");
Tap(nick, WALK);
Check(::Fort.StateOf(nick).buildMode && ::Fort.Players[1].ghost != null, "mode: a tap of WALK is build mode, the blueprint shows");
Check(!axe0.valid, "mode: the axe goes away, hands free");
Check(::Fort.Pick(::Fort.StateOf(nick)).shape == "wall", "mode: starts on the structures, a wall");
Check(::Fort.Hud(nick).cost == ::Fort.Pick(::Fort.StateOf(nick)).cost, "mode: the HUD shows its cost");
local kit = Ent("weapon_first_aid_kit");
nick.weapon = kit;
Press(nick, ATTACK, ATTACK);
Press(nick, 0, 0);
Check(kit.props.m_flNextPrimaryAttack > Time() && kit.props.m_flNextSecondaryAttack > Time(), "hands: a held medkit cannot be used while building");
nick.weapon = null;
foreach (i, pc in ::Fort.Pieces)
	pc.ent.Kill();
::Fort.Pieces.clear();
::Fort.Slots.clear();
::Fort.Scrap = ::Fort.StartScrap;
Check(::Fort.MaxPieces >= 300 && ::Fort.MaxItems >= 80, "freedom: 300 pieces, 80 items");
Check(::Fort.Blueprints.len() >= 30, "mode: thirty blueprints (" + ::Fort.Blueprints.len() + ")");

Press(nick, ATTACK, ATTACK);
Press(nick, 0, 0);
local w1 = Newest();
local sc = ::Fort.StructCell;
Check(w1 != null && w1.bp.shape == "wall" && w1.pos.x == sc && w1.pos.y == sc * 0.5 && w1.pos.z == 0.0,
	"wall: the far edge of your cell, on the ground (" + w1.pos + ")");
Check(w1.grounded && w1.slot != null, "wall: stands on the ground");
Check(::Fort.Scrap == ::Fort.StartScrap - ::Fort.Pick(::Fort.StateOf(nick)).cost, "wall: the team pays");
::Fort.Scrap = 2000;
local count = ::Fort.Pieces.len();
Press(nick, ATTACK, ATTACK);
Press(nick, 0, 0);
Check(::Fort.Pieces.len() == count && !::Fort.Hud(nick).ok, "wall: a taken spot places nothing");
nick.angles = QAngle(-30, 0, 0);
Press(nick, ATTACK, ATTACK);
Press(nick, 0, 0);
local w2 = Newest();
Check(w2 != w1 && w2.pos.z == ::Fort.StructHeight && w2.pos.x == sc && w2.supports.find(w1) != null && !w2.grounded,
	"wall: looking up puts it a level up, on the one below");
count = ::Fort.Pieces.len();
nick.angles = QAngle(-55, 0, 0);
Press(nick, ATTACK, ATTACK);
Press(nick, 0, 0);
nick.props.m_nButtons <- ATTACK;
nick.props.m_afButtonPressed <- 0;
::Fort.PlayerTick(nick, Time());
Check(::Fort.Pieces.len() == count + 1, "click: a flicker inside PlaceGap places nothing");
nick.angles = QAngle(-55, 90, 0);
::T.now += 1.0;
Press(nick, ATTACK, 0);
Check(::Fort.Pieces.len() == count + 1, "click: holding places nothing more, even on a new spot");
Press(nick, 0, 0);
Press(nick, ATTACK, ATTACK);
Press(nick, 0, 0);
Check(::Fort.Pieces.len() == count + 2 && Newest().pos.y == sc && Newest().pos.x == sc * 0.5, "click: the next click places");
nick.angles = QAngle(0, 0, 0);
nick.origin = Vector(sc + 20, 10, 0);
Press(nick, ATTACK, ATTACK);
Press(nick, 0, 0);
Check(Newest().pos.x == sc * 2.0 && Newest().pos.z == 0.0, "wall: walk a cell on, the next edge");
nick.origin = Vector(0, 0, 0);

const ZOOM = 524288;
local order = [];
for (local i = 0; i < 9; i++) {
	order.append(::Fort.Pick(::Fort.StateOf(nick)).name);
	Tap(nick, SHOVE);
}
Check(order[0] == "wall" && order[1] == "floor" && order[2] == "stairs" && order[3] == "roof" && order[4] == "door" && order[5] == "grate wall" && order[8] == "grate roof"
	&& ::Fort.Pick(::Fort.StateOf(nick)).name == "wall", "cycle: right click runs wall, floor, stairs, roof, door, then the grates (" + order.reduce(@(a, b) a + ", " + b) + ")");
Tap(nick, RELOAD);
Check(::Fort.Pick(::Fort.StateOf(nick)).name == "grate roof", "cycle: R goes back");
local heldAt = ::Fort.StateOf(nick).pick[0];
Press(nick, SHOVE, SHOVE);
for (local i = 0; i < 20; i++)
	Press(nick, SHOVE, SHOVE);
nick.props.m_nButtons <- 0;
nick.props.m_afButtonPressed <- 0;
::Fort.PlayerTick(nick, Time());
Press(nick, SHOVE, SHOVE);
Press(nick, SHOVE, SHOVE);
Press(nick, 0, 0);
Check(::Fort.StateOf(nick).pick[0] == (heldAt + 1) % 9, "cycle: held (and flickering) right click steps once");
Tap(nick, RELOAD);
Tap(nick, RELOAD);
Tap(nick, SHOVE);
Check(::Fort.Pick(::Fort.StateOf(nick)).name == "grate roof", "cycle: and forward again");
Check(nick.props.m_flNextShoveTime > ::T.now + 60.0, "shove: locked in build mode");
Tap(nick, ZOOM);
Check(::Fort.Pick(::Fort.StateOf(nick)).cat == "prop", "cycle: middle mouse next list");
Tap(nick, ZOOM);
Check(::Fort.Pick(::Fort.StateOf(nick)).cat == "item", "cycle: and the next");
Tap(nick, ZOOM);
Check(::Fort.Pick(::Fort.StateOf(nick)).name == "grate roof", "cycle: round to build, the pick remembered");
foreach (cat in ::Fort.Cats)
	Check(::Fort.List(cat).len() > 0 && ::Fort.List(cat).len() <= 24, "cycle: " + cat + " is a short list (" + ::Fort.List(cat).len() + ")");

Tap(nick, WALK);
Check(!::Fort.StateOf(nick).buildMode && ::Fort.Players[1].ghost == null, "mode: another tap leaves it");
Check(nick.props.m_flNextShoveTime <= ::T.now, "shove: back on leaving");
Check(Events(nick, "give").len() > 0 && Events(nick, "give")[0].name == "fireaxe", "mode: the axe is back");

Survival();
nick = MakeSurvivor();
::Fort.Scrap = 5000;
Tap(nick, WALK);
Press(nick, ATTACK, ATTACK);
Press(nick, 0, 0);
local wall = Newest();
Choose(nick, "roof");
Press(nick, ATTACK, ATTACK);
Press(nick, 0, 0);
local roof = Newest();
Check(roof.bp.shape == "roof" && roof.pos.x == sc * 1.5 && roof.pos.z == ::Fort.StructHeight && roof.supports.find(wall) != null && !roof.grounded,
	"roof: the cell in front a level up, held by the wall under its edge");
Choose(nick, "floor");
Press(nick, ATTACK, ATTACK);
Press(nick, 0, 0);
local floor0 = Newest();
Check(floor0.bp.shape == "floor" && floor0.pos.x == sc * 1.5 && floor0.pos.y == sc * 0.5 && floor0.pos.z == 0.0 && floor0.grounded,
	"floor: the cell in front, on the ground");
nick.angles = QAngle(70, 0, 0);
Press(nick, ATTACK, ATTACK);
Press(nick, 0, 0);
Check(Newest().pos.x == sc * 0.5 && Newest().pos.z == 0.0, "floor: looking down, your own cell");
nick.angles = QAngle(0, 0, 0);
nick.origin = Vector(sc * 1.5, sc * 0.5, 0);
Choose(nick, "wall");
Press(nick, ATTACK, ATTACK);
Press(nick, 0, 0);
local wall2 = Newest();
nick.origin = Vector(0, 0, 0);
roof.supports.append(wall2);
::Fort.StartWave(1);
foreach (i, pc in ::Fort.Pieces)
	if (pc == wall)
		::Fort.Break(i, pc);
Check(roof.ent.valid, "support: the roof stays while another wall holds it");
foreach (i, pc in ::Fort.Pieces)
	if (pc == wall2)
		::Fort.Break(i, pc);
Check(!roof.ent.valid, "support: the last one gone, it falls");
Check(floor0.ent.valid, "support: the floor on the ground stays");

Survival();
nick = MakeSurvivor();
::Fort.Scrap = 2000;
foreach (stairs in [ ::Fort.Blueprints[Bp("stairs")], ::Fort.Blueprints[Bp("grate stairs")] ]) {
	local sp = ::Fort.StructPlan(nick, ::Fort.StateOf(nick), stairs, ::Fort.Aim(nick, ::Fort.BuildRange), null);
	local b = ::Fort.Basis(sp.angles);
	local box = stairs.box;
	local tile = stairs.normal == "z";
	local mid = Vector((box[0] + box[3]) * 0.5, (box[1] + box[4]) * 0.5, (box[2] + box[5]) * 0.5);
	local slope = tile ? b.f : b.u;
	local up = tile ? b.u : b.f * -1.0;
	local half = (tile ? box[3] - box[0] : box[5] - box[2]) * 0.5;
	local thick = tile ? box[5] - box[2] : box[3] - box[0];
	Check(sp.origins.len() == 2, stairs.name + ": two panels");
	local bottom = sp.origins[0] + ::Fort.Local(b, mid) - slope * half + up * (thick * 0.5);
	local top = sp.origins[1] + ::Fort.Local(b, mid) + slope * half + up * (thick * 0.5);
	Check(fabs(bottom.x - 128.0) < 1.0 && fabs(bottom.y - 64.0) < 1.0 && fabs(bottom.z) < 1.0,
		stairs.name + ": starts on the cell's near edge on the ground (" + bottom + ")");
	Check(fabs(top.x - 256.0) < 1.0 && fabs(top.y - 64.0) < 1.0 && fabs(top.z - sc) < 1.0,
		stairs.name + ": ends on the far edge a level up (" + top + ")");
	Check(fabs(slope.x - 0.7071) < 0.01 && fabs(slope.z - 0.7071) < 0.01 && up.z > 0.7, stairs.name + ": 45 degrees, face up, climbing along your facing (" + slope + ")");
	Check(sp.pos.x == 192.0 && sp.pos.y == 64.0, stairs.name + ": in the cell in front");
}
foreach (name in [ "wall", "grate wall", "floor", "grate floor" ]) {
	local bp = ::Fort.Blueprints[Bp(name)];
	local plan = ::Fort.StructPlan(nick, ::Fort.StateOf(nick), bp, ::Fort.Aim(nick, ::Fort.BuildRange), null);
	local b = ::Fort.Basis(plan.angles);
	local box = bp.box;
	local c = plan.origins[0] + ::Fort.Local(b, Vector((box[0] + box[3]) * 0.5, (box[1] + box[4]) * 0.5, (box[2] + box[5]) * 0.5));
	local thin = bp.normal == "z" ? b.u : b.f;
	if (bp.shape == "wall")
		Check(fabs(c.x - 128.0) < 0.5 && fabs(c.y - 64.0) < 0.5 && fabs(c.z - 64.0) < 0.5 && fabs(thin.x) > 0.99, name + ": centred on the edge, thin across your view");
	else
		Check(fabs(c.x - 192.0) < 0.5 && fabs(c.y - 64.0) < 0.5 && c.z < 0.0 && c.z > -5.0 && fabs(thin.z) > 0.99, name + ": the cell in front, flat, its top on the ground");
}
local wallBp = ::Fort.Blueprints[Bp("wall")];
local wp = ::Fort.StructPlan(nick, ::Fort.StateOf(nick), wallBp, ::Fort.Aim(nick, ::Fort.BuildRange), null);
Check(!::Fort.Blocked(nick, wallBp.box, wp.origins, wp.angles, true, true, true), "clip: a clear spot is clear");
::ClipHit = true;
Check(::Fort.Blocked(nick, wallBp.box, wp.origins, wp.angles, true, true, true), "clip: a wall into the world is blocked");
local stc = ::Fort.StateOf(nick);
stc.clipKey = "";
Check(!::Fort.Clipped(nick, stc, wallBp, wp), "freedom: a wall into the world goes on");
::ClipHit = false;
mate2 <- MakeSurvivor("Rochelle", 3);
mate2.origin = Vector(130, 60, 0);
stc.clipKey = "";
Check(::Fort.Clipped(nick, stc, wallBp, wp), "freedom: but never into a player");
mate2.origin = Vector(900, -900, 0);
local wallPiece = null;
PlaceAt(nick, wallBp, Vector(900, 900, 0));
foreach (i, pc in ::Fort.Pieces)
	wallPiece = pc;
wallPiece.bp = wallBp;
::ClipHit = true;
::ClipEnt = wallPiece.ent;
local seen = function() { if ("clipSeen" in ::ClipEnt.props) delete ::ClipEnt.props.clipSeen; };
seen();
local stairBp = ::Fort.Blueprints[Bp("stairs")];
local sp2 = ::Fort.StructPlan(nick, ::Fort.StateOf(nick), stairBp, ::Fort.Aim(nick, ::Fort.BuildRange), null);
Check(!::Fort.Blocked(nick, stairBp.box, sp2.origins, sp2.angles, true, true, true), "clip: a stair touching your wall goes on");
local crateProp = Box("prop_physics", 30, 30, 30);
::ClipEnt = crateProp;
Check(::Fort.Blocked(nick, stairBp.box, sp2.origins, sp2.angles, true, true, true), "clip: a map prop in the way still blocks");
::ClipEnt = null;
::ClipHit = false;
foreach (i, pc in ::Fort.Pieces)
	pc.ent.Kill();
::Fort.Pieces.clear();
::Fort.Slots.clear();
local mate = MakeSurvivor("Ellis", 2);
mate.origin = Vector(130, 60, 0);
Check(::Fort.Blocked(nick, wallBp.box, wp.origins, wp.angles, true, true, true), "clip: a wall into a teammate is blocked");
mate.origin = Vector(170, 60, 0);
Check(!::Fort.Blocked(nick, wallBp.box, wp.origins, wp.angles, true, true, true), "clip: a teammate beside it is fine");
local fp = ::Fort.StructPlan(nick, ::Fort.StateOf(nick), ::Fort.Blueprints[Bp("floor")], ::Fort.Aim(nick, ::Fort.BuildRange), null);
mate.origin = Vector(192, 64, 0);
Check(!::Fort.Blocked(nick, wallBp.box, fp.origins, fp.angles, true, true, false), "clip: a floor under a teammate's feet is fine");
nick.origin = Vector(sc - 8, 64, 0);
local foot = ::Fort.StructPlan(nick, ::Fort.StateOf(nick), ::Fort.Blueprints[Bp("stairs")], ::Fort.Aim(nick, ::Fort.BuildRange), null);
mate.origin = Vector(900, 900, 0);
Check(!::Fort.Blocked(nick, ::Fort.Blueprints[Bp("stairs")].box, foot.origins, foot.angles, true, true, false), "clip: a stair starting at your feet is fine");
mate.origin = Vector(sc * 1.5, 64, 0);
Check(::Fort.Blocked(nick, ::Fort.Blueprints[Bp("stairs")].box, foot.origins, foot.angles, true, true, false), "clip: a stair through a teammate is not");
nick.origin = Vector(0, 0, 0);
::Fort.StateOf(nick).cellX = null;
mate.origin = Vector(900, 900, 0);
nick.angles = QAngle(0, 40, 0);
local held = ::Fort.StructPlan(nick, ::Fort.StateOf(nick), wallBp, ::Fort.Aim(nick, ::Fort.BuildRange), null);
Check(held.pos.x == 128.0 && held.pos.y == 64.0, "steady: 40 degrees off, the facing holds");
nick.angles = QAngle(0, 60, 0);
local moved = ::Fort.StructPlan(nick, ::Fort.StateOf(nick), wallBp, ::Fort.Aim(nick, ::Fort.BuildRange), null);
Check(moved.pos.x == 64.0 && moved.pos.y == 128.0, "steady: past FaceHold it turns");
nick.angles = QAngle(0, 0, 0);
::Fort.StructPlan(nick, ::Fort.StateOf(nick), wallBp, ::Fort.Aim(nick, ::Fort.BuildRange), null);
nick.origin = Vector(135, 10, 0);
local stay = ::Fort.StructPlan(nick, ::Fort.StateOf(nick), ::Fort.Blueprints[Bp("floor")], ::Fort.Aim(nick, ::Fort.BuildRange), null);
Check(stay.pos.x == 192.0, "steady: just over the cell line, your cell holds");
nick.origin = Vector(110, 10, 0);
local gap = ::Fort.StructPlan(nick, ::Fort.StateOf(nick), wallBp, ::Fort.Aim(nick, ::Fort.BuildRange), null);
Check(gap.pos.x == 256.0, "wall: never within WallGap of you, the next line instead");
nick.origin = Vector(0, 0, 0);

{
Survival();
nick = MakeSurvivor();
::Fort.Scrap = 2000;
Tap(nick, WALK);
Choose(nick, "stairs");
Press(nick, ATTACK, ATTACK);
Press(nick, 0, 0);
local s1 = Newest();
Check(s1.pos.x == sc * 1.5 && s1.pos.z == 0.0, "stairway: the first in front, on the ground");
nick.origin = Vector(sc * 1.5, sc * 0.5, 40);
nick.props.m_hGroundEntity <- s1.ent;
local lower = ::Fort.StructPlan(nick, ::Fort.StateOf(nick), ::Fort.Pick(::Fort.StateOf(nick)), ::Fort.Aim(nick, ::Fort.BuildRange), null);
Check(lower.pos.z == 0.0 && lower.pos.x == sc * 2.5, "stairway: on the lower half, the next cell on the same level");
nick.origin = Vector(sc * 1.8, sc * 0.5, 100);
nick.angles = QAngle(-40, 0, 0);
::T.now += 1.0;
Press(nick, ATTACK, ATTACK);
Press(nick, 0, 0);
local s2 = Newest();
Check(s2 != s1 && s2.pos.x == sc * 2.5 && s2.pos.z == sc && s2.supports.find(s1) != null,
	"stairway: on the upper half, a level up in the next cell, held by the one below (" + s2.pos + ")");
nick.origin = Vector(sc * 2.8, sc * 0.5, sc + 100);
nick.props.m_hGroundEntity <- s2.ent;
::T.now += 1.0;
Press(nick, ATTACK, ATTACK);
Press(nick, 0, 0);
Check(Newest().pos.x == sc * 3.5 && Newest().pos.z == sc * 2.0, "stairway: and on");
nick.props.m_hGroundEntity <- null;
::Boxes.append({ ent = s2.ent, lo = Vector(sc * 2.0, 0, 0), hi = Vector(sc * 3.0, sc, sc + 90) });
Check(::Fort.Standing(nick) == s2, "stairway: the stair under you found without a ground entity");
local again = ::Fort.StructPlan(nick, ::Fort.StateOf(nick), ::Fort.Pick(::Fort.StateOf(nick)), ::Fort.Aim(nick, ::Fort.BuildRange), null);
Check(again.pos.z == sc * 2.0, "stairway: and the level holds");
nick.origin = Vector(0, 0, 0);
nick.angles = QAngle(0, 0, 0);
delete nick.props.m_hGroundEntity;
::Boxes.clear();
}

local flat = ::Fort.Basis(QAngle(90, 0, 0));
Check(fabs(flat.f.z + 1.0) < 0.001 && fabs(flat.u.x - 1.0) < 0.001, "basis: pitch 90 lays it flat");
local turned = ::Fort.Basis(QAngle(0, 90, 0));
Check(fabs(turned.l.x + 1.0) < 0.001, "basis: yaw 90, left is -x");

Check(::Fort.Blueprints[Bp("grate wall")].model.find("fence001") != null && ::Fort.Blueprints[Bp("grate wall")].cost > ::Fort.Blueprints[Bp("wall")].cost,
	"grate: chain link, dearer than wood");

Survival();
nick = MakeSurvivor();
::Fort.Scrap = 2000;
Tap(nick, WALK);
Press(nick, ATTACK, ATTACK);
Press(nick, 0, 0);
local mine = Newest();
::Aimed = mine.ent;
local was = ::Fort.Scrap;
Tap(nick, USE);
Check(mine.ent.valid && ::Fort.Scrap == was, "use: a tap of USE leaves your piece alone (a gun stays under you)");
local pickBefore = ::Fort.StateOf(nick).pick[0];
TakeBack(nick);
Check(!mine.ent.valid && ::Fort.Scrap == was + mine.bp.cost, "take back: hold RELOAD, full refund");
Check(::Fort.StateOf(nick).pick[0] == pickBefore, "take back: and no piece cycled on release");
::Aimed = null;
Press(nick, ATTACK, ATTACK);
Press(nick, 0, 0);
local hurt = Newest();
hurt.health = hurt.max * 0.5;
::Aimed = hurt.ent;
local before = ::Fort.Scrap;
local pickHurt = ::Fort.StateOf(nick).pick[0];
Press(nick, SHOVE, SHOVE);
for (local i = 0; i < 25; i++) {
	::T.now += 0.1;
	Press(nick, SHOVE, 0);
}
Press(nick, 0, 0);
Check(hurt.ent.valid && hurt.health > hurt.max * 0.9, "repair: hold right click, it repairs (and is not taken back)");
Check(::Fort.Scrap < before, "repair: costs scrap");
Check(::Fort.StateOf(nick).pick[0] == pickHurt, "repair: no piece cycled on release");
::Aimed = null;

Survival();
nick = MakeSurvivor();
::Fort.Scrap = 500;
PlaceAt(nick, ::Fort.Blueprints[Bp("medkit")], Vector(200, 0, 0));
PlaceAt(nick, ::Fort.Blueprints[Bp("ammo")], Vector(200, 300, 0));
Check(::Fort.Supplies.len() == 2 && ::Fort.Pieces.len() == 0, "supply: items are supplies, not pieces");
local spent = ::Fort.Scrap;
Tap(nick, WALK);
LookAt(nick, 200, 2);
Press(nick, 0, 0);
Check(::Fort.Hud(nick).cost == ::Fort.Blueprints[Bp("medkit")].cost, "supply: looking at it shows its price");
TakeBack(nick);
Check(::Fort.Supplies.len() == 1 && ::Fort.Scrap == spent + ::Fort.Blueprints[Bp("medkit")].cost, "supply: hold RELOAD takes it back for its price");
::Fort.ConvertLoot();
Check(::Fort.Supplies.len() == 1 && ::Fort.Loot.len() == 0, "supply: the fort's own items never turn to loot");
nick.angles = QAngle(0, 0, 0);

Survival();
nick = MakeSurvivor();
::Fort.Scrap = 500;
PlaceAt(nick, ::Fort.Blueprints[Bp("razorwire")], Vector(150, 0, 0));
Tap(nick, WALK);
LookAt(nick, 150, 16);
TakeBack(nick);
Check(::Fort.Pieces.len() == 0, "build: wire taken back by looking at it");
nick.angles = QAngle(0, 0, 0);

Survival();
nick = MakeSurvivor();
local ellis = MakeSurvivor("Ellis", 2);
ellis.origin = Vector(300, 0, 0);
Check(!::Fort.CanPlace(::Fort.Blueprints[Bp("sandbags")], Vector(310, 0, 0)), "build: props not on a teammate");
Check(::Fort.CanPlace(::Fort.Blueprints[Bp("mine")], Vector(310, 0, 0)), "build: mines can go anywhere");
::Fort.Scrap = 5;
Tap(nick, WALK);
Choose(nick, "concrete wall");
Press(nick, ATTACK, ATTACK);
Press(nick, 0, 0);
Check(::Fort.Pieces.len() == 0 && !::Fort.Hud(nick).ok, "build: too poor, nothing placed, cost in blood");

function Aligned(v, n) {
	local t = v / ::Fort.Cell - (n % 2 == 0 ? 0.0 : 0.5);
	return fabs(t - floor(t + 0.5)) < 0.001;
}
Survival();
nick = MakeSurvivor();
::Fort.Scrap = 2000;
local sb = ::Fort.Blueprints[Bp("sandbags")];
::Fort.Sizes[sb.model] <- { sx = 2.0 * ::Fort.Cell - 10.0, sy = 40.0, cx = 0.0, cy = 0.0, known = true };
LookAt(nick, 150, 0);
local g = ::Fort.GridSpot(nick, ::Fort.StateOf(nick), sb, ::Fort.Aim(nick, ::Fort.BuildRange), null);
Check(g != null && Aligned(g.pos.x, 2) && Aligned(g.pos.y, 1) && g.pos.z == 0.0, "grid: a 2 x 1 prop sits on the cells (" + g.pos + ")");
Check(g.yaw % 90.0 == 0.0, "grid: facing snaps to 90");
nick.angles = QAngle(0, 50, 0);
Check(::Fort.GridYaw(nick, ::Fort.StateOf(nick)) == 45.0, "freedom: props turn in 45s with your view");
nick.angles = QAngle(0, 65, 0);
Check(::Fort.GridYaw(nick, ::Fort.StateOf(nick)) == 45.0, "freedom: held until you look past PropHold");
nick.angles = QAngle(0, 90, 0);
local g90 = ::Fort.GridSpot(nick, ::Fort.StateOf(nick), sb, ::Fort.Aim(nick, ::Fort.BuildRange), null);
Check(g90.yaw == 90.0 && Aligned(g90.pos.x, 1) && Aligned(g90.pos.y, 2), "grid: facing 90, the footprint turns with you");
nick.angles = QAngle(0, 0, 0);
PlaceAt(nick, ::Fort.Blueprints[Bp("barrier")], Vector(100, 0, 0));
local bottom = Newest();
PlaceAt(nick, ::Fort.Blueprints[Bp("sandbags")], Vector(100, 0, 48), 0, bottom);
local topper = Newest();
Check(topper.supports.find(bottom) != null && !topper.grounded, "stack: the upper prop is held by the lower");
local spentAll = ::Fort.Scrap;
Tap(nick, WALK);
::Aimed = bottom.ent;
::AimedAt = Vector(100, 0, 20);
TakeBack(nick);
Check(::Fort.Pieces.len() == 0 && ::Fort.Scrap == spentAll + ::Fort.Blueprints[Bp("barrier")].cost + ::Fort.Blueprints[Bp("sandbags")].cost,
	"stack: taking back the bottom takes the stack, all refunded");
::Aimed = null;
::AimedAt = null;
Check(Bp("scaffold") >= 0 && Bp("wood stairs") >= 0 && Bp("container") >= 0, "height: scaffold, stairs, container");

Survival();
nick = MakeSurvivor();
::Fort.Scrap = 1000;
PlaceAt(nick, ::Fort.Blueprints[Bp("scaffold")], Vector(0, 0, 0));
local tower = Newest();
::Boxes.append({ ent = tower.ent, lo = Vector(-70, -160, 0), hi = Vector(70, 160, 240) });
nick.origin = Vector(0, 0, 240);
nick.props.m_hGroundEntity <- tower.ent;
local fl = ::Fort.Blueprints[Bp("floor")];
local below = { pos = Vector(200, 0, 0), hit = true, enthit = Entities.First() };
local lp = ::Fort.StructPlan(nick, ::Fort.StateOf(nick), fl, below, null);
Check(lp != null && fabs(lp.pos.z - 240.0) < 0.5 && lp.supports.find(tower) != null && !lp.grounded, "ledge: out past the scaffold, at your feet, held by it");
::Fort.Place(nick, fl, lp);
local ledge = Newest();
::Fort.StartWave(1);
foreach (i, pc in ::Fort.Pieces)
	if (pc == tower)
		::Fort.Break(i, pc);
Check(!ledge.ent.valid, "ledge: the scaffold breaks, the ledge falls");
nick.origin = Vector(0, 0, 0);
::Fort.Sizes.clear();

Survival();
nick = MakeSurvivor();
local bot = MakeSurvivor("Coach", 3);
bot.bot = true;
::Fort.OnGameEvent_survival_round_start({});
Check(::Fort.Phase == "wave" && ::Fort.Wave == 1, "wave: the survival button starts wave 1");
Check(!::Fort.Building(), "wave: no building");
Check(Events(nick, "give").len() == 1 && Events(bot, "give").len() == 1, "wave: everyone gets a gun");
Check(::Fort.WaveLength(1) == ::Fort.WaveBase && ::Fort.WaveLength(3) > ::Fort.WaveLength(2), "wave: each wave longer");
Check(::Fort.TankCount(1) == 0 && ::Fort.TankCount(3) == 0 && ::Fort.TankCount(4) == 1 && ::Fort.TankCount(7) == 2, "wave: tanks from wave 4");
Check(::Fort.Options(1).TankLimit == 0 && ::Fort.Options(1).ProhibitBosses, "wave: the director's own tanks stay off");
Check(::Fort.Options(1).MaxSpecials < ::Fort.Options(2).MaxSpecials && ::Fort.Options(2).MaxSpecials < ::Fort.Options(3).MaxSpecials, "wave: more specials every wave");
Check(::Fort.Options(1).CommonLimit < ::Fort.Options(3).CommonLimit, "wave: bigger hordes");
Check(::Fort.Options(1).DominatorLimit == 3 && ::Fort.Options(4).DominatorLimit == 6, "wave: hd4l Fort keeps its pinners");
Check(::SessionOptions.MaxSpecials == ::Fort.Options(1).MaxSpecials, "wave: the director gets the wave's numbers");
local w = ::Fort.WaveHud(nick);
Check(w.state == 1 && w.wave == 1 && w.seconds == ::Fort.WaveBase.tointeger(), "wave: HUD shows wave 1 and its seconds");

local start = ::Fort.Scrap;
::Fort.OnGameEvent_infected_death({});
local hunter = MakeSpecial(3, 250, 60);
::Fort.OnGameEvent_player_death({ userid = 60 });
local tank = MakeSpecial(8, 6000, 61);
::Fort.OnGameEvent_player_death({ userid = 61 });
Check(::Fort.Scrap == start + ::Fort.KillScrap.common + ::Fort.KillScrap.special + ::Fort.KillScrap.tank, "wave: kills pay scrap");

local gun = Ent("weapon_rifle");
local kit2 = Ent("weapon_first_aid_kit");
local axe2 = Ent("weapon_melee");
axe2.props.m_strMapSetScriptName <- "fireaxe";
::Inv[1] <- { slot0 = gun, slot1 = axe2, slot3 = kit2 };
local z = Ent("infected");
start = ::Fort.Scrap;
::T.now += ::Fort.WaveBase + 1.0;
::Fort.WaveTick(Time());
Check(::Fort.Phase == "break" && ::Fort.Building(), "break: the wave ended, building open");
Check(::Fort.Scrap == start + ::Fort.BonusPerWave, "break: wave bonus");
Check(!gun.valid && kit2.valid && axe2.valid, "break: guns gone, the axe and items kept");
Check(!z.valid, "break: the wave's infected cleared");
Check(::SessionOptions.CommonLimit == 0 && ::SessionOptions.MaxSpecials == 0, "break: the director calm");
w = ::Fort.WaveHud(nick);
Check(w.state == 2 && w.wave == 2 && w.seconds == ::Fort.BreakSeconds.tointeger(), "break: HUD shows the countdown to wave 2");

start = ::Fort.Scrap;
::Fort.OnGameEvent_infected_death({});
Check(::Fort.Scrap == start, "break: no kill scrap");
local stray = Ent("infected");
::T.now += 1.0;
::Fort.BreakTick(Time());
Check(!stray.valid, "break: strays removed");

::T.now += ::Fort.BreakSeconds;
::Fort.BreakTick(Time());
Check(::Fort.Phase == "wave" && ::Fort.Wave == 2, "break: wave 2 starts");
Check(::Fort.PhaseUntil - Time() == ::Fort.WaveLength(2), "wave 2: longer");
Check(Events(nick, "give").len() == 2, "wave 2: another random gun");

Check(::Fort.PanicEvery(1) > ::Fort.PanicEvery(3) && ::Fort.PanicEvery(10) >= 6.0, "pressure: panics come faster each wave");
Check(::Fort.Keep(1) < ::Fort.Keep(3) && ::Fort.Keep(20) <= 16, "pressure: more specials kept up each wave");
local panicAt = ::Fort.NextPanic;
::T.now += 40.0;
::Fort.Pressure(Time());
Check(::Fort.NextPanic > panicAt, "pressure: a panic forced, the next one scheduled");

::Fort.StartWave(4);
Check(::Fort.Tanks.len() == 1, "wave 4: a tank on the schedule");
::Fort.StartWave(7);
Check(::Fort.Tanks.len() == 2, "wave 7: two");

Survival();
nick = MakeSurvivor();
::Fort.Scrap = 2000;
PlaceAt(nick, ::Fort.Blueprints[Bp("sandbags")], Vector(500, 0, 0), 0);
local piece = Newest();
::Fort.StartWave(1);
for (local i = 0; i < 6; i++) {
	local c = Ent("infected");
	c.origin = piece.pos + Vector(10, 0, 0);
}
start = piece.health;
::T.now += 1.0;
::Fort.WearTick(Time());
Check(piece.health < start, "wear: commons grind a wall");
piece.health = 1.0;
::T.now += 1.0;
::Fort.WearTick(Time());
Check(!piece.ent.valid && ::Fort.Pieces.len() == 0, "wear: a worn out piece breaks");

Survival();
nick = MakeSurvivor();
::Fort.Scrap = 2000;
PlaceAt(nick, ::Fort.Blueprints[Bp("razorwire")], Vector(500, 0, 0), 0);
PlaceAt(nick, ::Fort.Blueprints[Bp("mine")], Vector(-500, 0, 0), 0);
PlaceAt(nick, ::Fort.Blueprints[Bp("fire barricade")], Vector(0, 500, 0), 0);
::Fort.StartWave(1);
local cut = Ent("infected");
cut.origin = Vector(500, 0, 0);
local burnt = Ent("infected");
burnt.origin = Vector(0, 500 + 40, 0);
local walker = Ent("infected");
walker.origin = Vector(-500, 20, 0);
local far = Ent("infected");
far.origin = Vector(-500, 200, 0);
::T.now += 1.0;
::Fort.WearTick(Time());
Check(Events(cut, "damage").len() == 1, "wire: cuts what walks through");
Check(Events(burnt, "damage").len() == 1 && Events(burnt, "damage")[0].type == 8, "fire: burns what stands against it");
Check(Events(walker, "damage").len() == 1 && Events(far, "damage").len() == 1, "mine: goes off, the blast reaches further");
local mines = 0;
foreach (i, pc in ::Fort.Pieces)
	if (pc.kind == "mine")
		mines++;
Check(mines == 0, "mine: one use");

::g_ModeScript <- {};
Load("parts/core/addon/scripts/vscripts/hd4l_core.nut");
Load("parts/no-incap/addon/scripts/vscripts/no_incap.nut");
Survival();
nick = MakeSurvivor();
::Fort.Scrap = 500;
PlaceAt(nick, ::Fort.Blueprints[Bp("sandbags")], Vector(500, 0, 0), 0);
foreach (i, pc in ::Fort.Pieces)
	piece = pc;
Check(piece.ent.cls == "prop_physics_override" && piece.ent.kv.spawnflags == 8 && piece.ent.kv.health == ::Fort.PropHealth,
	"break: walls are motion locked physics props with health, something to punch");
PlaceAt(nick, ::Fort.Blueprints[Bp("razorwire")], Vector(-500, 0, 0), 0);
local wireKind = null;
foreach (i, pc in ::Fort.Pieces)
	if (pc.kind == "wire")
		wireKind = pc.ent.cls;
Check(wireKind == "prop_dynamic_override", "break: wire stays a plain prop (nothing to walk into)");
local zombie = Ent("infected");
local t = { Victim = piece.ent, Attacker = zombie, DamageDone = 40.0, DamageType = 128 };
Check(::g_ModeScript.AllowTakeDamage(t) == false && piece.health == piece.max, "break: no wear before the wave, the hit refused");
::Fort.StartWave(1);
Check(::g_ModeScript.AllowTakeDamage(t) == false && piece.health == piece.max - 40.0 * ::Fort.HitScale, "break: a common's punch wears it (times HitScale), the prop keeps its own health");
t = { Victim = piece.ent, Attacker = nick, DamageDone = 40.0, DamageType = 2 };
Check(::g_ModeScript.AllowTakeDamage(t) == false && piece.health == piece.max - 40.0 * ::Fort.HitScale, "break: survivors shooting their own fort do nothing");
local smasher = MakeSpecial(8, 6000, 70);
t = { Victim = piece.ent, Attacker = smasher, DamageDone = 2000.0, DamageType = 128 };
::g_ModeScript.AllowTakeDamage(t);
Check(!piece.ent.valid, "break: a tank punch through it breaks it");
local other = Ent("prop_physics");
t = { Victim = other, Attacker = zombie, DamageDone = 40.0, DamageType = 128 };
Check(::g_ModeScript.AllowTakeDamage(t) != false, "break: other props untouched");

Survival();
nick = MakeSurvivor();
::Fort.Scrap = 500;
PlaceAt(nick, ::Fort.Blueprints[Bp("barrier")], Vector(500, 0, 0), 0);
local idx = null;
foreach (i, pc in ::Fort.Pieces) {
	idx = i;
	piece = pc;
}
piece.ent.valid = false;
::Fort.Recheck(idx);
Check(::Fort.Pieces.len() == 1, "recheck: the piece stands again");
foreach (i, pc in ::Fort.Pieces)
	piece = pc;
Check(piece.ent.cls == "prop_dynamic_override" && piece.ent.valid, "recheck: as a plain prop");

Load("parts/hyper-feedback/addon/scripts/vscripts/hyper_feedback.nut");
function Sent(tag) {
	local out = [];
	foreach (f in Fired("Command"))
		if (typeof f.param == "string" && f.param.find("name2 ") == 0) {
			local v = f.param.slice(6).tointeger();
			if (v / 1000000 == tag)
				out.append(v % 1000000);
		}
	return out;
}
Survival();
nick = MakeSurvivor();
::Fort.Scrap = 75;
local st = ::HyperFeedback.PlayerState(nick);
::HyperFeedback.PanelFort(st, nick, true);
local v = Sent(8);
Check(v.len() == 1 && v[0] == 0 + 11 * (0 + 11 * (8 + 11 * (6 + 11 * 1))), "hud: scrap 75 is blank blank 7 5, shown");
Check(Sent(9).len() == 1 && Sent(9)[0] == 0, "hud: no cost while not building");
v = Sent(10);
Check(v.len() == 1 && v[0] == 0 + 11 * (2 + 11 * (0 + 11 * (0 + 11 * (0 + 11 * 2)))), "hud: prep shows wave 1 coming, no countdown");
Tap(nick, WALK);
Choose(nick, "sandbags");
Press(nick, 0, 0);
::Fort.Scrap = 20;
::T.fired.clear();
::HyperFeedback.PanelFort(st, nick, true);
v = Sent(9);
Check(v.len() == 1 && v[0] == 0 + 21 * (0 + 21 * (14 + 21 * (11 + 21 * 1))), "hud: sandbags 30 in blood with 20 scrap");
::Fort.OnGameEvent_survival_round_start({});
::T.fired.clear();
::HyperFeedback.PanelFort(st, nick, true);
v = Sent(10);
Check(v.len() == 1 && v[0] == 0 + 11 * (2 + 11 * (0 + 11 * (10 + 11 * (1 + 11 * 1)))), "hud: wave 1 with 90 seconds");
Check(Sent(8).len() == 1 && Sent(8)[0] / (11 * 11 * 11 * 11) == 1, "hud: scrap stays up in a wave");
Reset();
::T.mode = "hd4l";
::Fort.OnGameEvent_round_start({});
nick = MakeSurvivor();
::HyperFeedback.Players.clear();
st = ::HyperFeedback.PlayerState(nick);
::HyperFeedback.PanelFort(st, nick, true);
Check(Sent(8).len() == 0 && Sent(9).len() == 0 && Sent(10).len() == 0, "hud: coop never sends the fort tags");

Reset();
::T.mode = "hd4lfort";
::Aimed = null;
::Inv.clear();
::Fort.OnGameEvent_round_start({});
Check(::Fort.Phase == "prep", "fort mode: Fort runs");
local wanted = [ "fort", "no_incap", "self_defib", "bot_takeover", "death_shockwave", "firepower", "arsenal", "hyper_feedback", "chapter_stats" ];
local skipped = [ "momentum", "glory_kill2", "escalation", "infected_moves", "armour", "bodyguard", "witch_escort", "item_spin",
                  "bile_flash", "adrenaline_supply", "door_blast", "one_life", "projectiles" ];
local ok = true;
foreach (n in wanted)
	if (!::HD4L.Wanted(n)) { ok = false; print("    missing " + n + "\n"); }
Check(ok, "fort mode: the lives, the weapon buffs, the HUD and the stats load");
ok = true;
foreach (n in skipped)
	if (::HD4L.Wanted(n)) { ok = false; print("    wrongly on " + n + "\n"); }
Check(ok, "fort mode: no movement, no infected or director changes, no glory kills");
Check(::Fort.Options(1).DominatorLimit == 1 && ::Fort.Options(20).DominatorLimit <= ::Fort.StockDominators, "fort mode: one pinner, never more than two");
Check(::Fort.StockSpecials.find(1) == null && ::Fort.StockSpecials.find(3) == null && ::Fort.StockSpecials.find(5) == null
	&& ::Fort.StockSpecials.find(6) == null, "fort mode: Fort's own top up spawns no pinners");
Check(::HD4L.Active() && ::HD4L.Survival(), "fort mode: a Hyper Dead survival mode to the core");
Check(::HyperFeedback.ModeAllowed() && ::HyperFeedback.Lite(), "fort mode: the HUD in its lite form");
Check(::NoIncap.ModeAllowed(), "fort mode: no incaps");
local stockp = MakeSurvivor();
stockp.props["m_Local.m_iHideHUD"] <- 0;
::HyperFeedback.HideStock(stockp);
Check(stockp.props["m_Local.m_iHideHUD"] == 0, "fort mode: the stock health and team panels stay");
::T.fired.clear();
local lst = ::HyperFeedback.PlayerState(stockp);
::HyperFeedback.PanelFlash(stockp, "kill");
::HyperFeedback.PanelFlash(stockp, "dmg_front");
Check(Sent(1).len() == 0 && lst.mark == "", "fort mode: no hit or kill marks, no damage arcs");
::T.fired.clear();
stockp.health = 87;
::HyperFeedback.PanelSend5(lst, true);
Check(Sent(5).len() == 1 && Sent(5)[0] % (11 * 11 * 11 * 11) == 10 + 11 * (10 + 11 * (10 + 11 * 10)), "fort mode: HD4L's health number sends blanks (no stray 0000)");
::T.fired.clear();
lst.chain = 7;
::HyperFeedback.Resync = true;
::HyperFeedback.PanelTick();
Check(Sent(1).len() >= 1 && (Sent(1)[0] / 16200) % 2 == 0, "fort mode: no dot crosshair");
Check(Sent(6).len() >= 1 && Sent(6)[0] == 10 + 11 * 10, "fort mode: no kill chain");
Check(Sent(11).len() >= 1 && Sent(11)[0] == 10 + 11 * (10 + 11 * (6 + 7 * 10)), "fort mode: no timer");
::HyperFeedback.FeedKill(1, 9, false);
Check(::HyperFeedback.Feed.len() == 0, "fort mode: no kill feed");
Check(::HD4L.Plain(), "fort mode: the stock crosshair and kill feed");
::T.mode = "hd4lsurvival";
::HyperFeedback.HideStock(stockp);
Check(stockp.props["m_Local.m_iHideHUD"] != 0, "hd4l fort: the full HUD as before");
::T.fired.clear();
::HyperFeedback.Resync = true;
::HyperFeedback.PanelTick();
Check(!::HD4L.Plain() && Sent(1).len() >= 1 && (Sent(1)[0] / 16200) % 2 == 1, "hd4l fort: the dot crosshair");

Reset();
::T.mode = "hd4lfreebuild";
::Aimed = null;
::Inv.clear();
::Fort.OnGameEvent_round_start({});
Check(::Fort.Phase == "prep" && ::Fort.Scrap == ::Fort.ScrapCap, "freebuild: Fort runs, scrap full");
nick = MakeSurvivor();
PlaceAt(nick, ::Fort.Blueprints[Bp("container")], Vector(300, 0, 0));
Check(::Fort.Scrap < ::Fort.ScrapCap, "freebuild: building spends");
::T.now += 0.1;
::Fort.Tick(::Fort.Generation);
Check(::Fort.Scrap == ::Fort.ScrapCap, "freebuild: and it is full again");
Check(::HD4L.Active() && ::HD4L.Survival() && ::HD4L.Wanted("fort") && !::HD4L.Wanted("momentum"), "freebuild: the Fort mode's parts");
Check(::HyperFeedback.Lite() && ::NoIncap.ModeAllowed(), "freebuild: lite HUD, no incaps, like Fort");

function TwoBuilders() {
Reset();
::T.mode = "hd4lsurvival";
::Aimed = null;
::Inv.clear();
::Fort.OnGameEvent_round_start({});
local a = MakeSurvivor("Nick", 1);
local b = MakeSurvivor("Ellis", 2);
b.origin = Vector(0, 640, 0);
::Fort.Scrap = 2000;
foreach (pl in [ a, b ]) {
	pl.props.m_nButtons <- WALK;
	pl.props.m_afButtonPressed <- WALK;
}
::T.now += 0.1;
::Fort.Tick(::Fort.Generation);
foreach (pl in [ a, b ])
	pl.props.m_nButtons <- 0;
::Fort.Tick(::Fort.Generation);
::Fort.Tick(::Fort.Generation);
Check(::Fort.StateOf(a).buildMode && ::Fort.StateOf(b).buildMode, "multiplayer: two players in build mode at once");
local n0 = ::Fort.Pieces.len();
::T.now += 1.0;
foreach (pl in [ a, b ])
	pl.props.m_nButtons <- ATTACK;
::Fort.Tick(::Fort.Generation);
Check(::Fort.Pieces.len() - n0 == 2 && ::Fort.StateOf(a).ghost != null && ::Fort.StateOf(b).ghost != null, "multiplayer: both see their ghost, both place in the same tick");
}
TwoBuilders();
function Collapse() {
	Reset();
	::T.mode = "hd4lsurvival";
	::Aimed = null;
	::Inv.clear();
	::Fort.OnGameEvent_round_start({});
	local nick = MakeSurvivor();
	::Fort.Scrap = 2000;
	local wallBp = ::Fort.Blueprints[Bp("wall")];
	PlaceAt(nick, wallBp, Vector(128, 64, 0));
	local lower = null;
	foreach (i, pc in ::Fort.Pieces)
		lower = pc;
	PlaceAt(nick, wallBp, Vector(128, 64, 128), 0, lower);
	local top = null;
	foreach (i, pc in ::Fort.Pieces)
		if (pc != lower)
			top = pc;
	::Fort.StartWave(1);
	local tank = MakeSpecial(8, 6000, 60);
	tank.angles = QAngle(0, 0, 0);
	::Fort.PieceHit({ Victim = lower.ent, Attacker = tank, DamageDone = 99999.0 });
	Check(!lower.ent.valid && !top.ent.valid, "collapse: the wall breaks, the one on it falls");
	local loose = ::T.spawned.filter(@(i, e) e.cls == "prop_physics_override" && ("targetname" in e.kv) && e.kv.targetname == "hd4l_fort_debris");
	Check(loose.len() == 2 && ::Fort.Debris.len() == 2, "collapse: both come loose as physics debris (" + loose.len() + ")");
	Check(loose[0].events.filter(@(i, ev) ev.what == "impulse" && ev.v.x > 500.0).len() == 1, "collapse: the tank's blow throws it along the punch");
	local common = Ent("infected");
	common.origin = loose[0].origin + Vector(10, 0, 0);
	loose[0].origin = loose[0].origin + Vector(40, 0, 0);
	common.origin = loose[0].origin;
	::T.now += 0.1;
	::Fort.Tick(::Fort.Generation);
	local hits = common.events.filter(@(i, ev) ev.what == "damage");
	Check(hits.len() == 1 && hits[0].amount == ::Fort.CrushDamage, "collapse: moving debris crushes a common");
	loose[0].origin = loose[0].origin + Vector(40, 0, 0);
	common.origin = loose[0].origin;
	::T.now += 0.1;
	::Fort.Tick(::Fort.Generation);
	Check(common.events.filter(@(i, ev) ev.what == "damage").len() == 1, "collapse: once each");
	::T.now += ::Fort.DebrisLife + 1.0;
	::Fort.Tick(::Fort.Generation);
	Check(::Fort.Debris.len() == 0 && !loose[0].valid, "collapse: debris clears after DebrisLife");
	foreach (name in [ "gas can", "propane tank", "oxygen tank", "fireworks" ])
		Check(Bp(name) >= 0 && ::Fort.Blueprints[Bp(name)].kind == "item" && ::Fort.Blueprints[Bp(name)].cat == "prop", "explosives: " + name + " can be built");
}
Collapse();

function Moving() {
	Reset();
	::T.mode = "hd4lsurvival";
	::Aimed = null;
	::Inv.clear();
	::Fort.OnGameEvent_round_start({});
	local nick = MakeSurvivor();
	::Fort.Scrap = 5000;
	local wallBp = ::Fort.Blueprints[Bp("wall")];
	PlaceAt(nick, wallBp, Vector(128, 64, 0));
	local w = null;
	foreach (i, pc in ::Fort.Pieces)
		w = pc;
	local landAt = w.origin;
	Check(w.ent.origin.z == landAt.z + ::Fort.DropHeight, "drop: a new piece starts DropHeight up");
	::T.now += ::Fort.DropTime + 0.01;
	::Fort.Tick(::Fort.Generation);
	Check(w.ent.origin.z == landAt.z && ::Fort.Dropping.len() == 0 && !("drop" in w), "drop: and lands where it belongs");
	::Fort.StateOf(nick).cellX = null;
	::Fort.StateOf(nick).faceYaw = null;
	nick.origin = Vector(0, 0, 0);
	nick.angles = QAngle(0, 0, 0);
	local doorBp = ::Fort.Blueprints[Bp("door")];
	local dp = ::Fort.StructPlan(nick, ::Fort.StateOf(nick), doorBp, ::Fort.Aim(nick, ::Fort.BuildRange), null);
	Check(dp.parts.len() == 5 && dp.slot == ::Fort.WallKey(128, 64, 0), "door: in a wall's slot, five frame boards");
	Check(fabs(dp.origins[0].x - 128.0) < 0.1 && fabs(dp.origins[0].y - (64.0 - ::Fort.DoorWidth * 0.5)) < 0.1 && fabs(dp.origins[0].z - 54.6) < 0.1,
		"door: hinged half a door right of the slot's middle (" + dp.origins[0] + ")");
	local lint = dp.parts[4];
	Check(lint.angles.z == 90.0 && fabs(lint.origin.z - 119.5) < 0.1, "door: the top board lies across over the door");
	::Fort.Place(nick, doorBp, dp);
	local door = null;
	foreach (i, pc in ::Fort.Pieces)
		if ("door" in pc.bp)
			door = pc;
	Check(door != null && door.ent.cls == "prop_door_rotating" && door.ent.kv.spawnflags == 8192, "door: a real rotating door");
	Check(door.fx.len() == 5 && ::Fort.PieceOf(door.fx[0]) == door, "door: its boards are part of it");
	::Aimed = door.ent;
	::T.now += 1.0;
	local board = door.fx[0];
	local was = ::Fort.Scrap;
	Tap(nick, WALK);
	TakeBack(nick);
	Check(!door.ent.valid && !board.valid && ::Fort.Scrap > was, "door: taken back, boards and all");
	::Aimed = null;
}
Moving();

function Climbing() {
	Reset();
	::T.mode = "hd4lsurvival";
	::Aimed = null;
	::Inv.clear();
	::Boxes.clear();
	::Fort.OnGameEvent_round_start({});
	local nick = MakeSurvivor();
	::Fort.Scrap = 2000;
	PlaceAt(nick, ::Fort.Blueprints[Bp("scaffold")], Vector(0, 0, 0));
	local tower = null;
	foreach (i, pc in ::Fort.Pieces)
		tower = pc.ent;
	::Boxes.append({ ent = tower, lo = Vector(-64, -64, 0), hi = Vector(64, 64, 200) });
	::Fort.StartWave(1);
	nick.origin = Vector(0, 0, 200);
	local below = Ent("infected");
	below.health = 50;
	below.origin = Vector(150, 0, 0);
	local far = Ent("infected");
	far.health = 50;
	far.origin = Vector(900, 0, 0);
	local level = Ent("infected");
	level.health = 50;
	level.origin = Vector(100, 0, 190);
	::T.now += 1.0;
	::Fort.Tick(::Fort.Generation);
	local leap = below.events.filter(@(i, ev) ev.what == "impulse");
	Check(leap.len() == 1 && leap[0].v.z > 0.0 && leap[0].v.x < 0.0, "climb: a common below leaps up toward the survivor on the fort");
	Check(fabs(leap[0].v.z - sqrt(2.0 * ::Fort.Gravity * (200.0 + ::Fort.ClimbClear))) < 1.0, "climb: high enough to land up there");
	Check(far.events.filter(@(i, ev) ev.what == "impulse").len() == 0, "climb: not from far away");
	Check(level.events.filter(@(i, ev) ev.what == "impulse").len() == 0, "climb: not one already up there");
	::T.now += 0.3;
	::Fort.Tick(::Fort.Generation);
	Check(below.events.filter(@(i, ev) ev.what == "impulse").len() == 1, "climb: once per cooldown");
	local hunter = MakeSpecial(3, 250, 60);
	hunter.origin = Vector(-120, 0, 0);
	::T.now += 0.3;
	::Fort.Tick(::Fort.Generation);
	Check(hunter.vel.z > 0.0, "climb: specials too");
	nick.origin = Vector(400, 400, 0);
	local calm = Ent("infected");
	calm.health = 50;
	calm.origin = Vector(450, 400, 0);
	::T.now += 2.0;
	::Fort.Tick(::Fort.Generation);
	Check(calm.events.filter(@(i, ev) ev.what == "impulse").len() == 0, "climb: nobody up, nobody leaps");
	nick.origin = Vector(0, 0, 200);
	local bot = MakeSurvivor("Ellis", 2);
	bot.bot = true;
	bot.origin = Vector(300, 0, 0);
	::T.now += 0.3;
	::Fort.Tick(::Fort.Generation);
	Check(bot.origin.z == 0.0, "bot lift: not at once");
	::T.now += ::Fort.BotLiftAfter + 0.3;
	::Fort.Tick(::Fort.Generation);
	Check(bot.origin.z > 190.0 && (bot.origin - nick.origin).Length() < 60.0, "bot lift: after BotLiftAfter, beside the human (" + bot.origin + ")");
	::Boxes.clear();
}
Climbing();

Done();
