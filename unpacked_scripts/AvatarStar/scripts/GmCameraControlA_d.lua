module("GmCameraControlA", package.seeall)
normal_text_color = ARGB(255, 136, 112, 97)
white_text_color = ARGB(255, 255, 255, 255)
gm_view_player_list_red = {}
gm_view_player_list_blue = {}

function OnePlayerLine_L(index, line_pos)
  return Gui.Control("line_" .. index)({
    Size = Vector2(240, 31),
    Location = line_pos,
    Gui.Control("career_icon_" .. index)({
      Style = "",
      BackgroundColor = ARGB(255, 255, 255, 255),
      Size = Vector2(31, 31),
      Location = Vector2(0, 0),
      Skin = SkinF.personalInfo_job[1]
    }),
    Gui.ProportionBar("hp_" .. index)({
      Size = Vector2(150, 23),
      Location = Vector2(29, 5),
      MaxValue = 100,
      CurrentValue = 50,
      TextColor = ARGB(255, 255, 255, 255),
      TextShadowColor = ARGB(255, 64, 64, 64),
      TextAlign = "kAlignLeftMiddle",
      DrawCustomText = true,
      Text = "Player_Name" .. index,
      Icon = Gui.ProportionIcon("/ui/skinF/skin_ingame_gm_hp01.tga", "/ui/skinF/skin_ingame_gm_hp03.tga", Vector4(6, 6, 6, 6), Vector4(6, 6, 6, 6))
    }),
    Gui.Label("lv_" .. index)({
      Size = Vector2(25, 12),
      Location = Vector2(155, 5),
      FontSize = 12,
      Text = "Lv30"
    }),
    Gui.Button("pc_lock_" .. index)({
      Skin = SkinF.ingame_button_pcamera_lock,
      Size = Vector2(22, 21),
      Location = Vector2(188, 6)
    }),
    Gui.Button("pc_trace_" .. index)({
      Skin = SkinF.ingame_button_pcamera_trace,
      Size = Vector2(22, 21),
      Location = Vector2(218, 6)
    })
  })
end

camera_panel_a_L = Gui.Create(gui)({
  Gui.Control("root")({
    Size = Vector2(240, 248),
    Location = Vector2(6, 557),
    BackgroundColor = ARGB(0, 255, 255, 64),
    OnePlayerLine_L(1, Vector2(0, 0)),
    OnePlayerLine_L(2, Vector2(0, 31)),
    OnePlayerLine_L(3, Vector2(0, 62)),
    OnePlayerLine_L(4, Vector2(0, 93)),
    OnePlayerLine_L(5, Vector2(0, 124)),
    OnePlayerLine_L(6, Vector2(0, 155)),
    OnePlayerLine_L(7, Vector2(0, 186)),
    OnePlayerLine_L(8, Vector2(0, 217))
  })
})

function OnePlayerLine_R(index, line_pos)
  return Gui.Control("line_" .. index)({
    Size = Vector2(240, 31),
    Location = line_pos,
    Gui.Button("pc_trace_" .. index)({
      Skin = SkinF.ingame_button_pcamera_trace,
      Size = Vector2(22, 21),
      Location = Vector2(0, 6)
    }),
    Gui.Button("pc_lock_" .. index)({
      Skin = SkinF.ingame_button_pcamera_lock,
      Size = Vector2(22, 21),
      Location = Vector2(30, 6)
    }),
    Gui.Control("career_icon_" .. index)({
      Style = "",
      BackgroundColor = ARGB(255, 255, 255, 255),
      Size = Vector2(31, 31),
      Location = Vector2(60, 0),
      Skin = SkinF.personalInfo_job[1]
    }),
    Gui.ProportionBar("hp_" .. index)({
      Size = Vector2(150, 23),
      Location = Vector2(90, 5),
      MaxValue = 100,
      CurrentValue = 50,
      TextColor = ARGB(255, 255, 255, 255),
      TextShadowColor = ARGB(255, 64, 64, 64),
      TextAlign = "kAlignLeftMiddle",
      DrawCustomText = true,
      Text = "Player_Name" .. index,
      Icon = Gui.ProportionIcon("/ui/skinF/skin_ingame_gm_hp01.tga", "/ui/skinF/skin_ingame_gm_hp02.tga", Vector4(6, 6, 6, 6), Vector4(6, 6, 6, 6))
    }),
    Gui.Label("lv_" .. index)({
      Size = Vector2(25, 12),
      Location = Vector2(215, 5),
      FontSize = 12,
      Text = "Lv30"
    })
  })
end

camera_panel_a_R = Gui.Create(gui)({
  Gui.Control("root")({
    Size = Vector2(240, 248),
    Location = Vector2(1354, 557),
    BackgroundColor = ARGB(0, 255, 255, 64),
    OnePlayerLine_R(1, Vector2(0, 0)),
    OnePlayerLine_R(2, Vector2(0, 31)),
    OnePlayerLine_R(3, Vector2(0, 62)),
    OnePlayerLine_R(4, Vector2(0, 93)),
    OnePlayerLine_R(5, Vector2(0, 124)),
    OnePlayerLine_R(6, Vector2(0, 155)),
    OnePlayerLine_R(7, Vector2(0, 186)),
    OnePlayerLine_R(8, Vector2(0, 217))
  })
})

function Initialize()
  for i = 1, 8 do
    camera_panel_a_L["line_" .. i].Visible = false
  end
  for i = 1, 8 do
    camera_panel_a_R["line_" .. i].Visible = false
  end
  camera_panel_a_L.root.Parent = gui
  camera_panel_a_R.root.Parent = gui
  camera_panel_a_L.root.Visible = false
  camera_panel_a_R.root.Visible = false
end

function Finalize()
  camera_panel_a_L.root.Visible = false
  camera_panel_a_R.root.Visible = false
end

function Show()
  local screen_width = gui.Size.x
  camera_panel_a_R.root.Location = Vector2(screen_width - 240 - 6, 557)
  camera_panel_a_L.root.Visible = true
  camera_panel_a_R.root.Visible = true
end

function Hide()
  camera_panel_a_L.root.Visible = false
  camera_panel_a_R.root.Visible = false
end

function RelocateWindows()
  local new_width = gui.Size.x
  camera_panel_a_R.root.Location = Vector2(new_width - 240 - 6, 557)
end

function RefreshPlayerList()
  local stm = ptr_cast(game.CurrentState, "Client.StateMainGame")
  if stm then
    for i = 1, 8 do
      camera_panel_a_L["line_" .. i].Visible = false
      camera_panel_a_L["pc_trace_" .. i].EventClick = nil
      camera_panel_a_L["pc_lock_" .. i].EventClick = nil
    end
    for i = 1, 8 do
      camera_panel_a_R["line_" .. i].Visible = false
      camera_panel_a_R["pc_trace_" .. i].EventClick = nil
      camera_panel_a_R["pc_lock_" .. i].EventClick = nil
    end
    gm_view_player_list_red = {}
    gm_view_player_list_blue = {}
    local player_count = stm:GetIngamePlayerCount()
    for i = 1, player_count do
      local current_player = stm:GetGmCharacterBaseInfo(i - 1)
      if current_player and not current_player.is_viewer then
        if current_player.team == 0 then
          table.insert(gm_view_player_list_red, current_player)
        elseif current_player.team == 1 then
          table.insert(gm_view_player_list_blue, current_player)
        end
      end
    end
    for i = 1, #gm_view_player_list_red do
      local current_player = gm_view_player_list_red[i]
      camera_panel_a_L["career_icon_" .. i].Skin = SkinF.personalInfo_job[current_player.career + 1]
      camera_panel_a_L["hp_" .. i].MaxValue = current_player.max_hp
      camera_panel_a_L["hp_" .. i].CurrentValue = current_player.hp
      camera_panel_a_L["hp_" .. i].Text = current_player.character_name
      camera_panel_a_L["lv_" .. i].Text = "Lv" .. current_player.level
      camera_panel_a_L["pc_trace_" .. i].EventClick = function(sender, e)
        local main_game_state = ptr_cast(game.CurrentState, "Client.StateMainGame")
        if main_game_state then
          main_game_state:GM_TracePlayerCamera(current_player.uid, false)
          GmCameraControlB.ChangeCameraMode(1)
        end
      end
      camera_panel_a_L["pc_lock_" .. i].EventClick = function(sender, e)
        local main_game_state = ptr_cast(game.CurrentState, "Client.StateMainGame")
        if main_game_state then
          main_game_state:GM_TracePlayerCamera(current_player.uid, true)
          GmCameraControlB.ChangeCameraMode(2)
        end
      end
      camera_panel_a_L["line_" .. i].Visible = true
    end
    for i = 1, #gm_view_player_list_blue do
      local current_player = gm_view_player_list_blue[i]
      camera_panel_a_R["career_icon_" .. i].Skin = SkinF.personalInfo_job[current_player.career + 1]
      camera_panel_a_R["hp_" .. i].MaxValue = current_player.max_hp
      camera_panel_a_R["hp_" .. i].CurrentValue = current_player.hp
      camera_panel_a_R["hp_" .. i].Text = current_player.character_name
      camera_panel_a_R["lv_" .. i].Text = "Lv" .. current_player.level
      camera_panel_a_R["pc_trace_" .. i].EventClick = function(sender, e)
        local main_game_state = ptr_cast(game.CurrentState, "Client.StateMainGame")
        if main_game_state then
          main_game_state:GM_TracePlayerCamera(current_player.uid, false)
          GmCameraControlB.ChangeCameraMode(1)
        end
      end
      camera_panel_a_R["pc_lock_" .. i].EventClick = function(sender, e)
        local main_game_state = ptr_cast(game.CurrentState, "Client.StateMainGame")
        if main_game_state then
          main_game_state:GM_TracePlayerCamera(current_player.uid, true)
          GmCameraControlB.ChangeCameraMode(2)
        end
      end
      camera_panel_a_R["line_" .. i].Visible = true
    end
    local boss = stm:GetGmCharacterBaseInfo(10000)
    if boss and string.len(boss.character_name) > 5 then
      camera_panel_a_R["career_icon_" .. 1].Skin = SkinF.boss_small_icon
      camera_panel_a_R.pc_trace_1.Parent = nil
      camera_panel_a_R.pc_lock_1.Parent = nil
      camera_panel_a_R["lv_" .. 1].Text = ""
      camera_panel_a_R["hp_" .. 1].MaxValue = boss.max_hp
      camera_panel_a_R["hp_" .. 1].CurrentValue = boss.hp
      camera_panel_a_R["hp_" .. 1].Text = GetUTF8Text(boss.character_name)
      camera_panel_a_R["line_" .. 1].Visible = true
    end
  end
end
