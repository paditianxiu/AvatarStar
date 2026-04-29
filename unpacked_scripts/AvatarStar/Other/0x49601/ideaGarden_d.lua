module("GardenGameRoom", package.seeall)
require("../sys/mode_introduce.lua")
local colw = ComFuc.colw
local col0 = ComFuc.col0
local talk_referral
local Mode_Index = 0
local Talk_index = 1
local gameIndex = {}
local show_hero_info
local hero_card_info = Mode_Introduce.hero_card_info
local start_index = 0
local typeMap = {
  {
    0,
    4,
    1,
    2,
    3,
    11,
    8
  },
  {
    0,
    10,
    12,
    13
  }
}
local total_mode_count = math.max(#typeMap[1], #typeMap[2])
local backgroundSkin = {}
for i = 1, #typeMap do
  backgroundSkin[i] = {}
end
for i = 1, #SkinF.battle_034 do
  backgroundSkin[1][i] = SkinF.battle_034[i]
end
for i = 1, #SkinF.battle_032 do
  backgroundSkin[2][i] = SkinF.battle_032[i]
end
local mode_describe_key = {
  {
    "UI_lobby_moshijieshao_zhanchang_suiji",
    "UI_lobby_moshijieshao_zhanchang_tuanzhan",
    "UI_lobby_moshijieshao_zhanchang_zhandian",
    "UI_lobby_moshijieshao_zhanchang_duoqi",
    "UI_lobby_moshijieshao_zhanchang_duobao",
    "UI_lobby_moshijieshao_zhanchang_jianmie",
    "UI_mode_baopojieshao"
  },
  {
    "UI_lobby_moshijieshao_chuangxiangleyuan_suiji",
    "UI_lobby_moshijieshao_chuangxiangleyuan_shenghua",
    "UI_lobby_moshijieshao_chuangxiangleyuan_langren",
    "UI_lobby_moshijieshao_chuangxiangleyuan_jiushizhu"
  }
}
local test_skin = {
  change = Gui.ControlSkin({
    BackgroundImage = Gui.Image("/ui/skinF/skin_jiacheng_bianshenhou.tga", Vector4(0, 0, 0, 0))
  }),
  Gui.ControlSkin({
    BackgroundImage = Gui.Image("/ui/skinF/skin_jiacheng_wuqizhandouli.tga", Vector4(0, 0, 0, 0))
  }),
  Gui.ControlSkin({
    BackgroundImage = Gui.Image("/ui/skinF/skin_jiacheng_zhuanhuangongjili.tga", Vector4(0, 0, 0, 0))
  }),
  Gui.ControlSkin({
    BackgroundImage = Gui.Image("/ui/skinF/skin_jiacheng_jueseshuxing.tga", Vector4(0, 0, 0, 0))
  }),
  Gui.ControlSkin({
    BackgroundImage = Gui.Image("/ui/skinF/skin_jiacheng_zhuanhuanfangyuli.tga", Vector4(0, 0, 0, 0))
  })
}
local num_skin, HeroCard = {
  SkinF.info_number_4,
  SkinF.info_number_1
}, SkinF.info_number_4
local HeroCard, show_block = function(i)
  return Gui.Control("hero_" .. i)({
    BackgroundColor = colw,
    Size = Vector2(280, 340),
    Location = Vector2(35 + 300 * (i - 1), -5),
    Skin = SkinF.hero_card.jike,
    Gui.Control({
      Skin = SkinF.master_level_count,
      Location = Vector2(50, 300),
      Size = Vector2(200, 31),
      BackgroundColor = ComFuc.colw,
      ComFuc.ComLabel("hero_name_" .. i, "test", Vector2(140, 31), Vector2(20, 0), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComButton("show_info_" .. i, nil, Vector2(32, 32), Vector2(165, 0), 0, false, false, SkinF.lobbyMain_066)
    })
  })
end, SkinF.info_number_1
local show_block, effect_ui = function(i, x, y)
  return Gui.Control({
    BackgroundColor = colw,
    Size = Vector2(250, 110),
    Location = Vector2(x, y),
    Skin = SkinF.mode_effect_ui[1],
    ComFuc.ComControl(nil, Vector2(170, 30), Vector2(40, 5), 255, test_skin[i]),
    ComFuc.ComLabel("effect_num_" .. i, 1024, Vector2(192, 30), Vector2(25, 55), 0, 0, colw, "kAlignCenterMiddle", nil, true, num_skin[i % 2 + 1])
  })
end, Gui.ControlSkin({
  BackgroundImage = Gui.Image("/ui/skinF/skin_jiacheng_zhuanhuanfangyuli.tga", Vector4(0, 0, 0, 0))
})
local effect_ui, ModeButtonLocation = function(i, x, y)
  return Gui.Control("effect_ui_" .. i)({
    BackgroundColor = col0,
    Size = Vector2(613, 110),
    Location = Vector2(x, y),
    ComFuc.ComControl(nil, Vector2(125, 60), Vector2(245, 24), 255, SkinF.mode_effect_ui[2]),
    ComFuc.ComControl(nil, Vector2(151, 29), Vector2(230, 40), 255, SkinF.mode_effect_ui[3]),
    show_block(2 * (i - 1) + 1, 0, 0),
    show_block(2 * (i - 1) + 2, 363, 0),
    ComFuc.ComControl(nil, Vector2(23, 91), Vector2(236, 12), 255, SkinF.mode_effect_ui[4]),
    ComFuc.ComControl(nil, Vector2(23, 91), Vector2(353, 12), 255, SkinF.mode_effect_ui[4]),
    ComFuc.ComControl(nil, Vector2(170, 30), Vector2(218, 38), 255, test_skin.change)
  })
end, Gui.ControlSkin({
  BackgroundImage = Gui.Image("/ui/skinF/skin_jiacheng_zhuanhuanfangyuli.tga", Vector4(0, 0, 0, 0))
})

function ModeButtonLocation(i)
  return Vector2(1, 1 + 45 * (i - 1))
end

local wys_test, ModeButton = {
  Gui.ControlSkin({
    BackgroundImage = Gui.Image("ui/skinF/skin_wenzi_zhandian.tga", Vector4(0, 0, 0, 0))
  })
}, Gui.ControlSkin({
  BackgroundImage = Gui.Image("ui/skinF/skin_wenzi_zhandian.tga", Vector4(0, 0, 0, 0))
})
local ModeButton, ModeInfo = function(i)
  return Gui.Button("mode_" .. i)({
    Size = Vector2(100, 45),
    Location = ModeButtonLocation(i),
    CanPushDown = true,
    CanMove = true,
    ComFuc.ComControl(nil, Vector2(37, 37), Vector2(2, 5), 255, SkinF.mode_select_ui.background),
    ComFuc.ComControl("mode_ui_" .. i, Vector2(37, 37), Vector2(2, 5), 255, nil),
    ComFuc.ComControl("mode_describe_" .. i, Vector2(40, 20), Vector2(40, 15), 255, nil)
  })
end, Gui.ControlSkin({
  BackgroundImage = Gui.Image("ui/skinF/skin_wenzi_zhandian.tga", Vector4(0, 0, 0, 0))
})
local ModeInfo, SelectMode = function()
  return Gui.Control({
    Location = Vector2(107, 45),
    Size = Vector2(580, 395),
    BackgroundColor = colw,
    Skin = Gui.ControlSkin({
      BackgroundImage = Gui.Image("ui/skinF/skin_hecheng_BG07.tga", Vector4(20, 20, 20, 20))
    }),
    ComFuc.ComControl("mode_background", Vector2(570, 318), Vector2(5, 2), 255, SkinF.battle_032),
    ComFuc.ComLabel("mode_describe", nil, Vector2(570, 73), Vector2(5, 319), 0, 16, colw, "kAlignLeftTop"),
    Gui.Control("special_button")({
      Location = Vector2(5, 275),
      Size = Vector2(580, 45),
      ComFuc.ComButton("mode_effect", GetUTF8Text("UI_common_shuxingjiacheng_leyuan"), Vector2(132, 45), Vector2(172, 0), 16, false, false, SkinF.Button_SceneReferral),
      ComFuc.ComButton("introduce_hero", GetUTF8Text("UI_common_yingxiongjieshao"), Vector2(132, 45), Vector2(308, 0), 16, false, false, SkinF.Button_SceneReferral),
      ComFuc.ComButton("scene_referral_btl", GetUTF8Text("button_mode_story_type"), Vector2(132, 45), Vector2(442, 0), 16, false, false, SkinF.Button_SceneReferral)
    })
  })
end, Gui.ControlSkin({
  BackgroundImage = Gui.Image("ui/skinF/skin_wenzi_zhandian.tga", Vector4(0, 0, 0, 0))
})
local SelectMode, MatchType = function()
  return Gui.Control({
    Location = Vector2(5, 45),
    Size = Vector2(100, 385),
    ModeButton(1),
    ModeButton(2),
    ModeButton(3),
    ModeButton(4),
    ModeButton(5),
    ModeButton(6),
    ModeButton(7)
  })
end, Gui.ControlSkin({
  BackgroundImage = Gui.Image("ui/skinF/skin_wenzi_zhandian.tga", Vector4(0, 0, 0, 0))
})

function MatchType()
  return Gui.Control("theme_type_select")({
    Location = Vector2(5, 5),
    Size = Vector2(680, 40),
    ComFuc.MainTabBtn("match_type_1", GetUTF8Text("button_common_Arena"), Vector2(31, 7), Vector2(129, 31), SkinF.level_master_btn, true),
    ComFuc.MainTabBtn("match_type_2", GetUTF8Text("UI_abilities_AvatarParadise"), Vector2(160, 7), Vector2(129, 31), SkinF.level_master_btn, true)
  })
end

ui = Gui.Create()({
  Gui.Control("root")({
    Location = Vector2(9, 45),
    Size = Vector2(696, 446),
    BackgroundColor = colw,
    Skin = SkinF.battle_018,
    MatchType(),
    ComFuc.ComControl(nil, Vector2(690, 400), Vector2(2, 43), 255, SkinF.openBox_002),
    ModeInfo(),
    SelectMode(),
    ComFuc.ComControl("mode_shelter", Vector2(695, 340), Vector2(2, 103), 255, SkinF.battle_027),
    ComFuc.ComControl("mode_referral", Vector2(629, 110), Vector2(34, 335), 255, SkinF.battle_028),
    ComFuc.ComControl("mode_arrows", Vector2(84, 36), Vector2(306, 314), 255, SkinF.battle_029[1]),
    Gui.Label("mode_content")({
      Location = Vector2(76, 354),
      Size = Vector2(539, 70),
      TextAlign = "kAlignLeftTop",
      AutoWrap = true,
      FontSize = 15,
      TextColor = ARGB(255, 62, 26, 1),
      Text = GetUTF8Text("UI_lobby_explore_introduction")
    }),
    ComFuc.ComControl("mode_portrait_left", Vector2(350, 350), Vector2(-22, 87), 255),
    ComFuc.ComControl("mode_portrait_right", Vector2(350, 350), Vector2(385, 87), 255),
    ComFuc.ComButton("btn_close", nil, Vector2(21, 21), Vector2(635, 341), 16, false, false, SkinF.personalInfo_263),
    Gui.TextButton("btn_Next")({
      BackgroundColor = col0,
      TextColor = ARGB(255, 0, 0, 0),
      HoverTextColor = ARGB(255, 134, 25, 190),
      Text = GetUTF8Text("button_common_next_page"),
      Location = Vector2(580, 420),
      Size = Vector2(50, 30),
      FontSize = 15
    }),
    Gui.Control("introduce_hero_ui")({
      BackgroundColor = colw,
      Size = Vector2(695, 340),
      Location = Vector2(2, 103),
      Visible = false,
      Skin = SkinF.battle_027,
      HeroCard(1),
      HeroCard(2),
      ComFuc.ComButton("turn_left", nil, Vector2(35, 66), Vector2(10, 137), 16, false, false, SkinF.select_butten[1].left),
      ComFuc.ComButton("turn_right", nil, Vector2(35, 66), Vector2(650, 137), 16, false, false, SkinF.select_butten[1].right),
      ComFuc.ComButton("btn_close_hero_ui", nil, Vector2(21, 21), Vector2(670, 1), 16, false, false, SkinF.personalInfo_263)
    }),
    Gui.Control("mode_effect_ui")({
      BackgroundColor = colw,
      Size = Vector2(695, 340),
      Location = Vector2(2, 103),
      Visible = false,
      Skin = SkinF.battle_027,
      ComFuc.ComButton("btn_close_mode_effect", nil, Vector2(21, 21), Vector2(665, 6), 16, false, false, SkinF.personalInfo_263),
      effect_ui(1, 40, 40),
      effect_ui(2, 40, 197)
    })
  })
})

function Set(type, x, y, a)
  if 1 == type then
    ui[a].Location = Vector2(x, y)
  elseif 2 == type then
    ui[a].Size = Vector2(x, y)
  end
end

function SelectThemeType(type)
  for i = 1, #typeMap do
    ui["match_type_" .. i].PushDown = i == type
  end
  LobbyBattleGame.themeType = type
  ui.special_button.Visible = type == 2
end

for i = 1, 2 do
  ui["match_type_" .. i].EventClick = function(sender, e)
    SelectThemeType(i)
    LobbyBattleGame.SelModeClick(1)
  end
end
for i = 1, 4 do
  if i % 2 == 0 then
    ui["effect_num_" .. i].Size = Vector2(192, 41)
    ui["effect_num_" .. i].Location = Vector2(27, 48)
  end
end

function SetTalkVisible(vis)
  Talk_index = 1
  if Mode_Index ~= 1 then
    ui.scene_referral_btl.Visible = true
    talk_referral = Mode_Introduce.contents[Mode_Index - 1]
  else
    ui.scene_referral_btl.Visible = false
  end
  ui.mode_shelter.Visible = vis
  ui.btn_Next.Visible = vis
  ui.btn_close.Visible = vis
  ui.mode_content.Visible = vis
  ui.mode_referral.Visible = vis
  ui.mode_arrows.Visible = vis
  ui.mode_portrait_left.Visible = vis
  ui.mode_portrait_right.Visible = vis
  ui.scene_referral_btl.Padding = Vector4(0, 0, 0, 8)
end

function SetHeroVisible(vis)
  ui.introduce_hero_ui.Visible = vis
  ui.introduce_hero.Padding = Vector4(0, 0, 0, 8)
end

function SetModeEffectVisible(vis)
  ui.mode_effect_ui.Visible = vis
  ui.mode_effect.Padding = Vector4(0, 0, 0, 8)
end

function SetTalkContent(data)
  ui.mode_arrows.Skin = SkinF.battle_029[data[1]]
  if data[1] == 1 then
    ui.mode_portrait_left.Skin = SkinF.battle_030[data[2]]
    ui.mode_portrait_left.Visible = true
    ui.mode_portrait_right.Visible = false
    ui.mode_portrait_left.Location = Vector2(data.x or -22, 87)
  else
    ui.mode_portrait_right.Skin = SkinF.battle_030[data[2]]
    ui.mode_portrait_right.Visible = true
    ui.mode_portrait_left.Visible = false
    ui.mode_portrait_right.Location = Vector2(data.x or 385, 87)
  end
  ui.mode_content.Text = GetUTF8Text(data[3])
end

function IsShowGardenMode()
  local k = 0
  for i = 1, total_mode_count do
    gameIndex[i] = 0
    ui["mode_" .. i].Visible = false
  end
  if not typeMap[LobbyBattleGame.themeType] then
    return
  end
  for i = 1, #typeMap[LobbyBattleGame.themeType] do
    if CreateRoom and CreateRoom.CheckGameType(typeMap[LobbyBattleGame.themeType][i]) or i == 1 then
      k = k + 1
      gameIndex[i] = k
      ui["mode_" .. i].Visible = true
      ui["mode_" .. i].Enable = not ComFuc.isShowGameTime
      ui["mode_" .. i].Location = ModeButtonLocation(k)
      ui["mode_ui_" .. i].Skin = SkinF.mode_select_ui[LobbyBattleGame.themeType] and SkinF.mode_select_ui[LobbyBattleGame.themeType][i]
      ui["mode_describe_" .. i].Skin = SkinF.mode_describe[LobbyBattleGame.themeType] and SkinF.mode_describe[LobbyBattleGame.themeType][i]
      if ui["mode_describe_" .. i].Skin then
        ui["mode_describe_" .. i].Size = ui["mode_describe_" .. i].Skin.BackgroundImage.Size
      end
    end
  end
end

function SetGardenModeState(type)
  Mode_Index = type
  for i = 1, total_mode_count do
    ui["mode_" .. i].PushDown = i == type
  end
  SetHeroVisible(false)
  SetTalkVisible(false)
  SetModeEffectVisible(false)
  if 1 < type then
    if not Mode_Introduce.contents[type - 1] or #Mode_Introduce.contents[type - 1] == 0 then
      ui.scene_referral_btl.Enable = false
    else
      ui.scene_referral_btl.Enable = true
      ui.scene_referral_btl.Visible = true
      talk_referral = Mode_Introduce.contents[type - 1]
    end
    if not hero_card_info[type - 1] or #hero_card_info[type - 1] == 0 then
      ui.introduce_hero.Enable = false
    else
      ui.introduce_hero.Enable = true
    end
    ui.introduce_hero.Visible = true
    ui.mode_effect.Visible = true
  else
    ui.scene_referral_btl.Visible = false
    ui.introduce_hero.Visible = false
    ui.mode_effect.Visible = false
  end
  ui.mode_background.Skin = backgroundSkin[LobbyBattleGame.themeType] and backgroundSkin[LobbyBattleGame.themeType][type]
  ui.mode_describe.Text = mode_describe_key[LobbyBattleGame.themeType] and GetUTF8Text(mode_describe_key[LobbyBattleGame.themeType][type])
  ui.theme_type_select.Visible = LobbyBattleGame.IsNeedShowAllMode()
  if LobbyBattleGame.IsNeedShowAllMode() then
    LobbyBattleGame.ShowGameType()
  else
    for i = 1, total_mode_count do
      ui["mode_" .. i].Visible = i == type
      if i == type then
        ui["mode_" .. i].Enable = false
        ui["mode_" .. i].Location = ModeButtonLocation(1)
      end
    end
  end
end

function SetGardenModeEnable(enable, shouallmode)
  for i = 1, total_mode_count do
    ui["mode_" .. i].Enable = enable and shouallmode
  end
  for i = 1, #typeMap do
    ui["match_type_" .. i].Enable = enable and shouallmode
  end
end

for i = 1, total_mode_count do
  ui["mode_" .. i].EventClick = function(sender, e)
    LobbyBattleGame.SelModeClick(i)
  end
end

function ui.scene_referral_btl.EventClick(sender, e)
  if ui.mode_referral.Visible then
    SetTalkVisible(false)
  else
    SetTalkVisible(true)
    SetTalkContent(talk_referral[Talk_index])
  end
end

function ui.btn_close.EventClick(sender, e)
  if ui.mode_shelter.Visible then
    ui.mode_shelter.Visible = false
    SetTalkVisible(false)
    ui.btn_Next.Text = GetUTF8Text("button_common_next_page")
  end
end

function ui.btn_Next.EventClick(sender, e)
  if ui.btn_Next.Text == GetUTF8Text("button_common_next_page") then
    Talk_index = Talk_index + 1
    SetTalkContent(talk_referral[Talk_index])
    if Talk_index >= #talk_referral then
      ui.btn_Next.Text = GetUTF8Text("button_common_close_01")
    end
  elseif ui.btn_Next.Text == GetUTF8Text("button_common_close_01") then
    SetTalkVisible(false)
    ui.btn_Next.Text = GetUTF8Text("button_common_next_page")
  end
end

function Show(parent)
  SetTalkVisible(false)
  ui.root.Parent = parent
end

function Hide()
  ui.root.Parent = nil
end

local draw_hero, show_hero = function(i)
  ui["hero_" .. i].Visible = false
  if not hero_card_info[Mode_Index - 1] or not hero_card_info[Mode_Index - 1][start_index + i] then
    return
  end
  ui["hero_" .. i].Visible = true
  ui["hero_" .. i].Skin = SkinF.hero_card[hero_card_info[Mode_Index - 1][start_index + i].resource]
  ui["hero_name_" .. i].Text = GetUTF8Text(hero_card_info[Mode_Index - 1][start_index + i].name)
end, function(i)
  ui["hero_" .. i].Visible = false
  if not hero_card_info[Mode_Index - 1] or not hero_card_info[Mode_Index - 1][start_index + i] then
    return
  end
  ui["hero_" .. i].Visible = true
  ui["hero_" .. i].Skin = SkinF.hero_card[hero_card_info[Mode_Index - 1][start_index + i].resource]
  ui["hero_name_" .. i].Text = GetUTF8Text(hero_card_info[Mode_Index - 1][start_index + i].name)
end
local show_hero, GetInfo = function()
  SetTalkVisible(false)
  if ui.introduce_hero_ui.Visible or not show_hero_info then
    SetHeroVisible(false)
    return
  else
    SetHeroVisible(true)
  end
  for i = 1, 2 do
    draw_hero(i)
  end
  if start_index == 0 then
    ui.turn_left.Enable = false
  else
    ui.turn_left.Enable = true
  end
  if start_index + 2 >= #hero_card_info[Mode_Index - 1] then
    ui.turn_right.Enable = false
  else
    ui.turn_right.Enable = true
  end
end, function(sender, e)
  if ui.btn_Next.Text == GetUTF8Text("button_common_next_page") then
    Talk_index = Talk_index + 1
    SetTalkContent(talk_referral[Talk_index])
    if Talk_index >= #talk_referral then
      ui.btn_Next.Text = GetUTF8Text("button_common_close_01")
    end
  elseif ui.btn_Next.Text == GetUTF8Text("button_common_close_01") then
    SetTalkVisible(false)
    ui.btn_Next.Text = GetUTF8Text("button_common_next_page")
  end
end

function GetInfo(data)
  show_hero_info = data.avatarList
  for i = 1, #hero_card_info do
    for j = 1, #hero_card_info[i] do
      for k, v in ipairs(show_hero_info) do
        if v.avatarId == hero_card_info[i][j].avatarId then
          hero_card_info[i][j].name = v.name
          hero_card_info[i][j].subtype = v.subType
        end
      end
    end
  end
  show_hero()
end

function ui.introduce_hero.EventClick(sender, e)
  start_index = 0
  if show_hero_info == nil then
    gui:PlayAudio("prompt")
    rpc.safecall("hero_introduction", nil, GetInfo)
  else
    show_hero()
  end
end

function ui.btn_close_hero_ui.EventClick(sender, e)
  if ui.introduce_hero_ui.Visible then
    SetHeroVisible(false)
  end
end

for i = 1, 2 do
  ui["show_info_" .. i].EventClick = function(sender, e)
    if not LookCardInfo then
      require("lookCardInfo.lua")
    end
    LookCardInfo.Show(hero_card_info[Mode_Index - 1][start_index + i])
  end
  
  local function deal_with_num(sender, e)
    LobbyBattleGame.SelModeClick(i)
  end
end
local WeaponEffect = function(value)
  local temp
  value = math.floor(value * 10000)
  temp = value % 100
  value = value / 100
  if temp == 0 then
    value = "+" .. value .. ".00%"
  elseif temp % 10 == 0 then
    value = "+" .. value .. "0%"
  else
    value = "+" .. value .. "%"
  end
  return value
end

function PlayerInfoEffect()
  ui.effect_num_3.Text = ComFuc.info_table.stamina + ComFuc.info_table.cure + ComFuc.info_table.recovery + ComFuc.info_table.armor + ComFuc.info_table.arp
  local value = 0.8 * (ComFuc.info_table.stamina + ComFuc.info_table.armor) + 0.2 * (ComFuc.info_table.cure + ComFuc.info_table.recovery + ComFuc.info_table.arp)
  value = value * 0.00157
  ui.effect_num_4.Text = deal_with_num(value)
end

function deal_with_num(sender, e)
  if ui.mode_effect_ui.Visible then
    SetModeEffectVisible(false)
    return
  else
    SetModeEffectVisible(true)
  end
  WeaponEffect()
  PlayerInfoEffect()
end

ui.mode_effect.EventClick = deal_with_num

function deal_with_num(sender, e)
  if ui.mode_effect_ui.Visible then
    SetModeEffectVisible(false)
  end
end

ui.btn_close_mode_effect.EventClick = deal_with_num
