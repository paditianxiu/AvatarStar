module("PlayerCardInherit", package.seeall)
require("../sys/messagebox.lua")

function _PrintInfo(name)
  if type(name) == "table" then
    for k, v in pairs(name) do
      print("table begin: " .. k)
      _PrintInfo(v)
      print("table end")
    end
  else
    print("not table begin")
    print(name)
    print("not table end")
  end
end

local ComControl = ComFuc.ComControl
local ComLabel = ComFuc.ComLabel
local colg = ComFuc.colg
local colw = ComFuc.colw
local colh = ComFuc.colh
local color_coffee = ARGB(255, 82, 54, 44)
local GetMoveMesg = ComFuc.GetMoveMesg
local ComFlashNew = ComFuc.ComFlashNew
local IsInAABB = ComFuc.IsInAABB
local dealTargetCardReturn = false
local dealMaterialCardReturn = false
local timerAttrib, timerGrowBar, timerPolling, timerPopping, timerShining2, timerStayWhile, inheritAttribSel
local cntDisabledInheritAttrib = 0
local flowAttribIndex = {}
local materialCardExploreAttrib = {}
local targetCardExploreAttrib = {}
local isEnough = true
local isAddMore = true
local reinK = 0
local increasePercent = 0
local increaseBaseNum, increaseBoundBaseNum, increaseBoundPercent, realIncreasePercent, inheritMoney, stayAWhileTimeCnt, growBarLimit, flowIdxCnt
local isLevelUp = false
local canLevelUp = false
local maxPropertyTableIsEmpty = true
local maxLevel = 0
local cardMaxProperty = {
  Recovery = 0,
  Cure = 0,
  Armor = 0,
  Stamina = 0
}
local cardMinProperty = {
  Recovery = 0,
  Cure = 0,
  Armor = 0,
  Stamina = 0
}
local tmpCardMaxProperty = {
  Recovery = 0,
  Cure = 0,
  Armor = 0,
  Stamina = 0
}
local tmpCardMinProperty = {
  Recovery = 0,
  Cure = 0,
  Armor = 0,
  Stamina = 0
}
local cardNowMaxProperty = {
  Recovery = 0,
  Cure = 0,
  Armor = 0,
  Stamina = 0
}
local cardPropertyTable = {
  level_1 = nil,
  level_2 = nil,
  level_3 = nil,
  level_4 = nil,
  level_5 = nil,
  level_6 = nil,
  level_7 = nil,
  level_8 = nil,
  level_9 = nil,
  level_10 = nil
}
local oldTargetCarData, oldMaterialCarData
local useConvert = 0
local Is_JewelOrSkill = false
local NeddClonenum = {}
local ClonePrice = {}
local PropertyClone = {}
local AvtarType = {}
local Is_NoUseAddition = false
local Is_NilCover = {
  false,
  false,
  false
}
local tip_player_interface = {
  nil,
  "tip_player_item",
  "tip_player_item",
  "tip_player_item",
  "tip_player_avatar",
  "tip_player_avatar"
}
local tip_sys_interface = {
  "tip_sys_skill",
  "tip_sys_item",
  "tip_sys_item",
  "tip_sys_item",
  "tip_sys_avatar",
  "tip_sys_avatar"
}
local Cover_Text = {
  GetUTF8Text("UI_abilities_pve_power"),
  GetUTF8Text("button_avatar_gem_cover"),
  GetUTF8Text("button_avatar_heroskill_cover")
}
targetCardDpt = {}
materialCardDpt = {}
targetCardSel = nil
materialCardSel = nil
local totalTime = 0
targetCardSelected = {
  Stamina = 0,
  Vitality = 0,
  Armor = 0,
  Recovery = 0,
  level = 0
}
tmpTargetCardSelected = {
  Stamina = 0,
  Vitality = 0,
  Armor = 0,
  Recovery = 0,
  level = 0
}
materialCardSelected = {
  Stamina = 0,
  Vitality = 0,
  Armor = 0,
  Recovery = 0,
  StaminaEnable = false,
  VitalityEnable = false,
  AmorEnable = false,
  RecoveryEnable = false,
  level = 0
}
oldAddition = nil
local actualAddition, RefreshTargetCardList
local RefreshTargetCardList, RefreshMaterialCardList = function(data)
  oldTargetCarData = data
  targetCardDpt = {}
  ComFuc.HideCardBtn2(PersonalInfo.ui, "targetCard", 5, 1)
  PersonalInfo.ui.pb_targetCard.CurrIndex = data.page
  PersonalInfo.ui.pb_targetCard.PageCount = data.pages
  for i, v in ipairs(data.items) do
    targetCardDpt[i] = v
    AvtarType[i] = v.subType
    PersonalInfo.ui["targetCard_card_b_" .. i].Visible = true
    if v and v.unitType and v.unit and v.unitType == 2 and v.unit <= 20 then
      PersonalInfo.ui["targetCard_card_bs_" .. v.slot].Visible = true
    end
    PersonalInfo.ui["targetCard_card_p_" .. i].Skin = SkinF.personalInfo_quality[v.grade]
    ComFuc.SetPersonCardData(v.avatar, i, v.position)
    if targetCardSel and targetCardSel.pid == v.pid then
      PersonalInfo.ui["targetCard_card_b_" .. i].BackgroundColor = colh
      PersonalInfo.ui["targetCard_card_b_" .. i].Enable = true
      PersonalInfo.ui["targetCard_card_p_" .. i].BackgroundColor = colh
    elseif materialCardSel and materialCardSel.pid == v.pid then
      PersonalInfo.ui["targetCard_card_b_" .. i].BackgroundColor = colh
      PersonalInfo.ui["targetCard_card_b_" .. i].Enable = true
      PersonalInfo.ui["targetCard_card_p_" .. i].BackgroundColor = colh
    else
      PersonalInfo.ui["targetCard_card_b_" .. i].BackgroundColor = colw
      PersonalInfo.ui["targetCard_card_b_" .. i].Enable = true
      PersonalInfo.ui["targetCard_card_p_" .. i].BackgroundColor = colw
    end
    ComFuc.ShowUpgradeLevel(v, 5, PersonalInfo.ui["targetCard_card_level_" .. i], PersonalInfo.ui["targetCard_card_level_text_" .. i])
    if v.subType == 1 then
      PersonalInfo.ui["targetCard_card_b_" .. i].Skin = SkinF.personalInfo_143
      PersonalInfo.ui["targetCard_card_level_" .. i].Skin = SkinF.avatar_level
    elseif v.subType == 2 then
      PersonalInfo.ui["targetCard_card_b_" .. i].Skin = SkinF.personalInfo_261
      PersonalInfo.ui["targetCard_card_level_" .. i].Skin = SkinF.avatar_level_hero
    end
  end
  if NewLead.leadVisible and ComFuc.inherit_guide then
    NewLead.ShowNewLeadNoLock(Vector2(79, 341), Vector2(104, 163), GetUTF8Text("UI_enhance_Please_drag_in_the_avatar_card"), 0)
    if targetCardSel then
      if not materialCardSel then
        NewLead.ShowNewLeadNoLock(Vector2(412, 341), Vector2(104, 163), GetUTF8Text("UI_enhance_Please_drag_in_the_avatar_card"), 0)
      else
        NewLead.ShowNewLeadNoLock(Vector2(357, 751), Vector2(163, 63), GetUTF8Text("UI_common_Click"), 0)
      end
    end
  end
end, GetUTF8Text("button_avatar_heroskill_cover")
local RefreshMaterialCardList, DealTargetCardList = function(data)
  oldMaterialCarData = data
  materialCardDpt = {}
  ComFuc.HideCardBtn2(PersonalInfo.ui, "materialCard", 10, 6)
  PersonalInfo.ui.pb_materialCard.CurrIndex = data.page
  PersonalInfo.ui.pb_materialCard.PageCount = data.pages
  for i, v in ipairs(data.items) do
    i = i + 5
    materialCardDpt[i] = v
    AvtarType[i] = v.subType
    PersonalInfo.ui["materialCard_card_b_" .. i].Visible = true
    if v and v.unitType and v.unit and v.unitType == 2 and v.unit <= 20 then
      PersonalInfo.ui["materialCard_card_bs_" .. i].Visible = true
    end
    PersonalInfo.ui["materialCard_card_p_" .. i].Skin = SkinF.personalInfo_quality[v.grade]
    ComFuc.SetPersonCardData(v.avatar, ComFuc.CardId(i), v.position)
    if materialCardSel and materialCardSel.pid == v.pid then
      PersonalInfo.ui["materialCard_card_b_" .. i].BackgroundColor = colh
      PersonalInfo.ui["materialCard_card_b_" .. i].Enable = true
      PersonalInfo.ui["materialCard_card_p_" .. i].BackgroundColor = colh
    elseif targetCardSel and targetCardSel.pid == v.pid then
      PersonalInfo.ui["materialCard_card_b_" .. i].BackgroundColor = colh
      PersonalInfo.ui["materialCard_card_b_" .. i].Enable = true
      PersonalInfo.ui["materialCard_card_p_" .. i].BackgroundColor = colh
    else
      PersonalInfo.ui["materialCard_card_b_" .. i].BackgroundColor = colw
      PersonalInfo.ui["materialCard_card_b_" .. i].Enable = true
      PersonalInfo.ui["materialCard_card_p_" .. i].BackgroundColor = colw
    end
    if v.isEquip == "Y" or v.isDefault == "Y" then
      PersonalInfo.ui["materialCard_card_b_" .. i].BackgroundColor = colh
      PersonalInfo.ui["materialCard_card_b_" .. i].Enable = true
      PersonalInfo.ui["materialCard_card_p_" .. i].BackgroundColor = colh
    end
    ComFuc.ShowUpgradeLevel(v, 5, PersonalInfo.ui["materialCard_card_level_" .. i], PersonalInfo.ui["materialCard_card_level_text_" .. i])
    if v.subType == 1 then
      PersonalInfo.ui["materialCard_card_b_" .. i].Skin = SkinF.personalInfo_143
      PersonalInfo.ui["materialCard_card_level_" .. i].Skin = SkinF.avatar_level
    elseif v.subType == 2 then
      PersonalInfo.ui["materialCard_card_b_" .. i].Skin = SkinF.personalInfo_261
      PersonalInfo.ui["materialCard_card_level_" .. i].Skin = SkinF.avatar_level_hero
    end
  end
end, GetUTF8Text("button_avatar_heroskill_cover")
local DealTargetCardList, DealMaterialCardList = function(data)
  if oldMaterialCarData then
    RefreshMaterialCardList(oldMaterialCarData)
  end
  RefreshTargetCardList(data)
end, GetUTF8Text("button_avatar_heroskill_cover")
local DealMaterialCardList, ShowRefitTiao = function(data)
  if oldTargetCarData then
    RefreshTargetCardList(oldTargetCarData)
  end
  RefreshMaterialCardList(data)
end, GetUTF8Text("button_avatar_heroskill_cover")
local ShowRefitTiao, DealCloneNum = function(i, res, hc, nc, na, id, gr)
  PersonalInfo.ui["mastery_tiao_" .. i].Visible = nc and 0 < nc
  PersonalInfo.ui["mastery_refMtr_res_" .. i].Skin = Gui.ControlSkin({
    BackgroundImage = Gui.Image("ui/skinF/lobby/" .. res .. ".tga", Vector4(0, 0, 0, 0))
  })
  PersonalInfo.ui["mastery_refMtr_count_" .. i].Text = string.format("%d/%d", hc, nc)
  if nc <= hc then
    PersonalInfo.ui["mastery_refMtr_count_" .. i].TextureFont = SkinF.hecheng_number_5
  else
    PersonalInfo.ui["mastery_refMtr_count_" .. i].TextureFont = SkinF.hecheng_number_6
    if i == 1 or i == 2 or i == 3 then
      isEnough = false
    end
  end
  if na then
    PersonalInfo.ui["mastery_refMtr_" .. i].Text = na
  end
  PersonalInfo.ui["mastery_refMtr_res_p_" .. i].Skin = SkinF.personalInfo_quality[gr]
  PersonalInfo.ui["mastery_refMtr_res_" .. i].EventMouseEnter = function(sender, e)
    Tip.SetRpc(tip_sys_interface[3], {t = 3, sid = id})
    Tip.SetUseDescription(false)
    Tip.SetOwner(sender)
  end
end, GetUTF8Text("button_avatar_heroskill_cover")
local DealCloneNum, DealRefitNeed = function()
  local CloneNum = 0
  local spend_money = 0
  local Is_cover = false
  for j = 1, 3 do
    if PersonalInfo.ui["cover_" .. j].Check then
      CloneNum = CloneNum + NeddClonenum[j]
      spend_money = spend_money + ClonePrice[j]
      Is_cover = true
    end
  end
  if not Is_cover then
    PersonalInfo.ui.inherit_cost.Text = "" .. inheritMoney
  else
    PersonalInfo.ui.inherit_cost.Text = "" .. spend_money
  end
  ShowRefitTiao(4, PropertyClone.resource, PropertyClone.ownPropertyCloneNum, CloneNum or 0, nil, PropertyClone.id, PropertyClone.grade)
end, GetUTF8Text("button_avatar_heroskill_cover")

function DealRefitNeed(data)
  for i, v in ipairs(data.materials) do
    ShowRefitTiao(i, v.resource, v.ownNum, v.needNum, GetUTF8Text(v.displayName), v.itemId, v.grade)
  end
  NeddClonenum = {
    data.propertyClone.needPropertyCloneNum,
    data.propertyClone.needJewelCloneNum,
    data.propertyClone.needSkillCloneNum
  }
  ClonePrice = {
    data.propertyClonePrice,
    data.jewelClonePrice,
    data.skillClonePrice
  }
  PropertyClone = data.propertyClone
  PersonalInfo.ui.inherit_cost.Text = "" .. data.propertyInheritPrice
  inheritMoney = data.propertyInheritPrice
  DealCloneNum()
  if materialCardSel then
    if data.maProperty.properties == nil then
      Is_NilCover[1] = true
    else
      Is_NilCover[1] = false
    end
    if #data.maProperty.slot == 0 then
      Is_NilCover[2] = true
    else
      Is_NilCover[2] = false
    end
    if data.maProperty.skillId == nil then
      Is_NilCover[3] = true
    else
      Is_NilCover[3] = false
    end
  end
end

function rpc_storage_storage_list_no_empty_target_card(i)
  rpc.safecall("storage_storage_list_no_empty", {
    t = 5,
    s = ComFuc.reinfS[1],
    p = i,
    f = 0
  }, DealTargetCardList)
end

function rpc_storage_storage_list_no_empty_material_card(i)
  rpc.safecall("storage_storage_list_no_empty", {
    t = 5,
    s = ComFuc.reinfS[1],
    p = i,
    f = 1
  }, DealMaterialCardList)
end

function rpc_refit_need_inherit(Is_targetSel)
  if Is_targetSel then
    rpc.safecall("player_card_inherit_material", {
      tid = targetCardSel.pid
    }, DealRefitNeed)
  elseif targetCardSel then
    rpc.safecall("player_card_inherit_material", {
      tid = targetCardSel.pid,
      mid = materialCardSel.pid
    }, DealRefitNeed)
  end
end

local PlayerCardInherit_UI, get_avatar_attrib_bound = function(name)
  return Gui.Control(name)({
    Size = Vector2(1124, 641),
    Gui.Control({
      Size = Vector2(592, 304),
      Location = Vector2(512, 4),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComLabel(nil, GetUTF8Text("UI_lobby_explore_aim_avatar"), Vector2(582, 21), Vector2(14, 4), 0, 16, colw),
      ComFuc.ComPagesBar("pb_targetCard", Vector2(166, 250)),
      ComFuc.CardKeyCB2(1, "targetCard", -79, -111, 0, PersonalInfo, PlayerCardInherit, true),
      ComFuc.CardKeyCB2(2, "targetCard", -79, -111, 0, PersonalInfo, PlayerCardInherit, true),
      ComFuc.CardKeyCB2(3, "targetCard", -79, -111, 0, PersonalInfo, PlayerCardInherit, true),
      ComFuc.CardKeyCB2(4, "targetCard", -79, -111, 0, PersonalInfo, PlayerCardInherit, true),
      ComFuc.CardKeyCB2(5, "targetCard", -79, -111, 0, PersonalInfo, PlayerCardInherit, true)
    }),
    Gui.Control({
      Size = Vector2(592, 304),
      Location = Vector2(512, 316),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComLabel(nil, GetUTF8Text("UI_lobby_explore_material_avatar"), Vector2(582, 21), Vector2(14, 4), 0, 16, colw),
      ComFuc.ComPagesBar("pb_materialCard", Vector2(166, 250)),
      ComFuc.CardKeyCB2(6, "materialCard", -79, -275, 0, PersonalInfo, PlayerCardInherit, false),
      ComFuc.CardKeyCB2(7, "materialCard", -79, -275, 0, PersonalInfo, PlayerCardInherit, false),
      ComFuc.CardKeyCB2(8, "materialCard", -79, -275, 0, PersonalInfo, PlayerCardInherit, false),
      ComFuc.CardKeyCB2(9, "materialCard", -79, -275, 0, PersonalInfo, PlayerCardInherit, false),
      ComFuc.CardKeyCB2(10, "materialCard", -79, -275, 0, PersonalInfo, PlayerCardInherit, false)
    }),
    Gui.Control("inherit_functionality")({
      Size = Vector2(491, 590),
      Location = Vector2(5, 28),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_214,
      ComControl(nil, Vector2(471, 274), Vector2(10, 40), 255, SkinF.card_inherit_001),
      ComFuc.ComButton("btn_attribute_inherit_1", nil, Vector2(253, 59), Vector2(120, 74), 16, true, false, SkinF.card_inherit_002[1]),
      ComFuc.ComLabel("label_abilities_inherit_1", GetUTF8Text("tips_abilities_Stamina"), Vector2(253, 59), Vector2(220, 74), 0, 18, ComFuc.coly, "kAlignMiddle", nil),
      ComControl(nil, Vector2(20, 20), Vector2(194, 90), 255, SkinF.personalInfo_229[6]),
      ComFuc.ComButton("btn_attribute_inherit_2", nil, Vector2(253, 56), Vector2(120, 124), 16, true, false, SkinF.card_inherit_002[2]),
      ComFuc.ComLabel("label_abilities_inherit_2", GetUTF8Text("tips_abilities_Amor"), Vector2(253, 56), Vector2(220, 124), 0, 18, ComFuc.coly, "kAlignMiddle", nil),
      ComControl(nil, Vector2(20, 20), Vector2(194, 140), 255, SkinF.personalInfo_229[4]),
      ComFuc.ComButton("btn_attribute_inherit_3", nil, Vector2(253, 56), Vector2(120, 174), 16, true, false, SkinF.card_inherit_002[3]),
      ComFuc.ComLabel("label_abilities_inherit_3", GetUTF8Text("tips_abilities_Vitality"), Vector2(253, 56), Vector2(220, 174), 0, 18, ComFuc.coly, "kAlignMiddle", nil),
      ComControl(nil, Vector2(20, 20), Vector2(194, 190), 255, SkinF.personalInfo_229[2]),
      ComFuc.ComButton("btn_attribute_inherit_4", nil, Vector2(253, 59), Vector2(120, 221), 16, true, false, SkinF.card_inherit_002[4]),
      ComFuc.ComLabel("label_abilities_inherit_4", GetUTF8Text("tips_abilities_Recovery"), Vector2(253, 59), Vector2(220, 221), 0, 18, ComFuc.coly, "kAlignMiddle", nil),
      ComControl(nil, Vector2(20, 20), Vector2(194, 240), 255, SkinF.personalInfo_229[3]),
      ComFuc.ComControl("inherit_attrib_collider", Vector2(253, 316), Vector2(120, 74), 0, SkinF.skin_playgame_030, true, true),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_lobby_explore_aim_avatar"), Vector2(74, 22), Vector2(57, 266), 0, 18, ARGB(255, 255, 194, 64), "kAlignMiddle", nil),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_lobby_explore_material_avatar"), Vector2(74, 22), Vector2(399, 266), 0, 18, ARGB(255, 255, 194, 64), "kAlignMiddle", nil),
      ComFuc.ComControl("msg_attribute_inherit_1", Vector2(253, 59), Vector2(120, 74), 0),
      ComFuc.ComControl("msg_attribute_inherit_2", Vector2(253, 59), Vector2(120, 124), 0),
      ComFuc.ComControl("msg_attribute_inherit_3", Vector2(253, 59), Vector2(120, 174), 0),
      ComFuc.ComControl("msg_attribute_inherit_4", Vector2(253, 59), Vector2(120, 221), 0),
      ComFuc.ComControlAddPt("inherit_1_1", Vector2(100, 100), Vector2(104, 55), "L_ui_chuancheng_sx012"),
      ComFuc.ComControlAddPt("inherit_1_2", Vector2(100, 100), Vector2(286, 55), "L_ui_chuancheng_sx011"),
      ComFuc.ComControlAddPt("inherit_2_1", Vector2(100, 100), Vector2(104, 98), "ui_chuancheng_XS3"),
      ComFuc.ComControlAddPt("inherit_2_2", Vector2(100, 100), Vector2(286, 98), "ui_chuancheng_XS3"),
      ComFuc.ComControlAddPt("inherit_3_1", Vector2(100, 100), Vector2(104, 148), "ui_chuancheng_XS3"),
      ComFuc.ComControlAddPt("inherit_3_2", Vector2(100, 100), Vector2(286, 148), "ui_chuancheng_XS3"),
      ComFuc.ComControlAddPt("inherit_4_1", Vector2(100, 100), Vector2(104, 189), "ui_chuancheng"),
      ComFuc.ComControlAddPt("inherit_4_2", Vector2(100, 100), Vector2(286, 188), "L_ui_chuancheng_sx012"),
      Gui.Control("insert_targetcard_p")({
        Size = Vector2(104, 163),
        Location = Vector2(27, 95),
        Hint = GetUTF8Text("UI_enhance_additional_string_142"),
        BackgroundColor = colw,
        Skin = SkinF.skin_touming,
        Gui.DragBtn("insert_targetcard")({
          Size = Vector2(104, 163),
          BackgroundColor = colw,
          Skin = SkinF.personalInfo_143,
          ComFuc.ComCharacterStaticCard("insert_card_s", 11),
          ComControl("insert_targetcard_s2", Vector2(104, 163), Vector2(0, 0), 255, SkinF.personalInfo_144),
          Gui.Control("insert_targetcard_level")({
            Size = Vector2(45, 20),
            Location = Vector2(30, 131),
            BackgroundColor = colw,
            Skin = SkinF.avatar_level,
            Visible = false,
            ComLabel("insert_targetcard_level_text", nil, Vector2(45, 20), Vector2(0, 0), 0, 15, colw, "kAlignCenterMiddle")
          })
        })
      }),
      Gui.Control("insert_materialcard_p")({
        Size = Vector2(104, 163),
        Location = Vector2(360, 95),
        Hint = GetUTF8Text("UI_enhance_additional_string_142"),
        BackgroundColor = colw,
        Skin = SkinF.skin_touming,
        Gui.DragBtn("insert_materialcard")({
          Size = Vector2(104, 163),
          BackgroundColor = colw,
          Skin = SkinF.personalInfo_143,
          ComFuc.ComCharacterStaticCard("insert_card_s", 12),
          ComControl("insert_materialcard_s2", Vector2(104, 163), Vector2(0, 0), 255, SkinF.personalInfo_144),
          Gui.Control("insert_materialcard_level")({
            Size = Vector2(45, 20),
            Location = Vector2(30, 131),
            BackgroundColor = colw,
            Skin = SkinF.avatar_level,
            Visible = false,
            ComLabel("insert_materialcard_level_text", nil, Vector2(45, 20), Vector2(0, 0), 0, 12, colw, "kAlignCenterMiddle")
          })
        })
      }),
      ComFlashNew("insert_targetcard_hight", Vector2(104, 163), Vector2(27, 95), 255, SkinF.personalInfo_175),
      ComFlashNew("insert_materialcard_hight", Vector2(104, 163), Vector2(360, 95), 255, SkinF.personalInfo_175),
      ComControl("card_attrib_inherit_bg_bar", Vector2(464, 32), Vector2(14, 23), 255, SkinF.card_inherit_003),
      ComControl("card_attrib_inherit_yellow_bar", Vector2(450, 32), Vector2(20, 23), 255, SkinF.personalInfo_244[2]),
      ComControl("card_attrib_inherit_blue_bar", Vector2(450, 32), Vector2(20, 23), 255, SkinF.personalInfo_244[3]),
      ComFuc.ComLabel("real_increase_percent", "", Vector2(100, 18), Vector2(210, 28), 0, 18, ARGB(255, 80, 255, 255), "kAlignLeftMiddle", nil),
      ComFuc.ComLabel("label_card_increase_percent", "0%", Vector2(60, 16), Vector2(24, 62), 0, 18, ARGB(255, 80, 255, 255), "kAlignLeftMiddle", nil),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_lobby_explore_upper_limit"), Vector2(40, 22), Vector2(389, 62), 0, 18, ARGB(255, 255, 194, 64), "kAlignLeftMiddle", nil),
      ComFuc.ComLabel("label_card_increasebound_percent", "0%", Vector2(60, 22), Vector2(429, 62), 0, 18, ARGB(255, 255, 255, 255), "kAlignLeftMiddle", nil),
      ComFuc.ComButton("btn_inherit", nil, Vector2(163, 63), Vector2(308, 510), 16, false, true, SkinF.card_inherit_004),
      ComFuc.ComButton("btn_levelup", nil, Vector2(163, 63), Vector2(308, 510), 16, false, true, SkinF.card_inherit_levelup),
      ComFuc.ComButton("btn_cover", nil, Vector2(163, 63), Vector2(308, 510), 16, false, true, SkinF.card_inherit_cover),
      ComFuc.ComCheckBox("cover_1", Cover_Text[1], Vector2(130, 20), Vector2(26, 303), 16, colw),
      ComFuc.ComCheckBox("cover_2", Cover_Text[2], Vector2(130, 20), Vector2(216, 303), 16, colw),
      ComFuc.ComCheckBox("cover_3", Cover_Text[3], Vector2(130, 20), Vector2(346, 303), 16, colw),
      ComFuc.MasterMetrial("mastery", 1, Vector2(20, 341)),
      ComFuc.MasterMetrial("mastery", 2, Vector2(250, 341)),
      ComFuc.MasterMetrial("mastery", 3, Vector2(20, 421)),
      ComFuc.MasterMetrial("mastery", 4, Vector2(250, 421)),
      Gui.Label("inherit_opTip")({
        Size = Vector2(455, 165),
        Location = Vector2(15, 338),
        BackgroundColor = colw,
        Skin = SkinF.personalInfo_226,
        FontSize = 16,
        AutoWrap = true,
        TextPadding = Vector4(12, 8, 12, 8)
      }),
      ComLabel(nil, " " .. GetUTF8Text("UI_lobby_explore_inherit_cost"), Vector2(80, 20), Vector2(30, 533), 0, 16, colw),
      ComControl(nil, Vector2(110, 30), Vector2(110, 530), 255, SkinF.personalInfo_215),
      ComLabel("inherit_cost", "0", Vector2(110, 30), Vector2(102, 530), 0, 16, colw, "kAlignRightMiddle"),
      ComControl(nil, Vector2(30, 30), Vector2(220, 530), 255, SkinF.shop_02)
    }),
    ComFuc.PopControl("inheritWarning1_m", Vector2(346, 206), GetUTF8Text("UI_avatar_avatar_UI_06"), 40, 0),
    Gui.Control("inheritWarning2_m")({
      Dock = "kDockFill",
      ComFuc.ComControl(nil, Vector2(322, 96), Vector2(12, 0), 255, SkinF.battle_005),
      ComFuc.ComButton("insertTip_ok", GetUTF8Text("button_common_Cancel"), Vector2(84, 44), Vector2(222, 102)),
      ComFuc.ComLabel("inheritWarning2_text", GetUTF8Text("tips_lobby_explore_inherit_surpass"), Vector2(270, 80), Vector2(40, 8), 0, 16, ARGB(255, 156, 96, 14), "kAlignLeftMiddle")
    }),
    Gui.Control("inheritStateCtrl")({
      Size = Vector2(289, 296),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_209[1],
      ComControl("inheritStateCtrl_son", Vector2(289, 296), Vector2(0, 0), 255, SkinF.personalInfo_209[6])
    })
  })
end, function(name)
  return Gui.Control(name)({
    Size = Vector2(1124, 641),
    Gui.Control({
      Size = Vector2(592, 304),
      Location = Vector2(512, 4),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComLabel(nil, GetUTF8Text("UI_lobby_explore_aim_avatar"), Vector2(582, 21), Vector2(14, 4), 0, 16, colw),
      ComFuc.ComPagesBar("pb_targetCard", Vector2(166, 250)),
      ComFuc.CardKeyCB2(1, "targetCard", -79, -111, 0, PersonalInfo, PlayerCardInherit, true),
      ComFuc.CardKeyCB2(2, "targetCard", -79, -111, 0, PersonalInfo, PlayerCardInherit, true),
      ComFuc.CardKeyCB2(3, "targetCard", -79, -111, 0, PersonalInfo, PlayerCardInherit, true),
      ComFuc.CardKeyCB2(4, "targetCard", -79, -111, 0, PersonalInfo, PlayerCardInherit, true),
      ComFuc.CardKeyCB2(5, "targetCard", -79, -111, 0, PersonalInfo, PlayerCardInherit, true)
    }),
    Gui.Control({
      Size = Vector2(592, 304),
      Location = Vector2(512, 316),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComLabel(nil, GetUTF8Text("UI_lobby_explore_material_avatar"), Vector2(582, 21), Vector2(14, 4), 0, 16, colw),
      ComFuc.ComPagesBar("pb_materialCard", Vector2(166, 250)),
      ComFuc.CardKeyCB2(6, "materialCard", -79, -275, 0, PersonalInfo, PlayerCardInherit, false),
      ComFuc.CardKeyCB2(7, "materialCard", -79, -275, 0, PersonalInfo, PlayerCardInherit, false),
      ComFuc.CardKeyCB2(8, "materialCard", -79, -275, 0, PersonalInfo, PlayerCardInherit, false),
      ComFuc.CardKeyCB2(9, "materialCard", -79, -275, 0, PersonalInfo, PlayerCardInherit, false),
      ComFuc.CardKeyCB2(10, "materialCard", -79, -275, 0, PersonalInfo, PlayerCardInherit, false)
    }),
    Gui.Control("inherit_functionality")({
      Size = Vector2(491, 590),
      Location = Vector2(5, 28),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_214,
      ComControl(nil, Vector2(471, 274), Vector2(10, 40), 255, SkinF.card_inherit_001),
      ComFuc.ComButton("btn_attribute_inherit_1", nil, Vector2(253, 59), Vector2(120, 74), 16, true, false, SkinF.card_inherit_002[1]),
      ComFuc.ComLabel("label_abilities_inherit_1", GetUTF8Text("tips_abilities_Stamina"), Vector2(253, 59), Vector2(220, 74), 0, 18, ComFuc.coly, "kAlignMiddle", nil),
      ComControl(nil, Vector2(20, 20), Vector2(194, 90), 255, SkinF.personalInfo_229[6]),
      ComFuc.ComButton("btn_attribute_inherit_2", nil, Vector2(253, 56), Vector2(120, 124), 16, true, false, SkinF.card_inherit_002[2]),
      ComFuc.ComLabel("label_abilities_inherit_2", GetUTF8Text("tips_abilities_Amor"), Vector2(253, 56), Vector2(220, 124), 0, 18, ComFuc.coly, "kAlignMiddle", nil),
      ComControl(nil, Vector2(20, 20), Vector2(194, 140), 255, SkinF.personalInfo_229[4]),
      ComFuc.ComButton("btn_attribute_inherit_3", nil, Vector2(253, 56), Vector2(120, 174), 16, true, false, SkinF.card_inherit_002[3]),
      ComFuc.ComLabel("label_abilities_inherit_3", GetUTF8Text("tips_abilities_Vitality"), Vector2(253, 56), Vector2(220, 174), 0, 18, ComFuc.coly, "kAlignMiddle", nil),
      ComControl(nil, Vector2(20, 20), Vector2(194, 190), 255, SkinF.personalInfo_229[2]),
      ComFuc.ComButton("btn_attribute_inherit_4", nil, Vector2(253, 59), Vector2(120, 221), 16, true, false, SkinF.card_inherit_002[4]),
      ComFuc.ComLabel("label_abilities_inherit_4", GetUTF8Text("tips_abilities_Recovery"), Vector2(253, 59), Vector2(220, 221), 0, 18, ComFuc.coly, "kAlignMiddle", nil),
      ComControl(nil, Vector2(20, 20), Vector2(194, 240), 255, SkinF.personalInfo_229[3]),
      ComFuc.ComControl("inherit_attrib_collider", Vector2(253, 316), Vector2(120, 74), 0, SkinF.skin_playgame_030, true, true),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_lobby_explore_aim_avatar"), Vector2(74, 22), Vector2(57, 266), 0, 18, ARGB(255, 255, 194, 64), "kAlignMiddle", nil),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_lobby_explore_material_avatar"), Vector2(74, 22), Vector2(399, 266), 0, 18, ARGB(255, 255, 194, 64), "kAlignMiddle", nil),
      ComFuc.ComControl("msg_attribute_inherit_1", Vector2(253, 59), Vector2(120, 74), 0),
      ComFuc.ComControl("msg_attribute_inherit_2", Vector2(253, 59), Vector2(120, 124), 0),
      ComFuc.ComControl("msg_attribute_inherit_3", Vector2(253, 59), Vector2(120, 174), 0),
      ComFuc.ComControl("msg_attribute_inherit_4", Vector2(253, 59), Vector2(120, 221), 0),
      ComFuc.ComControlAddPt("inherit_1_1", Vector2(100, 100), Vector2(104, 55), "L_ui_chuancheng_sx012"),
      ComFuc.ComControlAddPt("inherit_1_2", Vector2(100, 100), Vector2(286, 55), "L_ui_chuancheng_sx011"),
      ComFuc.ComControlAddPt("inherit_2_1", Vector2(100, 100), Vector2(104, 98), "ui_chuancheng_XS3"),
      ComFuc.ComControlAddPt("inherit_2_2", Vector2(100, 100), Vector2(286, 98), "ui_chuancheng_XS3"),
      ComFuc.ComControlAddPt("inherit_3_1", Vector2(100, 100), Vector2(104, 148), "ui_chuancheng_XS3"),
      ComFuc.ComControlAddPt("inherit_3_2", Vector2(100, 100), Vector2(286, 148), "ui_chuancheng_XS3"),
      ComFuc.ComControlAddPt("inherit_4_1", Vector2(100, 100), Vector2(104, 189), "ui_chuancheng"),
      ComFuc.ComControlAddPt("inherit_4_2", Vector2(100, 100), Vector2(286, 188), "L_ui_chuancheng_sx012"),
      Gui.Control("insert_targetcard_p")({
        Size = Vector2(104, 163),
        Location = Vector2(27, 95),
        Hint = GetUTF8Text("UI_enhance_additional_string_142"),
        BackgroundColor = colw,
        Skin = SkinF.skin_touming,
        Gui.DragBtn("insert_targetcard")({
          Size = Vector2(104, 163),
          BackgroundColor = colw,
          Skin = SkinF.personalInfo_143,
          ComFuc.ComCharacterStaticCard("insert_card_s", 11),
          ComControl("insert_targetcard_s2", Vector2(104, 163), Vector2(0, 0), 255, SkinF.personalInfo_144),
          Gui.Control("insert_targetcard_level")({
            Size = Vector2(45, 20),
            Location = Vector2(30, 131),
            BackgroundColor = colw,
            Skin = SkinF.avatar_level,
            Visible = false,
            ComLabel("insert_targetcard_level_text", nil, Vector2(45, 20), Vector2(0, 0), 0, 15, colw, "kAlignCenterMiddle")
          })
        })
      }),
      Gui.Control("insert_materialcard_p")({
        Size = Vector2(104, 163),
        Location = Vector2(360, 95),
        Hint = GetUTF8Text("UI_enhance_additional_string_142"),
        BackgroundColor = colw,
        Skin = SkinF.skin_touming,
        Gui.DragBtn("insert_materialcard")({
          Size = Vector2(104, 163),
          BackgroundColor = colw,
          Skin = SkinF.personalInfo_143,
          ComFuc.ComCharacterStaticCard("insert_card_s", 12),
          ComControl("insert_materialcard_s2", Vector2(104, 163), Vector2(0, 0), 255, SkinF.personalInfo_144),
          Gui.Control("insert_materialcard_level")({
            Size = Vector2(45, 20),
            Location = Vector2(30, 131),
            BackgroundColor = colw,
            Skin = SkinF.avatar_level,
            Visible = false,
            ComLabel("insert_materialcard_level_text", nil, Vector2(45, 20), Vector2(0, 0), 0, 12, colw, "kAlignCenterMiddle")
          })
        })
      }),
      ComFlashNew("insert_targetcard_hight", Vector2(104, 163), Vector2(27, 95), 255, SkinF.personalInfo_175),
      ComFlashNew("insert_materialcard_hight", Vector2(104, 163), Vector2(360, 95), 255, SkinF.personalInfo_175),
      ComControl("card_attrib_inherit_bg_bar", Vector2(464, 32), Vector2(14, 23), 255, SkinF.card_inherit_003),
      ComControl("card_attrib_inherit_yellow_bar", Vector2(450, 32), Vector2(20, 23), 255, SkinF.personalInfo_244[2]),
      ComControl("card_attrib_inherit_blue_bar", Vector2(450, 32), Vector2(20, 23), 255, SkinF.personalInfo_244[3]),
      ComFuc.ComLabel("real_increase_percent", "", Vector2(100, 18), Vector2(210, 28), 0, 18, ARGB(255, 80, 255, 255), "kAlignLeftMiddle", nil),
      ComFuc.ComLabel("label_card_increase_percent", "0%", Vector2(60, 16), Vector2(24, 62), 0, 18, ARGB(255, 80, 255, 255), "kAlignLeftMiddle", nil),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_lobby_explore_upper_limit"), Vector2(40, 22), Vector2(389, 62), 0, 18, ARGB(255, 255, 194, 64), "kAlignLeftMiddle", nil),
      ComFuc.ComLabel("label_card_increasebound_percent", "0%", Vector2(60, 22), Vector2(429, 62), 0, 18, ARGB(255, 255, 255, 255), "kAlignLeftMiddle", nil),
      ComFuc.ComButton("btn_inherit", nil, Vector2(163, 63), Vector2(308, 510), 16, false, true, SkinF.card_inherit_004),
      ComFuc.ComButton("btn_levelup", nil, Vector2(163, 63), Vector2(308, 510), 16, false, true, SkinF.card_inherit_levelup),
      ComFuc.ComButton("btn_cover", nil, Vector2(163, 63), Vector2(308, 510), 16, false, true, SkinF.card_inherit_cover),
      ComFuc.ComCheckBox("cover_1", Cover_Text[1], Vector2(130, 20), Vector2(26, 303), 16, colw),
      ComFuc.ComCheckBox("cover_2", Cover_Text[2], Vector2(130, 20), Vector2(216, 303), 16, colw),
      ComFuc.ComCheckBox("cover_3", Cover_Text[3], Vector2(130, 20), Vector2(346, 303), 16, colw),
      ComFuc.MasterMetrial("mastery", 1, Vector2(20, 341)),
      ComFuc.MasterMetrial("mastery", 2, Vector2(250, 341)),
      ComFuc.MasterMetrial("mastery", 3, Vector2(20, 421)),
      ComFuc.MasterMetrial("mastery", 4, Vector2(250, 421)),
      Gui.Label("inherit_opTip")({
        Size = Vector2(455, 165),
        Location = Vector2(15, 338),
        BackgroundColor = colw,
        Skin = SkinF.personalInfo_226,
        FontSize = 16,
        AutoWrap = true,
        TextPadding = Vector4(12, 8, 12, 8)
      }),
      ComLabel(nil, " " .. GetUTF8Text("UI_lobby_explore_inherit_cost"), Vector2(80, 20), Vector2(30, 533), 0, 16, colw),
      ComControl(nil, Vector2(110, 30), Vector2(110, 530), 255, SkinF.personalInfo_215),
      ComLabel("inherit_cost", "0", Vector2(110, 30), Vector2(102, 530), 0, 16, colw, "kAlignRightMiddle"),
      ComControl(nil, Vector2(30, 30), Vector2(220, 530), 255, SkinF.shop_02)
    }),
    ComFuc.PopControl("inheritWarning1_m", Vector2(346, 206), GetUTF8Text("UI_avatar_avatar_UI_06"), 40, 0),
    Gui.Control("inheritWarning2_m")({
      Dock = "kDockFill",
      ComFuc.ComControl(nil, Vector2(322, 96), Vector2(12, 0), 255, SkinF.battle_005),
      ComFuc.ComButton("insertTip_ok", GetUTF8Text("button_common_Cancel"), Vector2(84, 44), Vector2(222, 102)),
      ComFuc.ComLabel("inheritWarning2_text", GetUTF8Text("tips_lobby_explore_inherit_surpass"), Vector2(270, 80), Vector2(40, 8), 0, 16, ARGB(255, 156, 96, 14), "kAlignLeftMiddle")
    }),
    Gui.Control("inheritStateCtrl")({
      Size = Vector2(289, 296),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_209[1],
      ComControl("inheritStateCtrl_son", Vector2(289, 296), Vector2(0, 0), 255, SkinF.personalInfo_209[6])
    })
  })
end
local get_avatar_attrib_bound, get_avatar_attrib = function(data)
  materialCardExploreAttrib = {}
  table.insert(materialCardExploreAttrib, data.stamina)
  table.insert(materialCardExploreAttrib, data.armor)
  table.insert(materialCardExploreAttrib, data.cureQuantity)
  table.insert(materialCardExploreAttrib, data.recovery)
end, GetUTF8Text("button_avatar_heroskill_cover")

function get_avatar_attrib(data)
  targetCardExploreAttrib = {}
  table.insert(targetCardExploreAttrib, data.stamina)
  table.insert(targetCardExploreAttrib, data.armor)
  table.insert(targetCardExploreAttrib, data.cureQuantity)
  table.insert(targetCardExploreAttrib, data.recovery)
end

local timeElapse, TimerRefreshGrowBar = 0, 0
local TimerRefreshGrowBar, DisplayGrowBar = function()
  if timeElapse < growBarLimit then
    local addStep = 1
    yellowBar = PersonalInfo.ui.card_attrib_inherit_blue_bar.Size
    PersonalInfo.ui.card_attrib_inherit_blue_bar.Size = Vector2(yellowBar.x + addStep, 32)
  else
    game.TimerMgr:RemoveTimer(timerGrowBar)
    timerGrowBar = nil
  end
  timeElapse = timeElapse + 1
end, GetUTF8Text("button_avatar_heroskill_cover")

function DisplayGrowBar()
  if useConvert == 0 then
    timeElapse = 0
    growBarLimit = actualAddition
    PersonalInfo.ui.card_attrib_inherit_blue_bar.Size = Vector2(oldAddition, 32)
    PersonalInfo.ui.card_attrib_inherit_yellow_bar.Size = Vector2(actualAddition + oldAddition, 32)
    game.TimerMgr:RemoveTimer(timerGrowBar)
    timerGrowBar = nil
    timerGrowBar = game.TimerMgr:AddTimer(0.02)
    timerGrowBar.EventOnTimer = TimerRefreshGrowBar
  else
    PersonalInfo.ui.card_attrib_inherit_yellow_bar.Size = Vector2(450, 32)
  end
end

local TimerRefreshPoping, SetInheritFinish = function()
  if reinK <= 21 then
    if reinK <= 10 then
      local ts = reinK / 10
      if reinK <= 5 then
        ts = reinK / 5
        PersonalInfo.ui.inheritStateCtrl.Size = Vector2(289 * ts, 296 * ts)
        PersonalInfo.ui.inheritStateCtrl.Location = Vector2(ComFuc.locationChanged + (1200 - 289 * ts) * 0.5, (900 - 296 * ts) * 0.5)
        if isAddMore then
          PersonalInfo.ui.inheritStateCtrl_son.Size = Vector2(289 * ts, 296 * ts)
        end
      end
    end
    gui:PlayAudio("upgraded")
    reinK = reinK + 1
  else
    isAddMore = false
    game.TimerMgr:RemoveTimer(timerPopping)
    timerPopping = nil
    PersonalInfo.ui.inheritStateCtrl.Parent = nil
  end
end, function()
  if reinK <= 21 then
    if reinK <= 10 then
      local ts = reinK / 10
      if reinK <= 5 then
        ts = reinK / 5
        PersonalInfo.ui.inheritStateCtrl.Size = Vector2(289 * ts, 296 * ts)
        PersonalInfo.ui.inheritStateCtrl.Location = Vector2(ComFuc.locationChanged + (1200 - 289 * ts) * 0.5, (900 - 296 * ts) * 0.5)
        if isAddMore then
          PersonalInfo.ui.inheritStateCtrl_son.Size = Vector2(289 * ts, 296 * ts)
        end
      end
    end
    gui:PlayAudio("upgraded")
    reinK = reinK + 1
  else
    isAddMore = false
    game.TimerMgr:RemoveTimer(timerPopping)
    timerPopping = nil
    PersonalInfo.ui.inheritStateCtrl.Parent = nil
  end
end
local SetInheritFinish, GetCardProperty = function(p, name, size, lc)
  game.TimerMgr:RemoveTimer(timerPopping)
  timerPopping = nil
  reinK = 0
  isAddMore = true
  PersonalInfo.ui.inheritStateCtrl.Size = size
  PersonalInfo.ui.inheritStateCtrl.Location = lc
  PersonalInfo.ui.inheritStateCtrl_son.Visible = p == 1 and isAddMore
  if p == 1 and isAddMore then
    PersonalInfo.ui.inheritStateCtrl.Skin = SkinF.personalInfo_209[5]
  else
    PersonalInfo.ui.inheritStateCtrl.Skin = SkinF.personalInfo_209[p]
  end
  PersonalInfo.ui.inheritStateCtrl.Parent = gui
  gui:AddParticle(name, Vector2(ComFuc.locationChanged + 600, 450), Vector3(0, 1, 0))
  timerPopping = game.TimerMgr:AddTimer(0.05)
  timerPopping.EventOnTimer = TimerRefreshPoping
end, GetUTF8Text("button_avatar_heroskill_cover")
local GetCardProperty, DealBtnShow = function()
  local level = targetCardSelected.level
  for i = maxLevel, 1, -1 do
    for ii = 1, 4 do
      if cardPropertyTable["level_" .. i][ii].property == "stamina" then
        if cardPropertyTable["level_" .. i][ii].value * 1 >= targetCardSelected.Stamina then
          cardMaxProperty.Stamina = cardPropertyTable["level_" .. i][ii].value * 1
          if 1 < i then
            cardMinProperty.Stamina = cardPropertyTable["level_" .. i - 1][ii].value * 1
          else
            cardMinProperty.Stamina = 0
          end
        end
        if i == level then
          cardNowMaxProperty.Stamina = cardPropertyTable["level_" .. i][ii].value * 1
        end
      end
      if cardPropertyTable["level_" .. i][ii].property == "cureQuantity" then
        if cardPropertyTable["level_" .. i][ii].value * 1 >= targetCardSelected.Vitality then
          cardMaxProperty.Cure = cardPropertyTable["level_" .. i][ii].value * 1
          if 1 < i then
            cardMinProperty.Cure = cardPropertyTable["level_" .. i - 1][ii].value * 1
          else
            cardMinProperty.Cure = 0
          end
        end
        if i == level then
          cardNowMaxProperty.Cure = cardPropertyTable["level_" .. i][ii].value * 1
        end
      end
      if cardPropertyTable["level_" .. i][ii].property == "armor" then
        if cardPropertyTable["level_" .. i][ii].value * 1 >= targetCardSelected.Armor then
          cardMaxProperty.Armor = cardPropertyTable["level_" .. i][ii].value * 1
          if 1 < i then
            cardMinProperty.Armor = cardPropertyTable["level_" .. i - 1][ii].value * 1
          else
            cardMinProperty.Armor = 0
          end
        end
        if i == level then
          cardNowMaxProperty.Armor = cardPropertyTable["level_" .. i][ii].value * 1
        end
      end
      if cardPropertyTable["level_" .. i][ii].property == "recovery" then
        if cardPropertyTable["level_" .. i][ii].value * 1 >= targetCardSelected.Recovery then
          cardMaxProperty.Recovery = cardPropertyTable["level_" .. i][ii].value * 1
          if 1 < i then
            cardMinProperty.Recovery = cardPropertyTable["level_" .. i - 1][ii].value * 1
          else
            cardMinProperty.Recovery = 0
          end
        end
        if i == level then
          cardNowMaxProperty.Recovery = cardPropertyTable["level_" .. i][ii].value * 1
        end
      end
    end
  end
end, GetUTF8Text("button_avatar_heroskill_cover")
local DealBtnShow, Btn_LevelupEnable = function()
  local Is_CoverCheck = false
  if targetCardSel and targetCardSelected.Stamina >= cardNowMaxProperty.Stamina and targetCardSelected.Armor >= cardNowMaxProperty.Armor and targetCardSelected.Vitality >= cardNowMaxProperty.Cure and targetCardSelected.Recovery >= cardNowMaxProperty.Recovery then
    PersonalInfo.ui.btn_inherit.Visible = false
    PersonalInfo.ui.btn_levelup.Visible = true
  else
    PersonalInfo.ui.btn_levelup.Visible = false
    for i = 1, 3 do
      if PersonalInfo.ui["cover_" .. i].Check then
        Is_CoverCheck = true
      end
    end
    if not Is_CoverCheck then
      PersonalInfo.ui.btn_inherit.Visible = true
    else
      PersonalInfo.ui.btn_cover.Visible = true
    end
  end
end, GetUTF8Text("button_avatar_heroskill_cover")
local Btn_LevelupEnable, Btn_InheritEnable = function()
  if PersonalInfo.ui.btn_levelup.Visible and targetCardSel and materialCardSel then
    PersonalInfo.ui.btn_levelup.Enable = true
  else
    PersonalInfo.ui.btn_levelup.Enable = false
  end
end, GetUTF8Text("button_avatar_heroskill_cover")
local Btn_InheritEnable, DealCloneEnable = function()
  if PersonalInfo.ui.btn_inherit.Visible and targetCardSel and materialCardSel then
    PersonalInfo.ui.btn_inherit.Enable = true
  else
    PersonalInfo.ui.btn_inherit.Enable = false
  end
end, GetUTF8Text("button_avatar_heroskill_cover")
local DealCloneEnable, Deal2Buttons = function()
  if targetCardSel and materialCardSel then
    for i = 1, 3 do
      PersonalInfo.ui["cover_" .. i].Enable = true
    end
  else
    for i = 1, 3 do
      PersonalInfo.ui["cover_" .. i].Check = false
      PersonalInfo.ui["cover_" .. i].Enable = false
    end
  end
end, GetUTF8Text("button_avatar_heroskill_cover")
local Deal2Buttons, GetCardPropertyTable = function()
  if useConvert == 1 and targetCardSel and materialCardSel then
    return
  end
  useConvert = 0
  PersonalInfo.ui.btn_cover.Visible = false
  PersonalInfo.ui.btn_cover.Visible = false
  DealBtnShow()
  Btn_LevelupEnable()
  Btn_InheritEnable()
  DealCloneEnable()
end, GetUTF8Text("button_avatar_heroskill_cover")
local GetCardPropertyTable, ClearCardPropertyTable = function(data)
  if maxPropertyTableIsEmpty then
    maxPropertyTableIsEmpty = false
    for _, v in ipairs(data.MaxProperty) do
      cardPropertyTable["level_" .. v.level] = v[1]
      maxLevel = maxLevel + 1
    end
  end
  GetCardProperty()
  Deal2Buttons()
end, GetUTF8Text("button_avatar_heroskill_cover")
local ClearCardPropertyTable, rpc_get_card_property_table = function()
  if not maxPropertyTableIsEmpty then
    maxPropertyTableIsEmpty = true
    for i = maxLevel, 1, -1 do
      cardPropertyTable["level_" .. i] = nil
    end
    maxLevel = 0
  end
end, GetUTF8Text("button_avatar_heroskill_cover")
local rpc_get_card_property_table, ClearCardProperty = function()
  rpc.safecall("player_card_max", {
    tid = targetCardSel.pid
  }, GetCardPropertyTable)
end, GetUTF8Text("button_avatar_heroskill_cover")
local ClearCardProperty, CleanInsertCard = function()
  cardMaxProperty = {
    Recovery = 0,
    Cure = 0,
    Armor = 0,
    Stamina = 0
  }
  cardMinProperty = {
    Recovery = 0,
    Cure = 0,
    Armor = 0,
    Stamina = 0
  }
  cardNowMaxProperty = {
    Recovery = 0,
    Cure = 0,
    Armor = 0,
    Stamina = 0
  }
end, GetUTF8Text("button_avatar_heroskill_cover")
local CleanInsertCard, DisablingAttribBtn = function(is0, is1, type)
  if type == "targetSlot" then
    PersonalInfo.ui.insert_targetcard_p.Visible = false
  else
    PersonalInfo.ui.insert_materialcard_p.Visible = false
  end
end, GetUTF8Text("button_avatar_heroskill_cover")
local DisablingAttribBtn, DealTargetCardAttrib = function()
  if targetCardSel == nil or materialCardSel == nil then
    return
  end
  if dealTargetCardReturn and dealMaterialCardReturn then
    if useConvert == 0 and not Is_NoUseAddition then
      cntDisabledInheritAttrib = 0
      flowAttribIndex = {}
      if tmpTargetCardSelected.Stamina >= cardNowMaxProperty.Stamina or materialCardSelected.StaminaEnable == false then
        PersonalInfo.ui.btn_attribute_inherit_1.Enable = false
        PersonalInfo.ui.btn_attribute_inherit_1.Visible = false
        cntDisabledInheritAttrib = cntDisabledInheritAttrib + 1
        PersonalInfo.ui.msg_attribute_inherit_1.Enable = true
      else
        PersonalInfo.ui.btn_attribute_inherit_1.Enable = true
        PersonalInfo.ui.btn_attribute_inherit_1.Visible = true
        table.insert(flowAttribIndex, 1)
        PersonalInfo.ui.msg_attribute_inherit_1.Enable = false
      end
      if tmpTargetCardSelected.Armor >= cardNowMaxProperty.Armor or materialCardSelected.AmorEnable == false then
        PersonalInfo.ui.btn_attribute_inherit_2.Enable = false
        PersonalInfo.ui.btn_attribute_inherit_2.Visible = false
        cntDisabledInheritAttrib = cntDisabledInheritAttrib + 1
        PersonalInfo.ui.msg_attribute_inherit_2.Enable = true
      else
        PersonalInfo.ui.btn_attribute_inherit_2.Enable = true
        PersonalInfo.ui.btn_attribute_inherit_2.Visible = true
        table.insert(flowAttribIndex, 2)
        PersonalInfo.ui.msg_attribute_inherit_2.Enable = false
      end
      if tmpTargetCardSelected.Vitality >= cardNowMaxProperty.Cure or materialCardSelected.VitalityEnable == false then
        PersonalInfo.ui.btn_attribute_inherit_3.Enable = false
        PersonalInfo.ui.btn_attribute_inherit_3.Visible = false
        cntDisabledInheritAttrib = cntDisabledInheritAttrib + 1
        PersonalInfo.ui.msg_attribute_inherit_3.Enable = true
      else
        PersonalInfo.ui.btn_attribute_inherit_3.Enable = true
        PersonalInfo.ui.btn_attribute_inherit_3.Visible = true
        table.insert(flowAttribIndex, 3)
        PersonalInfo.ui.msg_attribute_inherit_3.Enable = false
      end
      if tmpTargetCardSelected.Recovery >= cardNowMaxProperty.Recovery or materialCardSelected.RecoveryEnable == false then
        PersonalInfo.ui.btn_attribute_inherit_4.Enable = false
        PersonalInfo.ui.btn_attribute_inherit_4.Visible = false
        cntDisabledInheritAttrib = cntDisabledInheritAttrib + 1
        PersonalInfo.ui.msg_attribute_inherit_4.Enable = true
      else
        PersonalInfo.ui.btn_attribute_inherit_4.Enable = true
        PersonalInfo.ui.btn_attribute_inherit_4.Visible = true
        table.insert(flowAttribIndex, 4)
        PersonalInfo.ui.msg_attribute_inherit_4.Enable = false
      end
    else
      for k = 1, 4 do
        PersonalInfo.ui["btn_attribute_inherit_" .. k].Enable = true
        PersonalInfo.ui["btn_attribute_inherit_" .. k].Visible = true
        PersonalInfo.ui["msg_attribute_inherit_" .. k].Enable = false
      end
    end
  else
  end
end, GetUTF8Text("button_avatar_heroskill_cover")
local DealTargetCardAttrib, DealMaterialCardAttrib = function(data)
  targetCardSelected.Stamina = data.stamina or 0
  targetCardSelected.Vitality = data.cureQuantity or 0
  targetCardSelected.Armor = data.armor or 0
  targetCardSelected.Recovery = data.recovery or 0
  targetCardSelected.level = data.level or 0
  rpc_get_card_property_table()
  dealTargetCardReturn = true
  DisablingAttribBtn()
end, GetUTF8Text("button_avatar_heroskill_cover")
local DealMaterialCardAttrib, DetectCardsAttrib = function(data)
  materialCardSelected.Stamina = data.stamina or 0
  materialCardSelected.Vitality = data.cureQuantity or 0
  materialCardSelected.Armor = data.armor or 0
  materialCardSelected.Recovery = data.recovery or 0
  materialCardSelected.level = data.level or 0
  materialCardSelected.StaminaEnable = false
  materialCardSelected.AmorEnable = false
  materialCardSelected.VitalityEnable = false
  materialCardSelected.RecoveryEnable = false
  for _, v in ipairs(data.sysAvatarPlus) do
    if v.property == "stamina" then
      materialCardSelected.StaminaEnable = true
    elseif v.property == "armor" then
      materialCardSelected.AmorEnable = true
    elseif v.property == "cureQuantity" then
      materialCardSelected.VitalityEnable = true
    elseif v.property == "recovery" then
      materialCardSelected.RecoveryEnable = true
    end
  end
  dealMaterialCardReturn = true
  DisablingAttribBtn()
  Deal2Buttons()
end, GetUTF8Text("button_avatar_heroskill_cover")
local DetectCardsAttrib, ClearCardAttrib = function(type)
  if type == "target_card" then
    if targetCardSel and targetCardSel.pid then
      dealTargetCardReturn = false
      rpc.safecall("tip_player_avatar", {
        pid = targetCardSel.pid,
        t = 5
      }, DealTargetCardAttrib)
    end
    if targetCardSel and targetCardSel.pid then
      rpc.safecall("tip_player_avatar", {
        t = 5,
        pid = targetCardSel.pid
      }, get_avatar_attrib)
    end
  elseif type == "material_card" then
    if materialCardSel and materialCardSel.pid then
      dealMaterialCardReturn = false
      rpc.safecall("tip_player_avatar", {
        pid = materialCardSel.pid,
        t = 5
      }, DealMaterialCardAttrib)
    end
    if materialCardSel and materialCardSel.pid then
      rpc.safecall("tip_player_avatar", {
        t = 5,
        pid = materialCardSel.pid
      }, get_avatar_attrib_bound)
    end
  end
end, GetUTF8Text("button_avatar_heroskill_cover")

function ClearCardAttrib()
  PersonalInfo.ui.card_attrib_inherit_blue_bar.Size = Vector2(0, 32)
  PersonalInfo.ui.card_attrib_inherit_yellow_bar.Size = Vector2(0, 32)
  for i = 1, 4 do
    PersonalInfo.ui["btn_attribute_inherit_" .. i].PushDown = false
    PersonalInfo.ui["label_abilities_inherit_" .. i].TextColor = ComFuc.coly
  end
end

local ClearInheritStatistics, ShowMoveCard = function()
  ClearCardAttrib()
  targetCardDpt = {}
  materialCardDpt = {}
  targetCardExploreAttrib = {}
  materialCardExploreAttrib = {}
  targetCardSel = nil
  materialCardSel = nil
  oldAddition = nil
  actualAddition = nil
  dealTargetCardReturn = false
  dealMaterialCardReturn = false
  cntDisabledInheritAttrib = 0
  isEnough = true
  inherit_cost = "0"
  flowAttribIndex = {}
  timeCnt_TimerRefreshShining2 = 0
  CleanInsertCard(true, true, "targetSlot")
  CleanInsertCard(true, true, "materialSlot")
  Deal2Buttons()
  for i = 1, 4 do
    PersonalInfo.ui["btn_attribute_inherit_" .. i].Enable = true
    PersonalInfo.ui["msg_attribute_inherit_" .. i].Enable = false
  end
  PersonalInfo.ui.inherit_opTip.Text = GetUTF8Text("UI_datalist_explore_inherit_01")
  PersonalInfo.ui.inherit_opTip.Visible = true
end, function()
  ClearCardAttrib()
  targetCardDpt = {}
  materialCardDpt = {}
  targetCardExploreAttrib = {}
  materialCardExploreAttrib = {}
  targetCardSel = nil
  materialCardSel = nil
  oldAddition = nil
  actualAddition = nil
  dealTargetCardReturn = false
  dealMaterialCardReturn = false
  cntDisabledInheritAttrib = 0
  isEnough = true
  inherit_cost = "0"
  flowAttribIndex = {}
  timeCnt_TimerRefreshShining2 = 0
  CleanInsertCard(true, true, "targetSlot")
  CleanInsertCard(true, true, "materialSlot")
  Deal2Buttons()
  for i = 1, 4 do
    PersonalInfo.ui["btn_attribute_inherit_" .. i].Enable = true
    PersonalInfo.ui["msg_attribute_inherit_" .. i].Enable = false
  end
  PersonalInfo.ui.inherit_opTip.Text = GetUTF8Text("UI_datalist_explore_inherit_01")
  PersonalInfo.ui.inherit_opTip.Visible = true
end
local ShowMoveCard, OnMouseMove = function(size, lc, up, grade, subType)
  ComFuc.ShowMoveCard(size, lc, up, grade, PersonalInfo.ui.moveCard, PersonalInfo.ui.moveCard_son, PersonalInfo.ui.moveCard_s, PersonalInfo.ui.moveCard_c, false, subType)
end, GetUTF8Text("button_avatar_heroskill_cover")
local OnMouseMove, LighterOrNarmal = function(up, isCard)
  ComFuc.OnMouseMove(up, isCard, PersonalInfo.ui.moveCard, PersonalInfo.ui.moveControl)
end, GetUTF8Text("button_avatar_heroskill_cover")

function LighterOrNarmal(isHigh, type, subtype, p, q)
  if type == 3 then
    if subtype == "targetSlot" then
      PersonalInfo.ui.insert_targetcard_hight.IsReady = isHigh
      PersonalInfo.ui.insert_targetcard_hight.Visible = isHigh
    else
      PersonalInfo.ui.insert_materialcard_hight.IsReady = isHigh
      PersonalInfo.ui.insert_materialcard_hight.Visible = isHigh
    end
  end
end

local ShowInheritPersonCard, ReleaseCardToSlot = function(dt, ID, is0, is1, subtype)
  CleanInsertCard(is0, is1, subtype)
  if subtype == "targetSlot" then
    PersonalInfo.ui.insert_targetcard_p.Visible = true
    if dt then
      targetCardSel = dt
      lg:CopyStaticCard(ID, 11)
      lg:UpdateStaticCardByInfoString(11, dt.position)
      ComFuc.ShowUpgradeLevel(dt, 5, PersonalInfo.ui.insert_targetcard_level, PersonalInfo.ui.insert_targetcard_level_text)
      PersonalInfo.ui.insert_targetcard_p.Skin = SkinF.personalInfo_quality[dt.grade]
      
      function PersonalInfo.ui.insert_targetcard_s2.EventMouseEnter(sender, e)
        Tip.SetRpc(tip_player_interface[5], {
          t = 5,
          pid = dt.pid
        })
        Tip.SetUseDescription(false)
        Tip.SetOwner(sender)
      end
      
      if dt.subType == 1 then
        PersonalInfo.ui.insert_targetcard.Skin = SkinF.personalInfo_143
        PersonalInfo.ui.insert_targetcard_level.Skin = SkinF.avatar_level
      elseif dt.subType == 2 then
        PersonalInfo.ui.insert_targetcard.Skin = SkinF.personalInfo_261
        PersonalInfo.ui.insert_targetcard_level.Skin = SkinF.avatar_level_hero
      end
    end
  else
    PersonalInfo.ui.insert_materialcard_p.Visible = true
    if dt then
      materialCardSel = dt
      lg:CopyStaticCard(ID, 12)
      lg:UpdateStaticCardByInfoString(12, dt.position)
      ComFuc.ShowUpgradeLevel(dt, 5, PersonalInfo.ui.insert_materialcard_level, PersonalInfo.ui.insert_materialcard_level_text)
      PersonalInfo.ui.insert_materialcard_p.Skin = SkinF.personalInfo_quality[dt.grade]
      
      function PersonalInfo.ui.insert_materialcard_s2.EventMouseEnter(sender, e)
        Tip.SetRpc(tip_player_interface[6], {
          t = 5,
          pid = dt.pid
        })
        Tip.SetUseDescription(false)
        Tip.SetOwner(sender)
      end
      
      if dt.subType == 1 then
        PersonalInfo.ui.insert_materialcard.Skin = SkinF.personalInfo_143
        PersonalInfo.ui.insert_materialcard_level.Skin = SkinF.avatar_level
      elseif dt.subType == 2 then
        PersonalInfo.ui.insert_materialcard.Skin = SkinF.personalInfo_261
        PersonalInfo.ui.insert_materialcard_level.Skin = SkinF.avatar_level_hero
      end
    end
  end
end, function(dt, ID, is0, is1, subtype)
  CleanInsertCard(is0, is1, subtype)
  if subtype == "targetSlot" then
    PersonalInfo.ui.insert_targetcard_p.Visible = true
    if dt then
      targetCardSel = dt
      lg:CopyStaticCard(ID, 11)
      lg:UpdateStaticCardByInfoString(11, dt.position)
      ComFuc.ShowUpgradeLevel(dt, 5, PersonalInfo.ui.insert_targetcard_level, PersonalInfo.ui.insert_targetcard_level_text)
      PersonalInfo.ui.insert_targetcard_p.Skin = SkinF.personalInfo_quality[dt.grade]
      
      function PersonalInfo.ui.insert_targetcard_s2.EventMouseEnter(sender, e)
        Tip.SetRpc(tip_player_interface[5], {
          t = 5,
          pid = dt.pid
        })
        Tip.SetUseDescription(false)
        Tip.SetOwner(sender)
      end
      
      if dt.subType == 1 then
        PersonalInfo.ui.insert_targetcard.Skin = SkinF.personalInfo_143
        PersonalInfo.ui.insert_targetcard_level.Skin = SkinF.avatar_level
      elseif dt.subType == 2 then
        PersonalInfo.ui.insert_targetcard.Skin = SkinF.personalInfo_261
        PersonalInfo.ui.insert_targetcard_level.Skin = SkinF.avatar_level_hero
      end
    end
  else
    PersonalInfo.ui.insert_materialcard_p.Visible = true
    if dt then
      materialCardSel = dt
      lg:CopyStaticCard(ID, 12)
      lg:UpdateStaticCardByInfoString(12, dt.position)
      ComFuc.ShowUpgradeLevel(dt, 5, PersonalInfo.ui.insert_materialcard_level, PersonalInfo.ui.insert_materialcard_level_text)
      PersonalInfo.ui.insert_materialcard_p.Skin = SkinF.personalInfo_quality[dt.grade]
      
      function PersonalInfo.ui.insert_materialcard_s2.EventMouseEnter(sender, e)
        Tip.SetRpc(tip_player_interface[6], {
          t = 5,
          pid = dt.pid
        })
        Tip.SetUseDescription(false)
        Tip.SetOwner(sender)
      end
      
      if dt.subType == 1 then
        PersonalInfo.ui.insert_materialcard.Skin = SkinF.personalInfo_143
        PersonalInfo.ui.insert_materialcard_level.Skin = SkinF.avatar_level
      elseif dt.subType == 2 then
        PersonalInfo.ui.insert_materialcard.Skin = SkinF.personalInfo_261
        PersonalInfo.ui.insert_materialcard_level.Skin = SkinF.avatar_level_hero
      end
    end
  end
end
local ReleaseCardToSlot, CanAttribInherit = function(i, isTargetCard, c)
  gui:PlayAudio("putdown")
  if isTargetCard then
    LighterOrNarmal(false, 3, "targetSlot")
    if not c or IsInAABB(c, Vector2(80, 351), Vector2(104, 163)) then
      targetCardSel = targetCardDpt[i]
      if materialCardSel == nil or targetCardSel == nil then
        PersonalInfo.ui.inherit_opTip.Visible = true
      else
        PersonalInfo.ui.inherit_opTip.Visible = false
      end
      ShowInheritPersonCard(targetCardDpt[i], PersonalInfo.ui["targetCard_card_s_" .. i].ID, false, true, "targetSlot")
      rpc_storage_storage_list_no_empty_target_card(PersonalInfo.ui.pb_targetCard.CurrIndex)
      rpc_refit_need_inherit(true)
    end
  else
    LighterOrNarmal(false, 3, "materialSlot")
    if not c or IsInAABB(c, Vector2(379, 351), Vector2(104, 163)) then
      materialCardSel = materialCardDpt[i]
      if materialCardSel == nil or targetCardSel == nil then
        PersonalInfo.ui.inherit_opTip.Visible = true
      else
        PersonalInfo.ui.inherit_opTip.Visible = false
      end
      ShowInheritPersonCard(materialCardDpt[i], PersonalInfo.ui["materialCard_card_s_" .. i].ID, false, true, "materialSlot")
      rpc_storage_storage_list_no_empty_material_card(PersonalInfo.ui.pb_materialCard.CurrIndex)
      rpc_refit_need_inherit(false)
    end
  end
  PersonalInfo.ui.moveCard.Parent = nil
  PersonalInfo.ui.moveCard_s.ID = -1
  DetectCardsAttrib("target_card")
  DetectCardsAttrib("material_card")
  ClearCardAttrib()
end, GetUTF8Text("button_avatar_heroskill_cover")
local CanAttribInherit, StartInheritting = function()
  for i = 1, 4 do
    if PersonalInfo.ui["btn_attribute_inherit_" .. i].Enable == true then
      return true
    end
  end
  return false
end, GetUTF8Text("button_avatar_heroskill_cover")
local StartInheritting, DisplayTransmission = function()
end, GetUTF8Text("button_avatar_heroskill_cover")
local DisplayTransmission, TimerRefreshAttribFlow = function()
  if useConvert == 0 then
    for i = 1, 2 do
      PersonalInfo.ui["inherit_" .. inheritAttribSel .. "_" .. i].Visible = true
    end
  else
    for j = 1, 4 do
      for i = 1, 2 do
        PersonalInfo.ui["inherit_" .. j .. "_" .. i].Visible = true
      end
    end
  end
end, GetUTF8Text("button_avatar_heroskill_cover")
local TimerRefreshAttribFlow, ResetDataDisplay = function()
  if totalTime <= 3 * (4 - cntDisabledInheritAttrib) then
    for i = 1, 4 do
      PersonalInfo.ui["btn_attribute_inherit_" .. i].PushDown = false
      PersonalInfo.ui["label_abilities_inherit_" .. i].TextColor = ComFuc.coly
    end
    if flowIdxCnt == nil then
      game.TimerMgr:RemoveTimer(timerAttrib)
      timerAttrib = nil
      return
    end
    if cntDisabledInheritAttrib ~= 4 then
      local shiningBtnIdx = math.fmod(flowIdxCnt, 4 - cntDisabledInheritAttrib)
      if totalTime == 0 then
        while flowAttribIndex[shiningBtnIdx + 1] ~= inheritAttribSel do
          flowIdxCnt = flowIdxCnt + 1
          shiningBtnIdx = math.fmod(flowIdxCnt, 4 - cntDisabledInheritAttrib)
        end
      end
      flowIdxCnt = flowIdxCnt + 1
      local shiningBtn = flowAttribIndex[shiningBtnIdx + 1]
      PersonalInfo.ui["btn_attribute_inherit_" .. shiningBtn].PushDown = true
      PersonalInfo.ui["label_abilities_inherit_" .. shiningBtn].TextColor = color_coffee
    end
  else
    game.TimerMgr:RemoveTimer(timerAttrib)
    timerAttrib = nil
    DisplayTransmission()
  end
  totalTime = totalTime + 1
end, GetUTF8Text("button_avatar_heroskill_cover")

function ResetDataDisplay()
  PersonalInfo.ui.card_attrib_inherit_yellow_bar.Size = Vector2(0, 32)
  PersonalInfo.ui.card_attrib_inherit_blue_bar.Size = Vector2(0, 32)
  for i = 1, 4 do
    PersonalInfo.ui["btn_attribute_inherit_" .. i].PushDown = false
    PersonalInfo.ui["label_abilities_inherit_" .. i].TextColor = ComFuc.coly
  end
  PersonalInfo.ui.label_card_increase_percent.Text = "0%"
  PersonalInfo.ui.real_increase_percent.Text = ""
  PersonalInfo.ui.label_card_increasebound_percent.Text = "+0%"
  PersonalInfo.ui.inherit_cost.Text = "0"
  PersonalInfo.ui.inherit_opTip.Visible = true
end

local timeCnt_TimerRefreshShining2, TimerRefreshShining2 = 0, GetUTF8Text("button_avatar_heroskill_cover")

function TimerRefreshShining2()
  if timeCnt_TimerRefreshShining2 < 5 then
    for i = 1, 4 do
      PersonalInfo.ui["btn_attribute_inherit_" .. i].PushDown = not PersonalInfo.ui["btn_attribute_inherit_" .. i].PushDown
      PersonalInfo.ui["btn_attribute_inherit_" .. i].Visible = true
      PersonalInfo.ui["btn_attribute_inherit_" .. i].Enable = true
      if PersonalInfo.ui["btn_attribute_inherit_" .. i].PushDown == true then
        PersonalInfo.ui["label_abilities_inherit_" .. i].TextColor = color_coffee
      else
        PersonalInfo.ui["label_abilities_inherit_" .. i].TextColor = ComFuc.coly
      end
    end
  else
    game.TimerMgr:RemoveTimer(timerShining2)
    timerShining2 = nil
    timeCnt_TimerRefreshShining2 = 0
  end
  timeCnt_TimerRefreshShining2 = timeCnt_TimerRefreshShining2 + 1
end

local DisplayShiningAttrib, TimerStayAWhile = function(inheritSlot)
  if useConvert == 0 then
    if not Is_JewelOrSkill then
      totalTime = 0
      for i, v in pairs(flowAttribIndex) do
        if inheritAttribSel == v then
          flowIdxCnt = i - 1
          break
        else
          flowIdxCnt = 0
        end
      end
      if cntDisabledInheritAttrib < 4 then
        game.TimerMgr:RemoveTimer(timerAttrib)
        timerAttrib = nil
        timerAttrib = game.TimerMgr:AddTimer(0.15)
        timerAttrib.EventOnTimer = TimerRefreshAttribFlow
      end
    end
  else
    for i = 1, 4 do
      PersonalInfo.ui["btn_attribute_inherit_" .. i].PushDown = false
      PersonalInfo.ui["label_abilities_inherit_" .. i].TextColor = ComFuc.coly
    end
    game.TimerMgr:RemoveTimer(timerShining2)
    timerShining2 = nil
    timerShining2 = game.TimerMgr:AddTimer(0.25)
    timerShining2.EventOnTimer = TimerRefreshShining2
    DisplayTransmission()
  end
end, function(inheritSlot)
  if useConvert == 0 then
    if not Is_JewelOrSkill then
      totalTime = 0
      for i, v in pairs(flowAttribIndex) do
        if inheritAttribSel == v then
          flowIdxCnt = i - 1
          break
        else
          flowIdxCnt = 0
        end
      end
      if cntDisabledInheritAttrib < 4 then
        game.TimerMgr:RemoveTimer(timerAttrib)
        timerAttrib = nil
        timerAttrib = game.TimerMgr:AddTimer(0.15)
        timerAttrib.EventOnTimer = TimerRefreshAttribFlow
      end
    end
  else
    for i = 1, 4 do
      PersonalInfo.ui["btn_attribute_inherit_" .. i].PushDown = false
      PersonalInfo.ui["label_abilities_inherit_" .. i].TextColor = ComFuc.coly
    end
    game.TimerMgr:RemoveTimer(timerShining2)
    timerShining2 = nil
    timerShining2 = game.TimerMgr:AddTimer(0.25)
    timerShining2.EventOnTimer = TimerRefreshShining2
    DisplayTransmission()
  end
end
local TimerStayAWhile, StayAWhile = function()
  if stayAWhileTimeCnt <= 20 then
    if inheritAttribSel ~= 0 and stayAWhileTimeCnt == 7 then
      PersonalInfo.ui.label_card_increase_percent.Text = math.floor(increaseBaseNum * 10000) / 100 .. "%"
      PersonalInfo.ui.real_increase_percent.Text = "+" .. math.floor((realIncreasePercent - increasePercent) * 10000) / 100 .. "%"
      PersonalInfo.ui.label_card_increasebound_percent.Text = math.floor(increaseBoundBaseNum * 10000) / 100 .. "%"
      DisplayGrowBar()
    end
  else
    tmpTargetCardSelected.Stamina = 0
    tmpTargetCardSelected.Vitality = 0
    tmpTargetCardSelected.Armor = 0
    tmpTargetCardSelected.Recovery = 0
    tmpTargetCardSelected.level = 0
    tmpCardMaxProperty.Recovery = 0
    tmpCardMaxProperty.Cure = 0
    tmpCardMaxProperty.Armor = 0
    tmpCardMaxProperty.Stamina = 0
    tmpCardMinProperty.Recovery = 0
    tmpCardMinProperty.Cure = 0
    tmpCardMinProperty.Armor = 0
    tmpCardMinProperty.Stamina = 0
    game.TimerMgr:RemoveTimer(timerStayWhile)
    timerStayWhile = nil
    SetInheritFinish(1, "ui_success", Vector2(0, 0), Vector2(ComFuc.locationChanged + 600, 450))
    PersonalInfo.ui.card_attrib_inherit_yellow_bar.Size = Vector2(oldAddition, 32)
    if useConvert == 0 then
      for i = 1, 2 do
        PersonalInfo.ui["inherit_" .. inheritAttribSel .. "_" .. i].Visible = false
      end
    else
      for j = 1, 4 do
        for i = 1, 2 do
          PersonalInfo.ui["inherit_" .. j .. "_" .. i].Visible = false
        end
      end
    end
    CleanInsertCard(true, true, "materialSlot")
    materialCardSel = nil
    dealMaterialCardReturn = false
    ResetDataDisplay()
    PersonalInfo.ui.coverControl3.Parent = nil
    if canLevelUp then
      PersonalInfo.ReinLevelUp()
      useConvert = 0
      canLevelUp = false
    end
    Deal2Buttons()
  end
  stayAWhileTimeCnt = stayAWhileTimeCnt + 1
end, GetUTF8Text("button_avatar_heroskill_cover")
local StayAWhile, TimerRefreshPolling = function()
  game.TimerMgr:RemoveTimer(timerStayWhile)
  timerStayWhile = nil
  stayAWhileTimeCnt = 0
  timerStayWhile = game.TimerMgr:AddTimer(0.1)
  timerStayWhile.EventOnTimer = TimerStayAWhile
end, GetUTF8Text("button_avatar_heroskill_cover")
local TimerRefreshPolling, DealInheritOK = function()
  if timerGrowBar == nil and timerAttrib == nil then
    game.TimerMgr:RemoveTimer(timerPolling)
    timerPolling = nil
    StayAWhile()
  end
end, GetUTF8Text("button_avatar_heroskill_cover")
local DealInheritOK, DealRequireInheritCost = function()
  game.TimerMgr:RemoveTimer(timerPolling)
  timerPolling = nil
  timerPolling = game.TimerMgr:AddTimer(0.1)
  timerPolling.EventOnTimer = TimerRefreshPolling
end, GetUTF8Text("button_avatar_heroskill_cover")
local DealRequireInheritCost, DealCover = function(data)
  PersonalInfo.ui.coverControl3.Parent = gui
  Is_JewelOrSkill = false
  for i = 2, 3 do
    if PersonalInfo.ui["cover_" .. i].Check then
      Is_JewelOrSkill = true
    end
  end
  if useConvert == 0 then
    if not Is_JewelOrSkill then
      if data.stamina ~= tmpTargetCardSelected.Stamina then
        inheritAttribSel = 1
        realIncreasePercent = data.stamina - tmpCardMinProperty.Stamina
      elseif data.cureQuantity ~= tmpTargetCardSelected.Vitality then
        inheritAttribSel = 3
        realIncreasePercent = data.cureQuantity - tmpCardMinProperty.Cure
      elseif data.armor ~= tmpTargetCardSelected.Armor then
        inheritAttribSel = 2
        realIncreasePercent = data.armor - tmpCardMinProperty.Armor
      else
        if data.recovery ~= tmpTargetCardSelected.Recovery then
          inheritAttribSel = 4
          realIncreasePercent = data.recovery - tmpCardMinProperty.Recovery
        else
        end
      end
    end
  else
    inheritAttribSel = 0
  end
  DisplayShiningAttrib(inheritAttribSel)
  if not Is_JewelOrSkill then
    if inheritAttribSel ~= 0 then
      if inheritAttribSel == 1 then
        increasePercent = tmpTargetCardSelected.Stamina - tmpCardMinProperty.Stamina
        increaseBaseNum = tmpCardMinProperty.Stamina
        increaseBoundPercent = cardNowMaxProperty.Stamina - tmpCardMinProperty.Stamina
        increaseBoundBaseNum = cardNowMaxProperty.Stamina
      elseif inheritAttribSel == 2 then
        increasePercent = tmpTargetCardSelected.Armor - tmpCardMinProperty.Armor
        increaseBaseNum = tmpCardMinProperty.Armor
        increaseBoundPercent = cardNowMaxProperty.Armor - tmpCardMinProperty.Armor
        increaseBoundBaseNum = cardNowMaxProperty.Armor
      elseif inheritAttribSel == 3 then
        increasePercent = tmpTargetCardSelected.Vitality - tmpCardMinProperty.Cure
        increaseBaseNum = tmpCardMinProperty.Cure
        increaseBoundPercent = cardNowMaxProperty.Cure - tmpCardMinProperty.Cure
        increaseBoundBaseNum = cardNowMaxProperty.Cure
      elseif inheritAttribSel == 4 then
        increasePercent = tmpTargetCardSelected.Recovery - tmpCardMinProperty.Recovery
        increaseBaseNum = tmpCardMinProperty.Recovery
        increaseBoundPercent = cardNowMaxProperty.Recovery - tmpCardMinProperty.Recovery
        increaseBoundBaseNum = cardNowMaxProperty.Recovery
      end
      oldAddition = math.floor(450 * (increasePercent / increaseBoundPercent))
      actualAddition = math.floor(450 * (realIncreasePercent / increaseBoundPercent))
      actualAddition = actualAddition - oldAddition
    else
      timerGrowBar = nil
      timerAttrib = nil
    end
  end
  rpc_storage_storage_list_no_empty_target_card(1)
  rpc_storage_storage_list_no_empty_material_card(1)
  DetectCardsAttrib("target_card")
  if useConvert == 0 then
    if not Is_JewelOrSkill then
      DealInheritOK()
    else
      SetInheritFinish(1, "ui_success", Vector2(0, 0), Vector2(ComFuc.locationChanged + 600, 450))
      CleanInsertCard(true, true, "materialSlot")
      materialCardSel = nil
      dealMaterialCardReturn = false
      ResetDataDisplay()
      PersonalInfo.ui.coverControl3.Parent = nil
      Deal2Buttons()
    end
  else
    DealInheritOK()
  end
end, GetUTF8Text("button_avatar_heroskill_cover")
local DealCover, InheritConfirmFunc_2 = function()
  local useConvert = 0
  for i = 1, 3 do
    if PersonalInfo.ui["cover_" .. i].Check then
      useConvert = useConvert + math.pow(2, i - 1)
    end
  end
  rpc.safecall("player_card_inherit", {
    tid = targetCardSel.pid,
    sid = materialCardSel.pid,
    cloneType = useConvert
  }, DealRequireInheritCost)
end, GetUTF8Text("button_avatar_heroskill_cover")
local InheritConfirmFunc_2, UpdateCloneBtn = function()
  local BranchMsg = {}
  local HostMsg
  local IsHaveNil = false
  for i = 1, 3 do
    if PersonalInfo.ui["cover_" .. i].Check and Is_NilCover[i] then
      HostMsg = "\"" .. Cover_Text[i] .. "\""
      BranchMsg[i] = Cover_Text[i]
      IsHaveNil = true
    end
  end
  if BranchMsg[1] and BranchMsg[2] and BranchMsg[3] then
    HostMsg = "\"" .. Cover_Text[1] .. "\"" .. "\n" .. "\"" .. Cover_Text[2] .. "\"" .. "\n" .. "\"" .. Cover_Text[3] .. "\""
  elseif BranchMsg[1] and BranchMsg[2] then
    HostMsg = "\"" .. Cover_Text[1] .. "\"" .. "\n" .. "\"" .. Cover_Text[2] .. "\""
  elseif BranchMsg[1] and BranchMsg[3] then
    HostMsg = "\"" .. Cover_Text[1] .. "\"" .. "\n" .. "\"" .. Cover_Text[3] .. "\""
  elseif BranchMsg[2] and BranchMsg[3] then
    HostMsg = "\"" .. Cover_Text[2] .. "\"" .. "\n" .. "\"" .. Cover_Text[3] .. "\""
  end
  if isLevelUp then
    useConvert = 1
    canLevelUp = isLevelUp
    isLevelUp = not isLevelUp
    rpc.safecall("player_card_inherit", {
      tid = targetCardSel.pid,
      sid = materialCardSel.pid,
      cloneType = 0
    }, DealRequireInheritCost)
  elseif IsHaveNil then
    MessageBox.ShowWithTwoButtons(HostMsg .. "\n" .. GetUTF8Text("msgbox_common_explore_inherit_bound"), GetUTF8Text("button_common_Accept"), GetUTF8Text("button_common_Cancel"), DealCover)
  else
    DealCover()
  end
end, GetUTF8Text("button_avatar_heroskill_cover")
local UpdateCloneBtn, DealGlistenBtn = function()
  PersonalInfo.ui.btn_cover.Visible = false
  PersonalInfo.ui.btn_cover.Visible = false
  DealBtnShow()
  Btn_LevelupEnable()
  Btn_InheritEnable()
end, GetUTF8Text("button_avatar_heroskill_cover")

function DealGlistenBtn(Is_Use)
  if Is_Use then
    for k = 1, 4 do
      PersonalInfo.ui["btn_attribute_inherit_" .. k].Enable = true
      PersonalInfo.ui["btn_attribute_inherit_" .. k].Visible = true
      PersonalInfo.ui["msg_attribute_inherit_" .. k].Enable = false
    end
  else
    for k = 1, 4 do
      PersonalInfo.ui["btn_attribute_inherit_" .. k].Enable = false
      PersonalInfo.ui["btn_attribute_inherit_" .. k].Visible = false
      PersonalInfo.ui["msg_attribute_inherit_" .. k].Enable = true
    end
  end
end

function PlayerCardInheritUICallback()
  PersonalInfo.ui.inheritStateCtrl.Parent = nil
  PersonalInfo.ui.inherit_opTip.Text = GetUTF8Text("UI_datalist_explore_inherit_01")
  PersonalInfo.ui.inherit_opTip.Visible = true
  PersonalInfo.ui.mastery_refit_buy_1.Visible = false
  PersonalInfo.ui.mastery_refit_buy_2.Visible = false
  PersonalInfo.ui.mastery_refit_buy_3.Visible = false
  Deal2Buttons()
  PersonalInfo.ui.insert_targetcard_p.Visible = false
  PersonalInfo.ui.insert_materialcard_p.Visible = false
  PersonalInfo.ui.inheritWarning2_text.AutoWrap = true
  PersonalInfo.ui.inheritWarning1_m.Parent = nil
  PersonalInfo.ui.inheritWarning2_m.Parent = PersonalInfo.ui.inheritWarning1_m_son
  LighterOrNarmal(false, 3, "targetSlot")
  LighterOrNarmal(false, 3, "materialSlot")
  for i = 1, 4 do
    PersonalInfo.ui["mastery_refit_buy_" .. i].EventClick = function(sender, e)
      if not QuickBuy then
        require("shop/quick_buy.lua")
      end
      if i == 3 then
        QuickBuy.Show({
          t = 3,
          st = "301",
          category = 3
        })
      elseif i == 4 then
        QuickBuy.Show({
          t = 3,
          st = "301",
          category = 6
        })
      elseif i == 5 then
        QuickBuy.Show({
          t = 3,
          st = "301",
          category = 7
        })
      end
      
      function QuickBuy.callback()
        refitMoveDir = 0
        rpc_refit_need_inherit(false)
      end
    end
  end
  
  function PersonalInfo.ui.insertTip_ok.EventClick(sender, e)
    PersonalInfo.ui.inheritWarning1_m.Parent = nil
    PersonalInfo.ui.inheritWarning2_m.Parent = nil
  end
  
  function PersonalInfo.ui.pb_targetCard.EventIndexChanged(sender, e)
    rpc_storage_storage_list_no_empty_target_card(sender.CurrIndex)
  end
  
  local PersonalInfo.ui.pb_materialCard.EventIndexChanged, FilterTmpTargetCard = function(sender, e)
    rpc_storage_storage_list_no_empty_material_card(sender.CurrIndex)
  end, PersonalInfo.ui.pb_materialCard
  local FilterTmpTargetCard, InheritOrCover = function()
    tmpTargetCardSelected.Stamina = targetCardSelected.Stamina
    tmpTargetCardSelected.Vitality = targetCardSelected.Vitality
    tmpTargetCardSelected.Armor = targetCardSelected.Armor
    tmpTargetCardSelected.Recovery = targetCardSelected.Recovery
    tmpTargetCardSelected.level = targetCardSelected.level
    tmpCardMaxProperty.Recovery = cardMaxProperty.Recovery
    tmpCardMaxProperty.Cure = cardMaxProperty.Cure
    tmpCardMaxProperty.Armor = cardMaxProperty.Armor
    tmpCardMaxProperty.Stamina = cardMaxProperty.Stamina
    tmpCardMinProperty.Recovery = cardMinProperty.Recovery
    tmpCardMinProperty.Cure = cardMinProperty.Cure
    tmpCardMinProperty.Armor = cardMinProperty.Armor
    tmpCardMinProperty.Stamina = cardMinProperty.Stamina
  end, function(sender, e)
    rpc_storage_storage_list_no_empty_material_card(sender.CurrIndex)
  end
  
  function InheritOrCover()
    local Is_cover = false
    if NewLead.leadVisible then
      ComFuc.TestIsFinishOneTask(ComFuc.quest_id[1])
      ComFuc.inherit_guide = false
      NewLead.ShowNewLeadNoLock(Vector2(521, 78), Vector2(72, 73), GetUTF8Text("UI_common_Click"), 1)
    end
    for i = 1, 3 do
      if PersonalInfo.ui["cover_" .. i].Check then
        Is_cover = true
      end
    end
    if Is_cover then
      Is_NoUseAddition = true
      DealGlistenBtn(true)
    else
      Is_NoUseAddition = false
      DealGlistenBtn(false)
    end
    totalTime = 0
    FilterTmpTargetCard()
    DisablingAttribBtn()
    if not isLevelUp and CanAttribInherit() == false then
      MessageBox.ShowError(GetUTF8Text("tips_lobby_explore_inherit_surpass"))
    elseif isEnough == false then
      MessageBox.ShowError(GetUTF8Text("msgbox_common_blueprint_clew_03"))
    elseif Is_cover then
      MessageBox.ShowWithTwoButtons(GetUTF8Text("UI_enhance_chuancheng_fugai"), GetUTF8Text("button_common_Accept"), GetUTF8Text("button_common_Cancel"), InheritConfirmFunc_2)
    else
      InheritConfirmFunc_2()
    end
  end
  
  function PersonalInfo.ui.btn_levelup.EventClick(sender, e)
    if targetCardSelected.level >= materialCardSelected.level then
      MessageBox.ShowError(GetUTF8Text("tips_datalist_all_property_max"))
    else
      isLevelUp = true
      InheritOrCover()
    end
  end
  
  function PersonalInfo.ui.btn_inherit.EventClick(sender, e)
    if targetCardSelected.level > materialCardSelected.level then
      MessageBox.ShowError(GetUTF8Text("UI_enhance_avatar_grade_short"))
    else
      InheritOrCover()
    end
  end
  
  function PersonalInfo.ui.btn_cover.EventClick(sender, e)
    InheritOrCover()
  end
  
  for i = 1, 3 do
    PersonalInfo.ui["cover_" .. i].EventCheckChanged = function(sender, e)
      DealCloneNum()
      if sender.Check then
        PersonalInfo.ui.btn_levelup.Visible = false
        PersonalInfo.ui.btn_inherit.Visible = false
        PersonalInfo.ui.btn_cover.Visible = true
        PersonalInfo.ui.btn_inherit.Enable = true
        if i == 1 then
          useConvert = 1
        end
      else
        if not PersonalInfo.ui.cover_1.Check and not PersonalInfo.ui.cover_2.Check and not PersonalInfo.ui.cover_3.Check then
          UpdateCloneBtn()
        end
        if i == 1 then
          useConvert = 0
        end
      end
      DisablingAttribBtn()
    end
  end
  for i = 1, 4 do
    for j = 1, 2 do
      PersonalInfo.ui["inherit_" .. i .. "_" .. j].Visible = false
      PersonalInfo.ui["inherit_" .. i .. "_" .. j].Parent = PersonalInfo.ui.inherit_functionality
      PersonalInfo.ui["inherit_" .. i .. "_" .. j].Particle:SetEnable(true)
      PersonalInfo.ui["inherit_" .. i .. "_" .. j].Particle:Reset()
    end
  end
  
  function PersonalInfo.ui.inheritWarning1_m_cha.EventClick(sender, e)
    PersonalInfo.ui.inheritWarning1_m.Parent = nil
    PersonalInfo.ui.inheritWarning2_m.Parent = nil
  end
  
  for i = 1, 4 do
    PersonalInfo.ui["msg_attribute_inherit_" .. i].Enable = false
  end
  for i = 1, 4 do
    PersonalInfo.ui["msg_attribute_inherit_" .. i].EventMouseEnter = function(sender, e)
      if PersonalInfo.ui.btn_inherit.Enable or PersonalInfo.ui.btn_levelup.Enable then
        sender.Hint = GetUTF8Text("msgbox_lobby_property_max")
        sender.HintWidth = 150
      else
        sender.Hint = ""
      end
    end
  end
  for i = 1, 5 do
    PersonalInfo.ui["targetCard_card_b_" .. i].EventMouseDown = function(sender, e)
      if targetCardSel and targetCardSel.pid == targetCardDpt[i].pid or materialCardSel and materialCardSel.pid == targetCardDpt[i].pid then
      else
        local s, l, c = GetMoveMesg(sender)
        if sender.IsCapture then
          LighterOrNarmal(true, 3, "targetSlot")
          ShowMoveCard(s, l, PersonalInfo.ui["targetCard_card_s_" .. i], targetCardDpt[i].grade, AvtarType[i])
        else
          ReleaseCardToSlot(i, true, c)
        end
      end
    end
    PersonalInfo.ui["targetCard_card_b_" .. i].EventMouseMove = function(sender, e)
      OnMouseMove(sender, true)
    end
    PersonalInfo.ui["targetCard_card_b_" .. i].EventMouseUp = function(sender, e)
      ReleaseCardToSlot(i, true, sender.CurrentCursorPosition)
    end
    PersonalInfo.ui["targetCard_card_b_" .. i].EventRightClick = function(sender, e)
      if targetCardSel and targetCardSel.pid == targetCardDpt[i].pid or materialCardSel and materialCardSel.pid == targetCardDpt[i].pid then
      else
        ReleaseCardToSlot(i, true)
      end
    end
  end
  for i = 6, 10 do
    PersonalInfo.ui["materialCard_card_b_" .. i].EventMouseDown = function(sender, e)
      if materialCardSel and materialCardSel.pid == materialCardDpt[i].pid or targetCardSel and targetCardSel.pid == materialCardDpt[i].pid or materialCardDpt[i].isEquip == "Y" or materialCardDpt[i].isDefault == "Y" then
      else
        local s, l, c = GetMoveMesg(sender)
        if sender.IsCapture then
          LighterOrNarmal(true, 3, "materialSlot")
          ShowMoveCard(s, l, PersonalInfo.ui["materialCard_card_s_" .. i], materialCardDpt[i].grade, AvtarType[i])
        else
          ReleaseCardToSlot(i, false, c)
        end
      end
    end
    PersonalInfo.ui["materialCard_card_b_" .. i].EventMouseMove = function(sender, e)
      OnMouseMove(sender, true)
    end
    PersonalInfo.ui["materialCard_card_b_" .. i].EventMouseUp = function(sender, e)
      ReleaseCardToSlot(i, false, sender.CurrentCursorPosition)
    end
    PersonalInfo.ui["materialCard_card_b_" .. i].EventRightClick = function(sender, e)
      if materialCardSel and materialCardSel.pid == materialCardDpt[i].pid or targetCardSel and targetCardSel.pid == materialCardDpt[i].pid or materialCardDpt[i].isEquip == "Y" or materialCardDpt[i].isDefault == "Y" then
      else
        ReleaseCardToSlot(i, false)
      end
    end
  end
  for i = 1, 4 do
    PersonalInfo.ui["btn_attribute_inherit_" .. i].Visible = true
  end
  
  function PersonalInfo.ui.insert_targetcard.EventRightClick(sender, e)
    gui:PlayAudio("cancel")
    CleanInsertCard(true, true, "targetSlot")
    ClearCardAttrib()
    targetCardSel = nil
    if materialCardSel == nil or targetCardSel == nil then
      PersonalInfo.ui.inherit_opTip.Visible = true
    end
    rpc_storage_storage_list_no_empty_target_card(PersonalInfo.ui.pb_targetCard.CurrIndex)
    Deal2Buttons()
  end
  
  function PersonalInfo.ui.insert_materialcard.EventRightClick(sender, e)
    gui:PlayAudio("cancel")
    CleanInsertCard(true, true, "materialSlot")
    ClearCardAttrib()
    materialCardSel = nil
    if targetCardSel == nil or materialCardSel == nil then
      PersonalInfo.ui.inherit_opTip.Visible = true
    end
    rpc_storage_storage_list_no_empty_material_card(PersonalInfo.ui.pb_materialCard.CurrIndex)
    Deal2Buttons()
  end
end

function Hide()
  PersonalInfo.ui.ctrl_reinforce_6.Parent = nil
  ClearCardPropertyTable()
end
