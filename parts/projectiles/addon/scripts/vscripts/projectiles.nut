const PROJ_DMG_BULLET = 2;
const PROJ_MASK_SHOT = 1174421515;
const PROJ_TEAM_SURVIVOR = 2;
const PROJ_TEAM_INFECTED = 3;

::Projectiles <- {
	Versus = true,
	Survival = true,
	Stock = false,
	Enabled = true,

	Speed = 4000.0,
	TracerSpeeds = [ 1000, 1500, 2000, 3000, 4000, 6000, 8000, 12000 ],
	Tracer = "hd4l_projectile_tracer_4000",
	TracerLife = 2.0,
	Impact = "impact_concrete_cheap",
	Blood = "blood_impact_red_01_cheap",
	FxLife = 1.0,
	MuzzleDrop = 4.0,
	MuzzleForward = 16.0,

	HoldWounds = true,
	WoundProps = [ "m_iRequestedWound1", "m_iRequestedWound2" ],
	Wounds = {},

	BulletParry = true,
	ParryWeapons = { pistol = true, pistol_magnum = true, pumpshotgun = true, shotgun_chrome = true,
	                 hunting_rifle = true, sniper_military = true, sniper_awp = true, sniper_scout = true },
	ParryAmmo = 1,
	ParryWindow = 0.1,
	ParrySpeed = 8000.0,
	ParrySound = "physics/destruction/explosivegasleak.wav",
	ParryBlast = "impact_explosive_ammo_large",
	ParryBlastSound = "weapons/grenade_launcher/grenadefire/grenade_launcher_explode_1.wav",
	ParryRadius = 160.0,
	ParryDamage = 80.0,
	ParryPush = 400,
	ParryStaggerRadius = 50.0,
	LastShot = {},
	ParryAt = {},
	Pressed = {},

	HeadRadius = 10.0,
	HeadMultiplier = 4.0,
	HeadAttachments = [ "Head", "forward", "eyes", "mouth" ],

	HideStock = true,
	HideCommands = [ "cl_impacteffects", "r_drawtracers_firstperson" ],
	HideBlood = true,
	BloodCvars = [ "violence_hblood", "violence_ablood" ],

	Weapons = {
		pistol = [ 36, 2500, 0.75, 2 ], pistol_magnum = [ 80, 3500, 0.75, 2 ],
		smg = [ 20, 2500, 0.84, 2 ], smg_silenced = [ 25, 2200, 0.84, 2 ], smg_mp5 = [ 26, 2500, 0.84, 2 ],
		pumpshotgun = [ 25, 3000, 0.7, 2 ], shotgun_chrome = [ 31, 3000, 0.7, 2 ],
		autoshotgun = [ 23, 3000, 0.7, 2 ], shotgun_spas = [ 28, 3000, 0.7, 2 ],
		rifle = [ 33, 3000, 0.97, 2 ], rifle_ak47 = [ 58, 3000, 0.97, 2 ], rifle_desert = [ 44, 3000, 0.97, 2 ],
		rifle_sg552 = [ 33, 3000, 0.97, 2 ], rifle_m60 = [ 50, 3000, 0.97, 2 ],
		hunting_rifle = [ 90, 8192, 1.0, 2 ], sniper_military = [ 90, 8192, 1.0, 2 ],
		sniper_awp = [ 115, 8192, 1.0, 2 ], sniper_scout = [ 105, 8192, 1.0, 2 ]
	},

	Shots = {},
	Flying = [],
	InHit = false,
	LastTick = 0.0,
	Serial = 0,
	Counts = { fired = 0, rays = 0, held = 0, landed = 0, fresh = 0, missed = 0, leaks = 0, parried = 0, blasts = 0 },
	Debug = false,
	DebugTime = 4.0,
	Ours = {},
	Generation = 0
}

function Projectiles::Log(msg) {
	printl("[Projectiles] " + msg);
}

function Projectiles::ModeAllowed() {
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

function Projectiles::Active() {
	return Enabled && ModeAllowed();
}

function Projectiles::Precache() {
	foreach (s in TracerSpeeds)
		PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = "hd4l_projectile_tracer_" + s });
	PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = Impact });
	PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = Blood });
	PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = ParryBlast });
	PrecacheSound(ParrySound);
	PrecacheSound(ParryBlastSound);
}

function Projectiles::WeaponName(w) {
	if (w == null || !w.IsValid())
		return "";
	local cls = w.GetClassname();
	return cls.len() > 7 && cls.slice(0, 7) == "weapon_" ? cls.slice(7) : "";
}

function Projectiles::Gunner(p) {
	return p != null && p.IsValid() && p.GetClassname() == "player" && NetProps.GetPropInt(p, "m_iTeamNum") == PROJ_TEAM_SURVIVOR;
}

function Projectiles::ShotFor(p, weapon = "") {
	local id = p.GetPlayerUserId();
	local now = Time();
	if ((id in Shots) && Shots[id].t == now) {
		if (weapon != "" && Shots[id].weapon == "")
			Shots[id].weapon = weapon;
		return Shots[id];
	}
	if (weapon == "")
		weapon = WeaponName(p.GetActiveWeapon());
	local s = { t = now, p = p, weapon = weapon, eye = p.EyePosition(), dir = p.EyeAngles().Forward(), rays = [], hits = [] };
	Shots[id] <- s;
	DoEntFire("!self", "RunScriptCode", "::Projectiles.Launch(" + id + ")", 0.0, null, Entities.First());
	return s;
}

function Projectiles::OnGameEvent_weapon_fire(params) {
	if (!Active() || !("userid" in params) || !("weapon" in params) || !(params.weapon in Weapons))
		return;
	local p = GetPlayerFromUserID(params.userid);
	if (!Gunner(p))
		return;
	ShotFor(p, params.weapon);
	Counts.fired++;
}

function Projectiles::OnGameEvent_bullet_impact(params) {
	if (!Active() || !("userid" in params))
		return;
	local p = GetPlayerFromUserID(params.userid);
	if (!Gunner(p) || !(WeaponName(p.GetActiveWeapon()) in Weapons))
		return;
	ShotFor(p).rays.append(Vector(params.x, params.y, params.z));
	Counts.rays++;
}

function Projectiles::Intercept(damageTable) {
	if (InHit || !Active())
		return false;
	if (("Arsenal" in getroottable()) && ("InPellet" in ::Arsenal) && ::Arsenal.InPellet)
		return false;
	if (!("DamageType" in damageTable) || !(damageTable.DamageType & PROJ_DMG_BULLET))
		return false;
	local p = ("Attacker" in damageTable) ? damageTable.Attacker : null;
	if (!Gunner(p))
		return false;
	local wep = ("Weapon" in damageTable) ? damageTable.Weapon : null;
	if (wep == null || !wep.IsValid())
		wep = p.GetActiveWeapon();
	local name = WeaponName(wep);
	if (!(name in Weapons))
		return false;
	local victim = ("Victim" in damageTable) ? damageTable.Victim : null;
	if (victim == null || !victim.IsValid())
		return false;
	local hit = { victim = victim, damage = damageTable.DamageDone, type = damageTable.DamageType, wounds = null };
	if (HoldWounds && victim.GetClassname() == "infected")
		try { hit.wounds = HoldWound(victim); } catch (e) {}
	ShotFor(p, name).hits.append(hit);
	Counts.held++;
	return true;
}

function Projectiles::ReadWounds(ent) {
	local out = [];
	foreach (prop in WoundProps)
		out.append(NetProps.GetPropInt(ent, prop));
	return out;
}

function Projectiles::SetWounds(ent, values) {
	foreach (i, prop in WoundProps)
		if (NetProps.GetPropInt(ent, prop) != values[i])
			NetProps.SetPropInt(ent, prop, values[i]);
}

function Projectiles::HoldWound(ent) {
	local idx = ent.GetEntityIndex();
	if (!(idx in Wounds))
		return null;
	local before = Wounds[idx];
	local after = ReadWounds(ent);
	local changed = false;
	foreach (i, v in after)
		if (v != before[i])
			changed = true;
	if (!changed)
		return null;
	SetWounds(ent, before);
	return after;
}

function Projectiles::SnapWounds() {
	local seen = {};
	local ent = null;
	while ((ent = Entities.FindByClassname(ent, "infected")) != null) {
		if (!ent.IsValid())
			continue;
		local idx = ent.GetEntityIndex();
		seen[idx] <- true;
		Wounds[idx] <- ReadWounds(ent);
	}
	foreach (idx, v in clone Wounds)
		if (!(idx in seen))
			delete Wounds[idx];
}

function Projectiles::AddRay(p, end, damage, falloff) {
	if (!Active() || !Gunner(p))
		return false;
	local s = ShotFor(p);
	s.rays.append(end);
	if (!("own" in s))
		s.own <- {};
	s.own[s.rays.len() - 1] <- { damage = damage, falloff = falloff };
	return true;
}

function Projectiles::Center(ent) {
	try { return ent.GetCenter(); } catch (e) {}
	return ent.GetOrigin() + Vector(0, 0, 36);
}

function Projectiles::SegmentDistance(a, b, point) {
	local ab = b - a;
	local len2 = ab.Dot(ab);
	local t = len2 > 0.0 ? (point - a).Dot(ab) / len2 : 0.0;
	if (t < 0.0) t = 0.0;
	if (t > 1.0) t = 1.0;
	return ((a + ab * t) - point).Length();
}

function Projectiles::Launch(id) {
	if (!(id in Shots))
		return;
	local s = Shots[id];
	delete Shots[id];
	if (!s.p.IsValid() || !(s.weapon in Weapons))
		return;
	local w = Weapons[s.weapon];
	local rays = s.rays;
	if (rays.len() == 0)
		foreach (h in s.hits)
			rays.append(Center(h.victim));
	if (rays.len() == 0)
		rays.append(s.eye + s.dir * w[1]);
	if (Debug) {
		local held = "";
		foreach (h in s.hits)
			held += " " + Who(h.victim) + " " + h.damage;
		Log(s.weapon + ": " + rays.len() + " ray(s), " + s.hits.len() + " held" + held);
		foreach (end in rays)
			Line(s.eye, end, 255, 220, 0);
	}
	local up = Vector(0, 0, 1);
	local muzzle = s.eye + s.dir * MuzzleForward - up * MuzzleDrop;
	local projectiles = [];
	foreach (i, end in rays) {
		local dir = end - s.eye;
		local dist = dir.Norm();
		if (dist < 1.0) {
			dir = s.dir;
			dist = 1.0;
		}
		local own = ("own" in s) && (i in s.own) ? s.own[i] : null;
		projectiles.append({ p = s.p, weapon = s.weapon, born = Time(), pos = s.eye, dir = dir, left = w[1], end = end, held = [],
		                     pen = w[3], ignore = s.p, damage = own ? own.damage : w[0], falloff = own ? own.falloff : w[2],
		                     prescaled = own != null, travelled = 0.0, speed = Speed, explosive = false, shot = null,
		                     fx = Visual(muzzle, end, Tracer) });
	}
	foreach (h in s.hits) {
		local best = null, bestD = 1e9;
		foreach (pr in projectiles) {
			local d = SegmentDistance(s.eye, pr.end, Center(h.victim));
			if (d < bestD) {
				bestD = d;
				best = pr;
			}
		}
		if (best != null)
			best.held.append(h);
	}
	local record = { t = s.t, weapon = s.weapon, list = projectiles, parried = false, exploded = false };
	foreach (pr in projectiles) {
		if (pr.pen < pr.held.len())
			pr.pen = pr.held.len();
		pr.shot = record;
		Flying.append(pr);
	}
	LastShot[id] <- record;
	if ((id in ParryAt) && ParryAt[id] >= s.t && ParryAt[id] - s.t <= ParryWindow)
		Parry(s.p, record);
}

function Projectiles::Visual(from, to, tracer) {
	Serial++;
	local target = SpawnEntityFromTable("info_target", { targetname = "hd4l_proj_cp" + Serial, origin = to });
	local fx = SpawnEntityFromTable("info_particle_system", { origin = from, effect_name = tracer, cpoint1 = "hd4l_proj_cp" + Serial, start_active = 1 });
	if (fx != null)
		DoEntFire("!self", "Kill", "", TracerLife, null, fx);
	if (target != null)
		DoEntFire("!self", "Kill", "", TracerLife + 0.1, null, target);
	return fx;
}

function Projectiles::PayParry(p) {
	if (ParryAmmo <= 0)
		return true;
	local w = p.GetActiveWeapon();
	if (w == null || !w.IsValid())
		return false;
	local clip = NetProps.GetPropInt(w, "m_iClip1");
	if (clip >= ParryAmmo) {
		NetProps.SetPropInt(w, "m_iClip1", clip - ParryAmmo);
		return true;
	}
	local type = NetProps.GetPropInt(w, "m_iPrimaryAmmoType");
	if (type < 0)
		return false;
	local reserve = NetProps.GetPropIntArray(p, "m_iAmmo", type);
	if (reserve + clip < ParryAmmo)
		return false;
	NetProps.SetPropIntArray(p, "m_iAmmo", reserve - (ParryAmmo - clip), type);
	NetProps.SetPropInt(w, "m_iClip1", 0);
	return true;
}

function Projectiles::Parry(p, record) {
	if (record.parried || !(record.weapon in ParryWeapons))
		return false;
	local alive = [];
	foreach (pr in record.list)
		if (Flying.find(pr) != null)
			alive.append(pr);
	if (alive.len() == 0 || !PayParry(p))
		return false;
	record.parried = true;
	local tracer = "hd4l_projectile_tracer_" + NearestTracer(ParrySpeed);
	foreach (pr in alive) {
		pr.speed = ParrySpeed;
		pr.explosive = true;
		if (pr.fx != null && pr.fx.IsValid())
			DoEntFire("!self", "Kill", "", 0.0, null, pr.fx);
		pr.fx = Visual(pr.pos, pr.end, tracer);
	}
	EmitSoundOn(ParrySound, p);
	if (("HyperFeedback" in getroottable()) && ("FlashFor" in ::HyperFeedback))
		try { ::HyperFeedback.FlashFor(p, "parry"); } catch (e) {}
	Counts.parried++;
	if (Debug)
		Log("parried " + alive.len() + " projectile(s), " + format("%.2fs late", Time() - record.t));
	return true;
}

function Projectiles::NearestTracer(speed) {
	local best = TracerSpeeds[0];
	foreach (s in TracerSpeeds)
		if (fabs(s - speed) < fabs(best - speed))
			best = s;
	return best;
}

function Projectiles::ParryCheck() {
	local now = Time();
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null) {
		if (!p.IsValid() || IsPlayerABot(p) || !Gunner(p) || p.IsDead())
			continue;
		local id = p.GetPlayerUserId();
		local down = (NetProps.GetPropInt(p, "m_nButtons") & 2048) != 0;
		local was = (id in Pressed) && Pressed[id];
		Pressed[id] <- down;
		if (!down || was)
			continue;
		ParryAt[id] <- now;
		if ((id in LastShot) && now - LastShot[id].t <= ParryWindow)
			Parry(p, LastShot[id]);
	}
}

function Projectiles::Explode(pr, pos) {
	if (pr.shot == null || pr.shot.exploded)
		return;
	pr.shot.exploded = true;
	Counts.blasts++;
	Fx(ParryBlast, pos);
	try { StopSoundOn(ParrySound, pr.p); } catch (e) {}
	local speaker = SpawnEntityFromTable("info_target", { origin = pos });
	if (speaker != null) {
		EmitSoundOn(ParryBlastSound, speaker);
		DoEntFire("!self", "Kill", "", 3.0, null, speaker);
	}
	local push = SpawnEntityFromTable("env_physexplosion", { magnitude = ParryPush.tostring(), radius = ParryRadius.tostring(), spawnflags = "1", origin = pos });
	if (push != null) {
		DoEntFire("!self", "Explode", "", 0, null, push);
		DoEntFire("!self", "Kill", "", 0.5, null, push);
	}
	local victims = [];
	foreach (cls in [ "infected", "witch", "player" ]) {
		local ent = null;
		while ((ent = Entities.FindByClassnameWithin(ent, cls, pos, ParryRadius)) != null)
			if (ent.IsValid() && Flesh(ent) && ent.GetHealth() > 0)
				victims.append(ent);
	}
	foreach (ent in victims) {
		local d = (Center(ent) - pos).Length();
		local damage = ParryDamage * (1.0 - d / ParryRadius);
		if (damage <= 1.0)
			continue;
		local common = ent.GetClassname() == "infected";
		Hit(pr, ent, damage, common ? 64 : 0);
		if (!common && d <= ParryStaggerRadius && ent.GetClassname() == "player" && ent.GetZombieType() != 8 && ent.GetHealth() > 0)
			try { ent.Stagger(pos); } catch (e) {}
	}
	if (Debug)
		Log(format("blast at %.0fu: %d infected in %.0fu", pr.travelled, victims.len(), ParryRadius));
}

function Projectiles::Fx(effect, pos) {
	local fx = SpawnEntityFromTable("info_particle_system", { origin = pos, effect_name = effect, start_active = 1 });
	if (fx != null)
		DoEntFire("!self", "Kill", "", FxLife, null, fx);
}

function Projectiles::HeadHit(ent, pos) {
	foreach (name in HeadAttachments) {
		local id = 0;
		try { id = ent.LookupAttachment(name); } catch (e) { id = 0; }
		if (id > 0)
			return (ent.GetAttachmentOrigin(id) - pos).Length() <= HeadRadius;
	}
	return false;
}

function Projectiles::Flesh(ent) {
	local cls = ent.GetClassname();
	if (cls == "infected" || cls == "witch")
		return true;
	return cls == "player" && NetProps.GetPropInt(ent, "m_iTeamNum") == PROJ_TEAM_INFECTED && !ent.IsGhost();
}

function Projectiles::Hit(pr, ent, damage, type) {
	local prescaled = pr.prescaled && ("Arsenal" in getroottable()) && ("InPellet" in ::Arsenal);
	Ours[ent.GetEntityIndex()] <- Time();
	InHit = true;
	if (prescaled)
		::Arsenal.InPellet = true;
	try { ent.TakeDamage(damage, type, pr.p); } catch (e) { Log("hit failed: " + e); }
	if (prescaled)
		::Arsenal.InPellet = false;
	InHit = false;
}

function Projectiles::Step(pr, dt) {
	local step = pr.speed * dt;
	if (step > pr.left)
		step = pr.left;
	local to = pr.pos + pr.dir * step;
	for (local guard = 0; guard < 8; guard++) {
		local tr = { start = pr.pos, end = to, ignore = pr.ignore, mask = PROJ_MASK_SHOT };
		TraceLine(tr);
		if (!("hit" in tr) || !tr.hit || !("pos" in tr)) {
			pr.travelled += (to - pr.pos).Length();
			pr.left -= (to - pr.pos).Length();
			pr.pos = to;
			if (pr.left > 0.5)
				return true;
			if (pr.explosive)
				Explode(pr, pr.pos);
			return false;
		}
		local ent = ("enthit" in tr) ? tr.enthit : null;
		local world = ent == null || !ent.IsValid() || ent.GetClassname() == "worldspawn";
		pr.travelled += (tr.pos - pr.pos).Length();
		pr.left -= (tr.pos - pr.pos).Length();
		pr.pos = tr.pos;
		if (world) {
			Fx(Impact, tr.pos);
			if (pr.explosive)
				Explode(pr, tr.pos);
			return false;
		}
		local held = null;
		foreach (i, h in pr.held)
			if (h.victim == ent) {
				held = h;
				pr.held.remove(i);
				break;
			}
		if (held != null) {
			if (held.wounds != null && ent.IsValid()) {
				try { SetWounds(ent, held.wounds); } catch (e) {}
				Wounds[ent.GetEntityIndex()] <- held.wounds;
			}
			Hit(pr, ent, held.damage, held.type);
			Counts.landed++;
			if (Debug) {
				Log(format("landed %s %.0f at %.0fu after %.2fs", Who(ent), held.damage, pr.travelled, Time() - pr.born));
				Mark(tr.pos, 0, 255, 0);
			}
		} else if (Flesh(ent) || ent.GetClassname().find("prop_") == 0) {
			local damage = pr.damage * pow(pr.falloff, pr.travelled / 500.0);
			if (Flesh(ent) && HeadHit(ent, tr.pos))
				damage *= HeadMultiplier;
			Hit(pr, ent, damage, PROJ_DMG_BULLET);
			Counts.fresh++;
			if (Debug) {
				Log(format("fresh %s %.0f at %.0fu%s", Who(ent), damage, pr.travelled, damage > pr.damage ? " (head)" : ""));
				Mark(tr.pos, 60, 140, 255);
			}
		} else {
			pr.ignore = ent;
			continue;
		}
		if (Flesh(ent))
			Fx(Blood, tr.pos);
		if (pr.explosive) {
			Explode(pr, tr.pos);
			return false;
		}
		pr.pen--;
		if (pr.pen <= 0)
			return false;
		pr.ignore = ent;
	}
	return true;
}

function Projectiles::Tick(generation) {
	if (generation != Generation)
		return;
	local now = Time();
	local dt = now - LastTick;
	LastTick = now;
	if (HoldWounds && Enabled)
		try { SnapWounds(); } catch (e) { Log("wound snapshot failed: " + e); }
	if (BulletParry && Enabled)
		try { ParryCheck(); } catch (e) { Log("parry check failed: " + e); }
	if (dt > 0.0 && dt < 0.5 && Flying.len() > 0) {
		local still = [];
		foreach (pr in Flying) {
			local alive = false;
			if (pr.p.IsValid())
				try { alive = Step(pr, dt); } catch (e) { Log("step failed: " + e); }
			if (alive)
				still.append(pr);
			else {
				Counts.missed += pr.held.len();
				if (Debug)
					foreach (h in pr.held) {
						Log("missed " + Who(h.victim) + " (" + h.damage + ")");
						if (h.victim.IsValid())
							Mark(Center(h.victim), 255, 40, 40);
					}
			}
		}
		Flying = still;
	}
	DoEntFire("!self", "RunScriptCode", "::Projectiles.Tick(" + generation + ")", 0.01, null, Entities.First());
}

function Projectiles::ClientCommandEntity() {
	local ent = Entities.FindByName(null, "hd4l_proj_clientcmd");
	if (ent != null && ent.IsValid())
		return ent;
	return SpawnEntityFromTable("point_clientcommand", { targetname = "hd4l_proj_clientcmd" });
}

function Projectiles::ServerBlood() {
	if (!HideBlood)
		return;
	local value = Active() ? 0 : 1;
	foreach (cvar in BloodCvars)
		try { Convars.SetValue(cvar, value); } catch (e) { Log("no cvar " + cvar); }
}

function Projectiles::SendClientSettings() {
	ServerBlood();
	if (!HideStock)
		return;
	local ent = ClientCommandEntity();
	if (ent == null)
		return;
	local value = Active() ? "0" : "1";
	local p = null;
	while ((p = Entities.FindByClassname(p, "player")) != null)
		if (p.IsValid() && !IsPlayerABot(p))
			foreach (i, cmd in HideCommands)
				DoEntFire("!self", "Command", cmd + " " + value, 0.1 * i, p, ent);
}

function Projectiles::SetDebug(on) {
	Debug = on;
	foreach (k, v in Counts)
		Counts[k] = 0;
	Log("debug " + (on ? "on" : "off") + ", counters reset");
}

function Projectiles::Line(a, b, r, g, bl) {
	if (Debug)
		try { DebugDrawLine(a, b, r, g, bl, true, DebugTime); } catch (e) {}
}

function Projectiles::Mark(pos, r, g, bl) {
	if (!Debug)
		return;
	foreach (d in [ Vector(4, 0, 0), Vector(0, 4, 0), Vector(0, 0, 4) ])
		Line(pos - d, pos + d, r, g, bl);
}

function Projectiles::Who(ent) {
	if (ent == null || !ent.IsValid())
		return "?";
	local cls = ent.GetClassname();
	if (cls == "player")
		try { return ent.GetPlayerName(); } catch (e) {}
	return cls + "#" + ent.GetEntityIndex();
}

function Projectiles::CheckLeak(attacker, victim, type, amount) {
	if (!Active() || !Gunner(attacker) || !(type & PROJ_DMG_BULLET) || victim == null || !victim.IsValid())
		return;
	if (!(WeaponName(attacker.GetActiveWeapon()) in Weapons))
		return;
	local idx = victim.GetEntityIndex();
	if ((idx in Ours) && Ours[idx] == Time())
		return;
	Counts.leaks++;
	if (Debug)
		Log("leak: " + Who(victim) + " took " + amount + " from " + Who(attacker));
}

function Projectiles::OnGameEvent_infected_hurt(params) {
	if (!("attacker" in params) || !("entityid" in params))
		return;
	local a = null;
	try { a = GetPlayerFromUserID(params.attacker); } catch (e) {}
	CheckLeak(a, EntIndexToHScript(params.entityid), ("type" in params) ? params.type : 0, ("amount" in params) ? params.amount : 0);
}

function Projectiles::OnGameEvent_player_hurt(params) {
	if (!("attacker" in params) || !("userid" in params) || params.attacker == 0)
		return;
	local a = null, v = null;
	try { a = GetPlayerFromUserID(params.attacker); v = GetPlayerFromUserID(params.userid); } catch (e) {}
	CheckLeak(a, v, ("type" in params) ? params.type : 0, ("dmg_health" in params) ? params.dmg_health : 0);
}

function Projectiles::SetSpeed(speed) {
	Speed = speed.tofloat();
	local best = TracerSpeeds[0];
	foreach (s in TracerSpeeds)
		if (fabs(s - Speed) < fabs(best - Speed))
			best = s;
	Tracer = "hd4l_projectile_tracer_" + NearestTracer(Speed);
	SetEnabled(true);
	local at = [ 500, 1000, 2000 ];
	local times = "";
	foreach (d in at)
		times += format(", %du in %.2fs", d, d / Speed);
	Log(format("speed %.0f u/s (tracer %d)%s", Speed, best, times));
}

function Projectiles::SetEnabled(on) {
	Enabled = on;
	if (!on) {
		Flying = [];
		Shots = {};
	}
	SendClientSettings();
	Log(on ? "projectiles on" : "projectiles off");
}

function Projectiles::Report() {
	Log(format("fired %d, rays %d, held %d, landed %d, fresh %d, missed %d, flying %d, parried %d, blasts %d",
		Counts.fired, Counts.rays, Counts.held, Counts.landed, Counts.fresh, Counts.missed, Flying.len(), Counts.parried, Counts.blasts));
	Log("leaks " + Counts.leaks);
}

function Projectiles::OnGameEvent_round_start(params) {
	Generation++;
	Shots = {};
	Flying = [];
	LastShot = {};
	ParryAt = {};
	LastTick = Time();
	DoEntFire("!self", "RunScriptCode", "::Projectiles.SendClientSettings()", 1.0, null, Entities.First());
	if (ModeAllowed()) {
		Tick(Generation);
	}
}

function Projectiles::OnGameEvent_player_activate(params) {
	DoEntFire("!self", "RunScriptCode", "::Projectiles.SendClientSettings()", 1.0, null, Entities.First());
}

function Projectiles::Hook() {
	if (("GameEventCallbacks" in getroottable()) && ("hd4l_projectiles" in ::GameEventCallbacks))
		return;
	__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
	::GameEventCallbacks["hd4l_projectiles"] <- true;
}

Projectiles.Precache();
Projectiles.Hook();

if (!("HD4L_Parts" in getroottable()))
	::HD4L_Parts <- {};
::HD4L_Parts["projectiles"] <- "0.1";
