module("ChatBar", package.seeall)
local chat_map = {}
local CHANNEL_TYPE = 1
local FRIEND_TYPE = 2
local PUBLIC_CHANNEL = 1
local GONGHUI_CHANNEL = 3
local PRIVATE_CHANNEL = 2
local MYFRIEND_GROUP = 1
local LASTGAMER_GROUP = 2
local BLACKLIST_GROUP = 3
MAX_CHAT_WND = 8
local local_channel_id = 0
local local_group_id = 0
local CloseChatPair, m_inviteUI
local ui, OnInviteCallback = Gui.Create()({
  Gui.ChatBar("chat_bar")({
    Dock = "kDockFill",
    BackgroundColor = ARGB(0, 0, 0, 0),
    Padding = Vector4(2, 2, 2, 4),
    MaxPairWidth = 189,
    MovingSpeed = Vector2(1000, 1000),
    ScaleSpeed = Vector2(500, 500)
  })
}), Gui.Create()({
  Gui.ChatBar("chat_bar")({
    Dock = "kDockFill",
    BackgroundColor = ARGB(0, 0, 0, 0),
    Padding = Vector4(2, 2, 2, 4),
    MaxPairWidth = 189,
    MovingSpeed = Vector2(1000, 1000),
    ScaleSpeed = Vector2(500, 500)
  })
})
local OnInviteCallback, OnCloseInviteCallback = function(friendArray)
  local indexArray = ""
  local count = 0
  for k, v in pairs(friendArray) do
    indexArray = friendArray[k].id .. "#"
    count = count + 1
  end
  local chat = ptr_cast(game.ChatConnect)
  if chat then
    chat:InviteFriend(local_channel_id, local_group_id, indexArray, count)
  end
end, {
  Gui.ChatBar("chat_bar")({
    Dock = "kDockFill",
    BackgroundColor = ARGB(0, 0, 0, 0),
    Padding = Vector4(2, 2, 2, 4),
    MaxPairWidth = 189,
    MovingSpeed = Vector2(1000, 1000),
    ScaleSpeed = Vector2(500, 500)
  })
}
local OnCloseInviteCallback, fnInvitFriend = function()
  m_inviteUI = nil
end, Gui.ChatBar("chat_bar")({
  Dock = "kDockFill",
  BackgroundColor = ARGB(0, 0, 0, 0),
  Padding = Vector4(2, 2, 2, 4),
  MaxPairWidth = 189,
  MovingSpeed = Vector2(1000, 1000),
  ScaleSpeed = Vector2(500, 500)
})

function fnInvitFriend(parent_win, type, channel_id, group_id)
  local_channel_id = channel_id
  local_group_id = group_id
  local chat = ptr_cast(game.ChatConnect)
  if chat then
    local pItem
    local nIndex = 0
    local IDArray = {}
    while true do
      pItem = chat:GetFriendGroupItem(type, channel_id, group_id, nIndex)
      if not pItem then
        break
      end
      IDArray[nIndex] = pItem.PlayerID
      nIndex = nIndex + 1
    end
    LobbyBoxContern.SetBlockIDArray(IDArray)
    m_inviteUI = LobbyBoxContern.ShowInvite(parent_win, false, Vector2(390, 145), OnInviteCallback, OnCloseInviteCallback)
    IDArray = nil
  end
end

function CreateChatWindow(parent_win, type, channel_id, group_id, pair_name)
  local cw = {}
  Gui.Control({
    Dock = "kDockFill",
    BackgroundColor = ARGB(255, 255, 255, 255),
    Skin = SkinF.personalInfo_207,
    Gui.Control({
      Dock = "kDockTop",
      Size = Vector2(300, 30),
      ComFuc.ComLabel("title_lbl", GetUTF8Text("UI_common_Chat_Box"), Vector2(268, 24), Vector2(16, 4), 0, 16, ARGB(255, 255, 255, 255)),
      Gui.Button("close_btn")({
        Dock = "kDockRight",
        Size = Vector2(24, 24),
        Margin = Vector4(0, 4, 12, 2),
        Skin = SkinF.lookInfo_002
      }),
      Gui.Button("min_btn")({
        Dock = "kDockRight",
        Size = Vector2(24, 24),
        Margin = Vector4(0, 4, 4, 2),
        Skin = SkinF.sociality_button_001
      })
    }),
    Gui.Control({
      Dock = "kDockFill",
      BackgroundColor = ARGB(255, 255, 255, 255),
      Skin = SkinF.battle_005,
      Margin = Vector4(4, 4, 4, 10),
      Gui.Control("right_user_div")({
        Dock = "kDockRight",
        BackgroundColor = ARGB(0, 0, 0, 0),
        Padding = Vector4(0, 11, 11, 11),
        Size = Vector2(226, 0),
        Gui.Control("right_bottom_div")({
          Dock = "kDockBottom",
          Size = Vector2(0, 38),
          BackgroundColor = ARGB(0, 0, 0, 0),
          Gui.Button("invite_btn")({
            Dock = "kDockLeft",
            Size = Vector2(85, 0),
            Margin = Vector4(6, 3, 6, 3),
            Style = "Gui.Button",
            Text = GetUTF8Text("UI_social_additional_string_062"),
            CanMove = true,
            FontSize = 16,
            EventClick = function(sender, e)
              fnInvitFriend(parent_win, type, channel_id, group_id)
            end
          }),
          Gui.Button("exit_btn")({
            Dock = "kDockRight",
            Size = Vector2(85, 0),
            Margin = Vector4(6, 3, 6, 3),
            Style = "Gui.Button",
            Text = GetUTF8Text("button_common_Exit_Channel"),
            CanMove = true,
            FontSize = 16,
            EventClick = function(sender, e)
              if m_inviteUI then
                m_inviteUI.CloseInvite()
              end
              local chat = ptr_cast(game.ChatConnect)
              if chat then
                if chat:DeleteMyGroup(channel_id, group_id, true) then
                  MessageBox.ShowWithConfirmCancel(GetUTF8Text("msgbox_common_num_1234"), function()
                    chat:DeleteMyGroup(channel_id, group_id, false)
                  end, nil)
                  CloseChatPair(type, channel_id, group_id, false)
                else
                  CloseChatPair(type, channel_id, group_id, true)
                end
              end
            end
          })
        }),
        Gui.Control({
          Dock = "kDockFill",
          BackgroundColor = ARGB(255, 255, 255, 255),
          Skin = SkinF.auction_01,
          Margin = Vector4(0, 0, 0, 4),
          Gui.Label("lbl_PlayerCount")({
            Dock = "kDockTop",
            Size = Vector2(0, 34),
            Text = GetUTF8Text("UI_common_Member_List"),
            TextAlign = "kAlignCenterMiddle",
            TextColor = ARGB(255, 255, 255, 255),
            FontSize = 16
          }),
          Gui.ListTreeView("friend_list")({
            Dock = "kDockFill",
            Style = "Sociality.FriendsList",
            Margin = Vector4(7, 0, 7, 7)
          })
        })
      }),
      Gui.Control({
        Dock = "kDockFill",
        BackgroundColor = ARGB(0, 0, 0, 0),
        Padding = Vector4(11, 11, 11, 11),
        Gui.Control("left_bottom_div")({
          Dock = "kDockBottom",
          Size = Vector2(0, 38),
          BackgroundColor = ARGB(255, 255, 255, 255),
          Skin = SkinF.battle_012,
          Gui.Button("send_btn")({
            Dock = "kDockRight",
            Size = Vector2(64, 0),
            Margin = Vector4(6, 3, 6, 3),
            Style = "Gui.Button",
            Text = GetUTF8Text("button_common_Send"),
            CanMove = true,
            FontSize = 16
          }),
          Gui.Textbox("input_box")({
            Dock = "kDockFill",
            Margin = Vector4(0, 4, 4, 4),
            TextColor = ARGB(255, 255, 255, 255),
            BackgroundColor = ARGB(0, 0, 0, 0),
            FontSize = 16,
            MaxLength = 100
          })
        }),
        Gui.NewMessagePanel("msg_panel")({
          Dock = "kDockFill",
          Style = "Sociality.MessagePanel",
          MaxTextWidth = 426,
          OnePageLineNum = 14,
          MaxLineNum = 60,
          LineGap = 1
        })
      })
    })
  })(parent_win, cw)
  if game.isNoSpeak then
    cw.input_box.Enable = false
    cw.send_btn.Enable = false
  else
    cw.input_box.Enable = true
    cw.send_btn.Enable = true
  end
  HyLinkMenu(cw.msg_panel)
  return cw
end

function HyLinkMenu(sender)
  local user_ID, user_name
  ComFuc.InitSocialityMenu(sender.PopupMenu, {
    {
      "IDM_BEG_CHAT",
      GetUTF8Text("button_common_Chat"),
      function()
        ChatBar.OpenFriendChatPair(user_ID, user_name)
      end
    },
    {
      "IDM_VIEW_PERSONALITY",
      GetUTF8Text("button_common_Info"),
      function()
        LookInfo.Show(user_ID)
      end
    },
    {
      "IDM_ADD_TO_FRIEND",
      GetUTF8Text("button_common_Add_Friend"),
      function()
        Sociality.MoveFriend(4, user_ID, user_name, 2, 0)
      end
    },
    {
      "IDM_COPY_NAME",
      GetUTF8Text("tips_social_copy_name"),
      function()
        Sociality.CopyName(user_name)
      end
    }
  })
  
  function sender.EventHyLink(sender, e)
    user_ID = e.user_ID
    user_name = e.user_name
    local menu = sender.PopupMenu
    menu:Open()
  end
end

local CloseChatPair, GetChatHistoryMsg = function(type, channel_id, group_id, bSend)
  local chat_id = type .. "_" .. channel_id .. "_" .. group_id
  if tonumber(type) == CHANNEL_TYPE and tonumber(channel_id) == PUBLIC_CHANNEL then
    bSend = true
  end
  if chat_map and chat_map[chat_id] then
    ui.chat_bar:RemoveChatPair(chat_map[chat_id][1])
    chat_map[chat_id] = nil
    if tonumber(type) == CHANNEL_TYPE and bSend then
      local chat = ptr_cast(game.ChatConnect)
      if chat then
        chat:SendEnterOrLeaveChannal(channel_id, group_id, false)
      end
    end
  end
  local barPos = ui.chat_bar:ClientToScreen(ui.chat_bar:GetOriChatPairLocation(ui.chat_bar:GetChatPairCount() - 1))
  if chat_map then
    for _, cpw in pairs(chat_map) do
      cpw[1].WinChat.Location = Vector2(math.min(barPos.x, gui.Size.x - cpw[1].WinChat.Size.x - 5), barPos.y - cpw[1].WinChat.Size.y - 3)
    end
  end
end, function(sender)
  local user_ID, user_name
  ComFuc.InitSocialityMenu(sender.PopupMenu, {
    {
      "IDM_BEG_CHAT",
      GetUTF8Text("button_common_Chat"),
      function()
        ChatBar.OpenFriendChatPair(user_ID, user_name)
      end
    },
    {
      "IDM_VIEW_PERSONALITY",
      GetUTF8Text("button_common_Info"),
      function()
        LookInfo.Show(user_ID)
      end
    },
    {
      "IDM_ADD_TO_FRIEND",
      GetUTF8Text("button_common_Add_Friend"),
      function()
        Sociality.MoveFriend(4, user_ID, user_name, 2, 0)
      end
    },
    {
      "IDM_COPY_NAME",
      GetUTF8Text("tips_social_copy_name"),
      function()
        Sociality.CopyName(user_name)
      end
    }
  })
  
  function sender.EventHyLink(sender, e)
    user_ID = e.user_ID
    user_name = e.user_name
    local menu = sender.PopupMenu
    menu:Open()
  end
end

function GetChatHistoryMsg(cw, Type, ChannelID, GroupID, PlayerID, bSearchStranger)
  local nIndex = 0
  local pMsgItem
  local chat = ptr_cast(game.ChatConnect)
  if not chat then
    return
  end
  while true do
    pMsgItem = chat:GetHistoryMsg(Type, ChannelID, GroupID, PlayerID, nIndex, bSearchStranger)
    if not pMsgItem then
      break
    end
    if pMsgItem.Player_name == SelectCharacter.role_text then
      cw.msg_panel:AddMessage("kNone", pMsgItem.Player_name, pMsgItem.Msg, "")
    else
      cw.msg_panel:AddMessage("kNone", pMsgItem.Player_name, pMsgItem.Msg, PlayerID)
    end
    nIndex = nIndex + 1
  end
end

local OpenFriendChatPair, BeginChat = function(cid, name)
  if name == SelectCharacter.role_text then
    MessageBox.ShowError(GetUTF8Text("msgbox_common_num_1304"))
  else
    OpenChatPair(FRIEND_TYPE, MYFRIEND_GROUP, cid, name, true, true, 0, true)
  end
end, function(cid, name)
  if name == SelectCharacter.role_text then
    MessageBox.ShowError(GetUTF8Text("msgbox_common_num_1304"))
  else
    OpenChatPair(FRIEND_TYPE, MYFRIEND_GROUP, cid, name, true, true, 0, true)
  end
end
local BeginChat, InitFriendsListPopupMenu = function(list)
  if list and list.SelectedItem then
    if list.SelectedItem:GetText(0) == SelectCharacter.role_text then
      MessageBox.ShowError(GetUTF8Text("msgbox_common_num_1304"))
    else
      OpenChatPair(FRIEND_TYPE, MYFRIEND_GROUP, list.SelectedItem:GetText(1), list.SelectedItem:GetText(0), true, true, 0, true)
    end
  end
end, Gui.ChatBar("chat_bar")({
  Dock = "kDockFill",
  BackgroundColor = ARGB(0, 0, 0, 0),
  Padding = Vector4(2, 2, 2, 4),
  MaxPairWidth = 189,
  MovingSpeed = Vector2(1000, 1000),
  ScaleSpeed = Vector2(500, 500)
})
local InitFriendsListPopupMenu, AddChatPair = function(list, channel_id, group_id)
  ComFuc.InitSocialityMenu(list.PopupMenu, {
    {
      "IDM_BEG_WISPER",
      GetUTF8Text("button_common_Chat"),
      function()
        BeginChat(list)
      end
    },
    {
      "IDM_VIEW_PERSONALITY",
      GetUTF8Text("button_common_Info"),
      function()
        LookInfo.Show(list.SelectedItem:GetText(1))
      end
    },
    {
      "IDM_COPY_NAME",
      GetUTF8Text("tips_social_copy_name"),
      function()
        Sociality.CopyName(list.SelectedItem:GetText(0))
      end
    }
  })
  
  function list.EventRightClick(sender, e)
    if sender.SelectedItem then
      sender.PopupMenu:Open()
    end
  end
end, Gui.ChatBar("chat_bar")({
  Dock = "kDockFill",
  BackgroundColor = ARGB(0, 0, 0, 0),
  Padding = Vector4(2, 2, 2, 4),
  MaxPairWidth = 189,
  MovingSpeed = Vector2(1000, 1000),
  ScaleSpeed = Vector2(500, 500)
})

function AddChatPair(type, channel_id, group_id, pair_name, bActive)
  local WinChatSize
  local cp = ui.chat_bar:AddChatPair()
  local lineNum = 14
  if tonumber(type) == CHANNEL_TYPE then
    if tonumber(channel_id) == PUBLIC_CHANNEL then
      WinChatSize = Vector2(492, 424)
    else
      WinChatSize = Vector2(716, 528)
      lineNum = 19
    end
  else
    WinChatSize = Vector2(492, 424)
  end
  cp.BarLabel.Text = pair_name
  cp.BarLabel.TextColor = ARGB(255, 255, 240, 0)
  cp.BarLabel.HighlightTextColor = ARGB(255, 255, 240, 0)
  cp.BarLabel.FontSize = 16
  cp.BarLabel.BackgroundColor = ARGB(0, 0, 0, 0)
  cp.BarBtn.Skin = SkinF.sociality_button_009
  cp.WinChat.Size = WinChatSize
  local barPos = ui.chat_bar:ClientToScreen(ui.chat_bar:GetOriChatPairLocation(ui.chat_bar:GetChatPairCount() - 1))
  cp.WinChat.Location = Vector2(math.min(barPos.x, gui.Size.x - WinChatSize.x - 5), barPos.y - WinChatSize.y - 3)
  local cw = CreateChatWindow(cp.WinChat, type, channel_id, group_id, pair_name)
  cw.title_lbl.Text = pair_name
  cw.msg_panel.OnePageLineNum = lineNum
  cw.msg_panel.MaxLineNum = lineNum * 4
  if tonumber(type) == CHANNEL_TYPE then
    if tonumber(channel_id) == PUBLIC_CHANNEL then
      cw.right_user_div.Visible = false
    elseif tonumber(channel_id) == GONGHUI_CHANNEL then
      cw.right_bottom_div.Visible = false
    end
  else
    cw.right_user_div.Visible = false
  end
  CommonUtility.InitLtvHeader(cw.friend_list, {
    {
      "",
      160,
      "kAlignLeftMiddle"
    },
    {
      "",
      1,
      "kAlignLeftMiddle"
    }
  })
  InitFriendsListPopupMenu(cw.friend_list, channel_id, group_id)
  
  function cw.close_btn.EventClick(sender, e)
    CloseChatPair(type, channel_id, group_id, false)
  end
  
  function cw.min_btn.EventClick(sender, e)
    ui.chat_bar:HideChatPair(cp)
  end
  
  function cw.friend_list.EventDoubleClick(sender, e)
    BeginChat(sender)
  end
  
  function cw.input_box.EventValueEnter(sender, e)
    if not Sociality.gTimer and string.len(cw.input_box.Text) > 0 then
      if game.isNoSpeak then
        MessageBox.ShowError(GetUTF8Text("msgbox_social_punish_054_lobby"))
      else
        local chat = ptr_cast(game.ChatConnect)
        if chat then
          chat:SendChatMessage(type, channel_id, group_id, cw.input_box.Text)
        end
        cw.input_box.Text = ""
      end
    end
  end
  
  function cw.send_btn.EventClick(sender, e)
    if not Sociality.gTimer and string.len(cw.input_box.Text) > 0 then
      if game.isNoSpeak then
        MessageBox.ShowError(GetUTF8Text("msgbox_social_punish_054_lobby"))
      else
        local chat = ptr_cast(game.ChatConnect)
        if chat then
          chat:SendChatMessage(type, channel_id, group_id, cw.input_box.Text)
        end
        cw.input_box.Text = ""
      end
    end
  end
  
  function cp.BarCloseBtn.EventClick(sender, e)
    CloseChatPair(type, channel_id, group_id, false)
  end
  
  function cp.BarBtn.EventClick(sender, e)
    if not cp.IsActive then
      ui.chat_bar:SetActivePair(cp)
    else
      ui.chat_bar:HideChatPair(cp)
    end
  end
  
  function cp.WinChat.EventActived(sender, e)
    ui.chat_bar:SetActivePair(cp)
  end
  
  if bActive then
    ui.chat_bar:SetActivePair(cp)
  else
    ui.chat_bar:HideChatPair(cp)
  end
  return {cp, cw}
end

function CheckChatPairIsOpen(type, channel_id, cid)
  local chat_id = type .. "_" .. channel_id .. "_" .. cid
  if not chat_map[chat_id] then
    return false
  else
    local cpw = chat_map[chat_id]
    ui.chat_bar:SetActivePair(cpw[1])
    return true
  end
end

function IsCanOpenChatPair(type, channel_id, cid)
  if not chat_map then
    return true
  end
  local chat_id = type .. "_" .. channel_id .. "_" .. cid
  if tonumber(type) == CHANNEL_TYPE and tonumber(channel_id) == PUBLIC_CHANNEL then
    for i = 1, 6 do
      chat_id = type .. "_" .. channel_id .. "_" .. i
      if chat_map[chat_id] then
        return true
      end
    end
  end
  chat_id = type .. "_" .. channel_id .. "_" .. cid
  if not chat_map[chat_id] and ui.chat_bar:GetChatPairCount() >= tonumber(MAX_CHAT_WND) then
    return false
  end
  return true
end

local OpenChatPair, AddToUnShowList = function(type, channel_id, cid, pair_name, CreateUI, bActive, strOwerID, bShowMsg)
  if not chat_map then
    chat_map = {}
  end
  if CreateUI and not IsCanOpenChatPair(type, channel_id, cid) then
    if bShowMsg and ui.chat_bar.Parent then
      MessageBox.ShowError(GetUTF8Text("msgbox_common_num_1236"), 3)
    end
    return nil
  end
  local chat_id = type .. "_" .. channel_id .. "_" .. cid
  local bNew = false
  if tonumber(type) == CHANNEL_TYPE and tonumber(channel_id) == PUBLIC_CHANNEL then
    for i = 1, 6 do
      if i ~= tonumber(cid) then
        CloseChatPair(type, channel_id, i, true)
      end
    end
  end
  if not chat_map[chat_id] then
    if not CreateUI then
      return
    end
    chat_map[chat_id] = AddChatPair(type, channel_id, cid, pair_name, bActive)
    bNew = true
    if tonumber(type) == CHANNEL_TYPE and tonumber(channel_id) > PUBLIC_CHANNEL then
      if strOwerID == tostring(SelectCharacter.roleServerId) then
        chat_map[chat_id][2].invite_btn.Enable = true
      else
        chat_map[chat_id][2].invite_btn.Enable = false
      end
    end
  end
  local cpw = chat_map[chat_id]
  if not bNew and bActive then
    ui.chat_bar:SetActivePair(cpw[1])
  end
  if bNew or CreateUI then
    ui.chat_bar:SetBarBtnFlash(cpw[1], true)
  end
  local chat = ptr_cast(game.ChatConnect)
  if chat then
    if tonumber(type) == CHANNEL_TYPE and tonumber(channel_id) > PUBLIC_CHANNEL then
      chat:RequestInitGroupList(type, cpw[2].friend_list, channel_id, cid, SIM_LIST)
      if bNew then
        GetChatHistoryMsg(cpw[2], CHANNEL_TYPE, channel_id, cid, 0, false)
      end
    end
    if bNew and tonumber(type) == FRIEND_TYPE then
      GetChatHistoryMsg(cpw[2], FRIEND_TYPE, channel_id, 0, cid, false)
    end
  end
  return cpw
end, function(type, channel_id, cid, pair_name, CreateUI, bActive, strOwerID, bShowMsg)
  if not chat_map then
    chat_map = {}
  end
  if CreateUI and not IsCanOpenChatPair(type, channel_id, cid) then
    if bShowMsg and ui.chat_bar.Parent then
      MessageBox.ShowError(GetUTF8Text("msgbox_common_num_1236"), 3)
    end
    return nil
  end
  local chat_id = type .. "_" .. channel_id .. "_" .. cid
  local bNew = false
  if tonumber(type) == CHANNEL_TYPE and tonumber(channel_id) == PUBLIC_CHANNEL then
    for i = 1, 6 do
      if i ~= tonumber(cid) then
        CloseChatPair(type, channel_id, i, true)
      end
    end
  end
  if not chat_map[chat_id] then
    if not CreateUI then
      return
    end
    chat_map[chat_id] = AddChatPair(type, channel_id, cid, pair_name, bActive)
    bNew = true
    if tonumber(type) == CHANNEL_TYPE and tonumber(channel_id) > PUBLIC_CHANNEL then
      if strOwerID == tostring(SelectCharacter.roleServerId) then
        chat_map[chat_id][2].invite_btn.Enable = true
      else
        chat_map[chat_id][2].invite_btn.Enable = false
      end
    end
  end
  local cpw = chat_map[chat_id]
  if not bNew and bActive then
    ui.chat_bar:SetActivePair(cpw[1])
  end
  if bNew or CreateUI then
    ui.chat_bar:SetBarBtnFlash(cpw[1], true)
  end
  local chat = ptr_cast(game.ChatConnect)
  if chat then
    if tonumber(type) == CHANNEL_TYPE and tonumber(channel_id) > PUBLIC_CHANNEL then
      chat:RequestInitGroupList(type, cpw[2].friend_list, channel_id, cid, SIM_LIST)
      if bNew then
        GetChatHistoryMsg(cpw[2], CHANNEL_TYPE, channel_id, cid, 0, false)
      end
    end
    if bNew and tonumber(type) == FRIEND_TYPE then
      GetChatHistoryMsg(cpw[2], FRIEND_TYPE, channel_id, 0, cid, false)
    end
  end
  return cpw
end

function AddToUnShowList(type, channelID, cid, name, owerID)
  local chat = ptr_cast(game.ChatConnect)
  if not chat then
    return
  end
  chat:AddUnShowChatItem(type, channelID, cid, name, owerID)
  if ChatUnShow then
    ChatUnShow.UpdateUnShowChatList()
  end
  if Lobby then
    Lobby.NotifyUnShowChat()
  end
end

function OnUpdateChatMsg(sender, e)
  local cpw, cid
  local userID = ""
  if tonumber(e.Type) == CHANNEL_TYPE then
    cid = e.GroupID
    if tostring(e.UserID) == tostring(SelectCharacter.roleServerId) then
      userID = ""
    else
      userID = tostring(e.UserID)
    end
  else
    cid = e.UserID
  end
  if not e.msg or string.len(e.msg) == 0 then
    cpw = OpenChatPair(e.Type, e.ChannelID, cid, e.title, e.CreateUI, false, tostring(e.OwerID), false)
    if cpw and tonumber(e.Type) == FRIEND_TYPE then
      GetChatHistoryMsg(cpw[2], FRIEND_TYPE, e.ChannelID, 0, e.UserID, true)
    end
    return
  end
  local cpw = OpenChatPair(e.Type, e.ChannelID, cid, e.title, e.CreateUI, false, tostring(e.OwerID), false)
  if cpw then
    if e.channel == "/offline" then
      cpw[2].msg_panel:AddMessage("kInfo", e.sender, GetUTF8Text("msgbox_common_num_1365"))
    elseif e.channel == "kChannel" then
      cpw[2].msg_panel:AddMessage("kChannel", e.sender, e.msg, userID)
    else
      cpw[2].msg_panel:AddMessage("kNone", e.sender, e.msg, userID)
    end
  elseif e.CreateUI and not cpw then
    AddToUnShowList(e.Type, e.ChannelID, e.UserID, e.title, e.OwerID)
    return
  end
end

local NotifyTeamChat = 20121221
local SM_NotifyChat = 6

function InitStateCallBack()
  local state = ptr_cast(game.CurrentState)
  if state then
    function state.EventOnChat(sender, e)
      if e.chat_type == NotifyTeamChat then
        if e.channel == "/sys" then
          Lobby.ui.sys_pulic:AddMessage(e.channel, e.sender, e.msg)
          
          LobbyBattleGame.ui.msg_panel:AddMessage("kSys", GetUTF8Text("UI_social_additional_string_064"), e.msg)
        elseif e.channel == "/info" then
          LobbyBattleGame.ui.msg_panel:AddMessage("kInfo", "", e.msg)
        elseif e.channel == "/gag" then
          LobbyBattleGame.ui.msg_panel:AddMessage("kInfo", e.sender, GetUTF8Text("msgbox_common_num_1338"))
        elseif e.channel == "/offline" then
          LobbyBattleGame.ui.msg_panel:AddMessage("kInfo", e.sender, GetUTF8Text("msgbox_common_num_1365"))
        else
          LobbyBattleGame.ui.msg_panel:AddMessage("kNone", e.sender, e.msg)
        end
      elseif e.chat_type == SM_NotifyChat then
        if e.channel == "/sys" then
          Lobby.ui.sys_pulic:AddMessage(e.channel, GetUTF8Text("UI_social_additional_string_064"), e.msg)
        elseif e.channel == "/info" then
          Lobby.ui.sys_pulic:AddMessage(e.channel, GetUTF8Text("button_common_System_Info"), e.msg)
        else
          Lobby.ui.sys_pulic:AddMessage("kNone", e.sender, e.msg)
        end
      elseif e.channel == "/sys" then
        Lobby.ui.sys_pulic:AddMessage(e.channel, e.sender, e.msg)
        LobbyPlayGame.ui.msg_panel:AddMessage("kSys", GetUTF8Text("UI_social_additional_string_064"), e.msg)
        ExpeditionRoomCreate.ui.msg_panel:AddMessage("kSys", GetUTF8Text("UI_social_additional_string_064"), e.msg)
      elseif e.channel == "/info" then
        LobbyPlayGame.ui.msg_panel:AddMessage("kInfo", "", e.msg)
        ExpeditionRoomCreate.ui.msg_panel:AddMessage("kInfo", "", e.msg)
      elseif e.channel == "/gag" then
        LobbyPlayGame.ui.msg_panel:AddMessage("kInfo", e.sender, GetUTF8Text("msgbox_common_num_1338"))
        ExpeditionRoomCreate.ui.msg_panel:AddMessage("kInfo", e.sender, GetUTF8Text("msgbox_common_num_1338"))
      elseif e.channel == "/offline" then
        LobbyPlayGame.ui.msg_panel:AddMessage("kInfo", e.sender, GetUTF8Text("msgbox_common_num_1365"))
        ExpeditionRoomCreate.ui.msg_panel:AddMessage("kInfo", e.sender, GetUTF8Text("msgbox_common_num_1365"))
      else
        LobbyPlayGame.ui.msg_panel:AddMessage("kNone", e.sender, e.msg)
        ExpeditionRoomCreate.ui.msg_panel:AddMessage("kNone", e.sender, e.msg)
      end
    end
  end
end

function OnGroupDelete(sender, e)
  CloseChatPair(e.Type, e.ChannelID, e.GroupID, false)
end

function OnInviteFriend(sender, e)
  if m_inviteUI then
    m_inviteUI.CloseInvite()
  end
  if e.Count == 0 then
    MessageBox.ShowError(GetUTF8Text("msgbox_social_additional_string_065"))
  else
    MessageBox.ShowError(Text.SocialityErrorText[e.Count])
  end
end

function OnUpdateChannelFriend(sender, e)
  OpenChatPair(e.Type, e.ChannelID, e.GroupID, nil, false, false, 0, true)
end

function EnforceReshow()
  if chat_map then
    for _, cpw in pairs(chat_map) do
      if cpw[1].WinChat.Visible then
        ui.chat_bar:SetActivePair(cpw[1])
      end
    end
  end
end

function Show(ParentWin)
  ui.chat_bar.Parent = ParentWin
  local barPos = ui.chat_bar:ClientToScreen(ui.chat_bar:GetOriChatPairLocation(ui.chat_bar:GetChatPairCount() - 1))
  if chat_map then
    for _, cpw in pairs(chat_map) do
      cpw[1].WinChat.Location = Vector2(math.min(barPos.x, gui.Size.x - cpw[1].WinChat.Size.x - 5), barPos.y - cpw[1].WinChat.Size.y - 3)
    end
  end
  InitStateCallBack()
  local chat = ptr_cast(game.ChatConnect)
  if chat and Lobby then
    local chatItem = chat:GetUnShowChatItem(0)
    if chatItem then
      Lobby.NotifyUnShowChat()
    end
  end
end

function Hide()
  ui.chat_bar.Parent = nil
  ui.chat_bar:HideAllChatPair()
  if m_inviteUI then
    m_inviteUI.CloseInvite()
  end
end

function CloseAllChatPaire()
  if ui.chat_bar and chat_map then
    for id, cpw in pairs(chat_map) do
      ui.chat_bar:RemoveChatPair(chat_map[id][1])
      chat_map[id][1] = nil
    end
    chat_map = nil
  end
end
