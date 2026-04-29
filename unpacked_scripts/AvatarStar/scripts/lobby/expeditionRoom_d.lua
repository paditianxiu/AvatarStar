module("ExpeditionRoom", package.seeall)
what_map_name_select = 0
local game_mode = 0
local bfirsttime = 1
local ib_display_pic_count = 0
map_keys_of_game_type = {}
game_type_key = {}
map_id_of_key = {}
map_key_of_map_id = {}
mapInfo = {}
level_map_data = {}
local roomInfoLevelId
ui = Gui.Create()({
  Gui.Control("root")({
    Size = Vector2(431, 280),
    Location = Vector2(97, 36),
    BackgroundColor = colw,
    Skin = SkinF.skin_playgame_033,
    ComFuc.ComPagesBar("page_bar", Vector2(86, 237)),
    Gui.ImageBrowser("ib_map")({
      Location = Vector2(26, 10),
      Size = Vector2(380, 222),
      DisplayRowAndCol = Vector2(2, 2),
      PictureStyle = "Gui.PictureMapInBrowser0",
      Margin = Vector4(0, 0, 0, 0)
    })
  })
})
ui.ib_map.LeftBtn.Visible = false
ui.ib_map.RightBtn.Visible = false
local ShowLeves, SetUIText = function(is_host)
  for i = 1, Expedition.level_difficulty_num do
    Expedition.ui["level_difficulty_" .. i].Visible = is_host
  end
  Expedition.ui.selected_level_background.Visible = not is_host
  Expedition.ui.selected_difficulty.Text = GetUTF8Text(ComFuc.difficulty_list[ComFuc.level_difficulty + 1])
  Expedition.ui.selected_difficulty_bg.Skin = SkinF.level_difficulty_bg[ComFuc.level_difficulty + 1]
  ui.root.Visible = is_host
end, function(is_host)
  for i = 1, Expedition.level_difficulty_num do
    Expedition.ui["level_difficulty_" .. i].Visible = is_host
  end
  Expedition.ui.selected_level_background.Visible = not is_host
  Expedition.ui.selected_difficulty.Text = GetUTF8Text(ComFuc.difficulty_list[ComFuc.level_difficulty + 1])
  Expedition.ui.selected_difficulty_bg.Skin = SkinF.level_difficulty_bg[ComFuc.level_difficulty + 1]
  ui.root.Visible = is_host
end
local SetUIText, CleanText = function(data)
  level_map_data = data
  Expedition.ui.role_level.Text = GetUTF8Text("UI_lobby_explore_Character_level") .. GetMatchedUTF8Text(GetUTF8Text("UI_lobby_role_grade") .. "," .. data.level)
  Expedition.ui.count_limit.Text = GetUTF8Text("UI_lobby_people_limit") .. GetMatchedUTF8Text(GetUTF8Text("UI_lobby_rol_number") .. "," .. data.minCount .. "-" .. data.maxCount)
  Expedition.ui.exp_power.Text = GetUTF8Text("UI_abilities_explore_strength") .. data.venturePower
  Expedition.ui.power_consume.Text = GetUTF8Text("UI_lobby_stamina_consume") .. GetMatchedUTF8Text(GetUTF8Text("UI_lobby_explore_times") .. "," .. data.fitnessConsumer)
  ExpeditionLookIntroduce.ui.info_text.Text = GetUTF8Text(data.mapInfoKey)
  for i = 1, 8 do
    ExpeditionRoomCreate.slot_item[i].CanSelect = true
  end
  local maxPeopleCount = tonumber(data.maxCount)
  if maxPeopleCount then
    for i = maxPeopleCount + 1, 8 do
      ExpeditionRoomCreate.slot_item[i].CanSelect = false
    end
  end
end, {
  Gui.Control("root")({
    Size = Vector2(431, 280),
    Location = Vector2(97, 36),
    BackgroundColor = colw,
    Skin = SkinF.skin_playgame_033,
    ComFuc.ComPagesBar("page_bar", Vector2(86, 237)),
    Gui.ImageBrowser("ib_map")({
      Location = Vector2(26, 10),
      Size = Vector2(380, 222),
      DisplayRowAndCol = Vector2(2, 2),
      PictureStyle = "Gui.PictureMapInBrowser0",
      Margin = Vector4(0, 0, 0, 0)
    })
  })
}
local CleanText, DealMapInfo = function()
  Expedition.ui.role_level.Text = GetUTF8Text("UI_lobby_explore_Character_level")
  Expedition.ui.count_limit.Text = GetUTF8Text("UI_lobby_people_limit")
  Expedition.ui.exp_power.Text = GetUTF8Text("UI_abilities_explore_strength")
  Expedition.ui.power_consume.Text = GetUTF8Text("UI_lobby_stamina_consume")
  ExpeditionLookIntroduce.ui.info_text.Text = nil
end, Gui.Control("root")({
  Size = Vector2(431, 280),
  Location = Vector2(97, 36),
  BackgroundColor = colw,
  Skin = SkinF.skin_playgame_033,
  ComFuc.ComPagesBar("page_bar", Vector2(86, 237)),
  Gui.ImageBrowser("ib_map")({
    Location = Vector2(26, 10),
    Size = Vector2(380, 222),
    DisplayRowAndCol = Vector2(2, 2),
    PictureStyle = "Gui.PictureMapInBrowser0",
    Margin = Vector4(0, 0, 0, 0)
  })
})
local DealMapInfo, SelMap = function(data)
  ComFuc.venture_info[roomInfoLevelId] = data
  SetUIText(ComFuc.venture_info[roomInfoLevelId])
end, Gui.Control("root")({
  Size = Vector2(431, 280),
  Location = Vector2(97, 36),
  BackgroundColor = colw,
  Skin = SkinF.skin_playgame_033,
  ComFuc.ComPagesBar("page_bar", Vector2(86, 237)),
  Gui.ImageBrowser("ib_map")({
    Location = Vector2(26, 10),
    Size = Vector2(380, 222),
    DisplayRowAndCol = Vector2(2, 2),
    PictureStyle = "Gui.PictureMapInBrowser0",
    Margin = Vector4(0, 0, 0, 0)
  })
})
local SelMap, setup_ui_map_picture = function(pic, need_change)
  mapInfo.Text = pic.Text
  mapInfo.ForeGroundImage = pic.ForeGroundImage
  mapInfo.BeStatic = pic.BeStatic
  Expedition.selectLevel = map_id_of_key[ComFuc.level_difficulty][what_map_name_select]
  print("game mode: " .. game_mode .. ", level map name: " .. what_map_name_select .. ", level map id: " .. map_id_of_key[ComFuc.level_difficulty][what_map_name_select])
  if not need_change then
    local room_info_desc = ptr_new("Client.RoomInfoDesc")
    local state = ptr_cast(game.CurrentState)
    local room_info = state:GetSelfRoomInfo()
    room_info_desc.level_id = map_id_of_key[ComFuc.level_difficulty][what_map_name_select]
    room_info_desc.room_name = room_info.RoomName
    room_info_desc.game_type = room_info.GameType
    room_info_desc.max_client_num = room_info.MaxClientNum
    room_info_desc.spawn_time = 3
    room_info_desc.join_halfway = room_info.JoinHalfWay
    room_info_desc.check_balance = room_info.CheckBalance
    room_info_desc.enter_limit = room_info.EnterLimit
    if string.len(room_info.Password) > 0 then
      room_info_desc.use_password = 1
      room_info_desc.password = room_info.Password
    else
      room_info_desc.use_password = 0
      room_info_desc.password = ""
    end
    local state = ptr_cast(game.CurrentState)
    state:RoomChangeOption(room_info_desc)
  end
  roomInfoLevelId = Expedition.selectLevel
  if ComFuc.venture_info[roomInfoLevelId] and ComFuc.venture_info[roomInfoLevelId].venturePower then
    SetUIText(ComFuc.venture_info[roomInfoLevelId])
  else
    rpc.safecall("player_venture_info", {
      mid = Expedition.selectLevel
    }, DealMapInfo)
  end
end, Gui.Control("root")({
  Size = Vector2(431, 280),
  Location = Vector2(97, 36),
  BackgroundColor = colw,
  Skin = SkinF.skin_playgame_033,
  ComFuc.ComPagesBar("page_bar", Vector2(86, 237)),
  Gui.ImageBrowser("ib_map")({
    Location = Vector2(26, 10),
    Size = Vector2(380, 222),
    DisplayRowAndCol = Vector2(2, 2),
    PictureStyle = "Gui.PictureMapInBrowser0",
    Margin = Vector4(0, 0, 0, 0)
  })
})
local setup_ui_map_picture, OnPageChanged = function(ib, row, col, map_key, need_change)
  local pic = ib:GetDisplayPicture(row, col)
  pic.Text = map_key
  if map_key then
    pic.ForeGroundImage = Icons.PreviewMaps[string.lower(pic.Text)]
  else
    pic.ForeGroundImage = nil
  end
  pic.BeStatic = string.len(pic.Text) == 0
  pic.Highlighted = pic.Text == what_map_name_select
  if pic.Highlighted then
    SelMap(pic, need_change)
  end
  
  function pic.EventClick(sender, e)
    local state = ptr_cast(game.CurrentState)
    local room_info = state:GetSelfRoomInfo()
    if room_info.RoomState == 2 then
      pic.Highlighted = pic.Text == what_map_name_select
      MessageBox.ShowError(GetUTF8Text("msgbox_battlefield_additional_string_133"), show_error_time)
      return
    end
    what_map_name_select = pic.Text
    ib:AllPictureHL(false)
    pic.Highlighted = true
    SelMap(pic)
    if Expedition.expeditionState == 1 then
    else
      local state = ptr_cast(game.CurrentState, "Client.StateLobby")
      state:RequestTeamChangeGameMode(game_mode, map_id_of_key[ComFuc.level_difficulty][what_map_name_select])
    end
  end
end, Gui.Control("root")({
  Size = Vector2(431, 280),
  Location = Vector2(97, 36),
  BackgroundColor = colw,
  Skin = SkinF.skin_playgame_033,
  ComFuc.ComPagesBar("page_bar", Vector2(86, 237)),
  Gui.ImageBrowser("ib_map")({
    Location = Vector2(26, 10),
    Size = Vector2(380, 222),
    DisplayRowAndCol = Vector2(2, 2),
    PictureStyle = "Gui.PictureMapInBrowser0",
    Margin = Vector4(0, 0, 0, 0)
  })
})

function OnPageChanged(ib, game_type, newPage, need_change)
  CleanText()
  local start_map_key_index = ib_display_pic_count * (newPage - 1)
  for row = 1, ib.DisplayRowAndCol.x do
    for col = 1, ib.DisplayRowAndCol.y do
      if bfirsttime == 1 then
        what_map_name_select = map_keys_of_game_type[game_type][ComFuc.level_difficulty][start_map_key_index + 1]
        bfirsttime = 0
      end
      if map_keys_of_game_type[game_type][ComFuc.level_difficulty] then
        setup_ui_map_picture(ib, row, col, map_keys_of_game_type[game_type][ComFuc.level_difficulty][start_map_key_index + (row - 1) * ib.DisplayRowAndCol.y + col], need_change)
      else
        setup_ui_map_picture(ib, row, col, nil, need_change)
      end
    end
  end
end

local findSelectecLevel, SetBattleRoomInfo = function(type, level_id)
  local map_key = CreateRoom.find_map_key_from_id(level_id)
  map_key = map_key or "Level10001"
  local ib = ui.ib_map
  local game_type = game_type_key[type]
  for i = 1, #map_keys_of_game_type[game_type][ComFuc.level_difficulty] do
    if map_key == map_keys_of_game_type[game_type][ComFuc.level_difficulty][i] then
      what_map_name_select = map_key
      local newPage = math.floor(i / ib_display_pic_count)
      if 0 < i % ib_display_pic_count then
        newPage = newPage + 1
      end
      ui.page_bar.CurrIndex = newPage
      OnPageChanged(ib, game_type, newPage, true)
      break
    end
  end
end, function(type, level_id)
  local map_key = CreateRoom.find_map_key_from_id(level_id)
  map_key = map_key or "Level10001"
  local ib = ui.ib_map
  local game_type = game_type_key[type]
  for i = 1, #map_keys_of_game_type[game_type][ComFuc.level_difficulty] do
    if map_key == map_keys_of_game_type[game_type][ComFuc.level_difficulty][i] then
      what_map_name_select = map_key
      local newPage = math.floor(i / ib_display_pic_count)
      if 0 < i % ib_display_pic_count then
        newPage = newPage + 1
      end
      ui.page_bar.CurrIndex = newPage
      OnPageChanged(ib, game_type, newPage, true)
      break
    end
  end
end

function SetBattleRoomInfo(type, mode)
  game_mode = mode
  what_map_name_select = "LEVEL99"
  local ib = ui.ib_map
  local game_type = game_type_key[type]
  bfirsttime = 1
  ib_display_pic_count = ib.DisplayRowAndCol.x * ib.DisplayRowAndCol.y
  ib.Enable = true
  if map_keys_of_game_type[game_type][ComFuc.level_difficulty] then
    ui.page_bar.PageCount = math.ceil(#map_keys_of_game_type[game_type][ComFuc.level_difficulty] / ib_display_pic_count)
  else
    ui.page_bar.PageCount = 0
  end
  ui.page_bar.CurrIndex = 1
  OnPageChanged(ib, game_type, 1)
end

function ui.page_bar.EventIndexChanged(sender, e)
  local state = ptr_cast(game.CurrentState)
  local room_info = state:GetSelfRoomInfo()
  if room_info.RoomState == 2 then
    MessageBox.ShowError(GetUTF8Text("msgbox_battlefield_additional_string_133"), show_error_time)
    return
  end
  local ib = ui.ib_map
  local game_type = game_type_key[Expedition.boss_game_type]
  bfirsttime = 1
  OnPageChanged(ib, game_type, sender.CurrIndex)
end

function SetLevelIdAndMapInfo(level_id)
  local ib = ui.ib_map
  local randowType = {
    map_key_of_map_id[tostring(level_id)],
    nil,
    nil,
    nil,
    nil,
    nil
  }
  what_map_name_select = map_key_of_map_id[tostring(level_id)]
  ib.Enable = false
  for row = 1, ib.DisplayRowAndCol.x do
    for col = 1, ib.DisplayRowAndCol.y do
      setup_ui_map_picture(ib, row, col, randowType[(row - 1) * ib.DisplayRowAndCol.y + col], true)
    end
  end
  ui.page_bar.PageCount = 1
  ui.page_bar.CurrIndex = 1
end

function Show(parent)
  ui.ib_map.PictureStyle = "Gui.PictureMapInBrowser" .. tostring(ComFuc.level_difficulty)
  if not Expedition then
    require("expedition.lua")
  end
  SetBattleRoomInfo(Expedition.boss_game_type, 9)
  if not map_id_of_key[ComFuc.level_difficulty] then
    Expedition.ui.btn_create_room.Enable = false
  else
    Expedition.ui.btn_create_room.Enable = true
  end
  ShowLeves(true)
  ui.root.Parent = parent
end

function IsExist(i)
  local game_type = game_type_key[Expedition.boss_game_type]
  if map_keys_of_game_type[game_type][i] then
    return true
  else
    return false
  end
end

function Hide()
  ui.root.Parent = nil
end
