const TEAM_INFECTED = 3;
const ZOMBIE_TANK = 8;

::ChapterStats <- {
	ChainWindow = 3.0,

	ChainStep = 0.1,
	ChainMax = 4.0,

	ChainMinShow = 3,

	ChainSoundEvery = 5,

	LiveChain = true,

	Value = {
		common = 10,
		special = 150,
		tank = 1500,
		witch = 800
	},

	MethodBonus = {
		kick = 40,
		glory = 80,
		dash = 30,
		heavy = 30
	},

	HeadshotBonus = 5,

	EventValue = {
		parry = 250,
		breakfree = 120
	},

	DamagePenalty = 0.25,

	DeathPenalty = 500,

	ParSeconds = 420.0,
	TimePoints = 5,

	ClockFromSafeArea = true,

	Ranks =
	[
		[0,     "D"],
		[3000,  "C"],
		[6000,  "B"],
		[10000, "A"],
		[15000, "S"],
		[22000, "SS"],
		[30000, "HYPER DEAD"]
	],

	Sounds = {
		Chain = "hyper/chain.mp3"
	},

	Versus = true,
	Survival = true,
	Stock = true,

	CampaignSave = "hd4l_campaign",
	Carried = { time = 0.0, kills = {}, best = {} },

	Players = {},
	StartedAt = -1.0,
	EndedAt = -1.0,
	PausedAt = -1.0,
	PausedTotal = 0.0,
	Running = false,
	ClockSet = false,
	InCheckpoint = {},
	Generation = 0,
	TickInterval = 0.25
}

function ChapterStats::Log(msg) {
	printl("[ChapterStats] " + msg);
}

function ChapterStats::ModeAllowed() {
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

function ChapterStats::Precache() {
	foreach (snd in Sounds)
		PrecacheSound(snd);
}

function ChapterStats::Usable(p) {
	if (p == null)
		return false;
	try {
		if (!p.IsValid() || p.GetClassname() != "player")
			return false;
		return p.IsSurvivor() && !IsPlayerABot(p);
	} catch (e) { return false; }
}

function ChapterStats::StatOf(p) {
	local id = p.GetPlayerUserId();
	if (!(id in Players))
		Players[id] <- { name = p.GetPlayerName(), score = 0.0,
		                 common = 0, special = 0, tank = 0, witch = 0, headshot = 0,
		                 kick = 0, glory = 0, parry = 0, breakfree = 0,
		                 chain = 0, best = 0, lastKill = -100.0,
		                 damage = 0, deaths = 0,
		                 pending = "", pendingUntil = 0.0 };
	local st = Players[id];

	st.name = p.GetPlayerName();
	return st;
}

function ChapterStats::Resolve(params, key) {
	local p = null;
	if (key in params) {
		try { p = GetPlayerFromUserID(params[key]); } catch (e) { p = null; }
		if (Usable(p))
			return p;
		try { p = EntIndexToHScript(params[key]); } catch (e) { p = null; }
		if (Usable(p))
			return p;
	}
	if ("attackerentid" in params) {
		try { p = EntIndexToHScript(params.attackerentid); } catch (e) { p = null; }
		if (Usable(p))
			return p;
	}
	return null;
}

function ChapterStats::Begin() {
	Players = {};
	StartedAt = Time();
	EndedAt = -1.0;
	PausedAt = -1.0;
	PausedTotal = 0.0;
	Running = true;
	ClockSet = false;
	InCheckpoint = {};
	Generation++;
	LoadCampaign();
	Tick(Generation);
}

function ChapterStats::Elapsed() {
	if (StartedAt < 0.0)
		return 0.0;
	local end = EndedAt >= 0.0 ? EndedAt : Time();
	local paused = PausedTotal + (PausedAt >= 0.0 ? end - PausedAt : 0.0);
	local d = end - StartedAt - paused;
	return d < 0.0 ? 0.0 : d;
}

function ChapterStats::Finish(reason) {
	if (!Running)
		return;
	Running = false;
	EndedAt = Time();
	local seconds = Elapsed();
	local mins = (seconds / 60.0).tointeger();
	local secs = (seconds - mins * 60).tointeger();

	Log("chapter over (" + reason + "), " + Clock(seconds));
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null) {
		if (!Usable(p))
			continue;
		local st = StatOf(p);

		st.chain = 0;
		ClearChain(p);
		local total = Total(st, seconds);
		local rank = Rank(total);
		local kills = st.common + st.special + st.tank + st.witch;
		Log(st.name + "  RANK " + RankName(rank) + "  " + total + "  kills " + kills +
		    " (c " + st.common + " / s " + st.special + " / t " + st.tank + " / w " + st.witch + ")" +
		    "  headshots " + st.headshot + "  best chain x" + st.best +
		    "  kicks " + st.kick + "  glory " + st.glory + "  parry " + st.parry +
		    "  breaks " + st.breakfree + "  taken " + st.damage + "  deaths " + st.deaths);
	}
}

function ChapterStats::Total(st, seconds) {
	local total = st.score;
	local spare = ParSeconds - seconds;
	if (spare > 0.0)
		total += spare * TimePoints;
	return total.tointeger();
}

function ChapterStats::Rank(score) {
	local rank = 1;
	foreach (i, step in Ranks)
		if (score >= step[0])
			rank = i + 1;
	return rank;
}

function ChapterStats::RankName(rank) {
	if (rank < 1) rank = 1;
	if (rank > Ranks.len()) rank = Ranks.len();
	return Ranks[rank - 1][1];
}

function ChapterStats::Kill(p, kind, value, head) {
	if (!Running || !Usable(p))
		return;
	local st = StatOf(p);
	local now = Time();

	if (now - st.lastKill > ChainWindow)
		st.chain = 0;
	st.chain++;
	st.lastKill = now;
	if (st.chain > st.best)
		st.best = st.chain;

	local mult = 1.0 + (st.chain - 1) * ChainStep;
	if (mult > ChainMax)
		mult = ChainMax;

	local worth = value.tofloat();
	local method = TakeMethod(st, now);
	if (method != "" && (method in MethodBonus)) {
		worth += MethodBonus[method];
		if (method == "kick")
			st.kick++;
		else if (method == "glory")
			st.glory++;
	}
	if (head) {
		worth += HeadshotBonus;
		st.headshot++;
	}
	st.score += worth * mult;

	if (kind in st)
		st[kind]++;

	ShowChain(p, st);
}

function ChapterStats::Event(p, kind) {
	if (!Running || !Usable(p) || !(kind in EventValue))
		return;
	local st = StatOf(p);
	st.score += EventValue[kind].tofloat();
	if (kind in st)
		st[kind]++;
}

function ChapterStats::Note(p, method) {
	if (!Running || !Usable(p))
		return;
	local st = StatOf(p);
	st.pending = method;
	st.pendingUntil = Time() + 0.3;
}

function ChapterStats::TakeMethod(st, now) {
	if (st.pending == "" || now > st.pendingUntil)
		return "";
	local method = st.pending;
	st.pending = "";
	return method;
}

function ChapterStats::ShowChain(p, st) {
	if (!LiveChain)
		return;
	if (("HyperFeedback" in getroottable()) && ("Chain" in ::HyperFeedback))
		try { ::HyperFeedback.Chain(p, st.chain); } catch (e) {}
	if (st.chain >= ChainMinShow && ChainSoundEvery > 0 && st.chain % ChainSoundEvery == 0)
		try { EmitSoundOn(Sounds.Chain, p); } catch (e) {}
}

function ChapterStats::ClearChain(p) {
	if (!LiveChain)
		return;
	if (("HyperFeedback" in getroottable()) && ("Chain" in ::HyperFeedback))
		try { ::HyperFeedback.Chain(p, 0); } catch (e) {}
}

function ChapterStats::Tick(generation) {
	if (generation != Generation || !ModeAllowed())
		return;
	local now = Time();
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null) {
		if (!Usable(p))
			continue;
		local id = p.GetPlayerUserId();
		if (!(id in Players))
			continue;
		local st = Players[id];
		if (st.chain > 0 && now - st.lastKill > ChainWindow) {
			if (st.chain >= ChainMinShow)
				ClearChain(p);
			st.chain = 0;
		}
	}
	DoEntFire("!self", "RunScriptCode", "::ChapterStats.Tick(" + generation + ")", TickInterval, null, Entities.First());
}

function ChapterStats::OnGameEvent_round_start(params) {
	try {
		if (!ModeAllowed())
			return;
		Begin();
	} catch (e) { Log("round start failed: " + e); }
}

function ChapterStats::OnGameEvent_player_left_safe_area(params) {
	if (!Running || !ClockFromSafeArea || ClockSet || InSurvival())
		return;

	ClockSet = true;
	StartedAt = Time();
	PausedAt = -1.0;
	PausedTotal = 0.0;
}

function ChapterStats::OnGameEvent_survival_round_start(params) {
	if (!Running || ClockSet || !InSurvival())
		return;
	ClockSet = true;
	StartedAt = Time();
	PausedAt = -1.0;
	PausedTotal = 0.0;
}

function ChapterStats::OnGameEvent_infected_death(params) {
	if (!Running || !ModeAllowed())
		return;
	local p = Resolve(params, "attacker");
	if (p == null)
		return;
	local head = ("headshot" in params) && params.headshot;
	Kill(p, "common", Value.common, head);
}

function ChapterStats::OnGameEvent_player_death(params) {
	if (!Running || !ModeAllowed())
		return;
	local victim = null;
	if ("userid" in params)
		try { victim = GetPlayerFromUserID(params.userid); } catch (e) { victim = null; }
	if (victim == null || !victim.IsValid())
		return;

	if (Usable(victim)) {
		local st = StatOf(victim);
		st.deaths++;
		st.score -= DeathPenalty;
		st.chain = 0;
		ClearChain(victim);
		return;
	}

	if (NetProps.GetPropInt(victim, "m_iTeamNum") != TEAM_INFECTED)
		return;

	local cls = 0;
	try { cls = victim.GetZombieType(); } catch (e) { cls = 0; }
	if (cls == ZOMBIE_TANK)
		return;

	local p = Resolve(params, "attacker");
	if (p == null)
		return;
	Kill(p, "special", Value.special, false);
}

function ChapterStats::OnGameEvent_witch_killed(params) {
	if (!Running || !ModeAllowed())
		return;
	local p = Resolve(params, "userid");
	if (p == null)
		return;
	Kill(p, "witch", Value.witch, false);
}

function ChapterStats::OnGameEvent_tank_killed(params) {
	if (!Running || !ModeAllowed())
		return;
	local p = Resolve(params, "userid");
	if (p == null)
		return;
	Kill(p, "tank", Value.tank, false);
}

function ChapterStats::OnGameEvent_player_hurt(params) {
	if (!Running || !ModeAllowed() || !("userid" in params) || !("dmg_health" in params))
		return;
	local victim = null;
	try { victim = GetPlayerFromUserID(params.userid); } catch (e) { return; }
	if (!Usable(victim))
		return;
	local dmg = params.dmg_health;
	if (dmg <= 0)
		return;
	local st = StatOf(victim);
	st.damage += dmg;
	st.score -= dmg * DamagePenalty;
}

function ChapterStats::OnGameEvent_player_entered_checkpoint(params) {
	if (!Running || !("userid" in params))
		return;
	InCheckpoint[params.userid] <- true;
	CheckSaferoom();
}

function ChapterStats::OnGameEvent_player_left_checkpoint(params) {
	if (!("userid" in params) || !(params.userid in InCheckpoint))
		return;
	delete InCheckpoint[params.userid];
	if (Running && PausedAt >= 0.0 && !TeamInCheckpoint()) {
		PausedTotal += Time() - PausedAt;
		PausedAt = -1.0;
	}
}

function ChapterStats::CheckSaferoom() {
	if (!Running || !ClockSet || PausedAt >= 0.0)
		return;
	if (!TeamInCheckpoint())
		return;
	PausedAt = Time();
}

function ChapterStats::TeamInCheckpoint() {
	local any = false;
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null) {
		if (!Usable(p) || p.IsDead() || p.IsDying())
			continue;
		any = true;
		if (!(p.GetPlayerUserId() in InCheckpoint))
			return false;
		local start = false;
		try { start = NetProps.GetPropInt(p, "m_isInMissionStartArea") != 0; } catch (e) { start = false; }
		if (start)
			return false;
	}
	return any;
}

function ChapterStats::OnGameEvent_map_transition(params) {
	Finish("saferoom");
	try { SaveCampaign(); } catch (e) { Log("campaign save failed: " + e); }
}
function ChapterStats::OnGameEvent_finale_win(params) { Finish("finale"); }
function ChapterStats::OnGameEvent_mission_lost(params) { Finish("wipe"); }
function ChapterStats::OnGameEvent_round_end(params) { Finish("round over"); }

function ChapterStats::InVersus() {
	local mode = "";
	try { mode = Director.GetGameMode(); } catch (e) {}
	return mode == "hd4lversus";
}

function ChapterStats::InSurvival() {
	local mode = "";
	try { mode = Director.GetGameMode(); } catch (e) {}
	return mode == "hd4lsurvival" || (mode == "hd4lfort" || mode == "hd4lfreebuild");
}

function ChapterStats::LoadCampaign() {
	Carried = { time = 0.0, kills = {}, best = {} };
	if (InVersus() || InSurvival() || !("RestoreTable" in getroottable()))
		return;
	local first = false;
	try { first = Director.IsFirstMapInScenario(); } catch (e) {}
	if (first) {
		SaveTable(CampaignSave, {});
		return;
	}
	local saved = {};
	RestoreTable(CampaignSave, saved);
	foreach (key, value in saved) {
		if (key == "time")
			Carried.time = value.tofloat();
		else if (key.slice(0, 1) == "k")
			Carried.kills[key.slice(1).tointeger()] <- value;
		else if (key.slice(0, 1) == "b")
			Carried.best[key.slice(1).tointeger()] <- value;
	}

	SaveTable(CampaignSave, saved);
}

function ChapterStats::SaveCampaign() {
	if (InVersus() || InSurvival() || !("SaveTable" in getroottable()))
		return;
	local saved = { time = CampaignSeconds() };
	foreach (id, kills in Carried.kills)
		saved["k" + id] <- kills;
	foreach (id, best in Carried.best)
		saved["b" + id] <- best;
	foreach (id, st in Players) {
		saved["k" + id] <- ChapterKills(st) + (("k" + id) in saved ? saved["k" + id] : 0);
		local best = ("b" + id) in saved ? saved["b" + id] : 0;
		saved["b" + id] <- st.best > best ? st.best : best;
	}
	SaveTable(CampaignSave, saved);
}

function ChapterStats::ChapterKills(st) {
	return st.common + st.special + st.tank + st.witch;
}

function ChapterStats::CampaignSeconds() {
	return Carried.time + (ClockSet ? Elapsed() : 0.0);
}

function ChapterStats::Campaign(p) {
	if (!ModeAllowed() || !Usable(p))
		return null;
	local id = p.GetPlayerUserId();
	local kills = id in Carried.kills ? Carried.kills[id] : 0;
	local best = id in Carried.best ? Carried.best[id] : 0;
	if (id in Players) {
		kills += ChapterKills(Players[id]);
		if (Players[id].best > best)
			best = Players[id].best;
	}
	return { seconds = CampaignSeconds(), kills = kills, best = best };
}

function ChapterStats::Clock(seconds) {
	local s = seconds.tointeger();
	if (s < 0)
		s = 0;
	local m = s / 60;
	local r = s % 60;
	return m + ":" + (r < 10 ? "0" + r : "" + r);
}

ChapterStats.Precache();

function ChapterStats::Hook() {
	if (("GameEventCallbacks" in getroottable()) && ("hd4l_chapter_stats" in ::GameEventCallbacks))
		return;
	__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
	::GameEventCallbacks["hd4l_chapter_stats"] <- true;
}

ChapterStats.Hook();

if (!("HD4L_Parts" in getroottable()))
	::HD4L_Parts <- {};
::HD4L_Parts["chapter_stats"] <- "0.1";
