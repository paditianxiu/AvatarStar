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
boss.run_sound_name = "go/boss_3d/tobso_move"
boss.die_sound_name = "go/boss_3d/boss04_spawn_2d"
boss.hit_num_joint = "head"
boss.body_radius = 6.5
boss.body_height = 30
boss.body_capsule_offset = Vector3(0, 0, 0)
boss:SetEffectParticle("kBuffTypeBoss4ShockWave", "boss4_shockwave", "Gun_Fire_Rt", Vector3(0, 0, 0))
boss:SetEffectParticle("kBuffTypeBoss4FinalFire", "boss4_finalfire_xi", "tail", Vector3(0, 0, 0))
boss:SetEffectSound("kBuffTypeBoss4FinalFire", "go/boss_3d/ultimate_shot_2d")
