const HITGROUP_HEAD = 1;
const TEAM_INFECTED = 3;
const ZOMBIE_TANK = 8;

::HyperFeedback <- {
	Versus = true,
	Survival = true,
	Stock = true,

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

function HyperFeedback::PanelCommandEntity() {
	local ent = Entities.FindByName(null, "hyper_feedback_clientcmd");
	if (ent != null && ent.IsValid())
		return ent;
	return SpawnEntityFromTable("point_clientcommand", { targetname = "hyper_feedback_clientcmd" });
}

function HyperFeedback::PanelSend(st, tag, value) {
	local ent = PanelCommandEntity();
	if (ent == null)
		return;
	local now = Time();
	local at = st.sendAt + PanelGap;
	if (at < now)
		at = now;
	st.sendAt = at;
	DoEntFire("!self", "Command", "name2 " + (tag * 1000000 + value), at - now, st.p, ent);
}

function HyperFeedback::PanelSend1(st, force) {
	local v = st.pmark + 6 * (st.mseq + 5 * (st.arc + 9 * (st.aseq + 5 * (st.stam + 12 * st.dot))));
	local now = Time();
	if (!force && v == st.sent1 && now - st.sentAt1 < PanelRefresh)
		return;
	st.sent1 = v;
	st.sentAt1 = now;
	PanelSend(st, 1, v);
}

function HyperFeedback::PanelSend2(st, force) {
	local v = st.tank + 21 * (st.pstruggle + 10 * (st.spike + 5 * (st.cue + 6 * (st.cseq + 5 * st.hook))));
	local now = Time();
	if (!force && v == st.sent2 && now - st.sentAt2 < PanelRefresh)
		return;
	st.sent2 = v;
	st.sentAt2 = now;
	PanelSend(st, 2, v);
}

function HyperFeedback::FeedValue(first) {
	local now = Time();
	local rows = [];
	foreach (k in Feed) {
		if (now - k.at > FeedLife)
			continue;
		rows.append(k);
	}
	local v = 0;
	local mult = 1;
	for (local i = first; i < first + 2; i++) {
		local r = i < rows.len() ? rows[i] : null;
		v += mult * (r == null ? 0 : r.k); mult *= 18;
		v += mult * (r == null ? 0 : r.v); mult *= 18;
		v += mult * (r == null ? 0 : r.h); mult *= 2;
	}
	return v;
}

function HyperFeedback::PanelSend3(st, force) {
	local now = Time();
	local v = FeedValue(0);
	if (!force && v == st.sent3 && now - st.sentAt3 < PanelRefresh)
		return;
	st.sent3 = v;
	st.sentAt3 = now;
	PanelSend(st, 3, v);
}

function HyperFeedback::PanelSend4(st, force) {
	local now = Time();
	local v = FeedValue(2);
	if (!force && v == st.sent4 && now - st.sentAt4 < PanelRefresh)
		return;
	st.sent4 = v;
	st.sentAt4 = now;
	PanelSend(st, 4, v);
}

function HyperFeedback::PanelSend5(st, force) {
	local p = st.p;
	local hp = 0;
	try { hp = p.GetHealth(); } catch (e) {}
	local buffer = 0.0;
	if (p.IsSurvivor())
		try { buffer = p.GetHealthBuffer(); } catch (e) {}
	local total = (hp + buffer + 0.5).tointeger();
	if (total < 0) total = 0;
	if (total > 9999) total = 9999;
	local tone = (p.IsSurvivor() && total < LowHealth) ? 1 : 0;
	local digits = [10, 10, 10, 10];
	local n = total;
	local i = 3;
	if (p.IsSurvivor() && !Lite()) do {
		digits[i] = n % 10;
		n = n / 10;
		i--;
	} while (n > 0 && i >= 0);
	local v = digits[0] + 11 * (digits[1] + 11 * (digits[2] + 11 * (digits[3] + 11 * tone)));
	local now = Time();
	if (!force && v == st.sent5 && now - st.sentAt5 < PanelRefresh)
		return;
	st.sent5 = v;
	st.sentAt5 = now;
	PanelSend(st, 5, v);
}

function HyperFeedback::Digits(n, count) {
	local out = [];
	for (local i = 0; i < count; i++)
		out.append(10);
	if (n < 0)
		n = 0;
	local i = count - 1;
	do {
		out[i] = n % 10;
		n = n / 10;
		i--;
	} while (n > 0 && i >= 0);
	return out;
}

function HyperFeedback::Chain(p, n) {
	if (p == null || !p.IsValid() || IsPlayerABot(p))
		return;
	PlayerState(p).chain = n;
}

function HyperFeedback::PanelSend6(st, force) {
	local n = st.chain;
	local live = n >= ChainShow ? 1 : 0;
	local d = live == 1 ? Digits(n > 99 ? 99 : n, 2) : [10, 10];
	local v = d[0] + 11 * (d[1] + 11 * live);
	local now = Time();
	if (!force && v == st.sent6 && now - st.sentAt6 < PanelRefresh)
		return;
	st.sent6 = v;
	st.sentAt6 = now;
	PanelSend(st, 6, v);
}

function HyperFeedback::LeftDigits(n, count) {
	local out = [];
	local top = 1;
	for (local i = 0; i < count; i++)
		top *= 10;
	if (n < 0)
		n = 0;
	if (n >= top)
		n = top - 1;
	local text = n.tostring();
	for (local i = 0; i < count; i++)
		out.append(i < text.len() ? text[i] - '0' : 10);
	return out;
}

function HyperFeedback::PanelStats(st, p, force) {
	local c = null;
	if (p.IsSurvivor() && !Lite() && ("ChapterStats" in getroottable()) && ("Campaign" in ::ChapterStats))
		try { c = ::ChapterStats.Campaign(p); } catch (e) { c = null; }
	local now = Time();

	local v = 10 + 11 * (10 + 11 * (6 + 7 * 10));
	if (c != null) {
		local secs = c.seconds.tointeger();
		local m = secs / 60;
		if (m > 99)
			m = 99;
		local r = secs % 60;
		v = m / 10 + 11 * (m % 10 + 11 * (r / 10 + 7 * (r % 10 + 11)));
	}
	if (force || v != st.sent11 || now - st.sentAt11 >= PanelRefresh) {
		st.sent11 = v;
		st.sentAt11 = now;
		PanelSend(st, 11, v);
	}

	local d = c == null ? [10, 10, 10, 10, 10] : LeftDigits(c.kills, 5);
	v = d[0] + 11 * (d[1] + 11 * (d[2] + 11 * (d[3] + 11 * d[4])));
	if (force || (v != st.sent12 && now - st.sentAt12 >= StatsGap) || now - st.sentAt12 >= PanelRefresh) {
		st.sent12 = v;
		st.sentAt12 = now;
		PanelSend(st, 12, v);
	}

	d = c == null ? [10, 10, 10] : LeftDigits(c.best, 3);
	v = d[0] + 11 * (d[1] + 11 * d[2]);
	if (force || v != st.sent13 || now - st.sentAt13 >= PanelRefresh) {
		st.sent13 = v;
		st.sentAt13 = now;
		PanelSend(st, 13, v);
	}
}

function HyperFeedback::FeedCode(p) {
	if (p == null || !p.IsValid())
		return 0;
	if (p.IsSurvivor()) {
		local model = "";
		try { model = p.GetModelName().tolower(); } catch (e) {}
		foreach (i, name in FeedSurvivor)
			if (model.find("survivor_" + name) != null)
				return i + 1;
		local c = 0;
		try { c = NetProps.GetPropInt(p, "m_survivorCharacter"); } catch (e) {}
		return (c >= 0 && c < 8) ? c + 1 : 1;
	}
	local zt = 0;
	try { zt = p.GetZombieType(); } catch (e) {}
	return (zt in FeedClass) ? FeedClass[zt] : 16;
}

function HyperFeedback::FeedKill(k, v, head) {
	if (k == 0 || v == 0 || Lite())
		return;
	Feed.insert(0, { k = k, v = v, h = head ? 1 : 0, at = Time() });
	while (Feed.len() > FeedRows)
		Feed.pop();
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null) {
		if (IsPlayerABot(p) || p.IsDead() || p.IsDying())
			continue;
		if (!p.IsSurvivor() && NetProps.GetPropInt(p, "m_iTeamNum") != TEAM_INFECTED)
			continue;
		local st = PlayerState(p);
		PanelSend3(st, true);
		PanelSend4(st, true);
	}
}

function HyperFeedback::PanelFlash(p, name) {
	if (Lite())
		return;
	local st = PlayerState(p);
	local now = Time();
	if (name in PanelMark) {
		local active = now < st.markUntil && st.mark != "";
		if (!active || Rank[name] >= Rank[st.mark]) {
			st.mark = name;
			st.markUntil = now + Hold[name];
			st.pmark = PanelMark[name];
			st.mseq = (st.mseq + 1) % 5;
			PanelSend1(st, true);
		}
	} else if (name in PanelArc) {
		st.arc = PanelArc[name];
		st.aseq = (st.aseq + 1) % 5;
		PanelSend1(st, true);
	} else if (name == "spike") {
		st.spike = st.spike % 4 + 1;
		PanelSend2(st, true);
	} else if (name in PanelCue) {
		st.cue = PanelCue[name];
		st.cseq = (st.cseq + 1) % 5;
		PanelSend2(st, true);
	}
	if (name in Sounds)
		Play(name, p);
}

function HyperFeedback::Lite() {
	local mode = "";
	try { mode = Director.GetGameMode(); } catch (e) {}
	return (mode == "hd4lfort" || mode == "hd4lfreebuild");
}

function HyperFeedback::HideStock(p) {
	local want = (p.IsSurvivor() && !Lite()) ? StockHide : 0;
	try {
		local flags = NetProps.GetPropInt(p, "m_Local.m_iHideHUD");
		local next = (flags & ~StockHide) | want;
		if (next != flags)
			NetProps.SetPropInt(p, "m_Local.m_iHideHUD", next);
	} catch (e) {}
}

function HyperFeedback::Steps(n, steps) {
	if (n <= 0)
		return 0;
	local c = (n * steps / 100.0 + 0.5).tointeger();
	if (c < 1)
		c = 1;
	return c > steps ? steps : c;
}

function HyperFeedback::BarParts(p, steps) {
	local hp = 0;
	local buffer = 0.0;
	try { hp = p.GetHealth(); } catch (e) {}
	try { buffer = p.GetHealthBuffer(); } catch (e) {}
	local dead = false;
	try { dead = p.IsDead() || p.IsDying(); } catch (e) {}
	if (dead)
		return { hp = 0, total = 0, tone = 2, incap = 0 };
	local total = (hp + buffer + 0.5).tointeger();
	local incap = false;
	try { incap = p.IsIncapacitated(); } catch (e) {}
	local tone = (incap || total < ToneBlood) ? 2 : (total < ToneAmber ? 1 : 0);
	return { hp = Steps(hp, steps), total = Steps(total, steps), tone = tone, incap = incap ? 1 : 0 };
}

function HyperFeedback::PanelSendTag(st, tag, v, force, gap = 0.0) {
	if (!("tags" in st))
		st.tags <- {};
	local now = Time();
	if (tag in st.tags) {
		local last = st.tags[tag];
		if (!force && last.v == v && now - last.at < TeamRefresh)
			return;
		if (!force && last.v != v && now - last.at < gap)
			return;
	}
	st.tags[tag] <- { v = v, at = now };
	PanelSend(st, tag, v);
}

function HyperFeedback::MeValue(p) {
	if (!p.IsSurvivor())
		return 0;
	local b = BarParts(p, MeSteps);
	local crouch = (NetProps.GetPropInt(p, "m_fFlags") & 2) != 0 ? 1 : 0;
	local r = MeSteps + 1;
	return FeedCode(p) + 9 * (b.hp + r * (b.total + r * (b.tone + 3 * (crouch + 2 * 1))));
}

function HyperFeedback::Inventory(p) {
	local inv = {};
	try { GetInvTable(p, inv); } catch (e) {}
	return inv;
}

function HyperFeedback::Holds(inv, slot) {
	return (slot in inv && inv[slot] != null && inv[slot].IsValid()) ? 1 : 0;
}

function HyperFeedback::MateValue(m) {
	if (m == null)
		return 0;
	local b = BarParts(m, MateSteps);
	local alive = 1;
	try { alive = (m.IsDead() || m.IsDying()) ? 0 : 1; } catch (e) {}
	local inv = Inventory(m);
	local r = MateSteps + 1;
	return FeedCode(m) + 9 * (b.hp + r * (b.total + r * (b.tone + 3 * (alive + 2 * (b.incap + 2 * (Holds(inv, "slot2")
		+ 2 * (Holds(inv, "slot3") + 2 * Holds(inv, "slot4"))))))));
}

function HyperFeedback::Mates(p) {
	local out = [];
	if (!p.IsSurvivor())
		return out;
	local m = null;
	while ((m = Entities.FindByClassname(m, "player")) != null)
		if (m != p && m.IsValid() && m.IsSurvivor())
			out.append(m);
	out.sort(@(a, b) ::HyperFeedback.FeedCode(a) <=> ::HyperFeedback.FeedCode(b));
	return out;
}

function HyperFeedback::Blank(n, count) {
	local out = [];
	if (n < 0) {
		for (local i = 0; i < count; i++)
			out.append(0);
		return out;
	}
	local max = 1;
	for (local i = 0; i < count; i++)
		max *= 10;
	foreach (d in Digits(n >= max ? max - 1 : n, count))
		out.append(d == 10 ? 0 : d + 1);
	return out;
}

function HyperFeedback::PanelFort(st, p, force) {
	if (!("Fort" in getroottable()) || !("Hud" in ::Fort))
		return;
	local h = null;
	try { h = ::Fort.Hud(p); } catch (e) { h = null; }
	if (h == null && (!("tags" in st) || !(ScrapTag in st.tags)))
		return;
	local s = h == null ? [ 0, 0, 0, 0 ] : Blank(h.scrap, 4);
	local scrap = s[0] + 11 * (s[1] + 11 * (s[2] + 11 * (s[3] + 11 * (h == null ? 0 : 1))));
	local building = h != null && h.cost >= 0;
	local c = building ? Blank(h.cost, 4) : [ 0, 0, 0, 0 ];
	if (building && !h.ok)
		foreach (i, d in c)
			if (d > 0)
				c[i] = d + 10;
	local cost = c[0] + 21 * (c[1] + 21 * (c[2] + 21 * (c[3] + 21 * (building ? 1 : 0))));
	PanelSendTag(st, ScrapTag, scrap, force, StatsGap);
	PanelSendTag(st, CostTag, cost, force, AmmoGap);
	local w = null;
	if ("WaveHud" in ::Fort)
		try { w = ::Fort.WaveHud(p); } catch (e) { w = null; }
	local n = w == null ? [ 0, 0 ] : Blank(w.wave, 2);
	local t = (w == null || w.seconds < 0) ? [ 0, 0, 0 ] : Blank(w.seconds, 3);
	local wave = n[0] + 11 * (n[1] + 11 * (t[0] + 11 * (t[1] + 11 * (t[2] + 11 * (w == null ? 0 : w.state)))));
	PanelSendTag(st, WaveTag, wave, force, StatsGap);
}

function HyperFeedback::PanelSendTeam(st, force) {
	local p = st.p;
	PanelSendTag(st, MeTag, MeValue(p), force);
	local mates = Mates(p);
	foreach (r, tag in MateTags)
		PanelSendTag(st, tag, MateValue(r < mates.len() ? mates[r] : null), force);
}

function HyperFeedback::PanelTick() {
	local sent = false;
	local lite = Lite();
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null) {
		if (IsPlayerABot(p) || p.IsDead() || p.IsDying())
			continue;
		HideStock(p);
		local infected = NetProps.GetPropInt(p, "m_iTeamNum") == TEAM_INFECTED;
		if (infected && p.IsGhost())
			continue;
		if (!p.IsSurvivor() && !infected)
			continue;
		local st = PlayerState(p);

		local force = Resync;
		st.stam = lite ? 10 : StaminaLevel(p) * 2 + HyperOn(p);
		local t = (p.IsSurvivor() && !lite) ? TankLevel() : "n";
		st.tank = t == "n" ? 0 : t.tointeger() + 1;
		st.dot = lite ? 0 : 1;
		if (lite)
			st.chain = 0;
		PanelSend1(st, force);
		PanelSend2(st, force);
		PanelSend3(st, force);
		PanelSend4(st, force);
		PanelSend5(st, force);
		PanelSend6(st, force);
		if (!lite)
			PanelSendTeam(st, force);
		PanelStats(st, p, force);
		PanelFort(st, p, force);
		sent = true;
	}
	if (sent)
		Resync = false;
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

HyperFeedback.Precache();
HyperFeedback.Hook();

if (!("HD4L_Parts" in getroottable()))
	::HD4L_Parts <- {};
::HD4L_Parts["hyper_feedback"] <- "0.1";
