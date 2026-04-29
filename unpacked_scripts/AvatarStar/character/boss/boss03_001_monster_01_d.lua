local ActorType = {
  kSphere = 0,
  kCapsule = 1,
  kBox = 2
}
local JointType = {kSpherical = 0, kRevolute = 1}
local PI = 3.1415926
local tt = 0.707
actor_desc = {
  {
    "body_down",
    24,
    ActorType.kCapsule,
    {
      1.2,
      1.1,
      0
    },
    true,
    {
      0,
      0,
      0.6
    },
    true,
    {
      1,
      0,
      0,
      PI * 0.6
    }
  }
}
joint_desc = {
  {
    "body_up",
    "body_up2",
    JointType.kSpherical,
    {
      0,
      0,
      0
    },
    {
      0,
      0,
      0
    }
  },
  {
    "body_up2",
    "LArm_up",
    JointType.kSpherical,
    {
      0,
      0,
      0
    },
    {
      0,
      0,
      0
    }
  },
  {
    "LArm_up",
    "LArm",
    JointType.kSpherical,
    {
      1,
      -2,
      0
    },
    {
      0,
      0,
      90
    }
  }
}
boss:SetEffectSound("kBuffTypeShock", "go/impact_3d/jaw_shock")
boss:SetEffectParticle("kBuffTypeShock", "boss_shock_ball_b_by", "body", Vector3(0, 0, 0))
boss:SetEffectSound("kBuffTypeImmediately", "go/impact_3d/jaw_shock")
boss:SetEffectParticle("kBuffTypeImmediately", "boss_shock_ball_r_by", "body", Vector3(0, 0, 0))
boss:SetEffectParticle("kBuffTypeBossDecelerate", "boss_xiaoguai_jiansu", "body", Vector3(0, 0, 0))
boss:SetEffectParticle("kBuffTypeReactive", "boss_bloodfire_xiaoguai", "body", Vector3(0, 0, 0))
boss:SetEffectSound("kBuffTypeBossBombDied03", "go/boss_3d/mover_alarm")
boss:SetEffectParticle("kBuffTypeBossBombDied03", "boss_xiaoguai_explosionself_2", "body", Vector3(0, 0.5, 0))
boss.run_sound_name = "go/boss_3d/mover_mo"
boss.hit_num_joint = "hat02"
boss.draw_hp_joint = "hat02"
boss.body_radius = 0.5
boss.body_height = 0.8
boss.body_capsule_offset = Vector3(0, 0, 0)
