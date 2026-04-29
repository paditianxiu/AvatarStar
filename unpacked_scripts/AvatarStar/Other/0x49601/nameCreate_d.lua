module("NameCreate", package.seeall)
local colw = ComFuc.colw
local cols = ComFuc.cols
local td = {}
local ui, InitInterface = Gui.Create()({
  ComFuc.ComControl("cover", Vector2(1600, 1200), Vector2(0, 0), 0),
  Gui.Control("main")({
    Size = Vector2(312, 200),
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_206,
    ComFuc.ComControl(nil, Vector2(286, 100), Vector2(12, 40), 255, SkinF.battle_005),
    ComFuc.ComLabel("title", "", Vector2(302, 21), Vector2(16, 4), 0, 16, colw),
    ComFuc.ComLabel("tips", "", Vector2(296, 22), Vector2(32, 52), 0, 16, cols),
    ComFuc.ComTextBox("name", "", Vector2(248, 38), Vector2(32, 84), 14),
    ComFuc.ComButton("sure", GetUTF8Text("button_common_OK"), Vector2(84, 43), Vector2(40, 148), nil, false, true),
    ComFuc.ComButton("cancel", GetUTF8Text("button_common_Cancel"), Vector2(84, 43), Vector2(188, 148), nil, false, true),
    ComFuc.ComButton("close", nil, Vector2(24, 24), Vector2(280, 4), 0, false, false, SkinF.lookInfo_002)
  })
}), {
  ComFuc.ComControl("cover", Vector2(1600, 1200), Vector2(0, 0), 0),
  Gui.Control("main")({
    Size = Vector2(312, 200),
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_206,
    ComFuc.ComControl(nil, Vector2(286, 100), Vector2(12, 40), 255, SkinF.battle_005),
    ComFuc.ComLabel("title", "", Vector2(302, 21), Vector2(16, 4), 0, 16, colw),
    ComFuc.ComLabel("tips", "", Vector2(296, 22), Vector2(32, 52), 0, 16, cols),
    ComFuc.ComTextBox("name", "", Vector2(248, 38), Vector2(32, 84), 14),
    ComFuc.ComButton("sure", GetUTF8Text("button_common_OK"), Vector2(84, 43), Vector2(40, 148), nil, false, true),
    ComFuc.ComButton("cancel", GetUTF8Text("button_common_Cancel"), Vector2(84, 43), Vector2(188, 148), nil, false, true),
    ComFuc.ComButton("close", nil, Vector2(24, 24), Vector2(280, 4), 0, false, false, SkinF.lookInfo_002)
  })
}
local InitInterface, SetNameSure = function()
  ui.title.Text = td.title
  ui.tips.Text = td.tips
  ui.name.Text = ""
end, ComFuc.ComControl("cover", Vector2(1600, 1200), Vector2(0, 0), 0)

function SetNameSure()
  local isOpenIme = false
  for i = 1, 100 do
    if string.byte(ui.name.Text, i) and string.byte(ui.name.Text, i) > 128 then
      isOpenIme = true
      break
    end
  end
  if ui.name.Text == "" then
    MessageBox.ShowError(GetUTF8Text("UI_pet_function_05"))
  elseif game.local_language == "en_sg" and (isOpenIme or string.len(ui.name.Text) < 3) then
    if isOpenIme then
      MessageBox.ShowError(GetUTF8Text("msgbox_common_conditionkey_015"))
    elseif string.len(ui.name.Text) < 3 then
      MessageBox.ShowError(GetUTF8Text("msgbox_common_name_limit_client"))
    end
  else
    if td and td.funcSure then
      td.funcSure()
    end
    Hide()
  end
end

function ui.name.EventValueEnter()
  SetNameSure()
end

function ui.sure.EventClick()
  SetNameSure()
end

function ui.cancel.EventClick()
  Hide()
end

function ui.close.EventClick()
  Hide()
end

function GetInputName()
  return ui.name.Text
end

function Show(data)
  td = data
  InitInterface()
  ui.cover.Parent = gui
  ui.main.Parent = gui
  Gui.Align(ui.main, 0.5, 0.5)
end

function Hide()
  ui.cover.Parent = nil
  ui.main.Parent = nil
end
