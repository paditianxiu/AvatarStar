module("GuildTeamMy", package.seeall)
memDt = {}
local temDt = {}
local colw = ComFuc.colw
local colt = ComFuc.colt
local colh = ARGB(100, 255, 255, 255)
teamMyInfo = {}
local infoItem, ComInfoItem = {
  GetUTF8Text("UI_lobby_consortia_interface_08"),
  GetUTF8Text("UI_lobby_consortia_interface_09"),
  GetUTF8Text("UI_lobby_consortia_04"),
  GetUTF8Text("button_common_rank_info")
}, GetUTF8Text("UI_lobby_consortia_interface_08")

function ComInfoItem(i)
  return Gui.Control({
    Size = Vector2(360, 41),
    Location = Vector2(70, 87 + 38 * i),
    BackgroundColor = colh,
    Skin = SkinF.guild_035,
    ComFuc.ComLabel(nil, infoItem[i], Vector2(312, 24), Vector2(18, 7), 0, 16, colw),
    ComFuc.ComLabel("infoBar_" .. i, 0, Vector2(312, 24), Vector2(18, 7), 0, 16, colw, "kAlignRightMiddle")
  })
end

function ComTeamItem(i)
  return Gui.LcButton("member_" .. i)({
    Size = Vector2(360, 41),
    Location = Vector2(24, 28 + 38 * i),
    BackgroundColor = colw,
    Skin = SkinF.guild_039,
    CanPushDown = true,
    Visible = false,
    ComFuc.ComControl("leader_" .. i, Vector2(360, 41), Vector2(0, 0), 255, SkinF.guild_040, false, false),
    ComFuc.ComControl("job_" .. i, Vector2(30, 30), Vector2(30, 5), 255, SkinF.personalInfo_job[1]),
    ComFuc.ComControl("rank_" .. i, Vector2(30, 30), Vector2(64, 5), 255, SkinF.rank_006[1][1]),
    ComFuc.ComLabel("level_" .. i, "", Vector2(210, 30), Vector2(98, 5), 0, 16, colw),
    ComFuc.ComLabel("name_" .. i, "", Vector2(170, 30), Vector2(138, 5), 0, 16, colw),
    ComFuc.ComControl("vip_" .. i, Vector2(30, 30), Vector2(312, 5), 255, SkinF.vipPadShow_009)
  })
end

local ui = Gui.Create()({
  Gui.Control("main")({
    Size = Vector2(1128, 645),
    Gui.Control({
      Size = Vector2(533, 615),
      Location = Vector2(20, 16),
      BackgroundColor = colw,
      Skin = SkinF.skin_playgame_017,
      ComFuc.ComButton("quit_btn", GetUTF8Text("UI_lobby_consortia_interface_10"), Vector2(140, 40), Vector2(20, 560)),
      ComFuc.ComButton("invite_btn", GetUTF8Text("UI_lobby_consortia_interface_11"), Vector2(140, 40), Vector2(226, 560)),
      ComFuc.ComButton("reply_btn", GetUTF8Text("UI_lobby_consortia_interface_12"), Vector2(140, 40), Vector2(372, 560)),
      ComFuc.ComControl("has_new_replay", Vector2(25, 22), Vector2(491, 555), 255, SkinF.guild_029),
      Gui.Control({
        Size = Vector2(500, 515),
        Location = Vector2(16, 27),
        BackgroundColor = colw,
        Skin = SkinF.guild_036,
        ComInfoItem(1),
        ComInfoItem(2),
        ComInfoItem(3),
        ComInfoItem(4),
        ComFuc.ComLabel(nil, GetUTF8Text("UI_lobby_consortia_interface_07"), Vector2(200, 24), Vector2(150, 26), 0, 16, colw, "kAlignCenterMiddle"),
        ComFuc.ComButton("rank_btn", nil, Vector2(18, 18), Vector2(404, 251), nil, false, false, SkinF.lookInfo_005)
      })
    }),
    Gui.Control({
      Size = Vector2(552, 610),
      Location = Vector2(560, 16),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel(nil, GetUTF8Text("UI_lobby_consortia_interface_06"), Vector2(549, 27), Vector2(16, 3), 0, 16, colw),
      Gui.Control({
        Size = Vector2(508, 286),
        Location = Vector2(22, 36),
        BackgroundColor = colw,
        Skin = SkinF.battle_005,
        Gui.Control({
          Size = Vector2(410, 273),
          Location = Vector2(49, 8),
          BackgroundColor = colw,
          Skin = SkinF.guild_034,
          ComTeamItem(1),
          ComTeamItem(2),
          ComTeamItem(3),
          ComTeamItem(4),
          ComTeamItem(5),
          ComFuc.ComLabel("teamName", "", Vector2(206, 24), Vector2(64, 12), 0, 16, colw, "kAlignCenterMiddle"),
          ComFuc.ComLabel("teamCout", "1/5", Vector2(64, 22), Vector2(310, 26), 0, 16, colw, "kAlignCenterMiddle")
        })
      }),
      Gui.Control({
        Size = Vector2(508, 150),
        Location = Vector2(22, 333),
        BackgroundColor = colw,
        Skin = SkinF.battle_005,
        ComFuc.ComLabel("gameMatch_text", "", Vector2(460, 120), Vector2(33, 15), 0, 16, colt, "kAlignLeftMiddle")
      }),
      Gui.Control({
        Size = Vector2(552, 124),
        Location = Vector2(0, 491),
        BackgroundColor = colw,
        Skin = SkinF.guild_037,
        ComFuc.ComBtnHasPreIcon("btn_goMatch", GetUTF8Text("UI_lobby_consortia_interface_16"), Vector2(234, 63), Vector2(48, 48), Vector2(159, 34), nil, false, false, SkinF.select_character_029, SkinF.guild_038, 10)
      })
    }),
    ComFuc.ComMenu("menu_1")
  })
})
ui.gameMatch_text.AutoWrap = true
ui["menu_" .. 1]:AddItem(GetUTF8Text("UI_datalist_consortia_troop_33"))
ui["menu_" .. 1]:AddItem(GetUTF8Text("button_common_Add_Friends"))
ui["menu_" .. 1]:AddItem(GetUTF8Text("button_common_Info"))
ui.menu_1:Close()

function ShowNewManReplay(isReplay)
  ui.has_new_replay.Visible = isReplay
end

function SelItem(k)
  for i = 1, 5 do
    ui["member_" .. i].PushDown = i == k
    if i == k then
      ui["level_" .. i].TextColor = colt
      ui["name_" .. i].TextColor = colt
    else
      ui["level_" .. i].TextColor = colw
      ui["name_" .. i].TextColor = colw
    end
  end
  if k and 0 < k and k <= 5 then
    temDt = memDt[k]
    ui.menu_1:SetEnable(0, temDt.playerId ~= SelectCharacter.roleServerId and teamMyInfo.headerId == SelectCharacter.roleServerId)
    ui.menu_1:SetEnable(1, temDt.playerId ~= SelectCharacter.roleServerId)
    ui.menu_1:SetEnable(2, temDt.playerId ~= SelectCharacter.roleServerId)
  end
end

for i = 1, 5 do
  ui["member_" .. i].EventClick = function(sender, e)
    SelItem(i)
  end
  ui["member_" .. i].EventRightClick = function(sender, e)
    ui.menu_1.Location = sender.CurrentCursorPosition + Vector2(ComFuc.locationChanged, 0)
    ui.menu_1:Open()
    SelItem(i)
  end
end

function ui.menu_1.EventClick(sender, e)
  local t = sender.SelectedIndex
  if t == 0 then
    MessageBox.ShowWithConfirmCancel(GetUTF8Text("UI_lobby_consortia_troop_24"), function()
      local state = ptr_cast(game.CurrentState)
      state:KickOneFromGuildTeam(temDt.playerId)
      ComFuc.isQuitBySelf = false
    end)
  elseif t == 1 then
    Sociality.AddFriend(temDt.playerId, temDt.playerLevel)
  elseif t == 2 then
    LookInfo.Show(temDt.playerId)
  end
end

function ui.rank_btn.EventClick()
  if not LookRanking then
    require("lookRanking.lua")
  end
  LookRanking.Show(7, 7)
end

function ui.quit_btn.EventClick()
  MessageBox.ShowWithConfirmCancel(GetUTF8Text("UI_lobby_consortia_troop_27"), function()
    local state = ptr_cast(game.CurrentState)
    state:KickOneFromGuildTeam(SelectCharacter.roleServerId)
    ComFuc.isQuitBySelf = true
  end)
end

function ui.invite_btn.EventClick()
  if not GuildInvite then
    require("guildInvite.lua")
  end
  GuildInvite.Show(2)
end

function ui.reply_btn.EventClick()
  if not GuildJoin then
    require("guildJoin.lua")
  end
  GuildJoin.Show(2)
end

local ui.btn_goMatch.EventClick, DealGuildTeamMy = function()
  if LobbyPlayGame and LobbyPlayGame.CheckEquipment() then
    gui:PlayAudio("game_launch")
    Lobby.OnComSwitch(2)
    LobbyBattleGame.TeamMatchIn(2)
  end
end, ui.btn_goMatch

function DealGuildTeamMy(data)
  teamMyInfo = data
  ui.invite_btn.Visible = teamMyInfo.headerId == SelectCharacter.roleServerId
  ui.reply_btn.Visible = teamMyInfo.headerId == SelectCharacter.roleServerId
  ui.has_new_replay.Visible = teamMyInfo.headerId == SelectCharacter.roleServerId
  ui.infoBar_1.Text = data.teamWinNum
  ui.infoBar_2.Text = data.teamLoseNum
  ui.infoBar_3.Text = data.teamScore
  ui.rank_btn.Visible = data.teamRanking and tonumber(data.teamRanking) > 0
  if data.teamRanking and tonumber(data.teamRanking) > 0 then
    ui.infoBar_4.Text = data.teamRanking
  else
    ui.infoBar_4.Text = nil
  end
  ui.teamName.Text = data.teamName
  ui.teamCout.Text = tostring(#data.teamMemberList) .. "/5"
  ShowNewManReplay(data.newTeamRequisition)
  memDt = {}
  local pos = 5
  local leader = false
  for k = 1, #data.teamMemberList do
    local v = data.teamMemberList[k]
    if teamMyInfo.headerId == v.playerId then
      leader = true
    end
  end
  for i = 1, 5 do
    local v = data.teamMemberList[i]
    ui["member_" .. i].Visible = v
    if v then
      local t = i
      ui["leader_" .. t].Visible = false
      if teamMyInfo.headerId == v.playerId then
        t = 1
        pos = i
        ui["leader_" .. t].Visible = true
      end
      if i < pos and leader then
        t = i + 1
      elseif i < pos and not leader then
        t = i
      end
      memDt[t] = v
      ui["job_" .. t].Skin = SkinF.personalInfo_job[tonumber(v.occupation) + 1]
      ui["rank_" .. t].Skin = SkinF.rank_006[v.rankType][v.rankLevel]
      ui["level_" .. t].Text = "LV" .. v.level
      ui["name_" .. t].Text = v.name
      if 1 <= tonumber(v.vipLevel) then
        ui["vip_" .. t].Skin = SkinF.vipPadShow_004[tonumber(v.vipLevel) + 1]
      elseif tonumber(v.vipLevel) == -1 then
        ui["vip_" .. t].Skin = SkinF.vipPadShow_009
      else
        ui["vip_" .. t].Skin = SkinF.skin_touming
      end
    end
  end
  local weekTime = {
    GetUTF8Text("UI_common_time_week_01"),
    GetUTF8Text("UI_common_time_week_02"),
    GetUTF8Text("UI_common_time_week_03"),
    GetUTF8Text("UI_common_time_week_04"),
    GetUTF8Text("UI_common_time_week_05"),
    GetUTF8Text("UI_common_time_week_06"),
    GetUTF8Text("UI_common_time_week_07")
  }
  local publicMsg = GetUTF8Text("UI_common_consortia_compete_time") .. "\n"
  for i = 1, 8 do
    local v = data.configGuildTeamNotice.teamTimes[i]
    if v then
      local t1 = tostring(v.startHour)
      local t2 = tostring(v.startMinute)
      local t3 = tostring(v.endHour)
      local t4 = tostring(v.endMinute)
      if v.startHour < 10 then
        t1 = "0" .. t1
      end
      if v.startMinute < 10 then
        t2 = "0" .. t2
      end
      if v.endHour < 10 then
        t3 = "0" .. t3
      end
      if v.endMinute < 10 then
        t4 = "0" .. t4
      end
      publicMsg = publicMsg .. "   " .. weekTime[v.startWeak] .. " " .. t1 .. ":" .. t2 .. " - " .. weekTime[v.endWeak] .. " " .. t3 .. ":" .. t4
      if math.fmod(i, 2) == 0 then
        publicMsg = publicMsg .. "\n"
      end
    end
  end
  if math.fmod(#data.configGuildTeamNotice.teamTimes, 2) == 1 then
    publicMsg = publicMsg .. "\n"
  end
  publicMsg = publicMsg .. data.configGuildTeamNotice.notice
  ui.gameMatch_text.Text = publicMsg
  ui.btn_goMatch.Enable = LobbyBattleGame.matchType == 1 and not ComFuc.isInRoom and not ComFuc.isReadyStart and not ComFuc.isReadyMatch and teamMyInfo.headerId == SelectCharacter.roleServerId
end

function UpDateMemberList()
  rpc.safecall("guild_team_show", {}, DealGuildTeamMy)
end

function Show(parentCtrl)
  UpDateMemberList()
  SelItem(0)
  ComFuc.isQuitBySelf = false
  ui.main.Parent = parentCtrl
end

function Hide()
  ui.main.Parent = nil
end
