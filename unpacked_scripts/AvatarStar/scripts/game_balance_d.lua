module("Balance", package.seeall)
col0 = ARGB(0, 0, 0, 0)
colw = ARGB(255, 255, 255, 255)
colh = ARGB(127, 255, 255, 255)
colg = ARGB(255, 0, 255, 0)
colg2 = ARGB(255, 191, 251, 62)
coly = ARGB(255, 255, 255, 0)
coly2 = ARGB(255, 255, 222, 0)
local ComMenu = ComFuc.ComMenu
local add_friend_temp_data, equDt
local hasCount = 0
local totalTime = 0
local gradualTime = 0
local showCardT = 10
local missCardT = 14
local timer, ptBar
local isPlayOd = false
local isGet = {
  false,
  false,
  false,
  false,
  false,
  false,
  false,
  false,
  false
}
local isChance = {
  0,
  0,
  0,
  0,
  0
}
local isCanOpen = 0
local prizeDt, taskDt
local expDt = {}
local RankDt = {}
local game_type = 0
local prizeLev = 0
local prizeCurr = 1
local temp_add_id = 0
local temp_add_name = 0
local SelfPlayResult = 0
local TotalBossStage, IsBiocheMode = 5, nil

function IsBiocheMode(game_type)
  return game_type == 10 or game_type == 13
end

local color_sel = {
  ARGB(255, 255, 101, 74),
  ARGB(255, 128, 215, 255),
  ARGB(255, 254, 185, 0)
}
local tip_player_interface, ComGoalFinish = {
  "tip_player_skill",
  "tip_player_item",
  "tip_player_item",
  "tip_player_item",
  "tip_player_avatar_other",
  "tip_player_avatar_other"
}, "tip_player_skill"
local ComGoalFinish, ItemButton = function(name, i, lc)
  return Gui.Control({
    Size = Vector2(120, 186),
    Location = lc,
    ComFuc.ComControl(nil, Vector2(120, 140), Vector2(0, 0), 255, SkinF.boss_balance_03),
    ComFuc.ComControl(name .. "_content_" .. i, Vector2(120, 140), Vector2(0, 0), 255, SkinF.boss_balance_03),
    ComFuc.ComControl(name .. "_pass_" .. i, Vector2(120, 140), Vector2(0, 0), 255, SkinF.boss_balance_04),
    ComFuc.ComLabel(nil, GetMatchedUTF8Text(GetUTF8Text("UI_grade_pass_stage") .. "," .. i) .. "  ", Vector2(140, 20), Vector2(0, 4), 0, 14, colw, "kAlignCenterMiddle"),
    ComFuc.ComLabel(nil, GetUTF8Text("UI_grade_pass_time_cost"), Vector2(120, 20), Vector2(0, 144), 0, 16, colw, "kAlignCenterMiddle"),
    ComFuc.ComLabel(name .. "_time_" .. i, "00:00:00", Vector2(120, 20), Vector2(0, 167), 0, 16, colw, "kAlignCenterMiddle")
  })
end, "tip_player_item"
local ItemButton, BioItemButton = function(i, p)
  return Gui.LcButton("itemB_" .. i .. "_" .. p)({
    Style = "",
    Size = Vector2(760, 33),
    Location = Vector2(6, 44 + 34 * p),
    BackgroundColor = colw,
    Skin = SkinF.balance_018[i][1],
    Gui.Control("itemB_s_" .. i .. "_" .. p)({
      Size = Vector2(772, 32),
      Visible = false,
      ComFuc.ComLabel("rank_NO_" .. i .. "_" .. p, p, Vector2(40, 33), Vector2(0, 0), 0, 16, color_sel[i], "kAlignCenterMiddle"),
      ComFuc.ComLabel("rank_level_" .. i .. "_" .. p, "LV1", Vector2(50, 33), Vector2(40, 0), 0, 16, color_sel[i], "kAlignCenterMiddle"),
      ComFuc.ComControl("rank_job_" .. i .. "_" .. p, Vector2(31, 31), Vector2(99, 1), 255),
      ComFuc.ComControl("rank_rank_" .. i .. "_" .. p, Vector2(32, 32), Vector2(135, 1), 255, SkinF.rank_006[1][1]),
      ComFuc.ComLabel("rank_name_" .. i .. "_" .. p, "XXX", Vector2(150, 33), Vector2(185, 0), 0, 16, color_sel[i]),
      ComFuc.ComControl("rank_vipL_" .. i .. "_" .. p, Vector2(32, 33), Vector2(304, 0), 255, SkinF.vipPadShow_004[1]),
      ComFuc.ComLabel("rank_kill_" .. i .. "_" .. p, "1/1", Vector2(86, 33), Vector2(330, 0), 0, 16, color_sel[i], "kAlignCenterMiddle"),
      ComFuc.ComLabel("rank_hart_" .. i .. "_" .. p, nil, Vector2(86, 33), Vector2(416, 0), 0, 16, color_sel[i], "kAlignCenterMiddle"),
      ComFuc.ComLabel("rank_mode_" .. i .. "_" .. p, nil, Vector2(86, 33), Vector2(502, 0), 0, 16, color_sel[i], "kAlignCenterMiddle"),
      ComFuc.ComLabel("rank_chain_" .. i .. "_" .. p, nil, Vector2(86, 33), Vector2(588, 0), 0, 16, color_sel[i], "kAlignCenterMiddle"),
      ComFuc.ComLabel("rank_score_" .. i .. "_" .. p, nil, Vector2(86, 33), Vector2(674, 0), 0, 16, color_sel[3], "kAlignCenterMiddle")
    })
  })
end, "tip_player_item"
local BioItemButton, Team = function(i, p)
  return Gui.LcButton("itemB_" .. i .. "_" .. p)({
    Style = "",
    Size = Vector2(760, 33),
    Location = Vector2(6, 44 + 34 * p),
    BackgroundColor = colw,
    Skin = SkinF.balance_018[(i + 1) % 2 + 1][1],
    Gui.Control("itemB_s_" .. i .. "_" .. p)({
      Size = Vector2(772, 32),
      Visible = false,
      ComFuc.ComLabel("rank_NO_" .. i .. "_" .. p, p, Vector2(40, 33), Vector2(0, 0), 0, 16, color_sel[i], "kAlignCenterMiddle"),
      ComFuc.ComLabel("rank_result_" .. i .. "_" .. p, nil, Vector2(50, 33), Vector2(40, 0), 0, 16, color_sel[i], "kAlignCenterMiddle"),
      ComFuc.ComControl("rank_job_" .. i .. "_" .. p, Vector2(31, 31), Vector2(99, 1), 255),
      ComFuc.ComControl("rank_rank_" .. i .. "_" .. p, Vector2(32, 32), Vector2(135, 1), 255, SkinF.rank_006[1][1]),
      ComFuc.ComLabel("rank_name_" .. i .. "_" .. p, "XXX", Vector2(150, 33), Vector2(185, 0), 0, 16, color_sel[i]),
      ComFuc.ComControl("rank_vipL_" .. i .. "_" .. p, Vector2(32, 33), Vector2(304, 0), 255, SkinF.vipPadShow_004[1]),
      ComFuc.ComLabel("rank_mode_" .. i .. "_" .. p, nil, Vector2(86, 33), Vector2(502, 0), 0, 16, color_sel[i], "kAlignCenterMiddle"),
      ComFuc.ComLabel("rank_chain_" .. i .. "_" .. p, nil, Vector2(86, 33), Vector2(600, 0), 0, 16, color_sel[i], "kAlignCenterMiddle"),
      ComFuc.ComLabel("rank_score_" .. i .. "_" .. p, nil, Vector2(86, 33), Vector2(674, 0), 0, 16, color_sel[3], "kAlignCenterMiddle")
    })
  })
end, "tip_player_item"
local Team, BiocheTeam = function(i)
  return Gui.Control("team_" .. i)({
    Size = Vector2(772, 358),
    Location = Vector2(17, -201 + 363 * i),
    BackgroundColor = colw,
    Skin = SkinF.balance_022,
    ComFuc.ComControl(nil, Vector2(762, 38), Vector2(5, 3), 255, SkinF.balance_023[i]),
    ComFuc.ComControl(nil, Vector2(760, 33), Vector2(6, 44), 255, SkinF.balance_048),
    ItemButton(i, 1),
    ItemButton(i, 2),
    ItemButton(i, 3),
    ItemButton(i, 4),
    ItemButton(i, 5),
    ItemButton(i, 6),
    ItemButton(i, 7),
    ItemButton(i, 8)
  })
end, "tip_player_avatar_other"
local BiocheTeam, BossItemButton = function(i)
  return Gui.Control("team_" .. i)({
    Size = Vector2(772, 630),
    Location = Vector2(17, 162),
    BackgroundColor = colw,
    Skin = SkinF.balance_022,
    ComFuc.ComControl(nil, Vector2(762, 38), Vector2(5, 3), 255, SkinF.balance_023[1]),
    ComFuc.ComControl(nil, Vector2(760, 33), Vector2(6, 44), 255, SkinF.balance_051),
    BioItemButton(i, 1),
    BioItemButton(i, 2),
    BioItemButton(i, 3),
    BioItemButton(i, 4),
    BioItemButton(i, 5),
    BioItemButton(i, 6),
    BioItemButton(i, 7),
    BioItemButton(i, 8),
    BioItemButton(i, 9),
    BioItemButton(i, 10),
    BioItemButton(i, 11),
    BioItemButton(i, 12),
    BioItemButton(i, 13),
    BioItemButton(i, 14),
    BioItemButton(i, 15),
    BioItemButton(i, 16)
  })
end, "tip_player_avatar_other"
local BossItemButton, BossTeam = function(i, p)
  return Gui.LcButton("itemB_" .. i .. "_" .. p)({
    Style = "",
    Size = Vector2(760, 33),
    Location = Vector2(6, 44 + 34 * p),
    BackgroundColor = colw,
    Skin = SkinF.balance_018[(i + 1) % 2 + 1][1],
    Gui.Control("itemB_s_" .. i .. "_" .. p)({
      Size = Vector2(772, 32),
      Visible = false,
      ComFuc.ComLabel("rank_NO_" .. i .. "_" .. p, p, Vector2(40, 33), Vector2(0, 0), 0, 16, color_sel[(i + 1) % 2 + 1], "kAlignCenterMiddle"),
      ComFuc.ComLabel("rank_level_" .. i .. "_" .. p, "LV1", Vector2(50, 33), Vector2(40, 0), 0, 16, color_sel[(i + 1) % 2 + 1], "kAlignCenterMiddle"),
      ComFuc.ComControl("rank_job_" .. i .. "_" .. p, Vector2(31, 31), Vector2(99, 1), 255),
      ComFuc.ComControl("rank_rank_" .. i .. "_" .. p, Vector2(32, 32), Vector2(135, 1), 255, SkinF.rank_006[1][1]),
      ComFuc.ComLabel("rank_name_" .. i .. "_" .. p, "XXX", Vector2(150, 33), Vector2(185, 0), 0, 16, color_sel[(i + 1) % 2 + 1]),
      ComFuc.ComControl("rank_vipL_" .. i .. "_" .. p, Vector2(32, 33), Vector2(304, 0), 255, SkinF.vipPadShow_004[1]),
      ComFuc.ComLabel("rank_kill_" .. i .. "_" .. p, "1/1", Vector2(86, 33), Vector2(330, 0), 0, 16, color_sel[(i + 1) % 2 + 1], "kAlignCenterMiddle", nil, false),
      ComFuc.ComLabel("rank_hart_" .. i .. "_" .. p, nil, Vector2(86, 33), Vector2(416, 0), 0, 16, color_sel[(i + 1) % 2 + 1], "kAlignCenterMiddle"),
      ComFuc.ComLabel("rank_alive_" .. i .. "_" .. p, nil, Vector2(86, 33), Vector2(502, 0), 0, 16, color_sel[(i + 1) % 2 + 1], "kAlignCenterMiddle"),
      ComFuc.ComLabel("rank_mode_" .. i .. "_" .. p, nil, Vector2(86, 33), Vector2(588, 0), 0, 16, color_sel[(i + 1) % 2 + 1], "kAlignCenterMiddle"),
      ComFuc.ComLabel("rank_chain_" .. i .. "_" .. p, nil, Vector2(86, 33), Vector2(588, 0), 0, 16, color_sel[(i + 1) % 2 + 1], "kAlignCenterMiddle", nil, false),
      ComFuc.ComLabel("rank_score_" .. i .. "_" .. p, nil, Vector2(86, 33), Vector2(674, 0), 0, 16, color_sel[3], "kAlignCenterMiddle")
    })
  })
end, ARGB(255, 254, 185, 0)
local BossTeam, BossProgress = function()
  local i = 3
  return Gui.Control("team_" .. i)({
    Size = Vector2(772, 358),
    Location = Vector2(17, 162),
    BackgroundColor = colw,
    Skin = SkinF.balance_022,
    ComFuc.ComControl(nil, Vector2(762, 38), Vector2(5, 3), 255, SkinF.balance_023[i]),
    ComFuc.ComControl(nil, Vector2(760, 33), Vector2(6, 44), 255, SkinF.balance_050),
    BossItemButton(i, 1),
    BossItemButton(i, 2),
    BossItemButton(i, 3),
    BossItemButton(i, 4),
    BossItemButton(i, 5),
    BossItemButton(i, 6),
    BossItemButton(i, 7),
    BossItemButton(i, 8)
  })
end, ARGB(255, 254, 185, 0)
local BossProgress, MvpEquip = function()
  local i = 4
  return Gui.Control("team_" .. i)({
    Size = Vector2(772, 358),
    Location = Vector2(17, 525),
    BackgroundColor = colw,
    Skin = SkinF.balance_022,
    ComFuc.ComControl(nil, Vector2(762, 38), Vector2(5, 3), 255, SkinF.balance_023[i]),
    Gui.Control({
      Size = Vector2(760, 68),
      Location = Vector2(7, 44),
      BackgroundColor = colw,
      Skin = SkinF.balance_018[2][1],
      ComFuc.ComLabel("", GetUTF8Text("UI_grade_complete_level"), Vector2(160, 18), Vector2(13, 12), 0, 16, colw, "kAlignLeftMiddle"),
      ComFuc.ComLabel("", GetUTF8Text("UI_grade_explore_strength_avg"), Vector2(160, 18), Vector2(228, 12), 0, 16, colw, "kAlignLeftMiddle"),
      ComFuc.ComLabel("", GetUTF8Text("UI_grade_pass_time"), Vector2(160, 18), Vector2(13, 40), 0, 16, colw, "kAlignLeftMiddle"),
      ComFuc.ComLabel("", GetUTF8Text("UI_grade_explore_copy_difficulty"), Vector2(160, 18), Vector2(228, 40), 0, 16, colw, "kAlignLeftMiddle"),
      ComFuc.ComLabel("finish_du", "100%", Vector2(160, 18), Vector2(13, 12), 0, 16, colw, "kAlignRightMiddle"),
      ComFuc.ComLabel("average_du", "9999", Vector2(160, 18), Vector2(228, 12), 0, 16, colw, "kAlignRightMiddle"),
      ComFuc.ComLabel("finish_time", "00:00:00", Vector2(160, 18), Vector2(13, 40), 0, 16, colw, "kAlignRightMiddle"),
      ComFuc.ComLabel("finish_hard", "9999", Vector2(160, 18), Vector2(228, 40), 0, 16, colw, "kAlignRightMiddle"),
      ComFuc.ComControl(nil, Vector2(160, 36), Vector2(448, 18), 255, SkinF.boss_balance_06),
      ComFuc.ComLabel("finish_score", "9999", Vector2(126, 36), Vector2(625, 18), 0, 18, colw, "kAlignRightMiddle")
    }),
    ComFuc.ComButton("btn_left_show", nil, Vector2(32, 60), Vector2(44, 192), 0, false, true, SkinF.boss_balance_01),
    ComFuc.ComButton("btn_right_show", nil, Vector2(32, 60), Vector2(698, 192), 0, false, true, SkinF.boss_balance_02),
    ComGoalFinish("show", 1, Vector2(87, 145)),
    ComGoalFinish("show", 2, Vector2(207, 145)),
    ComGoalFinish("show", 3, Vector2(327, 145)),
    ComGoalFinish("show", 4, Vector2(447, 145)),
    ComGoalFinish("show", 5, Vector2(567, 145))
  })
end, ARGB(255, 254, 185, 0)
local MvpEquip, TaskItem = function(i, visible)
  return Gui.Control("mvpLev_" .. i)({
    Size = Vector2(80, 80),
    Location = Vector2(100 + 84 * i, 48),
    BackgroundColor = colw,
    Visible = visible or false,
    ComFuc.ComControl("mvpEq_" .. i, Vector2(80, 80), Vector2(0, 0), 255)
  })
end, ARGB(255, 254, 185, 0)
local TaskItem, ComTurnCard = function(i)
  return Gui.Control("taskg_" .. i)({
    Size = Vector2(330, 116),
    Location = Vector2(8, -84 + 121 * i),
    BackgroundColor = colw,
    Skin = SkinF.balance_043,
    ComFuc.ComControl(nil, Vector2(76, 79), Vector2(8, 8), 255, SkinF.balance_045[i]),
    ComFuc.ComLabel(nil, string.format(GetUTF8Text("UI_inGame_inGame_string36"), i), Vector2(120, 20), Vector2(88, 12), 0, 16, coly2),
    ComFuc.ComLabel("TaskC_" .. i, GetUTF8Text("UI_mission_additional_string_152"), Vector2(240, 40), Vector2(88, 40), 0, 16, colw),
    ComFuc.ComLabel(nil, GetUTF8Text("UI_mission_additional_string_043"), Vector2(104, 20), Vector2(10, 86), 0, 16, colw),
    ComFuc.ComControl("TaskF_" .. i, Vector2(90, 55), Vector2(232, -7), 255, SkinF.balance_035[1])
  })
end, ARGB(255, 254, 185, 0)

function ComTurnCard(i)
  return Gui.Control("reward_" .. i)({
    Size = Vector2(146, 200),
    Location = ComFuc.ComputLocation(i, -138, -178, 3, 146, 200),
    BackgroundColor = colw,
    Skin = SkinF.skin_touming,
    EventMouseEnter = function(sender, e)
      sender.Skin = SkinF.balance_042
    end,
    EventMouseLeave = function(sender, e)
      sender.Skin = SkinF.skin_touming
    end,
    Gui.AnimControl("turnC_" .. i)({
      Size = Vector2(146, 200),
      BackgroundColor = col0,
      ComFuc.ComControl("jiLev_" .. i, Vector2(80, 80), Vector2(33, 86), 255, nil, false),
      ComFuc.ComControl("jiang_" .. i, Vector2(80, 80), Vector2(33, 86), 255, nil, false),
      ComFuc.ComControl("isget_" .. i, Vector2(146, 35), Vector2(0, 56), 255, SkinF.balance_039, false),
      ComFuc.ComLabel("jiNum_" .. i, nil, Vector2(60, 18), Vector2(47, 140), 0, 16, colw, "kAlignRightMiddle", nil, false, SkinF.hecheng_number_1)
    })
  })
end

local ui = Gui.Create()({
  Gui.Control("balance_root")({
    Dock = "kDockCenter",
    Size = Vector2(1200, 900),
    Gui.Control("best_control")({
      Size = Vector2(529, 133),
      Location = Vector2(260, 24),
      BackgroundColor = colw,
      Skin = SkinF.balance_040,
      ComFuc.ComControl("best_job", Vector2(31, 31), Vector2(189, 13), 255),
      ComFuc.ComControl("best_rank", Vector2(32, 32), Vector2(222, 13), 255, SkinF.rank_006[1][1]),
      ComFuc.ComLabel("best_level", nil, Vector2(47, 21), Vector2(258, 19), 0, 16, colw),
      ComFuc.ComLabel("best_role", nil, Vector2(223, 21), Vector2(359, 19), 0, 16, colw),
      ComFuc.ComHeadMessage(Vector2(49, 8), 6, Vector2(116, 116)),
      MvpEquip(1),
      MvpEquip(2),
      MvpEquip(3),
      MvpEquip(4, true)
    }),
    ComFuc.ComControl("best_jinbei", Vector2(188, 130), Vector2(62, 26), 255, SkinF.balance_041),
    Team(1),
    Team(2),
    BossTeam(),
    BossProgress(),
    BiocheTeam(5),
    Gui.CharacterAnimCard({
      ID = 2,
      Size = Vector2(388, 517),
      Location = Vector2(775, 80),
      BackgroundColor = col0
    }),
    Gui.Control("gain_point")({
      Size = Vector2(346, 96),
      Location = Vector2(795, 418),
      BackgroundColor = colw,
      Visible = false,
      Skin = SkinF.balance_049,
      ComFuc.ComLabel(nil, GetUTF8Text("UI_battlefield_get_win_score"), Vector2(200, 24), Vector2(18, 29), 0, 20, colw),
      ComFuc.ComNumFlash("gain_point_score", "jiesuan.numFlash", Vector2(204, 23))
    }),
    Gui.Control("self_artributes")({
      Size = Vector2(388, 298),
      Location = Vector2(795, 520),
      BackgroundColor = colw,
      Skin = SkinF.balance_022,
      ComFuc.ComControl("name_ditu", Vector2(373, 71), Vector2(8, 8), 255, SkinF.balance_027),
      ComFuc.ComControl(nil, Vector2(372, 2), Vector2(8, 162), 255, SkinF.balance_028),
      ComFuc.ComControl("tiao_2", Vector2(372, 2), Vector2(8, 224), 255, SkinF.balance_028),
      ComFuc.ComControl("my_gbi_i", Vector2(30, 30), Vector2(17, 250), 255, SkinF.shop_02),
      ComFuc.ComControl("my_job", Vector2(31, 31), Vector2(92, 12), 255),
      ComFuc.ComControl("my_rank", Vector2(32, 32), Vector2(123, 12), 255, SkinF.rank_006[1][1]),
      ComFuc.ComLabel("my_Level", nil, Vector2(52, 21), Vector2(158, 18), 0, 16, colw),
      ComFuc.ComLabel("my_name", nil, Vector2(216, 21), Vector2(212, 18), 0, 16, colw),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_battlefield_Total_Score"), Vector2(144, 20), Vector2(17, 131), 0, 16, colw),
      ComFuc.ComLabel("my_exp_t", GetUTF8Text("UI_inGame_EXP_Gained"), Vector2(144, 20), Vector2(17, 194), 0, 16, colw),
      ComFuc.ComLabel("my_gbi_t", GetUTF8Text("UI_store_Obtain"), Vector2(144, 20), Vector2(50, 256), 0, 16, colw),
      ComFuc.ComNumFlash("my_score", "jiesuan.numFlash", Vector2(240, 118)),
      ComFuc.ComNumFlash("my_exp", "jiesuan.numFlash", Vector2(115, 180)),
      ComFuc.ComNumFlash("my_gbi", "jiesuan.numFlash", Vector2(115, 242)),
      ComFuc.ComNumFlash("my_exp_add", "jiesuan.numFlash2", Vector2(240, 180)),
      ComFuc.ComNumFlash("my_gbi_add", "jiesuan.numFlash2", Vector2(240, 242)),
      ComFuc.ComLabel("my_exp_add_cht", "+", Vector2(25, 36), Vector2(240, 180), 0, 0, col0, nil, nil, true, SkinF.jiesuan_number_2),
      ComFuc.ComLabel("my_gbi_add_cht", "+", Vector2(25, 36), Vector2(240, 242), 0, 0, col0, nil, nil, true, SkinF.jiesuan_number_2),
      ExpBar.ComExpBar("bar_exp", Vector2(359, 24), Vector2(7, 50), 0, 1, SkinF.lobbyMain_expbar[1], SkinF.lobbyMain_expbar[2], "kAlignLeftMiddle"),
      ComFuc.ComControl("buf_1", Vector2(43, 33), Vector2(8, 83), 255, nil, false),
      ComFuc.ComControl("buf_2", Vector2(43, 33), Vector2(57, 83), 255, nil, false),
      ComFuc.ComControl("buf_3", Vector2(43, 33), Vector2(106, 83), 255, nil, false),
      ComFuc.ComControl("buf_4", Vector2(43, 33), Vector2(155, 83), 255, nil, false),
      ComFuc.ComControl("buf_5", Vector2(43, 33), Vector2(204, 83), 255, nil, false),
      ComFuc.ComControl("buf_6", Vector2(43, 33), Vector2(253, 83), 255, nil, false),
      ComFuc.ComControl("buf_7", Vector2(43, 33), Vector2(302, 83), 255, nil, false),
      ComFuc.ComControl("buf_8", Vector2(43, 33), Vector2(351, 83), 255, nil, false),
      ComFuc.ComControl("buf_9", Vector2(43, 33), Vector2(400, 83), 255, nil, false),
      ComFuc.ComControl("buf_10", Vector2(43, 33), Vector2(449, 83), 255, nil, false),
      ComFuc.ComControl("buf_11", Vector2(43, 33), Vector2(498, 83), 255, nil, false),
      ComFuc.ComControl("buf_12", Vector2(43, 33), Vector2(547, 83), 255, nil, false),
      ComFuc.ComControl("exp_max", Vector2(96, 36), Vector2(270, 180), 255, SkinF.balance_047)
    }),
    ComFuc.ComControl("slefWin", Vector2(265, 99), Vector2(830, 30), 255, SkinF.balance_025[1]),
    ComFuc.ComButton("btn_cut", GetUTF8Text("button_common_Screenshot"), Vector2(186, 60), Vector2(800, 826), 18, false, true, SkinF.select_character_029),
    ComFuc.ComButton("btn_sure", GetUTF8Text("button_common_OK"), Vector2(186, 60), Vector2(992, 826), 18, false, true, SkinF.select_character_029)
  }),
  Gui.Control("balance_award")({
    Size = Vector2(831, 708),
    BackgroundColor = colw,
    Skin = SkinF.balance_029,
    ComFuc.ComControl(nil, Vector2(152, 40), Vector2(13, 13), 255, SkinF.balance_031),
    ComFuc.ComControl("last_time_bg", Vector2(152, 40), Vector2(598, 13), 255, SkinF.balance_031),
    ComFuc.ComLabel("last_time_pre", nil, Vector2(144, 20), Vector2(18, 23), 0, 16, colw),
    ComFuc.ComLabel("last_count_pre", nil, Vector2(144, 20), Vector2(606, 23), 0, 16, colw),
    ComFuc.ComButton("btn_close", nil, Vector2(43, 43), Vector2(772, 12), 0, false, true, SkinF.battle_015),
    ComFuc.ComControl("chance_1", Vector2(41, 44), Vector2(362, 12), 255, SkinF.balance_038[1][2]),
    ComFuc.ComControl("chance_2", Vector2(41, 44), Vector2(406, 12), 255, SkinF.balance_038[2][2]),
    ComFuc.ComControl("chance_3", Vector2(41, 44), Vector2(450, 12), 255, SkinF.balance_038[3][2]),
    ComFuc.ComControl("chance_4", Vector2(41, 44), Vector2(494, 12), 255, SkinF.balance_038[4][2]),
    ComFuc.ComControl("chance_5", Vector2(41, 44), Vector2(538, 12), 255, SkinF.balance_038[5][2]),
    Gui.Control("goal_finish_1")({
      Size = Vector2(346, 400),
      Location = Vector2(13, 60),
      BackgroundColor = colw,
      Skin = SkinF.balance_030,
      ComFuc.ComLabel(nil, GetUTF8Text("UI_inGame_inGame_string26"), Vector2(295, 20), Vector2(10, 10), 0, 16, colg2),
      TaskItem(1),
      TaskItem(2),
      TaskItem(3)
    }),
    Gui.Control("goal_finish_2")({
      Size = Vector2(346, 634),
      Location = Vector2(13, 60),
      BackgroundColor = colw,
      Skin = SkinF.balance_022,
      ComFuc.ComLabel(nil, GetUTF8Text("UI_inGame_explore_progress"), Vector2(326, 20), Vector2(10, 13), 0, 16, coly),
      ComFuc.ComButton("btn_left_goal", nil, Vector2(32, 60), Vector2(12, 300), 0, false, true, SkinF.boss_balance_01),
      ComFuc.ComButton("btn_right_goal", nil, Vector2(32, 60), Vector2(301, 300), 0, false, true, SkinF.boss_balance_02),
      ComGoalFinish("card", 1, Vector2(53, 36)),
      ComGoalFinish("card", 2, Vector2(173, 36)),
      ComGoalFinish("card", 3, Vector2(53, 236)),
      ComGoalFinish("card", 4, Vector2(173, 236)),
      ComGoalFinish("card", 5, Vector2(53, 436)),
      ComGoalFinish("card", 6, Vector2(173, 436))
    }),
    Gui.Control("reward")({
      Size = Vector2(454, 634),
      Location = Vector2(363, 60),
      BackgroundColor = colh,
      Skin = SkinF.balance_030,
      ComFuc.ComLabel("prize_title", GetUTF8Text("UI_inGame_Team_Goal_Reward"), Vector2(454, 30), Vector2(0, 0), 255, 16, coly, "kAlignCenterMiddle", SkinF.balance_032),
      ComTurnCard(1),
      ComTurnCard(2),
      ComTurnCard(3),
      ComTurnCard(4),
      ComTurnCard(5),
      ComTurnCard(6),
      ComTurnCard(7),
      ComTurnCard(8),
      ComTurnCard(9)
    })
  }),
  Gui.Control("balance_levelUp")({
    Dock = "kDockCenter",
    Size = Vector2(1100, 700),
    Gui.Control({
      Size = Vector2(740, 180),
      Location = Vector2(180, 260),
      BackgroundColor = colw,
      Skin = SkinF.gainGoods_001,
      ComFuc.ComLabel(nil, GetUTF8Text("UI_common_Level_to"), Vector2(120, 25), Vector2(302, 100), 0, 22, colw),
      ComFuc.ComLabel("get_sk_pre", "获得  点技能点数", Vector2(200, 21), Vector2(299, 136), 0, 16, colw),
      ComFuc.ComLabel("to_lev", 30, Vector2(30, 25), Vector2(418, 100), 0, 22, coly2),
      ComFuc.ComLabel("get_sk", 1, Vector2(20, 21), Vector2(331, 136), 0, 16, coly2)
    }),
    ComFuc.ComControl("cht_1", Vector2(620, 610), Vector2(0, 12), 0, SkinF.balance_046[1]),
    ComFuc.ComControl("cht_2", Vector2(620, 610), Vector2(150, 12), 0, SkinF.balance_046[2]),
    ComFuc.ComControl("cht_3", Vector2(620, 610), Vector2(193, 12), 0, SkinF.balance_046[3]),
    ComFuc.ComControl("cht_4", Vector2(620, 610), Vector2(232, 12), 0, SkinF.balance_046[2]),
    ComFuc.ComControl("cht_5", Vector2(620, 610), Vector2(265, 12), 0, SkinF.balance_046[1]),
    ComFuc.ComControl("cht_6", Vector2(62, 61), Vector2(606, 350), 0, SkinF.balance_046[4]),
    ComFuc.ComControl("cht_7", Vector2(62, 61), Vector2(649, 220), 0, SkinF.balance_046[5])
  }),
  Gui.Control("balance_RankUp")({
    Dock = "kDockCenter",
    Size = Vector2(1100, 700),
    Gui.Control({
      Size = Vector2(740, 180),
      Location = Vector2(180, 260),
      BackgroundColor = colw,
      Skin = SkinF.gainGoods_001,
      Gui.Control("Rank_2")({
        Location = Vector2(312, 32),
        Size = Vector2(116, 116),
        BackgroundColor = ARGB(255, 255, 255, 255)
      }),
      Gui.Control("Rank_1")({
        Location = Vector2(312, 32),
        Size = Vector2(116, 116),
        BackgroundColor = ARGB(255, 255, 255, 255)
      }),
      ComFuc.ComControlAddPt("rank_particle", Vector2(740, 180), Vector2(0, 0), "military_upgrade"),
      ComFuc.ComControlAddPt("rank2_particle", Vector2(740, 180), Vector2(0, 0), "military_fall")
    })
  }),
  ComMenu("menu_1")
})
for i = 1, 3 do
end
ui.btn_left_show.Enable = false
ui.btn_right_show.Enable = false
ui.btn_left_goal.Enable = false
ui.btn_right_goal.Enable = false
ui.menu_1:AddItem(GetUTF8Text("button_common_Add_Friend"))
ui.menu_1:AddItem(GetUTF8Text("button_common_Info"))
ui.menu_1:AddItem(GetUTF8Text("tips_social_copy_name"))
ui["mvpEq_" .. 4].Skin = SkinF.personalInfo_095
ui.finish_score.TextureFont = SkinF.jiesuan_number_1
local ui.chance_3.Visible, SetTimeFormat = config.IsNeedVip, ui.chance_3
local SetTimeFormat, TurnCard = function(t)
  local h = math.floor(t / 3600)
  local m = math.floor((t - h * 3600) / 60)
  local s = t - h * 3600 - m * 60
  return string.format("%02d:%02d:%02d", h, m, s)
end, config.IsNeedVip
local TurnCard, ShowChanceCard = function(p)
  p:DeleteFrameList("TurnCard")
  p:AddFrame("TurnCard", Gui.Image("ui/skinF/skin_jiesuan_card1.tga", Vector4(0, 0, 0, 0)))
  p:AddFrame("TurnCard", Gui.Image("ui/skinF/skin_jiesuan_card3.tga", Vector4(0, 0, 0, 0)))
  p:StartAnimation()
  p:TurnCard()
  p.Enable = false
end, "IsNeedVip"
local ShowChanceCard, ShowTurnCard = function(i, t)
  isChance[i] = t
  if 1 <= t then
    ui["chance_" .. i].Skin = SkinF.balance_038[i][2]
  else
    ui["chance_" .. i].Skin = SkinF.balance_038[i][1]
  end
end, "jiesuan_number_1"
local ShowTurnCard, ShowGetCardParticle = function(i)
  if i <= #prizeDt then
    TurnCard(ui["turnC_" .. i])
    ui["jiLev_" .. i].Skin = SkinF.personalInfo_quality[1]
    if prizeDt[prizeCurr].unitType and prizeDt[prizeCurr].unitType == 3 and 1 < prizeDt[prizeCurr].num then
      ui["jiNum_" .. i].Text = prizeDt[prizeCurr].num
    else
      ui["jiNum_" .. i].Text = nil
    end
    if prizeDt and prizeDt[prizeCurr] and prizeDt[prizeCurr].grade and prizeDt[prizeCurr].grade > 0 then
      ui["jiLev_" .. i].Skin = SkinF.personalInfo_quality[prizeDt[prizeCurr].grade]
    end
    if tonumber(prizeDt[prizeCurr].type) == 7 and (tonumber(prizeDt[prizeCurr].id) == 1 or tonumber(prizeDt[prizeCurr].id) == 2 or tonumber(prizeDt[prizeCurr].id) == 3) then
      ui["jiNum_" .. i].Text = prizeDt[prizeCurr].num
      ui["jiang_" .. i].Skin = Gui.ControlSkin({
        BackgroundImage = Gui.Image("ui/skinF/skin_common_icon_gold01.tga", Vector4(0, 0, 0, 0))
      })
    else
      local res = prizeDt[prizeCurr].resource
      if tonumber(prizeDt[prizeCurr].type) == 2 and tonumber(prizeDt[prizeCurr].subType) == 102 then
        local a = rpc.load_result("fuck = {" .. res .. "}")
        res = a.fuck[1]
      end
      ui["jiang_" .. i].Skin = Gui.ControlSkin({
        BackgroundImage = Gui.Image("ui/skinF/lobby/" .. res .. ".tga", Vector4(0, 0, 0, 0))
      })
      if tonumber(prizeDt[prizeCurr].type) == 5 then
        if tonumber(prizeDt[prizeCurr].subType) == 1 then
          ui["jiang_" .. i].Skin = SkinF.personalInfo_095
        elseif tonumber(prizeDt[prizeCurr].subType) == 2 then
          ui["jiang_" .. i].Skin = SkinF.personalInfo_262
        end
      end
    end
    prizeCurr = prizeCurr + 1
  end
end, GetUTF8Text("tips_social_copy_name")
local ShowGetCardParticle, SetTeamColor = function(i)
  if isGet[i] then
    gui:AddParticle("ui_openCard_01", ComFuc.ComputLocation(i, 467 + ComFuc.locationChanged, 84, 3, 146, 200), Vector3(0, 1, 0))
  end
end, GetUTF8Text("tips_social_copy_name")
local SetTeamColor, SetSelfColorInBossMode = function(i, p, teamCol, Is_BioMode)
  if not Is_BioMode then
    ui["rank_level_" .. i .. "_" .. p].TextColor = teamCol
    ui["rank_kill_" .. i .. "_" .. p].TextColor = teamCol
    ui["rank_hart_" .. i .. "_" .. p].TextColor = teamCol
  else
    ui["rank_result_" .. i .. "_" .. p].TextColor = teamCol
  end
  ui["rank_NO_" .. i .. "_" .. p].TextColor = teamCol
  ui["rank_name_" .. i .. "_" .. p].TextColor = teamCol
  ui["rank_mode_" .. i .. "_" .. p].TextColor = teamCol
  ui["rank_chain_" .. i .. "_" .. p].TextColor = teamCol
end, GetUTF8Text("tips_social_copy_name")
local SetSelfColorInBossMode, SetAnim = function(i, p)
  local color = color_sel[3]
  ui["rank_NO_" .. i .. "_" .. p].TextColor = color
  ui["rank_level_" .. i .. "_" .. p].TextColor = color
  ui["rank_name_" .. i .. "_" .. p].TextColor = color
  ui["rank_hart_" .. i .. "_" .. p].TextColor = color
  ui["rank_alive_" .. i .. "_" .. p].TextColor = color
  ui["rank_mode_" .. i .. "_" .. p].TextColor = color
  ui["rank_score_" .. i .. "_" .. p].TextColor = color
end, GetUTF8Text("tips_social_copy_name")
local SetAnim, SetBioAnim = function(isWin, winS)
  local t = 1
  if isWin == "Y" then
    lg:PlayVictoryAnim()
  elseif isWin == "N" then
    t = 2
    lg:PlayLoseAnim()
  end
  if winS == 2 then
    t = 3
  end
  ui.slefWin.Skin = SkinF.balance_025[t]
end, GetUTF8Text("tips_social_copy_name")
local SetBioAnim, SetTeamShow = function(isWin)
  local t = 1
  if isWin == 1 then
    lg:PlayVictoryAnim()
  elseif isWin == 0 then
    t = 2
    lg:PlayLoseAnim()
  end
  ui.slefWin.Skin = SkinF.balance_025[t]
end, GetUTF8Text("tips_social_copy_name")
local SetTeamShow, CloseBalanceAward = function(data, i, selfId, mvpId, Is_BioMode)
  local par = 8
  if Is_BioMode then
    par = 16
  else
    par = 8
  end
  for p = 1, par do
    ui["itemB_s_" .. i .. "_" .. p].Visible = false
    ui["itemB_" .. i .. "_" .. p].Skin = SkinF.balance_018[(i + 1) % 2 + 1][1]
  end
  for p, v in ipairs(data) do
    ui["itemB_s_" .. i .. "_" .. p].Visible = true
    ui["rank_vipL_" .. i .. "_" .. p].Visible = v.vipLevel > 0 or v.vipLevel == -1
    if not Is_BioMode then
      ui["rank_level_" .. i .. "_" .. p].Text = "" .. v.level
      ui["rank_kill_" .. i .. "_" .. p].Text = v.killScore or 0
      ui["rank_hart_" .. i .. "_" .. p].Text = v.outPutScore
      ui["rank_chain_" .. i .. "_" .. p].Text = v.comboKillScore
    else
      local result
      if v.result == 0 then
        result = GetUTF8Text("UI_datalist_lose_gameend")
      elseif v.result == 1 then
        result = GetUTF8Text("UI_datalist_win_gameend")
      end
      ui["rank_result_" .. i .. "_" .. p].Text = result
      ui["rank_chain_" .. i .. "_" .. p].Text = v.comboWinScore
    end
    ui["rank_job_" .. i .. "_" .. p].Skin = SkinF.personalInfo_job[v.occupation + 1]
    ui["rank_rank_" .. i .. "_" .. p].Skin = SkinF.rank_006[math.max(1, v.rankType)][math.max(1, v.rankLevel)]
    ui["rank_name_" .. i .. "_" .. p].Text = v.name
    ui["rank_mode_" .. i .. "_" .. p].Text = v.modeScore
    ui["rank_score_" .. i .. "_" .. p].Text = v.totalScore
    if v.vipLevel > 0 then
      ui["rank_vipL_" .. i .. "_" .. p].Skin = SkinF.vipPadShow_004[v.vipLevel + 1]
    else
      ui["rank_vipL_" .. i .. "_" .. p].Skin = SkinF.vipPadShow_009
    end
    if i == 3 then
      ui["rank_alive_" .. i .. "_" .. p].Text = v.survivalScore
      ui["rank_mode_" .. i .. "_" .. p].Text = v.modeScore
    end
    if v.id == selfId then
      if Is_BioMode then
        SetTeamColor(i, p, color_sel[3], true)
      else
        SetTeamColor(i, p, color_sel[3], false)
      end
      ui["itemB_" .. i .. "_" .. p].Skin = SkinF.balance_018[(i + 1) % 2 + 1][2]
      ui.my_job.Skin = SkinF.personalInfo_job[v.occupation + 1]
      ui.my_rank.Skin = SkinF.rank_006[math.max(1, v.rankType)][math.max(1, v.rankLevel)]
      ui.my_Level.Text = "LV" .. v.level
      ui.my_name.Text = v.name
      SelfPlayResult = v.result
    end
    if v.id == mvpId then
      ui.best_rank.Skin = SkinF.rank_006[math.max(1, v.rankType)][math.max(1, v.rankLevel)]
    end
  end
end, GetUTF8Text("tips_social_copy_name")
local CloseBalanceAward, RefreshReward = function()
  ui.balance_award.Parent = nil
  ui.balance_root.Parent = gui
  ptBar:SetEnable(true)
  TimerRemove()
  timer = game.TimerMgr:AddTimer(0.041666666666666664)
  timer.EventOnTimer = TimerRefresh2
  gui:PlayAudio("scoring_treasure")
end, GetUTF8Text("tips_social_copy_name")
local RefreshReward, DealStageQuit = function()
  if ui.goal_finish_2.Visible then
    ui.balance_award.Size = Vector2(831, 708)
  else
    ui.balance_award.Size = Vector2(648, 708)
  end
  ui.reward.Location = Vector2(ui.balance_award.Size.x - ui.reward.Size.x - 14, ui.reward.Location.y)
  ui.btn_close.Location = Vector2(ui.balance_award.Size.x - ui.btn_close.Size.x - 16, ui.btn_close.Location.y)
  ui.last_time_bg.Location = Vector2(ui.balance_award.Size.x - ui.last_time_bg.Size.x - 81, ui.last_time_bg.Location.y)
  ui.last_count_pre.Location = Vector2(ui.balance_award.Size.x - ui.last_count_pre.Size.x - 81, ui.last_count_pre.Location.y)
  local max_chance = 5
  for i = max_chance, 1, -1 do
    ui["chance_" .. i].Location = Vector2(ui.balance_award.Size.x - 252 - 44 * (max_chance - i) - ui["chance_" .. i].Size.x, ui["chance_" .. i].Location.y)
  end
end, GetUTF8Text("tips_social_copy_name")
local DealStageQuit, InintTurnCard = function(data)
  local state = ptr_cast(game.CurrentState, "Client.StateBalance")
  if state then
    add_friend_temp_data = data
    game_type = data.gameType
    if data.hookNum and data.hookNum >= 1 then
      ComFuc.hookNum = data.hookNum
    end
    for i = 1, 12 do
      ui["buf_" .. i].Visible = false
    end
    if data.self.buffs then
      local t = #data.self.buffs
      if 0 < t then
        for i, v in ipairs(data.self.buffs) do
          ui["buf_" .. i].Visible = true
          ui["buf_" .. i].Hint = GetUTF8Text(v.description)
          ui["buf_" .. i].Skin = Gui.ControlSkin({
            BackgroundImage = Gui.Image("ui/skinF/" .. v.source .. ".tga", Vector4(0, 0, 0, 0))
          })
        end
      end
      if data.self.isRandomMatchGame then
        t = t + 1
        ui["buf_" .. t].Visible = true
        ui["buf_" .. t].Hint = GetUTF8Text("tips_inGame_random_mode_additional_reward")
        ui["buf_" .. t].Skin = Gui.ControlSkin({
          BackgroundImage = Gui.Image("ui/skinF/" .. "skin_common_buff_random" .. ".tga", Vector4(0, 0, 0, 0))
        })
      end
      if data.self.weakGainExp and 0 < data.self.weakGainExp then
        t = t + 1
        ui["buf_" .. t].Visible = true
        ui["buf_" .. t].Skin = Gui.ControlSkin({
          BackgroundImage = Gui.Image("ui/skinF/" .. "skin_common_buff_inspire" .. ".tga", Vector4(0, 0, 0, 0))
        })
      end
      if data.self.addStageQuitGpRate and 0 < data.self.addStageQuitGpRate then
        t = t + 1
        ui["buf_" .. t].Visible = true
        ui["buf_" .. t].Hint = string.gsub(GetUTF8Text("tips_common_bewrite_Card_01"), "%%d", data.self.addStageQuitGpRate * 100)
        ui["buf_" .. t].Skin = Gui.ControlSkin({
          BackgroundImage = Gui.Image("ui/skinF/" .. "gbvip" .. ".tga", Vector4(0, 0, 0, 0))
        })
      end
      if data.self.addStageQuitExpRate and 0 < data.self.addStageQuitExpRate then
        t = t + 1
        ui["buf_" .. t].Visible = true
        ui["buf_" .. t].Hint = string.gsub(GetUTF8Text("tips_common_bewrite_Card_02"), "%%d", data.self.addStageQuitExpRate * 100)
        ui["buf_" .. t].Skin = Gui.ControlSkin({
          BackgroundImage = Gui.Image("ui/skinF/" .. "expvip" .. ".tga", Vector4(0, 0, 0, 0))
        })
      end
    end
    if not IsBiocheMode(game_type) then
      SetAnim(data.self.isWin, data.winnerSide)
    end
    ui.my_job.Skin = SkinF.personalInfo_job[SelectCharacter.role_job_id + 1]
    ui.my_name.Text = SelectCharacter.role_text
    ui.my_Level.Text = "LV." .. data.self.oldLevel + data.self.gainLevel
    ui.my_score.NumValue = data.self.totalScore
    ComFuc.isHookOP = data.isHook
    local isBoolExp = data.self.gainExp == 0 and tonumber(data.self.oldLevel + data.self.gainLevel) >= 30
    ui.my_exp.Visible = not isBoolExp
    ui.exp_max.Visible = isBoolExp
    ui.my_exp.NumValue = math.floor(data.self.demandGainExp * data.self.longPlayModulus)
    ui.my_gbi.NumValue = math.floor(data.self.demandGainGp * data.self.longPlayModulus)
    local tep1 = data.self.randomMatchGainExp + data.self.bufferGainExp + data.self.vipGainExp
    local tep2 = data.self.randomMatchGainGp + data.self.bufferGainGp + data.self.vipGainGp
    ui.my_exp_add.NumValue = math.floor(tep1 * data.self.longPlayModulus)
    ui.my_gbi_add.NumValue = math.floor(tep2 * data.self.longPlayModulus)
    ui.my_exp_add.Visible = tep1 ~= 0 and not isBoolExp
    ui.my_exp_add_cht.Visible = tep1 ~= 0 and not isBoolExp
    ui.my_gbi_add.Visible = tep2 ~= 0
    ui.my_gbi_add_cht.Visible = tep2 ~= 0
    ui.my_exp.Location = tep1 == 0 and Vector2(240, 180) or Vector2(115, 180)
    ui.my_gbi.Location = tep2 == 0 and Vector2(240, 242) or Vector2(115, 242)
    ui.to_lev.Text = data.self.oldLevel + data.self.gainLevel
    ui.get_sk_pre.Text = string.format(GetUTF8Text("UI_inGame_additional_string_125"), data.self.gainSkillPoint)
    ComFuc.globalGainSkillP = data.self.gainSkillPoint
    ui.get_sk.Text = ""
    ExpBar.SetExpBar(ui.bar_exp, ui.bar_exp_c, ui.bar_exp_l, data.self.oldExpCurrentLevelOffset, data.self.oldExpNextLevelOffset)
    expDt = {
      data.self.oldLevel,
      data.self.gainLevel,
      data.self.oldExpCurrentLevelOffset,
      data.self.oldExpNextLevelOffset,
      data.self.newExpCurrentLevelOffset,
      data.self.newExpNextLevelOffset
    }
    RankDt = {
      data.self.oldRankLevel,
      data.self.oldRankType,
      data.self.currentRankLevel,
      data.self.currentRankType
    }
    ui.best_control.Visible = data.mvp
    ui.best_jinbei.Visible = data.mvp
    if data.mvp then
      ui.best_role.Text = data.mvp.name
      ui.best_level.Text = "LV" .. data.mvp.level
      ui.best_job.Skin = SkinF.personalInfo_job[data.mvp.occupation + 1]
      if data.mvp.avatar.equip then
        ComFuc.SetHeadPhotoCardData(data.mvp.avatar.equip, 6)
      end
      ui["mvpLev_" .. 4].Skin = SkinF.personalInfo_quality[data.mvp.avatar.grade] or SkinF.personalInfo_quality[1]
      if data.mvp.subType == 1 then
        ui["mvpEq_" .. 4].Skin = SkinF.personalInfo_095
      elseif data.mvp.subType == 2 then
        ui["mvpEq_" .. 4].Skin = SkinF.personalInfo_262
      end
      local tk = 0
      for i, v in ipairs(data.mvp.weapon) do
        ui["mvpLev_" .. i].Visible = true
        ui["mvpLev_" .. i].Skin = SkinF.personalInfo_quality[v.grade]
        ui["mvpEq_" .. i].Skin = Gui.ControlSkin({
          BackgroundImage = Gui.Image("ui/skinF/lobby/" .. v.resource .. ".tga", Vector4(0, 0, 0, 0))
        })
        ui["mvpEq_" .. i].EventMouseEnter = function(sender, e)
          Tip.SetRpc(tip_player_interface[v.type], {
            t = v.type,
            pid = v.itemid
          })
          Tip.SetUseDescription(false)
          Tip.SetOwner(sender)
        end
        tk = tk + 1
      end
      for i = tk + 1, 3 do
        ui["mvpLev_" .. i].Visible = false
        ui["mvpEq_" .. i].EventMouseEnter = nil
      end
      ui["mvpEq_" .. 4].EventMouseEnter = function(sender, e)
        Tip.SetRpc(tip_player_interface[5], {
          t = 5,
          pid = data.mvp.id,
          aid = data.mvp.avatar.avatarId
        })
        Tip.SetUseDescription(false)
        Tip.SetOwner(sender)
      end
    else
      gui:RemoveParticle(ptBar)
    end
    local redData = data.t1
    local blueData = data.t2
    if tonumber(data.winnerSide) == 1 then
      redData = data.t2
      blueData = data.t1
    end
    local mvpid = -99999
    if data.mvp then
      mvpid = data.mvp.id
    end
    if IsBiocheMode(game_type) then
      SetTeamShow(redData, 5, data.self.playerId, mvpid, true)
      for p = 1, 16 do
        SetTeamColor(5, p, color_sel[1], true)
      end
    else
      SetTeamShow(redData, 1, data.self.playerId, mvpid, false)
      SetTeamShow(blueData, 2, data.self.playerId, mvpid, false)
      SetTeamShow(redData, 3, data.self.playerId, mvpid, false)
      for i = 1, 2 do
        for p = 1, 8 do
          SetTeamColor(i, p, color_sel[(i + 1) % 2 + 1], false)
        end
      end
      for p, v in pairs(redData) do
        if v.id == data.self.playerId then
          SetSelfColorInBossMode(3, p)
          break
        end
      end
    end
    add_friend_temp_data.t1 = redData
    add_friend_temp_data.t2 = blueData
    if data.self.lastBattlePoint and 0 < data.self.lastBattlePoint then
      ui.gain_point.Visible = true
      ui.gain_point_score.NumValue = data.self.lastBattlePoint
    else
      ui.gain_point.Visible = false
    end
    if IsBiocheMode(game_type) then
      SetBioAnim(SelfPlayResult)
    end
    local balance_type = 1
    if data.averageVenture and data.averageVenture ~= 0 then
      if data.cardprize then
        balance_type = 3
      else
        balance_type = 4
      end
    elseif data.cardprize then
      balance_type = 2
    else
      balance_type = 1
    end
    ui.goal_finish_1.Visible = false
    ui.goal_finish_2.Visible = balance_type == 3
    RefreshReward()
    ui.team_1.Visible = balance_type <= 2 and not IsBiocheMode(game_type)
    ui.team_2.Visible = balance_type <= 2 and not IsBiocheMode(game_type)
    ui.team_3.Visible = 3 <= balance_type and not IsBiocheMode(game_type)
    ui.team_4.Visible = 3 <= balance_type and not IsBiocheMode(game_type)
    ui.team_5.Visible = IsBiocheMode(game_type)
    ui.my_exp_t.Parent = 1 < balance_type and ui.self_artributes
    ui.my_gbi_t.Parent = 1 < balance_type and ui.self_artributes
    ui.my_gbi_i.Parent = 1 < balance_type and ui.self_artributes
    ui.my_exp.Parent = 1 < balance_type and ui.self_artributes
    ui.my_gbi.Parent = 1 < balance_type and ui.self_artributes
    ui.my_exp_add.Parent = 1 < balance_type and ui.self_artributes
    ui.my_gbi_add.Parent = 1 < balance_type and ui.self_artributes
    ui.my_exp_add_cht.Parent = 1 < balance_type and ui.self_artributes
    ui.my_gbi_add_cht.Parent = 1 < balance_type and ui.self_artributes
    ui.bar_exp.Parent = 1 < balance_type and ui.self_artributes
    ui.tiao_2.Parent = 1 < balance_type and ui.self_artributes
    for i = 1, 12 do
      ui["buf_" .. i].Parent = ui.self_artributes and 1 < balance_type
    end
    if data.cardprize then
      for i, v in ipairs(data.cardprize.levelQuest) do
        local tt = GetUTF8Text(v.trace)
        for k, v in pairs(v.map) do
          tt, n = string.gsub(tostring(tt), "{{" .. tostring(k) .. "}}", v)
        end
        if v.result == 2 then
          prizeLev = math.max(prizeLev, v.level)
        end
      end
      ShowChanceCard(1, data.cardprize.isCommon)
      ShowChanceCard(2, data.cardprize.isMVP)
      ShowChanceCard(3, data.cardprize.isVIP)
      ShowChanceCard(4, data.cardprize.isCard)
      ShowChanceCard(5, data.cardprize.isActivity)
      hasCount = isChance[1] + isChance[2] + isChance[3] + isChance[4] + isChance[5]
      ui.last_count_pre.Text = string.format(GetUTF8Text("UI_inGame_Remaining_No_num"), hasCount)
      prizeDt = data.cardprize.prize
      timer = game.TimerMgr:AddTimer(1)
      timer.EventOnTimer = TimerRefresh1
    end
    if balance_type == 1 or balance_type == 4 then
      ui.balance_award.Parent = nil
      ui.balance_root.Parent = gui
    else
      ui.balance_award.Parent = gui
      ui.balance_root.Parent = nil
    end
    if balance_type == 2 then
      ui.prize_title.Text = GetUTF8Text("UI_inGame_Team_Goal_Reward")
    elseif balance_type == 3 then
      ui.prize_title.Text = GetUTF8Text("UI_grade_pass_reward")
    end
    if 3 <= balance_type then
      local totalTime = 0
      local stageT = {}
      local stageS = {}
      for i = 1, 3 do
        ui["show_time_" .. i].Text = SetTimeFormat(0)
        ui["card_time_" .. i].Text = SetTimeFormat(0)
      end
      for i = 1, data.totalStageNum do
        local t = data.timeMap[i]
        for _, v in ipairs(data.timeMap) do
          if i == tonumber(v.stage) then
            t = v
            break
          end
        end
        local s = data.resourceMap[i]
        if t then
          stageT[t.stage] = t.times
          totalTime = totalTime + t.times
          ui["show_time_" .. t.stage].Text = SetTimeFormat(t.times)
          ui["card_time_" .. t.stage].Text = SetTimeFormat(t.times)
        end
        if s then
          stageS[s.stage] = s.resource
        end
      end
      for i = 1, data.totalStageNum do
        if tonumber(data.resourceMap[i].stage) <= TotalBossStage then
          local t = tostring(data.resourceMap[i].stage)
          local s = data.resourceMap[i].resource
          local skinT = Gui.ControlSkin({
            BackgroundImage = Gui.Image("ui/skinF/skin_jiesuan_" .. s .. ".tga", Vector4(0, 0, 0, 0))
          })
          ui["card_content_" .. t].Skin = skinT
          ui["show_content_" .. t].Skin = skinT
        end
      end
      for i = data.totalStageNum + 1, 5 do
        ui["card_content_" .. i].Skin = SkinF.boss_balance_03
        ui["show_content_" .. i].Skin = SkinF.boss_balance_03
      end
      for i = 1, 5 do
        ui["show_pass_" .. i].Visible = i < #data.timeMap
      end
      for i = 1, 6 do
        ui["card_pass_" .. i].Visible = i < #data.timeMap
      end
      ui.finish_du.Text = string.format("%d", data.stageNum * 100 / data.totalStageNum) .. "%"
      ui.average_du.Text = data.averageVenture
      ui.finish_time.Text = SetTimeFormat(totalTime)
      ui.finish_hard.Text = data.difficulty
      ui.finish_score.Text = data.passScore
    end
  else
    return
  end
  AlignUI()
end, GetUTF8Text("tips_social_copy_name")
local InintTurnCard, ClearTurnCard = function()
  for i = 1, 9 do
    ui["turnC_" .. i]:AddAnim("TurnCard", 0, 5)
    ui["turnC_" .. i]:AddFrame("TurnCard", Gui.Image("ui/skinF/skin_jiesuan_card1.tga", Vector4(0, 0, 0, 0)))
    ui["turnC_" .. i]:AddFrame("TurnCard", Gui.Image("", nil))
    ui["turnC_" .. i]:StartAnimation()
  end
end, GetUTF8Text("tips_social_copy_name")
local ClearTurnCard, ClearLevUp = function()
  isGet = {
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false
  }
  isChance = {
    0,
    0,
    0,
    0,
    0
  }
  hasCount = 0
  prizeCurr = 1
  for i = 1, 9 do
    ui["turnC_" .. i]:ClearAll()
    ui["turnC_" .. i]:ReStart()
    ui["turnC_" .. i].Enable = true
    ui["jiang_" .. i].Visible = false
    ui["jiLev_" .. i].Visible = false
    ui["jiNum_" .. i].Visible = false
    ui["isget_" .. i].Visible = false
    hasCount = 0
  end
end, GetUTF8Text("tips_social_copy_name")
local ClearLevUp, ClearRankUp = function()
  ui.balance_levelUp.Parent = nil
  for i = 1, 7 do
    ui["cht_" .. i].BackgroundColor = col0
  end
end, GetUTF8Text("tips_social_copy_name")
local ClearRankUp, SetLevUpCht = function()
  ui.balance_RankUp.Parent = nil
  TimerRemove()
end, GetUTF8Text("tips_social_copy_name")

function SetLevUpCht(i, p, q, s, lc1, lc2)
  if p <= totalTime and q >= totalTime then
    local k = (totalTime - p) / (q - p)
    local sz = s == 0 and Vector2(62, 61) or Vector2(620 - 558 * k, 610 - 549 * k)
    ui["cht_" .. i].Size = sz
    ui["cht_" .. i].Location = lc1 + (lc2 - lc1) * Vector2(1 - k, 1 - k)
    ui["cht_" .. i].BackgroundColor = ARGB(255 * k, 255, 255, 255)
  end
end

function TimerRefresh1()
  ui.btn_close.Enable = true
  totalTime = totalTime + 1
  if totalTime <= showCardT then
    ui.last_time_pre.Text = string.format(GetUTF8Text("UI_inGame_Remaining_Time_nums"), showCardT - totalTime)
    ui.btn_close.Enable = hasCount == 0
    if hasCount == 0 then
      if isCanOpen == 1 then
        if not isPlayOd then
          isPlayOd = true
          gui:PlayAudio("card_up_all")
        end
        for i = 1, 9 do
          if ui["turnC_" .. i].Enable then
            ShowTurnCard(i)
          end
        end
      end
      if isCanOpen == 0 then
        isCanOpen = 1
      end
    end
  elseif totalTime == showCardT + 1 then
    if not isPlayOd then
      isPlayOd = true
      gui:PlayAudio("card_up_all")
    end
    for i = 1, 9 do
      if ui["turnC_" .. i].Enable then
        ShowTurnCard(i)
        if 1 <= hasCount then
          hasCount = hasCount - 1
          isGet[i] = true
          for k = 1, 5 do
            if 1 <= isChance[k] then
              isChance[k] = isChance[k] - 1
              ShowChanceCard(k, isChance[k])
              break
            end
          end
        end
      end
    end
    ui.last_count_pre.Text = string.format(GetUTF8Text("UI_inGame_Remaining_No_num"), hasCount)
  elseif totalTime == missCardT then
    CloseBalanceAward()
  end
end

function RankLevelChange()
  if RankDt[4] == RankDt[2] and RankDt[1] < RankDt[3] then
    return 2
  elseif RankDt[4] == RankDt[2] and RankDt[1] > RankDt[3] then
    return 1
  elseif RankDt[4] < RankDt[2] then
    return 1
  elseif RankDt[4] > RankDt[2] then
    return 2
  elseif RankDt[4] == RankDt[2] and RankDt[1] == RankDt[3] then
    return false
  end
end

function TimerRefresh2()
  totalTime = totalTime + 1
  if expDt[2] == 0 then
    if game_type ~= 9 and RankLevelChange() and 25 <= totalTime then
      print("old Rank level", RankDt[1], "old Rank Type", RankDt[2], "new Rank lev", RankDt[3], "new Rank type", RankDt[4])
      ui.Rank_1.Skin = SkinF.GetBigRankIcon(RankDt[2], RankDt[1])
      ui.Rank_2.Skin = SkinF.GetBigRankIcon(RankDt[4], RankDt[3])
      ui.balance_RankUp.Parent = gui
      if 61 <= totalTime and totalTime <= 85 then
        gradualTime = gradualTime + 1
        if totalTime == 61 then
          if RankLevelChange() == 2 then
            ui.rank_particle.Particle:Reset()
            ui.rank2_particle.Visible = false
            ui.rank_particle.Visible = true
            gui:PlayAudio("rank_up")
          else
            ui.rank2_particle.Particle:Reset()
            ui.rank_particle.Visible = false
            ui.rank2_particle.Visible = true
            gui:PlayAudio("rank_down")
          end
        end
        ui.Rank_1.BackgroundColor = ARGB(255 - gradualTime * 10, 255, 255, 255)
      end
    end
    if ui.balance_RankUp.Parent and 121 <= totalTime then
      ClearRankUp()
    end
    if expDt[5] > expDt[3] and totalTime <= 48 then
      local k = totalTime / 48
      if totalTime == 1 then
        gui:PlayAudio("experience_up")
      end
      ExpBar.SetExpBar(ui.bar_exp, ui.bar_exp_c, ui.bar_exp_l, math.floor(expDt[3] + (expDt[5] - expDt[3]) * k), expDt[4])
    end
  else
    if totalTime == 1 then
      gui:PlayAudio("experience_up")
    end
    if totalTime <= 24 then
      local k = totalTime / 24
      ExpBar.SetExpBar(ui.bar_exp, ui.bar_exp_c, ui.bar_exp_l, math.floor(expDt[3] + (expDt[4] - expDt[3]) * k), expDt[4])
    elseif totalTime <= 48 then
      local k = (totalTime - 24) / 24
      ExpBar.SetExpBar(ui.bar_exp, ui.bar_exp_c, ui.bar_exp_l, math.floor(expDt[5] * k), expDt[6])
    end
    if 96 <= totalTime and game_type ~= 9 then
      if RankLevelChange() then
        ClearLevUp()
      else
        ClearLevUp()
        TimerRemove()
      end
    end
    if totalTime <= 49 then
      if totalTime == 25 then
        ui.balance_levelUp.Parent = gui
        gui:PlayAudio("level_up")
      end
      if totalTime == 40 then
        gui:AddParticle("ui_upglow", Vector2(712 + ComFuc.locationChanged, 417), Vector3(0, 1, 0))
      end
      if totalTime == 47 then
        gui:AddParticle("ui_upglow2", Vector2(590 + ComFuc.locationChanged, 440), Vector3(0, 1, 0))
      end
      SetLevUpCht(1, 27, 34, nil, Vector2(390, 286), Vector2(11, 12))
      SetLevUpCht(2, 28, 35, nil, Vector2(429, 286), Vector2(150, 12))
      SetLevUpCht(3, 29, 36, nil, Vector2(472, 286), Vector2(193, 12))
      SetLevUpCht(4, 30, 37, nil, Vector2(511, 286), Vector2(232, 12))
      SetLevUpCht(5, 31, 38, nil, Vector2(544, 286), Vector2(265, 12))
      SetLevUpCht(6, 40, 45, 0, Vector2(606, 286), Vector2(606, 350))
      SetLevUpCht(7, 40, 45, 0, Vector2(649, 286), Vector2(649, 220))
    end
    if ui.balance_RankUp.Parent and 194 <= totalTime then
      ClearRankUp()
    end
    if game_type ~= 9 and RankLevelChange() and 98 <= totalTime then
      print("old Rank level", RankDt[1], "old Rank Type", RankDt[2], "new Rank lev", RankDt[3], "new Rank type", RankDt[4])
      ui.Rank_1.Skin = SkinF.GetBigRankIcon(RankDt[2], RankDt[1])
      ui.Rank_2.Skin = SkinF.GetBigRankIcon(RankDt[4], RankDt[3])
      ui.balance_RankUp.Parent = gui
      if 134 <= totalTime and totalTime <= 158 then
        gradualTime = gradualTime + 1
        if totalTime == 134 then
          if RankLevelChange() == 2 then
            ui.rank_particle.Particle:Reset()
            ui.rank2_particle.Visible = false
            ui.rank_particle.Visible = true
            gui:PlayAudio("rank_up")
          else
            ui.rank2_particle.Particle:Reset()
            ui.rank_particle.Visible = false
            ui.rank2_particle.Visible = true
            gui:PlayAudio("rank_down")
          end
        end
        ui.Rank_1.BackgroundColor = ARGB(255 - gradualTime * 10, 255, 255, 255)
      end
    end
  end
end

function TimerRemove()
  game.TimerMgr:RemoveTimer(timer)
  totalTime = 0
  gradualTime = 0
  isCanOpen = 0
  timer = nil
  ui.Rank_1.BackgroundColor = ARGB(255 - gradualTime * 10, 255, 255, 255)
end

function ShowMenu(side, index, lc)
  if side == 1 then
    if index > #add_friend_temp_data.t1 then
      ui.menu_1:Close()
    elseif add_friend_temp_data.t1[index].id == add_friend_temp_data.self.playerId then
      ui.menu_1.Location = lc + Vector2(ComFuc.locationChanged, 0)
      ui.menu_1:Open()
      ui.menu_1:SetEnable(0, false)
      ui.menu_1:SetEnable(1, false)
      ui.menu_1:SetEnable(2, false)
    else
      ui.menu_1.Location = lc + Vector2(ComFuc.locationChanged, 0)
      ui.menu_1:Open()
      ui.menu_1:SetEnable(0, true)
      ui.menu_1:SetEnable(1, true)
      ui.menu_1:SetEnable(2, true)
      temp_add_id = add_friend_temp_data.t1[index].id
      temp_add_name = add_friend_temp_data.t1[index].name
    end
  elseif side == 2 then
    if index > #add_friend_temp_data.t2 then
      ui.menu_1:Close()
    elseif add_friend_temp_data.t2[index].id == add_friend_temp_data.self.playerId then
      ui.menu_1.Location = lc + Vector2(ComFuc.locationChanged, 0)
      ui.menu_1:Open()
      ui.menu_1:SetEnable(0, false)
      ui.menu_1:SetEnable(1, false)
      ui.menu_1:SetEnable(2, false)
    else
      ui.menu_1.Location = lc + Vector2(ComFuc.locationChanged, 0)
      ui.menu_1:Open()
      ui.menu_1:SetEnable(0, true)
      ui.menu_1:SetEnable(1, true)
      ui.menu_1:SetEnable(2, true)
      temp_add_id = add_friend_temp_data.t2[index].id
      temp_add_name = add_friend_temp_data.t2[index].name
    end
  end
end

for i = 1, 9 do
  ui["turnC_" .. i].EventClick = function(sender, e)
    if 1 <= hasCount then
      gui:PlayAudio("card_up")
      hasCount = hasCount - 1
      isGet[i] = true
      ShowTurnCard(i)
      for k = 1, 5 do
        if 1 <= isChance[k] then
          isChance[k] = isChance[k] - 1
          ShowChanceCard(k, isChance[k])
          break
        end
      end
    end
  end
  ui["turnC_" .. i].EventFinish = function(sender, e)
    ui["jiLev_" .. i].Visible = true
    ui["jiNum_" .. i].Visible = true
    ui["jiang_" .. i].Visible = true
    ui["isget_" .. i].Visible = isGet[i]
    ShowGetCardParticle(i)
    ui.last_count_pre.Text = string.format(GetUTF8Text("UI_inGame_Remaining_No_num"), hasCount)
  end
end
for i = 1, 3 do
  for j = 1, 8 do
    ui["itemB_" .. i .. "_" .. j].EventRightClick = function(sender, e)
      ShowMenu(i, j, sender.CurrentCursorPosition)
    end
  end
end

function ui.btn_cut.EventClick(sender, e)
  local state = ptr_cast(game.CurrentState, "Client.StateBalance")
  local str = string.format(GetUTF8Text("UI_inGame_additional_string_126"), state:CutAndSaveUIPicture())
  MessageBox.ShowError(str)
end

function ui.btn_sure.EventClick(sender, e)
  lg:PlayAnim("idlea", true)
  local state = ptr_cast(game.CurrentState, "Client.StateBalance")
  ComFuc.SetOneLeadFinish(512)
  if state then
    state:Quit()
  end
end

function ui.btn_close.EventClick(sender, e)
  ComFuc.SetOneLeadFinish(512)
  CloseBalanceAward()
end

function ui.menu_1.EventClick(sender, e)
  local t = sender.SelectedIndex
  if t == 0 then
    Sociality.AddFriend(temp_add_id)
  elseif t == 1 then
    LookInfo.Show(temp_add_id)
  elseif t == 2 then
    Sociality.CopyName(temp_add_name)
  end
end

function AlignUI()
  Gui.Align(ui.balance_root, 0.5, 0.5)
  Gui.Align(ui.balance_award, 0.5, 0.5)
end

function Show()
  AlignUI()
  isPlayOd = false
  local state = ptr_cast(game.CurrentState, "Client.StateBalance")
  if not state then
    return
  end
  rpc.clear()
  lg:SetBG("/ui/skinF/" .. SelectCharacter.bgRes[SelectCharacter.role_job_id + 1] .. ".dds")
  prizeLev = 0
  InintTurnCard()
  lg:SetREId(2)
  lg:UpdateVanByInfoString()
  for i = 1, 2 do
    for p = 1, 8 do
      ui["itemB_" .. i .. "_" .. p].Skin = SkinF.balance_018[i][1]
      ui["itemB_s_" .. i .. "_" .. p].Visible = false
    end
  end
  rpc.safecall("stage_quit", {
    serverId = 0,
    channelId = 0,
    roomId = state:GetSelfRoomInfo().RoomUid
  }, DealStageQuit)
  ui.last_count_pre.Text = string.format(GetUTF8Text("UI_inGame_Remaining_No_num"), hasCount)
  ptBar = gui:AddParticle("ui_trophy_star", Vector2(156 + ComFuc.locationChanged, 90), Vector3(0, 0, -1))
  ptBar:SetEnable(false)
  if ComFuc.isFromNew == 1 then
    lg:PlayAnim("idlea", true)
    local state = ptr_cast(game.CurrentState, "Client.StateBalance")
    if state then
      state:Quit()
    end
  end
end

function Hide()
  ui.balance_root.Parent = nil
  gui:RemoveParticle(ptBar)
  ClearTurnCard()
  TimerRemove()
end
