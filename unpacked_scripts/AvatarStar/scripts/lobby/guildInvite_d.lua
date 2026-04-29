module("GuildInvite", package.seeall)
local col0 = ComFuc.col0
local colw = ComFuc.colw
local from = 1
local search_name = ""
local titleText = {
  GetUTF8Text("UI_social_additional_string_066"),
  GetUTF8Text("UI_lobby_consortia_interface_11")
}
local ui, InviteOneMan = Gui.Create()({
  ComFuc.ComControl("coverControl2", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(100, 0, 0, 0)),
  Gui.Control("root")({
    Dock = "kDockCenter",
    Size = Vector2(402, 456),
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_207,
    Padding = Vector4(4, 4, 4, 9),
    Gui.FlowLayout({
      BackgroundColor = col0,
      Dock = "kDockFill",
      Direction = "kVertical",
      Gui.Label("title")({
        Dock = "kDockTop",
        Size = Vector2(0, 25),
        BackgroundColor = col0,
        Margin = Vector4(16, 0, 0, 0),
        Text = GetUTF8Text("button_common_Join_Application"),
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
          BackgroundColor = col0,
          Margin = Vector4(0, 0, 0, 11),
          Gui.NewPagesBar("page_bar")({
            Size = Vector2(260, 36),
            Dock = "kDockLeft",
            Margin = Vector4(10, 2, 0, 0)
          }),
          Gui.Button("btn_invite")({
            Size = Vector2(84, 40),
            Dock = "kDockRight",
            Text = GetUTF8Text("button_common_Invite"),
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
    Dock = "kDockCenter",
    Size = Vector2(402, 456),
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_207,
    Padding = Vector4(4, 4, 4, 9),
    Gui.FlowLayout({
      BackgroundColor = col0,
      Dock = "kDockFill",
      Direction = "kVertical",
      Gui.Label("title")({
        Dock = "kDockTop",
        Size = Vector2(0, 25),
        BackgroundColor = col0,
        Margin = Vector4(16, 0, 0, 0),
        Text = GetUTF8Text("button_common_Join_Application"),
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
          BackgroundColor = col0,
          Margin = Vector4(0, 0, 0, 11),
          Gui.NewPagesBar("page_bar")({
            Size = Vector2(260, 36),
            Dock = "kDockLeft",
            Margin = Vector4(10, 2, 0, 0)
          }),
          Gui.Button("btn_invite")({
            Size = Vector2(84, 40),
            Dock = "kDockRight",
            Text = GetUTF8Text("button_common_Invite"),
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
local InviteOneMan, InitListMenu = function(list)
  local state = ptr_cast(game.CurrentState)
  if from == 1 then
    state:InviteGuild(list.SelectedItem:GetText(5))
  elseif from == 2 then
    state:InviteOneToGuildTeam(list.SelectedItem:GetText(5))
  end
end, ComFuc.ComControl("coverControl2", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(100, 0, 0, 0))
local InitListMenu, InitMemberList = function(list)
  ComFuc.InitSocialityMenu(list.PopupMenu, {
    {
      "IDM_INVITE_TO_GUILD",
      GetUTF8Text("button_common_Invite"),
      function()
        InviteOneMan(list)
      end
    },
    {
      "IDM_VIEW_PERSONALITY",
      GetUTF8Text("button_common_Info"),
      function()
        LookInfo.Show(list.SelectedItem:GetText(5))
      end
    }
  })
  
  function list.EventRightClick(sender, e)
    if sender.SelectedItem then
      sender.PopupMenu:Open()
    end
  end
end, Gui.Control("root")({
  Dock = "kDockCenter",
  Size = Vector2(402, 456),
  BackgroundColor = colw,
  Skin = SkinF.personalInfo_207,
  Padding = Vector4(4, 4, 4, 9),
  Gui.FlowLayout({
    BackgroundColor = col0,
    Dock = "kDockFill",
    Direction = "kVertical",
    Gui.Label("title")({
      Dock = "kDockTop",
      Size = Vector2(0, 25),
      BackgroundColor = col0,
      Margin = Vector4(16, 0, 0, 0),
      Text = GetUTF8Text("button_common_Join_Application"),
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
        BackgroundColor = col0,
        Margin = Vector4(0, 0, 0, 11),
        Gui.NewPagesBar("page_bar")({
          Size = Vector2(260, 36),
          Dock = "kDockLeft",
          Margin = Vector4(10, 2, 0, 0)
        }),
        Gui.Button("btn_invite")({
          Size = Vector2(84, 40),
          Dock = "kDockRight",
          Text = GetUTF8Text("button_common_Invite"),
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

function InitMemberList()
  local list = ui.list
  list:DeleteColumns()
  LobbyBoxContern.InitFriendListHeader(list, 1)
  InitListMenu(list)
end

InitMemberList()

function RefreshMemberList(k)
  k = k or ui.page_bar.CurrIndex
  local list = ui.list
  list:DeleteAll()
  if from == 1 then
    rpc.safecall("friend_search", {
      name = search_name,
      currentPage = k,
      pageSize = 10
    }, function(data)
      for _, v in ipairs(data.friends.list) do
        Sociality.AddFriendsGroupItem(0, list, v.playerState, v.playerLevel, v.playerName, v.playerId, v.playerVipLevel, v.rankLevel, v.rankType)
      end
      ui.page_bar.PageCount = data.friends.pageNum
      ui.page_bar.CurrIndex = data.friends.currentPage
      ui.btn_invite.Enable = 0 < list.ItemCount
      if 0 < list.ItemCount then
        list.SelectedItem = list:GetItemAt(Vector2(0, 0))
      end
    end)
  elseif from == 2 then
    local Deta = {}
    local tk = 1
    rpc.safecall("guild_show", {onlineState = "N"}, function(data)
      local dtlt = data.list
      for i = 1, #dtlt do
        local isOnly = true
        local v = dtlt[i]
        for j = 1, #GuildTeamMy.memDt do
          local p = GuildTeamMy.memDt[j]
          if v.pId == p.playerId then
            isOnly = false
            break
          end
        end
        if isOnly then
          Deta[tk] = v
          tk = tk + 1
        end
      end
      local pPage = 10
      local t = math.min(pPage, #Deta - (k - 1) * pPage)
      for i = 1, t do
        local tm = (k - 1) * pPage + i
        local v = Deta[tm]
        Sociality.AddFriendsGroupItem(0, list, v.state, v.level, v.name, v.pId, v.vipLevel, v.rankLevel, v.rankType)
      end
      ui.page_bar.CurrIndex = k
      ui.page_bar.PageCount = math.floor((#Deta - 0.1) / pPage) + 1
      ui.btn_invite.Enable = 0 < list.ItemCount
      if 0 < list.ItemCount then
        list.SelectedItem = list:GetItemAt(Vector2(0, 0))
      end
    end)
  end
end

function ui.btn_close.EventClick(sender, e)
  Hide()
end

function ui.list.EventClick(sender, e)
  ui.btn_invite.Enable = sender.SelectedItem
end

function ui.btn_invite.EventClick(sender, e)
  if ui.list.SelectedItem then
    InviteOneMan(ui.list)
  end
end

function ui.page_bar.EventIndexChanged(sender, e)
  RefreshMemberList()
end

function Show(type, name)
  from = type
  search_name = name
  ui.title.Text = titleText[from]
  ui.coverControl2.Parent = gui
  ui.root.Parent = gui
  RefreshMemberList(1)
end

function Hide()
  ui.coverControl2.Parent = nil
  ui.root.Parent = nil
end
