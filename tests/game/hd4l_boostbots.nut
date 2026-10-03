local hyper = ("HD4LBoost" in getroottable()) && ("Hyper" in ::HD4LBoost) && ::HD4LBoost.Hyper;
local n = 0;
local p = null;
while ((p = Entities.FindByClassname(p, "player")) != null) {
	if (!p.IsSurvivor() || !IsPlayerABot(p) || p.IsDead())
		continue;
	if (hyper && ("Momentum" in getroottable()))
		::Momentum.StateOf(p).hyperUntil = Time() + 60.0;
	else
		try { p.UseAdrenaline(60.0); } catch (e) { NetProps.SetPropInt(p, "m_bAdrenalineActive", 1); }
	n++;
}
printl("[HD4L test] boosted " + n + " bots (" + (hyper ? "HYPER" : "adrenaline") + ", 60 s)");
