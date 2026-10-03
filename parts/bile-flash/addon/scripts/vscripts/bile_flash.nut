const TEAM_SURVIVOR = 2;
const TEAM_INFECTED = 3;
const ZOMBIE_TANK = 8;
const FLASH_DMG_STAGGER = 33554432;
const FLASH_BLIND = 7;
const FLASH_IN_ATTACKS = 2049;

::BileFlash <- {
	Versus = true,
	Survival = true,
	Stock = false,

	Radius = 500.0,
	StunSeconds = 5.0,

	StaggerPeriod = 0.5,

	StunSlow = 0.3,

	StunTanks = true,

	StunWitches = true,

	FadeScreen = true,
	FadeRange = 1500.0,
	FadeDuration = 0.1,
	FadeHold = 0.35,
	Effect = "gas_explosion_initialburst_blast",
	Sound = "physics/concrete/boulder_impact_hard1.wav",
	ShakeAmplitude = 12.0,

	Cvars = {
		vomitjar_radius = 0,
		vomitjar_radius_survivors = 0,
		vomitjar_duration_infected_bot = 0,
		vomitjar_duration_infected_pz = 0,
		vomitjar_duration_survivor = 0
	},

	SwarmSeconds = 0.5,
	SwarmRange = 300.0,

	Interval = 0.1,
	Jars = {},
	Landing = [],
	Stunned = {},
	Generation = 0
}

function BileFlash::Log(msg) {
	printl("[BileFlash] " + msg);
}

function BileFlash::ModeAllowed() {
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

function BileFlash::Precache() {
	PrecacheSound(Sound);
	PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = Effect, origin = Vector(0, 0, 0), start_active = 1 });
}

function BileFlash::Alive(ent) {
	if (ent == null || !ent.IsValid() || ent.GetHealth() <= 0)
		return false;
	try { return !ent.IsDead(); } catch (e) { return true; }
}

function BileFlash::Survivors() {
	local list = [];
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null)
		if (p.IsSurvivor() && !p.IsDead())
			list.append(p);
	return list;
}

function BileFlash::Flash(pos) {
	local now = Time();

	local gfx = SpawnEntityFromTable("info_particle_system", { effect_name = Effect, origin = pos + Vector(0, 0, 24), start_active = 1 });
	if (gfx != null)
		DoEntFire("!self", "Kill", "", 3.0, null, gfx);
	Bang(pos);
	local shake = SpawnEntityFromTable("env_shake", { amplitude = ShakeAmplitude.tostring(), radius = Radius.tostring(), duration = "0.6", frequency = "40", spawnflags = "4", origin = pos });
	if (shake != null) {
		DoEntFire("!self", "StartShake", "", 0, null, shake);
		DoEntFire("!self", "Kill", "", 1.0, null, shake);
	}
	if (FadeScreen)
		Fade(pos);

	local count = 0;
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null) {
		if (!Alive(p) || p.GetClassname() != "player")
			continue;
		local team = 0;
		try { team = NetProps.GetPropInt(p, "m_iTeamNum"); } catch (e) { continue; }
		if (team != TEAM_INFECTED || p.IsGhost())
			continue;
		if (!StunTanks && p.GetZombieType() == ZOMBIE_TANK)
			continue;
		if ((p.GetOrigin() - pos).Length() > Radius)
			continue;
		Stun(p, pos, now);
		count++;
	}
	local z = null;
	while ((z = Entities.FindByClassnameWithin(z, "infected", pos, Radius)) != null)
		if (Alive(z)) {
			Stun(z, pos, now);
			count++;
		}
	if (StunWitches) {
		local w = null;
		while ((w = Entities.FindByClassnameWithin(w, "witch", pos, Radius)) != null)
			if (Alive(w)) {
				Stun(w, pos, now);
				count++;
			}
	}
}

function BileFlash::Loud(sound, ent, level, pitch = 100) {
	if (("HD4L" in getroottable()) && ("Loud" in ::HD4L))
		try { ::HD4L.Loud(sound, ent, level, pitch); return; } catch (e) {}
	EmitSoundOn(sound, ent);
}

function BileFlash::Bang(pos) {
	if (Sound == null || Sound == "")
		return;
	local speaker = SpawnEntityFromTable("info_target", { origin = pos });
	if (speaker == null)
		return;
	try { Loud(Sound, speaker, 115, 85); } catch (e) {}
	DoEntFire("!self", "Kill", "", 3.0, null, speaker);
}

function BileFlash::Stun(ent, from, now) {
	local index = ent.GetEntityIndex();
	if (index in Stunned) {
		Stunned[index].until = now + StunSeconds;
		Stunned[index].from = from;
		return;
	}
	local s = { ent = ent, until = now + StunSeconds, next = now, from = from, kind = ent.GetClassname(),
	            speed = -1.0, wrote = -1.0, buttons = 0 };
	if (s.kind == "player") {
		try {
			local held = NetProps.GetPropInt(ent, "m_afButtonDisabled");
			s.buttons = FLASH_IN_ATTACKS & ~held;
			NetProps.SetPropInt(ent, "m_afButtonDisabled", held | FLASH_IN_ATTACKS);
		} catch (e) {}
	}
	Stunned[index] <- s;
}

function BileFlash::Thrower(from) {
	local best = null;
	local dist = 1.0e9;
	foreach (p in Survivors()) {
		local d = (p.GetOrigin() - from).Length();
		if (d < dist) {
			dist = d;
			best = p;
		}
	}
	return best != null ? best : Entities.First();
}

function BileFlash::Reel(s) {
	local ent = s.ent;
	if (s.kind == "player") {
		try { ent.Stagger(s.from); } catch (e) {}
		if (ent.GetZombieType() == ZOMBIE_TANK)
			try {
				local seq = ent.LookupSequence("Shoved_Backward");
				if (seq >= 0) {
					NetProps.SetPropFloatArray(ent, "m_NetGestureStartTime", Time(), 5);
					NetProps.SetPropIntArray(ent, "m_NetGestureSequence", seq, 5);
					NetProps.SetPropIntArray(ent, "m_NetGestureActivity", 1, 5);
				}
			} catch (e) {}
		return;
	}
	if (s.kind == "witch") {
		local rage = 0.0;
		try { rage = NetProps.GetPropFloat(ent, "m_rage"); } catch (e) {}
		if (rage < 1.0)
			return;
	}
	try { ent.TakeDamage(0, FLASH_DMG_STAGGER, Thrower(s.from)); } catch (e) {}
}

function BileFlash::Hold(s) {
	local ent = s.ent;
	if (s.kind == "witch") {
		try {
			if (NetProps.GetPropFloat(ent, "m_rage") < 1.0) {
				NetProps.SetPropFloat(ent, "m_rage", 0.0);
				NetProps.SetPropFloat(ent, "m_wanderrage", 0.0);
			}
		} catch (e) {}
		return;
	}
	if (s.kind != "player")
		return;
	try { ent.SetSenseFlags(FLASH_BLIND); } catch (e) {}
	try {
		local v = NetProps.GetPropFloat(ent, "m_flLaggedMovementValue");
		if (s.speed < 0.0 || fabs(v - s.wrote) > 0.001)
			s.speed = v;
		s.wrote = s.speed * StunSlow;
		NetProps.SetPropFloat(ent, "m_flLaggedMovementValue", s.wrote);
	} catch (e) {}
	try { NetProps.SetPropInt(ent, "m_afButtonDisabled", NetProps.GetPropInt(ent, "m_afButtonDisabled") | s.buttons); } catch (e) {}
}

function BileFlash::Release(s) {
	local ent = s.ent;
	if (s.kind != "player" || !ent.IsValid())
		return;
	try { ent.SetSenseFlags(0); } catch (e) {}
	try {
		if (s.speed >= 0.0 && fabs(NetProps.GetPropFloat(ent, "m_flLaggedMovementValue") - s.wrote) < 0.001)
			NetProps.SetPropFloat(ent, "m_flLaggedMovementValue", s.speed);
	} catch (e) {}
	try { NetProps.SetPropInt(ent, "m_afButtonDisabled", NetProps.GetPropInt(ent, "m_afButtonDisabled") & ~s.buttons); } catch (e) {}
}

function BileFlash::StunTick(now) {
	foreach (index, s in clone Stunned) {
		if (!Alive(s.ent) || now >= s.until) {
			Release(s);
			delete Stunned[index];
			continue;
		}
		Hold(s);
		if (now < s.next)
			continue;
		s.next = now + StaggerPeriod;
		Reel(s);
	}
}

function BileFlash::Fade(pos) {
	local near = false;
	foreach (s in Survivors())
		if ((s.GetOrigin() - pos).Length() <= FadeRange)
			near = true;
	if (!near)
		return;
	local fade = SpawnEntityFromTable("env_fade", {
		spawnflags = "1",
		duration = FadeDuration.tostring(),
		holdtime = FadeHold.tostring(),
		renderamt = "255",
		rendercolor = "255 255 255",
		origin = pos
	});
	if (fade == null)
		return;
	DoEntFire("!self", "Fade", "", 0, null, fade);
	DoEntFire("!self", "Kill", "", 2.0, null, fade);
}

function BileFlash::Cloud(pos) {
	local swarm = null;
	while ((swarm = Entities.FindByClassnameWithin(swarm, "insect_swarm", pos, SwarmRange)) != null) {
		local owner = null;
		try { owner = NetProps.GetPropEntity(swarm, "m_hOwnerEntity"); } catch (e) { owner = null; }
		if (owner != null && owner.IsValid() && owner.GetClassname() == "player") {
			local team = 0;
			try { team = NetProps.GetPropInt(owner, "m_iTeamNum"); } catch (e) { team = 0; }
			if (team != TEAM_SURVIVOR)
				continue;
		}
		return swarm;
	}
	return null;
}

function BileFlash::JarTick(now) {
	local seen = {};
	local proj = null;
	while ((proj = Entities.FindByClassname(proj, "vomitjar_projectile")) != null) {
		if (!proj.IsValid())
			continue;
		local index = proj.GetEntityIndex();
		seen[index] <- true;
		Jars[index] <- { pos = proj.GetOrigin() };
	}
	foreach (index, jar in clone Jars) {
		if (index in seen)
			continue;
		delete Jars[index];
		Landing.append({ pos = jar.pos, until = now + SwarmSeconds });
	}

	local keep = [];
	foreach (land in Landing) {
		local cloud = Cloud(land.pos);
		if (cloud != null) {
			local pos = cloud.GetOrigin();
			try { cloud.Kill(); } catch (e) {}
			Flash(pos);
			continue;
		}
		if (now >= land.until) {
			Flash(land.pos);
			continue;
		}
		keep.append(land);
	}
	Landing = keep;
}

function BileFlash::Tick(generation) {
	if (generation != Generation)
		return;
	if (ModeAllowed()) {
		local now = Time();
		try {
			JarTick(now);
			StunTick(now);
		} catch (e) { Log("tick failed: " + e); }
	}
	DoEntFire("!self", "RunScriptCode", "::BileFlash.Tick(" + generation + ")", Interval, null, Entities.First());
}

function BileFlash::OnGameEvent_round_start(params) {
	Jars = {};
	Landing = [];
	foreach (s in Stunned)
		try { Release(s); } catch (e) {}
	Stunned = {};
	Generation++;
	if (ModeAllowed())
		foreach (name, value in Cvars)
			Convars.SetValue(name, value);
	Tick(Generation);
}

function BileFlash::Hook() {
	if (("GameEventCallbacks" in getroottable()) && ("hd4l_bile_flash" in ::GameEventCallbacks))
		return;
	__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
	::GameEventCallbacks["hd4l_bile_flash"] <- true;
}

BileFlash.Precache();
BileFlash.Hook();

if (!("HD4L_Parts" in getroottable()))
	::HD4L_Parts <- {};
::HD4L_Parts["bile_flash"] <- "0.1";
