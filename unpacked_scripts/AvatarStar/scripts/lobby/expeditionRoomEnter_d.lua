module("ExpeditionRoomEnter", package.seeall)
local coly = ComFuc.coly
local roomInfoLevelId, enter_room_info
local difficulty_key = {
  "UI_common_make_06",
  "UI_mission_Normal",
  "UI_mission_Elite"
}
local ok_or_no = {
  "UI_common_kejiaruzhandou_shi",
  "UI_common_kejiaruzhandou_fou"
}
local host_name, map_name, select_diff
ui = Gui.Create()({
  Gui.Control("main")({
    Size = Vector2(1128, 645),
    Gui.Control("room_list_panel")({
      Location = Vector2(373, 52),
      Size = Vector2(748, 585),
      BackgroundColor = ARGB(255, 255, 255, 255),
      Skin = SkinF.personalInfo_124,
      ComFuc.ComControl("game_p", Vector2(1, 1), Vector2(15, 17)),
      ComFuc.ComControl(nil, Vector2(738, 511), Vector2(5, 2), 255, SkinF.battle_005),
      ComFuc.ComIconButton("btn_backto_battle", Vector2(128, 56), Vector2(10, 513), SkinF.icon_playgame_004, GetUTF8Text("button_common_Cancel"), SkinF.select_character_038),
      ComFuc.ComIcon2Button("btn_enter_room", Vector2(184, 60), Vector2(457, 513), SkinF.icon_playgame_003, GetUTF8Text("button_common_Room_Enter"), SkinF.SkinStartGame),
      Gui.ListTreeView("list")({
        Style = "Gui.AvatarListTreeView",
        Size = Vector2(726, 458),
        Location = Vector2(10, 45)
      }),
      Gui.Control({
        Location = Vector2(10, 5),
        Size = Vector2(720, 35),
        ComFuc.ComLabel(nil, GetUTF8Text("UI_battlefield_Host"), Vector2(63, 24), Vector2(5, 5), 0, 16, ComFuc.word_color, "kAlignRightMiddle"),
        ComFuc.ComTextBox("host_name", nil, Vector2(130, 30), Vector2(75, 2), 28),
        ComFuc.ComLabel(nil, GetUTF8Text("UI_battlefield_Map"), Vector2(63, 24), Vector2(210, 5), 0, 16, ComFuc.word_color, "kAlignRightMiddle"),
        ComFuc.ComTextBox("map_name", nil, Vector2(130, 30), Vector2(285, 2), 20),
        ComFuc.ComLabel(nil, GetUTF8Text("UI_grade_explore_copy_difficulty"), Vector2(73, 24), Vector2(420, 5), 0, 16, ComFuc.word_color, "kAlignRightMiddle"),
        ComFuc.ComComboBox("map_difficulty", Vector2(100, 30), Vector2(500, 4)),
        ComFuc.ComButton("search", GetUTF8Text("UI_common_Search"), Vector2(50, 30), Vector2(650, 5), 16, false, false)
      })
    }),
    Gui.Control("pic_area")({
      Size = Vector2(374, 281),
      Location = Vector2(15, 46),
      BackgroundColor = ARGB(255, 255, 255, 255),
      Skin = SkinF.skin_playgame_023,
      ComFuc.ComLabel(nil, GetUTF8Text("UI_lobby_explore_Character_level"), Vector2(99, 20), Vector2(38, 182), 0, 14, colw),
      ComFuc.ComLabel("lbl_room_name", nil, Vector2(187, 20), Vector2(147, 182), 0, 14, coly),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_lobby_people_limit"), Vector2(99, 20), Vector2(38, 203), 0, 14, colw),
      ComFuc.ComLabel("lbl_host_name", nil, Vector2(187, 20), Vector2(147, 203), 0, 14, coly),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_abilities_explore_strength"), Vector2(99, 20), Vector2(38, 224), 0, 14, colw),
      ComFuc.ComLabel("lbl_game_mode", nil, Vector2(187, 20), Vector2(147, 224), 0, 14, coly),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_lobby_stamina_consume"), Vector2(99, 20), Vector2(38, 245), 0, 14, colw),
      ComFuc.ComLabel("lbl_player_limits", nil, Vector2(187, 20), Vector2(147, 245), 0, 14, coly),
      Gui.Picture("pic_map")({
        Size = Vector2(306, 172),
        Location = Vector2(34, 9),
        KeepAspect = true,
        ForeGroundImage = nil
      })
    })
  })
})
ui.btn_enter_room.ClickAudio = "roomenter"
ui.list.Columns.Clickable = true
ui.list:AddColumn(GetUTF8Text("UI_battlefield_NO_room"), 53, "kAlignCenterMiddle")
ui.list:AddColumn(GetUTF8Text("UI_battlefield_State"), 61, "kAlignCenterMiddle")
ui.list:AddColumn(GetUTF8Text("UI_battlefield_Host"), 164, "kAlignLeftMiddle")
ui.list:AddColumn(GetUTF8Text("UI_common_kejiaruzhandou"), 100, "kAlignLeftMiddle")
ui.list:AddColumn(GetUTF8Text("UI_battlefield_Map"), 152, "kAlignLeftMiddle")
ui.list:AddColumn(GetUTF8Text("UI_grade_explore_copy_difficulty"), 100, "kAlignLeftMiddle")
ui.list:AddColumn(GetUTF8Text("UI_battlefield_Size"), 66, "kAlignLeftMiddle")
ui.list.Columns:SetAlign(1, "kAlignCenterMiddle")
ui.list.Columns.TextColor = ARGB(255, 255, 255, 255)
ui.list.Columns.TextShadowColor = ARGB(150, 0, 0, 0)
ui.list.Columns.FontSize = 16
ui.list.ItemClickAudio = "roomselected"
ui.map_difficulty:RemoveAll()
for i = 1, #difficulty_key do
  ui.map_difficulty:AddItem(GetUTF8Text(difficulty_key[i]))
end

function ClearSearch()
  ui.host_name.Text = nil
  ui.map_name.Text = nil
  if 0 < #difficulty_key then
    ui.map_difficulty.SelectedIndex = 0
  end
  host_name = nil
  map_name = nil
  select_diff = nil
end

function format_room_uid(uid)
  return string.format("%c%d", 64 + bit.bshift(uid, -16), bit.band(uid, 65535))
end

function UpdateRoomInfoItem(item, room_info)
  for i = 0, 6 do
    item:SetTextColor(i, ARGB(255, 81, 59, 45))
    item:SetHighLightTextColor(i, ARGB(255, 81, 59, 45))
  end
  if room_info.UsePassword then
    item:SetIcon(1, IconsF.RoomStatusIcons.PasswordN)
  elseif room_info.MaxClientNum <= room_info.CurrentClientNum then
    item:SetIcon(1, IconsF.RoomStatusIcons.FullN)
  elseif room_info.RoomState == 1 then
    item:SetIcon(1, IconsF.RoomStatusIcons.WaitingN)
  elseif room_info.RoomState == 2 then
    item:SetIcon(1, IconsF.RoomStatusIcons.PlayingN)
  end
  item:SetText(2, room_info.HostName)
  local enter_limit = room_info.EnterLimit
  local key = ok_or_no[1]
  if bit.band(enter_limit, 2) ~= 2 then
    key = ok_or_no[2]
  end
  item:SetText(3, GetUTF8Text(key))
  item:SetText(4, CreateRoom.map_show_name_of_map_id[room_info.LevelId])
  item:SetText(5, GetUTF8Text(ComFuc.difficulty_list[CreateRoom.map_difficulty_of_map_id[room_info.LevelId] + 1]))
  item:SetText(6, string.format("%d/%d", room_info.CurrentClientNum, room_info.MaxClientNum), false)
  item.Tag = room_info
end

local selected_uid
local RefreshRoomList, ReachLimit = function(game_type)
  local state = ptr_cast(game.CurrentState)
  if state then
    local list = ui.list
    local root = list.RootItem
    if list.SelectedItem then
      local room_info = ptr_cast(list.SelectedItem.Tag)
      if room_info then
        selected_uid = room_info.RoomUid
      end
    end
    list:DeleteAll()
    for i = 0, state:GetRoomCount() - 1 do
      local room_info = state:GetRoomInfo(i)
      if game_type == "kNone" or game_type == room_info.GameType then
        local flag = true
        local a
        if host_name ~= nil and host_name ~= "" then
          a = string.find(room_info.HostName, host_name)
          if not a then
            flag = false
          end
        end
        if map_name ~= nil and map_name ~= "" then
          local temp = CreateRoom.map_show_name_of_map_id[room_info.LevelId]
          a = string.find(temp, map_name)
          if not a then
            flag = false
          end
        end
        if select_diff ~= nil and select_diff ~= "" then
          local temp = GetUTF8Text(ComFuc.difficulty_list[CreateRoom.map_difficulty_of_map_id[room_info.LevelId] + 1])
          a = string.find(temp, select_diff)
          if not a then
            flag = false
          end
        end
        if flag then
          local item = list:AddItem(root, format_room_uid(room_info.RoomUid))
          UpdateRoomInfoItem(item, room_info)
          if selected_uid and selected_uid == room_info.RoomUid then
            list.SelectedItemNoScroll = item
          end
        end
      end
    end
    list:Ready()
  end
end, function(game_type)
  local state = ptr_cast(game.CurrentState)
  if state then
    local list = ui.list
    local root = list.RootItem
    if list.SelectedItem then
      local room_info = ptr_cast(list.SelectedItem.Tag)
      if room_info then
        selected_uid = room_info.RoomUid
      end
    end
    list:DeleteAll()
    for i = 0, state:GetRoomCount() - 1 do
      local room_info = state:GetRoomInfo(i)
      if game_type == "kNone" or game_type == room_info.GameType then
        local flag = true
        local a
        if host_name ~= nil and host_name ~= "" then
          a = string.find(room_info.HostName, host_name)
          if not a then
            flag = false
          end
        end
        if map_name ~= nil and map_name ~= "" then
          local temp = CreateRoom.map_show_name_of_map_id[room_info.LevelId]
          a = string.find(temp, map_name)
          if not a then
            flag = false
          end
        end
        if select_diff ~= nil and select_diff ~= "" then
          local temp = GetUTF8Text(ComFuc.difficulty_list[CreateRoom.map_difficulty_of_map_id[room_info.LevelId] + 1])
          a = string.find(temp, select_diff)
          if not a then
            flag = false
          end
        end
        if flag then
          local item = list:AddItem(root, format_room_uid(room_info.RoomUid))
          UpdateRoomInfoItem(item, room_info)
          if selected_uid and selected_uid == room_info.RoomUid then
            list.SelectedItemNoScroll = item
          end
        end
      end
    end
    list:Ready()
  end
end

function ReachLimit(data)
  ComFuc.venture_info[roomInfoLevelId] = data
  local enter_limit = enter_room_info.EnterLimit
  local check = true
  if bit.band(enter_limit, 1) ~= 1 then
    check = false
  end
  if check then
    if ComFuc.globalLV < data.level then
      MessageBox.ShowWithTwoButtons(GetMatchedUTF8Text("UI_lobby_explore_bility_lack" .. "," .. GetUTF8Text("UI_lobby_Level")), GetUTF8Text("button_common_OK"))
    elseif ComFuc.globalVF < data.venturePower then
      MessageBox.ShowWithTwoButtons(GetMatchedUTF8Text("UI_lobby_explore_bility_lack" .. "," .. GetUTF8Text("tips_lobby_explore_strength_tips")), GetUTF8Text("button_common_OK"))
    elseif ComFuc.globalFV < data.fitnessConsumer then
      MessageBox.ShowWithTwoButtons(GetMatchedUTF8Text("msgbox_lobby_explore_stamina_lack"), GetUTF8Text("button_common_OK"))
    else
      check = false
    end
  end
  if not check then
    gui:PlayAudio("room_enter")
    local state = ptr_cast(game.CurrentState)
    if enter_room_info.CurrentClientNum < enter_room_info.MaxClientNum then
      if enter_room_info.UsePassword then
        if not InputBox then
          require("inputBox.lua")
        end
        InputBox.Show(GetUTF8Text("UI_common_Enter_room_password"), GetUTF8Text("UI_common_Enter_room_password"), function(room_password)
          MessageBox.ShowWaiter(GetUTF8Text("msgbox_common_num_1295"))
          state:EnterRoom(enter_room_info.RoomUid, room_password)
        end, ComFuc.password_max_length)
      else
        MessageBox.ShowWaiter(GetUTF8Text("msgbox_common_num_1295"))
        state:EnterRoom(enter_room_info.RoomUid, "")
      end
    else
      MessageBox.ShowError(GetUTF8Text("msgbox_common_num_1193"))
    end
  end
end

function CanEnterRoom()
  roomInfoLevelId = enter_room_info.LevelId
  if ComFuc.venture_info[roomInfoLevelId] and ComFuc.venture_info[roomInfoLevelId].venturePower then
    ReachLimit(ComFuc.venture_info[roomInfoLevelId])
  else
    rpc.safecall("player_venture_info", {
      mid = enter_room_info.LevelId
    }, ReachLimit)
  end
end

local EnterRoom, SetLBLText = function(item)
  enter_room_info = ptr_cast(item.Tag)
  if enter_room_info then
    CanEnterRoom()
  end
end, function(item)
  enter_room_info = ptr_cast(item.Tag)
  if enter_room_info then
    CanEnterRoom()
  end
end
local SetLBLText, GiveVentureInfo = function(data)
  ui.lbl_room_name.Text = GetUTF8Text("UI_lobby_explore_Character_level") .. GetMatchedUTF8Text(GetUTF8Text("UI_lobby_role_grade") .. "," .. data.level)
  ui.lbl_host_name.Text = GetUTF8Text("UI_lobby_people_limit") .. GetMatchedUTF8Text(GetUTF8Text("UI_lobby_rol_number") .. "," .. data.minCount .. "-" .. data.maxCount)
  ui.lbl_game_mode.Text = GetUTF8Text("UI_abilities_explore_strength") .. data.venturePower
  ui.lbl_player_limits.Text = GetUTF8Text("UI_lobby_stamina_consume") .. GetMatchedUTF8Text(GetUTF8Text("UI_lobby_explore_times") .. "," .. data.fitnessConsumer)
end, 0

function GiveVentureInfo(data)
  ComFuc.venture_info[roomInfoLevelId] = data
  SetLBLText(ComFuc.venture_info[roomInfoLevelId])
end

function UpdateRoomInfoPanel(room_info)
  local map_key = CreateRoom.find_map_key_from_id(room_info.LevelId)
  if map_key then
    ui.pic_map.ForeGroundImage = Icons.PreviewMaps[string.lower(map_key)]
  else
    ui.pic_map.ForeGroundImage = Icons.PreviewMaps.level_random
  end
  roomInfoLevelId = room_info.LevelId
  if ComFuc.venture_info[roomInfoLevelId] and ComFuc.venture_info[roomInfoLevelId].venturePower then
    SetLBLText(ComFuc.venture_info[roomInfoLevelId])
  else
    rpc.safecall("player_venture_info", {
      mid = room_info.LevelId
    }, GiveVentureInfo)
  end
end

function ui.list.Columns.EventItemClick(sender, e)
  local state = ptr_cast(game.CurrentState)
  if state then
    ui.list:SortColumnExt(e.Column, false, state:GetRoomListCompareFunc())
  else
    print("state not valid when sorting rooms")
  end
end

function ui.list.EventDoubleClick(sender, e)
  gui:PlayAudio("roomenter")
  local item = sender.SelectedItem
  if item then
    EnterRoom(item)
  end
end

function ui.list.EventNodeMouseEnter(sender, e)
  if e.Item then
    local item = e.Item
    local room_info = ptr_cast(item.Tag)
    UpdateRoomInfoPanel(room_info)
    ui.pic_area.Parent = gui
    ui.pic_area.Location = ui.list:CalculateTipLocation(item, ui.pic_area.Size)
  end
end

function ui.list.EventNodeMouseLeave(sender, e)
  ui.pic_area.Parent = nil
end

function ui.btn_backto_battle.EventClick(sender, e)
  Hide()
  LobbyStartGame.SelectMainBtn(3)
end

function ui.btn_enter_room.EventClick(sender, e)
  local item = ui.list.SelectedItem
  if item then
    EnterRoom(item)
  else
    MessageBox.ShowError(GetUTF8Text("msgbox_battlefield_additional_string_131"))
  end
end

function Show(winRoot)
  ClearSearch()
  if not winRoot then
    Hide()
  else
    LobbyPlayGame.RequestRoomList()
    Expedition.expeditionState = 3
    RefreshRoomList("kBoss")
    ui.pic_area.Parent = nil
    ui.main.Parent = winRoot
  end
end

function Hide()
  ui.main.Parent = nil
end

function ui.search.EventClick(sender, e)
  host_name = ui.host_name.Text
  map_name = ui.map_name.Text
  if ui.map_difficulty.SelectedIndex == 0 then
    select_diff = nil
  else
    select_diff = GetUTF8Text(difficulty_key[ui.map_difficulty.SelectedIndex + 1])
  end
  RefreshRoomList("kBoss")
end
