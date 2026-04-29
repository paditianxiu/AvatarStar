module("ManufactureDepot", package.seeall)
colw = ARGB(255, 255, 255, 255)
dptDt = {}
depotCurr = 0
local resDir = "/ui/skinF/lobby/"
local ui, DealDepotList = Gui.Create()({
  Gui.Control("main")({
    Size = Vector2(592, 508),
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_206,
    ComFuc.ComLabel("sep_1", GetUTF8Text("button_common_Bag"), Vector2(582, 21), Vector2(14, 4), 0, 16, colw),
    ComFuc.ComControl("right_main_2_son", Vector2(573, 357), Vector2(10, 87), 255, SkinF.personalInfo_131),
    ComFuc.SecMainTabBtn("btn_depot_" .. 1, "   " .. GetUTF8Text("button_store_equipment_button"), Vector2(136, 38), Vector2(22, 52)),
    ComFuc.SecMainTabBtn("btn_depot_" .. 2, "   " .. GetUTF8Text("button_common_Item"), Vector2(136, 38), Vector2(160, 52)),
    ComFuc.SecMainTabBtn("btn_depot_" .. 3, "   " .. GetUTF8Text("button_common_Gesture"), Vector2(136, 38), Vector2(298, 52)),
    ComFuc.SecMainTabBtn("btn_depot_" .. 4, " " .. GetUTF8Text("button_common_Avatar_Card"), Vector2(136, 38), Vector2(436, 52)),
    ComFuc.ComPagesBar("pb_depot", Vector2(120, 458)),
    ComFuc.ComControl(nil, Vector2(38, 47), Vector2(20, 40), 255, SkinF.personalInfo_203[1], true, false),
    ComFuc.ComControl(nil, Vector2(38, 47), Vector2(158, 40), 255, SkinF.personalInfo_203[2], true, false),
    ComFuc.ComControl(nil, Vector2(38, 47), Vector2(296, 40), 255, SkinF.personalInfo_203[3], true, false),
    ComFuc.ComControl(nil, Vector2(38, 47), Vector2(434, 40), 255, SkinF.personalInfo_203[4], true, false)
  }),
  Gui.Control("ctrl_depot_1")({
    Size = Vector2(573, 357),
    ComFuc.DepotCB(1, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(2, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(3, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(4, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(5, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(6, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(7, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(8, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(9, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(10, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(11, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(12, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(13, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(14, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(15, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(16, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(17, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(18, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(19, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(20, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(21, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(22, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(23, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(24, "weapon", -54, -74, 2, ManufactureDepot)
  }),
  Gui.Control("ctrl_depot_4")({
    Size = Vector2(573, 357),
    ComFuc.CardKeyCB(1, "person", -86, -154, 0, ManufactureDepot),
    ComFuc.CardKeyCB(2, "person", -86, -154, 0, ManufactureDepot),
    ComFuc.CardKeyCB(3, "person", -86, -154, 0, ManufactureDepot),
    ComFuc.CardKeyCB(4, "person", -86, -154, 0, ManufactureDepot),
    ComFuc.CardKeyCB(5, "person", -86, -154, 0, ManufactureDepot),
    ComFuc.CardKeyCB(6, "person", -86, -154, 0, ManufactureDepot),
    ComFuc.CardKeyCB(7, "person", -86, -154, 0, ManufactureDepot),
    ComFuc.CardKeyCB(8, "person", -86, -154, 0, ManufactureDepot),
    ComFuc.CardKeyCB(9, "person", -86, -154, 0, ManufactureDepot),
    ComFuc.CardKeyCB(10, "person", -86, -154, 0, ManufactureDepot)
  }),
  ComFuc.ComMoveControl(),
  ComFuc.ComMoveCard()
}), {
  Gui.Control("main")({
    Size = Vector2(592, 508),
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_206,
    ComFuc.ComLabel("sep_1", GetUTF8Text("button_common_Bag"), Vector2(582, 21), Vector2(14, 4), 0, 16, colw),
    ComFuc.ComControl("right_main_2_son", Vector2(573, 357), Vector2(10, 87), 255, SkinF.personalInfo_131),
    ComFuc.SecMainTabBtn("btn_depot_" .. 1, "   " .. GetUTF8Text("button_store_equipment_button"), Vector2(136, 38), Vector2(22, 52)),
    ComFuc.SecMainTabBtn("btn_depot_" .. 2, "   " .. GetUTF8Text("button_common_Item"), Vector2(136, 38), Vector2(160, 52)),
    ComFuc.SecMainTabBtn("btn_depot_" .. 3, "   " .. GetUTF8Text("button_common_Gesture"), Vector2(136, 38), Vector2(298, 52)),
    ComFuc.SecMainTabBtn("btn_depot_" .. 4, " " .. GetUTF8Text("button_common_Avatar_Card"), Vector2(136, 38), Vector2(436, 52)),
    ComFuc.ComPagesBar("pb_depot", Vector2(120, 458)),
    ComFuc.ComControl(nil, Vector2(38, 47), Vector2(20, 40), 255, SkinF.personalInfo_203[1], true, false),
    ComFuc.ComControl(nil, Vector2(38, 47), Vector2(158, 40), 255, SkinF.personalInfo_203[2], true, false),
    ComFuc.ComControl(nil, Vector2(38, 47), Vector2(296, 40), 255, SkinF.personalInfo_203[3], true, false),
    ComFuc.ComControl(nil, Vector2(38, 47), Vector2(434, 40), 255, SkinF.personalInfo_203[4], true, false)
  }),
  Gui.Control("ctrl_depot_1")({
    Size = Vector2(573, 357),
    ComFuc.DepotCB(1, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(2, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(3, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(4, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(5, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(6, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(7, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(8, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(9, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(10, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(11, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(12, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(13, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(14, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(15, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(16, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(17, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(18, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(19, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(20, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(21, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(22, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(23, "weapon", -54, -74, 2, ManufactureDepot),
    ComFuc.DepotCB(24, "weapon", -54, -74, 2, ManufactureDepot)
  }),
  Gui.Control("ctrl_depot_4")({
    Size = Vector2(573, 357),
    ComFuc.CardKeyCB(1, "person", -86, -154, 0, ManufactureDepot),
    ComFuc.CardKeyCB(2, "person", -86, -154, 0, ManufactureDepot),
    ComFuc.CardKeyCB(3, "person", -86, -154, 0, ManufactureDepot),
    ComFuc.CardKeyCB(4, "person", -86, -154, 0, ManufactureDepot),
    ComFuc.CardKeyCB(5, "person", -86, -154, 0, ManufactureDepot),
    ComFuc.CardKeyCB(6, "person", -86, -154, 0, ManufactureDepot),
    ComFuc.CardKeyCB(7, "person", -86, -154, 0, ManufactureDepot),
    ComFuc.CardKeyCB(8, "person", -86, -154, 0, ManufactureDepot),
    ComFuc.CardKeyCB(9, "person", -86, -154, 0, ManufactureDepot),
    ComFuc.CardKeyCB(10, "person", -86, -154, 0, ManufactureDepot)
  }),
  ComFuc.ComMoveControl(),
  ComFuc.ComMoveCard()
}
local DealDepotList, rpc_storage_storage_list = function(data)
  ComFuc.CleanDepotTap(ui, ManufactureDepot, depotCurr)
  ui.pb_depot.CurrIndex = data.page
  ui.pb_depot.PageCount = data.pages
  for i, v in ipairs(data.items) do
    v.isBind = "N"
    v.isEquip = "N"
    dptDt[v.slot] = v
    if depotCurr == 1 or depotCurr == 2 or depotCurr == 3 then
      local resname = ComFuc.DoWingRes(v.resource, v.subtype, 102, depotCurr)
      ComFuc.ShowOneButton(ui["weapon_p_" .. v.slot], ui["weapon_b_" .. v.slot], resDir, resname, v.grade, v, ui["weapon_bs_" .. v.slot], ui["weapon_locked_" .. v.slot], true)
      ComFuc.ShowQuaity(ui["weapon_l_" .. v.slot], v.quantity, false)
      ComFuc.ShowUpgradeLevel(v, depotCurr + 1, ui["weapon_level_" .. v.slot], ui["weapon_level_text_" .. v.slot])
    elseif depotCurr == 4 then
      ComFuc.SetPersonCardData(v.avatar, ComFuc.CardId(v.slot), v.position)
      ComFuc.ShowOneButton(ui["person_card_p_" .. v.slot], ui["person_card_b_" .. v.slot], resDir, nil, v.grade, v, ui["person_card_bs_" .. v.slot], ui["persoan_card_locked_" .. v.slot], true)
      ComFuc.ShowUpgradeLevel(v, depotCurr + 1, ui["person_card_level_" .. v.slot], ui["person_card_level_text_" .. v.slot])
      if v.subType == 1 then
        ui["person_card_b_" .. v.slot].Skin = SkinF.personalInfo_143
        ui["person_card_level_" .. v.slot].Skin = SkinF.avatar_level
      elseif v.subType == 2 then
        ui["person_card_b_" .. v.slot].Skin = SkinF.personalInfo_261
        ui["person_card_level_" .. v.slot].Skin = SkinF.avatar_level_hero
      end
    end
  end
end, Gui.Control("main")({
  Size = Vector2(592, 508),
  BackgroundColor = colw,
  Skin = SkinF.personalInfo_206,
  ComFuc.ComLabel("sep_1", GetUTF8Text("button_common_Bag"), Vector2(582, 21), Vector2(14, 4), 0, 16, colw),
  ComFuc.ComControl("right_main_2_son", Vector2(573, 357), Vector2(10, 87), 255, SkinF.personalInfo_131),
  ComFuc.SecMainTabBtn("btn_depot_" .. 1, "   " .. GetUTF8Text("button_store_equipment_button"), Vector2(136, 38), Vector2(22, 52)),
  ComFuc.SecMainTabBtn("btn_depot_" .. 2, "   " .. GetUTF8Text("button_common_Item"), Vector2(136, 38), Vector2(160, 52)),
  ComFuc.SecMainTabBtn("btn_depot_" .. 3, "   " .. GetUTF8Text("button_common_Gesture"), Vector2(136, 38), Vector2(298, 52)),
  ComFuc.SecMainTabBtn("btn_depot_" .. 4, " " .. GetUTF8Text("button_common_Avatar_Card"), Vector2(136, 38), Vector2(436, 52)),
  ComFuc.ComPagesBar("pb_depot", Vector2(120, 458)),
  ComFuc.ComControl(nil, Vector2(38, 47), Vector2(20, 40), 255, SkinF.personalInfo_203[1], true, false),
  ComFuc.ComControl(nil, Vector2(38, 47), Vector2(158, 40), 255, SkinF.personalInfo_203[2], true, false),
  ComFuc.ComControl(nil, Vector2(38, 47), Vector2(296, 40), 255, SkinF.personalInfo_203[3], true, false),
  ComFuc.ComControl(nil, Vector2(38, 47), Vector2(434, 40), 255, SkinF.personalInfo_203[4], true, false)
})
local rpc_storage_storage_list, SelDepotBtn = function(i)
  rpc.safecall("storage_storage_list", {
    t = depotCurr + 1,
    p = i,
    s = ComFuc.depotS[depotCurr]
  }, DealDepotList)
end, Gui.Control("ctrl_depot_1")({
  Size = Vector2(573, 357),
  ComFuc.DepotCB(1, "weapon", -54, -74, 2, ManufactureDepot),
  ComFuc.DepotCB(2, "weapon", -54, -74, 2, ManufactureDepot),
  ComFuc.DepotCB(3, "weapon", -54, -74, 2, ManufactureDepot),
  ComFuc.DepotCB(4, "weapon", -54, -74, 2, ManufactureDepot),
  ComFuc.DepotCB(5, "weapon", -54, -74, 2, ManufactureDepot),
  ComFuc.DepotCB(6, "weapon", -54, -74, 2, ManufactureDepot),
  ComFuc.DepotCB(7, "weapon", -54, -74, 2, ManufactureDepot),
  ComFuc.DepotCB(8, "weapon", -54, -74, 2, ManufactureDepot),
  ComFuc.DepotCB(9, "weapon", -54, -74, 2, ManufactureDepot),
  ComFuc.DepotCB(10, "weapon", -54, -74, 2, ManufactureDepot),
  ComFuc.DepotCB(11, "weapon", -54, -74, 2, ManufactureDepot),
  ComFuc.DepotCB(12, "weapon", -54, -74, 2, ManufactureDepot),
  ComFuc.DepotCB(13, "weapon", -54, -74, 2, ManufactureDepot),
  ComFuc.DepotCB(14, "weapon", -54, -74, 2, ManufactureDepot),
  ComFuc.DepotCB(15, "weapon", -54, -74, 2, ManufactureDepot),
  ComFuc.DepotCB(16, "weapon", -54, -74, 2, ManufactureDepot),
  ComFuc.DepotCB(17, "weapon", -54, -74, 2, ManufactureDepot),
  ComFuc.DepotCB(18, "weapon", -54, -74, 2, ManufactureDepot),
  ComFuc.DepotCB(19, "weapon", -54, -74, 2, ManufactureDepot),
  ComFuc.DepotCB(20, "weapon", -54, -74, 2, ManufactureDepot),
  ComFuc.DepotCB(21, "weapon", -54, -74, 2, ManufactureDepot),
  ComFuc.DepotCB(22, "weapon", -54, -74, 2, ManufactureDepot),
  ComFuc.DepotCB(23, "weapon", -54, -74, 2, ManufactureDepot),
  ComFuc.DepotCB(24, "weapon", -54, -74, 2, ManufactureDepot)
})

function SelDepotBtn(i)
  for j = 1, 4 do
    ui["btn_depot_" .. j].PushDown = i == j
  end
  if depotCurr ~= i then
    ui.ctrl_depot_1.Parent = i ~= 4 and ui.right_main_2_son
    ui.ctrl_depot_4.Parent = i == 4 and ui.right_main_2_son
    ComFuc.CleanDepotTap(ui, ManufactureDepot, depotCurr)
    depotCurr = i
    rpc_storage_storage_list(1)
  end
end

function ManufOK()
  rpc_storage_storage_list(ui.pb_depot.CurrIndex)
end

for i = 1, 4 do
  ui["btn_depot_" .. i].EventClick = function(sender, e)
    SelDepotBtn(i)
  end
end

function ui.pb_depot.EventIndexChanged(sender, e)
  rpc_storage_storage_list(ui.pb_depot.CurrIndex)
end

function Show(parent)
  depotCurr = 0
  SelDepotBtn(1)
  ui.main.Parent = parent
end
