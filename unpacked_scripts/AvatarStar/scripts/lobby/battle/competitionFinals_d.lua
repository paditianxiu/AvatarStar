module("CompetititonFinals", package.seeall)
local colw = ComFuc.colw
local colt = ComFuc.colt
local SeasonName
local ui, RequestFinalsState = Gui.Create()({
  Gui.Control("main")({
    Size = Vector2(1128, 700),
    Gui.Control({
      Size = Vector2(1120, 33),
      Location = Vector2(4, 2),
      BackgroundColor = ARGB(255, 255, 255, 255),
      Skin = SkinF.battle_020[6],
      ComFuc.ComLabel("contest_timeTip", GetUTF8Text("UI_pet_saijijuesai"), Vector2(500, 20), Vector2(50, 5), 0, 16, colw, "kAlignLeftMiddle")
    }),
    ComFuc.ComControl("area_main", Vector2(1098, 578), Vector2(15, 78), 255, SkinF.personalInfo_131),
    ComFuc.SecMainTabBtn("btn_area_" .. 1, GetUTF8Text("UI_pet_asaiqu"), Vector2(100, 38), Vector2(30, 43)),
    ComFuc.SecMainTabBtn("btn_area_" .. 2, GetUTF8Text("UI_pet_bsaiqu"), Vector2(100, 38), Vector2(133, 43)),
    ComFuc.SecMainTabBtn("btn_area_" .. 3, GetUTF8Text("UI_pet_csaiqu"), Vector2(100, 38), Vector2(236, 43)),
    ComFuc.SecMainTabBtn("btn_area_" .. 4, GetUTF8Text("UI_pet_dsaiqu"), Vector2(100, 38), Vector2(339, 43)),
    ComFuc.SecMainTabBtn("btn_area_" .. 5, GetUTF8Text("UI_pet_zongjuesai"), Vector2(100, 38), Vector2(442, 43)),
    ComFuc.ComLabel("contest_detailsTip", GetUTF8Text("UI_pet_dianjizhanduitubiao_2"), Vector2(500, 20), Vector2(750, 100), 0, 16, colw, "kAlignLeftMiddle"),
    ComFuc.ComLabel("notStartTip", GetMatchedUTF8Text(GetUTF8Text("UI_pet_fuhuosaiweikaishi,") .. "," .. "juesai"), Vector2(500, 20), Vector2(300, 350), 0, 18, colt, "kAlignCenterMiddle"),
    ComFuc.ComIconButton("quit", Vector2(114, 56), Vector2(855, 590), SkinF.icon_playgame_004, GetUTF8Text("button_common_Back"), SkinF.select_character_038, nil),
    ComFuc.ComButton("ruleReferral", GetUTF8Text("UI_pet_guizejieshao"), Vector2(114, 56), Vector2(976, 590), 16, false, false)
  })
}), Gui.Create()({
  Gui.Control("main")({
    Size = Vector2(1128, 700),
    Gui.Control({
      Size = Vector2(1120, 33),
      Location = Vector2(4, 2),
      BackgroundColor = ARGB(255, 255, 255, 255),
      Skin = SkinF.battle_020[6],
      ComFuc.ComLabel("contest_timeTip", GetUTF8Text("UI_pet_saijijuesai"), Vector2(500, 20), Vector2(50, 5), 0, 16, colw, "kAlignLeftMiddle")
    }),
    ComFuc.ComControl("area_main", Vector2(1098, 578), Vector2(15, 78), 255, SkinF.personalInfo_131),
    ComFuc.SecMainTabBtn("btn_area_" .. 1, GetUTF8Text("UI_pet_asaiqu"), Vector2(100, 38), Vector2(30, 43)),
    ComFuc.SecMainTabBtn("btn_area_" .. 2, GetUTF8Text("UI_pet_bsaiqu"), Vector2(100, 38), Vector2(133, 43)),
    ComFuc.SecMainTabBtn("btn_area_" .. 3, GetUTF8Text("UI_pet_csaiqu"), Vector2(100, 38), Vector2(236, 43)),
    ComFuc.SecMainTabBtn("btn_area_" .. 4, GetUTF8Text("UI_pet_dsaiqu"), Vector2(100, 38), Vector2(339, 43)),
    ComFuc.SecMainTabBtn("btn_area_" .. 5, GetUTF8Text("UI_pet_zongjuesai"), Vector2(100, 38), Vector2(442, 43)),
    ComFuc.ComLabel("contest_detailsTip", GetUTF8Text("UI_pet_dianjizhanduitubiao_2"), Vector2(500, 20), Vector2(750, 100), 0, 16, colw, "kAlignLeftMiddle"),
    ComFuc.ComLabel("notStartTip", GetMatchedUTF8Text(GetUTF8Text("UI_pet_fuhuosaiweikaishi,") .. "," .. "juesai"), Vector2(500, 20), Vector2(300, 350), 0, 18, colt, "kAlignCenterMiddle"),
    ComFuc.ComIconButton("quit", Vector2(114, 56), Vector2(855, 590), SkinF.icon_playgame_004, GetUTF8Text("button_common_Back"), SkinF.select_character_038, nil),
    ComFuc.ComButton("ruleReferral", GetUTF8Text("UI_pet_guizejieshao"), Vector2(114, 56), Vector2(976, 590), 16, false, false)
  })
})
local RequestFinalsState, SelAreaBtn = function(data)
  SeasonName = data.seasonName
  local startT, endT
  for j, v in ipairs(data.seasonInfo) do
    if v.type == 3 then
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
  ui.contest_timeTip.Text = GetMatchedUTF8Text("UI_pet_saijibanjiang_0_1," .. SeasonName .. "," .. "-" .. GetUTF8Text("juesai") .. "," .. ys .. "," .. ms .. "," .. ds .. "," .. ye .. "," .. me .. "," .. de)
end, {
  Gui.Control("main")({
    Size = Vector2(1128, 700),
    Gui.Control({
      Size = Vector2(1120, 33),
      Location = Vector2(4, 2),
      BackgroundColor = ARGB(255, 255, 255, 255),
      Skin = SkinF.battle_020[6],
      ComFuc.ComLabel("contest_timeTip", GetUTF8Text("UI_pet_saijijuesai"), Vector2(500, 20), Vector2(50, 5), 0, 16, colw, "kAlignLeftMiddle")
    }),
    ComFuc.ComControl("area_main", Vector2(1098, 578), Vector2(15, 78), 255, SkinF.personalInfo_131),
    ComFuc.SecMainTabBtn("btn_area_" .. 1, GetUTF8Text("UI_pet_asaiqu"), Vector2(100, 38), Vector2(30, 43)),
    ComFuc.SecMainTabBtn("btn_area_" .. 2, GetUTF8Text("UI_pet_bsaiqu"), Vector2(100, 38), Vector2(133, 43)),
    ComFuc.SecMainTabBtn("btn_area_" .. 3, GetUTF8Text("UI_pet_csaiqu"), Vector2(100, 38), Vector2(236, 43)),
    ComFuc.SecMainTabBtn("btn_area_" .. 4, GetUTF8Text("UI_pet_dsaiqu"), Vector2(100, 38), Vector2(339, 43)),
    ComFuc.SecMainTabBtn("btn_area_" .. 5, GetUTF8Text("UI_pet_zongjuesai"), Vector2(100, 38), Vector2(442, 43)),
    ComFuc.ComLabel("contest_detailsTip", GetUTF8Text("UI_pet_dianjizhanduitubiao_2"), Vector2(500, 20), Vector2(750, 100), 0, 16, colw, "kAlignLeftMiddle"),
    ComFuc.ComLabel("notStartTip", GetMatchedUTF8Text(GetUTF8Text("UI_pet_fuhuosaiweikaishi,") .. "," .. "juesai"), Vector2(500, 20), Vector2(300, 350), 0, 18, colt, "kAlignCenterMiddle"),
    ComFuc.ComIconButton("quit", Vector2(114, 56), Vector2(855, 590), SkinF.icon_playgame_004, GetUTF8Text("button_common_Back"), SkinF.select_character_038, nil),
    ComFuc.ComButton("ruleReferral", GetUTF8Text("UI_pet_guizejieshao"), Vector2(114, 56), Vector2(976, 590), 16, false, false)
  })
}

function SelAreaBtn(i)
  for j = 1, 5 do
    ui["btn_area_" .. j].PushDown = i == j
  end
end

function ui.quit.EventClick(sender, e)
  Hide()
  CompetitionSystem.SelectAthleticsMode(2)
end

function ui.ruleReferral.EventClick(sender, e)
  RuleReferral.Show(3)
end

for i = 1, 5 do
  ui["btn_area_" .. i].EventClick = function(sender, e)
    SelAreaBtn(i)
  end
end

function Show(winRoot)
  rpc.safecall("racing_season_info", {}, RequestFinalsState)
  ui.main.Parent = winRoot
end

function Hide()
  ui.main.Parent = nil
end
