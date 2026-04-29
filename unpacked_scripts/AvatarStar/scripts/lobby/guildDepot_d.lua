module("GuildDepot", package.seeall)
col0 = ARGB(0, 0, 0, 0)
colw = ARGB(255, 255, 255, 255)
colr = ARGB(255, 255, 0, 0)
colg = ARGB(255, 0, 255, 198)
coly = ARGB(255, 255, 214, 50)
colt = ARGB(255, 113, 83, 65)
cols = ARGB(255, 62, 26, 1)
colh = ARGB(255, 160, 160, 160)
dptDt = {}
depotCurr = 0
local mgB1 = Vector2(100, 329)
local mgB2 = Vector2(100, 395)
local mgS = Vector2(68, 64)
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
    ComFuc.ComPagesBar("pb_depot", Vector2(120, 458)),
    ComFuc.ComControl(nil, Vector2(38, 47), Vector2(20, 40), 255, SkinF.personalInfo_203[1], true, false),
    ComFuc.ComControl(nil, Vector2(38, 47), Vector2(158, 40), 255, SkinF.personalInfo_203[2], true, false),
    ComFuc.ComControl(nil, Vector2(38, 47), Vector2(296, 40), 255, SkinF.personalInfo_203[3], true, false)
  }),
  Gui.Control("ctrl_depot_1")({
    Size = Vector2(573, 357),
    ComFuc.DepotCB(1, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(2, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(3, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(4, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(5, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(6, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(7, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(8, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(9, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(10, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(11, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(12, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(13, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(14, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(15, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(16, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(17, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(18, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(19, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(20, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(21, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(22, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(23, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(24, "weapon", -54, -74, 2, GuildDepot)
  }),
  ComFuc.ComMoveControl()
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
    ComFuc.ComPagesBar("pb_depot", Vector2(120, 458)),
    ComFuc.ComControl(nil, Vector2(38, 47), Vector2(20, 40), 255, SkinF.personalInfo_203[1], true, false),
    ComFuc.ComControl(nil, Vector2(38, 47), Vector2(158, 40), 255, SkinF.personalInfo_203[2], true, false),
    ComFuc.ComControl(nil, Vector2(38, 47), Vector2(296, 40), 255, SkinF.personalInfo_203[3], true, false)
  }),
  Gui.Control("ctrl_depot_1")({
    Size = Vector2(573, 357),
    ComFuc.DepotCB(1, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(2, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(3, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(4, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(5, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(6, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(7, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(8, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(9, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(10, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(11, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(12, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(13, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(14, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(15, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(16, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(17, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(18, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(19, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(20, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(21, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(22, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(23, "weapon", -54, -74, 2, GuildDepot),
    ComFuc.DepotCB(24, "weapon", -54, -74, 2, GuildDepot)
  }),
  ComFuc.ComMoveControl()
}
local DealDepotList, rpc_storage_storage_list = function(data)
  ComFuc.CleanDepotTap(ui, GuildDepot, depotCurr)
  ui.pb_depot.CurrIndex = data.page
  ui.pb_depot.PageCount = data.pages
  for i, v in ipairs(data.items) do
    dptDt[v.slot] = v
    if depotCurr == 1 or depotCurr == 2 or depotCurr == 3 then
      local resname = ComFuc.DoWingRes(v.resource, v.subtype, 102, depotCurr)
      ComFuc.ShowOneButton(ui["weapon_p_" .. v.slot], ui["weapon_b_" .. v.slot], resDir, resname, v.grade, v, ui["weapon_bs_" .. v.slot], true)
      ComFuc.ShowQuaity(ui["weapon_l_" .. v.slot], v.quantity, false)
      ComFuc.ShowUpgradeLevel(v, depotCurr + 1, ui["weapon_level_" .. v.slot], ui["weapon_level_text_" .. v.slot])
    elseif depotCurr == 4 then
      ComFuc.SetPersonCardData(v.avatar, ComFuc.CardId(v.slot), v.position)
      ComFuc.ShowOneButton(ui["person_card_p_" .. v.slot], ui["person_card_b_" .. v.slot], resDir, nil, v.grade, v, ui["person_card_bs_" .. v.slot], true)
      ComFuc.ShowUpgradeLevel(v, depotCurr + 1, ui["person_card_level_" .. v.slot], ui["person_card_level_text_" .. v.slot])
    end
    ui["weapon_bs_" .. v.slot].Visible = not v.sysComposeMerit or not (v.sysComposeMerit > 0) or v.isEquip ~= "N"
    for k = 1, 12 do
      if GuildBuild.hasInCombine[k] and v.pid == GuildBuild.hasInCombine[k].pid then
        ui["weapon_bs_" .. v.slot].Visible = true
      end
    end
  end
  GuildBuild.FinishCompose()
end, Gui.Control("main")({
  Size = Vector2(592, 508),
  BackgroundColor = colw,
  Skin = SkinF.personalInfo_206,
  ComFuc.ComLabel("sep_1", GetUTF8Text("button_common_Bag"), Vector2(582, 21), Vector2(14, 4), 0, 16, colw),
  ComFuc.ComControl("right_main_2_son", Vector2(573, 357), Vector2(10, 87), 255, SkinF.personalInfo_131),
  ComFuc.SecMainTabBtn("btn_depot_" .. 1, "   " .. GetUTF8Text("button_store_equipment_button"), Vector2(136, 38), Vector2(22, 52)),
  ComFuc.SecMainTabBtn("btn_depot_" .. 2, "   " .. GetUTF8Text("button_common_Item"), Vector2(136, 38), Vector2(160, 52)),
  ComFuc.SecMainTabBtn("btn_depot_" .. 3, "   " .. GetUTF8Text("button_common_Gesture"), Vector2(136, 38), Vector2(298, 52)),
  ComFuc.ComPagesBar("pb_depot", Vector2(120, 458)),
  ComFuc.ComControl(nil, Vector2(38, 47), Vector2(20, 40), 255, SkinF.personalInfo_203[1], true, false),
  ComFuc.ComControl(nil, Vector2(38, 47), Vector2(158, 40), 255, SkinF.personalInfo_203[2], true, false),
  ComFuc.ComControl(nil, Vector2(38, 47), Vector2(296, 40), 255, SkinF.personalInfo_203[3], true, false)
})
local rpc_storage_storage_list, SelDepotBtn = function(i)
  rpc.safecall("storage_storage_list", {
    t = depotCurr + 1,
    p = i,
    s = ComFuc.depotS[depotCurr]
  }, DealDepotList)
end, Gui.Control("ctrl_depot_1")({
  Size = Vector2(573, 357),
  ComFuc.DepotCB(1, "weapon", -54, -74, 2, GuildDepot),
  ComFuc.DepotCB(2, "weapon", -54, -74, 2, GuildDepot),
  ComFuc.DepotCB(3, "weapon", -54, -74, 2, GuildDepot),
  ComFuc.DepotCB(4, "weapon", -54, -74, 2, GuildDepot),
  ComFuc.DepotCB(5, "weapon", -54, -74, 2, GuildDepot),
  ComFuc.DepotCB(6, "weapon", -54, -74, 2, GuildDepot),
  ComFuc.DepotCB(7, "weapon", -54, -74, 2, GuildDepot),
  ComFuc.DepotCB(8, "weapon", -54, -74, 2, GuildDepot),
  ComFuc.DepotCB(9, "weapon", -54, -74, 2, GuildDepot),
  ComFuc.DepotCB(10, "weapon", -54, -74, 2, GuildDepot),
  ComFuc.DepotCB(11, "weapon", -54, -74, 2, GuildDepot),
  ComFuc.DepotCB(12, "weapon", -54, -74, 2, GuildDepot),
  ComFuc.DepotCB(13, "weapon", -54, -74, 2, GuildDepot),
  ComFuc.DepotCB(14, "weapon", -54, -74, 2, GuildDepot),
  ComFuc.DepotCB(15, "weapon", -54, -74, 2, GuildDepot),
  ComFuc.DepotCB(16, "weapon", -54, -74, 2, GuildDepot),
  ComFuc.DepotCB(17, "weapon", -54, -74, 2, GuildDepot),
  ComFuc.DepotCB(18, "weapon", -54, -74, 2, GuildDepot),
  ComFuc.DepotCB(19, "weapon", -54, -74, 2, GuildDepot),
  ComFuc.DepotCB(20, "weapon", -54, -74, 2, GuildDepot),
  ComFuc.DepotCB(21, "weapon", -54, -74, 2, GuildDepot),
  ComFuc.DepotCB(22, "weapon", -54, -74, 2, GuildDepot),
  ComFuc.DepotCB(23, "weapon", -54, -74, 2, GuildDepot),
  ComFuc.DepotCB(24, "weapon", -54, -74, 2, GuildDepot)
})
local SelDepotBtn, DragToCombine = function(i)
  for j = 1, 3 do
    ui["btn_depot_" .. j].PushDown = i == j
  end
  if depotCurr ~= i then
    ui.ctrl_depot_1.Parent = ui.right_main_2_son
    ComFuc.CleanDepotTap(ui, GuildDepot, depotCurr)
    depotCurr = i
    rpc_storage_storage_list(1)
  end
end, ComFuc.ComMoveControl()
local DragToCombine, ComItemUp = function(c, i, type)
  local k2 = 0
  if ComFuc.IsInAABB(c, mgB1, Vector2(mgS.x * 6, mgS.y)) then
    k2 = math.floor((c.x + (mgS.x - mgB1.x)) / mgS.x)
  end
  if ComFuc.IsInAABB(c, mgB2, Vector2(mgS.x * 6, mgS.y)) then
    k2 = 6 + math.floor((c.x + (mgS.x - mgB2.x)) / mgS.x)
  end
  if 0 < k2 and k2 < 13 then
    GuildBuild.HasGoodsIn(k2, dptDt[i], type)
    ui["weapon_bs_" .. i].Visible = true
  end
end, ComFuc.ComMoveControl()

function ComItemUp(i, c)
  gui:PlayAudio("putdown")
  DragToCombine(c, i, depotCurr + 1)
  ui.moveControl.Parent = nil
end

function CombineGoodOK()
  rpc_storage_storage_list(ui.pb_depot.CurrIndex)
end

function SetItemInCombine(itemQid, isIn)
end

function CleanItemInCombine()
  GuildBuild.hasInCombine = {}
end

ui["btn_depot_" .. 1].Enable = false
ui["btn_depot_" .. 3].Enable = false
for i = 1, 3 do
  ui["btn_depot_" .. i].EventClick = function(sender, e)
    SelDepotBtn(i)
  end
end
for i = 1, 24 do
  ui["weapon_b_" .. i].EventMouseDown = function(sender, e)
    if not ui["weapon_bs_" .. i].Visible and dptDt[i] then
      local s, l, c = ComFuc.GetMoveMesg(sender)
      if sender.IsCapture then
        local resname = ComFuc.DoWingRes(dptDt[i].resource, dptDt[i].subtype, 102, depotCurr)
        ComFuc.ShowMoveControl(s, l, resDir, resname, dptDt[i].grade, ui.moveControl, ui.moveControl_son, false)
      else
        ComItemUp(i, c)
      end
    end
  end
  ui["weapon_b_" .. i].EventMouseMove = function(sender, e)
    ComFuc.OnMouseMove(sender, false, nil, ui.moveControl, false)
  end
  ui["weapon_b_" .. i].EventMouseUp = function(sender, e)
    ComItemUp(i, sender.CurrentCursorPosition)
  end
  ui["weapon_b_" .. i].EventRightClick = function(sender, e)
    if not ui["weapon_bs_" .. i].Visible then
      gui:PlayAudio("putdown")
      GuildBuild.HasGoodsIn(0, dptDt[i], depotCurr + 1)
      ui["weapon_bs_" .. i].Visible = true
    end
  end
end

function ui.pb_depot.EventIndexChanged(sender, e)
  rpc_storage_storage_list(ui.pb_depot.CurrIndex)
end

function CleanOneMoveInState(k)
  for i = 1, 24 do
    if GuildBuild.hasInCombine[k] and dptDt[i] and dptDt[i].pid == GuildBuild.hasInCombine[k].pid then
      ui["weapon_bs_" .. i].Visible = false
    end
  end
end

function Show(parentCtrl)
  depotCurr = 0
  SelDepotBtn(2)
  ui.main.Parent = parentCtrl
end

function Hide()
  ui.main.Parent = nil
end
