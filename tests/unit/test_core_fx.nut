::ROOT <- vargv.len() > 0 ? vargv[0] : ".";
dofile(::ROOT + "/tests/unit/mock.nut");
Suite("core fx");

Load("parts/core/addon/scripts/vscripts/hd4l_core.nut");

Reset();
local nick = MakeSurvivor();
::HD4L.Loud("hyper/kill.mp3", nick, 110, 80);
Check(::T.sounds.len() == 1 && ::T.sounds[0].how == "ambient", "loud: one ambient emit");
Check(::T.sounds.len() == 1 && ::T.sounds[0].level == 110 && ::T.sounds[0].pitch == 80, "loud: level 110, pitch 80");

Reset();
nick = MakeSurvivor();
local keep = ::EmitAmbientSoundOn;
delete getroottable().EmitAmbientSoundOn;
::HD4L.Loud("hyper/kill.mp3", nick);
Check(::T.sounds.len() == 2 && ::T.sounds[0].how == "plain", "loud: fallback emits twice");
::EmitAmbientSoundOn <- keep;

Reset();
local gone = Ent("info_target");
gone.valid = false;
::HD4L.Loud("hyper/kill.mp3", gone);
Check(::T.sounds.len() == 0, "loud: invalid entity, no sound");

Reset();
local witch = Ent("witch");
witch.attachments = [ "forward", "eyes" ];
local fx = ::HD4L.Eyes(witch, "hd4l_eyes_red", 48.0);
Check(fx.len() == 2, "eyes: two particles");
Check(fx.len() == 2 && fx[0].kv.effect_name == "hd4l_eyes_red", "eyes: effect name passed through");
Check(fx.len() == 2 && (fx[0].GetOrigin() - fx[1].GetOrigin()).Length() > 2.0, "eyes: left and right apart");
local attach = Fired("SetParentAttachmentMaintainOffset");
Check(attach.len() == 2 && attach[0].param == "eyes", "eyes: parented to the eyes attachment");
Check(::T.logs.filter(@(i, l) l.find("eyes on witch at attachment 'eyes'") != null).len() == 1, "eyes: logged once per class");

Reset();
local jockey = Ent("player");
fx = ::HD4L.Eyes(jockey, "hd4l_eyes_white", 64.0);
Check(fx.len() == 2 && Fired("SetParentAttachmentMaintainOffset").len() == 0, "eyes: no attachment, parent only");
Check(fx.len() == 2 && fabs(fx[0].GetOrigin().z - 64.0) < 0.01, "eyes: fallback height 64");

Reset();
local tank = Ent("player");
tank.model = "models/infected/hulk.mdl";
tank.attachments = [ "rhand", "mouth" ];
tank.angles = QAngle(0, 90, 0);
fx = ::HD4L.Eyes(tank, "hd4l_eyes_tank", 80.0);
attach = Fired("SetParentAttachmentMaintainOffset");
Check(fx.len() == 2 && attach.len() == 2 && attach[0].param == "mouth", "tank eyes: parented to the mouth");
Check(fx.len() == 2 && fabs(fx[0].GetOrigin().z - fx[1].GetOrigin().z) < 0.01, "tank eyes: level with each other");
Check(fx.len() == 2 && fabs(fx[0].GetOrigin().y - fx[1].GetOrigin().y) < 0.01 && fabs(fx[0].GetOrigin().x - fx[1].GetOrigin().x) > 3.0, "tank eyes: spread across the facing");
Check(fx.len() == 2 && fx[0].GetOrigin().z > 60.0, "tank eyes: above the mouth, not the fallback");

Reset();
local p1 = Ent("info_particle_system");
local s1 = Ent("env_sprite");
::HD4L.Unfx([ p1, s1, null ], 0.3);
local stops = Fired("Stop");
local kills = Fired("Kill");
Check(stops.len() == 1 && stops[0].ent == p1 && stops[0].delay == 0.3, "unfx: particle stopped at the delay");
Check(kills.len() == 2, "unfx: both killed");
Check(kills.filter(@(i, k) k.ent == p1 && k.delay > 1.0).len() == 1, "unfx: particle killed after its trail fades");

Reset();
local glow = ::HD4L.Flash(Vector(0, 0, 0), "255 176 60", 3.0, 0.2);
Check(glow != null && glow.cls == "env_sprite" && glow.kv.rendercolor == "255 176 60", "flash: amber sprite");
Check(Fired("Kill").filter(@(i, k) k.ent == glow && k.delay == 0.2).len() == 1, "flash: killed after 0.2 s");

Check(::HD4L.EyeEffects.len() == 5, "five eye effects declared");

Done();
