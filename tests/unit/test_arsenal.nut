::ROOT <- vargv.len() > 0 ? vargv[0] : ".";
dofile(::ROOT + "/tests/unit/mock.nut");
Suite("arsenal");

Load("parts/core/addon/scripts/vscripts/hd4l_core.nut");
Load("parts/arsenal/addon/scripts/vscripts/arsenal.nut");

function Melee(p) {
	local w = Ent("weapon_melee");
	p.weapon = w;
	return w;
}

function Hit(p, victim, type, weapon) {
	::Arsenal.MeleeHit({ Victim = victim, Attacker = p, DamageType = type, DamageDone = 100, Weapon = weapon, Inflictor = p });
}

Reset();
local nick = MakeSurvivor();
local bat = Melee(nick);
local common = Ent("infected");
common.origin = Vector(50, 0, 0);
Hit(nick, common, 128, bat);
local push = Events(common, "impulse");
Check(push.len() == 1, "blunt on common: one launch");
Check(push.len() == 1 && push[0].v.x > 600 && push[0].v.z > 200, "blunt on common: away and up");
Check(::T.sounds.filter(@(i, s) s.sound == ::Arsenal.BluntSound).len() == 1, "blunt: one thud");

Hit(nick, common, 128, bat);
Check(::T.sounds.filter(@(i, s) s.sound == ::Arsenal.BluntSound).len() == 1, "blunt: second hit in 0.12 s makes no second thud");

Reset();
nick = MakeSurvivor();
local axe = Melee(nick);
common = Ent("infected");
common.origin = Vector(50, 0, 0);
Hit(nick, common, 4, axe);
Check(Events(common, "impulse").len() == 0, "sharp melee: no launch");

Hit(nick, common, 128 | 4, axe);
Check(Events(common, "impulse").len() == 1, "club | slash counts as blunt");

Reset();
nick = MakeSurvivor();
bat = Melee(nick);
common = Ent("infected");
common.origin = Vector(50, 0, 0);
Hit(nick, common, 128 | 64, bat);
Hit(nick, common, 128 | 33554432, bat);
Check(Events(common, "impulse").len() == 0, "club with blast or stagger bits: skipped");

Reset();
nick = MakeSurvivor();
bat = Melee(nick);
local hunter = MakeSpecial(3);
hunter.origin = Vector(50, 0, 0);
Hit(nick, hunter, 128, bat);
Check(Events(hunter, "stagger").len() == 1, "blunt on special: staggered");
local tank = MakeSpecial(8, 6000, 51);
tank.origin = Vector(50, 0, 0);
Hit(nick, tank, 128, bat);
Check(Events(tank, "stagger").len() == 0, "blunt on tank: no stagger");
Check(Events(tank, "impulse").len() == 1 && Events(tank, "impulse")[0].v.Length() < 200, "blunt on tank: small nudge");

Reset();
nick = MakeSurvivor();
Melee(nick);
::Momentum <- { StateOf = function(p) { return { kick = true, move = "", dive = "" }; } };
common = Ent("infected");
common.origin = Vector(50, 0, 0);
::Arsenal.MeleeHit({ Victim = common, Attacker = nick, DamageType = 128, DamageDone = 150, Inflictor = nick });
Check(Events(common, "impulse").len() == 0, "held bat while kicking: not blunt");
delete ::Momentum;

Reset();
::T.mode = "coop";
nick = MakeSurvivor();
bat = Melee(nick);
common = Ent("infected");
Hit(nick, common, 128, bat);
Check(Events(common, "impulse").len() == 0, "vanilla coop: blunt off");

Reset();
nick = MakeSurvivor();
local pistol = Ent("weapon_pistol");
pistol.props.m_isHoldingFireButton <- 1;
nick.weapon = pistol;
::Arsenal.CheckAuto();
local st = ::Arsenal.State(nick);
nick.props.m_nButtons = 1;
::Arsenal.AutoStep(nick, st, Time());
Check(::Arsenal.AutoMode == "prop", "autofire: prop route picked when the prop exists");
Check(pistol.props.m_isHoldingFireButton == 0, "autofire: held M1 clears the holding flag");
pistol.props.m_isHoldingFireButton = 1;
nick.props.m_nButtons = 0;
::Arsenal.AutoStep(nick, st, Time());
Check(pistol.props.m_isHoldingFireButton == 1, "autofire: released M1 leaves the flag");

Reset();
nick = MakeSurvivor();
local magnum = Ent("weapon_pistol_magnum");
magnum.props.m_iClip1 <- 8;
magnum.props.m_flNextPrimaryAttack <- 0.0;
magnum.props.m_bInReload <- 0;
nick.weapon = magnum;
::Arsenal.CheckAuto();
st = ::Arsenal.State(nick);
st.released = false;
nick.props.m_nButtons = 1;
::Arsenal.AutoStep(nick, st, Time());
Check(::Arsenal.AutoMode == "toggle", "autofire: toggle route without the prop");
Check((nick.props.m_afButtonDisabled & 1) == 1, "autofire: attack released for a tick");
::Arsenal.AutoStep(nick, st, Time());
Check((nick.props.m_afButtonDisabled & 1) == 0, "autofire: attack pressed again next tick");
magnum.props.m_flNextPrimaryAttack = Time() + 1.0;
::Arsenal.AutoStep(nick, st, Time());
Check((nick.props.m_afButtonDisabled & 1) == 0, "autofire: no release while the gun is cycling");

Reset();
nick = MakeSurvivor();
nick.weapon = Ent("weapon_rifle");
st = ::Arsenal.State(nick);
st.released = false;
nick.props.m_nButtons = 1;
::Arsenal.AutoStep(nick, st, Time());
Check(nick.props.m_afButtonDisabled == 0, "autofire: rifle untouched");

Reset();
::Arsenal.SetCorpses();
Check(::T.cvars.phys_pushscale == 2.5, "corpses: phys_pushscale 2.5");

Check(!("PistolBurst" in ::Arsenal) && !("BurstStep" in ::Arsenal), "pistol burst removed");

Reset();
nick = MakeSurvivor();
local m60 = Ent("weapon_rifle_m60");
nick.weapon = m60;
common = Ent("infected");
common.origin = Vector(500, 0, 0);
common.health = 1000;
local realTrace = ::TraceLine;
::TraceLine <- function(t) { t.hit <- true; t.pos <- Vector(500, 0, 64); t.enthit <- common; };
::Arsenal.M60Scatter(nick);
::TraceLine <- realTrace;
local pellets = Events(common, "damage");
Check(pellets.len() == 6, "m60: six traced pellets on top of the game's ray");
Check(pellets.len() == 6 && pellets[0].type == 2, "m60: pellets are bullet damage");
Near(pellets.len() ? pellets[0].amount : 0, 20.0 * pow(0.8, (Vector(500, 0, 64) - nick.EyePosition()).Length() / 500.0), "m60: 20 with 0.8 falloff", 0.01);
local ray = { Victim = common, Attacker = nick, DamageType = 2, DamageDone = 50.0, Weapon = m60 };
::Arsenal.ScaleDamage(ray);
Near(ray.DamageDone, 50.0 * 0.4 * pow(0.8, 1.0) / pow(0.97, 1.0), "m60: the game's ray scaled to a pellet", 0.01);
::Arsenal.InPellet = true;
ray.DamageDone = 20.0;
::Arsenal.ScaleDamage(ray);
::Arsenal.InPellet = false;
Near(ray.DamageDone, 20.0, "m60: a traced pellet is not scaled twice", 0.001);
::T.mode = "coop";
ray.DamageDone = 50.0;
::Arsenal.ScaleDamage(ray);
Near(ray.DamageDone, 50.0, "m60: vanilla modes untouched", 0.001);
::T.mode = "hd4l";

m60.props.m_iClip1 <- 187;
m60.props.m_iPrimaryAmmoType <- 6;
m60.props.m_bInReload <- 0;
nick.props["m_iAmmo6"] <- 50;
::Inv <- { slot0 = m60 };
::GetInvTable <- function(p, t) { foreach (k, v in ::Inv) t[k] <- v; };
::Arsenal.M60ClipCap(nick);
Check(m60.props.m_iClip1 == 125 && nick.props["m_iAmmo6"] == 112, "m60 clip: 187 capped to 125, 62 back to reserve");
m60.props.m_iClip1 = 90;
::Arsenal.M60ClipCap(nick);
Check(m60.props.m_iClip1 == 90, "m60 clip: under the cap left alone");

Done();
