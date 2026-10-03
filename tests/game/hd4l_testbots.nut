const HD4L_BOT_CMD_MOVE = 1;
const HD4L_BOT_CMD_RESET = 3;

::HD4LBots <- { bots = [], until = 0.0, radius = 260.0, step = 1.2, seconds = 25.0, generation = 0 };

function HD4LBots::Say(line) {
	printl("[HD4L test] " + line);
}

function HD4LBots::Human() {
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null)
		if (p.IsSurvivor() && !IsPlayerABot(p) && !p.IsDead())
			return p;
	return null;
}

function HD4LBots::Particles(effect) {
	local n = 0;
	local e = null;
	while ((e = Entities.FindByClassname(e, "info_particle_system")) != null) {
		local name = "";
		try { name = NetProps.GetPropString(e, "m_iszEffectName"); } catch (x) {}
		if (name == effect)
			n++;
	}
	return n;
}

function HD4LBots::Start() {
	bots = [];
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null)
		if (p.IsSurvivor() && IsPlayerABot(p) && !p.IsDead())
			bots.append(p);
	Say("bots: " + bots.len());
	foreach (i, b in bots) {
		if (i < 2) {
			try { b.UseAdrenaline(seconds + 5.0); } catch (e) { NetProps.SetPropInt(b, "m_bAdrenalineActive", 1); }
		} else if ("Momentum" in getroottable())
			::Momentum.StateOf(b).hyperUntil = Time() + seconds + 5.0;
	}
	until = Time() + seconds;
	generation++;
	Run(generation, 0);
	DoEntFire("!self", "RunScriptCode", "::HD4LBots.Verify()", 1.5, null, Entities.First());
}

function HD4LBots::Run(gen, lap) {
	if (gen != generation)
		return;
	local human = Human();
	if (human == null || Time() >= until) {
		foreach (b in bots)
			if (b.IsValid() && !b.IsDead())
				try { CommandABot({ cmd = HD4L_BOT_CMD_RESET, bot = b }); } catch (e) {}
		Say("bots released");
		return;
	}
	local centre = human.GetOrigin();
	foreach (i, b in bots) {
		if (!b.IsValid() || b.IsDead())
			continue;
		local a = (lap * 1.6 + i * 6.283 / (bots.len() > 0 ? bots.len() : 1));
		local to = centre + Vector(cos(a) * radius, sin(a) * radius, 0);
		try { CommandABot({ cmd = HD4L_BOT_CMD_MOVE, pos = to, bot = b }); } catch (e) { Say("CommandABot failed: " + e); }
	}
	DoEntFire("!self", "RunScriptCode", "::HD4LBots.Run(" + gen + ", " + (lap + 1) + ")", step, null, Entities.First());
}

function HD4LBots::Verify() {
	local root = getroottable();
	if (!("Momentum" in root) || !("Aura" in ::Momentum)) {
		Say("FAIL this build has no Momentum.Aura: rebuild with the game closed");
		return;
	}
	foreach (i, b in bots) {
		if (!b.IsValid() || b.IsDead())
			continue;
		local s = ::Momentum.StateOf(b);
		local want = i < 2 ? "boost" : "hyper";
		local live = 0;
		if (s.eyes != null)
			foreach (fx in s.eyes)
				if (fx != null && fx.IsValid())
					live++;
		local ok = s.eyesKind == want && live == 2;
		Say((ok ? "ok   " : "FAIL ") + b.GetPlayerName() + ": want " + want + " eyes, have '" + s.eyesKind + "' with " + live + " particles"
			+ (s.eyesKind != "" ? "" : (::Momentum.Boosted(b, s) ? " (boosted but no eyes: the installed build predates bot eyes, rebuild with the game closed)" : " (not boosted: adrenaline did not take)")));
	}
	Say("particles by name: white " + Particles("hd4l_eyes_white") + ", hyper " + Particles("hd4l_eyes_hyper") + " (0 with eyes present means the name prop is not readable, not a failure)");
}

HD4LBots.Start();
