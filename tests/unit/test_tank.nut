::ROOT <- vargv.len() > 0 ? vargv[0] : ".";
dofile(::ROOT + "/tests/unit/mock.nut");
Suite("tank");

Load("parts/core/addon/scripts/vscripts/hd4l_core.nut");
Load("parts/infected-moves/addon/scripts/vscripts/infected_moves.nut");
Load("parts/hyper-feedback/addon/scripts/vscripts/hyper_feedback.nut");

Reset();
::InfectedMoves.OnGameEvent_round_start({});
Check(::T.cvars.z_speed == 290, "commons: z_speed 290");

Check(::InfectedMoves.RushSpeed * ::InfectedMoves.RushTime >= 900.0, "AI rush covers 900u or more (" + (::InfectedMoves.RushSpeed * ::InfectedMoves.RushTime) + ")");
Check(::InfectedMoves.HumanKnobs.RushSpeed * ::InfectedMoves.HumanKnobs.RushTime >= 1300.0, "human rush covers 1300u or more");

Reset();
::InfectedMoves.Tanks.clear();
local nick = MakeSurvivor();
nick.origin = Vector(100, 0, 0);
local tank = MakeSpecial(8, 6000, 51);
local t = ::InfectedMoves.TankState(tank);
::InfectedMoves.TankBegin(tank, t, "slam", nick, Time());
Check(t.phase == "slam_windup", "slam wound up");
tank.incap = true;
::T.now += 1.0;
::InfectedMoves.TankPhase(tank, t, Time());
Check(!(tank.index in ::InfectedMoves.Tanks), "dying tank: move cancelled");
Check(Events(nick, "damage").len() == 0 && Events(nick, "stagger").len() == 0, "dying tank: no shockwave");

::InfectedMoves.Tick(::InfectedMoves.Generation);
Check(!(tank.index in ::InfectedMoves.Tanks), "tick: dying tank not re-armed");

Reset();
::InfectedMoves.Tanks.clear();
nick = MakeSurvivor();
tank = MakeSpecial(8, 6000, 51);
t = ::InfectedMoves.TankState(tank);
t.phase = "";
::InfectedMoves.RushTick(tank.index, ::InfectedMoves.Generation);
Check(tank.index in ::InfectedMoves.Tanks, "rush tick after the rush: state kept");

Reset();
::InfectedMoves.Tanks.clear();
nick = MakeSurvivor();
nick.origin = Vector(2000, 0, 0);
tank = MakeSpecial(8, 6000, 51);
t = ::InfectedMoves.TankState(tank);
::InfectedMoves.TankBegin(tank, t, "rush", nick, Time());
::T.now += 1.0;
::InfectedMoves.TankPhase(tank, t, Time());
Check(t.phase == "rush_run", "rush running");
tank.origin = Vector(900, 0, 0);
::T.now += 1.0;
::InfectedMoves.TankPhase(tank, t, Time());
local st = Events(tank, "stagger");
Check(st.len() == 1 && (st[0].from - tank.GetOrigin()).Dot(t.dir) < 0, "missed rush: stumbles forward, not back");
Check(tank.vel.Dot(t.dir) > 0, "missed rush: keeps moving forward");
Check(Fired("CommandABot").filter(@(i, f) f.param.cmd == 0 && f.param.target == nick).len() == 1, "missed rush: AI told to go for the nearest survivor");

::InfectedMoves.OnGameEvent_tank_killed({ userid = tank.userid });
Check(!(tank.index in ::InfectedMoves.Tanks), "tank_killed clears the state");

Reset();
local boomer = MakeSpecial(2, 50, 60);
local near = Ent("infected");
near.origin = Vector(100, 0, 0);
local far = Ent("infected");
far.origin = Vector(900, 0, 0);
::InfectedMoves.OnGameEvent_player_death({ userid = boomer.userid });
Check(Events(near, "impulse").len() == 1 && Events(near, "impulse")[0].v.x > 300, "boomer pop: near common shoved outward");
Check(Events(far, "impulse").len() == 0, "boomer pop: far common untouched");
Check(::T.sounds.filter(@(i, x) x.sound == ::InfectedMoves.PopSound && x.pitch == 70).len() == 1, "boomer pop: low boom");
local hunter = MakeSpecial(3, 250, 61);
::InfectedMoves.OnGameEvent_player_death({ userid = hunter.userid });
Check(Spawned("env_physexplosion").len() == 1, "only the boomer pops");

Reset();
nick = MakeSurvivor();
::InfectedMoves.OnGameEvent_lunge_pounce({ userid = 61, victim = nick.userid });
Check(Spawned("info_particle_system").len() == 2, "pounce: dust burst at the victim");
Check(::T.sounds.filter(@(i, x) x.sound == ::InfectedMoves.ScarSound).len() == 1, "pounce: heavy thud");

Reset();
::InfectedMoves.Tanks.clear();
tank = MakeSpecial(8, 6000, 51);
t = ::InfectedMoves.TankState(tank);
::InfectedMoves.Step(tank, t);
tank.origin = Vector(50, 0, 0);
::InfectedMoves.Step(tank, t);
Check(::T.sounds.len() == 0, "steps: nothing under a stride");
tank.origin = Vector(100, 0, 0);
::InfectedMoves.Step(tank, t);
Check(::T.sounds.filter(@(i, x) x.how == "ambient" && x.pitch == 55).len() == 1 && Spawned("info_particle_system").len() == 1, "steps: thud and dust every 90u");

Reset();
tank = MakeSpecial(8, 6000, 51);
tank.health = 3000;
Near(::HyperFeedback.TankFraction(), 0.5, "boss bar: living tank at half");
tank.incap = true;
Check(::HyperFeedback.TankFraction() < 0, "boss bar: dying tank hidden");
tank.incap = false;
tank.health = 0;
Check(::HyperFeedback.TankFraction() < 0, "boss bar: zero health hidden");

Done();
