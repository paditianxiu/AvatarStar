module("CompetititonReward", package.seeall)
local colw = ComFuc.colw
local colt = ComFuc.colt
local SeasonName
local ui, RequestRewardState = Gui.Create()({
  Gui.Control("main")({
    Size = Vector2(1128, 700),
    Gui.Control({
      Size = Vector2(1120, 33),
      Location = Vector2(4, 2),
      BackgroundColor = ARGB(255, 255, 255, 255),
      Skin = SkinF.battle_020[6],
      ComFuc.ComLabel("contest_timeTip", GetUTF8Text("UI_pet_fuhuosai_0_1"), Vector2(500, 20), Vector2(50, 5), 0, 16, colw, "kAlignLeftMiddle")
    }),
    ComFuc.ComControl("award_main", Vector2(1098, 578), Vector2(15, 78), 255, SkinF.personalInfo_131),
    ComFuc.SecMainTabBtn("btn_award_" .. 1, GetUTF8Text("UI_pet_guanjyajun"), Vector2(100, 38), Vector2(30, 43)),
    ComFuc.SecMainTabBtn("btn_award_" .. 2, GetUTF8Text("UI_pet_guanjun_1"), Vector2(100, 38), Vector2(133, 43)),
    ComFuc.SecMainTabBtn("btn_award_" .. 3, GetUTF8Text("UI_pet_defenwang"), Vector2(100, 38), Vector2(236, 43)),
    ComFuc.SecMainTabBtn("btn_award_" .. 4, GetUTF8Text("UI_pet_renqiwang"), Vector2(100, 38), Vector2(339, 43)),
    ComFuc.SecMainTabBtn("btn_award_" .. 5, GetUTF8Text("UI_pet_jiangjinchi"), Vector2(100, 38), Vector2(442, 43)),
    ComFuc.ComLabel("notStartTip", GetMatchedUTF8Text(GetUTF8Text("UI_pet_fuhuosaiweikaishi,") .. "," .. "banjiang"), Vector2(500, 20), Vector2(350, 350), 0, 18, colt, "kAlignCenterMiddle"),
    ComFuc.ComIconButton("quit", Vector2(114, 56), Vector2(30, 590), SkinF.icon_playgame_004, GetUTF8Text("button_common_Back"), SkinF.select_character_038, nil),
    ComFuc.ComButton("giveAward", GetUTF8Text("banjiang"), Vector2(114, 56), Vector2(827, 590), 16, false, false)
  })
}), Gui.Create()({
  Gui.Control("main")({
    Size = Vector2(1128, 700),
    Gui.Control({
      Size = Vector2(1120, 33),
      Location = Vector2(4, 2),
      BackgroundColor = ARGB(255, 255, 255, 255),
      Skin = SkinF.battle_020[6],
      ComFuc.ComLabel("contest_timeTip", GetUTF8Text("UI_pet_fuhuosai_0_1"), Vector2(500, 20), Vector2(50, 5), 0, 16, colw, "kAlignLeftMiddle")
    }),
    ComFuc.ComControl("award_main", Vector2(1098, 578), Vector2(15, 78), 255, SkinF.personalInfo_131),
    ComFuc.SecMainTabBtn("btn_award_" .. 1, GetUTF8Text("UI_pet_guanjyajun"), Vector2(100, 38), Vector2(30, 43)),
    ComFuc.SecMainTabBtn("btn_award_" .. 2, GetUTF8Text("UI_pet_guanjun_1"), Vector2(100, 38), Vector2(133, 43)),
    ComFuc.SecMainTabBtn("btn_award_" .. 3, GetUTF8Text("UI_pet_defenwang"), Vector2(100, 38), Vector2(236, 43)),
    ComFuc.SecMainTabBtn("btn_award_" .. 4, GetUTF8Text("UI_pet_renqiwang"), Vector2(100, 38), Vector2(339, 43)),
    ComFuc.SecMainTabBtn("btn_award_" .. 5, GetUTF8Text("UI_pet_jiangjinchi"), Vector2(100, 38), Vector2(442, 43)),
    ComFuc.ComLabel("notStartTip", GetMatchedUTF8Text(GetUTF8Text("UI_pet_fuhuosaiweikaishi,") .. "," .. "banjiang"), Vector2(500, 20), Vector2(350, 350), 0, 18, colt, "kAlignCenterMiddle"),
    ComFuc.ComIconButton("quit", Vector2(114, 56), Vector2(30, 590), SkinF.icon_playgame_004, GetUTF8Text("button_common_Back"), SkinF.select_character_038, nil),
    ComFuc.ComButton("giveAward", GetUTF8Text("banjiang"), Vector2(114, 56), Vector2(827, 590), 16, false, false)
  })
})

function RequestRewardState(data)
  SeasonName = data.seasonName
  local startT, endT
  for j, v in ipairs(data.seasonInfo) do
    if v.type == 4 then
      startT = v.startTime
      endT = v.endTime
    end
  end
  if startT and endT then
    if startT > data.now then
      ui.notStartTip.Visible = true
    elseif startT <= data.now and endT > data.now then
      ui.notStartTip.Visible = false
    end
  else
    ui.notStartTip.Visible = true
  end
  local ys, ms, ds = os.date("*t", startT).year, os.date("*t", startT).month, os.date("*t", startT).day
  local ye, me, de = os.date("*t", endT).year, os.date("*t", endT).month, os.date("*t", endT).day
  ui.contest_timeTip.Text = GetMatchedUTF8Text("UI_pet_saijibanjiang_0_1," .. SeasonName .. "," .. "-" .. GetUTF8Text("banjiang") .. "," .. ys .. "," .. ms .. "," .. ds .. "," .. ye .. "," .. me .. "," .. de)
end

function ui.quit.EventClick(sender, e)
  Hide()
  CompetitionSystem.SelectAthleticsMode(2)
end

function ui.giveAward.EventClick(sender, e)
end

function Show(winRoot)
  rpc.safecall("racing_season_info", {}, RequestRewardState)
  ui.main.Parent = winRoot
end

function Hide()
  ui.main.Parent = nil
end
