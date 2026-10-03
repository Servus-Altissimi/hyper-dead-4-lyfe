const LASTSTAND_TEAM_INFECTED = 3;
const LASTSTAND_ZOMBIE_WITCH = 7;

::LastStand <- {
	Versus = true,
	Survival = false,
	Stock = false,
	MapPrefix = "c14m",

	WitchEvery = 10.0,
	WitchCap = 8,
	WitchMin = 500.0,
	WitchMax = 1400.0,

	PanicEvery = 20.0,

	RainEvery = 0.15,
	RainPerDrop = 2,
	RainSpread = 450.0,
	RainHeight = 700.0,
	RainSpeed = 1800.0,
	RainMass = 30.0,
	RainSeconds = 6.0,
	RainModel = "models/weapons/melee/w_pitchfork.mdl",

	GiveWeapon = "sniper_awp",
	GiveClass = "weapon_sniper_awp",
	GiveDelay = 0.5,

	StrikeEvery = 1.2,
	StrikeSpread = 400.0,
	StrikeWarn = 0.7,
	StrikeRadius = 130.0,
	StrikeDamage = 12.0,
	StrikeFlash = 70,
	StrikeWarnEffect = "electrical_arc_01",
	StrikeEffects = [ "gas_explosion_initialburst_blast", "tank_rock_throw_impact", "tank_ground_pound", "electrical_arc_01" ],
	StrikeSounds = [ "physics/concrete/boulder_impact_hard1.wav", "physics/concrete/concrete_break2.wav" ],

	TickInterval = 0.05,

	NextWitch = 0.0,
	NextPanic = 0.0,
	NextRain = 0.0,
	NextStrike = 0.0,
	Generation = 0
}

function LastStand::Log(msg) {
	printl("[LastStand] " + msg);
}

function LastStand::ModeAllowed() {
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

function LastStand::MapName() {
	local name = "";
	try { name = GetMapName(); } catch (e) {}
	if (name == "")
		try { name = Director.GetMapName(); } catch (e) {}
	return name.tolower();
}

function LastStand::Cursed() {
	return ModeAllowed() && MapName().find(MapPrefix) == 0;
}

function LastStand::Precache() {
	try { PrecacheModel(RainModel); } catch (e) {}
	local effects = [ StrikeWarnEffect ];
	effects.extend(StrikeEffects);
	foreach (effect in effects)
		try { PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = effect, origin = Vector(0, 0, 0), start_active = 1 }); } catch (e) {}
	foreach (sound in StrikeSounds)
		try { PrecacheSound(sound); } catch (e) {}
}

function LastStand::Particle(effect, pos, seconds) {
	local gfx = SpawnEntityFromTable("info_particle_system", { effect_name = effect, origin = pos, start_active = 1 });
	if (gfx != null && gfx.IsValid())
		DoEntFire("!self", "Kill", "", seconds, null, gfx);
	return gfx;
}

function LastStand::Ground(p) {
	local from = p.EyePosition() + Vector(RandomFloat(-StrikeSpread, StrikeSpread), RandomFloat(-StrikeSpread, StrikeSpread), 0);
	local side = { start = p.EyePosition(), end = from, ignore = p };
	TraceLine(side);
	if (side.hit && ("pos" in side))
		from = side.pos;
	local down = { start = from, end = from - Vector(0, 0, 600), ignore = p };
	TraceLine(down);
	if (!down.hit || !("pos" in down))
		return null;
	return down.pos + Vector(0, 0, 4);
}

function LastStand::Warn(pos) {
	Particle(StrikeWarnEffect, pos, StrikeWarn + 0.5);
	DoEntFire("!self", "RunScriptCode", "::LastStand.Strike(Vector(" + pos.x + "," + pos.y + "," + pos.z + "))", StrikeWarn, null, Entities.First());
}

function LastStand::Strike(pos) {
	if (!Cursed())
		return;
	local first = null;
	foreach (effect in StrikeEffects) {
		local gfx = Particle(effect, pos + Vector(0, 0, 8), 3.0);
		if (first == null)
			first = gfx;
	}
	if (first != null && first.IsValid())
		foreach (sound in StrikeSounds)
			EmitSoundOn(sound, first);
	ScreenShake(pos, 14.0, 40.0, 0.8, StrikeRadius * 5.0, 0, false);

	local push = SpawnEntityFromTable("env_physexplosion", { magnitude = "900", radius = (StrikeRadius * 2.5).tostring(), spawnflags = "1", origin = pos });
	if (push != null) {
		DoEntFire("!self", "Explode", "", 0, null, push);
		DoEntFire("!self", "Kill", "", 0.1, null, push);
	}

	if (StrikeFlash > 0) {
		local near = false;
		foreach (s in Survivors())
			if ((s.GetOrigin() - pos).Length() <= StrikeRadius * 6.0)
				near = true;
		if (near) {
			local fade = SpawnEntityFromTable("env_fade", { spawnflags = "1", duration = "0.15", holdtime = "0.03", renderamt = StrikeFlash.tostring(), rendercolor = "255 255 255", origin = pos });
			if (fade != null) {
				DoEntFire("!self", "Fade", "", 0, null, fade);
				DoEntFire("!self", "Kill", "", 1.0, null, fade);
			}
		}
	}

	foreach (s in Survivors())
		if ((s.GetOrigin() - pos).Length() <= StrikeRadius) {
			try { s.Stagger(pos); } catch (e) {}
			s.TakeDamage(StrikeDamage, 256, Entities.First());
		}
	local z = null;
	local zapped = [];
	while ((z = Entities.FindByClassnameWithin(z, "infected", pos, StrikeRadius)) != null)
		zapped.append(z);
	foreach (z in zapped)
		if (z.IsValid())
			z.TakeDamage(z.GetHealth() + 1, 64, Entities.First());
}

function LastStand::Survivors() {
	local out = [];
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null)
		if (p.IsValid() && p.IsSurvivor() && !p.IsDead())
			out.append(p);
	return out;
}

function LastStand::Witches() {
	local n = 0;
	local w = null;
	while ((w = Entities.FindByClassname(w, "witch")) != null)
		n++;
	return n;
}

function LastStand::Spot(around) {
	local origin = around.GetOrigin();
	local areas = {};
	try { NavMesh.GetNavAreasInRadius(origin, WitchMax, areas); } catch (e) { return null; }
	local picks = [];
	foreach (name, area in areas) {
		local c = null;
		try { c = area.GetCenter(); } catch (e) { continue; }
		local d = (c - origin).Length();
		if (d < WitchMin || d > WitchMax)
			continue;
		local blocked = false;
		try { blocked = area.IsBlocked(LASTSTAND_TEAM_INFECTED, false); } catch (e) {}
		if (!blocked)
			picks.append(c);
	}
	if (picks.len() == 0)
		return null;
	return picks[RandomInt(0, picks.len() - 1)];
}

function LastStand::Witch(survivors) {
	local pos = Spot(survivors[RandomInt(0, survivors.len() - 1)]);
	if (pos == null)
		return;
	Warn(pos);
	ZSpawn({ type = LASTSTAND_ZOMBIE_WITCH, pos = pos, ang = QAngle(0, RandomInt(0, 359), 0) });
}

function LastStand::Drop(p) {
	local head = p.EyePosition();
	local aim = head + Vector(RandomFloat(-RainSpread, RainSpread), RandomFloat(-RainSpread, RainSpread), RainHeight);
	local trace = { start = head, end = aim, ignore = p };
	TraceLine(trace);
	local pos = (trace.hit && ("pos" in trace)) ? trace.pos - Vector(0, 0, 24) : aim;
	local fork = SpawnEntityFromTable("prop_physics_override", {
		model = RainModel,
		origin = pos,
		angles = RandomInt(60, 120) + " " + RandomInt(0, 359) + " 0",
		massScale = RainMass,
		spawnflags = 4
	});
	if (fork == null || !fork.IsValid())
		return;
	try { fork.ApplyAbsVelocityImpulse(Vector(0, 0, -RainSpeed)); } catch (e) {}
	try { fork.ApplyLocalAngularVelocityImpulse(Vector(RandomFloat(-400, 400), RandomFloat(-400, 400), 0)); } catch (e) {}
	DoEntFire("!self", "Kill", "", RainSeconds, null, fork);
}

function LastStand::Arm(userid) {
	if (!Cursed())
		return;
	local p = null;
	try { p = GetPlayerFromUserID(userid); } catch (e) { return; }
	if (p == null || !p.IsValid() || !p.IsSurvivor() || p.IsDead())
		return;
	local inv = {};
	try { GetInvTable(p, inv); } catch (e) {}
	local primary = ("slot0" in inv) ? inv.slot0 : null;
	if (primary != null && primary.IsValid() && primary.GetClassname() == GiveClass)
		return;
	p.GiveItem(GiveWeapon);
}

function LastStand::ArmAll() {
	foreach (p in Survivors())
		Arm(p.GetPlayerUserId());
}

function LastStand::OnGameEvent_player_spawn(params) {
	if (("userid" in params) && Cursed())
		DoEntFire("!self", "RunScriptCode", "::LastStand.Arm(" + params.userid + ")", GiveDelay, null, Entities.First());
}

function LastStand::Step(now) {
	local survivors = Survivors();
	if (survivors.len() == 0)
		return;
	if (now >= NextWitch) {
		NextWitch = now + WitchEvery;
		if (Witches() < WitchCap)
			Witch(survivors);
	}
	if (now >= NextPanic) {
		NextPanic = now + PanicEvery;
		try { Director.ForcePanicEvent(); } catch (e) {}
		foreach (p in survivors)
			Particle("tank_ground_pound", p.GetOrigin(), 1.0);
		ScreenShake(survivors[0].GetOrigin(), 16.0, 30.0, 1.5, 5000.0, 0, false);
	}
	if (now >= NextStrike) {
		NextStrike = now + StrikeEvery;
		local spot = Ground(survivors[RandomInt(0, survivors.len() - 1)]);
		if (spot != null)
			Warn(spot);
	}
	if (now >= NextRain) {
		NextRain = now + RainEvery;
		foreach (p in survivors)
			for (local i = 0; i < RainPerDrop; i++)
				Drop(p);
	}
}

function LastStand::Tick(generation) {
	if (generation != Generation)
		return;
	if (Cursed())
		try { Step(Time()); } catch (e) { Log("tick failed: " + e); }
	DoEntFire("!self", "RunScriptCode", "::LastStand.Tick(" + generation + ")", TickInterval, null, Entities.First());
}

function LastStand::OnGameEvent_round_start(params) {
	local now = Time();
	NextWitch = now + 8.0;
	NextPanic = now + 10.0;
	NextRain = now + 3.0;
	NextStrike = now + 4.0;
	Generation++;
	DoEntFire("!self", "RunScriptCode", "::LastStand.ArmAll()", 1.0, null, Entities.First());
	Tick(Generation);
}

function LastStand::Hook() {
	if (("GameEventCallbacks" in getroottable()) && ("hd4l_laststand" in ::GameEventCallbacks))
		return;
	__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
	::GameEventCallbacks["hd4l_laststand"] <- true;
}

LastStand.Precache();
LastStand.Hook();
