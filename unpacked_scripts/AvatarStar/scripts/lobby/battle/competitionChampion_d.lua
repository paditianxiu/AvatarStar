module("CompetitionChampion", package.seeall)
require("CompetitionQualifying.lua")
require("CompetitionRevive.lua")
require("CompetitionFinals.lua")
require("CompetitionReward.lua")
require("CompetitionApply.lua")
require("CompetitionPlayback.lua")
local colw = ComFuc.colw
local colt = ComFuc.colt
local ui_mgr = require("competitionModeManage.lua")
local competitionMgr = ui_mgr:create()
SeasonName = nil
ApplyMemNum = nil
local NowTime, qualifyBeginT, qualifyEndT
local NowMatchType = 0
competitionMgr:push("competition1", CompetitionQualifying)
competitionMgr:push("competition2", CompetititonRevive)
competitionMgr:push("competition3", CompetititonFinals)
competitionMgr:push("competition4", CompetititonReward)
local titleText = {
  GetUTF8Text("UI_pet_cup_paiweisai"),
  GetUTF8Text("UI_pet_cup_fuhuosai"),
  GetUTF8Text("UI_pet_cup_juesai"),
  GetUTF8Text("UI_pet_guanjunbei_banjiang")
}
local ui, RequestBattleMain = Gui.Create()({
  Gui.Control("root")({
    Size = Vector2(1128, 700),
    Gui.Control("main")({
      Dock = "kDockFill",
      Gui.Control({
        Size = Vector2(1120, 33),
        Location = Vector2(4, 2),
        BackgroundColor = colw,
        Skin = SkinF.battle_020[6],
        ComFuc.ComLabel("contest_timeTip", GetUTF8Text("UI_pet_worldcup_1"), Vector2(500, 20), Vector2(50, 5), 0, 16, colw, "kAlignLeftMiddle")
      }),
      ComFuc.ComLabel("contest_detailsTip", GetUTF8Text("tips_pet_worldcup_gametype"), Vector2(500, 20), Vector2(50, 40), 0, 16, colw, "kAlignLeftMiddle"),
      ComFuc.ComButton("competition1", "paiweisai", Vector2(200, 300), Vector2(120, 130), 16, false, false),
      ComFuc.ComButton("competition2", "fuhuosai", Vector2(200, 300), Vector2(340, 130), 16, false, false),
      ComFuc.ComButton("competition3", "juesai", Vector2(200, 300), Vector2(560, 130), 16, false, false),
      ComFuc.ComButton("competition4", "banjiang", Vector2(200, 300), Vector2(780, 130), 16, false, false),
      ComFuc.ComLabel("schedule1", GetUTF8Text("UI_pet_guanzhan"), Vector2(100, 20), Vector2(200, 440), 0, 16, colt, "kAlignLeftMiddle"),
      ComFuc.ComLabel("schedule2", GetUTF8Text("UI_pet_guanzhan"), Vector2(100, 20), Vector2(420, 440), 0, 16, colt, "kAlignLeftMiddle"),
      ComFuc.ComLabel("schedule3", GetUTF8Text("UI_pet_guanzhan"), Vector2(100, 20), Vector2(640, 440), 0, 16, colt, "kAlignLeftMiddle"),
      ComFuc.ComLabel("schedule4", GetUTF8Text("UI_pet_guanzhan"), Vector2(100, 20), Vector2(860, 440), 0, 16, colt, "kAlignLeftMiddle"),
      ComFuc.ComIconButton("quit", Vector2(114, 56), Vector2(30, 580), SkinF.icon_playgame_004, GetUTF8Text("button_common_Back"), SkinF.select_character_038, nil),
      ComFuc.ComButton("review", GetUTF8Text("UI_pet_worldcup_review"), Vector2(114, 56), Vector2(670, 580), 16, false, false),
      ComFuc.ComButton("apply", GetUTF8Text("UI_pet_baomingcansai"), Vector2(114, 56), Vector2(789, 580), 16, false, false),
      ComFuc.ComButton("begin_match", GetUTF8Text("button_pet_gotocup"), Vector2(114, 56), Vector2(908, 580), 16, false, false)
    })
  })
}), Gui.Create()({
  Gui.Control("root")({
    Size = Vector2(1128, 700),
    Gui.Control("main")({
      Dock = "kDockFill",
      Gui.Control({
        Size = Vector2(1120, 33),
        Location = Vector2(4, 2),
        BackgroundColor = colw,
        Skin = SkinF.battle_020[6],
        ComFuc.ComLabel("contest_timeTip", GetUTF8Text("UI_pet_worldcup_1"), Vector2(500, 20), Vector2(50, 5), 0, 16, colw, "kAlignLeftMiddle")
      }),
      ComFuc.ComLabel("contest_detailsTip", GetUTF8Text("tips_pet_worldcup_gametype"), Vector2(500, 20), Vector2(50, 40), 0, 16, colw, "kAlignLeftMiddle"),
      ComFuc.ComButton("competition1", "paiweisai", Vector2(200, 300), Vector2(120, 130), 16, false, false),
      ComFuc.ComButton("competition2", "fuhuosai", Vector2(200, 300), Vector2(340, 130), 16, false, false),
      ComFuc.ComButton("competition3", "juesai", Vector2(200, 300), Vector2(560, 130), 16, false, false),
      ComFuc.ComButton("competition4", "banjiang", Vector2(200, 300), Vector2(780, 130), 16, false, false),
      ComFuc.ComLabel("schedule1", GetUTF8Text("UI_pet_guanzhan"), Vector2(100, 20), Vector2(200, 440), 0, 16, colt, "kAlignLeftMiddle"),
      ComFuc.ComLabel("schedule2", GetUTF8Text("UI_pet_guanzhan"), Vector2(100, 20), Vector2(420, 440), 0, 16, colt, "kAlignLeftMiddle"),
      ComFuc.ComLabel("schedule3", GetUTF8Text("UI_pet_guanzhan"), Vector2(100, 20), Vector2(640, 440), 0, 16, colt, "kAlignLeftMiddle"),
      ComFuc.ComLabel("schedule4", GetUTF8Text("UI_pet_guanzhan"), Vector2(100, 20), Vector2(860, 440), 0, 16, colt, "kAlignLeftMiddle"),
      ComFuc.ComIconButton("quit", Vector2(114, 56), Vector2(30, 580), SkinF.icon_playgame_004, GetUTF8Text("button_common_Back"), SkinF.select_character_038, nil),
      ComFuc.ComButton("review", GetUTF8Text("UI_pet_worldcup_review"), Vector2(114, 56), Vector2(670, 580), 16, false, false),
      ComFuc.ComButton("apply", GetUTF8Text("UI_pet_baomingcansai"), Vector2(114, 56), Vector2(789, 580), 16, false, false),
      ComFuc.ComButton("begin_match", GetUTF8Text("button_pet_gotocup"), Vector2(114, 56), Vector2(908, 580), 16, false, false)
    })
  })
})

function RequestBattleMain(data)
  SeasonName = data.seasonName
  ApplyMemNum = tonumber(data.teamMemberNum)
  NowTime = data.now
  local endT
  for j, v in ipairs(data.seasonInfo) do
    if v.type == 1 then
      qualifyBeginT = v.startTime
      qualifyEndT = v.endTime
    elseif v.type == 4 then
      endT = v.endTime
    end
    if v.startTime and v.endTime then
      if data.now < v.startTime then
        ui["schedule" .. v.type].Text = GetUTF8Text("UI_pet_jinqingqidai")
      elseif data.now >= v.startTime and data.now < v.endTime then
        NowMatchType = v.type
        ui["schedule" .. v.type].Text = GetUTF8Text("msgbox_common_num_1334")
      elseif data.now >= v.endTime then
        ui["schedule" .. v.type].Text = GetUTF8Text("UI_pet_yijieshu")
      end
    else
      ui["schedule" .. v.type].Text = GetUTF8Text("UI_pet_jinqingqidai")
    end
  end
  local ys, ms, ds = os.date("*t", qualifyBeginT).year, os.date("*t", qualifyBeginT).month, os.date("*t", qualifyBeginT).day
  local ye, me, de = os.date("*t", endT).year, os.date("*t", endT).month, os.date("*t", endT).day
  ui.contest_timeTip.Text = GetMatchedUTF8Text("UI_pet_saijibanjiang_0_1," .. SeasonName .. "," .. " " .. "," .. ys .. "," .. ms .. "," .. ds .. "," .. ye .. "," .. me .. "," .. de)
end

for i = 1, 4 do
  ui["competition" .. i].EventClick = function(sender, e)
    ui.main.Parent = nil
    competitionMgr:switch("competition" .. i, ui.root)
    LobbyStartGame.ui.lbl_game_type.Text = titleText[i]
  end
end

function ui.apply.EventClick(sender, e)
  if NowTime >= qualifyEndT then
    MessageBox.Show(GetUTF8Text("UI_pet_baomingjieshu_1"), GetUTF8Text("button_common_OK"))
  elseif NowTime >= qualifyBeginT and NowTime < qualifyEndT then
    rpc.safecall("leader_apply", {}, CompetitionApply.DealApplyLogic)
  end
end

function ui.review.EventClick(sender, e)
  CompetitionPlayback.Show()
end

function ui.quit.EventClick(sender, e)
  Hide()
  LobbyStartGame.SelectMainBtn(4)
end

function ui.begin_match.EventClick(sender, e)
  if NowMatchType ~= 0 and NowMatchType ~= 4 and NowMatchType == 1 and LobbyPlayGame and LobbyPlayGame.CheckEquipment() then
    Lobby.OnComSwitch(2)
    LobbyBattleGame.TeamMatchIn(3)
  end
end

function Show(winRoot)
  if not winRoot then
    Hide()
  else
    ui.main.Parent = ui.root
    ui.root.Parent = winRoot
  end
end

function Hide()
  ui.root.Parent = nil
end
