module("CompetitionSystem", package.seeall)
require("CompetitionLeague.lua")
require("CompetitionChampion.lua")
local colw = ComFuc.colw
local colt = ComFuc.colt
local winParent
local ui_mgr = require("competitionModeManage.lua")
local competitionMgr = ui_mgr:create()
competitionMgr:push("athletics_btn1", CompetitionLeague)
competitionMgr:push("athletics_btn2", CompetitionChampion)
local title_text = {
  GetUTF8Text("UI_pet_cup_paiweisai"),
  GetUTF8Text("UI_pet_cup_fuhuosai")
}
ui = Gui.Create()({
  Gui.Control("root")({
    Size = Vector2(1128, 700),
    Gui.Control({
      Size = Vector2(1120, 33),
      Location = Vector2(4, 2),
      BackgroundColor = colw,
      Skin = SkinF.battle_020[6]
    }),
    ComFuc.ComButton("athletics_btn1", "liansai", Vector2(200, 300), Vector2(280, 130), 16, false, false),
    ComFuc.ComButton("athletics_btn2", "guanjunbei", Vector2(200, 300), Vector2(600, 130), 16, false, false),
    ComFuc.ComIconButton("quit", Vector2(114, 56), Vector2(30, 580), SkinF.icon_playgame_004, GetUTF8Text("button_common_Back"), SkinF.select_character_038, nil)
  })
})

function SelectAthleticsMode(i)
  competitionMgr:switch("athletics_btn" .. i, winParent)
end

for i = 1, 2 do
  ui["athletics_btn" .. i].EventClick = function(sender, e)
    Hide()
    SelectAthleticsMode(i)
    LobbyStartGame.ui.lbl_game_type.Text = title_text[i]
  end
end

function ui.quit.EventClick(sender, e)
  LobbyStartGame.SelectMainBtn(1)
end

function Show(winRoot)
  if not winRoot then
    Hide()
  else
    winParent = winRoot
    ui.root.Parent = winRoot
  end
end

function Hide()
  ui.root.Parent = nil
end
