::ROOT <- vargv.len() > 0 ? vargv[0] : ".";
dofile(::ROOT + "/tests/unit/mock.nut");
Suite("bot takeover");

::g_ModeScript <- {};
Load("parts/core/addon/scripts/vscripts/hd4l_core.nut");
Load("parts/bot-takeover/addon/scripts/vscripts/bot_takeover.nut");
Load("parts/no-incap/addon/scripts/vscripts/no_incap.nut");

class Body extends Ent {
	function ReviveByDefib() { dead = false; events.append({ what = "defib", returnTime = ::T.cvars["defibrillator_return_to_life_time"] }); }
	function SetModel(m) { model = m; }
	function IsSuppressingFallingDamage() { return false; }
	function DropItem(n) {}
	function ReviveFromIncap() { incap = false; events.append({ what = "revived" }); }
}

class Stuck extends Body {
	function ReviveByDefib() {}
}

function Person(name, userid, character, isBot = false) {
	local p = Body("player");
	p.team = 2; p.name = name; p.userid = userid; p.bot = isBot; p.model = name;
	p.props.m_survivorCharacter <- character;
	return p;
}

function Fresh(mode = "hd4l") {
	Reset();
	::T.mode = mode;
	::BotTakeover.Holds = 0;
	::BotTakeover.Pending = {};
	::BotTakeover.HeldCvar = false;
}

function Runs(what) {
	return Fired("RunScriptCode").filter(@(i, f) f.param.find(what) != null);
}

function Throws(f) {
	try { f(); } catch (e) { return true; }
	return false;
}

local allowed = [];
foreach (m in [ "hd4l", "hd4lsurvival", "hd4lfort", "hd4lfreebuild", "hd4lversus", "coop", "versus" ]) {
	::T.mode = m;
	if (::BotTakeover.ModeAllowed())
		allowed.append(m);
}
Check(allowed.len() == 4 && allowed.find("hd4lversus") == null && allowed.find("coop") == null, "modes: hd4l, survival, fort, freebuild only");

Fresh();
::T.cvars.sb_all_bot_game <- 0;
local you = Person("Nick", 1, 0);
you.dead = true;
::BotTakeover.OnGameEvent_player_death({ userid = 1 });
local runs = Runs("TakeOver(1, 0, ");
Check(runs.len() == 1 && runs[0].delay == ::BotTakeover.Delay, "death: takeover scheduled");
Check(::BotTakeover.Holds == 1 && ::T.cvars.sb_all_bot_game == 1, "death: mission lost held");

Fresh("coop");
you = Person("Nick", 1, 0);
you.dead = true;
::BotTakeover.OnGameEvent_player_death({ userid = 1 });
Check(Fired("RunScriptCode").len() == 0 && ::BotTakeover.Holds == 0, "coop: death ignored");

Fresh();
Person("Coach", 3, 2, true).dead = true;
::BotTakeover.OnGameEvent_player_death({ userid = 3 });
Check(Fired("RunScriptCode").len() == 0, "death: a bot dying is ignored");

Fresh();
local bad = Throws(function() {
	::BotTakeover.OnGameEvent_player_death({});
	::BotTakeover.OnGameEvent_player_death({ userid = 99 });
	::BotTakeover.OnGameEvent_defibrillator_used({});
	::BotTakeover.Reclaim(99);
	::BotTakeover.TakeOver(99, 0);
});
Check(!bad && Fired("RunScriptCode").len() == 0, "events: missing or unknown ids do not throw");

Fresh();
::T.cvars.sb_all_bot_game <- 0;
::BotTakeover.HoldMissionLost(true);
::BotTakeover.HoldMissionLost(true);
::BotTakeover.HoldMissionLost(false);
local nested = ::T.cvars.sb_all_bot_game == 1;
::BotTakeover.HoldMissionLost(false);
::BotTakeover.HoldMissionLost(false);
Check(nested && ::T.cvars.sb_all_bot_game == 0 && ::BotTakeover.Holds == 0, "hold: nested holds release on the last, never below zero");

Fresh();
::T.cvars.sb_all_bot_game <- 0;
::T.cvars.defibrillator_return_to_life_time <- 3.0;
you = Person("Nick", 1, 0);
you.dead = true;
you.health = 0;
local weak = Person("Bill", 4, 4, true);
weak.health = 20;
local strong = Person("Coach", 3, 2, true);
strong.health = 80;
strong.origin = Vector(50, 0, 0);
::BotTakeover.HoldMissionLost(true);
::BotTakeover.TakeOver(1, 0);
local defib = Events(you, "defib");
Check(defib.len() == 1 && defib[0].returnTime == 1, "takeover: revived with a 1s return time");
Check(::T.cvars.defibrillator_return_to_life_time == 3.0, "takeover: return time restored");
Check(you.health == 80 && you.origin.x == 50 && Events(strong, "damage").len() == 1, "takeover: healthiest bot taken over and killed");
Check(Events(weak, "damage").len() == 0, "takeover: the other bot is left alone");
Check(you.props.m_survivorCharacter == 2 && strong.props.m_survivorCharacter == 0 && you.model == "Coach", "takeover: character and model swapped");
Check(::BotTakeover.Holds == 0 && ::T.cvars.sb_all_bot_game == 0, "takeover: hold released");

Fresh();
you = Person("Nick", 1, 0);
you.dead = true;
local downed = Person("Coach", 3, 2, true);
downed.incap = true;
::BotTakeover.TakeOver(1, 0);
runs = Runs("TakeOver(1, 1, ");
Check(runs.len() == 1 && runs[0].delay == ::BotTakeover.RetrySeconds && Events(you, "defib").len() == 0, "no free bot: incapped bot skipped, retry scheduled");
Check(::BotTakeover.Holds == 0, "no free bot: hold released while waiting");

Fresh();
you = Person("Nick", 1, 0);
you.dead = true;
::BotTakeover.TakeOver(1, ::BotTakeover.RetryLimit);
Check(Fired("RunScriptCode").len() == 0, "retry: gives up at RetryLimit");

Fresh();
you = Person("Nick", 1, 0);
strong = Person("Coach", 3, 2, true);
::BotTakeover.TakeOver(1, 0);
Check(Events(you, "defib").len() == 0 && Events(strong, "damage").len() == 0, "takeover: a living player is not moved");

Fresh();
you = Person("Nick", 1, 0);
you.dead = true;
strong = Person("Coach", 3, 2, true);
local corpse = Ent("survivor_death_model");
corpse.props.m_nCharacterType <- 0;
corpse.origin = Vector(-200, 10, 0);
::BotTakeover.TakeOver(1, 0);
Check(!corpse.valid && strong.origin.x == -200, "corpse: bot dies where the body lay");

Fresh("hd4lfort");
::BotTakeover.OnGameEvent_defibrillator_used({ subject = 3 });
Check(Runs("Reclaim(3)").len() == 1, "defib: reclaim scheduled");

Fresh();
you = Person("Nick", 1, 0);
you.dead = true;
strong = Person("Coach", 3, 2, true);
::BotTakeover.Reclaim(1);
Check(Events(you, "defib").len() == 0, "reclaim: a human subject is not stolen");
::BotTakeover.Reclaim(3);
Check(Events(you, "defib").len() == 1 && Events(strong, "damage").len() == 1 && ::BotTakeover.Holds == 0, "reclaim: dead human takes the defibbed bot");

Fresh();
you = Person("Nick", 1, 0);
Person("Coach", 3, 2, true);
::BotTakeover.Hijack(you);
::T.now += 0.2;
::BotTakeover.Hijack(you);
local once = Runs("HijackNow(1)").len() == 1;
::T.now += 0.5;
::BotTakeover.Hijack(you);
Check(once && Runs("HijackNow(1)").len() == 2, "hijack: repeats within 0.5s are dropped");

Fresh();
::T.cvars.sb_all_bot_game <- 1;
::BotTakeover.HoldMissionLost(true);
::BotTakeover.HoldMissionLost(false);
Check(::T.cvars.sb_all_bot_game == 1, "hold: a server's own sb_all_bot_game 1 survives a takeover");

Fresh("hd4lfort");
::T.cvars.sb_all_bot_game <- 0;
you = Person("Nick", 1, 0);
you.dead = true;
strong = Person("Coach", 3, 2, true);
::BotTakeover.OnGameEvent_player_death({ userid = 1 });
local stale = Runs("TakeOver(1, 0, ")[0].param;
::BotTakeover.OnGameEvent_round_start({});
Check(::BotTakeover.Holds == 0 && ::T.cvars.sb_all_bot_game == 0, "round start: a pending hold is released");
compilestring(stale)();
Check(Events(you, "defib").len() == 0 && Events(strong, "damage").len() == 0, "round start: last round's takeover never fires");

Fresh("hd4lfort");
you = Stuck("player");
you.team = 2; you.name = "Nick"; you.userid = 1; you.dead = true;
you.props.m_survivorCharacter <- 0;
strong = Person("Coach", 3, 2, true);
::BotTakeover.TakeOver(1, 0);
Check(Events(strong, "damage").len() == 0 && strong.props.m_survivorCharacter == 2, "revive fails: the bot is spared");
Check(::BotTakeover.Holds == 0, "revive fails: hold released");

Fresh("hd4lfort");
you = Person("Nick", 1, 0);
::BotTakeover.Hijack(you);
::BotTakeover.HijackNow(1);
Check(Events(you, "damage").len() == 1 && !(1 in ::BotTakeover.Pending) && !::BotTakeover.CanHijack(you), "hijack: with no bot left the kill lands instead of being swallowed");

Fresh("hd4lfort");
::g_ModeScript.AllowTakeDamage <- function(t) { return true; };
::NoIncap.Hook();
Check(::g_ModeScript.AllowTakeDamage == ::NoIncap.Installed.g_ModeScript, "no incap: Hook reinstalls a lost damage hook even when armed");
delete ::g_ModeScript.AllowTakeDamage;
::NoIncap.OnGameEvent_round_start({});
Check(("AllowTakeDamage" in ::g_ModeScript) && ::g_ModeScript.AllowTakeDamage == ::NoIncap.Installed.g_ModeScript, "no incap: round start reinstalls it");

Fresh("hd4lfort");
you = Person("Nick", 1, 0);
you.incap = true;
Person("Coach", 3, 2, true);
::NoIncap.OnGameEvent_player_incapacitated({ userid = 1 });
Check(Events(you, "revived").len() == 1 && Events(you, "damage").len() == 0 && Runs("HijackNow(1)").len() == 1, "incap fallback: the downed human takes over a bot");

Fresh("hd4lfort");
you = Person("Nick", 1, 0);
you.incap = true;
::NoIncap.OnGameEvent_player_incapacitated({ userid = 1 });
Check(Events(you, "revived").len() == 0 && Events(you, "damage").len() >= 1, "incap fallback: with no bot the human dies as before");

Done();
