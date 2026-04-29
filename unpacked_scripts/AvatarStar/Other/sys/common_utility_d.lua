module("CommonUtility", package.seeall)

function gui.EventShowMessage(sender, args)
  if args then
    if args.Message == GetUTF8Text("msgbox_lobby_lag_down") then
      if not Lobby then
        require("Lobby.lua")
      end
      for i = 1, 10 do
        Lobby.ui["btn_m_" .. i].PushDown = false
      end
      Lobby.mainBtnPushDown = 0
      Lobby.MainBtnSelect(2)
      Lobby.ui["btn_m_" .. 2].PushDown = true
    end
    MessageBox.ShowError(args.Message)
  end
end

function ShowCloseAccount(needMesg)
  if game.isCloseAccount and needMesg then
    local t = os.date("*t", game.endCloseAccountTime)
    local s = GetMatchedUTF8Text("tips_social_punish_056_lobby," .. t.year .. "," .. t.month .. "," .. t.day .. "," .. t.hour .. "," .. t.min)
    MessageBox.ShowError(s .. "\n" .. game.bannedReason)
  end
end

function gui.EventShowCloseAccount(sender, args)
  ShowCloseAccount(true)
end

function ShowCloseRole(needMesg)
  if game.isCloseRole and needMesg then
    local t = os.date("*t", game.endCloseRoleTime)
    local s = GetMatchedUTF8Text("tips_social_punish_056_lobby," .. t.year .. "," .. t.month .. "," .. t.day .. "," .. t.hour .. "," .. t.min)
    MessageBox.ShowError(s .. "\n" .. game.bannedReason)
  end
end

function gui.EventShowCloseRole(sender, args)
  ShowCloseRole(true)
end

function ShowNoSpeak(needMesg)
  if Lobby and Lobby.ui then
    if game.isNoSpeak then
      local t = os.date("*t", game.endNoSpeakTime)
      local s = GetMatchedUTF8Text("tips_social_punish_056_lobby," .. t.year .. "," .. t.month .. "," .. t.day .. "," .. t.hour .. "," .. t.min)
      Lobby.ui.no_speak.Hint = s .. "\n" .. game.bannedReason
      if needMesg then
        MessageBox.ShowError(s .. "\n" .. game.bannedReason)
      end
    end
    Lobby.ui.no_speak.Visible = game.isNoSpeak
  end
end

function gui.EventShowNoSpeak(sender, args)
  ShowNoSpeak(true)
end

function InitLtvHeader(ltv, t)
  for _, v in ipairs(t) do
    ltv:AddColumn(table.unpack(v))
  end
end
