module("MailDepot", package.seeall)
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
IsCallDepot = 0
local resDir = "/ui/skinF/lobby/"
local closeCallBackFun
local hasInMail = {
  "0",
  "0",
  "0",
  "0",
  "0"
}
local AvtarType = {}
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
    ComFuc.ComControl(nil, Vector2(38, 47), Vector2(434, 40), 255, SkinF.personalInfo_203[4], true, false),
    ComFuc.ComButton("main_close", nil, Vector2(24, 24), Vector2(560, 4), 0, false, false, SkinF.lookInfo_002)
  }),
  Gui.Control("ctrl_depot_1")({
    Size = Vector2(573, 357),
    ComFuc.DepotCB(1, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(2, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(3, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(4, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(5, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(6, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(7, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(8, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(9, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(10, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(11, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(12, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(13, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(14, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(15, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(16, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(17, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(18, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(19, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(20, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(21, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(22, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(23, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(24, "weapon", -54, -74, 2, MailDepot)
  }),
  Gui.Control("ctrl_depot_4")({
    Size = Vector2(573, 357),
    ComFuc.CardKeyCB(1, "person", -86, -154, 0, MailDepot),
    ComFuc.CardKeyCB(2, "person", -86, -154, 0, MailDepot),
    ComFuc.CardKeyCB(3, "person", -86, -154, 0, MailDepot),
    ComFuc.CardKeyCB(4, "person", -86, -154, 0, MailDepot),
    ComFuc.CardKeyCB(5, "person", -86, -154, 0, MailDepot),
    ComFuc.CardKeyCB(6, "person", -86, -154, 0, MailDepot),
    ComFuc.CardKeyCB(7, "person", -86, -154, 0, MailDepot),
    ComFuc.CardKeyCB(8, "person", -86, -154, 0, MailDepot),
    ComFuc.CardKeyCB(9, "person", -86, -154, 0, MailDepot),
    ComFuc.CardKeyCB(10, "person", -86, -154, 0, MailDepot)
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
    ComFuc.ComControl(nil, Vector2(38, 47), Vector2(434, 40), 255, SkinF.personalInfo_203[4], true, false),
    ComFuc.ComButton("main_close", nil, Vector2(24, 24), Vector2(560, 4), 0, false, false, SkinF.lookInfo_002)
  }),
  Gui.Control("ctrl_depot_1")({
    Size = Vector2(573, 357),
    ComFuc.DepotCB(1, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(2, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(3, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(4, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(5, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(6, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(7, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(8, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(9, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(10, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(11, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(12, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(13, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(14, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(15, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(16, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(17, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(18, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(19, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(20, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(21, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(22, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(23, "weapon", -54, -74, 2, MailDepot),
    ComFuc.DepotCB(24, "weapon", -54, -74, 2, MailDepot)
  }),
  Gui.Control("ctrl_depot_4")({
    Size = Vector2(573, 357),
    ComFuc.CardKeyCB(1, "person", -86, -154, 0, MailDepot),
    ComFuc.CardKeyCB(2, "person", -86, -154, 0, MailDepot),
    ComFuc.CardKeyCB(3, "person", -86, -154, 0, MailDepot),
    ComFuc.CardKeyCB(4, "person", -86, -154, 0, MailDepot),
    ComFuc.CardKeyCB(5, "person", -86, -154, 0, MailDepot),
    ComFuc.CardKeyCB(6, "person", -86, -154, 0, MailDepot),
    ComFuc.CardKeyCB(7, "person", -86, -154, 0, MailDepot),
    ComFuc.CardKeyCB(8, "person", -86, -154, 0, MailDepot),
    ComFuc.CardKeyCB(9, "person", -86, -154, 0, MailDepot),
    ComFuc.CardKeyCB(10, "person", -86, -154, 0, MailDepot)
  }),
  ComFuc.ComMoveControl(),
  ComFuc.ComMoveCard()
}
local DealDepotList, rpc_storage_storage_list = function(data)
  ComFuc.CleanDepotTap(ui, MailDepot, depotCurr)
  ui.pb_depot.CurrIndex = data.page
  ui.pb_depot.PageCount = data.pages
  for i, v in ipairs(data.items) do
    dptDt[v.slot] = v
    AvtarType[v.slot] = v.subType
    if depotCurr == 1 or depotCurr == 2 or depotCurr == 3 then
      local resname = ComFuc.DoWingRes(v.resource, v.subtype, 102, depotCurr)
      ComFuc.ShowOneButton(ui["weapon_p_" .. v.slot], ui["weapon_b_" .. v.slot], resDir, resname, v.grade, v, ui["weapon_bs_" .. v.slot], ui["weapon_locked_" .. v.slot], true)
      ComFuc.ShowQuaity(ui["weapon_l_" .. v.slot], v.quantity, false)
      ComFuc.ShowUpgradeLevel(v, depotCurr + 1, ui["weapon_level_" .. v.slot], ui["weapon_level_text_" .. v.slot])
    elseif depotCurr == 4 then
      ComFuc.SetPersonCardData(v.avatar, ComFuc.CardId(v.slot), v.position)
      ComFuc.ShowOneButton(ui["person_card_p_" .. v.slot], ui["person_card_b_" .. v.slot], resDir, nil, v.grade, v, ui["person_card_bs_" .. v.slot], ui["personalInfo_card_locked_" .. v.slot], true)
      ComFuc.ShowUpgradeLevel(v, depotCurr + 1, ui["person_card_level_" .. v.slot], ui["person_card_level_text_" .. v.slot])
      if v.subType == 1 then
        ui["person_card_b_" .. v.slot].Skin = SkinF.personalInfo_143
        ui["person_card_level_" .. v.slot].Skin = SkinF.avatar_level
      elseif v.subType == 2 then
        ui["person_card_b_" .. v.slot].Skin = SkinF.personalInfo_261
        ui["person_card_level_" .. v.slot].Skin = SkinF.avatar_level_hero
      end
    end
    local t = {
      "weapon_bs_",
      "weapon_bs_",
      "weapon_bs_",
      "person_card_bs_"
    }
    for k = 1, 5 do
      if v.pid == hasInMail[k] then
        ui[t[depotCurr] .. v.slot].Visible = true
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
  ComFuc.ComControl(nil, Vector2(38, 47), Vector2(434, 40), 255, SkinF.personalInfo_203[4], true, false),
  ComFuc.ComButton("main_close", nil, Vector2(24, 24), Vector2(560, 4), 0, false, false, SkinF.lookInfo_002)
})
local rpc_storage_storage_list, SelDepotBtn = function(i)
  rpc.safecall("storage_storage_list", {
    t = depotCurr + 1,
    p = i,
    s = ComFuc.depotS[depotCurr]
  }, DealDepotList)
end, Gui.Control("ctrl_depot_1")({
  Size = Vector2(573, 357),
  ComFuc.DepotCB(1, "weapon", -54, -74, 2, MailDepot),
  ComFuc.DepotCB(2, "weapon", -54, -74, 2, MailDepot),
  ComFuc.DepotCB(3, "weapon", -54, -74, 2, MailDepot),
  ComFuc.DepotCB(4, "weapon", -54, -74, 2, MailDepot),
  ComFuc.DepotCB(5, "weapon", -54, -74, 2, MailDepot),
  ComFuc.DepotCB(6, "weapon", -54, -74, 2, MailDepot),
  ComFuc.DepotCB(7, "weapon", -54, -74, 2, MailDepot),
  ComFuc.DepotCB(8, "weapon", -54, -74, 2, MailDepot),
  ComFuc.DepotCB(9, "weapon", -54, -74, 2, MailDepot),
  ComFuc.DepotCB(10, "weapon", -54, -74, 2, MailDepot),
  ComFuc.DepotCB(11, "weapon", -54, -74, 2, MailDepot),
  ComFuc.DepotCB(12, "weapon", -54, -74, 2, MailDepot),
  ComFuc.DepotCB(13, "weapon", -54, -74, 2, MailDepot),
  ComFuc.DepotCB(14, "weapon", -54, -74, 2, MailDepot),
  ComFuc.DepotCB(15, "weapon", -54, -74, 2, MailDepot),
  ComFuc.DepotCB(16, "weapon", -54, -74, 2, MailDepot),
  ComFuc.DepotCB(17, "weapon", -54, -74, 2, MailDepot),
  ComFuc.DepotCB(18, "weapon", -54, -74, 2, MailDepot),
  ComFuc.DepotCB(19, "weapon", -54, -74, 2, MailDepot),
  ComFuc.DepotCB(20, "weapon", -54, -74, 2, MailDepot),
  ComFuc.DepotCB(21, "weapon", -54, -74, 2, MailDepot),
  ComFuc.DepotCB(22, "weapon", -54, -74, 2, MailDepot),
  ComFuc.DepotCB(23, "weapon", -54, -74, 2, MailDepot),
  ComFuc.DepotCB(24, "weapon", -54, -74, 2, MailDepot)
})
local SelDepotBtn, DragToMail = function(i)
  for j = 1, 4 do
    ui["btn_depot_" .. j].PushDown = i == j
  end
  if depotCurr ~= i then
    ui.ctrl_depot_1.Parent = i ~= 4 and ui.right_main_2_son
    ui.ctrl_depot_4.Parent = i == 4 and ui.right_main_2_son
    ComFuc.CleanDepotTap(ui, MailDepot, depotCurr)
    depotCurr = i
    rpc_storage_storage_list(1)
  end
end, Gui.Control("ctrl_depot_4")({
  Size = Vector2(573, 357),
  ComFuc.CardKeyCB(1, "person", -86, -154, 0, MailDepot),
  ComFuc.CardKeyCB(2, "person", -86, -154, 0, MailDepot),
  ComFuc.CardKeyCB(3, "person", -86, -154, 0, MailDepot),
  ComFuc.CardKeyCB(4, "person", -86, -154, 0, MailDepot),
  ComFuc.CardKeyCB(5, "person", -86, -154, 0, MailDepot),
  ComFuc.CardKeyCB(6, "person", -86, -154, 0, MailDepot),
  ComFuc.CardKeyCB(7, "person", -86, -154, 0, MailDepot),
  ComFuc.CardKeyCB(8, "person", -86, -154, 0, MailDepot),
  ComFuc.CardKeyCB(9, "person", -86, -154, 0, MailDepot),
  ComFuc.CardKeyCB(10, "person", -86, -154, 0, MailDepot)
})
local DragToMail, DragToSale = function(c, i, type)
  if Mail.IsMailWriteVisible() and IsCallDepot == 0 then
    for k = 1, 5 do
      if ComFuc.IsInAABB(c, Vector2(ComFuc.maBl[k].x, ComFuc.maBl[k].y), ComFuc.maS) then
        Mail.OnAddAttachment(k, dptDt[i], type)
        break
      end
    end
  end
end, ComFuc.ComMoveControl()
local DragToSale, WeaponUp = function(c, i, type)
  if IsCallDepot == 1 then
    AHRegister.UpdateStorageList = SendToMailOK
    if ComFuc.IsInAABB(c, Vector2(ComFuc.locationChanged + ComFuc.slB.x, ComFuc.slB.y), ComFuc.slS) then
      AHRegister.SetArgs(depotCurr + 1, ui.pb_depot.CurrIndex, ComFuc.depotS[depotCurr], i, dptDt[i])
    end
  end
end, ComFuc.ComMoveCard()
local WeaponUp, PropUp = function(i, c)
  gui:PlayAudio("putdown")
  DragToMail(c, i, 2)
  DragToSale(c, i, 2)
  ui.moveControl.Parent = nil
end, ComFuc.ComMoveCard()
local PropUp, PoseUp = function(i, c)
  gui:PlayAudio("putdown")
  DragToMail(c, i, 3)
  DragToSale(c, i, 3)
  ui.moveControl.Parent = nil
end, ComFuc.ComMoveCard()
local PoseUp, PersonUp = function(i, c)
  gui:PlayAudio("putdown")
  DragToMail(c, i, 4)
  DragToSale(c, i, 4)
  ui.moveControl.Parent = nil
end, ComFuc.ComMoveCard()

function PersonUp(i, c)
  gui:PlayAudio("putdown")
  DragToMail(c, i, 5)
  DragToSale(c, i, 5)
  ui.moveCard.Parent = nil
  ui.moveCard_s.ID = -1
end

function SendToMailOK()
  rpc_storage_storage_list(ui.pb_depot.CurrIndex)
end

function SetItemInMail(itemQid, isIn)
  if itemQid and (itemQid ~= "0" or 0 < itemQid) then
    if isIn then
      for i = 1, 5 do
        if hasInMail[i] == "0" then
          hasInMail[i] = itemQid
          break
        end
      end
    else
      for i = 1, 5 do
        if hasInMail[i] == itemQid then
          hasInMail[i] = "0"
          break
        end
      end
    end
  end
  for i = 1, 24 do
    if dptDt[i] and dptDt[i].pid == itemQid then
      local t = {
        "weapon_bs_",
        "weapon_bs_",
        "weapon_bs_",
        "person_card_bs_"
      }
      ui[t[depotCurr] .. i].Visible = isIn
    end
  end
end

function CleanItemInMail()
  hasInMail = {
    "0",
    "0",
    "0",
    "0",
    "0"
  }
end

local dealMouseUp = {
  WeaponUp,
  PropUp,
  PoseUp
}
for i = 1, 4 do
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
        ComFuc.ShowMoveControl(s, l, resDir, resname, dptDt[i].grade, ui.moveControl, ui.moveControl_son, true)
      else
        dealMouseUp[depotCurr](i, c)
      end
    end
  end
  ui["weapon_b_" .. i].EventMouseMove = function(sender, e)
    ComFuc.OnMouseMove(sender, false, ui.moveCard, ui.moveControl, true)
  end
  ui["weapon_b_" .. i].EventMouseUp = function(sender, e)
    dealMouseUp[depotCurr](i, sender.CurrentCursorPosition)
  end
end
for i = 1, 10 do
  ui["person_card_b_" .. i].EventMouseDown = function(sender, e)
    if not ui["person_card_bs_" .. i].Visible then
      local s, l, c = ComFuc.GetMoveMesg(sender)
      if sender.IsCapture then
        ComFuc.ShowMoveCard(s, l, ui["person_card_s_" .. i], dptDt[i].grade, ui.moveCard, ui.moveCard_son, ui.moveCard_s, ui.moveCard_c, true, AvtarType[i])
      else
        PersonUp(i, c)
      end
    end
  end
  ui["person_card_b_" .. i].EventMouseMove = function(sender, e)
    ComFuc.OnMouseMove(sender, true, ui.moveCard, ui.moveControl, true)
  end
  ui["person_card_b_" .. i].EventMouseUp = function(sender, e)
    PersonUp(i, sender.CurrentCursorPosition)
  end
end

function ui.pb_depot.EventIndexChanged(sender, e)
  rpc_storage_storage_list(ui.pb_depot.CurrIndex)
end

local ui.main_close.EventClick, ComShow = function(sender, e)
  Hide()
  if closeCallBackFun then
    closeCallBackFun()
  end
end, ui.main_close

function ComShow(p, lc, color, state)
  ui.main.Parent = p
  ui.main.Location = lc
  ui.main.BackgroundColor = color
  IsCallDepot = state
  depotCurr = 0
  SelDepotBtn(1)
end

function Visible()
  return ui.main.Parent ~= nil
end

function ShowAction(parent, lc)
  ComShow(parent, lc, col0, 1)
end

function Show(parent, fun1)
  ComShow(parent, Vector2(0, 0), colw, 0)
  closeCallBackFun = fun1
end

function Hide()
  ui.main.Parent = nil
  PersonalInfo.ReflashMail()
end
