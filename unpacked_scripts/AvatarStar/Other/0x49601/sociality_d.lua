module("Sociality", package.seeall)
local SEARCH_TYPE = 0
local CHANNEL_TYPE = 1
local FRIEND_TYPE = 2
local MYFRIEND_GROUP = 1
local LASTGAMER_GROUP = 2
local BLACKLIST_GROUP = 3
local STRANGER_GROUP = 4
local OFFLINE = 1
local ONLINE = 2
local INGAMING = 3
local PUBLIC_CHANNEL = 1
local GONGHUI_CHANNEL = 3
local PRIVATE_CHANNEL = 2
local bShowAddMyChannelBtn = false
local bShowNoDisturbeBtn = false
local SHOW_ICON_COUNT_1 = 25
local SHOW_ICON_COUNT_2 = 75
local MAX_MYCHANNEL_COUNT = 5
col0 = ComFuc.col0
colw = ComFuc.colw
cols = ComFuc.cols
coly = ComFuc.coly
local ui = Gui.Create()({
  Gui.Control("root")({
    Location = Vector2(11, 3),
    Size = Vector2(376, 599),
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_207,
    ComFuc.ComLabel("", GetUTF8Text("tips_abilities_Interact"), Vector2(218, 18), Vector2(16, 6), 0, 16, colw),
    ComFuc.ComButton("btn_close", "", Vector2(24, 25), Vector2(342, 4), 16, false, false, SkinF.lookInfo_002),
    ComFuc.ComButton("btn_channel", GetUTF8Text("button_common_Channel"), Vector2(125, 38), Vector2(21, 48), 18, true, false, SkinF.personalInfo_121),
    ComFuc.ComButton("btn_friends", GetUTF8Text("button_common_Friend"), Vector2(125, 38), Vector2(150, 48), 18, true, false, SkinF.personalInfo_121),
    Gui.Control("page_container")({
      Location = Vector2(7, 84),
      Size = Vector2(362, 506),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_131,
      ComFuc.ComButton("btn_social_config", "", Vector2(34, 36), Vector2(315, 450), 16, false, true, SkinF.mail_button_007),
      ComFuc.ComButton("btn_AddMyChannel", GetUTF8Text("button_common_Create_Channel"), Vector2(84, 40), Vector2(18, 445), 16),
      ComFuc.ComButton("btn_sysinfo", GetUTF8Text("button_common_System_Info"), Vector2(84, 40), Vector2(120, 445), 16),
      ComFuc.ComButton("btn_search", GetUTF8Text("button_common_Add_Friend"), Vector2(84, 40), Vector2(222, 445), 16)
    })
  }),
  Gui.Control("ui_social_config")({
    Location = Vector2(72, 405),
    Size = Vector2(300, 120),
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_131,
    Gui.Control({
      Location = Vector2(4, 5),
      Size = Vector2(292, 105),
      BackgroundColor = colw,
      Skin = SkinF.battle_005,
      ComFuc.ComLabel("", GetUTF8Text("UI_lobby_social_config"), Vector2(271, 20), Vector2(11, 15), 0, 16, cols, "kAlignLeftMiddle"),
      ComFuc.ComCheckBox("mode_no_disturbe", GetUTF8Text("UI_social_no_disturb"), Vector2(271, 20), Vector2(11, 46), 16, cols)
    })
  })
})
ui.btn_channel.TextColor = cols
ui.btn_channel.HighlightTextColor = cols
ui.btn_channel.TextShadowColor = col0
ui.btn_channel.TextShadowWhenNormal = false
ui.btn_channel.Padding = Vector4(0, 0, 14, 0)
ui.btn_friends.TextColor = cols
ui.btn_friends.HighlightTextColor = cols
ui.btn_friends.TextShadowColor = col0
ui.btn_friends.TextShadowWhenNormal = false
ui.btn_friends.Padding = Vector4(0, 0, 14, 0)
ui.btn_social_config.Hint = GetUTF8Text("UI_lobby_social_config")

function ui.mode_no_disturbe.EventCheckChanged(sender, e)
  if ComFuc.g_bNoDisturbed ~= sender.Check then
    ComFuc.g_bNoDisturbed = sender.Check
    rpc.safecall("set_social_detail", {
      isOpen = sender.Check and 1 or 0
    }, nil)
    if ComFuc.g_bNoDisturbed then
      MessageBox.ShowError(GetUTF8Text("msgbox_social_no_disturb_message"))
    end
  end
end

function ui.btn_social_config.EventClick(sender, e)
  ShowSocialConfig()
end

function ui.ui_social_config.EventLeave(sender, e)
  sender.Parent = nil
end

function ShowSocialConfig()
  ui.ui_social_config.Parent = ui.root
  ui.ui_social_config.Focused = true
  ui.mode_no_disturbe.Check = ComFuc.g_bNoDisturbed
end

function SetNoDisturbCheckBox(p)
  ui.mode_no_disturbe.Check = p
end

local ui_search_result, LayoutPage = Gui.Create()({
  ComFuc.ComControl("coverControl2", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(100, 0, 0, 0)),
  Gui.Control("root")({
    Location = Vector2(823, 161),
    Size = Vector2(402, 456),
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_207,
    Padding = Vector4(4, 4, 4, 9),
    Gui.FlowLayout({
      Dock = "kDockFill",
      Direction = "kVertical",
      Gui.Label({
        Dock = "kDockTop",
        Size = Vector2(0, 25),
        Margin = Vector4(16, 0, 0, 0),
        Text = GetUTF8Text("UI_social_additional_string_066"),
        FontSize = 16,
        Gui.Button("btn_close")({
          Dock = "kDockRight",
          Size = Vector2(24, 0),
          Margin = Vector4(0, 0, 6, 0),
          Skin = SkinF.lookInfo_002
        })
      }),
      Gui.Control({
        Dock = "kDockFill",
        BackgroundColor = colw,
        Skin = SkinF.battle_005,
        Margin = Vector4(4, 4, 4, 4),
        Gui.Control({
          Dock = "kDockBottom",
          Size = Vector2(0, 43),
          Margin = Vector4(0, 0, 0, 11),
          Gui.NewPagesBar("page_bar")({
            Size = Vector2(260, 36),
            Dock = "kDockLeft",
            Margin = Vector4(10, 2, 0, 0)
          }),
          Gui.Button("btn_search_add_friends")({
            Size = Vector2(84, 40),
            Dock = "kDockRight",
            Text = GetUTF8Text("button_common_Add_Friend"),
            Margin = Vector4(0, 0, 10, 0),
            Enable = false
          })
        }),
        Gui.Control({
          Dock = "kDockFill",
          BackgroundColor = colw,
          Skin = SkinF.personalInfo_068,
          Margin = Vector4(10, 10, 10, 10),
          Padding = Vector4(4, 6, 4, 6),
          Gui.ListTreeView("list")({
            Dock = "kDockFill",
            Style = "Sociality.FriendsList",
            VScrollBarDisplay = "kHide"
          })
        })
      })
    })
  })
}), {
  ComFuc.ComControl("coverControl2", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(100, 0, 0, 0)),
  Gui.Control("root")({
    Location = Vector2(823, 161),
    Size = Vector2(402, 456),
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_207,
    Padding = Vector4(4, 4, 4, 9),
    Gui.FlowLayout({
      Dock = "kDockFill",
      Direction = "kVertical",
      Gui.Label({
        Dock = "kDockTop",
        Size = Vector2(0, 25),
        Margin = Vector4(16, 0, 0, 0),
        Text = GetUTF8Text("UI_social_additional_string_066"),
        FontSize = 16,
        Gui.Button("btn_close")({
          Dock = "kDockRight",
          Size = Vector2(24, 0),
          Margin = Vector4(0, 0, 6, 0),
          Skin = SkinF.lookInfo_002
        })
      }),
      Gui.Control({
        Dock = "kDockFill",
        BackgroundColor = colw,
        Skin = SkinF.battle_005,
        Margin = Vector4(4, 4, 4, 4),
        Gui.Control({
          Dock = "kDockBottom",
          Size = Vector2(0, 43),
          Margin = Vector4(0, 0, 0, 11),
          Gui.NewPagesBar("page_bar")({
            Size = Vector2(260, 36),
            Dock = "kDockLeft",
            Margin = Vector4(10, 2, 0, 0)
          }),
          Gui.Button("btn_search_add_friends")({
            Size = Vector2(84, 40),
            Dock = "kDockRight",
            Text = GetUTF8Text("button_common_Add_Friend"),
            Margin = Vector4(0, 0, 10, 0),
            Enable = false
          })
        }),
        Gui.Control({
          Dock = "kDockFill",
          BackgroundColor = colw,
          Skin = SkinF.personalInfo_068,
          Margin = Vector4(10, 10, 10, 10),
          Padding = Vector4(4, 6, 4, 6),
          Gui.ListTreeView("list")({
            Dock = "kDockFill",
            Style = "Sociality.FriendsList",
            VScrollBarDisplay = "kHide"
          })
        })
      })
    })
  })
}

function LayoutPage(strPageName, index)
  return Gui.Control(strPageName)({
    Location = Vector2(7, 7),
    Size = Vector2(348, 434),
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_068,
    Gui.SocialityGroupList("group")({
      Dock = "kDockFill",
      BackgroundColor = col0,
      EventGroupExpand = function(sender, e)
        if index == 1 then
          if sender.Text == GetUTF8Text("button_common_My_Channel") then
            ui.btn_AddMyChannel.Visible = true
            bShowAddMyChannelBtn = true
          else
            ui.btn_AddMyChannel.Visible = false
            bShowAddMyChannelBtn = false
          end
        end
      end
    })
  })
end

local ui_page_channel = Gui.Create()({
  LayoutPage("page", 1)
})
local ui_page_friends = Gui.Create()({
  LayoutPage("page", 2)
})
local ui_add_channel = Gui.Create()({
  Gui.Control("root")({
    Location = Vector2(862, 622),
    Size = Vector2(300, 160),
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_207,
    ComFuc.ComLabel(nil, GetUTF8Text("button_common_Create_Channel"), Vector2(218, 18), Vector2(16, 6), 0, 16, colw),
    ComFuc.ComLabel(nil, GetUTF8Text("UI_social_Enter_Channel_Name"), Vector2(218, 18), Vector2(30, 40), 0, 16, ARGB(255, 82, 54, 44)),
    ComFuc.ComTextBox("txt_channel_name", "", Vector2(240, 26), Vector2(30, 68), 12),
    ComFuc.ComButton("btn_close", "", Vector2(24, 25), Vector2(266, 4), 16, false, false, SkinF.lookInfo_002),
    ComFuc.ComButton("btn_OK", GetUTF8Text("button_common_OK"), Vector2(60, 40), Vector2(70, 106), 16, false),
    ComFuc.ComButton("btn_Cancel", GetUTF8Text("button_common_Cancel"), Vector2(60, 40), Vector2(170, 106), 16, false)
  })
})
local m_ui_sys, sysTimer
local imgIndex = 1
sysBtn1_Skin = Gui.ButtonSkin({
  BackgroundImage = Gui.Image("ui/skinF/skin_common_button_normal.tga", Vector4(20, 18, 20, 18)),
  HoverImage = Gui.Image("ui/skinF/skin_common_button_hover.tga", Vector4(20, 18, 20, 18)),
  DownImage = Gui.Image("ui/skinF/skin_common_button_down.tga", Vector4(20, 18, 20, 18)),
  DisabledImage = Gui.Image("ui/skinF/skin_common_button_disabled.tga", Vector4(20, 18, 20, 18))
})
local sysBtn2_Skin, CreateSystemMsgWnd = Gui.ButtonSkin({
  BackgroundImage = Gui.Image("ui/skinF/skin_common_button_down.tga", Vector4(20, 18, 20, 18)),
  HoverImage = Gui.Image("ui/skinF/skin_common_button_hover.tga", Vector4(20, 18, 20, 18)),
  DownImage = Gui.Image("ui/skinF/skin_common_button_normal.tga", Vector4(20, 18, 20, 18)),
  DisabledImage = Gui.Image("ui/skinF/skin_common_button_disabled.tga", Vector4(20, 18, 20, 18))
}), Gui.ButtonSkin({
  BackgroundImage = Gui.Image("ui/skinF/skin_common_button_down.tga", Vector4(20, 18, 20, 18)),
  HoverImage = Gui.Image("ui/skinF/skin_common_button_hover.tga", Vector4(20, 18, 20, 18)),
  DownImage = Gui.Image("ui/skinF/skin_common_button_normal.tga", Vector4(20, 18, 20, 18)),
  DisabledImage = Gui.Image("ui/skinF/skin_common_button_disabled.tga", Vector4(20, 18, 20, 18))
})
local CreateSystemMsgWnd, StopTimer = function(parent_win)
  local ui = Gui.Create()({
    Gui.Window("root")({
      Location = Vector2(-313, 462),
      Size = Vector2(492, 388),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_207,
      ComFuc.ComLabel(nil, GetUTF8Text("button_common_System_Info"), Vector2(268, 24), Vector2(16, 4), 0, 16, colw),
      Gui.Control({
        Dock = "kDockTop",
        Size = Vector2(300, 30),
        ComFuc.ComLabel(nil, GetUTF8Text("button_common_System_Info"), Vector2(268, 24), Vector2(16, 4), 0, 16, colw),
        Gui.Button("close_btn")({
          Dock = "kDockRight",
          Size = Vector2(24, 24),
          Margin = Vector4(0, 4, 12, 2),
          Skin = SkinF.lookInfo_002,
          EventClick = function(sender, e)
            HideSysWnd()
          end
        })
      }),
      Gui.Control({
        Dock = "kDockFill",
        BackgroundColor = colw,
        Skin = SkinF.battle_005,
        Margin = Vector4(4, 4, 4, 10),
        Gui.Control({
          Dock = "kDockFill",
          Padding = Vector4(11, 11, 11, 11),
          Gui.NewMessagePanel("msg_panel")({
            Dock = "kDockFill",
            Style = "Sociality.MessagePanel",
            MaxTextWidth = 416,
            OnePageLineNum = 14,
            MaxLineNum = 300,
            LineGap = 1
          })
        })
      })
    })
  })
  ui.root.Parent = parent_win
  return ui
end, {
  BackgroundImage = Gui.Image("ui/skinF/skin_common_button_down.tga", Vector4(20, 18, 20, 18)),
  HoverImage = Gui.Image("ui/skinF/skin_common_button_hover.tga", Vector4(20, 18, 20, 18)),
  DownImage = Gui.Image("ui/skinF/skin_common_button_normal.tga", Vector4(20, 18, 20, 18)),
  DisabledImage = Gui.Image("ui/skinF/skin_common_button_disabled.tga", Vector4(20, 18, 20, 18))
}
local StopTimer, OnTimer = function()
  if sysTimer then
    game.TimerMgr:RemoveTimer(sysTimer)
    sysTimer = nil
    imgIndex = 1
    ui.btn_sysinfo.Skin = sysBtn1_Skin
  end
end, Gui.Image("ui/skinF/skin_common_button_disabled.tga", Vector4(20, 18, 20, 18))
local OnTimer, RunTimer = function()
  if imgIndex == 1 then
    ui.btn_sysinfo.Skin = sysBtn2_Skin
    imgIndex = 2
  else
    ui.btn_sysinfo.Skin = sysBtn1_Skin
    imgIndex = 1
  end
end, "ui/skinF/skin_common_button_disabled.tga"

function RunTimer()
  if m_ui_sys then
    GetSysMsgHistory()
  elseif not sysTimer then
    sysTimer = game.TimerMgr:AddTimer(0.5)
    sysTimer.EventOnTimer = OnTimer
    imgIndex = 1
  end
end

local lobbyTimer, OnLobbyTimer = nil, Vector4(20, 18, 20, 18)

function OnLobbyTimer()
  if Lobby then
    Lobby.ClearFirstLineMessage()
    if Lobby.GetMessageLineCount() < 1 then
      StopLobbyTimer()
    end
  end
end

function RunLobbyMsgTimer()
  if not lobbyTimer then
    lobbyTimer = game.TimerMgr:AddTimer(10)
    lobbyTimer.EventOnTimer = OnLobbyTimer
  end
end

function StopLobbyTimer()
  if lobbyTimer then
    game.TimerMgr:RemoveTimer(lobbyTimer)
    lobbyTimer = nil
  end
end

function AlignSysMsgWndUI()
  if m_ui_sys then
    Gui.Align(m_ui_sys.root, -313, 462)
  end
end

local GetSysMsgHistory, ShowSysWnd = function()
  if not m_ui_sys then
    return
  end
  m_ui_sys.msg_panel:ClearMessage()
  local pMsgItem
  local nIndex = 0
  local chat = ptr_cast(game.ChatConnect)
  if chat then
    while true do
      pMsgItem = chat:GetHistorySysMsg(nIndex)
      if not pMsgItem then
        break
      end
      m_ui_sys.msg_panel:AddSystemMessage(pMsgItem.Type, pMsgItem.Msg, true)
      nIndex = nIndex + 1
    end
  end
end, function()
  if not m_ui_sys then
    return
  end
  m_ui_sys.msg_panel:ClearMessage()
  local pMsgItem
  local nIndex = 0
  local chat = ptr_cast(game.ChatConnect)
  if chat then
    while true do
      pMsgItem = chat:GetHistorySysMsg(nIndex)
      if not pMsgItem then
        break
      end
      m_ui_sys.msg_panel:AddSystemMessage(pMsgItem.Type, pMsgItem.Msg, true)
      nIndex = nIndex + 1
    end
  end
end

function ShowSysWnd(parent_win, location)
  if not m_ui_sys then
    m_ui_sys = CreateSystemMsgWnd(parent_win)
    AlignSysMsgWndUI()
  end
  GetSysMsgHistory()
  StopTimer()
end

function HideSysWnd()
  if m_ui_sys then
    m_ui_sys.root.Parent = nil
    m_ui_sys = nil
  end
end

local ui.btn_sysinfo.EventClick, TabSetCurSel = function(sender, e)
  HideAddChannelUI()
  HideSearchResult()
  if m_ui_sys then
    HideSysWnd()
  else
    ShowSysWnd(gui, Vector2(199, 23))
  end
end, ui.btn_sysinfo

function TabSetCurSel(nIndex)
  ui.btn_channel.PushDown = false
  ui.btn_friends.PushDown = false
  ui_page_channel.page.Parent = nil
  ui_page_friends.page.Parent = nil
  if nIndex == 0 then
    ui_page_channel.page.Parent = ui.page_container
    ui.btn_channel.PushDown = true
    ui.btn_AddMyChannel.Visible = bShowAddMyChannelBtn
  else
    ui_page_friends.page.Parent = ui.page_container
    ui.btn_friends.PushDown = true
    ui.btn_AddMyChannel.Visible = false
  end
end

function MoveFriend(nChannelID, unPlayerID, strPlayerName, Option, level)
  local chat = ptr_cast(game.ChatConnect)
  if chat then
    chat:RequestMoveFriend(nChannelID, unPlayerID, Option, level)
  end
end

function AddFriend(playID, level)
  MoveFriend(STRANGER_GROUP, playID, nil, 2, level)
end

function AddFriendsGroupItem(Type, group_list, online_state, player_level, player_name, player_id, player_vip, rank_level, rank_type)
  local list = group_list
  local root = list.RootItem
  local item
  if tonumber(Type) == SEARCH_TYPE or tonumber(Type) == FRIEND_TYPE then
    item = list:AddItem(root, "")
    if tonumber(online_state) == INGAMING then
      item:SetIcon(LobbyBoxContern.ITEM_INDEX_ONLINE_ICON, IconsF.SocialityStatusIcons.PlayingA)
    elseif tonumber(online_state) == ONLINE then
      item:SetIcon(LobbyBoxContern.ITEM_INDEX_ONLINE_ICON, IconsF.SocialityStatusIcons.OnlineA)
    else
      item:SetIcon(LobbyBoxContern.ITEM_INDEX_ONLINE_ICON, IconsF.SocialityStatusIcons.OnlineN)
    end
    if rank_level and tonumber(rank_level) > 0 and tonumber(rank_level) < 15 and rank_type then
      list:AddSubItem(item, tonumber(rank_level))
      item:SetIcon(LobbyBoxContern.ITEM_INDEX_RANK_LEVEL_ICON, IconsF.RankIcons[tonumber(rank_type)][tonumber(rank_level)])
    else
      list:AddSubItem(item, 0)
      item:SetIcon(LobbyBoxContern.ITEM_INDEX_RANK_LEVEL_ICON, nil)
    end
    list:AddSubItem(item, "Lv" .. tonumber(player_level))
    item:SetTextColor(LobbyBoxContern.ITEM_INDEX_LEVEL_VALUE, colw)
    item:SetHighLightTextColor(LobbyBoxContern.ITEM_INDEX_LEVEL_VALUE, cols)
    list:AddSubItem(item, player_name)
    item:SetTextColor(LobbyBoxContern.ITEM_INDEX_PLAYER_NAME, colw)
    item:SetHighLightTextColor(LobbyBoxContern.ITEM_INDEX_PLAYER_NAME, cols)
    list:AddSubItem(item, player_id)
    list:AddSubItem(item, online_state)
    if player_vip and tonumber(player_vip) > 0 and tonumber(player_vip) < 6 then
      list:AddSubItem(item, player_vip)
      item:SetIcon(LobbyBoxContern.ITEM_INDEX_VIP_ICON, IconsF.RoomStatusIcons["vip_level" .. player_vip])
    elseif player_vip and tonumber(player_vip) ~= 0 then
      list:AddSubItem(item, player_vip)
      item:SetIcon(LobbyBoxContern.ITEM_INDEX_VIP_ICON, IconsF.RoomStatusIcons.vip_level_temp)
    else
      list:AddSubItem(item, 0)
      item:SetIcon(LobbyBoxContern.ITEM_INDEX_VIP_ICON, nil)
    end
    list:AddSubItem(item, rank_type)
  else
    item = list:AddItem(root, player_name)
    item:SetTextColor(0, colw)
    item:SetHighLightTextColor(0, cols)
    list:AddSubItem(item, player_id)
  end
  return item
end

function CopyName(name)
  local chat = ptr_cast(game.ChatConnect)
  if chat then
    chat:CopyName(name)
  end
end

function ui.btn_close.EventClick(sender, e)
  Hide()
end

function ui.btn_channel.EventClick(sender, e)
  TabSetCurSel(0)
end

local ui.btn_friends.EventClick, AddSearchFriend = function(sender, e)
  HideSearchResult()
  HideAddChannelUI()
  TabSetCurSel(1)
end, ui.btn_friends

function AddSearchFriend(list)
  if not list then
    return
  end
  if list.SelectedItem then
    if list.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_PLAYER_NAME) == SelectCharacter.role_text then
      MessageBox.ShowError(GetUTF8Text("msgbox_common_num_1324"))
    else
      local level = string.sub(list.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_LEVEL_VALUE), string.len("Lv") + 1)
      local vip = 0
      local rank_level = 0
      if list.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_VIP_VALUE) then
        vip = tonumber(list.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_VIP_VALUE))
      end
      if list.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_RANK_LEVEL) then
        rank_level = tonumber(list.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_RANK_LEVEL))
      end
      local chat = ptr_cast(game.ChatConnect)
      if chat then
        chat:SearchAddToFriend(list.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_ONLINE_ICON), tonumber(level), vip, list.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_PLAYER_NAME), list.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_PLAYER_ID), list.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_RANK_TYPE), rank_level)
      end
    end
  end
end

function ui_search_result.btn_search_add_friends.EventClick(sender, e)
  if ui_search_result.list.SelectedItem then
    AddSearchFriend(ui_search_result.list)
  end
end

local ui_search_result.list.EventClick, RefreshSearchResult = function(sender, e)
  local list = sender
  if list.SelectedItem then
    ui_search_result.btn_search_add_friends.Enable = true
  else
    ui_search_result.btn_search_add_friends.Enable = false
  end
end, ui_search_result.list

function RefreshSearchResult(search_name, search_page)
  local list = ui_search_result.list
  list:DeleteAll()
  rpc.safecall("friend_search", {
    name = search_name,
    currentPage = search_page,
    pageSize = 10
  }, function(data)
    for _, v in ipairs(data.friends.list) do
      AddFriendsGroupItem(SEARCH_TYPE, list, v.playerState, v.playerLevel, v.playerName, v.playerId, v.playerVipLevel, v.rankLevel, v.rankType)
    end
    local page_bar = ui_search_result.page_bar
    page_bar.EventIndexChanged = nil
    page_bar.PageCount = data.friends.pageNum
    page_bar.CurrIndex = data.friends.currentPage
    
    function page_bar.EventIndexChanged(sender, e)
      RefreshSearchResult(search_name, sender.CurrIndex)
    end
    
    if list.ItemCount > 0 then
      list.SelectedItem = list:GetItemAt(Vector2(0, 0))
      ui_search_result.btn_search_add_friends.Enable = true
      if page_bar.PageCount > 1 then
        page_bar.Enable = true
      end
    else
      ui_search_result.btn_search_add_friends.Enable = false
      page_bar.Enable = false
    end
  end)
end

local ui.btn_search.EventClick, AddMyChannel = function(sender, e)
  HideAddChannelUI()
  HideSearchResult()
  if not InputBox then
    require("inputBox.lua")
  end
  InputBox.Show(GetUTF8Text("UI_social_Search_Player"), GetUTF8Text("UI_social_Enter_Players_Nickname"), function(player_name)
    RefreshSearchResult(player_name, 1)
    ShowSearchResult()
  end)
end, ui.btn_search

function AddMyChannel()
  local channel_name = string.gsub(ui_add_channel.txt_channel_name.Text, "^%s+", "")
  channel_name = string.gsub(channel_name, "%s+$", "")
  local Name = channel_name
  channel_name = string.gsub(channel_name, "%" .. GetUTF8Text("button_common_Channel") .. "+$", "")
  channel_name = string.gsub(channel_name, "%s+$", "")
  if string.len(channel_name) == 0 then
    if Name == GetUTF8Text("button_common_Channel") then
      MessageBox.ShowError(GetUTF8Text("msgbox_social_additional_string_067"), 2)
    else
      MessageBox.ShowError(GetUTF8Text("UI_social_Enter_Channel_Name"), 2)
    end
    return
  end
  channel_name = channel_name .. GetUTF8Text("button_common_Channel")
  local chat = ptr_cast(game.ChatConnect)
  if chat and chat:SendAddMyChannal(channel_name) then
    ui_add_channel.btn_OK.Enable = false
  end
end

function HideAddChannelUI()
  if ui_add_channel.root.Parent then
    ui_add_channel.txt_channel_name.Text = ""
    ui_add_channel.btn_OK.Enable = false
    ui_add_channel.root.Parent = nil
  end
end

function ui.btn_AddMyChannel.EventClick(sender, e)
  ui_add_channel.root.Parent = gui
  ui_add_channel.btn_OK.Enable = true
  ui_add_channel.txt_channel_name.Text = ""
end

function ui_add_channel.btn_OK.EventClick(sender, e)
  AddMyChannel()
end

function ui_add_channel.txt_channel_name.EventValueEnter(sender, e)
  AddMyChannel()
end

function ui_add_channel.btn_close.EventClick(sender, e)
  HideAddChannelUI()
end

local ui_add_channel.btn_Cancel.EventClick, AddChannelGroup = function(sender, e)
  HideAddChannelUI()
end, ui_add_channel.btn_Cancel
local AddChannelGroup, InitFriendsGroupListPopupMenu = function(name, channel_id)
  local group = ui_page_channel.group:AddChannelGroup(name)
  local list = group.ChannelList
  local align
  group.Tag = channel_id
  list.ItemGap = 2
  if tonumber(channel_id) == PUBLIC_CHANNEL then
    list.Style = "Sociality.ChannelList2"
    align = "kAlignCenterMiddle"
  else
    list.Style = "Sociality.ChannelList"
    align = "kAlignLeftMiddle"
  end
  CommonUtility.InitLtvHeader(list, {
    {
      "",
      1,
      "kAlignCenterMiddle"
    },
    {
      "",
      1,
      align
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
      1,
      "kAlignCenterMiddle"
    }
  })
  
  function list.EventDoubleClick(sender, e)
    HideSearchResult()
    HideAddChannelUI()
    if sender.SelectedItem then
      if tonumber(channel_id) == PUBLIC_CHANNEL then
        if tonumber(list.SelectedItem:GetText(3)) >= tonumber(list.SelectedItem:GetText(4)) then
          if not ChatBar.CheckChatPairIsOpen(CHANNEL_TYPE, PUBLIC_CHANNEL, list.SelectedItem:GetText(2)) then
            MessageBox.ShowError(GetUTF8Text("msgbox_social_additional_string_068"), 2)
          end
        else
          local chat = ptr_cast(game.ChatConnect)
          if chat then
            chat:SendEnterOrLeaveChannal(PUBLIC_CHANNEL, list.SelectedItem:GetText(2), true)
          end
        end
      elseif tonumber(channel_id) == PUBLIC_CHANNEL then
        ChatBar.OpenChatPair(CHANNEL_TYPE, tonumber(channel_id), list.SelectedItem:GetText(2), sender.SelectedItem:GetText(1), true, true, 0, true)
      else
        ChatBar.OpenChatPair(CHANNEL_TYPE, tonumber(channel_id), list.SelectedItem:GetText(2), sender.SelectedItem:GetText(1), true, true, list.SelectedItem:GetText(5), true)
      end
    end
  end
  
  return group
end, function(sender, e)
  HideAddChannelUI()
end
local InitFriendsGroupListPopupMenu, InitFriendsGroupListPopupMenuForRecent = function(list)
  ComFuc.InitSocialityMenu(list.PopupMenu, {
    {
      "IDM_BEG_WISPER",
      GetUTF8Text("button_common_Chat"),
      function()
        if tonumber(list.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_ONLINE_VALUE)) == OFFLINE then
          MessageBox.ShowError(GetUTF8Text("msgbox_social_additional_string_069"))
        else
          ChatBar.OpenChatPair(FRIEND_TYPE, MYFRIEND_GROUP, list.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_PLAYER_ID), list.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_PLAYER_NAME), true, true, 0, true)
        end
      end
    },
    {
      "IDM_VIEW_PERSONALITY",
      GetUTF8Text("button_common_Info"),
      function()
        LookInfo.Show(list.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_PLAYER_ID))
      end
    },
    {
      "IDM_DELETE_FRIEND",
      GetUTF8Text("button_common_Delete"),
      function()
        local Msg = string.format(GetUTF8Text("msgbox_common_num_1242"), list.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_PLAYER_NAME))
        MessageBox.ShowWithConfirmCancel(Msg, function()
          MoveFriend(MYFRIEND_GROUP, list.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_PLAYER_ID), list.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_PLAYER_NAME), 0, 1)
        end, nil)
      end
    },
    {
      "IDM_MOVETO_BLACK",
      GetUTF8Text("button_common_Blacklist"),
      function()
        MoveFriend(MYFRIEND_GROUP, list.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_PLAYER_ID), list.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_PLAYER_NAME), 1, 1)
      end
    },
    {
      "IDM_COPY_NAME",
      GetUTF8Text("tips_social_copy_name"),
      function()
        CopyName(list.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_PLAYER_NAME))
      end
    }
  })
  
  function list.EventRightClick(sender, e)
    HideSearchResult()
    if sender.SelectedItem then
      local menu = sender.PopupMenu
      menu:Open()
    end
  end
end, Vector4(20, 18, 20, 18)
local InitFriendsGroupListPopupMenuForRecent, InitFriendsGroupListPopupMenuForBlack = function(list, nChannelID)
  ComFuc.InitSocialityMenu(list.PopupMenu, {
    {
      "IDM_ADD_FRIEND",
      GetUTF8Text("button_common_Add_Friend"),
      function()
        assert(list.SelectedItem)
        if nChannelID == SEARCH_TYPE then
          AddSearchFriend(list)
        else
          MoveFriend(LASTGAMER_GROUP, list.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_PLAYER_ID), list.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_PLAYER_NAME), 2, 1)
        end
      end
    },
    {
      "IDM_VIEW_PERSONALITY",
      GetUTF8Text("button_common_Info"),
      function()
        LookInfo.Show(list.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_PLAYER_ID))
      end
    },
    {
      "IDM_COPY_NAME",
      GetUTF8Text("tips_social_copy_name"),
      function()
        CopyName(list.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_PLAYER_NAME))
      end
    }
  })
  
  function list.EventRightClick(sender, e)
    if nChannelID ~= SEARCH_TYPE then
      HideSearchResult()
    end
    if sender.SelectedItem then
      sender.PopupMenu:Open()
    end
  end
end, Vector4(20, 18, 20, 18)
local InitFriendsGroupListPopupMenuForBlack, AddFriendsGroup = function(list)
  ComFuc.InitSocialityMenu(list.PopupMenu, {
    {
      "IDM_DELETE_FRIEND",
      GetUTF8Text("button_common_Delete"),
      function()
        local Msg = string.format(GetUTF8Text("msgbox_social_additional_string_070"), list.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_PLAYER_NAME))
        MessageBox.ShowWithConfirmCancel(Msg, function()
          MoveFriend(BLACKLIST_GROUP, list.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_PLAYER_ID), list.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_PLAYER_NAME), 0, 1)
        end, nil)
      end
    },
    {
      "IDM_VIEW_PERSONALITY",
      GetUTF8Text("button_common_Info"),
      function()
        LookInfo.Show(list.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_PLAYER_ID))
      end
    },
    {
      "IDM_ADD_TO_FRIEND",
      GetUTF8Text("button_common_Add_Friend"),
      function()
        MoveFriend(BLACKLIST_GROUP, list.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_PLAYER_ID), list.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_PLAYER_NAME), 3, 1)
      end
    },
    {
      "IDM_COPY_NAME",
      GetUTF8Text("tips_social_copy_name"),
      function()
        CopyName(list.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_PLAYER_NAME))
      end
    }
  })
  
  function list.EventRightClick(sender, e)
    HideSearchResult()
    if sender.SelectedItem then
      local menu = sender.PopupMenu
      menu:Open()
    end
  end
end, Vector4(20, 18, 20, 18)
local AddFriendsGroup, InitialSearchResult = function(name, id)
  local group = ui_page_friends.group:AddFriendsGroup(name)
  local list = group.FriendsList
  list.Style = "Sociality.FriendsList"
  LobbyBoxContern.InitFriendListHeader(list, 0)
  if tonumber(id) == tonumber(BLACKLIST_GROUP) then
    InitFriendsGroupListPopupMenuForBlack(list)
  elseif tonumber(id) == tonumber(LASTGAMER_GROUP) then
    InitFriendsGroupListPopupMenuForRecent(list, LASTGAMER_GROUP)
  else
    InitFriendsGroupListPopupMenu(list)
  end
  if id == MYFRIEND_GROUP then
    group.ExpendFlag = true
  end
  
  function list.EventDoubleClick(sender, e)
    HideSearchResult()
    HideAddChannelUI()
    if sender.SelectedItem then
      if tonumber(id) == tonumber(BLACKLIST_GROUP) then
        MessageBox.ShowError(GetUTF8Text("msgbox_common_num_1351"))
      elseif tonumber(id) == tonumber(MYFRIEND_GROUP) then
        if tonumber(list.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_ONLINE_VALUE)) == OFFLINE then
          MessageBox.ShowError(GetUTF8Text("msgbox_social_additional_string_071"), 2)
        else
          ChatBar.OpenChatPair(FRIEND_TYPE, id, list.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_PLAYER_ID), sender.SelectedItem:GetText(LobbyBoxContern.ITEM_INDEX_PLAYER_NAME), true, true, 0, true)
        end
      end
    end
  end
  
  return group
end, Vector4(20, 18, 20, 18)

function InitialSearchResult()
  local list = ui_search_result.list
  list:DeleteColumns()
  LobbyBoxContern.InitFriendListHeader(list, 1)
  InitFriendsGroupListPopupMenuForRecent(list, 0)
  
  function list.EventDoubleClick(sender, e)
    AddSearchFriend(list)
  end
  
  function ui_search_result.btn_close.EventClick(sender, e)
    local page_bar = ui_search_result.page_bar
    page_bar.CurrIndex = 1
    ui_search_result.coverControl2.Parent = nil
    ui_search_result.root.Parent = nil
  end
end

function ShowSearchResult()
  ui_search_result.coverControl2.Parent = gui
  ui_search_result.root.Parent = gui
  ui_search_result.page_bar.CurrIndex = 1
  AlignSearchResult()
end

function HideSearchResult()
  ui_search_result.coverControl2.Parent = nil
  ui_search_result.root.Parent = nil
end

local AlignSearchResult, UpdateChannel = function()
  Gui.Align(ui_search_result.root, 0.5, 0.5)
end, function()
  Gui.Align(ui_search_result.root, 0.5, 0.5)
end

function UpdateChannel(Type)
  local chat = ptr_cast(game.ChatConnect)
  if not chat then
    return
  end
  if tonumber(Type) == CHANNEL_TYPE then
    ui_page_channel.group:RemoveAllGroup()
  elseif tonumber(Type) == FRIEND_TYPE then
    ui_page_friends.group:RemoveAllGroup()
  else
    return
  end
  local channelItem
  local index = 0
  local group
  while true do
    channelItem = chat:GetChannelItem(Type, index)
    if not channelItem then
      break
    end
    if tonumber(Type) == CHANNEL_TYPE then
      group = AddChannelGroup(channelItem.Name, channelItem.ChannelID)
      chat:SetGroupList(Type, channelItem.ChannelID, group.ChannelList)
    else
      group = AddFriendsGroup(channelItem.Name, channelItem.ChannelID)
      chat:SetGroupList(Type, channelItem.ChannelID, group.FriendsList)
    end
    group.TitleBtn.CloseBtn.Visible = false
    if index == 0 then
      group.ExpendFlag = true
    end
    index = index + 1
  end
end

local HalfHot = Gui.Icon("/ui/skinF/skin_mail_icon07.tga", Vector4(0, 0, 0, 0))
local HotN, UpdateChannelGroup = Gui.Icon("/ui/skinF/skin_mail_icon08.tga", Vector4(0, 0, 0, 0)), "/ui/skinF/skin_mail_icon08.tga"
local UpdateChannelGroup, UpdateFriendList = function(sender, ChannelID, count)
  local list = sender
  local chat = ptr_cast(game.ChatConnect)
  if chat == nil or list == nil then
    return
  end
  local selected_item = list.SelectedItem
  list:DeleteAll()
  for i = 1, count do
    local Group = chat:GetChannelGroupItem(ChannelID, i - 1)
    if Group then
      local item = ptr_cast(list:AddItem(list.RootItem, ""), "Gui.SocialityChannelListItem")
      if item then
        item:SetLocation(0, Vector2(6, 6))
        item:SetSize(0, Vector2(48, 48))
        list:AddSubItem(item, Group.GroupName)
        item:SetTextColor(1, colw)
        item:SetHighLightTextColor(1, coly)
        if tonumber(ChannelID) == PUBLIC_CHANNEL then
          item:SetLocation(1, Vector2(28, 3))
        else
          item:SetLocation(1, Vector2(10, 5))
        end
        item:SetSize(1, Vector2(236, 23))
        list:AddSubItem(item, Group.GroupID)
        item:SetSize(2, Vector2(0, 0))
        if tonumber(ChannelID) == PUBLIC_CHANNEL then
          list:AddSubItem(item, Group.Player_num)
          item:SetSize(3, Vector2(0, 0))
        else
          if tonumber(ChannelID) == GONGHUI_CHANNEL then
            list:AddSubItem(item, GetUTF8Text("UI_common_Current_Size") .. ": " .. Group.Player_num)
          else
            list:AddSubItem(item, GetUTF8Text("UI_common_Current_Size") .. ": " .. Group.Player_num .. "/" .. Group.MaxPlayer)
          end
          item:SetTextColor(3, colw)
          item:SetHighLightTextColor(3, coly)
          item:SetLocation(3, Vector2(10, 28))
          item:SetSize(3, Vector2(199, 23))
        end
        list:AddSubItem(item, Group.MaxPlayer)
        item:SetSize(4, Vector2(0, 0))
        if tonumber(ChannelID) == PUBLIC_CHANNEL then
          list:AddSubItem(item, "")
          item:SetLocation(5, Vector2(263, 8))
          item:SetSize(5, Vector2(16, 16))
          if tonumber(Group.Pacent) >= tonumber(SHOW_ICON_COUNT_1) and tonumber(Group.Pacent) < tonumber(SHOW_ICON_COUNT_2) then
            item:SetIcon(5, HalfHot)
          elseif tonumber(Group.Pacent) >= tonumber(SHOW_ICON_COUNT_2) then
            item:SetIcon(5, HotN)
          end
        else
          list:AddSubItem(item, Group.OwerID)
          item:SetSize(5, Vector2(0, 0))
        end
        if selected_item and tonumber(selected_item:GetText(2)) == Group.GroupID then
          list.SelectedItem = item
        end
      end
    end
  end
  if tonumber(ChannelID) == PRIVATE_CHANNEL then
    if tonumber(count) == MAX_MYCHANNEL_COUNT then
      ui.btn_AddMyChannel.Enable = false
    else
      ui.btn_AddMyChannel.Enable = true
    end
  end
end, Vector4(0, 0, 0, 0)
local UpdateFriendList, InitChatCallBack = function(list, Type, ChannelID, GroupID, count)
  local chat = ptr_cast(game.ChatConnect)
  if not chat or not list then
    return
  end
  local selected_item = list.SelectedItem
  list:DeleteAll()
  for i = 1, count do
    local GroupItem = chat:GetFriendGroupItem(Type, ChannelID, GroupID, i - 1)
    local RetItem = AddFriendsGroupItem(Type, list, GroupItem.Online_state, GroupItem.Player_level, GroupItem.Player_name, GroupItem.PlayerID, GroupItem.Vip, GroupItem.Rank_Level, GroupItem.Rank_Type)
    if selected_item and selected_item:GetText(LobbyBoxContern.ITEM_INDEX_PLAYER_ID) == tostring(GroupItem.PlayerID) then
      list.SelectedItem = RetItem
    end
  end
end, Vector4(0, 0, 0, 0)

function InitChatCallBack()
  local chat = ptr_cast(game.ChatConnect)
  if not chat then
    return
  end
  
  function chat.EventReturnResult(sender, e)
    local state = ptr_cast(game.CurrentState, "Client.StateMainGame")
    if state then
      return
    end
    if e.RetValue == Text.SocialityErrorChat.kErrorSocialChatToFast then
    end
    if e.RetValue ~= 0 then
      if not ui_add_channel.btn_OK.Enable then
        ui_add_channel.btn_OK.Enable = true
      end
      HideSearchResult()
      MessageBox.ShowError(Text.SocialityErrorText[e.RetValue])
    else
      MessageBox.ShowError(e.msg)
    end
  end
  
  function chat.EventUpdateChannel(sender, e)
    if tonumber(e.ChannelID) == 0 then
      UpdateChannel(e.Type)
    elseif tonumber(e.GroupID) == 0 then
      if tonumber(e.Type) == CHANNEL_TYPE then
        UpdateChannelGroup(sender, e.ChannelID, e.Count)
      elseif tonumber(e.Type) == FRIEND_TYPE then
        UpdateFriendList(sender, e.Type, e.ChannelID, 0, e.Count)
      end
    elseif tonumber(e.Type) == CHANNEL_TYPE then
      UpdateFriendList(sender, e.Type, e.ChannelID, e.GroupID, e.Count)
    end
  end
  
  function chat.EventUpdateChatMsg(sender, e)
    ChatBar.OnUpdateChatMsg(sender, e)
  end
  
  function chat.EventAddChannel(sender, e)
    HideAddChannelUI()
    MessageBox.ShowError(GetUTF8Text("msgbox_common_num_1226"))
  end
  
  function chat.EventEnterChannel(sender, e)
    ChatBar.OpenChatPair(CHANNEL_TYPE, e.ChannelID, e.GroupID, e.GroupName, true, true, 0, true)
  end
  
  function chat.EventInviteFriend(sender, e)
    ChatBar.OnInviteFriend(sender, e)
  end
  
  function chat.EventFriendAsking(sender, e)
    local state = ptr_cast(game.CurrentState, "Client.StateMainGame")
    if state then
      return
    end
    local pItem = chat:GetFriendGroupItem(3, 0, 0, 0)
    if pItem then
      local Msg = string.format(GetUTF8Text("msgbox_social_additional_string_072"), pItem.Player_name)
      MessageBox.ShowWithConfirmCancel(Msg, function()
        chat:FriendAskingAgree(pItem.PlayerID, true)
      end, function()
        chat:FriendAskingAgree(pItem.PlayerID, false)
      end)
    end
  end
  
  function chat.EventUpdateChannelFriend(sender, e)
    ChatBar.OnUpdateChannelFriend(sender, e)
  end
  
  function chat.EventGroupDelete(sender, e)
    ChatBar.OnGroupDelete(sender, e)
  end
  
  function chat.EventSystemMessage(sender, e)
    if e.Type == 1 then
      LobbyBoxContern.ShowSysMsgTip(e.Type, e.msg)
      RunTimer()
    else
      Lobby.ShowSysMsgTip(e.Type, e.msg)
      RunLobbyMsgTimer()
    end
  end
  
  function chat.EventOnDisconnected(sender, e)
    print("EventOnDisconnected")
    if m_ui_sys then
      m_ui_sys.msg_panel:ClearMessage()
      HideSysWnd()
    end
    if ChatBar then
      ChatBar.CloseAllChatPaire()
    end
    Hide()
  end
end

function Initialize()
  bShowAddMyChannelBtn = false
  InitialSearchResult()
  InitChatCallBack()
  UpdateChannel(CHANNEL_TYPE)
  ui.btn_AddMyChannel.Visible = false
  UpdateChannel(FRIEND_TYPE)
  TabSetCurSel(1)
end

function AlignUI()
  Gui.Align(ui.root, -13, 253)
  AlignSearchResult()
  AlignSysMsgWndUI()
end

function Visible()
  return ui.root.Parent ~= nil
end

function Show(MailWin)
  ui.root.Parent = gui
  AlignUI()
  print("sociality show()")
  InitChatCallBack()
  if ui_page_channel.group and ui_page_channel.group:GroupIsEmpty() then
    UpdateChannel(CHANNEL_TYPE)
  end
  if ui_page_friends.group and ui_page_friends.group:GroupIsEmpty() then
    ui.btn_AddMyChannel.Visible = false
    UpdateChannel(FRIEND_TYPE)
  end
  ChatUnShow.AlignUI()
end

function Hide()
  ui.root.Parent = nil
  HideSearchResult()
  HideAddChannelUI()
  if ui_page_channel then
    ui_page_channel.group:RemoveAllGroup()
  end
  if ui_page_friends then
    ui_page_friends.group:RemoveAllGroup()
  end
  StopTimer()
  StopLobbyTimer()
  ChatUnShow.AlignUI()
end

Initialize()

function TestMsg()
  local Msg = "<msg type=\"p\" background=\"16769101\" color=\"8143627\" ><player name=\"ooxx\" id=\"0001\"/>fdfdsfdsfggFMMM <sysitem id=\"1\" name=\"bbb\" grade=\"3\"/></msg>"
  Lobby.ShowSysMsgTip(1, Msg)
end

function ShutDown(psw)
  local state = ptr_cast(game.CurrentState, "Client.StateLobby")
  if state then
    state:RequestShutdown(psw)
  end
end
