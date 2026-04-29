module("GmCameraControlB", package.seeall)
normal_text_color = ARGB(255, 136, 112, 97)
white_text_color = ARGB(255, 255, 255, 255)
camera_panel_b = Gui.Create(gui)({
  Gui.Control("root")({
    Size = Vector2(1596, 90),
    Location = Vector2(2, 809),
    BackgroundColor = ARGB(255, 255, 255, 255),
    Skin = SkinF.ingame_01,
    Gui.Label({
      Size = Vector2(202, 24),
      Location = Vector2(20, 13),
      Text = GetUTF8Text("UI_social_camera_01"),
      FontSize = 18,
      TextColor = normal_text_color
    }),
    Gui.ComboBox("combo_current_camera")({
      Size = Vector2(202, 34),
      Location = Vector2(20, 42)
    }),
    Gui.Label({
      Size = Vector2(300, 24),
      Location = Vector2(230, 13),
      Text = GetUTF8Text("UI_social_camera_02"),
      FontSize = 18,
      TextColor = normal_text_color
    }),
    Gui.Control({
      Size = Vector2(306, 34),
      Location = Vector2(230, 42),
      Gui.Label({
        Size = Vector2(188, 24),
        Location = Vector2(0, 7),
        Text = GetUTF8Text("UI_social_camera_03"),
        FontSize = 18,
        TextColor = normal_text_color
      }),
      Gui.Textbox("current_speed")({
        Size = Vector2(74, 34),
        Location = Vector2(190, 0),
        Text = "0",
        Number = true,
        MaxLength = 3,
        TextColor = white_text_color
      }),
      Gui.Label({
        Size = Vector2(38, 24),
        Location = Vector2(268, 7),
        Text = GetUTF8Text("UI_social_camera_04"),
        FontSize = 18,
        TextColor = normal_text_color
      })
    }),
    Gui.Control({
      Size = Vector2(264, 34),
      Location = Vector2(542, 42),
      Gui.Label({
        Size = Vector2(188, 24),
        Location = Vector2(0, 7),
        Text = GetUTF8Text("UI_social_camera_05"),
        FontSize = 18,
        TextColor = normal_text_color
      }),
      Gui.Textbox("textbox_mouse_speed")({
        Size = Vector2(74, 34),
        Location = Vector2(190, 0),
        Number = true,
        MaxLength = 3,
        Text = "1",
        TextColor = white_text_color
      })
    }),
    Gui.Slider("slider_mouse_speed")({
      Location = Vector2(810, 44),
      ThumbSize = Vector2(28, 30),
      Size = Vector2(130, 30),
      IsInt = true,
      MinValue = 1,
      MaxValue = 100
    }),
    Gui.Control({
      Size = Vector2(264, 34),
      Location = Vector2(542, 6),
      Gui.Label({
        Size = Vector2(93, 24),
        Location = Vector2(0, 7),
        Text = GetUTF8Text("UI_social_camera_06"),
        FontSize = 18,
        TextColor = normal_text_color
      }),
      Gui.Textbox("focus_length")({
        Size = Vector2(74, 34),
        Location = Vector2(97, 0),
        Number = true,
        MaxLength = 3,
        Text = "65",
        TextColor = white_text_color
      })
    }),
    Gui.Label({
      Size = Vector2(200, 24),
      Location = Vector2(893, 13),
      Text = GetUTF8Text("UI_social_camera_07"),
      FontSize = 18,
      TextAlign = "kAlignRightMiddle",
      TextColor = normal_text_color
    }),
    Gui.Control({
      Size = Vector2(300, 34),
      Location = Vector2(1100, 6),
      Gui.Label({
        Size = Vector2(188, 24),
        Location = Vector2(0, 7),
        Text = GetUTF8Text("UI_social_camera_08"),
        FontSize = 18,
        TextColor = normal_text_color
      }),
      Gui.Textbox("back_shift")({
        Size = Vector2(74, 34),
        Location = Vector2(190, 0),
        Number = true,
        MaxLength = 3,
        Text = "2",
        TextColor = white_text_color
      }),
      Gui.Label({
        Size = Vector2(32, 24),
        Location = Vector2(268, 7),
        Text = GetUTF8Text("UI_social_camera_10"),
        FontSize = 18,
        TextColor = normal_text_color
      })
    }),
    Gui.Control({
      Size = Vector2(300, 34),
      Location = Vector2(1100, 42),
      Gui.Label({
        Size = Vector2(188, 24),
        Location = Vector2(0, 7),
        Text = GetUTF8Text("UI_social_camera_09"),
        FontSize = 18,
        TextColor = normal_text_color
      }),
      Gui.Textbox("up_shift")({
        Size = Vector2(74, 34),
        Location = Vector2(190, 0),
        Number = true,
        MaxLength = 3,
        Text = "2",
        TextColor = white_text_color
      }),
      Gui.Label({
        Size = Vector2(32, 24),
        Location = Vector2(268, 7),
        Text = GetUTF8Text("UI_social_camera_10"),
        FontSize = 18,
        TextColor = normal_text_color
      })
    }),
    Gui.CheckBox("red_switch")({
      Location = Vector2(1442, 16),
      Size = Vector2(143, 28),
      FontSize = 16,
      TextColor = normal_text_color,
      Text = GetUTF8Text("UI_social_camera_11"),
      FontSize = 18
    }),
    Gui.CheckBox("blue_switch")({
      Location = Vector2(1442, 46),
      Size = Vector2(143, 28),
      FontSize = 16,
      TextColor = normal_text_color,
      Text = GetUTF8Text("UI_social_camera_12"),
      FontSize = 18
    })
  })
})

function SetSliderValue(textbox_control, slider_control)
  local value = tonumber(textbox_control.Text)
  if value then
    if 100 < value then
      value = 100
    end
    if value < 1 then
      value = 1
    end
    slider_control.CurValue = value
  end
end

function ChangeCameraMode(new_mode)
  if new_mode == 1 then
    camera_panel_b.combo_current_camera.SelectedIndexSilent = 7
  end
  if new_mode == 2 then
    camera_panel_b.combo_current_camera.SelectedIndexSilent = 6
  end
end

function ChangePlayerHeaderMode(red_check, blue_check)
  local header_mode = -1
  if red_check then
    if blue_check then
      header_mode = 2
    else
      header_mode = 0
    end
  elseif blue_check then
    header_mode = 1
  else
    header_mode = -1
  end
  local main_game_state = ptr_cast(game.CurrentState, "Client.StateMainGame")
  if main_game_state then
    main_game_state:GM_SetShowPlayerHeader(header_mode)
  end
end

function Initialize()
  local current_observer_id = 3
  camera_panel_b.combo_current_camera:AddItem("observer" .. current_observer_id .. "AC")
  for i = 1, 5 do
    camera_panel_b.combo_current_camera:AddItem("observer" .. current_observer_id .. "C" .. i)
  end
  camera_panel_b.combo_current_camera:AddItem("observer" .. current_observer_id .. "PC")
  camera_panel_b.combo_current_camera:AddItem("observer" .. current_observer_id .. "FC")
  camera_panel_b.combo_current_camera.SelectedIndex = 0
  
  function camera_panel_b.combo_current_camera.EventValueChanged(sender, e)
    local main_game_state = ptr_cast(game.CurrentState, "Client.StateMainGame")
    if main_game_state then
      main_game_state:GM_ChangeCameraMode(sender.SelectedIndex)
    end
  end
  
  function camera_panel_b.current_speed.EventValueEnter(sender, e)
    local value = tonumber(sender.Text)
    if value then
      if 10 < value then
        value = 10
        sender.Text = "10"
      end
      local main_game_state = ptr_cast(game.CurrentState, "Client.StateMainGame")
      if main_game_state then
        main_game_state:GM_SetCameraMoveSpeed(value)
      end
    end
  end
  
  function camera_panel_b.focus_length.EventValueEnter(sender, e)
    local value = tonumber(sender.Text)
    if value then
      if 178 < value then
        value = 178
        sender.Text = "178"
      end
      local main_game_state = ptr_cast(game.CurrentState, "Client.StateMainGame")
      if main_game_state then
        main_game_state:GM_SetCameraFov(value)
      end
    end
  end
  
  function camera_panel_b.back_shift.EventValueEnter(sender, e)
    local hori_value = tonumber(sender.Text)
    local vert_value = tonumber(camera_panel_b.up_shift.Text)
    if hori_value and vert_value then
      local main_game_state = ptr_cast(game.CurrentState, "Client.StateMainGame")
      if main_game_state then
        main_game_state:GM_SetCameraShift(hori_value, vert_value)
      end
    end
  end
  
  function camera_panel_b.up_shift.EventValueEnter(sender, e)
    local vert_value = tonumber(sender.Text)
    local hori_value = tonumber(camera_panel_b.back_shift.Text)
    if hori_value and vert_value then
      local main_game_state = ptr_cast(game.CurrentState, "Client.StateMainGame")
      if main_game_state then
        main_game_state:GM_SetCameraShift(hori_value, vert_value)
      end
    end
  end
  
  function camera_panel_b.red_switch.EventCheckChanged(sender, e)
    local red_check = sender.Check
    local blue_check = camera_panel_b.blue_switch.Check
    ChangePlayerHeaderMode(red_check, blue_check)
  end
  
  function camera_panel_b.blue_switch.EventCheckChanged(sender, e)
    local red_check = camera_panel_b.red_switch.Check
    local blue_check = sender.Check
    ChangePlayerHeaderMode(red_check, blue_check)
  end
  
  camera_panel_b.root.Parent = gui
  camera_panel_b.root.Visible = false
  camera_panel_b.slider_mouse_speed.CurValue = 1
  
  function camera_panel_b.textbox_mouse_speed.EventValueEnter(sender, e)
    SetSliderValue(camera_panel_b.textbox_mouse_speed, camera_panel_b.slider_mouse_speed)
  end
  
  function camera_panel_b.textbox_mouse_speed.EventActiveChanged(sender, e)
    if not sender.Active then
      SetSliderValue(camera_panel_b.textbox_mouse_speed, camera_panel_b.slider_mouse_speed)
    end
  end
  
  function camera_panel_b.slider_mouse_speed.EventValueChange(sender, e)
    camera_panel_b.textbox_mouse_speed.Text = sender.CurValue
    local main_game_state = ptr_cast(game.CurrentState, "Client.StateMainGame")
    if main_game_state then
      main_game_state:GM_SetCameraRotationSentitivity(sender.CurValue)
    end
  end
end

function Finalize()
  camera_panel_b.combo_current_camera:RemoveAll()
  camera_panel_b.combo_current_camera.EventValueChanged = nil
  camera_panel_b.current_speed.EventValueEnter = nil
  camera_panel_b.focus_length.EventValueEnter = nil
  camera_panel_b.back_shift.EventValueEnter = nil
  camera_panel_b.up_shift.EventValueEnter = nil
  camera_panel_b.red_switch.EventCheckChanged = nil
  camera_panel_b.blue_switch.EventCheckChanged = nil
  camera_panel_b.textbox_mouse_speed.EventValueEnter = nil
  camera_panel_b.textbox_mouse_speed.EventActiveChanged = nil
  camera_panel_b.slider_mouse_speed.EventValueChange = nil
  camera_panel_b.root.Visible = false
end

function Show()
  camera_panel_b.root.Visible = true
end

function Hide()
  camera_panel_b.root.Visible = false
  camera_panel_b.combo_current_camera.Focused = false
end

function ResetParam()
  camera_panel_b.current_speed.Text = "0"
  camera_panel_b.focus_length.Text = "65"
  camera_panel_b.back_shift.Text = "2"
  camera_panel_b.up_shift.Text = "2"
  camera_panel_b.red_switch.Check = false
  camera_panel_b.blue_switch.Check = false
  camera_panel_b.textbox_mouse_speed.Text = "1"
  camera_panel_b.slider_mouse_speed.CurValue = 1
end
