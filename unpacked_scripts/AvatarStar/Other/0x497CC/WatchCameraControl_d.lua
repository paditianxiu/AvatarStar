local WatchCameraControl = {}
local gm_view_player_list
normal_text_color = ARGB(255, 205, 205, 205)
white_text_color = ARGB(255, 255, 255, 255)
local SIZE, create_fx = Vector2(570, 130), 570

function create_fx(name, text, size, pos)
  return Gui.Button(name)({
    Size = size or Vector2(84, 40),
    Location = pos,
    Text = text,
    FontSize = 13,
    Skin = SkinF.ingame_button_camera_mode,
    Enable = enable,
    ClickAudio = ado,
    Padding = Vector4(4, 14, 3, 0)
  })
end

local camera_panel_b, click_fx = Gui.Create(gui)({
  Gui.Control("root")({
    Size = SIZE,
    Location = Vector2((gui.Size.x - SIZE.x) / 2, gui.Size.y - SIZE.y),
    BackgroundColor = ARGB(255, 255, 255, 255),
    Skin = SkinF.ingame_01,
    Gui.Label({
      Size = Vector2(230, 15),
      Location = Vector2(20, 21),
      Text = GetUTF8Text("UI_pet_qiehuanshexiangji"),
      FontSize = 15,
      TextColor = normal_text_color
    }),
    Gui.Label({
      Size = Vector2(80, 15),
      Location = Vector2(31, 55),
      Text = GetUTF8Text("UI_pet_dianji_01"),
      FontSize = 15,
      TextColor = normal_text_color,
      TextAlign = "kAlignRightMiddle"
    }),
    Gui.Label({
      Size = Vector2(80, 15),
      Location = Vector2(31, 84),
      Text = GetUTF8Text("UI_pet_dianji_01"),
      FontSize = 15,
      TextColor = normal_text_color,
      TextAlign = "kAlignRightMiddle"
    }),
    Gui.Label({
      Size = Vector2(214, 15),
      Location = Vector2(151, 55),
      Text = GetUTF8Text("UI_pet_wanjiashexiangji"),
      FontSize = 15,
      TextColor = normal_text_color
    }),
    Gui.Label({
      Size = Vector2(214, 15),
      Location = Vector2(151, 84),
      Text = GetUTF8Text("UI_pet_zhuizongshexiangji"),
      FontSize = 15,
      TextColor = normal_text_color
    }),
    Gui.Control({
      Size = Vector2(22, 21),
      Location = Vector2(117, 54),
      BackgroundColor = ARGB(255, 255, 255, 255),
      Skin = SkinF.ingame_button_pcamera_lock
    }),
    Gui.Control({
      Size = Vector2(22, 21),
      Location = Vector2(117, 88),
      BackgroundColor = ARGB(255, 255, 255, 255),
      Skin = SkinF.ingame_button_pcamera_trace
    }),
    Gui.Label({
      Size = Vector2(110, 15),
      Location = Vector2(436, 23),
      Text = GetUTF8Text("id_lobby_kaiguandanmu"),
      FontSize = 15,
      TextColor = normal_text_color
    }),
    Gui.CheckBox("is_open_barrage")({
      Location = Vector2(410, 20),
      Size = Vector2(24, 24),
      Check = true
    }),
    Gui.Label({
      Size = Vector2(130, 15),
      Location = Vector2(410, 54),
      Text = GetUTF8Text("UI_pet_ziyoushexiangji"),
      FontSize = 15,
      TextColor = normal_text_color
    }),
    create_fx("trace_F1", "F1", Vector2(32, 36), Vector2(408, 78)),
    create_fx("trace_F2", "F2", Vector2(32, 36), Vector2(452, 78)),
    create_fx("trace_F3", "F3", Vector2(32, 36), Vector2(494, 78))
  })
}), Gui.Create(gui)({
  Gui.Control("root")({
    Size = SIZE,
    Location = Vector2((gui.Size.x - SIZE.x) / 2, gui.Size.y - SIZE.y),
    BackgroundColor = ARGB(255, 255, 255, 255),
    Skin = SkinF.ingame_01,
    Gui.Label({
      Size = Vector2(230, 15),
      Location = Vector2(20, 21),
      Text = GetUTF8Text("UI_pet_qiehuanshexiangji"),
      FontSize = 15,
      TextColor = normal_text_color
    }),
    Gui.Label({
      Size = Vector2(80, 15),
      Location = Vector2(31, 55),
      Text = GetUTF8Text("UI_pet_dianji_01"),
      FontSize = 15,
      TextColor = normal_text_color,
      TextAlign = "kAlignRightMiddle"
    }),
    Gui.Label({
      Size = Vector2(80, 15),
      Location = Vector2(31, 84),
      Text = GetUTF8Text("UI_pet_dianji_01"),
      FontSize = 15,
      TextColor = normal_text_color,
      TextAlign = "kAlignRightMiddle"
    }),
    Gui.Label({
      Size = Vector2(214, 15),
      Location = Vector2(151, 55),
      Text = GetUTF8Text("UI_pet_wanjiashexiangji"),
      FontSize = 15,
      TextColor = normal_text_color
    }),
    Gui.Label({
      Size = Vector2(214, 15),
      Location = Vector2(151, 84),
      Text = GetUTF8Text("UI_pet_zhuizongshexiangji"),
      FontSize = 15,
      TextColor = normal_text_color
    }),
    Gui.Control({
      Size = Vector2(22, 21),
      Location = Vector2(117, 54),
      BackgroundColor = ARGB(255, 255, 255, 255),
      Skin = SkinF.ingame_button_pcamera_lock
    }),
    Gui.Control({
      Size = Vector2(22, 21),
      Location = Vector2(117, 88),
      BackgroundColor = ARGB(255, 255, 255, 255),
      Skin = SkinF.ingame_button_pcamera_trace
    }),
    Gui.Label({
      Size = Vector2(110, 15),
      Location = Vector2(436, 23),
      Text = GetUTF8Text("id_lobby_kaiguandanmu"),
      FontSize = 15,
      TextColor = normal_text_color
    }),
    Gui.CheckBox("is_open_barrage")({
      Location = Vector2(410, 20),
      Size = Vector2(24, 24),
      Check = true
    }),
    Gui.Label({
      Size = Vector2(130, 15),
      Location = Vector2(410, 54),
      Text = GetUTF8Text("UI_pet_ziyoushexiangji"),
      FontSize = 15,
      TextColor = normal_text_color
    }),
    create_fx("trace_F1", "F1", Vector2(32, 36), Vector2(408, 78)),
    create_fx("trace_F2", "F2", Vector2(32, 36), Vector2(452, 78)),
    create_fx("trace_F3", "F3", Vector2(32, 36), Vector2(494, 78))
  })
})

function click_fx(index)
  if index == 3 then
    index = 0
  end
  return function(sender, e)
    local main_game_state = ptr_cast(game.CurrentState, "Client.StateMainGame")
    if main_game_state then
      main_game_state:GM_ChangeCameraMode(index)
    end
  end
end

for i = 1, 3 do
  camera_panel_b["trace_F" .. i].EventClick = click_fx(i)
end

function camera_panel_b.is_open_barrage.EventCheckChanged(sender, e)
  local main_game_state = ptr_cast(game.CurrentState, "Client.StateMainGame")
  if main_game_state then
    main_game_state:SetBarrageMark(camera_panel_b.is_open_barrage.Check)
  end
end

function WatchCameraControl.Initialize()
  WatchCameraControl.RefreshPlayerList()
  local main_game_state = ptr_cast(game.CurrentState, "Client.StateMainGame")
  if main_game_state then
    main_game_state:GM_SetShowPlayerHeader(2)
  end
  camera_panel_b.root.Parent = gui
  camera_panel_b.root.Visible = false
end

function WatchCameraControl.Finalize()
  camera_panel_b.root.Visible = false
end

function WatchCameraControl.Show()
  camera_panel_b.root.Visible = true
end

function WatchCameraControl.Hide()
  camera_panel_b.root.Visible = false
end

function WatchCameraControl.ResetParam()
end

function WatchCameraControl.RefreshPlayerList()
end

return WatchCameraControl
