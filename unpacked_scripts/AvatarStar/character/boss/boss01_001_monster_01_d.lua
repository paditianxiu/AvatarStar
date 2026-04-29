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
boss.run_sound_name = "go/minion/bomber_move"
boss.hit_num_joint = "body_down"
boss.draw_hp_joint = "body_down"
boss.body_radius = 0.7
boss.body_height = 1.1
boss.body_capsule_offset = Vector3(0, 3.2, 0)
boss:SetEffectParticle("kBuffTypeBoss4CrazyFlyer", "boss4_bombfly", "body", Vector3(0, 0, 0))
boss:SetEffectParticle("kBuffTypeBoss4BombFly", "boss4_air_trail", "body", Vector3(0, 0, 0))
boss:SetEffectParticle("kBuffTypeBoss4BombFlyDiedEffect", "boss_xiaoguai_explosionself", "body", Vector3(0, 0, 0))
boss:SetEffectSound("kBuffTypeBoss4BombFlyDiedEffect", "go/minion/bomber_impact")
