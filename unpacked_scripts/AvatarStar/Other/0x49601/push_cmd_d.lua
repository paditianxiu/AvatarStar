module("PushCmd", package.seeall)
local state = ptr_cast(game.CurrentState)
local money_callback = {}

function SubscribeMoney(cb)
  table.insert(money_callback, cb)
end

function FireMoney(my_money)
  for k, v in pairs(money_callback) do
    v(my_money)
  end
end

function GetMyMoney(c)
  local my_money = {
    ComFuc.globalGP,
    ComFuc.globalMB,
    ComFuc.globalTB,
    ComFuc.globalTB
  }
  return my_money[c]
end

function GetLevel()
  return ComFuc.globalLV
end

function GetExp()
  return ComFuc.globalEXP
end

function GetExpP()
  return ComFuc.globalEXPP
end

function GetExpN()
  return ComFuc.globalEXPN
end

local level = {}

function SubscribeLevel(k, v)
  level.k = v
end

function FireLevel(lv)
  for k, v in pairs(level) do
    v(lv)
  end
end

cmdTable = {
  updatePlayer = function(data)
    ComFuc.globalGP = data.gp or ComFuc.globalGP
    ComFuc.globalMB = data.mb or ComFuc.globalMB
    if ComFuc.isCloseMedal then
      ComFuc.globalTB = data.tk or ComFuc.globalTB
    else
      ComFuc.globalTB = data.tb or ComFuc.globalTB
    end
    ComFuc.globalLV = data.lv
    ComFuc.globalExp = data.exp
    ComFuc.globalEXPP = data.expPercent
    ComFuc.globalEXPN = data.expNextLevel
    Lobby.ui.role_dianbi.Text = " " .. ComFuc.globalMB
    Lobby.ui.role_gbi.Text = " " .. ComFuc.globalGP
    Lobby.ui.role_mbi.Text = " " .. ComFuc.globalTB
    Lobby.ui.role_level.Text = ComFuc.globalLV
    ExpBar.SetExpBar(Lobby.ui.bar_exp, Lobby.ui.bar_exp_c, Lobby.ui.bar_exp_l, data.exp, data.expNextLevel)
    FireMoney({
      ComFuc.globalGP,
      ComFuc.globalMB,
      ComFuc.globalTB,
      ComFuc.globalTB
    })
    FireLevel(data.lv)
  end,
  winRollPlayer = function(data)
    if Balance then
    end
  end,
  missionListChanged = function(data)
    ComFuc.TestHasAwardNoReceive()
    if Mission and Mission.Active() then
      Mission.RequestSMList({
        t = data.type .. ";"
      })
    end
  end,
  newMail = function(data)
    ComFuc.globalNewMail = true
    Lobby.SetNewMail()
    gui:PlayAudio("promptmail")
  end,
  newRequisition = function(data)
    if Guild then
      Guild.ShowNewManReplay(true)
    end
  end,
  newTeamRequisition = function(data)
    if GuildTeamMy then
      GuildTeamMy.ShowNewManReplay(true)
    end
  end,
  petHotkeyExpired = function(data)
    MessageBox.ShowError(GetUTF8Text("msgbox_pet_skill_cue_02"))
  end,
  facebook = function(data)
    Lobby.RequestCompletedFbQuests()
  end
}

function OnServerCmd(sender, args)
  local data, load_err = rpc.load_result(args.Details)
  if data then
    if data.cmd and cmdTable[data.cmd] then
      cmdTable[data.cmd](data)
    end
  else
    print(load_err)
  end
end
