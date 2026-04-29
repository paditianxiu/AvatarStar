boss:SetEffectAnimation("kBuffTypeQuickMeachinegun", "stdconjure", 0.05, false)
boss:SetEffectSound("kBuffTypeQuickMeachinegun", "go/boss_3d/boss_lv3_conjure")
boss:SetEffectAnimation("kBuffTypeQuickRpg", "stdconjure", 0.05, false)
boss:SetEffectSound("kBuffTypeQuickRpg", "go/boss_3d/boss_lv3_conjure")
boss:SetEffectAnimation("kBuffTypeDeadlyRpg", "stdconjure", 0.05, false)
boss:SetEffectSound("kBuffTypeDeadlyRpg", "go/boss_3d/boss_lv3_conjure")
boss:SetEffectAnimation("kBuffTypeCoolDownRpg", "stdconjure", 0.05, false)
boss:SetEffectSound("kBuffTypeCoolDownRpg", "go/boss_3d/boss_lv3_conjure")
boss:SetEffectAnimation("kBuffTypeCoolDownBow", "stdconjure", 0.05, false)
boss:SetEffectSound("kBuffTypeCoolDownBow", "go/boss_3d/boss_lv3_conjure")
boss:SetEffectAnimation("kBuffTypeQuickBow", "stdconjure", 0.05, false)
boss:SetEffectSound("kBuffTypeQuickBow", "go/boss_3d/boss_lv3_conjure")
boss:SetEffectAnimation("kBuffTypeHoldUp", "stdskill002", 0.05, false)
boss:SetEffectSound("kBuffTypeHoldUp", "go/boss_3d/boss_grasp")
boss:SetEffectAnimation("kBuffTypeShieldBoss", "stdshield", 0.05, false)
boss:SetEffectSound("kBuffTypeShieldBoss", "go/boss_3d/boss_lv3_shield")
boss:SetEffectParticle("kBuffTypeShieldBoss", "boss_energy", "body_up_front01", Vector3(0, 0, 0))
boss:SetEffectAnimation("kBuffTypeVitalsAll", "stdskill001", 0.05, false)
boss:SetEffectSound("kBuffTypeVitalsAll", "go/boss_3d/boss_burst")
boss:SetEffectParticle("kBuffTypeVitalsAll", "boss_crack_tempest", "body", Vector3(0, 0, 0))
boss:SetEffectAnimation("kBuffTypeVitalsBoss", "stdfaint", 0.05, true)
boss:SetEffectSound("kBuffTypeVitalsBoss", "go/boss_3d/boss_lv3_faint")
boss:SetEffectParticle("kBuffTypeVitalsBoss", "boss_serious1_somke", "body", Vector3(0, 0, 0))
boss.born_sound_name = "go/boss_3d/boss_lv3_born"
boss.die_sound_name = "go/boss_3d/boss_lv3_dead"
boss.run_sound_name = "go/boss_3d/boss_lv3_runforward"
boss.idle_sound_name = "go/boss_3d/boss_lv3_idle"
boss.jump_up_sound_name = "go/boss_3d/boss_lv3_jumpup"
boss.jump_down_sound_name = "go/boss_3d/boss_lv3_jumpdown"
boss.jump_loop_sound_name = "go/boss_3d/boss_lv3_jumpshoot"
boss.hit_num_joint = "body_up_front01"
boss.draw_hp_joint = "body_up_front05"
boss.body_radius = 6
boss.body_height = 6
boss.body_capsule_offset = Vector3(0, 6, 1)
