const DMG_CLUB = 128;
const ZOMBIE_TANK = 8;
const TEAM_INFECTED = 3;
const TWO_PI = 6.28318;

::DeathShockwave <- {
	IncludeBots = false,

	Radius = 750.0,
	Rings = 5,
	RingDelay = 0.12,

	ZTolerance = 96.0,

	DamageCommon = 1000,
	DamageSpecial = 1000,
	DamageWitch = 1000,
	DamageTank = 1500,

	LaunchSpeed = 450.0,
	LaunchLift = 300.0,

	Versus = false,
	Survival = true,
	Stock = true,

	Active = {},
	NextId = 0
}

function DeathShockwave::Log(msg) {
	printl("[DeathShockwave] " + msg);
}

function DeathShockwave::ModeAllowed() {
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

function DeathShockwave::Precache() {
	PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = "tank_ground_pound" });
	PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = "tank_rock_throw_impact" });
	foreach (snd in [ "physics/concrete/boulder_impact_hard1.wav", "physics/concrete/boulder_impact_hard2.wav",
	                  "physics/concrete/concrete_break2.wav", "physics/concrete/concrete_break3.wav" ])
		PrecacheSound(snd);
}

function DeathShockwave::OnGameEvent_player_death(params) {
	if (!("userid" in params) || !ModeAllowed())
		return;
	local player = null;
	try { player = GetPlayerFromUserID(params.userid); } catch (e) { return; }
	if (player == null || !player.IsValid() || !player.IsSurvivor())
		return;
	if (!IncludeBots && IsPlayerABot(player))
		return;
	Start(player);
}

function DeathShockwave::Start(player) {
	StartAt(player.GetOrigin(), player);
}

function DeathShockwave::StartAt(origin, player) {
	local ground = Ground(origin, player);
	if (ground != null)
		origin = ground;

	NextId++;
	Active[NextId] <- { origin = origin, attacker = player.GetEntityIndex(), hit = {}, ring = 0 };
	Ring(NextId);
}

function DeathShockwave::Ring(id) {
	if (!(id in Active))
		return;
	local wave = Active[id];
	wave.ring++;
	local radius = Radius * wave.ring / Rings;

	if (wave.ring == 1)
		Centre(wave.origin);
	RingEffects(wave.origin, radius, wave.ring);
	RingDamage(wave, radius);

	if (wave.ring >= Rings)
		delete Active[id];
	else
		DoEntFire("!self", "RunScriptCode", "::DeathShockwave.Ring(" + id + ")", RingDelay, null, Entities.First());
}

function DeathShockwave::RingDamage(wave, radius) {
	local ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "player", wave.origin, radius)) != null) {
		if (!ent.IsValid() || NetProps.GetPropInt(ent, "m_iTeamNum") != TEAM_INFECTED || ent.IsDead() || ent.IsGhost())
			continue;
		Hit(wave, ent, ent.GetZombieType() == ZOMBIE_TANK ? DamageTank : DamageSpecial);
	}
	ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "witch", wave.origin, radius)) != null)
		Hit(wave, ent, DamageWitch);
	ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "infected", wave.origin, radius)) != null)
		Hit(wave, ent, DamageCommon);
}

function DeathShockwave::Hit(wave, ent, damage) {
	if (!ent.IsValid() || ent.GetHealth() <= 0)
		return;
	local index = ent.GetEntityIndex();
	if (index in wave.hit)
		return;
	if (fabs(ent.GetOrigin().z - wave.origin.z) > ZTolerance)
		return;
	wave.hit[index] <- true;

	local attacker = EntIndexToHScript(wave.attacker);
	if (attacker == null || !attacker.IsValid())
		attacker = Entities.First();

	local away = ent.GetOrigin() - wave.origin;
	away.z = 0;
	if (away.Length() < 1.0)
		away = Vector(1, 0, 0);
	away.Norm();

	if (damage >= ent.GetHealth())
		ent.ApplyAbsVelocityImpulse(away * LaunchSpeed + Vector(0, 0, LaunchLift));
	else
		try { ent.Stagger(wave.origin); } catch (e) {}

	ent.TakeDamage(damage, DMG_CLUB, attacker);
}

function DeathShockwave::Loud(sound, ent, level, pitch = 100) {
	if (("HD4L" in getroottable()) && ("Loud" in ::HD4L))
		try { ::HD4L.Loud(sound, ent, level, pitch); return; } catch (e) {}
	EmitSoundOn(sound, ent);
}

function DeathShockwave::Centre(origin) {
	local pound = SpawnEntityFromTable("info_particle_system", { effect_name = "tank_ground_pound", start_active = "1", origin = origin });
	if (pound != null) {
		Loud("physics/concrete/boulder_impact_hard1.wav", pound, 120, 70);
		Loud("physics/concrete/concrete_break2.wav", pound, 115, 85);
		DoEntFire("!self", "Kill", "", 1.0, null, pound);
	}
	ScreenShake(origin, 12.0, 40.0, 1.2, Radius * 1.5, 0, false);

	local push = SpawnEntityFromTable("env_physexplosion", { magnitude = "1200", radius = Radius.tostring(), spawnflags = "1", origin = origin });
	if (push != null) {
		DoEntFire("!self", "Explode", "", 0, null, push);
		DoEntFire("!self", "Kill", "", 0.1, null, push);
	}
}

function DeathShockwave::RingEffects(origin, radius, ring) {
	local count = 6 + 2 * ring;
	local step = TWO_PI / count;
	local rotate = ring * 0.3;
	for (local i = 0; i < count; i++) {
		local angle = i * step + rotate;
		local spot = origin + Vector(cos(angle), sin(angle), 0) * radius;
		local ground = Ground(spot, null);
		if (ground == null)
			continue;
		ground.z -= 20.0;
		local impact = SpawnEntityFromTable("info_particle_system", { effect_name = "tank_rock_throw_impact", start_active = "1", origin = ground });
		if (impact == null)
			continue;
		if (i % 3 == 0)
			Loud(RandomInt(0, 1) == 0 ? "physics/concrete/boulder_impact_hard2.wav" : "physics/concrete/concrete_break3.wav", impact, 105, RandomInt(80, 100));
		DoEntFire("!self", "Kill", "", 1.0, null, impact);
	}
}

function DeathShockwave::Ground(pos, ignore) {
	local trace = { start = Vector(pos.x, pos.y, pos.z + 100.0), end = Vector(pos.x, pos.y, pos.z - 300.0) };
	if (ignore != null)
		trace.ignore <- ignore;
	TraceLine(trace);
	return trace.hit ? trace.pos : null;
}

DeathShockwave.Precache();

function DeathShockwave::Hook() {
	if (("GameEventCallbacks" in getroottable()) && ("hd4l_death_shockwave" in ::GameEventCallbacks))
		return;
	__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
	::GameEventCallbacks["hd4l_death_shockwave"] <- true;
}

DeathShockwave.Hook();

if (!("HD4L_Parts" in getroottable()))
	::HD4L_Parts <- {};
::HD4L_Parts["death_shockwave"] <- "0.1";
