const DMG_CRUSH = 1;
const DMG_FALL = 32;

::BotTakeover <- {
	SwapCharacter = true,

	Delay = 0.25,

	RetrySeconds = 1.0,
	RetryLimit = 120,

	Versus = false,
	Survival = true,
	Stock = true,

	Holds = 0,

	Pending = {}
}

function BotTakeover::Log(msg) {
	printl("[BotTakeover] " + msg);
}

function BotTakeover::ModeAllowed() {
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

function BotTakeover::PlayerFromUserID(userid) {
	local player = null;
	try { player = GetPlayerFromUserID(userid); } catch (e) { return null; }
	if (player == null || !player.IsValid() || !player.IsSurvivor() || IsPlayerABot(player))
		return null;
	return player;
}

function BotTakeover::HoldMissionLost(hold) {
	if (hold) {
		if (Holds == 0 && Convars.GetFloat("sb_all_bot_game") == 0)
			Convars.SetValue("sb_all_bot_game", 1);
		Holds++;
	} else if (Holds > 0) {
		Holds--;
		if (Holds == 0)
			Convars.SetValue("sb_all_bot_game", 0);
	}
}

function BotTakeover::Schedule(userid, delay, attempt) {
	DoEntFire("!self", "RunScriptCode", "::BotTakeover.TakeOver(" + userid + ", " + attempt + ")", delay, null, Entities.First());
}

function BotTakeover::OnGameEvent_player_death(params) {
	if (!("userid" in params) || !ModeAllowed())
		return;
	local player = PlayerFromUserID(params.userid);
	if (player == null)
		return;
	if (Condemned(player)) {
		return;
	}
	HoldMissionLost(true);
	Schedule(params.userid, Delay, 0);
}

function BotTakeover::Condemned(player) {
	if (!("OneLife" in getroottable()) || !("IsCondemned" in ::OneLife))
		return false;
	try { return ::OneLife.IsCondemned(player); } catch (e) { return false; }
}

function BotTakeover::OnGameEvent_defibrillator_used(params) {
	if (!ModeAllowed() || !("subject" in params))
		return;
	DoEntFire("!self", "RunScriptCode", "::BotTakeover.Reclaim(" + params.subject + ")", 0.1, null, Entities.First());
}

function BotTakeover::Reclaim(subject) {
	local bot = null;
	try { bot = GetPlayerFromUserID(subject); } catch (e) { return; }
	if (bot == null || !bot.IsValid() || !IsPlayerABot(bot) || !bot.IsSurvivor() || bot.IsDead())
		return;
	local player = DeadHuman();
	if (player == null)
		return;
	HoldMissionLost(true);
	try { Steal(player, bot); } catch (e) { Log("defib reclaim of " + bot.GetPlayerName() + " failed: " + e); }
	HoldMissionLost(false);
}

function BotTakeover::DeadHuman() {
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null)
		if (p.IsSurvivor() && !IsPlayerABot(p) && p.IsDead())
			return p;
	return null;
}

function BotTakeover::TakeOver(userid, attempt) {
	local held = attempt == 0;

	local player = PlayerFromUserID(userid);

	local bot = (player != null && (player.IsDead() || player.IsDying())) ? PickBot() : null;

	if (bot != null) {
		if (!held)
			HoldMissionLost(true);
		held = true;
		try { Steal(player, bot); } catch (e) { Log("takeover of " + bot.GetPlayerName() + " failed: " + e); }
	} else if (player != null && player.IsDead() && attempt < RetryLimit) {
		Schedule(userid, RetrySeconds, attempt + 1);
	}

	if (held)
		HoldMissionLost(false);
}

function BotTakeover::ClearFade(player) {
	local fade = SpawnEntityFromTable("env_fade", { targetname = "bot_takeover_fade", duration = "0.4", holdtime = "0", renderamt = "255", rendercolor = "0 0 0", spawnflags = "5" });
	if (fade == null)
		return;
	DoEntFire("!self", "Fade", "", 0, player, fade);
	DoEntFire("!self", "Kill", "", 1.0, null, fade);
}

function BotTakeover::CanHijack(player) {
	if (!ModeAllowed() || player == null || !player.IsValid() || IsPlayerABot(player) || Condemned(player))
		return false;
	local id = player.GetPlayerUserId();
	if ((id in Pending) && Time() - Pending[id] < 0.5)
		return true;
	return PickBot() != null;
}

function BotTakeover::Hijack(player) {
	local id = player.GetPlayerUserId();
	if ((id in Pending) && Time() - Pending[id] < 0.5)
		return;
	Pending[id] <- Time();
	DoEntFire("!self", "RunScriptCode", "::BotTakeover.HijackNow(" + id + ")", 0.0, null, Entities.First());
}

function BotTakeover::HijackNow(userid) {
	local player = PlayerFromUserID(userid);
	if (player == null || player.IsDead() || player.IsDying())
		return;
	local bot = PickBot();
	if (bot == null) {
		player.TakeDamage(99999, DMG_FALL, Entities.First());
		return;
	}
	local playerOrigin = player.GetOrigin();
	local playerAngles = player.EyeAngles();
	local botOrigin = bot.GetOrigin();
	local botAngles = bot.EyeAngles();

	if (SwapCharacter)
		SwapIdentity(player, bot);
	player.SetHealth(bot.GetHealth());
	player.SetHealthBuffer(bot.GetHealthBuffer());
	foreach (prop in [ "m_currentReviveCount", "m_bIsOnThirdStrike", "m_isGoingToDie" ])
		NetProps.SetPropInt(player, prop, NetProps.GetPropInt(bot, prop));
	TransferInventory(player, bot);
	botAngles.z = 0;
	player.SnapEyeAngles(botAngles);
	player.SetOrigin(botOrigin);
	playerAngles.z = 0;
	bot.SnapEyeAngles(playerAngles);
	bot.SetOrigin(playerOrigin);
	KillBot(bot);
	ClearFade(player);
	if (("DeathShockwave" in getroottable()) && ("Start" in ::DeathShockwave))
		try { ::DeathShockwave.StartAt(playerOrigin, player); } catch (e) {}
}

function BotTakeover::PickBot() {
	local best = null;
	local bestScore = 0;
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null) {
		if (!IsPlayerABot(p) || !p.IsSurvivor() || p.IsDead() || p.IsDying())
			continue;
		if (p.IsIncapacitated() || p.IsHangingFromLedge())
			continue;
		local score = p.GetHealth() + p.GetHealthBuffer();
		if (p.IsDominatedBySpecialInfected())
			score -= 1000;
		if (best == null || score > bestScore) {
			best = p;
			bestScore = score;
		}
	}
	return best;
}

function BotTakeover::Steal(player, bot) {

	local corpse = FindCorpse(NetProps.GetPropInt(player, "m_survivorCharacter"));
	local bodyOrigin = null;
	local bodyYaw = 0;
	if (corpse != null) {
		bodyOrigin = corpse.GetOrigin();
		bodyYaw = corpse.GetAngles().y;
	}

	local returnTime = Convars.GetFloat("defibrillator_return_to_life_time");
	Convars.SetValue("defibrillator_return_to_life_time", 1);
	player.ReviveByDefib();
	Convars.SetValue("defibrillator_return_to_life_time", returnTime);

	if (SwapCharacter)
		SwapIdentity(player, bot);

	player.SetHealth(bot.GetHealth());
	player.SetHealthBuffer(bot.GetHealthBuffer());
	foreach (prop in [ "m_currentReviveCount", "m_bIsOnThirdStrike", "m_isGoingToDie" ])
		NetProps.SetPropInt(player, prop, NetProps.GetPropInt(bot, prop));

	TransferInventory(player, bot);

	local angles = bot.EyeAngles();
	angles.z = 0;
	player.SnapEyeAngles(angles);
	player.SetOrigin(bot.GetOrigin());
	ClearFade(player);

	if (bodyOrigin != null) {
		bot.SetOrigin(bodyOrigin);
		bot.SnapEyeAngles(QAngle(0, bodyYaw, 0));
		if (corpse.IsValid())
			corpse.Kill();
		KillBot(bot);
	} else {
		local botCharacter = NetProps.GetPropInt(bot, "m_survivorCharacter");
		KillBot(bot);
		DoEntFire("!self", "RunScriptCode", "::BotTakeover.RemoveCorpse(" + botCharacter + ")", 0.1, null, Entities.First());
	}
}

function BotTakeover::SwapIdentity(player, bot) {
	local playerCharacter = NetProps.GetPropInt(player, "m_survivorCharacter");
	local botCharacter = NetProps.GetPropInt(bot, "m_survivorCharacter");
	local playerModel = player.GetModelName();
	local botModel = bot.GetModelName();

	NetProps.SetPropInt(player, "m_survivorCharacter", botCharacter);
	player.SetModel(botModel);
	NetProps.SetPropInt(bot, "m_survivorCharacter", playerCharacter);
	bot.SetModel(playerModel);
}

function BotTakeover::TransferInventory(player, bot) {
	local inv = {};
	GetInvTable(bot, inv);

	if ("slot1" in inv) {
		local given = player.GetActiveWeapon();
		if (given != null && given.IsValid())
			given.Kill();
	}

	foreach (slot, weapon in inv) {
		if (weapon == null || !weapon.IsValid())
			continue;

		local ammoType = NetProps.GetPropInt(weapon, "m_iPrimaryAmmoType");
		local reserve = ammoType >= 0 ? NetProps.GetPropIntArray(bot, "m_iAmmo", ammoType) : 0;

		local dual = false;
		if (weapon.GetClassname() == "weapon_pistol") {
			dual = NetProps.GetPropInt(weapon, "m_hasDualWeapons") != 0;
			NetProps.SetPropInt(weapon, "m_hasDualWeapons", 0);
			NetProps.SetPropInt(weapon, "m_isDualWielding", 0);
		}
		bot.DropItem(weapon.GetClassname());
		if (dual)
			NetProps.SetPropInt(weapon, "m_isDualWielding", 1);

		NetProps.SetPropInt(weapon, "m_iExtraPrimaryAmmo", reserve);
		DoEntFire("!self", "Use", "", 0, player, weapon);
	}
}

function BotTakeover::FindCorpse(character) {
	local body = null;
	while ((body = Entities.FindByClassname(body, "survivor_death_model")) != null) {
		if (NetProps.GetPropInt(body, "m_nCharacterType") == character)
			return body;
	}
	return null;
}

function BotTakeover::RemoveCorpse(character) {
	local body = FindCorpse(character);
	if (body != null)
		body.Kill();
}

function BotTakeover::KillBot(bot) {
	NetProps.SetPropEntity(bot, "m_hDamageFilter", null);
	NetProps.SetPropString(bot, "m_iszDamageFilterName", "");

	local world = Entities.First();

	if (bot.IsSuppressingFallingDamage()) {
		bot.TakeDamage(99999, DMG_CRUSH, world);
		DoEntFire("!self", "IgnoreFallDamageWithoutReset", "0.000001", 0, null, bot);
		DoEntFire("!self", "RunScriptCode", "self.TakeDamage(99999, 32, Entities.First())", 0.034, null, bot);
	} else {
		bot.TakeDamage(99999, DMG_FALL, world);
	}
}

function BotTakeover::PrecacheFade() {
	PrecacheEntityFromTable({ classname = "env_fade", duration = "0.4", holdtime = "0", renderamt = "255", rendercolor = "0 0 0", spawnflags = "5" });
}

function BotTakeover::Hook() {
	if (("GameEventCallbacks" in getroottable()) && ("hd4l_bot_takeover" in ::GameEventCallbacks))
		return;
	__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
	::GameEventCallbacks["hd4l_bot_takeover"] <- true;
}

BotTakeover.PrecacheFade();
BotTakeover.Hook();

if (!("HD4L_Parts" in getroottable()))
	::HD4L_Parts <- {};
::HD4L_Parts["bot_takeover"] <- "0.1";
