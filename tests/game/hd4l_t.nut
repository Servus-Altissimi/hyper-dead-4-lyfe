::HD4LT <- {
	Watching = 0
}

function HD4LT::Log(msg) {
	printl("[HD4LT] " + msg);
}

function HD4LT::Host() {
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null)
		if (!IsPlayerABot(p) && p.IsSurvivor())
			return p;
	return null;
}

function HD4LT::Players(filter) {
	local out = [];
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null)
		if (p.IsValid() && filter(p))
			out.append(p);
	return out;
}

function HD4LT::Bots() {
	return Players(@(p) p.IsSurvivor() && IsPlayerABot(p) && !p.IsDead());
}

function HD4LT::Infected() {
	return Players(@(p) NetProps.GetPropInt(p, "m_iTeamNum") == 3 && !p.IsDead() && !p.IsGhost());
}

function HD4LT::Look(dist = 300.0) {
	local h = Host();
	if (h == null)
		return null;
	local t = { start = h.EyePosition(), end = h.EyePosition() + h.EyeAngles().Forward() * dist, ignore = h };
	TraceLine(t);
	return t.pos;
}

function HD4LT::KillBots() {
	local n = 0;
	foreach (b in Bots()) {
		b.TakeDamage(100000, 0, null);
		n++;
	}
	Log("killed " + n + " survivor bots");
}

function HD4LT::Hurt(amount) {
	local h = Host();
	if (h == null)
		return;
	h.SetHealth(amount > h.GetHealth() ? 1 : h.GetHealth() - amount);
	Log("host health now " + h.GetHealth());
}

function HD4LT::Heal() {
	foreach (p in Players(@(p) p.IsSurvivor() && !p.IsDead())) {
		p.SetHealth(p.GetMaxHealth());
		p.SetHealthBuffer(0);
	}
	Log("survivors healed");
}

function HD4LT::Hyper(seconds = 30.0) {
	local h = Host();
	if (h == null || !("Momentum" in getroottable()))
		return;
	::Momentum.StateOf(h).hyperUntil = Time() + seconds;
	Log("host in HYPER for " + seconds + " s");
}

function HD4LT::Stamina() {
	local h = Host();
	if (h == null || !("Momentum" in getroottable()))
		return;
	try { ::Momentum.Refill(h); } catch (e) { Log("refill failed: " + e); }
	Log("stamina refilled");
}

function HD4LT::Strand(dist = 1500.0) {
	local h = Host();
	if (h == null)
		return;
	local n = 0;
	foreach (b in Bots()) {
		local areas = {};
		NavMesh.GetNavAreasInRadius(h.GetOrigin(), dist, areas);
		local far = null;
		local best = 0.0;
		foreach (id, a in areas) {
			local d = (a.GetCenter() - h.GetOrigin()).Length();
			if (d > best) {
				best = d;
				far = a.GetCenter();
			}
		}
		if (far != null) {
			b.SetOrigin(far + Vector(0, 0, 8));
			n++;
		}
	}
	Log("stranded " + n + " bots up to " + dist + "u away; they should warp back onto your trail");
}

function HD4LT::Trail() {
	local h = Host();
	if (h == null || !("Bodyguard" in getroottable()))
		return;
	local id = h.GetPlayerUserId();
	local trail = (id in ::Bodyguard.Trails) ? ::Bodyguard.Trails[id] : [];
	Log("trail: " + trail.len() + " safe points");
	local spot = ::Bodyguard.SafeSpot(h);
	Log("warp spot now: " + (spot == null ? "none (bots wait)" : spot.tostring()));
}

function HD4LT::ArmBots(primary = "rifle", secondary = "pistol_magnum") {
	local n = 0;
	foreach (b in Bots()) {
		foreach (item in [ primary, secondary, "first_aid_kit", "molotov", "adrenaline", "ammo" ])
			if (item != "")
				try { b.GiveItem(item); } catch (e) {}
		n++;
	}
	Log("armed " + n + " bots: " + primary + ", " + secondary + ", medkit, molotov, adrenaline, ammo");
}

function HD4LT::ArmShotgun() { ArmBots("autoshotgun"); }
function HD4LT::ArmSniper() { ArmBots("sniper_military"); }
function HD4LT::ArmSmg() { ArmBots("smg_silenced"); }
function HD4LT::ArmM60() { ArmBots("rifle_m60"); }
function HD4LT::ArmAk() { ArmBots("rifle_ak47"); }

function HD4LT::WatchSlow(seconds = 15.0) {
	Watching++;
	WatchTick(Watching, Time() + seconds, -1.0);
	Log("printing m_flVelocityModifier on change for " + seconds + " s: get hit by commons");
}

function HD4LT::WatchTick(gen, until, last) {
	if (gen != Watching || Time() > until)
		return;
	local h = Host();
	if (h != null) {
		local v = NetProps.GetPropFloat(h, "m_flVelocityModifier");
		if (fabs(v - last) > 0.01)
			Log(format("velocity modifier %.2f  lagged %.2f", v, NetProps.GetPropFloat(h, "m_flLaggedMovementValue")));
		last = v;
	}
	DoEntFire("!self", "RunScriptCode", "::HD4LT.WatchTick(" + gen + ", " + until + ", " + last + ")", 0.05, null, Entities.First());
}

function HD4LT::ClearInfected() {
	local n = 0;
	foreach (cls in [ "infected", "witch" ]) {
		local e = null;
		while ((e = Entities.FindByClassname(e, cls)) != null) {
			e.Kill();
			n++;
		}
	}
	foreach (p in Infected()) {
		p.TakeDamage(100000, 0, null);
		n++;
	}
	Log("cleared " + n + " infected");
}

function HD4LT::Witch() {
	local pos = Look(400.0);
	if (pos == null)
		return;
	ZSpawn({ type = 7, pos = pos, ang = QAngle(0, RandomInt(0, 359), 0) });
	Log("witch at " + pos);
}

function HD4LT::Horde(count = 30, near = 350.0, far = 700.0) {
	local h = Host();
	if (h == null)
		return;
	local centre = h.GetOrigin();
	local n = 0;
	for (local i = 0; i < count; i++) {
		local yaw = RandomFloat(0.0, 6.2832);
		local dist = RandomFloat(near, far);
		local want = centre + Vector(cos(yaw) * dist, sin(yaw) * dist, 0);
		local down = { start = want + Vector(0, 0, 200), end = want - Vector(0, 0, 400), mask = 81931 };
		TraceLine(down);
		if (!down.hit)
			continue;
		local z = SpawnEntityFromTable("infected", { origin = down.pos + Vector(0, 0, 4), angles = QAngle(0, RandomInt(0, 359), 0) });
		if (z != null)
			n++;
	}
	Log("spawned " + n + " commons " + near + ".." + far + "u around you (no nav mesh: they stand still)");
}

function HD4LT::AmpTank() {
	if (!("Escalation" in getroottable()) || !("Amp" in ::Escalation))
		return Log("escalation not loaded (coop hd4l only)");
	local n = 0;
	foreach (p in Infected())
		if (p.GetZombieType() == 8 && !::Escalation.IsAmped(p)) {
			::Escalation.Amp(p.GetEntityIndex());
			n++;
		}
	Log("amped " + n + " tanks");
}

function HD4LT::Tanks() {
	foreach (p in Infected())
		if (p.GetZombieType() == 8) {
			local amped = ("Escalation" in getroottable()) && ::Escalation.IsAmped(p);
			Log(format("tank %d: %d / %d hp, lagged %.2f, amped %s", p.GetEntityIndex(), p.GetHealth(), p.GetMaxHealth(),
				NetProps.GetPropFloat(p, "m_flLaggedMovementValue"), amped ? "yes" : "no"));
		}
}

function HD4LT::Stunned() {
	if (!("BileFlash" in getroottable()))
		return Log("bile flash not loaded");
	local n = 0;
	foreach (index, s in ::BileFlash.Stunned) {
		if (!s.ent.IsValid())
			continue;
		local extra = "";
		if (s.kind == "witch")
			try { extra = format(" rage %.2f", NetProps.GetPropFloat(s.ent, "m_rage")); } catch (e) {}
		else if (s.kind == "player")
			extra = format(" lagged %.2f disabled %d", NetProps.GetPropFloat(s.ent, "m_flLaggedMovementValue"), NetProps.GetPropInt(s.ent, "m_afButtonDisabled"));
		Log(format("stunned %s %d for %.1f s%s", s.kind, index, s.until - Time(), extra));
		n++;
	}
	Log(n + " stunned");
}

function HD4LT::Esc() {
	if (!("Escalation" in getroottable()))
		return Log("escalation not loaded (coop hd4l only)");
	local e = ::Escalation;
	local p = e.Progress();
	Log(format("progress %.2f, tank group %d, finale %s, finale tanks %d, hyper %s, last stand %s, amped %d",
		p, e.TankGroup(p), e.InFinale() ? "yes" : "no", e.FinaleTanks, e.Hyper ? "yes" : "no", e.LastStand ? "yes" : "no", e.Amps.len()));
	if (e.LastApplied != null)
		foreach (key in [ "CommonLimit", "MobMinSize", "MobMaxSize", "MobSpawnMinTime", "MobSpawnMaxTime", "MaxSpecials", "DominatorLimit",
		                  "SmokerLimit", "HunterLimit", "JockeyLimit", "ChargerLimit", "SpecialRespawnInterval" ])
			if (key in e.LastApplied)
				Log("  " + key + " " + e.LastApplied[key]);
}

function HD4LT::TankNow() {
	if (!("Escalation" in getroottable()))
		return Log("escalation not loaded");
	::Escalation.TankDue = Time();
	::Escalation.TankSeen = false;
	Log("forced chapter tank due now (next 10 s tick)");
}

function HD4LT::Parts() {
	if (!("HD4L_Parts" in getroottable()))
		return Log("no parts registered");
	local names = [];
	foreach (name, v in ::HD4L_Parts)
		names.append(name);
	names.sort();
	local line = "";
	foreach (n in names)
		line += " " + n;
	Log(names.len() + " parts:" + line);
}

HD4LT.Log("helpers loaded: Horde ArmBots KillBots Hurt Heal Hyper Stamina Strand Trail WatchSlow ClearInfected Witch AmpTank Tanks Stunned Esc TankNow Parts");

::HD4LT.HideBits <- [ 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768 ];
::HD4LT.HideStep <- -1;
::HD4LT.HideUntil <- 0.0;
::HD4LT.HideShown <- -1;

function HD4LT::HideProbe() {
	HideStep = 0;
	HideShown = -1;
	HideUntil = Time() + 4.0;
	Log("hidehud probe: 16 bits, 4 s each");
	HideTick();
}

function HD4LT::HideTick() {
	local p = Host();
	if (p == null || HideStep < 0)
		return;
	if (Time() >= HideUntil) {
		HideStep++;
		HideUntil = Time() + 4.0;
	}
	if (HideStep >= HideBits.len()) {
		NetProps.SetPropInt(p, "m_Local.m_iHideHUD", 0);
		HideStep = -1;
		Log("hidehud probe done");
		ClientPrint(p, 4, "hidehud probe done");
		return;
	}
	local bit = HideBits[HideStep];
	NetProps.SetPropInt(p, "m_Local.m_iHideHUD", bit);
	if (HideShown != HideStep) {
		HideShown = HideStep;
		Log("hidehud bit " + bit);
	}
	ClientPrint(p, 4, "hidehud bit " + bit);
	DoEntFire("!self", "RunScriptCode", "::HD4LT.HideTick()", 0.1, null, Entities.First());
}

function HD4LT::Fort() {
	if (!("Fort" in getroottable())) {
		Log("fort: part not loaded");
		return;
	}
	local f = ::Fort;
	local left = f.PhaseUntil - Time();
	Log("fort: mode " + Director.GetGameMode() + ", phase " + f.Phase + ", wave " + f.Wave
		+ (f.Phase == "prep" ? "" : format(", %.0f s left", left < 0 ? 0 : left))
		+ ", scrap " + f.Scrap + ", pieces " + f.Pieces.len() + "/" + f.MaxPieces + ", supplies " + f.Supplies.len()
		+ ", loot " + f.Loot.len() + ", tanks due " + f.Tanks.len());
	foreach (index, pc in f.Pieces)
		Log(format("  %s #%d  %.0f/%.0f hp  radius %.0f%s", pc.bp.name, index, pc.health, pc.max, pc.radius, pc.wrecked ? "  wrecked" : ""));
	foreach (id, st in f.Players)
		Log("  " + (st.p != null && st.p.IsValid() ? st.p.GetPlayerName() : "?") + ": blueprint " + (st.buildMode ? "building " : "") + f.Pick(st).name
			+ " (" + f.Pick(st).cost + ")");
}

function HD4LT::FortScrap(amount = 500) {
	if (!("Fort" in getroottable()))
		return;
	::Fort.AddScrap(amount);
	Log("fort: +" + amount + " scrap, team has " + ::Fort.Scrap);
}

function HD4LT::FortProps() {
	local h = Host();
	if (h == null)
		return;
	local fwd = h.EyeAngles().Forward();
	fwd.z = 0;
	fwd.Norm();
	local side = Vector(-fwd.y, fwd.x, 0);
	local row = h.GetOrigin() + fwd * 220.0;
	local models = [ "models/props_vehicles/cara_95sedan.mdl", "models/props_junk/dumpster.mdl",
	                 "models/props_junk/trashbin01a.mdl", "models/props_interiors/trashcan01.mdl" ];
	foreach (i, model in models) {
		PrecacheModel(model);
		local pos = row + side * ((i - 1.5) * 150.0) + Vector(0, 0, 8);
		local p = SpawnEntityFromTable("prop_physics_override", { model = model, origin = pos, angles = QAngle(0, h.EyeAngles().y + 90, 0) });
		local scrap = (p != null && ("ScrapOf" in ::Fort)) ? ::Fort.ScrapOf(p) : -1;
		Log("fort: " + model + (p == null ? " did not spawn" : " worth " + scrap + " scrap"));
	}
}

function HD4LT::FortItems() {
	local h = Host();
	if (h == null)
		return;
	local fwd = h.EyeAngles().Forward();
	fwd.z = 0;
	fwd.Norm();
	foreach (i, cls in [ "weapon_rifle_spawn", "weapon_first_aid_kit_spawn", "weapon_pain_pills_spawn" ]) {
		local e = SpawnEntityFromTable(cls, { origin = h.GetOrigin() + fwd * (150.0 + 60.0 * i) + Vector(0, 0, 8), count = 1 });
		Log("fort: " + cls + (e == null ? " did not spawn" : " placed"));
	}
}

function HD4LT::FortNext() {
	if (!("Fort" in getroottable()))
		return;
	local f = ::Fort;
	if (f.Phase == "wave")
		f.EndWave();
	else if (f.Phase == "prep" || f.Phase == "break")
		f.StartWave(f.Wave + 1);
	Log("fort: now " + f.Phase + ", wave " + f.Wave);
}

function HD4LT::FortSkip() {
	if (!("Fort" in getroottable()) || ::Fort.Phase == "prep")
		return;
	::Fort.PhaseUntil = Time() + 3.0;
	Log("fort: " + ::Fort.Phase + " ends in 3 s");
}

function HD4LT::FortWave(n) {
	if (!("Fort" in getroottable()))
		return;
	::Fort.StartWave(n);
	Log("fort: wave " + n + ", " + ::Fort.WaveLength(n) + " s, " + ::Fort.TankCount(n) + " tank(s)");
}

function HD4LT::FortSiege(count = 40) {
	if (!("Fort" in getroottable()) || ::Fort.Pieces.len() == 0) {
		Log("fort: nothing built to siege");
		return;
	}
	if (::Fort.Phase != "wave")
		::Fort.StartWave(::Fort.Wave + 1);
	local pieces = [];
	foreach (index, pc in ::Fort.Pieces)
		pieces.append(pc);
	local n = 0;
	for (local i = 0; i < count; i++) {
		local pc = pieces[i % pieces.len()];
		local yaw = RandomFloat(0.0, 6.2832);
		local dist = pc.radius + RandomFloat(8.0, 20.0);
		local want = pc.pos + Vector(cos(yaw) * dist, sin(yaw) * dist, 0);
		local down = { start = want + Vector(0, 0, 100), end = want - Vector(0, 0, 200), mask = 81931 };
		TraceLine(down);
		if (!down.hit)
			continue;
		if (SpawnEntityFromTable("infected", { origin = down.pos + Vector(0, 0, 4), angles = QAngle(0, RandomInt(0, 359), 0) }) != null)
			n++;
	}
	Log("fort: " + n + " commons against " + pieces.len() + " pieces");
}

function HD4LT::FortTank() {
	if (!("Fort" in getroottable()))
		return;
	if (::Fort.Phase != "wave")
		::Fort.StartWave(::Fort.Wave + 1);
	::Fort.SpawnTank();
}
