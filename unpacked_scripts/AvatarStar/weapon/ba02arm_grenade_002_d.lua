weapon:SetMesh("rv", "Ba02Arm_grenade_002/Ba02Arm_grenade_002.mesh", 0)
local ActorType = {
  kSphere = 0,
  kCapsule = 1,
  kBox = 2
}
weapon.ik_enable = false
weapon.hand_bind_type = "kHandNone"
weapon.name = "ÊÖÀ×"
weapon.sound_name = "boss02_grenade"
weapon.skeleton = "/skeleton/Ba02Arm_grenade_rig.skel"
weapon.icon = texture("/ui/skinF/lobby/Ba02Arm_grenade_002.tga")
weapon.kill_icon = texture("/ui/weapon/Ba02Arm_grenade_002.dds")
weapon.ammo_icon = texture("/ui/ingameF/weapon_ammo_icon/Ba02Arm_grenade_002.tga")
weapon.cross_hair_icon = texture("/ui/weapon/grenade.dds")
weapon.explode_particle = "b2_grenade_explosino1"
weapon.trail_particle = "b2_scorching"
weapon.explode_sound = "go/impact_3d/explosion_grenade"
weapon.throw_sound_3d = "go/weapon_3d/boss02_grenade/fire"
weapon.owner_type = 1
weapon:SetActor(ActorType.kSphere, Vector3(1.2, 0, 0))
weapon.sound_name = "boss02_grenade"
