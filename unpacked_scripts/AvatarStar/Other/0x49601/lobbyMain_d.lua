module("Lobby", package.seeall)
require("onlinereward.lua")
require("bufList.lua")
if not AHMain then
  require("auction_house/ah_main.lua")
end
ESCPressed = nil
mainBtnPushDown = 0
mainLc = {
  Vector2(371, 78),
  Vector2(446, 78),
  Vector2(521, 78),
  Vector2(596, 78),
  Vector2(671, 78),
  Vector2(746, 78),
  Vector2(821, 78),
  Vector2(896, 78),
  Vector2(971, 78)
}
mainGap = Vector2(-50, 75)
ligLc = {
  mainLc[1] + mainGap,
  Vector2(0, 900),
  mainLc[2] + mainGap,
  mainLc[5] + mainGap,
  mainLc[7] + mainGap,
  mainLc[6] + mainGap,
  mainLc[4] + mainGap,
  mainLc[3] + mainGap,
  mainLc[7] + mainGap,
  mainLc[8] + mainGap,
  mainLc[7] + mainGap
}
local MAX_SHOW_BUF_CNT = 4
local MAX_BUF_CNT = 5
max_buf_end_time = 0
local buf_show_list = {}
local buf_list_from_server = {}
local punishment_run_cnt = 0
local punishment_sleep_cnt = 0
local buf_description = {}
local isFirstShow = true
local timer, gameTFuc
petModuleOpened = nil
local col0 = ARGB(0, 255, 255, 255)
local colw = ARGB(255, 255, 255, 255)
local coly = ARGB(255, 255, 255, 0)
local jobName = {
  GetUTF8Text("UI_profession_Guardian"),
  GetUTF8Text("UI_profession_Gunner"),
  GetUTF8Text("UI_profession_Assassin"),
  GetUTF8Text("UI_profession_Biochemical")
}
local resDir = "/ui/skinF/lobby/"
giftAwardList = {}
mh_skin = Gui.ControlSkin({
  BackgroundImage = Gui.Image("ui/skinF/skin_common_online_award_icon03.tga", Vector4(0, 0, 0, 0))
})

function ComTimeLabel(name, text, size, lc, alpha, fontSize, textColor, align, skin, visible, textureF)
  return Gui.Label(name)({
    Size = size,
    Location = lc,
    Text = text,
    BackgroundColor = ARGB(alpha, 255, 255, 255),
    FontSize = fontSize,
    TextColor = textColor,
    Skin = skin,
    TextAlign = align,
    Visible = visible,
    TextureFont = textureF,
    Enable = false
  })
end

ui = Gui.Create()({
  Gui.Control("lobby_root")({
    Size = Vector2(1200, 900),
    Location = Vector2(200, 0),
    ComFuc.ComButton("btn_m_2", nil, Vector2(90, 90), Vector2(1074, 29), 0, true, false, SkinF.lobbyMain_013),
    ComFuc.LobbyMainTabButton(1, Lobby.mainLc[1]),
    ComFuc.LobbyMainTabButton(3, Lobby.mainLc[2]),
    ComFuc.LobbyMainTabButton(4, Lobby.mainLc[5]),
    ComFuc.LobbyMainTabButton(5, Lobby.mainLc[7]),
    ComFuc.LobbyMainTabButton(6, Lobby.mainLc[6]),
    ComFuc.LobbyMainTabButton(7, Lobby.mainLc[4]),
    ComFuc.LobbyMainTabButton(8, Lobby.mainLc[3]),
    ComFuc.LobbyMainTabButton(9, Lobby.mainLc[7]),
    ComFuc.LobbyMainTabButton(10, Lobby.mainLc[8]),
    Gui.Control("ctl_online_root")({
      Size = Vector2(70, 63),
      Location = Vector2(975, 81),
      ComFuc.BtmLabelButton("time_award", Vector2(70, 63), Vector2(0, 0), SkinF.lobbyMain_062),
      Gui.Control("ctl_time_ui")({
        Size = Vector2(70, 18),
        Location = Vector2(0, 42),
        Enable = false,
        ComTimeLabel("hour", "00", Vector2(20, 18), Vector2(2, 0), 0, 18, col0, "kAlignCenterMiddle", nil, true, SkinF.hecheng_number_1),
        ComTimeLabel("minute", "00", Vector2(20, 18), Vector2(26, 0), 0, 18, col0, "kAlignCenterMiddle", nil, true, SkinF.hecheng_number_1),
        ComTimeLabel("second", "00", Vector2(20, 18), Vector2(50, 0), 0, 18, col0, "kAlignCenterMiddle", nil, true, SkinF.hecheng_number_1),
        Gui.Control("mh1")({
          Size = Vector2(6, 18),
          Location = Vector2(22, 0),
          Skin = mh_skin,
          BackgroundColor = colw,
          Enable = false
        }),
        Gui.Control("mh2")({
          Size = Vector2(6, 18),
          Location = Vector2(46, 0),
          Skin = mh_skin,
          BackgroundColor = colw,
          Enable = false
        })
      }),
      Gui.Control("getGift_bg")({
        Size = Vector2(70, 63),
        Location = Vector2(0, 0),
        Skin = SkinF.lobbyMain_064_2,
        BackgroundColor = colw,
        Enable = false
      }),
      Gui.Control("getGift")({
        Size = Vector2(70, 63),
        Location = Vector2(0, 0),
        Skin = SkinF.lobbyMain_064,
        BackgroundColor = colw,
        Shine = true,
        Enable = false
      }),
      Gui.Control("getGiftFinish")({
        Size = Vector2(70, 63),
        Location = Vector2(0, 0),
        Skin = SkinF.lobbyMain_082,
        BackgroundColor = colw,
        Enable = false
      }),
      Gui.TimerLabel("tlbl_online")({
        Timer = 1,
        Text = "0",
        Visible = false
      }),
      Gui.TimerLabel("left_time")({
        Timer = 1,
        Text = "0",
        Visible = false
      })
    }),
    ComFuc.ComButton("btn_chatUnShow", nil, Vector2(44, 38), Vector2(826, 862), 16, false, false, SkinF.lobbyMain_069, true),
    ComFuc.BtmButton("btn_activity", Vector2(878, 862), SkinF.lobbyMain_060[8]),
    ComFuc.BtmButton("btn_rankArmy", Vector2(925, 862), SkinF.lobbyMain_060[7]),
    ComFuc.BtmButton("btn_sign", Vector2(972, 862), SkinF.lobbyMain_060[1]),
    ComFuc.BtmButton("btn_social", Vector2(1019, 862), SkinF.lobbyMain_060[3]),
    ComFuc.BtmButton("btn_mail", Vector2(1066, 862), SkinF.lobbyMain_060[2][1]),
    ComFuc.BtmButton("btn_ESC", Vector2(1113, 862), SkinF.lobbyMain_060[4]),
    ComFuc.ComButton("look_info", nil, Vector2(32, 32), Vector2(332, 18), 0, false, false, SkinF.lobbyMain_066),
    ComFuc.ComHeadMessage(Vector2(18, 13), 0, Vector2(123, 123), "topHead"),
    ExpBar.ComExpBar("bar_exp", Vector2(212, 23), Vector2(153, 56), 0, 1, SkinF.lobbyMain_expbar[1], SkinF.lobbyMain_expbar[2], "kAlignLeftMiddle"),
    ComFuc.ComControl("topHead_c", Vector2(123, 123), Vector2(18, 13), 255, SkinF.lobbyMain_068),
    ComFuc.ComButton("topHead_b", nil, Vector2(139, 139), Vector2(9, 4), 0, false, false, SkinF.lobbyMain_075),
    ComFuc.ComLabel("role_level", nil, Vector2(40, 19), Vector2(108, 21), 0, 16, colw, "kAlignCenterMiddle", nil, true, SkinF.level_number_1),
    ComFuc.ComLabel("role_job", nil, Vector2(31, 31), Vector2(155, 18), 255, 0),
    ComFuc.ComLabel("role_name", nil, Vector2(130, 22), Vector2(198, 22), 0, 16, colw),
    ComFuc.ComLabel("role_gbi", nil, Vector2(100, 15), Vector2(147, 90), 0, 14, colw, "kAlignRightMiddle"),
    ComFuc.ComLabel("role_dianbi", nil, Vector2(100, 15), Vector2(147, 119), 0, 14, coly, "kAlignRightMiddle"),
    ComFuc.ComLabel("role_mbi", 0, Vector2(100, 15), Vector2(251, 90), 0, 14, coly, "kAlignRightMiddle"),
    ComFuc.ComButton("btn_money", nil, Vector2(99, 26), Vector2(256, 115), 0, false, false, SkinF.lobbyMain_067),
    ComFuc.ComControl("buf_1", Vector2(44, 34), Vector2(11, 2), 255, SkinF.personalInfo_234[2][1]),
    ComFuc.ComControl("buf_2", Vector2(44, 34), Vector2(-5, 36), 255, SkinF.personalInfo_234[2][2]),
    ComFuc.ComControl("buf_3", Vector2(44, 34), Vector2(-1, 70), 255, SkinF.personalInfo_234[3][2]),
    ComFuc.ComLabel("run_num", nil, Vector2(44, 34), Vector2(-5, 36), 255, 18, colw, "kAlignRightBottom", SkinF.lobbyMain_083, true, SkinF.hecheng_number_1),
    ComFuc.ComLabel("hook_num", nil, Vector2(44, 34), Vector2(11, 2), 255, 18, colw, "kAlignRightBottom", SkinF.lobbyMain_076, false, SkinF.hecheng_number_1),
    ComFuc.ComControl("rank_point", Vector2(32, 32), Vector2(123, 54), 255, SkinF.SkinF.rank_006[1][1]),
    ComFuc.ComControl("no_speak", Vector2(44, 34), Vector2(58, 1), 255, SkinF.personalInfo_241, false),
    ComFuc.ComControl("buf_4", Vector2(36, 36), Vector2(106, 108), 255, SkinF.personalInfo_234[1][1]),
    ComFuc.ComControl("buf_list", Vector2(44, 34), Vector2(10, 108), 255, SkinF.personalInfo_234[1][1]),
    ComFuc.ComButton("vip_info", nil, Vector2(36, 36), Vector2(106, 108), 0, false, false, SkinF.lobbyMain_074),
    ComFuc.ComControlAddPt("vip_particle", Vector2(36, 36), Vector2(106, 108), "ui_viptime"),
    ComFuc.ComControl("lobby_btm", Vector2(786, 40), Vector2(44, 861)),
    ComFuc.ComControl("lobby_mid", Vector2(1142, 694), Vector2(28, 156)),
    ComFuc.ComControl("cover_btn_rankArmy", Vector2(44, 38), Vector2(925, 862)),
    ComFuc.ComButton("stretch_public", nil, Vector2(24, 28), Vector2(1044, 10), 0, false, false, SkinF.lobbyMain_077[1]),
    Gui.NewMessagePanel("sys_pulic")({
      Location = Vector2(370, 11),
      Size = Vector2(679, 66),
      Style = "Sociality.MessagePanel",
      FontSize = 14,
      VScrollBarDisplay = false,
      MaxTextWidth = 650,
      OnePageLineNum = 3,
      MaxLineNum = 3,
      LineGap = 1
    }),
    Gui.Button("btn_receive")({
      Size = Vector2(70, 63),
      Location = Vector2(975, 81),
      BackgroundColor = colw,
      Skin = SkinF.lobbyMain_063,
      ComFuc.ComControl(nil, Vector2(70, 63), Vector2(0, 0), 255, SkinF.lobbyMain_062),
      ComFuc.ComControl("text_receive", Vector2(70, 63), Vector2(0, 0), 255, SkinF.lobbyMain_064)
    }),
    Gui.Control("gameLastT_p")({
      Size = Vector2(146, 142),
      Location = Vector2(1049, 7),
      BackgroundColor = colw,
      Enable = false,
      Skin = SkinF.lobbyMain_071,
      Gui.Control({
        Size = Vector2(90, 90),
        Skin = SkinF.lobbyMain_072,
        Location = Vector2(25, 22),
        ComFuc.ComControl(nil, Vector2(86, 86), Vector2(2, 2), 255, SkinF.lobbyMain_078),
        Gui.Control("gameMatchCount")({
          Size = Vector2(86, 86),
          BackgroundColor = col0,
          Location = Vector2(2, 2),
          ComFuc.ComControl(nil, Vector2(86, 86), Vector2(0, 0), 255, SkinF.lobbyMain_081)
        }),
        ComFuc.ComControl("gameMatchCount_upLight", Vector2(0, 0), Vector2(0, 0), 255, SkinF.lobbyMain_080),
        ComFuc.ComControl(nil, Vector2(86, 86), Vector2(2, 2), 255, SkinF.lobbyMain_079),
        Gui.WaitTime("gameLastT")({
          Size = Vector2(90, 90),
          BackgroundColor = col0,
          CanPushDown = true,
          EventMouseEnter = function(sender, e)
            sender.Parent.BackgroundColor = colw
          end,
          EventMouseLeave = function(sender, e)
            sender.Parent.BackgroundColor = col0
          end
        })
      }),
      ComFuc.ComControlAddPt("partc2", Vector2(128, 128), Vector2(6, 3), "ui_start2")
    }),
    ComFuc.ComControlAddPt("partc1", Vector2(128, 128), Vector2(1055, 10), "ui_start3"),
    ComFuc.ComButton("btn_closeLT", nil, Vector2(43, 43), Vector2(1149, 3), 0, false, false, SkinF.battle_015),
    ComFuc.ComFlashArrow("mail_f", Vector2(94, 42), Vector2(1042, 815), 255, SkinF.lobbyMain_073, false, GetUTF8Text("tips_social_new_mail_arrival")),
    ComFuc.ComFlashArrow("sign_f", Vector2(94, 42), Vector2(948, 815), 255, SkinF.lobbyMain_073, false, GetUTF8Text("tips_store_Sign_In_tips")),
    ComFuc.ComFlashArrow("leftP_f", Vector2(134, 42), Vector2(304, 125), 255, SkinF.lobbyMain_073, false, GetUTF8Text("button_common_skill_01")),
    ComFuc.ComControlAddPt("partc3", Vector2(128, 128), Vector2(1056, 13), "ui_start")
  }),
  ComFuc.ComControl("lobby_root_p", Vector2(1600, 900), Vector2(0, 0), 255, SkinF.lobbyMain_033),
  ComFuc.ComControl("down_light", Vector2(164, 47), Vector2(0, 0), 255, SkinF.lobbyMain_065),
  ComFuc.ComControlAddPt("partc4", Vector2(128, 128), mainLc[3] - Vector2(28, 28), "ui_renwu_star")
})
ui.vip_particle.Particle:Reset()
ui.look_info.Hint = GetUTF8Text("tips_lobby_Common_Desc19")
ui.vip_info.Hint = GetUTF8Text("tips_lobby_VIP_button_tips")
ui.btn_sign.Hint = GetUTF8Text("UI_common_Daily_Sign_In")
ui.btn_chatUnShow.Hint = GetUTF8Text("tips_lobby_Button_Decs4")
ui.btn_mail.Hint = GetUTF8Text("tips_lobby_Button_Decs5")
ui.btn_social.Hint = GetUTF8Text("tips_lobby_Common_Desc14")
ui.btn_ESC.Hint = GetUTF8Text("tips_lobby_Button_Decs6")
ui.role_gbi.Hint = GetUTF8Text("id_common_Gold")
ui.role_dianbi.Hint = GetUTF8Text("id_common_CC")
ui.role_mbi.Hint = GetUTF8Text("msgbox_common_conditionkey_195")
ui.btn_rankArmy.Hint = GetUTF8Text("UI_social_military_rank")
ui.btn_activity.Hint = GetUTF8Text("tips_common_bill_04")
ui.rank_point.Hint = GetUTF8Text("UI_social_rank_lv_01")
ui.cover_btn_rankArmy.Hint = GetUTF8Text("tips_social_rank_error")
ui.down_light.Enable = false
ui.btn_m_2.ClickAudio = ""
ui.btn_m_9.Visible = false
ui.btn_receive.Visible = false
ui.mail_f.Enable = false
ui.mail_f.DirState = 1
ui.sign_f.Enable = false
ui.sign_f.DirState = 1
ui.leftP_f.Enable = false
ui.leftP_f.DirState = 1
ui.btn_money.Enable = config.IsRecharge
ui.vip_info.Visible = config.IsNeedVip
ui.partc3.Visible = false
ui.partc4.Visible = false
ui.buf_1.Visible = false
ui.buf_2.Visible = false
ui.buf_3.Visible = false
ui.buf_4.Visible = false
ui.buf_list.Visible = false
ui.hook_num.TextPadding = Vector4(0, 0, 6, 0)
ui.run_num.TextPadding = Vector4(0, 0, 6, 0)
ui.partc3.Particle:Reset()
ui.partc4.Particle:Reset()
ui.partc4.Parent = ui.lobby_root
ui.getGift_bg.Visible = false
ui.getGift.Visible = false
ui.getGiftFinish.Visible = false
ui.btn_m_2.ClickAudio = "game_launch_prior"

function GoLobby(i)
  if ptr_cast(game.CurrentState, "Client.StateAvatar") then
    ptr_cast(game.CurrentState):ReturnToLobby()
  end
  if i ~= 2 then
    ui.gameLastT.PushDown = false
  end
  NewLead.HideLead()
  Lobby.OnComSwitch(i)
end

function HideGameTime(p)
  if not p then
    ui.partc1.Particle:Reset()
  end
  ui.gameLastT_p.Visible = false
  ui.btn_closeLT.Visible = false
  ComFuc.isReadyStart = false
  ui.partc3.Visible = mainBtnPushDown ~= 2
  ComFuc.Is_StartGameParticle = mainBtnPushDown ~= 2
  ComFuc.isReadyStart = false
  ComFuc.isShowGameTime = false
  if LobbyBattleGame then
    LobbyBattleGame.SetMatchButtonState(false)
  end
  local state = ptr_cast(game.CurrentState, "Client.StateLobby")
  if state then
    state:PlaySpecialAudioForMatch(ui.gameLastT_p.Visible)
  end
end

HideGameTime(true)

function ShowGameTime(t, fuc)
  ui.partc1.Particle:Reset()
  ui.partc2.Particle:Reset()
  ui.gameLastT_p.Visible = true
  ui.gameLastT.IsGo = true
  ui.gameLastT.IsReady = true
  ui.gameLastT.TimeAll = t
  ui.gameLastT.IsReady = true
  ui.gameLastT.PushDown = ui["btn_m_" .. 2].PushDown
  ui.btn_closeLT.Visible = true
  gameTFuc = fuc
  ui.partc3.Visible = false
  ComFuc.Is_StartGameParticle = false
  ComFuc.isReadyStart = true
  ComFuc.isShowGameTime = true
  if not ComFuc.Is_FirstPrintLog[5] then
    rpc.safecall("user_retention", {
      sign = ComFuc.First_Log[5]
    }, function(data)
    end)
    ComFuc.Is_FirstPrintLog[5] = true
  end
  if LobbyBattleGame then
    LobbyBattleGame.SetMatchButtonState(true)
  end
  local state = ptr_cast(game.CurrentState, "Client.StateLobby")
  if state then
    state:PlaySpecialAudioForMatch(ui.gameLastT_p.Visible)
  end
end

function ShowMatchGameCount(currentPeople, maxPeople)
  local r = currentPeople / maxPeople
  local p = 1 - 2 * math.abs(r - 0.5)
  ui.gameMatchCount.Size = Vector2(86, 86 * (1 - r))
  ui.gameMatchCount_upLight.Size = Vector2(112, 20) * Vector2(p, p)
  if 0.8125 <= r then
    ui.gameMatchCount_upLight.Location = Vector2((90 - 112 * p) / 2, 90 * (1 - r) - 20 * p / 2 + 2)
  else
    ui.gameMatchCount_upLight.Location = Vector2((90 - 112 * p) / 2, 90 * (1 - r) - 20 * p / 2)
  end
end

local ShowLeftPointTips, SetMainBtnPushDown = function(isShow)
  ui.leftP_f.Visible = isShow
end, function(isShow)
  ui.leftP_f.Visible = isShow
end
local SetMainBtnPushDown, SetCanSwitch = function(i)
  if i == 0 then
    for k = 2, 10 do
      ui["btn_m_" .. k].PushDown = false
    end
  else
    ui["btn_m_" .. i].PushDown = false
  end
end, true
local SetCanSwitch, SwitchMainTab = function(i)
  if i == 0 then
    return true
  elseif i == 1 then
    local a, b = PersonalInfo.CanSwitch()
    return a, b
  elseif i == 2 then
    local a, b = LobbyStartGame.CanSwitch()
    return a, b
  elseif i == 3 then
    local a, b = Guild.CanSwitch()
    return a, b
  elseif i == 4 then
    local a, b = Shop.CanSwitch()
    return a, b
  elseif i == 5 then
    local a, b = AHMain.CanSwitch()
    return a, b
  elseif i == 6 then
    return true
  elseif i == 7 then
    return true
  elseif i == 8 then
    return true
  elseif i == 9 then
    return true
  elseif i == 10 then
    return true
  end
end, "game_launch_prior"
local SwitchMainTab, SwitchTo = function(i)
  if mainBtnPushDown == 0 then
    if PersonalInfo then
      PersonalInfo.Hide()
    end
    if Guild then
      Guild.Hide()
    end
    if AHMain then
      AHMain.Hide()
    end
    if Shop then
      Shop.Hide()
    end
    if Mission then
      Mission.Hide()
    end
    if LobbyStartGame then
      LobbyStartGame.Hide()
    end
    if PersonalInfo then
      PersonalInfo.HideRefit()
    end
    if LuckDraw then
      LuckDraw.Hide()
    end
    if RankPublic then
      RankPublic.Hide()
    end
  elseif mainBtnPushDown == 1 then
    PersonalInfo.Hide()
  elseif mainBtnPushDown == 2 then
    LobbyStartGame.Hide()
  elseif mainBtnPushDown == 3 then
    Guild.Hide()
  elseif mainBtnPushDown == 4 then
    Shop.Hide()
  elseif mainBtnPushDown == 5 then
    AHMain.Hide()
  elseif mainBtnPushDown == 6 then
  elseif mainBtnPushDown == 7 then
    PersonalInfo.HideRefit()
  elseif mainBtnPushDown == 8 then
    Mission.Hide()
  elseif mainBtnPushDown == 9 then
    LuckDraw.Hide()
  elseif mainBtnPushDown == 10 then
    RankPublic.Hide()
  end
  if i == 1 then
    PersonalInfo.Show(ui.lobby_mid)
  elseif i == 2 then
    LobbyStartGame.Show(ui.lobby_mid)
  elseif i == 3 then
    require("guild.lua")
    Guild.Show(ui.lobby_mid)
  elseif i == 4 then
    require("shop/shop.lua")
    Shop.Show(ui.lobby_mid)
  elseif i == 5 then
    AHMain.Show(ui.lobby_mid)
  elseif i == 6 then
  elseif i == 7 then
    PersonalInfo.ShowRefit(ui.lobby_mid)
  elseif i == 8 then
    require("mission/mission.lua")
    Mission.Show(ui.lobby_mid)
  elseif i == 9 then
    require("luckDraw.lua")
    LuckDraw.Show(ui.lobby_mid)
  elseif i == 10 then
    require("RankPublic.lua")
    RankPublic.Show(ui.lobby_mid)
  end
  if i ~= 2 and LobbyBattleGame then
    LobbyBattleGame.RemoveTimer2()
  end
end, 0

function SwitchTo(i, state)
  ui["btn_m_" .. i].PushDown = true
  if mainBtnPushDown ~= i then
    ui.down_light.Parent = gui
    ui.down_light.Location = ligLc[i] + Vector2(ComFuc.locationChanged, 0)
    SetMainBtnPushDown(mainBtnPushDown)
    SwitchMainTab(i)
    mainBtnPushDown = i
    if state then
      state:EnterAvatarRoom()
    end
  end
end

local OnComSwitch, _gen_msg_from_second = function(i, state)
  local canA, canT = SetCanSwitch(mainBtnPushDown)
  if canA then
    SwitchTo(i, state)
    ui.partc3.Visible = i ~= 2 and not ui.gameLastT_p.Visible
    ComFuc.Is_StartGameParticle = i ~= 2 and not ui.gameLastT_p.Visible
  else
    MessageBox.ShowWithConfirmCancel(canT, function(sender, e)
      SwitchTo(i, state)
    end, function(sender, e)
      ui["btn_m_" .. i].PushDown = false
    end)
  end
  if i ~= 2 then
  else
    LobbyStartGame.SelectMainBtn(1)
  end
end, function(i, state)
  local canA, canT = SetCanSwitch(mainBtnPushDown)
  if canA then
    SwitchTo(i, state)
    ui.partc3.Visible = i ~= 2 and not ui.gameLastT_p.Visible
    ComFuc.Is_StartGameParticle = i ~= 2 and not ui.gameLastT_p.Visible
  else
    MessageBox.ShowWithConfirmCancel(canT, function(sender, e)
      SwitchTo(i, state)
    end, function(sender, e)
      ui["btn_m_" .. i].PushDown = false
    end)
  end
  if i ~= 2 then
  else
    LobbyStartGame.SelectMainBtn(1)
  end
end

function _gen_msg_from_second(seconds)
  local msg
  local d = math.floor(seconds / 86400)
  local h = math.floor(seconds / 3600)
  local m = math.floor(seconds / 60)
  local s = seconds
  if 0 < d then
    h = math.floor(seconds % 86400 / 3600)
    local tt, n = string.gsub(GetUTF8Text("tips_lobby_additional_string_074"), "%%d", d)
    tt, n = string.gsub(tt, "%%h", h)
    msg = tt
  elseif 0 < h then
    m = math.floor(seconds % 3600 / 60)
    local tt, n = string.gsub(GetUTF8Text("tips_lobby_additional_string_075"), "%%h", h)
    tt, n = string.gsub(tt, "%%m", m)
    msg = tt
  elseif 0 < m then
    s = math.floor(seconds % 30 / 1)
    local tt, n = string.gsub(GetUTF8Text("tips_lobby_additional_string_076"), "%%m", m)
    tt, n = string.gsub(tt, "%%s", s)
    msg = tt
  else
    local tt, n = string.gsub(GetUTF8Text("tips_lobby_additional_string_077"), "%%s", s)
    msg = tt
  end
  return msg
end

function TimerRefresh()
  local buf_active_cnt = 0
  if 0 < max_buf_end_time then
    max_buf_end_time = max_buf_end_time - 1
    for i = 1, MAX_BUF_CNT do
      if buf_list_from_server[i] and 0 < buf_list_from_server[i].left_time then
        buf_active_cnt = buf_active_cnt + 1
        buf_list_from_server[i].left_time = buf_list_from_server[i].left_time - 1
      end
    end
  else
    for i = 1, 4 do
      ui["buf_" .. i].Visible = false
    end
    TimerRemove()
    return
  end
  local head_curr_buf = 1
  if ui.hook_num.Visible then
    ui["buf_" .. head_curr_buf].Visible = false
    head_curr_buf = head_curr_buf + 1
    buf_active_cnt = buf_active_cnt + 1
  end
  if ui.run_num.Visible then
    ui["buf_" .. head_curr_buf].Visible = false
    head_curr_buf = head_curr_buf + 1
    buf_active_cnt = buf_active_cnt + 1
    ui.run_num.Location = Vector2(-5, 36)
    if ui.hook_num.Visible == false then
      ui.run_num.Location = ui.hook_num.Location
    end
  end
  buf_show_list = {}
  for i = 1, MAX_BUF_CNT do
    if buf_list_from_server[i] and 0 < buf_list_from_server[i].left_time then
      local msg = _gen_msg_from_second(buf_list_from_server[i].left_time)
      if head_curr_buf < MAX_SHOW_BUF_CNT then
        ui["buf_" .. head_curr_buf].Visible = true
        ui["buf_" .. head_curr_buf].Skin = buf_list_from_server[i].skin
        ui["buf_" .. head_curr_buf].Hint = string.format(GetUTF8Text("tips_lobby_additional_string_078"), GetUTF8Text(buf_list_from_server[i].desc)) .. msg
      elseif head_curr_buf == MAX_SHOW_BUF_CNT and buf_active_cnt == MAX_SHOW_BUF_CNT then
        ui["buf_" .. "list"].Visible = true
        ui["buf_" .. "list"].Skin = buf_list_from_server[i].skin
        ui["buf_" .. "list"].Hint = string.format(GetUTF8Text("tips_lobby_additional_string_078"), GetUTF8Text(buf_list_from_server[i].desc)) .. msg
        ui.buf_list.EventMouseEnter = nil
        ui.buf_list.EventMouseLeave = nil
      else
        buf_show_list[#buf_show_list + 1] = {
          skin = buf_list_from_server[i].skin,
          hint = string.format(GetUTF8Text("tips_lobby_additional_string_078"), GetUTF8Text(buf_list_from_server[i].desc)) .. msg,
          last = _gen_msg_from_second(buf_list_from_server[i].left_time)
        }
        ui.buf_list.Skin = SkinF.personalInfo_234[4][1]
        
        function ui.buf_list.EventMouseEnter(sender, e)
          bufList.Show(ui.lobby_root, buf_show_list)
        end
        
        function ui.buf_list.EventMouseLeave(sender, e)
          bufList.Hide()
        end
        
        ui.buf_list.Visible = true
      end
      head_curr_buf = head_curr_buf + 1
    end
  end
  for i = head_curr_buf, MAX_SHOW_BUF_CNT do
    if i < MAX_SHOW_BUF_CNT then
      ui["buf_" .. i].Visible = false
    else
      ui.buf_list.Visible = false
    end
  end
end

function TimerRemove()
  game.TimerMgr:RemoveTimer(timer)
  timer = nil
end

local quest_message_key = {
  "msgbox_common_grading_01",
  "msgbox_common_grading_02",
  "msgbox_common_grading_03",
  "msgbox_common_grading_04",
  "msgbox_common_grading_05",
  "msgbox_common_grading_06",
  "msgbox_common_grading_07",
  "msgbox_common_grading_08"
}
local completed_quest_list, PopPromotion = {}, "msgbox_common_grading_02"
local PopPromotion, DealCompletedFbQuests = function(quest_list)
  if type(quest_list) == "table" and 0 < #quest_list then
    local current_quest = quest_list[1]
    local quest_message = GetMatchedUTF8Text(string.format("%s,%s", quest_message_key[current_quest.type], current_quest.params))
    local whole_message = quest_message .. "\n" .. GetUTF8Text("msgbox_common_grading_09")
    MessageBox.ShowWithConfirmCancel(whole_message, function()
      rpc.safecall("facebook_success", {
        result = 1,
        type = current_quest.type
      }, nil)
      game:PostFacebookAchievement(current_quest.url)
      PopPromotion(completed_quest_list)
    end, function()
      rpc.safecall("facebook_success", {
        result = 0,
        type = current_quest.type
      }, nil)
      PopPromotion(completed_quest_list)
    end)
    table.remove(quest_list, 1)
  end
end, "msgbox_common_grading_03"

function DealCompletedFbQuests(data)
  completed_quest_list = data.mission
  PopPromotion(completed_quest_list)
end

function RequestCompletedFbQuests()
  rpc.safecall("get_facebook_mission", {}, DealCompletedFbQuests)
end

function OnEnterLobby()
  MessageBox.CloseWaiter()
  LobbyPlayGame.InitStateCallBack()
  LobbyBattleGame.InitStateCallBack()
  AlignUI()
end

function OnRestoreLobby()
  LobbyPlayGame.SwitchRoomListPanel()
  LobbyPlayGame.RequestRoomList()
end

function ChangeTo(i)
  if mainBtnPushDown == 6 then
    GoLobby(i)
  else
    MainBtnSelect(i)
  end
end

function MainBtnSelect(i)
  if mainBtnPushDown ~= i then
    NewLead.HideLead()
    if i == 2 then
      OnComSwitch(2)
    elseif i == 6 then
      if ComFuc.isReadyStart or ComFuc.isReadyMatch then
        MessageBox.ShowError(GetUTF8Text("msgbox_common_num_1188"))
        ui.btn_m_6.PushDown = false
      else
        local state = ptr_cast(game.CurrentState, "Client.StateLobby")
        if state then
          OnComSwitch(6, state)
        end
      end
    else
      OnComSwitch(i)
    end
  else
    ui["btn_m_" .. i].PushDown = true
    if i == 5 and mainBtnPushDown == i then
      AHMain.Hide()
      AHMain.Show(ui.lobby_mid)
    end
  end
end

for i = 1, 10 do
  ui["btn_m_" .. i].EventClick = function(sender, e)
    MainBtnSelect(i)
  end
end

function ui.topHead_b.EventClick(sender, e)
  LookInfo.Show(SelectCharacter.roleServerId)
end

function ui.look_info.EventClick(sender, e)
  LookInfo.Show(SelectCharacter.roleServerId)
end

function ui.vip_info.EventClick(sender, e)
  require("../sys/vipPadShow.lua")
  VipPadShow.Show(ComFuc.VIPLevel)
end

function ui.btn_sign.EventClick(sender, e)
  require("signPresent.lua")
  SignPresent.Show()
end

function ui.btn_rankArmy.EventClick(sender, e)
  require("rank/rank.lua")
  Rank.Show()
end

function ui.btn_activity.EventClick(sender, e)
  L_Activity.RpcActiveList()
end

function ui.btn_ESC.EventClick(sender, e)
  if ESCPressed then
    ESCPressed()
  end
end

local chatTimer
local imgIndex, StopTimer = 1, function(sender, e)
  if ESCPressed then
    ESCPressed()
  end
end
local StopTimer, OnTimer = function()
  if chatTimer then
    game.TimerMgr:RemoveTimer(chatTimer)
    chatTimer = nil
    imgIndex = 1
    ui.btn_chatUnShow.Skin = SkinF.lobbyMain_069
  end
end, "msgbox_common_grading_07"

function OnTimer()
  if imgIndex == 1 then
    ui.btn_chatUnShow.Skin = SkinF.lobbyMain_070
    imgIndex = 2
  else
    ui.btn_chatUnShow.Skin = SkinF.lobbyMain_069
    imgIndex = 1
  end
end

function ui.btn_chatUnShow.EventClick(sender, e)
  if not ChatUnShow.Visible() then
    ChatUnShow.Show(ui.lobby_root)
    StopTimer()
  else
    ChatUnShow.Hide()
  end
end

function ui.btn_social.EventClick(sender, e)
  if not Sociality.Visible() then
    Sociality.Show(ui.lobby_root)
  else
    Sociality.Hide()
  end
end

function ui.btn_mail.EventClick(sender, e)
  if not Mail.Visible() then
    Mail.Show(ui.lobby_root)
  else
    Mail.Hide()
  end
end

function ui.gameLastT.EventClick(sender, e)
  sender.PushDown = true
  if mainBtnPushDown ~= 2 then
    GoLobby(2)
  end
end

function ui.btn_closeLT.EventClick(sender, e)
  HideGameTime()
  if gameTFuc then
    gameTFuc()
  end
end

function ui.btn_money.EventClick(sender, e)
  game:OpenUrl(config.RechargeUrl)
end

function NotifyUnShowChat()
  if not chatTimer and not ChatUnShow.Visible() then
    chatTimer = game.TimerMgr:AddTimer(0.5)
    chatTimer.EventOnTimer = OnTimer
    imgIndex = 1
  end
end

function ShowSysMsgTip(Type, msg)
  ui.sys_pulic:AddSystemMessage(Type, msg)
end

function ClearFirstLineMessage()
  ui.sys_pulic:ClearFirstLineMessage()
end

local GetMessageLineCount, LoadHistoryMessage = function()
  return ui.sys_pulic:GetLineCount()
end, function()
  return ui.sys_pulic:GetLineCount()
end
local LoadHistoryMessage, DealPublicStetchClick = function(nBeginIndex)
  local pMsgItem
  local nIndex = nBeginIndex
  local chat = ptr_cast(game.ChatConnect)
  if chat then
    ui.sys_pulic:ClearMessage()
    while true do
      pMsgItem = chat:GetHistorySysMsg(nIndex)
      if not pMsgItem then
        break
      end
      if pMsgItem.Type ~= 1 then
        ui.sys_pulic:AddSystemMessage(pMsgItem.Type, pMsgItem.Msg)
      end
      nIndex = nIndex + 1
    end
  end
end, "EventClick"

function DealPublicStetchClick()
  ui.sys_pulic.Parent = gui
  NewLead.ui.Anti_addiction.Parent = gui
  if not isPublicStretch then
    ui.sys_pulic.Size = Vector2(679, 66)
    ui.sys_pulic.VScrollBarDisplay = false
    ui.sys_pulic.OnePageLineNum = 3
    ui.sys_pulic.MaxLineNum = 3
    ui.stretch_public.Skin = SkinF.lobbyMain_077[1]
    if 3 < ui.sys_pulic:GetLineCount() then
      LoadHistoryMessage(ui.sys_pulic:GetLineCount() - 3)
    else
      LoadHistoryMessage(0)
    end
  else
    ui.sys_pulic.Size = Vector2(679, 260)
    ui.sys_pulic.VScrollBarDisplay = true
    ui.sys_pulic.OnePageLineNum = 13
    ui.sys_pulic.MaxLineNum = 120
    ui.stretch_public.Skin = SkinF.lobbyMain_077[2]
    LoadHistoryMessage(0)
  end
end

function ui.stretch_public.EventClick(sender, e)
  isPublicStretch = not isPublicStretch
  DealPublicStetchClick()
end

function HyLinkMenu(sender)
  local user_ID, user_name
  ComFuc.InitSocialityMenu(sender.PopupMenu, {
    {
      "IDM_BEG_CHAT",
      GetUTF8Text("button_common_Chat"),
      function()
        ChatBar.OpenFriendChatPair(user_ID, user_name)
      end
    },
    {
      "IDM_VIEW_PERSONALITY",
      GetUTF8Text("button_common_Info"),
      function()
        LookInfo.Show(user_ID)
      end
    },
    {
      "IDM_ADD_TO_FRIEND",
      GetUTF8Text("button_common_Add_Friend"),
      function()
        Sociality.MoveFriend(4, user_ID, user_name, 2, 0)
      end
    },
    {
      "IDM_COPY_NAME",
      GetUTF8Text("tips_social_copy_name"),
      function()
        Sociality.CopyName(user_name)
      end
    }
  })
  
  function sender.EventHyLink(sender, e)
    user_ID = e.user_ID
    user_name = e.user_name
    local menu = sender.PopupMenu
    menu:Open()
  end
end

function SetNewMail(p)
  if p then
    ComFuc.globalNewMail = false
  end
  ui.mail_f.Visible = ComFuc.globalNewMail
end

local SetIsCheckin, AsyncCmdShow = function(p)
  ui.sign_f.Visible = not p
  ComFuc.isSignFromSelect = false
end, function(p)
  ui.sign_f.Visible = not p
  ComFuc.isSignFromSelect = false
end
local AsyncCmdShow, _sort_buf_list = function(tn)
  ui.role_job.Skin = SkinF.personalInfo_job[SelectCharacter.role_job_id + 1]
  ui.role_name.Text = SelectCharacter.role_text
  ui.role_level.Text = ComFuc.globalLV
  ComFuc.fromSelToLobby2 = false
  ComFuc.isFromNew = 0
  ui.lobby_root_p.Parent = gui
  ui.lobby_root.Parent = gui
  ui.down_light.Parent = gui
  if mainBtnPushDown == 0 then
    mainBtnPushDown = 1
  end
  ui.down_light.Location = ligLc[mainBtnPushDown] + Vector2(ComFuc.locationChanged, 0)
  if tn == 2 or tn == 3 then
    ForceLeadGotoMission()
  end
  if tn == 4 and mainBtnPushDown == 1 then
    PersonalInfo.ForceLeadEasyUse(PersonalInfo.FORCE_LEAD_EASYUSE_TAG)
  end
  if tn == 5 and mainBtnPushDown == 1 then
    PersonalInfo.ForceLeadSkillLearn(PersonalInfo.FORCE_LEAD_SKILLLEARN_TAG)
  end
  if tn == 6 and mainBtnPushDown == 1 then
    MainBtnSelect(8)
    Mission.ForceLeadAcceptTask(Mission.FORCE_LEAD_SEL_TUTORIAL)
  end
  if tn == 7 then
    ForceLeadGotoShop()
  end
  ui.partc3.Visible = not game.GameBalanceEnterMacth and mainBtnPushDown ~= 2
  ComFuc.Is_StartGameParticle = not game.GameBalanceEnterMacth and mainBtnPushDown ~= 2
  if ComFuc.isInGame and mainBtnPushDown ~= 2 then
    ComFuc.isInGame = false
    MainBtnSelect(2)
  end
  if 1 <= ComFuc.globalGainSkillP then
    ComFuc.globalGainSkillP = 0
    require("../sys/levelUpTipShow.lua")
    LevelUpTipShow.Show(ComFuc.globalLV)
  end
  ChatBar.Show(ui.lobby_btm)
  AlignUI()
  Visible = true
  NewLead.ui.Anti_addiction.Parent = gui
  HyLinkMenu(ui.sys_pulic)
  if ComFuc.isHookOP then
    ComFuc.isHookOP = false
    MessageBox.ShowError(GetUTF8Text("msgbox_inGame_erhuo"))
  end
  NewLead.ShowHoldUi()
  ui.cover_btn_rankArmy.Visible = false
  ui.btn_rankArmy.Enable = true
  ui.sys_pulic.Parent = gui
  ui.sys_pulic.Location = Vector2(370, 11) + Vector2(ComFuc.locationChanged, 0)
end, "EventClick"

function _sort_buf_list(tbl)
  return tbl
end

function rpc_player_detail(p, call_back)
  rpc.safecall("player_detail", {}, function(data)
    petModuleOpened = data.player.isOpenPet
    punishment_sleep_cnt = data.player.hookNum
    if punishment_sleep_cnt and 1 <= punishment_sleep_cnt then
      ui.hook_num.Visible = true
      ui["buf_" .. 1].Visible = false
      ui.hook_num.Text = punishment_sleep_cnt or 1
      ui.hook_num.Hint = string.format(GetUTF8Text("tips_social_debuff_parasite_num"), punishment_sleep_cnt or 1)
    else
      ui.hook_num.Visible = false
    end
    punishment_run_cnt = data.player.halfQuitNum
    if punishment_run_cnt and 1 <= punishment_run_cnt and 0 ~= ComFuc.globalLeftTime then
      ui.run_num.Visible = true
      ui["buf_" .. 2].Visible = false
      ui.run_num.Text = punishment_run_cnt or 1
      ui.run_num.Location = Vector2(-5, 36)
      if ui.hook_num.Visible == false then
        ui.run_num.Location = ui.hook_num.Location
      end
    else
      ui.run_num.Visible = false
    end
    ui.left_time.Timer = 1
    ui.left_time:Start()
    ComFuc.leadList = data.player.tutorial or 0
    ComFuc.globalLV = data.player.level
    ComFuc.globalMB = data.player.mb or ComFuc.globalMB
    ComFuc.globalGP = data.player.gp
    ComFuc.giveTime = data.giveTime
    if ComFuc.isCloseMedal then
      ComFuc.globalTB = data.player.tk
    else
      ComFuc.globalTB = data.player.tb
    end
    ComFuc.globalEXP = data.player.exp
    ComFuc.globalEXPN = data.player.expNextLevel
    ComFuc.globalNewMail = data.player.newMail
    ComFuc.isOpenHeroList = data.player.configList
    SetNewMail()
    if ComFuc.globalNewMail then
      gui:PlayAudio("promptmail")
    end
    if PersonalInfo then
      PersonalInfo.EnablePetModule(petModuleOpened == "Y" or data.player.level >= 3)
    end
    ComFuc.isVIP = 0 < data.player.vipLevel
    ComFuc.VIPLevel = data.player.vipLevel or 0
    ComFuc.isTrialedVip = data.player.isTrialedVip
    ComFuc.isTrialingVip = data.player.isTrialingVip
    ComFuc.isTrialedVipTip = data.player.isTrialedVipTip
    if not ComFuc.isTrialedVipTip and ComFuc.VIPLevel == 0 and ComFuc.isTrialedVip then
      ComFuc.isTrialedVipTip = true
      rpc.safecall("update_trial_vip_tip", {}, nil)
      MessageBox.ShowError(GetUTF8Text("msgbox_store_VIP_temp_03"))
    end
    SelectCharacter.role_text = data.player.name
    SelectCharacter.job_text = jobName[data.player.occupation + 1]
    SelectCharacter.roleServerId = data.player.id
    SelectCharacter.role_job_id = data.player.occupation
    SelectCharacter.isHaveGuild = data.player.isInGuild
    ui.role_job.Skin = SkinF.personalInfo_job[SelectCharacter.role_job_id + 1]
    ui.role_name.Text = SelectCharacter.role_text
    ui.role_dianbi.Text = " " .. ComFuc.globalMB
    ui.role_gbi.Text = " " .. ComFuc.globalGP
    ui.role_mbi.Text = " " .. ComFuc.globalTB
    ui.role_level.Text = ComFuc.globalLV
    ui.rank_point.Skin = SkinF.SkinF.rank_006[data.player.rankType][data.player.rankLevel]
    if data.player.rankLevel <= 9 then
      ui.rank_point.Hint = GetUTF8Text("UI_social_rank_lv_0" .. math.max(1, data.player.rankLevel))
    else
      ui.rank_point.Hint = GetUTF8Text("UI_social_rank_lv_" .. math.max(1, data.player.rankLevel))
    end
    ComFuc.g_bNoDisturbed = data.player.isAvoidDisturb == "Y"
    if ComFuc.g_bNoDisturbed and ComFuc.is_from_select then
      ComFuc.is_from_select = false
      MessageBox.ShowError(GetUTF8Text("msgbox_social_no_disturb_message"))
    end
    if data.player.leftpoints then
      ComFuc.hasLeftPoint = data.player.leftpoints
      if mainBtnPushDown == 1 then
        PersonalInfo.ShowLeftPointTips()
      end
    end
    game.isNoSpeak = data.player.isNoSpeak
    game.sysTimeNow = data.player.sysTimeNow or 0
    game.beginNoSpeakTime = data.player.beginNoSpeakTime or 0
    game.endNoSpeakTime = data.player.endNoSpeakTime or 0
    game.bannedReason = data.player.silencedReason or ""
    CommonUtility.ShowNoSpeak()
    buf_list_from_server = {}
    max_buf_end_time = 0
    local head_buf_index = 1
    for i = 1, MAX_BUF_CNT do
      if data.player.buffs and data.player.buffs[i] then
        if head_buf_index <= MAX_SHOW_BUF_CNT then
          ui["buf_" .. head_buf_index].Visible = true
        end
        buf_list_from_server[i] = {
          desc = data.player.buffs[i].description,
          skin = Gui.ControlSkin({
            BackgroundImage = Gui.Image("ui/skinF/" .. data.player.buffs[i].source .. ".tga", Vector4(0, 0, 0, 0))
          }),
          left_time = data.player.buffs[i].leftTime
        }
        if head_buf_index <= MAX_SHOW_BUF_CNT then
          ui["buf_" .. head_buf_index].Skin = buf_list_from_server[i].skin
        end
        max_buf_end_time = math.max(max_buf_end_time, buf_list_from_server[i].left_time)
      elseif head_buf_index < MAX_SHOW_BUF_CNT then
        ui["buf_" .. head_buf_index].Visible = false
      end
      if head_buf_index < MAX_SHOW_BUF_CNT then
        ui["buf_" .. head_buf_index].Hint = nil
      end
      head_buf_index = head_buf_index + 1
    end
    buf_list_from_server = _sort_buf_list(buf_list_from_server)
    if 0 < max_buf_end_time then
      if timer then
        TimerRemove()
      end
      TimerRefresh()
      timer = game.TimerMgr:AddTimer(1)
      timer.EventOnTimer = TimerRefresh
    else
      ui["buf_" .. 1].Visible = false
      ui["buf_" .. 2].Visible = false
      ui["buf_" .. 3].Visible = false
      ui["buf_" .. "list"].Visible = false
    end
    if not p then
      SetIsCheckin(data.player.isCheckin)
    end
    for i, v in ipairs(data.player.inviteList) do
      local state = ptr_cast(game.CurrentState)
      local msg = GetMatchedUTF8Text("msgbox_social_guild_UI_24," .. v.inviteName .. "," .. v.inviteGuildName)
      MessageBox.ShowWithTwoButtons(msg, GetUTF8Text("button_common_Accept"), GetUTF8Text("button_common_Decline"), function()
        state:JoinGuild(v.inviteId)
        SelectCharacter.isHaveGuild = "Y"
      end, function()
        state:RefuseGuild(v.inviteId)
      end)
    end
    for i, v in ipairs(data.player.inviteTeamMemberList) do
      local state = ptr_cast(game.CurrentState)
      state:DisagreeOneToGuildTeam(0, v.headerId)
    end
    local timeList = {
      60,
      120,
      180
    }
    if data.player.onlineEndTime then
      timeList = data.player.onlineEndTime
    end
    onlineTimeSection = CreateTimeSection(timeList)
    endTimeText = CreateTimeText(timeList)
    if isOnlineOpen then
      canGetPrize = false
      local onlineCount = #onlineTimeSection
      if onlineCount == 0 then
        onlineIndex = 0
      elseif data.player.timeOnline == 0 then
        onlineIndex = 1
      else
        for i = 1, onlineCount do
          if data.player.timeOnline > onlineTimeSection[i][1] and data.player.timeOnline < onlineTimeSection[i][2] then
            onlineIndex = i
          elseif data.player.timeOnline == onlineTimeSection[i][2] then
            if not data.player.isGetPrize then
              onlineIndex = i
              canGetPrize = true
            else
              onlineIndex = i + 1
            end
          end
        end
      end
      if not onlineIndex then
        print("Error!The time is not in time section.")
      elseif onlineIndex == 0 then
        ui.ctl_online_root.Visible = false
      else
        ui.ctl_online_root.Visible = true
        if onlineIndex == #onlineTimeSection + 1 then
          ShowGetGiftFinishControl()
        elseif not canGetPrize then
          originalTime = onlineTimeSection[onlineIndex][2] - data.player.timeOnline
          current_time = originalTime
          curMinute, curHour, curHour = TimeTranslate(current_time)
          ui.hour.Text = curHour >= 10 and curHour or "0" .. curHour
          ui.minute.Text = curMinute >= 10 and curMinute or "0" .. curMinute
          ui.second.Text = curSecond >= 10 and curSecond or "0" .. curSecond
          OnlineReward.SetTimeText(onlineIndex, ui.hour.Text, ui.minute.Text, ui.second.Text)
          ShowTimeNum()
          ui.tlbl_online.Timer = 1
          ui.tlbl_online:Start()
        else
          OnlineReward.initializelabelMember("label")
          ShowGetGiftControl()
        end
      end
    end
    if call_back then
      call_back()
    end
  end)
end

function AlignUI()
  Gui.Align(ui.lobby_root_p, 0.5, 0.5)
  Gui.Align(ui.lobby_root, 0.5, 0.5)
  if Sociality.Visible() then
    Sociality.AlignUI()
  end
  if ChatUnShow.Visible() then
    ChatUnShow.AlignUI()
  end
end

function ForceLeadGotoMission(metion)
  if bit.band(2, ComFuc.leadList) ~= 2 or bit.band(4, ComFuc.leadList) ~= 4 then
    return
  end
  metion = metion or GetUTF8Text("UI_common_Click")
  NewLead.ShowNewLeadHasLock(Vector2(521, 78), Vector2(72, 73), metion, 1)
end

function ForceLeadGotoPersonalInfo(metion)
  if bit.band(2, ComFuc.leadList) == 2 and bit.band(4, ComFuc.leadList) == 4 or bit.band(512, ComFuc.leadList) ~= 512 and bit.band(1024, ComFuc.leadList) == 1024 then
    metion = metion or GetUTF8Text("UI_common_Click")
    NewLead.ShowNewLeadHasLock(Vector2(371, 78), Vector2(72, 73), GetUTF8Text("UI_common_Click"), 1)
  end
end

function ForceLeadGotoShop()
  if bit.band(1024, ComFuc.leadList) ~= 1024 then
    return
  end
  NewLead.ShowNewLeadHasLock(Vector2(671, 78), Vector2(72, 73), GetUTF8Text("UI_common_Click"), 1)
end

function ForceLeadGotoStartGame()
  NewLead.ShowNewLeadNoLock(Vector2(1070, 25), Vector2(100, 100), GetUTF8Text("UI_common_Task_guide_11"), 3)
end

local ComShow, async_show = function(tn)
  lg:SetBG("/ui/skinF/" .. SelectCharacter.bgRes[SelectCharacter.role_job_id + 1] .. ".dds")
  NewLead.HideLead()
  if ComFuc.fromSelToLobby2 then
    mainBtnPushDown = 0
    OnComSwitch(1)
  end
  ui.btn_m_5.Visible = ComFuc.isOpenAuction
  AsyncCmdShow(tn)
end, function(tn)
  lg:SetBG("/ui/skinF/" .. SelectCharacter.bgRes[SelectCharacter.role_job_id + 1] .. ".dds")
  NewLead.HideLead()
  if ComFuc.fromSelToLobby2 then
    mainBtnPushDown = 0
    OnComSwitch(1)
  end
  ui.btn_m_5.Visible = ComFuc.isOpenAuction
  AsyncCmdShow(tn)
end

function async_show()
  local tn = 0
  ComFuc.TestHasAwardNoReceive()
  if ComFuc.fromAToL then
    ComFuc.fromAToL = false
    ComShow(tn)
  else
    rpc.safecall("sys_quest_list", {t = 1}, function(data)
      if data.quests then
        for i, v in ipairs(data.quests) do
          if tonumber(v.id) == 1001 and v.isAccepted == "N" then
            tn = 3
          end
        end
      end
      rpc.safecall("player_quest_list", {}, function(data)
        if data.quests then
          for i, v in ipairs(data.quests) do
            if tonumber(v.qid) == 1003 then
              accept_learn_skill = v.state
              break
            end
          end
          for i, v in ipairs(data.quests) do
            if tonumber(v.qid) == 1000 then
              if tonumber(v.state) == 1 and ComFuc.isCrossNew then
                ComFuc.isCrossNew = false
                tn = 1
                break
              end
              if tonumber(v.state) == 2 then
                tn = 2
              end
              break
            end
            if tonumber(v.qid) == 1001 and tonumber(v.state) == 1 and accept_learn_skill == false then
              tn = 6
              break
            end
            if tonumber(v.qid) == 1001 then
              if tonumber(v.state) == 1 then
                tn = 4
                break
              elseif tonumber(v.state) == 2 and accept_learn_skill == 1 then
                tn = 5
                break
              end
            end
          end
        end
        if bit.band(512, ComFuc.leadList) ~= 512 and bit.band(1024, ComFuc.leadList) == 1024 then
          tn = 7
        end
        for i, v in ipairs(data.quests) do
          if tonumber(v.qid) == 1000 and tonumber(v.state) == 1 and ComFuc.isCrossNew then
            ComFuc.isCrossNew = false
            tn = 1
          end
        end
        if tn ~= 1 then
          ComShow(tn)
        elseif tn == 1 then
          ComFuc.isFromNew = 1
          LobbyPlayGame.CreateNoviceRoom()
        end
      end)
    end)
  end
end

function Show()
  if not Visible then
    local accept_learn_skill = 0
    local state = ptr_cast(game.CurrentState)
    if state then
      state.EventServerCmd = PushCmd.OnServerCmd
    else
      MessageBox.ShowError("Error: No Lobby")
      return
    end
    rpc.clear()
    rpc_player_detail(nil, async_show)
  end
  if mainBtnPushDown == 2 then
    PersonalInfo.rpc_player_info()
    PersonalInfo.rpc_slot_get()
  end
end

function Hide()
  ui.partc3.Visible = false
  ComFuc.Is_StartGameParticle = false
  Visible = false
  ui.tlbl_online:Stop()
  if mainBtnPushDown ~= 2 then
    SwitchMainTab(0)
  end
  local state = ptr_cast(game.CurrentState)
  state.EventServerCmd = nil
  ui.lobby_root_p.Parent = nil
  ui.lobby_root.Parent = nil
  ui.down_light.Parent = nil
  ui.mail_f.Visible = false
  Sociality.Hide()
  Mail.Hide()
  ChatBar.Hide()
  TimerRemove()
  lg:SetWeapon(nil, nil)
  ui.partc4.Visible = false
  if Rank then
    Rank.Reset()
  end
  if PersonalInfo then
    PersonalInfo.ClearPetsData()
  end
  StopTimer()
end

Visible = false

function TimeTranslate(cur_time)
  local hour = 0
  local minute = 0
  local second = 0
  local h, m, s = 0
  hour = cur_time / 3600
  h = math.floor(hour)
  minute = cur_time / 60 - h * 60
  m = math.floor(minute)
  second = cur_time - (3600 * h + m * 60)
  s = math.floor(second)
  return s, m, h
end

function CreateTimeSection(timeList)
  local timeSection = {}
  for i = 1, #timeList do
    local sec = {}
    sec[1] = i == 1 and 0 or timeList[i - 1]
    sec[2] = timeList[i]
    timeSection[i] = sec
  end
  return timeSection
end

function CreateTimeText(timeList)
  local timeTextList = {}
  for i, v in ipairs(timeList) do
    local s, m, h = TimeTranslate(v)
    hText = 10 <= h and h or "0" .. h
    mText = 10 <= m and m or "0" .. m
    sText = 10 <= s and s or "0" .. s
    timeTextList[i] = hText .. ":" .. mText .. ":" .. sText
  end
  return timeTextList
end

function rpc_player_ol_prize()
  rpc.safecall("player_ol_prize", nil, DealGiftAward)
end

function ui.time_award.EventClick(sender, e)
  if not isOnlineOpen then
    MessageBox.ShowError(GetUTF8Text("Sorry,this mode is not open now."))
    return
  end
  if onlineIndex == #onlineTimeSection + 1 then
    OnlineReward.ShowFinishTimeAwardDialog()
  else
    rpc_player_ol_prize()
  end
end

function DealGiftAward(data)
  OnlineReward.ShowPrizeButState(data.currentPrizeLevel)
  OnlineReward.ShowUnTimeAwardDialog(data.prizeList)
end

function DealGetGiftSuccess(data)
  local icon_cancel = Gui.Icon("ui/skinF/skin_button_icon_cancel.tga", Vector4(0, 0, 0, 0))
  MessageBox.Show(GetUTF8Text("msgbox_social_receive_success"), GetUTF8Text("button_common_close_01"), nil, nil, nil, icon_cancel)
  onlineIndex = onlineIndex + 1
  canGetPrize = false
  if onlineIndex == #onlineTimeSection + 1 then
    ShowGetGiftFinishControl()
  else
    originalTime = onlineTimeSection[onlineIndex][2] - onlineTimeSection[onlineIndex][1]
    current_time = originalTime
    curMinute, curHour, curHour = TimeTranslate(current_time)
    ui.hour.Text = curHour >= 10 and curHour or "0" .. curHour
    ui.minute.Text = curMinute >= 10 and curMinute or "0" .. curMinute
    ui.second.Text = curSecond >= 10 and curSecond or "0" .. curSecond
    OnlineReward.SetTimeText(onlineIndex, ui.hour.Text, ui.minute.Text, ui.second.Text)
    ShowTimeNum()
    ui.tlbl_online.Timer = 1
    ui.tlbl_online:Start()
  end
end

function HideTimeNum()
  ui.ctl_time_ui.Visible = false
end

function ShowTimeNum()
  ui.ctl_time_ui.Visible = true
  HideGetGiftControl()
  HideGetGiftFinishControl()
end

function ShowGetGiftControl()
  if onlineIndex >= 4 then
    ShowGetGiftFinishControl()
    canGetPrize = false
    return
  end
  ui.getGift_bg.Visible = true
  ui.getGift.Visible = true
  ui.getGift.Shine = true
  HideTimeNum()
  HideGetGiftFinishControl()
end

function HideGetGiftControl()
  ui.getGift_bg.Visible = false
  ui.getGift.Visible = false
end

function ShowGetGiftFinishControl()
  ui.getGiftFinish.Visible = true
  HideTimeNum()
  HideGetGiftControl()
end

function HideGetGiftFinishControl()
  ui.getGiftFinish.Visible = false
end

curSecond = 0
curMinute = 0
curHour = 0
isOnlineOpen = true
onlineIndex = nil
canGetPrize = nil
originalTime = 0
current_time = 0
onlineTimeSection = {}
endTimeText = {}

function ui.tlbl_online.EventTimeUp(sender, e)
  local timeup
  if current_time and current_time <= 0 then
    ShowGetGiftControl()
    canGetPrize = true
    timeup = true
  else
    timeup = false
  end
  if not timeup then
    if 0 >= curSecond then
      if 0 >= curMinute then
        curHour = curHour - 1
        curMinute = 59
        curSecond = 59
      else
        curSecond = 59
        curMinute = curMinute - 1
      end
    else
      curSecond = curSecond - 1
    end
    ui.hour.Text = curHour >= 10 and curHour or "0" .. curHour
    ui.minute.Text = curMinute >= 10 and curMinute or "0" .. curMinute
    ui.second.Text = curSecond >= 10 and curSecond or "0" .. curSecond
    OnlineReward.SetTimeText(onlineIndex, ui.hour.Text, ui.minute.Text, ui.second.Text)
    current_time = current_time - 1
    sender.Timer = 1
    sender:Start()
  end
end

function ui.left_time.EventTimeUp(sender, e)
  local temp_time
  if ComFuc.globalLeftTime > 0 then
    ComFuc.globalLeftTime = ComFuc.globalLeftTime - 1
    if ComFuc.globalLeftTime < 0 then
      ComFuc.globalLeftTime = 0
    end
  end
  if 0 == ComFuc.globalLeftTime then
    temp_time = tostring(ComFuc.globalLeftTime) .. GetUTF8Text("tips_abilities_Sec")
    ui.left_time:Stop()
    ui.run_num.Visible = false
  else
    temp_time = Tip.GetLeftTime(ComFuc.globalLeftTime)
    ui.run_num.Visible = true
  end
  ui.run_num.Hint = GetMatchedUTF8Text("UI_lobby_deserter_punishment" .. "," .. temp_time)
  sender.Timer = 1
  sender:Start()
end
