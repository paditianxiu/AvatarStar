module("MessageBox", package.seeall)
local wmbHolder, message_box
local uiS = Vector2(560, 178)
local errormsg_show_time = 5
local errorMsgBox, btnIcon, errormsg_timer
local icon_ok = Gui.Icon("ui/skinF/skin_button_icon_ok.tga", Vector4(0, 0, 0, 0))
local icon_cancel = Gui.Icon("ui/skinF/skin_button_icon_cancel.tga", Vector4(0, 0, 0, 0))
local button_area_type, GetStandardMB = {
  {
    align = "kAlignRightMiddle",
    control_align = "kAlignRightMiddle",
    control_space = 6
  },
  {
    align = "kAlignCenterMiddle",
    control_align = "kAlignCenterMiddle",
    control_space = 280
  }
}, {
  align = "kAlignRightMiddle",
  control_align = "kAlignRightMiddle",
  control_space = 6
}
local GetStandardMB, AddButton = function(message, time, type_num)
  local lblSize = Vector2(484, 101)
  local maxLineNum = 4
  if type(type_num) ~= "number" then
    type_num = 1
  elseif type_num > #button_area_type or type_num < 1 then
    type_num = 1
  end
  message_box = Gui.Create({
    Gui.Control("panel")({
      Size = Vector2(480, 200),
      Dock = "kDockFill",
      Padding = Vector4(5, 5, 5, 0),
      Gui.FlowLayout("button_area")({
        Size = Vector2(0, 46),
        Dock = "kDockBottom",
        Align = button_area_type[type_num].align,
        ControlAlign = button_area_type[type_num].control_align,
        ControlSpace = button_area_type[type_num].control_space
      }),
      Gui.Label("proportion_area")({
        Size = Vector2(2, 8),
        Dock = "kDockBottom"
      }),
      Gui.Label({
        Dock = "kDockFill",
        Margin = Vector4(16, 0, 16, 0),
        BackgroundColor = ARGB(255, 255, 255, 255),
        Skin = SkinF.battle_005,
        Gui.Label("lbl")({
          Style = "MessageBoxStyle.Text",
          Dock = "kDockCenter",
          Margin = Vector4(0, 0, 0, 0),
          Size = lblSize,
          Text = message
        })
      })
    })
  })
  local needAdd_y = 0
  local textLineNum = message_box.lbl.TextLineNum
  if textLineNum > maxLineNum - 1 then
    needAdd_y = (textLineNum - maxLineNum) * math.ceil(lblSize.y / maxLineNum) + 20
  end
  local modalwin = ModalWindow.GetNew()
  modalwin.screen.AllowEscToExit = false
  modalwin.root.Size = uiS + Vector2(0, needAdd_y)
  message_box.lbl.Size = lblSize + Vector2(0, needAdd_y)
  message_box.panel.Parent = modalwin.root
  message_box.root = modalwin.root
  
  function message_box.Close()
    modalwin.Close()
  end
  
  if time and 0 < tonumber(time) then
    message_box.root.Timer = time
  end
  return message_box
end, {
  align = "kAlignCenterMiddle",
  control_align = "kAlignCenterMiddle",
  control_space = 280
}

function AddButton(button, clicked, style, icon, isCloseSound)
  if message_box then
    local button_control
    if type(button) == "string" then
      button_control = ptr_new("Gui.Button")
      button_control.Style = style or "MessageBoxStyle.Button"
      button_control.Parent = message_box.button_area
      button_control.EventClick = clicked
      if not isCloseSound then
        button_control.ClickAudio = "button"
      end
      if icon then
        button_icon = ptr_new("Gui.Label")
        button_icon.Style = "Gui.Label"
        button_icon.Dock = "kDockFill"
        button_icon.Margin = Vector4(6, 0, 0, 0)
        button_icon.Text = button
        button_icon.TextAlign = "kAlignCenterMiddle"
        button_icon.Icon = icon
        button_icon.Parent = button_control
        button_icon.BackgroundColor = ARGB(0, 0, 0, 0)
        button_icon.FontSize = 16
        return button_control, button_icon
      else
        button_control.Text = button
        return button_control
      end
    end
  end
end

function ShowWithTwoButtons(message, strA, strB, clickedA, clickedB, styleA, styleB, iconA, iconB, isCloseSound, enableA, enableB, type)
  gui:PlayAudio("prompt")
  local tempMB = GetStandardMB(message, nil, type)
  local btn_a, btn_b
  if strA then
    btn_a = AddButton(strA, function()
      if clickedA then
        clickedA()
      end
      if tempMB.root then
        tempMB.Close()
      end
    end, styleA, iconA, isCloseSound)
    if btn_a then
      if enableA == false then
        btn_a.Enable = false
      else
        btn_a.Enable = true
      end
    end
  end
  if strB then
    btn_b = AddButton(strB, function()
      if clickedB then
        clickedB()
      end
      if tempMB.root then
        tempMB.Close()
      end
    end, styleB, iconB)
    if btn_b then
      if enableB == false then
        btn_b.Enable = false
      else
        btn_b.Enable = true
      end
    end
  end
  if btn_a then
    btn_a.Focused = true
  elseif btn_b then
    btn_b.Focused = true
  else
    tempMB.panel.Focused = true
  end
  return tempMB
end

function ShowWithConfirmCancel(message, clickedA, clickedB, isCloseSound)
  ShowWithTwoButtons(message, GetUTF8Text("button_common_OK"), GetUTF8Text("button_common_Cancel"), clickedA, clickedB, nil, nil, icon_ok, icon_cancel, isCloseSound)
end

local Show, StopTimer = function(message, button, clicked, time, style, icon, mute)
  if not mute then
    gui:PlayAudio("prompt")
  end
  local tempMB = GetStandardMB(message, time)
  local btn_a
  if button then
    btn_a, btn_ic = AddButton(button, function()
      if clicked then
        clicked()
      end
      if tempMB.root then
        tempMB.Close()
      end
    end, style, icon)
  end
  if btn_a then
    btn_a.Focused = true
  else
    tempMB.panel.Focused = true
  end
  return tempMB, btn_a, btn_ic
end, function(message, button, clicked, time, style, icon, mute)
  if not mute then
    gui:PlayAudio("prompt")
  end
  local tempMB = GetStandardMB(message, time)
  local btn_a
  if button then
    btn_a, btn_ic = AddButton(button, function()
      if clicked then
        clicked()
      end
      if tempMB.root then
        tempMB.Close()
      end
    end, style, icon)
  end
  if btn_a then
    btn_a.Focused = true
  else
    tempMB.panel.Focused = true
  end
  return tempMB, btn_a, btn_ic
end
local StopTimer, OnTimer = function()
  if errormsg_timer then
    game.TimerMgr:RemoveTimer(errormsg_timer)
    errormsg_timer = nil
    errormsg_show_time = 0
  end
  if errorMsgBox then
    if btnIcon then
      btnIcon = nil
    end
    errorMsgBox.Close()
    errorMsgBox = nil
    btnIcon = nil
  end
end, Vector4(0, 0, 0, 0)

function OnTimer()
  errormsg_show_time = errormsg_show_time - 1
  if 0 < errormsg_show_time then
    local strText = string.format("%s (%d%s)", GetUTF8Text("button_common_Cancel"), errormsg_show_time, GetUTF8Text("tips_abilities_Sec"))
    if btnIcon and btnIcon then
      btnIcon.Text = strText
    end
  else
    StopTimer()
  end
end

function ShowError(err, time, mute)
  local btnCtrl
  time = time or 3
  if errorMsgBox then
    StopTimer()
  end
  errormsg_show_time = time
  local strText = string.format("%s (%d%s)", GetUTF8Text("button_common_Cancel"), errormsg_show_time, GetUTF8Text("tips_abilities_Sec"))
  errorMsgBox, btnCtrl, btnIcon = Show(tostring(err), strText, nil, tonumber(errormsg_show_time), "MessageBoxStyle.Button2", icon_cancel, mute)
  if errorMsgBox then
    errormsg_timer = game.TimerMgr:AddTimer(1)
    errormsg_timer.EventOnTimer = OnTimer
    
    function errorMsgBox.root.EventClose(sender, e)
      StopTimer()
    end
  end
end

function CloseWaiter()
  if wmbHolder then
    wmbHolder.Close()
    wmbHolder = nil
  end
end

function ShowWaiter(msg)
  CloseWaiter()
  wmbHolder = Show(msg)
  wmbHolder.button_area.Size = Vector2(0, 0)
end

function AddGold()
  AHMain.SetIndex(3)
  Lobby.ChangeTo(5)
end

function AddStar()
  game:OpenUrl(config.RechargeUrl)
end

function AddTicket()
  AHMain.SetIndex(0)
  Lobby.ChangeTo(5)
end

function ShowNotEnough(message, money_type, IsRecharge)
  if money_type == "gold" then
    ShowWithTwoButtons(message, GetUTF8Text("button_common_lijiqianwang"), GetUTF8Text("button_common_OK"), AddGold, nil, nil, nil, nil, icon_ok, nil, true, nil, 2)
  elseif money_type == "star" then
    ShowWithTwoButtons(message, GetUTF8Text("button_common_Online_Topup"), GetUTF8Text("button_common_OK"), AddStar, nil, nil, nil, nil, icon_ok, nil, IsRecharge, nil, 2)
  elseif money_type == "ticket" then
    ShowWithTwoButtons(message, GetUTF8Text("button_common_lijiqianwang"), GetUTF8Text("button_common_OK"), AddTicket, nil, nil, nil, nil, icon_ok, nil, true, nil, 2)
  else
    ShowWithTwoButtons(message, GetUTF8Text("button_common_Online_Topup"), GetUTF8Text("button_common_OK"), AddStar, nil, nil, nil, nil, icon_ok, nil, IsRecharge, nil, 2)
  end
end
