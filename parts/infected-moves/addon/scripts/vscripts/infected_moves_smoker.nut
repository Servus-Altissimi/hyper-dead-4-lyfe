function InfectedMoves::TongueLost(smokerUserid) {
	if (!Smoker || !ModeAllowed())
		return;
	DoEntFire("!self", "RunScriptCode", "::InfectedMoves.Phantom(" + smokerUserid + ")", PhantomDelay, null, Entities.First());
}

function InfectedMoves::OnGameEvent_tongue_release(params) {
	if ("userid" in params)
		TongueLost(params.userid);
}

function InfectedMoves::OnGameEvent_tongue_broke_bent(params) {
	if ("userid" in params)
		TongueLost(params.userid);
}

function InfectedMoves::HiddenSpot(ent, survivors, min, max) {
	local origin = ent.GetOrigin();
	local areas = {};
	try { NavMesh.GetNavAreasInRadius(origin, max, areas); } catch (e) { Log("no navmesh: " + e); return null; }
	local best = null;
	foreach (name, area in areas) {
		local c = null;
		try { c = area.GetCenter(); } catch (e) { continue; }
		local d = (c - origin).Length();
		if (d < min * 0.5 || d > max)
			continue;
		local isBlocked = false;
		try { isBlocked = area.IsBlocked(TEAM_INFECTED, false); } catch (e) {}
		if (isBlocked)
			continue;
		local up = { start = c + Vector(0, 0, 20), end = c + Vector(0, 0, 76), ignore = ent };
		TraceLine(up);
		if (up.hit)
			continue;
		local ok = true;
		foreach (s in survivors) {
			if ((s.GetOrigin() - c).Length() < min) {
				ok = false;
				break;
			}
			local look = { start = s.EyePosition(), end = c + Vector(0, 0, 40), ignore = s };
			TraceLine(look);
			if (!look.hit || look.fraction > 0.98) {
				ok = false;
				break;
			}
		}
		if (ok && (best == null || c.z > best.z))
			best = c;
	}
	return best;
}

function InfectedMoves::Phantom(userid) {
	local smoker = null;
	try { smoker = GetPlayerFromUserID(userid); } catch (e) { return; }
	if (!IsSpecial(smoker, ZOMBIE_SMOKER) || !IsPlayerABot(smoker))
		return;
	local spot = HiddenSpot(smoker, Survivors(), PhantomMin, PhantomMax);
	if (spot == null)
		return;
	local from = smoker.GetOrigin();
	Particle("smoker_smokecloud", from, 3.0);
	Sound(smoker, Sounds.smoker);
	smoker.SetOrigin(spot);
	Particle("smoker_smokecloud", spot, 3.0);
	smoker.SetHealth(smoker.GetMaxHealth());
}
