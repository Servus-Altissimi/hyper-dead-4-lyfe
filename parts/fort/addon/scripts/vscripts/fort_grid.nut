function Fort::AnglesText(a) {
	return a.x + " " + a.y + " " + a.z;
}

function Fort::Basis(a) {
	local r = 0.0174533;
	local sp = sin(a.x * r), cp = cos(a.x * r);
	local sy = sin(a.y * r), cy = cos(a.y * r);
	local sr = sin(a.z * r), cr = cos(a.z * r);
	local right = Vector(-sr * sp * cy + cr * sy, -sr * sp * sy - cr * cy, -sr * cp);
	return { f = Vector(cp * cy, cp * sy, -sp), l = right * -1.0, u = Vector(cr * sp * cy + sr * sy, cr * sp * sy - sr * cy, cr * cp) };
}

function Fort::Local(b, v) {
	return b.f * v.x + b.l * v.y + b.u * v.z;
}

function Fort::Facing(p, st = null) {
	local face = p.EyeAngles().y;
	local yaw = ((face / 90.0 + (face < 0.0 ? -0.5 : 0.5)).tointeger() * 90) % 360;
	if (yaw < 0)
		yaw += 360;
	if (st != null) {
		if (st.faceYaw != null) {
			local off = face - st.faceYaw;
			while (off > 180.0) off -= 360.0;
			while (off < -180.0) off += 360.0;
			if (fabs(off) <= FaceHold)
				yaw = st.faceYaw;
		}
		st.faceYaw = yaw;
	}
	local dirs = { [0] = Vector(1, 0, 0), [90] = Vector(0, 1, 0), [180] = Vector(-1, 0, 0), [270] = Vector(0, -1, 0) };
	return { yaw = yaw.tofloat(), dir = dirs[yaw] };
}

function Fort::GridYaw(p, st) {
	local face = p.EyeAngles().y;
	local step = PropStep.tofloat();
	local yaw = ((face / step + (face < 0.0 ? -0.5 : 0.5)).tointeger() * PropStep) % 360;
	if (yaw < 0)
		yaw += 360;
	if (st.propYaw != null) {
		local off = face - st.propYaw;
		while (off > 180.0) off -= 360.0;
		while (off < -180.0) off += 360.0;
		if (fabs(off) <= PropHold)
			yaw = st.propYaw;
	}
	st.propYaw = yaw;
	return yaw.tofloat();
}

function Fort::Surface(p, x, y) {
	local eye = p.EyePosition();
	local down = { start = Vector(x, y, eye.z + BuildAbove), end = Vector(x, y, eye.z - BuildBelow), ignore = p };
	TraceLine(down);
	if (("startsolid" in down) && down.startsolid)
		return null;
	if (!("hit" in down) || !down.hit || !("pos" in down))
		return null;
	local under = ("enthit" in down) ? down.enthit : null;
	if (under != null && under.IsValid() && under.GetClassname() == "player")
		return null;
	local piece = PieceOf(under);
	return { z = down.pos.z, under = piece, grounded = piece == null };
}

function Fort::Plan(p, st, bp, tr, piece) {
	if (bp.kind == "struct")
		return StructPlan(p, st, bp, tr, piece);
	local g = GridSpot(p, st, bp, tr, piece);
	if (g == null)
		return null;
	local key = bp.kind + ":" + g.pos.x.tointeger() + ":" + g.pos.y.tointeger() + ":" + (g.pos.z / 8.0).tointeger();
	return { origins = Origins(bp, g.pos, g.yaw), angles = QAngle(0, g.yaw, 0), pos = g.pos, yaw = g.yaw,
	         spot = bp.kind + ":" + g.pos.x.tointeger() + ":" + g.pos.y.tointeger(), supports = g.support != null ? [ g.support ] : [], grounded = g.support == null, key = key, slot = null };
}

function Fort::SlotZ(z) {
	return (z / 8.0 + (z < 0.0 ? -0.5 : 0.5)).tointeger();
}

function Fort::WallKey(x, y, z) {
	return "W:" + (x + 0.5).tointeger() + ":" + (y + 0.5).tointeger() + ":" + SlotZ(z);
}

function Fort::FloorKey(ix, iy, z) {
	return "F:" + ix + ":" + iy + ":" + SlotZ(z);
}

function Fort::Slotted(key) {
	if (!(key in Slots))
		return null;
	local pc = Slots[key];
	foreach (i, q in Pieces)
		if (q == pc)
			return pc;
	delete Slots[key];
	return null;
}

function Fort::StructPlan(p, st, bp, tr, piece) {
	local face = Facing(p, st);
	local d = face.dir;
	local yaw = face.yaw;
	local sc = StructCell, sh = StructHeight;
	local shape = bp.shape;
	local feet = p.GetOrigin();
	local pitch = p.EyeAngles().x;

	local ox = floor(feet.x / sc).tointeger(), oy = floor(feet.y / sc).tointeger();
	if (st.cellX != null && feet.x >= st.cellX * sc - CellHold && feet.x <= (st.cellX + 1) * sc + CellHold
	    && feet.y >= st.cellY * sc - CellHold && feet.y <= (st.cellY + 1) * sc + CellHold) {
		ox = st.cellX;
		oy = st.cellY;
	}
	st.cellX = ox;
	st.cellY = oy;
	local dx = d.x.tointeger(), dy = d.y.tointeger();
	local down = DownPitch - (st.lastOwn ? LevelHold : 0.0);
	local own = (shape == "floor" || shape == "roof") && pitch >= down;
	if (shape == "floor" || shape == "roof")
		st.lastOwn = own;
	local ix = own ? ox : ox + dx, iy = own ? oy : oy + dy;
	local cx = (ix + 0.5) * sc, cy = (iy + 0.5) * sc;
	local spot = Vector(cx, cy, 0);
	local wa = 0, wb = 0;
	if (shape == "wall") {
		local sign = dx != 0 ? dx : dy;
		local q = (dx != 0 ? feet.x : feet.y) * sign + WallGap;
		local at = ((floor(q / sc).tointeger() + 1) * sign).tofloat() * sc;
		spot = dx != 0 ? Vector(at, (oy + 0.5) * sc, 0) : Vector((ox + 0.5) * sc, at, 0);
		wa = floor(at / sc + 0.5).tointeger();
		wb = wa - 1;
	}

	local z = feet.z, under = Standing(p), grounded = false;
	local surf = Surface(p, spot.x, spot.y);
	if (under != null && ("shape" in under.bp)) {
		z = under.pos.z;
		if (under.bp.shape == "wall" || (under.bp.shape == "stairs" && feet.z > z + sh * 0.5))
			z += sh;
	} else if (surf != null && fabs(surf.z - feet.z) <= FloorDrop) {
		z = surf.z;
		under = surf.under;
		grounded = surf.grounded;
	}
	local level = 0;
	if (!own && shape != "stairs") {
		foreach (i, up in LevelPitch)
			if (pitch <= up + (st.lastLevel > i ? LevelHold : -LevelHold))
				level++;
		st.lastLevel = level;
	}
	if (shape == "roof")
		level++;
	local Z = z + level * sh;
	if (level > 0) {
		under = null;
		grounded = false;
	}

	local tile = !("normal" in bp) || bp.normal == "z";
	local box = ("box" in bp) ? bp.box : [ 0, 0, 0, 0, 0, 0 ];
	local mid = Vector((box[0] + box[3]) * 0.5, (box[1] + box[4]) * 0.5, (box[2] + box[5]) * 0.5);
	local thick = tile ? box[5] - box[2] : box[3] - box[0];
	local supports = [];
	if (under != null)
		supports.append(under);
	local plan = { yaw = yaw, grounded = grounded, supports = supports, key = "", slot = null, radius = sc * 0.5 };
	local key = "";
	local angles = null;
	local centres = [];
	if (shape == "wall" && ("door" in bp)) {
		key = WallKey(spot.x, spot.y, Z);
		angles = QAngle(0, yaw, 0);
		local left = Basis(angles).l;
		local foot = Vector(spot.x, spot.y, Z);
		local half = DoorWidth * 0.5;
		centres.append(foot - left * half + Vector(0, 0, 54.6));
		local parts = [];
		foreach (lat in [ -sc * 0.5 + 11.5, -half - 11.5, half + 11.5, sc * 0.5 - 11.5 ])
			parts.append({ model = Board, origin = foot + left * lat + Vector(0, 0, sh * 0.5), angles = angles });
		parts.append({ model = Board, origin = foot + Vector(0, 0, 119.5), angles = QAngle(0, yaw, 90) });
		plan.parts <- parts;
		local below = Slotted(WallKey(spot.x, spot.y, Z - sh));
		if (below != null)
			supports.append(below);
		plan.pos <- Vector(spot.x, spot.y, Z);
		plan.top <- Z + sh;
		plan.origins <- centres;
		plan.angles <- angles;
		if (Slotted(key) != null)
			plan.taken <- true;
		plan.key = key;
		plan.slot = key;
		return plan;
	} else if (shape == "wall") {
		key = WallKey(spot.x, spot.y, Z);
		angles = tile ? QAngle(90, yaw, 0) : QAngle(0, yaw, 0);
		centres.append(Vector(spot.x, spot.y, Z + sh * 0.5));
		local below = Slotted(WallKey(spot.x, spot.y, Z - sh));
		if (below != null)
			supports.append(below);
		local fa = dx != 0 ? FloorKey(wa, oy, Z) : FloorKey(ox, wa, Z);
		local fb = dx != 0 ? FloorKey(wb, oy, Z) : FloorKey(ox, wb, Z);
		foreach (k in [ fa, fb ]) {
			local fl = Slotted(k);
			if (fl != null)
				supports.append(fl);
		}
		plan.pos <- Vector(spot.x, spot.y, Z);
		plan.top <- Z + sh;
	} else if (shape == "floor" || shape == "roof") {
		key = FloorKey(ix, iy, Z);
		angles = tile ? QAngle(0, yaw, 0) : QAngle(90, yaw, 0);
		centres.append(Vector(cx, cy, Z - thick * 0.5));
		foreach (e in [ Vector(1, 0, 0), Vector(-1, 0, 0), Vector(0, 1, 0), Vector(0, -1, 0) ]) {
			local wall = Slotted(WallKey(cx + e.x * sc * 0.5, cy + e.y * sc * 0.5, Z - sh));
			if (wall != null)
				supports.append(wall);
			local next = Slotted(FloorKey(ix + e.x.tointeger(), iy + e.y.tointeger(), Z));
			if (next != null)
				supports.append(next);
		}
		plan.pos <- Vector(cx, cy, Z);
		plan.top <- Z;
	} else {
		key = "S:" + ix + ":" + iy + ":" + SlotZ(Z);
		angles = tile ? QAngle(-StairPitch, yaw, 0) : QAngle(StairPitch, yaw, 0);
		local r = 0.7071;
		local slope = Vector(d.x * r, d.y * r, r);
		local up = Vector(-d.x * r, -d.y * r, r);
		local foot = Vector(cx - d.x * sc * 0.5, cy - d.y * sc * 0.5, Z);
		local run = sqrt(sc * sc + sh * sh);
		local half = (tile ? box[3] - box[0] : box[5] - box[2]) * 0.5;
		centres.append(foot + slope * half - up * (thick * 0.5));
		centres.append(foot + slope * (run - half) - up * (thick * 0.5 + 0.5));
		foreach (k in [ FloorKey(ix, iy, Z), FloorKey(ix + dx, iy + dy, Z + sh) ]) {
			local fl = Slotted(k);
			if (fl != null && supports.find(fl) == null)
				supports.append(fl);
		}
		plan.pos <- Vector(cx, cy, Z);
		plan.top <- Z + sh;
	}
	local b = Basis(angles);
	plan.origins <- [];
	foreach (c in centres)
		plan.origins.append(c - Local(b, mid));
	plan.angles <- angles;
	if (Slotted(key) != null)
		plan.taken <- true;
	plan.key = key;
	plan.slot = key;
	return plan;
}

function Fort::Blocked(p, box, origins, angles, solid, low, world) {
	local b = Basis(angles);
	local axes = [ b.f, b.l, b.u ];
	local lo = [ box[0], box[1], box[2] ], hi = [ box[3], box[4], box[5] ];
	foreach (o in origins) {
		if (solid) {
			local centre = o + Local(b, Vector((lo[0] + hi[0]) * 0.5, (lo[1] + hi[1]) * 0.5, (lo[2] + hi[2]) * 0.5));
			foreach (s in Survivors()) {
				local v = s.GetOrigin() + Vector(0, 0, 45) - centre;
				local apart = false;
				foreach (i, ax in axes) {
					local reach = (hi[i] - lo[i]) * 0.5 + 16.0 * (fabs(ax.x) + fabs(ax.y)) + 27.0 * fabs(ax.z) - 2.0;
					if (fabs(v.Dot(ax)) > reach) {
						apart = true;
						break;
					}
				}
				if (!apart)
					return true;
			}
		}
		if (!world)
			continue;
		local a = [], z = [];
		for (local i = 0; i < 3; i++) {
			local m = (lo[i] + hi[i]) * 0.5;
			local h = (hi[i] - lo[i]) * 0.5 - ClipMargin;
			if (h < 0.0)
				h = 0.0;
			a.append(m - h);
			z.append(m + h);
		}
		local corners = [];
		for (local c = 0; c < 8; c++)
			corners.append(o + Local(b, Vector((c & 1) ? z[0] : a[0], (c & 2) ? z[1] : a[1], (c & 4) ? z[2] : a[2])));
		if (low) {
			local floorZ = corners[0].z, topZ = corners[0].z;
			foreach (c in corners) {
				if (c.z < floorZ) floorZ = c.z;
				if (c.z > topZ) topZ = c.z;
			}
			local lift = floorZ + ClipGround < topZ ? floorZ + ClipGround : topZ;
			foreach (i, c in corners)
				if (c.z < lift)
					corners[i] = Vector(c.x, c.y, lift);
		}
		local lines = [ [0, 1], [2, 3], [4, 5], [6, 7], [0, 2], [1, 3], [4, 6], [5, 7], [0, 4], [1, 5], [2, 6], [3, 7],
		                [0, 7], [1, 6], [2, 5], [3, 4] ];
		foreach (l in lines) {
			local from = corners[l[0]], to = corners[l[1]];
			if ((to - from).Length() < 1.0)
				continue;
			local dir = to - from;
			dir.Norm();
			for (local k = 0; k < 6; k++) {
				local tr = { start = from, end = to, ignore = p, clip = true };
				TraceLine(tr);
				if (!("hit" in tr) || !tr.hit)
					break;
				local pc = ("enthit" in tr) ? PieceOf(tr.enthit) : null;
				if (pc == null || pc.bp.kind != "struct")
					return true;
				from = (("pos" in tr) ? tr.pos : from) + dir * 2.0;
				if ((to - from).Dot(dir) <= 0.0)
					break;
			}
		}
	}
	return false;
}

function Fort::Dims(bp) {
	if ("size" in bp)
		return { sx = bp.size[0], sy = bp.size[1] };
	if (bp.model in Sizes)
		return Sizes[bp.model];
	return { sx = Cell, sy = Cell };
}

function Fort::Learn(bp, ent) {
	if (bp.model in Sizes || bp.kind == "struct")
		return;
	try {
		local lo = ent.GetBoundingMins();
		local hi = ent.GetBoundingMaxs();
		if (hi.x - lo.x > 0.5 && hi.y - lo.y > 0.5)
			Sizes[bp.model] <- { sx = hi.x - lo.x, sy = hi.y - lo.y, cx = (hi.x + lo.x) * 0.5, cy = (hi.y + lo.y) * 0.5, known = true };
	} catch (e) {}
}

function Fort::Origins(bp, pos, yaw) {
	if (!("parts" in bp))
		return [ Anchor(bp, pos, yaw) ];
	local r = yaw * 0.0174533;
	local out = [];
	foreach (part in bp.parts) {
		local at = pos + Vector(part[0] * cos(r) - part[1] * sin(r), part[0] * sin(r) + part[1] * cos(r), 0);
		out.append(Anchor(bp, at, yaw));
	}
	return out;
}

function Fort::Cells(size) {
	local n = (size / Cell + 0.5).tointeger();
	return n < 1 ? 1 : (n > MaxCells ? MaxCells : n);
}

function Fort::Snap(v) {
	return floor(v / Cell).tointeger();
}

function Fort::GridSpot(p, st, bp, tr, piece) {
	local yaw = GridYaw(p, st);
	local d = Dims(bp);
	local sx = d.sx, sy = d.sy;
	if ((yaw.tointeger() / 90) % 2 == 1) {
		local t = sx; sx = sy; sy = t;
	}
	local w = Cells(sx), h = Cells(sy);
	if (yaw.tointeger() % 90 != 0) {
		w = Cells((d.sx + d.sy) * 0.7071);
		h = w;
	}
	local aim = tr.pos;
	if (piece != null && Hit(tr) == piece.ent && aim.z < piece.top - SideBelow) {
		local back = p.EyeAngles().Forward();
		back = Vector(back.x, back.y, 0);
		if (back.Length() > 0.01)
			back.Norm();
		aim = aim - back * (Cell * 0.5);
	}
	local feet = p.GetOrigin();
	local reach = bp.kind == "floor" ? FloorReach : BuildRange;
	local out = Vector(aim.x - feet.x, aim.y - feet.y, 0);
	if (out.Length() > reach)
		aim = Vector(feet.x, feet.y, aim.z) + out * (reach / out.Length());
	local x0 = Snap(aim.x) - (w - 1) / 2;
	local y0 = Snap(aim.y) - (h - 1) / 2;
	local cx = (x0 + w * 0.5) * Cell;
	local cy = (y0 + h * 0.5) * Cell;
	local surf = Surface(p, cx, cy);
	if (surf == null)
		return null;
	local z = surf.z;
	local support = surf.under;
	if (bp.kind == "floor" && z < feet.z - FloorDrop) {
		z = feet.z - 1.0;
		support = Standing(p);
	}
	return { pos = Vector(cx, cy, z), yaw = yaw, support = support };
}

function Fort::Anchor(bp, pos, yaw) {
	local ox = 0.0, oy = 0.0;
	if (bp.model in Sizes) {
		ox = Sizes[bp.model].cx; oy = Sizes[bp.model].cy;
	} else if ("offset" in bp) {
		ox = bp.offset[0]; oy = bp.offset[1];
	}
	if (ox == 0.0 && oy == 0.0)
		return pos;
	local r = yaw * 0.0174533;
	return pos - Vector(ox * cos(r) - oy * sin(r), ox * sin(r) + oy * cos(r), 0);
}

function Fort::Standing(p) {
	local ground = null;
	try { ground = NetProps.GetPropEntity(p, "m_hGroundEntity"); } catch (e) {}
	local piece = PieceOf(ground);
	if (piece != null)
		return piece;
	local feet = p.GetOrigin();
	local tr = { start = feet + Vector(0, 0, 4), end = feet - Vector(0, 0, StandProbe), ignore = p };
	TraceLine(tr);
	if (("hit" in tr) && tr.hit && ("enthit" in tr))
		return PieceOf(tr.enthit);
	return null;
}

function Fort::Place(p, bp, plan) {
	local angles = AnglesText(plan.angles);
	local origins = plan.origins;
	local origin = origins[0];
	local pos = plan.pos;
	local ent = null;
	if (bp.kind == "item") {
		ent = SpawnEntityFromTable(bp.classname, { origin = pos + Vector(0, 0, 2), angles = angles, count = 1, model = bp.model,
			solid = 6, targetname = FORT_ITEM_NAME });
		if (ent == null) {
			EmitSoundOn(Sounds.Deny, p);
			Log(bp.name + " did not spawn");
			return;
		}
		Supplies[ent.GetEntityIndex()] <- { ent = ent, bp = bp };
	} else {
		if ("door" in bp)
			ent = SpawnEntityFromTable("prop_door_rotating", { model = bp.model, origin = origin, angles = angles,
				spawnflags = 8192, speed = 200, distance = 90, opendir = 0, returndelay = -1, forceclosed = 0,
				hardware = 1, health = 0, spawnpos = 0, disableshadows = 1, targetname = FORT_PIECE_NAME });
		else if (bp.kind == "gun")
			ent = SpawnEntityFromTable(bp.classname, { model = bp.model, origin = origin, angles = angles, targetname = FORT_PIECE_NAME,
				MaxYaw = "90", MinPitch = "-30", MaxPitch = "50" });
		else if (Breakable && Solid(bp)) {
			ent = SpawnEntityFromTable("prop_physics_override", { model = bp.model, origin = origin, angles = angles,
				spawnflags = 8, health = PropHealth, nodamageforces = 1, targetname = FORT_PIECE_NAME });
			if (ent != null && !ent.IsValid())
				ent = null;
			if (ent == null)
				Log(bp.name + ": no physics model, unbreakable");
		}
		if (ent == null && bp.kind != "gun" && !("door" in bp))
			ent = SpawnEntityFromTable("prop_dynamic_override", { model = bp.model, origin = origin, angles = angles,
				solid = Solid(bp) ? 6 : 0, targetname = FORT_PIECE_NAME });
		if (ent == null) {
			EmitSoundOn(Sounds.Deny, p);
			Log(bp.name + " did not spawn");
			return;
		}
		local piece = { ent = ent, bp = bp, kind = bp.kind, health = bp.health.tofloat(), max = bp.health.tofloat(),
		                pos = pos, radius = ("radius" in plan) ? plan.radius : Radius(ent), stage = 0, trapAt = 0.0, wrecked = false,
		                fx = [], angles = angles, supports = plan.supports, grounded = plan.grounded, slot = plan.slot,
		                top = ("top" in plan) ? plan.top : Top(ent, origin, pos), yaw = plan.yaw.tofloat(), origin = origin };
		if (plan.slot != null)
			Slots[plan.slot] <- piece;
		if (ent.GetClassname() == "prop_physics_override")
			DoEntFire("!self", "RunScriptCode", "::Fort.Recheck(" + ent.GetEntityIndex() + ")", 0.1, null, Entities.First());
		if ("parts" in plan)
			foreach (pt in plan.parts) {
				local part = SpawnEntityFromTable("prop_dynamic_override", { model = pt.model, origin = pt.origin,
					angles = AnglesText(pt.angles), solid = 6, targetname = FORT_PIECE_NAME });
				if (part != null) {
					piece.fx.append(part);
					Parts[part.GetEntityIndex()] <- { ent = part, piece = piece };
				}
			}
		for (local i = 1; i < origins.len(); i++) {
			local part = SpawnEntityFromTable("prop_dynamic_override", { model = bp.model, origin = origins[i], angles = angles,
				solid = 6, targetname = FORT_PIECE_NAME });
			if (part != null) {
				piece.fx.append(part);
				Parts[part.GetEntityIndex()] <- { ent = part, piece = piece };
			}
		}
		if (bp.kind == "fire") {
			local fire = Particle(FireEffect, pos + Vector(0, 0, 8), 0.0);
			if (fire != null)
				piece.fx.append(fire);
		} else if (bp.kind == "light") {
			local light = SpawnEntityFromTable("light_dynamic", { origin = pos + Vector(0, 0, LightHeight), _light = LightColor,
				brightness = 3, distance = LightDistance, spotlight_radius = 0, style = 0 });
			if (light != null) {
				DoEntFire("!self", "TurnOn", "", 0, null, light);
				piece.fx.append(light);
			}
		}
		Pieces[ent.GetEntityIndex()] <- piece;
		Drop(piece);
	}
	Scrap -= bp.cost;
	Particle(Dust, pos, 1.0);
	SoundAt(Sounds.Place, pos);
	Mark(p, "hit_head");
}

function Fort::Recheck(index) {
	if (!(index in Pieces))
		return;
	local piece = Pieces[index];
	if (piece.ent != null && piece.ent.IsValid())
		return;
	delete Pieces[index];
	local ent = SpawnEntityFromTable("prop_dynamic_override", { model = piece.bp.model, origin = piece.origin, angles = piece.angles,
		solid = 6, targetname = FORT_PIECE_NAME });
	if (ent == null) {
		Unfx(piece);
		Unslot(piece);
		AddScrap(piece.bp.cost);
		Log(piece.bp.name + " failed, refunded");
		return;
	}
	piece.ent = ent;
	Pieces[ent.GetEntityIndex()] <- piece;
	Log(piece.bp.name + ": no physics model, unbreakable");
}

function Fort::Top(ent, origin, pos) {
	local top = pos.z + 48.0;
	try {
		local hi = ent.GetBoundingMaxs();
		if (hi.z > 0.5)
			top = origin.z + hi.z;
	} catch (e) {}
	local tr = { start = Vector(pos.x, pos.y, top + 64.0), end = Vector(pos.x, pos.y, pos.z - 4.0) };
	try {
		TraceLine(tr);
		if (("hit" in tr) && tr.hit && ("enthit" in tr) && tr.enthit == ent && ("pos" in tr))
			top = tr.pos.z;
	} catch (e) {}
	return top;
}

function Fort::Unslot(piece) {
	if (piece.slot != null && (piece.slot in Slots) && Slots[piece.slot] == piece)
		delete Slots[piece.slot];
}

function Fort::Fall(gone, refund) {
	Unslot(gone);
	foreach (index, pc in clone Pieces) {
		if (!(index in Pieces))
			continue;
		local at = pc.supports.find(gone);
		if (at == null)
			continue;
		pc.supports.remove(at);
		if (pc.supports.len() > 0 || pc.grounded)
			continue;
		if (refund) {
			AddScrap((pc.bp.cost * Refund * pc.health / pc.max + 0.5).tointeger());
			Unfx(pc);
			if (pc.ent.IsValid())
				pc.ent.Kill();
			delete Pieces[index];
			Fall(pc, true);
		} else
			Break(index, pc);
	}
}

function Fort::Radius(ent) {
	try {
		local lo = ent.GetBoundingMins();
		local hi = ent.GetBoundingMaxs();
		local r = fabs(hi.x - lo.x) > fabs(hi.y - lo.y) ? fabs(hi.x - lo.x) : fabs(hi.y - lo.y);
		if (r > 8.0)
			return r * 0.5;
	} catch (e) {}
	return 48.0;
}

function Fort::Unfx(piece) {
	foreach (fx in piece.fx)
		if (fx != null && fx.IsValid())
			fx.Kill();
	piece.fx = [];
}

function Fort::Remove(p, st, piece) {
	local index = piece.ent.GetEntityIndex();
	local give = (piece.bp.cost * Refund * piece.health / piece.max + 0.5).tointeger();
	st.aim = null;
	st.value = -1;
	SoundAt(Sounds.Remove, piece.pos);
	Particle(Dust, piece.pos, 1.0);
	Unfx(piece);
	piece.ent.Kill();
	delete Pieces[index];
	AddScrap(give);
	Fall(piece, true);
}

function Fort::TakeSupply(p, st, supply) {
	local index = supply.ent.GetEntityIndex();
	local pos = supply.ent.GetOrigin();
	Unlook(st);
	supply.ent.Kill();
	delete Supplies[index];
	AddScrap(supply.bp.cost);
	SoundAt(Sounds.Remove, pos);
	Particle(Dust, pos, 1.0);
}

function Fort::Repair(p, st, piece, now) {
	if (piece.health >= piece.max || piece.kind == "mine")
		return;
	local dt = now - st.repairAt;
	st.repairAt = now;
	if (dt <= 0.0 || dt > 0.25)
		return;
	local heal = piece.max * RepairRate * dt;
	if (heal > piece.max - piece.health)
		heal = piece.max - piece.health;
	st.debt += piece.bp.cost * heal / piece.max;
	local pay = st.debt.tointeger();
	if (pay > Scrap) {
		EmitSoundOn(Sounds.Deny, p);
		st.debt = 0.0;
		return;
	}
	Scrap -= pay;
	st.debt -= pay;
	piece.health += heal;
	if (((now / TickEvery).tointeger() != ((now - dt) / TickEvery).tointeger())) {
		Sound(Sounds.Tick, piece.ent);
		Mark(p, "hit");
	}
	local stage = StageOf(piece);
	if (stage != piece.stage) {
		piece.stage = stage;
		DoEntFire("!self", "Color", AimColor, 0, null, piece.ent);
	}
}
