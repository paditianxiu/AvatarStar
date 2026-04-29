bossBattleGUIConfig = {
  {
    Vector4(566, 3, 115, 115),
    Vector4(0, 0, 0, 0)
  },
  {
    Vector4(583, 101, 85, 31),
    Vector4(0, 0, 0, 0)
  },
  {
    Vector4(583, 101, 85, 31),
    Vector4(0, 0, 0, 0)
  },
  {
    Vector4(706, 11, 240, 16),
    Vector4(0, 0, 0, 0)
  },
  {
    Vector4(669, 26, 366, 30),
    Vector4(20, 10, 10, 10)
  },
  {
    Vector4(690, 54, 60, 60),
    Vector4(0, 0, 0, 0)
  },
  {
    Vector4(-3, -44, 70, 42),
    Vector4(0, 0, 0, 0)
  }
}
for i, v in ipairs(bossBattleGUIConfig) do
  ingameui:SetBossBattleGUI(i - 1, v[1], v[2])
end
