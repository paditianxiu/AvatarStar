local ActorType = {
  kSphere = 0,
  kCapsule = 1,
  kBox = 2
}
weapon.ik_enable = false
weapon.hand_bind_type = "kHandNone"
weapon.name = "ÊÖÀ×"
weapon.sound_name = "boss02_grenade"
weapon.skeleton = "/skeleton/Ba03Monster_grenade_001.skel"
weapon.icon = texture("/ui/skinF/lobby/Ba03Monster_grenade.tga")
weapon.kill_icon = texture("/ui/weapon/Ba03Monster_grenade.dds")
weapon.ammo_icon = texture("/ui/ingameF/weapon_ammo_icon/Ba03Monster_grenade.tga")
weapon.cross_hair_icon = texture("/ui/weapon/grenade.dds")
weapon.explode_particle = "boss_xiaoguai_explosionself"
weapon.explode_sound = "go/impact_3d/explosion_grenade"
weapon.throw_sound_3d = "go/boss_3d/mover_at"
weapon.owner_type = 1
weapon:SetActor(ActorType.kSphere, Vector3(1.2, 0, 0))
