::ROOT <- vargv.len() > 0 ? vargv[0] : ".";
dofile(::ROOT + "/tests/unit/mock.nut");
Suite("death shockwave");

Load("parts/core/addon/scripts/vscripts/hd4l_core.nut");
Load("parts/death-shockwave/addon/scripts/vscripts/death_shockwave.nut");

function Fresh() {
	Reset();
	::DeathShockwave.Active.clear();
}

function Rings() {
	local done = 0;
	while (done < ::T.fired.len()) {
		local f = ::T.fired[done++];
		if (f.input == "RunScriptCode" && f.param.find("DeathShockwave.Ring") != null)
			compilestring(f.param)();
	}
}

function Common(x, health = 50, z = 0) {
	local c = Ent("infected");
	c.health = health;
	c.origin = Vector(x, 0, z);
	return c;
}

function Died(player) {
	::DeathShockwave.OnGameEvent_player_death({ userid = player.userid });
}

function Quiet() {
	foreach (e in ::T.ents)
		if (e.events.len() > 0)
			return false;
	return true;
}

foreach (mode in [ "coop", "versus", "hd4lversus" ]) {
	Fresh();
	::T.mode = mode;
	local nick = MakeSurvivor();
	Common(100);
	Died(nick);
	Rings();
	Check(Quiet() && ::DeathShockwave.Active.len() == 0, mode + ": no shockwave");
}

foreach (mode in [ "hd4l", "hd4lsurvival", "hd4lfort", "hd4lfreebuild" ]) {
	Fresh();
	::T.mode = mode;
	local nick = MakeSurvivor();
	local c = Common(100);
	Died(nick);
	Check(Events(c, "damage").len() == 1, mode + ": shockwave fires");
}

Fresh();
local ok = true;
try {
	::DeathShockwave.OnGameEvent_player_death({});
	::DeathShockwave.OnGameEvent_player_death({ userid = 999 });
	local gone = MakeSurvivor("Ellis", 2);
	gone.valid = false;
	Died(gone);
	::DeathShockwave.Ring(12345);
} catch (e) {
	ok = false;
}
Check(ok && ::DeathShockwave.Active.len() == 0, "bad params: no throw, no wave");

Fresh();
local bot = MakeSurvivor("Coach", 3);
bot.bot = true;
local smoker = MakeSpecial(1, 250, 51);
local c = Common(100);
Died(bot);
Died(smoker);
Check(Quiet(), "bot survivor and infected deaths spared");

Fresh();
local nick = MakeSurvivor();
local ally = MakeSurvivor("Rochelle", 2);
ally.origin = Vector(50, 0, 0);
local near = Common(100);
local high = Common(100, 50, 200);
local far = Common(800);
local special = MakeSpecial(1, 250, 51);
special.origin = Vector(0, 300, 0);
local ghost = MakeSpecial(3, 250, 52);
ghost.ghost = true;
ghost.origin = Vector(0, 100, 0);
local tank = MakeSpecial(8, 6000, 53);
tank.origin = Vector(-200, 0, 0);
local witch = Ent("witch");
witch.health = 1500;
witch.origin = Vector(0, -400, 0);

Died(nick);
Check(Events(near, "damage").len() == 1 && Events(special, "damage").len() == 0, "ring 1: only within 150u");
Rings();

local hit = Events(near, "damage");
Check(hit.len() == 1 && hit[0].amount == 1000 && hit[0].type == 128 && hit[0].attacker == nick, "common: 1000 club from the dead survivor");
local push = Events(near, "impulse");
Check(push.len() == 1 && push[0].v.x > 0 && push[0].v.z == 300.0 && Events(near, "stagger").len() == 0, "lethal hit launches away, no stagger");
Check(Events(special, "damage").len() == 1 && Events(special, "damage")[0].amount == 1000, "special: 1000");
local th = Events(tank, "damage");
Check(th.len() == 1 && th[0].amount == 1500 && Events(tank, "stagger").len() == 1 && Events(tank, "impulse").len() == 0, "tank: 1500 and staggered");
Check(Events(witch, "damage").len() == 1 && Events(witch, "damage")[0].amount == 1000 && Events(witch, "stagger").len() == 1, "witch: 1000 and staggered");
Check(ally.events.len() == 0 && nick.events.len() == 0, "survivors spared");
Check(ghost.events.len() == 0, "ghost spared");
Check(far.events.len() == 0, "beyond 750u spared");
Check(high.events.len() == 0, "beyond z tolerance spared");
local runs = Fired("RunScriptCode");
Check(runs.len() == 4 && runs[0].delay == 0.12, "five rings, 0.12s apart");
Check(::DeathShockwave.Active.len() == 0, "wave forgotten after last ring");
Check(Spawned("info_particle_system").len() == 1 && Spawned("env_physexplosion").len() == 1, "centre pound and push once");

Fresh();
nick = MakeSurvivor();
local tough = Common(100, 5000);
local dead = MakeSpecial(2, 250, 51);
dead.dead = true;
dead.origin = Vector(50, 0, 0);
Died(nick);
nick.valid = false;
Rings();
Check(Events(tough, "damage").len() == 1 && Events(tough, "stagger").len() == 1 && Events(tough, "impulse").len() == 0, "non-lethal hit staggers, hit once");
Check(dead.events.len() == 0, "dead special spared");

Fresh();
nick = MakeSurvivor();
local late = Common(700);
Died(nick);
nick.valid = false;
Rings();
local lh = Events(late, "damage");
Check(lh.len() == 1 && lh[0].attacker == ::Entities.First(), "gone survivor: world is the attacker");

Check(::DeathShockwave.ModeAllowed() && ("hd4l_death_shockwave" in ::GameEventCallbacks), "hook marker set");

Done();
