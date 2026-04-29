module("Tip", package.seeall)
lang = {
  zh_cn = 1,
  en_sg = 2,
  zh_tw = 3,
  vi_vn = 4,
  th_th = 5
}
_T = GetUTF8Text
_L = GetUTF8Text
_M = GetMatchedUTF8Text
local floor = math.floor
local ceil = math.ceil
local gsub = string.gsub

function _Key(key, t)
  return (gsub(key, "(%[(%d)%])", function(re, d)
    return t[d + 1] or re
  end))
end

function _Value(key, t)
  return (gsub(key, "({(%d)})", function(re, d)
    return t[d + 1] or re
  end))
end

function _LL(key)
  if not key then
    return ""
  end
  local k = string.match(key, "{(.*)}")
  return k and _M(k) or key
end

function CreateTimer(cb)
  local mgr = game.TimerMgr
  local timer
  local t = {}
  
  function t.Stop()
    if timer then
      mgr:RemoveTimer(timer)
    end
  end
  
  function t.Start()
    t.Stop()
    timer = mgr:AddTimer(120)
    if timer then
      function timer.EventOnTimer()
        cb()
      end
    end
  end
  
  return t
end

function CreateTitle(p, ui, t)
  ui.lb = Gui.Label({
    Size = Vector2(0, 30),
    Dock = "kDockTop",
    TextPadding = Vector4(12, 0, 0, 0),
    FontSize = 16,
    Text = t
  })(p, nil)
  ui.hint = Gui.Label({
    Size = Vector2(0, 30),
    Dock = "kDockTop",
    TextAlign = "kAlignRightMiddle",
    TextPadding = Vector4(120, 0, 36, 0),
    FontSize = 16,
    Text = ""
  })(ui.lb, nil)
  ui.btn = Gui.Button({
    Size = Vector2(24, 24),
    Margin = Vector4(0, 4, 6, 2),
    Dock = "kDockRight",
    Skin = SkinF.lookInfo_002
  })(ui.hint, nil)
end

white = ARGB(255, 255, 255, 255)
black = ARGB(255, 0, 0, 0)
red = ARGB(255, 255, 0, 0)
brown = ARGB(255, 113, 83, 65)
yellow = ARGB(255, 255, 240, 0)
green = ARGB(255, 0, 255, 0)
gp_text = _T("id_common_Gold")
mb_text = _T("id_common_CC")
tb_text = _T("id_common_Medal")
tk_text = _T("id_common_Ticket")
local currency_key = {
  "id_common_Gold",
  "id_common_CC",
  "id_common_Medal",
  "id_common_Ticket"
}

function GetCurrencyKey(c)
  return currency_key[c]
end

local tip_t = {
  [1] = {},
  [2] = {},
  [3] = {},
  [4] = {},
  [5] = {},
  [6] = {},
  [7] = {},
  [8] = {},
  [9] = {},
  [10] = {}
}
local tip_st = {
  [2] = {
    [1] = {},
    [2] = {},
    [3] = {},
    [4] = {},
    [5] = {},
    [6] = {},
    [10] = {},
    [11] = {},
    [12] = {},
    [13] = {},
    [14] = {},
    [15] = {},
    [16] = {},
    [101] = {},
    [102] = {},
    [103] = {}
  },
  [3] = {
    [100] = {},
    [101] = {},
    [102] = {},
    [103] = {},
    [104] = {},
    [105] = {},
    [106] = {},
    [107] = {},
    [108] = {},
    [109] = {},
    [110] = {},
    [111] = {},
    [112] = {},
    [200] = {},
    [300] = {},
    [301] = {},
    [302] = {},
    [303] = {},
    [304] = {},
    [400] = {},
    [401] = {},
    [112001] = {}
  },
  [5] = {
    [1] = {},
    [2] = {}
  },
  [8] = {
    [501] = {},
    [502] = {},
    [503] = {},
    [504] = {},
    [505] = {},
    [506] = {}
  }
}
local currency = {
  {
    gp_text,
    IconsF.GpIcon
  },
  {
    mb_text,
    IconsF.MbIcon
  },
  {
    tb_text,
    IconsF.TbIcon
  },
  {
    tk_text,
    IconsF.TkIcon
  }
}

function GetCurrencyText(c)
  return currency[c][1]
end

function GetCurrencyIcon(c)
  return currency[c][2]
end

local big_currency_icon = {
  IconsF.BigGpIcon,
  IconsF.BigMbIcon,
  IconsF.BigTbIcon,
  IconsF.BigTkIcon
}

function GetBigCurrencyIcon(c)
  return big_currency_icon[c]
end

local format = string.format
local grade = {
  {
    _T("tips_lobby_Common_Desc8"),
    ARGB(255, 255, 255, 255)
  },
  {
    _T("tips_lobby_Common_Desc9"),
    ARGB(255, 126, 255, 0)
  },
  {
    _T("tips_lobby_Common_Desc10"),
    ARGB(255, 0, 180, 255)
  },
  {
    _T("tips_lobby_Common_Desc11"),
    ARGB(255, 198, 0, 255)
  },
  {
    _T("tips_lobby_Common_Desc12"),
    ARGB(255, 255, 128, 0)
  }
}
for i = 1, 5 do
  grade[i][3] = Gui.Image(format("ui/skinF/skin_common_weapon_bg%02d.tga", i), Vector4(0, 0, 0, 0))
end

function GetGradeText(g)
  return grade[g][1]
end

function GetGradeColor(g)
  return grade[g][2]
end

function GetGradeImage(g)
  return grade[g][3]
end

function GetRankKey(r)
  return string.format("UI_social_rank_lv_%02d", r)
end

function GetRankName(r)
  return _T(GetRankKey(r))
end

function SortPrice(t1, t2)
  if t1.unitType == t2.unitType then
    if t1.unit == t2.unit then
      return t1.currency < t2.currency
    else
      return t1.unit < t2.unit
    end
  else
    return t1.unitType < t2.unitType
  end
end

local level_image = {}
for i = 1, 20 do
  level_image[i] = Gui.Image(format("ui/skinF/skin_tooltips_level%02d.tga", i), Vector4(0, 0, 0, 0))
end

function GetLevelImage(i)
  return level_image[i]
end

function GetLevelImageBg(i)
  local temp = {
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    2,
    2,
    2,
    2,
    2,
    2,
    3,
    3,
    3,
    3,
    4
  }
  if i > #temp or i < 1 then
    return nil
  end
  return Gui.Image(format("ui/skinF/skin_common_enhancelv_%02d.tga", temp[i]), Vector4(0, 0, 0, 0))
end

function GetPlusLevelSkin(i)
  local temp = {
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    2,
    2,
    2,
    2,
    2,
    2,
    3,
    3,
    3,
    3,
    4
  }
  if i > #temp or i < 1 then
    return nil
  end
  return SkinF.personalInfo_245[temp[i]]
end

function TableCopy(t)
  local ret = {}
  for k, v in pairs(t) do
    if type(v) == "table" then
      ret[k] = TableCopy(v)
    else
      ret[k] = v
    end
  end
  return ret
end

local rpc_interface = ""
local rpc_args = {}
local use_desc = false
local is_renew = false
local Un_Bind = false

function SetRpc(i, a)
  rpc_interface = i
  rpc_args = a
end

function SetUseDescription(ud)
  use_desc = ud
end

local it = Gui.ItemTip({})()

function SetOwner(o)
  it.Owner = o
end

function SetOffset(o)
  it.Offset = o
end

function SetAlignSize(s)
  it.AlignSize = s
end

function GetIcon(name)
  return Gui.Icon(format("ui/skinF/lobby/%s.tga", string.match(name, "[%w_]+")))
end

local occupation_icon = {
  "skin_common_icon01.tga",
  "skin_common_icon02.tga",
  "skin_common_icon03.tga"
}

function GetMyOccupationIcon()
  local resource = occupation_icon[SelectCharacter.role_job_id + 1]
  return Gui.Icon("ui/skinF/" .. resource, Vector4(0, 0, 0, 0))
end

function GetOccupationNA(o)
  if not o or o == 0 then
    return false
  end
  return bit.band(bit.bshift(1, SelectCharacter.role_job_id), o) == 0
end

local occupation_text = {
  _T("UI_profession_Guardian"),
  _T("UI_profession_Gunner"),
  _T("UI_profession_Assassin"),
  _T("UI_profession_Biochemical")
}
local GetMyOccupationText, GetOccupation = function()
  return occupation_text[SelectCharacter.role_job_id + 1]
end, function()
  return occupation_text[SelectCharacter.role_job_id + 1]
end

function GetOccupation(o)
  local s = ""
  local c = GetOccupationNA(o) and red or white
  for i, v in ipairs(occupation_text) do
    if o == 0 or bit.band(bit.bshift(1, i - 1), o) ~= 0 then
      s = s .. v .. " "
    end
  end
  return s, c
end

local day = 86400
local hour = 3600
local minute = 60
local second = 0
local time_fmt = {
  {
    day,
    _T("UI_common_Day"),
    function(t)
      return floor(t / day)
    end
  },
  {
    hour,
    _T("tips_lobby_Common_Desc31"),
    function(t)
      return floor(t % day / hour)
    end
  },
  {
    minute,
    _T("UI_common_Minute"),
    function(t)
      return floor(t % hour / minute)
    end
  },
  {
    second,
    _T("tips_abilities_Sec"),
    function(t)
      return t % minute
    end
  }
}

function GetLeftTime(time)
  if time <= 0 then
    return _T("tips_lobby_Common_Desc26")
  else
    local time_v = {}
    local time_t = {}
    local time_end = 1
    for i, v in ipairs(time_fmt) do
      if time >= v[1] then
        time_end = i
        time_v[i] = v[3](time)
        time_t[i] = v[2]
        if time_end < #time_fmt then
          time_end = time_end + 1
          local t = time_fmt[time_end][3](time)
          if 0 < t then
            time_v[time_end] = t
            time_t[time_end] = time_fmt[time_end][2]
            break
          end
          time_v[time_end] = ""
          time_t[time_end] = ""
        end
        break
      else
        time_v[i] = ""
        time_t[i] = ""
      end
    end
    for i = time_end + 1, #time_fmt do
      time_v[i] = ""
      time_t[i] = ""
    end
    local ret = _Key(_T("UI_common_time_format_unit"), time_t)
    return _Value(ret, time_v)
  end
end

local GetLockedTime, GetRemain = function(lockExpireTime, now)
  local surplusTime = lockExpireTime - now / 1000
  if 0 < surplusTime then
    return 4, surplusTime
  end
end, function(lockExpireTime, now)
  local surplusTime = lockExpireTime - now / 1000
  if 0 < surplusTime then
    return 4, surplusTime
  end
end

function GetRemain(unitType, remain, unit)
  if 1 == unitType then
    return _T("tips_lobby_Common_Desc5"), _T("tips_lobby_Common_Desc7"), white
  end
  if 2 == unitType then
    return _T("tips_lobby_Common_Desc27"), unit .. " / 100", 0 < unit and white or red
  end
  if 3 == unitType then
    return _T("tips_lobby_Common_Desc16"), unit, 0 < unit and white or red
  end
  if 4 == unitType then
    if is_renew then
      if remain then
        return _T("tips_lobby_Common_Desc5"), GetLeftTime(remain) .. _T("tips_buff_u_can_renew"), 0 < remain and white or red
      else
        return _T("tips_lobby_Common_Desc5"), format("%s(%s)%s", _T("tips_datalist_Binding_timer"), GetLeftTime(unit), _T("tips_buff_u_can_renew")), white
      end
    elseif remain then
      return _T("tips_lobby_Common_Desc5"), GetLeftTime(remain) .. _T("tips_buff_u_cannot_renew"), 0 < remain and white or red
    else
      return _T("tips_lobby_Common_Desc5"), format("%s(%s)%s", _T("tips_datalist_Binding_timer"), GetLeftTime(unit), _T("tips_buff_u_cannot_renew")), white
    end
  end
  if 5 == unitType then
    return _T("tips_lobby_Common_Desc17"), unit, 0 < unit and white or red
  end
end

local unit_type = {
  _T("tips_lobby_Common_Desc7"),
  _T("tips_lobby_Common_Desc27"),
  _T("UI_common_number"),
  "",
  _T("tips_lobby_Common_Desc25")
}

function GetUnitType(ut)
  return unit_type[ut]
end

function GetUnit(unitType, unit)
  if unitType == 1 then
    return ""
  elseif unitType == 4 then
    return GetLeftTime(unit)
  else
    return unit
  end
end

function GetCount(unitType, unit)
  local ret = _Value(_T("tips_store_value_price_01"), {
    GetUnit(unitType, unit)
  })
  return _Key(ret, {
    GetUnitType(unitType)
  })
end

function GetPrice(p)
  local price = p.price
  if p.rebatePrice > 0 then
    price = p.rebatePrice
  end
  local ret = _Value(_T("tips_store_value_price"), {
    GetUnit(p.unitType, p.unit),
    price
  })
  return _Key(ret, {
    GetUnitType(p.unitType),
    GetCurrencyText(p.currency)
  })
end

function GetRenewPrice(p)
  local price = p.price
  local ret = _Value(_T("tips_store_value_price"), {
    GetUnit(p.unitType, p.unit),
    price
  })
  return _Key(ret, {
    GetUnitType(p.unitType),
    GetCurrencyText(p.currency)
  })
end

local bind_type, GetBind = {
  _T("tips_abilities_None"),
  _T("tips_abilities_Equipment_Bind"),
  _T("tips_abilities_Loot_Bind")
}, _T("tips_abilities_None")
local GetBind, GetType = function(isBind, bindType)
  if "Y" == isBind then
    if Un_Bind then
      return _T("UI_common_Bound") .. _T("UI_abilities_kejiebang")
    else
      return _T("UI_common_Bound") .. _T("UI_abilities_bukejiebang")
    end
  elseif Un_Bind then
    return bind_type[bindType + 1] .. _T("UI_abilities_kejiebang")
  else
    return bind_type[bindType + 1] .. _T("UI_abilities_bukejiebang")
  end
end, _T("tips_abilities_Equipment_Bind")
local GetType, GetSubType = function(t)
  return tip_t[t].text
end, _T("tips_abilities_Loot_Bind")

function GetSubType(t, st)
  if 0 < st then
    return tip_st[t][st].text
  else
    return GetType(t)
  end
end

tip_t[1].text = _T("button_common_Skill")
tip_t[1].tip = function(data)
  it.SummaryLevel = nil
  local skill_1 = data.skills[1]
  local skill_2 = data.skills[2]
  if data.ventureForce and data.ventureForce > 0 then
    it.SummaryAdvent = _T("tips_lobby_explore_strength_tips") .. " " .. math.floor(data.ventureForce)
  else
    it.SummaryAdvent = ""
  end
  it:SetTitle(GetIcon(skill_1.resource), _L(skill_1.display), white)
  it.GradeImage = nil
  it.Summary = ""
  if data.canEquip == "Y" then
    it.State = data.isEquip == "Y" and _T("tips_common_additional_tips6") or _T("tips_common_additional_tips7")
  else
    it.State = ""
  end
  it:SetInfo(_T("UI_common_Skill_Level"), _Value(_T("tips_abilities_Lv_num_and_above"), {
    skill_1.level
  }), white)
  it:SetInfo(_T("UI_common_Use_Skill"), skill_1.isActive == "Y" and _T("UI_common_Active") or _T("UI_common_Passive"), white)
  it:SetEffect(GetType(data.type) .. _T("tips_common_additional_tips1"), _L(skill_1.description), _L(skill_1.effect))
  if skill_2 ~= nil then
    it:SetEffect(_T("UI_common_Next_Level"), _L(""), _L(skill_2.effect))
  end
  if skill_1.isActive == "Y" and use_desc then
    it.UseDesc = _T("UI_common_onto_a_Quick_Key_Slot")
  end
  PersonalInfo.ForceLeadSkillLearn(PersonalInfo.FORCE_LEAD_SKILLLEARN_SKILL_ADD)
end
tip_t[2].text = _T("tips_store_Weapon_lottery")
tip_t[2].tip = function(data)
  if data.ventureForce and data.ventureForce > 0 then
    it.SummaryAdvent = _T("tips_lobby_explore_strength_tips") .. " " .. math.floor(data.ventureForce)
  else
    it.SummaryAdvent = ""
  end
  if data.subType == 102 or data.subType == 103 then
    it.ExploreStrengthTitle = ""
  else
    it.ExploreStrengthTitle = _T("tips_lobby_explore_addition")
    data.refitRatio = data.refitRatio or 0
    if data.ratio and (data.ratio ~= 0 or data.refitRatio ~= 0) then
      it:SetExploreStrength(_T("tips_abilities_Damage"), "+" .. math.floor(data.ratio * 10000) / 100 .. "%", "(+" .. math.floor(data.refitRatio * 10000) / 100 .. "%)")
    end
  end
  it:SetTitle(GetIcon(data.resource), _L(data.display), GetGradeColor(data.grade))
  it.GradeImage = GetGradeImage(data.grade)
  it.Summary = _T("tips_abilities_Power") .. " " .. data.battleForce
  if data.refitedNum and 0 < data.refitedNum then
    it.LevelImage = GetLevelImage(data.refitedNum)
    it.SummaryLevel = _T("UI_enhance_enhance_grade")
  else
    it.SummaryLevel = nil
  end
  if data.canEquip == "Y" then
    it.State = data.isEquip == "Y" and _T("tips_common_additional_tips6") or _T("tips_common_additional_tips7")
  else
    it.State = ""
  end
  it:SetInfo(_T("tips_abilities_Character_Level"), _Value(_T("tips_abilities_Lv_num_and_above"), {
    data.level
  }), data.level > ComFuc.globalLV and red or white)
  it:SetInfo(_T("tips_abilities_Class_Requirement"), GetOccupation(data.occupation))
  it:SetInfo(_T("tips_abilities_Item_Type"), GetSubType(data.type, data.subType), white)
  it:SetInfo(_T("tips_abilities_Binding_State"), GetBind(data.isBind, data.bindType), white)
  if data.unitType then
    local k, v, c = GetRemain(data.unitType, data.remain, data.unit)
    it:SetInfo(k, v, c)
  end
  if 2 == data.isLock and data.lockExpireTime and data.lockTime.lockTime then
    local x, y = GetLockedTime(data.lockExpireTime, data.now)
    local z
    x, y, z = GetRemain(x, y, data.unit)
    it:SetInfo(_T("tips_common_ready_unlock_time"), y, z)
  end
  it:SetPerformance(1, _T("tips_abilities_Quality"), GetGradeText(data.grade), GetGradeColor(data.grade))
  if use_desc then
    it.UseDesc = _T("tips_lobby_Common_Desc1")
  end
end
tip_t[3].text = _T("button_common_Item")
tip_t[3].tip = function(data)
  it.SummaryLevel = nil
  if data.ventureForce and data.ventureForce > 0 then
    it.SummaryAdvent = _T("tips_lobby_explore_strength_tips") .. " " .. math.floor(data.ventureForce)
  else
    it.SummaryAdvent = ""
  end
  it:SetTitle(GetIcon(data.resource), _L(data.display), GetGradeColor(data.grade))
  it.GradeImage = GetGradeImage(data.grade)
  it.Summary = ""
  if data.canEquip == "Y" then
    it.State = data.isEquip == "Y" and _T("tips_common_additional_tips6") or _T("tips_common_additional_tips7")
  else
    it.State = ""
  end
  it:SetInfo(_T("tips_abilities_Character_Level"), _Value(_T("tips_abilities_Lv_num_and_above"), {
    data.level
  }), data.level > ComFuc.globalLV and red or white)
  it:SetInfo(_T("tips_abilities_Class_Requirement"), GetOccupation(data.occupation))
  it:SetInfo(_T("tips_abilities_Item_Type"), GetSubType(data.type, data.subType), white)
  it:SetInfo(_T("tips_abilities_Binding_State"), GetBind(data.isBind, data.bindType), white)
  if data.unitType then
    local k, v, c = GetRemain(data.unitType, data.remain, data.unit)
    it:SetInfo(k, v, c)
  end
  if 2 == data.isLock and data.lockExpireTime and data.lockTime.lockTime then
    local x, y = GetLockedTime(data.lockExpireTime, data.now)
    local z
    x, y, z = GetRemain(x, y, data.unit)
    it:SetInfo(_T("tips_common_ready_unlock_time"), y, z)
  end
  it:SetPerformance(1, _T("tips_abilities_Quality"), GetGradeText(data.grade), GetGradeColor(data.grade))
  it:SetEffect(GetType(data.type) .. _T("UI_mission_additional_string_044"), _L(data.description), _L(data.effect))
  if use_desc then
    it.UseDesc = _T("tips_lobby_Common_Desc1")
  end
end
tip_t[4].text = _T("button_common_Gesture")
local tip_t[4].tip, GetAvatarPerformance = function(data)
  it.SummaryLevel = nil
  if data.ventureForce and data.ventureForce > 0 then
    it.SummaryAdvent = _T("tips_lobby_explore_strength_tips") .. " " .. math.floor(data.ventureForce)
  else
    it.SummaryAdvent = ""
  end
  it:SetTitle(GetIcon(data.resource), _L(data.display), white)
  it.GradeImage = GetGradeImage(data.grade)
  it.Summary = ""
  if data.canEquip == "Y" then
    it.State = data.isEquip == "Y" and _T("tips_common_additional_tips6") or _T("tips_common_additional_tips7")
  else
    it.State = ""
  end
  it:SetInfo(_T("tips_abilities_Item_Type"), GetSubType(data.type, data.subType), white)
  it:SetInfo(_T("tips_abilities_Binding_State"), GetBind(data.isBind, data.bindType), white)
  if data.unitType then
    local k, v, c = GetRemain(data.unitType, data.remain, data.unit)
    it:SetInfo(k, v, c)
  end
  if 2 == data.isLock and data.lockExpireTime and data.lockTime.lockTime then
    local x, y = GetLockedTime(data.lockExpireTime, data.now)
    local z
    x, y, z = GetRemain(x, y, data.unit)
    it:SetInfo(_T("tips_common_ready_unlock_time"), y, z)
  end
  it:SetEffect(GetType(data.type) .. _T("UI_mission_additional_string_044"), _L(data.description), _L(data.effect))
  if use_desc then
    it.UseDesc = _T("tips_lobby_Common_Desc1")
  end
end, tip_t[4]

function GetAvatarPerformance(v)
  if v[2] then
    return v[1] + v[2]
  else
    return v[1]
  end
end

tip_t[5].text = _T("button_common_Avatar_Card")
tip_t[5].tip = function(data)
  it:SetTitle(nil, data.isSys and _L(data.display) or _LL(data.display), GetGradeColor(data.grade))
  it.GradeImage = GetGradeImage(data.grade)
  it.SubType = data.subType
  if data.canEquip == "Y" then
    it.State = data.isEquip == "Y" and _T("tips_common_additional_tips6") or _T("tips_common_additional_tips7")
  else
    it.State = ""
  end
  it.IsCard = true
  if ptr_cast(game.CurrentState, "Client.StateLobby") or ptr_cast(game.CurrentState, "Client.StateBalance") then
    ComFuc.SetPersonCardData(data.avatar, 16, data.position)
  else
    ComFuc.SetPersonCardDataARoom(data.avatar, 8, data.position)
  end
  it:SetInfo(_T("tips_abilities_Item_Type"), GetType(data.type), white)
  it:SetInfo(_T("tips_abilities_Binding_State"), GetBind(data.isBind, data.bindType), white)
  if data.unitType then
    local k, v, c = GetRemain(data.unitType, data.remain, data.unit)
    it:SetInfo(k, v, c)
  end
  if 2 == data.isLock and data.lockExpireTime and data.lockTime.lockTime then
    local x, y = GetLockedTime(data.lockExpireTime, data.now)
    local z
    x, y, z = GetRemain(x, y, data.unit)
    it:SetInfo(_T("tips_common_ready_unlock_time"), y, z)
  end
  if data.popularity then
  end
  data.staminaGem = data.staminaGem or 0
  data.stamina = data.stamina or 0
  data.armorGem = data.armorGem or 0
  data.armor = data.armor or 0
  data.cureQuantityGem = data.cureQuantityGem or 0
  data.cureQuantity = data.cureQuantity or 0
  data.recoveryGem = data.recoveryGem or 0
  data.recovery = data.recovery or 0
  it:SetCardAttribs(_T("tips_lobby_Staminatip"), "" .. data.staminaGem, "+" .. math.floor(data.stamina * 10000) / 100 .. "%")
  it:SetCardAttribs(_T("tips_lobby_Amortips"), "" .. data.armorGem, "+" .. math.floor(data.armor * 10000) / 100 .. "%")
  it:SetCardAttribs(_T("tips_lobby_Vitalitytips"), "" .. data.cureQuantityGem, "+" .. math.floor(data.cureQuantity * 10000) / 100 .. "%")
  it:SetCardAttribs(_T("tips_abilities_Recovery"), "" .. data.recoveryGem, "+" .. math.floor(data.recovery * 10000) / 100 .. "%")
  it:SetPerformance(1, _T("tips_abilities_Quality"), GetGradeText(data.grade), GetGradeColor(data.grade))
  if data.slots then
    table.sort(data.slots, function(t1, t2)
      return t1.num < t2.num
    end)
    local battleForce = 0
    for _, v in ipairs(data.slots) do
      if v.isEnable == "Y" then
        if v.sid ~= "0" then
          if ComFuc.globalLV >= v.level then
            battleForce = battleForce + v.battleForce
            it:SetSlot(true, GetGradeImage(v.grade), GetIcon(v.resource), _L(v.effect), white)
          else
            it:SetSlot(true, GetGradeImage(v.grade), GetIcon(v.resource), _L(v.effect) .. " " .. _Value(_T("tips_abilities_Lv_num_and_above"), {
              v.level
            }), red)
          end
        else
          it:SetSlot(false, nil, nil, "", white)
        end
      end
    end
    if 0 < battleForce then
      it.Summary = _T("tips_abilities_Power") .. " " .. battleForce
    else
      it.Summary = ""
    end
    if data.cardVentureForce and 0 < data.cardVentureForce then
      it.SummaryAdvent = _T("tips_lobby_explore_strength_tips") .. " " .. math.floor(data.cardVentureForce)
    else
      it.SummaryAdvent = ""
    end
    it.LevelText = nil
    if data.level and 0 < data.level then
      it.LevelImage = Gui.Image("ui/skinF/skin_tooltips_chuancheng.tga", Vector4(0, 0, 0, 0))
      it.TextureFont = SkinF.level_number_2
      it.LevelText = data.level .. ""
      it.SummaryLevel = _T("UI_common_chuancheng_Lv")
    else
      it.SummaryLevel = nil
    end
  end
  if data.sysAvatarPlus then
    local bEmpty = true
    local p = {
      "",
      "",
      "",
      ""
    }
    for i, v in ipairs(data.sysAvatarPlus) do
      bEmpty = false
      if v.property == "stamina" then
        p[i] = _T("tips_lobby_Staminatip")
      elseif v.property == "armor" then
        p[i] = _T("tips_lobby_Amortips")
      elseif v.property == "cureQuantity" then
        p[i] = _T("tips_lobby_Vitalitytips")
      elseif v.property == "recovery" then
        p[i] = _T("tips_abilities_Recovery")
      end
    end
    it.Attribute1 = p[1]
    it.Attribute2 = p[2]
    it.Attribute3 = p[3]
    it.Attribute4 = p[4]
    if bEmpty then
      it.IniherriteAttribute = ""
    else
      it.IniherriteAttribute = _T("UI_lobby_inherit_property")
    end
  end
  if data.skillDisplayName and data.skillDisplayName ~= "" and data.skillDescription and data.skillDescription ~= "" then
    it:SetEffect(_T("UI_mission_Hero") .. _T("button_common_Skill") .. _T("UI_mission_additional_string_044"), _L(data.skillDisplayName) .. ":" .. _L(data.skillDescription))
  end
  if data.designer == SelectCharacter.role_text or data.designer == "msgbox_common_conditionkey_146" then
    it:SetEffect(GetType(data.type) .. _T("UI_mission_additional_string_044"), _Value(_T("msgbox_common_num_1152"), {
      _L(data.designer)
    }))
  elseif data.designer == "{msgbox_common_conditionkey_146}" then
    it:SetEffect(GetType(data.type) .. _T("UI_mission_additional_string_044"), _Value(_T("msgbox_common_num_1152"), {
      _LL(data.designer)
    }))
  else
    it:SetEffect(GetType(data.type) .. _T("UI_mission_additional_string_044"), _Value("{0}", {
      data.isSys and _L(data.designer) or _LL(data.designer)
    }))
  end
  if use_desc then
    it.UseDesc = _T("tips_lobby_Common_Desc1")
  end
end
tip_t[6].text = _T("button_common_Avatar_Card")
tip_t[6].tip = function(data)
  tip_t[5].tip(data)
end
tip_t[8].text = _T("UI_inGame_pet_string_01")
tip_t[8].tip = function(data)
  it.SummaryLevel = nil
  if data.ventureForce and data.ventureForce > 0 then
    it.SummaryAdvent = _T("tips_lobby_explore_strength_tips") .. " " .. math.floor(data.ventureForce)
  else
    it.SummaryAdvent = ""
  end
  local disp_name = data.name
  if disp_name == nil then
    disp_name = _T(data.displayName)
  else
    disp_name = ComFuc.GetPetDisplayName(disp_name)
  end
  it:SetTitle(GetIcon(data.icon), disp_name, GetGradeColor(data.grade))
  it.GradeImage = GetGradeImage(data.grade)
  it.Summary = _T("tips_abilities_Power") .. " " .. data.battleForce
  if data.isEquipped then
    if data.isEquipped == "Y" then
      it.State = _T("UI_pet_switch_02")
    else
      it.State = _T("UI_pet_switch_03")
    end
  else
    it.State = ""
  end
  it:SetInfo(_T("tips_abilities_Character_Level"), _Value(_T("tips_abilities_Lv_num_and_above"), {
    data.level
  }), data.level > ComFuc.globalLV and red or white)
  it:SetInfo(_T("tips_abilities_Class_Requirement"), GetOccupation(data.occupation))
  it:SetInfo(_T("tips_abilities_Item_Type"), GetSubType(data.type, data.subType), white)
  it:SetInfo(_T("tips_abilities_Binding_State"), GetBind(data.isBind, data.bindType), white)
  if data.unitType == 2 and data.unit and data.price == nil then
    local iMood = data.unit
    if iMood < 0 then
      iMood = 0
    end
    if 100 <= iMood then
      iMood = 99
    end
    local iMoodLevel = math.floor(iMood / 25) + 1
    it:SetInfoWithIcon(_T("UI_pet_function_12"), [[
a
b]], white, SkinF.personalInfo_pet_mood_icon[iMoodLevel])
  end
  it:SetPerformance(1, _T("tips_abilities_Quality"), GetGradeText(data.grade), GetGradeColor(data.grade))
  if data.isNoble == "Y" then
    it:SetPerformance(1, _T("UI_common_identity_01"), _T("UI_common_identity_02"), ARGB(255, 255, 255, 0))
  else
    it:SetPerformance(1, _T("UI_common_identity_01"), _T("tips_lobby_Common_Desc8"), ARGB(255, 255, 255, 255))
  end
  it:SetEffect(GetType(data.type) .. _T("UI_mission_additional_string_044"), _T(data.description), _T(data.effect))
  if use_desc then
    it.UseDesc = _T("UI_common_mouse_left_01")
  end
end
tip_t[9].text = _T("button_common_Skill")
tip_t[9].tip = function(data)
  it.SummaryLevel = nil
  if data.ventureForce and data.ventureForce > 0 then
    it.SummaryAdvent = _T("tips_lobby_explore_strength_tips") .. " " .. math.floor(data.ventureForce)
  else
    it.SummaryAdvent = ""
  end
  local skill_1 = data.skills[1]
  local skill_2 = data.skills[2]
  it:SetTitle(GetIcon(skill_1.resource), _L(skill_1.displayName), white)
  it.GradeImage = nil
  it.Summary = ""
  it:SetInfo(_T("UI_common_Skill_Level"), _Value(_T("tips_abilities_Lv_num_and_above"), {
    skill_1.level
  }), white)
  it:SetEffect(GetType(data.type) .. _T("tips_common_additional_tips1"), _L(skill_1.description), _L(skill_1.effect))
  if skill_1.isMaximum ~= "Y" then
    it:SetEffect(_T("UI_common_Next_Level"), _L(""), _L(skill_2.effect))
  end
end
tip_t[10].text = _T("button_common_Skill")
local tip_t[10].tip, GetOutput = function(data)
  tip_t[1].tip(data)
end, tip_t[10]
local GetOutput, GetCriticalRate = function(v)
  return v[1], white, v[2] and format("(+%d)", v[2]), v[3] and format("(+%d)", v[3])
end, function(data)
  tip_t[1].tip(data)
end
local GetCriticalRate, GetFireSpeed = function(v)
  return format("%.2f%%", v[1] * 100), white, v[2] and format("(+%.2f%%)", v[2] * 100), v[3] and format("(+%.2f%%)", v[3] * 100)
end, "button_common_Skill"
local GetFireSpeed, GetAttackSpeed = function(v)
  return format("%.2f", 100 * (v[1] - 2) / -1.9), white, v[2] and format("(+%d)", 100 * v[2]), v[3] and format("(+%.2f)", (2 - v[1]) / 1.9 * 100 * v[3] / v[1])
end, _T("tips_abilities_Loot_Bind")
local GetAttackSpeed, GetShootSpread = function(v)
  return format("%.2f", 100 * (v[1] - 5) / -4.9), white, v[2] and format("(+%d)", 100 * v[2]), v[3] and format("(+%.2f)", (5 - v[1]) / 4.9 * 100 * v[3] / v[1])
end, _T("tips_abilities_Loot_Bind")
local GetShootSpread, GetAmmoOneClip = function(v)
  return format("%.2f", 100 * (v[1] - 2) / -1.99), white, v[2] and format("(+%d)", 100 * v[2]), v[3] and format("(+%.2f)", (2 - v[1]) / 1.99 * 100 * v[3] / v[1])
end, _T("tips_abilities_Loot_Bind")

function GetAmmoOneClip(v)
  return v[1], white, v[2] and format("(+%d)", v[2] * 200), v[3] and format("(+%d)", v[3])
end

tip_st[2][1].text = _T("tips_abilities_Rifle")
tip_st[2][1].tip = function(data)
  tip_t[2].tip(data)
  it:SetPerformance(1, _T("tips_abilities_Damage"), GetOutput(data.output))
  it:SetPerformance(1, _T("tips_abilities_Critical_Rate"), GetCriticalRate(data.criticalRate))
  it:SetPerformance(1, _T("tips_abilities_Firing_Rate"), GetFireSpeed(data.fireSpeed))
  it:SetPerformance(1, _T("tips_abilities_Accuracy"), GetShootSpread(data.shootSpread))
  it:SetPerformance(1, _T("tips_abilities_Ammunition"), GetAmmoOneClip(data.ammoOneClip))
  if _L(data.description) and #_L(data.description) > 0 then
    it:SetEffect(GetType(data.type) .. _T("UI_mission_additional_string_044"), _L(data.description), _L(data.effect))
  end
end
tip_st[2][2].text = _T("tips_abilities_Sniper_Rifle")
tip_st[2][2].tip = function(data)
  tip_st[2][1].tip(data)
end
tip_st[2][3].text = _T("UI_common_M_G")
tip_st[2][3].tip = function(data)
  tip_st[2][1].tip(data)
end
tip_st[2][4].text = _T("tips_abilities_Shotgun")
tip_st[2][4].tip = function(data)
  data.output[1] = data.output[1] * 8
  if data.output[2] then
    data.output[2] = data.output[2] * 8
  end
  if data.output[3] then
    data.output[3] = data.output[3] * 8
  end
  tip_st[2][1].tip(data)
end
tip_st[2][5].text = _T("tips_abilities_Pistol")
local tip_st[2][5].tip, GetExplodeDistance = function(data)
  tip_st[2][1].tip(data)
end, tip_st[2][5]
local GetExplodeDistance, GetAttackDistance = function(v)
  return format(_T("UI_lobby_float_m_01"), v[1]), white, v[2] and format(_T("UI_common_float_m"), v[2] * 10), v[3] and format("(+%.2f)", v[3])
end, function(data)
  tip_st[2][1].tip(data)
end

function GetAttackDistance(v)
  return format(_T("UI_lobby_float_m_01"), v[1]), white, v[2] and format(_T("UI_common_float_m"), v[2] * 5), v[3] and format("(+%.2f)", v[3])
end

tip_st[2][6].text = _T("tips_abilities_Knife")
local tip_st[2][6].tip, GetExplodeTime = function(data)
  tip_t[2].tip(data)
  it:SetPerformance(1, _T("tips_abilities_Damage"), GetOutput(data.output))
  it:SetPerformance(1, _T("tips_abilities_Critical_Rate"), GetCriticalRate(data.criticalRate))
  it:SetPerformance(1, _T("tips_abilities_Attack_Speed"), GetAttackSpeed(data.fireSpeed))
  it:SetPerformance(1, _T("tips_common_additional_tips3"), GetAttackDistance(data.distance))
  if _L(data.description) and #_L(data.description) > 0 then
    it:SetEffect(GetType(data.type) .. _T("UI_mission_additional_string_044"), _L(data.description), _L(data.effect))
  end
end, tip_st[2][6]

function GetExplodeTime(v)
  return format(_T("UI_common_float_s"), v[1]), white, v[2] and fomrat(_T("UI_common_float_s"), v[2] * 5), v[3] and fomrat("(+%.2f)", v[3])
end

tip_st[2][10].text = _T("tips_abilities_Grenade")
local tip_st[2][10].tip, GetCoolDown = function(data)
  tip_t[2].tip(data)
  it:SetPerformance(1, _T("tips_abilities_Damage"), GetOutput(data.output))
  it:SetPerformance(1, _T("tips_abilities_Critical_Rate"), GetCriticalRate(data.criticalRate))
  it:SetPerformance(1, _T("tips_abilities_Blast_Radius"), GetExplodeDistance(data.distance))
  it:SetPerformance(1, _T("tips_abilities_Detonation_Time"), GetExplodeTime(data.explodeTime))
  if _L(data.description) and #_L(data.description) > 0 then
    it:SetEffect(GetType(data.type) .. _T("UI_mission_additional_string_044"), _L(data.description), _L(data.effect))
  end
end, tip_st[2][10]

function GetCoolDown(v)
  return format(_T("UI_common_float_s"), v[1]), white, v[2] and format(_T("UI_common_float_s"), v[2] * 5), v[3] and format("(-%.2f)", v[3])
end

tip_st[2][11].text = _T("tips_abilities_Bazooka")
tip_st[2][11].tip = function(data)
  tip_t[2].tip(data)
  it:SetPerformance(1, _T("tips_abilities_Damage"), GetOutput(data.output))
  it:SetPerformance(1, _T("tips_abilities_Critical_Rate"), GetCriticalRate(data.criticalRate))
  it:SetPerformance(1, _T("tips_abilities_Blast_Radius"), GetExplodeDistance(data.distance))
  it:SetPerformance(1, _T("tips_abilities_Reloading_Time"), GetCoolDown(data.coolDown))
  if _L(data.description) and #_L(data.description) > 0 then
    it:SetEffect(GetType(data.type) .. _T("UI_mission_additional_string_044"), _L(data.description), _L(data.effect))
  end
end
tip_st[2][12].text = _T("tips_abilities_Bow")
tip_st[2][12].tip = function(data)
  tip_t[2].tip(data)
  it:SetPerformance(1, _T("tips_abilities_Damage"), GetOutput(data.output))
  it:SetPerformance(1, _T("tips_abilities_Critical_Rate"), GetCriticalRate(data.criticalRate))
  it:SetPerformance(1, _T("tips_abilities_Blast_Radius"), GetExplodeDistance(data.distance))
  it:SetPerformance(1, _T("tips_abilities_Reloading_Time"), GetCoolDown(data.coolDown))
  if _L(data.description) and #_L(data.description) > 0 then
    it:SetEffect(GetType(data.type) .. _T("UI_mission_additional_string_044"), _L(data.description), _L(data.effect))
  end
end
tip_st[2][13].text = _T("tips_abilities_Shield_Weapon")
tip_st[2][13].tip = function(data)
  tip_st[2][6].tip(data)
end
tip_st[2][14].text = _T("UI_datalist_m32_type")
tip_st[2][14].tip = function(data)
  tip_t[2].tip(data)
  it:SetPerformance(1, _T("tips_abilities_Damage"), GetOutput(data.output))
  it:SetPerformance(1, _T("tips_abilities_Critical_Rate"), GetCriticalRate(data.criticalRate))
  it:SetPerformance(1, _T("tips_abilities_Firing_Rate"), GetFireSpeed(data.fireSpeed))
  it:SetPerformance(1, _T("tips_abilities_Blast_Radius"), GetExplodeDistance(data.distance))
  it:SetPerformance(1, _T("tips_abilities_Ammunition"), GetAmmoOneClip(data.ammoOneClip))
  if _L(data.description) and #_L(data.description) > 0 then
    it:SetEffect(GetType(data.type) .. _T("UI_mission_additional_string_044"), _L(data.description), _L(data.effect))
  end
end
tip_st[2][15].text = _T("UI_datalist_penwuqi_type")
tip_st[2][15].tip = function(data)
  tip_t[2].tip(data)
  it:SetPerformance(1, _T("tips_abilities_Damage"), GetOutput(data.output))
  it:SetPerformance(1, _T("tips_abilities_Critical_Rate"), GetCriticalRate(data.criticalRate))
  it:SetPerformance(1, _T("tips_abilities_Firing_Rate"), GetFireSpeed(data.fireSpeed))
  it:SetPerformance(1, _T("tips_common_additional_tips3"), GetExplodeDistance(data.distance))
  it:SetPerformance(1, _T("tips_abilities_Ammunition"), GetAmmoOneClip(data.ammoOneClip))
  if _L(data.description) and #_L(data.description) > 0 then
    it:SetEffect(GetType(data.type) .. _T("UI_mission_additional_string_044"), _L(data.description), _L(data.effect))
  end
end
tip_st[2][16].text = _T("UI_datalist_nu_type")
tip_st[2][16].tip = function(data)
  tip_t[2].tip(data)
  it:SetPerformance(1, _T("tips_abilities_Damage"), GetOutput(data.output))
  it:SetPerformance(1, _T("tips_abilities_Critical_Rate"), GetCriticalRate(data.criticalRate))
  it:SetPerformance(1, _T("tips_abilities_Firing_Rate"), GetFireSpeed(data.fireSpeed))
  it:SetPerformance(1, _T("tips_abilities_Ammunition"), GetAmmoOneClip(data.ammoOneClip))
  if _L(data.description) and #_L(data.description) > 0 then
    it:SetEffect(GetType(data.type) .. _T("UI_mission_additional_string_044"), _L(data.description), _L(data.effect))
  end
end
tip_st[2][101].text = _T("tips_common_additional_tips4")
tip_st[2][101].tip = function(data)
  it:SetTitle(GetIcon(data.resource), data.guildName .. _T("tips_common_additional_tips5"), GetGradeColor(data.grade))
  it.Summary = _T("tips_abilities_Power") .. data.battleForce
  if data.ventureForce and data.ventureForce > 0 then
    it.SummaryAdvent = _T("tips_lobby_explore_strength_tips") .. " " .. math.floor(data.ventureForce)
  else
    it.SummaryAdvent = ""
  end
  if data.canEquip == "Y" then
    it.State = data.isEquip == "Y" and _T("tips_common_additional_tips6") or _T("tips_common_additional_tips7")
  else
    it.State = ""
  end
  it.GradeImage = GetGradeImage(data.grade)
  it:SetInfo(_T("tips_abilities_Binding_State"), GetBind(data.isBind, data.bindType), white)
  it:SetPerformance(1, _T("tips_abilities_Quality"), GetGradeText(data.grade), GetGradeColor(data.grade))
  it:SetEffect(_T("tips_abilities_Item_Description"), _L(data.description), _L(data.effect))
end
tip_st[2][102].text = _T("tips_abilities_Equipment_for_back")
local tip_st[2][102].tip, PlusMap = function(data)
  tip_t[2].tip(data)
  it:SetEffect(_T("tips_abilities_Item_Description"), _L(data.description), _L(data.effect))
end, tip_st[2][102]

function PlusMap(data)
  local temp1, temp2
  if data then
    for i = 1, #data do
      temp1 = nil
      if "stamina" == data[i].property then
        temp1 = "+" .. data[i].value .. _L("tips_lobby_Staminatip")
      elseif "recovery" == data[i].property then
        temp1 = "+" .. data[i].value .. _L("tips_abilities_Recovery")
      elseif "cureQuantity" == data[i].property then
        temp1 = "+" .. data[i].value .. _L("tips_lobby_Vitalitytips")
      elseif "arp" == data[i].property then
        temp1 = "+" .. data[i].value .. _L("tips_datalist_Penetration")
      elseif "armor" == data[i].property then
        temp1 = "+" .. data[i].value .. _L("tips_lobby_Amortips")
      end
      if temp2 then
        temp2 = temp2 .. "\n" .. temp1
      else
        temp2 = temp1
      end
    end
  end
  return temp2
end

tip_st[2][103].text = _T("tips_abilities_Ring_Amor")
tip_st[2][103].tip = function(data)
  tip_t[2].tip(data)
  data.ratio = data.ratio or 0
  local plusMap = PlusMap(data.plusMap)
  local effectStr = _L(plusMap)
  if data.ratio ~= 0 then
    local ratioNum = 100 * data.ratio
    local _, repeatTime = effectStr.gsub(effectStr, "+", "+")
    local setRatioNum = "        "
    for i = 1, repeatTime do
      setRatioNum = setRatioNum .. "+" .. ratioNum .. "%"
      if i ~= repeatTime then
        setRatioNum = setRatioNum .. "\n" .. "        "
      end
    end
    it:SetEffect(_T("tips_abilities_Item_Description"), _L(data.description), _L(plusMap), setRatioNum)
  else
    it:SetEffect(_T("tips_abilities_Item_Description"), _L(data.description), _L(plusMap))
  end
end
tip_st[3][100].text = _T("tips_common_additional_tips8")
tip_st[3][100].tip = function(data)
  tip_t[3].tip(data)
end
tip_st[3][101].text = _T("id_datalist_Bandage")
tip_st[3][101].tip = function(data)
  tip_t[3].tip(data)
end
tip_st[3][102].text = _T("tips_abilities_Pharmacy")
tip_st[3][102].tip = function(data)
  tip_t[3].tip(data)
end
tip_st[3][103].text = _T("tips_abilities_Food")
tip_st[3][103].tip = function(data)
  tip_t[3].tip(data)
end
tip_st[3][104].text = _T("UI_common_Skill_Enhancement_Manual")
tip_st[3][104].tip = function(data)
  tip_t[3].tip(data)
end
tip_st[3][105].text = _T("tips_abilities_Device")
tip_st[3][105].tip = function(data)
  tip_t[3].tip(data)
end
tip_st[3][106].text = _T("tips_abilities_Bonus_Card")
tip_st[3][106].tip = function(data)
  tip_t[3].tip(data)
end
tip_st[3][107].text = _T("tips_abilities_VIP")
tip_st[3][107].tip = function(data)
  tip_t[3].tip(data)
end
tip_st[3][108].text = _T("tips_abilities_Bag_Type")
tip_st[3][108].tip = function(data)
  tip_t[3].tip(data)
end
tip_st[3][109].text = _T("tips_abilities_Bag_Type")
tip_st[3][109].tip = function(data)
  tip_t[3].tip(data)
end
tip_st[3][110].text = _T("id_datalist_voucher_new")
tip_st[3][110].tip = function(data)
  tip_t[3].tip(data)
end
tip_st[3][111].text = _T("UI_common_gift_02")
tip_st[3][111].tip = function(data)
  tip_t[3].tip(data)
end
tip_st[3][112].text = _T("UI_common_blueprint_01")
tip_st[3][112].tip = function(data)
  tip_t[3].tip(data)
end
tip_st[3][200].text = _T("tips_common_additional_tips9")
tip_st[3][200].tip = function(data)
  tip_t[3].tip(data)
end
tip_st[3][300].text = _T("tips_store_Enhancement_Material_lottery")
tip_st[3][300].tip = function(data)
  tip_t[3].tip(data)
end
tip_st[3][301].text = _T("tips_lobby_Common_Desc24")
tip_st[3][301].tip = function(data)
  tip_t[3].tip(data)
end
tip_st[3][302].text = _T("tips_store_Gem_lottery")
tip_st[3][302].tip = function(data)
  tip_t[3].tip(data)
end
tip_st[3][303].text = _T("UI_common_make_07")
tip_st[3][303].tip = function(data)
  tip_t[3].tip(data)
end
tip_st[3][304].text = _T("UI_common_chip_01")
tip_st[3][304].tip = function(data)
  tip_t[3].tip(data)
end
tip_st[3][400].text = _T("tips_abilities_Treasure_Chest")
tip_st[3][400].tip = function(data)
  tip_t[3].tip(data)
end
tip_st[3][401].text = _T("tips_abilities_Key")
tip_st[3][401].tip = function(data)
  tip_t[3].tip(data)
end
tip_st[3][112001].text = _T("UI_common_make_03")
tip_st[3][112001].tip = function(data)
  tip_t[3].tip(data)
end
tip_st[5][1].text = _T("button_common_Avatar_Card")
tip_st[5][1].tip = function(data)
  tip_t[5].tip(data)
end
tip_st[5][2].text = _T("button_common_Avatar_Card")
tip_st[5][2].tip = function(data)
  tip_t[5].tip(data)
end
tip_st[8][501].text = _T("id_pet_breed_05")
tip_st[8][501].tip = function(data)
  tip_t[8].tip(data)
end
tip_st[8][502].text = _T("id_pet_breed_06")
tip_st[8][502].tip = function(data)
  tip_t[8].tip(data)
end
tip_st[8][503].text = _T("id_pet_breed_07")
tip_st[8][503].tip = function(data)
  tip_t[8].tip(data)
end
tip_st[8][504].text = _T("id_pet_breed_08")
tip_st[8][504].tip = function(data)
  tip_t[8].tip(data)
end
tip_st[8][505].text = _T("id_pet_breed_09")
tip_st[8][505].tip = function(data)
  tip_t[8].tip(data)
end
tip_st[8][506].text = _T("id_pet_breed_06")
local tip_st[8][506].tip, SetData = function(data)
  tip_t[8].tip(data)
end, tip_st[8][506]

function SetData(data)
  it:Reset()
  local t = data.type
  is_renew = data.isRenew
  Un_Bind = data.canUnbind
  local st = data.subType
  if st and 0 < st and tip_st[t][st] then
    tip_st[t][st].tip(data)
  else
    tip_t[t].tip(data)
  end
  it:Show()
end

function it.EventTimeUp(sender, e)
  rpc.safecall(rpc_interface, rpc_args, SetData, nil, 9)
end
