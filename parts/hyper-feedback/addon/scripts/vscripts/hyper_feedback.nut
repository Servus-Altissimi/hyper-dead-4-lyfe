const HITGROUP_HEAD = 1;
const TEAM_INFECTED = 3;
const ZOMBIE_TANK = 8;

::HyperFeedback <- {
	Versus = true,
	Survival = true,
	Stock = true,
	Files = [ "hyper_feedback_panel" ],

	PanelRefresh = 1.0,
	PanelMark = { hit = 1, hit_head = 2, kill = 3, headshot = 4, parry = 5, glory = 3 },
	PanelArc = { dmg_front = 1, dmg_frontright = 2, dmg_right = 3, dmg_backright = 4, dmg_back = 5, dmg_backleft = 6, dmg_left = 7, dmg_frontleft = 8 },
	PanelCue = { cue_left = 1, cue_right = 2, cue_front = 3, cue_back = 4, cue_jump = 5 },
	PanelGap = 0.05,

	FeedLife = 7.0,
	FeedRows = 4,

	LowHealth = 40,

	StockHide = 72,
	MeSteps = 50,
	MateSteps = 25,
	MateTags = [ 15, 16, 0 ],
	MeTag = 14,
	ScrapTag = 8,
	CostTag = 9,
	WaveTag = 10,
	ToneAmber = 40,
	ToneBlood = 25,
	AmmoGap = 0.12,
	TeamRefresh = 4.0,

	ChainShow = 3,

	StatsGap = 0.25,

	Resync = true,
	FeedClass = { [3] = 9, [1] = 10, [2] = 11, [4] = 12, [5] = 13, [6] = 14, [8] = 15 },
	FeedSurvivor = [ "gambler", "producer", "coach", "mechanic", "namvet", "teenangst", "biker", "manager" ],
	Feed = [],

	Hold = { hurt = 0.16, hit = 0.10, hit_head = 0.16, kill = 0.22, headshot = 0.30, spike = 0.6, glory = 0.35, parry = 0.45,
	         dmg_front = 0.5, dmg_frontright = 0.5, dmg_right = 0.5, dmg_backright = 0.5, dmg_back = 0.5, dmg_backleft = 0.5, dmg_left = 0.5, dmg_frontleft = 0.5,
	         cue_left = 0.5, cue_right = 0.5, cue_front = 0.5, cue_back = 0.5, cue_jump = 0.6 },
	Rank = { hurt = 1, hit = 1, hit_head = 2, kill = 3, headshot = 4, spike = 5, glory = 6, parry = 4,
	         dmg_front = 0, dmg_frontright = 0, dmg_right = 0, dmg_backright = 0, dmg_back = 0, dmg_backleft = 0, dmg_left = 0, dmg_frontleft = 0,
	         cue_left = 5, cue_right = 5, cue_front = 5, cue_back = 5, cue_jump = 5 },

	DmgDirs = [ "front", "frontright", "right", "backright", "back", "backleft", "left", "frontleft" ],
	TankLevels = 20,

	Sounds = {
		hit = "hyper/hit.mp3",
		hit_head = "hyper/hit_head.mp3",
		kill = "hyper/kill.mp3",
		headshot = "hyper/headshot.mp3",
		spike = "hyper/heavy.mp3",
		parry = "hyper/parry.mp3"
	},

	SoundGap = { hit = 0.04, hit_head = 0.06, kill = 0.12, headshot = 0.15, spike = 0.5, parry = 0.2 },

	HurtRipple = 25,

	Interval = 0.1,

	LastSound = {},

	Players = {},
	Generation = 0
}

function HyperFeedback::Log(msg) {
	printl("[HyperFeedback] " + msg);
}

function HyperFeedback::ModeAllowed() {
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

function HyperFeedback::Precache() {
	foreach (name, path in Sounds)
		PrecacheSound(path);
}

function HyperFeedback::FlashFor(p, name) {
	if (p != null && p.IsValid() && !IsPlayerABot(p))
		PanelFlash(p, name);
}

function HyperFeedback::Cue(name, p = null) {
	if (p != null) {
		FlashFor(p, "cue_" + name);
		return;
	}
	foreach (id, st in Players)
		if (st.p != null && st.p.IsValid() && st.p.IsSurvivor())
			PanelFlash(st.p, "cue_" + name);
}

function HyperFeedback::Struggle(state, p = null) {
	if (p == null || !p.IsValid() || IsPlayerABot(p))
		return;
	local st = PlayerState(p);
	local codes = { wait = 1, ["0"] = 2, ["1"] = 3, ["2"] = 4, ["3"] = 5, ["4"] = 6, ["5"] = 7, ["6"] = 8, fail = 9 };
	st.pstruggle = (state in codes) ? codes[state] : 0;
	PanelSend2(st, true);
}

function HyperFeedback::Glory(p = null) {
	if (p != null)
		FlashFor(p, "glory");
}

function HyperFeedback::Play(name, p = null) {
	local now = Time();
	local gaps = LastSound;
	if (p == null)
		p = Human();
	else
		gaps = PlayerState(p).lastSound;
	if ((name in gaps) && now - gaps[name] < SoundGap[name])
		return;
	gaps[name] <- now;
	if (p != null && p.IsValid())
		EmitSoundOn(Sounds[name], p);
}

function HyperFeedback::Spike() {
	foreach (id, st in Players)
		if (st.p != null && st.p.IsValid() && st.p.IsSurvivor())
			PanelFlash(st.p, "spike");
}

function HyperFeedback::Human() {
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null)
		if (p.IsSurvivor() && !IsPlayerABot(p) && !p.IsDead())
			return p;
	return null;
}

function HyperFeedback::TankFraction() {
	local worst = -1.0;
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null) {
		if (NetProps.GetPropInt(p, "m_iTeamNum") != TEAM_INFECTED || p.IsDead() || p.IsGhost() || p.GetZombieType() != ZOMBIE_TANK)
			continue;
		if (p.GetHealth() <= 0 || p.IsDying() || p.IsIncapacitated())
			continue;
		local max = p.GetMaxHealth();
		if (max <= 0)
			continue;
		local f = p.GetHealth().tofloat() / max;
		if (worst < 0 || f < worst)
			worst = f;
	}
	return worst;
}

function HyperFeedback::TankLevel() {
	local tank = TankFraction();
	if (tank < 0)
		return "n";
	local bucket = (tank * TankLevels).tointeger();
	if (bucket > TankLevels - 1) bucket = TankLevels - 1;
	if (bucket < 0) bucket = 0;
	return bucket.tostring();
}

function HyperFeedback::StaminaLevel(p = null) {
	local human = p != null ? p : Human();
	if (human == null || !("Momentum" in getroottable()) || !("StateOf" in ::Momentum))
		return 5;
	local s = ::Momentum.StateOf(human);
	local max = ("StaminaMax" in ::Momentum) ? ::Momentum.StaminaMax : 100.0;
	local frac = ("stamina" in s) ? s.stamina / max : 1.0;
	local level = (frac * 5 + 0.5).tointeger();
	if (level < 0) level = 0;
	if (level > 5) level = 5;
	return level;
}

function HyperFeedback::HyperOn(p) {
	if (p == null || !("Momentum" in getroottable()) || !("StateOf" in ::Momentum))
		return 0;
	local s = ::Momentum.StateOf(p);
	if ((("hyperUntil" in s) && Time() < s.hyperUntil) || (("lastStand" in s) && s.lastStand))
		return 1;
	return 0;
}

function HyperFeedback::PlayerState(p) {
	local id = p.GetPlayerUserId();
	if (!(id in Players))
		Players[id] <- { p = p, mark = "", markUntil = 0.0, lastSound = {},
		                 pmark = 0, mseq = 0, arc = 0, aseq = 0, stam = 10, dot = 1, tank = 0, pstruggle = 0, spike = 0, cue = 0, cseq = 0, hook = 0, chain = 0,
		                 sent1 = -1, sent2 = -1, sent3 = -1, sent4 = -1, sent5 = -1, sent6 = -1, sent11 = -1, sent12 = -1, sent13 = -1,
		                 sentAt1 = -10.0, sentAt2 = -10.0, sentAt3 = -10.0, sentAt4 = -10.0, sentAt5 = -10.0, sentAt6 = -10.0,
		                 sentAt11 = -10.0, sentAt12 = -10.0, sentAt13 = -10.0, sendAt = -10.0 };
	local st = Players[id];
	st.p = p;
	return st;
}

function HyperFeedback::Tick(generation) {
	if (generation != Generation)
		return;
	if (ModeAllowed())
		try { PanelTick(); } catch (e) { Log("panel tick failed: " + e); }
	DoEntFire("!self", "RunScriptCode", "::HyperFeedback.Tick(" + generation + ")", Interval, null, Entities.First());
}

function HyperFeedback::HumanSurvivor(userid) {
	local p = null;
	try { p = GetPlayerFromUserID(userid); } catch (e) { return null; }
	if (p != null && p.IsValid() && p.IsSurvivor() && !IsPlayerABot(p))
		return p;
	return null;
}

function HyperFeedback::HumanAny(userid) {
	local p = null;
	try { p = GetPlayerFromUserID(userid); } catch (e) { return null; }
	if (p != null && p.IsValid() && !IsPlayerABot(p))
		return p;
	return null;
}

function HyperFeedback::OnGameEvent_infected_hurt(params) {
	if (!ModeAllowed() || !("attacker" in params))
		return;
	local shooter = HumanSurvivor(params.attacker);
	if (shooter == null)
		return;
	local head = ("hitgroup" in params) && params.hitgroup == HITGROUP_HEAD;
	FlashFor(shooter, head ? "hit_head" : "hit");
}

function HyperFeedback::OnGameEvent_player_hurt(params) {
	if (!ModeAllowed() || !("userid" in params))
		return;
	local damage = ("dmg_health" in params) ? params.dmg_health : 0;
	if (damage <= 0)
		return;
	local victim = HumanAny(params.userid);
	if (victim != null && victim.IsSurvivor()) {
		if (damage >= HurtRipple)
			FlashFor(victim, "hurt");
		else {
			local dir = HurtDirection(params);
			if (dir != null)
				FlashFor(victim, "dmg_" + dir);
		}
	}
	if (!("attacker" in params))
		return;
	local attacker = HumanAny(params.attacker);
	if (attacker == null)
		return;
	local target = null;
	try { target = GetPlayerFromUserID(params.userid); } catch (e) { return; }
	if (target == null || !target.IsValid())
		return;
	local attackerTeam = NetProps.GetPropInt(attacker, "m_iTeamNum");
	local targetTeam = NetProps.GetPropInt(target, "m_iTeamNum");
	if (attackerTeam == targetTeam)
		return;
	local head = ("hitgroup" in params) && params.hitgroup == HITGROUP_HEAD;
	FlashFor(attacker, head ? "hit_head" : "hit");
}

function HyperFeedback::HurtDirection(params) {
	local victim = null;
	try { victim = GetPlayerFromUserID(params.userid); } catch (e) { return null; }
	if (victim == null || !victim.IsValid())
		return null;
	local attacker = null;
	if (("attacker" in params) && params.attacker > 0)
		try { attacker = GetPlayerFromUserID(params.attacker); } catch (e) {}
	if (attacker == null && ("attackerentid" in params) && params.attackerentid > 0)
		try { attacker = EntIndexToHScript(params.attackerentid); } catch (e) {}
	if (attacker == null || !attacker.IsValid() || attacker == victim)
		return null;
	local to = attacker.GetOrigin() - victim.GetOrigin();
	if (to.x * to.x + to.y * to.y < 1.0)
		return null;
	local bearing = atan2(to.y, to.x) * 57.29578;
	local diff = bearing - victim.EyeAngles().y;
	while (diff > 180.0) diff -= 360.0;
	while (diff <= -180.0) diff += 360.0;
	local index = (((-diff) / 45.0) + 0.5).tointeger();
	index = ((index % 8) + 8) % 8;
	return DmgDirs[index];
}

function HyperFeedback::OnGameEvent_infected_death(params) {
	if (!ModeAllowed() || !("attacker" in params))
		return;
	local shooter = HumanSurvivor(params.attacker);
	if (shooter == null)
		return;
	local head = ("headshot" in params) && params.headshot;
	FlashFor(shooter, head ? "headshot" : "kill");
}

function HyperFeedback::OnGameEvent_player_death(params) {
	if (!ModeAllowed())
		return;
	local victim = null;
	if ("userid" in params)
		try { victim = GetPlayerFromUserID(params.userid); } catch (e) {}
	if (victim != null && victim.IsValid() && (victim.IsSurvivor() || !victim.IsGhost())) {
		local k = 17;
		local killer = null;
		if (("attacker" in params) && params.attacker != 0)
			try { killer = GetPlayerFromUserID(params.attacker); } catch (e) {}
		if (killer != null && killer.IsValid() && killer != victim)
			k = FeedCode(killer);
		else if ("attackerentid" in params) {
			local ent = null;
			try { ent = EntIndexToHScript(params.attackerentid); } catch (e) {}
			if (ent != null && ent.IsValid() && (ent.GetClassname() == "infected" || ent.GetClassname() == "witch"))
				k = 16;
		}
		try { FeedKill(k, FeedCode(victim), ("headshot" in params) && params.headshot); } catch (e) { Log("feed failed: " + e); }
	}
	if (!("attacker" in params))
		return;
	local attacker = HumanAny(params.attacker);
	if (attacker == null || victim == null || !victim.IsValid() || attacker == victim)
		return;
	if (NetProps.GetPropInt(attacker, "m_iTeamNum") == NetProps.GetPropInt(victim, "m_iTeamNum"))
		return;
	local head = ("headshot" in params) && params.headshot;
	FlashFor(attacker, head ? "headshot" : "kill");
}

function HyperFeedback::OnGameEvent_witch_killed(params) {
	if (!ModeAllowed() || !("userid" in params))
		return;
	local killer = null;
	try { killer = GetPlayerFromUserID(params.userid); } catch (e) {}
	try { FeedKill(FeedCode(killer), 16, false); } catch (e) { Log("feed failed: " + e); }
	local shooter = HumanSurvivor(params.userid);
	if (shooter != null)
		FlashFor(shooter, "kill");
}

function HyperFeedback::OnGameEvent_player_disconnect(params) {
	if (("userid" in params) && (params.userid in Players))
		delete Players[params.userid];
}

function HyperFeedback::OnGameEvent_round_start(params) {
	Players = {};
	Feed = [];
	Resync = true;
	Generation++;
	Tick(Generation);
}

function HyperFeedback::Hook() {
	if (("GameEventCallbacks" in getroottable()) && ("hd4l_hyper_feedback" in ::GameEventCallbacks))
		return;
	__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
	::GameEventCallbacks["hd4l_hyper_feedback"] <- true;
}

foreach (file in HyperFeedback.Files)
	try { IncludeScript(file, getroottable()); } catch (e) { HyperFeedback.Log("could not include " + file + ": " + e); }

HyperFeedback.Precache();
HyperFeedback.Hook();

if (!("HD4L_Parts" in getroottable()))
	::HD4L_Parts <- {};
::HD4L_Parts["hyper_feedback"] <- "0.1";
