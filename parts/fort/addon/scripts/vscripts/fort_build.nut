function Fort::PieceOf(ent) {
	if (ent == null || !ent.IsValid())
		return null;
	local index = ent.GetEntityIndex();
	if ((index in Pieces) && Pieces[index].ent == ent)
		return Pieces[index];
	if ((index in Parts) && Parts[index].ent == ent) {
		local piece = Parts[index].piece;
		foreach (i, pc in Pieces)
			if (pc == piece)
				return piece;
	}
	return null;
}

function Fort::AimedPiece(p, tr) {
	local piece = PieceOf(Hit(tr));
	if (piece != null)
		return piece;
	local best = null;
	local bestAlong = BuildRange;
	foreach (index, pc in Pieces) {
		if (!pc.ent.IsValid())
			continue;
		local r = OffRay(p, pc.pos + Vector(0, 0, 16));
		local reach = pc.radius * 0.5;
		if (reach < 16.0) reach = 16.0;
		if (reach > 48.0) reach = 48.0;
		if (r.off <= reach && r.along < bestAlong) {
			best = pc;
			bestAlong = r.along;
		}
	}
	return best;
}

function Fort::AimedSupply(p) {
	local best = null;
	local bestAlong = BuildRange;
	foreach (index, s in Supplies) {
		if (!s.ent.IsValid())
			continue;
		local r = OffRay(p, s.ent.GetOrigin());
		if (r.off <= ItemPick && r.along < bestAlong) {
			best = s;
			bestAlong = r.along;
		}
	}
	return best;
}

function Fort::Structures() {
	return Pieces.len();
}

function Fort::Items() {
	foreach (index, s in clone Supplies)
		if (!s.ent.IsValid())
			delete Supplies[index];
	return Supplies.len();
}

function Fort::Spot(p, tr) {
	local pos = tr.pos;
	if (("hit" in tr) && tr.hit)
		pos = pos - p.EyeAngles().Forward() * 16.0;
	local down = { start = pos + Vector(0, 0, 8), end = pos - Vector(0, 0, FloorProbe), ignore = p };
	TraceLine(down);
	if (!("hit" in down) || !down.hit || !("pos" in down))
		return null;
	if (("enthit" in down) && down.enthit != null && down.enthit.IsValid() && down.enthit.GetClassname() == "player")
		return null;
	return down.pos;
}

function Fort::Solid(bp) {
	return bp.kind == "wall" || bp.kind == "fire" || bp.kind == "light" || bp.kind == "gun" || bp.kind == "floor" || bp.kind == "struct";
}

function Fort::CanPlace(bp, pos) {
	if (bp.kind == "item")
		return Items() < MaxItems;
	if (Structures() >= MaxPieces)
		return false;
	if (!Solid(bp) || bp.kind == "floor" || bp.kind == "struct")
		return true;
	foreach (s in Survivors()) {
		local d = s.GetOrigin() - pos;
		if (Vector(d.x, d.y, 0).Length() < Clearance && fabs(d.z) < 80.0)
			return false;
	}
	return true;
}

function Fort::HideGhost(st) {
	if (st.ghost != null && st.ghost.IsValid())
		st.ghost.Kill();
	foreach (g in st.ghostParts)
		if (g != null && g.IsValid())
			g.Kill();
	st.ghostParts = [];
	st.ghost = null;
	st.ghostModel = "";
	st.ghostColor = "";
}

function Fort::GhostEnt(model, origin, angles, color) {
	local g = SpawnEntityFromTable("prop_dynamic_override", { model = model, origin = origin, angles = AnglesText(angles),
		solid = 0, rendermode = 1, renderamt = GhostAlpha, rendercolor = color, disableshadows = 1, targetname = FORT_GHOST_NAME });
	if (g != null)
		DoEntFire("!self", "DisableCollision", "", 0, null, g);
	return g;
}

function Fort::ShowGhost(st, bp, origins, angles, ok) {
	local color = ok ? GhostOk : GhostNo;
	local want = origins.len() - 1;
	if (st.ghost == null || !st.ghost.IsValid() || st.ghostModel != bp.model || st.ghostParts.len() != want) {
		HideGhost(st);
		st.ghost = GhostEnt(bp.model, origins[0], angles, color);
		st.ghostModel = bp.model;
		st.ghostColor = color;
		if (st.ghost == null)
			return;
		Learn(bp, st.ghost);
		for (local i = 0; i < want; i++) {
			local g = GhostEnt(bp.model, origins[i + 1], angles, color);
			if (g != null)
				st.ghostParts.append(g);
		}
	}
	st.ghost.SetOrigin(origins[0]);
	st.ghost.SetAngles(angles);
	foreach (i, g in st.ghostParts)
		if (g.IsValid() && i + 1 < origins.len()) {
			g.SetOrigin(origins[i + 1]);
			g.SetAngles(angles);
		}
	if (color != st.ghostColor) {
		st.ghostColor = color;
		DoEntFire("!self", "Color", color, 0, null, st.ghost);
		foreach (g in st.ghostParts)
			if (g.IsValid())
				DoEntFire("!self", "Color", color, 0, null, g);
	}
}

function Fort::Tint(piece) {
	local color = "255 255 255";
	foreach (stage in Stages)
		if (piece.health <= piece.max * stage.at)
			color = stage.color;
	return color;
}

function Fort::SetAim(st, piece) {
	if (st.aim == piece)
		return;
	ClearAim(st);
	st.aim = piece;
	if (piece != null && piece.ent.IsValid())
		DoEntFire("!self", "Color", AimColor, 0, null, piece.ent);
}

function Fort::ClearAim(st) {
	if (st.aim != null && st.aim.ent.IsValid())
		DoEntFire("!self", "Color", Tint(st.aim), 0, null, st.aim.ent);
	st.aim = null;
}

function Fort::List(cat) {
	local out = [];
	foreach (i, bp in Blueprints)
		if (bp.cat == cat)
			out.append(i);
	return out;
}

function Fort::Pick(st) {
	local list = List(Cats[st.cat]);
	if (list.len() == 0)
		return Blueprints[0];
	return Blueprints[list[st.pick[st.cat] % list.len()]];
}

function Fort::Cycle(p, st, step) {
	if (step == 0)
		st.cat = (st.cat + 1) % Cats.len();
	else {
		local n = List(Cats[st.cat]).len();
		st.pick[st.cat] = n > 0 ? (st.pick[st.cat] + step + n) % n : 0;
	}
	try { EmitSoundOnClient(Sounds.Cycle, p); } catch (e) {}
}

function Fort::Clipped(p, st, bp, plan) {
	if (bp.kind == "item")
		return false;
	local box = ("box" in bp) ? bp.box : null;
	if (box == null && st.ghost != null && st.ghost.IsValid() && st.ghostModel == bp.model) {
		try {
			local lo = st.ghost.GetBoundingMins(), hi = st.ghost.GetBoundingMaxs();
			box = [ lo.x, lo.y, lo.z, hi.x, hi.y, hi.z ];
		} catch (e) {}
	}
	if (box == null)
		return false;
	local key = bp.name + "@" + AnglesText(plan.angles);
	foreach (o in plan.origins)
		key += "@" + o.x.tointeger() + ":" + o.y.tointeger() + ":" + o.z.tointeger();
	if (key == st.clipKey)
		return st.clipBlocked;
	st.clipKey = key;
	st.clipBlocked = Blocked(p, box, plan.origins, plan.angles, Solid(bp), plan.grounded || plan.supports.len() > 0, ClipWorld);
	return st.clipBlocked;
}

function Fort::NoShove(p, on) {
	try { NetProps.SetPropFloat(p, "m_flNextShoveTime", on ? Time() + 3600.0 : Time()); } catch (e) {}
}

function Fort::Toggle(p, st) {
	st.buildMode = !st.buildMode;
	if (st.buildMode) {
		local inv = {};
		try { GetInvTable(p, inv); } catch (e) {}
		if (("slot1" in inv) && inv.slot1 != null && inv.slot1.IsValid())
			inv.slot1.Kill();
		NoShove(p, true);
	} else {
		NoShove(p, false);
		HideGhost(st);
		ClearAim(st);
		Unlook(st);
		Arm2(p);
	}
	try { EmitSoundOnClient(Sounds.Cycle, p); } catch (e) {}
}

function Fort::BuildTick(p, st, buttons, pressed) {
	local now = Time();
	if (pressed & ListKey)
		Cycle(p, st, 0);
	if (pressed & NextKey) {
		st.nextAt = now;
		st.nextUsed = false;
	}
	if (pressed & PrevKey) {
		st.prevAt = now;
		st.prevUsed = false;
	}
	local nextDown = (NextKey in st.down) && st.down[NextKey] >= 0;
	local prevDown = (PrevKey in st.down) && st.down[PrevKey] >= 0;
	if (!nextDown && st.nextWas && !st.nextUsed)
		Cycle(p, st, 1);
	if (!prevDown && st.prevWas && !st.prevUsed)
		Cycle(p, st, -1);
	st.nextWas = nextDown;
	st.prevWas = prevDown;
	local repairing = nextDown && now - st.nextAt >= TapTime;
	local taking = prevDown && now - st.prevAt >= TapTime && !st.prevUsed;
	local hands = null;
	try { hands = p.GetActiveWeapon(); } catch (e) {}
	if (hands != null && hands.IsValid())
		try {
			NetProps.SetPropFloat(hands, "m_flNextPrimaryAttack", now + HandsLock);
			NetProps.SetPropFloat(hands, "m_flNextSecondaryAttack", now + HandsLock);
		} catch (e) {}
	try {
		if (now >= NetProps.GetPropFloat(p, "m_flNextShoveTime") - 60.0)
			NoShove(p, true);
	} catch (e) {}

	local tr = Aim(p, BuildRange);
	local piece = AimedPiece(p, tr);
	if (piece != null) {
		Unlook(st);
		SetAim(st, piece);
		st.value = (piece.bp.cost * Refund * piece.health / piece.max + 0.5).tointeger();
		if (taking) {
			st.prevUsed = true;
			HideGhost(st);
			Remove(p, st, piece);
			return;
		}
		if (repairing) {
			st.nextUsed = true;
			HideGhost(st);
			Repair(p, st, piece, now);
			return;
		}
	} else {
		ClearAim(st);
		local supply = AimedSupply(p);
		if (supply != null) {
			Look(st, supply.ent, supply.bp.cost);
			if (taking) {
				st.prevUsed = true;
				HideGhost(st);
				TakeSupply(p, st, supply);
				return;
			}
		} else
			Unlook(st);
	}

	local bp = Pick(st);
	local plan = Plan(p, st, bp, tr, piece);
	st.spotOk = plan != null && !("taken" in plan) && CanPlace(bp, plan.pos) && !Clipped(p, st, bp, plan);
	local ok = st.spotOk && Scrap >= bp.cost;
	if (plan != null)
		ShowGhost(st, bp, plan.origins, plan.angles, ok);
	else
		ShowGhost(st, bp, [ tr.pos ], QAngle(0, GridYaw(p, st), 0), false);
	if (!(pressed & PlaceKey))
		return;
	if (now - st.placedAt < PlaceGap)
		return;
	if (!ok) {
		EmitSoundOn(Sounds.Deny, p);
		return;
	}
	st.placedAt = now;
	Place(p, bp, plan);
}
