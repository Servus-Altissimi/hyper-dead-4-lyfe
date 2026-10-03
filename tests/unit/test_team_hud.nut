::ROOT <- vargv.len() > 0 ? vargv[0] : ".";
dofile(::ROOT + "/tests/unit/mock.nut");
Suite("team hud");

Load("parts/core/addon/scripts/vscripts/hd4l_core.nut");
Load("parts/hyper-feedback/addon/scripts/vscripts/hyper_feedback.nut");
local H = ::HyperFeedback;

function Field(v, fields, name) {
	local div = 1;
	foreach (f in fields) {
		if (f[0] == name)
			return (v / div) % f[1];
		div *= f[1];
	}
	return -1;
}
local ME = [ ["who", 9], ["hp", 51], ["total", 51], ["tone", 3], ["crouch", 2], ["on", 2] ];
local MATE = [ ["who", 9], ["hp", 26], ["total", 26], ["tone", 3], ["alive", 2], ["incap", 2], ["nade", 2], ["kit", 2], ["pills", 2] ];

::Inv <- {};
function GetInvTable(p, t) {
	if (p in ::Inv)
		foreach (k, v in ::Inv[p])
			t[k] <- v;
}
function Weapon(cls, clip = -1, props = {}) {
	local w = Ent(cls);
	w.props.m_iClip1 <- clip;
	foreach (k, v in props)
		w.props[k] <- v;
	return w;
}

Reset();
local me = MakeSurvivor("Nick", 1);
me.model = "models/survivors/survivor_gambler.mdl";
me.health = 50; me.buffer = 20.0;
me.props.m_fFlags <- 3;
local v = H.MeValue(me);
Check(Field(v, ME, "who") == 1 && Field(v, ME, "on") == 1 && Field(v, ME, "crouch") == 1, "me: Nick, on, crouching");
Check(Field(v, ME, "hp") == 25 && Field(v, ME, "total") == 35, "me: 50 + 20 temp is 25 and 35 of 50 steps");
Check(Field(v, ME, "tone") == 0, "me: bone above 40");
me.health = 30; me.buffer = 0.0;
Check(Field(H.MeValue(me), ME, "tone") == 1, "me: 30 is amber");
me.health = 10;
Check(Field(H.MeValue(me), ME, "tone") == 2, "me: 10 is blood");
me.health = 1;
Check(Field(H.MeValue(me), ME, "hp") == 1, "me: 1 health still shows");
Check(H.MeValue(me) < 1000000, "me: payload fits");

local hunter = MakeSpecial(3, 250, 50);
Check(H.MeValue(hunter) == 0, "infected: no bars");

local coach = MakeSurvivor("Coach", 3); coach.model = "survivor_coach"; coach.health = 100; coach.bot = true;
local ro = MakeSurvivor("Rochelle", 2); ro.model = "survivor_producer"; ro.health = 20; ro.bot = true;
local ellis = MakeSurvivor("Ellis", 4); ellis.model = "survivor_mechanic"; ellis.dead = true; ellis.bot = true;
local mates = H.Mates(me);
Check(mates.len() == 3 && mates[0] == ro && mates[1] == coach && mates[2] == ellis, "mates: by survivor, without you");
::Inv[ro] <- { slot2 = Weapon("weapon_molotov"), slot4 = Weapon("weapon_adrenaline") };
local r = H.MateValue(ro);
Check(Field(r, MATE, "who") == 2 && Field(r, MATE, "hp") == 5 && Field(r, MATE, "tone") == 2 && Field(r, MATE, "alive") == 1,
	"mate: Rochelle at 20, blood");
Check(Field(r, MATE, "nade") == 1 && Field(r, MATE, "kit") == 0 && Field(r, MATE, "pills") == 1, "mate: her items");
ro.incap = true;
Check(Field(H.MateValue(ro), MATE, "incap") == 1, "mate: downed");
local e = H.MateValue(ellis);
Check(Field(e, MATE, "who") == 4 && Field(e, MATE, "alive") == 0 && Field(e, MATE, "hp") == 0, "mate: dead Ellis, empty bar");
Check(H.MateValue(null) == 0, "mate: empty row is 0");
Check(9 * 26 * 26 * 3 * 2 * 2 * 8 < 777216, "mate: fits tag 16 under 2^24");

me.props["m_Local.m_iHideHUD"] <- 256;
H.HideStock(me);
Check(me.props["m_Local.m_iHideHUD"] == (256 | 72), "hide: survivor loses health, team, damage arcs; crosshair bit kept");
Check((me.props["m_Local.m_iHideHUD"] & 1) == 0, "hide: never 0x1, it blocks weapon switching");
hunter.props["m_Local.m_iHideHUD"] <- 256 | 72;
H.HideStock(hunter);
Check(hunter.props["m_Local.m_iHideHUD"] == 256, "hide: infected get the stock panels back");

local st = H.PlayerState(hunter);
::T.fired.clear();
H.PanelSend5(st, true);
local sends = Fired("Command");
Check(sends.len() == 1 && sends[0].param == "name2 " + (5 * 1000000 + 10 + 11 * (10 + 11 * (10 + 11 * 10))), "digits: blank for infected");

foreach (tag in [ H.MeTag ])
	Check(tag * 1000000 + 999999 < 16777216, "tag " + tag + " is exact as a float");

Done();
