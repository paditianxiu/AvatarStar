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
    "head",
    31,
    ActorType.kCapsule,
    {
      2.8,
      2,
      0.2
    },
    true,
    {
      0,
      0,
      0
    },
    true,
    {
      1,
      0,
      0,
      PI * 0.65
    }
  },
  {
    "chest",
    21,
    ActorType.kCapsule,
    {
      10,
      5.5,
      3
    },
    true,
    {
      0,
      1,
      0
    },
    true,
    {
      0,
      0,
      1,
      PI
    }
  },
  {
    "board_R",
    21,
    ActorType.kBox,
    {
      1.4,
      3.1,
      3.6
    },
    true,
    {
      0.3,
      -0.1,
      -0.1
    },
    true,
    {
      1,
      0,
      0,
      PI * 0.65
    }
  },
  {
    "board_L",
    21,
    ActorType.kBox,
    {
      1.4,
      3.1,
      3.6
    },
    true,
    {
      -0.2,
      0,
      0
    },
    true,
    {
      1,
      0,
      0,
      PI * 0.65
    }
  },
  {
    "chest",
    21,
    ActorType.kBox,
    {
      6,
      8,
      6
    },
    true,
    {
      0,
      8,
      0
    },
    true,
    {
      1,
      0,
      0,
      PI * 0.65
    }
  },
  {
    "chest",
    21,
    ActorType.kBox,
    {
      2.6,
      10,
      3
    },
    true,
    {
      0,
      8,
      -3
    },
    true,
    {
      1,
      0,
      0,
      PI * 0.65
    }
  },
  {
    "chest",
    21,
    ActorType.kBox,
    {
      3.3,
      7,
      4
    },
    true,
    {
      7.3,
      8,
      0
    },
    true,
    {
      1,
      0,
      0,
      PI * 0.65
    }
  },
  {
    "chest",
    21,
    ActorType.kBox,
    {
      3.3,
      7,
      4
    },
    true,
    {
      -7.3,
      8,
      0
    },
    true,
    {
      1,
      0,
      0,
      PI * 0.65
    }
  },
  {
    "armup_A_L",
    21,
    ActorType.kBox,
    {
      7,
      2.3,
      2
    },
    true,
    {
      2,
      1,
      0
    },
    true,
    {
      0,
      0,
      1,
      PI * 0.25
    }
  },
  {
    "armup_A_R",
    21,
    ActorType.kBox,
    {
      7,
      2.3,
      2
    },
    true,
    {
      -2,
      -1,
      0
    },
    true,
    {
      0,
      0,
      1,
      PI * 0.25
    }
  },
  {
    "armup_B_L",
    21,
    ActorType.kBox,
    {
      2,
      5,
      2
    },
    true,
    {
      -1,
      0,
      0
    },
    true,
    {
      0,
      0,
      1,
      PI * 0.45
    }
  },
  {
    "armup_B_R",
    21,
    ActorType.kBox,
    {
      2,
      5,
      2
    },
    true,
    {
      2,
      0,
      0
    },
    true,
    {
      0,
      0,
      1,
      PI * 0.55
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
boss.born_sound_name = "go/boss_3d/boss03_spawn2"
boss.die_sound_name = "go/boss_3d/boss03_die"
boss.hit_num_joint = "head"
boss.body_radius = 8
boss.body_height = 20
boss.body_capsule_offset = Vector3(0, 18, 0)
boss:SetEffectAnimation("kBuffTypeBoss4Spray", "stdattack", 0.05, false)
boss:SetEffectParticle("kBuffTypeBoss4Spray", "boss4_spray_fire", "tail", Vector3(0, 0, 0))
boss:SetEffectParticle("kBuffTypeBoss4TailParticle", "boss4_spray_fire", "tail", Vector3(0, 0, 0))
boss:SetEffectParticle("kBuffTypeBoss4CrazyFlyer", "boss4_crazyflyer", "head", Vector3(0, 0, 0))
boss:SetEffectParticle("kBuffTypeBoss4BombFly", "boss4_bombfly_2", "head", Vector3(0, 0, 0))
boss:SetEffectAnimation("kBuffTypeBoss4Wind", "stdattack01", 0.05, false)
boss:SetEffectParticle("kBuffTypeBoss4WindParticle", "boss4_dryer", "tail", Vector3(0, 0, 0))
boss:SetEffectSound("kBuffTypeBoss4WindParticle", "go/boss_3d/mega_blow")
