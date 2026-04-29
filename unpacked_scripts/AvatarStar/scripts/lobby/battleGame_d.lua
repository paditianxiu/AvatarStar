module("LobbyBattleGame", package.seeall)
require("battleGameTeamWait.lua")
require("ideaGarden.lua")
local col0 = ComFuc.col0
local colw = ComFuc.colw
local coly = ComFuc.coly
local teamInviteType = 0
matchType = 1
themeType = 0
gameType = 1
local typeMap = {
  0,
  4,
  1,
  2,
  3,
  11,
  8
}
local typeMap2 = {
  0,
  10,
  12,
  13
}

function GetMaxModeCount()
  return math.max(#typeMap, #typeMap2)
end

local gameIndex = {}
for i = 1, GetMaxModeCount() do
  gameIndex[i] = i
end
local isFirst = true
local timer
local ids = {
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0
}
local bitValue = {
  1,
  2,
  4,
  8,
  16
}
local memDt = {}
local isInGame = false
local isHostMan = false
local matching_game_can_begin = false
local ready_num = 0
local teamMatchNeed = 0
local teamCurrCount = 0
local peopleCount = 0
local needPeople = 16
local totalSize = Vector2(236, 55)
local TextSize = Vector2(198, 35)
local maxLineNum = 2
local Is_QuickJoin = false
local timer2, ptBar
local QUICK_JOIN_FLASH = {
  x = 0,
  y = 0,
  frame_cnt = 20,
  frame_flx1 = 25,
  frame_finish = 30,
  frame_step = 14,
  frame_flx1_step = -8,
  frame_flx2_step = 8,
  alpha_scale = 1,
  timer = 0.025
}
local modeTarget = {
  {
    {
      "",
      "",
      ""
    },
    {
      "",
      "",
      ""
    }
  },
  {
    {
      GetUTF8Text("UI_mission_additional_string_030"),
      GetUTF8Text("UI_mission_additional_string_032"),
      GetUTF8Text("UI_common_Min_Casualties")
    },
    {
      GetUTF8Text("UI_mission_Quest_Desc_3000"),
      GetUTF8Text("UI_mission_Quest_Desc_3001"),
      GetUTF8Text("UI_mission_Quest_Desc_3002")
    }
  },
  {
    {
      GetUTF8Text("UI_mission_additional_string_039"),
      GetUTF8Text("UI_common_Offenser_and_Defender"),
      GetUTF8Text("UI_mission_additional_string_041")
    },
    {
      GetUTF8Text("UI_mission_Quest_Desc_3003"),
      GetUTF8Text("UI_mission_Quest_Desc_3004"),
      GetUTF8Text("UI_mission_Quest_Desc_3005")
    }
  },
  {
    {
      GetUTF8Text("UI_mission_additional_string_026"),
      GetUTF8Text("UI_common_Never_Give_Up"),
      GetUTF8Text("UI_mission_additional_string_029")
    },
    {
      GetUTF8Text("UI_mission_Quest_Desc_3006"),
      GetUTF8Text("UI_mission_Quest_Desc_3007"),
      GetUTF8Text("UI_mission_Quest_Desc_3008")
    }
  },
  {
    {
      GetUTF8Text("UI_mission_additional_string_035"),
      GetUTF8Text("UI_common_The_Treasure_Guard"),
      GetUTF8Text("UI_common_The_Treasure_Expert")
    },
    {
      GetUTF8Text("UI_mission_Quest_Desc_3009"),
      GetUTF8Text("UI_mission_Quest_Desc_3010"),
      GetUTF8Text("UI_mission_Quest_Desc_3011")
    }
  }
}
local modeDes = {
  "",
  GetUTF8Text("UI_mission_additional_string_048"),
  GetUTF8Text("UI_inGame_inGame_string22"),
  GetUTF8Text("UI_inGame_inGame_string23"),
  GetUTF8Text("UI_inGame_inGame_string24"),
  GetUTF8Text("UI_inGame_killallmode_tips_win")
}
local btnText = {
  GetUTF8Text("button_battlefield_additional_string_047"),
  GetUTF8Text("button_battlefield_additional_string_047"),
  GetUTF8Text("UI_lobby_consortia_interface_14")
}
local titleText = {
  GetUTF8Text("UI_datalist_Avatar_fortress_home"),
  GetUTF8Text("button_common_Arena"),
  GetUTF8Text("UI_datalist_consortia_troop_28")
}
local teamTileText = {
  GetUTF8Text("UI_common_Team_List"),
  GetUTF8Text("UI_common_Team_List"),
  GetUTF8Text("UI_datalist_consortia_troop_29")
}
local titleSkin = {
  LobbyStartGame.btn_1_Skin,
  LobbyStartGame.btn_1_Skin,
  LobbyStartGame.btn_3_Skin
}
local itemSkin = {
  SkinF.battle_020[6],
  SkinF.battle_020[6],
  SkinF.battle_020[7]
}
local ModeTipText, BattleTarget = {
  GetUTF8Text("UI_battlefield_Instruction_Freestyle_Combat"),
  GetUTF8Text("UI_mission_additional_string_045"),
  GetUTF8Text("UI_mission_AvatarParadi_string_tips"),
  GetUTF8Text("UI_lobby_explore_introduction")
}, GetUTF8Text("UI_battlefield_Instruction_Freestyle_Combat")

function BattleTarget(i)
  return Gui.Control("target_item_" .. i)({
    Location = Vector2(-209 + 222 * i, 111),
    Size = Vector2(215, 283),
    BackgroundColor = colw,
    Skin = SkinF.battle_020[1],
    ComFuc.ComControl(nil, Vector2(76, 79), Vector2(69, 47), 255, SkinF.balance_045[i]),
    ComFuc.ComLabel(nil, GetUTF8Text("UI_battlefield_Lv" .. i .. "_Team_Goal"), Vector2(198, 20), Vector2(10, 12), 0, 16, coly, "kAlignCenterMiddle"),
    ComFuc.ComLabel("target_title_" .. i, "", Vector2(198, 36), Vector2(10, 120), 0, 14, colw, "kAlignCenterMiddle"),
    ComFuc.ComLabel("target_detail_" .. i, "", Vector2(188, 128), Vector2(14, 156), 0, 14, colw, "kAlignLeftTop"),
    ComFuc.ComLabel(nil, GetUTF8Text("UI_mission_additional_string_043"), Vector2(196, 20), Vector2(10, 254), 0, 16, colw, "kAlignLeftTop")
  })
end

ui = Gui.Create()({
  ComFuc.ComControl("coverControl2", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(100, 0, 0, 0)),
  Gui.Control("main")({
    Size = Vector2(1128, 645),
    BackgroundColor = colw,
    Skin = SkinF.game_background,
    Gui.Control("plane_1")({
      Dock = "kDockFill",
      ComFuc.ComControlAddPt("main1_particle", Vector2(1128, 460), Vector2(0, 0), "scene_clouds"),
      ComFuc.ComButton("theme_5", "", Vector2(410, 484), Vector2(313, 0), 16, false, false, SkinF.themeMode_btn[5]),
      ComFuc.ComButton("theme_1", "", Vector2(280, 229), Vector2(73, 292), 16, false, false, SkinF.themeMode_btn[1]),
      ComFuc.ComButton("theme_2", "", Vector2(381, 372), Vector2(471, 262), 16, false, false, SkinF.themeMode_btn[2]),
      ComFuc.ComButton("theme_3", "", Vector2(282, 317), Vector2(780, 165), 16, false, false, SkinF.themeMode_btn[3]),
      ComFuc.ComButton("theme_4", "", Vector2(293, 248), Vector2(720, 0), 16, false, false, SkinF.themeMode_btn[4]),
      ComFuc.ComControlAddPt("theme1_particle", Vector2(350, 350), Vector2(73, 175), "scene_practice"),
      ComFuc.ComControlAddPt("theme2_particle", Vector2(381, 372), Vector2(473, 166), "scene_battlefield"),
      ComFuc.ComControlAddPt("theme3_particle", Vector2(282, 317), Vector2(780, 165), "scene_group"),
      ComFuc.ComControlAddPt("theme4_particle", Vector2(293, 248), Vector2(697, -23), "scene_adventure"),
      ComFuc.ComControlAddPt("theme5_particle", Vector2(381, 372), Vector2(300, 0), "scene_adventure"),
      ComFuc.ComControlAddPt("main2_particle", Vector2(1128, 185), Vector2(0, 460), "scene_clouds_2"),
      Gui.Control("theme_tip")({
        Location = Vector2(500, 150),
        Size = totalSize,
        BackgroundColor = colw,
        Skin = SkinF.lookInfo_004,
        Visible = false,
        Gui.Label("theme_text")({
          Location = Vector2(0, 0),
          Size = TextSize,
          TextAlign = "kAlignLeftTop",
          AutoWrap = true,
          FontSize = 15,
          TextColor = ARGB(255, 255, 255, 255),
          Text = GetUTF8Text("UI_battlefield_Instruction_Freestyle_Combat")
        })
      }),
      ComFuc.ComControl(nil, Vector2(220, 50), Vector2(19, 492), 255, SkinF.battle_026[1], true, false),
      ComFuc.ComControl(nil, Vector2(220, 50), Vector2(646, 561), 255, SkinF.battle_026[2], true, false),
      ComFuc.ComControl(nil, Vector2(220, 50), Vector2(913, 423), 255, SkinF.battle_026[3], true, false),
      ComFuc.ComControl(nil, Vector2(220, 50), Vector2(620, 73), 255, SkinF.battle_026[4], true, false),
      Gui.Control("match_shelter")({
        BackgroundColor = ARGB(0, 0, 0, 0),
        Size = Vector2(130, 200),
        Location = Vector2(1040, 134),
        ComFuc.ComButton("match_1", GetUTF8Text("button_battlefield_fast_matching"), Vector2(130, 140), Vector2(0, -140), 18, false, false, SkinF.battle_033, true)
      })
    }),
    Gui.Control("plane_2")({
      Dock = "kDockFill",
      Gui.Control("mode_out2")({
        Location = Vector2(8, 45),
        Size = Vector2(701, 447),
        BackgroundColor = colw,
        Skin = SkinF.personalInfo_206,
        ComFuc.ComLabel(nil, GetUTF8Text("UI_battlefield_Mode_Selection"), Vector2(635, 21), Vector2(4, 3), 0, 16, colw, "kAlignCenterMiddle"),
        ComFuc.ComControl(nil, Vector2(631, 98), Vector2(6, 34), 255, SkinF.battle_005),
        Gui.Control("mode_select")({
          Location = Vector2(9, 45),
          Size = Vector2(696, 446),
          BackgroundColor = colw,
          Skin = SkinF.battle_018,
          Gui.Control("mode_sel_host")({
            Location = Vector2(0, -10),
            Size = Vector2(685, 135),
            ComFuc.ComControl("mode_di", Vector2(255, 110), Vector2(69, -3), 255, SkinF.battle_019),
            ComFuc.ComButton("mode_1", nil, Vector2(93, 93), Vector2(72, 22), 0, false, true, SkinF.battle_004[1], false),
            ComFuc.ComButton("mode_2", nil, Vector2(93, 93), Vector2(184, 22), 0, false, true, SkinF.battle_004[3], true),
            ComFuc.ComButton("mode_3", nil, Vector2(93, 93), Vector2(296, 22), 0, false, true, SkinF.battle_004[5], true),
            ComFuc.ComButton("mode_4", nil, Vector2(93, 93), Vector2(408, 22), 0, false, true, SkinF.battle_004[2], true),
            ComFuc.ComButton("mode_5", nil, Vector2(93, 93), Vector2(520, 22), 0, false, true, SkinF.battle_004[4], true),
            ComFuc.ComButton("mode_6", nil, Vector2(93, 93), Vector2(532, 22), 0, false, true, SkinF.battle_004[7], true),
            ComFuc.ComButton("mode_7", nil, Vector2(93, 93), Vector2(532, 22), 0, false, true, SkinF.battle_004[8], true)
          })
        })
      }),
      Gui.Control({
        Size = Vector2(701, 144),
        Location = Vector2(8, 494),
        Gui.NewMessagePanel("msg_panel")({
          Size = Vector2(701, 105),
          BackgroundColor = colw,
          Skin = SkinF.battle_013,
          Style = "LobbyBattleGame.MessagePanel",
          MaxTextWidth = 670,
          OnePageLineNum = 4,
          LineGap = 1
        }),
        Gui.Control({
          Size = Vector2(701, 38),
          Location = Vector2(0, 106),
          BackgroundColor = colw,
          Skin = SkinF.battle_012,
          ComFuc.ComButton("send_btn", GetUTF8Text("button_common_Send"), Vector2(64, 32), Vector2(630, 3), 16, false, false),
          ComFuc.ComTextBox("input_box", "", Vector2(630, 36), Vector2(3, 2), 80)
        })
      }),
      Gui.Control({
        Location = Vector2(713, 45),
        Size = Vector2(405, 586),
        BackgroundColor = colw,
        Skin = SkinF.personalInfo_206,
        ComFuc.ComLabel("team_title", GetUTF8Text("UI_common_Team_List"), Vector2(390, 21), Vector2(4, 3), 0, 16, colw, "kAlignCenterMiddle"),
        ComFuc.ComIconButton("quit", Vector2(114, 56), Vector2(86, 432), SkinF.icon_playgame_004, GetUTF8Text("button_common_Back"), SkinF.select_character_038, nil),
        ComFuc.ComIconButton("invite", Vector2(114, 56), Vector2(202, 432), SkinF.icon_playgame_005, GetUTF8Text("button_battlefield_additional_string_047"), SkinF.select_character_038, nil),
        ComFuc.ComButton("sys_match", GetUTF8Text("button_common_Start_Auto_Match"), Vector2(234, 88), Vector2(84, 488), 16, false, false, SkinF.battle_021, true),
        ComFuc.ComIcon2Button("sys_ready", Vector2(234, 88), Vector2(84, 488), SkinF.icon_playgame_009, GetUTF8Text("button_battlefield_additional_string_138"), SkinF.SkinStartGame),
        Gui.Control({
          Location = Vector2(10, 34),
          Size = Vector2(385, 398),
          BackgroundColor = colw,
          Skin = SkinF.battle_005,
          Gui.ListTreeView("member_list")({
            Style = "Gui.AvatarListTreeView002",
            ItemGap = 1,
            Size = Vector2(368, 400),
            Location = Vector2(9, 13)
          })
        })
      })
    }),
    Gui.Control("rank_ckeck")({
      Size = Vector2(430, 24),
      Location = Vector2(683, 12),
      ComFuc.ComLabel("add_rankSore_text", GetUTF8Text("msgbox_common_clew_rank_integral_01"), Vector2(400, 24), Vector2(0, 0), 0, 16, colw, "kAlignRightMiddle"),
      ComFuc.ComCheckBox("add_rankSore_cb", nil, Vector2(24, 24), Vector2(406, 0))
    })
  })
})
ui.rank_ckeck.Visible = false
ui.add_rankSore_cb.Visible = false
config.VictoryConnectMilitary = config.VictoryConnectMilitary + bitValue[SelectCharacter.role_pos_id]
config:SaveOther()
ui.sys_ready.ClickAudio = "game_launch_ready"
for i = 1, #typeMap do
  ui["mode_" .. i].ClickAudio = "menu2nd"
end
local RemoveTimer2, TimerRefresh2 = function()
  for i = 1, 2 do
    ui["main" .. i .. "_particle"].Visible = false
  end
  ui.match_shelter.Parent = nil
  if not ComFuc.isReadyMatch and not Is_QuickJoin then
    if matchType ~= 1 then
      game.IsjoinedBattle = 1
    end
    if game.IsjoinedBattle == 0 then
      game:PlayAudioMusic(0)
    else
      game:PlayAudioMusic(6)
    end
  end
  ui.match_1.Location = Vector2(0, -140)
  if timer2 then
    game.TimerMgr:RemoveTimer(timer2)
    timer2 = nil
  end
end, function()
  for i = 1, 2 do
    ui["main" .. i .. "_particle"].Visible = false
  end
  ui.match_shelter.Parent = nil
  if not ComFuc.isReadyMatch and not Is_QuickJoin then
    if matchType ~= 1 then
      game.IsjoinedBattle = 1
    end
    if game.IsjoinedBattle == 0 then
      game:PlayAudioMusic(0)
    else
      game:PlayAudioMusic(6)
    end
  end
  ui.match_1.Location = Vector2(0, -140)
  if timer2 then
    game.TimerMgr:RemoveTimer(timer2)
    timer2 = nil
  end
end

function TimerRefresh2()
  local frameC = 10
  local timer_gift_box_pos = -140
  return function()
    local ts = math.min(1, frameC / QUICK_JOIN_FLASH.alpha_scale)
    if frameC < QUICK_JOIN_FLASH.frame_cnt then
      ui.match_shelter.Location = Vector2(1040, 153)
      timer_gift_box_pos = timer_gift_box_pos + QUICK_JOIN_FLASH.frame_step
    elseif frameC >= QUICK_JOIN_FLASH.frame_cnt and frameC < QUICK_JOIN_FLASH.frame_flx1 then
      timer_gift_box_pos = timer_gift_box_pos + QUICK_JOIN_FLASH.frame_flx1_step
    elseif frameC >= QUICK_JOIN_FLASH.frame_flx1 and frameC < QUICK_JOIN_FLASH.frame_finish - 1 then
      timer_gift_box_pos = timer_gift_box_pos + QUICK_JOIN_FLASH.frame_flx2_step
    else
      timer_gift_box_pos = QUICK_JOIN_FLASH.y
      ui.match_shelter.Location = Vector2(1040, 134)
    end
    ui.match_1.Location = Vector2(QUICK_JOIN_FLASH.x, timer_gift_box_pos)
    frameC = frameC + 1
    if frameC >= QUICK_JOIN_FLASH.frame_finish then
      timer_gift_box_pos = 0
      if timer2 then
        game.TimerMgr:RemoveTimer(timer2)
        timer2 = nil
      end
    end
    if frameC <= QUICK_JOIN_FLASH.frame_finish then
    end
  end
end

function AddBtntimer()
  for i = 1, 2 do
    ui["main" .. i .. "_particle"].Particle:Reset()
    ui["main" .. i .. "_particle"].Visible = true
  end
  ui.match_shelter.Parent = Lobby.ui.lobby_root
  if not ComFuc.isReadyMatch and not Is_QuickJoin then
    game:PlayAudioMusic(5)
  end
  ui.match_1.TextColor = ARGB(255, 255, 252, 8)
  ui.match_1.Padding = Vector4(0, 35, 0, 0)
  timer2 = game.TimerMgr:AddTimer(QUICK_JOIN_FLASH.timer)
  timer2.EventOnTimer = TimerRefresh2()
end

function IsNeedShowAllMode()
  return isHostMan and (matchType == 1 or matchType == 2 and (themeType == 1 or themeType == 2) or matchType == 3)
end

local ShowGameType, SetModeBtnState = function()
  local k = 0
  if matchType == 3 then
    for i = 1, #typeMap do
      if CreateRoom and CreateRoom.CheckGameType(typeMap[i]) and i ~= 1 then
        k = k + 1
        gameIndex[i] = k
        ui["mode_" .. i].Visible = true
        ui["mode_" .. i].Enable = not ComFuc.isShowGameTime
        ui["mode_" .. i].Location = Vector2(-90 + 112 * k, 22)
      elseif i == 1 then
        gameIndex[i] = 0
        ui["mode_" .. i].Visible = false
      else
        gameIndex[i] = 0
        ui["mode_" .. i].Visible = false
      end
    end
  else
    GardenGameRoom.SelectThemeType(themeType)
    GardenGameRoom.IsShowGardenMode()
  end
end, function()
  local k = 0
  if matchType == 3 then
    for i = 1, #typeMap do
      if CreateRoom and CreateRoom.CheckGameType(typeMap[i]) and i ~= 1 then
        k = k + 1
        gameIndex[i] = k
        ui["mode_" .. i].Visible = true
        ui["mode_" .. i].Enable = not ComFuc.isShowGameTime
        ui["mode_" .. i].Location = Vector2(-90 + 112 * k, 22)
      elseif i == 1 then
        gameIndex[i] = 0
        ui["mode_" .. i].Visible = false
      else
        gameIndex[i] = 0
        ui["mode_" .. i].Visible = false
      end
    end
  else
    GardenGameRoom.SelectThemeType(themeType)
    GardenGameRoom.IsShowGardenMode()
  end
end
local SetModeBtnState, SetModeBtnEnable = function(type)
  if matchType == 3 then
    gameType = type
    for i = 1, #typeMap do
      ui["mode_" .. i].PushDown = i == type
    end
    ui.mode_di.Visible = IsNeedShowAllMode()
    if IsNeedShowAllMode() then
      ShowGameType()
      if matchType == 2 and themeType == 1 then
        ui.mode_di.Location = Vector2(-36 + 104 * (gameIndex[type] - 1), 7)
      else
        ui.mode_di.Location = Vector2(-53 + 112 * (gameIndex[type] - 1), 7)
      end
    else
      for i = 1, #typeMap do
        ui["mode_" .. i].Visible = i == type
        if i == type then
          ui["mode_" .. i].Location = Vector2(72, 22)
        end
      end
    end
  else
    ui.mode_di.Visible = false
    gameType = type
    GardenGameRoom.SetGardenModeState(type)
  end
end, 1
local SetModeBtnEnable, OnTeamLeaderChanged = function()
  bEnable = not ComFuc.isShowGameTime
  ui.add_rankSore_cb.Enable = bEnable
  ui.sys_ready.Enable = bEnable
  ui.add_rankSore_text.TextColor = bEnable and colw or ARGB(255, 100, 100, 100)
  if matchType == 3 then
    for i = 1, GetMaxModeCount() do
      ui["mode_" .. i].Enable = bEnable and IsNeedShowAllMode()
    end
  else
    GardenGameRoom.SetGardenModeEnable(bEnable, IsNeedShowAllMode())
  end
  print("SetModeBtnEnable() " .. matchType)
  if matchType == 1 then
    ui.theme_tip.Visible = false
  elseif matchType == 2 then
    ui.invite.Enable = bEnable and isHostMan
    ui.sys_match.Enable = isHostMan
    ui.quit.Enable = bEnable or not isHostMan
  elseif matchType == 3 then
    ui.invite.Enable = bEnable and isHostMan
    ui.sys_match.Enable = isHostMan and (teamCurrCount == teamMatchNeed or ui.sys_match.Text == GetUTF8Text("button_common_Stop_Auto_Match"))
    ui.quit.Enable = bEnable or not isHostMan
    ui.match_1.Text = GetUTF8Text("button_battlefield_fast_matching")
    ui.match_1.TextColor = ARGB(255, 255, 252, 8)
  end
end, bitValue[SelectCharacter.role_pos_id]

function OnTeamLeaderChanged(character_id)
  print(">> OnTeamLeaderChanged gameType  " .. gameType)
  isHostMan = tostring(character_id) == tostring(SelectCharacter.roleServerId)
  ui.invite.Enable = isHostMan and matchType ~= 1 and not ComFuc.isShowGameTime
  SetModeBtnState(gameType)
end

function SetMatchButtonState(bStart)
  if bStart then
    if ComFuc.isShowGameTime then
      if matchType == 1 or matchType == 2 then
        ui.match_1.Text = GetUTF8Text("button_common_Stop_Auto_Match")
        ui.match_1.TextColor = ARGB(255, 255, 255, 255)
        Is_QuickJoin = true
        ui.match_1.Enable = true
        ui.theme_tip.Visible = false
      end
      ui.sys_match.Text = GetUTF8Text("button_common_Stop_Auto_Match")
      ui.sys_match.Enable = true
      if matchType == 3 then
        BattleGameRoom.ui.ib_map.Enable = false
      end
      ComFuc.isReadyMatch = true
    end
  else
    if matchType == 1 or matchType == 2 then
      ui.match_1.Text = GetUTF8Text("button_battlefield_fast_matching")
      ui.match_1.TextColor = ARGB(255, 255, 252, 8)
      Is_QuickJoin = false
      ui.match_1.Enable = true
      ComFuc.isReadyStart = false
      if ui.match_shelter.Parent then
        game:PlayAudioMusic(5)
      end
    end
    if isHostMan or ui.sys_match.Text == GetUTF8Text("button_common_Stop_Auto_Match") then
      ui.sys_match.Text = GetUTF8Text("button_common_Start_Auto_Match")
      ui.sys_match.Enable = true
      BattleGameRoom.ui.ib_map.Enable = true
      if matchType == 3 then
        ui.sys_match.Enable = teamCurrCount == teamMatchNeed or ui.sys_match.Text == GetUTF8Text("button_common_Stop_Auto_Match")
      end
      ComFuc.isReadyMatch = false
    end
    ui.coverControl2.Parent = nil
  end
  SetModeBtnEnable()
end

local UpdateInTeamButtonState, UpdateMemberItem = function(self_character_info)
  ComFuc.is_in_room = true
  local state = ptr_cast(game.CurrentState)
  if self_character_info.host then
    ui.sys_ready.Visible = false
    ui.sys_match.Visible = true
    ComFuc.isReadyStart = false
  elseif self_character_info.ready then
    ui.sys_match.Visible = false
    ui.sys_ready.Visible = true
    ui.sys_ready_lbl.Text = GetUTF8Text("button_common_Cancel_Ready")
    ui.sys_ready_lbl.Icon = SkinF.icon_playgame_008
    ComFuc.isReadyStart = true
    
    function ui.sys_ready.EventClick(sender, e)
      MessageBox.ShowWaiter(GetUTF8Text("msgbox_battlefield_additional_string_137"))
      state:TeamReady(false)
    end
  else
    ui.sys_match.Visible = false
    ui.sys_ready.Visible = true
    ui.sys_ready_lbl.Text = GetUTF8Text("button_battlefield_additional_string_138")
    ui.sys_ready_lbl.Icon = SkinF.icon_playgame_009
    ComFuc.isReadyStart = false
    
    function ui.sys_ready.EventClick(sender, e)
      if not LobbyPlayGame then
        require("playgame.lua")
      end
      if LobbyPlayGame.CheckEquipment() then
        MessageBox.ShowWaiter(GetUTF8Text("msgbox_battlefield_additional_string_139"))
        state:TeamReady(true)
      end
    end
  end
end, function(self_character_info)
  ComFuc.is_in_room = true
  local state = ptr_cast(game.CurrentState)
  if self_character_info.host then
    ui.sys_ready.Visible = false
    ui.sys_match.Visible = true
    ComFuc.isReadyStart = false
  elseif self_character_info.ready then
    ui.sys_match.Visible = false
    ui.sys_ready.Visible = true
    ui.sys_ready_lbl.Text = GetUTF8Text("button_common_Cancel_Ready")
    ui.sys_ready_lbl.Icon = SkinF.icon_playgame_008
    ComFuc.isReadyStart = true
    
    function ui.sys_ready.EventClick(sender, e)
      MessageBox.ShowWaiter(GetUTF8Text("msgbox_battlefield_additional_string_137"))
      state:TeamReady(false)
    end
  else
    ui.sys_match.Visible = false
    ui.sys_ready.Visible = true
    ui.sys_ready_lbl.Text = GetUTF8Text("button_battlefield_additional_string_138")
    ui.sys_ready_lbl.Icon = SkinF.icon_playgame_009
    ComFuc.isReadyStart = false
    
    function ui.sys_ready.EventClick(sender, e)
      if not LobbyPlayGame then
        require("playgame.lua")
      end
      if LobbyPlayGame.CheckEquipment() then
        MessageBox.ShowWaiter(GetUTF8Text("msgbox_battlefield_additional_string_139"))
        state:TeamReady(true)
      end
    end
  end
end
local UpdateMemberItem, Free_member_item = function(item, slot)
  local bMoved = false
  local Info = ptr_cast(item.Tag)
  local client_info
  if slot then
    client_info = slot.client
  end
  if Info and client_info == nil then
    local client = ptr_cast(item.Tag, "Client.ClientInfo")
    if client then
      ui.msg_panel:AddMessage("kSys", "", client.character_name .. GetUTF8Text("msgbox_battlefield_additional_string_049"))
    end
    bMoved = true
  end
  item.Tag = nil
  if client_info then
    item:SetText(0, "")
    item:SetIcon(0, IconsF.PlayerCareerIcons[client_info.career + 1])
    item:SetText(1, "")
    if client_info.rank_level and 0 < tonumber(client_info.rank_level) and tonumber(client_info.rank_level) < 15 and client_info.rank_type and client_info.rank_type < 5 and 0 < client_info.rank_type then
      item:SetIcon(1, IconsF.RankIcons[tonumber(client_info.rank_type)][tonumber(client_info.rank_level)])
    else
      item:SetIcon(1, nil)
    end
    item:SetText(2, string.format("Lv%d", client_info.level))
    item:SetText(3, client_info.character_name)
    if client_info.vip_level and 0 < tonumber(client_info.vip_level) then
      item:SetIcon(4, IconsF.RoomStatusIcons["vip_level" .. client_info.vip_level])
    elseif client_info.vip_level and tonumber(client_info.vip_level) ~= 0 then
      item:SetIcon(4, IconsF.RoomStatusIcons.vip_level_temp)
    else
      item:SetIcon(4, nil)
    end
    if client_info.host then
      ready_num = ready_num + 1
      item:SetIcon(5, IconsF.PlayerStatusIcons.HostN)
      item:SetHoverIcon(5, IconsF.PlayerStatusIcons.HostA)
      OnTeamLeaderChanged(client_info.character_id)
    elseif client_info.in_game then
      item:SetIcon(5, IconsF.PlayerStatusIcons.PlayingN)
      item:SetHoverIcon(5, IconsF.PlayerStatusIcons.PlayingN)
    elseif client_info.ready then
      ready_num = ready_num + 1
      item:SetIcon(5, IconsF.PlayerStatusIcons.ReadyN)
      item:SetHoverIcon(5, IconsF.PlayerStatusIcons.ReadyA)
    else
      item:SetIcon(5, nil)
      item:SetHoverIcon(5, nil)
    end
    item.Tag = client_info
  else
    item:SetText(0, "")
    item:SetIcon(0, nil)
    item:SetHoverIcon(0, nil)
    item:SetText(1, "")
    item:SetIcon(1, nil)
    item:SetHoverIcon(1, nil)
    item:SetText(2, "")
    item:SetText(3, "")
    item:SetIcon(4, nil)
    item:SetHoverIcon(4, nil)
    item:SetIcon(5, nil)
    item:SetHoverIcon(5, nil)
  end
  return bMoved
end, "ClickAudio"
local Free_member_item, SwitchToMatchMode = function()
  for i = 1, 8 do
    local item = ptr_cast(memDt[i])
    if item then
      UpdateMemberItem(memDt[i], nil)
      item.Tag = nil
    end
  end
  peopleCount = 0
end, "menu2nd"
local SwitchToMatchMode, OnTimerCallBack = function(type, isHst)
  matchType = type
  isHostMan = isHst
  ui.mode_sel_host.Parent = ui.mode_select
  ui.plane_1.Visible = type == 1
  ui.plane_2.Visible = type ~= 1
  ui.mode_out2.Visible = type ~= 2
  BattleGameRoom.Show(type == 3 and ui.plane_2)
  GardenGameRoom.Show(matchType == 2 and (themeType == 1 or themeType == 2) and ui.plane_2)
  ui.match_1.Enable = type == 1 or type == 2
  if type == 1 then
    themeType = 0
    ui.input_box.Text = ""
    isHostMan = false
    ui.main.Skin = SkinF.game_background
    ui.main.Location = Vector2(9, 22)
    ui.main.Size = Vector2(1110, 634)
    LobbyStartGame.SetTitlePart(true)
    LobbyBoxContern.CloseInvite()
    Free_member_item()
    ui.msg_panel:ClearMessage()
    if bit.band(128, ComFuc.leadList) == 128 then
      NewLead.ShowNewLeadNoLock(Vector2(1060, 189), Vector2(90, 65), GetUTF8Text("button_battlefield_fast_matching"), 0)
    end
  else
    LobbyStartGame.SetTitlePart(false)
    LobbyStartGame.ui.item_di_title.Visible = true
    ui.main.Location = Vector2(0, 0)
    ui.main.Size = Vector2(1128, 645)
    ui.main.Skin = SkinF.personalInfo_098
    ui.invite.Visible = true
    ui.sys_match.Visible = true
    ui.input_box.Enable = not game.isNoSpeak
    ui.send_btn.Enable = not game.isNoSpeak
    NewLead.HideLead()
    ui.mode_select.Parent = ui.mode_out2
  end
  SetModeBtnState(gameType)
  if (type == 1 or type == 2 and isHostMan) and not ComFuc.Is_StartGameParticle then
    if not timer2 then
      AddBtntimer()
    end
  else
    RemoveTimer2()
  end
  SetModeBtnEnable()
end, Gui.Control("main")({
  Size = Vector2(1128, 645),
  BackgroundColor = colw,
  Skin = SkinF.game_background,
  Gui.Control("plane_1")({
    Dock = "kDockFill",
    ComFuc.ComControlAddPt("main1_particle", Vector2(1128, 460), Vector2(0, 0), "scene_clouds"),
    ComFuc.ComButton("theme_5", "", Vector2(410, 484), Vector2(313, 0), 16, false, false, SkinF.themeMode_btn[5]),
    ComFuc.ComButton("theme_1", "", Vector2(280, 229), Vector2(73, 292), 16, false, false, SkinF.themeMode_btn[1]),
    ComFuc.ComButton("theme_2", "", Vector2(381, 372), Vector2(471, 262), 16, false, false, SkinF.themeMode_btn[2]),
    ComFuc.ComButton("theme_3", "", Vector2(282, 317), Vector2(780, 165), 16, false, false, SkinF.themeMode_btn[3]),
    ComFuc.ComButton("theme_4", "", Vector2(293, 248), Vector2(720, 0), 16, false, false, SkinF.themeMode_btn[4]),
    ComFuc.ComControlAddPt("theme1_particle", Vector2(350, 350), Vector2(73, 175), "scene_practice"),
    ComFuc.ComControlAddPt("theme2_particle", Vector2(381, 372), Vector2(473, 166), "scene_battlefield"),
    ComFuc.ComControlAddPt("theme3_particle", Vector2(282, 317), Vector2(780, 165), "scene_group"),
    ComFuc.ComControlAddPt("theme4_particle", Vector2(293, 248), Vector2(697, -23), "scene_adventure"),
    ComFuc.ComControlAddPt("theme5_particle", Vector2(381, 372), Vector2(300, 0), "scene_adventure"),
    ComFuc.ComControlAddPt("main2_particle", Vector2(1128, 185), Vector2(0, 460), "scene_clouds_2"),
    Gui.Control("theme_tip")({
      Location = Vector2(500, 150),
      Size = totalSize,
      BackgroundColor = colw,
      Skin = SkinF.lookInfo_004,
      Visible = false,
      Gui.Label("theme_text")({
        Location = Vector2(0, 0),
        Size = TextSize,
        TextAlign = "kAlignLeftTop",
        AutoWrap = true,
        FontSize = 15,
        TextColor = ARGB(255, 255, 255, 255),
        Text = GetUTF8Text("UI_battlefield_Instruction_Freestyle_Combat")
      })
    }),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(19, 492), 255, SkinF.battle_026[1], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(646, 561), 255, SkinF.battle_026[2], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(913, 423), 255, SkinF.battle_026[3], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(620, 73), 255, SkinF.battle_026[4], true, false),
    Gui.Control("match_shelter")({
      BackgroundColor = ARGB(0, 0, 0, 0),
      Size = Vector2(130, 200),
      Location = Vector2(1040, 134),
      ComFuc.ComButton("match_1", GetUTF8Text("button_battlefield_fast_matching"), Vector2(130, 140), Vector2(0, -140), 18, false, false, SkinF.battle_033, true)
    })
  }),
  Gui.Control("plane_2")({
    Dock = "kDockFill",
    Gui.Control("mode_out2")({
      Location = Vector2(8, 45),
      Size = Vector2(701, 447),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel(nil, GetUTF8Text("UI_battlefield_Mode_Selection"), Vector2(635, 21), Vector2(4, 3), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComControl(nil, Vector2(631, 98), Vector2(6, 34), 255, SkinF.battle_005),
      Gui.Control("mode_select")({
        Location = Vector2(9, 45),
        Size = Vector2(696, 446),
        BackgroundColor = colw,
        Skin = SkinF.battle_018,
        Gui.Control("mode_sel_host")({
          Location = Vector2(0, -10),
          Size = Vector2(685, 135),
          ComFuc.ComControl("mode_di", Vector2(255, 110), Vector2(69, -3), 255, SkinF.battle_019),
          ComFuc.ComButton("mode_1", nil, Vector2(93, 93), Vector2(72, 22), 0, false, true, SkinF.battle_004[1], false),
          ComFuc.ComButton("mode_2", nil, Vector2(93, 93), Vector2(184, 22), 0, false, true, SkinF.battle_004[3], true),
          ComFuc.ComButton("mode_3", nil, Vector2(93, 93), Vector2(296, 22), 0, false, true, SkinF.battle_004[5], true),
          ComFuc.ComButton("mode_4", nil, Vector2(93, 93), Vector2(408, 22), 0, false, true, SkinF.battle_004[2], true),
          ComFuc.ComButton("mode_5", nil, Vector2(93, 93), Vector2(520, 22), 0, false, true, SkinF.battle_004[4], true),
          ComFuc.ComButton("mode_6", nil, Vector2(93, 93), Vector2(532, 22), 0, false, true, SkinF.battle_004[7], true),
          ComFuc.ComButton("mode_7", nil, Vector2(93, 93), Vector2(532, 22), 0, false, true, SkinF.battle_004[8], true)
        })
      })
    }),
    Gui.Control({
      Size = Vector2(701, 144),
      Location = Vector2(8, 494),
      Gui.NewMessagePanel("msg_panel")({
        Size = Vector2(701, 105),
        BackgroundColor = colw,
        Skin = SkinF.battle_013,
        Style = "LobbyBattleGame.MessagePanel",
        MaxTextWidth = 670,
        OnePageLineNum = 4,
        LineGap = 1
      }),
      Gui.Control({
        Size = Vector2(701, 38),
        Location = Vector2(0, 106),
        BackgroundColor = colw,
        Skin = SkinF.battle_012,
        ComFuc.ComButton("send_btn", GetUTF8Text("button_common_Send"), Vector2(64, 32), Vector2(630, 3), 16, false, false),
        ComFuc.ComTextBox("input_box", "", Vector2(630, 36), Vector2(3, 2), 80)
      })
    }),
    Gui.Control({
      Location = Vector2(713, 45),
      Size = Vector2(405, 586),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel("team_title", GetUTF8Text("UI_common_Team_List"), Vector2(390, 21), Vector2(4, 3), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComIconButton("quit", Vector2(114, 56), Vector2(86, 432), SkinF.icon_playgame_004, GetUTF8Text("button_common_Back"), SkinF.select_character_038, nil),
      ComFuc.ComIconButton("invite", Vector2(114, 56), Vector2(202, 432), SkinF.icon_playgame_005, GetUTF8Text("button_battlefield_additional_string_047"), SkinF.select_character_038, nil),
      ComFuc.ComButton("sys_match", GetUTF8Text("button_common_Start_Auto_Match"), Vector2(234, 88), Vector2(84, 488), 16, false, false, SkinF.battle_021, true),
      ComFuc.ComIcon2Button("sys_ready", Vector2(234, 88), Vector2(84, 488), SkinF.icon_playgame_009, GetUTF8Text("button_battlefield_additional_string_138"), SkinF.SkinStartGame),
      Gui.Control({
        Location = Vector2(10, 34),
        Size = Vector2(385, 398),
        BackgroundColor = colw,
        Skin = SkinF.battle_005,
        Gui.ListTreeView("member_list")({
          Style = "Gui.AvatarListTreeView002",
          ItemGap = 1,
          Size = Vector2(368, 400),
          Location = Vector2(9, 13)
        })
      })
    })
  }),
  Gui.Control("rank_ckeck")({
    Size = Vector2(430, 24),
    Location = Vector2(683, 12),
    ComFuc.ComLabel("add_rankSore_text", GetUTF8Text("msgbox_common_clew_rank_integral_01"), Vector2(400, 24), Vector2(0, 0), 0, 16, colw, "kAlignRightMiddle"),
    ComFuc.ComCheckBox("add_rankSore_cb", nil, Vector2(24, 24), Vector2(406, 0))
  })
})
local OnTimerCallBack, SetTeamMatchEnable = function()
  ui.coverControl2.Parent = nil
end, Gui.Control("main")({
  Size = Vector2(1128, 645),
  BackgroundColor = colw,
  Skin = SkinF.game_background,
  Gui.Control("plane_1")({
    Dock = "kDockFill",
    ComFuc.ComControlAddPt("main1_particle", Vector2(1128, 460), Vector2(0, 0), "scene_clouds"),
    ComFuc.ComButton("theme_5", "", Vector2(410, 484), Vector2(313, 0), 16, false, false, SkinF.themeMode_btn[5]),
    ComFuc.ComButton("theme_1", "", Vector2(280, 229), Vector2(73, 292), 16, false, false, SkinF.themeMode_btn[1]),
    ComFuc.ComButton("theme_2", "", Vector2(381, 372), Vector2(471, 262), 16, false, false, SkinF.themeMode_btn[2]),
    ComFuc.ComButton("theme_3", "", Vector2(282, 317), Vector2(780, 165), 16, false, false, SkinF.themeMode_btn[3]),
    ComFuc.ComButton("theme_4", "", Vector2(293, 248), Vector2(720, 0), 16, false, false, SkinF.themeMode_btn[4]),
    ComFuc.ComControlAddPt("theme1_particle", Vector2(350, 350), Vector2(73, 175), "scene_practice"),
    ComFuc.ComControlAddPt("theme2_particle", Vector2(381, 372), Vector2(473, 166), "scene_battlefield"),
    ComFuc.ComControlAddPt("theme3_particle", Vector2(282, 317), Vector2(780, 165), "scene_group"),
    ComFuc.ComControlAddPt("theme4_particle", Vector2(293, 248), Vector2(697, -23), "scene_adventure"),
    ComFuc.ComControlAddPt("theme5_particle", Vector2(381, 372), Vector2(300, 0), "scene_adventure"),
    ComFuc.ComControlAddPt("main2_particle", Vector2(1128, 185), Vector2(0, 460), "scene_clouds_2"),
    Gui.Control("theme_tip")({
      Location = Vector2(500, 150),
      Size = totalSize,
      BackgroundColor = colw,
      Skin = SkinF.lookInfo_004,
      Visible = false,
      Gui.Label("theme_text")({
        Location = Vector2(0, 0),
        Size = TextSize,
        TextAlign = "kAlignLeftTop",
        AutoWrap = true,
        FontSize = 15,
        TextColor = ARGB(255, 255, 255, 255),
        Text = GetUTF8Text("UI_battlefield_Instruction_Freestyle_Combat")
      })
    }),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(19, 492), 255, SkinF.battle_026[1], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(646, 561), 255, SkinF.battle_026[2], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(913, 423), 255, SkinF.battle_026[3], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(620, 73), 255, SkinF.battle_026[4], true, false),
    Gui.Control("match_shelter")({
      BackgroundColor = ARGB(0, 0, 0, 0),
      Size = Vector2(130, 200),
      Location = Vector2(1040, 134),
      ComFuc.ComButton("match_1", GetUTF8Text("button_battlefield_fast_matching"), Vector2(130, 140), Vector2(0, -140), 18, false, false, SkinF.battle_033, true)
    })
  }),
  Gui.Control("plane_2")({
    Dock = "kDockFill",
    Gui.Control("mode_out2")({
      Location = Vector2(8, 45),
      Size = Vector2(701, 447),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel(nil, GetUTF8Text("UI_battlefield_Mode_Selection"), Vector2(635, 21), Vector2(4, 3), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComControl(nil, Vector2(631, 98), Vector2(6, 34), 255, SkinF.battle_005),
      Gui.Control("mode_select")({
        Location = Vector2(9, 45),
        Size = Vector2(696, 446),
        BackgroundColor = colw,
        Skin = SkinF.battle_018,
        Gui.Control("mode_sel_host")({
          Location = Vector2(0, -10),
          Size = Vector2(685, 135),
          ComFuc.ComControl("mode_di", Vector2(255, 110), Vector2(69, -3), 255, SkinF.battle_019),
          ComFuc.ComButton("mode_1", nil, Vector2(93, 93), Vector2(72, 22), 0, false, true, SkinF.battle_004[1], false),
          ComFuc.ComButton("mode_2", nil, Vector2(93, 93), Vector2(184, 22), 0, false, true, SkinF.battle_004[3], true),
          ComFuc.ComButton("mode_3", nil, Vector2(93, 93), Vector2(296, 22), 0, false, true, SkinF.battle_004[5], true),
          ComFuc.ComButton("mode_4", nil, Vector2(93, 93), Vector2(408, 22), 0, false, true, SkinF.battle_004[2], true),
          ComFuc.ComButton("mode_5", nil, Vector2(93, 93), Vector2(520, 22), 0, false, true, SkinF.battle_004[4], true),
          ComFuc.ComButton("mode_6", nil, Vector2(93, 93), Vector2(532, 22), 0, false, true, SkinF.battle_004[7], true),
          ComFuc.ComButton("mode_7", nil, Vector2(93, 93), Vector2(532, 22), 0, false, true, SkinF.battle_004[8], true)
        })
      })
    }),
    Gui.Control({
      Size = Vector2(701, 144),
      Location = Vector2(8, 494),
      Gui.NewMessagePanel("msg_panel")({
        Size = Vector2(701, 105),
        BackgroundColor = colw,
        Skin = SkinF.battle_013,
        Style = "LobbyBattleGame.MessagePanel",
        MaxTextWidth = 670,
        OnePageLineNum = 4,
        LineGap = 1
      }),
      Gui.Control({
        Size = Vector2(701, 38),
        Location = Vector2(0, 106),
        BackgroundColor = colw,
        Skin = SkinF.battle_012,
        ComFuc.ComButton("send_btn", GetUTF8Text("button_common_Send"), Vector2(64, 32), Vector2(630, 3), 16, false, false),
        ComFuc.ComTextBox("input_box", "", Vector2(630, 36), Vector2(3, 2), 80)
      })
    }),
    Gui.Control({
      Location = Vector2(713, 45),
      Size = Vector2(405, 586),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel("team_title", GetUTF8Text("UI_common_Team_List"), Vector2(390, 21), Vector2(4, 3), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComIconButton("quit", Vector2(114, 56), Vector2(86, 432), SkinF.icon_playgame_004, GetUTF8Text("button_common_Back"), SkinF.select_character_038, nil),
      ComFuc.ComIconButton("invite", Vector2(114, 56), Vector2(202, 432), SkinF.icon_playgame_005, GetUTF8Text("button_battlefield_additional_string_047"), SkinF.select_character_038, nil),
      ComFuc.ComButton("sys_match", GetUTF8Text("button_common_Start_Auto_Match"), Vector2(234, 88), Vector2(84, 488), 16, false, false, SkinF.battle_021, true),
      ComFuc.ComIcon2Button("sys_ready", Vector2(234, 88), Vector2(84, 488), SkinF.icon_playgame_009, GetUTF8Text("button_battlefield_additional_string_138"), SkinF.SkinStartGame),
      Gui.Control({
        Location = Vector2(10, 34),
        Size = Vector2(385, 398),
        BackgroundColor = colw,
        Skin = SkinF.battle_005,
        Gui.ListTreeView("member_list")({
          Style = "Gui.AvatarListTreeView002",
          ItemGap = 1,
          Size = Vector2(368, 400),
          Location = Vector2(9, 13)
        })
      })
    })
  }),
  Gui.Control("rank_ckeck")({
    Size = Vector2(430, 24),
    Location = Vector2(683, 12),
    ComFuc.ComLabel("add_rankSore_text", GetUTF8Text("msgbox_common_clew_rank_integral_01"), Vector2(400, 24), Vector2(0, 0), 0, 16, colw, "kAlignRightMiddle"),
    ComFuc.ComCheckBox("add_rankSore_cb", nil, Vector2(24, 24), Vector2(406, 0))
  })
})
local SetTeamMatchEnable, RequestTeamMemberList = function(bEnable)
  ui.match_1.Enable = bEnable
  if bEnable then
    if matchType == 1 then
      ComFuc.isReadyStart = false
    end
    ComFuc.isReadyMatch = false
  else
  end
end, Gui.Control("main")({
  Size = Vector2(1128, 645),
  BackgroundColor = colw,
  Skin = SkinF.game_background,
  Gui.Control("plane_1")({
    Dock = "kDockFill",
    ComFuc.ComControlAddPt("main1_particle", Vector2(1128, 460), Vector2(0, 0), "scene_clouds"),
    ComFuc.ComButton("theme_5", "", Vector2(410, 484), Vector2(313, 0), 16, false, false, SkinF.themeMode_btn[5]),
    ComFuc.ComButton("theme_1", "", Vector2(280, 229), Vector2(73, 292), 16, false, false, SkinF.themeMode_btn[1]),
    ComFuc.ComButton("theme_2", "", Vector2(381, 372), Vector2(471, 262), 16, false, false, SkinF.themeMode_btn[2]),
    ComFuc.ComButton("theme_3", "", Vector2(282, 317), Vector2(780, 165), 16, false, false, SkinF.themeMode_btn[3]),
    ComFuc.ComButton("theme_4", "", Vector2(293, 248), Vector2(720, 0), 16, false, false, SkinF.themeMode_btn[4]),
    ComFuc.ComControlAddPt("theme1_particle", Vector2(350, 350), Vector2(73, 175), "scene_practice"),
    ComFuc.ComControlAddPt("theme2_particle", Vector2(381, 372), Vector2(473, 166), "scene_battlefield"),
    ComFuc.ComControlAddPt("theme3_particle", Vector2(282, 317), Vector2(780, 165), "scene_group"),
    ComFuc.ComControlAddPt("theme4_particle", Vector2(293, 248), Vector2(697, -23), "scene_adventure"),
    ComFuc.ComControlAddPt("theme5_particle", Vector2(381, 372), Vector2(300, 0), "scene_adventure"),
    ComFuc.ComControlAddPt("main2_particle", Vector2(1128, 185), Vector2(0, 460), "scene_clouds_2"),
    Gui.Control("theme_tip")({
      Location = Vector2(500, 150),
      Size = totalSize,
      BackgroundColor = colw,
      Skin = SkinF.lookInfo_004,
      Visible = false,
      Gui.Label("theme_text")({
        Location = Vector2(0, 0),
        Size = TextSize,
        TextAlign = "kAlignLeftTop",
        AutoWrap = true,
        FontSize = 15,
        TextColor = ARGB(255, 255, 255, 255),
        Text = GetUTF8Text("UI_battlefield_Instruction_Freestyle_Combat")
      })
    }),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(19, 492), 255, SkinF.battle_026[1], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(646, 561), 255, SkinF.battle_026[2], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(913, 423), 255, SkinF.battle_026[3], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(620, 73), 255, SkinF.battle_026[4], true, false),
    Gui.Control("match_shelter")({
      BackgroundColor = ARGB(0, 0, 0, 0),
      Size = Vector2(130, 200),
      Location = Vector2(1040, 134),
      ComFuc.ComButton("match_1", GetUTF8Text("button_battlefield_fast_matching"), Vector2(130, 140), Vector2(0, -140), 18, false, false, SkinF.battle_033, true)
    })
  }),
  Gui.Control("plane_2")({
    Dock = "kDockFill",
    Gui.Control("mode_out2")({
      Location = Vector2(8, 45),
      Size = Vector2(701, 447),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel(nil, GetUTF8Text("UI_battlefield_Mode_Selection"), Vector2(635, 21), Vector2(4, 3), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComControl(nil, Vector2(631, 98), Vector2(6, 34), 255, SkinF.battle_005),
      Gui.Control("mode_select")({
        Location = Vector2(9, 45),
        Size = Vector2(696, 446),
        BackgroundColor = colw,
        Skin = SkinF.battle_018,
        Gui.Control("mode_sel_host")({
          Location = Vector2(0, -10),
          Size = Vector2(685, 135),
          ComFuc.ComControl("mode_di", Vector2(255, 110), Vector2(69, -3), 255, SkinF.battle_019),
          ComFuc.ComButton("mode_1", nil, Vector2(93, 93), Vector2(72, 22), 0, false, true, SkinF.battle_004[1], false),
          ComFuc.ComButton("mode_2", nil, Vector2(93, 93), Vector2(184, 22), 0, false, true, SkinF.battle_004[3], true),
          ComFuc.ComButton("mode_3", nil, Vector2(93, 93), Vector2(296, 22), 0, false, true, SkinF.battle_004[5], true),
          ComFuc.ComButton("mode_4", nil, Vector2(93, 93), Vector2(408, 22), 0, false, true, SkinF.battle_004[2], true),
          ComFuc.ComButton("mode_5", nil, Vector2(93, 93), Vector2(520, 22), 0, false, true, SkinF.battle_004[4], true),
          ComFuc.ComButton("mode_6", nil, Vector2(93, 93), Vector2(532, 22), 0, false, true, SkinF.battle_004[7], true),
          ComFuc.ComButton("mode_7", nil, Vector2(93, 93), Vector2(532, 22), 0, false, true, SkinF.battle_004[8], true)
        })
      })
    }),
    Gui.Control({
      Size = Vector2(701, 144),
      Location = Vector2(8, 494),
      Gui.NewMessagePanel("msg_panel")({
        Size = Vector2(701, 105),
        BackgroundColor = colw,
        Skin = SkinF.battle_013,
        Style = "LobbyBattleGame.MessagePanel",
        MaxTextWidth = 670,
        OnePageLineNum = 4,
        LineGap = 1
      }),
      Gui.Control({
        Size = Vector2(701, 38),
        Location = Vector2(0, 106),
        BackgroundColor = colw,
        Skin = SkinF.battle_012,
        ComFuc.ComButton("send_btn", GetUTF8Text("button_common_Send"), Vector2(64, 32), Vector2(630, 3), 16, false, false),
        ComFuc.ComTextBox("input_box", "", Vector2(630, 36), Vector2(3, 2), 80)
      })
    }),
    Gui.Control({
      Location = Vector2(713, 45),
      Size = Vector2(405, 586),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel("team_title", GetUTF8Text("UI_common_Team_List"), Vector2(390, 21), Vector2(4, 3), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComIconButton("quit", Vector2(114, 56), Vector2(86, 432), SkinF.icon_playgame_004, GetUTF8Text("button_common_Back"), SkinF.select_character_038, nil),
      ComFuc.ComIconButton("invite", Vector2(114, 56), Vector2(202, 432), SkinF.icon_playgame_005, GetUTF8Text("button_battlefield_additional_string_047"), SkinF.select_character_038, nil),
      ComFuc.ComButton("sys_match", GetUTF8Text("button_common_Start_Auto_Match"), Vector2(234, 88), Vector2(84, 488), 16, false, false, SkinF.battle_021, true),
      ComFuc.ComIcon2Button("sys_ready", Vector2(234, 88), Vector2(84, 488), SkinF.icon_playgame_009, GetUTF8Text("button_battlefield_additional_string_138"), SkinF.SkinStartGame),
      Gui.Control({
        Location = Vector2(10, 34),
        Size = Vector2(385, 398),
        BackgroundColor = colw,
        Skin = SkinF.battle_005,
        Gui.ListTreeView("member_list")({
          Style = "Gui.AvatarListTreeView002",
          ItemGap = 1,
          Size = Vector2(368, 400),
          Location = Vector2(9, 13)
        })
      })
    })
  }),
  Gui.Control("rank_ckeck")({
    Size = Vector2(430, 24),
    Location = Vector2(683, 12),
    ComFuc.ComLabel("add_rankSore_text", GetUTF8Text("msgbox_common_clew_rank_integral_01"), Vector2(400, 24), Vector2(0, 0), 0, 16, colw, "kAlignRightMiddle"),
    ComFuc.ComCheckBox("add_rankSore_cb", nil, Vector2(24, 24), Vector2(406, 0))
  })
})
local RequestTeamMemberList, LeaveTeamMatch = function(theme_Type)
  local state = ptr_cast(game.CurrentState, "Client.StateLobby")
  state:RequestTeamMemberList(theme_Type)
end, Gui.Control("main")({
  Size = Vector2(1128, 645),
  BackgroundColor = colw,
  Skin = SkinF.game_background,
  Gui.Control("plane_1")({
    Dock = "kDockFill",
    ComFuc.ComControlAddPt("main1_particle", Vector2(1128, 460), Vector2(0, 0), "scene_clouds"),
    ComFuc.ComButton("theme_5", "", Vector2(410, 484), Vector2(313, 0), 16, false, false, SkinF.themeMode_btn[5]),
    ComFuc.ComButton("theme_1", "", Vector2(280, 229), Vector2(73, 292), 16, false, false, SkinF.themeMode_btn[1]),
    ComFuc.ComButton("theme_2", "", Vector2(381, 372), Vector2(471, 262), 16, false, false, SkinF.themeMode_btn[2]),
    ComFuc.ComButton("theme_3", "", Vector2(282, 317), Vector2(780, 165), 16, false, false, SkinF.themeMode_btn[3]),
    ComFuc.ComButton("theme_4", "", Vector2(293, 248), Vector2(720, 0), 16, false, false, SkinF.themeMode_btn[4]),
    ComFuc.ComControlAddPt("theme1_particle", Vector2(350, 350), Vector2(73, 175), "scene_practice"),
    ComFuc.ComControlAddPt("theme2_particle", Vector2(381, 372), Vector2(473, 166), "scene_battlefield"),
    ComFuc.ComControlAddPt("theme3_particle", Vector2(282, 317), Vector2(780, 165), "scene_group"),
    ComFuc.ComControlAddPt("theme4_particle", Vector2(293, 248), Vector2(697, -23), "scene_adventure"),
    ComFuc.ComControlAddPt("theme5_particle", Vector2(381, 372), Vector2(300, 0), "scene_adventure"),
    ComFuc.ComControlAddPt("main2_particle", Vector2(1128, 185), Vector2(0, 460), "scene_clouds_2"),
    Gui.Control("theme_tip")({
      Location = Vector2(500, 150),
      Size = totalSize,
      BackgroundColor = colw,
      Skin = SkinF.lookInfo_004,
      Visible = false,
      Gui.Label("theme_text")({
        Location = Vector2(0, 0),
        Size = TextSize,
        TextAlign = "kAlignLeftTop",
        AutoWrap = true,
        FontSize = 15,
        TextColor = ARGB(255, 255, 255, 255),
        Text = GetUTF8Text("UI_battlefield_Instruction_Freestyle_Combat")
      })
    }),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(19, 492), 255, SkinF.battle_026[1], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(646, 561), 255, SkinF.battle_026[2], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(913, 423), 255, SkinF.battle_026[3], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(620, 73), 255, SkinF.battle_026[4], true, false),
    Gui.Control("match_shelter")({
      BackgroundColor = ARGB(0, 0, 0, 0),
      Size = Vector2(130, 200),
      Location = Vector2(1040, 134),
      ComFuc.ComButton("match_1", GetUTF8Text("button_battlefield_fast_matching"), Vector2(130, 140), Vector2(0, -140), 18, false, false, SkinF.battle_033, true)
    })
  }),
  Gui.Control("plane_2")({
    Dock = "kDockFill",
    Gui.Control("mode_out2")({
      Location = Vector2(8, 45),
      Size = Vector2(701, 447),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel(nil, GetUTF8Text("UI_battlefield_Mode_Selection"), Vector2(635, 21), Vector2(4, 3), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComControl(nil, Vector2(631, 98), Vector2(6, 34), 255, SkinF.battle_005),
      Gui.Control("mode_select")({
        Location = Vector2(9, 45),
        Size = Vector2(696, 446),
        BackgroundColor = colw,
        Skin = SkinF.battle_018,
        Gui.Control("mode_sel_host")({
          Location = Vector2(0, -10),
          Size = Vector2(685, 135),
          ComFuc.ComControl("mode_di", Vector2(255, 110), Vector2(69, -3), 255, SkinF.battle_019),
          ComFuc.ComButton("mode_1", nil, Vector2(93, 93), Vector2(72, 22), 0, false, true, SkinF.battle_004[1], false),
          ComFuc.ComButton("mode_2", nil, Vector2(93, 93), Vector2(184, 22), 0, false, true, SkinF.battle_004[3], true),
          ComFuc.ComButton("mode_3", nil, Vector2(93, 93), Vector2(296, 22), 0, false, true, SkinF.battle_004[5], true),
          ComFuc.ComButton("mode_4", nil, Vector2(93, 93), Vector2(408, 22), 0, false, true, SkinF.battle_004[2], true),
          ComFuc.ComButton("mode_5", nil, Vector2(93, 93), Vector2(520, 22), 0, false, true, SkinF.battle_004[4], true),
          ComFuc.ComButton("mode_6", nil, Vector2(93, 93), Vector2(532, 22), 0, false, true, SkinF.battle_004[7], true),
          ComFuc.ComButton("mode_7", nil, Vector2(93, 93), Vector2(532, 22), 0, false, true, SkinF.battle_004[8], true)
        })
      })
    }),
    Gui.Control({
      Size = Vector2(701, 144),
      Location = Vector2(8, 494),
      Gui.NewMessagePanel("msg_panel")({
        Size = Vector2(701, 105),
        BackgroundColor = colw,
        Skin = SkinF.battle_013,
        Style = "LobbyBattleGame.MessagePanel",
        MaxTextWidth = 670,
        OnePageLineNum = 4,
        LineGap = 1
      }),
      Gui.Control({
        Size = Vector2(701, 38),
        Location = Vector2(0, 106),
        BackgroundColor = colw,
        Skin = SkinF.battle_012,
        ComFuc.ComButton("send_btn", GetUTF8Text("button_common_Send"), Vector2(64, 32), Vector2(630, 3), 16, false, false),
        ComFuc.ComTextBox("input_box", "", Vector2(630, 36), Vector2(3, 2), 80)
      })
    }),
    Gui.Control({
      Location = Vector2(713, 45),
      Size = Vector2(405, 586),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel("team_title", GetUTF8Text("UI_common_Team_List"), Vector2(390, 21), Vector2(4, 3), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComIconButton("quit", Vector2(114, 56), Vector2(86, 432), SkinF.icon_playgame_004, GetUTF8Text("button_common_Back"), SkinF.select_character_038, nil),
      ComFuc.ComIconButton("invite", Vector2(114, 56), Vector2(202, 432), SkinF.icon_playgame_005, GetUTF8Text("button_battlefield_additional_string_047"), SkinF.select_character_038, nil),
      ComFuc.ComButton("sys_match", GetUTF8Text("button_common_Start_Auto_Match"), Vector2(234, 88), Vector2(84, 488), 16, false, false, SkinF.battle_021, true),
      ComFuc.ComIcon2Button("sys_ready", Vector2(234, 88), Vector2(84, 488), SkinF.icon_playgame_009, GetUTF8Text("button_battlefield_additional_string_138"), SkinF.SkinStartGame),
      Gui.Control({
        Location = Vector2(10, 34),
        Size = Vector2(385, 398),
        BackgroundColor = colw,
        Skin = SkinF.battle_005,
        Gui.ListTreeView("member_list")({
          Style = "Gui.AvatarListTreeView002",
          ItemGap = 1,
          Size = Vector2(368, 400),
          Location = Vector2(9, 13)
        })
      })
    })
  }),
  Gui.Control("rank_ckeck")({
    Size = Vector2(430, 24),
    Location = Vector2(683, 12),
    ComFuc.ComLabel("add_rankSore_text", GetUTF8Text("msgbox_common_clew_rank_integral_01"), Vector2(400, 24), Vector2(0, 0), 0, 16, colw, "kAlignRightMiddle"),
    ComFuc.ComCheckBox("add_rankSore_cb", nil, Vector2(24, 24), Vector2(406, 0))
  })
})
local LeaveTeamMatch, HideLobbyGameTime = function()
  Free_member_item()
  CloseTeamMatch(true)
  ui.invite_lbl.Text = btnText[1]
  ui.team_title.Text = teamTileText[1]
  LobbyStartGame.ui.item_di_title.Skin = itemSkin[1]
  LobbyStartGame.ui.lbl_game_type.Text = titleText[1]
  LobbyStartGame.ui.btn_main_1.Skin = titleSkin[1]
end, Gui.Control("main")({
  Size = Vector2(1128, 645),
  BackgroundColor = colw,
  Skin = SkinF.game_background,
  Gui.Control("plane_1")({
    Dock = "kDockFill",
    ComFuc.ComControlAddPt("main1_particle", Vector2(1128, 460), Vector2(0, 0), "scene_clouds"),
    ComFuc.ComButton("theme_5", "", Vector2(410, 484), Vector2(313, 0), 16, false, false, SkinF.themeMode_btn[5]),
    ComFuc.ComButton("theme_1", "", Vector2(280, 229), Vector2(73, 292), 16, false, false, SkinF.themeMode_btn[1]),
    ComFuc.ComButton("theme_2", "", Vector2(381, 372), Vector2(471, 262), 16, false, false, SkinF.themeMode_btn[2]),
    ComFuc.ComButton("theme_3", "", Vector2(282, 317), Vector2(780, 165), 16, false, false, SkinF.themeMode_btn[3]),
    ComFuc.ComButton("theme_4", "", Vector2(293, 248), Vector2(720, 0), 16, false, false, SkinF.themeMode_btn[4]),
    ComFuc.ComControlAddPt("theme1_particle", Vector2(350, 350), Vector2(73, 175), "scene_practice"),
    ComFuc.ComControlAddPt("theme2_particle", Vector2(381, 372), Vector2(473, 166), "scene_battlefield"),
    ComFuc.ComControlAddPt("theme3_particle", Vector2(282, 317), Vector2(780, 165), "scene_group"),
    ComFuc.ComControlAddPt("theme4_particle", Vector2(293, 248), Vector2(697, -23), "scene_adventure"),
    ComFuc.ComControlAddPt("theme5_particle", Vector2(381, 372), Vector2(300, 0), "scene_adventure"),
    ComFuc.ComControlAddPt("main2_particle", Vector2(1128, 185), Vector2(0, 460), "scene_clouds_2"),
    Gui.Control("theme_tip")({
      Location = Vector2(500, 150),
      Size = totalSize,
      BackgroundColor = colw,
      Skin = SkinF.lookInfo_004,
      Visible = false,
      Gui.Label("theme_text")({
        Location = Vector2(0, 0),
        Size = TextSize,
        TextAlign = "kAlignLeftTop",
        AutoWrap = true,
        FontSize = 15,
        TextColor = ARGB(255, 255, 255, 255),
        Text = GetUTF8Text("UI_battlefield_Instruction_Freestyle_Combat")
      })
    }),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(19, 492), 255, SkinF.battle_026[1], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(646, 561), 255, SkinF.battle_026[2], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(913, 423), 255, SkinF.battle_026[3], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(620, 73), 255, SkinF.battle_026[4], true, false),
    Gui.Control("match_shelter")({
      BackgroundColor = ARGB(0, 0, 0, 0),
      Size = Vector2(130, 200),
      Location = Vector2(1040, 134),
      ComFuc.ComButton("match_1", GetUTF8Text("button_battlefield_fast_matching"), Vector2(130, 140), Vector2(0, -140), 18, false, false, SkinF.battle_033, true)
    })
  }),
  Gui.Control("plane_2")({
    Dock = "kDockFill",
    Gui.Control("mode_out2")({
      Location = Vector2(8, 45),
      Size = Vector2(701, 447),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel(nil, GetUTF8Text("UI_battlefield_Mode_Selection"), Vector2(635, 21), Vector2(4, 3), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComControl(nil, Vector2(631, 98), Vector2(6, 34), 255, SkinF.battle_005),
      Gui.Control("mode_select")({
        Location = Vector2(9, 45),
        Size = Vector2(696, 446),
        BackgroundColor = colw,
        Skin = SkinF.battle_018,
        Gui.Control("mode_sel_host")({
          Location = Vector2(0, -10),
          Size = Vector2(685, 135),
          ComFuc.ComControl("mode_di", Vector2(255, 110), Vector2(69, -3), 255, SkinF.battle_019),
          ComFuc.ComButton("mode_1", nil, Vector2(93, 93), Vector2(72, 22), 0, false, true, SkinF.battle_004[1], false),
          ComFuc.ComButton("mode_2", nil, Vector2(93, 93), Vector2(184, 22), 0, false, true, SkinF.battle_004[3], true),
          ComFuc.ComButton("mode_3", nil, Vector2(93, 93), Vector2(296, 22), 0, false, true, SkinF.battle_004[5], true),
          ComFuc.ComButton("mode_4", nil, Vector2(93, 93), Vector2(408, 22), 0, false, true, SkinF.battle_004[2], true),
          ComFuc.ComButton("mode_5", nil, Vector2(93, 93), Vector2(520, 22), 0, false, true, SkinF.battle_004[4], true),
          ComFuc.ComButton("mode_6", nil, Vector2(93, 93), Vector2(532, 22), 0, false, true, SkinF.battle_004[7], true),
          ComFuc.ComButton("mode_7", nil, Vector2(93, 93), Vector2(532, 22), 0, false, true, SkinF.battle_004[8], true)
        })
      })
    }),
    Gui.Control({
      Size = Vector2(701, 144),
      Location = Vector2(8, 494),
      Gui.NewMessagePanel("msg_panel")({
        Size = Vector2(701, 105),
        BackgroundColor = colw,
        Skin = SkinF.battle_013,
        Style = "LobbyBattleGame.MessagePanel",
        MaxTextWidth = 670,
        OnePageLineNum = 4,
        LineGap = 1
      }),
      Gui.Control({
        Size = Vector2(701, 38),
        Location = Vector2(0, 106),
        BackgroundColor = colw,
        Skin = SkinF.battle_012,
        ComFuc.ComButton("send_btn", GetUTF8Text("button_common_Send"), Vector2(64, 32), Vector2(630, 3), 16, false, false),
        ComFuc.ComTextBox("input_box", "", Vector2(630, 36), Vector2(3, 2), 80)
      })
    }),
    Gui.Control({
      Location = Vector2(713, 45),
      Size = Vector2(405, 586),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel("team_title", GetUTF8Text("UI_common_Team_List"), Vector2(390, 21), Vector2(4, 3), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComIconButton("quit", Vector2(114, 56), Vector2(86, 432), SkinF.icon_playgame_004, GetUTF8Text("button_common_Back"), SkinF.select_character_038, nil),
      ComFuc.ComIconButton("invite", Vector2(114, 56), Vector2(202, 432), SkinF.icon_playgame_005, GetUTF8Text("button_battlefield_additional_string_047"), SkinF.select_character_038, nil),
      ComFuc.ComButton("sys_match", GetUTF8Text("button_common_Start_Auto_Match"), Vector2(234, 88), Vector2(84, 488), 16, false, false, SkinF.battle_021, true),
      ComFuc.ComIcon2Button("sys_ready", Vector2(234, 88), Vector2(84, 488), SkinF.icon_playgame_009, GetUTF8Text("button_battlefield_additional_string_138"), SkinF.SkinStartGame),
      Gui.Control({
        Location = Vector2(10, 34),
        Size = Vector2(385, 398),
        BackgroundColor = colw,
        Skin = SkinF.battle_005,
        Gui.ListTreeView("member_list")({
          Style = "Gui.AvatarListTreeView002",
          ItemGap = 1,
          Size = Vector2(368, 400),
          Location = Vector2(9, 13)
        })
      })
    })
  }),
  Gui.Control("rank_ckeck")({
    Size = Vector2(430, 24),
    Location = Vector2(683, 12),
    ComFuc.ComLabel("add_rankSore_text", GetUTF8Text("msgbox_common_clew_rank_integral_01"), Vector2(400, 24), Vector2(0, 0), 0, 16, colw, "kAlignRightMiddle"),
    ComFuc.ComCheckBox("add_rankSore_cb", nil, Vector2(24, 24), Vector2(406, 0))
  })
})
local HideLobbyGameTime, OnInviteCallback = function()
  if Lobby then
    Lobby.HideGameTime(true)
    if matchType ~= 1 and not isHostMan then
      ComFuc.isReadyStart = true
    end
  end
end, Gui.Control("main")({
  Size = Vector2(1128, 645),
  BackgroundColor = colw,
  Skin = SkinF.game_background,
  Gui.Control("plane_1")({
    Dock = "kDockFill",
    ComFuc.ComControlAddPt("main1_particle", Vector2(1128, 460), Vector2(0, 0), "scene_clouds"),
    ComFuc.ComButton("theme_5", "", Vector2(410, 484), Vector2(313, 0), 16, false, false, SkinF.themeMode_btn[5]),
    ComFuc.ComButton("theme_1", "", Vector2(280, 229), Vector2(73, 292), 16, false, false, SkinF.themeMode_btn[1]),
    ComFuc.ComButton("theme_2", "", Vector2(381, 372), Vector2(471, 262), 16, false, false, SkinF.themeMode_btn[2]),
    ComFuc.ComButton("theme_3", "", Vector2(282, 317), Vector2(780, 165), 16, false, false, SkinF.themeMode_btn[3]),
    ComFuc.ComButton("theme_4", "", Vector2(293, 248), Vector2(720, 0), 16, false, false, SkinF.themeMode_btn[4]),
    ComFuc.ComControlAddPt("theme1_particle", Vector2(350, 350), Vector2(73, 175), "scene_practice"),
    ComFuc.ComControlAddPt("theme2_particle", Vector2(381, 372), Vector2(473, 166), "scene_battlefield"),
    ComFuc.ComControlAddPt("theme3_particle", Vector2(282, 317), Vector2(780, 165), "scene_group"),
    ComFuc.ComControlAddPt("theme4_particle", Vector2(293, 248), Vector2(697, -23), "scene_adventure"),
    ComFuc.ComControlAddPt("theme5_particle", Vector2(381, 372), Vector2(300, 0), "scene_adventure"),
    ComFuc.ComControlAddPt("main2_particle", Vector2(1128, 185), Vector2(0, 460), "scene_clouds_2"),
    Gui.Control("theme_tip")({
      Location = Vector2(500, 150),
      Size = totalSize,
      BackgroundColor = colw,
      Skin = SkinF.lookInfo_004,
      Visible = false,
      Gui.Label("theme_text")({
        Location = Vector2(0, 0),
        Size = TextSize,
        TextAlign = "kAlignLeftTop",
        AutoWrap = true,
        FontSize = 15,
        TextColor = ARGB(255, 255, 255, 255),
        Text = GetUTF8Text("UI_battlefield_Instruction_Freestyle_Combat")
      })
    }),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(19, 492), 255, SkinF.battle_026[1], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(646, 561), 255, SkinF.battle_026[2], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(913, 423), 255, SkinF.battle_026[3], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(620, 73), 255, SkinF.battle_026[4], true, false),
    Gui.Control("match_shelter")({
      BackgroundColor = ARGB(0, 0, 0, 0),
      Size = Vector2(130, 200),
      Location = Vector2(1040, 134),
      ComFuc.ComButton("match_1", GetUTF8Text("button_battlefield_fast_matching"), Vector2(130, 140), Vector2(0, -140), 18, false, false, SkinF.battle_033, true)
    })
  }),
  Gui.Control("plane_2")({
    Dock = "kDockFill",
    Gui.Control("mode_out2")({
      Location = Vector2(8, 45),
      Size = Vector2(701, 447),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel(nil, GetUTF8Text("UI_battlefield_Mode_Selection"), Vector2(635, 21), Vector2(4, 3), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComControl(nil, Vector2(631, 98), Vector2(6, 34), 255, SkinF.battle_005),
      Gui.Control("mode_select")({
        Location = Vector2(9, 45),
        Size = Vector2(696, 446),
        BackgroundColor = colw,
        Skin = SkinF.battle_018,
        Gui.Control("mode_sel_host")({
          Location = Vector2(0, -10),
          Size = Vector2(685, 135),
          ComFuc.ComControl("mode_di", Vector2(255, 110), Vector2(69, -3), 255, SkinF.battle_019),
          ComFuc.ComButton("mode_1", nil, Vector2(93, 93), Vector2(72, 22), 0, false, true, SkinF.battle_004[1], false),
          ComFuc.ComButton("mode_2", nil, Vector2(93, 93), Vector2(184, 22), 0, false, true, SkinF.battle_004[3], true),
          ComFuc.ComButton("mode_3", nil, Vector2(93, 93), Vector2(296, 22), 0, false, true, SkinF.battle_004[5], true),
          ComFuc.ComButton("mode_4", nil, Vector2(93, 93), Vector2(408, 22), 0, false, true, SkinF.battle_004[2], true),
          ComFuc.ComButton("mode_5", nil, Vector2(93, 93), Vector2(520, 22), 0, false, true, SkinF.battle_004[4], true),
          ComFuc.ComButton("mode_6", nil, Vector2(93, 93), Vector2(532, 22), 0, false, true, SkinF.battle_004[7], true),
          ComFuc.ComButton("mode_7", nil, Vector2(93, 93), Vector2(532, 22), 0, false, true, SkinF.battle_004[8], true)
        })
      })
    }),
    Gui.Control({
      Size = Vector2(701, 144),
      Location = Vector2(8, 494),
      Gui.NewMessagePanel("msg_panel")({
        Size = Vector2(701, 105),
        BackgroundColor = colw,
        Skin = SkinF.battle_013,
        Style = "LobbyBattleGame.MessagePanel",
        MaxTextWidth = 670,
        OnePageLineNum = 4,
        LineGap = 1
      }),
      Gui.Control({
        Size = Vector2(701, 38),
        Location = Vector2(0, 106),
        BackgroundColor = colw,
        Skin = SkinF.battle_012,
        ComFuc.ComButton("send_btn", GetUTF8Text("button_common_Send"), Vector2(64, 32), Vector2(630, 3), 16, false, false),
        ComFuc.ComTextBox("input_box", "", Vector2(630, 36), Vector2(3, 2), 80)
      })
    }),
    Gui.Control({
      Location = Vector2(713, 45),
      Size = Vector2(405, 586),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel("team_title", GetUTF8Text("UI_common_Team_List"), Vector2(390, 21), Vector2(4, 3), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComIconButton("quit", Vector2(114, 56), Vector2(86, 432), SkinF.icon_playgame_004, GetUTF8Text("button_common_Back"), SkinF.select_character_038, nil),
      ComFuc.ComIconButton("invite", Vector2(114, 56), Vector2(202, 432), SkinF.icon_playgame_005, GetUTF8Text("button_battlefield_additional_string_047"), SkinF.select_character_038, nil),
      ComFuc.ComButton("sys_match", GetUTF8Text("button_common_Start_Auto_Match"), Vector2(234, 88), Vector2(84, 488), 16, false, false, SkinF.battle_021, true),
      ComFuc.ComIcon2Button("sys_ready", Vector2(234, 88), Vector2(84, 488), SkinF.icon_playgame_009, GetUTF8Text("button_battlefield_additional_string_138"), SkinF.SkinStartGame),
      Gui.Control({
        Location = Vector2(10, 34),
        Size = Vector2(385, 398),
        BackgroundColor = colw,
        Skin = SkinF.battle_005,
        Gui.ListTreeView("member_list")({
          Style = "Gui.AvatarListTreeView002",
          ItemGap = 1,
          Size = Vector2(368, 400),
          Location = Vector2(9, 13)
        })
      })
    })
  }),
  Gui.Control("rank_ckeck")({
    Size = Vector2(430, 24),
    Location = Vector2(683, 12),
    ComFuc.ComLabel("add_rankSore_text", GetUTF8Text("msgbox_common_clew_rank_integral_01"), Vector2(400, 24), Vector2(0, 0), 0, 16, colw, "kAlignRightMiddle"),
    ComFuc.ComCheckBox("add_rankSore_cb", nil, Vector2(24, 24), Vector2(406, 0))
  })
})

function OnInviteCallback(friendArray)
  for k, v in pairs(friendArray) do
    local state = ptr_cast(game.CurrentState, "Client.StateLobby")
    if state then
      state:TeamInvite(friendArray[k].name, themeType)
    end
  end
end

local SelModeClick, SendChatText = function(i)
  SetModeBtnState(i)
  local state = ptr_cast(game.CurrentState, "Client.StateLobby")
  if state and matchType == 2 and themeType == 2 then
    state:RequestTeamChangeGameMode(typeMap2[i], 0, 2)
  end
  if state and matchType == 2 and themeType == 1 then
    state:RequestTeamChangeGameMode(typeMap[i], 0, 1)
  end
  if state and matchType == 3 then
    state:RequestTeamChangeGameMode(typeMap[i], 0, 0)
    BattleGameRoom.SetBattleRoomInfo(i, typeMap[i])
  end
end, function(i)
  SetModeBtnState(i)
  local state = ptr_cast(game.CurrentState, "Client.StateLobby")
  if state and matchType == 2 and themeType == 2 then
    state:RequestTeamChangeGameMode(typeMap2[i], 0, 2)
  end
  if state and matchType == 2 and themeType == 1 then
    state:RequestTeamChangeGameMode(typeMap[i], 0, 1)
  end
  if state and matchType == 3 then
    state:RequestTeamChangeGameMode(typeMap[i], 0, 0)
    BattleGameRoom.SetBattleRoomInfo(i, typeMap[i])
  end
end
local SendChatText, TimerRemove = function()
  if string.len(ui.input_box.Text) > 0 then
    if game.isNoSpeak then
      MessageBox.ShowError(GetUTF8Text("msgbox_social_punish_054_lobby"))
    else
      game:Chat("Team", ui.input_box.Text)
      ui.input_box.Text = ""
    end
  end
end, Gui.Control("main")({
  Size = Vector2(1128, 645),
  BackgroundColor = colw,
  Skin = SkinF.game_background,
  Gui.Control("plane_1")({
    Dock = "kDockFill",
    ComFuc.ComControlAddPt("main1_particle", Vector2(1128, 460), Vector2(0, 0), "scene_clouds"),
    ComFuc.ComButton("theme_5", "", Vector2(410, 484), Vector2(313, 0), 16, false, false, SkinF.themeMode_btn[5]),
    ComFuc.ComButton("theme_1", "", Vector2(280, 229), Vector2(73, 292), 16, false, false, SkinF.themeMode_btn[1]),
    ComFuc.ComButton("theme_2", "", Vector2(381, 372), Vector2(471, 262), 16, false, false, SkinF.themeMode_btn[2]),
    ComFuc.ComButton("theme_3", "", Vector2(282, 317), Vector2(780, 165), 16, false, false, SkinF.themeMode_btn[3]),
    ComFuc.ComButton("theme_4", "", Vector2(293, 248), Vector2(720, 0), 16, false, false, SkinF.themeMode_btn[4]),
    ComFuc.ComControlAddPt("theme1_particle", Vector2(350, 350), Vector2(73, 175), "scene_practice"),
    ComFuc.ComControlAddPt("theme2_particle", Vector2(381, 372), Vector2(473, 166), "scene_battlefield"),
    ComFuc.ComControlAddPt("theme3_particle", Vector2(282, 317), Vector2(780, 165), "scene_group"),
    ComFuc.ComControlAddPt("theme4_particle", Vector2(293, 248), Vector2(697, -23), "scene_adventure"),
    ComFuc.ComControlAddPt("theme5_particle", Vector2(381, 372), Vector2(300, 0), "scene_adventure"),
    ComFuc.ComControlAddPt("main2_particle", Vector2(1128, 185), Vector2(0, 460), "scene_clouds_2"),
    Gui.Control("theme_tip")({
      Location = Vector2(500, 150),
      Size = totalSize,
      BackgroundColor = colw,
      Skin = SkinF.lookInfo_004,
      Visible = false,
      Gui.Label("theme_text")({
        Location = Vector2(0, 0),
        Size = TextSize,
        TextAlign = "kAlignLeftTop",
        AutoWrap = true,
        FontSize = 15,
        TextColor = ARGB(255, 255, 255, 255),
        Text = GetUTF8Text("UI_battlefield_Instruction_Freestyle_Combat")
      })
    }),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(19, 492), 255, SkinF.battle_026[1], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(646, 561), 255, SkinF.battle_026[2], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(913, 423), 255, SkinF.battle_026[3], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(620, 73), 255, SkinF.battle_026[4], true, false),
    Gui.Control("match_shelter")({
      BackgroundColor = ARGB(0, 0, 0, 0),
      Size = Vector2(130, 200),
      Location = Vector2(1040, 134),
      ComFuc.ComButton("match_1", GetUTF8Text("button_battlefield_fast_matching"), Vector2(130, 140), Vector2(0, -140), 18, false, false, SkinF.battle_033, true)
    })
  }),
  Gui.Control("plane_2")({
    Dock = "kDockFill",
    Gui.Control("mode_out2")({
      Location = Vector2(8, 45),
      Size = Vector2(701, 447),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel(nil, GetUTF8Text("UI_battlefield_Mode_Selection"), Vector2(635, 21), Vector2(4, 3), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComControl(nil, Vector2(631, 98), Vector2(6, 34), 255, SkinF.battle_005),
      Gui.Control("mode_select")({
        Location = Vector2(9, 45),
        Size = Vector2(696, 446),
        BackgroundColor = colw,
        Skin = SkinF.battle_018,
        Gui.Control("mode_sel_host")({
          Location = Vector2(0, -10),
          Size = Vector2(685, 135),
          ComFuc.ComControl("mode_di", Vector2(255, 110), Vector2(69, -3), 255, SkinF.battle_019),
          ComFuc.ComButton("mode_1", nil, Vector2(93, 93), Vector2(72, 22), 0, false, true, SkinF.battle_004[1], false),
          ComFuc.ComButton("mode_2", nil, Vector2(93, 93), Vector2(184, 22), 0, false, true, SkinF.battle_004[3], true),
          ComFuc.ComButton("mode_3", nil, Vector2(93, 93), Vector2(296, 22), 0, false, true, SkinF.battle_004[5], true),
          ComFuc.ComButton("mode_4", nil, Vector2(93, 93), Vector2(408, 22), 0, false, true, SkinF.battle_004[2], true),
          ComFuc.ComButton("mode_5", nil, Vector2(93, 93), Vector2(520, 22), 0, false, true, SkinF.battle_004[4], true),
          ComFuc.ComButton("mode_6", nil, Vector2(93, 93), Vector2(532, 22), 0, false, true, SkinF.battle_004[7], true),
          ComFuc.ComButton("mode_7", nil, Vector2(93, 93), Vector2(532, 22), 0, false, true, SkinF.battle_004[8], true)
        })
      })
    }),
    Gui.Control({
      Size = Vector2(701, 144),
      Location = Vector2(8, 494),
      Gui.NewMessagePanel("msg_panel")({
        Size = Vector2(701, 105),
        BackgroundColor = colw,
        Skin = SkinF.battle_013,
        Style = "LobbyBattleGame.MessagePanel",
        MaxTextWidth = 670,
        OnePageLineNum = 4,
        LineGap = 1
      }),
      Gui.Control({
        Size = Vector2(701, 38),
        Location = Vector2(0, 106),
        BackgroundColor = colw,
        Skin = SkinF.battle_012,
        ComFuc.ComButton("send_btn", GetUTF8Text("button_common_Send"), Vector2(64, 32), Vector2(630, 3), 16, false, false),
        ComFuc.ComTextBox("input_box", "", Vector2(630, 36), Vector2(3, 2), 80)
      })
    }),
    Gui.Control({
      Location = Vector2(713, 45),
      Size = Vector2(405, 586),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel("team_title", GetUTF8Text("UI_common_Team_List"), Vector2(390, 21), Vector2(4, 3), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComIconButton("quit", Vector2(114, 56), Vector2(86, 432), SkinF.icon_playgame_004, GetUTF8Text("button_common_Back"), SkinF.select_character_038, nil),
      ComFuc.ComIconButton("invite", Vector2(114, 56), Vector2(202, 432), SkinF.icon_playgame_005, GetUTF8Text("button_battlefield_additional_string_047"), SkinF.select_character_038, nil),
      ComFuc.ComButton("sys_match", GetUTF8Text("button_common_Start_Auto_Match"), Vector2(234, 88), Vector2(84, 488), 16, false, false, SkinF.battle_021, true),
      ComFuc.ComIcon2Button("sys_ready", Vector2(234, 88), Vector2(84, 488), SkinF.icon_playgame_009, GetUTF8Text("button_battlefield_additional_string_138"), SkinF.SkinStartGame),
      Gui.Control({
        Location = Vector2(10, 34),
        Size = Vector2(385, 398),
        BackgroundColor = colw,
        Skin = SkinF.battle_005,
        Gui.ListTreeView("member_list")({
          Style = "Gui.AvatarListTreeView002",
          ItemGap = 1,
          Size = Vector2(368, 400),
          Location = Vector2(9, 13)
        })
      })
    })
  }),
  Gui.Control("rank_ckeck")({
    Size = Vector2(430, 24),
    Location = Vector2(683, 12),
    ComFuc.ComLabel("add_rankSore_text", GetUTF8Text("msgbox_common_clew_rank_integral_01"), Vector2(400, 24), Vector2(0, 0), 0, 16, colw, "kAlignRightMiddle"),
    ComFuc.ComCheckBox("add_rankSore_cb", nil, Vector2(24, 24), Vector2(406, 0))
  })
})
local TimerRemove, TimerRefresh = function()
  if timer then
    game.TimerMgr:RemoveTimer(timer)
    timer = nil
  end
end, Gui.Control("main")({
  Size = Vector2(1128, 645),
  BackgroundColor = colw,
  Skin = SkinF.game_background,
  Gui.Control("plane_1")({
    Dock = "kDockFill",
    ComFuc.ComControlAddPt("main1_particle", Vector2(1128, 460), Vector2(0, 0), "scene_clouds"),
    ComFuc.ComButton("theme_5", "", Vector2(410, 484), Vector2(313, 0), 16, false, false, SkinF.themeMode_btn[5]),
    ComFuc.ComButton("theme_1", "", Vector2(280, 229), Vector2(73, 292), 16, false, false, SkinF.themeMode_btn[1]),
    ComFuc.ComButton("theme_2", "", Vector2(381, 372), Vector2(471, 262), 16, false, false, SkinF.themeMode_btn[2]),
    ComFuc.ComButton("theme_3", "", Vector2(282, 317), Vector2(780, 165), 16, false, false, SkinF.themeMode_btn[3]),
    ComFuc.ComButton("theme_4", "", Vector2(293, 248), Vector2(720, 0), 16, false, false, SkinF.themeMode_btn[4]),
    ComFuc.ComControlAddPt("theme1_particle", Vector2(350, 350), Vector2(73, 175), "scene_practice"),
    ComFuc.ComControlAddPt("theme2_particle", Vector2(381, 372), Vector2(473, 166), "scene_battlefield"),
    ComFuc.ComControlAddPt("theme3_particle", Vector2(282, 317), Vector2(780, 165), "scene_group"),
    ComFuc.ComControlAddPt("theme4_particle", Vector2(293, 248), Vector2(697, -23), "scene_adventure"),
    ComFuc.ComControlAddPt("theme5_particle", Vector2(381, 372), Vector2(300, 0), "scene_adventure"),
    ComFuc.ComControlAddPt("main2_particle", Vector2(1128, 185), Vector2(0, 460), "scene_clouds_2"),
    Gui.Control("theme_tip")({
      Location = Vector2(500, 150),
      Size = totalSize,
      BackgroundColor = colw,
      Skin = SkinF.lookInfo_004,
      Visible = false,
      Gui.Label("theme_text")({
        Location = Vector2(0, 0),
        Size = TextSize,
        TextAlign = "kAlignLeftTop",
        AutoWrap = true,
        FontSize = 15,
        TextColor = ARGB(255, 255, 255, 255),
        Text = GetUTF8Text("UI_battlefield_Instruction_Freestyle_Combat")
      })
    }),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(19, 492), 255, SkinF.battle_026[1], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(646, 561), 255, SkinF.battle_026[2], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(913, 423), 255, SkinF.battle_026[3], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(620, 73), 255, SkinF.battle_026[4], true, false),
    Gui.Control("match_shelter")({
      BackgroundColor = ARGB(0, 0, 0, 0),
      Size = Vector2(130, 200),
      Location = Vector2(1040, 134),
      ComFuc.ComButton("match_1", GetUTF8Text("button_battlefield_fast_matching"), Vector2(130, 140), Vector2(0, -140), 18, false, false, SkinF.battle_033, true)
    })
  }),
  Gui.Control("plane_2")({
    Dock = "kDockFill",
    Gui.Control("mode_out2")({
      Location = Vector2(8, 45),
      Size = Vector2(701, 447),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel(nil, GetUTF8Text("UI_battlefield_Mode_Selection"), Vector2(635, 21), Vector2(4, 3), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComControl(nil, Vector2(631, 98), Vector2(6, 34), 255, SkinF.battle_005),
      Gui.Control("mode_select")({
        Location = Vector2(9, 45),
        Size = Vector2(696, 446),
        BackgroundColor = colw,
        Skin = SkinF.battle_018,
        Gui.Control("mode_sel_host")({
          Location = Vector2(0, -10),
          Size = Vector2(685, 135),
          ComFuc.ComControl("mode_di", Vector2(255, 110), Vector2(69, -3), 255, SkinF.battle_019),
          ComFuc.ComButton("mode_1", nil, Vector2(93, 93), Vector2(72, 22), 0, false, true, SkinF.battle_004[1], false),
          ComFuc.ComButton("mode_2", nil, Vector2(93, 93), Vector2(184, 22), 0, false, true, SkinF.battle_004[3], true),
          ComFuc.ComButton("mode_3", nil, Vector2(93, 93), Vector2(296, 22), 0, false, true, SkinF.battle_004[5], true),
          ComFuc.ComButton("mode_4", nil, Vector2(93, 93), Vector2(408, 22), 0, false, true, SkinF.battle_004[2], true),
          ComFuc.ComButton("mode_5", nil, Vector2(93, 93), Vector2(520, 22), 0, false, true, SkinF.battle_004[4], true),
          ComFuc.ComButton("mode_6", nil, Vector2(93, 93), Vector2(532, 22), 0, false, true, SkinF.battle_004[7], true),
          ComFuc.ComButton("mode_7", nil, Vector2(93, 93), Vector2(532, 22), 0, false, true, SkinF.battle_004[8], true)
        })
      })
    }),
    Gui.Control({
      Size = Vector2(701, 144),
      Location = Vector2(8, 494),
      Gui.NewMessagePanel("msg_panel")({
        Size = Vector2(701, 105),
        BackgroundColor = colw,
        Skin = SkinF.battle_013,
        Style = "LobbyBattleGame.MessagePanel",
        MaxTextWidth = 670,
        OnePageLineNum = 4,
        LineGap = 1
      }),
      Gui.Control({
        Size = Vector2(701, 38),
        Location = Vector2(0, 106),
        BackgroundColor = colw,
        Skin = SkinF.battle_012,
        ComFuc.ComButton("send_btn", GetUTF8Text("button_common_Send"), Vector2(64, 32), Vector2(630, 3), 16, false, false),
        ComFuc.ComTextBox("input_box", "", Vector2(630, 36), Vector2(3, 2), 80)
      })
    }),
    Gui.Control({
      Location = Vector2(713, 45),
      Size = Vector2(405, 586),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel("team_title", GetUTF8Text("UI_common_Team_List"), Vector2(390, 21), Vector2(4, 3), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComIconButton("quit", Vector2(114, 56), Vector2(86, 432), SkinF.icon_playgame_004, GetUTF8Text("button_common_Back"), SkinF.select_character_038, nil),
      ComFuc.ComIconButton("invite", Vector2(114, 56), Vector2(202, 432), SkinF.icon_playgame_005, GetUTF8Text("button_battlefield_additional_string_047"), SkinF.select_character_038, nil),
      ComFuc.ComButton("sys_match", GetUTF8Text("button_common_Start_Auto_Match"), Vector2(234, 88), Vector2(84, 488), 16, false, false, SkinF.battle_021, true),
      ComFuc.ComIcon2Button("sys_ready", Vector2(234, 88), Vector2(84, 488), SkinF.icon_playgame_009, GetUTF8Text("button_battlefield_additional_string_138"), SkinF.SkinStartGame),
      Gui.Control({
        Location = Vector2(10, 34),
        Size = Vector2(385, 398),
        BackgroundColor = colw,
        Skin = SkinF.battle_005,
        Gui.ListTreeView("member_list")({
          Style = "Gui.AvatarListTreeView002",
          ItemGap = 1,
          Size = Vector2(368, 400),
          Location = Vector2(9, 13)
        })
      })
    })
  }),
  Gui.Control("rank_ckeck")({
    Size = Vector2(430, 24),
    Location = Vector2(683, 12),
    ComFuc.ComLabel("add_rankSore_text", GetUTF8Text("msgbox_common_clew_rank_integral_01"), Vector2(400, 24), Vector2(0, 0), 0, 16, colw, "kAlignRightMiddle"),
    ComFuc.ComCheckBox("add_rankSore_cb", nil, Vector2(24, 24), Vector2(406, 0))
  })
})
local TimerRefresh, StartMatching = function()
  Lobby.ShowMatchGameCount(peopleCount, needPeople)
  if not timer then
    timer = game.TimerMgr:AddTimer(1)
    
    function timer.EventOnTimer(sender, e)
      local state = ptr_cast(game.CurrentState, "Client.StateLobby")
      if state then
        state:RequestMatchingProgress()
      else
        TimerRemove()
      end
    end
  end
end, Gui.Control("main")({
  Size = Vector2(1128, 645),
  BackgroundColor = colw,
  Skin = SkinF.game_background,
  Gui.Control("plane_1")({
    Dock = "kDockFill",
    ComFuc.ComControlAddPt("main1_particle", Vector2(1128, 460), Vector2(0, 0), "scene_clouds"),
    ComFuc.ComButton("theme_5", "", Vector2(410, 484), Vector2(313, 0), 16, false, false, SkinF.themeMode_btn[5]),
    ComFuc.ComButton("theme_1", "", Vector2(280, 229), Vector2(73, 292), 16, false, false, SkinF.themeMode_btn[1]),
    ComFuc.ComButton("theme_2", "", Vector2(381, 372), Vector2(471, 262), 16, false, false, SkinF.themeMode_btn[2]),
    ComFuc.ComButton("theme_3", "", Vector2(282, 317), Vector2(780, 165), 16, false, false, SkinF.themeMode_btn[3]),
    ComFuc.ComButton("theme_4", "", Vector2(293, 248), Vector2(720, 0), 16, false, false, SkinF.themeMode_btn[4]),
    ComFuc.ComControlAddPt("theme1_particle", Vector2(350, 350), Vector2(73, 175), "scene_practice"),
    ComFuc.ComControlAddPt("theme2_particle", Vector2(381, 372), Vector2(473, 166), "scene_battlefield"),
    ComFuc.ComControlAddPt("theme3_particle", Vector2(282, 317), Vector2(780, 165), "scene_group"),
    ComFuc.ComControlAddPt("theme4_particle", Vector2(293, 248), Vector2(697, -23), "scene_adventure"),
    ComFuc.ComControlAddPt("theme5_particle", Vector2(381, 372), Vector2(300, 0), "scene_adventure"),
    ComFuc.ComControlAddPt("main2_particle", Vector2(1128, 185), Vector2(0, 460), "scene_clouds_2"),
    Gui.Control("theme_tip")({
      Location = Vector2(500, 150),
      Size = totalSize,
      BackgroundColor = colw,
      Skin = SkinF.lookInfo_004,
      Visible = false,
      Gui.Label("theme_text")({
        Location = Vector2(0, 0),
        Size = TextSize,
        TextAlign = "kAlignLeftTop",
        AutoWrap = true,
        FontSize = 15,
        TextColor = ARGB(255, 255, 255, 255),
        Text = GetUTF8Text("UI_battlefield_Instruction_Freestyle_Combat")
      })
    }),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(19, 492), 255, SkinF.battle_026[1], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(646, 561), 255, SkinF.battle_026[2], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(913, 423), 255, SkinF.battle_026[3], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(620, 73), 255, SkinF.battle_026[4], true, false),
    Gui.Control("match_shelter")({
      BackgroundColor = ARGB(0, 0, 0, 0),
      Size = Vector2(130, 200),
      Location = Vector2(1040, 134),
      ComFuc.ComButton("match_1", GetUTF8Text("button_battlefield_fast_matching"), Vector2(130, 140), Vector2(0, -140), 18, false, false, SkinF.battle_033, true)
    })
  }),
  Gui.Control("plane_2")({
    Dock = "kDockFill",
    Gui.Control("mode_out2")({
      Location = Vector2(8, 45),
      Size = Vector2(701, 447),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel(nil, GetUTF8Text("UI_battlefield_Mode_Selection"), Vector2(635, 21), Vector2(4, 3), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComControl(nil, Vector2(631, 98), Vector2(6, 34), 255, SkinF.battle_005),
      Gui.Control("mode_select")({
        Location = Vector2(9, 45),
        Size = Vector2(696, 446),
        BackgroundColor = colw,
        Skin = SkinF.battle_018,
        Gui.Control("mode_sel_host")({
          Location = Vector2(0, -10),
          Size = Vector2(685, 135),
          ComFuc.ComControl("mode_di", Vector2(255, 110), Vector2(69, -3), 255, SkinF.battle_019),
          ComFuc.ComButton("mode_1", nil, Vector2(93, 93), Vector2(72, 22), 0, false, true, SkinF.battle_004[1], false),
          ComFuc.ComButton("mode_2", nil, Vector2(93, 93), Vector2(184, 22), 0, false, true, SkinF.battle_004[3], true),
          ComFuc.ComButton("mode_3", nil, Vector2(93, 93), Vector2(296, 22), 0, false, true, SkinF.battle_004[5], true),
          ComFuc.ComButton("mode_4", nil, Vector2(93, 93), Vector2(408, 22), 0, false, true, SkinF.battle_004[2], true),
          ComFuc.ComButton("mode_5", nil, Vector2(93, 93), Vector2(520, 22), 0, false, true, SkinF.battle_004[4], true),
          ComFuc.ComButton("mode_6", nil, Vector2(93, 93), Vector2(532, 22), 0, false, true, SkinF.battle_004[7], true),
          ComFuc.ComButton("mode_7", nil, Vector2(93, 93), Vector2(532, 22), 0, false, true, SkinF.battle_004[8], true)
        })
      })
    }),
    Gui.Control({
      Size = Vector2(701, 144),
      Location = Vector2(8, 494),
      Gui.NewMessagePanel("msg_panel")({
        Size = Vector2(701, 105),
        BackgroundColor = colw,
        Skin = SkinF.battle_013,
        Style = "LobbyBattleGame.MessagePanel",
        MaxTextWidth = 670,
        OnePageLineNum = 4,
        LineGap = 1
      }),
      Gui.Control({
        Size = Vector2(701, 38),
        Location = Vector2(0, 106),
        BackgroundColor = colw,
        Skin = SkinF.battle_012,
        ComFuc.ComButton("send_btn", GetUTF8Text("button_common_Send"), Vector2(64, 32), Vector2(630, 3), 16, false, false),
        ComFuc.ComTextBox("input_box", "", Vector2(630, 36), Vector2(3, 2), 80)
      })
    }),
    Gui.Control({
      Location = Vector2(713, 45),
      Size = Vector2(405, 586),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel("team_title", GetUTF8Text("UI_common_Team_List"), Vector2(390, 21), Vector2(4, 3), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComIconButton("quit", Vector2(114, 56), Vector2(86, 432), SkinF.icon_playgame_004, GetUTF8Text("button_common_Back"), SkinF.select_character_038, nil),
      ComFuc.ComIconButton("invite", Vector2(114, 56), Vector2(202, 432), SkinF.icon_playgame_005, GetUTF8Text("button_battlefield_additional_string_047"), SkinF.select_character_038, nil),
      ComFuc.ComButton("sys_match", GetUTF8Text("button_common_Start_Auto_Match"), Vector2(234, 88), Vector2(84, 488), 16, false, false, SkinF.battle_021, true),
      ComFuc.ComIcon2Button("sys_ready", Vector2(234, 88), Vector2(84, 488), SkinF.icon_playgame_009, GetUTF8Text("button_battlefield_additional_string_138"), SkinF.SkinStartGame),
      Gui.Control({
        Location = Vector2(10, 34),
        Size = Vector2(385, 398),
        BackgroundColor = colw,
        Skin = SkinF.battle_005,
        Gui.ListTreeView("member_list")({
          Style = "Gui.AvatarListTreeView002",
          ItemGap = 1,
          Size = Vector2(368, 400),
          Location = Vector2(9, 13)
        })
      })
    })
  }),
  Gui.Control("rank_ckeck")({
    Size = Vector2(430, 24),
    Location = Vector2(683, 12),
    ComFuc.ComLabel("add_rankSore_text", GetUTF8Text("msgbox_common_clew_rank_integral_01"), Vector2(400, 24), Vector2(0, 0), 0, 16, colw, "kAlignRightMiddle"),
    ComFuc.ComCheckBox("add_rankSore_cb", nil, Vector2(24, 24), Vector2(406, 0))
  })
})
local StartMatching, ReMatchGame = function()
  if matchType ~= 1 then
    if not matching_game_can_begin then
      MessageBox.ShowError(GetUTF8Text("msgbox_lobby_noready_start01"))
      return
    end
    for i = 1, 8 do
      local item = ptr_cast(memDt[i])
      local client_info = ptr_cast(item.Tag, "Client.ClientInfo")
      if client_info and client_info.in_game == true then
        MessageBox.ShowError(GetUTF8Text("msgbox_battlefield_additional_string_050"))
        return
      end
    end
  end
  local game_mode_select = 0
  local typeMap_list = {}
  local state = ptr_cast(game.CurrentState, "Client.StateLobby")
  local match_type = 0
  if matchType == 1 then
    game_mode_select = 1
    typeMap_list = typeMap
    match_type = 0
  elseif matchType == 2 and themeType == 2 then
    game_mode_select = gameType
    typeMap_list = typeMap2
    match_type = 2
  else
    game_mode_select = gameType
    typeMap_list = typeMap
    match_type = 1
  end
  if state and state:MatchingGame(typeMap_list[game_mode_select], match_type) then
    SetMatchButtonState(true)
    SetModeBtnEnable()
    TimerRefresh()
  end
end, Gui.Control("main")({
  Size = Vector2(1128, 645),
  BackgroundColor = colw,
  Skin = SkinF.game_background,
  Gui.Control("plane_1")({
    Dock = "kDockFill",
    ComFuc.ComControlAddPt("main1_particle", Vector2(1128, 460), Vector2(0, 0), "scene_clouds"),
    ComFuc.ComButton("theme_5", "", Vector2(410, 484), Vector2(313, 0), 16, false, false, SkinF.themeMode_btn[5]),
    ComFuc.ComButton("theme_1", "", Vector2(280, 229), Vector2(73, 292), 16, false, false, SkinF.themeMode_btn[1]),
    ComFuc.ComButton("theme_2", "", Vector2(381, 372), Vector2(471, 262), 16, false, false, SkinF.themeMode_btn[2]),
    ComFuc.ComButton("theme_3", "", Vector2(282, 317), Vector2(780, 165), 16, false, false, SkinF.themeMode_btn[3]),
    ComFuc.ComButton("theme_4", "", Vector2(293, 248), Vector2(720, 0), 16, false, false, SkinF.themeMode_btn[4]),
    ComFuc.ComControlAddPt("theme1_particle", Vector2(350, 350), Vector2(73, 175), "scene_practice"),
    ComFuc.ComControlAddPt("theme2_particle", Vector2(381, 372), Vector2(473, 166), "scene_battlefield"),
    ComFuc.ComControlAddPt("theme3_particle", Vector2(282, 317), Vector2(780, 165), "scene_group"),
    ComFuc.ComControlAddPt("theme4_particle", Vector2(293, 248), Vector2(697, -23), "scene_adventure"),
    ComFuc.ComControlAddPt("theme5_particle", Vector2(381, 372), Vector2(300, 0), "scene_adventure"),
    ComFuc.ComControlAddPt("main2_particle", Vector2(1128, 185), Vector2(0, 460), "scene_clouds_2"),
    Gui.Control("theme_tip")({
      Location = Vector2(500, 150),
      Size = totalSize,
      BackgroundColor = colw,
      Skin = SkinF.lookInfo_004,
      Visible = false,
      Gui.Label("theme_text")({
        Location = Vector2(0, 0),
        Size = TextSize,
        TextAlign = "kAlignLeftTop",
        AutoWrap = true,
        FontSize = 15,
        TextColor = ARGB(255, 255, 255, 255),
        Text = GetUTF8Text("UI_battlefield_Instruction_Freestyle_Combat")
      })
    }),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(19, 492), 255, SkinF.battle_026[1], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(646, 561), 255, SkinF.battle_026[2], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(913, 423), 255, SkinF.battle_026[3], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(620, 73), 255, SkinF.battle_026[4], true, false),
    Gui.Control("match_shelter")({
      BackgroundColor = ARGB(0, 0, 0, 0),
      Size = Vector2(130, 200),
      Location = Vector2(1040, 134),
      ComFuc.ComButton("match_1", GetUTF8Text("button_battlefield_fast_matching"), Vector2(130, 140), Vector2(0, -140), 18, false, false, SkinF.battle_033, true)
    })
  }),
  Gui.Control("plane_2")({
    Dock = "kDockFill",
    Gui.Control("mode_out2")({
      Location = Vector2(8, 45),
      Size = Vector2(701, 447),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel(nil, GetUTF8Text("UI_battlefield_Mode_Selection"), Vector2(635, 21), Vector2(4, 3), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComControl(nil, Vector2(631, 98), Vector2(6, 34), 255, SkinF.battle_005),
      Gui.Control("mode_select")({
        Location = Vector2(9, 45),
        Size = Vector2(696, 446),
        BackgroundColor = colw,
        Skin = SkinF.battle_018,
        Gui.Control("mode_sel_host")({
          Location = Vector2(0, -10),
          Size = Vector2(685, 135),
          ComFuc.ComControl("mode_di", Vector2(255, 110), Vector2(69, -3), 255, SkinF.battle_019),
          ComFuc.ComButton("mode_1", nil, Vector2(93, 93), Vector2(72, 22), 0, false, true, SkinF.battle_004[1], false),
          ComFuc.ComButton("mode_2", nil, Vector2(93, 93), Vector2(184, 22), 0, false, true, SkinF.battle_004[3], true),
          ComFuc.ComButton("mode_3", nil, Vector2(93, 93), Vector2(296, 22), 0, false, true, SkinF.battle_004[5], true),
          ComFuc.ComButton("mode_4", nil, Vector2(93, 93), Vector2(408, 22), 0, false, true, SkinF.battle_004[2], true),
          ComFuc.ComButton("mode_5", nil, Vector2(93, 93), Vector2(520, 22), 0, false, true, SkinF.battle_004[4], true),
          ComFuc.ComButton("mode_6", nil, Vector2(93, 93), Vector2(532, 22), 0, false, true, SkinF.battle_004[7], true),
          ComFuc.ComButton("mode_7", nil, Vector2(93, 93), Vector2(532, 22), 0, false, true, SkinF.battle_004[8], true)
        })
      })
    }),
    Gui.Control({
      Size = Vector2(701, 144),
      Location = Vector2(8, 494),
      Gui.NewMessagePanel("msg_panel")({
        Size = Vector2(701, 105),
        BackgroundColor = colw,
        Skin = SkinF.battle_013,
        Style = "LobbyBattleGame.MessagePanel",
        MaxTextWidth = 670,
        OnePageLineNum = 4,
        LineGap = 1
      }),
      Gui.Control({
        Size = Vector2(701, 38),
        Location = Vector2(0, 106),
        BackgroundColor = colw,
        Skin = SkinF.battle_012,
        ComFuc.ComButton("send_btn", GetUTF8Text("button_common_Send"), Vector2(64, 32), Vector2(630, 3), 16, false, false),
        ComFuc.ComTextBox("input_box", "", Vector2(630, 36), Vector2(3, 2), 80)
      })
    }),
    Gui.Control({
      Location = Vector2(713, 45),
      Size = Vector2(405, 586),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel("team_title", GetUTF8Text("UI_common_Team_List"), Vector2(390, 21), Vector2(4, 3), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComIconButton("quit", Vector2(114, 56), Vector2(86, 432), SkinF.icon_playgame_004, GetUTF8Text("button_common_Back"), SkinF.select_character_038, nil),
      ComFuc.ComIconButton("invite", Vector2(114, 56), Vector2(202, 432), SkinF.icon_playgame_005, GetUTF8Text("button_battlefield_additional_string_047"), SkinF.select_character_038, nil),
      ComFuc.ComButton("sys_match", GetUTF8Text("button_common_Start_Auto_Match"), Vector2(234, 88), Vector2(84, 488), 16, false, false, SkinF.battle_021, true),
      ComFuc.ComIcon2Button("sys_ready", Vector2(234, 88), Vector2(84, 488), SkinF.icon_playgame_009, GetUTF8Text("button_battlefield_additional_string_138"), SkinF.SkinStartGame),
      Gui.Control({
        Location = Vector2(10, 34),
        Size = Vector2(385, 398),
        BackgroundColor = colw,
        Skin = SkinF.battle_005,
        Gui.ListTreeView("member_list")({
          Style = "Gui.AvatarListTreeView002",
          ItemGap = 1,
          Size = Vector2(368, 400),
          Location = Vector2(9, 13)
        })
      })
    })
  }),
  Gui.Control("rank_ckeck")({
    Size = Vector2(430, 24),
    Location = Vector2(683, 12),
    ComFuc.ComLabel("add_rankSore_text", GetUTF8Text("msgbox_common_clew_rank_integral_01"), Vector2(400, 24), Vector2(0, 0), 0, 16, colw, "kAlignRightMiddle"),
    ComFuc.ComCheckBox("add_rankSore_cb", nil, Vector2(24, 24), Vector2(406, 0))
  })
})
local ReMatchGame, StopMatching = function()
  SetMatchButtonState(false)
  LobbyBoxContern.CloseClockTimer()
  SetMatchButtonState(true)
  StartMatching()
end, Gui.Control("main")({
  Size = Vector2(1128, 645),
  BackgroundColor = colw,
  Skin = SkinF.game_background,
  Gui.Control("plane_1")({
    Dock = "kDockFill",
    ComFuc.ComControlAddPt("main1_particle", Vector2(1128, 460), Vector2(0, 0), "scene_clouds"),
    ComFuc.ComButton("theme_5", "", Vector2(410, 484), Vector2(313, 0), 16, false, false, SkinF.themeMode_btn[5]),
    ComFuc.ComButton("theme_1", "", Vector2(280, 229), Vector2(73, 292), 16, false, false, SkinF.themeMode_btn[1]),
    ComFuc.ComButton("theme_2", "", Vector2(381, 372), Vector2(471, 262), 16, false, false, SkinF.themeMode_btn[2]),
    ComFuc.ComButton("theme_3", "", Vector2(282, 317), Vector2(780, 165), 16, false, false, SkinF.themeMode_btn[3]),
    ComFuc.ComButton("theme_4", "", Vector2(293, 248), Vector2(720, 0), 16, false, false, SkinF.themeMode_btn[4]),
    ComFuc.ComControlAddPt("theme1_particle", Vector2(350, 350), Vector2(73, 175), "scene_practice"),
    ComFuc.ComControlAddPt("theme2_particle", Vector2(381, 372), Vector2(473, 166), "scene_battlefield"),
    ComFuc.ComControlAddPt("theme3_particle", Vector2(282, 317), Vector2(780, 165), "scene_group"),
    ComFuc.ComControlAddPt("theme4_particle", Vector2(293, 248), Vector2(697, -23), "scene_adventure"),
    ComFuc.ComControlAddPt("theme5_particle", Vector2(381, 372), Vector2(300, 0), "scene_adventure"),
    ComFuc.ComControlAddPt("main2_particle", Vector2(1128, 185), Vector2(0, 460), "scene_clouds_2"),
    Gui.Control("theme_tip")({
      Location = Vector2(500, 150),
      Size = totalSize,
      BackgroundColor = colw,
      Skin = SkinF.lookInfo_004,
      Visible = false,
      Gui.Label("theme_text")({
        Location = Vector2(0, 0),
        Size = TextSize,
        TextAlign = "kAlignLeftTop",
        AutoWrap = true,
        FontSize = 15,
        TextColor = ARGB(255, 255, 255, 255),
        Text = GetUTF8Text("UI_battlefield_Instruction_Freestyle_Combat")
      })
    }),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(19, 492), 255, SkinF.battle_026[1], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(646, 561), 255, SkinF.battle_026[2], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(913, 423), 255, SkinF.battle_026[3], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(620, 73), 255, SkinF.battle_026[4], true, false),
    Gui.Control("match_shelter")({
      BackgroundColor = ARGB(0, 0, 0, 0),
      Size = Vector2(130, 200),
      Location = Vector2(1040, 134),
      ComFuc.ComButton("match_1", GetUTF8Text("button_battlefield_fast_matching"), Vector2(130, 140), Vector2(0, -140), 18, false, false, SkinF.battle_033, true)
    })
  }),
  Gui.Control("plane_2")({
    Dock = "kDockFill",
    Gui.Control("mode_out2")({
      Location = Vector2(8, 45),
      Size = Vector2(701, 447),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel(nil, GetUTF8Text("UI_battlefield_Mode_Selection"), Vector2(635, 21), Vector2(4, 3), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComControl(nil, Vector2(631, 98), Vector2(6, 34), 255, SkinF.battle_005),
      Gui.Control("mode_select")({
        Location = Vector2(9, 45),
        Size = Vector2(696, 446),
        BackgroundColor = colw,
        Skin = SkinF.battle_018,
        Gui.Control("mode_sel_host")({
          Location = Vector2(0, -10),
          Size = Vector2(685, 135),
          ComFuc.ComControl("mode_di", Vector2(255, 110), Vector2(69, -3), 255, SkinF.battle_019),
          ComFuc.ComButton("mode_1", nil, Vector2(93, 93), Vector2(72, 22), 0, false, true, SkinF.battle_004[1], false),
          ComFuc.ComButton("mode_2", nil, Vector2(93, 93), Vector2(184, 22), 0, false, true, SkinF.battle_004[3], true),
          ComFuc.ComButton("mode_3", nil, Vector2(93, 93), Vector2(296, 22), 0, false, true, SkinF.battle_004[5], true),
          ComFuc.ComButton("mode_4", nil, Vector2(93, 93), Vector2(408, 22), 0, false, true, SkinF.battle_004[2], true),
          ComFuc.ComButton("mode_5", nil, Vector2(93, 93), Vector2(520, 22), 0, false, true, SkinF.battle_004[4], true),
          ComFuc.ComButton("mode_6", nil, Vector2(93, 93), Vector2(532, 22), 0, false, true, SkinF.battle_004[7], true),
          ComFuc.ComButton("mode_7", nil, Vector2(93, 93), Vector2(532, 22), 0, false, true, SkinF.battle_004[8], true)
        })
      })
    }),
    Gui.Control({
      Size = Vector2(701, 144),
      Location = Vector2(8, 494),
      Gui.NewMessagePanel("msg_panel")({
        Size = Vector2(701, 105),
        BackgroundColor = colw,
        Skin = SkinF.battle_013,
        Style = "LobbyBattleGame.MessagePanel",
        MaxTextWidth = 670,
        OnePageLineNum = 4,
        LineGap = 1
      }),
      Gui.Control({
        Size = Vector2(701, 38),
        Location = Vector2(0, 106),
        BackgroundColor = colw,
        Skin = SkinF.battle_012,
        ComFuc.ComButton("send_btn", GetUTF8Text("button_common_Send"), Vector2(64, 32), Vector2(630, 3), 16, false, false),
        ComFuc.ComTextBox("input_box", "", Vector2(630, 36), Vector2(3, 2), 80)
      })
    }),
    Gui.Control({
      Location = Vector2(713, 45),
      Size = Vector2(405, 586),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel("team_title", GetUTF8Text("UI_common_Team_List"), Vector2(390, 21), Vector2(4, 3), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComIconButton("quit", Vector2(114, 56), Vector2(86, 432), SkinF.icon_playgame_004, GetUTF8Text("button_common_Back"), SkinF.select_character_038, nil),
      ComFuc.ComIconButton("invite", Vector2(114, 56), Vector2(202, 432), SkinF.icon_playgame_005, GetUTF8Text("button_battlefield_additional_string_047"), SkinF.select_character_038, nil),
      ComFuc.ComButton("sys_match", GetUTF8Text("button_common_Start_Auto_Match"), Vector2(234, 88), Vector2(84, 488), 16, false, false, SkinF.battle_021, true),
      ComFuc.ComIcon2Button("sys_ready", Vector2(234, 88), Vector2(84, 488), SkinF.icon_playgame_009, GetUTF8Text("button_battlefield_additional_string_138"), SkinF.SkinStartGame),
      Gui.Control({
        Location = Vector2(10, 34),
        Size = Vector2(385, 398),
        BackgroundColor = colw,
        Skin = SkinF.battle_005,
        Gui.ListTreeView("member_list")({
          Style = "Gui.AvatarListTreeView002",
          ItemGap = 1,
          Size = Vector2(368, 400),
          Location = Vector2(9, 13)
        })
      })
    })
  }),
  Gui.Control("rank_ckeck")({
    Size = Vector2(430, 24),
    Location = Vector2(683, 12),
    ComFuc.ComLabel("add_rankSore_text", GetUTF8Text("msgbox_common_clew_rank_integral_01"), Vector2(400, 24), Vector2(0, 0), 0, 16, colw, "kAlignRightMiddle"),
    ComFuc.ComCheckBox("add_rankSore_cb", nil, Vector2(24, 24), Vector2(406, 0))
  })
})
local StopMatching, StopMatchingEx = function(bIsCloseTeamMatch)
  local state = ptr_cast(game.CurrentState, "Client.StateLobby")
  if state and state.Matching then
    if matchType == 1 then
      state:CancelMatchingGame()
    elseif isHostMan then
      state:CancelMatchingGame()
    else
      if ComFuc.isReadyStart then
        HideLobbyGameTime()
      end
      if bIsCloseTeamMatch then
        CloseTeamMatch(true)
      end
    end
    TimerRemove()
  end
end, Gui.Control("main")({
  Size = Vector2(1128, 645),
  BackgroundColor = colw,
  Skin = SkinF.game_background,
  Gui.Control("plane_1")({
    Dock = "kDockFill",
    ComFuc.ComControlAddPt("main1_particle", Vector2(1128, 460), Vector2(0, 0), "scene_clouds"),
    ComFuc.ComButton("theme_5", "", Vector2(410, 484), Vector2(313, 0), 16, false, false, SkinF.themeMode_btn[5]),
    ComFuc.ComButton("theme_1", "", Vector2(280, 229), Vector2(73, 292), 16, false, false, SkinF.themeMode_btn[1]),
    ComFuc.ComButton("theme_2", "", Vector2(381, 372), Vector2(471, 262), 16, false, false, SkinF.themeMode_btn[2]),
    ComFuc.ComButton("theme_3", "", Vector2(282, 317), Vector2(780, 165), 16, false, false, SkinF.themeMode_btn[3]),
    ComFuc.ComButton("theme_4", "", Vector2(293, 248), Vector2(720, 0), 16, false, false, SkinF.themeMode_btn[4]),
    ComFuc.ComControlAddPt("theme1_particle", Vector2(350, 350), Vector2(73, 175), "scene_practice"),
    ComFuc.ComControlAddPt("theme2_particle", Vector2(381, 372), Vector2(473, 166), "scene_battlefield"),
    ComFuc.ComControlAddPt("theme3_particle", Vector2(282, 317), Vector2(780, 165), "scene_group"),
    ComFuc.ComControlAddPt("theme4_particle", Vector2(293, 248), Vector2(697, -23), "scene_adventure"),
    ComFuc.ComControlAddPt("theme5_particle", Vector2(381, 372), Vector2(300, 0), "scene_adventure"),
    ComFuc.ComControlAddPt("main2_particle", Vector2(1128, 185), Vector2(0, 460), "scene_clouds_2"),
    Gui.Control("theme_tip")({
      Location = Vector2(500, 150),
      Size = totalSize,
      BackgroundColor = colw,
      Skin = SkinF.lookInfo_004,
      Visible = false,
      Gui.Label("theme_text")({
        Location = Vector2(0, 0),
        Size = TextSize,
        TextAlign = "kAlignLeftTop",
        AutoWrap = true,
        FontSize = 15,
        TextColor = ARGB(255, 255, 255, 255),
        Text = GetUTF8Text("UI_battlefield_Instruction_Freestyle_Combat")
      })
    }),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(19, 492), 255, SkinF.battle_026[1], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(646, 561), 255, SkinF.battle_026[2], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(913, 423), 255, SkinF.battle_026[3], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(620, 73), 255, SkinF.battle_026[4], true, false),
    Gui.Control("match_shelter")({
      BackgroundColor = ARGB(0, 0, 0, 0),
      Size = Vector2(130, 200),
      Location = Vector2(1040, 134),
      ComFuc.ComButton("match_1", GetUTF8Text("button_battlefield_fast_matching"), Vector2(130, 140), Vector2(0, -140), 18, false, false, SkinF.battle_033, true)
    })
  }),
  Gui.Control("plane_2")({
    Dock = "kDockFill",
    Gui.Control("mode_out2")({
      Location = Vector2(8, 45),
      Size = Vector2(701, 447),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel(nil, GetUTF8Text("UI_battlefield_Mode_Selection"), Vector2(635, 21), Vector2(4, 3), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComControl(nil, Vector2(631, 98), Vector2(6, 34), 255, SkinF.battle_005),
      Gui.Control("mode_select")({
        Location = Vector2(9, 45),
        Size = Vector2(696, 446),
        BackgroundColor = colw,
        Skin = SkinF.battle_018,
        Gui.Control("mode_sel_host")({
          Location = Vector2(0, -10),
          Size = Vector2(685, 135),
          ComFuc.ComControl("mode_di", Vector2(255, 110), Vector2(69, -3), 255, SkinF.battle_019),
          ComFuc.ComButton("mode_1", nil, Vector2(93, 93), Vector2(72, 22), 0, false, true, SkinF.battle_004[1], false),
          ComFuc.ComButton("mode_2", nil, Vector2(93, 93), Vector2(184, 22), 0, false, true, SkinF.battle_004[3], true),
          ComFuc.ComButton("mode_3", nil, Vector2(93, 93), Vector2(296, 22), 0, false, true, SkinF.battle_004[5], true),
          ComFuc.ComButton("mode_4", nil, Vector2(93, 93), Vector2(408, 22), 0, false, true, SkinF.battle_004[2], true),
          ComFuc.ComButton("mode_5", nil, Vector2(93, 93), Vector2(520, 22), 0, false, true, SkinF.battle_004[4], true),
          ComFuc.ComButton("mode_6", nil, Vector2(93, 93), Vector2(532, 22), 0, false, true, SkinF.battle_004[7], true),
          ComFuc.ComButton("mode_7", nil, Vector2(93, 93), Vector2(532, 22), 0, false, true, SkinF.battle_004[8], true)
        })
      })
    }),
    Gui.Control({
      Size = Vector2(701, 144),
      Location = Vector2(8, 494),
      Gui.NewMessagePanel("msg_panel")({
        Size = Vector2(701, 105),
        BackgroundColor = colw,
        Skin = SkinF.battle_013,
        Style = "LobbyBattleGame.MessagePanel",
        MaxTextWidth = 670,
        OnePageLineNum = 4,
        LineGap = 1
      }),
      Gui.Control({
        Size = Vector2(701, 38),
        Location = Vector2(0, 106),
        BackgroundColor = colw,
        Skin = SkinF.battle_012,
        ComFuc.ComButton("send_btn", GetUTF8Text("button_common_Send"), Vector2(64, 32), Vector2(630, 3), 16, false, false),
        ComFuc.ComTextBox("input_box", "", Vector2(630, 36), Vector2(3, 2), 80)
      })
    }),
    Gui.Control({
      Location = Vector2(713, 45),
      Size = Vector2(405, 586),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel("team_title", GetUTF8Text("UI_common_Team_List"), Vector2(390, 21), Vector2(4, 3), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComIconButton("quit", Vector2(114, 56), Vector2(86, 432), SkinF.icon_playgame_004, GetUTF8Text("button_common_Back"), SkinF.select_character_038, nil),
      ComFuc.ComIconButton("invite", Vector2(114, 56), Vector2(202, 432), SkinF.icon_playgame_005, GetUTF8Text("button_battlefield_additional_string_047"), SkinF.select_character_038, nil),
      ComFuc.ComButton("sys_match", GetUTF8Text("button_common_Start_Auto_Match"), Vector2(234, 88), Vector2(84, 488), 16, false, false, SkinF.battle_021, true),
      ComFuc.ComIcon2Button("sys_ready", Vector2(234, 88), Vector2(84, 488), SkinF.icon_playgame_009, GetUTF8Text("button_battlefield_additional_string_138"), SkinF.SkinStartGame),
      Gui.Control({
        Location = Vector2(10, 34),
        Size = Vector2(385, 398),
        BackgroundColor = colw,
        Skin = SkinF.battle_005,
        Gui.ListTreeView("member_list")({
          Style = "Gui.AvatarListTreeView002",
          ItemGap = 1,
          Size = Vector2(368, 400),
          Location = Vector2(9, 13)
        })
      })
    })
  }),
  Gui.Control("rank_ckeck")({
    Size = Vector2(430, 24),
    Location = Vector2(683, 12),
    ComFuc.ComLabel("add_rankSore_text", GetUTF8Text("msgbox_common_clew_rank_integral_01"), Vector2(400, 24), Vector2(0, 0), 0, 16, colw, "kAlignRightMiddle"),
    ComFuc.ComCheckBox("add_rankSore_cb", nil, Vector2(24, 24), Vector2(406, 0))
  })
})
local StopMatchingEx, OnMatchingCancel = function()
  StopMatching(true)
end, Gui.Control("main")({
  Size = Vector2(1128, 645),
  BackgroundColor = colw,
  Skin = SkinF.game_background,
  Gui.Control("plane_1")({
    Dock = "kDockFill",
    ComFuc.ComControlAddPt("main1_particle", Vector2(1128, 460), Vector2(0, 0), "scene_clouds"),
    ComFuc.ComButton("theme_5", "", Vector2(410, 484), Vector2(313, 0), 16, false, false, SkinF.themeMode_btn[5]),
    ComFuc.ComButton("theme_1", "", Vector2(280, 229), Vector2(73, 292), 16, false, false, SkinF.themeMode_btn[1]),
    ComFuc.ComButton("theme_2", "", Vector2(381, 372), Vector2(471, 262), 16, false, false, SkinF.themeMode_btn[2]),
    ComFuc.ComButton("theme_3", "", Vector2(282, 317), Vector2(780, 165), 16, false, false, SkinF.themeMode_btn[3]),
    ComFuc.ComButton("theme_4", "", Vector2(293, 248), Vector2(720, 0), 16, false, false, SkinF.themeMode_btn[4]),
    ComFuc.ComControlAddPt("theme1_particle", Vector2(350, 350), Vector2(73, 175), "scene_practice"),
    ComFuc.ComControlAddPt("theme2_particle", Vector2(381, 372), Vector2(473, 166), "scene_battlefield"),
    ComFuc.ComControlAddPt("theme3_particle", Vector2(282, 317), Vector2(780, 165), "scene_group"),
    ComFuc.ComControlAddPt("theme4_particle", Vector2(293, 248), Vector2(697, -23), "scene_adventure"),
    ComFuc.ComControlAddPt("theme5_particle", Vector2(381, 372), Vector2(300, 0), "scene_adventure"),
    ComFuc.ComControlAddPt("main2_particle", Vector2(1128, 185), Vector2(0, 460), "scene_clouds_2"),
    Gui.Control("theme_tip")({
      Location = Vector2(500, 150),
      Size = totalSize,
      BackgroundColor = colw,
      Skin = SkinF.lookInfo_004,
      Visible = false,
      Gui.Label("theme_text")({
        Location = Vector2(0, 0),
        Size = TextSize,
        TextAlign = "kAlignLeftTop",
        AutoWrap = true,
        FontSize = 15,
        TextColor = ARGB(255, 255, 255, 255),
        Text = GetUTF8Text("UI_battlefield_Instruction_Freestyle_Combat")
      })
    }),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(19, 492), 255, SkinF.battle_026[1], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(646, 561), 255, SkinF.battle_026[2], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(913, 423), 255, SkinF.battle_026[3], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(620, 73), 255, SkinF.battle_026[4], true, false),
    Gui.Control("match_shelter")({
      BackgroundColor = ARGB(0, 0, 0, 0),
      Size = Vector2(130, 200),
      Location = Vector2(1040, 134),
      ComFuc.ComButton("match_1", GetUTF8Text("button_battlefield_fast_matching"), Vector2(130, 140), Vector2(0, -140), 18, false, false, SkinF.battle_033, true)
    })
  }),
  Gui.Control("plane_2")({
    Dock = "kDockFill",
    Gui.Control("mode_out2")({
      Location = Vector2(8, 45),
      Size = Vector2(701, 447),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel(nil, GetUTF8Text("UI_battlefield_Mode_Selection"), Vector2(635, 21), Vector2(4, 3), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComControl(nil, Vector2(631, 98), Vector2(6, 34), 255, SkinF.battle_005),
      Gui.Control("mode_select")({
        Location = Vector2(9, 45),
        Size = Vector2(696, 446),
        BackgroundColor = colw,
        Skin = SkinF.battle_018,
        Gui.Control("mode_sel_host")({
          Location = Vector2(0, -10),
          Size = Vector2(685, 135),
          ComFuc.ComControl("mode_di", Vector2(255, 110), Vector2(69, -3), 255, SkinF.battle_019),
          ComFuc.ComButton("mode_1", nil, Vector2(93, 93), Vector2(72, 22), 0, false, true, SkinF.battle_004[1], false),
          ComFuc.ComButton("mode_2", nil, Vector2(93, 93), Vector2(184, 22), 0, false, true, SkinF.battle_004[3], true),
          ComFuc.ComButton("mode_3", nil, Vector2(93, 93), Vector2(296, 22), 0, false, true, SkinF.battle_004[5], true),
          ComFuc.ComButton("mode_4", nil, Vector2(93, 93), Vector2(408, 22), 0, false, true, SkinF.battle_004[2], true),
          ComFuc.ComButton("mode_5", nil, Vector2(93, 93), Vector2(520, 22), 0, false, true, SkinF.battle_004[4], true),
          ComFuc.ComButton("mode_6", nil, Vector2(93, 93), Vector2(532, 22), 0, false, true, SkinF.battle_004[7], true),
          ComFuc.ComButton("mode_7", nil, Vector2(93, 93), Vector2(532, 22), 0, false, true, SkinF.battle_004[8], true)
        })
      })
    }),
    Gui.Control({
      Size = Vector2(701, 144),
      Location = Vector2(8, 494),
      Gui.NewMessagePanel("msg_panel")({
        Size = Vector2(701, 105),
        BackgroundColor = colw,
        Skin = SkinF.battle_013,
        Style = "LobbyBattleGame.MessagePanel",
        MaxTextWidth = 670,
        OnePageLineNum = 4,
        LineGap = 1
      }),
      Gui.Control({
        Size = Vector2(701, 38),
        Location = Vector2(0, 106),
        BackgroundColor = colw,
        Skin = SkinF.battle_012,
        ComFuc.ComButton("send_btn", GetUTF8Text("button_common_Send"), Vector2(64, 32), Vector2(630, 3), 16, false, false),
        ComFuc.ComTextBox("input_box", "", Vector2(630, 36), Vector2(3, 2), 80)
      })
    }),
    Gui.Control({
      Location = Vector2(713, 45),
      Size = Vector2(405, 586),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel("team_title", GetUTF8Text("UI_common_Team_List"), Vector2(390, 21), Vector2(4, 3), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComIconButton("quit", Vector2(114, 56), Vector2(86, 432), SkinF.icon_playgame_004, GetUTF8Text("button_common_Back"), SkinF.select_character_038, nil),
      ComFuc.ComIconButton("invite", Vector2(114, 56), Vector2(202, 432), SkinF.icon_playgame_005, GetUTF8Text("button_battlefield_additional_string_047"), SkinF.select_character_038, nil),
      ComFuc.ComButton("sys_match", GetUTF8Text("button_common_Start_Auto_Match"), Vector2(234, 88), Vector2(84, 488), 16, false, false, SkinF.battle_021, true),
      ComFuc.ComIcon2Button("sys_ready", Vector2(234, 88), Vector2(84, 488), SkinF.icon_playgame_009, GetUTF8Text("button_battlefield_additional_string_138"), SkinF.SkinStartGame),
      Gui.Control({
        Location = Vector2(10, 34),
        Size = Vector2(385, 398),
        BackgroundColor = colw,
        Skin = SkinF.battle_005,
        Gui.ListTreeView("member_list")({
          Style = "Gui.AvatarListTreeView002",
          ItemGap = 1,
          Size = Vector2(368, 400),
          Location = Vector2(9, 13)
        })
      })
    })
  }),
  Gui.Control("rank_ckeck")({
    Size = Vector2(430, 24),
    Location = Vector2(683, 12),
    ComFuc.ComLabel("add_rankSore_text", GetUTF8Text("msgbox_common_clew_rank_integral_01"), Vector2(400, 24), Vector2(0, 0), 0, 16, colw, "kAlignRightMiddle"),
    ComFuc.ComCheckBox("add_rankSore_cb", nil, Vector2(24, 24), Vector2(406, 0))
  })
})

function OnMatchingCancel()
  HideLobbyGameTime()
  ComFuc.isReadyMatch = false
  SetMatchButtonState(false)
  SetModeBtnEnable()
  TimerRemove()
  peopleCount = 0
  if matchType ~= 1 then
    ui.msg_panel:AddMessage("kSys", "", GetUTF8Text("msgbox_battlefield_additional_string_051"))
  end
end

local InitStateCallBack, InitUI = function()
  local state = ptr_cast(game.CurrentState, "Client.StateLobby")
  if state then
    function state.EventMatchingWaiting(sender, e)
      print(" ## state.EventMatchingWaiting time=" .. e.Value)
      
      HideLobbyGameTime()
      if matchType == 1 then
        ui.match_1.Enable = false
      end
      ui.coverControl2.Parent = gui
      Lobby.ShowMatchGameCount(needPeople, needPeople)
      if matchType == 3 then
        print(e.Value, e.teamName1, e.mode1, e.levelId1, e.teamName2, e.mode2, e.levelId2, e.winTeam, e.selfTeam, "BattleGameTeamWait.Show(e)")
        BattleGameTeamWait.Show(e)
      else
        if not ComFuc.Is_FirstPrintLog[6] then
          ComFuc.Is_FirstPrintLog[6] = true
          rpc.safecall("user_retention", {
            sign = ComFuc.First_Log[6]
          }, function(data)
          end)
        end
        game:PlayAudioMusic(4)
        LobbyBoxContern.ShowClockTimer(OnTimerCallBack, e.Value)
      end
    end
    
    function state.EventMatchingCancel(sender, e)
      print(" ## state.EventMatchingCancel e.a=" .. e.a .. " e.b=" .. e.b)
      if e.b == 0 then
        if e.a ~= 0 and Text.ErrorText[e.a] then
          MessageBox.ShowError(Text.ErrorText[e.a])
        end
        OnMatchingCancel()
      else
        MessageBox.ShowError(Text.ErrorText[e.a])
      end
    end
    
    function state.EventMatchingResult(sender, e)
      print(" ## state.EventMatchingResult e.a=" .. e.a .. " e.b=" .. e.b .. " e.c=" .. e.c)
      if e.b == 0 then
        OnMatchingCancel()
        if e.a ~= 0 and Text.ErrorText[e.a] then
          MessageBox.ShowError(Text.ErrorText[e.a])
        else
          MessageBox.ShowError(GetUTF8Text("msgbox_battlefield_additional_string_052"))
        end
      else
        ComFuc.isReadyStart = true
        ComFuc.isReadyMatch = false
        needPeople = e.c
        if matchType ~= 1 then
          peopleCount = 0
          for i = 1, 8 do
            local item = ptr_cast(memDt[i])
            local client_info = ptr_cast(item.Tag, "Client.ClientInfo")
            if client_info then
              peopleCount = peopleCount + 1
            end
          end
        elseif matchType == 1 then
          peopleCount = 1
        end
        Lobby.ShowGameTime(180, StopMatchingEx)
        TimerRefresh()
      end
    end
    
    function state.EventResponseRoomLeave(sender, e)
      ComFuc.is_in_room = false
      print(" ## state.EventResponseRoomLeave")
      if ComFuc.isReadyMatch then
        ReMatchGame()
      end
    end
    
    function state.EventTeamCreate(sender, e)
      print(" ## state.EventTeamCreate: " .. e.Ret .. " the match team create", matchType, themeType)
      MessageBox.CloseWaiter()
      if e.Ret == 0 then
        teamMatchNeed = 8
        SwitchToMatchMode(matchType, true)
        UpdateMemberItem(memDt[1], state:GetTeamSlot(0))
        if matchType == 3 then
          SetModeBtnEnable()
        end
        RequestTeamMemberList(themeType)
      else
        SetTeamMatchEnable(true)
        MessageBox.ShowError(Text.ErrorText[e.Ret])
      end
    end
    
    function state.EventTeamReady(sender, e)
      print(" ## state.EventTeamReady: " .. e.Ret)
      if e.Ret == 0 then
        MessageBox.CloseWaiter()
      else
        MessageBox.CloseWaiter()
        MessageBox.ShowError(Text.ErrorText[e.Ret], 3)
      end
    end
    
    function state.EventTeamLeave(sender, e)
      print(" ## state.EventTeamLeave: " .. e.Ret)
      SetTeamMatchEnable(true)
      isHostMan = false
      ui.theme_tip.Visible = false
      ComFuc.is_in_room = false
      Free_member_item()
      if e.Ret ~= 0 then
        MessageBox.ShowError(Text.ErrorText[e.Ret])
      else
        CloseTeamMatch(false)
      end
      matchType = 1
      themeType = 0
      SetMatchTypeUIShow()
      local state = ptr_cast(game.CurrentState, "Client.StateLobby")
      if state then
        state:SetMatching(false)
      end
    end
    
    function state.EventTeamInvite(sender, e)
      print(" ## state.EventTeamInvite: " .. e.Ret)
      if e.Ret ~= 0 then
        MessageBox.ShowError(Text.ErrorText[e.Ret])
      end
    end
    
    function state.EventTeamInvited(sender, e)
      print(string.format(" ## state.EventTeamInvited (be invited %s, %d, %d, %d)", e.name, e.uid, e.index, e.themeType))
      local typeMsg = {
        string.format(GetUTF8Text("msgbox_battlefield_additional_string_053"), e.name),
        string.format(GetUTF8Text("UI_datalist_consortia_troop_32"))
      }
      local Msg = typeMsg[e.type]
      local uid = e.uid
      local teamId = e.index
      teamInviteType = e.type
      themeType = e.themeType
      if e.type == 1 then
        if not ComFuc.g_bNoDisturbed then
          MessageBox.ShowWithConfirmCancel(Msg, function()
            if LobbyPlayGame and LobbyPlayGame.CheckEquipment() then
              state:TeamInvitedReply(uid, teamId, true, themeType)
            else
              state:TeamInvitedReply(uid, teamId, false, themeType)
            end
          end, function()
            state:TeamInvitedReply(uid, teamId, false, themeType)
          end)
        else
          state:TeamInvitedReply(uid, teamId, false, themeType)
        end
      else
        MessageBox.ShowWithConfirmCancel(Msg, function()
          if LobbyPlayGame and LobbyPlayGame.CheckEquipment() then
            state:TeamInvitedReply(uid, teamId, true, themeType)
          else
            state:TeamInvitedReply(uid, teamId, false, themeType)
          end
        end, function()
          state:TeamInvitedReply(uid, teamId, false, themeType)
        end)
      end
    end
    
    function state.EventTeamInvitedReply(sender, e)
      print(" ## state.EventTeamInvitedReply: " .. e.Ret)
      if e.Ret == 0 then
        if not LobbyStartGame.ui.main.Parent then
          if Lobby then
            Lobby.MainBtnSelect(2)
          end
          LobbyStartGame.SelectMainBtn(1)
        elseif LobbyPlayGame.ui.root.Parent then
          LobbyPlayGame.Hide()
          LobbyBattleGame.Show(LobbyStartGame.ui.main_mid)
          LobbyStartGame.ui.btn_main_1.PushDown = true
        elseif Expedition.ui.main.Parent then
          Expedition.Hide()
          LobbyBattleGame.Show(LobbyStartGame.ui.main_mid)
          LobbyStartGame.ui.btn_main_1.PushDown = true
        end
        themeType = e.theme_Type
        matchType = teamInviteType + 1
        OnCloseWaitting(true)
        SwitchToMatchMode(matchType, false)
        RequestTeamMemberList(themeType)
        SetMatchTypeUIShow()
      else
        MessageBox.ShowError(Text.ErrorText[e.Ret], 3)
      end
    end
    
    function state.EventTeamMemberListChanged(sender, e)
      print(" ## state.EventTeamMemberListChanged")
      teamCurrCount = 0
      ready_num = 0
      matching_game_can_begin = false
      local left_num = 0
      for i = 1, 8 do
        if i <= teamMatchNeed then
          UpdateMemberItem(memDt[i], state:GetTeamSlot(i - 1))
          local client_info = state:GetTeamSlot(i - 1).client
          if client_info then
            if i <= 8 then
              left_num = left_num + 1
            end
            local my_id = state:GetCharacterId()
            if client_info.character_id == my_id then
              UpdateInTeamButtonState(client_info)
            end
          end
          local item = ptr_cast(memDt[i])
          if item then
            item.CanSelect = true
            if item:GetText(3) and item:GetText(3) ~= "" then
              teamCurrCount = teamCurrCount + 1
            end
          end
        else
          local item = ptr_cast(memDt[i])
          if item then
            item.CanSelect = false
          end
        end
      end
      if left_num == ready_num then
        matching_game_can_begin = true
      end
      if matchType == 3 then
        ui.sys_match.Enable = isHostMan and (teamCurrCount == teamMatchNeed or ui.sys_match.Text == GetUTF8Text("button_common_Stop_Auto_Match"))
      end
    end
    
    function state.EventPunishedMembers(sender, e)
      print(" ## state.EventPunishedMembers" .. e.names .. "," .. e.time .. "," .. e.is_team)
      if e.is_team ~= 0 then
        MessageBox.ShowWithTwoButtons(GetMatchedUTF8Text("UI_lobby_game_break_team," .. e.names), GetUTF8Text("button_common_OK"))
      else
        local temp_time
        ComFuc.globalLeftTime = tonumber(e.time)
        if 0 == e.time then
          temp_time = tostring(e.time) .. GetUTF8Text("tips_abilities_Sec")
        else
          if not Tip then
            require("Tip.lua")
          end
          temp_time = Tip.GetLeftTime(tonumber(e.time))
        end
        MessageBox.ShowWithTwoButtons(GetMatchedUTF8Text("UI_lobby_game_break_individual," .. temp_time), GetUTF8Text("button_common_OK"))
      end
    end
    
    function state.EventTeamMemberLeave(sender, e)
      print(" ## state.EventTeamMemberLeave")
      OnMatchingCancel()
    end
    
    function state.EventResponseTeamChangeGameMode(sender, e)
      print(" ## state.EventResponseTeamChangeGameMode: " .. e.Ret)
      themeType = e.theme_Type
      if e.Ret ~= 0 then
        MessageBox.ShowError(Text.ErrorText[e.Ret])
      end
      if matchType == 2 and themeType == 2 then
        GardenGameRoom.SetTalkVisible(false)
      end
    end
    
    function state.EventNotifyTeamChangeGameMode(sender, e)
      print(" ## state.EventNotifyTeamChangeGameMode: " .. e.Ret .. ", " .. e.teamType .. ", " .. e.teamMaxCount .. "," .. e.level_id .. "," .. e.theme_Type)
      themeType = e.theme_Type
      if e.teamType > 0 then
        matchType = e.teamType + 1
        SwitchToMatchMode(matchType, isHostMan)
        SetMatchTypeUIShow()
        if e.teamMaxCount > 0 then
          teamMatchNeed = e.teamMaxCount
        end
      end
      if matchType == 2 and (themeType == 1 or themeType == 2) then
        GardenGameRoom.SelectThemeType(themeType)
      end
      for i = 1, GetMaxModeCount() do
        if matchType == 2 and themeType == 2 and i <= #typeMap2 then
          if typeMap2[i] == tonumber(e.Ret) then
            SetModeBtnState(i)
          end
        elseif typeMap[i] == tonumber(e.Ret) then
          SetModeBtnState(i)
        end
      end
      if matchType == 3 and not isHostMan then
        BattleGameRoom.SetLevelIdAndMapInfo(e.level_id)
      end
    end
    
    function state.EventTeamKick(sender, e)
      print(" ## state.EventTeamKick: " .. e.uid .. " e.index=" .. e.index)
      if e.uid ~= 0 then
        MessageBox.ShowError(Text.ErrorText[e.uid])
      else
        OnMatchingCancel()
      end
    end
    
    function state.EventNotifyTeamMemberKicked(sender, e)
      print(" ## state.EventNotifyTeamMemberKicked: " .. e.Ret)
      if e.Ret < 4 then
        UpdateMemberItem(memDt[e.Ret + 1], nil)
        ui.msg_panel:AddMessage("kSys", "", GetUTF8Text("msgbox_battlefield_additional_string_054"))
      end
    end
    
    function state.EventNotifyTeamClientInGame(sender, e)
      print(" ## state.EventNotifyTeamClientInGame: " .. e.uid .. " e.index=" .. e.index)
      for i = 1, 8 do
        if i <= teamMatchNeed then
          UpdateMemberItem(memDt[i], state:GetTeamSlot(i - 1))
          local client_info = state:GetTeamSlot(e.index).client
          if client_info then
            local my_id = state:GetCharacterId()
            if client_info.character_id == my_id then
              UpdateInTeamButtonState(client_info)
            end
          end
        end
      end
    end
    
    function state.EventMatchingStatus(sender, e)
      peopleCount = math.max(peopleCount, e.a)
      Lobby.ShowMatchGameCount(peopleCount, e.b)
    end
  end
end, function()
  local state = ptr_cast(game.CurrentState, "Client.StateLobby")
  if state then
    function state.EventMatchingWaiting(sender, e)
      print(" ## state.EventMatchingWaiting time=" .. e.Value)
      
      HideLobbyGameTime()
      if matchType == 1 then
        ui.match_1.Enable = false
      end
      ui.coverControl2.Parent = gui
      Lobby.ShowMatchGameCount(needPeople, needPeople)
      if matchType == 3 then
        print(e.Value, e.teamName1, e.mode1, e.levelId1, e.teamName2, e.mode2, e.levelId2, e.winTeam, e.selfTeam, "BattleGameTeamWait.Show(e)")
        BattleGameTeamWait.Show(e)
      else
        if not ComFuc.Is_FirstPrintLog[6] then
          ComFuc.Is_FirstPrintLog[6] = true
          rpc.safecall("user_retention", {
            sign = ComFuc.First_Log[6]
          }, function(data)
          end)
        end
        game:PlayAudioMusic(4)
        LobbyBoxContern.ShowClockTimer(OnTimerCallBack, e.Value)
      end
    end
    
    function state.EventMatchingCancel(sender, e)
      print(" ## state.EventMatchingCancel e.a=" .. e.a .. " e.b=" .. e.b)
      if e.b == 0 then
        if e.a ~= 0 and Text.ErrorText[e.a] then
          MessageBox.ShowError(Text.ErrorText[e.a])
        end
        OnMatchingCancel()
      else
        MessageBox.ShowError(Text.ErrorText[e.a])
      end
    end
    
    function state.EventMatchingResult(sender, e)
      print(" ## state.EventMatchingResult e.a=" .. e.a .. " e.b=" .. e.b .. " e.c=" .. e.c)
      if e.b == 0 then
        OnMatchingCancel()
        if e.a ~= 0 and Text.ErrorText[e.a] then
          MessageBox.ShowError(Text.ErrorText[e.a])
        else
          MessageBox.ShowError(GetUTF8Text("msgbox_battlefield_additional_string_052"))
        end
      else
        ComFuc.isReadyStart = true
        ComFuc.isReadyMatch = false
        needPeople = e.c
        if matchType ~= 1 then
          peopleCount = 0
          for i = 1, 8 do
            local item = ptr_cast(memDt[i])
            local client_info = ptr_cast(item.Tag, "Client.ClientInfo")
            if client_info then
              peopleCount = peopleCount + 1
            end
          end
        elseif matchType == 1 then
          peopleCount = 1
        end
        Lobby.ShowGameTime(180, StopMatchingEx)
        TimerRefresh()
      end
    end
    
    function state.EventResponseRoomLeave(sender, e)
      ComFuc.is_in_room = false
      print(" ## state.EventResponseRoomLeave")
      if ComFuc.isReadyMatch then
        ReMatchGame()
      end
    end
    
    function state.EventTeamCreate(sender, e)
      print(" ## state.EventTeamCreate: " .. e.Ret .. " the match team create", matchType, themeType)
      MessageBox.CloseWaiter()
      if e.Ret == 0 then
        teamMatchNeed = 8
        SwitchToMatchMode(matchType, true)
        UpdateMemberItem(memDt[1], state:GetTeamSlot(0))
        if matchType == 3 then
          SetModeBtnEnable()
        end
        RequestTeamMemberList(themeType)
      else
        SetTeamMatchEnable(true)
        MessageBox.ShowError(Text.ErrorText[e.Ret])
      end
    end
    
    function state.EventTeamReady(sender, e)
      print(" ## state.EventTeamReady: " .. e.Ret)
      if e.Ret == 0 then
        MessageBox.CloseWaiter()
      else
        MessageBox.CloseWaiter()
        MessageBox.ShowError(Text.ErrorText[e.Ret], 3)
      end
    end
    
    function state.EventTeamLeave(sender, e)
      print(" ## state.EventTeamLeave: " .. e.Ret)
      SetTeamMatchEnable(true)
      isHostMan = false
      ui.theme_tip.Visible = false
      ComFuc.is_in_room = false
      Free_member_item()
      if e.Ret ~= 0 then
        MessageBox.ShowError(Text.ErrorText[e.Ret])
      else
        CloseTeamMatch(false)
      end
      matchType = 1
      themeType = 0
      SetMatchTypeUIShow()
      local state = ptr_cast(game.CurrentState, "Client.StateLobby")
      if state then
        state:SetMatching(false)
      end
    end
    
    function state.EventTeamInvite(sender, e)
      print(" ## state.EventTeamInvite: " .. e.Ret)
      if e.Ret ~= 0 then
        MessageBox.ShowError(Text.ErrorText[e.Ret])
      end
    end
    
    function state.EventTeamInvited(sender, e)
      print(string.format(" ## state.EventTeamInvited (be invited %s, %d, %d, %d)", e.name, e.uid, e.index, e.themeType))
      local typeMsg = {
        string.format(GetUTF8Text("msgbox_battlefield_additional_string_053"), e.name),
        string.format(GetUTF8Text("UI_datalist_consortia_troop_32"))
      }
      local Msg = typeMsg[e.type]
      local uid = e.uid
      local teamId = e.index
      teamInviteType = e.type
      themeType = e.themeType
      if e.type == 1 then
        if not ComFuc.g_bNoDisturbed then
          MessageBox.ShowWithConfirmCancel(Msg, function()
            if LobbyPlayGame and LobbyPlayGame.CheckEquipment() then
              state:TeamInvitedReply(uid, teamId, true, themeType)
            else
              state:TeamInvitedReply(uid, teamId, false, themeType)
            end
          end, function()
            state:TeamInvitedReply(uid, teamId, false, themeType)
          end)
        else
          state:TeamInvitedReply(uid, teamId, false, themeType)
        end
      else
        MessageBox.ShowWithConfirmCancel(Msg, function()
          if LobbyPlayGame and LobbyPlayGame.CheckEquipment() then
            state:TeamInvitedReply(uid, teamId, true, themeType)
          else
            state:TeamInvitedReply(uid, teamId, false, themeType)
          end
        end, function()
          state:TeamInvitedReply(uid, teamId, false, themeType)
        end)
      end
    end
    
    function state.EventTeamInvitedReply(sender, e)
      print(" ## state.EventTeamInvitedReply: " .. e.Ret)
      if e.Ret == 0 then
        if not LobbyStartGame.ui.main.Parent then
          if Lobby then
            Lobby.MainBtnSelect(2)
          end
          LobbyStartGame.SelectMainBtn(1)
        elseif LobbyPlayGame.ui.root.Parent then
          LobbyPlayGame.Hide()
          LobbyBattleGame.Show(LobbyStartGame.ui.main_mid)
          LobbyStartGame.ui.btn_main_1.PushDown = true
        elseif Expedition.ui.main.Parent then
          Expedition.Hide()
          LobbyBattleGame.Show(LobbyStartGame.ui.main_mid)
          LobbyStartGame.ui.btn_main_1.PushDown = true
        end
        themeType = e.theme_Type
        matchType = teamInviteType + 1
        OnCloseWaitting(true)
        SwitchToMatchMode(matchType, false)
        RequestTeamMemberList(themeType)
        SetMatchTypeUIShow()
      else
        MessageBox.ShowError(Text.ErrorText[e.Ret], 3)
      end
    end
    
    function state.EventTeamMemberListChanged(sender, e)
      print(" ## state.EventTeamMemberListChanged")
      teamCurrCount = 0
      ready_num = 0
      matching_game_can_begin = false
      local left_num = 0
      for i = 1, 8 do
        if i <= teamMatchNeed then
          UpdateMemberItem(memDt[i], state:GetTeamSlot(i - 1))
          local client_info = state:GetTeamSlot(i - 1).client
          if client_info then
            if i <= 8 then
              left_num = left_num + 1
            end
            local my_id = state:GetCharacterId()
            if client_info.character_id == my_id then
              UpdateInTeamButtonState(client_info)
            end
          end
          local item = ptr_cast(memDt[i])
          if item then
            item.CanSelect = true
            if item:GetText(3) and item:GetText(3) ~= "" then
              teamCurrCount = teamCurrCount + 1
            end
          end
        else
          local item = ptr_cast(memDt[i])
          if item then
            item.CanSelect = false
          end
        end
      end
      if left_num == ready_num then
        matching_game_can_begin = true
      end
      if matchType == 3 then
        ui.sys_match.Enable = isHostMan and (teamCurrCount == teamMatchNeed or ui.sys_match.Text == GetUTF8Text("button_common_Stop_Auto_Match"))
      end
    end
    
    function state.EventPunishedMembers(sender, e)
      print(" ## state.EventPunishedMembers" .. e.names .. "," .. e.time .. "," .. e.is_team)
      if e.is_team ~= 0 then
        MessageBox.ShowWithTwoButtons(GetMatchedUTF8Text("UI_lobby_game_break_team," .. e.names), GetUTF8Text("button_common_OK"))
      else
        local temp_time
        ComFuc.globalLeftTime = tonumber(e.time)
        if 0 == e.time then
          temp_time = tostring(e.time) .. GetUTF8Text("tips_abilities_Sec")
        else
          if not Tip then
            require("Tip.lua")
          end
          temp_time = Tip.GetLeftTime(tonumber(e.time))
        end
        MessageBox.ShowWithTwoButtons(GetMatchedUTF8Text("UI_lobby_game_break_individual," .. temp_time), GetUTF8Text("button_common_OK"))
      end
    end
    
    function state.EventTeamMemberLeave(sender, e)
      print(" ## state.EventTeamMemberLeave")
      OnMatchingCancel()
    end
    
    function state.EventResponseTeamChangeGameMode(sender, e)
      print(" ## state.EventResponseTeamChangeGameMode: " .. e.Ret)
      themeType = e.theme_Type
      if e.Ret ~= 0 then
        MessageBox.ShowError(Text.ErrorText[e.Ret])
      end
      if matchType == 2 and themeType == 2 then
        GardenGameRoom.SetTalkVisible(false)
      end
    end
    
    function state.EventNotifyTeamChangeGameMode(sender, e)
      print(" ## state.EventNotifyTeamChangeGameMode: " .. e.Ret .. ", " .. e.teamType .. ", " .. e.teamMaxCount .. "," .. e.level_id .. "," .. e.theme_Type)
      themeType = e.theme_Type
      if e.teamType > 0 then
        matchType = e.teamType + 1
        SwitchToMatchMode(matchType, isHostMan)
        SetMatchTypeUIShow()
        if e.teamMaxCount > 0 then
          teamMatchNeed = e.teamMaxCount
        end
      end
      if matchType == 2 and (themeType == 1 or themeType == 2) then
        GardenGameRoom.SelectThemeType(themeType)
      end
      for i = 1, GetMaxModeCount() do
        if matchType == 2 and themeType == 2 and i <= #typeMap2 then
          if typeMap2[i] == tonumber(e.Ret) then
            SetModeBtnState(i)
          end
        elseif typeMap[i] == tonumber(e.Ret) then
          SetModeBtnState(i)
        end
      end
      if matchType == 3 and not isHostMan then
        BattleGameRoom.SetLevelIdAndMapInfo(e.level_id)
      end
    end
    
    function state.EventTeamKick(sender, e)
      print(" ## state.EventTeamKick: " .. e.uid .. " e.index=" .. e.index)
      if e.uid ~= 0 then
        MessageBox.ShowError(Text.ErrorText[e.uid])
      else
        OnMatchingCancel()
      end
    end
    
    function state.EventNotifyTeamMemberKicked(sender, e)
      print(" ## state.EventNotifyTeamMemberKicked: " .. e.Ret)
      if e.Ret < 4 then
        UpdateMemberItem(memDt[e.Ret + 1], nil)
        ui.msg_panel:AddMessage("kSys", "", GetUTF8Text("msgbox_battlefield_additional_string_054"))
      end
    end
    
    function state.EventNotifyTeamClientInGame(sender, e)
      print(" ## state.EventNotifyTeamClientInGame: " .. e.uid .. " e.index=" .. e.index)
      for i = 1, 8 do
        if i <= teamMatchNeed then
          UpdateMemberItem(memDt[i], state:GetTeamSlot(i - 1))
          local client_info = state:GetTeamSlot(e.index).client
          if client_info then
            local my_id = state:GetCharacterId()
            if client_info.character_id == my_id then
              UpdateInTeamButtonState(client_info)
            end
          end
        end
      end
    end
    
    function state.EventMatchingStatus(sender, e)
      peopleCount = math.max(peopleCount, e.a)
      Lobby.ShowMatchGameCount(peopleCount, e.b)
    end
  end
end
local InitUI, InitItemMenu = function()
  ui.input_box.BackgroundColor = col0
  ui.sys_ready.Visible = false
  ui.member_list.Columns.Clickable = false
  ui.member_list.Columns.Movable = false
  ui.member_list:AddColumn("", 40, "kAlignCenterMiddle")
  ui.member_list:AddColumn("", 36, "kAlignCenterMiddle")
  ui.member_list:AddColumn(GetUTF8Text("UI_inGame_inGame_string27"), 44, "kAlignLeftMiddle")
  ui.member_list:AddColumn(GetUTF8Text("UI_common_Nickname"), 143, "kAlignLeftMiddle")
  ui.member_list:AddColumn(GetUTF8Text("tips_abilities_VIP"), 36, "kAlignLeftMiddle")
  ui.member_list:AddColumn(GetUTF8Text("UI_battlefield_State"), 70, "kAlignLeftMiddle")
  ui.member_list.Columns.TextColor = colw
  ui.member_list.Columns.FontSize = 16
  for i = 1, 8 do
    local root = ui.member_list.RootItem
    local item = ui.member_list:AddItem(root, "")
    item.ID = i - 1
    for j = 0, 7 do
      item:AddSubItem("")
      item:SetTextColor(j, ARGB(255, 81, 59, 45))
      item:SetHighLightTextColor(j, ARGB(255, 81, 59, 45))
    end
    table.insert(memDt, item)
  end
end, Gui.Control("main")({
  Size = Vector2(1128, 645),
  BackgroundColor = colw,
  Skin = SkinF.game_background,
  Gui.Control("plane_1")({
    Dock = "kDockFill",
    ComFuc.ComControlAddPt("main1_particle", Vector2(1128, 460), Vector2(0, 0), "scene_clouds"),
    ComFuc.ComButton("theme_5", "", Vector2(410, 484), Vector2(313, 0), 16, false, false, SkinF.themeMode_btn[5]),
    ComFuc.ComButton("theme_1", "", Vector2(280, 229), Vector2(73, 292), 16, false, false, SkinF.themeMode_btn[1]),
    ComFuc.ComButton("theme_2", "", Vector2(381, 372), Vector2(471, 262), 16, false, false, SkinF.themeMode_btn[2]),
    ComFuc.ComButton("theme_3", "", Vector2(282, 317), Vector2(780, 165), 16, false, false, SkinF.themeMode_btn[3]),
    ComFuc.ComButton("theme_4", "", Vector2(293, 248), Vector2(720, 0), 16, false, false, SkinF.themeMode_btn[4]),
    ComFuc.ComControlAddPt("theme1_particle", Vector2(350, 350), Vector2(73, 175), "scene_practice"),
    ComFuc.ComControlAddPt("theme2_particle", Vector2(381, 372), Vector2(473, 166), "scene_battlefield"),
    ComFuc.ComControlAddPt("theme3_particle", Vector2(282, 317), Vector2(780, 165), "scene_group"),
    ComFuc.ComControlAddPt("theme4_particle", Vector2(293, 248), Vector2(697, -23), "scene_adventure"),
    ComFuc.ComControlAddPt("theme5_particle", Vector2(381, 372), Vector2(300, 0), "scene_adventure"),
    ComFuc.ComControlAddPt("main2_particle", Vector2(1128, 185), Vector2(0, 460), "scene_clouds_2"),
    Gui.Control("theme_tip")({
      Location = Vector2(500, 150),
      Size = totalSize,
      BackgroundColor = colw,
      Skin = SkinF.lookInfo_004,
      Visible = false,
      Gui.Label("theme_text")({
        Location = Vector2(0, 0),
        Size = TextSize,
        TextAlign = "kAlignLeftTop",
        AutoWrap = true,
        FontSize = 15,
        TextColor = ARGB(255, 255, 255, 255),
        Text = GetUTF8Text("UI_battlefield_Instruction_Freestyle_Combat")
      })
    }),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(19, 492), 255, SkinF.battle_026[1], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(646, 561), 255, SkinF.battle_026[2], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(913, 423), 255, SkinF.battle_026[3], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(620, 73), 255, SkinF.battle_026[4], true, false),
    Gui.Control("match_shelter")({
      BackgroundColor = ARGB(0, 0, 0, 0),
      Size = Vector2(130, 200),
      Location = Vector2(1040, 134),
      ComFuc.ComButton("match_1", GetUTF8Text("button_battlefield_fast_matching"), Vector2(130, 140), Vector2(0, -140), 18, false, false, SkinF.battle_033, true)
    })
  }),
  Gui.Control("plane_2")({
    Dock = "kDockFill",
    Gui.Control("mode_out2")({
      Location = Vector2(8, 45),
      Size = Vector2(701, 447),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel(nil, GetUTF8Text("UI_battlefield_Mode_Selection"), Vector2(635, 21), Vector2(4, 3), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComControl(nil, Vector2(631, 98), Vector2(6, 34), 255, SkinF.battle_005),
      Gui.Control("mode_select")({
        Location = Vector2(9, 45),
        Size = Vector2(696, 446),
        BackgroundColor = colw,
        Skin = SkinF.battle_018,
        Gui.Control("mode_sel_host")({
          Location = Vector2(0, -10),
          Size = Vector2(685, 135),
          ComFuc.ComControl("mode_di", Vector2(255, 110), Vector2(69, -3), 255, SkinF.battle_019),
          ComFuc.ComButton("mode_1", nil, Vector2(93, 93), Vector2(72, 22), 0, false, true, SkinF.battle_004[1], false),
          ComFuc.ComButton("mode_2", nil, Vector2(93, 93), Vector2(184, 22), 0, false, true, SkinF.battle_004[3], true),
          ComFuc.ComButton("mode_3", nil, Vector2(93, 93), Vector2(296, 22), 0, false, true, SkinF.battle_004[5], true),
          ComFuc.ComButton("mode_4", nil, Vector2(93, 93), Vector2(408, 22), 0, false, true, SkinF.battle_004[2], true),
          ComFuc.ComButton("mode_5", nil, Vector2(93, 93), Vector2(520, 22), 0, false, true, SkinF.battle_004[4], true),
          ComFuc.ComButton("mode_6", nil, Vector2(93, 93), Vector2(532, 22), 0, false, true, SkinF.battle_004[7], true),
          ComFuc.ComButton("mode_7", nil, Vector2(93, 93), Vector2(532, 22), 0, false, true, SkinF.battle_004[8], true)
        })
      })
    }),
    Gui.Control({
      Size = Vector2(701, 144),
      Location = Vector2(8, 494),
      Gui.NewMessagePanel("msg_panel")({
        Size = Vector2(701, 105),
        BackgroundColor = colw,
        Skin = SkinF.battle_013,
        Style = "LobbyBattleGame.MessagePanel",
        MaxTextWidth = 670,
        OnePageLineNum = 4,
        LineGap = 1
      }),
      Gui.Control({
        Size = Vector2(701, 38),
        Location = Vector2(0, 106),
        BackgroundColor = colw,
        Skin = SkinF.battle_012,
        ComFuc.ComButton("send_btn", GetUTF8Text("button_common_Send"), Vector2(64, 32), Vector2(630, 3), 16, false, false),
        ComFuc.ComTextBox("input_box", "", Vector2(630, 36), Vector2(3, 2), 80)
      })
    }),
    Gui.Control({
      Location = Vector2(713, 45),
      Size = Vector2(405, 586),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel("team_title", GetUTF8Text("UI_common_Team_List"), Vector2(390, 21), Vector2(4, 3), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComIconButton("quit", Vector2(114, 56), Vector2(86, 432), SkinF.icon_playgame_004, GetUTF8Text("button_common_Back"), SkinF.select_character_038, nil),
      ComFuc.ComIconButton("invite", Vector2(114, 56), Vector2(202, 432), SkinF.icon_playgame_005, GetUTF8Text("button_battlefield_additional_string_047"), SkinF.select_character_038, nil),
      ComFuc.ComButton("sys_match", GetUTF8Text("button_common_Start_Auto_Match"), Vector2(234, 88), Vector2(84, 488), 16, false, false, SkinF.battle_021, true),
      ComFuc.ComIcon2Button("sys_ready", Vector2(234, 88), Vector2(84, 488), SkinF.icon_playgame_009, GetUTF8Text("button_battlefield_additional_string_138"), SkinF.SkinStartGame),
      Gui.Control({
        Location = Vector2(10, 34),
        Size = Vector2(385, 398),
        BackgroundColor = colw,
        Skin = SkinF.battle_005,
        Gui.ListTreeView("member_list")({
          Style = "Gui.AvatarListTreeView002",
          ItemGap = 1,
          Size = Vector2(368, 400),
          Location = Vector2(9, 13)
        })
      })
    })
  }),
  Gui.Control("rank_ckeck")({
    Size = Vector2(430, 24),
    Location = Vector2(683, 12),
    ComFuc.ComLabel("add_rankSore_text", GetUTF8Text("msgbox_common_clew_rank_integral_01"), Vector2(400, 24), Vector2(0, 0), 0, 16, colw, "kAlignRightMiddle"),
    ComFuc.ComCheckBox("add_rankSore_cb", nil, Vector2(24, 24), Vector2(406, 0))
  })
})
local InitItemMenu, Init = function()
  local list = ui.member_list
  ComFuc.InitSocialityMenu(list.PopupMenu, {
    {
      "IDM_KICK_OUT",
      GetUTF8Text("button_common_Kick_from_Room"),
      function()
        local state = ptr_cast(game.CurrentState, "Client.StateLobby")
        if state and not state.Matching then
          local index = tonumber(list.SelectedItem.ID) + 1
          local item = ptr_cast(memDt[index])
          local client_info = ptr_cast(item.Tag, "Client.ClientInfo")
          if client_info and client_info.in_game == true then
            MessageBox.ShowError(GetUTF8Text("msgbox_battlefield_additional_string_055"), 2)
            return
          end
          state:RequestTeamKick(list.SelectedItem.ID)
        end
      end
    },
    {
      "IDM_BEG_WISPER",
      GetUTF8Text("button_common_Chat"),
      function()
        local client_info = ptr_cast(list.SelectedItem.Tag)
        ChatBar.OpenFriendChatPair(client_info.character_id, client_info.character_name)
      end
    },
    {
      "IDM_ADD_FRIEND",
      GetUTF8Text("button_common_Add_Friend"),
      function()
        local client_info = ptr_cast(list.SelectedItem.Tag)
        Sociality.AddFriend(client_info.character_id, client_info.level)
      end
    },
    {
      "IDM_VIEW_PERSONALITY",
      GetUTF8Text("button_common_Info"),
      function()
        local client_info = ptr_cast(list.SelectedItem.Tag)
        LookInfo.Show(client_info.character_id)
      end
    },
    {
      "IDM_COPY_NAME",
      GetUTF8Text("tips_social_copy_name"),
      function()
        local client_info = ptr_cast(list.SelectedItem.Tag)
        Sociality.CopyName(client_info.character_name)
      end
    }
  })
  
  function EnableMenuItem(menu, ids, enable)
    for k, v in pairs(ids) do
      menu:SetEnable(v, enable)
    end
  end
  
  function list.EventRightClick(sender, e)
    if sender.SelectedItem and sender.SelectedItem.Tag then
      local client_info = ptr_cast(sender.SelectedItem.Tag)
      local state = ptr_cast(game.CurrentState, "Client.StateLobby")
      local my_id = state:GetCharacterId()
      if client_info.character_id == my_id then
        EnableMenuItem(sender.PopupMenu, {1, 2}, false)
        EnableMenuItem(sender.PopupMenu, {3}, true)
      else
        EnableMenuItem(sender.PopupMenu, {1, 2}, true)
        EnableMenuItem(sender.PopupMenu, {3}, true)
      end
      if client_info.character_id ~= my_id and isHostMan then
        if state and state.Matching then
          EnableMenuItem(sender.PopupMenu, {0}, false)
        else
          EnableMenuItem(sender.PopupMenu, {0}, true)
        end
      else
        EnableMenuItem(sender.PopupMenu, {0}, false)
      end
      if client_info.character_id ~= my_id then
        EnableMenuItem(sender.PopupMenu, {4}, true)
      end
      sender.PopupMenu:Open()
    else
      EnableMenuItem(sender.PopupMenu, {
        0,
        1,
        2,
        3,
        4
      }, false)
    end
  end
end, Gui.Control("main")({
  Size = Vector2(1128, 645),
  BackgroundColor = colw,
  Skin = SkinF.game_background,
  Gui.Control("plane_1")({
    Dock = "kDockFill",
    ComFuc.ComControlAddPt("main1_particle", Vector2(1128, 460), Vector2(0, 0), "scene_clouds"),
    ComFuc.ComButton("theme_5", "", Vector2(410, 484), Vector2(313, 0), 16, false, false, SkinF.themeMode_btn[5]),
    ComFuc.ComButton("theme_1", "", Vector2(280, 229), Vector2(73, 292), 16, false, false, SkinF.themeMode_btn[1]),
    ComFuc.ComButton("theme_2", "", Vector2(381, 372), Vector2(471, 262), 16, false, false, SkinF.themeMode_btn[2]),
    ComFuc.ComButton("theme_3", "", Vector2(282, 317), Vector2(780, 165), 16, false, false, SkinF.themeMode_btn[3]),
    ComFuc.ComButton("theme_4", "", Vector2(293, 248), Vector2(720, 0), 16, false, false, SkinF.themeMode_btn[4]),
    ComFuc.ComControlAddPt("theme1_particle", Vector2(350, 350), Vector2(73, 175), "scene_practice"),
    ComFuc.ComControlAddPt("theme2_particle", Vector2(381, 372), Vector2(473, 166), "scene_battlefield"),
    ComFuc.ComControlAddPt("theme3_particle", Vector2(282, 317), Vector2(780, 165), "scene_group"),
    ComFuc.ComControlAddPt("theme4_particle", Vector2(293, 248), Vector2(697, -23), "scene_adventure"),
    ComFuc.ComControlAddPt("theme5_particle", Vector2(381, 372), Vector2(300, 0), "scene_adventure"),
    ComFuc.ComControlAddPt("main2_particle", Vector2(1128, 185), Vector2(0, 460), "scene_clouds_2"),
    Gui.Control("theme_tip")({
      Location = Vector2(500, 150),
      Size = totalSize,
      BackgroundColor = colw,
      Skin = SkinF.lookInfo_004,
      Visible = false,
      Gui.Label("theme_text")({
        Location = Vector2(0, 0),
        Size = TextSize,
        TextAlign = "kAlignLeftTop",
        AutoWrap = true,
        FontSize = 15,
        TextColor = ARGB(255, 255, 255, 255),
        Text = GetUTF8Text("UI_battlefield_Instruction_Freestyle_Combat")
      })
    }),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(19, 492), 255, SkinF.battle_026[1], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(646, 561), 255, SkinF.battle_026[2], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(913, 423), 255, SkinF.battle_026[3], true, false),
    ComFuc.ComControl(nil, Vector2(220, 50), Vector2(620, 73), 255, SkinF.battle_026[4], true, false),
    Gui.Control("match_shelter")({
      BackgroundColor = ARGB(0, 0, 0, 0),
      Size = Vector2(130, 200),
      Location = Vector2(1040, 134),
      ComFuc.ComButton("match_1", GetUTF8Text("button_battlefield_fast_matching"), Vector2(130, 140), Vector2(0, -140), 18, false, false, SkinF.battle_033, true)
    })
  }),
  Gui.Control("plane_2")({
    Dock = "kDockFill",
    Gui.Control("mode_out2")({
      Location = Vector2(8, 45),
      Size = Vector2(701, 447),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel(nil, GetUTF8Text("UI_battlefield_Mode_Selection"), Vector2(635, 21), Vector2(4, 3), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComControl(nil, Vector2(631, 98), Vector2(6, 34), 255, SkinF.battle_005),
      Gui.Control("mode_select")({
        Location = Vector2(9, 45),
        Size = Vector2(696, 446),
        BackgroundColor = colw,
        Skin = SkinF.battle_018,
        Gui.Control("mode_sel_host")({
          Location = Vector2(0, -10),
          Size = Vector2(685, 135),
          ComFuc.ComControl("mode_di", Vector2(255, 110), Vector2(69, -3), 255, SkinF.battle_019),
          ComFuc.ComButton("mode_1", nil, Vector2(93, 93), Vector2(72, 22), 0, false, true, SkinF.battle_004[1], false),
          ComFuc.ComButton("mode_2", nil, Vector2(93, 93), Vector2(184, 22), 0, false, true, SkinF.battle_004[3], true),
          ComFuc.ComButton("mode_3", nil, Vector2(93, 93), Vector2(296, 22), 0, false, true, SkinF.battle_004[5], true),
          ComFuc.ComButton("mode_4", nil, Vector2(93, 93), Vector2(408, 22), 0, false, true, SkinF.battle_004[2], true),
          ComFuc.ComButton("mode_5", nil, Vector2(93, 93), Vector2(520, 22), 0, false, true, SkinF.battle_004[4], true),
          ComFuc.ComButton("mode_6", nil, Vector2(93, 93), Vector2(532, 22), 0, false, true, SkinF.battle_004[7], true),
          ComFuc.ComButton("mode_7", nil, Vector2(93, 93), Vector2(532, 22), 0, false, true, SkinF.battle_004[8], true)
        })
      })
    }),
    Gui.Control({
      Size = Vector2(701, 144),
      Location = Vector2(8, 494),
      Gui.NewMessagePanel("msg_panel")({
        Size = Vector2(701, 105),
        BackgroundColor = colw,
        Skin = SkinF.battle_013,
        Style = "LobbyBattleGame.MessagePanel",
        MaxTextWidth = 670,
        OnePageLineNum = 4,
        LineGap = 1
      }),
      Gui.Control({
        Size = Vector2(701, 38),
        Location = Vector2(0, 106),
        BackgroundColor = colw,
        Skin = SkinF.battle_012,
        ComFuc.ComButton("send_btn", GetUTF8Text("button_common_Send"), Vector2(64, 32), Vector2(630, 3), 16, false, false),
        ComFuc.ComTextBox("input_box", "", Vector2(630, 36), Vector2(3, 2), 80)
      })
    }),
    Gui.Control({
      Location = Vector2(713, 45),
      Size = Vector2(405, 586),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComFuc.ComLabel("team_title", GetUTF8Text("UI_common_Team_List"), Vector2(390, 21), Vector2(4, 3), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComIconButton("quit", Vector2(114, 56), Vector2(86, 432), SkinF.icon_playgame_004, GetUTF8Text("button_common_Back"), SkinF.select_character_038, nil),
      ComFuc.ComIconButton("invite", Vector2(114, 56), Vector2(202, 432), SkinF.icon_playgame_005, GetUTF8Text("button_battlefield_additional_string_047"), SkinF.select_character_038, nil),
      ComFuc.ComButton("sys_match", GetUTF8Text("button_common_Start_Auto_Match"), Vector2(234, 88), Vector2(84, 488), 16, false, false, SkinF.battle_021, true),
      ComFuc.ComIcon2Button("sys_ready", Vector2(234, 88), Vector2(84, 488), SkinF.icon_playgame_009, GetUTF8Text("button_battlefield_additional_string_138"), SkinF.SkinStartGame),
      Gui.Control({
        Location = Vector2(10, 34),
        Size = Vector2(385, 398),
        BackgroundColor = colw,
        Skin = SkinF.battle_005,
        Gui.ListTreeView("member_list")({
          Style = "Gui.AvatarListTreeView002",
          ItemGap = 1,
          Size = Vector2(368, 400),
          Location = Vector2(9, 13)
        })
      })
    })
  }),
  Gui.Control("rank_ckeck")({
    Size = Vector2(430, 24),
    Location = Vector2(683, 12),
    ComFuc.ComLabel("add_rankSore_text", GetUTF8Text("msgbox_common_clew_rank_integral_01"), Vector2(400, 24), Vector2(0, 0), 0, 16, colw, "kAlignRightMiddle"),
    ComFuc.ComCheckBox("add_rankSore_cb", nil, Vector2(24, 24), Vector2(406, 0))
  })
})

function Init()
  InitUI()
  InitItemMenu()
  SwitchToMatchMode(1, false)
end

Init()

function CloseTeamMatch(bNotifyLeave)
  if matchType ~= 1 then
    if bNotifyLeave then
      local state = ptr_cast(game.CurrentState, "Client.StateLobby")
      if state then
        state:TeamLeave()
      end
    end
    if ComFuc.isReadyStart then
      HideLobbyGameTime()
    end
    SwitchToMatchMode(1, false)
  end
end

function SetMatchTypeUIShow()
  ui.invite_lbl.Text = btnText[matchType]
  ui.team_title.Text = teamTileText[matchType]
  LobbyStartGame.ui.item_di_title.Skin = itemSkin[matchType]
  if matchType == 2 and themeType == 2 then
    LobbyStartGame.ui.lbl_game_type.Text = GetUTF8Text("UI_abilities_AvatarParadise")
  else
    LobbyStartGame.ui.lbl_game_type.Text = titleText[matchType]
  end
  LobbyStartGame.ui.btn_main_1.Skin = titleSkin[matchType]
end

function TeamMatchIn(type)
  matchType = type + 1
  local state = ptr_cast(game.CurrentState, "Client.StateLobby")
  if state then
    Free_member_item()
    NewLead.HideLead()
    SetTeamMatchEnable(false)
    if matchType == 2 and themeType == 2 then
      state:TeamCreate(type, typeMap2[gameType], 0)
    elseif type == 1 then
      state:TeamCreate(type, typeMap[gameType], 0)
    else
      SetModeBtnState(2)
      state:TeamCreate(type, typeMap[gameType], 0)
      BattleGameRoom.SetBattleRoomInfo(2, typeMap[2])
    end
    SetMatchTypeUIShow()
  end
end

function OnGameBegin(sender, e)
  print(" ## OnGameBegin() e.Ret=" .. e.Ret)
  OnCloseWaitting(true)
  if e.Ret ~= 0 then
    MessageBox.ShowError(Text.ErrorText[e.Ret], show_error_time)
    SetMatchButtonState(false)
    SetModeBtnEnable()
  else
    isInGame = true
  end
end

function OnLeaveRoom(sender, e)
  print(" ## OnLeaveRoom")
  if matchType ~= 1 then
    RequestTeamMemberList(themeType)
  end
  if matchType == 1 then
    game:PlayAudioMusic(5)
  end
  isInGame = false
end

function OnEnterRoomFailed(sender, e)
  if matchType == 1 then
    OnCloseWaitting(false)
    isInGame = false
  end
end

function OnLeaveChannel(sender, e)
  print(" ## OnLeaveChannel")
  if isInGame then
    OnCloseWaitting(false)
    isInGame = false
  end
end

function OnCloseWaitting(bCancelMatching)
  if bCancelMatching then
    print(" ## OnCloseWaitting(true)")
  else
    print(" ## OnCloseWaitting(false)")
  end
  if ComFuc.isReadyStart then
    print(" ## OnCloseWaitting -- ComFuc.isReadyStart")
    local state = ptr_cast(game.CurrentState, "Client.StateLobby")
    if state and bCancelMatching then
      if matchType == 1 then
        if not ComFuc.isReadyMatch then
          state:CancelMatchingGame()
          print(" ## 1 state:CancelMatchingGame() ")
        end
      elseif isHostMan and not ComFuc.isReadyMatch then
        state:CancelMatchingGame()
        print(" ## 2 state:CancelMatchingGame() ")
      end
    end
    HideLobbyGameTime()
  end
  if matchType == 1 then
    ComFuc.isReadyStart = false
  end
  ComFuc.isReadyMatch = false
  SetMatchButtonState(false)
  SetModeBtnEnable()
  TimerRemove()
end

function Reset(bLogin)
  print("### battleGame() ->Reset")
  ui.msg_panel:ClearMessage()
  NewLead.HideLead()
  if bLogin then
    ui.match_1.Text = GetUTF8Text("button_battlefield_fast_matching")
    ui.match_1.TextColor = ARGB(255, 255, 252, 8)
    ui.sys_match.Text = GetUTF8Text("button_common_Start_Auto_Match")
    ui.match_1.Enable = true
    SetModeBtnEnable()
  else
    OnCloseWaitting(true)
    HideLobbyGameTime()
  end
  if bLogin or matchType ~= 1 then
    SwitchToMatchMode(1, false)
  end
  LobbyBoxContern.CloseInvite()
  LobbyBoxContern.CloseClockTimer()
  ui.coverControl2.Parent = nil
  TimerRemove()
  ComFuc.isReadyStart = false
  ComFuc.isReadyMatch = false
  isInGame = false
  ComFuc.is_in_room = false
end

for i = 1, #typeMap do
  ui["mode_" .. i].EventClick = function(sender, e)
    SelModeClick(i)
  end
end
for i = 1, 5 do
  ui["theme_" .. i].EventClick = function(sender, e)
    if Is_QuickJoin then
      MessageBox.ShowError(GetUTF8Text("msgbox_common_playing_padlock"))
      return
    end
    if i == 1 then
      themeType = 0
      NewLead.HideLead()
      LobbyStartGame.SelectMainBtn(2)
    elseif i == 2 then
      if LobbyPlayGame and LobbyPlayGame.CheckEquipment() then
        themeType = 1
        NewLead.HideLead()
        TeamMatchIn(1)
      end
    elseif i == 3 then
      if LobbyPlayGame and LobbyPlayGame.CheckEquipment() then
        themeType = 2
        TeamMatchIn(1)
      end
    elseif i == 4 then
      themeType = 0
      NewLead.HideLead()
      LobbyStartGame.SelectMainBtn(3)
      game.IsjoinedBattle = 1
      LobbyStartGame.ChangeBackMusic()
    else
      themeType = 0
      LobbyStartGame.SelectMainBtn(4)
    end
  end
  ui["theme_" .. i].EventMouseEnter = function(sender, e)
    gui:PlayAudio("fortresstone")
    ui.theme_tip.Visible = true
    ui.theme_tip.Enable = false
    ui.theme_text.Text = ModeTipText[i]
    local needAdd_y = 0
    local textLineNum = ui.theme_text.TextLineNum
    if textLineNum > maxLineNum - 1 then
      needAdd_y = (textLineNum - maxLineNum) * math.ceil(TextSize.y / maxLineNum)
    end
    ui.theme_tip.Size = totalSize + Vector2(0, needAdd_y)
    ui.theme_text.Size = TextSize + Vector2(0, needAdd_y)
    ui.theme_text.Location = Vector2((ui.theme_tip.Size.x - ui.theme_text.Size.x) / 2 + 3, (ui.theme_tip.Size.y - ui.theme_text.Size.y) / 2 - 2)
    ui["theme" .. i .. "_particle"].Particle:Reset()
    if i == 1 then
      ui.theme1_particle.Visible = true
      ui.theme_tip.Location = Vector2(95, 538)
    elseif i == 2 then
      ui.theme2_particle.Visible = true
      ui.theme_tip.Location = Vector2(791, 517)
    elseif i == 3 then
      ui.theme3_particle.Visible = true
      ui.theme_tip.Location = Vector2(857, 470)
    elseif i == 4 then
      ui.theme4_particle.Visible = true
      ui.theme_tip.Location = Vector2(540, 116)
    end
  end
  ui["theme_" .. i].EventMouseLeave = function(sender, e)
    ui["theme" .. i .. "_particle"].Visible = false
    ui.theme_tip.Visible = false
  end
end

function ui.sys_match.EventClick(sender, e)
  if ui.sys_match.Text == GetUTF8Text("button_common_Start_Auto_Match") then
    LobbyBoxContern.CloseInvite()
    StartMatching()
  else
    StopMatching(false)
  end
end

function ui.match_1.EventClick(sender, e)
  if ui.match_1.Text == GetUTF8Text("button_battlefield_fast_matching") then
    if LobbyPlayGame and LobbyPlayGame.CheckEquipment() then
      if bit.band(128, ComFuc.leadList) == 128 then
        NewLead.HideLead()
        ComFuc.SetOneLeadFinish(128)
      end
      StartMatching()
    end
  else
    StopMatching(false)
  end
end

function ui.quit.EventClick(sender, e)
  LeaveTeamMatch()
end

function ui.invite.EventClick(sender, e)
  if LobbyBoxContern and matchType == 2 then
    local IDArray = {}
    local nIndex = 1
    for i = 1, 8 do
      local item = ptr_cast(memDt[i])
      local client_info = ptr_cast(item.Tag, "Client.ClientInfo")
      if client_info and tonumber(client_info.character_id) > 0 then
        IDArray[nIndex] = tonumber(client_info.character_id)
        nIndex = nIndex + 1
      end
    end
    LobbyBoxContern.m_bCheckPlayerLevel = true
    LobbyBoxContern.SetBlockIDArray(IDArray)
    LobbyBoxContern.ShowInvite(gui, true, Vector2(700, 420), OnInviteCallback, nil, true)
  end
  if matchType == 3 then
    rpc.safecall("guild_team_show", {}, function(data)
      local state = ptr_cast(game.CurrentState, "Client.StateLobby")
      if state then
        for i, v in ipairs(data.teamMemberList) do
          if v.playerId ~= SelectCharacter.roleServerId then
            state:TeamInvite(v.name)
            MessageBox.ShowError(GetMatchedUTF8Text("UI_datalist_consortia_troop_30"))
          end
        end
      end
    end)
  end
end

function ui.input_box.EventValueEnter(sender, e)
  SendChatText()
end

function ui.send_btn.EventClick(sender, e)
  SendChatText()
end

function ui.add_rankSore_cb.EventCheckChanged(sender, e)
  if not isFirst then
    local msg = GetUTF8Text("msgbox_common_clew_rank_integral_02")
    if sender.Check then
      config.VictoryConnectMilitary = config.VictoryConnectMilitary + bitValue[SelectCharacter.role_pos_id]
    else
      config.VictoryConnectMilitary = config.VictoryConnectMilitary - bitValue[SelectCharacter.role_pos_id]
      msg = GetUTF8Text("msgbox_common_clew_rank_integral_03")
    end
    MessageBox.ShowError(msg)
    config:SaveOther()
  end
end

function Show(winRoot)
  if not winRoot then
    Hide()
  else
    ui.theme_5.Enable = false
    AddBtntimer()
    isFirst = true
    if isFirst and ComFuc.globalLV >= 10 and (matchType == 1 or matchType == 2) then
      local p = bit.band(config.VictoryConnectMilitary, bitValue[SelectCharacter.role_pos_id]) == bitValue[SelectCharacter.role_pos_id]
      ui.add_rankSore_cb.Check = not p
      ui.add_rankSore_cb.Check = p
      isFirst = false
    end
    ShowGameType()
    if not first then
      SwitchToMatchMode(matchType, isHostMan)
      RequestTeamMemberList(themeType)
      SetMatchTypeUIShow()
    end
    if bit.band(128, ComFuc.leadList) == 128 and matchType == 1 then
      NewLead.ShowNewLeadNoLock(Vector2(1060, 189), Vector2(90, 65), GetUTF8Text("button_battlefield_fast_matching"), 0)
    end
    ui.main.Parent = winRoot
  end
end

function Hide()
  RemoveTimer2()
  TimerRemove()
  ui.main.Parent = nil
  LobbyBoxContern.CloseInvite()
  Free_member_item()
  NewLead.HideLead()
end
