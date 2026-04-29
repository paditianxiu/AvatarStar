weapon:SetMesh("rv", "Ba01ArmRt_003/Ba01ArmRt_003.mesh")
weapon:SetMesh("mz", "Ba01ArmRt_003/Ba01ArmRt_003.mesh")
weapon.skeleton = "/skeleton/Ba01ArmRt_003.skel"
weapon.animation_set = "Ba01ArmRt_003"
weapon.icon = texture("/ui/skinF/lobby/smg_17.tga")
weapon.kill_icon = texture("/ui/weapon/mk18_17.dds")
weapon.ammo_icon = texture("/ui/ingameF/skin_ingame_icon_ammoBG_row.tga")
weapon.cross_hair_icon = texture("/ui/weapon/smg.dds")
weapon.fire_particle_offset = Vector3(0, -0.02, 0)
weapon.bullet_particle_first = "mk18_bullets_out_1st"
weapon.bullet_particle_third = "smg_01_bullets_out_3rd"
weapon.name = "smg_17"
weapon.sound_name = "boss01_smg"
weapon.reload_sound = "reload"
weapon.fire_particle = "smg_01_mzflash"
weapon.fire_joint_name = "Gun_Fire"
weapon:SetEffectParticle("kBuffTypeQuickMeachinegun", "boss_buff_speed")
