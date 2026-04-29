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
    "hat02",
    24,
    ActorType.kBox,
    {
      0.5,
      0.5,
      0.5
    },
    true,
    {
      0,
      0,
      0
    },
    true,
    {
      0,
      0,
      0,
      PI * 1
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
boss:SetEffectSound("kBuffTypeNuclear01", "go/boss_3d/boss03_skill001")
boss:SetEffectParticle("kBuffTypeNuclear01", "boss_hefushe_guangbo", "hat04", Vector3(0, 0, 0))
boss:SetEffectSound("kBuffTypeBlareField", "go/boss_3d/boss03_skill003")
boss:SetEffectParticle("kBuffTypeBlareField", "boss_blazefield_bom", "hat04", Vector3(0, 0, 0))
boss:SetEffectSound("kBuffTypeSacrifice", "go/boss_3d/boss03_skill001")
boss:SetEffectParticle("kBuffTypeSacrifice", "boss_bloodfire_xishou", "hat04", Vector3(0, 0, 0))
boss:SetEffectSound("kBuffTypeShock03", "go/boss_3d/boss03_skill002")
boss:SetEffectParticle("kBuffTypeShock03", "boss_shock_ball_b", "hat04", Vector3(0, 0, 0))
boss:SetEffectSound("kBuffTypeImmediately02", "go/boss_3d/boss03_skill002")
boss:SetEffectParticle("kBuffTypeImmediately02", "boss_shock_ball_r", "hat04", Vector3(0, 0, 0))
boss:SetEffectParticle("kFlyParticleForBossSkill63", "boss_bloodfire_energy_by", "body_up02", Vector3(0, 0, 0))
boss.born_sound_name = "go/boss_3d/boss03_spawn2"
boss.die_sound_name = "go/boss_3d/boss03_die"
boss.hit_num_joint = "hat04"
boss.draw_hp_joint = "body_up_front05"
boss.body_radius = 3
boss.body_height = 7
boss.body_capsule_offset = Vector3(0, 0.5, 0)
