require("avatar.lua")
Gui.Clear(gui)
gui:PlayAudio("luckydraw_expand_sq3_lp", true)
gui:PlayAudio("luckydraw_expand_sq4_lp", true)
local state = ptr_cast(game.CurrentState)

function gui.EventSizeChanged(sender, e)
  NewLead.ui.Anti_addiction.Size = Vector2(gui.Size.x, 30)
  ComFuc.locationChanged = (gui.Size.x - 1200) / 2
  Lobby.ui.down_light.Location = Lobby.ligLc[6] + Vector2(ComFuc.locationChanged, 0)
  Lobby.ui.sys_pulic.Location = Vector2(370, 11) + Vector2(ComFuc.locationChanged, 0)
  Avatar.AlignUI()
  if NewLead.leadVisible and NewLead.leadFuc then
    NewLead.leadFuc(NewLead.leadA, NewLead.leadB, NewLead.leadT, NewLead.leadD, true)
  end
end

function state.EventLeave()
  Avatar.Hide()
  gui.EventSizeChanged = nil
  state.EventLeave = nil
  gui.EventEscPressed = nil
  state.EventServerCmd = nil
  ModalWindow.CloseAll()
end

function state.EventPrtScn(sender, e)
  MessageBox.ShowError(string.format(GetUTF8Text("UI_inGame_additional_string_126"), ptr_cast(e).Details))
end

function state.EventOnGuild(sender, e)
  if e.errId == 702 then
    MessageBox.ShowError(GetMatchedUTF8Text("UI_lobby_consortia_troop_26"))
  elseif e.errId == 804 then
  elseif e.errId == 805 then
  elseif e.errId == 902 then
    msg = GetMatchedUTF8Text("UI_lobby_consortia_troop_19," .. e.c_name .. "," .. e.guild_name)
    local tid = e.from_cid
    MessageBox.ShowWithTwoButtons(msg, GetUTF8Text("button_common_Accept"), GetUTF8Text("button_common_Decline"), function()
      state:AgreeOneToGuildTeam(0, tid)
    end, function()
      state:DisagreeOneToGuildTeam(0, tid)
    end)
  elseif e.errId == 20000 then
    msg = GetMatchedUTF8Text("msgbox_social_guild_UI_24," .. e.c_name .. "," .. e.guild_name)
    local tid = e.from_cid
    MessageBox.ShowWithTwoButtons(msg, GetUTF8Text("button_common_Accept"), GetUTF8Text("button_common_Decline"), function()
      state:JoinGuild(tid)
    end, function()
      state:RefuseGuild(tid)
    end)
  elseif e.errId == 40000 then
    SelectCharacter.isHaveGuild = "Y"
    MessageBox.ShowError(string.format(GetUTF8Text("msgbox_social_guild_UI_27"), e.guild_name))
  elseif e.errId == 70000 then
    SelectCharacter.isHaveGuild = "N"
    MessageBox.ShowError(GetUTF8Text("msgbox_common_num_1263"))
  elseif e.errId == 80000 then
    SelectCharacter.isHaveGuild = "Y"
    MessageBox.ShowError(string.format(GetUTF8Text("msgbox_social_guild_UI_27"), e.guild_name))
  elseif e.errId == 80001 then
    MessageBox.ShowError(GetMatchedUTF8Text(e.error_key))
  elseif e.errId == 91000 then
    local classText = {
      GetUTF8Text("UI_social_Guild_Leader"),
      GetUTF8Text("UI_social_Officer"),
      GetUTF8Text("UI_social_Elite_Rank"),
      GetUTF8Text("UI_social_Recruit")
    }
    MessageBox.ShowError(string.format(GetUTF8Text("msgbox_social_official_change"), classText[e.guild_floor]))
  end
end

function state.EventVipLevChange(sender, e)
  if e.newVipLev > 127 then
    ComFuc.VIPLevel = e.newVipLev - 256
  end
end

function state.EventOnUserAnti(sender, e)
  NewLead.ShowAntiAddiction(e)
end

state.EventServerCmd = PushCmd.OnServerCmd
EscMenu.InitEscMenu(4)
gui.EventEscPressed = EscMenu.SwitchEscMenu
Avatar.ESCPressed = EscMenu.SwitchEscMenu
gui.EventConfirmClose = EscMenu.ConfirmClose
Avatar.Show()
NewLead.ui.Anti_addiction.Parent = gui
