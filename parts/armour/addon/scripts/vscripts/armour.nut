const ARMOUR_DMG_FALL = 32;
const ARMOUR_DMG_DROWN = 16384;

::Armour <- {
	Versus = true,
	Survival = true,
	Stock = false,

	Incoming = 0.65,

	Bots = true,

	Floor = 1.0,

	MovingOnly = true,
	MoveSpeed = 200.0,

	SkipTypes = ARMOUR_DMG_FALL | ARMOUR_DMG_DROWN
}

function Armour::Log(msg) {
	printl("[Armour] " + msg);
}

function Armour::ModeAllowed() {
	local mode = "";
	try { mode = Director.GetGameMode(); } catch (e) {}
	if ((mode == "hd4lfort" || mode == "hd4lfreebuild"))
		return Stock;
	if (mode == "hd4lsurvival")
		return Survival;
	if (mode != "hd4l" && mode != "hd4lversus")
		return false;
	return Versus || mode == "hd4l";
}

function Armour::Applies(victim) {
	if (victim == null || !victim.IsValid() || victim.GetClassname() != "player")
		return false;
	if (!victim.IsSurvivor() || victim.IsDead())
		return false;
	return Bots || !IsPlayerABot(victim);
}

function Armour::Moving(victim) {
	if (IsPlayerABot(victim))
		return true;
	try { if (victim.IsDominatedBySpecialInfected()) return true; } catch (e) {}
	local v = victim.GetVelocity();
	return Vector(v.x, v.y, 0).Length() >= MoveSpeed || !(NetProps.GetPropInt(victim, "m_fFlags") & 1);
}

function Armour::Scale(damageTable) {
	if (Incoming >= 1.0 || !ModeAllowed())
		return false;
	if (!("Victim" in damageTable) || !("DamageDone" in damageTable))
		return false;
	if (!Applies(damageTable.Victim))
		return false;
	if (MovingOnly && !Moving(damageTable.Victim))
		return false;
	if (("DamageType" in damageTable) && (damageTable.DamageType & SkipTypes))
		return false;
	local before = damageTable.DamageDone;
	if (before <= 0)
		return false;
	local after = before * Incoming;
	if (after < Floor)
		after = before < Floor ? before : Floor;
	damageTable.DamageDone = after;
	return true;
}

function Armour::Hook() {
	if (("GameEventCallbacks" in getroottable()) && ("hd4l_armour" in ::GameEventCallbacks))
		return;
	__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
	::GameEventCallbacks["hd4l_armour"] <- true;
}

Armour.Hook();

if (!("HD4L_Parts" in getroottable()))
	::HD4L_Parts <- {};
::HD4L_Parts["armour"] <- "0.1";
