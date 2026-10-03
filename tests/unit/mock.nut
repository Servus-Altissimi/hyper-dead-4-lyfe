::T <- {
	now = 100.0, mode = "hd4l", ents = [], nextIndex = 1, fired = [], sounds = [], spawned = [],
	cvars = {}, logs = [], pass = 0, fail = 0, suite = ""
};

::GameEventCallbacks <- {};

const INFECTED_FLAG_CANT_SEE_SURVIVORS = 1;
const INFECTED_FLAG_CANT_HEAR_SURVIVORS = 2;
const INFECTED_FLAG_CANT_FEEL_SURVIVORS = 4;

function printl(s) { ::T.logs.append(s.tostring()); }
function Time() { return ::T.now; }
function RandomInt(a, b) { return a; }
function RandomFloat(a, b) { return (a + b) * 0.5; }
function ScreenShake(a, b, c, d, e, f, g) {}
function PrecacheSound(s) {}
function PrecacheModel(s) {}
function PrecacheScriptSound(s) {}
function PrecacheEntityFromTable(t) {}
function __CollectEventCallbacks(a, b, c, d) {}
function RegisterScriptGameEventListener(n) {}
function ClientPrint(a, b, c) {}
function IncludeScript(a, b = null) {}
function SaveTable(n, t) {}
function RestoreTable(n, t) {}
function GetFlowDistanceForPosition(p) { return 0.0; }
function TraceLine(t) { t.hit <- false; t.fraction <- 1.0; t.pos <- t.end; }
function IsPlayerABot(p) { return p.bot; }
function GetPlayerFromUserID(id) {
	foreach (e in ::T.ents)
		if (e.cls == "player" && e.userid == id)
			return e;
	return null;
}
function EntIndexToHScript(i) {
	foreach (e in ::T.ents)
		if (e.index == i)
			return e;
	return null;
}
function EmitSoundOn(s, e) { ::T.sounds.append({ sound = s, ent = e, how = "plain", level = 75, pitch = 100 }); }
function EmitSoundOnClient(s, p) { ::T.sounds.append({ sound = s, ent = p, how = "client", level = 75, pitch = 100 }); }
function EmitAmbientSoundOn(s, v, l, p, e) { ::T.sounds.append({ sound = s, ent = e, how = "ambient", level = l, pitch = p }); }
function DoEntFire(target, input, param, delay, activator, ent) {
	::T.fired.append({ input = input, param = param, delay = delay, activator = activator, ent = ent });
}
function EntFire(a, b, c = "", d = 0.0) {}
function SendToServerConsole(c) { ::T.fired.append({ input = "ServerCommand", param = c, delay = 0.0, activator = null, ent = null }); }
function GetInvTable(p, t) {}
function CommandABot(t) { ::T.fired.append({ input = "CommandABot", param = t, delay = 0.0, activator = null, ent = ("bot" in t) ? t.bot : null }); }

class Vector {
	x = 0.0; y = 0.0; z = 0.0;
	constructor(a = 0.0, b = 0.0, c = 0.0) { x = a.tofloat(); y = b.tofloat(); z = c.tofloat(); }
	function _add(o) { return Vector(x + o.x, y + o.y, z + o.z); }
	function _sub(o) { return Vector(x - o.x, y - o.y, z - o.z); }
	function _mul(k) { return Vector(x * k, y * k, z * k); }
	function _unm() { return Vector(-x, -y, -z); }
	function Length() { return sqrt(x * x + y * y + z * z); }
	function Norm() { local l = Length(); if (l > 0.0) { x /= l; y /= l; z /= l; } return l; }
	function Dot(o) { return x * o.x + y * o.y + z * o.z; }
	function Scale(k) { return Vector(x * k, y * k, z * k); }
	function _tostring() { return format("(%.1f %.1f %.1f)", x, y, z); }
}

class QAngle {
	x = 0.0; y = 0.0; z = 0.0;
	constructor(a = 0.0, b = 0.0, c = 0.0) { x = a.tofloat(); y = b.tofloat(); z = c.tofloat(); }
	function Forward() {
		local p = x * 0.0174533, w = y * 0.0174533;
		return Vector(cos(p) * cos(w), cos(p) * sin(w), -sin(p));
	}
	function Left() { local w = y * 0.0174533; return Vector(-sin(w), cos(w), 0.0); }
}

class Ent {
	cls = ""; index = 0; origin = null; vel = null; angles = null; props = null; kv = null;
	health = 100; maxHealth = 100; buffer = 0.0; incap = false; team = 0; zombie = 0; bot = false; dead = false; ghost = false;
	userid = 0; name = ""; model = ""; attachments = null; valid = true; weapon = null; events = null; scope = null; parent = null;

	constructor(c) {
		cls = c; index = ::T.nextIndex++; origin = Vector(); vel = Vector(); angles = QAngle();
		props = {}; kv = {}; attachments = []; events = []; scope = {};
		::T.ents.append(this);
	}
	function IsValid() { return valid; }
	function GetClassname() { return cls; }
	function GetEntityIndex() { return index; }
	function GetOrigin() { return Vector(origin.x, origin.y, origin.z); }
	function SetOrigin(v) { origin = Vector(v.x, v.y, v.z); }
	function GetCenter() { return GetOrigin() + Vector(0, 0, 36); }
	function GetVelocity() { return Vector(vel.x, vel.y, vel.z); }
	function SetVelocity(v) { vel = Vector(v.x, v.y, v.z); }
	function ApplyAbsVelocityImpulse(v) { vel = vel + v; events.append({ what = "impulse", v = v }); }
	function ApplyLocalAngularVelocityImpulse(v) {}
	function TakeDamage(d, t, a) { events.append({ what = "damage", amount = d, type = t, attacker = a }); health -= d.tointeger(); }
	function Stagger(v) { events.append({ what = "stagger", from = v }); }
	function GetHealth() { return health; }
	function SetHealth(h) { health = h; }
	function GetMaxHealth() { return maxHealth; }
	function GetHealthBuffer() { return buffer; }
	function SetHealthBuffer(b) { buffer = b; }
	function IsSurvivor() { return cls == "player" && team == 2; }
	function IsDead() { return dead; }
	function IsDying() { return false; }
	function IsGhost() { return ghost; }
	function IsIncapacitated() { return incap; }
	function IsHangingFromLedge() { return false; }
	function IsAdrenalineActive() { return false; }
	function IsImmobilized() { return false; }
	function IsStaggering() { return false; }
	function IsDominatedBySpecialInfected() { return false; }
	function GetZombieType() { return zombie; }
	function GetPlayerUserId() { return userid; }
	function GetPlayerName() { return name; }
	function GetName() { return ("targetname" in kv) ? kv.targetname : ""; }
	function GetModelName() { return model; }
	function EyeAngles() { return QAngle(angles.x, angles.y, angles.z); }
	function SnapEyeAngles(a) { angles = QAngle(a.x, a.y, a.z); }
	function EyePosition() { return GetOrigin() + Vector(0, 0, 64); }
	function GetAngles() { return QAngle(angles.x, angles.y, angles.z); }
	function SetAngles(a) { angles = QAngle(a.x, a.y, a.z); }
	function GiveItem(n) { events.append({ what = "give", name = n }); }
	function GetForwardVector() { return angles.Forward(); }
	function GetActiveWeapon() { return weapon; }
	function GetMaxClip1() { return 15; }
	function LookupAttachment(n) { local i = attachments.find(n); return i == null ? 0 : i + 1; }
	function GetAttachmentOrigin(i) { return GetOrigin() + Vector(0, 0, 60); }
	function GetAttachmentAngles(i) { return GetAngles(); }
	function LookupSequence(n) { return -1; }
	function LookupActivity(n) { return -1; }
	function GetSequence() { return 0; }
	function SetSenseFlags(f) { props.senseFlags <- f; }
	function SetFriction(f) {}
	function SetContext(a, b, c) {}
	function ValidateScriptScope() {}
	function GetScriptScope() { return scope; }
	function ConnectOutput(a, b) {}
	function Kill() { valid = false; }
	function GetMoveParent() { return parent; }
	function _tostring() { return cls + "#" + index; }
}

function MakePlayer(team, name, userid) {
	local p = Ent("player");
	p.team = team; p.name = name; p.userid = userid;
	p.props.m_iTeamNum <- team;
	p.props.m_fFlags <- 1;
	p.props.m_nButtons <- 0;
	p.props.m_afButtonPressed <- 0;
	p.props.m_afButtonDisabled <- 0;
	p.props.m_flLaggedMovementValue <- 1.0;
	return p;
}

function MakeSurvivor(name = "Nick", userid = 1) { return MakePlayer(2, name, userid); }

function MakeSpecial(zombie, health = 250, userid = 50) {
	local p = MakePlayer(3, "special" + zombie, userid);
	p.zombie = zombie; p.health = health; p.maxHealth = health; p.bot = true;
	return p;
}

class NetPropsClass {
	function Get(e, n, d) { return (n in e.props) ? e.props[n] : d; }
	function GetPropInt(e, n) { return Get(e, n, 0); }
	function GetPropFloat(e, n) { return Get(e, n, 0.0); }
	function GetPropEntity(e, n) { return Get(e, n, null); }
	function GetPropString(e, n) { return Get(e, n, ""); }
	function GetPropVector(e, n) { return Get(e, n, Vector()); }
	function GetPropIntArray(e, n, i) { return Get(e, n + i, 0); }
	function GetPropFloatArray(e, n, i) { return Get(e, n + i, 0.0); }
	function GetPropEntityArray(e, n, i) { return Get(e, n + i, null); }
	function SetPropInt(e, n, v) { e.props[n] <- v; }
	function SetPropFloat(e, n, v) { e.props[n] <- v; }
	function SetPropEntity(e, n, v) { e.props[n] <- v; }
	function SetPropString(e, n, v) { e.props[n] <- v; }
	function SetPropVector(e, n, v) { e.props[n] <- v; }
	function SetPropIntArray(e, n, v, i) { e.props[n + i] <- v; }
	function SetPropFloatArray(e, n, v, i) { e.props[n + i] <- v; }
	function SetPropStringArray(e, n, v, i) { e.props[n + i] <- v; }
	function HasProp(e, n) { return n in e.props; }
}
::NetProps <- NetPropsClass();

class EntitiesClass {
	world = null;
	function First() { if (world == null) world = Ent("worldspawn"); return world; }
	function After(prev) {
		local start = prev == null ? 0 : ::T.ents.find(prev) + 1;
		return start;
	}
	function FindByClassname(prev, cls) {
		local list = ::T.ents;
		for (local i = After(prev); i < list.len(); i++)
			if (list[i].valid && (list[i].cls == cls || (cls.len() > 1 && cls.slice(cls.len() - 1) == "*" && list[i].cls.find(cls.slice(0, cls.len() - 1)) == 0)))
				return list[i];
		return null;
	}
	function FindByClassnameWithin(prev, cls, pos, r) {
		local list = ::T.ents;
		for (local i = After(prev); i < list.len(); i++)
			if (list[i].valid && list[i].cls == cls && (list[i].GetOrigin() - pos).Length() <= r)
				return list[i];
		return null;
	}
	function FindByName(prev, n) {
		foreach (e in ::T.ents)
			if (e.valid && e.GetName() == n)
				return e;
		return null;
	}
}
::Entities <- EntitiesClass();

class ConvarsClass {
	function SetValue(n, v) { ::T.cvars[n] <- v; }
	function GetFloat(n) { return (n in ::T.cvars) ? ::T.cvars[n].tofloat() : 1.0; }
	function GetClientConvarValue(n, i) { return ""; }
}
::Convars <- ConvarsClass();

class DirectorClass {
	function GetGameMode() { return ::T.mode; }
	function GetMapNumber() { return 1; }
	function IsFirstMapInScenario() { return false; }
	function IsFinale() { return false; }
	function IsTankInPlay() { return false; }
	function HasAnySurvivorLeftSafeArea() { return false; }
	function GetFurthestSurvivorFlow() { return 0.0; }
	function GetMapName() { return "c1m1_hotel"; }
}
::Director <- DirectorClass();

function SpawnEntityFromTable(cls, kv) {
	local e = Ent(cls);
	e.kv = kv;
	if ("origin" in kv && typeof kv.origin == "instance")
		e.origin = kv.origin;
	::T.spawned.append(e);
	return e;
}

function ZSpawn(t) { return null; }

function Suite(name) {
	::T.suite = name;
	print("== " + name + "\n");
}

function Reset() {
	::T.ents.clear(); ::T.fired.clear(); ::T.sounds.clear(); ::T.spawned.clear(); ::T.logs.clear();
	::T.cvars.clear(); ::T.now = 100.0; ::T.mode = "hd4l";
	::Entities.world = null;
}

function Check(ok, what) {
	if (ok) {
		::T.pass++;
		print("  ok   " + what + "\n");
	} else {
		::T.fail++;
		print("  FAIL " + what + "\n");
	}
}

function Near(a, b, what, tol = 0.01) {
	Check(fabs(a - b) <= tol, what + " (got " + a + ", want " + b + ")");
}

function Events(ent, what) {
	local out = [];
	foreach (e in ent.events)
		if (e.what == what)
			out.append(e);
	return out;
}

function Fired(input) {
	local out = [];
	foreach (f in ::T.fired)
		if (f.input == input)
			out.append(f);
	return out;
}

function Spawned(cls) {
	local out = [];
	foreach (e in ::T.spawned)
		if (e.cls == cls)
			out.append(e);
	return out;
}

function Done() {
	print("RESULT " + ::T.suite + " pass=" + ::T.pass + " fail=" + ::T.fail + "\n");
}

function Load(path) {
	dofile(::ROOT + "/" + path);
}
