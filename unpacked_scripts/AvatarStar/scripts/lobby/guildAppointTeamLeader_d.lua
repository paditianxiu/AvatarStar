module("GuildAppointTeamLeader", package.seeall)
local col0 = ComFuc.col0
local colw = ComFuc.colw
local colt = ComFuc.colt
local candidateList = {}
local teamList = {}
local state = ptr_cast(game.CurrentState)
local ui, InitTeamList = Gui.Create()({
  ComFuc.ComControl("coverControl2", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(100, 0, 0, 0)),
  Gui.Control("main")({
    Size = Vector2(616, 441),
    Dock = "kDockCenter",
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_207,
    Gui.Control({
      Size = Vector2(616, 40),
      ComFuc.ComLabel(nil, "  " .. GetUTF8Text("button_common_duizhangquanxian"), Vector2(608, 21), Vector2(4, 4), 0, 16, colw),
      ComFuc.ComButton("close", nil, Vector2(24, 24), Vector2(584, 4), 0, false, false, SkinF.lookInfo_002)
    }),
    Gui.Control({
      Size = Vector2(595, 388),
      Location = Vector2(10, 38),
      BackgroundColor = colw,
      Skin = SkinF.battle_005,
      Gui.Control({
        Size = Vector2(379, 325),
        Location = Vector2(8, 9),
        BackgroundColor = colw,
        Skin = SkinF.guild_042,
        ComFuc.ComLabel(nil, GetUTF8Text("UI_lobby_consortia_02"), Vector2(168, 30), Vector2(16, 4), 0, 16, colw),
        ComFuc.ComLabel(nil, GetUTF8Text("button_common_war_05"), Vector2(177, 30), Vector2(186, 4), 0, 16, colw),
        Gui.Control({
          Size = Vector2(367, 303),
          Location = Vector2(5, 39),
          Padding = Vector4(8, 0, 0, 0),
          Gui.ListTreeView("team_list")({
            Dock = "kDockFill",
            Style = "Guild.AppliedList"
          })
        })
      }),
      Gui.Control({
        Size = Vector2(183, 325),
        Location = Vector2(405, 9),
        BackgroundColor = colw,
        Skin = SkinF.guild_042,
        ComFuc.ComLabel(nil, GetUTF8Text("button_common_war_06"), Vector2(168, 30), Vector2(16, 4), 0, 16, colw),
        Gui.Control({
          Size = Vector2(171, 303),
          Location = Vector2(5, 39),
          Padding = Vector4(8, 0, 0, 0),
          Gui.ListTreeView("leader_list")({
            Dock = "kDockFill",
            Style = "Guild.AppliedList"
          })
        })
      })
    }),
    ComFuc.ComButton("btn_enlarge", GetUTF8Text("button_common_war_07"), Vector2(100, 40), Vector2(150, 379)),
    ComFuc.ComButton("btn_repeal", GetUTF8Text("button_common_chexiaoduizhang"), Vector2(100, 40), Vector2(260, 379)),
    ComFuc.ComButton("btn_cancel", GetUTF8Text("button_common_Cancel"), Vector2(100, 40), Vector2(370, 379))
  })
}), {
  ComFuc.ComControl("coverControl2", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(100, 0, 0, 0)),
  Gui.Control("main")({
    Size = Vector2(616, 441),
    Dock = "kDockCenter",
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_207,
    Gui.Control({
      Size = Vector2(616, 40),
      ComFuc.ComLabel(nil, "  " .. GetUTF8Text("button_common_duizhangquanxian"), Vector2(608, 21), Vector2(4, 4), 0, 16, colw),
      ComFuc.ComButton("close", nil, Vector2(24, 24), Vector2(584, 4), 0, false, false, SkinF.lookInfo_002)
    }),
    Gui.Control({
      Size = Vector2(595, 388),
      Location = Vector2(10, 38),
      BackgroundColor = colw,
      Skin = SkinF.battle_005,
      Gui.Control({
        Size = Vector2(379, 325),
        Location = Vector2(8, 9),
        BackgroundColor = colw,
        Skin = SkinF.guild_042,
        ComFuc.ComLabel(nil, GetUTF8Text("UI_lobby_consortia_02"), Vector2(168, 30), Vector2(16, 4), 0, 16, colw),
        ComFuc.ComLabel(nil, GetUTF8Text("button_common_war_05"), Vector2(177, 30), Vector2(186, 4), 0, 16, colw),
        Gui.Control({
          Size = Vector2(367, 303),
          Location = Vector2(5, 39),
          Padding = Vector4(8, 0, 0, 0),
          Gui.ListTreeView("team_list")({
            Dock = "kDockFill",
            Style = "Guild.AppliedList"
          })
        })
      }),
      Gui.Control({
        Size = Vector2(183, 325),
        Location = Vector2(405, 9),
        BackgroundColor = colw,
        Skin = SkinF.guild_042,
        ComFuc.ComLabel(nil, GetUTF8Text("button_common_war_06"), Vector2(168, 30), Vector2(16, 4), 0, 16, colw),
        Gui.Control({
          Size = Vector2(171, 303),
          Location = Vector2(5, 39),
          Padding = Vector4(8, 0, 0, 0),
          Gui.ListTreeView("leader_list")({
            Dock = "kDockFill",
            Style = "Guild.AppliedList"
          })
        })
      })
    }),
    ComFuc.ComButton("btn_enlarge", GetUTF8Text("button_common_war_07"), Vector2(100, 40), Vector2(150, 379)),
    ComFuc.ComButton("btn_repeal", GetUTF8Text("button_common_chexiaoduizhang"), Vector2(100, 40), Vector2(260, 379)),
    ComFuc.ComButton("btn_cancel", GetUTF8Text("button_common_Cancel"), Vector2(100, 40), Vector2(370, 379))
  })
}

function InitTeamList()
  local list = ui.team_list
  list:DeleteColumns()
  list:AddColumn("", 168, "kAlignLeftMiddle")
  list:AddColumn("", 170, "kAlignLeftMiddle")
  list:AddColumn("", 1, "kAlignLeftMiddle")
  list:AddColumn("", 1, "kAlignLeftMiddle")
end

InitTeamList()
local InitLeaderList = InitTeamList

function InitLeaderList()
  local list = ui.leader_list
  list:DeleteColumns()
  list:AddColumn("", 144, "kAlignLeftMiddle")
  list:AddColumn("", 1, "kAlignLeftMiddle")
end

InitLeaderList()
local RefreshTeamList, RefreshLeaderList = function(data)
  ui.team_list:DeleteAll()
  local list = ui.team_list
  local root = list.RootItem
  local per = data.permission
  teamList = data.teamList
  candidateList = data.guildMemberList
  for i = 1, #teamList do
    local team = teamList[i]
    local item = list:AddItem(root, "")
    item:SetText(item, team.teamName)
    item:SetTextColor(0, ARGB(255, 255, 255, 255))
    item:SetHighLightTextColor(0, ARGB(255, 62, 26, 1))
    local headerStr = GetUTF8Text("UI_common_duizhangkongque")
    if team.headerName then
      headerStr = team.headerName
    end
    list:AddSubItem(item, headerStr)
    item:SetTextColor(1, ARGB(255, 255, 255, 255))
    item:SetHighLightTextColor(1, ARGB(255, 62, 26, 1))
    list:AddSubItem(item, i)
    list:AddSubItem(item, 2 * i)
    item.ID = i
  end
  if data.gmFloor == 2 then
    ui.btn_enlarge.Enable = per.officer.appoint_captain == 1 or false
    ui.btn_repeal.Enable = per.officer.repeal_captain == 1 or false
  elseif data.gmFloor == 3 then
    ui.btn_enlarge.Enable = per.elite.appoint_captain == 1 or false
    ui.btn_repeal.Enable = per.elite.repeal_captain == 1 or false
  elseif data.gmFloor == 4 then
    ui.btn_enlarge.Enable = per.fresh.appoint_captain == 1 or false
    ui.btn_repeal.Enable = per.fresh.repeal_captain == 1 or false
  end
end, function(data)
  ui.team_list:DeleteAll()
  local list = ui.team_list
  local root = list.RootItem
  local per = data.permission
  teamList = data.teamList
  candidateList = data.guildMemberList
  for i = 1, #teamList do
    local team = teamList[i]
    local item = list:AddItem(root, "")
    item:SetText(item, team.teamName)
    item:SetTextColor(0, ARGB(255, 255, 255, 255))
    item:SetHighLightTextColor(0, ARGB(255, 62, 26, 1))
    local headerStr = GetUTF8Text("UI_common_duizhangkongque")
    if team.headerName then
      headerStr = team.headerName
    end
    list:AddSubItem(item, headerStr)
    item:SetTextColor(1, ARGB(255, 255, 255, 255))
    item:SetHighLightTextColor(1, ARGB(255, 62, 26, 1))
    list:AddSubItem(item, i)
    list:AddSubItem(item, 2 * i)
    item.ID = i
  end
  if data.gmFloor == 2 then
    ui.btn_enlarge.Enable = per.officer.appoint_captain == 1 or false
    ui.btn_repeal.Enable = per.officer.repeal_captain == 1 or false
  elseif data.gmFloor == 3 then
    ui.btn_enlarge.Enable = per.elite.appoint_captain == 1 or false
    ui.btn_repeal.Enable = per.elite.repeal_captain == 1 or false
  elseif data.gmFloor == 4 then
    ui.btn_enlarge.Enable = per.fresh.appoint_captain == 1 or false
    ui.btn_repeal.Enable = per.fresh.repeal_captain == 1 or false
  end
end
local RefreshLeaderList, rpc_refreshTeamList = function(data)
  local list = ui.leader_list
  local root = list.RootItem
  for i = 1, #data do
    local item = list:AddItem(root, "")
    item:SetText(item, data[i].playerName)
    item:SetTextColor(0, ARGB(255, 255, 255, 255))
    item:SetHighLightTextColor(0, ARGB(255, 62, 26, 1))
    list:AddSubItem(item, i)
    item.ID = i
  end
end, Gui.Control("main")({
  Size = Vector2(616, 441),
  Dock = "kDockCenter",
  BackgroundColor = colw,
  Skin = SkinF.personalInfo_207,
  Gui.Control({
    Size = Vector2(616, 40),
    ComFuc.ComLabel(nil, "  " .. GetUTF8Text("button_common_duizhangquanxian"), Vector2(608, 21), Vector2(4, 4), 0, 16, colw),
    ComFuc.ComButton("close", nil, Vector2(24, 24), Vector2(584, 4), 0, false, false, SkinF.lookInfo_002)
  }),
  Gui.Control({
    Size = Vector2(595, 388),
    Location = Vector2(10, 38),
    BackgroundColor = colw,
    Skin = SkinF.battle_005,
    Gui.Control({
      Size = Vector2(379, 325),
      Location = Vector2(8, 9),
      BackgroundColor = colw,
      Skin = SkinF.guild_042,
      ComFuc.ComLabel(nil, GetUTF8Text("UI_lobby_consortia_02"), Vector2(168, 30), Vector2(16, 4), 0, 16, colw),
      ComFuc.ComLabel(nil, GetUTF8Text("button_common_war_05"), Vector2(177, 30), Vector2(186, 4), 0, 16, colw),
      Gui.Control({
        Size = Vector2(367, 303),
        Location = Vector2(5, 39),
        Padding = Vector4(8, 0, 0, 0),
        Gui.ListTreeView("team_list")({
          Dock = "kDockFill",
          Style = "Guild.AppliedList"
        })
      })
    }),
    Gui.Control({
      Size = Vector2(183, 325),
      Location = Vector2(405, 9),
      BackgroundColor = colw,
      Skin = SkinF.guild_042,
      ComFuc.ComLabel(nil, GetUTF8Text("button_common_war_06"), Vector2(168, 30), Vector2(16, 4), 0, 16, colw),
      Gui.Control({
        Size = Vector2(171, 303),
        Location = Vector2(5, 39),
        Padding = Vector4(8, 0, 0, 0),
        Gui.ListTreeView("leader_list")({
          Dock = "kDockFill",
          Style = "Guild.AppliedList"
        })
      })
    })
  }),
  ComFuc.ComButton("btn_enlarge", GetUTF8Text("button_common_war_07"), Vector2(100, 40), Vector2(150, 379)),
  ComFuc.ComButton("btn_repeal", GetUTF8Text("button_common_chexiaoduizhang"), Vector2(100, 40), Vector2(260, 379)),
  ComFuc.ComButton("btn_cancel", GetUTF8Text("button_common_Cancel"), Vector2(100, 40), Vector2(370, 379))
})

function rpc_refreshTeamList()
  rpc.safecall("guild_team_info_detail", {}, RefreshTeamList)
end

function ui.btn_cancel.EventClick()
  Hide()
  GuildTeamCreate.RpcCallTeamShow()
end

function ui.btn_enlarge.EventClick()
  local t_item = ui.team_list.SelectedItem
  local c_item = ui.leader_list.SelectedItem
  local team_info = {}
  if t_item then
    team_info = teamList[t_item.ID]
  end
  if c_item then
    state:ChangeGuildTeamMemberJob(team_info.teamId, candidateList[c_item.ID].playerId, 1)
  else
    MessageBox.ShowError(GetUTF8Text("msgbox_common_weixuanzhongduiwu"))
  end
end

function ui.btn_repeal.EventClick()
  local t_item = ui.team_list.SelectedItem
  if t_item then
    local team_info = teamList[t_item.ID]
    if t_item:GetText(1) == GetUTF8Text("UI_common_duizhangkongque") then
      state:ChangeGuildTeamMemberJob(team_info.teamId, team_info.headerId, 2)
    else
      MessageBox.ShowWithConfirmCancel(string.format(GetUTF8Text("msgbox_common_chexiaoduizhang_2")), function(sender, e)
        state:ChangeGuildTeamMemberJob(team_info.teamId, team_info.headerId, 2)
      end)
    end
  else
    MessageBox.ShowError(GetUTF8Text("msgbox_common_weixuanzhongduiwu"))
  end
end

function ui.close.EventClick()
  Hide()
  GuildTeamCreate.RpcCallTeamShow()
end

function ui.team_list.EventSelectItemChange()
  local item = ui.team_list.SelectedItem
  ui.leader_list:DeleteAll()
  if item then
    RefreshLeaderList(candidateList)
  end
end

function Show(info)
  rpc_refreshTeamList()
  ui.coverControl2.Parent = gui
  ui.main.Parent = gui
end

function Hide()
  ui.coverControl2.Parent = nil
  ui.main.Parent = nil
end
