weapon:SetMesh("rv", "Ba01ArmhRt_002/Ba01ArmhRt_002.mesh")
weapon:SetMesh("mz", "Ba01ArmhRt_002/Ba01ArmhRt_002.mesh")
weapon.skeleton = "/skeleton/Ba01ArmhRt_002.skel"
weapon.animation_set = "ba01armhrt_002"
weapon.icon = texture("/ui/skinF/lobby/machinegun_23.tga")
weapon.kill_icon = texture("/ui/weapon/mk18_14.dds")
weapon.ammo_icon = texture("/ui/ingameF/skin_ingame_icon_ammoBG_row.tga")
weapon.cross_hair_icon = texture("/ui/weapon/machinegun.dds")
weapon.bullet_particle_first = "mk18_bullets_out_1st"
weapon.bullet_particle_third = "mk18_bullets_out_3rd"
weapon.name = "ba01armhrt_002"
weapon.sound_name = "boss01_shoulder"
weapon.explode_sound = "go/impact_3d/explosion_large"
weapon.explode_particle = "grenade_explosion"
weapon.shot_mesh = "Ba01ArmLt_rpgbullet_001.mesh"
weapon.shot_trail_particle = "boss_attack_rocket"
weapon.reload_sound = "reload"
weapon.fire_particle = "boss_attack_rocket_1"
weapon.fire_joint_name = "Gun_Fire"
weapon:SetEffectParticle("kBuffTypeQuickRpg", "boss_buff_bomb")
weapon:SetEffectParticle("kBuffTypeDeadlyRpg", "boss_buff_artillery")
weapon:SetEffectParticle("kBuffTypeCoolDownRpg", "boss_buff_cooling")
weapon:SetEffectParticle("kBuffTypeVitalsAll", "boss_buff_cooling")
