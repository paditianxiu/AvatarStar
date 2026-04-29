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
    31,
    ActorType.kCapsule,
    {
      0.85,
      0.7,
      0
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
      PI * 1.5
    }
  }
}
