module("Setting", package.seeall)
local _T = GetUTF8Text
local brown = ARGB(255, 113, 83, 65)
local gray = ARGB(85, 85, 85, 85)
local white = ARGB(255, 255, 255, 255)
local black = ARGB(255, 0, 0, 0)
local blue = ARGB(255, 82, 54, 44)
local red = ARGB(255, 255, 0, 0)
local sel = "graphic"
local brightness_init_value
local s = {
  graphic = {
    title = _T("UI_common_Video_Setting"),
    ui = {}
  },
  audio = {
    title = _T("tips_common_additional_tips18"),
    ui = {}
  },
  action = {
    title = _T("button_common_Hotkey"),
    ui = {}
  },
  interface = {
    title = _T("button_common_Screen_Setting"),
    ui = {}
  },
  switch = {
    title = _T("UI_common_Switch_Screen"),
    ui = {}
  },
  ingame_display = {
    title = _T("button_common_Setting"),
    ui = {}
  }
}
local ctrl_setting = Gui.Control({
  Dock = "kDockFill",
  BackgroundColor = white,
  Skin = SkinF.personalInfo_207
})()
local lb_title = Gui.Label({
  Size = Vector2(0, 30),
  Dock = "kDockTop",
  FontSize = 16,
  TextPadding = Vector4(10, 0, 0, 0),
  Gui.Button({
    Size = Vector2(24, 24),
    Margin = Vector4(0, 3, 8, 4),
    Dock = "kDockRight",
    Skin = SkinF.lookInfo_002,
    EventClick = function(sender, e)
      Hide()
    end
  })
})()
local ctrl_main, Ctrl = Gui.Control({
  Location = Vector2(7, 47),
  Size = Vector2(410, 642)
})(), {
  Location = Vector2(7, 47),
  Size = Vector2(410, 642)
}
local Ctrl, ComboBox = function(y, t, h, ui)
  local c = Gui.Control({
    Location = Vector2(9, y),
    Size = Vector2(398, h),
    BackgroundColor = ARGB(255, 255, 255, 255),
    Skin = SkinF.setting_03
  })(nil, ui)
  Gui.Label({
    Location = Vector2(9, 9),
    Size = Vector2(299, 19),
    FontSize = 16,
    Text = t,
    TextColor = blue
  })(c, nil)
end, Vector2(410, 642)
local ComboBox, CheckBox = function(x, y, t, p)
  Gui.Label({
    Location = Vector2(x, y),
    Size = Vector2(199, 19),
    FontSize = 16,
    TextColor = blue,
    Text = t
  })(p, nil)
  return Gui.ComboBox({
    Location = Vector2(x, y + 24),
    Size = Vector2(189, 29)
  })(p, nil)
end, 410
local CheckBox, Slider = function(x, y, w, t, p)
  return Gui.CheckBox({
    Location = Vector2(x, y),
    Size = Vector2(w, 24),
    FontSize = 16,
    TextColor = blue,
    Text = t
  })(p, nil)
end, 642

function Slider(x, y, t, p, is_int, l, r)
  Gui.Label({
    Location = Vector2(x, y),
    Size = Vector2(153, 22),
    TextAlign = "kAlignCenterMiddle",
    FontSize = 16,
    TextColor = blue,
    Text = t
  })(p, nil)
  Gui.Label({
    Location = Vector2(x, y + 54),
    Size = Vector2(153, 19),
    TextAlign = "kAlignLeftMiddle",
    FontSize = 16,
    TextColor = blue,
    Text = _T("tips_common_additional_tips19")
  })(p, nil)
  Gui.Label({
    Location = Vector2(x + 80, y + 54),
    Size = Vector2(73, 19),
    TextAlign = "kAlignRightMiddle",
    FontSize = 16,
    TextColor = blue,
    Text = _T("tips_common_additional_tips20")
  })(p, nil)
  return Gui.Slider({
    Location = Vector2(x, y + 26),
    ThumbSize = Vector2(28, 30),
    Size = Vector2(153, 30),
    IsInt = is_int,
    MinValue = l,
    MaxValue = r
  })(p, nil)
end

local brightchange, BrightSlider = function(sender, e)
  config.brightness = sender.CurValue - 0.5
end, function(sender, e)
  config.brightness = sender.CurValue - 0.5
end
local BrightSlider, MouseSlider = function(x, y, t, p, is_int, l, r, c)
  Gui.Label({
    Location = Vector2(x, y),
    Size = Vector2(153, 22),
    TextAlign = "kAlignCenterMiddle",
    FontSize = 16,
    TextColor = blue,
    Text = t
  })(p, nil)
  Gui.Label({
    Location = Vector2(x, y + 54),
    Size = Vector2(153, 19),
    TextAlign = "kAlignLeftMiddle",
    FontSize = 16,
    TextColor = blue,
    Text = _T("UI_common_low")
  })(p, nil)
  Gui.Label({
    Location = Vector2(x + 80, y + 54),
    Size = Vector2(73, 19),
    TextAlign = "kAlignRightMiddle",
    FontSize = 16,
    TextColor = blue,
    Text = _T("UI_common_high")
  })(p, nil)
  return Gui.Slider({
    Location = Vector2(x, y + 26),
    ThumbSize = Vector2(28, 30),
    Size = Vector2(153, 30),
    MinValue = l,
    MaxValue = r,
    EventValueChange = brightchange
  })(p, nil)
end, Gui.Button({
  Size = Vector2(24, 24),
  Margin = Vector4(0, 3, 8, 4),
  Dock = "kDockRight",
  Skin = SkinF.lookInfo_002,
  EventClick = function(sender, e)
    Hide()
  end
})

function MouseSlider(x, y, t, p, is_int, l, r)
  Gui.Label({
    Location = Vector2(x, y),
    Size = Vector2(153, 22),
    TextAlign = "kAlignCenterMiddle",
    FontSize = 16,
    TextColor = blue,
    Text = t
  })(p, nil)
  local txb = Gui.Textbox({
    Location = Vector2(x + 39, y + 25),
    Size = Vector2(72, 23),
    Number = true,
    MaxLength = 3
  })(p, nil)
  Gui.Label({
    Location = Vector2(x, y + 81),
    Size = Vector2(153, 19),
    TextAlign = "kAlignLeftMiddle",
    FontSize = 16,
    TextColor = blue,
    Text = 1
  })(p, nil)
  Gui.Label({
    Location = Vector2(x + 80, y + 81),
    Size = Vector2(73, 19),
    TextAlign = "kAlignRightMiddle",
    FontSize = 16,
    TextColor = blue,
    Text = 100
  })(p, nil)
  local sld, SetSldValue = Gui.Slider({
    Location = Vector2(x, y + 53),
    ThumbSize = Vector2(28, 30),
    Size = Vector2(153, 30),
    IsInt = true,
    MinValue = 1,
    MaxValue = 100
  })(p, nil), p
  
  function SetSldValue()
    local value = tonumber(txb.Text)
    if value then
      if 100 < value then
        value = 100
      end
      if value < 1 then
        value = 1
      end
      sld.CurValue = value
    end
  end
  
  function txb.EventValueEnter(sender, e)
    SetSldValue()
  end
  
  function txb.EventActiveChanged(sender, e)
    if not sender.Active then
      SetSldValue()
    end
  end
  
  function sld.EventValueChange(sender, e)
    txb.Text = sender.CurValue
  end
  
  return sld
end

local default_graphic_setting = {
  resolution = "1024x768",
  refresh_rate = 60,
  full_screen = false,
  shadow_quality = 2,
  model_quality = 2,
  shader_quality = 2,
  hdr_quality = 0,
  filter_index = 0,
  msaa_index = 0,
  v_sync = false,
  soft_particle = false
}
Ctrl(3, _T("UI_lobby_Display"), 169, s.graphic.ui)
Ctrl(178, _T("UI_lobby_Visual"), 231, s.graphic.ui)
Ctrl(412, _T("tips_common_additional_tips21"), 171, s.graphic.ui)
isquanityselect = false
local cmb_resolution = ComboBox(9, 41, _T("UI_lobby_Resolution"), s.graphic.ui[1])
local cmb_refresh = ComboBox(9, 102, _T("UI_lobby_Refresh_Rate"), s.graphic.ui[1])
local ckb_full_screen = CheckBox(236, 65, 186, _T("UI_lobby_Window_Mode"), s.graphic.ui[1])
local sld_bright = BrightSlider(228, 93, _T("UI_common_brightness"), s.graphic.ui[1], true, 0, 1)
local sld_shadow = Slider(36, 84, _T("UI_lobby_Shadow"), s.graphic.ui[2], true, 0, 2)
local sld_model = Slider(225, 84, _T("UI_common_Model_Quality"), s.graphic.ui[2], true, 0, 2)
local sld_shader = Slider(36, 149, _T("UI_lobby_Shader"), s.graphic.ui[2], true, 0, 2)
local sld_hdr = Slider(225, 149, _T("UI_lobby_HDR"), s.graphic.ui[2], true, 0, 2)

function disablequanitycheckforcheckbox(sender, e)
  if isquanityselect == false and sender.CurValue ~= quanityslider.CurValue - 1 and isquanityselect == false then
    quanityslider.CurValue = 0
  end
end

sld_shadow.EventValueChange = disablequanitycheckforcheckbox
sld_model.EventValueChange = disablequanitycheckforcheckbox
sld_shader.EventValueChange = disablequanitycheckforcheckbox
sld_hdr.EventValueChange = disablequanitycheckforcheckbox
local cmb_filter = ComboBox(9, 46, _T("UI_lobby_Texture"), s.graphic.ui[3])
local cmb_msaa = ComboBox(9, 108, _T("UI_lobby_AntiAliasing"), s.graphic.ui[3])
local ckb_sync = CheckBox(236, 79, 190, _T("UI_lobby_Verticle_Sync"), s.graphic.ui[3])
local ckb_soft_particle = CheckBox(236, 140, 190, _T("UI_lobby_Soft_Particle"), s.graphic.ui[3])

function disablequanitycheckforcombobox(sender, e)
  if isquanityselect == false then
    if quanityslider.CurValue ~= 3 and sender.SelectedIndex ~= quanityslider.CurValue - 1 then
      quanityslider.CurValue = 0
    elseif quanityslider.CurValue == 3 and sender.SelectedIndex ~= quanityslider.CurValue then
      quanityslider.CurValue = 0
    end
  end
end

cmb_filter.EventValueChanged = disablequanitycheckforcombobox
cmb_msaa.EventValueChanged = disablequanitycheckforcombobox

function quanityselect(sender, e)
  if sender.CurValue == 0 then
    return
  end
  isquanityselect = true
  sld_shadow.CurValue = sender.CurValue - 1
  sld_model.CurValue = sender.CurValue - 1
  sld_shader.CurValue = sender.CurValue - 1
  sld_hdr.CurValue = sender.CurValue - 1
  if sender.CurValue ~= 3 then
    cmb_filter.SelectedIndex = sender.CurValue - 1
    cmb_msaa.SelectedIndex = sender.CurValue - 1
  else
    cmb_filter.SelectedIndex = sender.CurValue
    cmb_msaa.SelectedIndex = sender.CurValue
  end
end

local quanityselectend, QuanitySlider = function(sender, e)
  isquanityselect = false
end, function(sender, e)
  isquanityselect = false
end

function QuanitySlider(x, y, t, p, is_int, l, r)
  Gui.Label({
    Location = Vector2(x, y),
    Size = Vector2(283, 22),
    TextAlign = "kAlignCenterMiddle",
    FontSize = 16,
    TextColor = blue,
    Text = t
  })(p, nil)
  Gui.Label({
    Location = Vector2(x, y + 54),
    Size = Vector2(153, 19),
    TextAlign = "kAlignLeftMiddle",
    FontSize = 16,
    TextColor = blue,
    Text = _T("UI_common_custom_config")
  })(p, nil)
  Gui.Label({
    Location = Vector2(x + 90, y + 54),
    Size = Vector2(153, 19),
    TextAlign = "kAlignLeftMiddle",
    FontSize = 16,
    TextColor = blue,
    Text = _T("UI_common_low_config")
  })(p, nil)
  Gui.Label({
    Location = Vector2(x + 175, y + 54),
    Size = Vector2(153, 19),
    TextAlign = "kAlignLeftMiddle",
    FontSize = 16,
    TextColor = blue,
    Text = _T("UI_common_mid_config")
  })(p, nil)
  Gui.Label({
    Location = Vector2(x + 205, y + 54),
    Size = Vector2(73, 19),
    TextAlign = "kAlignRightMiddle",
    FontSize = 16,
    TextColor = blue,
    Text = _T("UI_common_high_config")
  })(p, nil)
  return Gui.Slider({
    Location = Vector2(x, y + 26),
    ThumbSize = Vector2(28, 30),
    Size = Vector2(283, 30),
    IsInt = is_int,
    MinValue = l,
    MaxValue = r,
    EventValueChange = quanityselect,
    EventValueChangedEnd = quanityselectend
  })(p, nil)
end

local quanityslider, AddResolution = QuanitySlider(56, 10, _T("UI_common_shortcut_config"), s.graphic.ui[2], true, 0, 3), QuanitySlider(56, 10, _T("UI_common_shortcut_config"), s.graphic.ui[2], true, 0, 3)
local AddResolution, AddRefreshRate = function()
  cmb_resolution:RemoveAll()
  local count = config:GetDisplayModeCount()
  for i = 0, count - 1 do
    local resolution = config:FillDisplayMode(i)
    local res = resolution.x .. "x" .. resolution.y
    if 0 > cmb_resolution:TextToIndex(res) then
      cmb_resolution:AddItem(res)
    end
  end
end, 56
local AddRefreshRate, AddMSAA = function()
  cmb_refresh:RemoveAll()
  local count = config:GetDisplayModeCount()
  for i = 0, count do
    local refresh_rate = config:FillRefreshRate(i)
    if 0 < refresh_rate and 0 > cmb_refresh:TextToIndex(refresh_rate) then
      cmb_refresh:AddItem(refresh_rate)
    end
  end
end, 10
local AddMSAA, AddTextureFilter = function()
  cmb_msaa:RemoveAll()
  cmb_msaa:AddItem(_T("tips_abilities_None"))
  for i = 2, 16, 2 do
    if config:CheckMultiSamplerType(i) then
      cmb_msaa:AddItem(i .. "X")
    end
  end
end, _T("UI_common_shortcut_config")

function AddTextureFilter()
  cmb_filter:RemoveAll()
  cmb_filter:AddItem(_T("UI_lobby_Trilinear"))
  for i = 1, 4 do
    if config:CheckAnisotropy(2 ^ i) then
      cmb_filter:AddItem(_T("UI_lobby_Anisotropic") .. 2 ^ i .. "X")
    end
  end
end

AddResolution()
AddRefreshRate()
AddMSAA()
AddTextureFilter()
local UpdateGraphicUI = function(data)
  if data then
    ckb_full_screen.Check = not data.full_screen
    cmb_refresh.Enable = data.full_screen
    cmb_refresh.Text = data.refresh_rate
    cmb_resolution.SelectedIndex = cmb_resolution:TextToIndex(data.resolution)
    sld_shadow.CurValue = data.shadow_quality
    sld_model.CurValue = data.model_quality
    sld_shader.CurValue = data.shader_quality
    sld_hdr.CurValue = data.hdr_quality
    sld_bright.CurValue = 0.5
    brightness_init_value = 0.5
    cmb_filter.SelectedIndex = data.filter_index
    cmb_msaa.SelectedIndex = data.msaa_index / 2
    ckb_sync.Check = data.v_sync
    ckb_soft_particle.Check = data.soft_particle
  else
    ckb_full_screen.Check = not config.FullScreen
    cmb_refresh.Enable = config.FullScreen
    cmb_refresh.Text = config.RefreshRate
    cmb_resolution.SelectedIndex = cmb_resolution:TextToIndex(config.UserResolution)
    sld_shadow.CurValue = config.Shadow
    sld_model.CurValue = config.ModelQuality
    sld_shader.CurValue = config.ShaderQuality
    sld_hdr.CurValue = config.HDR
    sld_bright.CurValue = config.brightness + 0.5
    brightness_init_value = config.brightness
    cmb_filter.SelectedIndex = config.Anisotropy
    if config.MSAA == 0 then
      cmb_msaa.SelectedIndex = 0
    else
      cmb_msaa.SelectedIndex = math.log(config.MSAA, 2)
    end
    ckb_sync.Check = config.VSync
    ckb_soft_particle.Check = config.SoftParticle
  end
  if game.IsLowerVideo then
    sld_hdr.Enable = false
    cmb_filter.Enable = false
    cmb_msaa.Enable = false
    cmb_msaa.SelectedIndex = 0
  end
end
local ApplyGraphicSetting = function()
  config.FullScreen = not ckb_full_screen.Check
  config.RefreshRate = tonumber(cmb_refresh.Text)
  config.UserResolution = cmb_resolution.Text
  config.Shadow = sld_shadow.CurValue
  config.ModelQuality = sld_model.CurValue
  config.ShaderQuality = sld_shader.CurValue
  config.HDR = sld_hdr.CurValue
  config.brightness = sld_bright.CurValue - 0.5
  config.Anisotropy = cmb_filter.SelectedIndex
  if cmb_msaa.SelectedIndex == 0 then
    config.MSAA = 0
  else
    config.MSAA = 2 ^ cmb_msaa.SelectedIndex
  end
  config.SoftParticle = ckb_soft_particle.Check
  config.VSync = ckb_sync.Check
  config:SaveGraphic()
end

function s.graphic.reset()
  UpdateGraphicUI(default_graphic_setting)
end

function s.graphic.confirm()
  ApplyGraphicSetting()
  Hide()
end

function s.graphic.show()
  UpdateGraphicUI()
end

local default_audio_setting = {
  music_on = true,
  music_volume = 30,
  sound_effect_on = true,
  sound_effect_volume = 30,
  error_sound_on = false,
  ambience_effect_on = true,
  ambience_effect_volume = 30,
  player_sound_on = false,
  player_sound_volume = 30,
  player_language_index = 0
}
Ctrl(6, _T("UI_lobby_Game_Music"), 127, s.audio.ui)
Ctrl(136, _T("UI_lobby_Sound_Effect"), 169, s.audio.ui)
Ctrl(308, _T("UI_lobby_Environmental_Sound_Effect"), 127, s.audio.ui)
local ckb_music = CheckBox(24, 63, 190, _T("UI_lobby_Enable_Game_Music"), s.audio.ui[1])
local sld_music = Slider(201, 39, _T("UI_lobby_Volume"), s.audio.ui[1], false, 0, 100)
local ckb_sound_effect = CheckBox(24, 71, 190, _T("UI_lobby_Enable_Sound_Effect"), s.audio.ui[2])
local sld_sound_effect = Slider(201, 47, _T("UI_lobby_Sound_Effect_Volume"), s.audio.ui[2], false, 0, 100)
local ckb_error_sound = CheckBox(24, 129, 190, _T("UI_lobby_Enable_Error_Warning"), s.audio.ui[2])
local ckb_ambience_effect = CheckBox(24, 63, 190, _T("UI_lobby_Enable_Environmental_Sound_Effect"), s.audio.ui[3])
local sld_ambience_effect = Slider(201, 39, _T("UI_lobby_Environmental_Sound_Effect_Volume"), s.audio.ui[3], false, 0, 100)
local ckb_player_sound = CheckBox(24, 71, 190, _T("UI_common_Enable_Character_Sound"), s.audio.ui[4])
local sld_player_sound = Slider(201, 47, _T("tips_common_additional_tips22"), s.audio.ui[4], false, 0, 100)
local cmb_language = ComboBox(9, 119, _T("UI_common_Character_Language"), s.audio.ui[4])
local player_language_list = {
  _T("tips_common_additional_tips23"),
  _T("tips_common_additional_tips24")
}
for _, v in ipairs(player_language_list) do
  cmb_language:AddItem(v)
end

function sld_music.EventValueChange(s, e)
  game:CategorySetVolume("music", s.CurValue)
end

function sld_sound_effect.EventValueChange(s, e)
  game:CategorySetVolume("sound effect", s.CurValue)
end

function sld_ambience_effect.EventValueChange(s, e)
  game:CategorySetVolume("ambience", s.CurValue)
end

function ckb_music.EventCheckChanged(s, e)
  game:CategorySetMute("music", not s.Check)
end

function ckb_sound_effect.EventCheckChanged(s, e)
  game:CategorySetMute("sound effect", not s.Check)
end

function ckb_ambience_effect.EventCheckChanged(s, e)
  game:CategorySetMute("ambience", not s.Check)
end

function UpdateAudioUI(data)
  if data then
    ckb_music.Check = data.music_on
    sld_music.CurValue = data.music_volume
    ckb_sound_effect.Check = data.sound_effect_on
    sld_sound_effect.CurValue = data.sound_effect_volume
    ckb_error_sound.Check = data.error_sound_on
    ckb_ambience_effect.Check = data.ambience_effect_on
    sld_ambience_effect.CurValue = data.ambience_effect_volume
    ckb_player_sound.Check = data.player_sound_on
    sld_player_sound.CurValue = data.player_sound_volume
    cmb_language.SelectedIndex = data.player_language_index
  else
    ckb_music.Check = not game:CategoryGetMute("music")
    sld_music.CurValue = game:CategoryGetVolume("music")
    ckb_sound_effect.Check = not game:CategoryGetMute("sound effect")
    sld_sound_effect.CurValue = game:CategoryGetVolume("sound effect")
    ckb_ambience_effect.Check = not game:CategoryGetMute("ambience")
    sld_ambience_effect.CurValue = game:CategoryGetVolume("ambience")
    cmb_language.SelectedIndex = 0
  end
end

function ApplyAudioSetting()
  game:CategorySetMute("music", not ckb_music.Check)
  game:CategorySetVolume("music", sld_music.CurValue)
  game:CategorySetMute("sound effect", not ckb_sound_effect.Check)
  game:CategorySetVolume("sound effect", sld_sound_effect.CurValue)
  game:CategorySetMute("ambience", not ckb_ambience_effect.Check)
  game:CategorySetVolume("ambience", sld_ambience_effect.CurValue)
  config:SaveAudio()
end

function s.audio.reset()
  UpdateAudioUI(default_audio_setting)
  ApplyAudioSetting()
end

function s.audio.confirm()
  ApplyAudioSetting()
  Hide()
end

function s.audio.cancle()
  ckb_music.Check = ptr_cast(ckb_music.Tag)
  sld_music.CurValue = ptr_cast(sld_music.Tag)
  ckb_sound_effect.Check = ptr_cast(ckb_sound_effect.Tag)
  sld_sound_effect.CurValue = ptr_cast(sld_sound_effect.Tag)
  ckb_error_sound.Check = ptr_cast(ckb_error_sound.Tag)
  ckb_ambience_effect.Check = ptr_cast(ckb_ambience_effect.Tag)
  sld_ambience_effect.CurValue = ptr_cast(sld_ambience_effect.Tag)
  ckb_player_sound.Check = ptr_cast(ckb_player_sound.Tag)
  sld_player_sound.CurValue = ptr_cast(sld_player_sound.Tag)
  ApplyAudioSetting()
end

function s.audio.show()
  UpdateAudioUI()
  ckb_music.Tag = ckb_music.Check
  sld_music.Tag = sld_music.CurValue
  ckb_sound_effect.Tag = ckb_sound_effect.Check
  sld_sound_effect.Tag = sld_sound_effect.CurValue
  ckb_error_sound.Tag = ckb_error_sound.Check
  ckb_ambience_effect.Tag = ckb_ambience_effect.Check
  sld_ambience_effect.Tag = sld_ambience_effect.CurValue
  ckb_player_sound.Tag = ckb_player_sound.Check
  sld_player_sound.Tag = sld_player_sound.CurValue
end

Ctrl(6, _T("UI_lobby_Mouse"), 154, s.action.ui)
Ctrl(163, _T("tips_common_additional_tips26"), 380, s.action.ui)
local sld_sensitivity = MouseSlider(30, 39, _T("UI_lobby_Sensitivity"), s.action.ui[1], false, 0.05, 2.5)
local sld_sniper = MouseSlider(220, 39, _T("UI_lobby_Sighting_Sensitivity"), s.action.ui[1], false, 0.05, 2.5)
s.action.ui[2].Padding = Vector4(0, 40, 10, 10)
local src = Gui.ScrollableControl({
  Dock = "kDockFill",
  AutoScroll = true,
  AutoSize = true
})(s.action.ui[2], nil)
fl = Gui.FlowLayout({
  Size = Vector2(318, 1088),
  Padding = Vector4(4, 4, 4, 4),
  LineSpace = 4,
  Align = "kAlignCenterMiddle"
})(src, nil)
local key = {
  {
    _T("UI_lobby_Forward"),
    "kActionMoveForward"
  },
  {
    _T("UI_lobby_Backward"),
    "kActionMoveBackward"
  },
  {
    _T("UI_lobby_Left"),
    "kActionMoveLeft"
  },
  {
    _T("UI_lobby_Right"),
    "kActionMoveRight"
  },
  {
    _T("UI_lobby_additional_string_083"),
    "kActionJump"
  },
  {
    _T("UI_lobby_Roll"),
    "kActionCrouch"
  },
  {
    _T("UI_lobby_additional_string_085"),
    "kActionChangeWeapon"
  },
  {
    _T("UI_lobby_additional_string_086"),
    "kActionReload"
  },
  {
    _T("UI_lobby_Special_Action"),
    "kActionPickUpDropItem"
  },
  {
    _T("UI_lobby_Special_Action2"),
    "kActionThrowDropItem"
  },
  {
    _T("UI_lobby_additional_string_088"),
    "kActionMotionMenu"
  },
  {
    _T("UI_lobby_additional_string_089"),
    "kActionChangeView"
  },
  {
    _T("UI_lobby_additional_string_090"),
    "kActionUIMap"
  },
  {
    _T("UI_lobby_additional_string_091"),
    "kActionMenu1"
  },
  {
    _T("UI_lobby_additional_string_092"),
    "kActionMenu2"
  },
  {
    _T("UI_lobby_additional_string_093"),
    "kActionMenu3"
  },
  {
    _T("UI_lobby_additional_string_094"),
    "kActionMenu4"
  },
  {
    _T("UI_lobby_additional_string_095"),
    "kActionMenu5"
  },
  {
    _T("UI_lobby_additional_string_096"),
    "kActionMenu6"
  },
  {
    _T("UI_lobby_additional_string_097"),
    "kActionMenu7"
  },
  {
    _T("UI_lobby_additional_string_098"),
    "kActionMenu8"
  },
  {
    _T("UI_lobby_additional_string_099"),
    "kActionMenu9"
  },
  {
    _T("UI_lobby_additional_string_100"),
    "kActionMenu10"
  },
  {
    _T("UI_lobby_additional_string_101"),
    "kActionMenu11"
  },
  {
    _T("UI_lobby_additional_string_102"),
    "kActionMenu12"
  },
  {
    _T("UI_lobby_hotkey_new_01"),
    "kActionSensitivityDown"
  },
  {
    _T("UI_lobby_hotkey_new_02"),
    "kActionSensitivityUp"
  },
  {
    _T("UI_lobby_hotkey_new_03"),
    "kActionBrightnessDown"
  },
  {
    _T("UI_lobby_hotkey_new_04"),
    "kActionBrightnessUp"
  },
  {
    _T("UI_lobby_hotkey_new_05"),
    "kActionMotion0"
  },
  {
    _T("UI_lobby_hotkey_new_06"),
    "kActionMotion1"
  },
  {
    _T("UI_lobby_hotkey_new_07"),
    "kActionMotion2"
  },
  {
    _T("UI_lobby_hotkey_new_08"),
    "kActionMotion3"
  },
  {
    _T("UI_lobby_hotkey_new_09"),
    "kActionMotion4"
  },
  {
    _T("UI_lobby_hotkey_new_10"),
    "kActionMotion5"
  },
  {
    _T("UI_pet_switch_01"),
    "kActionPetOption"
  }
}
local key2 = {
  {
    _T("UI_lobby_additional_string_103"),
    _T("UI_lobby_Tab")
  },
  {
    _T("UI_lobby_additional_string_104"),
    _T("UI_lobby_Esc")
  },
  {
    _T("UI_lobby_additional_string_109"),
    _T("UI_lobby_Enter_Key")
  },
  {
    _T("UI_lobby_Screenshot_Button"),
    _T("UI_lobby_PrtScn")
  }
}
local kb_ui = {}
local control_kb_list
for _, v in ipairs(key) do
  Gui.Control({
    Size = Vector2(303, 23),
    Gui.Label({
      Location = Vector2(0, 2),
      Size = Vector2(177, 19),
      FontSize = 16,
      Text = v[1],
      TextColor = blue
    }),
    Gui.KeyBox(v[2])({
      Location = Vector2(195, 0),
      Size = Vector2(103, 23),
      Skin = SkinF.setting_01,
      EventKeyNameChanged = function(sender)
        for k, v in ipairs(control_kb_list) do
          if v ~= sender and v.KeyName == sender.KeyName then
            v:Empty()
          end
        end
      end,
      EventKeyConflict = function(sender)
        MessageBox.ShowError(_T("UI_common_This_key_has_been_used"))
      end,
      EventKeyForbidden = function()
        MessageBox.ShowError(_T("tips_common_additional_tips28"))
      end
    })
  })(fl, kb_ui)
end
control_kb_list = {
  kb_ui.kActionMoveForward,
  kb_ui.kActionMoveBackward,
  kb_ui.kActionMoveLeft,
  kb_ui.kActionMoveRight,
  kb_ui.kActionJump,
  kb_ui.kActionCrouch,
  kb_ui.kActionChangeWeapon,
  kb_ui.kActionReload,
  kb_ui.kActionPickUpDropItem,
  kb_ui.kActionThrowDropItem,
  kb_ui.kActionMotionMenu,
  kb_ui.kActionChangeView,
  kb_ui.kActionUIMap,
  kb_ui.kActionMenu1,
  kb_ui.kActionMenu2,
  kb_ui.kActionMenu3,
  kb_ui.kActionMenu4,
  kb_ui.kActionMenu5,
  kb_ui.kActionMenu6,
  kb_ui.kActionMenu7,
  kb_ui.kActionMenu8,
  kb_ui.kActionMenu9,
  kb_ui.kActionMenu10,
  kb_ui.kActionMenu11,
  kb_ui.kActionMenu12,
  kb_ui.kActionSensitivityDown,
  kb_ui.kActionSensitivityUp,
  kb_ui.kActionBrightnessDown,
  kb_ui.kActionBrightnessUp,
  kb_ui.kActionMotion0,
  kb_ui.kActionMotion1,
  kb_ui.kActionMotion2,
  kb_ui.kActionMotion3,
  kb_ui.kActionMotion4,
  kb_ui.kActionMotion5,
  kb_ui.kActionPetOption
}
for _, v in ipairs(key2) do
  Gui.Control({
    Size = Vector2(303, 23),
    Gui.Label({
      Location = Vector2(0, 2),
      Size = Vector2(153, 19),
      FontSize = 16,
      Text = v[1],
      TextColor = blue
    }),
    Gui.Label({
      Location = Vector2(195, 0),
      Size = Vector2(103, 23),
      TextAlign = "kAlignCenterMiddle",
      FontSize = 16,
      Text = v[2],
      TextColor = brown,
      Skin = SkinF.sociality_text_002,
      BackgroundColor = gray
    })
  })(fl, nil)
  local SensitivityUI2Data = kb_ui.kActionMoveLeft
end
local SensitivityData2UI = function(sld)
  return (sld.CurValue - sld.MinValue) / (sld.MaxValue - sld.MinValue) * 2.45 + 0.05
end
SensitivityUI2Data = "sensitivity"
SensitivityUI2Data = "sniper_sensitivity"
SensitivityUI2Data = "mouse_filter"
SensitivityUI2Data = "forward"
SensitivityUI2Data = "backward"
SensitivityUI2Data = "left"
SensitivityUI2Data = "right"
SensitivityUI2Data = "jump"
SensitivityUI2Data = "crouch"
SensitivityUI2Data = "change_weapon"
SensitivityUI2Data = "reload"
SensitivityUI2Data = "pickupitem"
SensitivityUI2Data = "throwitem"
SensitivityUI2Data = "motion_menu"
SensitivityUI2Data = "changeview"
SensitivityUI2Data = "map"
SensitivityUI2Data = "slot1"
SensitivityUI2Data = "slot2"
SensitivityUI2Data = "slot3"
SensitivityUI2Data = "slot4"
SensitivityUI2Data = "slot5"
SensitivityUI2Data = "slot6"
SensitivityUI2Data = "slot7"
SensitivityUI2Data = "slot8"
SensitivityUI2Data = "slot9"
SensitivityUI2Data = "slot10"
SensitivityUI2Data = "slot11"
SensitivityUI2Data = "slot12"
SensitivityUI2Data = "sensitivity_down"
SensitivityUI2Data = "sensitivity_up"
SensitivityUI2Data = "brightness_down"
SensitivityUI2Data = "brightness_up"
SensitivityUI2Data = "motion0"
SensitivityUI2Data = "motion1"
SensitivityUI2Data = "motion2"
SensitivityUI2Data = "motion3"
SensitivityUI2Data = "motion4"
SensitivityUI2Data = "motion5"
SensitivityUI2Data = "petoption"
local default_action_setting, UpdateAction = function(sld, value)
  sld.CurValue = (value - 0.05) * (sld.MaxValue - sld.MinValue) / 2.45 + sld.MinValue
end, {
  [SensitivityUI2Data] = 1.0151515007019,
  [SensitivityUI2Data] = 0.64393937587738,
  [SensitivityUI2Data] = true,
  [SensitivityUI2Data] = "W",
  [SensitivityUI2Data] = "S",
  [SensitivityUI2Data] = "A",
  [SensitivityUI2Data] = "D",
  [SensitivityUI2Data] = "SPACE",
  [SensitivityUI2Data] = "LCONTROL",
  [SensitivityUI2Data] = "Q",
  [SensitivityUI2Data] = "R",
  [SensitivityUI2Data] = "E",
  [SensitivityUI2Data] = "G",
  [SensitivityUI2Data] = "LMENU",
  [SensitivityUI2Data] = "F",
  [SensitivityUI2Data] = "M",
  [SensitivityUI2Data] = "1",
  [SensitivityUI2Data] = "2",
  [SensitivityUI2Data] = "3",
  [SensitivityUI2Data] = "4",
  [SensitivityUI2Data] = "5",
  [SensitivityUI2Data] = "6",
  [SensitivityUI2Data] = "7",
  [SensitivityUI2Data] = "8",
  [SensitivityUI2Data] = "9",
  [SensitivityUI2Data] = "0",
  [SensitivityUI2Data] = "MINUS",
  [SensitivityUI2Data] = "EQUALS",
  [SensitivityUI2Data] = "LBRACKET",
  [SensitivityUI2Data] = "RBRACKET",
  [SensitivityUI2Data] = "SEMICOLON",
  [SensitivityUI2Data] = "APOSTROPHE",
  [SensitivityUI2Data] = "F5",
  [SensitivityUI2Data] = "F6",
  [SensitivityUI2Data] = "F7",
  [SensitivityUI2Data] = "F8",
  [SensitivityUI2Data] = "F9",
  [SensitivityUI2Data] = "F10",
  [SensitivityUI2Data] = "P"
}
local SensitivityUI2Data, SaveAction = function(data)
  if data then
    SensitivityData2UI(sld_sensitivity, data.sensitivity)
    SensitivityData2UI(sld_sniper, data.sniper_sensitivity)
    kb_ui.kActionMoveForward.KeyName = data.forward
    kb_ui.kActionMoveBackward.KeyName = data.backward
    kb_ui.kActionMoveLeft.KeyName = data.left
    kb_ui.kActionMoveRight.KeyName = data.right
    kb_ui.kActionJump.KeyName = data.jump
    kb_ui.kActionCrouch.KeyName = data.crouch
    kb_ui.kActionChangeWeapon.KeyName = data.change_weapon
    kb_ui.kActionReload.KeyName = data.reload
    kb_ui.kActionPickUpDropItem.KeyName = data.pickupitem
    kb_ui.kActionThrowDropItem.KeyName = data.throwitem
    kb_ui.kActionMotionMenu.KeyName = data.motion_menu
    kb_ui.kActionChangeView.KeyName = data.changeview
    kb_ui.kActionUIMap.KeyName = data.map
    kb_ui.kActionMenu1.KeyName = data.slot1
    kb_ui.kActionMenu2.KeyName = data.slot2
    kb_ui.kActionMenu3.KeyName = data.slot3
    kb_ui.kActionMenu4.KeyName = data.slot4
    kb_ui.kActionMenu5.KeyName = data.slot5
    kb_ui.kActionMenu6.KeyName = data.slot6
    kb_ui.kActionMenu7.KeyName = data.slot7
    kb_ui.kActionMenu8.KeyName = data.slot8
    kb_ui.kActionMenu9.KeyName = data.slot9
    kb_ui.kActionMenu10.KeyName = data.slot10
    kb_ui.kActionMenu11.KeyName = data.slot11
    kb_ui.kActionMenu12.KeyName = data.slot12
    kb_ui.kActionSensitivityDown.KeyName = data.sensitivity_down
    kb_ui.kActionSensitivityUp.KeyName = data.sensitivity_up
    kb_ui.kActionBrightnessDown.KeyName = data.brightness_down
    kb_ui.kActionBrightnessUp.KeyName = data.brightness_up
    kb_ui.kActionMotion0.KeyName = data.motion0
    kb_ui.kActionMotion1.KeyName = data.motion1
    kb_ui.kActionMotion2.KeyName = data.motion2
    kb_ui.kActionMotion3.KeyName = data.motion3
    kb_ui.kActionMotion4.KeyName = data.motion4
    kb_ui.kActionMotion5.KeyName = data.motion5
    kb_ui.kActionPetOption.KeyName = data.petoption
  else
    print("update action(data) failed! data = nil")
  end
end, "P"
local SaveAction, ApplyAction = function()
  local t = {}
  t.sensitivity = SensitivityUI2Data(sld_sensitivity)
  t.sniper_sensitivity = SensitivityUI2Data(sld_sniper)
  t.forward = kb_ui.kActionMoveForward.KeyName
  t.backward = kb_ui.kActionMoveBackward.KeyName
  t.left = kb_ui.kActionMoveLeft.KeyName
  t.right = kb_ui.kActionMoveRight.KeyName
  t.jump = kb_ui.kActionJump.KeyName
  t.crouch = kb_ui.kActionCrouch.KeyName
  t.change_weapon = kb_ui.kActionChangeWeapon.KeyName
  t.reload = kb_ui.kActionReload.KeyName
  t.pickupitem = kb_ui.kActionPickUpDropItem.KeyName
  t.throwitem = kb_ui.kActionThrowDropItem.KeyName
  t.motion_menu = kb_ui.kActionMotionMenu.KeyName
  t.changeview = kb_ui.kActionChangeView.KeyName
  t.map = kb_ui.kActionUIMap.KeyName
  t.slot1 = kb_ui.kActionMenu1.KeyName
  t.slot2 = kb_ui.kActionMenu2.KeyName
  t.slot3 = kb_ui.kActionMenu3.KeyName
  t.slot4 = kb_ui.kActionMenu4.KeyName
  t.slot5 = kb_ui.kActionMenu5.KeyName
  t.slot6 = kb_ui.kActionMenu6.KeyName
  t.slot7 = kb_ui.kActionMenu7.KeyName
  t.slot8 = kb_ui.kActionMenu8.KeyName
  t.slot9 = kb_ui.kActionMenu9.KeyName
  t.slot10 = kb_ui.kActionMenu10.KeyName
  t.slot11 = kb_ui.kActionMenu11.KeyName
  t.slot12 = kb_ui.kActionMenu12.KeyName
  t.sensitivity_down = kb_ui.kActionSensitivityDown.KeyName
  t.sensitivity_up = kb_ui.kActionSensitivityUp.KeyName
  t.brightness_down = kb_ui.kActionBrightnessDown.KeyName
  t.brightness_up = kb_ui.kActionBrightnessUp.KeyName
  t.motion0 = kb_ui.kActionMotion0.KeyName
  t.motion1 = kb_ui.kActionMotion1.KeyName
  t.motion2 = kb_ui.kActionMotion2.KeyName
  t.motion3 = kb_ui.kActionMotion3.KeyName
  t.motion4 = kb_ui.kActionMotion4.KeyName
  t.motion5 = kb_ui.kActionMotion5.KeyName
  t.petoption = kb_ui.kActionPetOption.KeyName
  local str = [[
list = 
{
]]
  for k, v in pairs(t) do
    local value = v
    if type(value) == "boolean" then
      value = value and "true" or "false"
    elseif type(value) == "string" then
      value = "\"" .. value .. "\""
    end
    str = str .. "\t" .. k .. " = " .. value .. ",\n"
  end
  str = str .. "}"
  config.ProfileStream = str
  config:SaveProfile()
end, Gui.Control({
  Size = Vector2(303, 23),
  Gui.Label({
    Location = Vector2(0, 2),
    Size = Vector2(153, 19),
    FontSize = 16,
    Text = v[1],
    TextColor = blue
  }),
  Gui.Label({
    Location = Vector2(195, 0),
    Size = Vector2(103, 23),
    TextAlign = "kAlignCenterMiddle",
    FontSize = 16,
    Text = v[2],
    TextColor = brown,
    Skin = SkinF.sociality_text_002,
    BackgroundColor = gray
  })
})

function ApplyAction(boolSave)
  config.Sensitivity = SensitivityUI2Data(sld_sensitivity)
  config.SensitivitySniper = SensitivityUI2Data(sld_sniper)
  config:BindAction("kActionMoveForward", kb_ui.kActionMoveForward.KeyName)
  config:BindAction("kActionMoveBackward", kb_ui.kActionMoveBackward.KeyName)
  config:BindAction("kActionMoveLeft", kb_ui.kActionMoveLeft.KeyName)
  config:BindAction("kActionMoveRight", kb_ui.kActionMoveRight.KeyName)
  config:BindAction("kActionJump", kb_ui.kActionJump.KeyName)
  config:BindAction("kActionCrouch", kb_ui.kActionCrouch.KeyName)
  config:BindAction("kActionChangeWeapon", kb_ui.kActionChangeWeapon.KeyName)
  config:BindAction("kActionReload", kb_ui.kActionReload.KeyName)
  config:BindAction("kActionPickUpDropItem", kb_ui.kActionPickUpDropItem.KeyName)
  config:BindAction("kActionThrowDropItem", kb_ui.kActionThrowDropItem.KeyName)
  config:BindAction("kActionMotionMenu", kb_ui.kActionMotionMenu.KeyName)
  config:BindAction("kActionChangeView", kb_ui.kActionChangeView.KeyName)
  config:BindAction("kActionUIMap", kb_ui.kActionUIMap.KeyName)
  config:BindAction("kActionMenu1", kb_ui.kActionMenu1.KeyName)
  config:BindAction("kActionMenu2", kb_ui.kActionMenu2.KeyName)
  config:BindAction("kActionMenu3", kb_ui.kActionMenu3.KeyName)
  config:BindAction("kActionMenu4", kb_ui.kActionMenu4.KeyName)
  config:BindAction("kActionMenu5", kb_ui.kActionMenu5.KeyName)
  config:BindAction("kActionMenu6", kb_ui.kActionMenu6.KeyName)
  config:BindAction("kActionMenu7", kb_ui.kActionMenu7.KeyName)
  config:BindAction("kActionMenu8", kb_ui.kActionMenu8.KeyName)
  config:BindAction("kActionMenu9", kb_ui.kActionMenu9.KeyName)
  config:BindAction("kActionMenu10", kb_ui.kActionMenu10.KeyName)
  config:BindAction("kActionMenu11", kb_ui.kActionMenu11.KeyName)
  config:BindAction("kActionMenu12", kb_ui.kActionMenu12.KeyName)
  config:BindAction("kActionSensitivityDown", kb_ui.kActionSensitivityDown.KeyName)
  config:BindAction("kActionSensitivityUp", kb_ui.kActionSensitivityUp.KeyName)
  config:BindAction("kActionBrightnessDown", kb_ui.kActionBrightnessDown.KeyName)
  config:BindAction("kActionBrightnessUp", kb_ui.kActionBrightnessUp.KeyName)
  config:BindAction("kActionMotion0", kb_ui.kActionMotion0.KeyName)
  config:BindAction("kActionMotion1", kb_ui.kActionMotion1.KeyName)
  config:BindAction("kActionMotion2", kb_ui.kActionMotion2.KeyName)
  config:BindAction("kActionMotion3", kb_ui.kActionMotion3.KeyName)
  config:BindAction("kActionMotion4", kb_ui.kActionMotion4.KeyName)
  config:BindAction("kActionMotion5", kb_ui.kActionMotion5.KeyName)
  config:BindAction("kActionPetOption", kb_ui.kActionPetOption.KeyName)
  if boolSave then
    SaveAction()
  end
end

function s.action.show()
  local data, load_err = rpc.load_result(config.ProfileStream)
  if load_err then
    data = {}
  end
  local my_action_settings = data.list
  if my_action_settings then
    setmetatable(my_action_settings, {__index = default_action_setting})
    UpdateAction(my_action_settings)
  else
    UpdateAction(default_action_setting)
  end
end

function s.action.reset()
  UpdateAction(default_action_setting)
end

function s.action.confirm()
  ApplyAction(true)
  Hide()
end

Ctrl(6, _T("tips_common_additional_tips21"), 137, s.interface.ui)
local ckb_invite = CheckBox(17, 48, 190, _T("UI_common_Do_not_accept_mission_party_invite"), s.interface.ui[1])
local ckb_guide, UpdateInterface = CheckBox(17, 91, 190, _T("UI_common_Close_guide"), s.interface.ui[1]), 17
local UpdateInterface, ApplyInterface = function(data)
  if data then
    ckb_invite.Check = data.invite_off
    ckb_guide.Check = data.guide_off
  else
    local cp = game.CharacterProfile
    if cp then
      ckb_invite.Check = cp.InviteOff
      ckb_guide.Check = cp.GuideOff
    end
  end
end, 91

function ApplyInterface()
  local cp = game.CharacterProfile
  if cp then
    cp.InviteOff = ckb_invite.Check
    cp.GuideOff = ckb_guide.Check
    cp:Save()
  end
end

function s.interface.show()
  UpdateInterface()
end

function s.interface.reset()
  ckb_invite.Check = false
  ckb_guide.Check = false
  ApplyInterface()
end

function s.interface.confirm()
  ApplyInterface()
  Hide()
end

function s.switch.show()
end

function s.switch.reset()
  MessageBox.ShowError(_T("UI_common_Invalid_Key"))
end

function s.switch.confirm()
  MessageBox.ShowError(_T("UI_common_Invalid_Key"))
end

local pre_setting_value = 0
Ctrl(6, _T("UI_common_display_01"), 150, s.ingame_display.ui)
Ctrl(178, _T("UI_common_display_05"), 150, s.ingame_display.ui)
local ckb_ingame_display_fps = CheckBox(24, 45, 380, _T("UI_common_display_03"), s.ingame_display.ui[1])
local ckb_ingame_display_ping = CheckBox(24, 80, 380, _T("UI_common_display_04"), s.ingame_display.ui[1])
local ckb_ingame_display_pet = CheckBox(24, 45, 380, _T("UI_common_display_06"), s.ingame_display.ui[2])

function s.ingame_display.show()
  if bit.band(config.VictoryConnectMilitary, 256) == 0 then
    ckb_ingame_display_fps.Check = false
  else
    ckb_ingame_display_fps.Check = true
  end
  if bit.band(config.VictoryConnectMilitary, 512) == 0 then
    ckb_ingame_display_ping.Check = false
  else
    ckb_ingame_display_ping.Check = true
  end
  if bit.band(config.VictoryConnectMilitary, 1024) == 0 then
    ckb_ingame_display_pet.Check = false
  else
    ckb_ingame_display_pet.Check = true
  end
  pre_setting_value = config.VictoryConnectMilitary
end

function s.ingame_display.reset()
  if ckb_ingame_display_fps then
    ckb_ingame_display_fps.Check = true
  end
  if ckb_ingame_display_ping then
    ckb_ingame_display_ping.Check = true
  end
  if ckb_ingame_display_pet then
    ckb_ingame_display_pet.Check = true
  end
end

function s.ingame_display.confirm()
  if ckb_ingame_display_fps.Check then
    config.VictoryConnectMilitary = bit.bor(config.VictoryConnectMilitary, 256)
  else
    config.VictoryConnectMilitary = bit.band(config.VictoryConnectMilitary, 2147483391)
  end
  if ckb_ingame_display_ping.Check then
    config.VictoryConnectMilitary = bit.bor(config.VictoryConnectMilitary, 512)
  else
    config.VictoryConnectMilitary = bit.band(config.VictoryConnectMilitary, 2147483135)
  end
  if ckb_ingame_display_pet.Check then
    config.VictoryConnectMilitary = bit.bor(config.VictoryConnectMilitary, 1024)
  else
    config.VictoryConnectMilitary = bit.band(config.VictoryConnectMilitary, 2147482623)
  end
  config:SaveOther()
  if bit.band(config.VictoryConnectMilitary, 1024) ~= bit.band(pre_setting_value, 1024) then
    local game_state = ptr_cast(game.CurrentState, "Client.StateMainGame")
    if game_state then
      game_state:RequestPetVisible()
    end
  end
  Hide()
end

local btn_go_1 = Gui.Button({
  Location = Vector2(9, 5),
  Size = Vector2(398, 70),
  Text = _T("tips_common_additional_tips29"),
  EventClick = function(sender, e)
    local state = ptr_cast(game.CurrentState, "Client.StateLogin")
    if state ~= nil then
    end
  end
})(nil, s.switch.ui)
local btn_go_2 = Gui.Button({
  Location = Vector2(9, 80),
  Size = Vector2(398, 70),
  Text = _T("tips_common_additional_tips30"),
  EventClick = function(sender, e)
    local state = ptr_cast(game.CurrentState, "Client.StateSelectCharacter")
    if state ~= nil then
    end
  end
})(nil, s.switch.ui)
local btn_go_3 = Gui.Button({
  Location = Vector2(9, 155),
  Size = Vector2(398, 70),
  Text = _T("tips_common_additional_tips31"),
  EventClick = function(sender, e)
    local state = ptr_cast(game.CurrentState, "Client.StateAvatar")
    if state ~= nil then
    end
  end
})(nil, s.switch.ui)
local btn_go_4 = Gui.Button({
  Location = Vector2(9, 230),
  Size = Vector2(398, 70),
  Text = _T("UI_common_Lobby"),
  EventClick = function(sender, e)
    local state = ptr_cast(game.CurrentState, "Client.StateLobby")
    if state ~= nil then
    end
  end
})(nil, s.switch.ui)
local btn_go_5 = Gui.Button({
  Location = Vector2(9, 305),
  Size = Vector2(398, 70),
  Text = _T("UI_common_Clearance_Settlement"),
  EventClick = function(sender, e)
    local state = ptr_cast(game.CurrentState, "Client.StateBalance")
    if state ~= nil then
    end
  end
})(nil, s.switch.ui)
local btn_reset = Gui.Button({
  Location = Vector2(10, 590),
  Size = Vector2(124, 37),
  Text = _T("button_common_Default"),
  EventClick = function(sender, e)
    s[sel].reset()
  end
})(ctrl_main, nil)
local btn_confirm = Gui.Button({
  Location = Vector2(178, 590),
  Size = Vector2(105, 37),
  Text = _T("button_common_OK"),
  EventClick = function(sender, e)
    s[sel].confirm()
  end
})(ctrl_main, nil)
local btn_cancel = Gui.Button({
  Location = Vector2(291, 590),
  Size = Vector2(105, 37),
  Text = _T("button_common_Cancel"),
  EventClick = function(sender, e)
    if s[sel].cancle then
      s[sel].cancle()
    end
    Hide()
    config.brightness = brightness_init_value
  end
})(ctrl_main, nil)

function Init()
  UpdateInterface()
  UpdateAudioUI()
  UpdateGraphicUI()
  ApplyAudioSetting()
  ApplyGraphicSetting()
  ApplyInterface()
  
  function config.EventLoadSettings(sender, e)
    if e.Details then
      local data, load_err = rpc.load_result(config.SettingStream)
      if load_err then
        data = {}
      end
    end
  end
  
  function config.EventLoadProfile(sender, e)
    local cProfile = game.CharacterProfile
    if e.Details and cProfile then
      local data, load_err = rpc.load_result(e.Details)
      if load_err then
        data = {}
      end
      local my_settings = data.list
      if type(my_settings) ~= "table" then
        my_settings = {}
      end
      setmetatable(my_settings, {__index = default_action_setting})
      UpdateAction(my_settings)
      ApplyAction(true)
    end
  end
  
  function config.EventSaveProfile(sender, e)
    if PersonalInfo then
      PersonalInfo.SetHotKeyName()
    end
  end
  
  function config.EventSettingsChanged(sender, e)
    if e.action_type == "kActionSensitivityDown" then
      sld_sensitivity.CurValue = sld_sensitivity.CurValue - 1
      config.Sensitivity = SensitivityUI2Data(sld_sensitivity)
    elseif e.action_type == "kActionSensitivityUp" then
      sld_sensitivity.CurValue = sld_sensitivity.CurValue + 1
      config.Sensitivity = SensitivityUI2Data(sld_sensitivity)
    elseif e.action_type == "kActionBrightnessDown" then
      sld_sniper.CurValue = sld_sniper.CurValue - 1
      config.SensitivitySniper = SensitivityUI2Data(sld_sniper)
    elseif e.action_type == "kActionBrightnessUp" then
      sld_sniper.CurValue = sld_sniper.CurValue + 1
      config.SensitivitySniper = SensitivityUI2Data(sld_sniper)
    end
  end
  
  function config.EventSettingsChangedEnd(sender, e)
    ApplyAction(true)
  end
end

function Show(t)
  local m = ModalWindow.Show("transparent")
  m.root.Size = Vector2(430, 690)
  ctrl_setting.Parent = m.root
  Gui.Clear(s[sel].ui)
  sel = t
  for _, v in ipairs(s[sel].ui) do
    v.Parent = ctrl_main
  end
  lb_title.Text = s[t].title
  lb_title.Parent = ctrl_setting
  ctrl_main.Parent = ctrl_setting
  s[sel].show()
  return m
end

function Hide()
  ModalWindow.Close()
end
