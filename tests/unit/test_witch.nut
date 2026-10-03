::ROOT <- vargv.len() > 0 ? vargv[0] : ".";
dofile(::ROOT + "/tests/unit/mock.nut");
Suite("witch");

Load("parts/core/addon/scripts/vscripts/hd4l_core.nut");
Load("parts/witch-escort/addon/scripts/vscripts/witch_escort.nut");

Reset();
::WitchEscort.Fx.clear();
local witch = Ent("witch");
witch.attachments = [ "eyes" ];
witch.health = 1500;

::WitchEscort.OnGameEvent_witch_spawn({ witchid = witch.index });
local runs = Fired("RunScriptCode").filter(@(i, f) f.param.find("SetEyes") != null);
Check(runs.len() == 1, "spawn: eyes scheduled");
::WitchEscort.SetEyes(witch.index, ::WitchEscort.CalmEyes);
Check(::WitchEscort.Fx[witch.index].len() == 2 && ::WitchEscort.Fx[witch.index][0].kv.effect_name == "hd4l_eyes_red", "calm: red eyes");

local nick = MakeSurvivor();
local calm = ::WitchEscort.Fx[witch.index];
::WitchEscort.OnGameEvent_witch_harasser_set({ witchid = witch.index, userid = nick.userid });
Check(::WitchEscort.Fx[witch.index][0].kv.effect_name == "hd4l_eyes_rage", "rage: rage eyes");
Check(Fired("Stop").filter(@(i, f) f.ent == calm[0] || f.ent == calm[1]).len() == 2, "rage: calm eyes stopped");
local shriek = ::T.sounds.filter(@(i, s) s.how == "ambient" && s.pitch == 70);
Check(shriek.len() == 1 && shriek[0].level == 110, "rage: low shriek at level 110");

::WitchEscort.OnGameEvent_witch_killed({ witchid = witch.index });
Check(!(witch.index in ::WitchEscort.Fx), "killed: fx forgotten");

Reset();
witch = Ent("witch");
local table = { Victim = witch, DamageDone = 900 };
::WitchEscort.DamageHook("g_ModeScript", table);
Check(table.DamageDone == 350, "cap: 900 becomes 350");

Check(!("m_Glow.m_iGlowType" in witch.props), "no outline glow on the witch");

Done();
