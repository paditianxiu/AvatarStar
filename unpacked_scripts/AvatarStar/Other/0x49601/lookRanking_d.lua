module("LookRanking", package.seeall)
local col0 = ComFuc.col0
local colw = ComFuc.colw
local colt = ComFuc.colt
local curSelRank = 1
local testRR = {
  GetUTF8Text("UI_social_rank_actor"),
  GetUTF8Text("UI_lobby_consortia_02")
}
local textRP = {
  GetUTF8Text("UI_lobby_victory_score"),
  GetUTF8Text("tips_abilities_Power"),
  GetUTF8Text("UI_lobby_MVP_times"),
  GetUTF8Text("UI_lobby_rank_total_score"),
  GetUTF8Text("UI_social_add_rank_button_01"),
  GetUTF8Text("UI_social_add_rank_button_02"),
  GetUTF8Text("UI_lobby_consortia_04"),
  GetUTF8Text("tips_lobby_explore_strength_tips"),
  GetUTF8Text("UI_lobby_explore_max_rank")
}
local testRN, ComBar = {
  GetUTF8Text("UI_social_military_rank"),
  GetUTF8Text("button_common_Avatar_Card"),
  GetUTF8Text("UI_lobby_consortia_03")
}, GetUTF8Text("UI_social_military_rank")

function ComBar(i)
  return Gui.Control("bar_" .. i)({
    Size = Vector2(670, 34),
    Location = Vector2(74, 88 + 36 * i),
    BackgroundColor = colw,
    Skin = SkinF.rank_010[1],
    Visible = false,
    ComFuc.ComLabel("bar_NO_" .. i, nil, Vector2(52, 36), Vector2(8, -1), 0, 16, colt, "kAlignCenterMiddle"),
    ComFuc.ComControl("bar_job" .. i, Vector2(30, 30), Vector2(74, 2), 255, SkinF.personalInfo_job[i % 3 + 1]),
    ComFuc.ComControl("bar_rank_i_" .. i, Vector2(32, 32), Vector2(106, 1), 255, SkinF.rank_006[1][1]),
    ComFuc.ComLabel("bar_lv_" .. i, nil, Vector2(42, 34), Vector2(148, 0), 0, 16, colt),
    ComFuc.ComLabel("bar_name_" .. i, nil, Vector2(250, 34), Vector2(196, 0), 0, 16, colt),
    ComFuc.ComControl("bar_vip" .. i, Vector2(32, 32), Vector2(346, 1), 255, SkinF.vipPadShow_004[i % 6 + 1]),
    ComFuc.ComLabel("bar_rank_n_" .. i, nil, Vector2(160, 34), Vector2(379, 0), 0, 16, colt),
    ComFuc.ComLabel("bar_power_" .. i, nil, Vector2(112, 34), Vector2(546, 0), 0, 16, colt, "kAlignCenterMiddle")
  })
end

local ui, InitUI = Gui.Create()({
  Gui.Control("main")({
    Dock = "kDockCenter",
    Size = Vector2(819, 611),
    BackgroundColor = colw,
    Skin = SkinF.rank_001,
    ComFuc.ComButton("self_rank_cha", nil, Vector2(24, 24), Vector2(730, 19), 0, false, false, SkinF.lookInfo_002),
    ComFuc.ComControl(nil, Vector2(300, 35), Vector2(260, 14), 255, SkinF.rank_011),
    Gui.Control({
      Size = Vector2(670, 34),
      Location = Vector2(74, 88),
      BackgroundColor = colw,
      Skin = SkinF.rank_004,
      ComFuc.ComLabel(nil, GetUTF8Text("UI_social_rank_title"), Vector2(300, 34), Vector2(8, 0), 0, 16, colw),
      ComFuc.ComLabel("R_R", testRR[1], Vector2(300, 34), Vector2(74, 0), 0, 16, colw),
      ComFuc.ComLabel("R_N", testRN[1], Vector2(180, 34), Vector2(379, 0), 0, 16, colw),
      ComFuc.ComLabel("R_G", GetUTF8Text("UI_lobby_Guild"), Vector2(160, 34), Vector2(395, 0), 0, 16, colw),
      ComFuc.ComLabel("R_P", textRP[1], Vector2(128, 34), Vector2(530, 0), 0, 16, colw, "kAlignCenterMiddle")
    }),
    ComBar(1),
    ComBar(2),
    ComBar(3),
    ComBar(4),
    ComBar(5),
    ComBar(6),
    ComBar(7),
    ComBar(8),
    ComBar(9),
    ComBar(10),
    ComBar(11)
  })
}), {
  Gui.Control("main")({
    Dock = "kDockCenter",
    Size = Vector2(819, 611),
    BackgroundColor = colw,
    Skin = SkinF.rank_001,
    ComFuc.ComButton("self_rank_cha", nil, Vector2(24, 24), Vector2(730, 19), 0, false, false, SkinF.lookInfo_002),
    ComFuc.ComControl(nil, Vector2(300, 35), Vector2(260, 14), 255, SkinF.rank_011),
    Gui.Control({
      Size = Vector2(670, 34),
      Location = Vector2(74, 88),
      BackgroundColor = colw,
      Skin = SkinF.rank_004,
      ComFuc.ComLabel(nil, GetUTF8Text("UI_social_rank_title"), Vector2(300, 34), Vector2(8, 0), 0, 16, colw),
      ComFuc.ComLabel("R_R", testRR[1], Vector2(300, 34), Vector2(74, 0), 0, 16, colw),
      ComFuc.ComLabel("R_N", testRN[1], Vector2(180, 34), Vector2(379, 0), 0, 16, colw),
      ComFuc.ComLabel("R_G", GetUTF8Text("UI_lobby_Guild"), Vector2(160, 34), Vector2(395, 0), 0, 16, colw),
      ComFuc.ComLabel("R_P", textRP[1], Vector2(128, 34), Vector2(530, 0), 0, 16, colw, "kAlignCenterMiddle")
    }),
    ComBar(1),
    ComBar(2),
    ComBar(3),
    ComBar(4),
    ComBar(5),
    ComBar(6),
    ComBar(7),
    ComBar(8),
    ComBar(9),
    ComBar(10),
    ComBar(11)
  })
}
local InitUI, DealNearbyList = function(k)
  if k == 7 then
    ui.R_N.Location = Vector2(235, 0)
    ui.R_P.Location = Vector2(555, 0)
  else
    ui.R_N.Location = Vector2(379, 0)
    ui.R_P.Location = Vector2(526, 0)
  end
  ui.R_N.Visible = 4 <= k and k <= 7
  ui.R_G.Visible = k == 7
  ui.R_R.Text = testRR[1]
  if k == 7 then
    ui.R_R.Text = testRR[2]
  end
  ui.R_N.Text = testRN[2]
  if k == 4 then
    ui.R_N.Text = testRN[1]
  elseif k == 7 then
    ui.R_N.Text = testRN[3]
  end
  ui.R_P.Text = textRP[k]
  if k == 9 then
    ui.R_P.Text = textRP[8]
  elseif k == 10 then
    ui.R_P.Text = textRP[9]
  end
  for i = 1, 11 do
    ui["bar_job" .. i].Visible = k ~= 7
    ui["bar_rank_i_" .. i].Visible = k ~= 7
    ui["bar_rank_n_" .. i].Visible = 4 <= k and k <= 7
    if k == 7 then
      ui["bar_lv_" .. i].Size = Vector2(160, 34)
      ui["bar_lv_" .. i].Location = Vector2(75, 0)
      ui["bar_name_" .. i].Size = Vector2(160, 34)
      ui["bar_name_" .. i].Location = Vector2(235, 0)
      ui["bar_rank_n_" .. i].Size = Vector2(160, 34)
      ui["bar_rank_n_" .. i].Location = Vector2(395, 0)
      ui["bar_power_" .. i].Size = Vector2(112, 34)
      ui["bar_power_" .. i].Location = Vector2(555, 0)
    else
      ui["bar_lv_" .. i].Size = Vector2(42, 34)
      ui["bar_lv_" .. i].Location = Vector2(148, 0)
      ui["bar_name_" .. i].Size = Vector2(250, 34)
      ui["bar_name_" .. i].Location = Vector2(196, 0)
      ui["bar_rank_n_" .. i].Size = Vector2(160, 34)
      ui["bar_rank_n_" .. i].Location = Vector2(379, 0)
      ui["bar_power_" .. i].Size = Vector2(112, 34)
      ui["bar_power_" .. i].Location = Vector2(526, 0)
    end
  end
end, Gui.Control("main")({
  Dock = "kDockCenter",
  Size = Vector2(819, 611),
  BackgroundColor = colw,
  Skin = SkinF.rank_001,
  ComFuc.ComButton("self_rank_cha", nil, Vector2(24, 24), Vector2(730, 19), 0, false, false, SkinF.lookInfo_002),
  ComFuc.ComControl(nil, Vector2(300, 35), Vector2(260, 14), 255, SkinF.rank_011),
  Gui.Control({
    Size = Vector2(670, 34),
    Location = Vector2(74, 88),
    BackgroundColor = colw,
    Skin = SkinF.rank_004,
    ComFuc.ComLabel(nil, GetUTF8Text("UI_social_rank_title"), Vector2(300, 34), Vector2(8, 0), 0, 16, colw),
    ComFuc.ComLabel("R_R", testRR[1], Vector2(300, 34), Vector2(74, 0), 0, 16, colw),
    ComFuc.ComLabel("R_N", testRN[1], Vector2(180, 34), Vector2(379, 0), 0, 16, colw),
    ComFuc.ComLabel("R_G", GetUTF8Text("UI_lobby_Guild"), Vector2(160, 34), Vector2(395, 0), 0, 16, colw),
    ComFuc.ComLabel("R_P", textRP[1], Vector2(128, 34), Vector2(530, 0), 0, 16, colw, "kAlignCenterMiddle")
  }),
  ComBar(1),
  ComBar(2),
  ComBar(3),
  ComBar(4),
  ComBar(5),
  ComBar(6),
  ComBar(7),
  ComBar(8),
  ComBar(9),
  ComBar(10),
  ComBar(11)
})

function DealNearbyList(data)
  data.rankingList = data.rankingList or data.rankingGuildList
  local tc = #data.rankingList
  for i = 1, 11 do
    ui["bar_" .. i].Visible = i <= tc
    if i <= tc then
      local td = data.rankingList[i]
      if curSelRank ~= 7 then
        ui["bar_job" .. i].Skin = SkinF.personalInfo_job[td.occupation % 4 + 1]
        ui["bar_rank_i_" .. i].Skin = SkinF.rank_006[math.max(1, td.rankType)][math.max(1, td.rankLevel)]
        ui["bar_lv_" .. i].Text = "LV" .. td.playerLevel
        if td.vipLevel > 0 then
          ui["bar_vip" .. i].Skin = SkinF.vipPadShow_004[td.vipLevel + 1]
        else
          ui["bar_vip" .. i].Skin = SkinF.vipPadShow_009
        end
      else
        ui["bar_lv_" .. i].Text = td.teamName or ""
      end
      ui["bar_vip" .. i].Visible = curSelRank ~= 7 and (1 <= td.vipLevel or td.vipLevel == -1)
      ui["bar_name_" .. i].Text = td.playerName or ""
      local tm = tonumber(td.ranking)
      if tm <= 3 then
        ui["bar_NO_" .. i].Text = nil
        ui["bar_NO_" .. i].BackgroundColor = colw
        ui["bar_NO_" .. i].Skin = SkinF.rank_008[tm]
      else
        ui["bar_NO_" .. i].Text = tm
        ui["bar_NO_" .. i].BackgroundColor = col0
      end
      if td.playerId == SelectCharacter.roleServerId or GuildTeamMy and td.playerId == GuildTeamMy.teamMyInfo.headerId then
        ui["bar_" .. i].Skin = SkinF.rank_010[2]
        ui["bar_NO_" .. i].TextColor = colw
        ui["bar_lv_" .. i].TextColor = colw
        ui["bar_name_" .. i].TextColor = colw
        ui["bar_rank_n_" .. i].TextColor = colw
        ui["bar_power_" .. i].TextColor = colw
      else
        ui["bar_" .. i].Skin = SkinF.rank_010[1]
        ui["bar_NO_" .. i].TextColor = colt
        ui["bar_lv_" .. i].TextColor = colt
        ui["bar_name_" .. i].TextColor = colt
        ui["bar_rank_n_" .. i].TextColor = colt
        ui["bar_power_" .. i].TextColor = colt
      end
      if curSelRank == 4 then
        if td.rankLevel <= 9 then
          ui["bar_rank_n_" .. i].Text = GetUTF8Text("UI_social_rank_lv_0" .. math.max(1, td.rankLevel))
        else
          ui["bar_rank_n_" .. i].Text = GetUTF8Text("UI_social_rank_lv_" .. math.max(1, td.rankLevel))
        end
      elseif curSelRank == 5 or curSelRank == 6 then
        ui["bar_rank_n_" .. i].Text = Tip._LL(td.pAvatarName)
      elseif curSelRank == 7 then
        ui["bar_rank_n_" .. i].Text = td.name or ""
      end
      if curSelRank == 1 then
        ui["bar_power_" .. i].Text = td.battlePoint
      elseif curSelRank == 2 then
        ui["bar_power_" .. i].Text = td.battleForce
      elseif curSelRank == 3 then
        ui["bar_power_" .. i].Text = td.mvpNum
      elseif curSelRank == 4 then
        ui["bar_power_" .. i].Text = td.rankPoint
      elseif curSelRank == 5 then
        ui["bar_power_" .. i].Text = td.praiseNum
      elseif curSelRank == 6 then
        ui["bar_power_" .. i].Text = td.defameNum
      elseif curSelRank == 7 then
        ui["bar_power_" .. i].Text = td.teamPower or ""
      elseif curSelRank == 9 then
        ui["bar_power_" .. i].Text = td.ventureForce or ""
      elseif curSelRank == 10 then
        ui["bar_power_" .. i].Text = td.passPoint or ""
      end
    end
  end
  ui.main.Parent = gui
end

function ui.self_rank_cha.EventClick(sender, e)
  Hide()
end

function Show(i, tp)
  curSelRank = i
  InitUI(curSelRank)
  rpc.safecall("player_nearby_list", {t = tp}, DealNearbyList)
end

function Hide()
  ui.main.Parent = nil
end
