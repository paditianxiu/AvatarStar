module("EscMenu", package.seeall)
local colw = ComFuc.colw
local uiS = Vector2(251, 425)
local escWindow, ComEscButton = nil, 425

function ComEscButton(i, text, size, lc, skin, fuc)
  return Gui.Button("btn_" .. i)({
    Size = size or Vector2(193, 37),
    Location = lc,
    Text = text,
    FontSize = 18,
    CanMove = true,
    Skin = skin,
    EventClick = function()
      escWindow.screen.Visible = false
      if fuc then
        fuc()
      end
    end
  })
end

local ui = Gui.Create()({
  Gui.Control("main")({
    Size = uiS,
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_207,
    ComFuc.ComLabel(nil, "    " .. GetUTF8Text("button_common_Setting"), Vector2(uiS.x, 30), Vector2(0, 0), 0, 16, colw),
    ComEscButton(0, nil, Vector2(24, 24), Vector2(uiS.x - 33, 4), SkinF.lookInfo_002),
    Gui.Control({
      Location = Vector2(14, 45),
      Size = Vector2(222, 350),
      BackgroundColor = colw,
      Skin = SkinF.setting_03,
      ComEscButton(1, GetUTF8Text("button_common_Video"), nil, Vector2(16, 15), nil, function()
        Setting.Show("graphic")
      end),
      ComEscButton(2, GetUTF8Text("button_common_Sound"), nil, Vector2(16, 56), nil, function()
        Setting.Show("audio")
      end),
      ComEscButton(3, GetUTF8Text("button_common_Hotkey"), nil, Vector2(16, 97), nil, function()
        Setting.Show("action")
      end),
      ComEscButton(4, GetUTF8Text("button_common_Reselect_Character"), nil, Vector2(16, 138), nil, function()
        MessageBox.ShowWithConfirmCancel(GetUTF8Text("msgbox_common_num_1362"), function()
          if LobbyBattleGame then
            LobbyBattleGame.Reset(false)
          end
          if ChatBar then
            ChatBar.CloseAllChatPaire()
          end
          game:LogoutCharacter()
        end)
      end),
      ComEscButton(5, GetUTF8Text("button_social_suggestion"), nil, Vector2(16, 179), nil, function()
        ResposeQuestion.InitEscMenu()
        ResposeQuestion.SwitchEscMenu()
      end),
      ComEscButton(6, GetUTF8Text("button_common_Quit_Game"), nil, Vector2(16, 220), nil, function()
        MessageBox.ShowWithConfirmCancel(GetUTF8Text("msgbox_common_additional_string_153"), function()
          Thread.Quit()
        end)
      end),
      ComEscButton(7, GetUTF8Text("button_common_Back_to_Game"), nil, Vector2(16, 297))
    })
  })
})

function InitEscMenu(s)
  escWindow = ModalWindow.GetNew("transparent")
  escWindow.screen.AllowEscToExit = false
  escWindow.screen.Visible = false
  escWindow.screen.EventEscPressed = SwitchEscMenu
  gui.Focused = true
  escWindow.root.Size = uiS
  ui.main.Parent = escWindow.root
  ui.btn_3.Visible = s == 3 or s == 4
  ui.btn_4.Visible = s == 3 or s == 4
  ui.btn_5.Visible = config.IsSuggest
end

function SwitchEscMenu()
  if escWindow and escWindow.screen then
    escWindow.screen.Visible = not escWindow.screen.Visible
    if escWindow.screen.Visible then
      gui:PlayAudio("prompt")
      escWindow.root.Focused = true
    else
      gui.Focused = true
    end
  end
end

function ConfirmClose()
  local really_show = true
  local main_game_state = ptr_cast(game.CurrentState, "Client.StateMainGame")
  if main_game_state then
    local already_show = main_game_state:GetShowConfirmBox()
    if already_show then
      really_show = false
    end
  end
  if really_show then
    MessageBox.ShowWithConfirmCancel(GetUTF8Text("msgbox_common_additional_string_153"), function()
      Thread.Quit()
    end, function()
      local game_state = ptr_cast(game.CurrentState, "Client.StateMainGame")
      if game_state then
        game_state:SetShowConfirmBox(false)
      end
    end)
    local game_state = ptr_cast(game.CurrentState, "Client.StateMainGame")
    if game_state then
      game_state:SetShowConfirmBox(true)
    end
  end
end
