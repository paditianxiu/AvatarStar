weapon:SetMesh("rv", "Ba01ArmRt_002/Ba01ArmRt_002.mesh")
weapon.skeleton = "/skeleton/Ba01ArmRt_002.skel"
weapon.animation_set = "ba01armrt_002"
weapon.icon = texture("/ui/skinF/lobby/machinegun_23.tga")
weapon.kill_icon = texture("/ui/weapon/mk18_14.dds")
weapon.ammo_icon = texture("/ui/ingameF/skin_ingame_icon_ammoBG_row.tga")
weapon.cross_hair_icon = texture("/ui/weapon/machinegun.dds")
weapon.fire_particle_offset = Vector3(0, 0.03, 0.15)
weapon.bullet_particle_first = "mk18_bullets_out_1st"
weapon.bullet_particle_third = "machinegun_02_bullout_3rd"
weapon.name = "machinegun_14"
weapon.sound_name = "boss01_smg"
weapon.reload_sound = "reload"
weapon.fire_particle = "machinegun_01_mzflash"
weapon.fire_joint_name = "Gun_Fire"
weapon:SetEffectParticle("kBuffTypeQuickMeachinegun", "boss_buff_speed")
