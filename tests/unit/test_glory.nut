::ROOT <- vargv.len() > 0 ? vargv[0] : ".";
dofile(::ROOT + "/tests/unit/mock.nut");
Suite("glory kill");

Load("parts/core/addon/scripts/vscripts/hd4l_core.nut");
Load("parts/glory-kill/addon/scripts/vscripts/glory_kill2.nut");

function Hurt(victim, attacker, health) {
	victim.health = health;
	::GloryKill2.OnGameEvent_player_hurt({ userid = victim.userid, attacker = attacker.userid, health = health });
}

Reset();
local nick = MakeSurvivor();
local hunter = MakeSpecial(3, 250);
Hurt(hunter, nick, 80);
Check(::GloryKill2.IsOpen(hunter), "coop: hunter under 35% opens a window");
Near(::GloryKill2.Open[hunter.index].until - Time(), 3.5, "coop: special window 3.5 s");
Check(Events(hunter, "stagger").len() == 1, "coop: opening staggers the special");

Reset();
nick = MakeSurvivor();
hunter = MakeSpecial(3, 250);
::GloryKill2.Open.clear();
Hurt(hunter, nick, 100);
Check(!::GloryKill2.IsOpen(hunter), "coop: hunter at 40% stays closed");

Reset();
::T.mode = "hd4lversus";
::GloryKill2.Open.clear();
nick = MakeSurvivor();
hunter = MakeSpecial(3, 250);
Hurt(hunter, nick, 80);
Near(::GloryKill2.Open[hunter.index].until - Time(), 1.2, "versus: special window 1.2 s");
local tank = MakeSpecial(8, 6000, 51);
Hurt(tank, nick, 500);
Near(::GloryKill2.Open[tank.index].until - Time(), 2.5, "versus: tank window 2.5 s");

::T.now += 1.3;
::GloryKill2.Tick(::GloryKill2.Generation);
Check(!::GloryKill2.IsOpen(hunter), "versus: window gone after 1.3 s");
Check(::GloryKill2.IsOpen(tank), "versus: tank window still open after 1.3 s");

Reset();
::GloryKill2.Open.clear();
nick = MakeSurvivor();
nick.health = 50;
hunter = MakeSpecial(3, 250);
Hurt(hunter, nick, 80);
::GloryKill2.OnGameEvent_player_shoved({ userid = hunter.userid, attacker = nick.userid });
Check(!::GloryKill2.IsOpen(hunter), "finish: shove closes the window");
local kills = Events(hunter, "damage");
Check(kills.filter(@(i, d) d.amount >= 1000).len() == 1, "finish: lethal damage dealt");
Check(nick.buffer == 15.0, "finish: 15 temp health");
local ambient = ::T.sounds.filter(@(i, s) s.how == "ambient");
Check(ambient.len() >= 4, "finish: finisher plus three loud layers (" + ambient.len() + ")");
Check(ambient.filter(@(i, s) s.pitch == 62).len() == 1, "finish: low bass layer at pitch 62");
Check(Spawned("env_sprite").len() == 2, "finish: amber and red flashes");
Check(Spawned("env_explosion").len() == 0, "finish: no generic fireball");
Check(Spawned("info_particle_system").filter(@(i, e) e.kv.effect_name == "hd4l_red_mist").len() == 1, "finish: red mist burst");

Reset();
::GloryKill2.Open.clear();
nick = MakeSurvivor();
tank = MakeSpecial(8, 6000, 51);
Hurt(tank, nick, 500);
Check(!::GloryKill2.TryFinish(tank, nick, "shove"), "tank: shove does not finish");
Check(::GloryKill2.TryFinish(tank, nick, "kick"), "tank: kick finishes");

Reset();
::T.mode = "coop";
::GloryKill2.Open.clear();
nick = MakeSurvivor();
hunter = MakeSpecial(3, 250);
Hurt(hunter, nick, 10);
Check(!::GloryKill2.IsOpen(hunter), "vanilla coop: no window");

Done();
