weapon.name = "Ba03ArmHLt_001"
weapon:SetMesh("rv", "Ba03ArmHLt_001/Ba03ArmHLt_001.mesh")
weapon:SetMesh("mz", "Ba03ArmHLt_001/Ba03ArmHLt_001.mesh")
weapon.skeleton = "/skeleton/Ba03ArmHLt_001.skel"
weapon.animation_set = "ba03armhlt_002"
weapon.icon = texture("/ui/skinF/lobby/bow_17.tga")
weapon.kill_icon = texture("/ui/weapon/mk18_01.dds")
weapon.ammo_icon = texture("/ui/ingameF/weapon_ammo_icon/bow_17.tga")
weapon.cross_hair_icon = texture("/ui/weapon/rpg.dds")
weapon.sound_name = "boss01_bow"
weapon.explode_sound = "go/impact_3d/explosion_med"
weapon.explode_particle = "s_bow_explosion"
weapon.shot_trail_particle = "boss_attack_rocket_2"
weapon.arrow_trail_particle = "s_bow_trail2"
weapon.bow_glow_particle = "s_bow_glow"
weapon.reload_sound = "reload"
weapon.fire_particle = "boss_attack_rocket_1"
weapon.fire_joint_name = "Gun_Fire"
weapon:SetEffectParticle("kBuffTypeShootUp", "boss_buff_shootup")
