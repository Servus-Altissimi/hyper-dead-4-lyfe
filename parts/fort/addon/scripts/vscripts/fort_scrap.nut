function Fort::Salvageable(ent) {
	if (ent == null || !ent.IsValid() || !(ent.GetClassname() in SalvageClasses))
		return false;
	if (ent.GetHealth() < 0)
		return false;
	local name = "";
	try { name = ent.GetName(); } catch (e) {}
	if (name != "")
		return false;
	try { if (ent.GetMoveParent() != null) return false; } catch (e) {}
	local model = "";
	try { model = ent.GetModelName().tolower(); } catch (e) {}
	foreach (hint in KeepHints)
		if (model.find(hint) != null)
			return false;
	local cls = ent.GetClassname();
	if (cls == "prop_dynamic" || cls == "prop_dynamic_override") {
		try {
			local size = ent.GetBoundingMaxs() - ent.GetBoundingMins();
			if (size.x > BreakMax || size.y > BreakMax || size.z > BreakMax)
				return false;
		} catch (e) {}
	}
	return true;
}

function Fort::IsExplosive(ent) {
	if (ent.GetClassname() == "prop_fuel_barrel")
		return true;
	local model = "";
	try { model = ent.GetModelName().tolower(); } catch (e) {}
	foreach (hint in Explosive)
		if (model.find(hint) != null)
			return true;
	return false;
}

function Fort::Free() {
	local mode = "";
	try { mode = Director.GetGameMode(); } catch (e) {}
	return mode == "hd4lfreebuild";
}

function Fort::ScrapOf(ent) {
	local scrap = -1;
	try {
		local lo = ent.GetBoundingMins();
		local hi = ent.GetBoundingMaxs();
		local volume = fabs((hi.x - lo.x) * (hi.y - lo.y) * (hi.z - lo.z));
		if (volume > 1.0)
			scrap = (VolumeScale * pow(volume, VolumePower) + 0.5).tointeger();
	} catch (e) {}
	if (scrap < 0) {
		scrap = ScrapFallback;
		local model = "";
		try { model = ent.GetModelName().tolower(); } catch (e) {}
		foreach (pair in ScrapByModel)
			if (model.find(pair[0]) != null) {
				scrap = pair[1];
				break;
			}
	}
	if (scrap < ScrapMin) scrap = ScrapMin;
	if (scrap > ScrapMax) scrap = ScrapMax;
	local index = ent.GetEntityIndex();
	if ((index in Loot) && Loot[index].ent == ent)
		return Loot[index].value;
	return scrap;
}

function Fort::Target(p) {
	local tr = Aim(p, HammerRange);
	local ent = Hit(tr);
	if (Salvageable(ent))
		return ent;
	local best = null, off = 24.0;
	foreach (i, l in Loot) {
		if (l.ent == null || !l.ent.IsValid())
			continue;
		local r = OffRay(p, l.ent.GetOrigin());
		if (r.along > 0.0 && r.along <= HammerRange && r.off < off) {
			best = l.ent;
			off = r.off;
		}
	}
	return best;
}

function Fort::Worth(ent) {
	local index = ent.GetEntityIndex();
	if ((index in Dents) && Dents[index].ent == ent)
		return Dents[index].left;
	return ScrapOf(ent);
}

function Fort::HammerTick(p, st) {
	local ent = Target(p);
	if (ent != null)
		Look(st, ent, Worth(ent));
	else
		Unlook(st);
	local w = null;
	try { w = p.GetActiveWeapon(); } catch (e) {}
	if (w == null || !w.IsValid() || w.GetClassname() != "weapon_melee") {
		st.swingWeapon = null;
		return;
	}
	local next = 0.0;
	try { next = NetProps.GetPropFloat(w, "m_flNextPrimaryAttack"); } catch (e) { return; }
	local shoving = false;
	try { shoving = (NetProps.GetPropInt(p, "m_nButtons") & FORT_IN_ATTACK2) != 0; } catch (e) {}
	if (st.swingWeapon == w && next > st.swingNext + 0.05 && !shoving)
		Swing(p, st);
	st.swingWeapon = w;
	st.swingNext = next;
}

function Fort::Swing(p, st) {
	local now = Time();
	if (now - st.swungAt < SwingGap)
		return;
	st.swungAt = now;
	DoEntFire("!self", "RunScriptCode", "::Fort.Whack(" + p.GetPlayerUserId() + ")", HammerDelay, null, Entities.First());
}

function Fort::OnGameEvent_break_prop(params) {
	Broke(params);
}

function Fort::OnGameEvent_break_breakable(params) {
	Broke(params);
}

function Fort::Broke(params) {
	if (!InSurvival() || !Building() || !("entindex" in params) || !("userid" in params))
		return;
	local p = null;
	try { p = GetPlayerFromUserID(params.userid); } catch (e) {}
	if (p == null || !p.IsValid() || NetProps.GetPropInt(p, "m_iTeamNum") != 2)
		return;
	local index = params.entindex;
	local ent = null;
	try { ent = EntIndexToHScript(index); } catch (e) {}
	local worth = -1;
	if ((index in Dents) && (ent == null || Dents[index].ent == ent)) {
		if (Dents[index].broken)
			return;
		worth = Dents[index].left;
		Dents[index].broken = true;
	} else if (index in Loot)
		worth = Loot[index].value;
	else if (ent != null && ent.IsValid() && Salvageable(ent))
		worth = ScrapOf(ent);
	if (index in Loot)
		delete Loot[index];
	if (worth <= 0)
		return;
	if (!(index in Dents) || Dents[index].ent != ent)
		Dents[index] <- { ent = ent, left = 0, hits = 0, broken = true };
	AddScrap(worth);
	Mark(p, "kill");
}

function Fort::OnGameEvent_weapon_fire(params) {
	if (!InSurvival() || !Building() || !("userid" in params))
		return;
	local p = null;
	try { p = GetPlayerFromUserID(params.userid); } catch (e) { return; }
	if (p == null || !p.IsValid() || IsPlayerABot(p))
		return;
	local st = StateOf(p);
	if (st.buildMode)
		return;
	local w = null;
	try { w = p.GetActiveWeapon(); } catch (e) {}
	if ((("weapon" in params) && params.weapon == "melee") || (w != null && w.IsValid() && w.GetClassname() == "weapon_melee"))
		Swing(p, st);
}

function Fort::Whack(userid) {
	local p = null;
	try { p = GetPlayerFromUserID(userid); } catch (e) {}
	if (p == null || !p.IsValid() || p.IsDead() || !Building())
		return;
	local ent = Target(p);
	if (ent == null)
		return;
	local index = ent.GetEntityIndex();
	if (!(index in Dents) || Dents[index].ent != ent) {
		local scrap = ScrapOf(ent);
		local hits = ((scrap + ScrapPerHit - 1) / ScrapPerHit).tointeger();
		Dents[index] <- { ent = ent, left = scrap, hits = hits < 1 ? 1 : (hits > MaxHits ? MaxHits : hits), broken = false };
	}
	local dent = Dents[index];
	if (dent.broken)
		return;
	local pos = ent.GetOrigin();
	try { pos = ent.GetCenter(); } catch (e) {}
	local pay = dent.hits <= 1 ? dent.left : (dent.left / dent.hits).tointeger();
	dent.left -= pay;
	dent.hits--;
	AddScrap(pay);
	if (dent.hits > 0) {
		local push = p.EyeAngles().Forward() * Knock + Vector(0, 0, Knock * 0.4);
		local cls = ent.GetClassname();
		if (cls.find("prop_physics") == 0 || cls == "prop_car_alarm")
			try { ent.ApplyAbsVelocityImpulse(push); } catch (e) {}
		Particle(Dust, pos, 1.0);
		Sound(Sounds.Tick, ent);
		Mark(p, "hit");
		return;
	}
	dent.broken = true;
	RemoveChildren(ent);
	if (index in Loot)
		delete Loot[index];
	if (index in Pieces)
		return;
	if (IsExplosive(ent))
		DoEntFire("!self", "Kill", "", 0, null, ent);
	else {
		DoEntFire("!self", "Break", "", 0, null, ent);
		DoEntFire("!self", "Kill", "", 0.1, null, ent);
	}
	Particle(Dust, pos, 1.5);
	SoundAt(Sounds.Salvaged, pos);
	Mark(p, "kill");
}

function Fort::RemoveChildren(ent) {
	local found = [];
	foreach (cls in Children) {
		local c = null;
		while ((c = Entities.FindByClassnameWithin(c, cls, ent.GetOrigin(), 400.0)) != null) {
			local parent = null;
			try { parent = c.GetMoveParent(); } catch (e) {}
			if (parent == ent)
				found.append(c);
		}
	}
	foreach (c in found)
		if (c.IsValid())
			c.Kill();
}

function Fort::LootName(cls) {
	local name = cls;
	if (name.len() > 7 && name.slice(0, 7) == "weapon_")
		name = name.slice(7);
	if (name.len() > 6 && name.slice(name.len() - 6) == "_spawn")
		name = name.slice(0, name.len() - 6);
	return name;
}

function Fort::LootWorth(ent) {
	local name = LootName(ent.GetClassname());
	local value = (name in LootValue) ? LootValue[name] : LootDefault;
	local count = 1;
	try { count = NetProps.GetPropInt(ent, "m_itemCount"); } catch (e) { count = 1; }
	if (count < 1 || count > 16)
		count = 1;
	return value * count;
}

function Fort::Lootable(ent) {
	if (ent == null || !ent.IsValid())
		return false;
	local cls = ent.GetClassname();
	if (cls in LootKeep)
		return false;
	if (!(cls.len() > 7 && cls.slice(0, 7) == "weapon_") && !(cls.len() > 8 && cls.slice(0, 8) == "upgrade_"))
		return false;
	local name = "";
	try { name = ent.GetName(); } catch (e) {}
	if (name == FORT_ITEM_NAME)
		return false;
	local owner = null;
	try { owner = NetProps.GetPropEntity(ent, "m_hOwner"); } catch (e) {}
	local index = ent.GetEntityIndex();
	if (owner != null) {
		Held[index] <- ent;
		return false;
	}
	if ((index in Held) && Held[index] == ent)
		return false;
	if ((LootName(cls) in Carryables) && Time() - StartedAt > CarryFirst)
		return false;
	try { if (ent.GetMoveParent() != null) return false; } catch (e) {}
	return true;
}

function Fort::QuietAlarms() {
	local ent = null;
	while ((ent = Entities.FindByClassname(ent, "prop_car_alarm")) != null) {
		local index = ent.GetEntityIndex();
		if ((index in Quiet) && Quiet[index] == ent)
			continue;
		Quiet[index] <- ent;
		DoEntFire("!self", "Disable", "", 0, null, ent);
	}
}

function Fort::ConvertLoot() {
	local found = [];
	foreach (pattern in [ "weapon_*", "upgrade_*" ]) {
		local ent = null;
		while ((ent = Entities.FindByClassname(ent, pattern)) != null)
			if (Lootable(ent))
				found.append(ent);
	}
	local placed = [];
	foreach (ent in found) {
		if (!ent.IsValid())
			continue;
		local pos = ent.GetOrigin();
		local name = LootName(ent.GetClassname());
		local value = LootWorth(ent);
		ent.Kill();
		SpawnLoot(pos, name, value, placed);
	}
}

function Fort::SpawnLoot(pos, name, value, placed = null) {
	local kind = (name in LootKind) ? LootKind[name] : LootOther;
	local models = LootProps[kind];
	local model = models[RandomInt(0, models.len() - 1)];
	local stack = 0;
	if (placed != null)
		foreach (at in placed)
			if (Vector(at.x - pos.x, at.y - pos.y, 0).Length() < LootSpread)
				stack++;
	local drop = pos + Vector(0, 0, LootDrop + LootStack * stack);
	local angles = "0 " + RandomInt(0, 359) + " 0";
	local ent = SpawnEntityFromTable("prop_physics_override", { model = model, origin = drop, angles = angles });
	if (ent == null)
		return null;
	if (placed != null)
		placed.append(pos);
	Loot[ent.GetEntityIndex()] <- { ent = ent, value = value, kind = kind, model = model, pos = drop, angles = angles };
	DoEntFire("!self", "RunScriptCode", "::Fort.LootRecheck(" + ent.GetEntityIndex() + ")", 0.1, null, Entities.First());
	return ent;
}

function Fort::LootRecheck(index) {
	if (!(index in Loot))
		return;
	local loot = Loot[index];
	if (loot.ent != null && loot.ent.IsValid())
		return;
	delete Loot[index];
	local ent = SpawnEntityFromTable("prop_dynamic_override", { model = loot.model, origin = loot.pos - Vector(0, 0, LootDrop),
		angles = loot.angles, solid = 6 });
	if (ent == null)
		return;
	loot.ent = ent;
	Loot[ent.GetEntityIndex()] <- loot;
}

function Fort::LootTick(now) {
	foreach (index, loot in clone Loot)
		if (!loot.ent.IsValid())
			delete Loot[index];
	foreach (index, ent in clone Held)
		if (ent == null || !ent.IsValid())
			delete Held[index];
}

function Fort::OnGameEvent_weapon_drop(params) {
	if (Phase == "off" || !("propid" in params))
		return;
	local ent = EntIndexToHScript(params.propid);
	if (ent != null && ent.IsValid())
		Held[params.propid] <- ent;
}
