weapon:SetMesh("rv", "smg_20/rv1_lod0.mesh")
weapon:SetMesh("mz", "smg_20/mz1_lod0.mesh")
weapon.skeleton = "/skeleton/smg_09.skel"
weapon.animation_set = "smg_09"
weapon.icon = texture("/ui/skinF/lobby/smg_20.tga")
weapon.kill_icon = texture("/ui/weapon/mk18_20.dds")
weapon.ammo_icon = texture("/ui/ingameF/skin_ingame_icon_ammoBG_row.tga")
weapon.cross_hair_icon = texture("/ui/weapon/smg.dds")
weapon.is_sight = true
weapon.bullet_particle_first = "mk18_bullets_out_1st"
weapon.bullet_particle_third = "smg_01_bullets_out_3rd"
weapon.name = "smg_20"
weapon.sound_name = "smg"
weapon.fire_particle_offset = Vector3(0, -0.05, 0.17)
weapon.reload_sound = "reload"
weapon.fire_particle = "smg_01_mzflash"
weapon.attach_particle = "q_smg"
