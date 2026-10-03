::ROOT <- vargv.len() > 0 ? vargv[0] : ".";
dofile(::ROOT + "/tests/unit/mock.nut");
Suite("projectiles");

Load("parts/core/addon/scripts/vscripts/hd4l_core.nut");
Load("parts/projectiles/addon/scripts/vscripts/projectiles.nut");
local P = ::Projectiles;

::Target <- null;
::TraceLine <- function(t) {
	t.hit <- false; t.pos <- t.end; t.fraction <- 1.0;
	if (::Target == null || !::Target.valid || t.ignore == ::Target)
		return;
	local x = ::Target.origin.x;
	if (t.start.x <= x && t.end.x >= x) {
		t.hit = true;
		t.pos = Vector(x, t.start.y, t.start.z);
		t.enthit <- ::Target;
	}
};

function Setup() {
	Reset();
	P.Shots = {}; P.Flying = []; P.InHit = false;
	local p = MakeSurvivor("Nick", 1);
	p.origin = Vector(0, 0, 0);
	p.weapon = Ent("weapon_rifle");
	local c = Ent("infected");
	c.origin = Vector(800, 0, 0);
	c.health = 100;
	::Target = c;
	return [p, c];
}
function Fly(seconds) {
	local steps = (seconds / 0.01 + 0.5).tointeger();
	for (local i = 0; i < steps; i++) {
		::T.now += 0.01;
		foreach (pr in clone P.Flying) {}
		local still = [];
		foreach (pr in P.Flying)
			if (P.Step(pr, 0.01))
				still.append(pr);
		P.Flying = still;
	}
}

local s = Setup(); local p = s[0], c = s[1];
local dt = { Attacker = p, Victim = c, DamageDone = 33.0, DamageType = 2, Weapon = p.weapon };
Check(P.Intercept(dt) == true, "held: the stock hit is blocked");
P.OnGameEvent_bullet_impact({ userid = p.userid, x = 800.0, y = 0.0, z = 64.0 });
P.Launch(p.userid);
Check(P.Flying.len() == 1, "launch: one projectile for the ray");
Check(Events(c, "damage").len() == 0, "launch: nothing lands at once");
Fly(0.1);
Check(Events(c, "damage").len() == 0, "flight: 400 units in 0.1 s, not there yet");
Fly(0.12);
local hits = Events(c, "damage");
Check(hits.len() == 1 && hits[0].amount == 33.0 && hits[0].type == 2, "arrival: the held 33 lands after about 0.2 s");
Check(!P.InHit, "arrival: the hit flag is cleared");

s = Setup(); p = s[0]; c = s[1];
P.Intercept({ Attacker = p, Victim = c, DamageDone = 33.0, DamageType = 2, Weapon = p.weapon });
P.OnGameEvent_bullet_impact({ userid = p.userid, x = 800.0, y = 0.0, z = 64.0 });
P.Launch(p.userid);
c.origin = Vector(9000, 0, 0);
Fly(0.3);
Check(Events(c, "damage").len() == 0, "dodge: a victim that left the line takes nothing");

s = Setup(); p = s[0]; c = s[1];
local other = Ent("infected");
other.origin = Vector(400, 0, 0);
P.Intercept({ Attacker = p, Victim = c, DamageDone = 33.0, DamageType = 2, Weapon = p.weapon });
P.OnGameEvent_bullet_impact({ userid = p.userid, x = 800.0, y = 0.0, z = 64.0 });
P.Launch(p.userid);
::Target = other;
Fly(0.15);
local f = Events(other, "damage");
Near(f.len() ? f[0].amount : 0, 33.0 * pow(0.97, 400.0 / 500.0), "fresh: rifle 33 with its falloff", 0.01);

s = Setup(); p = s[0]; c = s[1];
::T.mode = "coop";
Check(P.Intercept({ Attacker = p, Victim = c, DamageDone = 33.0, DamageType = 2, Weapon = p.weapon }) == false, "vanilla: hits are not touched");
::T.mode = "hd4l";

Check(P.Intercept({ Attacker = p, Victim = c, DamageDone = 33.0, DamageType = 128, Weapon = p.weapon }) == false, "melee: not held");
local mg = Ent("prop_minigun");
Check(P.Intercept({ Attacker = p, Victim = c, DamageDone = 33.0, DamageType = 2, Weapon = mg }) == false, "mounted gun: not held");

P.InHit = true;
Check(P.Intercept({ Attacker = p, Victim = c, DamageDone = 33.0, DamageType = 2, Weapon = p.weapon }) == false, "replay: not held again");
P.InHit = false;

local pcf = "";
Check(P.Speed == 4000.0 && P.Tracer == "hd4l_projectile_tracer_4000", "speed 4000 and its tracer by default");

s = Setup(); p = s[0]; c = s[1];
foreach (k, v in P.Counts) P.Counts[k] = 0;
P.CheckLeak(p, c, 2, 33);
Check(P.Counts.leaks == 1, "leak: instant bullet damage is counted");
P.Ours[c.GetEntityIndex()] <- Time();
P.CheckLeak(p, c, 2, 33);
Check(P.Counts.leaks == 1, "leak: a landing this frame is ours, not counted");
P.CheckLeak(p, c, 128, 33);
Check(P.Counts.leaks == 1, "leak: melee is not a leak");

P.SetSpeed(2000);
Check(P.Tracer == "hd4l_projectile_tracer_2000" && P.Enabled, "speed 2000: its tracer, projectiles on");
P.SetSpeed(2600);
Check(P.Tracer == "hd4l_projectile_tracer_3000", "speed 2600: nearest tracer 3000");
P.SetSpeed(2000);
s = Setup(); p = s[0]; c = s[1];
P.Intercept({ Attacker = p, Victim = c, DamageDone = 33.0, DamageType = 2, Weapon = p.weapon });
P.OnGameEvent_bullet_impact({ userid = p.userid, x = 800.0, y = 0.0, z = 64.0 });
P.Launch(p.userid);
Fly(0.35);
Check(Events(c, "damage").len() == 0, "2000 u/s: not there after 0.35 s");
Fly(0.1);
Check(Events(c, "damage").len() == 1, "2000 u/s: there after 0.45 s");
P.SetEnabled(false);
Check(P.Intercept({ Attacker = p, Victim = c, DamageDone = 33.0, DamageType = 2, Weapon = p.weapon }) == false, "off: stock hitscan");
P.SetSpeed(4000);

s = Setup(); p = s[0]; c = s[1];
c.props.m_iRequestedWound1 <- -1;
c.props.m_iRequestedWound2 <- -1;
P.Wounds = {};
P.SnapWounds();
c.props.m_iRequestedWound1 = 7;
P.Intercept({ Attacker = p, Victim = c, DamageDone = 33.0, DamageType = 2, Weapon = p.weapon });
Check(c.props.m_iRequestedWound1 == -1, "wound: taken back in the same frame");
P.OnGameEvent_bullet_impact({ userid = p.userid, x = 800.0, y = 0.0, z = 64.0 });
P.Launch(p.userid);
Fly(0.1);
Check(c.props.m_iRequestedWound1 == -1, "wound: still clean in flight");
Fly(0.15);
Check(c.props.m_iRequestedWound1 == 7 && Events(c, "damage").len() == 1, "wound: lands with the projectile");

P.SendClientSettings();
Check(::T.cvars["violence_hblood"] == 0 && ::T.cvars["violence_ablood"] == 0, "blood: stock blood off in hd4l");
::T.mode = "coop";
P.SendClientSettings();
Check(::T.cvars["violence_hblood"] == 1, "blood: back on in vanilla");
::T.mode = "hd4l";

function Shoot(p, c) {
	P.Intercept({ Attacker = p, Victim = c, DamageDone = 33.0, DamageType = 2, Weapon = p.weapon });
	P.OnGameEvent_bullet_impact({ userid = p.userid, x = 800.0, y = 0.0, z = 64.0 });
	P.Launch(p.userid);
}
function Press(p) {
	p.props.m_nButtons <- 2048;
	P.ParryCheck();
	p.props.m_nButtons <- 0;
	P.ParryCheck();
}
s = Setup(); p = s[0]; c = s[1];
p.weapon = Ent("weapon_pumpshotgun");
p.weapon.props.m_iClip1 <- 6;
p.weapon.props.m_iPrimaryAmmoType <- 7;
P.LastShot = {}; P.ParryAt = {}; P.Pressed = {};
local mate = MakeSurvivor("Coach", 3);
mate.origin = Vector(790, 40, 0);
local near = Ent("infected");
near.origin = Vector(790, -60, 0);
near.health = 100;
Shoot(p, c);
::T.now += 0.05;
Press(p);
Check(P.Flying.len() == 1 && P.Flying[0].explosive && P.Flying[0].speed == P.ParrySpeed, "parry: in the window, the shot goes fast and explosive");
Check(::T.sounds.filter(@(i, x) x.sound == P.ParrySound).len() == 1, "parry: the gas leak hiss plays");
Check(p.weapon.props.m_iClip1 == 5, "parry: costs one more round from the clip");
Fly(0.1);
Check(Events(c, "damage").filter(@(i, e) e.amount == 33.0).len() == 1, "parry: the held hit still lands, sooner");
Check(Events(near, "damage").filter(@(i, e) e.type == 64).len() == 1, "parry: the blast hurts infected near the impact");
Check(Events(mate, "damage").len() == 0, "parry: the blast spares survivors");
Check(P.Counts.blasts >= 1, "parry: one blast");

s = Setup(); p = s[0]; c = s[1];
P.LastShot = {}; P.ParryAt = {}; P.Pressed = {};
Shoot(p, c);
::T.now += 0.15;
Press(p);
Check(P.Flying.len() == 0 || !P.Flying[0].explosive, "parry: outside the window nothing happens");

s = Setup(); p = s[0]; c = s[1];
p.weapon.props.m_iClip1 <- 20;
P.LastShot = {}; P.ParryAt = {}; P.Pressed = {};
Shoot(p, c);
::T.now += 0.05;
Press(p);
Check(P.Flying.len() == 1 && !P.Flying[0].explosive && p.weapon.props.m_iClip1 == 20, "parry: a rifle cannot parry, no round taken");
foreach (auto in [ "weapon_autoshotgun", "weapon_shotgun_spas" ]) {
	s = Setup(); p = s[0]; c = s[1];
	p.weapon = Ent(auto);
	P.LastShot = {}; P.ParryAt = {}; P.Pressed = {};
	Shoot(p, c);
	::T.now += 0.05;
	Press(p);
	Check(P.Flying.len() == 1 && !P.Flying[0].explosive, "parry: " + auto + " cannot parry");
}
s = Setup(); p = s[0]; c = s[1];
p.weapon = Ent("weapon_hunting_rifle");
p.weapon.props.m_iClip1 <- 0;
p.weapon.props.m_iPrimaryAmmoType <- 2;
p.props["m_iAmmo2"] <- 0;
P.LastShot = {}; P.ParryAt = {}; P.Pressed = {};
Shoot(p, c);
::T.now += 0.05;
Press(p);
Check(P.Flying.len() == 1 && !P.Flying[0].explosive, "parry: no round to spare, no parry");
p.props["m_iAmmo2"] <- 10;
P.LastShot = {}; P.ParryAt = {}; P.Pressed = {};
P.Flying = [];
Shoot(p, c);
::T.now += 0.05;
Press(p);
Check(P.Flying.len() == 1 && P.Flying[0].explosive && p.props["m_iAmmo2"] == 9, "parry: an empty clip pays from the reserve");

s = Setup(); p = s[0]; c = s[1];
p.weapon = Ent("weapon_pumpshotgun");
p.weapon.props.m_iClip1 <- 6;
P.LastShot = {}; P.ParryAt = {}; P.Pressed = {}; P.Flying = [];
local tank = MakeSpecial(8, 6000, 70);
tank.origin = Vector(800, 20, 0);
local hunter = MakeSpecial(3, 250, 71);
hunter.origin = Vector(800, 10, 20);
local farHunter = MakeSpecial(3, 250, 72);
farHunter.origin = Vector(800, 130, 0);
local near2 = Ent("infected");
near2.origin = Vector(790, -40, 0);
near2.health = 100;
Shoot(p, c);
::T.now += 0.05;
Press(p);
Fly(0.1);
Check(Events(near2, "damage").filter(@(i, e) e.type == 64).len() == 1, "blast: commons take it as blast");
Check(Events(tank, "damage").filter(@(i, e) e.type == 0).len() == 1 && Events(tank, "stagger").len() == 0, "blast: a tank takes plain damage, no stagger");
Check(Events(hunter, "stagger").len() == 1, "blast: a special at the centre staggers");
Check(Events(farHunter, "stagger").len() == 0 && Events(farHunter, "damage").len() == 1, "blast: a special further out is hurt, not staggered");

Done();
