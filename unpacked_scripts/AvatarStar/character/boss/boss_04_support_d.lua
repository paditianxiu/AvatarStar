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
    21,
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
boss.hit_num_joint = "hat04"
boss.draw_hp_joint = "body_up_front05"
boss.body_radius = 3
boss.body_height = 7
boss.body_capsule_offset = Vector3(0, 0.5, 0)
