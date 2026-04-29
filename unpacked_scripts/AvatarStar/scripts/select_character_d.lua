module("SelectCharacter", package.seeall)
require("sys/numeralConst.lua")
local RequireLobbyNeedFiles = require

function RequireLobbyNeedFiles()
  require("sys/expBar.lua")
  require("sys/common_utility.lua")
  require("text.lua")
  require("lobby/lookInfo.lua")
  require("lobby/tip/tip.lua")
  require("lobby/chatBar.lua")
  require("lobby/lobbyMain.lua")
  require("lobby/push_cmd.lua")
  require("lobby/startGame.lua")
  require("lobby/playgame.lua")
  require("lobby/expedition.lua")
  require("lobby/shop/shop_balance.lua")
  require("lobby/auction_house/ah_tab0.lua")
  require("lobby/personalInfo.lua")
  require("lobby/mail.lua")
  require("lobby/chatUnShow.lua")
end

bgRes = {
  "bg_normal02",
  "bg_normal31",
  "bg_normal",
  "bg_normal04"
}
ESCPressed = nil
role_text = nil
job_text = nil
roleServerId = nil
role_job_id = nil
isHaveGuild = "N"
role_pos_id = nil
col0 = ComFuc.col0
colw = ComFuc.colw
coly = ComFuc.coly
colt = ComFuc.colt
colh = ComFuc.colh
colv = ComFuc.colv
colq = ComFuc.colq
colg = ARGB(255, 0, 255, 198)
local resDir = "/ui/skinF/lobby/"
local isReadSevr = true
local jobName = {
  GetUTF8Text("UI_profession_Guardian"),
  GetUTF8Text("UI_profession_Gunner"),
  GetUTF8Text("UI_profession_Assassin"),
  GetUTF8Text("UI_profession_Biochemical")
}
local particleNa = {
  "ui_creat_glowb",
  "ui_creat_glow",
  "ui_creat_glowp",
  "ui_creat_glowr"
}
local timer
local frameC = 0
local inState = 0
local roleId = 0
local jobId = 0
local suitId = 0
local jobList, roleList, suitList, timer
local NewManLead = 0
local cost = 0
local partCount = {
  0,
  0,
  0,
  0
}
local partDt = {
  {},
  {},
  {},
  {}
}
local weapDt
local jobPower = {
  {
    5,
    3,
    2,
    5
  },
  {
    3,
    2,
    5,
    3
  },
  {
    4,
    5,
    3,
    2
  },
  {
    2,
    4,
    2,
    4
  }
}
local jobDes, RoleBtn = {}, {
  3,
  2,
  5,
  3
}
local RoleBtn, SuitPartSelect = function(i)
  return Gui.Button("role_" .. i)({
    Size = Vector2(248, 82),
    Location = Vector2(928, 142 + 93 * i),
    Skin = SkinF.select_character_024[1],
    BackgroundColor = col0,
    Enable = false,
    CanPushDown = true,
    ClickAudio = "000",
    Gui.Control("role_c_" .. i)({
      Size = Vector2(240, 84),
      Visible = false,
      ComFuc.ComControl("job_" .. i, Vector2(31, 31), Vector2(24, 9), 255, nil),
      ComFuc.ComLabel("jobNa_" .. i, nil, Vector2(90, 19), Vector2(62, 15), 0, 16, colt, "kAlignLeftMiddle"),
      ComFuc.ComLabel("level_" .. i, nil, Vector2(71, 19), Vector2(164, 15), 0, 16, colt, "kAlignLeftMiddle"),
      ComFuc.ComLabel("name_" .. i, nil, Vector2(202, 22), Vector2(23, 43), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComControl("no_use_" .. i, Vector2(43, 34), Vector2(192, 38), 255, SkinF.select_character_046, false)
    }),
    Gui.Label("role_free_" .. i)({
      Size = Vector2(248, 82),
      BackgroundColor = colw,
      Skin = SkinF.select_character_047,
      Visible = false,
      TextAlign = "kAlignCenterMiddle",
      FontSize = 18,
      ComFuc.ComButton("sure_delete_" .. i, GetUTF8Text("UI_lobby_confirm_to_delete"), Vector2(124, 56), Vector2(32, 13), nil, false, false, SkinF.select_character_029),
      ComFuc.ComButton("un_freeze_" .. i, nil, Vector2(45, 46), Vector2(195, 18), nil, false, false, SkinF.select_character_048)
    })
  })
end, {
  4,
  5,
  3,
  2
}
local SuitPartSelect, ComParBar = function(i, text)
  return Gui.Control({
    Size = Vector2(220, 36),
    Location = Vector2(26, 264 + 43 * i),
    ComFuc.ComLabel(nil, text, Vector2(72, 19), Vector2(0, 6), 0, 16, colt),
    ComFuc.ComLabel("suit_part_" .. i, "1", Vector2(48, 27), Vector2(114, 3), 255, 16, colw, "kAlignCenterMiddle", SkinF.page_003),
    ComFuc.ComButton("suit_part_left_" .. i, nil, Vector2(33, 36), Vector2(75, 0), nil, false, false, SkinF.page_001),
    ComFuc.ComButton("suit_part_right_" .. i, nil, Vector2(33, 36), Vector2(168, 0), nil, false, false, SkinF.page_002)
  })
end, {
  2,
  4,
  2,
  4
}

function ComParBar(i, text)
  return Gui.Label("par_" .. i)({
    Size = Vector2(216, 31),
    Location = Vector2(87, 264 + 36 * i),
    BackgroundColor = colw,
    Skin = SkinF.select_character_040,
    Text = text,
    FontSize = 16,
    TextColor = colw,
    TextPadding = Vector4(0, 5, 140, 10),
    TextAlign = "kAlignRightMiddle",
    ComFuc.ComControl("par_" .. i .. "_1", Vector2(18, 18), Vector2(91, 5), 255, SkinF.select_character_041[1]),
    ComFuc.ComControl("par_" .. i .. "_2", Vector2(18, 18), Vector2(112, 5), 255, SkinF.select_character_041[1]),
    ComFuc.ComControl("par_" .. i .. "_3", Vector2(18, 18), Vector2(133, 5), 255, SkinF.select_character_041[1]),
    ComFuc.ComControl("par_" .. i .. "_4", Vector2(18, 18), Vector2(154, 5), 255, SkinF.select_character_041[1]),
    ComFuc.ComControl("par_" .. i .. "_5", Vector2(18, 18), Vector2(175, 5), 255, SkinF.select_character_041[1])
  })
end

ui = Gui.Create()({
  ComFuc.ComControl("select_root_p", Vector2(1600, 900), Vector2(0, 0), 255, SkinF.select_character_037),
  ComFuc.ComControl("select_root", Vector2(1200, 900), Vector2(0, 0)),
  Gui.Control("select_role")({
    Size = Vector2(1200, 900),
    ComFuc.ComLabel("game_version", nil, Vector2(300, 22), Vector2(62, 825), 0, 16, colw),
    ComFuc.ComControl(nil, Vector2(206, 49), Vector2(497, 10), 255, SkinF.select_character_035[1]),
    ComFuc.ComButton("btn_enter", GetUTF8Text("button_common_Enter_Game"), Vector2(255, 66), Vector2(473, 804), nil, false, true, SkinF.select_character_029),
    ComFuc.ComBtnHasPreIcon("btn_create", "   " .. GetUTF8Text("button_common_Create"), Vector2(114, 50), Vector2(48, 48), Vector2(935, 698), nil, false, true, SkinF.select_character_038, SkinF.avatar_mian_087[6], -2),
    ComFuc.ComBtnHasPreIcon("btn_delete", "   " .. GetUTF8Text("button_common_Delete"), Vector2(114, 50), Vector2(48, 48), Vector2(1055, 698), nil, false, true, SkinF.select_character_038, SkinF.select_character_045[3], -2),
    Gui.Control({
      Size = Vector2(360, 46),
      Location = Vector2(0, 240),
      BackgroundColor = colw,
      Skin = SkinF.select_character_039,
      ComFuc.ComControl("job_lf", Vector2(30, 30), Vector2(35, 9), 255),
      ComFuc.ComLabel("name_lf", nil, Vector2(190, 30), Vector2(78, 9), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComLabel("lev_lf", nil, Vector2(40, 24), Vector2(272, 13), 0, 0, nil, nil, nil, true, SkinF.level_number_1)
    }),
    Gui.Control({
      Size = Vector2(360, 273),
      Location = Vector2(0, 289),
      BackgroundColor = colw,
      Skin = SkinF.select_character_039,
      ComFuc.ComLabel(nil, GetUTF8Text("tips_abilities_Power"), Vector2(112, 30), Vector2(92, 39), 0, 16, colw),
      ComFuc.ComLabel("fight_lf", 0, Vector2(120, 36), Vector2(150, 38), 0, 0, colw, "kAlignRightMiddle", nil, true, SkinF.info_number_1),
      ComFuc.ComControl(nil, Vector2(20, 17), Vector2(67, 96), 255, SkinF.personalInfo_229[1]),
      ComFuc.ComControl(nil, Vector2(20, 17), Vector2(67, 122), 255, SkinF.personalInfo_229[6]),
      ComFuc.ComControl(nil, Vector2(20, 17), Vector2(67, 148), 255, SkinF.personalInfo_229[2]),
      ComFuc.ComControl(nil, Vector2(20, 17), Vector2(67, 174), 255, SkinF.personalInfo_229[3]),
      ComFuc.ComControl(nil, Vector2(20, 17), Vector2(67, 200), 255, SkinF.personalInfo_229[4]),
      ComFuc.ComControl(nil, Vector2(20, 17), Vector2(67, 226), 255, SkinF.personalInfo_229[5]),
      ComFuc.ComLabel(nil, GetUTF8Text("tips_abilities_HP"), Vector2(192, 26), Vector2(92, 88), 0, 16, colw),
      ComFuc.ComLabel(nil, GetUTF8Text("tips_abilities_Stamina"), Vector2(192, 26), Vector2(92, 114), 0, 16, colw),
      ComFuc.ComLabel(nil, GetUTF8Text("tips_abilities_Vitality"), Vector2(192, 26), Vector2(92, 140), 0, 16, colw),
      ComFuc.ComLabel(nil, GetUTF8Text("tips_abilities_Recovery"), Vector2(192, 26), Vector2(92, 166), 0, 16, colw),
      ComFuc.ComLabel(nil, GetUTF8Text("tips_abilities_Amor"), Vector2(192, 26), Vector2(92, 192), 0, 16, colw),
      ComFuc.ComLabel(nil, GetUTF8Text("tips_abilities_Armor_Penetration"), Vector2(192, 26), Vector2(92, 218), 0, 16, colw),
      ComFuc.ComLabel("main_par_1", 0, Vector2(200, 26), Vector2(62, 88), 0, 16, colw, "kAlignRightMiddle"),
      ComFuc.ComLabel("main_par_6", 0, Vector2(200, 26), Vector2(62, 114), 0, 16, colw, "kAlignRightMiddle"),
      ComFuc.ComLabel("main_par_2", 0, Vector2(200, 26), Vector2(62, 140), 0, 16, colw, "kAlignRightMiddle"),
      ComFuc.ComLabel("main_par_3", 0, Vector2(200, 26), Vector2(62, 166), 0, 16, colw, "kAlignRightMiddle"),
      ComFuc.ComLabel("main_par_4", 0, Vector2(200, 26), Vector2(62, 192), 0, 16, colw, "kAlignRightMiddle"),
      ComFuc.ComLabel("main_par_5", 0, Vector2(200, 26), Vector2(62, 218), 0, 16, colw, "kAlignRightMiddle")
    }),
    Gui.Control({
      Location = Vector2(0, 564),
      Size = Vector2(360, 46),
      BackgroundColor = colw,
      Skin = SkinF.select_character_039,
      ComFuc.ComControl(nil, Vector2(30, 30), Vector2(62, 10), 255, SkinF.avatar_main_088[2]),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_lobby_CC_balance"), Vector2(192, 26), Vector2(92, 11), 0, 16, colw),
      ComFuc.ComLabel("cc_lf", 0, Vector2(200, 26), Vector2(62, 11), 0, 16, colw, "kAlignRightMiddle")
    }),
    RoleBtn(1),
    RoleBtn(2),
    RoleBtn(3),
    RoleBtn(4),
    RoleBtn(5)
  }),
  Gui.Control("select_job")({
    Size = Vector2(1200, 900),
    ComFuc.ComControl(nil, Vector2(206, 49), Vector2(497, 10), 255, SkinF.select_character_035[2]),
    ComFuc.ComControl("jobPho", Vector2(581, 574), Vector2(334, 169), 255, SkinF.select_character_043[1]),
    ComFuc.ComBtnHasPreIcon("btn_roleList", "     " .. GetUTF8Text("button_common_Back"), Vector2(124, 56), Vector2(48, 48), Vector2(24, 817), nil, false, true, SkinF.select_character_029, SkinF.select_character_045[1], 8),
    ComFuc.ComButton("btn_beginCreat", GetUTF8Text("button_common_Create_Begin"), Vector2(255, 66), Vector2(473, 804), nil, false, true, SkinF.select_character_029),
    ComFuc.ComButton("btn_job_1", nil, Vector2(180, 175), Vector2(963, 82), nil, true, false, SkinF.select_character_031[1], true, "00"),
    ComFuc.ComButton("btn_job_2", nil, Vector2(180, 175), Vector2(963, 442), nil, true, false, SkinF.select_character_031[2], true, "00"),
    ComFuc.ComButton("btn_job_3", nil, Vector2(180, 175), Vector2(963, 262), nil, true, false, SkinF.select_character_031[3], true, "00"),
    ComFuc.ComButton("btn_job_4", nil, Vector2(180, 175), Vector2(963, 622), nil, true, false, SkinF.select_character_031[4], true, "00")
  }),
  Gui.Control("select_suit")({
    Size = Vector2(1200, 900),
    ComFuc.ComControl(nil, Vector2(206, 49), Vector2(497, 10), 255, SkinF.select_character_035[3]),
    ComFuc.ComBtnHasPreIcon("btn_jobList", "     " .. GetUTF8Text("button_common_Back"), Vector2(124, 56), Vector2(48, 48), Vector2(24, 817), nil, false, true, SkinF.select_character_029, SkinF.select_character_045[1], 8),
    ComFuc.ComButton("btn_finish", GetUTF8Text("button_common_Complete_Create"), Vector2(255, 66), Vector2(473, 804), nil, false, true, SkinF.select_character_029),
    Gui.Control({
      Size = Vector2(248, 501),
      Location = Vector2(41, 234),
      BackgroundColor = colw,
      Skin = SkinF.select_character_032,
      ComFuc.ComControl(nil, Vector2(216, 31), Vector2(16, 14), 255, SkinF.select_character_040),
      ComFuc.ComControl(nil, Vector2(216, 31), Vector2(16, 132), 255, SkinF.select_character_040),
      ComFuc.ComControl(nil, Vector2(216, 31), Vector2(16, 263), 255, SkinF.select_character_040),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_profession_Enter_Nickname"), Vector2(216, 31), Vector2(16, 11), 0, 16, coly, "kAlignCenterMiddle"),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_lobby_additional_string_061"), Vector2(202, 19), Vector2(23, 99), 0, 16, colv, "kAlignCenterMiddle"),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_profession_Choose_Gender"), Vector2(216, 31), Vector2(16, 129), 0, 16, coly, "kAlignCenterMiddle"),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_profession_Choose_Appearance"), Vector2(216, 31), Vector2(16, 260), 0, 16, coly, "kAlignCenterMiddle"),
      ComFuc.ComTextBox("suit_role_name", nil, Vector2(218, 32), Vector2(15, 60), 14),
      ComFuc.ComButton("suit_sex_1", nil, Vector2(76, 76), Vector2(39, 172), nil, true, true, SkinF.select_character_033[1]),
      ComFuc.ComButton("suit_sex_2", nil, Vector2(76, 76), Vector2(134, 172), nil, true, true, SkinF.select_character_033[2]),
      SuitPartSelect(1, GetUTF8Text("UI_profession_Head_Ornament")),
      SuitPartSelect(2, GetUTF8Text("UI_profession_Eyes")),
      SuitPartSelect(3, GetUTF8Text("UI_profession_Mouth")),
      SuitPartSelect(4, GetUTF8Text("UI_profession_Accessories"))
    }),
    Gui.Control({
      Size = Vector2(248, 136),
      Location = Vector2(881, 661),
      BackgroundColor = colw,
      Skin = SkinF.select_character_032,
      ComFuc.ComControl(nil, Vector2(216, 31), Vector2(16, 8), 255, SkinF.select_character_040),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_profession_Weapon_Display"), Vector2(216, 31), Vector2(16, 5), 0, 16, coly, "kAlignCenterMiddle"),
      ComFuc.ComGuildIconFlag("suit_weapon_1", Vector2(9, 49), Vector2(72, 72), ""),
      ComFuc.ComGuildIconFlag("suit_weapon_2", Vector2(88, 49), Vector2(72, 72), ""),
      ComFuc.ComGuildIconFlag("suit_weapon_3", Vector2(167, 49), Vector2(72, 72), "")
    })
  }),
  Gui.Control("JobIntro")({
    Size = Vector2(390, 456),
    Gui.Label("suit_job_name")({
      Size = Vector2(303, 67),
      Location = Vector2(43, 0),
      BackgroundColor = colw,
      Skin = SkinF.select_character_042,
      FontSize = 16,
      TextColor = colw,
      TextPadding = Vector4(151, 20, 0, 30),
      ComFuc.ComControl("suit_job_icon", Vector2(31, 31), Vector2(16, 14), 255)
    }),
    ComFuc.ComLabel("suit_job_exh", nil, Vector2(390, 210), Vector2(0, 73), 255, 16, colw, nil, SkinF.select_character_039),
    ComParBar(1, GetUTF8Text("UI_lobby_control_level")),
    ComParBar(2, GetUTF8Text("UI_profession_Attack")),
    ComParBar(3, GetUTF8Text("UI_profession_Defense")),
    ComParBar(4, GetUTF8Text("UI_profession_Survive"))
  }),
  ComFuc.ComControl("jobTiao", Vector2(1170, 62), Vector2(0, 144), 255, SkinF.select_character_044[1]),
  ComFuc.ComBtnHasPreIcon("btn_setting", "     " .. GetUTF8Text("button_common_Setting"), Vector2(124, 56), Vector2(48, 48), Vector2(1052, 817), nil, false, true, SkinF.select_character_029, SkinF.select_character_045[2], 8),
  ComFuc.ComBtnHasPreIcon("btn_login", "   " .. GetUTF8Text("button_common_Back_to_Login"), Vector2(124, 56), Vector2(48, 48), Vector2(24, 817), nil, false, true, SkinF.select_character_029, SkinF.select_character_045[1], 2),
  ComFuc.ComControl("coverControl", Vector2(1600, 1200), Vector2(0, 0), 0)
})
ui.btn_job_1.BackgroundColor = ARGB(128, 255, 255, 255)
ui.btn_job_2.BackgroundColor = ARGB(128, 255, 255, 255)
ui.btn_job_3.BackgroundColor = ARGB(128, 255, 255, 255)
ui.btn_job_4.BackgroundColor = ARGB(128, 255, 255, 255)
ui.suit_job_exh.TextPadding = Vector4(40, 25, 40, 25)
ui.suit_job_exh.AutoWrap = true
ui.game_version.Visible = game and game.is_run_launch
ui.btn_login.Visible = not game or not game.is_run_launch
if game.local_language == "en_sg" then
  local ui.suit_role_name.Letter, ShowParAdd = true, ui.suit_role_name
end

function ShowParAdd(i, p)
  if p and math.floor(p) > 0 then
    ui["main_par_" .. i].TextColor = colg
    return math.floor(p)
  end
  ui["main_par_" .. i].TextColor = colw
  return 0
end

function TimerRefresh()
  if ui.select_job.Parent then
    if frameC <= 17 then
      ui.jobTiao.BackgroundColor = ARGB(255 * frameC / 17, 255, 255, 255)
      if frameC == 0 then
        gui:AddParticle(particleNa[jobId], Vector2(0, 146), Vector3(0, -1, 0))
      end
      if frameC <= 4 then
        ui.jobTiao.Size = Vector2(1170, 62 * (4 - frameC) / 4)
        ui.jobTiao.Location = Vector2(0, 144 + (62 - 62 * (4 - frameC) / 4) / 2)
      elseif frameC <= 8 then
        ui.jobTiao.Size = Vector2(1170, 62 * (frameC - 4) / 4)
        ui.jobTiao.Location = Vector2(0, 144 + (62 - 62 * (frameC - 4) / 4) / 2)
      elseif frameC <= 12 then
        ui.jobTiao.Size = Vector2(1170, 62 * (12 - frameC) / 4)
        ui.jobTiao.Location = Vector2(0, 144 + (62 - 62 * (12 - frameC) / 4) / 2)
      elseif frameC <= 17 then
        ui.jobTiao.Size = Vector2(1170, 62 * (frameC - 12) / 5)
        ui.jobTiao.Location = Vector2(0, 144 + (62 - 62 * (frameC - 12) / 5) / 2)
      end
    end
    if 10 <= frameC and frameC <= 24 then
      ui.jobPho.BackgroundColor = ARGB(255 * (frameC - 10) / 14, 255, 255, 255)
      ui.jobPho.Location = Vector2(334 - (364 - (frameC - 10) * 26), 169)
    end
    if 22 <= frameC and frameC <= 32 then
      if frameC <= 30 then
        ComFuc.SetCtrlColorLcSize(ui.JobIntro, ui.JobIntro.Size, Vector2(0, 93 + (frameC - 21) * (14 + 7 * (frameC - 22)) / 2), ARGB((frameC - 22) * 255 / 10, 255, 255, 255))
      elseif frameC <= 32 then
        ComFuc.SetCtrlColorLcSize(ui.JobIntro, ui.JobIntro.Size, Vector2(0, 268 - (frameC - 30) * 13), ARGB((frameC - 22) * 255 / 10, 255, 255, 255))
      end
      if frameC == 30 then
        gui:AddParticle(particleNa[jobId] .. 2, Vector2(ComFuc.locationChanged + 75, 273), Vector3(0, 1, 0))
      end
    end
    frameC = frameC + 1
  end
end

local TimerRemove, ShowJobPar = function()
  game.TimerMgr:RemoveTimer(timer)
  frameC = 0
  timer = nil
  ui.jobTiao.BackgroundColor = col0
  ui.jobPho.BackgroundColor = col0
end, function()
  game.TimerMgr:RemoveTimer(timer)
  frameC = 0
  timer = nil
  ui.jobTiao.BackgroundColor = col0
  ui.jobPho.BackgroundColor = col0
end
local ShowJobPar, ComSelectJob = function(a)
  for i = 1, 5 do
    for j = 1, 4 do
      if i <= a[j] then
        ui["par_" .. j .. "_" .. i].Skin = SkinF.select_character_041[1]
      else
        ui["par_" .. j .. "_" .. i].Skin = SkinF.select_character_041[2]
      end
    end
  end
end, true
local ComSelectJob, SelectCurrentJob = function(i)
  lg:SetBG("/ui/skinF/" .. bgRes[i] .. ".dds")
  ui.suit_job_icon.Skin = SkinF.personalInfo_job[i]
  ui.suit_job_name.Text = jobName[i]
  ui.suit_job_exh.Text = jobDes[i]
  ShowJobPar(jobPower[i])
end, "is_run_launch"
local SelectCurrentJob, SaveSuit = function(i)
  ComSelectJob(i)
  if tonumber(jobId) ~= i then
    gui:PlayAudio("char_change")
    jobId = i
    TimerRemove()
    ComFuc.SetCtrlColorLcSize(ui.JobIntro, ui.JobIntro.Size, Vector2(0, 100), ARGB(0, 0, 0, 0))
    timer = game.TimerMgr:AddTimer(0.041666666666666664)
    timer.EventOnTimer = TimerRefresh
  end
  ui.btn_beginCreat.Enable = i ~= 0
  for k = 1, 4 do
    if k == i then
      ui["btn_job_" .. k].BackgroundColor = ARGB(255, 255, 255, 255)
      ui.jobPho.Skin = SkinF.select_character_043[i]
      ui.jobTiao.Skin = SkinF.select_character_044[i]
      if bit.band(1, NewManLead) == 1 then
        NewManLead = NewManLead - 1
        NewLead.ShowNewLeadNoLock(Vector2(473, 806), Vector2(255, 66), nil, 0)
      end
    else
      ui["btn_job_" .. k].BackgroundColor = ARGB(128, 255, 255, 255)
    end
  end
end, 40
local SaveSuit, DoSuitPartEnable = function()
  lg:UpdateVanInfo()
  local info = lg:GetVanInfo()
  local skinstr = ComFuc.GetDressInfo(info.skin_info, -1, 1)
  local Count = info:GetDressInfoArrCount()
  local dressstrArr = {}
  for k = 1, 5 do
    dressstrArr[k] = "{"
    for i = 1, Count do
      local singleDressInfoStruct = info:GetDressInfoByID(i - 1)
      if singleDressInfoStruct.part_id == k + 8 then
        dressstrArr[k] = dressstrArr[k] .. ComFuc.GetDressInfo(singleDressInfoStruct, i - 1, k + 8) .. ","
      end
    end
    dressstrArr[k] = dressstrArr[k] .. "}"
  end
  local mouthstr = ""
  local nosestr = ""
  local eyestr = ""
  local leye, reye
  Count = info:GetFaceAnimInfoArrCount()
  for i = 1, Count do
    local faceinfoX = info:GetFaceAnimInfoByID(i - 1)
    if faceinfoX.part_id == 3 then
      mouthstr = ComFuc.GetFaceAnimInfo(faceinfoX)
    elseif faceinfoX.part_id == 4 then
      nosestr = ComFuc.GetFaceAnimInfo(faceinfoX)
    elseif faceinfoX.part_name == "eye_l" then
      leye = faceinfoX
    elseif faceinfoX.part_name == "eye_r" then
      reye = faceinfoX
    end
  end
  if leye.tex_res_name == "onecolor_a" then
    eyestr = "{}"
  else
    eyestr = string.format("{'%s',2,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%s}", leye.tex_res_name, leye.translate_x, leye.translate_y, leye.theta, leye.scale_x, leye.scale_y, reye.translate_x, reye.translate_y, reye.theta, reye.scale_x, reye.scale_y, ComFuc.GetChannelInfoStr(leye))
  end
  local earstr, beardstr, hairstr, helmetstr
  Count = info:GetHeadPartTrinketInfoArrCount()
  for i = 1, Count do
    local spartinfo = info:GetHeadPartTrinketByID(i - 1)
    local strtemp = ComFuc.GetSpartInfo(spartinfo)
    if spartinfo.part_id == 6 then
      beardstr = strtemp
    elseif spartinfo.part_id == 7 then
      hairstr = strtemp
    elseif spartinfo.part_id == 8 then
      helmetstr = strtemp
    end
  end
  earstr = ComFuc.GetEarInfo(info.ear_info)
  beardstr = beardstr or "{}"
  hairstr = hairstr or "{}"
  helmetstr = helmetstr or "{}"
  local decalstr = "{"
  Count = info:GetDecalInfoArrCount()
  for i = 1, Count do
    decalstr = decalstr .. ComFuc.GetDecalInfo(info:GetDecalInfoByID(i - 1)) .. ","
  end
  decalstr = decalstr .. "}"
  local mpartstr = "{"
  Count = info:GetMTrinketInfoArrCount()
  for i = 1, Count do
    mpartstr = mpartstr .. ComFuc.GetMTrinketInfo(info:GetMTrinketByID(i - 1)) .. ","
  end
  mpartstr = mpartstr .. "}"
  immobilestr = ComFuc.GetImmovealbeHeadUpDown(info, 16)
  immobileUpstr = ComFuc.GetImmovealbeHeadUpDown(info, 17)
  immobileDownstr = ComFuc.GetImmovealbeHeadUpDown(info, 18)
  return skinstr, eyestr, mouthstr, nosestr, earstr, beardstr, hairstr, helmetstr, dressstrArr[1], dressstrArr[2], dressstrArr[3], dressstrArr[4], dressstrArr[5], decalstr, mpartstr, immobilestr, immobileUpstr, immobileDownstr
end, 25
local DoSuitPartEnable, InitSuitPartIndex = function(i)
  ui["suit_part_left_" .. i].Enable = true
  ui["suit_part_right_" .. i].Enable = true
  if 1 <= partCount[i] then
    local tt = tonumber(ui["suit_part_" .. i].Text)
    if tt < 1 then
      tt = partCount[i]
    elseif tt > partCount[i] then
      tt = 1
    end
    ui["suit_part_" .. i].Text = tt
    if i == 1 then
      suitList[suitId].avatar.hair = partDt[i][tt].value
    elseif i == 2 then
      suitList[suitId].avatar.eye = partDt[i][tt].value
    elseif i == 3 then
      suitList[suitId].avatar.mouth = partDt[i][tt].value
    elseif i == 4 then
      suitList[suitId].avatar.immobileDown = partDt[i][tt].value
    end
  end
  if partCount[i] <= 1 then
    ui["suit_part_" .. i].Text = partCount[i]
    ui["suit_part_left_" .. i].Enable = false
    ui["suit_part_right_" .. i].Enable = false
  end
  ComFuc.DealAvatarEquip(suitList[suitId].avatar)
end, Gui.Control("select_suit")({
  Size = Vector2(1200, 900),
  ComFuc.ComControl(nil, Vector2(206, 49), Vector2(497, 10), 255, SkinF.select_character_035[3]),
  ComFuc.ComBtnHasPreIcon("btn_jobList", "     " .. GetUTF8Text("button_common_Back"), Vector2(124, 56), Vector2(48, 48), Vector2(24, 817), nil, false, true, SkinF.select_character_029, SkinF.select_character_045[1], 8),
  ComFuc.ComButton("btn_finish", GetUTF8Text("button_common_Complete_Create"), Vector2(255, 66), Vector2(473, 804), nil, false, true, SkinF.select_character_029),
  Gui.Control({
    Size = Vector2(248, 501),
    Location = Vector2(41, 234),
    BackgroundColor = colw,
    Skin = SkinF.select_character_032,
    ComFuc.ComControl(nil, Vector2(216, 31), Vector2(16, 14), 255, SkinF.select_character_040),
    ComFuc.ComControl(nil, Vector2(216, 31), Vector2(16, 132), 255, SkinF.select_character_040),
    ComFuc.ComControl(nil, Vector2(216, 31), Vector2(16, 263), 255, SkinF.select_character_040),
    ComFuc.ComLabel(nil, GetUTF8Text("UI_profession_Enter_Nickname"), Vector2(216, 31), Vector2(16, 11), 0, 16, coly, "kAlignCenterMiddle"),
    ComFuc.ComLabel(nil, GetUTF8Text("UI_lobby_additional_string_061"), Vector2(202, 19), Vector2(23, 99), 0, 16, colv, "kAlignCenterMiddle"),
    ComFuc.ComLabel(nil, GetUTF8Text("UI_profession_Choose_Gender"), Vector2(216, 31), Vector2(16, 129), 0, 16, coly, "kAlignCenterMiddle"),
    ComFuc.ComLabel(nil, GetUTF8Text("UI_profession_Choose_Appearance"), Vector2(216, 31), Vector2(16, 260), 0, 16, coly, "kAlignCenterMiddle"),
    ComFuc.ComTextBox("suit_role_name", nil, Vector2(218, 32), Vector2(15, 60), 14),
    ComFuc.ComButton("suit_sex_1", nil, Vector2(76, 76), Vector2(39, 172), nil, true, true, SkinF.select_character_033[1]),
    ComFuc.ComButton("suit_sex_2", nil, Vector2(76, 76), Vector2(134, 172), nil, true, true, SkinF.select_character_033[2]),
    SuitPartSelect(1, GetUTF8Text("UI_profession_Head_Ornament")),
    SuitPartSelect(2, GetUTF8Text("UI_profession_Eyes")),
    SuitPartSelect(3, GetUTF8Text("UI_profession_Mouth")),
    SuitPartSelect(4, GetUTF8Text("UI_profession_Accessories"))
  }),
  Gui.Control({
    Size = Vector2(248, 136),
    Location = Vector2(881, 661),
    BackgroundColor = colw,
    Skin = SkinF.select_character_032,
    ComFuc.ComControl(nil, Vector2(216, 31), Vector2(16, 8), 255, SkinF.select_character_040),
    ComFuc.ComLabel(nil, GetUTF8Text("UI_profession_Weapon_Display"), Vector2(216, 31), Vector2(16, 5), 0, 16, coly, "kAlignCenterMiddle"),
    ComFuc.ComGuildIconFlag("suit_weapon_1", Vector2(9, 49), Vector2(72, 72), ""),
    ComFuc.ComGuildIconFlag("suit_weapon_2", Vector2(88, 49), Vector2(72, 72), ""),
    ComFuc.ComGuildIconFlag("suit_weapon_3", Vector2(167, 49), Vector2(72, 72), "")
  })
})
local InitSuitPartIndex, SelSuitWeapon = function()
  partDt = {
    {},
    {},
    {},
    {}
  }
  for i, v in ipairs(suitList[suitId].part) do
    if tonumber(v.partId) == 7 then
      partDt[1][#partDt[1] + 1] = v
    elseif tonumber(v.partId) == 2 then
      partDt[2][#partDt[2] + 1] = v
    elseif tonumber(v.partId) == 3 then
      partDt[3][#partDt[3] + 1] = v
    elseif tonumber(v.partId) == 18 then
      partDt[4][#partDt[4] + 1] = v
    end
  end
  for i = 1, 4 do
    table.sort(partDt[i], function(t1, t2)
      return tonumber(t1.id) < tonumber(t2.id)
    end)
  end
  for i = 1, 4 do
    partCount[i] = #partDt[i]
    ui["suit_part_" .. i].Text = 1
    DoSuitPartEnable(i)
  end
end, Gui.Control("JobIntro")({
  Size = Vector2(390, 456),
  Gui.Label("suit_job_name")({
    Size = Vector2(303, 67),
    Location = Vector2(43, 0),
    BackgroundColor = colw,
    Skin = SkinF.select_character_042,
    FontSize = 16,
    TextColor = colw,
    TextPadding = Vector4(151, 20, 0, 30),
    ComFuc.ComControl("suit_job_icon", Vector2(31, 31), Vector2(16, 14), 255)
  }),
  ComFuc.ComLabel("suit_job_exh", nil, Vector2(390, 210), Vector2(0, 73), 255, 16, colw, nil, SkinF.select_character_039),
  ComParBar(1, GetUTF8Text("UI_lobby_control_level")),
  ComParBar(2, GetUTF8Text("UI_profession_Attack")),
  ComParBar(3, GetUTF8Text("UI_profession_Defense")),
  ComParBar(4, GetUTF8Text("UI_profession_Survive"))
})
local SelSuitWeapon, EnterLobby = function(i)
  for k = 1, 3 do
    if k == i then
      ui["suit_weapon_" .. k .. "_c"].Visible = true
      lg:SetWeapon(weapDt[k].subType, weapDt[k].resource, 0, false)
    else
      ui["suit_weapon_" .. k .. "_c"].Visible = false
    end
  end
end, ComFuc.ComControl("jobTiao", Vector2(1170, 62), Vector2(0, 144), 255, SkinF.select_character_044[1])
local EnterLobby, SelectIRoleBtn = function(i)
  if roleList and roleList[i] then
    if roleList[i].isColseRole and roleList[i].beginCloseRoleTime >= 100000 and game.sysTimeNow >= roleList[i].beginCloseRoleTime and game.sysTimeNow <= roleList[i].endCloseRoleTime then
      local t = os.date("*t", roleList[i].endCloseRoleTime)
      local s = GetMatchedUTF8Text("tips_social_punish_056_lobby," .. t.year .. "," .. t.month .. "," .. t.day .. "," .. t.hour .. "," .. t.min)
      MessageBox.ShowError(s .. "\n" .. roleList[i].bannedReason)
      return
    end
    ComFuc.isInGame = false
    role_text = roleList[i].name
    job_text = jobName[roleList[i].occupation + 1]
    roleServerId = roleList[i].id
    role_job_id = roleList[i].occupation
    ComFuc.globalLV = roleList[i].level
    game.isCloseRole = roleList[i].isColseRole
    game.beginCloseRoleTime = roleList[i].beginCloseRoleTime or 0
    game.endCloseRoleTime = roleList[i].endCloseRoleTime or 0
    if Lobby and Lobby.mainBtnPushDown then
      Lobby.mainBtnPushDown = 0
    end
    MessageBox.ShowWaiter(GetUTF8Text("msgbox_common_num_1302"))
    local state = ptr_cast(game.CurrentState, "Client.StateSelectCharacter")
    if state then
      RequireLobbyNeedFiles()
      role_pos_id = i
      config.CharacterPosIndex = role_pos_id
      state:EnterLobby(roleList[i].id)
    end
  end
end, ComFuc.ComBtnHasPreIcon("btn_setting", "     " .. GetUTF8Text("button_common_Setting"), Vector2(124, 56), Vector2(48, 48), Vector2(1052, 817), nil, false, true, SkinF.select_character_029, SkinF.select_character_045[2], 8)
local SelectIRoleBtn, DealRoleList = function(i, isSel)
  if isSel then
    gui:PlayAudio("char_select")
    ui["role_" .. i].PushDown = true
    ui.job_lf.Skin = SkinF.personalInfo_job[roleList[i].occupation + 1]
    ui.name_lf.Text = roleList[i].name
    ui.lev_lf.Text = roleList[i].level
    if roleList[i].playerForce and roleList[i].weaponForce then
      ui.fight_lf.Text = roleList[i].playerForce + roleList[i].weaponForce
      ui.main_par_2.Text = math.floor(roleList[i].cureQuantity) + ShowParAdd(2, roleList[i].cureQuantity_p)
      ui.main_par_3.Text = math.floor(roleList[i].recoveryCapacity) + ShowParAdd(3, roleList[i].recoveryCapacity_p)
      ui.main_par_4.Text = math.floor(roleList[i].armor) + ShowParAdd(4, roleList[i].armor_p)
      ui.main_par_5.Text = math.floor(roleList[i].arp) + ShowParAdd(5, roleList[i].arp_p)
      ui.main_par_6.Text = math.floor(roleList[i].stamina) + ShowParAdd(6, roleList[i].stamina_p)
      local tp = NumeralConst.CharacterTransform("ÄÍÁ¦", roleList[i].stamina + roleList[i].stamina_p, roleList[i].occupation + 1)
      ui.main_par_1.Text = roleList[i].life + ShowParAdd(1, tp)
    end
    lg:SetBG("/ui/skinF/" .. bgRes[roleList[i].occupation + 1] .. ".dds")
    if tonumber(roleId) ~= i then
      roleId = i
      local isNotFreeze = roleList[i].freezeTime < 0
      ui.btn_enter.Enable = isNotFreeze
      ui.btn_delete.Enable = isNotFreeze
      if inState == 0 then
        lg:OnSelectChar(isNotFreeze)
        ComFuc.ClearIndependentTrinket()
        if roleList[roleId].equips then
          for i, v in ipairs(roleList[roleId].equips) do
            lg:Set_Independent_Trinket(v.type, v.resource, false, 0, true)
          end
        end
        ComFuc.DealAvatarEquip(roleList[i].equipAvatar)
      end
    end
  else
    ui["role_" .. i].PushDown = false
  end
end, ComFuc.ComBtnHasPreIcon("btn_login", "   " .. GetUTF8Text("button_common_Back_to_Login"), Vector2(124, 56), Vector2(48, 48), Vector2(24, 817), nil, false, true, SkinF.select_character_029, SkinF.select_character_045[1], 2)

function DealRoleList(data)
  MessageBox.CloseWaiter()
  roleList = {}
  NewManLead = 0
  for i = 1, 5 do
    ui["role_" .. i].PushDown = false
    ui["role_" .. i].Enable = false
    ui["role_" .. i].BackgroundColor = colh
    ui["role_c_" .. i].Visible = false
    ui["name_" .. i].Text = ""
  end
  ui.btn_create.Enable = false
  ComFuc.ClearIndependentTrinket()
  cost = data.cost
  ui.cc_lf.Text = data.mb or 0
  ComFuc.globalMB = data.mb or 0
  ComFuc.isOpenAuction = not data.isAuctionClose
  ComFuc.isOpenPet = not data.isPetClose
  roleList = data.characters
  if roleList[1] == nil then
    if not ComFuc.Is_FirstPrintLog[1] then
      ComFuc.Is_FirstPrintLog[1] = true
      rpc.safecall("create_retention", {
        sign = ComFuc.First_Log[1]
      }, function(data)
      end)
    end
    rpc.safecall("get_occupation_properties", {}, function(data)
      for i = 1, 4 do
        jobDes[i] = GetUTF8Text(data.characterList[i].description)
      end
      NewManLead = 63
      lg:SetREId(100)
      ComFuc.SetCtrlColorLcSize(ui.JobIntro, ui.JobIntro.Size, Vector2(0, 100), ARGB(0, 0, 0, 0))
      timer = game.TimerMgr:AddTimer(0.041666666666666664)
      timer.EventOnTimer = TimerRefresh
      ui.select_role.Parent = nil
      ui.btn_roleList.Visible = false
      ui.btn_login.Parent = ui.select_job
      ui.JobIntro.Parent = ui.select_job
      ui.btn_setting.Parent = ui.select_job
      ui.select_job.Parent = ui.select_root
      ui.jobTiao.Parent = ui.select_root_p
      SelectCurrentJob(1)
      return
    end)
  end
  if roleList[5] == nil then
    ui.btn_create.Enable = true
  end
  game.sysTimeNow = data.sysTimeNow or 0
  game.isCloseAccount = data.isColseAccount
  game.beginCloseAccountTime = data.beginColseAccountTime or 0
  game.endCloseAccountTime = data.endColseAccountTime or 0
  if data.isColseAccount and data.beginColseAccountTime >= 100000 and data.sysTimeNow >= data.beginColseAccountTime and data.sysTimeNow <= data.endColseAccountTime then
    local t = os.date("*t", data.endColseAccountTime)
    local s = GetMatchedUTF8Text("tips_social_punish_056_lobby," .. t.year .. "," .. t.month .. "," .. t.day .. "," .. t.hour .. "," .. t.min)
    MessageBox.Show(s .. "\n" .. data.bannedReason, GetUTF8Text("button_common_OK"), function()
      Thread.Quit()
    end)
  end
  local tHasFreeze = false
  for i = 1, 5 do
    ui["no_use_" .. i].Visible = false
    if roleList[i] ~= nil then
      ui["role_" .. i].Enable = true
      ui["role_" .. i].BackgroundColor = colw
      ui["role_c_" .. i].Visible = true
      ui["name_" .. i].Text = roleList[i].name
      ui["level_" .. i].Text = "LV." .. roleList[i].level
      ui["jobNa_" .. i].Text = jobName[roleList[i].occupation + 1]
      ui["job_" .. i].Skin = SkinF.personalInfo_job[roleList[i].occupation + 1]
      if data.lastPid == roleList[i].id and isReadSevr and isReadSevr then
        roleId = 0
        SelectIRoleBtn(i, true)
      end
      if roleList[i].isColseRole and data.sysTimeNow >= roleList[i].beginCloseRoleTime and data.sysTimeNow <= roleList[i].endCloseRoleTime then
        ui["no_use_" .. i].Visible = true
      end
      ui["role_free_" .. i].Visible = 0 <= roleList[i].freezeTime
      ui["sure_delete_" .. i].Visible = roleList[i].freezeTime == 0
      if 0 < roleList[i].freezeTime then
        tHasFreeze = true
        roleList[i].freezeTime = roleList[i].freezeTime
      else
        ui["role_free_" .. i].Text = nil
      end
    end
  end
  if tHasFreeze then
    if timer then
      TimerRemove2()
    end
    timer = game.TimerMgr:AddTimer(1)
    timer.EventOnTimer = TimerRefresh2
  end
  for i = 5, 1, -1 do
    if ui["name_" .. i].Text ~= "" and (not isReadSevr or data.lastPid == 0) then
      roleId = 0
      SelectIRoleBtn(i, true)
      break
    end
  end
  inState = 0
end

function TimerRefresh2()
  local tHasFreeze = false
  for i = 1, 5 do
    if roleList[i] ~= nil then
      if roleList[i].freezeTime > 0 then
        tHasFreeze = true
      else
        if roleList[i].freezeTime == 0 then
          ui["sure_delete_" .. i].Visible = true
        end
        ui["role_free_" .. i].Text = nil
      end
    end
  end
  if tHasFreeze then
    for i = 1, 5 do
      if roleList[i] ~= nil then
        if roleList[i].freezeTime > 0 then
          roleList[i].freezeTime = roleList[i].freezeTime - 1
          local d = math.floor(roleList[i].freezeTime / 86400)
          local h = math.floor(roleList[i].freezeTime / 3600)
          local m = math.floor(roleList[i].freezeTime / 60)
          local s = roleList[i].freezeTime
          if 0 < d then
            h = math.floor(roleList[i].freezeTime % 86400 / 3600)
            local tt, n = string.gsub(GetUTF8Text("tips_lobby_additional_string_074"), "%%d", d)
            tt, n = string.gsub(tt, "%%h", h)
            msg = tt
          elseif 0 < h then
            m = math.floor(roleList[i].freezeTime % 3600 / 60)
            local tt, n = string.gsub(GetUTF8Text("tips_lobby_additional_string_075"), "%%h", h)
            tt, n = string.gsub(tt, "%%m", m)
            msg = tt
          elseif 0 < m then
            s = math.floor(roleList[i].freezeTime % 30 / 1)
            local tt, n = string.gsub(GetUTF8Text("tips_lobby_additional_string_076"), "%%m", m)
            tt, n = string.gsub(tt, "%%s", s)
            msg = tt
          else
            local tt, n = string.gsub(GetUTF8Text("tips_lobby_additional_string_077"), "%%s", s)
            msg = tt
          end
          ui["role_free_" .. i].Text = GetUTF8Text("UI_lobby_delete_timer") .. "\n" .. msg
          ui["role_free_" .. i].AutoWrap = true
        else
          ui["role_free_" .. i].Text = nil
        end
      end
    end
  else
    TimerRemove2()
  end
end

local TimerRemove2, DealSuitList = function()
  game.TimerMgr:RemoveTimer(timer)
  timer = nil
end, function()
  game.TimerMgr:RemoveTimer(timer)
  timer = nil
end
local DealSuitList, ShowRole = function(data)
  suitList = data.sysAvatar
  weapDt = data.weapons
  suitId = 1
  for i, v in ipairs(data.weapons) do
    ui["suit_weapon_" .. i .. "_b"].Skin = Gui.ButtonSkin({
      BackgroundImage = Gui.Image(resDir .. v.resource .. ".tga", Vector4(0, 0, 0, 0))
    })
  end
  InitSuitPartIndex()
end, ComFuc.ComControl("coverControl", Vector2(1600, 1200), Vector2(0, 0), 0)
local ShowRole, ShowJob = function()
  lg:SetWeapon(0, "")
  lg:SetREId(6)
  TimerRemove()
  ui.jobTiao.Parent = nil
  ui.btn_setting.Parent = ui.select_role
  ui.btn_login.Parent = ui.select_role
  ui.select_role.Parent = ui.select_root
  rpc.safecall("player_list", nil, DealRoleList)
end, ComFuc.ComControl("coverControl", Vector2(1600, 1200), Vector2(0, 0), 0)
local ShowJob, ShowSuit = function()
  lg:SetREId(100)
  TimerRemove2()
  ComFuc.SetCtrlColorLcSize(ui.JobIntro, ui.JobIntro.Size, Vector2(0, 100), ARGB(0, 0, 0, 0))
  timer = game.TimerMgr:AddTimer(0.041666666666666664)
  timer.EventOnTimer = TimerRefresh
  ui.btn_roleList.Visible = true
  ui.JobIntro.Parent = ui.select_job
  ui.btn_setting.Parent = ui.select_job
  ui.select_job.Parent = ui.select_root
  ui.jobTiao.Parent = ui.select_root_p
end, ComFuc.ComControl("coverControl", Vector2(1600, 1200), Vector2(0, 0), 0)
local ShowSuit, CreateRole = function()
  lg:SetWeapon(0, "")
  lg:PlayAnim("idlea")
  lg:SetREId(7)
  lg:ClearVanInfo()
  SelSuitWeapon(0)
  TimerRemove()
  TimerRemove2()
  ComFuc.ClearIndependentTrinket()
  ui.suit_role_name.Text = ""
  ui.suit_role_name.Focused = true
  ui["suit_sex_" .. 1].PushDown = true
  ui["suit_sex_" .. 2].PushDown = false
  ui.btn_setting.Parent = ui.select_suit
  ui.JobIntro.Parent = ui.select_suit
  ui.select_suit.Parent = ui.select_root
  ui.jobTiao.Parent = nil
  ComFuc.SetCtrlColorLcSize(ui.JobIntro, ui.JobIntro.Size, Vector2(810, 210), ARGB(255, 255, 255, 255))
  if NewManLead ~= 0 then
    NewManLead = 63
    NewLead.ShowNewLeadNoLock(Vector2(41, 288), Vector2(248, 44), nil, 2)
  end
  rpc.safecall("sysavatar_list", {sysCharacterId = jobId}, DealSuitList)
end, ComFuc.ComControl("coverControl", Vector2(1600, 1200), Vector2(0, 0), 0)
local CreateRole, DeleteRole = function()
  MessageBox.ShowWaiter(GetUTF8Text("msgbox_common_num_1352"))
  local a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18 = SaveSuit()
  local des, n = string.gsub(GetUTF8Text("msgbox_common_conditionkey_155"), "{" .. tostring(0) .. "}", ui.suit_role_name.Text)
  rpc.safecall("player_create", {
    name = ui.suit_role_name.Text,
    description = des,
    id = jobId,
    local_code = config.InternetBar,
    avatar_id = suitList[suitId].avatar.avatarId,
    skin = a1,
    eye = a2,
    mouth = a3,
    nose = a4,
    ear = a5,
    beard = a6,
    hair = a7,
    helmet = a8,
    underwear = a9,
    outerwear = a10,
    trousers = a11,
    glove = a12,
    shoes = a13,
    decal = a14,
    movable = a15,
    immobile = a16,
    immobileUp = a17,
    immobileDown = a18
  }, function(data)
    local warning = data.warning
    if warning then
      print(warning)
      MessageBox.CloseWaiter()
    else
      isReadSevr = false
      ui.select_suit.Parent = nil
      inState = 1
      ShowRole()
      if NewManLead ~= 0 then
        NewManLead = 0
        NewLead.HideLead()
      end
    end
  end, function()
    MessageBox.CloseWaiter()
  end)
end, ComFuc.ComControl("coverControl", Vector2(1600, 1200), Vector2(0, 0), 0)

function DeleteRole()
  MessageBox.ShowWaiter(GetUTF8Text("msgbox_common_num_1313"))
  rpc.safecall("player_freeze", {
    cid = roleList[roleId].id
  }, function(data)
    MessageBox.CloseWaiter()
    isReadSevr = false
    rpc.safecall("player_list", nil, DealRoleList)
  end, function()
    MessageBox.CloseWaiter()
  end)
end

for i = 1, 5 do
  ui["role_" .. i].EventClick = function()
    for k = 1, 5 do
      SelectIRoleBtn(k, k == i)
    end
  end
  ui["role_" .. i].EventDoubleClick = function()
    if roleList[i].freezeTime < 0 then
      gui:PlayAudio("button")
      EnterLobby(i)
    end
  end
  ui["sure_delete_" .. i].EventClick = function()
    MessageBox.ShowWaiter(GetUTF8Text("msgbox_common_num_1313"))
    rpc.safecall("player_delete", {
      cid = roleList[i].id
    }, function(data)
      MessageBox.CloseWaiter()
      isReadSevr = false
      rpc.safecall("player_list", nil, DealRoleList)
    end, function()
      MessageBox.CloseWaiter()
    end)
  end
  ui["un_freeze_" .. i].EventClick = function()
    rpc.safecall("player_unfreeze", {
      cid = roleList[i].id
    }, function(data)
      MessageBox.CloseWaiter()
      isReadSevr = false
      rpc.safecall("player_list", nil, DealRoleList)
    end)
  end
end
for i = 1, 4 do
  ui["btn_job_" .. i].EventClick = function()
    SelectCurrentJob(i)
  end
  ui["btn_job_" .. i].EventDoubleClick = function()
    gui:PlayAudio("button")
    jobId = i
    ComFuc.ClearIndependentTrinket()
    ComSelectJob(i)
    ui.select_job.Parent = nil
    ShowSuit()
  end
end
for i = 1, 2 do
  ui["suit_sex_" .. i].EventClick = function(sender, e)
    if tonumber(suitId) ~= i then
      suitId = i
      InitSuitPartIndex()
    end
    for k = 1, 2 do
      if k == i then
        ui["suit_sex_" .. k].PushDown = true
      else
        ui["suit_sex_" .. k].PushDown = false
      end
    end
  end
end
for i = 1, 4 do
  ui["suit_part_left_" .. i].EventClick = function(sender, e)
    ui["suit_part_" .. i].Text = ui["suit_part_" .. i].Text - 1
    DoSuitPartEnable(i)
  end
  ui["suit_part_right_" .. i].EventClick = function(sender, e)
    ui["suit_part_" .. i].Text = ui["suit_part_" .. i].Text + 1
    DoSuitPartEnable(i)
  end
end
for i = 1, 3 do
  ui["suit_weapon_" .. i .. "_b"].EventClick = function(sender, e)
    SelSuitWeapon(i)
  end
end

function ui.btn_setting.EventClick(sender, e)
  if ESCPressed then
    ESCPressed()
  end
end

function ui.btn_login.EventClick()
  game:LogoutAccount()
end

function ui.btn_enter.EventClick()
  EnterLobby(roleId)
end

function ui.btn_create.EventClick()
  rpc.safecall("get_occupation_properties", {}, function(data)
    for i = 1, 4 do
      jobDes[i] = GetUTF8Text(data.characterList[i].description)
    end
    SelectCurrentJob(1)
    ui.select_role.Parent = nil
    ShowJob()
  end)
end

function ui.btn_delete.EventClick()
  MessageBox.ShowWithConfirmCancel(GetUTF8Text("msgbox_common_num_1316"), DeleteRole)
end

function ui.btn_roleList.EventClick(sender, e)
  ui.select_job.Parent = nil
  ShowRole()
end

function ui.btn_beginCreat.EventClick(sender, e)
  ComFuc.ClearIndependentTrinket()
  ui.select_job.Parent = nil
  ShowSuit()
end

function ui.btn_jobList.EventClick()
  ui.select_suit.Parent = nil
  if NewManLead ~= 0 then
    NewLead.HideLead()
  end
  ShowJob()
end

function ui.btn_finish.EventClick()
  local isOpenIme = false
  for i = 1, 100 do
    if string.byte(ui.suit_role_name.Text, i) and string.byte(ui.suit_role_name.Text, i) > 128 then
      isOpenIme = true
      break
    end
  end
  if ui.suit_role_name.Text == "" then
    MessageBox.ShowError(GetUTF8Text("msgbox_common_num_1384"))
  elseif game.local_language == "en_sg" and (isOpenIme or string.len(ui.suit_role_name.Text) < 3) then
    if isOpenIme then
      MessageBox.ShowError(GetUTF8Text("msgbox_common_conditionkey_015"))
    elseif string.len(ui.suit_role_name.Text) < 3 then
      MessageBox.ShowError(GetUTF8Text("msgbox_common_name_limit_client"))
    end
  else
    CreateRole()
  end
end

function ui.suit_role_name.EventTextChanged()
  if bit.band(4, NewManLead) == 4 then
    NewManLead = NewManLead - 4
    NewLead.ShowNewLeadNoLock(Vector2(473, 806), Vector2(255, 66), nil, 0)
  end
end

function AlignUI()
  Gui.Align(ui.select_root_p, 0.5, 0.5)
  Gui.Align(ui.select_root, 0.5, 0.5)
end

function Show()
  rpc.clear()
  NewLead.HideLead()
  ComFuc.fromSelToLobby = true
  ComFuc.fromSelToLobby2 = true
  ComFuc.isCrossNew = true
  ComFuc.isSignFromSelect = true
  ComFuc.fromAToL = false
  ComFuc.is_from_select = true
  ComFuc.selToLobbyState = 0
  game.IsjoinedBattle = 0
  ui.select_job.Parent = nil
  ui.select_suit.Parent = nil
  ui.game_version.Text = string.format(GetUTF8Text("UI_common_Version"), game.version)
  ui.select_root_p.Parent = gui
  ui.select_root.Parent = gui
  roleId = 0
  isReadSevr = true
  for i = 1, 3 do
    ui["suit_weapon_" .. i .. "_b"].Visible = true
  end
  ShowRole()
  AlignUI()
  if AHMain then
    AHMain.Init()
  end
  if Lobby and Lobby.ui.gameLastT_p.Visible then
    Lobby.ui.gameLastT_p.Visible = false
    Lobby.ui.btn_closeLT.Visible = false
  end
  ComFuc.isSlefExitGuild = false
  if LobbyBattleGame and LobbyStartGame then
    LobbyBattleGame.matchType = 1
    LobbyBattleGame.SetMatchTypeUIShow()
  end
end

function Hide()
  lg:SetREId(100)
  TimerRemove()
  TimerRemove2()
  ui.select_root_p.Parent = nil
  ui.select_root.Parent = nil
end
