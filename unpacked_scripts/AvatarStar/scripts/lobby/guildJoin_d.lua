module("GuildJoin", package.seeall)
local col0 = ComFuc.col0
local colw = ComFuc.colw
local from = 1
local titleText = {
  GetUTF8Text("button_common_Join_Application"),
  GetUTF8Text("UI_lobby_consortia_interface_12")
}
local rpcInterface = {
  "guild_requisition_list",
  "guild_team_requisition_list"
}
local ui = Gui.Create()({
  ComFuc.ComControl("coverControl2", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(100, 0, 0, 0)),
  Gui.Control("root")({
    Dock = "kDockCenter",
    Size = Vector2(402, 536),
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
        Text = "",
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
          Size = Vector2(368, 418),
          Location = Vector2(10, 10),
          BackgroundColor = colw,
          Skin = SkinF.personalInfo_068,
          Padding = Vector4(6, 7, 6, 7),
          Gui.ListTreeView("list")({
            Dock = "kDockFill",
            Style = "Guild.AppliedList",
            VScrollBarDisplay = "kHide"
          })
        }),
        ComFuc.ComButton("btn_agree", GetUTF8Text("button_social_agreement"), Vector2(84, 40), Vector2(88, 441), 16, false, true),
        ComFuc.ComButton("btn_decline", GetUTF8Text("button_common_Decline"), Vector2(84, 40), Vector2(216, 441), 16, false, true),
        ComFuc.ComPagesBar("page_bar", Vector2(57, 383))
      })
    })
  })
})
local UpdateAll, AgreeOneMan = function()
  RefreshAppliedList(ui.page_bar.CurrIndex)
  if from == 2 then
    Guild.RpcCallGuildShow()
  end
end, function()
  RefreshAppliedList(ui.page_bar.CurrIndex)
  if from == 2 then
    Guild.RpcCallGuildShow()
  end
end
local AgreeOneMan, DeclineOneMan = function(list)
  local state = ptr_cast(game.CurrentState)
  if from == 1 then
    state:AgreeOneJoinGuild(list.SelectedItem:GetText(6))
  elseif from == 2 then
    state:AgreeOneToGuildTeam(1, list.SelectedItem:GetText(6))
  end
end, ComFuc.ComControl("coverControl2", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(100, 0, 0, 0))
local DeclineOneMan, InitListMenu = function(list)
  local state = ptr_cast(game.CurrentState)
  if from == 1 then
    state:DeclineOnejoinGuild(list.SelectedItem:GetText(6))
  elseif from == 2 then
    state:DisagreeOneToGuildTeam(1, list.SelectedItem:GetText(6))
  end
end, Gui.Control("root")({
  Dock = "kDockCenter",
  Size = Vector2(402, 536),
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
      Text = "",
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
        Size = Vector2(368, 418),
        Location = Vector2(10, 10),
        BackgroundColor = colw,
        Skin = SkinF.personalInfo_068,
        Padding = Vector4(6, 7, 6, 7),
        Gui.ListTreeView("list")({
          Dock = "kDockFill",
          Style = "Guild.AppliedList",
          VScrollBarDisplay = "kHide"
        })
      }),
      ComFuc.ComButton("btn_agree", GetUTF8Text("button_social_agreement"), Vector2(84, 40), Vector2(88, 441), 16, false, true),
      ComFuc.ComButton("btn_decline", GetUTF8Text("button_common_Decline"), Vector2(84, 40), Vector2(216, 441), 16, false, true),
      ComFuc.ComPagesBar("page_bar", Vector2(57, 383))
    })
  })
})
local InitListMenu, InitAppliedList = function(list)
  ComFuc.InitSocialityMenu(list.PopupMenu, {
    {
      "IDM_AGREE_ONE_MAN",
      GetUTF8Text("button_social_agreement"),
      function()
        AgreeOneMan(list)
      end
    },
    {
      "IDM_DECLINE_ONE_MAN",
      GetUTF8Text("button_common_Decline"),
      function()
        DeclineOneMan(list)
      end
    },
    {
      "IDM_VIEW_PERSONALITY",
      GetUTF8Text("button_common_Info"),
      function()
        LookInfo.Show(list.SelectedItem:GetText(6))
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
  Size = Vector2(402, 536),
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
      Text = "",
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
        Size = Vector2(368, 418),
        Location = Vector2(10, 10),
        BackgroundColor = colw,
        Skin = SkinF.personalInfo_068,
        Padding = Vector4(6, 7, 6, 7),
        Gui.ListTreeView("list")({
          Dock = "kDockFill",
          Style = "Guild.AppliedList",
          VScrollBarDisplay = "kHide"
        })
      }),
      ComFuc.ComButton("btn_agree", GetUTF8Text("button_social_agreement"), Vector2(84, 40), Vector2(88, 441), 16, false, true),
      ComFuc.ComButton("btn_decline", GetUTF8Text("button_common_Decline"), Vector2(84, 40), Vector2(216, 441), 16, false, true),
      ComFuc.ComPagesBar("page_bar", Vector2(57, 383))
    })
  })
})

function InitAppliedList()
  local list = ui.list
  list:DeleteColumns()
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
      1,
      "kAlignLeftMiddle"
    },
    {
      "",
      38,
      "kAlignLeftMiddle"
    },
    {
      "",
      1,
      "kAlignLeftMiddle"
    },
    {
      "",
      34,
      "kAlignLeftMiddle"
    },
    {
      "",
      1,
      "kAlignCenterMiddle"
    },
    {
      "",
      40,
      "kAlignLeftMiddle"
    },
    {
      "",
      175,
      "kAlignLeftMiddle"
    },
    {
      "",
      1,
      "kAlignLeftMiddle"
    },
    {
      "",
      36,
      "kAlignCenterMiddle"
    }
  })
  InitListMenu(list)
end

InitAppliedList()
local AddAppliedListItem = InitAppliedList

function AddAppliedListItem(list, v)
  local root = list.RootItem
  local item = list:AddItem(root, "")
  if tonumber(v.onlineState) == 3 then
    item:SetIcon(0, IconsF.SocialityStatusIcons.PlayingA)
  elseif tonumber(v.onlineState) == 2 then
    item:SetIcon(0, IconsF.SocialityStatusIcons.OnlineA)
  else
    item:SetIcon(0, IconsF.SocialityStatusIcons.OnlineN)
  end
  list:AddSubItem(item, v.onlineState)
  list:AddSubItem(item, tonumber(v.occupation))
  item:SetIcon(3, IconsF.jobIcons[tonumber(v.occupation) + 1])
  list:AddSubItem(item, tonumber(v.rankLevel))
  item:SetIcon(5, IconsF.RankIcons[tonumber(v.rankType) or 1][tonumber(v.rankLevel)])
  list:AddSubItem(item, v.pId)
  list:AddSubItem(item, "Lv" .. tonumber(v.level))
  item:SetTextColor(7, ARGB(255, 255, 255, 255))
  item:SetHighLightTextColor(7, ARGB(255, 62, 26, 1))
  list:AddSubItem(item, v.name)
  item:SetTextColor(8, ARGB(255, 255, 255, 255))
  item:SetHighLightTextColor(8, ARGB(255, 62, 26, 1))
  list:AddSubItem(item, v.vipLevel)
  if v.vipLevel and 0 < tonumber(v.vipLevel) and tonumber(v.vipLevel) < 6 then
    item:SetIcon(10, IconsF.RoomStatusIcons["vip_level" .. v.vipLevel])
  elseif v.vipLevel and tonumber(v.vipLevel) ~= 0 then
    item:SetIcon(10, IconsF.RoomStatusIcons.vip_level_temp)
  else
    item:SetIcon(10, nil)
  end
  return item
end

function RefreshAppliedList(page)
  local list = ui.list
  list:DeleteAll()
  rpc.safecall(rpcInterface[from], {currentPage = page, pageSize = 10}, function(data)
    if #data.list == 0 then
      Guild.ShowNewManReplay(false)
    end
    for _, v in ipairs(data.list) do
      AddAppliedListItem(list, v)
    end
    ui.page_bar.PageCount = data.pageNum
    ui.page_bar.CurrIndex = data.currentPage
    ui.btn_agree.Enable = 0 < list.ItemCount
    ui.btn_decline.Enable = 0 < list.ItemCount
    if 0 < list.ItemCount then
      list.SelectedItem = list:GetItemAt(Vector2(0, 0))
    end
  end)
end

function ui.btn_close.EventClick(sender, e)
  Hide()
end

function ui.list.EventClick(sender, e)
  ui.btn_agree.Enable = sender.SelectedItem
  ui.btn_decline.Enable = sender.SelectedItem
end

function ui.btn_agree.EventClick(sender, e)
  if ui.list.SelectedItem then
    AgreeOneMan(ui.list)
  end
end

function ui.btn_decline.EventClick(sender, e)
  if ui.list.SelectedItem then
    DeclineOneMan(ui.list)
  end
end

function ui.page_bar.EventIndexChanged(sender, e)
  RefreshAppliedList(sender.CurrIndex)
end

function Show(type)
  from = type
  ui.title.Text = titleText[from]
  ui.coverControl2.Parent = gui
  ui.root.Parent = gui
  RefreshAppliedList(1)
end

function Hide()
  ui.coverControl2.Parent = nil
  ui.root.Parent = nil
end
