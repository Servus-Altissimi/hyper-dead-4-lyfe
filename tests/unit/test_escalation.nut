::ROOT <- vargv.len() > 0 ? vargv[0] : ".";
dofile(::ROOT + "/tests/unit/mock.nut");
Suite("escalation");

Load("parts/core/addon/scripts/vscripts/hd4l_core.nut");
Load("parts/escalation/addon/scripts/vscripts/escalation.nut");

function Spawned(tank) {
	::Escalation.OnGameEvent_tank_spawn({ userid = tank.userid, tankid = tank.GetEntityIndex() });
}

function Kicks() {
	return ::T.fired.filter(@(i, f) f.input == "ServerCommand" && f.param.find("kickid") == 0);
}

Reset();
::Escalation.PendingTanks = 0;
Ent("trigger_finale");
local first = MakeSpecial(8, 6000, 60);
Spawned(first);
Check(Kicks().len() == 0, "finale: the first tank stays");
local second = MakeSpecial(8, 6000, 61);
Spawned(second);
Check(Kicks().len() == 1 && Kicks()[0].param == "kickid 61", "finale: the second tank is kicked");
Check(Fired("RunScriptCode").filter(@(i, f) f.param.find("SpawnTankNear") != null).len() == 0, "finale: no extra tanks added");

Reset();
::Escalation.PendingTanks = 0;
Ent("trigger_finale");
first = MakeSpecial(8, 6000, 60);
first.dead = true;
second = MakeSpecial(8, 6000, 61);
Spawned(second);
Check(Kicks().len() == 0, "finale: a tank after the first died stays");

Reset();
Ent("trigger_finale");
::Escalation.TankSeen = false;
::Escalation.TankDue = Time() - 1.0;
::Escalation.MaybeForceTank();
Check(::T.logs.filter(@(i, l) l.find("forcing a tank") != null).len() == 0, "finale map: no forced tank");

Reset();
::Escalation.PendingTanks = 0;
first = MakeSpecial(8, 6000, 60);
Spawned(first);
second = MakeSpecial(8, 6000, 61);
Spawned(second);
Check(Kicks().len() == 0, "normal map: tanks never kicked");

Reset();
::Escalation.PendingTanks = 0;
::Escalation.Amps = {};
local realFinale = ::Director.IsFinale;
::DirectorClass.IsFinale <- function() { return true; };
local forced = MakeSpecial(8, 6000, 80);
Spawned(forced);
Check(Fired("RunScriptCode").filter(@(i, f) f.param.find("Amp(") != null).len() == 0, "normal chapter: the forced tank is not amped");
forced.dead = true;
Ent("trigger_finale");
local finaleTank = MakeSpecial(8, 6000, 81);
Spawned(finaleTank);
Check(Fired("RunScriptCode").filter(@(i, f) f.param.find("Amp(") != null).len() == 1, "finale map in its finale: amped");
::DirectorClass.IsFinale <- function() { return false; };

Done();
