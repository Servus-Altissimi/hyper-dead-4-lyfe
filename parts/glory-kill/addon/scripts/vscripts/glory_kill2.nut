const TEAM_INFECTED = 3;
const ZOMBIE_TANK = 8;
const DMG_CLUB = 128;
const DMG_BLAST = 64;

::GloryKill2 <- {
	Versus = true,
	Survival = true,
	Stock = false,

	Threshold = 0.35,
	TankThreshold = 0.10,

	Window = 3.5,
	TankWindow = 6.0,

	VersusWindow = 1.2,
	VersusTankWindow = 2.5,

	Passive = true,

	TempHealth = 15,
	RefillStamina = true,

	ReelPeriod = 1.2,
	BleedPeriod = 0.4,
	Bleed = "blood_impact_red_01",

	Gore = [ "blood_impact_headshot_01", "blood_atomized_gore" ],
	ScreenBlood = "screen_blood_splatter_melee",
	Sound = "glory2/finisher.mp3",
	Layers = [ { sound = "glory2/finisher.mp3", pitch = 62, level = 110 },
	           { sound = "player/tank/hit/pound_victim_1.wav", pitch = 90, level = 105 },
	           { sound = "player/tank/hit/hulk_punch_1.wav", pitch = 80, level = 100 } ],
	Ring = "tank_ground_pound",
	Mist = "hd4l_red_mist",
	Spray = 4,
	Flashes = [ { color = "255 176 60", scale = 3.0, life = 0.18 }, { color = "215 45 35", scale = 2.2, life = 0.4 } ],
	Punch = 8.0,
	LaunchSpeed = 700.0,
	LaunchLift = 250.0,

	BlastRadius = 280.0,
	BlastDamageCommon = 500,
	BlastDamageSpecial = 150,
	BlastLaunch = 500.0,
	BlastLift = 250.0,

	Open = {},
	Generation = 0
}

function GloryKill2::Log(msg) {
	printl("[GloryKill2] " + msg);
}

function GloryKill2::ModeAllowed() {
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

function GloryKill2::Precache() {
	PrecacheSound(Sound);
	foreach (layer in Layers)
		PrecacheSound(layer.sound);
	PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = Ring });
	PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = Mist });
	foreach (effect in Gore)
		PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = effect });
	PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = ScreenBlood });
	PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = Bleed });
}

function GloryKill2::IsSpecial(ent) {
	return ent != null && ent.IsValid() && ent.GetClassname() == "player"
		&& NetProps.GetPropInt(ent, "m_iTeamNum") == TEAM_INFECTED && !ent.IsDead() && !ent.IsGhost();
}

function GloryKill2::IsHumanSurvivor(ent) {
	return ent != null && ent.IsValid() && ent.GetClassname() == "player" && ent.IsSurvivor() && !ent.IsDead();
}

function GloryKill2::IsOpen(ent) {
	return ent != null && ent.IsValid() && (ent.GetEntityIndex() in Open);
}

function GloryKill2::OpenWindow(ent, attacker) {
	local index = ent.GetEntityIndex();
	local tank = ent.GetZombieType() == ZOMBIE_TANK;
	local now = Time();
	local versus = false;
	try { versus = Director.GetGameMode() == "hd4lversus"; } catch (e) {}
	local length = versus ? (tank ? VersusTankWindow : VersusWindow) : (tank ? TankWindow : Window);
	Open[index] <- { ent = ent, until = now + length, tank = tank, reelAt = now + ReelPeriod, bleedAt = now };
	if (!tank) {
		try { ent.Stagger(attacker != null && attacker.IsValid() ? attacker.GetOrigin() : ent.GetOrigin()); } catch (e) {}
		if (Passive)
			try { ent.SetSenseFlags(INFECTED_FLAG_CANT_SEE_SURVIVORS | INFECTED_FLAG_CANT_HEAR_SURVIVORS | INFECTED_FLAG_CANT_FEEL_SURVIVORS); } catch (e) {}
	}
}

function GloryKill2::Reel(w, now) {
	local ent = w.ent;
	if (!w.tank && now >= w.reelAt) {
		w.reelAt = now + ReelPeriod;
		local from = ent.GetOrigin();
		local p = null;
		local best = 99999.0;
		while ((p = Entities.FindByClassname(p, "player")) != null) {
			if (!p.IsSurvivor() || p.IsDead())
				continue;
			local d = (p.GetOrigin() - ent.GetOrigin()).Length();
			if (d < best) {
				best = d;
				from = p.GetOrigin();
			}
		}
		try { ent.Stagger(from); } catch (e) {}
	}
	if (now >= w.bleedAt) {
		w.bleedAt = now + BleedPeriod;
		local puff = SpawnEntityFromTable("info_particle_system", { effect_name = Bleed, start_active = 1, origin = ent.GetOrigin() + Vector(0, 0, 48) });
		if (puff != null)
			DoEntFire("!self", "Kill", "", 0.5, null, puff);
	}
}

function GloryKill2::CloseWindow(index, finished) {
	if (!(index in Open))
		return;
	local ent = Open[index].ent;
	delete Open[index];
	if (ent == null || !ent.IsValid())
		return;
	try { ent.SetSenseFlags(0); } catch (e) {}
}

function GloryKill2::Tick(generation) {
	if (generation != Generation)
		return;
	local now = Time();
	foreach (index, w in clone Open) {
		if (w.ent == null || !w.ent.IsValid() || w.ent.IsDead())
			CloseWindow(index, false);
		else if (now >= w.until)
			CloseWindow(index, false);
		else
			Reel(w, now);
	}
	DoEntFire("!self", "RunScriptCode", "::GloryKill2.Tick(" + generation + ")", 0.1, null, Entities.First());
}

function GloryKill2::TryFinish(victim, attacker, kind) {
	if (!ModeAllowed() || !IsOpen(victim) || !IsHumanSurvivor(attacker))
		return false;
	local w = Open[victim.GetEntityIndex()];
	if (w.tank && kind != "kick")
		return false;
	Finish(victim, attacker, kind);
	return true;
}

function GloryKill2::Finish(victim, attacker, kind) {
	local index = victim.GetEntityIndex();
	local origin = victim.GetOrigin();
	local boomer = victim.GetZombieType() == 2;
	CloseWindow(index, true);

	foreach (i, effect in Gore) {
		local gfx = SpawnEntityFromTable("info_particle_system", { effect_name = effect, start_active = 1, origin = origin + Vector(0, 0, 40) });
		if (gfx != null)
			DoEntFire("!self", "Kill", "", 1.5, null, gfx);
	}
	local splat = SpawnEntityFromTable("info_particle_system", { effect_name = ScreenBlood, start_active = 1, render_in_front = 1, origin = attacker.EyePosition() });
	if (splat != null)
		DoEntFire("!self", "Kill", "", 1.0, null, splat);
	EmitSoundOn(Sound, attacker);
	ScreenShake(origin, 8.0, 40.0, 0.5, 400.0, 0, false);
	try { Spectacle(origin, attacker); } catch (e) { Log("spectacle failed: " + e); }

	local away = origin - attacker.GetOrigin();
	away.z = 0;
	if (away.Length() < 1.0)
		away = Vector(1, 0, 0);
	away.Norm();
	victim.ApplyAbsVelocityImpulse(away * LaunchSpeed + Vector(0, 0, LaunchLift));

	if (boomer) {
		local inner = Convars.GetFloat("z_exploding_inner_radius");
		local outer = Convars.GetFloat("z_exploding_outer_radius");
		Convars.SetValue("z_exploding_inner_radius", 0);
		Convars.SetValue("z_exploding_outer_radius", 0);
		DoEntFire("!self", "RunScriptCode", "Convars.SetValue(\"z_exploding_inner_radius\", " + inner + "); Convars.SetValue(\"z_exploding_outer_radius\", " + outer + ")", 0.3, null, Entities.First());
	}
	if (("ChapterStats" in getroottable()) && ("Note" in ::ChapterStats))
		try { ::ChapterStats.Note(attacker, "glory"); } catch (e) {}
	victim.TakeDamage(victim.GetHealth() + 1000, DMG_CLUB | DMG_BLAST, attacker);

	Blast(origin, attacker);
	Reward(attacker);
	if ("HyperFeedback" in getroottable() && ("Glory" in ::HyperFeedback))
		::HyperFeedback.Glory(attacker);
}

function GloryKill2::Spectacle(origin, attacker) {
	local ring = SpawnEntityFromTable("info_particle_system", { effect_name = Ring, start_active = 1, origin = origin });
	if (ring != null)
		DoEntFire("!self", "Kill", "", 1.5, null, ring);
	for (local i = 0; i < Spray; i++) {
		local at = origin + Vector(RandomFloat(-40, 40), RandomFloat(-40, 40), RandomFloat(20, 70));
		local gfx = SpawnEntityFromTable("info_particle_system", { effect_name = Bleed, start_active = 1, origin = at });
		if (gfx != null)
			DoEntFire("!self", "Kill", "", 1.0, null, gfx);
	}
	try {
		local punch = NetProps.GetPropVector(attacker, "m_Local.m_vecPunchAngle");
		NetProps.SetPropVector(attacker, "m_Local.m_vecPunchAngle", Vector(punch.x - Punch, punch.y, punch.z + RandomFloat(-Punch, Punch) * 0.5));
	} catch (e) {}
	if (!("HD4L" in getroottable()) || !("Loud" in ::HD4L))
		return;
	foreach (flash in Flashes)
		::HD4L.Flash(origin + Vector(0, 0, 40), flash.color, flash.scale, flash.life);
	local speaker = ::HD4L.Speaker(origin + Vector(0, 0, 40), 3.0);
	::HD4L.Loud(Sound, attacker, 100);
	foreach (layer in Layers)
		::HD4L.Loud(layer.sound, speaker != null ? speaker : attacker, layer.level, layer.pitch);
}

function GloryKill2::Blast(origin, attacker) {
	local mist = SpawnEntityFromTable("info_particle_system", { effect_name = Mist, start_active = 1, origin = origin + Vector(0, 0, 32) });
	if (mist != null)
		DoEntFire("!self", "Kill", "", 3.0, null, mist);
	local push = SpawnEntityFromTable("env_physexplosion", { magnitude = "900", radius = BlastRadius.tostring(), spawnflags = "1", origin = origin });
	if (push != null) {
		DoEntFire("!self", "Explode", "", 0, null, push);
		DoEntFire("!self", "Kill", "", 0.1, null, push);
	}
	ScreenShake(origin, 14.0, 40.0, 0.8, BlastRadius * 2, 0, false);

	local ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "infected", origin, BlastRadius)) != null) {
		if (ent.GetHealth() <= 0)
			continue;
		local away = ent.GetOrigin() - origin;
		away.z = 0;
		if (away.Length() < 1.0)
			away = Vector(1, 0, 0);
		away.Norm();
		ent.ApplyAbsVelocityImpulse(away * BlastLaunch + Vector(0, 0, BlastLift));
		ent.TakeDamage(BlastDamageCommon, DMG_CLUB | DMG_BLAST, attacker);
	}
	ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "player", origin, BlastRadius)) != null) {
		if (!IsSpecial(ent))
			continue;
		ent.TakeDamage(BlastDamageSpecial, DMG_CLUB, attacker);
		if (ent.GetZombieType() != ZOMBIE_TANK)
			try { ent.Stagger(origin); } catch (e) {}
	}
}

function GloryKill2::Reward(attacker) {
	if (TempHealth > 0) {
		local room = attacker.GetMaxHealth() - attacker.GetHealth() - attacker.GetHealthBuffer();
		local give = TempHealth < room ? TempHealth : room;
		if (give > 0)
			attacker.SetHealthBuffer(attacker.GetHealthBuffer() + give);
	}
	if (RefillStamina && ("Momentum" in getroottable()) && ("Refill" in ::Momentum))
		::Momentum.Refill(attacker);
}

function GloryKill2::OnGameEvent_player_hurt(params) {
	if (!ModeAllowed() || !("userid" in params) || !("health" in params))
		return;
	local victim = null;
	try { victim = GetPlayerFromUserID(params.userid); } catch (e) { return; }
	if (!IsSpecial(victim) || IsOpen(victim))
		return;
	local attacker = null;
	if ("attacker" in params)
		try { attacker = GetPlayerFromUserID(params.attacker); } catch (e) {}
	if (!IsHumanSurvivor(attacker))
		return;
	local tank = victim.GetZombieType() == ZOMBIE_TANK;
	local max = victim.GetMaxHealth();
	if (max <= 0 || params.health <= 0)
		return;
	if (params.health <= max * (tank ? TankThreshold : Threshold))
		OpenWindow(victim, attacker);
}

function GloryKill2::OnGameEvent_player_shoved(params) {
	if (!("userid" in params) || !("attacker" in params))
		return;
	local victim = null;
	local attacker = null;
	try { victim = GetPlayerFromUserID(params.userid); attacker = GetPlayerFromUserID(params.attacker); } catch (e) { return; }
	TryFinish(victim, attacker, "shove");
}

function GloryKill2::OnGameEvent_player_death(params) {
	if (!("userid" in params))
		return;
	local victim = null;
	try { victim = GetPlayerFromUserID(params.userid); } catch (e) { return; }
	if (victim != null && victim.IsValid())
		CloseWindow(victim.GetEntityIndex(), false);
}

function GloryKill2::OnGameEvent_round_start(params) {
	Open = {};
	Generation++;
	Tick(Generation);
}

function GloryKill2::Hook() {
	if (("GameEventCallbacks" in getroottable()) && ("hd4l_glory_kill2" in ::GameEventCallbacks))
		return;
	__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
	::GameEventCallbacks["hd4l_glory_kill2"] <- true;
}

GloryKill2.Precache();
GloryKill2.Hook();

if (!("HD4L_Parts" in getroottable()))
	::HD4L_Parts <- {};
::HD4L_Parts["glory_kill2"] <- "0.1";
