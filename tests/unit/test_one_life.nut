::ROOT <- vargv.len() > 0 ? vargv[0] : ".";
dofile(::ROOT + "/tests/unit/mock.nut");
Suite("one life");

::g_ModeScript <- {};
Load("parts/core/addon/scripts/vscripts/hd4l_core.nut");
Load("parts/self-defib/addon/scripts/vscripts/self_defib.nut");
Load("parts/one-life/addon/scripts/vscripts/one_life.nut");
Load("parts/bot-takeover/addon/scripts/vscripts/bot_takeover.nut");
Load("parts/no-incap/addon/scripts/vscripts/no_incap.nut");

function Character(p, c) { p.props.m_survivorCharacter <- c; return p; }

Reset();
::OneLife.Condemned = {};
local you = Character(MakeSurvivor("Nick", 1), 0);
local friend = Character(MakeSurvivor("Ellis", 2), 3);
local bot = Character(MakeSurvivor("Coach", 3), 2);
bot.bot = true;
::OneLife.Generation = 7;
::OneLife.Carried = { c3 = true, c2 = true };
::OneLife.TryCarriedDeaths(7, 0);
Check(Events(friend, "damage").len() > 0, "carried: the human in a dead character is killed");
Check(Events(bot, "damage").len() > 0, "carried: the bot in a dead character is killed");
Check(Events(you, "damage").len() == 0, "carried: a living character is left alone");
Check(::OneLife.IsCondemned(friend), "carried: the human is condemned");
Check(!::OneLife.IsCondemned(you), "carried: nobody else is");
::T.now += 5.0;
Check(!::OneLife.IsCondemned(friend), "condemned lapses after CondemnSeconds");

Reset();
::OneLife.Condemned = {};
friend = MakeSurvivor("Ellis", 2);
friend.health = 20;
local defib = Ent("weapon_defibrillator");
friend.props["m_hMyWeapons0"] <- defib;
bot = MakeSurvivor("Coach", 3);
bot.bot = true;
::OneLife.Condemned[2] <- Time();
local t = { Victim = friend, Attacker = null, DamageDone = 99999.0, DamageType = 32 };
local allow = ::g_ModeScript.AllowTakeDamage(t);
Check(allow != false, "condemned: the hit lands");
Check(defib.valid, "condemned: the defib is kept");
Check(friend.props.m_bIsOnThirdStrike == 1, "condemned: dies, no incap");
Check(!::BotTakeover.CanHijack(friend), "condemned: no hijack");

::OneLife.Condemned = {};
Check(::BotTakeover.CanHijack(friend), "not condemned: hijack as before");

Reset();
you = MakeSurvivor("Nick", 1);
friend = MakeSurvivor("Ellis", 2);
friend.dead = true;
bot = MakeSurvivor("Coach", 3);
bot.bot = true;
Check(::BotTakeover.DeadHuman() == friend, "defib: the dead human is found");
friend.dead = false;
Check(::BotTakeover.DeadHuman() == null, "defib: nobody dead, nobody to put in");

Reset();
::T.mode = "coop";
::OneLife.Condemned = {};
friend = MakeSurvivor("Ellis", 2);
friend.health = 20;
t = { Victim = friend, Attacker = null, DamageDone = 100.0, DamageType = 128 };
::g_ModeScript.AllowTakeDamage(t);
Check(!("m_bIsOnThirdStrike" in friend.props), "vanilla coop: untouched");

Done();
