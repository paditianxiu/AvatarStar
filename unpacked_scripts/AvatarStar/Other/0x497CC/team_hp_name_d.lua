module("team_hp_name", package.seeall)
normal_text_color = ARGB(255, 136, 112, 97)
white_text_color = ARGB(255, 255, 255, 255)
gm_view_player_list_red = {}

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
    })
  })
end

camera_panel_a_L = Gui.Create(gui)({
  Gui.Control("root")({
    Size = Vector2(240, 248),
    Location = Vector2(6, 307),
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

function Initialize()
  for i = 1, 8 do
    camera_panel_a_L["line_" .. i].Visible = false
  end
  camera_panel_a_L.root.Parent = gui
  camera_panel_a_L.root.Visible = false
end

function Finalize()
  camera_panel_a_L.root.Visible = false
end

function Show()
  local screen_width = gui.Size.x
  camera_panel_a_L.root.Visible = true
end

function Hide()
  camera_panel_a_L.root.Visible = false
end

function RelocateWindows()
  camera_panel_a_L.root.Location = Vector2(950 + ComFuc.locationChanged, 557)
  local new_width = gui.Size.x
end

function RefreshPlayerList()
  local stm = ptr_cast(game.CurrentState, "Client.StateMainGame")
  if stm then
    for i = 1, 8 do
      camera_panel_a_L["line_" .. i].Visible = false
    end
    gm_view_player_list_red = {}
    local player_count = stm:GetIngamePlayerCount()
    for i = 1, player_count do
      local current_player = stm:GetGmCharacterBaseInfo(i - 1)
      if current_player and not current_player.is_viewer and current_player.team == 0 then
        table.insert(gm_view_player_list_red, current_player)
      end
    end
    for i = 1, #gm_view_player_list_red do
      local current_player = gm_view_player_list_red[i]
      camera_panel_a_L["career_icon_" .. i].Skin = SkinF.personalInfo_job[current_player.career + 1]
      camera_panel_a_L["hp_" .. i].MaxValue = current_player.max_hp
      camera_panel_a_L["hp_" .. i].CurrentValue = current_player.hp
      camera_panel_a_L["hp_" .. i].Text = current_player.character_name
      camera_panel_a_L["lv_" .. i].Text = "Lv" .. current_player.level
      camera_panel_a_L["line_" .. i].Visible = true
    end
  end
end
