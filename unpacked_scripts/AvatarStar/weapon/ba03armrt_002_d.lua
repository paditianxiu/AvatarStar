weapon.name = "Ba03ArmRt_001"
weapon:SetMesh("rv", "Ba03ArmRt_001/Ba03ArmRt_001.mesh")
weapon:SetMesh("mz", "Ba03ArmRt_001/Ba03ArmRt_001.mesh")
weapon.skeleton = "/skeleton/Ba03ArmRt_001.skel"
weapon.animation_set = "ba03armrt_002"
weapon.icon = texture("/ui/skinF/lobby/rpg_01.tga")
weapon.kill_icon = texture("/ui/weapon/mk18_01.dds")
weapon.ammo_icon = texture("/ui/ingameF/weapon_ammo_icon/rpg_01.tga")
weapon.cross_hair_icon = texture("/ui/weapon/rpg.dds")
weapon.bullet_particle_first = "mk18_bullets_out_1st"
weapon.bullet_particle_third = "mk18_bullets_out_3rd"
weapon.sound_name = "boss01_shoulder"
weapon.explode_sound = "go/impact_3d/explosion_large"
weapon.explode_particle = "grenade_explosion"
weapon.shot_mesh = "Ba03ArmRt_rpgbullet_001.mesh"
weapon.shot_trail_particle = "boss_attack_rocket"
weapon.reload_sound = "reload"
weapon.fire_particle = "boss_attack_rocket_1"
weapon.fire_joint_name = "Gun_Fire"
weapon:SetEffectParticle("kBuffTypeRocketUp", "boss_buff_rocketup")
