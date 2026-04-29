weapon:SetMesh("rv", "Ba03ArmHMt_001/Ba03ArmHMt_001.mesh")
weapon.skeleton = "/skeleton/Ba03ArmHMt_001.skel"
weapon.animation_set = "ba03armhmt_002"
weapon.icon = texture("/ui/skinF/lobby/sniperrifle_01.tga")
weapon.kill_icon = texture("/ui/weapon/mk18_01.dds")
weapon.ammo_icon = texture("/ui/ingameF/skin_ingame_icon_ammoBG_row.tga")
weapon.cross_hair_icon = texture("/ui/weapon/sniperrifle.dds")
weapon.sight = texture("/ui/weapon/sniperrifle.dds")
weapon.bullet_particle_first = "mk18_bullets_out_1st"
weapon.bullet_particle_third = "sniperrifle_01_bullets_out_3rd"
weapon.name = "Ba03ArmHmt_001"
weapon.sound_name = "sniperrifle"
weapon.reload_sound = "reload2"
weapon.fire_particle = "sniperrifle_01_mzflash"
weapon.fire_joint_name = "Gun_Fire"
weapon:SetEffectParticle("kBuffTypeAwpUp", "boss_buff_awpup")
