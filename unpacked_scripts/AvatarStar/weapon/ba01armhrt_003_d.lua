weapon:SetMesh("rv", "Ba01Armhrt_003/Ba01Armhrt_003.mesh")
weapon:SetMesh("mz", "Ba01Armhrt_003/Ba01Armhrt_003.mesh")
weapon.skeleton = "/skeleton/Ba01Armhrt_003.skel"
weapon.animation_set = "ba01armhrt_003"
weapon.icon = texture("/ui/skinF/lobby/rpg_01.tga")
weapon.kill_icon = texture("/ui/weapon/mk18_01.dds")
weapon.ammo_icon = texture("/ui/ingameF/weapon_ammo_icon/rpg_01.tga")
weapon.cross_hair_icon = texture("/ui/weapon/rpg.dds")
weapon.bullet_particle_first = "mk18_bullets_out_1st"
weapon.bullet_particle_third = "mk18_bullets_out_3rd"
weapon.name = "Ba01ArmHrt_003"
weapon.sound_name = "boss01_shoulder"
weapon.explode_sound = "go/impact_3d/explosion_large"
weapon.explode_particle = "grenade_explosion"
weapon.shot_mesh = "Ba01ArmLt_rpgbullet_001.mesh"
weapon.shot_trail_particle = "boss_attack_rocket"
weapon.reload_sound = "reload"
weapon.fire_particle = "boss_attack_rocket_1"
weapon.fire_joint_name = "Gun_Fire_HRt"
weapon:SetEffectParticle("kBuffTypeQuickRpg", "boss_buff_bomb")
weapon:SetEffectParticle("kBuffTypeDeadlyRpg", "boss_buff_artillery")
weapon:SetEffectParticle("kBuffTypeCoolDownRpg", "boss_buff_cooling")
weapon:SetEffectParticle("kBuffTypeVitalsAll", "boss_crack_energy")
