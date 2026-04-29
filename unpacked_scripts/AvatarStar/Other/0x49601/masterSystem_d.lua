module("MasterSystem", package.seeall)
local PI = 3.14159265358
local CircleBarR0 = 138.5
local ratio_A = 1.1
local ratio_B = 5
local ratio_C = 1.0E-4
local MAX_LEVEL = 5
local come_from_character = false
local rangeLocationNum = 0
local detailLocationNum = 0
local oldLevel = 0
local levelUp = false
local isFinish = false
local maxLocationAreaNum = 10
local masterLevel = 1
local rangeLocationIndex = 0
local detailLocationIndex = 0
local rangeLocation = {}
local detailLocation = {}
local attackCanSwitch = true
local defendCanSwitch = true
local mapId = 0
local skillId, activateTable
local isActivate = false
local tmp_mapId = 0
local shinyArrow
local shinyDuringTime = 0
local showTimer
local showIsFinished = false
local getMapTimer
local getMapFinished = false
local masterState = 0
local areaInfoTable = {}
local mapInfoTable = {}
local skillTable
local isAddition = {attack = true, defend = true}
local material1 = {
  kind = {},
  detail = {}
}
local material2 = {
  kind = {},
  detail = {}
}
local materialGold = {}
local guide_num = 0
local need_show_guide = true
local currentCircle = {
  red_attack = {
    OriginAngle = 0,
    CurrentAngle = 0,
    OffsetAngle = 0
  },
  blue_defend = {
    OriginAngle = 0,
    CurrentAngle = 0,
    OffsetAngle = 0
  }
}
local showSmallThing = {
  levelAccount = nil,
  expeditionAddition = nil,
  mapName = "",
  masterLevel = nil,
  attack = nil,
  defend = nil,
  need = 1000
}

function MemberList(i, bArea)
  if i == 0 then
    return
  end
  local ControlWidth, lcx, lcy, mun
  if bArea then
    ControlWidth = 130
    lcx = math.fmod(i - 1, 3) * 180
    lcy = 140 * (math.ceil(i / 3) - 1)
    num = 1
  else
    ControlWidth = 230
    lcx = math.fmod(i - 1, 2) * 245
    lcy = 140 * (math.ceil(i / 2) - 1)
    num = 2
  end
  local buttonName = "mb_" .. num .. "_" .. i
  return Gui.Control({
    Location = Vector2(lcx, lcy),
    Size = Vector2(ControlWidth, 130),
    BackgroundColor = ComFuc.colw,
    Skin = SkinF.master_main_background,
    ComFuc.MainTabBtn(buttonName, nil, Vector2(6, 6), Vector2(ControlWidth - 12, 118))
  })
end

ui = Gui.Create()({
  Gui.Control("main")({
    Size = Vector2(1126, 642),
    BackgroundColor = ARGB(0, 0, 0, 0),
    ComFuc.MainTabBtn("btn_copy_master", GetUTF8Text("UI_common_copy_master"), Vector2(9, 5), Vector2(129, 31), SkinF.level_master_btn, true),
    Gui.Control("master_background")({
      Location = Vector2(0, 36),
      Size = Vector2(1108, 582),
      BackgroundColor = ComFuc.colw,
      Skin = SkinF.master_main_background,
      Gui.ScrollableControl("area_select_scroll")({
        Size = Vector2(522, 145),
        Location = Vector2(35, 96),
        HScrollBarDisplay = "kHide",
        VScrollBarDisplay = "kVisible",
        VScrollBarWidth = 22,
        AutoScroll = true,
        AutoSize = true,
        AutoScrollMinSize = Vector2(566, 498),
        MemberList(1, true),
        MemberList(2, true),
        MemberList(3, true),
        MemberList(4, true),
        MemberList(5, true),
        MemberList(6, true),
        MemberList(7, true),
        MemberList(8, true),
        MemberList(9, true),
        MemberList(10, true)
      }),
      Gui.ScrollableControl("copy_select_scroll")({
        Size = Vector2(522, 153),
        Location = Vector2(35, 288),
        HScrollBarDisplay = "kHide",
        VScrollBarDisplay = "kVisible",
        VScrollBarWidth = 22,
        AutoScroll = true,
        AutoSize = true,
        AutoScrollMinSize = Vector2(566, 498),
        MemberList(1, false),
        MemberList(2, false),
        MemberList(3, false),
        MemberList(4, false),
        MemberList(5, false),
        MemberList(6, false),
        MemberList(7, false),
        MemberList(8, false),
        MemberList(9, false),
        MemberList(10, false)
      }),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_common_copy_master_total_grade"), Vector2(113, 18), Vector2(86, 26), 0, 16, ComFuc.coly, "kAlignCenterMiddle"),
      ComFuc.ComLabel(nil, GetUTF8Text("tips_lobby_explore_addition"), Vector2(110, 18), Vector2(314, 26), 0, 16, ComFuc.coly, "kAlignCenterMiddle"),
      ComFuc.ComLabel("master_total_grade", "", Vector2(43, 16), Vector2(216, 27), 0, 16, ARGB(255, 255, 0, 0), "kAlignLeftMiddle"),
      ComFuc.ComLabel("explore_strength_addition", "", Vector2(43, 16), Vector2(443, 27), 0, 16, ARGB(255, 255, 0, 0), "kAlignLeftMiddle"),
      ComFuc.ComLabel("area_select", GetUTF8Text("UI_common_select_area"), Vector2(136, 16), Vector2(46, 70), 0, 16, ComFuc.coly, "kAlignLeftMiddle"),
      ComFuc.ComLabel("copy_select", GetUTF8Text("UI_common_select_copy"), Vector2(136, 16), Vector2(46, 263), 0, 16, ComFuc.coly, "kAlignLeftMiddle"),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_common_copy_name_01"), Vector2(136, 18), Vector2(39, 470), 0, 16, ComFuc.coly, "kAlignLeftMiddle"),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_common_copy_master_grade"), Vector2(136, 18), Vector2(39, 492), 0, 16, ComFuc.coly, "kAlignLeftMiddle"),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_common_attack_master"), Vector2(136, 18), Vector2(39, 514), 0, 16, ComFuc.coly, "kAlignLeftMiddle"),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_common_defend_master"), Vector2(136, 18), Vector2(39, 536), 0, 16, ComFuc.coly, "kAlignLeftMiddle"),
      ComFuc.ComLabel("copy_name", "", Vector2(410, 18), Vector2(152, 470), 0, 16, ComFuc.colw, "kAlignLeftMiddle"),
      ComFuc.ComLabel("master_grade", "", Vector2(410, 18), Vector2(152, 492), 0, 16, ComFuc.colw, "kAlignLeftMiddle"),
      ComFuc.ComLabel("attack_master", "", Vector2(410, 18), Vector2(152, 514), 0, 16, ComFuc.colw, "kAlignLeftMiddle"),
      ComFuc.ComLabel("defend_master", "", Vector2(410, 18), Vector2(152, 536), 0, 16, ComFuc.colw, "kAlignLeftMiddle"),
      ComFuc.MainTabBtn("attack_switch_btn", nil, Vector2(598, 229), Vector2(100, 68), SkinF.attack_switch),
      ComFuc.MainTabBtn("defend_switch_btn", nil, Vector2(982, 229), Vector2(100, 68), SkinF.defend_switch),
      ComFuc.ComLabel("master_exp", "", Vector2(93, 15), Vector2(789, 28), 0, 16, ComFuc.coly, "kAlignCenterMiddle"),
      ComFuc.ComLabel("attack_addition_num", "", Vector2(35, 15), Vector2(728, 325), 0, 16, ARGB(255, 255, 0, 0), "kAlignCenterMiddle"),
      ComFuc.ComLabel("defend_addition_num", "", Vector2(35, 15), Vector2(913, 325), 0, 16, ComFuc.colb, "kAlignCenterMiddle"),
      Gui.Control("master_hecheng_box")({
        Skin = SkinF.master_hechengkuang,
        Location = Vector2(796, 144),
        Size = Vector2(80, 80),
        BackgroundColor = ComFuc.colw
      }),
      Gui.Control("skill_disable")({
        Location = Vector2(797, 145),
        Size = Vector2(78, 78),
        BackgroundColor = ComFuc.colw
      }),
      Gui.Control("skill_visible")({
        Location = Vector2(797, 145),
        Size = Vector2(78, 0),
        BackgroundColor = ComFuc.colw
      }),
      ComFuc.ComControl("ctr_attack_arrow", Vector2(22, 0), Vector2(636, 102), 255),
      ComFuc.ComControl("ctr_defend_arrow", Vector2(22, 0), Vector2(1018, 102), 255),
      Gui.Control("attack_arrow_bg")({
        Location = Vector2(632, 101),
        Size = Vector2(29, 106),
        BackgroundColor = ComFuc.colw,
        Skin = SkinF.arrow_icon_bg
      }),
      Gui.Control("defend_arrow_bg")({
        Location = Vector2(1014, 101),
        Size = Vector2(29, 106),
        BackgroundColor = ComFuc.colw,
        Skin = SkinF.arrow_icon_bg
      }),
      ComFuc.Mastermaterial("mastery", 1, Vector2(601, 402), 1),
      ComFuc.Mastermaterial("mastery", 2, Vector2(860, 402), 3),
      Gui.Control("disableMaterial")({
        Size = Vector2(494, 103),
        Location = Vector2(596, 398),
        BackgroundColor = ComFuc.colw,
        Skin = SkinF.induction_bg,
        Gui.Label({
          Location = Vector2(31, 17),
          Size = Vector2(432, 61),
          TextAlign = "kAlignLeftTop",
          AutoWrap = true,
          FontSize = 16,
          Text = GetUTF8Text("msgbox_enhance_master_desc")
        })
      }),
      ComFuc.ComButton("btn_master", nil, Vector2(161, 63), Vector2(888, 500), 16, false, true, SkinF.underground_city_master),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_common_master_cost"), Vector2(64, 18), Vector2(600, 521), 0, 16, colw),
      Gui.Control({
        Size = Vector2(100, 24),
        Location = Vector2(668, 516),
        BackgroundColor = ComFuc.colw,
        Skin = SkinF.master_gold_cost_bg,
        ComFuc.ComLabel("master_cost", "0", Vector2(90, 24), Vector2(0, 0), 0, 16, colw, "kAlignRightMiddle")
      }),
      ComFuc.ComControl(nil, Vector2(25, 25), Vector2(778, 515), 255, SkinF.shop_02),
      Gui.CircleContainer("red_part")({
        Location = Vector2(698, 58),
        BackgroundColor = ARGB(0, 12, 12, 0),
        IsClockWise = true,
        CircleBarR = CircleBarR0,
        Size = Vector2(CircleBarR0 * 2, CircleBarR0 * 2),
        OriginAngle = PI,
        CurrentAngle = 0,
        OffsetAngle = 0,
        CircleWidth = 11,
        Changing = false,
        RefreshTime = 0.5,
        CircleColor = ARGB(255, 255, 0, 0)
      }),
      Gui.CircleContainer("blue_part")({
        Location = Vector2(698, 58),
        BackgroundColor = ARGB(0, 12, 12, 0),
        IsClockWise = false,
        CircleBarR = CircleBarR0,
        Size = Vector2(CircleBarR0 * 2, CircleBarR0 * 2),
        OriginAngle = PI,
        CurrentAngle = 0,
        OffsetAngle = 0,
        CircleWidth = 11,
        Changing = false,
        RefreshTime = 0.5,
        CircleColor = ARGB(255, 0, 138, 255)
      }),
      Gui.CircleContainer("red_part_disable")({
        Location = Vector2(698, 58),
        BackgroundColor = ARGB(0, 12, 12, 0),
        IsClockWise = false,
        CircleBarR = CircleBarR0,
        Size = Vector2(CircleBarR0 * 2, CircleBarR0 * 2),
        OriginAngle = PI,
        CurrentAngle = 0,
        OffsetAngle = 0,
        CircleWidth = 11,
        Changing = false,
        RefreshTime = 0.5,
        CircleColor = ComFuc.coly
      }),
      Gui.CircleContainer("blue_part_disable")({
        Location = Vector2(698, 58),
        BackgroundColor = ARGB(0, 12, 12, 0),
        IsClockWise = false,
        CircleBarR = CircleBarR0,
        Size = Vector2(CircleBarR0 * 2, CircleBarR0 * 2),
        OriginAngle = PI,
        CurrentAngle = 0,
        OffsetAngle = 0,
        CircleWidth = 11,
        Changing = false,
        RefreshTime = 0.5,
        CircleColor = ComFuc.coly
      }),
      Gui.Control({
        Size = Vector2(CircleBarR0 * 2, CircleBarR0 * 2),
        Location = Vector2(698, 58),
        BackgroundColor = ComFuc.colw,
        Skin = SkinF.circle_around
      })
    }),
    ComFuc.ComButton("btn_set_active", GetUTF8Text("button_common_active_skill"), Vector2(100, 40), Vector2(786, 274), 16, false, true, SkinF.btn_set_active),
    ComFuc.ComControl("btn_set_active_disabled", Vector2(100, 40), Vector2(786, 274), 0),
    ComFuc.ComControl("attack_switch_btn_disabled", Vector2(100, 68), Vector2(598, 225), 0),
    ComFuc.ComControl("defend_switch_btn_disabled", Vector2(100, 68), Vector2(982, 225), 0),
    Gui.Control("skill_tip")({
      Location = Vector2(797, 181),
      Size = Vector2(78, 78),
      BackgroundColor = ComFuc.col0,
      EventMouseEnter = function(sender, e)
        if skillTable ~= nil then
          Tip.SetRpc("tip_sys_skill", {
            t = skillTable.type,
            sid = tonumber(skillTable.sid),
            level = tonumber(skillTable.level)
          })
          Tip.SetUseDescription(true)
          Tip.SetOwner(sender)
        end
      end
    })
  }),
  ComFuc.ComControl("coverControlmaster", Vector2(1600, 1200), Vector2(0, 0), 0)
})
ui.mastery_material_skin_1.Skin = SkinF.personalInfo_quality[1]
ui.mastery_material_skin_2.Skin = SkinF.personalInfo_quality[1]
ui.ctr_attack_arrow.BackgroundColor = ARGB(255, 255, 0, 0)
ui.ctr_defend_arrow.BackgroundColor = ARGB(255, 0, 138, 255)
ui.mastery_material_name_2.AutoWrap = true
ui.mastery_material_name_2.Size = Vector2(130, 60)
ui.mastery_refit_buy_2.Visible = false
ui.attack_switch_btn.ClickAudio = "button"
ui.defend_switch_btn.ClickAudio = "button"

function ui.attack_switch_btn.EventMouseEnter(sender, e)
  sender.Hint = GetUTF8Text("UI_enhance_attack_transform")
  sender.HintWidth = 150
end

function ui.attack_switch_btn_disabled.EventMouseEnter(sender, e)
  sender.Hint = GetUTF8Text("UI_enhance_attack_transform")
  sender.HintWidth = 150
end

function ui.defend_switch_btn.EventMouseEnter(sender, e)
  sender.Hint = GetUTF8Text("UI_enhance_defense_transform")
  sender.HintWidth = 150
end

function ui.defend_switch_btn_disabled.EventMouseEnter(sender, e)
  sender.Hint = GetUTF8Text("UI_enhance_defense_transform")
  sender.HintWidth = 150
end

local ui.btn_set_active_disabled.EventMouseEnter, ClearArrowDir = function(sender, e)
  if not isActivate then
    sender.Hint = GetUTF8Text("UI_enhance_skill_active")
    sender.HintWidth = 150
  end
end, ui.btn_set_active_disabled
local ClearArrowDir, DealArrowDir = function()
  ui.attack_arrow_bg.Skin = SkinF.arrow_icon_bg
  ui.defend_arrow_bg.Skin = SkinF.arrow_icon_bg
  ui.ctr_attack_arrow.Size = Vector2(0, 0)
  ui.ctr_defend_arrow.Size = Vector2(0, 0)
end, function(sender, e)
  if not isActivate then
    sender.Hint = GetUTF8Text("UI_enhance_skill_active")
    sender.HintWidth = 150
  end
end
local DealArrowDir, GetAngle = function()
  if ui.attack_switch_btn.PushDown then
    ui.defend_arrow_bg.Skin = SkinF.arrow_icon_bg_down
  else
    ui.defend_arrow_bg.Skin = SkinF.arrow_icon_bg
  end
  if ui.defend_switch_btn.PushDown then
    ui.attack_arrow_bg.Skin = SkinF.arrow_icon_bg_down
  else
    ui.attack_arrow_bg.Skin = SkinF.arrow_icon_bg
  end
  if not ui.attack_switch_btn.PushDown and not ui.defend_switch_btn.PushDown then
    ui.btn_master.Skin = SkinF.underground_city_master
  else
    ui.btn_master.Skin = SkinF.guild_041
  end
  ui.ctr_attack_arrow.Location = Vector2(636, 102)
  ui.ctr_attack_arrow.Size = Vector2(22, 98)
  ui.ctr_defend_arrow.Location = Vector2(1018, 102)
  ui.ctr_defend_arrow.Size = Vector2(22, 98)
end, "button"
local GetAngle, GetDisableAngle = function(change)
  currentCircle.red_attack.OffsetAngle = showSmallThing.attack / showSmallThing.need * 2 * PI
  currentCircle.blue_defend.OffsetAngle = showSmallThing.defend / showSmallThing.need * 2 * PI
  if change == false then
    currentCircle.red_attack.CurrentAngle = currentCircle.red_attack.OffsetAngle
    currentCircle.blue_defend.CurrentAngle = currentCircle.blue_defend.OffsetAngle
  end
end, 60
local GetDisableAngle, BeginMoving = function()
  ui.red_part_disable.OriginAngle = currentCircle.red_attack.OffsetAngle + PI
  if currentCircle.red_attack.OffsetAngle > PI then
    ui.red_part_disable.OriginAngle = currentCircle.red_attack.OffsetAngle - PI
  end
  ui.red_part_disable.OffsetAngle = 0
  ui.red_part_disable.CurrentAngle = currentCircle.red_attack.OffsetAngle - currentCircle.red_attack.CurrentAngle
  if currentCircle.red_attack.CurrentAngle > currentCircle.red_attack.OffsetAngle then
    ui.red_part_disable.IsClockWise = true
    ui.red_part_disable.CurrentAngle = currentCircle.red_attack.CurrentAngle - currentCircle.red_attack.OffsetAngle
  else
    ui.red_part_disable.IsClockWise = false
    ui.red_part_disable.CurrentAngle = currentCircle.red_attack.OffsetAngle - currentCircle.red_attack.CurrentAngle
  end
  ui.blue_part_disable.OriginAngle = PI - currentCircle.blue_defend.OffsetAngle
  if currentCircle.blue_defend.OffsetAngle > PI then
    ui.blue_part_disable.OriginAngle = 3 * PI - currentCircle.blue_defend.OffsetAngle
  end
  ui.blue_part_disable.OffsetAngle = 0
  ui.blue_part_disable.CurrentAngle = currentCircle.blue_defend.OffsetAngle - currentCircle.blue_defend.CurrentAngle
  if currentCircle.blue_defend.CurrentAngle > currentCircle.blue_defend.OffsetAngle then
    ui.blue_part_disable.IsClockWise = false
    ui.blue_part_disable.CurrentAngle = currentCircle.blue_defend.CurrentAngle - currentCircle.blue_defend.OffsetAngle
  else
    ui.blue_part_disable.IsClockWise = true
    ui.blue_part_disable.CurrentAngle = currentCircle.blue_defend.OffsetAngle - currentCircle.blue_defend.CurrentAngle
  end
end, 138
local BeginMoving, EndMoving = function()
  ui.red_part_disable.Changing = true
  ui.blue_part_disable.Changing = true
  ui.red_part.Changing = true
  ui.blue_part.Changing = true
end, 255
local EndMoving, ViewCircleCondition = function()
  ui.red_part_disable.Changing = false
  ui.blue_part_disable.Changing = false
  ui.red_part.Changing = false
  ui.blue_part.Changing = false
  ui.red_part_disable.OriginAngle = 0
  ui.red_part_disable.OffsetAngle = 0
  ui.red_part_disable.CurrentAngle = 0
  ui.blue_part_disable.OriginAngle = 0
  ui.blue_part_disable.OffsetAngle = 0
  ui.blue_part_disable.CurrentAngle = 0
end, ComFuc.ComControl("coverControlmaster", Vector2(1600, 1200), Vector2(0, 0), 0)
local ViewCircleCondition, DealAttackDefendBtn = function()
  if detailLocationIndex == 0 then
    ui.red_part.CurrentAngle = 0
    ui.red_part.OffsetAngle = 0
    ui.blue_part.CurrentAngle = 0
    ui.blue_part.OffsetAngle = 0
  else
    ui.red_part.CurrentAngle = currentCircle.red_attack.CurrentAngle
    ui.red_part.OffsetAngle = currentCircle.red_attack.OffsetAngle
    ui.blue_part.CurrentAngle = currentCircle.blue_defend.CurrentAngle
    ui.blue_part.OffsetAngle = currentCircle.blue_defend.OffsetAngle
  end
end, ComFuc.ComControl("coverControlmaster", Vector2(1600, 1200), Vector2(0, 0), 0)
local DealAttackDefendBtn, DealMaterialCanShow = function()
  ui.attack_switch_btn_disabled.Parent = ui.master_background
  ui.defend_switch_btn_disabled.Parent = ui.master_background
  attackCanSwitch = true
  defendCanSwitch = true
  if detailLocationIndex == 0 then
    attackCanSwitch = false
    defendCanSwitch = false
  end
  if showSmallThing.attack == nil or showSmallThing.attack >= showSmallThing.need then
    attackCanSwitch = false
  end
  if showSmallThing.defend == nil or showSmallThing.defend >= showSmallThing.need then
    defendCanSwitch = false
  end
  ui.attack_switch_btn.Enable = attackCanSwitch
  ui.defend_switch_btn.Enable = defendCanSwitch
  if attackCanSwitch then
    ui.attack_switch_btn_disabled.Parent = nil
  end
  if defendCanSwitch then
    ui.defend_switch_btn_disabled.Parent = nil
  end
  if not attackCanSwitch or not defendCanSwitch then
    ui.attack_switch_btn.PushDown = false
    ui.defend_switch_btn.PushDown = false
    DealArrowDir()
  end
end, ComFuc.ComControl("coverControlmaster", Vector2(1600, 1200), Vector2(0, 0), 0)
local DealMaterialCanShow, InitRangeLocation = function()
  if detailLocationIndex == 0 then
    ui.disableMaterial.Parent = ui.master_background
    ui.btn_master.Enable = false
  else
    ui.disableMaterial.Parent = nil
    ui.btn_master.Enable = true
  end
end, ComFuc.ComControl("coverControlmaster", Vector2(1600, 1200), Vector2(0, 0), 0)
local InitRangeLocation, InitDetailLocation = function()
  detailLocationIndex = 0
  detailLocationNum = 0
  for i = 1, rangeLocationNum do
    ui["mb_1_" .. i].PushDown = false
    ui["mb_1_" .. i].Skin = Gui.ButtonSkin({
      BackgroundImage = Gui.Image("ui/MapsAndBG/previewMaps/area/" .. areaInfoTable[i].resource .. ".tga", Vector4(0, 0, 0, 0))
    })
    ui["mb_1_" .. i].Parent.Skin = SkinF.master_map_bg[1]
  end
  for i = rangeLocationNum + 1, maxLocationAreaNum do
    ui["mb_1_" .. i].Parent.Parent = nil
  end
end, ComFuc.ComControl("coverControlmaster", Vector2(1600, 1200), Vector2(0, 0), 0)
local InitDetailLocation, DealSkill = function()
  for i = 1, detailLocationNum do
    ui["mb_2_" .. i].Parent.Parent = ui.copy_select_scroll
    ui["mb_2_" .. i].PushDown = false
    ui["mb_2_" .. i].Skin = Gui.ButtonSkin({
      BackgroundImage = Gui.Image("/ui/MapsAndBG/previewMaps/skinC_smallmap_" .. string.lower(mapInfoTable[i].name) .. ".tga", Vector4(0, 0, 0, 0))
    })
    ui["mb_2_" .. i].Parent.Skin = SkinF.master_map_bg[1]
  end
  for i = detailLocationNum + 1, maxLocationAreaNum do
    ui["mb_2_" .. i].Parent.Parent = nil
  end
  if detailLocationIndex and 0 < detailLocationIndex and detailLocationIndex <= detailLocationNum then
    ui["mb_2_" .. detailLocationIndex].PushDown = true
    ui["mb_2_" .. detailLocationIndex].Parent.Skin = SkinF.master_map_bg[2]
  end
  DealAttackDefendBtn()
end, ComFuc.ComControl("coverControlmaster", Vector2(1600, 1200), Vector2(0, 0), 0)
local DealSkill, DealSkillShow = function()
  if ui.skill_disable.Parent == nil then
    ui.skill_disable.Parent = ui.master_background
  end
  ui.skill_disable.Skin = Gui.ControlSkin({
    BackgroundImage = Gui.Image("ui/skinF/lobby/" .. skillTable.resource .. "_disabled.tga", Vector4(0, 0, 0, 0))
  })
end, ComFuc.ComControl("coverControlmaster", Vector2(1600, 1200), Vector2(0, 0), 0)
local DealSkillShow, ClearSkill = function()
  local height = 0
  if ui.skill_visible.Parent == nil then
    ui.skill_visible.Parent = ui.master_background
  end
  if showSmallThing and showSmallThing.masterLevel then
    height = 15.6 * showSmallThing.masterLevel
  else
    height = 0
  end
  ui.skill_visible.Location = Vector2(797, 223 - height)
  ui.skill_visible.Size = Vector2(78, height)
  ui.skill_visible.Skin = Gui.ControlSkin({
    BackgroundImage = Gui.Image("ui/skinF/lobby/" .. skillTable.resource .. ".tga", Vector4(0, 0, 0, height))
  })
end, ComFuc.ComControl("coverControlmaster", Vector2(1600, 1200), Vector2(0, 0), 0)
local ClearSkill, ClearArea = function()
  ui.skill_visible.Parent = nil
  ui.skill_disable.Parent = nil
end, ComFuc.ComControl("coverControlmaster", Vector2(1600, 1200), Vector2(0, 0), 0)
local ClearArea, GetMap = function()
  for i = 1, rangeLocationNum do
    areaInfoTable[i] = nil
  end
  rangeLocationNum = 0
  rangeLocationIndex = 0
  showIsFinished = false
  ClearSkill()
end, ComFuc.ComControl("coverControlmaster", Vector2(1600, 1200), Vector2(0, 0), 0)
local GetMap, ClearMap = function(data)
  skillTable = nil
  skillId = nil
  for _, v in ipairs(data.levelTmp) do
    if v.name ~= "null" then
      detailLocationNum = detailLocationNum + 1
      mapInfoTable[detailLocationNum] = v
    end
  end
  table.sort(mapInfoTable, function(t1, t2)
    return t1.levelId < t2.levelId
  end)
  for _, v in ipairs(data.configMap) do
    if v.property == "A" then
      ratio_A = v.value
    end
    if v.property == "B" then
      ratio_B = v.value
    end
    if v.property == "C" then
      ratio_C = v.value
    end
  end
  InitDetailLocation()
  getMapFinished = true
end, ComFuc.ComControl("coverControlmaster", Vector2(1600, 1200), Vector2(0, 0), 0)
local ClearMap, DealSkillActivate = function()
  for i = 1, detailLocationNum do
    mapInfoTable[i] = nil
  end
  ClearArrowDir()
  ClearSkill()
  skillTable = nil
  skillId = nil
  detailLocationNum = 0
  detailLocationIndex = 0
  ui.copy_name.Text = ""
  ui.master_grade.Text = ""
  ui.btn_set_active.Enable = false
  ui.btn_set_active.Visible = false
  ui.btn_set_active_disabled.Parent = nil
  ui.attack_master.Text = ""
  ui.attack_addition_num.Text = ""
  ui.defend_master.Text = ""
  ui.defend_addition_num.Text = ""
  ui.master_exp.Text = ""
  ui.master_cost.Text = "0"
  isAddition.attack = true
  isAddition.defend = true
  getMapFinished = false
end, ComFuc.ComControl("coverControlmaster", Vector2(1600, 1200), Vector2(0, 0), 0)
local DealSkillActivate, DealProperty = function()
  local isFound = false
  if activateTable then
    for _, v in ipairs(activateTable) do
      if v.id == skillId then
        isFound = true
        isActivate = v.activate == 1
        break
      end
    end
  end
  if not isFound then
    isActivate = false
  end
  if isActivate then
    ui.btn_set_active.Text = GetUTF8Text("button_common_actived_skill")
  else
    ui.btn_set_active.Text = GetUTF8Text("button_common_active_skill")
  end
end, ComFuc.ComControl("coverControlmaster", Vector2(1600, 1200), Vector2(0, 0), 0)
local DealProperty, GetArea = function()
  ui.copy_name.Text = GetUTF8Text(showSmallThing.mapName)
  ui.btn_set_active.Visible = true
  ui.btn_set_active_disabled.Parent = ui.main
  if showSmallThing.masterLevel then
    ui.master_grade.Text = GetMatchedUTF8Text("tips_abilities_Lv_num_and_above" .. "," .. tostring(showSmallThing.masterLevel))
    if showSmallThing.masterLevel == MAX_LEVEL and not isActivate then
      ui.btn_set_active.Enable = true
      ui.btn_set_active_disabled.Parent = nil
    else
      ui.btn_set_active.Enable = false
    end
  else
    ui.master_grade.Text = GetUTF8Text("msgbox_enhance_no_master")
    ui.btn_set_active.Enable = false
  end
  if showSmallThing.attack then
    local attackAdditionPercent = math.floor((showSmallThing.attack * ratio_A + ratio_B) * ratio_C * 10000) / 100 .. "%"
    ui.attack_master.Text = GetMatchedUTF8Text("msgbox_enhance_master_attack_point" .. "," .. tostring(showSmallThing.attack) .. "," .. attackAdditionPercent)
    ui.attack_addition_num.Text = tostring(showSmallThing.attack)
  else
    ui.attack_master.Text = ""
    ui.attack_addition_num.Text = ""
  end
  if showSmallThing.defend then
    local defendAdditionPercent = math.floor((showSmallThing.defend * ratio_A + ratio_B) * ratio_C * 10000) / 100 .. "%"
    ui.defend_master.Text = GetMatchedUTF8Text("msgbox_enhance_master_defense_point" .. "," .. tostring(showSmallThing.defend) .. "," .. defendAdditionPercent)
    ui.defend_addition_num.Text = tostring(showSmallThing.defend)
    ui.master_exp.Text = tostring(showSmallThing.attack + showSmallThing.defend) .. "/" .. tostring(showSmallThing.need)
  else
    ui.defend_master.Text = ""
    ui.defend_addition_num.Text = ""
    ui.master_exp.Text = ""
  end
end, ComFuc.ComControl("coverControlmaster", Vector2(1600, 1200), Vector2(0, 0), 0)
local GetArea, DealMaterial_1 = function(data)
  skillId = nil
  skillTable = nil
  rangeLocationNum = 0
  for _, v in ipairs(data.localList) do
    if v.localId > 10000 then
      rangeLocationNum = rangeLocationNum + 1
      areaInfoTable[rangeLocationNum] = v
    end
  end
  activateTable = data.bossList
  InitRangeLocation()
  InitDetailLocation()
  DealMaterialCanShow()
  if data.proficientLevel then
    ui.master_total_grade.Text = "+" .. data.proficientLevel
  else
    ui.master_total_grade.Text = ""
  end
  if data.proficientVentureForce then
    ui.explore_strength_addition.Text = "+" .. data.proficientVentureForce
  else
    ui.explore_strength_addition.Text = ""
  end
  ui.main.Parent = PersonalInfo.ui.left_main_2_s1
  ClearArrowDir()
  showIsFinished = true
  ui["mb_1_" .. 1].PushDown = true
  ui["mb_1_" .. 1].Parent.Skin = SkinF.master_map_bg[2]
  rangeLocationIndex = 1
  need_show_guide = not come_from_character and ComFuc.boss_skill_master
  if not come_from_character then
    if need_show_guide and 0 == guide_num then
      guide_num = guide_num + 1
      NewLead.ShowNewLeadNoLock(Vector2(76, 343), Vector2(522, 145), GetUTF8Text("UI_lobby_area_select"), 0)
    end
    rpc_get_map(areaInfoTable[1].localId)
  end
end, ComFuc.ComControl("coverControlmaster", Vector2(1600, 1200), Vector2(0, 0), 0)
local DealMaterial_1, DealMaterial_2 = function(data)
  for _, v in ipairs(data) do
    if v.itemType == 7 then
      materialGold = v
    elseif v.sysItemId == 823 then
      material1.kind = v
    else
      material2.kind = v
    end
  end
end, ComFuc.ComControl("coverControlmaster", Vector2(1600, 1200), Vector2(0, 0), 0)
local DealMaterial_2, DealMaterial = function(data)
  for _, v in ipairs(data) do
    if material1.kind.sysItemId == v.sysItemId then
      material1.detail = v
    end
    if material2.kind.sysItemId == v.sysItemId then
      material2.detail = v
    end
  end
end, ComFuc.ComControl("coverControlmaster", Vector2(1600, 1200), Vector2(0, 0), 0)
local DealMaterial, GetPropertyAndMaterial = function()
  ui.mastery_1.Skin = SkinF.personalInfo_quality[material1.detail.grade]
  ui.mastery_2.Skin = SkinF.personalInfo_quality[material2.detail.grade]
  ui.mastery_material_skin_1.Skin = Gui.ControlSkin({
    BackgroundImage = Gui.Image("ui/skinF/lobby/" .. material1.detail.resource .. ".tga", Vector4(0, 0, 0, 0))
  })
  ui.mastery_material_skin_2.Skin = Gui.ControlSkin({
    BackgroundImage = Gui.Image("ui/skinF/lobby/" .. material2.detail.resource .. ".tga", Vector4(0, 0, 0, 0))
  })
  ui.mastery_material_count_1.Text = string.format("%d/%d", material1.detail.ownNum, material1.detail.needNum)
  if material1.detail.ownNum >= material1.detail.needNum then
    ui["mastery_material_count_" .. 1].TextureFont = SkinF.hecheng_number_5
  else
    ui["mastery_material_count_" .. 1].TextureFont = SkinF.hecheng_number_6
  end
  ui.mastery_material_count_2.Text = string.format("%d/%d", material2.detail.ownNum, material2.detail.needNum)
  if material2.detail.ownNum >= material2.detail.needNum then
    ui["mastery_material_count_" .. 2].TextureFont = SkinF.hecheng_number_5
  else
    ui["mastery_material_count_" .. 2].TextureFont = SkinF.hecheng_number_6
  end
  ui.mastery_material_name_1.Text = GetUTF8Text(material1.detail.displayName)
  ui.mastery_material_name_2.Text = GetUTF8Text(material2.detail.displayName)
  ui.master_cost.Text = tostring(materialGold.unit)
end, ComFuc.ComControl("coverControlmaster", Vector2(1600, 1200), Vector2(0, 0), 0)

function GetPropertyAndMaterial(data)
  local master = data.playerProficient
  skillTable = data.totalSkillMap[1]
  master.levelName = mapInfoTable[detailLocationIndex].displayName
  showSmallThing.attack = master.attack or 0
  showSmallThing.defend = master.defend or 0
  for _, v in ipairs(data.totalExpMap) do
    if v.property == "4" then
      showSmallThing.need = v.value
    end
  end
  if master.proficientLevel then
    showSmallThing.masterLevel = master.proficientLevel
  else
    showSmallThing.masterLevel = nil
  end
  if showSmallThing.attack + showSmallThing.defend >= showSmallThing.need then
    showSmallThing.masterLevel = showSmallThing.masterLevel + 1
  end
  if (master.attack or 0) + (master.defend or 0) >= showSmallThing.need then
    oldLevel = master.proficientLevel + 1
  else
    oldLevel = master.proficientLevel
  end
  skillId = tonumber(skillTable.sid)
  DealSkillActivate()
  showSmallThing.mapName = master.levelName
  DealAttackDefendBtn()
  DealMaterialCanShow()
  GetAngle(false)
  ViewCircleCondition()
  DealProperty()
  DealMaterial_1(data.sysProficient.material)
  DealMaterial_2(data.material)
  DealMaterial()
  DealSkill()
  DealSkillShow()
  DealArrowDir()
  if come_from_character then
    come_from_character = false
  end
end

function ui.btn_set_active.EventClick()
  if not Lobby then
    require("Lobby.lua")
  end
  for i = 1, 10 do
    Lobby.ui["btn_m_" .. i].PushDown = false
  end
  Lobby.mainBtnPushDown = 0
  Lobby.MainBtnSelect(1)
  Lobby.ui["btn_m_" .. 1].PushDown = true
  if not PersonalInfo then
    require("PersonalInfo.lua")
  end
  PersonalInfo.activeBossSkill(skillId)
  Hide()
end

local ui["mastery_refit_buy_" .. 1].EventClick, GetResultProperty = function(sender, e)
  if not QuickBuy then
    require("shop/quick_buy.lua")
  end
  QuickBuy.Show({
    t = 3,
    st = material1.detail.subType,
    category = material1.detail.category
  })
  
  function QuickBuy.callback()
    refitMoveDir = 0
    rpc_get_master_property()
  end
end, ui["mastery_refit_buy_" .. 1]
local GetResultProperty, FreshAngleAfterMaster = function(data)
  if showSmallThing.attack >= data.proficient.attack then
    isAddition.attack = false
  else
    isAddition.attack = true
  end
  if showSmallThing.defend >= data.proficient.defend then
    isAddition.defend = false
  else
    isAddition.defend = true
  end
  showSmallThing.attack = data.proficient.attack
  showSmallThing.defend = data.proficient.defend
  if data.proficient.proficientLevel then
    showSmallThing.masterLevel = data.proficient.proficientLevel
  else
    showSmallThing.masterLevel = nil
  end
  if data.proficient.proficientLevel and showSmallThing.masterLevel then
    levelUp = false
    if showSmallThing.attack + showSmallThing.defend >= showSmallThing.need then
      showSmallThing.masterLevel = showSmallThing.masterLevel + 1
    end
    if oldLevel then
      levelUp = showSmallThing.masterLevel and showSmallThing.masterLevel > oldLevel
    end
    if data.proficient.attack + data.proficient.defend >= showSmallThing.need then
      oldLevel = data.proficient.proficientLevel + 1
    else
      oldLevel = data.proficient.proficientLevel
    end
  end
  showSmallThing.mapName = data.proficient.levelName
  DealMaterial_1(data.sysProficient.material)
  DealMaterial_2(data.material)
  DealMaterial()
  isFinish = true
end, "EventClick"

function FreshAngleAfterMaster()
  currentCircle.red_attack.CurrentAngle = currentCircle.red_attack.OffsetAngle
  currentCircle.blue_defend.CurrentAngle = currentCircle.blue_defend.OffsetAngle
end

function ui.attack_switch_btn.EventClick()
  if ui.attack_switch_btn.PushDown and ui.defend_switch_btn.PushDown then
    ui.defend_switch_btn.PushDown = false
  end
  DealArrowDir()
  if need_show_guide and 3 == guide_num then
    guide_num = guide_num + 1
    NewLead.ShowNewLeadNoLock(Vector2(1027, 463), Vector2(100, 68), GetUTF8Text("UI_lobby_click_defense_switch"), 0)
  end
end

local ui.defend_switch_btn.EventClick, DealMasterState = function()
  if ui.defend_switch_btn.PushDown and ui.attack_switch_btn.PushDown then
    ui.attack_switch_btn.PushDown = false
  end
  DealArrowDir()
  if need_show_guide then
    if 4 == guide_num then
      guide_num = guide_num + 1
      NewLead.ShowNewLeadNoLock(Vector2(1027, 463), Vector2(100, 68), GetUTF8Text("UI_lobby_click_switch_cancel"), 0)
    elseif 5 == guide_num then
      guide_num = guide_num + 1
      NewLead.ShowNewLeadNoLock(Vector2(930, 750), Vector2(161, 63), GetUTF8Text("UI_common_Click"), 0)
    end
  end
end, ui.defend_switch_btn
local DealMasterState, MaterialIsEnough = function()
  if ui.attack_switch_btn.PushDown then
    masterState = 1
  end
  if ui.defend_switch_btn.PushDown then
    masterState = 2
  end
  if not ui.attack_switch_btn.PushDown and not ui.defend_switch_btn.PushDown then
    masterState = 0
  end
end, "EventClick"

function MaterialIsEnough()
  return material1.detail.ownNum >= material1.detail.needNum and material2.detail.ownNum >= material2.detail.needNum
end

for i = 1, 10 do
  ui["mb_1_" .. i].ClickAudio = "button"
  ui["mb_1_" .. i].EventClick = function()
    if rangeLocationIndex and rangeLocationIndex == i then
      ui["mb_1_" .. i].PushDown = true
      ui["mb_1_" .. i].Parent.Skin = SkinF.master_map_bg[2]
    else
      if rangeLocationIndex and 0 < rangeLocationIndex and rangeLocationIndex <= rangeLocationNum then
        ui["mb_1_" .. rangeLocationIndex].PushDown = false
        ui["mb_1_" .. rangeLocationIndex].Parent.Skin = SkinF.master_map_bg[1]
      end
      rangeLocationIndex = i
      ClearMap()
      rpc_get_map(areaInfoTable[i].localId)
      DealAttackDefendBtn()
      DealMaterialCanShow()
      ui["mb_1_" .. i].PushDown = true
      ui["mb_1_" .. i].Parent.Skin = SkinF.master_map_bg[2]
      ViewCircleCondition()
    end
    if need_show_guide and 1 == guide_num then
      guide_num = guide_num + 1
      NewLead.ShowNewLeadNoLock(Vector2(76, 535), Vector2(522, 145), GetUTF8Text("UI_lobby_copy_select"), 0)
    end
  end
end
for i = 1, 10 do
  ui["mb_2_" .. i].ClickAudio = "button"
  ui["mb_2_" .. i].EventClick = function()
    if detailLocationIndex and detailLocationIndex == i then
      ClearMap()
      rpc_get_map(areaInfoTable[rangeLocationIndex].localId)
      DealAttackDefendBtn()
      DealMaterialCanShow()
      ViewCircleCondition()
      ui["mb_2_" .. i].Parent.Skin = SkinF.master_map_bg[2]
    else
      if detailLocationIndex and 0 < detailLocationIndex and detailLocationIndex <= detailLocationNum then
        ui["mb_2_" .. detailLocationIndex].PushDown = false
        ui["mb_2_" .. detailLocationIndex].Parent.Skin = SkinF.master_map_bg[1]
      end
      detailLocationIndex = i
      ui["mb_2_" .. i].PushDown = true
      ui["mb_2_" .. i].Parent.Skin = SkinF.master_map_bg[2]
      ui.defend_switch_btn.PushDown = false
      ui.attack_switch_btn.PushDown = false
      mapId = mapInfoTable[i].levelId
      rpc_get_master_property()
      if need_show_guide and 2 == guide_num then
        guide_num = guide_num + 1
        NewLead.ShowNewLeadNoLock(Vector2(643, 463), Vector2(100, 68), GetUTF8Text("UI_lobby_click_attack_switch"), 0)
      end
    end
  end
  local DealAttackDefendAddition = ComFuc.ComControl("coverControlmaster", Vector2(1600, 1200), Vector2(0, 0), 0)
end
local GetMasterAccount = function(switchNum, checkboxIndex)
  local locationx, sizey
  if switchNum == 1 then
    locationx = 636
  else
    locationx = 1018
  end
  if shinyDuringTime < 80 then
    local percent_y = (math.fmod(shinyDuringTime, 20) + 1) / 20
    sizey = 98 * percent_y
  end
  if switchNum == 1 then
    if checkboxIndex == 2 then
      ui.ctr_attack_arrow.Location = Vector2(locationx, 102)
    else
      ui.ctr_attack_arrow.Location = Vector2(locationx, 200 - sizey)
    end
    ui.ctr_attack_arrow.Size = Vector2(22, sizey)
  else
    if checkboxIndex == 1 then
      ui.ctr_defend_arrow.Location = Vector2(locationx, 102)
    else
      ui.ctr_defend_arrow.Location = Vector2(locationx, 200 - sizey)
    end
    ui.ctr_defend_arrow.Size = Vector2(22, sizey)
  end
end
local DealArrowAddition = function(data)
  if data.proficientLevel then
    ui.master_total_grade.Text = "+" .. data.proficientLevel
  end
  if data.proficientVentureForce then
    ui.explore_strength_addition.Text = "+" .. data.proficientVentureForce
  end
end

function DealAttackDefendAddition()
  rpc.safecall("proficient_local_info", {}, GetArea)
end

rpc_get_area = DealAttackDefendAddition

function DealAttackDefendAddition(i)
  rpc.safecall("proficient_level_info", {localId = i}, GetMap)
end

rpc_get_map = DealAttackDefendAddition

function DealAttackDefendAddition()
  rpc.safecall("proficient_property", {mid = mapId}, GetPropertyAndMaterial)
end

rpc_get_master_property = DealAttackDefendAddition

function DealAttackDefendAddition()
  rpc.safecall("player_level_proficient", {mid = mapId, state = masterState}, GetResultProperty)
end

local rpc_get_after_press_master_btn, ArrowShine = DealAttackDefendAddition, function()
  if shinyDuringTime == 0 then
    rpc_get_after_press_master_btn()
  end
  if shinyDuringTime == 1 and not isFinish then
    shinyDuringTime = 0
  end
  if shinyDuringTime < 80 and 1 < shinyDuringTime then
    if isAddition.attack then
      DealAttackDefendAddition(1, 0)
    end
    if ui.defend_switch_btn.PushDown then
      DealAttackDefendAddition(1, 2)
    end
    if isAddition.defend then
      DealAttackDefendAddition(2, 0)
    end
    if ui.attack_switch_btn.PushDown then
      DealAttackDefendAddition(2, 1)
    end
  end
  if shinyDuringTime == 80 then
    GetAngle(true)
    GetDisableAngle()
  end
  if shinyDuringTime == 120 then
    BeginMoving()
    ViewCircleCondition()
  end
  if 180 <= shinyDuringTime then
    if levelUp then
      PersonalInfo.ReinLevelUp()
    end
    isFinish = false
    EndMoving()
    game.TimerMgr:RemoveTimer(shinyArrow)
    shinyArrow = nil
    DealArrowDir()
    FreshAngleAfterMaster()
    ViewCircleCondition()
    DealProperty()
    DealSkillShow()
    rpc.safecall("proficient_local_info", {}, GetMasterAccount)
    ui.coverControlmaster.Parent = nil
    DealAttackDefendBtn()
  end
  shinyDuringTime = shinyDuringTime + 1
end
local DealAttackDefendAddition, DealFinishGetMap = function()
  ui.coverControlmaster.Parent = gui
  game.TimerMgr:RemoveTimer(shinyArrow)
  shinyArrow = nil
  shinyDuringTime = 0
  shinyArrow = game.TimerMgr:AddTimer(0.02)
  shinyArrow.EventOnTimer = DealArrowAddition
end, ui["mb_2_" .. i]
local DealFinishGetMap, FinishGetMap = function()
  if getMapFinished then
    game.TimerMgr:RemoveTimer(getMapTimer)
    getMapTimer = nil
    ui.coverControlmaster.Parent = nil
    rpc_get_master_property()
  end
end, "EventClick"

function FinishGetMap()
  ui.coverControlmaster.Parent = gui
  game.TimerMgr:RemoveTimer(getMapTimer)
  getMapTimer = nil
  getMapTimer = game.TimerMgr:AddTimer(0.1)
  getMapTimer.EventOnTimer = DealFinishGetMap
end

local lua_string_split, FilterAreaByLevelId = function(str, split_char)
  local sub_str_tab = {}
  while true do
    local pos = string.find(str, split_char)
    if not pos then
      sub_str_tab[#sub_str_tab + 1] = str
      break
    end
    local sub_str = string.sub(str, 1, pos - 1)
    sub_str_tab[#sub_str_tab + 1] = sub_str
    str = string.sub(str, pos + 1, #str)
  end
  return sub_str_tab
end, function(str, split_char)
  local sub_str_tab = {}
  while true do
    local pos = string.find(str, split_char)
    if not pos then
      sub_str_tab[#sub_str_tab + 1] = str
      break
    end
    local sub_str = string.sub(str, 1, pos - 1)
    sub_str_tab[#sub_str_tab + 1] = sub_str
    str = string.sub(str, pos + 1, #str)
  end
  return sub_str_tab
end
local FilterAreaByLevelId, DealFinishShow = function(levelId)
  local str_id = tostring(levelId)
  if ui.btn_copy_master.PushDown and areaInfoTable then
    for i = 1, maxLocationAreaNum do
      if areaInfoTable[i] then
        local v = areaInfoTable[i]
        if v and v.levelIds and string.len(v.levelIds) > 0 then
          local sub_str = lua_string_split(v.levelIds, ",")
          for k, u in ipairs(sub_str) do
            if u == str_id then
              mapId = levelId
              rangeLocationIndex = i
              ClearMap()
              detailLocationIndex = k
              rpc_get_map(areaInfoTable[rangeLocationIndex].localId)
              DealAttackDefendBtn()
              DealMaterialCanShow()
              ui["mb_1_" .. rangeLocationIndex].PushDown = true
              ui["mb_1_" .. rangeLocationIndex].Parent.Skin = SkinF.master_map_bg[2]
              FinishGetMap()
              return
            end
          end
        end
      end
    end
  end
end, ComFuc.ComControl("coverControlmaster", Vector2(1600, 1200), Vector2(0, 0), 0)

function DealFinishShow()
  if showIsFinished then
    game.TimerMgr:RemoveTimer(showTimer)
    showTimer = nil
    ui.coverControlmaster.Parent = nil
    FilterAreaByLevelId(tmp_mapId)
  end
end

function FinishShow(levelId)
  come_from_character = true
  Show()
  tmp_mapId = levelId
  ui.coverControlmaster.Parent = gui
  game.TimerMgr:RemoveTimer(showTimer)
  showTimer = nil
  showTimer = game.TimerMgr:AddTimer(0.1)
  showTimer.EventOnTimer = DealFinishShow
end

function ui.btn_copy_master.EventClick()
  if ui.btn_copy_master.PushDown == false then
    ui.btn_copy_master.PushDown = true
  end
end

function ui.mastery_material_skin_1.EventMouseEnter(sender, e)
  Tip.SetRpc("tip_sys_item", {
    t = 3,
    sid = material1.detail.sysItemId
  })
  Tip.SetUseDescription(false)
  Tip.SetOwner(sender)
end

function ui.mastery_material_skin_2.EventMouseEnter(sender, e)
  Tip.SetRpc("tip_sys_item", {
    t = 3,
    sid = material2.detail.sysItemId
  })
  Tip.SetUseDescription(false)
  Tip.SetOwner(sender)
end

function ui.btn_master.EventClick()
  if 6 == guide_num then
    ComFuc.TestIsFinishOneTask(ComFuc.quest_id[2])
    boss_skill_master = false
    NewLead.ShowNewLeadNoLock(Vector2(521, 78), Vector2(72, 73), GetUTF8Text("UI_common_Click"), 1)
  end
  DealMasterState()
  if not MaterialIsEnough() then
    MessageBox.ShowError(GetUTF8Text("msgbox_common_blueprint_clew_03"))
  elseif ComFuc.globalGP < materialGold.unit then
    if not L_MoneyLessKey then
      require("moneyLessKey.lua")
    end
    local moneyType = "gold"
    local s = GetMatchedUTF8Text("msgbox_common_num_1128" .. "," .. "UI_store_AH_mainUI_blank_42") .. "\n" .. GetUTF8Text(L_MoneyLessKey.HelpTextKey[moneyType])
    MessageBox.ShowNotEnough(s, moneyType, config.IsRecharge)
  elseif masterState == 0 and showSmallThing.attack and showSmallThing.defend and showSmallThing.attack + showSmallThing.defend >= showSmallThing.need then
    MessageBox.ShowError(GetUTF8Text("tips_common_master_max_prompt"))
  elseif masterState == 1 and (not showSmallThing.defend or showSmallThing.defend == 0) then
    MessageBox.ShowError(GetUTF8Text("msgbox_enhance_defense_zero"))
  elseif masterState == 2 and (not showSmallThing.attack or showSmallThing.attack == 0) then
    MessageBox.ShowError(GetUTF8Text("msgbox_enhance_attack_zero"))
  elseif masterState == 1 then
    MessageBox.ShowWithTwoButtons(GetUTF8Text("msgbox_enhance_attack_convert"), GetUTF8Text("button_common_Accept"), GetUTF8Text("button_common_Cancel"), ArrowShine)
  elseif masterState == 2 then
    MessageBox.ShowWithTwoButtons(GetUTF8Text("msgbox_enhance_defense_convert"), GetUTF8Text("button_common_Accept"), GetUTF8Text("button_common_Cancel"), ArrowShine)
  else
    ArrowShine()
  end
end

function Show()
  Hide()
  if not PersonalInfo then
    require("personalInfo.lua")
  end
  if PersonalInfo.ui["btn_reinforce_" .. 6].PushDown == false then
    PersonalInfo.ui["btn_reinforce_" .. 6].PushDown = true
  end
  if PersonalInfo.ui.ctrl_reinforce_2.Parent then
    PersonalInfo.ui.ctrl_reinforce_2.Parent = nil
  end
  NewLead.HideLead()
  ui.btn_copy_master.PushDown = true
  rpc_get_area()
end

function Hide()
  skillTable = nil
  activateTable = nil
  skillId = nil
  ui.master_total_grade.Text = ""
  ui.explore_strength_addition.Text = ""
  ClearMap()
  ClearArea()
  ViewCircleCondition()
  ui.main.Parent = nil
  guide_num = 0
end
