module("ExpeditionRoomCreate", package.seeall)
if not ExpeditionRoomSet then
  require("expeditionRoomSet.lua")
end
local colw = ComFuc.colw
local colt = ComFuc.colt
local col0 = ComFuc.col0
local isHostMan = false
local old_password = ""
slot_item = {}
local ui, InitUI = Gui.Create()({
  ComFuc.ComControl("coverControl2", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(100, 0, 0, 0)),
  Gui.Control("main")({
    Size = Vector2(1128, 645),
    Gui.Control("plane_2")({
      Size = Vector2(1128, 645),
      Gui.Control({
        Size = Vector2(701, 144),
        Location = Vector2(8, 494),
        Gui.NewMessagePanel("msg_panel")({
          Size = Vector2(701, 105),
          BackgroundColor = colw,
          Skin = SkinF.battle_013,
          Style = "LobbyBattleGame.MessagePanel",
          MaxTextWidth = 670,
          OnePageLineNum = 4,
          LineGap = 1
        }),
        Gui.Control({
          Size = Vector2(701, 38),
          Location = Vector2(0, 106),
          BackgroundColor = colw,
          Skin = SkinF.battle_012,
          ComFuc.ComButton("send_btn", GetUTF8Text("button_common_Send"), Vector2(64, 32), Vector2(630, 3), 16, false, false),
          ComFuc.ComTextBox("input_box", "", Vector2(630, 28), Vector2(3, 6), 80)
        })
      }),
      Gui.Control({
        Location = Vector2(713, 45),
        Size = Vector2(405, 586),
        BackgroundColor = colw,
        Skin = SkinF.personalInfo_206,
        ComFuc.ComLabel("room_name", nil, Vector2(200, 21), Vector2(10, 3), 0, 16, colw, "kAlignLeftMiddle"),
        ComFuc.ComLabel(nil, GetUTF8Text("UI_battlefield_Room_Password"), Vector2(90, 21), Vector2(240, 3), 0, 16, ComFuc.coly, "kAlignRightMiddle"),
        ComFuc.ComLabel("tb_password", nil, Vector2(60, 21), Vector2(340, 3), 0, 16, ComFuc.coly, "kAlignLeftMiddle"),
        ComFuc.ComIconButton("b_back", Vector2(114, 56), Vector2(15, 445), SkinF.icon_playgame_004, GetUTF8Text("button_common_Back"), SkinF.select_character_038),
        ComFuc.ComIconButton("b_invite", Vector2(114, 56), Vector2(145, 445), SkinF.icon_playgame_005, GetUTF8Text("button_common_Invite"), SkinF.select_character_038),
        ComFuc.ComIconButton("b_set", Vector2(114, 56), Vector2(275, 445), SkinF.icon_playgame_012, GetUTF8Text("button_common_Setting"), SkinF.select_character_038),
        ComFuc.ComIcon2Button("b_start", Vector2(141, 60), Vector2(118, 515), SkinF.icon_playgame_007, GetUTF8Text("button_lobby_enter_map"), SkinF.SkinStartGame),
        Gui.Control({
          Location = Vector2(10, 35),
          Size = Vector2(385, 398),
          BackgroundColor = colw,
          Skin = SkinF.battle_005,
          Gui.ListTreeView("member_list")({
            Style = "Gui.AvatarListTreeView002",
            ItemGap = 1,
            Size = Vector2(368, 400),
            Location = Vector2(9, 13)
          })
        })
      })
    })
  })
}), Gui.Create()({
  ComFuc.ComControl("coverControl2", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(100, 0, 0, 0)),
  Gui.Control("main")({
    Size = Vector2(1128, 645),
    Gui.Control("plane_2")({
      Size = Vector2(1128, 645),
      Gui.Control({
        Size = Vector2(701, 144),
        Location = Vector2(8, 494),
        Gui.NewMessagePanel("msg_panel")({
          Size = Vector2(701, 105),
          BackgroundColor = colw,
          Skin = SkinF.battle_013,
          Style = "LobbyBattleGame.MessagePanel",
          MaxTextWidth = 670,
          OnePageLineNum = 4,
          LineGap = 1
        }),
        Gui.Control({
          Size = Vector2(701, 38),
          Location = Vector2(0, 106),
          BackgroundColor = colw,
          Skin = SkinF.battle_012,
          ComFuc.ComButton("send_btn", GetUTF8Text("button_common_Send"), Vector2(64, 32), Vector2(630, 3), 16, false, false),
          ComFuc.ComTextBox("input_box", "", Vector2(630, 28), Vector2(3, 6), 80)
        })
      }),
      Gui.Control({
        Location = Vector2(713, 45),
        Size = Vector2(405, 586),
        BackgroundColor = colw,
        Skin = SkinF.personalInfo_206,
        ComFuc.ComLabel("room_name", nil, Vector2(200, 21), Vector2(10, 3), 0, 16, colw, "kAlignLeftMiddle"),
        ComFuc.ComLabel(nil, GetUTF8Text("UI_battlefield_Room_Password"), Vector2(90, 21), Vector2(240, 3), 0, 16, ComFuc.coly, "kAlignRightMiddle"),
        ComFuc.ComLabel("tb_password", nil, Vector2(60, 21), Vector2(340, 3), 0, 16, ComFuc.coly, "kAlignLeftMiddle"),
        ComFuc.ComIconButton("b_back", Vector2(114, 56), Vector2(15, 445), SkinF.icon_playgame_004, GetUTF8Text("button_common_Back"), SkinF.select_character_038),
        ComFuc.ComIconButton("b_invite", Vector2(114, 56), Vector2(145, 445), SkinF.icon_playgame_005, GetUTF8Text("button_common_Invite"), SkinF.select_character_038),
        ComFuc.ComIconButton("b_set", Vector2(114, 56), Vector2(275, 445), SkinF.icon_playgame_012, GetUTF8Text("button_common_Setting"), SkinF.select_character_038),
        ComFuc.ComIcon2Button("b_start", Vector2(141, 60), Vector2(118, 515), SkinF.icon_playgame_007, GetUTF8Text("button_lobby_enter_map"), SkinF.SkinStartGame),
        Gui.Control({
          Location = Vector2(10, 35),
          Size = Vector2(385, 398),
          BackgroundColor = colw,
          Skin = SkinF.battle_005,
          Gui.ListTreeView("member_list")({
            Style = "Gui.AvatarListTreeView002",
            ItemGap = 1,
            Size = Vector2(368, 400),
            Location = Vector2(9, 13)
          })
        })
      })
    })
  })
})
local InitUI, InitItemMenu = function()
  local list = ui.member_list
  list.Columns.Clickable = false
  list.Columns.Movable = false
  list:AddColumn("", 40, "kAlignCenterMiddle")
  list:AddColumn("", 40, "kAlignCenterMiddle")
  list:AddColumn("", 174, "kAlignLeftMiddle")
  list:AddColumn("", 100, "kAlignLeftMiddle")
  list.Columns.TextColor = ARGB(255, 255, 255, 255)
  list.Columns.FontSize = 16
  local root = list.RootItem
  for i = 1, 8 do
    local item = list:AddItem(root, "")
    item.ID = i
    item:AddSubItem("")
    item:AddSubItem("")
    item:AddSubItem("")
    item:SetTextColor(0, ARGB(255, 81, 59, 45))
    item:SetTextColor(1, ARGB(255, 81, 59, 45))
    item:SetTextColor(2, ARGB(255, 81, 59, 45))
    item:SetHighLightTextColor(0, ARGB(255, 81, 59, 45))
    item:SetHighLightTextColor(1, ARGB(255, 81, 59, 45))
    item:SetHighLightTextColor(2, ARGB(255, 81, 59, 45))
    table.insert(slot_item, item)
  end
  ui.b_start.ClickAudio = ""
end, {
  ComFuc.ComControl("coverControl2", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(100, 0, 0, 0)),
  Gui.Control("main")({
    Size = Vector2(1128, 645),
    Gui.Control("plane_2")({
      Size = Vector2(1128, 645),
      Gui.Control({
        Size = Vector2(701, 144),
        Location = Vector2(8, 494),
        Gui.NewMessagePanel("msg_panel")({
          Size = Vector2(701, 105),
          BackgroundColor = colw,
          Skin = SkinF.battle_013,
          Style = "LobbyBattleGame.MessagePanel",
          MaxTextWidth = 670,
          OnePageLineNum = 4,
          LineGap = 1
        }),
        Gui.Control({
          Size = Vector2(701, 38),
          Location = Vector2(0, 106),
          BackgroundColor = colw,
          Skin = SkinF.battle_012,
          ComFuc.ComButton("send_btn", GetUTF8Text("button_common_Send"), Vector2(64, 32), Vector2(630, 3), 16, false, false),
          ComFuc.ComTextBox("input_box", "", Vector2(630, 28), Vector2(3, 6), 80)
        })
      }),
      Gui.Control({
        Location = Vector2(713, 45),
        Size = Vector2(405, 586),
        BackgroundColor = colw,
        Skin = SkinF.personalInfo_206,
        ComFuc.ComLabel("room_name", nil, Vector2(200, 21), Vector2(10, 3), 0, 16, colw, "kAlignLeftMiddle"),
        ComFuc.ComLabel(nil, GetUTF8Text("UI_battlefield_Room_Password"), Vector2(90, 21), Vector2(240, 3), 0, 16, ComFuc.coly, "kAlignRightMiddle"),
        ComFuc.ComLabel("tb_password", nil, Vector2(60, 21), Vector2(340, 3), 0, 16, ComFuc.coly, "kAlignLeftMiddle"),
        ComFuc.ComIconButton("b_back", Vector2(114, 56), Vector2(15, 445), SkinF.icon_playgame_004, GetUTF8Text("button_common_Back"), SkinF.select_character_038),
        ComFuc.ComIconButton("b_invite", Vector2(114, 56), Vector2(145, 445), SkinF.icon_playgame_005, GetUTF8Text("button_common_Invite"), SkinF.select_character_038),
        ComFuc.ComIconButton("b_set", Vector2(114, 56), Vector2(275, 445), SkinF.icon_playgame_012, GetUTF8Text("button_common_Setting"), SkinF.select_character_038),
        ComFuc.ComIcon2Button("b_start", Vector2(141, 60), Vector2(118, 515), SkinF.icon_playgame_007, GetUTF8Text("button_lobby_enter_map"), SkinF.SkinStartGame),
        Gui.Control({
          Location = Vector2(10, 35),
          Size = Vector2(385, 398),
          BackgroundColor = colw,
          Skin = SkinF.battle_005,
          Gui.ListTreeView("member_list")({
            Style = "Gui.AvatarListTreeView002",
            ItemGap = 1,
            Size = Vector2(368, 400),
            Location = Vector2(9, 13)
          })
        })
      })
    })
  })
}
local InitItemMenu, Init = function()
  local list = ui.member_list
  ComFuc.InitSocialityMenu(list.PopupMenu, {
    {
      "IDM_KICK_OUT",
      GetUTF8Text("button_common_Kick_from_Room"),
      function()
        local state = ptr_cast(game.CurrentState, "Client.StateLobby")
        if state and not state.Matching then
          local state = ptr_cast(game.CurrentState)
          state:RoomKickClient(ptr_cast(list.SelectedItem.Tag).slot_id)
          MessageBox.ShowWaiter(GetUTF8Text("msgbox_battlefield_additional_string_135"))
        end
      end
    },
    {
      "IDM_BEG_WISPER",
      GetUTF8Text("button_common_Chat"),
      function()
        local client_info = ptr_cast(list.SelectedItem.Tag)
        ChatBar.OpenFriendChatPair(client_info.character_id, client_info.character_name)
      end
    },
    {
      "IDM_ADD_FRIEND",
      GetUTF8Text("button_common_Add_Friend"),
      function()
        local client_info = ptr_cast(list.SelectedItem.Tag)
        Sociality.AddFriend(client_info.character_id, client_info.level)
      end
    },
    {
      "IDM_VIEW_PERSONALITY",
      GetUTF8Text("button_common_Info"),
      function()
        local client_info = ptr_cast(list.SelectedItem.Tag)
        LookInfo.Show(client_info.character_id)
      end
    },
    {
      "IDM_COPY_NAME",
      GetUTF8Text("tips_social_copy_name"),
      function()
        local client_info = ptr_cast(list.SelectedItem.Tag)
        Sociality.CopyName(client_info.character_name)
      end
    }
  })
  
  function EnableMenuItem(menu, ids, enable)
    for k, v in pairs(ids) do
      menu:SetEnable(v, enable)
    end
  end
  
  function list.EventRightClick(sender, e)
    if sender.SelectedItem and sender.SelectedItem.Tag then
      local client_info = ptr_cast(sender.SelectedItem.Tag)
      local state = ptr_cast(game.CurrentState, "Client.StateLobby")
      local my_id = state:GetCharacterId()
      if client_info.character_id == my_id then
        EnableMenuItem(sender.PopupMenu, {1, 2}, false)
        EnableMenuItem(sender.PopupMenu, {3}, true)
      else
        EnableMenuItem(sender.PopupMenu, {1, 2}, true)
        EnableMenuItem(sender.PopupMenu, {3}, true)
      end
      if client_info.character_id ~= my_id and isHostMan then
        if state and state.Matching then
          EnableMenuItem(sender.PopupMenu, {0}, false)
        else
          EnableMenuItem(sender.PopupMenu, {0}, true)
        end
      else
        EnableMenuItem(sender.PopupMenu, {0}, false)
      end
      if client_info.character_id ~= my_id then
        EnableMenuItem(sender.PopupMenu, {4}, true)
      end
      sender.PopupMenu:Open()
    else
      EnableMenuItem(sender.PopupMenu, {
        0,
        1,
        2,
        3,
        4
      }, false)
    end
  end
end, ComFuc.ComControl("coverControl2", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(100, 0, 0, 0))

function Init()
  InitUI()
  InitItemMenu()
end

Init()

function ChangeRoomOption(password, enter_limit)
  local state = ptr_cast(game.CurrentState)
  local room_info = state:GetSelfRoomInfo()
  if room_info.RoomState == 2 and isHostMan and false then
    MessageBox.ShowError(GetUTF8Text("msgbox_battlefield_additional_string_133"), show_error_time)
    return
  end
  local room_info_desc = ptr_new("Client.RoomInfoDesc")
  room_info_desc.room_name = room_info.RoomName
  room_info_desc.game_type = room_info.GameType
  room_info_desc.level_id = room_info.LevelId
  room_info_desc.max_client_num = room_info.MaxClientNum
  room_info_desc.spawn_time = 3
  room_info_desc.join_halfway = room_info.JoinHalfWay
  room_info_desc.check_balance = room_info.CheckBalance
  room_info_desc.enter_limit = enter_limit
  if string.len(password) > 0 then
    room_info_desc.use_password = 1
    room_info_desc.password = password
  else
    room_info_desc.use_password = 0
    room_info_desc.password = ""
  end
  if isHostMan then
    state:RoomChangeOption(room_info_desc)
  end
end

local UpdateInRoomButtonState, SendChatText = function(self_character_info, room_info)
  ComFuc.is_in_room = true
  local state = ptr_cast(game.CurrentState)
  local room_info = state:GetSelfRoomInfo()
  ui.b_invite.Visible = self_character_info.host
  ui.b_set.Visible = self_character_info.host
  if not ExpeditionRoom then
    require("expeditionRoom.lua")
  end
  ExpeditionRoom.ShowLeves(true)
  if not Expedition then
    require("expedition.lua")
  end
  Expedition.ui.selected_level_background.Visible = false
  if not ExpeditionRoom then
    require("expeditionRoom.lua")
  end
  ExpeditionRoom.ui.root.Visible = true
  if room_info.RoomState == 2 then
    if self_character_info.ready and not self_character_info.host then
    else
      ui.b_start_lbl.Text = GetUTF8Text("button_common_Join")
      ui.b_start_lbl.Icon = SkinF.icon_playgame_007
      ComFuc.isReadyStart = false
      
      function ui.b_start.EventClick(sender, e)
        if LobbyPlayGame.CheckEquipment() then
          Expedition.SetLimitText(true, true)
          local state = ptr_cast(game.CurrentState)
          gui:PlayAudio("game_launch")
        end
      end
    end
  elseif self_character_info.host then
    ui.b_start_lbl.Text = GetUTF8Text("UI_common_Start_Game")
    ui.b_start_lbl.Icon = SkinF.icon_playgame_007
    ComFuc.isReadyStart = false
    
    function ui.b_start.EventClick(sender, e)
      local state = ptr_cast(game.CurrentState)
      gui:PlayAudio("game_launch")
      if LobbyPlayGame.CheckEquipment() then
        Expedition.SetLimitText(true)
        local state = ptr_cast(game.CurrentState)
        gui:PlayAudio("game_launch")
      end
    end
  elseif self_character_info.ready then
    ui.b_start_lbl.Text = GetUTF8Text("button_common_Cancel_Ready")
    ui.b_start_lbl.Icon = SkinF.icon_playgame_008
    ComFuc.isReadyStart = true
    
    function ui.b_start.EventClick(sender, e)
      gui:PlayAudio("game_launch_ready")
      MessageBox.ShowWaiter(GetUTF8Text("msgbox_battlefield_additional_string_137"))
      state:Ready(false)
    end
  else
    ui.b_start_lbl.Text = GetUTF8Text("button_battlefield_additional_string_138")
    ui.b_start_lbl.Icon = SkinF.icon_playgame_009
    ComFuc.isReadyStart = false
    
    function ui.b_start.EventClick(sender, e)
      gui:PlayAudio("game_launch_ready")
      if not LobbyPlayGame then
        require("playgame.lua")
      end
      if LobbyPlayGame.CheckEquipment() then
        MessageBox.ShowWaiter(GetUTF8Text("msgbox_battlefield_additional_string_139"))
        state:Ready(true)
      end
    end
  end
  isHostMan = self_character_info.host
  if room_info and not isHostMan then
    Expedition.ShowSelectLevel(room_info.LevelId)
    ExpeditionRoom.findSelectecLevel(Expedition.boss_game_type, room_info.LevelId)
    ExpeditionRoom.ShowLeves(false)
    if not ExpeditionLookIntroduce then
      require("expeditionLookIntroduce.lua")
    end
    if ExpeditionLookIntroduce.ui.main.Parent then
      ExpeditionLookIntroduce.pic.ForeGroundImage = Expedition.ui.selected_level.ForeGroundImage
    end
  end
  Expedition.ShowLevelDifficultyButton()
end, function(self_character_info, room_info)
  ComFuc.is_in_room = true
  local state = ptr_cast(game.CurrentState)
  local room_info = state:GetSelfRoomInfo()
  ui.b_invite.Visible = self_character_info.host
  ui.b_set.Visible = self_character_info.host
  if not ExpeditionRoom then
    require("expeditionRoom.lua")
  end
  ExpeditionRoom.ShowLeves(true)
  if not Expedition then
    require("expedition.lua")
  end
  Expedition.ui.selected_level_background.Visible = false
  if not ExpeditionRoom then
    require("expeditionRoom.lua")
  end
  ExpeditionRoom.ui.root.Visible = true
  if room_info.RoomState == 2 then
    if self_character_info.ready and not self_character_info.host then
    else
      ui.b_start_lbl.Text = GetUTF8Text("button_common_Join")
      ui.b_start_lbl.Icon = SkinF.icon_playgame_007
      ComFuc.isReadyStart = false
      
      function ui.b_start.EventClick(sender, e)
        if LobbyPlayGame.CheckEquipment() then
          Expedition.SetLimitText(true, true)
          local state = ptr_cast(game.CurrentState)
          gui:PlayAudio("game_launch")
        end
      end
    end
  elseif self_character_info.host then
    ui.b_start_lbl.Text = GetUTF8Text("UI_common_Start_Game")
    ui.b_start_lbl.Icon = SkinF.icon_playgame_007
    ComFuc.isReadyStart = false
    
    function ui.b_start.EventClick(sender, e)
      local state = ptr_cast(game.CurrentState)
      gui:PlayAudio("game_launch")
      if LobbyPlayGame.CheckEquipment() then
        Expedition.SetLimitText(true)
        local state = ptr_cast(game.CurrentState)
        gui:PlayAudio("game_launch")
      end
    end
  elseif self_character_info.ready then
    ui.b_start_lbl.Text = GetUTF8Text("button_common_Cancel_Ready")
    ui.b_start_lbl.Icon = SkinF.icon_playgame_008
    ComFuc.isReadyStart = true
    
    function ui.b_start.EventClick(sender, e)
      gui:PlayAudio("game_launch_ready")
      MessageBox.ShowWaiter(GetUTF8Text("msgbox_battlefield_additional_string_137"))
      state:Ready(false)
    end
  else
    ui.b_start_lbl.Text = GetUTF8Text("button_battlefield_additional_string_138")
    ui.b_start_lbl.Icon = SkinF.icon_playgame_009
    ComFuc.isReadyStart = false
    
    function ui.b_start.EventClick(sender, e)
      gui:PlayAudio("game_launch_ready")
      if not LobbyPlayGame then
        require("playgame.lua")
      end
      if LobbyPlayGame.CheckEquipment() then
        MessageBox.ShowWaiter(GetUTF8Text("msgbox_battlefield_additional_string_139"))
        state:Ready(true)
      end
    end
  end
  isHostMan = self_character_info.host
  if room_info and not isHostMan then
    Expedition.ShowSelectLevel(room_info.LevelId)
    ExpeditionRoom.findSelectecLevel(Expedition.boss_game_type, room_info.LevelId)
    ExpeditionRoom.ShowLeves(false)
    if not ExpeditionLookIntroduce then
      require("expeditionLookIntroduce.lua")
    end
    if ExpeditionLookIntroduce.ui.main.Parent then
      ExpeditionLookIntroduce.pic.ForeGroundImage = Expedition.ui.selected_level.ForeGroundImage
    end
  end
  Expedition.ShowLevelDifficultyButton()
end

function SendChatText()
  if string.len(ui.input_box.Text) > 0 then
    if game.isNoSpeak then
      MessageBox.ShowError(GetUTF8Text("msgbox_social_punish_054_lobby"))
    else
      game:Chat(nil, ui.input_box.Text)
      ui.input_box.Text = ""
    end
  end
end

function ui.input_box.EventValueEnter(sender, e)
  SendChatText()
end

function ui.send_btn.EventClick(sender, e)
  SendChatText()
end

function ui.b_back.EventClick(sender, e)
  if not ExpeditionRoom then
    require("expeditionRoom.lua")
  end
  if not ExpeditionRoom.ui.root.Visible then
    ExpeditionRoom.ShowLeves(true)
  end
  isHostMan = false
  local state = ptr_cast(game.CurrentState)
  state:LeaveRoom()
  Hide()
  LobbyStartGame.SelectMainBtn(3)
end

function ui.b_invite.EventClick(sender, e)
  function OnInviteCallback(friendArray)
    local state = ptr_cast(game.CurrentState)
    
    local room_info = state:GetSelfRoomInfo()
    if room_info.GameType ~= "kNone" then
      for k, v in pairs(friendArray) do
        state:RoomInvite(v.name, room_info.RoomUid, 9, 10)
      end
    end
  end
  
  LobbyBoxContern.m_bCheckPlayerLevel = false
  local IDArray = {}
  for k, v in pairs(slot_item) do
    if v.Tag then
      table.insert(IDArray, ptr_cast(v.Tag).character_id)
    end
  end
  LobbyBoxContern.SetBlockIDArray(IDArray)
  m_inviteUI = LobbyBoxContern.ShowInvite(gui, true, Vector2(700, 420), OnInviteCallback, nil, true)
end

function ui.b_set.EventClick(sender, e)
  ExpeditionRoomSet.Show()
end

function Show(winRoot)
  if not winRoot then
    Hide()
  else
    Expedition.RpcPlayerVentureDetail()
    Expedition.expeditionState = 2
    ui.tb_password.Text = ""
    ui.msg_panel:ClearMessage()
    Expedition.ui.levels.Parent = ui.main
    Expedition.ui.levels.Location = Vector2(10, 163)
    ui.main.Parent = winRoot
  end
end

function Hide()
  Expedition.ui.levels.Parent = Expedition.ui.main_plane
  Expedition.ui.levels.Location = Vector2(420, 163)
  ui.main.Parent = nil
end

function UpdateRoomInfoPanel(room_info)
  if room_info.UsePassword then
    ui.tb_password.Text = room_info.Password
  else
    ui.tb_password.Text = ""
  end
  ui.room_name.Text = room_info.RoomName
  ExpeditionRoomSet.SetInfo(room_info)
end
