weapon:SetMesh("rv", "Ba02ArmRt_001/Ba02ArmRt_001.mesh")
weapon:SetMesh("mz", "Ba02ArmRt_001/Ba02ArmRt_001.mesh")
weapon.skeleton = "/skeleton/Ba02ArmRt_001.skel"
weapon.animation_set = "Ba02ArmRt_001"
weapon.icon = texture("/ui/skinF/lobby/rpg_01.tga")
weapon.kill_icon = texture("/ui/weapon/mk18_01.dds")
weapon.ammo_icon = texture("/ui/ingameF/weapon_ammo_icon/rpg_01.tga")
weapon.cross_hair_icon = texture("/ui/weapon/rpg.dds")
weapon.bullet_particle_first = "mk18_bullets_out_1st"
weapon.bullet_particle_third = "mk18_bullets_out_3rd"
weapon.fire_particle = "boss_attack_rocket_1"
weapon.name = "Ba02ArmRt_001"
weapon.sound_name = "boss02_rpg"
weapon.explode_sound = "go/impact_3d/explosion_large"
weapon.explode_particle = "grenade_explosion"
weapon.shot_mesh = "Ba02ArmRt_bullet_001.mesh"
weapon.shot_trail_particle = "b2_attack_rpg1"
weapon.shot_trail_particle_skill1 = "b2_shock_1"
weapon.shot_trail_particle_skill2 = "b2_chaos_1"
weapon.fire_joint_name = "Gun_Fire_L"
weapon.bullet_joint_name = "Gun_RV_L"
weapon.backfire_joint_name = "Gun_backFire_L"
weapon.reload_sound = "reload"
weapon.attach_particle_joint_name = "Gun_Fire_L"
weapon.fire_joint_name = "Gun_Fire"
weapon:SetEffectParticle("kBuffTypeCoolDownRpg2", "b2_meteor")
