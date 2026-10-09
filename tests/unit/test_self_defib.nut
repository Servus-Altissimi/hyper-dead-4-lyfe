::ROOT <- vargv.len() > 0 ? vargv[0] : ".";
dofile(::ROOT + "/tests/unit/mock.nut");
Suite("self defib");

function OldConvert(classname) {
	if (classname == "weapon_rifle_spawn")
		return "weapon_smg_spawn";
	return 0;
}
::g_ModeScript <- { ConvertWeaponSpawn = OldConvert };
Load("parts/core/addon/scripts/vscripts/hd4l_core.nut");
Load("parts/self-defib/addon/scripts/vscripts/self_defib.nut");
Load("parts/no-incap/addon/scripts/vscripts/no_incap.nut");

function Armed(name, userid) {
	local p = MakeSurvivor(name, userid);
	local defib = Ent("weapon_defibrillator");
	p.props["m_hMyWeapons1"] <- defib;
	return [p, defib];
}

Reset();
local hook = ::SelfDefib.Installed.g_ModeScript;
Check(::SelfDefib.ConvertHook("g_ModeScript", "weapon_upgradepack_incendiary_spawn") == "weapon_defibrillator_spawn", "convert: upgrade pack becomes a defib");
Check(::SelfDefib.ConvertHook("g_ModeScript", "weapon_rifle_spawn") == "weapon_smg_spawn", "convert: the previous hook still answers");
Check(::SelfDefib.ConvertHook("g_ModeScript", "weapon_pistol_spawn") == 0, "convert: other spawns left alone");
::SelfDefib.ConvertChance = 0;
Check(::SelfDefib.ConvertHook("g_ModeScript", "weapon_upgradepack_explosive") == 0, "convert: chance 0 converts nothing");
::SelfDefib.ConvertChance = 50;
::SelfDefib.InstallHook();
Check(::g_ModeScript.ConvertWeaponSpawn == hook && ::SelfDefib.Previous.g_ModeScript == OldConvert, "rehook: no double wrap");

Reset();
::T.mode = "coop";
Check(::SelfDefib.ConvertHook("g_ModeScript", "weapon_upgradepack_explosive_spawn") == 0, "coop: no conversion");
Check(::SelfDefib.ConvertHook("g_ModeScript", "weapon_rifle_spawn") == "weapon_smg_spawn", "coop: previous hook kept");
::SessionOptions <- {};
::SelfDefib.ApplyDensity();
Check(!("DefibrillatorDensity" in ::SessionOptions), "coop: density untouched");
::T.mode = "hd4lsurvival";
::SelfDefib.OnGameEvent_round_start({});
Check(::SessionOptions.DefibrillatorDensity == ::SelfDefib.Density, "survival: round start sets density");

Reset();
::SelfDefib.Versus = false;
::T.mode = "hd4lversus";
local v = !::SelfDefib.ModeAllowed();
::T.mode = "hd4l";
Check(v && ::SelfDefib.ModeAllowed(), "modes: Versus off gates versus only");
::SelfDefib.Versus = true;
::SelfDefib.Stock = false;
::T.mode = "hd4lfort";
Check(!::SelfDefib.ModeAllowed(), "modes: Stock off gates fort");
::SelfDefib.Stock = true;

Reset();
local you = Armed("Nick", 1)[0];
local bare = MakeSurvivor("Ellis", 2);
local gone = Armed("Coach", 3)[0];
gone.dead = true;
local special = MakeSpecial(1);
special.props["m_hMyWeapons0"] <- Ent("weapon_defibrillator");
Check(::SelfDefib.CanRevive(you), "can revive: survivor holding a defib");
Check(!::SelfDefib.CanRevive(bare) && !::SelfDefib.CanRevive(gone) && !::SelfDefib.CanRevive(special) && !::SelfDefib.CanRevive(null), "can revive: not without defib, dead, infected or null");
::T.mode = "coop";
Check(!::SelfDefib.CanRevive(you), "can revive: not in coop");

Reset();
local kit = Armed("Nick", 7);
you = kit[0];
you.health = 3;
you.props.m_bIsOnThirdStrike <- 1;
you.props.m_currentReviveCount <- 2;
Check(::SelfDefib.Revive(you), "revive: succeeds");
Check(!kit[1].valid, "revive: the defib is used up");
Check(you.health == 50 && you.props.m_healthBuffer == 25.0, "revive: 50 health plus 25 temp");
Check(you.props.m_bIsOnThirdStrike == 0 && you.props.m_currentReviveCount == 0, "revive: strikes cleared");
Check(Spawned("info_particle_system").len() == 1 && Fired("StartShake").len() == 1, "revive: arc and shake");
local grace = Fired("RunScriptCode");
Check(you.props.m_takedamage == 0 && grace.len() == 1 && grace[0].delay == 1.5 && grace[0].param.find("EndGrace(7)") != null, "revive: grace then EndGrace");
::SelfDefib.EndGrace(7);
Check(you.props.m_takedamage == 2, "end grace: damage back on");
::SelfDefib.EndGrace(999);
Check(!::SelfDefib.Revive(you) && you.health == 50, "revive: no second defib, no revive");

Reset();
kit = Armed("Nick", 1);
you = kit[0];
you.health = 20;
local allow = ::g_ModeScript.AllowTakeDamage({ Victim = you, Attacker = null, DamageDone = 500.0, DamageType = 128 });
Check(allow == false && you.health == 50 && !kit[1].valid, "lethal hit: the defib takes it");

Reset();
local ok = true;
try {
	::SelfDefib.OnGameEvent_round_start(null);
	::SelfDefib.OnGameEvent_round_start({ userid = -1 });
} catch (e) { ok = false; }
Check(ok, "round start: bad params do not throw");

Done();
