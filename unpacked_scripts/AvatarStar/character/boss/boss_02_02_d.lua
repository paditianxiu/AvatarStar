boss:SetEffectAnimation("kBuffTypeDamageGrenade", "stdconjure", 0.05, false)
boss:SetEffectSound("kBuffTypeDamageGrenade", "go/boss_3d/boss02_lv2_conjure")
boss:SetEffectParticle("kBuffTypeDamageGrenade", "b2_burst_2", "bArm_r_12", Vector3(0, -1, 1))
boss:SetEffectParticle("kBuffTypeDamageGrenade2", "b2_burst_2_l", "bArm_l_12", Vector3(0, -1, 1))
boss:SetEffectAnimation("kBuffTypeCoolDownGrenade", "stdconjure", 0.05, false)
boss:SetEffectSound("kBuffTypeCoolDownGrenade", "go/boss_3d/boss02_lv2_conjure")
boss:SetEffectParticle("kBuffTypeCoolDownGrenade", "b2_irrigate", "bArm_r_12", Vector3(0, 0, 0))
boss:SetEffectParticle("kBuffTypeCoolDownGrenade2", "b2_irrigate_l", "bArm_l_12", Vector3(0, 0, 0))
boss:SetEffectAnimation("kBuffTypeCoolDownRpg2", "stdconjure", 0.05, false)
boss:SetEffectSound("kBuffTypeCoolDownRpg2", "go/boss_3d/boss02_lv2_conjure")
boss:SetEffectAnimation("kBuffTypeNoHarm", "stdshield", 0.05, false)
boss:SetEffectSound("kBuffTypeNoHarm", "go/boss_3d/boss02_lv2_shield")
boss:SetEffectParticle("kBuffTypeNoHarm", "b2_shield", "chilun_02", Vector3(0, 0, 0))
boss:SetEffectAnimation("kBuffTypeRecovery", "stdfix", 0.05, false)
boss:SetEffectSound("kBuffTypeRecovery", "go/boss_3d/boss02_lv2_fix")
boss:SetEffectParticle("kBuffTypeRecovery", "b2_repair", "neck", Vector3(0, 0, 0))
boss:SetEffectAnimation("kBuffTypeFireHurt", "stdconjure", 0.05, false)
boss:SetEffectSound("kBuffTypeFireHurt", "go/boss_3d/boss02_lv2_conjure")
boss:SetEffectParticle("kBuffTypeFireHurt", "b2_renascence_1", "body_up", Vector3(0, 0, 0))
boss:SetEffectAnimation("kBuffTypeHB", "stdconjure", 0.05, false)
boss:SetEffectSound("kBuffTypeHB", "go/boss_3d/boss02_lv2_conjure")
boss:SetEffectAnimation("kBuffTypeRpgHit", "stdconjure", 0.05, false)
boss:SetEffectSound("kBuffTypeRpgHit", "go/boss_3d/boss02_lv2_conjure")
boss:SetEffectAnimation("kBuffTypeHighlyDamage", "stdskill002", 0.05, false)
boss:SetEffectParticle("kBuffTypeHighlyDamage", "b2_lava_1", "body_up", Vector3(0, 0, 0))
boss:SetEffectAnimation("kBuffTypeQuickMove", "stdconjure", 0.05, false)
boss:SetEffectParticle("kBuffTypeQuickMove", "b2_accelerate", "foot_l", Vector3(0, 0, 0))
boss.born_sound_name = "go/boss_3d/boss02_lv2_born"
boss.die_sound_name = "go/boss_3d/boss02_lv2_die"
boss.run_sound_name = "go/boss_3d/boss02_lv2_run"
boss.idle_sound_name = "go/boss_3d/boss02_lv2_idle"
boss.jump_up_sound_name = ""
boss.jump_down_sound_name = ""
boss.jump_loop_sound_name = ""
boss.hit_num_joint = "head"
boss.draw_hp_joint = "body_up_front05"
boss.body_radius = 4
boss.body_height = 6
boss.body_capsule_offset = Vector3(0, 3, 0)
