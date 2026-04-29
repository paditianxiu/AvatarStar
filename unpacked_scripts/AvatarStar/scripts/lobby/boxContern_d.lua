module("LobbyBoxContern", package.seeall)
ITEM_INDEX_ONLINE_ICON = 0
ITEM_INDEX_RANK_LEVEL = 1
ITEM_INDEX_RANK_LEVEL_ICON = 2
ITEM_INDEX_LEVEL_VALUE = 3
ITEM_INDEX_PLAYER_NAME = 4
ITEM_INDEX_PLAYER_ID = 5
ITEM_INDEX_ONLINE_VALUE = 6
ITEM_INDEX_VIP_VALUE = 7
ITEM_INDEX_VIP_ICON = 8
ITEM_INDEX_RANK_TYPE = 9

function InitFriendListHeader(list, list_type)
  local rank_icon_width = 36
  local name_width = 167
  if list_type == 0 then
    rank_icon_width = 36
    name_width = 167
  elseif list_type == 1 then
    rank_icon_width = 36
    name_width = 216
  else
    rank_icon_width = 1
    name_width = 167
  end
  CommonUtility.InitLtvHeader(list, {
    {
      "",
      23,
      "kAlignLeftMiddle"
    },
    {
      "",
      1,
      "kAlignLeftMiddle"
    },
    {
      "",
      rank_icon_width,
      "kAlignLeftMiddle"
    },
    {
      "",
      46,
      "kAlignLeftMiddle"
    },
    {
      "",
      name_width,
      "kAlignLeftMiddle"
    },
    {
      "",
      1,
      "kAlignCenterMiddle"
    },
    {
      "",
      1,
      "kAlignLeftMiddle"
    },
    {
      "",
      1,
      "kAlignLeftMiddle"
    },
    {
      "",
      32,
      "kAlignCenterMiddle"
    },
    {
      "",
      1,
      "kAlignCenterMiddle"
    }
  })
end

local wndClock
local timeNum = 15
local total_time = 15
local timer, timeCallBackFun, GetStandardMB
local GetStandardMB, OnTimer = function(time)
  local message_box = Gui.Create({
    Gui.Control("panel")({
      Size = Vector2(400, 200),
      Dock = "kDockFill",
      Margin = Vector4(6, 6, 6, 6),
      Gui.Control({
        Dock = "kDockFill",
        BackgroundColor = ARGB(255, 255, 255, 255),
        Skin = SkinF.battle_005,
        Padding = Vector4(16, 16, 16, 16),
        Gui.Label({
          Dock = "kDockBottomCenter",
          Text = GetUTF8Text("msgbox_battlefield_additional_string_022"),
          FontSize = 16,
          TextColor = ARGB(255, 113, 83, 65),
          TextAlign = "kAlignCenterMiddle",
          Size = Vector2(400, 64),
          Margin = Vector4(6, 6, 6, 10),
          AutoWrap = true
        }),
        Gui.Control({
          Dock = "kDockTop",
          Size = Vector2(432, 30),
          Gui.Label({
            Dock = "kDockLeft",
            Text = GetUTF8Text("msgbox_battlefield_additional_string_023"),
            FontSize = 16,
            TextColor = ARGB(255, 113, 83, 65),
            Size = Vector2(200, 24),
            TextAlign = "kAlignLeftMiddle"
          }),
          Gui.Label({
            Dock = "kDockRight",
            Text = GetUTF8Text("tips_abilities_Sec"),
            FontSize = 16,
            TextColor = ARGB(255, 113, 83, 65),
            TextAlign = "kAlignRightMiddle",
            Size = Vector2(40, 24)
          }),
          Gui.Label("lbl_time")({
            Dock = "kDockRight",
            Text = "",
            FontSize = 16,
            TextColor = ARGB(255, 203, 3, 3),
            TextAlign = "kAlignRightMiddle"
          })
        })
      })
    })
  })
  local modalwin = ModalWindow.GetNew()
  modalwin.screen.AllowEscToExit = false
  modalwin.root.Size = Vector2(432, 160)
  message_box.panel.Parent = modalwin.root
  message_box.root = modalwin.root
  
  function message_box.Close()
    modalwin.Close()
  end
  
  return message_box
end, nil

function OnTimer()
  timeNum = timeNum - 1
  if 0 < timeNum then
    if wndClock then
      wndClock.lbl_time.Text = timeNum
    end
  else
    CloseClockTimer()
    if timeCallBackFun then
      timeCallBackFun(timeNum)
    end
  end
end

function ShowClockTimer(fun1, time)
  CloseClockTimer()
  total_time = time
  timeNum = time
  if total_time == 0 then
    total_time = 1
  end
  timeCallBackFun = fun1
  if wndClock then
    wndClock.lbl_time.Text = ""
  end
  wndClock = GetStandardMB(time)
  if wndClock then
    wndClock.lbl_time.Text = timeNum
  end
  timer = game.TimerMgr:AddTimer(1)
  timer.EventOnTimer = OnTimer
end

function CloseClockTimer()
  if timer then
    game.TimerMgr:RemoveTimer(timer)
    timer = nil
    total_time = 0
    timeNum = 0
  end
  if wndClock then
    wndClock.Close()
    wndClock = nil
  end
end

local invite_ui, friend_list, OnListSelectedItem, OnCloseClallback
local SEARCH_TYPE = 0
local FRIEND_TYPE = 2
local MYFRIEND_GROUP = 1
local OFFLINE = 1
local ONLINE = 2
local INGAMING = 3
local m_location = Vector2(460, 280)
local local_friend_list, m_BlockIDArray
local m_bCheckPlayerLevel, GetInviteWnd = false, false
local GetInviteWnd, AddFriendsGroupItem = function(bCheckBox, location)
  local ui_invite = Gui.Create()({
    Gui.Control("root")({
      Location = location,
      Size = Vector2(326, 340),
      BackgroundColor = ARGB(255, 255, 255, 255),
      Skin = SkinF.personalInfo_207,
      ComFuc.ComLabel(nil, GetUTF8Text("button_social_additional_string_006"), Vector2(218, 18), Vector2(16, 6), 0, 16, ARGB(255, 255, 255, 255)),
      Gui.Button("btn_close")({
        Size = Vector2(24, 25),
        Location = Vector2(288, 4),
        BackgroundColor = ARGB(255, 255, 255, 255),
        Skin = SkinF.lookInfo_002,
        EventClick = function(sender, e)
          CloseInvite()
        end
      }),
      Gui.Control("listBlock")({
        Location = Vector2(5, 36),
        Size = Vector2(314, 250),
        BackgroundColor = ARGB(255, 255, 255, 255),
        Skin = SkinF.personalInfo_068,
        Margin = Vector4(10, 10, 10, 10),
        Padding = Vector4(7, 4, 7, 4)
      }),
      Gui.Button("btn_OK")({
        Location = Vector2(76, 292),
        Size = Vector2(70, 34),
        Text = GetUTF8Text("button_common_OK"),
        FontSize = 16,
        CanMove = true,
        TextColor = ARGB(255, 255, 255, 255),
        DisabledTextColor = ARGB(255, 192, 192, 192),
        TextShadowWhenNormal = true,
        TextShadowColor = ARGB(150, 0, 0, 0),
        Enable = false,
        EventClick = function(sender, e)
          InviteFriend(friend_list, bCheckBox)
        end
      }),
      Gui.Button("btn_cancel")({
        Location = Vector2(176, 292),
        Size = Vector2(70, 34),
        Text = GetUTF8Text("button_common_Cancel"),
        FontSize = 16,
        CanMove = true,
        TextColor = ARGB(255, 255, 255, 255),
        DisabledTextColor = ARGB(255, 192, 192, 192),
        TextShadowWhenNormal = true,
        TextShadowColor = ARGB(150, 0, 0, 0),
        EventClick = function(sender, e)
          CloseInvite()
        end
      })
    })
  })
  if bCheckBox then
    friend_list = Gui.SocialityChannelList({
      Dock = "kDockFill",
      Margin = Vector4(4, 4, 6, 4),
      BackgroundColor = ARGB(255, 255, 0, 255),
      Style = "Friend.List",
      EventCheckChanged = function(sender, e)
        SetBtnSEnableState()
      end
    })(ui_invite.listBlock, nil)
    CommonUtility.InitLtvHeader(friend_list, {
      {
        "",
        36,
        "kAlignCenterMiddle"
      },
      {
        "",
        40,
        "kAlignLeftMiddle"
      },
      {
        "",
        167,
        "kAlignLeftMiddle"
      },
      {
        "",
        1,
        "kAlignLeftMiddle"
      }
    })
  else
    friend_list = Gui.ListTreeView({
      Dock = "kDockFill",
      Style = "Sociality.FriendsList",
      EventClick = function(sender, e)
        local list = sender
        if list.SelectedItem then
          ui_invite.btn_OK.Enable = true
        else
          ui_invite.btn_OK.Enable = false
        end
      end,
      EventDoubleClick = function(sender, e)
        InviteFriend(sender, bCheckBox)
      end
    })(ui_invite.listBlock, nil)
    InitFriendListHeader(friend_list, 2)
  end
  return ui_invite
end, nil

function AddFriendsGroupItem(Type, group_list, online_state, player_level, player_name, player_id)
  local list = group_list
  local root = list.RootItem
  local item
  if tonumber(Type) == SEARCH_TYPE or tonumber(Type) == FRIEND_TYPE then
    item = list:AddItem(root, "")
    if tonumber(online_state) == OFFLINE then
      item:SetIcon(ITEM_INDEX_ONLINE_ICON, IconsF.SocialityStatusIcons.OnlineN)
    else
      item:SetIcon(ITEM_INDEX_ONLINE_ICON, IconsF.SocialityStatusIcons.OnlineA)
    end
    list:AddSubItem(item, "")
    item:SetIcon(ITEM_INDEX_RANK_LEVEL_ICON, nil)
    list:AddSubItem(item, "Lv" .. tonumber(player_level))
    item:SetTextColor(ITEM_INDEX_LEVEL_VALUE, ARGB(255, 255, 255, 255))
    item:SetHighLightTextColor(ITEM_INDEX_LEVEL_VALUE, ARGB(255, 62, 26, 1))
    list:AddSubItem(item, player_name)
    item:SetTextColor(ITEM_INDEX_PLAYER_NAME, ARGB(255, 255, 255, 255))
    item:SetHighLightTextColor(ITEM_INDEX_PLAYER_NAME, ARGB(255, 62, 26, 1))
    list:AddSubItem(item, player_id)
    list:AddSubItem(item, online_state)
  end
  return item
end

local SetBtnSEnableState, AddFriendsGroupItemEx = function()
  local bEnable = false
  if local_friend_list then
    for k, v in pairs(local_friend_list) do
      if v.item.Parent and v.item.Check then
        bEnable = true
        break
      end
    end
  end
  invite_ui.btn_OK.Enable = bEnable
end, function()
  local bEnable = false
  if local_friend_list then
    for k, v in pairs(local_friend_list) do
      if v.item.Parent and v.item.Check then
        bEnable = true
        break
      end
    end
  end
  invite_ui.btn_OK.Enable = bEnable
end

function AddFriendsGroupItemEx(list, key, friendItem)
  local root = list.RootItem
  if not local_friend_list[key] then
    local_friend_list[key] = {}
    local_friend_list[key].item = list:CreateItem()
  end
  local item = ptr_cast(local_friend_list[key].item)
  local_friend_list[key].data = friendItem
  list:AddExistingItem(root, item)
  item:SetText(0, "")
  item:SetLocation(0, Vector2(6, 6))
  item:SetSize(0, Vector2(24, 24))
  item:SetText(1, "Lv" .. tonumber(friendItem.level))
  item:SetLocation(1, Vector2(35, 6))
  item:SetSize(1, Vector2(40, 24))
  item:SetTextColor(1, ARGB(255, 255, 255, 255))
  item:SetHighLightTextColor(1, ARGB(255, 62, 26, 1))
  item:SetHoverTextColor(1, ARGB(255, 62, 26, 1))
  item:SetText(2, friendItem.name)
  item:SetLocation(2, Vector2(75, 6))
  item:SetSize(2, Vector2(170, 24))
  item:SetTextColor(2, ARGB(255, 255, 255, 255))
  item:SetHighLightTextColor(2, ARGB(255, 62, 26, 1))
  item:SetHoverTextColor(2, ARGB(255, 62, 26, 1))
  item:SetText(3, key)
end

local GetFriendList, UpdateFriendList = function()
  local chat = ptr_cast(game.ChatConnect)
  if not chat then
    return
  end
  local friendArray = {}
  local index = 0
  local key
  while true do
    local pItem = chat:GetFriendGroupItem(FRIEND_TYPE, MYFRIEND_GROUP, 0, index)
    if not pItem then
      break
    end
    key = pItem.PlayerID
    if not friendArray[key] then
      friendArray[key] = {}
      friendArray[key].id = key
      friendArray[key].name = pItem.Player_name
      friendArray[key].state = pItem.Online_state
      friendArray[key].level = pItem.Player_level
    end
    index = index + 1
  end
  return friendArray
end, function()
  local chat = ptr_cast(game.ChatConnect)
  if not chat then
    return
  end
  local friendArray = {}
  local index = 0
  local key
  while true do
    local pItem = chat:GetFriendGroupItem(FRIEND_TYPE, MYFRIEND_GROUP, 0, index)
    if not pItem then
      break
    end
    key = pItem.PlayerID
    if not friendArray[key] then
      friendArray[key] = {}
      friendArray[key].id = key
      friendArray[key].name = pItem.Player_name
      friendArray[key].state = pItem.Online_state
      friendArray[key].level = pItem.Player_level
    end
    index = index + 1
  end
  return friendArray
end

function UpdateFriendList(list, bCheckBox, bBlockOffline)
  local chat = ptr_cast(game.ChatConnect)
  if not chat or not list then
    return
  end
  local selected_item = list.SelectedItem
  if bCheckBox then
    if local_friend_list then
      for k, v in pairs(local_friend_list) do
        local_friend_list[k].data = nil
        local_friend_list[k].item.Parent = nil
        local_friend_list[k].item = nil
        local_friend_list[k] = nil
      end
      local_friend_list = nil
    end
    if not local_friend_list then
      local_friend_list = {}
    end
  else
    list:DeleteAll()
  end
  local index = 0
  local RetItem, continue
  local friendList = GetFriendList()
  if friendList then
    for _, item in pairs(friendList) do
      continue = true
      if bBlockOffline and item.state == OFFLINE then
        continue = false
      end
      if continue then
        local bNotExist = true
        if m_BlockIDArray then
          for _, v in pairs(m_BlockIDArray) do
            if tostring(v) == tostring(item.id) then
              bNotExist = false
              break
            end
          end
        end
        if bNotExist then
          if bCheckBox then
            AddFriendsGroupItemEx(list, item.id, item)
          else
            RetItem = AddFriendsGroupItem(FRIEND_TYPE, list, item.state, item.level, item.name, item.id)
            if selected_item and selected_item:GetText(ITEM_INDEX_PLAYER_ID) == item.id then
              sender.SelectedItem = RetItem
            end
          end
        end
      end
    end
  end
end

function InviteFriend(list, bCheckBox)
  local friendArray = {}
  if bCheckBox then
    local indexArray = ""
    local count = 0
    local bLessLevelFive = false
    for k, v in pairs(local_friend_list) do
      if v.item.Check then
        local key = v.item:GetText(3)
        if not friendArray[key] then
          friendArray[key] = {}
          friendArray[key].id = key
          friendArray[key].name = v.item:GetText(2)
          friendArray[key].level = string.sub(v.item:GetText(1), string.len("Lv") + 1)
          if tonumber(friendArray[key].level) < 5 then
            bLessLevelFive = true
          end
        end
        count = count + 1
      end
    end
    if count < 1 then
      MessageBox.ShowError(GetUTF8Text("msgbox_battlefield_additional_string_024"))
    elseif OnListSelectedItem then
      OnListSelectedItem(friendArray)
      CloseInvite()
    end
  elseif list and list.SelectedItem then
    if list.SelectedItem:GetText(ITEM_INDEX_PLAYER_NAME) == SelectCharacter.role_text then
      MessageBox.ShowError(GetUTF8Text("msgbox_common_num_1324"))
    else
      indexArray = list.SelectedItem:GetText(ITEM_INDEX_PLAYER_ID) .. "#"
      local key = list.SelectedItem:GetText(ITEM_INDEX_PLAYER_ID)
      if not friendArray[key] then
        friendArray[key] = {}
        friendArray[key].id = key
        friendArray[key].name = list.SelectedItem:GetText(ITEM_INDEX_PLAYER_NAME)
        friendArray[key].level = string.sub(list.SelectedItem:GetText(ITEM_INDEX_LEVEL_VALUE), string.len("Lv") + 1)
      end
      if OnListSelectedItem then
        OnListSelectedItem(friendArray)
        CloseInvite()
      end
    end
  else
    MessageBox.ShowError(GetUTF8Text("msgbox_common_num_1228"))
  end
  for k, v in pairs(friendArray) do
    friendArray[k].id = nil
    friendArray[k].name = nil
    friendArray[k] = nil
  end
  friendArray = nil
end

function AlignUI()
  local x = gui.Size.x * m_location.x / 1200
  local y = gui.Size.y * m_location.y / 900
  Gui.Align(invite_ui.root, x, y)
end

local ui_conver = Gui.Create()({
  ComFuc.ComControl("coverControl2", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(100, 0, 0, 0))
})

function ShowInvite(parent_win, bCheckBox, location, selectFun, closeFun, bBlockOffline)
  CloseInvite()
  m_location = location
  ui_conver.coverControl2.Parent = parent_win
  invite_ui = GetInviteWnd(bCheckBox, m_location)
  invite_ui.root.Parent = parent_win
  OnListSelectedItem = selectFun
  OnCloseClallback = closeFun
  if parent_win == gui then
    AlignUI()
  end
  if friend_list then
    UpdateFriendList(friend_list, bCheckBox, bBlockOffline)
  end
  return invite_ui
end

function CloseInvite()
  ui_conver.coverControl2.Parent = nil
  if invite_ui and invite_ui.root.Parent then
    invite_ui.root.Parent = nil
  end
  if friend_list then
    friend_list = nil
  end
  OnListSelectedItem = nil
  if OnCloseClallback then
    OnCloseClallback()
  end
  OnCloseClallback = nil
  if local_friend_list then
    for k, v in pairs(local_friend_list) do
      local_friend_list[k].data = nil
      local_friend_list[k].item.Parent = nil
      local_friend_list[k].item = nil
      local_friend_list[k] = nil
    end
    local_friend_list = nil
  end
end

function SetBlockIDArray(IDArray)
  if m_BlockIDArray then
    m_BlockIDArray = nil
  end
  if IDArray then
    local nIndex = 0
    m_BlockIDArray = {}
    for _, v in pairs(IDArray) do
      m_BlockIDArray[nIndex] = v
      nIndex = nIndex + 1
    end
  end
end

local sys_msg_bg_skin = Gui.ControlSkin({
  BackgroundImage = Gui.Image("ui/skinF/skin_common_background_new.tga", Vector4(0, 70, 0, 60))
})
local sys_msg_ui, sys_msg_timer

function ShowSysMsgTip(Type, msg)
  if sys_msg_timer then
    game.TimerMgr:RemoveTimer(sys_msg_timer)
    sys_msg_timer = nil
  end
  if sys_msg_ui then
    sys_msg_ui.root.Parent = nil
    sys_msg_ui = nil
  end
  sys_msg_ui = Gui.Create()({
    Gui.Window("root")({
      Size = Vector2(326, 257),
      Dock = "kDockRightBottom",
      BackgroundColor = ARGB(255, 255, 255, 255),
      Skin = sys_msg_bg_skin,
      Padding = Vector4(11, 11, 11, 11),
      Margin = Vector4(0, 0, 36, 36),
      Moveable = true,
      Gui.Label({
        Location = Vector2(0, 21),
        Size = Vector2(326, 16),
        TextColor = ARGB(255, 255, 255, 255),
        FontSize = 16,
        TextAlign = "kAlignCenterMiddle",
        Text = GetUTF8Text("UI_social_additional_string_064")
      }),
      Gui.Button("btn_close")({
        Size = Vector2(24, 24),
        Skin = SkinF.lookInfo_002,
        Location = Vector2(284, 15),
        BackgroundColor = colw
      }),
      Gui.NewMessagePanel("msg_panel")({
        Size = Vector2(296, 193),
        Location = Vector2(15, 50),
        Style = "Sociality.MessagePanel",
        Padding = Vector4(8, 12, 12, 12),
        BackgroundColor = ARGB(0, 255, 255, 255),
        VScrollBarDisplay = false,
        MaxTextWidth = 295,
        OnePageLineNum = 10,
        MaxLineNum = 300,
        LineGap = 1
      })
    })
  })
  sys_msg_ui.root.Parent = gui
  sys_msg_ui.msg_panel:AddSystemMessage(Type, msg)
  sys_msg_timer = game.TimerMgr:AddTimer(5)
  
  function sys_msg_ui.btn_close.EventClick(sender, e)
    sys_msg_ui.root.Parent = nil
  end
  
  function sys_msg_timer.EventOnTimer(sender, e)
    game.TimerMgr:RemoveTimer(sys_msg_timer)
    sys_msg_ui.root.Parent = nil
    sys_msg_ui = nil
    sys_msg_timer = nil
  end
end
