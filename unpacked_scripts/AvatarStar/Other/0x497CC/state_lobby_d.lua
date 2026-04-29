require("lobby/boxContern.lua")
require("lobby/battleGame.lua")
require("lobby/sociality.lua")
require("lobby/activity/activity.lua")
require("sys/all.lua")
require("lobby/openBox.lua")
Gui.Clear(gui)
gui:PlayAudio("luckydraw_expand_sq3_lp", true)
gui:PlayAudio("luckydraw_expand_sq4_lp", true)
local state = ptr_cast(game.CurrentState)

function gui.EventSizeChanged(sender, e)
  NewLead.ui.Anti_addiction.Size = Vector2(gui.Size.x, 30)
  ComFuc.locationChanged = (gui.Size.x - 1200) / 2
  local index = Lobby.mainBtnPushDown
  if index < 1 or 9 < index then
    index = 2
  end
  Lobby.ui.down_light.Location = Lobby.ligLc[index] + Vector2(ComFuc.locationChanged, 0)
  Lobby.ui.sys_pulic.Location = Vector2(370, 11) + Vector2(ComFuc.locationChanged, 0)
  OpenBox.Resize()
  Lobby.AlignUI()
  if NewLead.leadVisible and NewLead.leadFuc then
    NewLead.leadFuc(NewLead.leadA, NewLead.leadB, NewLead.leadT, NewLead.leadD, true)
  end
  if Lobby.mainBtnPushDown == 9 and LuckDraw then
    LuckDraw.SetHeadPosxy()
  end
end

function state.EventLeave()
  if Guild then
    Guild.TimerRemove()
  end
  Lobby.Hide()
  Setting.Hide()
  state.EventLeave = nil
  gui.EventSizeChanged = nil
  gui.EventEscPressed = nil
  ModalWindow.CloseAll()
  ComFuc.ResetAnim()
end

function state.EventPrtScn(sender, e)
  MessageBox.ShowError(string.format(GetUTF8Text("UI_inGame_additional_string_126"), ptr_cast(e).Details))
end

function state.EventInitUI()
  EscMenu.InitEscMenu(3)
  gui.EventEscPressed = EscMenu.SwitchEscMenu
  Lobby.Show()
  Lobby.OnEnterLobby()
end

function state.EventRestoreUI()
  EscMenu.InitEscMenu(3)
  gui.EventEscPressed = EscMenu.SwitchEscMenu
  Lobby.Show(true)
  Lobby.OnRestoreLobby()
end

function state.EventUpdateLevelList()
  if not CreateRoom then
    require("lobby/CreateRoom.lua")
  end
  CreateRoom.UpdateLevelList()
end

function state.EventOnGuild(sender, e)
  if e.errId == 500 then
    Guild.DealGuildCreate()
  elseif e.errId == 501 then
    if e.error_key == "msgbox_common_conditionkey_131,msgbox_common_conditionkey_128" then
      if not L_MoneyLessKey then
        require("moneyLessKey.lua")
      end
      local moneyType = "gold"
      local s = GetMatchedUTF8Text(e.error_key) .. "\n" .. GetUTF8Text(L_MoneyLessKey.HelpTextKey[moneyType])
      MessageBox.ShowNotEnough(s, moneyType, config.IsRecharge)
    else
      MessageBox.ShowError(GetMatchedUTF8Text(e.error_key))
    end
  elseif e.errId == 600 then
    MessageBox.ShowError(string.format(GetUTF8Text("UI_lobby_consortia_troop_16"), NameCreate.GetInputName()))
    Guild.SetIsHasGuildTeam(true)
    Guild.SelMainBC(4)
  elseif e.errId == 601 then
    MessageBox.ShowError(GetMatchedUTF8Text(e.error_key))
  elseif e.errId == 700 then
    if ComFuc.isQuitBySelf then
      Guild.SetIsHasGuildTeam(false)
      Guild.SelMainBC(3)
      GuildTeamCreate.SetIsHasGuildTeam()
      ComFuc.isQuitBySelf = false
    else
      MessageBox.ShowError(GetMatchedUTF8Text("UI_lobby_consortia_troop_25"))
      GuildTeamMy.UpDateMemberList()
    end
  elseif e.errId == 701 then
    MessageBox.ShowError(GetMatchedUTF8Text(e.error_key))
  elseif e.errId == 702 then
    MessageBox.ShowError(GetMatchedUTF8Text("UI_lobby_consortia_troop_26"))
    if Guild and GuildTeamCreate and Lobby.mainBtnPushDown == 3 then
      Guild.SetIsHasGuildTeam(false)
      if Guild.curMainBtn == 3 or Guild.curMainBtn == 4 then
        Guild.curMainBtn = 0
        Guild.SelMainBC(3)
      end
      GuildTeamCreate.SetIsHasGuildTeam()
    end
  elseif e.errId == 800 then
    if Lobby.mainBtnPushDown == 3 and (Guild.curMainBtn == 3 or Guild.curMainBtn == 4) then
      if ComFuc.isMemberAgree then
        ComFuc.isMemberAgree = false
        Guild.curMainBtn = 0
        Guild.SetIsHasGuildTeam(true)
        Guild.SelMainBC(4)
        GuildTeamCreate.SetIsHasGuildTeam()
      else
        GuildTeamMy.UpDateMemberList()
        GuildJoin.UpdateAll()
      end
    end
  elseif e.errId == 801 then
    MessageBox.ShowError(GetMatchedUTF8Text(e.error_key))
  elseif e.errId == 802 then
    if GuildTeamMy and GuildJoin then
      GuildTeamMy.UpDateMemberList()
      if ComFuc.isHasGuildTeam then
        GuildJoin.UpdateAll()
      end
    end
    if ComFuc.isFefuseBySelf and Guild and (Guild.curMainBtn == 3 or Guild.curMainBtn == 4) then
      Guild.SetIsHasGuildTeam(false)
      Guild.curMainBtn = 0
      Guild.SelMainBC(3)
      GuildTeamCreate.SetIsHasGuildTeam()
    end
  elseif e.errId == 803 then
    MessageBox.ShowError(GetMatchedUTF8Text(e.error_key))
  elseif e.errId == 804 then
    if Lobby.mainBtnPushDown == 3 and (Guild.curMainBtn == 3 or Guild.curMainBtn == 4) then
      ComFuc.isMemberAgree = false
      Guild.curMainBtn = 0
      Guild.SetIsHasGuildTeam(true)
      Guild.SelMainBC(4)
      GuildTeamCreate.SetIsHasGuildTeam()
    end
  elseif e.errId == 805 then
    if Lobby.mainBtnPushDown == 3 and Guild.curMainBtn == 4 then
      GuildTeamMy.UpDateMemberList()
      GuildInvite.RefreshMemberList()
      if GuildJoin then
        GuildJoin.UpdateAll()
      end
    end
  elseif e.errId == 901 then
    MessageBox.ShowError(GetMatchedUTF8Text(e.error_key))
  elseif e.errId == 902 then
    msg = GetMatchedUTF8Text("UI_lobby_consortia_troop_19," .. e.c_name .. "," .. e.guild_name)
    local tid = e.from_cid
    MessageBox.ShowWithTwoButtons(msg, GetUTF8Text("button_common_Accept"), GetUTF8Text("button_common_Decline"), function()
      ComFuc.isMemberAgree = true
      state:AgreeOneToGuildTeam(0, tid)
    end, function()
      ComFuc.isFefuseBySelf = true
      state:DisagreeOneToGuildTeam(0, tid)
    end)
  elseif e.errId == 10000 then
    MessageBox.ShowError(GetMatchedUTF8Text(e.error_key))
  elseif e.errId == 20000 then
    msg = GetMatchedUTF8Text("msgbox_social_guild_UI_24," .. e.c_name .. "," .. e.guild_name)
    local tid = e.from_cid
    MessageBox.ShowWithTwoButtons(msg, GetUTF8Text("button_common_Accept"), GetUTF8Text("button_common_Decline"), function()
      state:JoinGuild(tid)
    end, function()
      state:RefuseGuild(tid)
    end)
  elseif e.errId == 30000 then
    GuildJoin.UpdateAll()
  elseif e.errId == 30001 then
    MessageBox.ShowError(GetMatchedUTF8Text(e.error_key))
  elseif e.errId == 40000 then
    SelectCharacter.isHaveGuild = "Y"
    if Lobby.mainBtnPushDown == 3 then
      Guild.Show(Lobby.ui.lobby_mid)
    end
    MessageBox.ShowError(string.format(GetUTF8Text("msgbox_social_guild_UI_27"), e.guild_name))
  elseif e.errId == 50000 then
    GuildJoin.UpdateAll()
  elseif e.errId == 60000 then
    Guild.RpcCallGuildShow()
  elseif e.errId == 60001 then
    MessageBox.ShowError(GetMatchedUTF8Text(e.error_key))
  elseif e.errId == 70000 then
    SelectCharacter.isHaveGuild = "N"
    if Lobby.mainBtnPushDown == 3 then
      Guild.Show(Lobby.ui.lobby_mid)
    end
    if ComFuc.isSlefExitGuild then
      ComFuc.isSlefExitGuild = false
      MessageBox.ShowError(string.format(GetUTF8Text("msgbox_common_num_1257"), ComFuc.guildName))
    else
      MessageBox.ShowError(GetUTF8Text("msgbox_common_num_1263"))
    end
  elseif e.errId == 80000 then
    SelectCharacter.isHaveGuild = "Y"
    if Lobby.mainBtnPushDown == 3 then
      Guild.Show(Lobby.ui.lobby_mid)
    end
    MessageBox.ShowError(string.format(GetUTF8Text("msgbox_social_guild_UI_27"), e.guild_name))
  elseif e.errId == 80001 then
    MessageBox.ShowError(GetMatchedUTF8Text(e.error_key))
  elseif e.errId == 90000 then
    if e.guild_floor == 1 then
      Guild.RpcCallGuildShow()
      print(e.c_name)
      MessageBox.ShowError(string.format(GetUTF8Text("msgbox_common_Transfer_president_success"), e.c_name))
    else
      Guild.RpcCallGuildShow()
      MessageBox.ShowError(GetUTF8Text("msgbox_social_guild_UI_32"))
    end
  elseif e.errId == 90001 then
    MessageBox.ShowError(GetMatchedUTF8Text(e.error_key))
  elseif e.errId == 91000 then
    Guild.RpcCallGuildShow()
    local classText = {
      GetUTF8Text("UI_social_Guild_Leader"),
      GetUTF8Text("UI_social_Officer"),
      GetUTF8Text("UI_social_Elite_Rank"),
      GetUTF8Text("UI_social_Recruit")
    }
    MessageBox.ShowError(string.format(GetUTF8Text("msgbox_social_official_change"), classText[e.guild_floor]))
  elseif e.errId == 92000 then
    if e.error_key ~= "" then
      MessageBox.ShowError(GetMatchedUTF8Text(e.error_key))
    end
    if not GuildAppointTeamLeader then
      require("guildAppointTeamLeader.lua")
    end
    rpc.safecall("guild_team_info_detail", {}, GuildAppointTeamLeader.RefreshTeamList)
  end
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

function state.EventVipLevChange(sender, e)
  if e.newVipLev > 127 then
    ComFuc.VIPLevel = e.newVipLev - 256
  end
end

function state.EventOnUserAnti(sender, e)
  NewLead.ShowAntiAddiction(e)
end

function state.EventSocialOnConnected(sender, e)
  Sociality.Initialize()
end

Lobby.ESCPressed = EscMenu.SwitchEscMenu
gui.EventConfirmClose = EscMenu.ConfirmClose
NewLead.ui.Anti_addiction.Parent = gui
if game.online_time > 0 and ComFuc.isFromGame then
  e = {}
  e.errId = 1000
  e.online_time = game.online_time
  NewLead.ShowAntiAddiction(e)
  ComFuc.isFromGame = false
end
