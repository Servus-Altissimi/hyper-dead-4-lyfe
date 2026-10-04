::ROOT <- vargv.len() > 0 ? vargv[0] : ".";
dofile(::ROOT + "/tests/unit/mock.nut");
Suite("damage path");

::g_ModeScript <- {};
Load("parts/core/addon/scripts/vscripts/hd4l_core.nut");
Load("parts/armour/addon/scripts/vscripts/armour.nut");
Load("parts/self-defib/addon/scripts/vscripts/self_defib.nut");
Load("parts/arsenal/addon/scripts/vscripts/arsenal.nut");
Load("parts/no-incap/addon/scripts/vscripts/no_incap.nut");

Check("AllowTakeDamage" in ::g_ModeScript, "no-incap installs the one wrapper");

Reset();
local nick = MakeSurvivor();
nick.health = 100;
nick.vel = Vector(250, 0, 0);
local t = { Victim = nick, Attacker = null, DamageDone = 100.0, DamageType = 128 };
local allow = ::g_ModeScript.AllowTakeDamage(t);
Near(t.DamageDone, 65.0, "armour: moving, 100 becomes 65");
Check(allow, "armour: hit allowed");
nick.vel = Vector(100, 0, 0);
t = { Victim = nick, Attacker = null, DamageDone = 100.0, DamageType = 128 };
::g_ModeScript.AllowTakeDamage(t);
Near(t.DamageDone, 85.0, "armour: standing or walking, 100 becomes 85");
nick.props.m_fFlags = 0;
t = { Victim = nick, Attacker = null, DamageDone = 100.0, DamageType = 128 };
::g_ModeScript.AllowTakeDamage(t);
Near(t.DamageDone, 65.0, "armour: airborne counts as moving");
local bot = MakeSurvivor("Coach", 9);
bot.bot = true;
t = { Victim = bot, Attacker = null, DamageDone = 100.0, DamageType = 128 };
::g_ModeScript.AllowTakeDamage(t);
Near(t.DamageDone, 65.0, "armour: bots always armoured");

Reset();
nick = MakeSurvivor();
t = { Victim = nick, Attacker = null, DamageDone = 40.0, DamageType = 32 };
::g_ModeScript.AllowTakeDamage(t);
Near(t.DamageDone, 40.0, "armour: fall damage untouched");

Reset();
nick = MakeSurvivor();
nick.health = 20;
local defib = Ent("weapon_defibrillator");
nick.props["m_hMyWeapons0"] <- defib;
t = { Victim = nick, Attacker = null, DamageDone = 100.0, DamageType = 128 };
allow = ::g_ModeScript.AllowTakeDamage(t);
Check(allow == false, "defib: lethal hit refused");
Check(!defib.valid && nick.health == 50, "defib: burned, back at 50");

Reset();
nick = MakeSurvivor();
nick.health = 20;
t = { Victim = nick, Attacker = null, DamageDone = 100.0, DamageType = 128 };
::g_ModeScript.AllowTakeDamage(t);
Check(nick.props.m_bIsOnThirdStrike == 1, "no defib: third strike set");

Reset();
nick = MakeSurvivor();
local bat = Ent("weapon_melee");
local common = Ent("infected");
common.origin = Vector(40, 0, 0);
t = { Victim = common, Attacker = nick, DamageDone = 100.0, DamageType = 128, Weapon = bat };
::g_ModeScript.AllowTakeDamage(t);
Check(Events(common, "impulse").len() == 1, "blunt: called from inside no-incap's hook");

Reset();
nick = MakeSurvivor();
local pistol = Ent("weapon_pistol");
common = Ent("infected");
t = { Victim = common, Attacker = nick, DamageDone = 40.0, DamageType = 2, Weapon = pistol };
::g_ModeScript.AllowTakeDamage(t);
Near(t.DamageDone, 28.0, "pistol: 40 becomes 28");
t = { Victim = common, Attacker = nick, DamageDone = 80.0, DamageType = 2, Weapon = Ent("weapon_pistol_magnum") };
::g_ModeScript.AllowTakeDamage(t);
Near(t.DamageDone, 80.0, "magnum untouched");

Reset();
nick = MakeSurvivor();
local can = Ent("prop_physics");
t = { Victim = nick, Attacker = can, Inflictor = can, DamageDone = 300.0, DamageType = 1 };
Check(::g_ModeScript.AllowTakeDamage(t) == false, "prop crush: cancelled");
local tank = MakeSpecial(8, 6000, 51);
local car = Ent("prop_physics");
t = { Victim = nick, Attacker = tank, Inflictor = car, DamageDone = 60.0, DamageType = 1 };
Check(::g_ModeScript.AllowTakeDamage(t) != false, "tank hittable: still hits");
local car2 = Ent("prop_physics");
car2.props.m_hPhysicsAttacker <- tank;
t = { Victim = nick, Attacker = car2, Inflictor = car2, DamageDone = 60.0, DamageType = 1 };
Check(::g_ModeScript.AllowTakeDamage(t) != false, "tank hittable via physics attacker: still hits");
local barrel = Ent("prop_physics");
t = { Victim = nick, Attacker = barrel, Inflictor = barrel, DamageDone = 40.0, DamageType = 64 };
Check(::g_ModeScript.AllowTakeDamage(t) != false, "exploding prop: still hurts");

Reset();
::T.mode = "coop";
nick = MakeSurvivor();
t = { Victim = nick, Attacker = null, DamageDone = 100.0, DamageType = 128 };
::g_ModeScript.AllowTakeDamage(t);
Near(t.DamageDone, 100.0, "vanilla coop: no armour");

Done();
