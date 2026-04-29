local GMCamera = require("/scripts/GMCamera.lua")
local state = ptr_cast(game.CurrentState, "Client.StateMainGame")
Gui.Clear(gui)
gui:PlayAudio("luckydraw_expand_sq3_lp", true)
gui:PlayAudio("luckydraw_expand_sq4_lp", true)
require("team_hp_name.lua")
if not state then
  return
end
if ComFuc.partc1 then
  ComFuc.partc1:SetEnable(false)
end
local esc_ctrl_size = Vector2(251, 397)
local escWindow
local escMenu = Gui.Create()({
  Gui.Control("content")({
    Size = esc_ctrl_size,
    BackgroundColor = ARGB(255, 255, 255, 255),
    Skin = SkinF.personalInfo_207,
    Gui.Label({
      Size = Vector2(0, 30),
      Dock = "kDockTop",
      TextPadding = Vector4(15, 0, 0, 0),
      FontSize = 16,
      Text = GetUTF8Text("button_common_Setting"),
      Gui.Button({
        Size = Vector2(24, 24),
        Margin = Vector4(0, 3, 8, 4),
        Dock = "kDockRight",
        Skin = SkinF.lookInfo_002,
        EventClick = function(sender, e)
          if escWindow and escWindow.screen then
            escWindow.screen.Visible = not escWindow.screen.Visible
            state.EscHasFocus = escWindow.screen.Visible
          end
        end
      })
    }),
    Gui.Control("content_area")({
      Location = Vector2(14, 35),
      Size = Vector2(223, 347),
      BackgroundColor = ARGB(255, 255, 255, 255),
      Skin = SkinF.setting_03,
      ComFuc.ComButton("graphic", GetUTF8Text("button_common_Video"), Vector2(193, 37), Vector2(16, 10), 18, false, true),
      ComFuc.ComButton("audio", GetUTF8Text("button_common_Sound"), Vector2(193, 37), Vector2(16, 51), 18, false, true),
      ComFuc.ComButton("action", GetUTF8Text("button_common_Hotkey"), Vector2(193, 37), Vector2(16, 92), 18, false, true),
      ComFuc.ComButton("vote_kick", GetUTF8Text("button_inGame_tirenhejubao"), Vector2(193, 37), Vector2(16, 133), 18, false, true),
      ComFuc.ComButton("resqose_ques", GetUTF8Text("button_social_suggestion"), Vector2(193, 37), Vector2(16, 174), 18, false, true),
      ComFuc.ComButton("show_setting", GetUTF8Text("UI_common_display_02"), Vector2(193, 37), Vector2(16, 215), 18, false, true),
      ComFuc.ComButton("quit_combat", GetUTF8Text("button_inGame_additional_string_161"), Vector2(193, 37), Vector2(16, 256), 18, false, true),
      ComFuc.ComButton("quit_novice", GetUTF8Text("button_common_Completed_Beginners_Stage"), Vector2(193, 37), Vector2(16, 256), 18, false, true),
      ComFuc.ComButton("cancel", GetUTF8Text("button_common_Back_to_Game"), Vector2(193, 37), Vector2(16, 297), 18, false, true)
    })
  })
})

function InitEscMenu()
  escWindow = ModalWindow.GetNew("transparent")
  escWindow.screen.AllowEscToExit = false
  escWindow.screen.Visible = false
  escWindow.screen.EventEscPressed = SwitchEscMenu
  gui.Focused = true
  escWindow.root.Size = esc_ctrl_size
  escMenu.content.Parent = escWindow.root
  escMenu.resqose_ques.Visible = config.IsSuggest
  
  function escMenu.cancel.EventClick()
    escWindow.screen.Visible = false
    gui.Focused = true
    if state then
      state.EscHasFocus = false
    end
  end
  
  function escMenu.graphic.EventClick()
    escWindow.screen.Visible = false
    local settingWin = Setting.Show("graphic")
    
    function settingWin.root.EventClose()
      if state then
        state.EscHasFocus = false
      end
    end
  end
  
  function escMenu.audio.EventClick()
    escWindow.screen.Visible = false
    local settingWin = Setting.Show("audio")
    
    function settingWin.root.EventClose()
      if state then
        state.EscHasFocus = false
      end
    end
  end
  
  function escMenu.action.EventClick()
    escWindow.screen.Visible = false
    local settingWin = Setting.Show("action")
    
    function settingWin.root.EventClose()
      if state then
        state.EscHasFocus = false
      end
    end
  end
  
  escMenu.vote_kick.Enable = true
  if state and state:GetIsGM() then
    escMenu.vote_kick.Enable = false
  end
  if escMenu.vote_kick.Enable then
    function escMenu.vote_kick.EventClick()
      escWindow.screen.Visible = false
      
      VoteKick.InitEscMenu()
      VoteKick.SwitchEscMenu()
    end
  end
  
  function escMenu.resqose_ques.EventClick()
    escWindow.screen.Visible = false
    ResposeQuestion.InitEscMenu()
    ResposeQuestion.SwitchEscMenu()
  end
  
  function escMenu.show_setting.EventClick()
    escWindow.screen.Visible = false
    local settingWin = Setting.Show("ingame_display")
    
    function settingWin.root.EventClose()
      if state then
        state.EscHasFocus = false
      end
    end
  end
  
  function escMenu.quit_combat.EventClick()
    local msgstr
    if state:GetMatching() then
      msgstr = GetUTF8Text("msgbox_inGame_additional_string_160")
    else
      msgstr = GetUTF8Text("msgbox_battlefield_free_combat_msgbox")
    end
    MessageBox.ShowWithConfirmCancel(msgstr, function(sender, e)
      escWindow.screen.Visible = false
      gui.Focused = true
      state.EscHasFocus = false
      MessageBox.ShowWaiter(GetUTF8Text("msgbox_inGame_additional_string_162"))
      state:Quit()
    end, nil)
  end
  
  function escMenu.quit_novice.EventClick()
    local msgstr = GetUTF8Text("msgbox_inGame_additional_string_163")
    MessageBox.ShowWithConfirmCancel(msgstr, function(sender, e)
      SwitchEscMenu()
      state:FinishNovice()
    end, nil)
  end
  
  gui.EventConfirmClose = EscMenu.ConfirmClose
end

function DestroyEscMenu()
  escMenu.cancel.EventClick = nil
  escMenu.graphic.EventClick = nil
  escMenu.audio.EventClick = nil
  escMenu.action.EventClick = nil
  escMenu.quit_combat.EventClick = nil
  escMenu.content.Parent = nil
  escWindow.screen.EventEscPressed = nil
  escWindow.Close()
  escWindow = nil
end

function SwitchEscMenu()
  if escWindow and escWindow.screen then
    escWindow.screen.Visible = not escWindow.screen.Visible
    if escWindow.screen.Visible then
      gui:PlayAudio("prompt")
      if state:IsNovice() then
        escMenu.action.Enable = false
        escMenu.quit_novice.Visible = true
        escMenu.quit_combat.Visible = false
      else
        escMenu.action.Enable = true
        escMenu.quit_novice.Visible = false
        escMenu.quit_combat.Visible = true
      end
    end
    state.EscHasFocus = escWindow.screen.Visible
  end
end

function gui.EventSizeChanged(sender, e)
  ComFuc.locationChanged = (sender.Size.x - 1200) / 2
  GMCamera.RelocateWindows()
  team_hp_name.RelocateWindows()
end

function state.EventLeave()
  MessageBox.CloseWaiter()
  gui.EventSizeChanged = nil
  gui.EventEscPressed = nil
  DestroyEscMenu()
  GMCamera.Finalize()
  team_hp_name.Finalize()
  state.EventLeave = nil
  state.EventServerCmd = nil
  state.EventShowCameraControlA = nil
  state.EventHideCameraControlA = nil
  state.EventShowTeamHpName = nil
  state.EventHideTeamHpName = nil
  state.EventShowCameraControlB = nil
  state.EventHideCameraControlB = nil
  state.EventRefreshCameraControlA = nil
  state.EventRefreshTeamHpName = nil
  state.EventResetCameraParam = nil
  state = nil
  Setting.Hide()
  ModalWindow.CloseAll()
  if ComFuc.isFromNew ~= 1 then
    ComFuc.isInGame = true
  end
end

function state.EventPrtScn(sender, e)
  MessageBox.ShowError(string.format(GetUTF8Text("UI_inGame_additional_string_126"), ptr_cast(e).Details))
end

function state.EventGetLeftPunishedTime(sender, e)
  ComFuc.globalLeftTime = e.left_time
  local temp_time
  if ComFuc.globalLeftTime > 0 and ComFuc.globalLeftTime < 0 then
    ComFuc.globalLeftTime = 0
  end
  if 0 == ComFuc.globalLeftTime then
    temp_time = tostring(ComFuc.globalLeftTime) .. GetUTF8Text("tips_abilities_Sec")
    Lobby.ui.left_time:Stop()
    Lobby.ui.run_num.Visible = false
  else
    temp_time = Tip.GetLeftTime(ComFuc.globalLeftTime)
    Lobby.ui.run_num.Visible = true
  end
  Lobby.ui.run_num.Hint = GetMatchedUTF8Text("UI_lobby_deserter_punishment" .. "," .. temp_time)
  if ComFuc.globalLeftTime > 0 then
    Lobby.ui.left_time.Timer = 1
    Lobby.ui.left_time:Start()
  end
end

function ShowGmCameraControlA()
  GMCamera.ShowControlA()
end

function HideGmCameraControlA()
  GMCamera.HideControlA()
end

function ShowTeamHpName()
  team_hp_name.Show()
end

function HideTeamHpName()
  team_hp_name.Hide()
end

function ShowGmCameraControlB()
  GMCamera.ShowControlB()
end

function HideGmCameraControlB()
  GMCamera.HideControlB()
end

function RefreshGmCameraControlA()
  GMCamera.RefreshControl()
end

function RefreshTeamHpName()
  team_hp_name.RefreshPlayerList()
end

function ResetGmCameraControlBUI()
  GMCamera.ResetParam()
end

InitEscMenu()
gui.EventEscPressed = SwitchEscMenu
state.EventServerCmd = PushCmd.OnServerCmd
state.EventShowCameraControlA = ShowGmCameraControlA
state.EventHideCameraControlA = HideGmCameraControlA
state.EventShowTeamHpName = ShowTeamHpName
state.EventHideTeamHpName = HideTeamHpName
state.EventShowCameraControlB = ShowGmCameraControlB
state.EventHideCameraControlB = HideGmCameraControlB
state.EventRefreshCameraControlA = RefreshGmCameraControlA
state.EventRefreshTeamHpName = RefreshTeamHpName
state.EventResetCameraParam = ResetGmCameraControlBUI
GMCamera.Initialize()
team_hp_name.Initialize()
NewLead.ui.Anti_addiction.MissTime = 0
NewLead.ui.Anti_addiction.Parent = nil
ComFuc.isFromGame = true
if state:IsNovice() and not ComFuc.Is_FirstPrintLog[2] then
  ComFuc.Is_FirstPrintLog[2] = true
  rpc.safecall("user_retention", {
    sign = ComFuc.First_Log[2]
  }, function(data)
  end)
end
if state:Is_PVPMode() and not ComFuc.Is_FirstPrintLog[7] then
  ComFuc.Is_FirstPrintLog[7] = true
  rpc.safecall("user_retention", {
    sign = ComFuc.First_Log[7]
  }, function(data)
  end)
end
