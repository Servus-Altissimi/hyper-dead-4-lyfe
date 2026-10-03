::ROOT <- vargv.len() > 0 ? vargv[0] : ".";
dofile(::ROOT + "/tests/unit/mock.nut");
Suite("parry");

Load("parts/core/addon/scripts/vscripts/hd4l_core.nut");
Load("parts/momentum/addon/scripts/vscripts/momentum.nut");
foreach (file in ::Momentum.Files)
	Load("parts/momentum/addon/scripts/vscripts/" + file + ".nut");

function Setup() {
	Reset();
	::Momentum.State.clear();
	::Momentum.Rocks.clear();
	::Momentum.Spits.clear();
	local p = MakeSurvivor();
	p.angles = QAngle(0, 0, 0);
	return p;
}

function Shove(p) {
	local s = ::Momentum.StateOf(p);
	s.stamina = 100.0;
	s.nextShove = 0.0;
	p.props.m_nButtons = 2048;
	p.props.m_flNextShoveTime <- Time() + 0.7;
	::Momentum.ShoveStaminaCheck(p, s, 2048, 2048, Time());
	return s;
}

local nick = Setup();
local s = Shove(nick);
Near(s.parryUntil - Time(), ::Momentum.ParryWindow, "shove opens a 0.2 s parry window");

local tank = MakeSpecial(8, 6000, 51);
tank.origin = Vector(800, 0, 0);
local rock = Ent("tank_rock");
rock.origin = Vector(100, 0, 64);
rock.vel = Vector(-900, 0, 0);
rock.props.m_hThrower <- tank;
::T.now += 0.1;
::Momentum.ParryCheck(nick, s);
Check(rock.vel.x > 1000, "rock reversed toward the tank (vx " + rock.vel.x + ")");
Check(rock.props.m_hThrower == nick, "rock now thrown by the survivor");
Check(rock.index in ::Momentum.Rocks && ::Momentum.Rocks[rock.index].tank == tank, "rock tracked with its tank");
Check(::T.sounds.filter(@(i, x) x.sound == ::Momentum.Sounds.Parry).len() == 1, "parry clang");
Check(Spawned("env_fade").len() == 1 && Spawned("env_fade")[0].kv.spawnflags == "5", "parry: white flash to the parrier only");

local vx = rock.vel.x;
rock.vel = Vector(-900, 0, 0);
::Momentum.ParryCheck(nick, s);
Check(rock.vel.x == -900, "no second parry of the same rock in one window");

nick = Setup();
s = Shove(nick);
nick.angles = QAngle(0, 90, 0);
tank = MakeSpecial(8, 6000, 51);
tank.origin = Vector(800, 0, 0);
rock = Ent("tank_rock");
rock.origin = Vector(0, 100, 64);
rock.vel = Vector(0, -900, 0);
rock.props.m_hThrower <- tank;
::Momentum.ParryCheck(nick, s);
Check(rock.vel.y > 1000 && fabs(rock.vel.x) < 50, "off-target parry follows the view");

nick = Setup();
s = Shove(nick);
rock = Ent("tank_rock");
rock.origin = Vector(-100, 0, 64);
rock.vel = Vector(900, 0, 0);
::Momentum.ParryCheck(nick, s);
Check(rock.vel.x == 900, "rock behind you: untouched");

nick = Setup();
s = Shove(nick);
rock = Ent("tank_rock");
rock.origin = Vector(100, 0, 64);
rock.vel = Vector(-900, 0, 0);
::Momentum.ParryCheck(nick, s);
Check(rock.vel.x > 1000, "rock without a thrower still parried");

nick = Setup();
s = Shove(nick);
tank = MakeSpecial(8, 6000, 51);
tank.origin = Vector(300, 0, 0);
tank.angles = QAngle(0, 180, 0);
rock = Ent("tank_rock");
rock.origin = Vector(100, 0, 64);
rock.vel = Vector(-900, 0, 0);
rock.props.m_hThrower <- tank;
::Momentum.ParryCheck(nick, s);
rock.origin = Vector(250, 0, 64);
::Momentum.TankParryCheck(tank, false);
Check(rock.props.m_hThrower == tank && rock.vel.x < 0, "tank bats it back at the survivor");

nick = Setup();
s = Shove(nick);
local spitter = MakeSpecial(4, 100, 52);
spitter.origin = Vector(600, 0, 0);
local spit = Ent("spitter_projectile");
spit.origin = Vector(80, 0, 64);
spit.vel = Vector(-700, 0, 0);
spit.props.m_hThrower <- spitter;
::Momentum.ParryCheck(nick, s);
Check(spit.vel.x > 1000, "spit sent back at the spitter");
Check(spit.props.m_hThrower == nick, "spit now thrown by the survivor");
Check(spit.index in ::Momentum.Spits, "spit tracked");

local hunter = MakeSpecial(3, 250, 53);
hunter.origin = Vector(600, 0, 0);
local common = Ent("infected");
common.origin = Vector(620, 20, 0);
nick.origin = Vector(0, 0, 0);
spit.origin = Vector(600, 0, 0);
::Momentum.OnGameEvent_spit_burst({ userid = spitter.userid, subject = spit.index });
Check(!(spit.index in ::Momentum.Spits), "burst consumes the tracked spit");
Check(Events(common, "damage").len() == 1 && Events(common, "damage")[0].amount == ::Momentum.SpitBurstDamage, "burst hurts commons");
Check(Events(hunter, "stagger").len() == 1, "burst staggers specials");
Check(Events(nick, "damage").len() == 0, "burst never hurts the survivor");
Check(Fired("RunScriptCode").filter(@(i, f) f.param.find("DrainPool") != null).len() == 1, "pool drained after the burst");
local pool = Ent("insect_swarm");
pool.origin = Vector(600, 0, 0);
::Momentum.DrainPool(Vector(600, 0, 0));
Check(!pool.valid, "the acid pool is removed");

nick = Setup();
local other = Ent("spitter_projectile");
other.origin = Vector(500, 0, 0);
::Momentum.OnGameEvent_spit_burst({ userid = 52, subject = other.index });
Check(Fired("RunScriptCode").len() == 0, "normal spit: no burst");

nick = Setup();
::Momentum.SpitParry = false;
s = Shove(nick);
spit = Ent("spitter_projectile");
spit.origin = Vector(80, 0, 64);
spit.vel = Vector(-700, 0, 0);
::Momentum.ParryCheck(nick, s);
Check(spit.vel.x == -700, "SpitParry off: spit untouched");
::Momentum.SpitParry = true;

Done();
