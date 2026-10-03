const DOORBLAST_EF_NODRAW = 32;
const DOORBLAST_COLLISION_DEBRIS = 1;
const DOORBLAST_COLLISION_NONE = 0;
const DOORBLAST_DMG_BLAST = 64;
const DOORBLAST_PROP_NAME = "door_blast_prop";

::DoorBlast <- {
	Versus = true,
	Survival = false,
	Stock = false,

	Classname = "prop_door_rotating_checkpoint",
	Speed = 1400.0,
	Lift = 260.0,
	Spin = 500.0,
	Tumble = 120.0,
	MassScale = 6.0,
	PropSeconds = 0.0,

	Explosion = true,
	FireballSize = 200,
	BlastRadius = 260.0,
	BlastDamage = 1000.0,
	ShakeAmplitude = 14.0,
	ShakeRadius = 900.0,
	ShakeSeconds = 1.2,
	Effect = "tank_rock_throw_impact",
	EffectSeconds = 5.0,
	Sound = "Breakable.Metal",
	Layers = [ { sound = "physics/concrete/boulder_impact_hard1.wav", pitch = 65 }, { sound = "physics/metal/metal_sheet_impact_hard6.wav", pitch = 80 } ],

	Generation = 0
}

function DoorBlast::Log(msg) {
	printl("[DoorBlast] " + msg);
}

function DoorBlast::ModeAllowed() {
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

function DoorBlast::Precache() {
	PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = Effect, origin = Vector(0, 0, 0), start_active = 1 });
	try { PrecacheSound(Sound); } catch (e) {}
	try { PrecacheScriptSound(Sound); } catch (e) {}
	foreach (layer in Layers)
		try { PrecacheSound(layer.sound); } catch (e) {}
}

function DoorBlast::Arm() {
	local count = 0;
	local door = null;
	while ((door = Entities.FindByClassname(door, Classname)) != null) {
		if (!door.IsValid())
			continue;
		door.ValidateScriptScope();
		local scope = door.GetScriptScope();
		if ("DoorBlastArmed" in scope)
			continue;
		scope.DoorBlastArmed <- true;
		scope.DoorBlastDone <- false;
		scope.DoorBlastOpen <- function() { ::DoorBlast.Blast(self, activator); };
		scope.DoorBlastClose <- function() { ::DoorBlast.Show(self, true); };
		door.ConnectOutput("OnOpen", "DoorBlastOpen");
		door.ConnectOutput("OnClose", "DoorBlastClose");
		count++;
	}
}

function DoorBlast::Show(door, on) {
	if (door == null || !door.IsValid())
		return;
	local scope = door.GetScriptScope();
	if (scope == null || !("DoorBlastDone" in scope) || !scope.DoorBlastDone)
		return;
	local fx = NetProps.GetPropInt(door, "m_fEffects");
	NetProps.SetPropInt(door, "m_fEffects", on ? (fx & ~DOORBLAST_EF_NODRAW) : (fx | DOORBLAST_EF_NODRAW));
	try { NetProps.SetPropInt(door, "m_CollisionGroup", on ? DOORBLAST_COLLISION_NONE : DOORBLAST_COLLISION_DEBRIS); } catch (e) {}
	try {
		if (on && ("DoorBlastGlow" in scope))
			NetProps.SetPropInt(door, "m_Glow.m_iGlowType", scope.DoorBlastGlow);
		else if (!on) {
			scope.DoorBlastGlow <- NetProps.GetPropInt(door, "m_Glow.m_iGlowType");
			NetProps.SetPropInt(door, "m_Glow.m_iGlowType", 0);
		}
	} catch (e) {}
}

function DoorBlast::Direction(door, opener) {
	local dir = null;
	if (opener != null && opener.IsValid())
		dir = door.GetCenter() - opener.GetOrigin();
	else
		dir = door.GetForwardVector();
	dir.z = 0.0;
	if (dir.Length() < 1.0)
		dir = door.GetForwardVector();
	dir.z = 0.0;
	return dir * (1.0 / dir.Length());
}

function DoorBlast::Loud(sound, ent, level, pitch = 100) {
	if (("HD4L" in getroottable()) && ("Loud" in ::HD4L))
		try { ::HD4L.Loud(sound, ent, level, pitch); return; } catch (e) {}
	EmitSoundOn(sound, ent);
}

function DoorBlast::Blast(door, opener) {
	if (!ModeAllowed() || door == null || !door.IsValid())
		return;
	local scope = door.GetScriptScope();
	if (scope.DoorBlastDone) {
		Show(door, false);
		return;
	}
	local left = true;
	try { left = Director.HasAnySurvivorLeftSafeArea(); } catch (e) {}
	if (left)
		return;
	scope.DoorBlastDone <- true;

	local origin = door.GetOrigin();
	local angles = door.GetAngles();
	local center = door.GetCenter();
	local dir = Direction(door, opener);

	local prop = SpawnEntityFromTable("prop_physics_override", {
		model = door.GetModelName(),
		origin = origin,
		angles = angles.x + " " + angles.y + " " + angles.z,
		skin = NetProps.GetPropInt(door, "m_nSkin"),
		targetname = DOORBLAST_PROP_NAME,
		massScale = MassScale,
		spawnflags = 4
	});
	if (prop != null && prop.IsValid()) {
		try { prop.ApplyAbsVelocityImpulse(dir * Speed + Vector(0, 0, Lift)); } catch (e) { Log("impulse failed: " + e); }
		try { prop.ApplyLocalAngularVelocityImpulse(Vector(RandomFloat(-Tumble, Tumble), RandomFloat(-Spin, Spin), RandomFloat(-Tumble, Tumble))); } catch (e) {}
		if (PropSeconds > 0.0)
			DoEntFire("!self", "Kill", "", PropSeconds, null, prop);
	} else
		Log("no door prop: " + door.GetModelName());

	Show(door, false);

	if (Explosion) {
		local boom = SpawnEntityFromTable("env_explosion", { origin = center, iMagnitude = FireballSize, iRadiusOverride = 1, spawnflags = 1 });
		if (boom != null) {
			DoEntFire("!self", "Explode", "", 0, null, boom);
			DoEntFire("!self", "Kill", "", 1.0, null, boom);
		}
	}
	local gfx = SpawnEntityFromTable("info_particle_system", { effect_name = Effect, origin = center, start_active = 1 });
	if (gfx != null)
		DoEntFire("!self", "Kill", "", EffectSeconds, null, gfx);
	try { EmitSoundOn(Sound, door); } catch (e) {}
	foreach (layer in Layers)
		try { Loud(layer.sound, door, 120, layer.pitch); } catch (e) {}
	local shake = SpawnEntityFromTable("env_shake", { origin = center, amplitude = ShakeAmplitude, radius = ShakeRadius, duration = ShakeSeconds, frequency = 180, spawnflags = 0 });
	if (shake != null) {
		DoEntFire("!self", "StartShake", "", 0, null, shake);
		DoEntFire("!self", "Kill", "", ShakeSeconds + 0.5, null, shake);
	}
	try { Shockwave(center, dir, prop); } catch (e) { Log("shockwave failed: " + e); }
}

function DoorBlast::Shockwave(center, dir, source) {
	local killed = 0;
	local ent = null;
	while ((ent = Entities.FindByClassnameWithin(ent, "infected", center, BlastRadius)) != null) {
		local to = ent.GetOrigin() - center;
		to.z = 0.0;
		if (to.Dot(dir) < 0.0 || ent.GetHealth() <= 0)
			continue;
		ent.TakeDamage(BlastDamage, DOORBLAST_DMG_BLAST, (source != null && source.IsValid()) ? source : Entities.First());
		killed++;
	}
	local p = null;
	while ((p = Entities.FindByClassnameWithin(p, "player", center, BlastRadius)) != null)
		if (!p.IsSurvivor() && !p.IsDead() && !p.IsGhost())
			try { p.Stagger(center); } catch (e) {}
}

function DoorBlast::Harmless(damageTable) {
	if (!("Victim" in damageTable) || !("Inflictor" in damageTable))
		return false;
	local victim = damageTable.Victim;
	local inflictor = damageTable.Inflictor;
	if (victim == null || !victim.IsValid() || victim.GetClassname() != "player" || !victim.IsSurvivor())
		return false;
	return inflictor != null && inflictor.IsValid() && inflictor.GetName() == DOORBLAST_PROP_NAME;
}

function DoorBlast::OnGameEvent_round_start(params) {
	Generation++;
	if (ModeAllowed())
		DoEntFire("!self", "RunScriptCode", "::DoorBlast.Arm()", 0.5, null, Entities.First());
}

function DoorBlast::OnGameEvent_player_first_spawn(params) {
	if (ModeAllowed())
		try { Arm(); } catch (e) { Log("arm failed: " + e); }
}

function DoorBlast::Hook() {
	if (("GameEventCallbacks" in getroottable()) && ("hd4l_door_blast" in ::GameEventCallbacks))
		return;
	__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
	::GameEventCallbacks["hd4l_door_blast"] <- true;
}

DoorBlast.Precache();
DoorBlast.Hook();

if (!("HD4L_Parts" in getroottable()))
	::HD4L_Parts <- {};
::HD4L_Parts["door_blast"] <- "0.1";
