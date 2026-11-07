-- Installed after the original, unmodified scripts/lobby/playgame.lua bytecode.
local P = LobbyPlayGame
if not P or not P.ui or P.__roomAi then return end
P.__roomAi = true
local ui = P.ui
local panel
local busy = false
local function stateAndRoom()
  local state = ptr_cast(game.CurrentState, "Client.StateLobby")
  return state, state and state:GetSelfRoomInfo()
end
local function isHost(state)
  local id = state:GetCharacterId()
  for i = 1, 16 do
    local slot = state:GetSlot(i)
    if slot and slot.client and slot.client.character_id == id then
      return slot.client.host
    end
  end
  return false
end
local function close()
  if panel then panel.root.Parent = nil end
end
local function request(action)
  if busy then return end
  local state, room = stateAndRoom()
  if not room or not isHost(state) then
    MessageBox.ShowError("只有房主可以管理 AI 玩家")
    return
  end
  busy = true
  panel.add.Enable = false
  panel.remove.Enable = false
  panel.fill.Enable = false
  rpc.safecall("room_ai_" .. action, {
    roomUid = room.RoomUid,
    team = panel.team.SelectedIndex,
    occupation = panel.job.SelectedIndex,
    count = panel.count.SelectedIndex + 1,
  }, function(data)
    busy = false
    panel.add.Enable = true
    panel.remove.Enable = true
    panel.fill.Enable = true
    if not data or data.ok ~= 1 then
      MessageBox.ShowError(data and data.message or "AI 操作失败，请重新进入房间后再试")
      return
    end
    panel.status.Text = data.message or "操作完成"
  end)
end
local function show()
  local state, room = stateAndRoom()
  if not room or room.RoomState == 2 or not isHost(state) then return end
  if not panel then
    panel = Gui.Create() {
      Gui.Control("root") {
        Location = Vector2(330, 155), Size = Vector2(470, 395),
        BackgroundColor = ARGB(255, 255, 255, 255), Skin = SkinF.skin_playgame_030,
        ComFuc.ComLabel(nil, "添加 AI 玩家", Vector2(360, 28), Vector2(28, 22), 0, 20, ARGB(255,255,255,255)),
        ComFuc.ComLabel(nil, "队伍", Vector2(80, 26), Vector2(35, 73), 0, 16, ARGB(255,255,255,255)),
        ComFuc.ComComboBox("team", Vector2(290, 32), Vector2(125, 68)),
        ComFuc.ComLabel(nil, "职业", Vector2(80, 26), Vector2(35, 121), 0, 16, ARGB(255,255,255,255)),
        ComFuc.ComComboBox("job", Vector2(290, 32), Vector2(125, 116)),
        ComFuc.ComLabel(nil, "数量", Vector2(80, 26), Vector2(35, 169), 0, 16, ARGB(255,255,255,255)),
        ComFuc.ComComboBox("count", Vector2(290, 32), Vector2(125, 164)),
        ComFuc.ComLabel("status", "武器随机分配；AI 会自动准备。", Vector2(410, 34), Vector2(30, 211), 0, 14, ARGB(255,255,255,255)),
        ComFuc.ComButton("fill", "一键随机填满", Vector2(404, 44), Vector2(32, 256), 16, false, false, SkinF.select_character_038),
        ComFuc.ComButton("remove", "移除本队 AI", Vector2(126, 40), Vector2(28, 325)),
        ComFuc.ComButton("add", "添加", Vector2(120, 40), Vector2(170, 325)),
        ComFuc.ComButton("close", "关闭", Vector2(120, 40), Vector2(312, 325)),
      },
    }
    panel.team:AddItem("红队")
    panel.team:AddItem("蓝队")
    for _, name in ipairs({"护卫", "重装", "突击", "生化专家", "武士"}) do panel.job:AddItem(name) end
    for i = 1, 8 do panel.count:AddItem(tostring(i)) end
    panel.team.SelectedIndex = 1
    panel.job.SelectedIndex = 0
    panel.count.SelectedIndex = 0
    panel.close.EventClick = close
    panel.add.EventClick = function() request("add") end
    panel.remove.EventClick = function() request("remove") end
    panel.fill.EventClick = function() request("fill") end
  end
  panel.root.Parent = ui.root
end
Gui.Create(ui.b_back.Parent, ui) {
  ComFuc.ComButton("b_ai", "添加 AI", Vector2(120, 56), Vector2(137, 526), nil, true, false, SkinF.select_character_038),
}
ui.b_ai.EventClick = show
local oldUpdate = P.UpdateInRoomButtonState
P.UpdateInRoomButtonState = function(info, ...)
  oldUpdate(info, ...)
  local state, room = stateAndRoom()
  ui.b_ai.Enable = not busy and info and info.host and room and room.RoomState ~= 2 and room.GameType ~= "kBoss"
  if not ui.b_ai.Enable then close() end
end
local oldBack = ui.b_back.EventClick
ui.b_back.EventClick = function(sender, e)
  close()
  return oldBack(sender, e)
end
