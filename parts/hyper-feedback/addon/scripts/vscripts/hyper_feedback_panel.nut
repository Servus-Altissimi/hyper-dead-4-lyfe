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
