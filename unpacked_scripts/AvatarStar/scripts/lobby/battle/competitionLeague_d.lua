module("CompetitionLeague", package.seeall)
require("competitionRuleReferral.lua")
require("BattleTeamList.lua")
local colw = ComFuc.colw
local colt = ComFuc.colt
ui = Gui.Create()({
  Gui.Control("main")({
    Size = Vector2(1128, 700),
    Gui.Control({
      Size = Vector2(1120, 33),
      Location = Vector2(4, 2),
      BackgroundColor = ARGB(255, 255, 255, 255),
      Skin = SkinF.battle_020[6],
      ComFuc.ComLabel("contest_timeTip", GetUTF8Text("UI_pet_saiji_0_1"), Vector2(500, 20), Vector2(23, 5), 0, 16, colw, "kAlignLeftMiddle")
    }),
    ComFuc.ComLabel("contest_detailsTip", GetUTF8Text("UI_pet_dianjizhanduitubiao_1"), Vector2(611, 15), Vector2(43, 54), 0, 16, colw, "kAlignLeftMiddle"),
    ComFuc.ComButton("refresh_btn", GetUTF8Text("button_store_refresh_AH"), Vector2(69, 40), Vector2(1037, 37), 16, false, false),
    Gui.Control("team_list")({
      Size = Vector2(1088, 504),
      Location = Vector2(20, 83),
      BackgroundColor = colw,
      Skin = SkinF.battle_bg
    }),
    ComFuc.ComLabel("notStartTip", GetMatchedUTF8Text(GetUTF8Text("UI_pet_fuhuosaiweikaishi,") .. "," .. "paiweisai"), Vector2(500, 20), Vector2(350, 350), 0, 18, colt, "kAlignCenterMiddle"),
    ComFuc.ComIconButton("quit", Vector2(115, 53), Vector2(24, 596), SkinF.icon_playgame_004, GetUTF8Text("button_common_Back"), SkinF.select_character_038, nil),
    ComFuc.ComButton("ruleReferral", GetUTF8Text("UI_pet_guizejieshao"), Vector2(115, 40), Vector2(751, 605), 16, false, false),
    ComFuc.ComButton("my_team_btn", GetUTF8Text("UI_pet_guizejieshao"), Vector2(115, 40), Vector2(871, 605), 16, false, false),
    ComFuc.ComButton("begin_match", GetUTF8Text("UI_pet_guizejieshao"), Vector2(115, 40), Vector2(991, 605), 16, false, false)
  })
})

function ui.quit.EventClick(sender, e)
  Hide()
  LobbyStartGame.SelectMainBtn(4)
end

function Show(winRoot)
  ui.main.Parent = winRoot
end

function Hide()
  ui.main.Parent = nil
end
