module("ExpeditionRoomSet", package.seeall)
if not ExpeditionRoomCreate then
  require("expeditionRoomCreate.lua")
end
local word_color = ARGB(255, 82, 54, 44)
local room_info
ui = Gui.Create()({
  Gui.Control("main")({
    Dock = "kDockFill",
    BackgroundColor = ARGB(128, 0, 0, 0),
    Gui.Control({
      Size = Vector2(346, 402),
      Dock = "kDockCenter",
      BackgroundColor = ComFuc.colw,
      Skin = SkinF.personalInfo_207,
      ComFuc.ComLabel(nil, GetUTF8Text("button_common_Room_Setting"), Vector2(300, 24), Vector2(12, 4), 0, 16, ComFuc.colw),
      ComFuc.ComButton("quit", nil, Vector2(24, 24), Vector2(314, 4), 16, false, false, SkinF.lookInfo_002),
      Gui.Control({
        Size = Vector2(313, 282),
        Location = Vector2(17, 39),
        BackgroundColor = ComFuc.colw,
        Skin = SkinF.battle_005,
        ComFuc.ComLabel(nil, GetUTF8Text("UI_battlefield_Room_Name") .. ":", Vector2(73, 24), Vector2(11, 27), 0, 16, word_color, "kAlignRightMiddle"),
        ComFuc.ComTextBox("room_name", nil, Vector2(192, 34), Vector2(90, 24)),
        ComFuc.ComLabel(nil, GetUTF8Text("UI_battlefield_Room_Password") .. ":", Vector2(73, 24), Vector2(11, 86), 0, 16, word_color, "kAlignRightMiddle"),
        ComFuc.ComTextBox("room_password", nil, Vector2(192, 34), Vector2(90, 83), 6),
        ComFuc.ComCheckBox("condition1", GetUTF8Text("UI_common_bukejinru"), Vector2(293, 40), Vector2(12, 172), 12, word_color),
        ComFuc.ComCheckBox("condition2", GetUTF8Text("UI_common_zhongtujiaru_shezhi"), Vector2(293, 40), Vector2(12, 219), 12, word_color)
      }),
      ComFuc.ComButton("save", GetUTF8Text("button_common_OK"), Vector2(74, 40), Vector2(218, 343), 16, false, false),
      ComFuc.ComButton("cancel", GetUTF8Text("button_common_Cancel"), Vector2(74, 40), Vector2(54, 343), 16, false, false)
    })
  })
})
ui.condition1.Check = true
ui.condition2.Check = true
ui.room_name.Readonly = true
ui.room_password.Focused = true

function Hide()
  ui.room_name.Text = ""
  ui.room_password.Text = ""
  ui.condition1.Check = false
  ui.condition2.Check = false
  ui.main.Parent = nil
end

function Show()
  local state = ptr_cast(game.CurrentState)
  local room_info = state:GetSelfRoomInfo()
  if room_info.RoomState == 2 then
    MessageBox.ShowError(GetUTF8Text("msgbox_battlefield_additional_string_133"), show_error_time)
    return
  end
  Hide()
  if room_info then
    ui.room_name.Text = room_info.RoomName
    if room_info.UsePassword then
      ui.room_password.Text = room_info.Password
    else
      ui.room_password.Text = ""
    end
    local enter_limit = room_info.EnterLimit
    for i = 1, 2 do
      ui["condition" .. i].Check = bit.band(enter_limit, i) == i
    end
  end
  ui.main.Parent = gui
end

function ui.quit.EventClick(sender, e)
  Hide()
end

function ui.cancel.EventClick(sender, e)
  Hide()
end

function ui.save.EventClick(sender, e)
  local enter_limit = 0
  for i = 1, 2 do
    if ui["condition" .. i].Check then
      enter_limit = bit.bor(enter_limit, i)
    end
  end
  ExpeditionRoomCreate.ChangeRoomOption(ui.room_password.Text, enter_limit)
  Hide()
end

function SetInfo(info)
  if not info then
    return
  end
  room_info = info
end
