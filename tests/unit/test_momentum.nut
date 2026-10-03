::ROOT <- vargv.len() > 0 ? vargv[0] : ".";
dofile(::ROOT + "/tests/unit/mock.nut");
Suite("momentum");

Load("parts/core/addon/scripts/vscripts/hd4l_core.nut");
Load("parts/momentum/addon/scripts/vscripts/momentum.nut");
foreach (file in ::Momentum.Files)
	Load("parts/momentum/addon/scripts/vscripts/" + file + ".nut");

function Fresh() {
	Reset();
	::Momentum.State.clear();
	local p = MakeSurvivor();
	p.props.m_fFlags = 0;
	return p;
}

function Speed(p) { return p.GetVelocity().Length(); }

local nick = Fresh();
local s = ::Momentum.StateOf(nick);
::Momentum.StartKick(nick, s, Time());
Near(Speed(nick), sqrt(pow(::Momentum.KickSpeed, 2) + pow(::Momentum.KickLift, 2)), "plain kick: base speed, lift on top", 1.0);
Check(!s.kickLaunch, "plain kick: not a launch");

nick = Fresh();
s = ::Momentum.StateOf(nick);
s.wallRun = true;
::Momentum.StartKick(nick, s, Time());
Near(Speed(nick), sqrt(pow(::Momentum.KickSpeed * 1.5, 2) + pow(::Momentum.KickLift, 2)), "wall kick: 1.5x speed", 1.0);
Check(s.kickLaunch, "wall kick: launch flag set");
Check(!s.wallRun, "wall kick: wall run ended");

nick = Fresh();
s = ::Momentum.StateOf(nick);
s.wallRun = true;
::Momentum.EndWallRun(nick, s);
::T.now += 0.3;
::Momentum.StartKick(nick, s, Time());
Check(s.kickLaunch, "grace: kick 0.3 s after the wall is a launch");

nick = Fresh();
s = ::Momentum.StateOf(nick);
s.wallRun = true;
::Momentum.EndWallRun(nick, s);
::T.now += 0.5;
::Momentum.StartKick(nick, s, Time());
Check(!s.kickLaunch, "grace: kick 0.5 s after the wall is plain");

nick = Fresh();
s = ::Momentum.StateOf(nick);
s.wallRun = true;
::Momentum.StartKick(nick, s, Time());
s.kicks = 1;
s.kick = false;
::T.now += 0.1;
::Momentum.StartKick(nick, s, Time());
Check(!s.kickLaunch, "second kick right after a launch is plain");

function KickSpecial(launch) {
	local p = Fresh();
	local st = ::Momentum.StateOf(p);
	st.wallRun = launch;
	::Momentum.StartKick(p, st, Time());
	local hunter = MakeSpecial(3, 1000);
	hunter.origin = p.GetOrigin() + st.kickDir * 30.0 - Vector(0, 0, 4);
	::Momentum.KickCheck(p, st);
	local hits = Events(hunter, "damage");
	return hits.len() > 0 ? hits[0].amount : 0;
}
Near(KickSpecial(false), ::Momentum.KickDamageSpecial, "kick on hunter: 150");
Near(KickSpecial(true), ::Momentum.KickDamageSpecial * 2.0, "wall kick on hunter: 300");

function KickCommon(below) {
	local p = Fresh();
	local st = ::Momentum.StateOf(p);
	::Momentum.StartKick(p, st, Time());
	st.stamina = 0.0;
	local z = Ent("infected");
	z.health = 50;
	z.origin = p.GetOrigin() + ::Momentum.Flat(st.kickDir) * 40.0 - Vector(0, 0, below);
	::Momentum.KickCheck(p, st);
	return { p = p, st = st, z = z };
}
local k = KickCommon(0.0);
local dmg = Events(k.z, "damage");
Check(dmg.len() == 1 && dmg[0].amount >= 1000 && (dmg[0].type & 8192) != 0, "kick on common: killed and gibbed without a boost");
Check(!k.st.kick && k.st.kicks == ::Momentum.AirKicks && k.p.GetVelocity().z > 0.0, "kick on common: bounce, kick returned");
Check(k.st.stamina > 0.0, "kick on common: stamina refunded");
Check(k.st.chain == 1, "kick on common: counts for the chain");
k = KickCommon(60.0);
Check(Events(k.z, "damage").len() == 1, "kick on common: hits one well below the kicker");

nick = Fresh();
s = ::Momentum.StateOf(nick);
::Momentum.Aura(nick, s);
Check(s.eyes == null && s.eyesKind == "", "eyes: none unboosted");
nick.props.m_bAdrenalineActive <- 1;
::Momentum.Aura(nick, s);
Check(s.eyesKind == "boost" && s.eyes.len() == 2 && s.eyes[0].kv.effect_name == "hd4l_eyes_white", "eyes: white on adrenaline");
s.hyperUntil = Time() + 5.0;
::Momentum.Aura(nick, s);
Check(s.eyesKind == "hyper" && s.eyes[0].kv.effect_name == "hd4l_eyes_hyper", "eyes: hyper eyes in HYPER");
nick.props.m_bAdrenalineActive = 0;
s.hyperUntil = 0.0;
local before = Fired("Stop").len();
::Momentum.Aura(nick, s);
Check(s.eyes == null && Fired("Stop").len() == before + 2, "eyes: both stopped when the boost ends");

nick = Fresh();
s = ::Momentum.StateOf(nick);
nick.props.m_bAdrenalineActive <- 1;
::Momentum.SurvivorEyes = false;
::Momentum.Aura(nick, s);
Check(s.eyes == null, "eyes: knob off, no eyes");
::Momentum.SurvivorEyes = true;

nick = Fresh();
s = ::Momentum.StateOf(nick);
::Momentum.StartHyper(nick, s);
Check(Spawned("env_fade").len() == 1 && Spawned("env_fade")[0].kv.spawnflags == "5", "hyper: white fade to that player only");
Check(::T.sounds.filter(@(i, x) x.how == "ambient").len() == 2, "hyper: two loud layers");
Check(s.stamina == ::Momentum.StaminaMax, "hyper: stamina refilled");

nick = Fresh();
s = ::Momentum.StateOf(nick);
::Momentum.Streak(nick, s, true);
Check(s.streak != null && s.streak.cls == "env_spritetrail", "streak: amber trail on");
::Momentum.Streak(nick, s, false);
Check(s.streak == null, "streak: off");

nick = Fresh();
local bot = MakeSurvivor("Coach", 2);
bot.bot = true;
bot.props.m_bAdrenalineActive <- 1;
::Momentum.Tick(::Momentum.Generation);
local bs = ::Momentum.StateOf(bot);
Check(bs.eyesKind == "boost" && bs.eyes.len() == 2, "bots: adrenaline bot gets white eyes");
bs.hyperUntil = Time() + 5.0;
::Momentum.Tick(::Momentum.Generation);
Check(bs.eyesKind == "hyper", "bots: HYPER bot gets hyper eyes");

nick = Fresh();
local mate = MakeSurvivor("Ellis", 3);
mate.bot = true;
::Momentum.Update(nick);
Check(::T.sounds.filter(@(i, x) x.sound == ::Momentum.Heartbeat).len() == 0, "heartbeat: silent with a teammate alive");
mate.dead = true;
::T.now += 1.0;
::Momentum.Update(nick);
local beats = ::T.sounds.filter(@(i, x) x.sound == ::Momentum.Heartbeat);
Check(beats.len() == ::Momentum.BeatLayers && beats.filter(@(i, x) x.how != "client" || x.ent != nick).len() == 0, "heartbeat: alone, layered, played to that player only");
local s2 = ::Momentum.StateOf(nick);
Near(s2.beatAt - Time(), ::Momentum.BeatPeriod, "heartbeat: 0.85 s apart at full health");
nick.health = 20;
::T.now += 1.0;
::Momentum.Update(nick);
Near(s2.beatAt - Time(), ::Momentum.BeatFast, "heartbeat: 0.55 s apart under 40 health");

nick = Fresh();
s = ::Momentum.StateOf(nick);
::Momentum.OnGameEvent_player_hurt_concise({ userid = nick.userid, type = 32, dmg_health = 5 });
Check(Events(nick, "stagger").len() == 0, "light landing: no stagger");
Near(s.slowMult, ::Momentum.LightLandSlow, "light landing: slowed to 0.7");
::T.now += 1.0;
::Momentum.OnGameEvent_player_hurt_concise({ userid = nick.userid, type = 32, dmg_health = 30 });
Near(s.slowMult, ::Momentum.HardLandSlow, "hard landing: slowed to 0.45");
Near(s.slowUntil - Time(), ::Momentum.HardLandSeconds, "hard landing: for 0.9 s");
Check(!("m_TimeForceExternalView" in nick.props), "hard landing: no third person stumble");
nick.props.m_flLaggedMovementValue = 1.0;
s.engineLag = 1.0; s.appliedLag = 1.0;
::Momentum.ApplyLag(nick, s, Time());
Near(nick.props.m_flLaggedMovementValue, ::Momentum.BaseSpeed * ::Momentum.HardLandSlow, "hard landing: speed scaled while slowed", 0.01);
::T.now += 1.0;
::Momentum.ApplyLag(nick, s, Time());
Near(nick.props.m_flLaggedMovementValue, ::Momentum.BaseSpeed, "slow wears off", 0.01);
nick = Fresh();
s = ::Momentum.StateOf(nick);
nick.props.m_bAdrenalineActive <- 1;
::Momentum.OnGameEvent_player_hurt_concise({ userid = nick.userid, type = 32, dmg_health = 30 });
Check(s.slowUntil <= Time(), "boosted landing: no slow");

nick = Fresh();
nick.model = "models/survivors/survivor_gambler.mdl";
nick.props.m_fFlags = 1;
s = ::Momentum.StateOf(nick);
s.move = "dash";
s.moveUntil = Time() + 5.0;
s.moveDir = Vector(1, 0, 0);
nick.vel = Vector(600, 0, 0);
for (local i = 0; i < 10; i++) {
	::Momentum.Update(nick);
	::T.now += 0.07;
}
local ghosts = Spawned("prop_dynamic_override");
Check(ghosts.len() == ::Momentum.GhostMax, "afterimages: capped at " + ::Momentum.GhostMax + " per move (" + ghosts.len() + ")");
Check(ghosts.len() > 0 && ghosts[0].kv.model == nick.model && ghosts[0].kv.rendermode == 5, "afterimages: survivor model, additive");
Check(ghosts.len() > 0 && ghosts[0].props.m_flPlaybackRate == 0.0, "afterimages: pose frozen");
Check(ghosts.len() > 0 && (ghosts[0].GetOrigin() - nick.GetOrigin()).Dot(Vector(1, 0, 0)) <= -50.0, "afterimages: spawn behind you, never on the camera");
Check(Fired("Alpha").filter(@(i, f) f.ent == ghosts[0]).len() == 3, "afterimages: fade in three steps");
Check(Fired("Kill").filter(@(i, f) f.ent == ghosts[0] && f.delay == ::Momentum.GhostLife).len() == 1, "afterimages: gone after 0.35 s");
nick = Fresh();
s = ::Momentum.StateOf(nick);
::Momentum.Update(nick);
Check(Spawned("prop_dynamic_override").len() == 0, "afterimages: none when not moving");

nick = Fresh();
s = ::Momentum.StateOf(nick);
local jockey = MakeSpecial(5, 325, 70);
nick.props.m_jockeyAttacker <- jockey;
nick.vel = Vector(0, -200, 0);
for (local i = 0; i < 20; i++) { ::Momentum.Update(nick); ::T.now += 0.01; }
local punch = nick.props["m_Local.m_vecPunchAngle"];
Check(s.swaying && fabs(punch.z) > 3.0, "jockey: view rolls toward the steering (" + punch.z + ")");
nick.props.m_jockeyAttacker = null;
::Momentum.Update(nick);
Check(!s.swaying && nick.props["m_Local.m_vecPunchAngle"].z == 0.0, "jockey: view level again after the ride");

nick = Fresh();
s = ::Momentum.StateOf(nick);
nick.props.m_bAdrenalineActive <- 1;
::Momentum.Aura(nick, s);
::Momentum.OnGameEvent_player_death({ userid = nick.userid });
Check(s.eyes == null, "death: eyes cleared");

Done();
