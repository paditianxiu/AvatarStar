module("GuildTeamCreate", package.seeall)
local colw = ComFuc.colw
local teamListInfo = {}
local teamEnlargeInfo = {}
local teamIdList, ComTeam = {}, nil

function ComTeam(i)
  return Gui.Control("team_" .. i)({
    Size = Vector2(410, 317),
    Location = ComFuc.ComputLocation(i, -410, -323, 2, 420, 323),
    BackgroundColor = colw,
    Skin = SkinF.guild_043,
    ComFuc.ComTeamItem("teamMember_" .. i, 1, Vector2(24, 58)),
    ComFuc.ComTeamItem("teamMember_" .. i, 2, Vector2(24, 96)),
    ComFuc.ComTeamItem("teamMember_" .. i, 3, Vector2(24, 134)),
    ComFuc.ComTeamItem("teamMember_" .. i, 4, Vector2(24, 172)),
    ComFuc.ComTeamItem("teamMember_" .. i, 5, Vector2(24, 210)),
    ComFuc.ComControl("hasReplay_" .. i, Vector2(28, 28), Vector2(18, 30), 255, SkinF.guild_027),
    ComFuc.ComLabel("teamName_" .. i, "", Vector2(206, 24), Vector2(64, 12), 0, 16, colw, "kAlignCenterMiddle"),
    ComFuc.ComLabel("teamCout_" .. i, "0/5", Vector2(64, 22), Vector2(310, 22), 0, 16, colw, "kAlignCenterMiddle"),
    ComFuc.ComButton("team_add_" .. i, GetUTF8Text("UI_lobby_consortia_interface_04"), Vector2(160, 40), Vector2(222, 260), 16),
    ComFuc.ComButton("team_dis_" .. i, GetUTF8Text("button_datalist_jiesanzhandui"), Vector2(160, 40), Vector2(26, 260), 16)
  })
end

local ui, ShowInputTeamName = Gui.Create()({
  Gui.Control("main")({
    Size = Vector2(1128, 645),
    BackgroundColor = colw,
    Skin = SkinF.guild_025,
    Gui.Control({
      Size = Vector2(908, 110),
      Location = Vector2(110, 14),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel(nil, GetUTF8Text("button_common_war_01"), Vector2(549, 27), Vector2(16, 3), 0, 16, colw),
      ComFuc.ComButton("btn_create", GetUTF8Text("UI_lobby_consortia_interface_02"), Vector2(160, 56), Vector2(113, 40), 16, false, true, SkinF.select_character_038),
      ComFuc.ComButton("btn_appoint", GetUTF8Text("button_common_duizhangquanxian"), Vector2(160, 56), Vector2(294, 40), 16, false, true, SkinF.select_character_038),
      ComFuc.ComButton("btn_enlarge", GetUTF8Text("button_common_war_03"), Vector2(160, 56), Vector2(475, 40), 16, false, true, SkinF.select_character_038)
    }),
    Gui.Control({
      Size = Vector2(908, 488),
      Location = Vector2(110, 133),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel("team_title", GetUTF8Text("UI_datalist_consortia_troop_29"), Vector2(549, 27), Vector2(16, 3), 0, 16, colw),
      ComFuc.ComControl(nil, Vector2(880, 438), Vector2(19, 39), 255, SkinF.battle_005),
      Gui.ScrollableControl({
        Size = Vector2(871, 420),
        Location = Vector2(19, 48),
        HScrollBarDisplay = "kHide",
        VScrollBarDisplay = "kVisible",
        VScrollBarWidth = 22,
        AutoScroll = true,
        AutoSize = true,
        AutoScrollMinSize = Vector2(871, 420),
        Gui.Control("goos_Content")({
          Size = Vector2(871, 1415),
          ComTeam(1),
          ComTeam(2),
          ComTeam(3),
          ComTeam(4),
          ComTeam(5),
          ComTeam(6),
          ComTeam(7),
          ComTeam(8),
          ComTeam(9),
          ComTeam(10)
        })
      })
    })
  })
}), {
  Gui.Control("main")({
    Size = Vector2(1128, 645),
    BackgroundColor = colw,
    Skin = SkinF.guild_025,
    Gui.Control({
      Size = Vector2(908, 110),
      Location = Vector2(110, 14),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel(nil, GetUTF8Text("button_common_war_01"), Vector2(549, 27), Vector2(16, 3), 0, 16, colw),
      ComFuc.ComButton("btn_create", GetUTF8Text("UI_lobby_consortia_interface_02"), Vector2(160, 56), Vector2(113, 40), 16, false, true, SkinF.select_character_038),
      ComFuc.ComButton("btn_appoint", GetUTF8Text("button_common_duizhangquanxian"), Vector2(160, 56), Vector2(294, 40), 16, false, true, SkinF.select_character_038),
      ComFuc.ComButton("btn_enlarge", GetUTF8Text("button_common_war_03"), Vector2(160, 56), Vector2(475, 40), 16, false, true, SkinF.select_character_038)
    }),
    Gui.Control({
      Size = Vector2(908, 488),
      Location = Vector2(110, 133),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel("team_title", GetUTF8Text("UI_datalist_consortia_troop_29"), Vector2(549, 27), Vector2(16, 3), 0, 16, colw),
      ComFuc.ComControl(nil, Vector2(880, 438), Vector2(19, 39), 255, SkinF.battle_005),
      Gui.ScrollableControl({
        Size = Vector2(871, 420),
        Location = Vector2(19, 48),
        HScrollBarDisplay = "kHide",
        VScrollBarDisplay = "kVisible",
        VScrollBarWidth = 22,
        AutoScroll = true,
        AutoSize = true,
        AutoScrollMinSize = Vector2(871, 420),
        Gui.Control("goos_Content")({
          Size = Vector2(871, 1415),
          ComTeam(1),
          ComTeam(2),
          ComTeam(3),
          ComTeam(4),
          ComTeam(5),
          ComTeam(6),
          ComTeam(7),
          ComTeam(8),
          ComTeam(9),
          ComTeam(10)
        })
      })
    })
  })
}

function ShowInputTeamName()
  local state = ptr_cast(game.CurrentState)
  state:CreateGuildTeam(NameCreate.GetInputName())
end

local inputNameInfo = {
  title = GetUTF8Text("UI_lobby_consortia_interface_02"),
  tips = GetUTF8Text("UI_lobby_consortia_interface_05"),
  funcSure = ShowInputTeamName
}

function ui.btn_create.EventClick()
  if ComFuc.isHasGuildTeam then
    MessageBox.ShowError(GetUTF8Text("msgbox_common_chexiaoduizhang_4"))
    return
  end
  if not NameCreate then
    require("nameCreate.lua")
  end
  NameCreate.Show(inputNameInfo)
end

function ui.btn_appoint.EventClick()
  if not GuildAppointTeamLeader then
    require("guildAppointTeamLeader.lua")
  end
  GuildAppointTeamLeader.Show()
end

function ui.btn_enlarge.EventClick()
  if not GuildTeamEnlarge then
    require("guildTeamEnlarge.lua")
  end
  teamEnlargeInfo[3] = Guild.guildEnlargeInfo[3]
  GuildTeamEnlarge.Show(teamEnlargeInfo)
end

for i = 1, 10 do
  ui["team_add_" .. i].EventClick = function()
    rpc.safecall("guild_team_member_requisition", {
      teamId = teamListInfo[i].teamId
    }, function(data)
    end)
  end
  ui["team_dis_" .. i].EventClick = function()
    MessageBox.ShowWithConfirmCancel(string.format(GetUTF8Text("msgbox_common_jiesanzhandui_2")), function(sender, e)
      rpc.safecall("guild_team_dismiss", {
        guildTeamId = teamIdList[i]
      }, function(data)
        rpc.safecall("guild_team_list", {}, DealGuildTeamList)
      end)
    end)
  end
  local SetButtonPermission = Gui.Control("main")({
    Size = Vector2(1128, 645),
    BackgroundColor = colw,
    Skin = SkinF.guild_025,
    Gui.Control({
      Size = Vector2(908, 110),
      Location = Vector2(110, 14),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel(nil, GetUTF8Text("button_common_war_01"), Vector2(549, 27), Vector2(16, 3), 0, 16, colw),
      ComFuc.ComButton("btn_create", GetUTF8Text("UI_lobby_consortia_interface_02"), Vector2(160, 56), Vector2(113, 40), 16, false, true, SkinF.select_character_038),
      ComFuc.ComButton("btn_appoint", GetUTF8Text("button_common_duizhangquanxian"), Vector2(160, 56), Vector2(294, 40), 16, false, true, SkinF.select_character_038),
      ComFuc.ComButton("btn_enlarge", GetUTF8Text("button_common_war_03"), Vector2(160, 56), Vector2(475, 40), 16, false, true, SkinF.select_character_038)
    }),
    Gui.Control({
      Size = Vector2(908, 488),
      Location = Vector2(110, 133),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel("team_title", GetUTF8Text("UI_datalist_consortia_troop_29"), Vector2(549, 27), Vector2(16, 3), 0, 16, colw),
      ComFuc.ComControl(nil, Vector2(880, 438), Vector2(19, 39), 255, SkinF.battle_005),
      Gui.ScrollableControl({
        Size = Vector2(871, 420),
        Location = Vector2(19, 48),
        HScrollBarDisplay = "kHide",
        VScrollBarDisplay = "kVisible",
        VScrollBarWidth = 22,
        AutoScroll = true,
        AutoSize = true,
        AutoScrollMinSize = Vector2(871, 420),
        Gui.Control("goos_Content")({
          Size = Vector2(871, 1415),
          ComTeam(1),
          ComTeam(2),
          ComTeam(3),
          ComTeam(4),
          ComTeam(5),
          ComTeam(6),
          ComTeam(7),
          ComTeam(8),
          ComTeam(9),
          ComTeam(10)
        })
      })
    })
  })
end

function DealGuildTeamList(data)
  teamListInfo = data.teamList
  teamEnlargeInfo[1] = #teamListInfo
  teamEnlargeInfo[2] = data.maxGuildTeamNum
  ui.team_title.Text = GetUTF8Text("UI_datalist_consortia_troop_29") .. " (" .. #teamListInfo .. "/" .. data.maxGuildTeamNum .. ")"
  local permission = data.permission
  for i = 1, 10 do
    local p = teamListInfo[i]
    ui["team_" .. i].Visible = p
    if p then
      teamIdList[i] = p.teamId
      ui["teamName_" .. i].Text = p.teamName
      ui["teamCout_" .. i].Text = tostring(#p) .. "/5"
      ui["team_add_" .. i].Visible = #p < 5
      local pos = 5
      local leader = false
      for k = 1, #p do
        local v = p[k]
        if p.headerId == v.playerId then
          leader = true
        end
      end
      for j = 1, 5 do
        local v = p[j]
        ui["teamMember_" .. i .. j].Visible = v
        if v then
          local t = j
          ui["teamMember_" .. i .. t .. "leader"].Visible = false
          if p.headerId == v.playerId then
            t = 1
            pos = j
            ui["teamMember_" .. i .. t .. "leader"].Visible = true
          end
          if j < pos and leader then
            t = j + 1
          elseif j < pos and not leader then
            t = j
          end
          ui["teamMember_" .. i .. t .. "job"].Skin = SkinF.personalInfo_job[tonumber(v.occupation) + 1]
          ui["teamMember_" .. i .. t .. "rank"].Skin = SkinF.rank_006[v.rankType][v.rankLevel]
          ui["teamMember_" .. i .. t .. "level"].Text = "LV" .. v.level
          ui["teamMember_" .. i .. t .. "name"].Text = v.name
          if 1 <= tonumber(v.vipLevel) then
            ui["teamMember_" .. i .. t .. "vip"].Skin = SkinF.vipPadShow_004[tonumber(v.vipLevel) + 1]
          elseif tonumber(v.vipLevel) == -1 then
            ui["teamMember_" .. i .. t .. "vip"].Skin = SkinF.vipPadShow_009
          else
            ui["teamMember_" .. i .. t .. "vip"].Skin = SkinF.skin_touming
          end
        end
      end
      SetButtonPermission(data.gmFloor, permission, i)
    end
  end
  SetButtonPermission(data.gmFloor, permission)
  local c = #teamListInfo
  ui.goos_Content.Size = Vector2(871, math.max(420, 323 * math.floor((c + 1) / 2) - 6))
  SetIsHasGuildTeam()
  Guild.SetIsHasGuildTeam(data.isInTeam)
end

function SetIsHasGuildTeam()
  for i = 1, 10 do
    ui["team_add_" .. i].Enable = not ComFuc.isHasGuildTeam
  end
end

function RpcCallTeamShow()
  rpc.safecall("guild_team_list", {}, DealGuildTeamList)
end

function Show(parentCtrl)
  RpcCallTeamShow()
  ui.main.Parent = parentCtrl
end

function Hide()
  ui.main.Parent = nil
end
