module("ResposeQuestion", package.seeall)
local colw = ComFuc.colw
local colt = ComFuc.colt
local uiS = Vector2(420, 346)
local escWindow, ComEscButton

function ComEscButton(i, text, size, lc, skin, fuc)
  return Gui.Button("btn_" .. i)({
    Size = size or Vector2(84, 40),
    Location = lc,
    Text = text,
    FontSize = 16,
    CanMove = true,
    Skin = skin,
    EventClick = function()
      escWindow.screen.Visible = false
      gui.Focused = true
      if fuc then
        fuc()
      end
      local state = ptr_cast(game.CurrentState, "Client.StateMainGame")
      if state then
        state.EscHasFocus = false
      end
    end
  })
end

ui = Gui.Create()({
  Gui.Control("main")({
    Size = uiS,
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_207,
    ComFuc.ComLabel(nil, GetUTF8Text("UI_social_bug_confirm"), Vector2(uiS.x, 30), Vector2(10, 0), 0, 16, colw),
    ComEscButton(0, nil, Vector2(24, 24), Vector2(uiS.x - 33, 4), SkinF.lookInfo_002),
    ComEscButton(1, GetUTF8Text("UI_social_bug_submit"), nil, Vector2(220, 292), nil, function()
      if ui.rp_text.Text == "" then
        MessageBox.ShowError(GetUTF8Text("msgbox_lobby_bug_enter_null"))
      else
        local state = 1
        if ui.qest_2.Check then
          state = 2
        end
        if game:SetSuggestion(ui.rp_text.Text, state) then
          MessageBox.ShowError(GetUTF8Text("msgbox_social_submit_success"))
        else
          MessageBox.ShowError(GetUTF8Text("msgbox_social_submit_success"))
        end
      end
    end),
    ComEscButton(2, GetUTF8Text("button_common_Cancel"), nil, Vector2(314, 292)),
    Gui.Control({
      Location = Vector2(10, 38),
      Size = Vector2(400, 76),
      BackgroundColor = colw,
      Skin = SkinF.setting_03,
      ComFuc.ComLabel(nil, GetUTF8Text("UI_social_bug_type"), Vector2(376, 24), Vector2(12, 10), 0, 16, colt),
      ComFuc.ComCheckBox("qest_1", GetUTF8Text("UI_social_bug_select"), Vector2(138, 24), Vector2(22, 40), 16, colt, "Gui.CheckBox_01"),
      ComFuc.ComCheckBox("qest_2", GetUTF8Text("UI_social_suggestion_select"), Vector2(138, 24), Vector2(162, 40), 16, colt, "Gui.CheckBox_01")
    }),
    Gui.Control({
      Location = Vector2(10, 120),
      Size = Vector2(400, 170),
      BackgroundColor = colw,
      Skin = SkinF.setting_03,
      ComFuc.ComLabel(nil, GetUTF8Text("UI_social_bug_desc"), Vector2(376, 24), Vector2(12, 10), 0, 16, colt),
      ComFuc.ComTextArea("rp_text", Vector2(376, 120), Vector2(12, 36), 16, colw, 300)
    })
  })
})
for i = 1, 2 do
  ui["qest_" .. i].EventCheckChanged = function(sender, e)
    if "kTriggerMouse" == e.Trigger then
      sender.Check = true
      ui["qest_" .. 3 - i].Check = false
    end
  end
end

function InitEscMenu()
  escWindow = ModalWindow.GetNew("transparent")
  escWindow.screen.AllowEscToExit = false
  escWindow.screen.Visible = false
  
  function escWindow.screen.EventEscPressed()
    escWindow.screen.Visible = false
    gui.Focused = true
    local state = ptr_cast(game.CurrentState, "Client.StateMainGame")
    if state then
      state.EscHasFocus = false
    end
  end
  
  gui.Focused = true
  escWindow.root.Size = uiS
  ui.main.Parent = escWindow.root
  ui.qest_1.Check = true
  ui.qest_2.Check = false
  ui.rp_text.Text = ""
end

function SwitchEscMenu()
  if escWindow and escWindow.screen then
    escWindow.screen.Visible = not escWindow.screen.Visible
    if escWindow.screen.Visible then
      escWindow.root.Focused = true
    else
      gui.Focused = true
    end
  end
end
