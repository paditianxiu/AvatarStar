module("GuildBuild", package.seeall)
local col0 = ComFuc.col0
local colw = ComFuc.colw
local colt = ComFuc.colt
local coly = ComFuc.coly
local resDir = "/ui/skinF/lobby/"
local ids = ""
hasInCombine = {}
local hasInProduce, ComMoveInCB = {}, {}
local ComMoveInCB, ComCanProduce = function(i)
  return Gui.Control("moveIn_p_" .. i)({
    Size = Vector2(64, 64),
    Location = ComFuc.ComputLocation(i, -24, -1, 6, 68, 66),
    BackgroundColor = colw,
    Skin = SkinF.skin_touming,
    Gui.DragBtn("moveIn_b_" .. i)({
      Size = Vector2(64, 64),
      Skin = SkinF.skin_touming2,
      ComFuc.ComLabel("moveIn_l_" .. i, nil, Vector2(60, 18), Vector2(4, 43), 0, 0, col0, "kAlignRightMiddle", nil, true, SkinF.hecheng_number_1),
      Gui.Control({
        Size = Vector2(64, 64),
        EventMouseEnter = function(sender, e)
          ComFuc.ShowDepotTips(sender, hasInCombine[i].pid, hasInCombine[i].type, hasInCombine[i].pid, false)
        end
      })
    })
  })
end, nil

function ComCanProduce(i)
  return Gui.Control("produce_p_" .. i)({
    Size = Vector2(80, 80),
    Location = ComFuc.ComputLocation(i, 16, 277, 4, 86, 80),
    BackgroundColor = colw,
    Skin = SkinF.skin_touming,
    Gui.Control("produce_b_" .. i)({
      Size = Vector2(80, 80),
      BackgroundColor = colw,
      Skin = SkinF.skin_touming2,
      ComFuc.ComLabel("produce_l_" .. i, nil, Vector2(60, 18), Vector2(20, 59), 0, 0, col0, "kAlignRightMiddle", nil, true, SkinF.hecheng_number_1)
    })
  })
end

local ui = Gui.Create()({
  ComFuc.ComControl("coverControl2", Vector2(1600, 1200), Vector2(0, 0), 0),
  Gui.Control("main")({
    Size = Vector2(1128, 645),
    ComFuc.ComControl(nil, Vector2(1088, 42), Vector2(21, 13), 255, SkinF.shop_12),
    ComFuc.ComButton("research_center", GetUTF8Text("button_common_new_study"), Vector2(144, 40), Vector2(26, 14), 16, true, false),
    ComFuc.ComControl(nil, Vector2(592, 45), Vector2(517, 64), 255, SkinF.skin_playgame_017),
    ComFuc.ComLabel(nil, GetUTF8Text("button_common_new_conversion_03"), Vector2(572, 25), Vector2(527, 72), 0, 16, colt, "kAlignCenterMiddle"),
    Gui.Control({
      Size = Vector2(491, 564),
      Location = Vector2(21, 63),
      BackgroundColor = colw,
      Skin = SkinF.guild_031,
      ComFuc.ComLabel(nil, GetUTF8Text("button_common_new_convertinto"), Vector2(194, 24), Vector2(134, 217), 0, 16, coly),
      ComFuc.ComLabel("transform_value", "0", Vector2(194, 24), Vector2(134, 217), 0, 16, coly, "kAlignRightMiddle"),
      ComFuc.ComLabel("transform_rate", "0/12", Vector2(74, 24), Vector2(374, 217), 0, 16, coly, "kAlignCenterMiddle"),
      ComFuc.ComLabel(nil, GetUTF8Text("button_common_new_conversion_01"), Vector2(220, 24), Vector2(134, 291), 0, 16, colw),
      ComFuc.ComControl("light", Vector2(40, 42), Vector2(83, 289), 255, SkinF.guild_032),
      ComFuc.ComControl("water", Vector2(50, 35), Vector2(386, 283), 255, SkinF.guild_033),
      ComFuc.ComButton("clean_goods", GetUTF8Text("UI_store_mainUI_blank_50"), Vector2(84, 39), Vector2(36, 208), 16),
      ComFuc.ComButton("transform", nil, Vector2(163, 63), Vector2(162, 479), 0, false, false, SkinF.guild_041),
      ComMoveInCB(1),
      ComMoveInCB(2),
      ComMoveInCB(3),
      ComMoveInCB(4),
      ComMoveInCB(5),
      ComMoveInCB(6),
      ComMoveInCB(7),
      ComMoveInCB(8),
      ComMoveInCB(9),
      ComMoveInCB(10),
      ComMoveInCB(11),
      ComMoveInCB(12),
      ComCanProduce(1),
      ComCanProduce(2),
      ComCanProduce(3),
      ComCanProduce(4)
    }),
    Gui.Control("depot")({
      Size = Vector2(592, 508),
      Location = Vector2(517, 111)
    })
  })
})
ui.research_center.PushDown = true
local ui.research_center.EventClick, CleanOneProduce = function(sender, e)
  sender.PushDown = true
end, ui.research_center
local CleanOneProduce, CleanAllProduce = function(i)
  ui["produce_p_" .. i].Visible = false
end, function(sender, e)
  sender.PushDown = true
end
local CleanAllProduce, HasGoodSInProduce = function()
  for i = 1, 4 do
    CleanOneProduce(i)
  end
end, Gui.Control("main")({
  Size = Vector2(1128, 645),
  ComFuc.ComControl(nil, Vector2(1088, 42), Vector2(21, 13), 255, SkinF.shop_12),
  ComFuc.ComButton("research_center", GetUTF8Text("button_common_new_study"), Vector2(144, 40), Vector2(26, 14), 16, true, false),
  ComFuc.ComControl(nil, Vector2(592, 45), Vector2(517, 64), 255, SkinF.skin_playgame_017),
  ComFuc.ComLabel(nil, GetUTF8Text("button_common_new_conversion_03"), Vector2(572, 25), Vector2(527, 72), 0, 16, colt, "kAlignCenterMiddle"),
  Gui.Control({
    Size = Vector2(491, 564),
    Location = Vector2(21, 63),
    BackgroundColor = colw,
    Skin = SkinF.guild_031,
    ComFuc.ComLabel(nil, GetUTF8Text("button_common_new_convertinto"), Vector2(194, 24), Vector2(134, 217), 0, 16, coly),
    ComFuc.ComLabel("transform_value", "0", Vector2(194, 24), Vector2(134, 217), 0, 16, coly, "kAlignRightMiddle"),
    ComFuc.ComLabel("transform_rate", "0/12", Vector2(74, 24), Vector2(374, 217), 0, 16, coly, "kAlignCenterMiddle"),
    ComFuc.ComLabel(nil, GetUTF8Text("button_common_new_conversion_01"), Vector2(220, 24), Vector2(134, 291), 0, 16, colw),
    ComFuc.ComControl("light", Vector2(40, 42), Vector2(83, 289), 255, SkinF.guild_032),
    ComFuc.ComControl("water", Vector2(50, 35), Vector2(386, 283), 255, SkinF.guild_033),
    ComFuc.ComButton("clean_goods", GetUTF8Text("UI_store_mainUI_blank_50"), Vector2(84, 39), Vector2(36, 208), 16),
    ComFuc.ComButton("transform", nil, Vector2(163, 63), Vector2(162, 479), 0, false, false, SkinF.guild_041),
    ComMoveInCB(1),
    ComMoveInCB(2),
    ComMoveInCB(3),
    ComMoveInCB(4),
    ComMoveInCB(5),
    ComMoveInCB(6),
    ComMoveInCB(7),
    ComMoveInCB(8),
    ComMoveInCB(9),
    ComMoveInCB(10),
    ComMoveInCB(11),
    ComMoveInCB(12),
    ComCanProduce(1),
    ComCanProduce(2),
    ComCanProduce(3),
    ComCanProduce(4)
  }),
  Gui.Control("depot")({
    Size = Vector2(592, 508),
    Location = Vector2(517, 111)
  })
})
local HasGoodSInProduce, ComputePriceAndSafecall = function(data)
  for i = 1, 4 do
    if data.list[i] then
      v = data.list[i]
      ui["produce_p_" .. i].Visible = true
      ui["produce_p_" .. i].Skin = SkinF.personalInfo_quality[v.grade]
      local tnum = v.num or v.unit or 0
      if tonumber(v.type) == 7 and (tonumber(v.id) == 1 or tonumber(v.id) == 2 or tonumber(v.id) == 3) then
        ui["produce_b_" .. i].Skin = Gui.Gui.ControlSkin({
          BackgroundImage = Gui.Image("ui/skinF/skin_common_icon_gold01.tga", Vector4(0, 0, 0, 0))
        })
      else
        local res = v.resource
        if v.type == 2 and v.subType == 102 then
          local a = rpc.load_result("fuck = {" .. res .. "}")
          res = a.fuck[1]
        end
        ui["produce_b_" .. i].Skin = Gui.Gui.ControlSkin({
          BackgroundImage = Gui.Image(resDir .. res .. ".tga", Vector4(0, 0, 0, 0))
        })
      end
      if (v.unitType and v.unitType == 3 or v.type == 7) and 1 < tnum then
        ui["produce_l_" .. i].Text = tnum
      else
        ui["produce_l_" .. i].Text = nil
      end
      ui["produce_b_" .. i].EventMouseEnter = function(sender, e)
        if tonumber(data.list[i].type) ~= 7 then
          Tip.SetRpc("tip_sys_guild_item_compose_prize", {
            t = data.list[i].type,
            prizeId = data.list[i].prizeId
          })
          Tip.SetUseDescription(false)
          Tip.SetOwner(sender)
        end
      end
    else
      CleanOneProduce(i)
    end
  end
end, Gui.Control("main")({
  Size = Vector2(1128, 645),
  ComFuc.ComControl(nil, Vector2(1088, 42), Vector2(21, 13), 255, SkinF.shop_12),
  ComFuc.ComButton("research_center", GetUTF8Text("button_common_new_study"), Vector2(144, 40), Vector2(26, 14), 16, true, false),
  ComFuc.ComControl(nil, Vector2(592, 45), Vector2(517, 64), 255, SkinF.skin_playgame_017),
  ComFuc.ComLabel(nil, GetUTF8Text("button_common_new_conversion_03"), Vector2(572, 25), Vector2(527, 72), 0, 16, colt, "kAlignCenterMiddle"),
  Gui.Control({
    Size = Vector2(491, 564),
    Location = Vector2(21, 63),
    BackgroundColor = colw,
    Skin = SkinF.guild_031,
    ComFuc.ComLabel(nil, GetUTF8Text("button_common_new_convertinto"), Vector2(194, 24), Vector2(134, 217), 0, 16, coly),
    ComFuc.ComLabel("transform_value", "0", Vector2(194, 24), Vector2(134, 217), 0, 16, coly, "kAlignRightMiddle"),
    ComFuc.ComLabel("transform_rate", "0/12", Vector2(74, 24), Vector2(374, 217), 0, 16, coly, "kAlignCenterMiddle"),
    ComFuc.ComLabel(nil, GetUTF8Text("button_common_new_conversion_01"), Vector2(220, 24), Vector2(134, 291), 0, 16, colw),
    ComFuc.ComControl("light", Vector2(40, 42), Vector2(83, 289), 255, SkinF.guild_032),
    ComFuc.ComControl("water", Vector2(50, 35), Vector2(386, 283), 255, SkinF.guild_033),
    ComFuc.ComButton("clean_goods", GetUTF8Text("UI_store_mainUI_blank_50"), Vector2(84, 39), Vector2(36, 208), 16),
    ComFuc.ComButton("transform", nil, Vector2(163, 63), Vector2(162, 479), 0, false, false, SkinF.guild_041),
    ComMoveInCB(1),
    ComMoveInCB(2),
    ComMoveInCB(3),
    ComMoveInCB(4),
    ComMoveInCB(5),
    ComMoveInCB(6),
    ComMoveInCB(7),
    ComMoveInCB(8),
    ComMoveInCB(9),
    ComMoveInCB(10),
    ComMoveInCB(11),
    ComMoveInCB(12),
    ComCanProduce(1),
    ComCanProduce(2),
    ComCanProduce(3),
    ComCanProduce(4)
  }),
  Gui.Control("depot")({
    Size = Vector2(592, 508),
    Location = Vector2(517, 111)
  })
})
local ComputePriceAndSafecall, CleanOneMoveIn = function(needRpc)
  local price = 0
  local k = 0
  ids = ""
  for i = 1, 12 do
    if hasInCombine[i] then
      ids = ids .. hasInCombine[i].pid .. ";"
      price = price + hasInCombine[i].sysComposeMerit * hasInCombine[i].quantity
      k = k + 1
    end
  end
  ui.transform_value.Text = price
  ui.transform_rate.Text = k .. "/12"
  local pbool = 0 < k
  ui.light.Visible = pbool
  ui.water.Visible = pbool
  ui.clean_goods.Enable = pbool
  ui.transform.Enable = pbool
  if not pbool then
    CleanAllProduce()
  end
  if needRpc and 0 < k then
    rpc.safecall("guild_item_compose_show", {itemIds = ids}, HasGoodSInProduce)
  end
end, Gui.Control("main")({
  Size = Vector2(1128, 645),
  ComFuc.ComControl(nil, Vector2(1088, 42), Vector2(21, 13), 255, SkinF.shop_12),
  ComFuc.ComButton("research_center", GetUTF8Text("button_common_new_study"), Vector2(144, 40), Vector2(26, 14), 16, true, false),
  ComFuc.ComControl(nil, Vector2(592, 45), Vector2(517, 64), 255, SkinF.skin_playgame_017),
  ComFuc.ComLabel(nil, GetUTF8Text("button_common_new_conversion_03"), Vector2(572, 25), Vector2(527, 72), 0, 16, colt, "kAlignCenterMiddle"),
  Gui.Control({
    Size = Vector2(491, 564),
    Location = Vector2(21, 63),
    BackgroundColor = colw,
    Skin = SkinF.guild_031,
    ComFuc.ComLabel(nil, GetUTF8Text("button_common_new_convertinto"), Vector2(194, 24), Vector2(134, 217), 0, 16, coly),
    ComFuc.ComLabel("transform_value", "0", Vector2(194, 24), Vector2(134, 217), 0, 16, coly, "kAlignRightMiddle"),
    ComFuc.ComLabel("transform_rate", "0/12", Vector2(74, 24), Vector2(374, 217), 0, 16, coly, "kAlignCenterMiddle"),
    ComFuc.ComLabel(nil, GetUTF8Text("button_common_new_conversion_01"), Vector2(220, 24), Vector2(134, 291), 0, 16, colw),
    ComFuc.ComControl("light", Vector2(40, 42), Vector2(83, 289), 255, SkinF.guild_032),
    ComFuc.ComControl("water", Vector2(50, 35), Vector2(386, 283), 255, SkinF.guild_033),
    ComFuc.ComButton("clean_goods", GetUTF8Text("UI_store_mainUI_blank_50"), Vector2(84, 39), Vector2(36, 208), 16),
    ComFuc.ComButton("transform", nil, Vector2(163, 63), Vector2(162, 479), 0, false, false, SkinF.guild_041),
    ComMoveInCB(1),
    ComMoveInCB(2),
    ComMoveInCB(3),
    ComMoveInCB(4),
    ComMoveInCB(5),
    ComMoveInCB(6),
    ComMoveInCB(7),
    ComMoveInCB(8),
    ComMoveInCB(9),
    ComMoveInCB(10),
    ComMoveInCB(11),
    ComMoveInCB(12),
    ComCanProduce(1),
    ComCanProduce(2),
    ComCanProduce(3),
    ComCanProduce(4)
  }),
  Gui.Control("depot")({
    Size = Vector2(592, 508),
    Location = Vector2(517, 111)
  })
})
local CleanOneMoveIn, CleanAllMoveIn = function(i, needRpc)
  ui["moveIn_p_" .. i].Visible = false
  GuildDepot.CleanOneMoveInState(i)
  hasInCombine[i] = nil
  ComputePriceAndSafecall(needRpc)
end, Gui.Control("main")({
  Size = Vector2(1128, 645),
  ComFuc.ComControl(nil, Vector2(1088, 42), Vector2(21, 13), 255, SkinF.shop_12),
  ComFuc.ComButton("research_center", GetUTF8Text("button_common_new_study"), Vector2(144, 40), Vector2(26, 14), 16, true, false),
  ComFuc.ComControl(nil, Vector2(592, 45), Vector2(517, 64), 255, SkinF.skin_playgame_017),
  ComFuc.ComLabel(nil, GetUTF8Text("button_common_new_conversion_03"), Vector2(572, 25), Vector2(527, 72), 0, 16, colt, "kAlignCenterMiddle"),
  Gui.Control({
    Size = Vector2(491, 564),
    Location = Vector2(21, 63),
    BackgroundColor = colw,
    Skin = SkinF.guild_031,
    ComFuc.ComLabel(nil, GetUTF8Text("button_common_new_convertinto"), Vector2(194, 24), Vector2(134, 217), 0, 16, coly),
    ComFuc.ComLabel("transform_value", "0", Vector2(194, 24), Vector2(134, 217), 0, 16, coly, "kAlignRightMiddle"),
    ComFuc.ComLabel("transform_rate", "0/12", Vector2(74, 24), Vector2(374, 217), 0, 16, coly, "kAlignCenterMiddle"),
    ComFuc.ComLabel(nil, GetUTF8Text("button_common_new_conversion_01"), Vector2(220, 24), Vector2(134, 291), 0, 16, colw),
    ComFuc.ComControl("light", Vector2(40, 42), Vector2(83, 289), 255, SkinF.guild_032),
    ComFuc.ComControl("water", Vector2(50, 35), Vector2(386, 283), 255, SkinF.guild_033),
    ComFuc.ComButton("clean_goods", GetUTF8Text("UI_store_mainUI_blank_50"), Vector2(84, 39), Vector2(36, 208), 16),
    ComFuc.ComButton("transform", nil, Vector2(163, 63), Vector2(162, 479), 0, false, false, SkinF.guild_041),
    ComMoveInCB(1),
    ComMoveInCB(2),
    ComMoveInCB(3),
    ComMoveInCB(4),
    ComMoveInCB(5),
    ComMoveInCB(6),
    ComMoveInCB(7),
    ComMoveInCB(8),
    ComMoveInCB(9),
    ComMoveInCB(10),
    ComMoveInCB(11),
    ComMoveInCB(12),
    ComCanProduce(1),
    ComCanProduce(2),
    ComCanProduce(3),
    ComCanProduce(4)
  }),
  Gui.Control("depot")({
    Size = Vector2(592, 508),
    Location = Vector2(517, 111)
  })
})
local CleanAllMoveIn, GetFirstNilSlot = function()
  for i = 1, 12 do
    CleanOneMoveIn(i, i == 12)
  end
end, Gui.Control("main")({
  Size = Vector2(1128, 645),
  ComFuc.ComControl(nil, Vector2(1088, 42), Vector2(21, 13), 255, SkinF.shop_12),
  ComFuc.ComButton("research_center", GetUTF8Text("button_common_new_study"), Vector2(144, 40), Vector2(26, 14), 16, true, false),
  ComFuc.ComControl(nil, Vector2(592, 45), Vector2(517, 64), 255, SkinF.skin_playgame_017),
  ComFuc.ComLabel(nil, GetUTF8Text("button_common_new_conversion_03"), Vector2(572, 25), Vector2(527, 72), 0, 16, colt, "kAlignCenterMiddle"),
  Gui.Control({
    Size = Vector2(491, 564),
    Location = Vector2(21, 63),
    BackgroundColor = colw,
    Skin = SkinF.guild_031,
    ComFuc.ComLabel(nil, GetUTF8Text("button_common_new_convertinto"), Vector2(194, 24), Vector2(134, 217), 0, 16, coly),
    ComFuc.ComLabel("transform_value", "0", Vector2(194, 24), Vector2(134, 217), 0, 16, coly, "kAlignRightMiddle"),
    ComFuc.ComLabel("transform_rate", "0/12", Vector2(74, 24), Vector2(374, 217), 0, 16, coly, "kAlignCenterMiddle"),
    ComFuc.ComLabel(nil, GetUTF8Text("button_common_new_conversion_01"), Vector2(220, 24), Vector2(134, 291), 0, 16, colw),
    ComFuc.ComControl("light", Vector2(40, 42), Vector2(83, 289), 255, SkinF.guild_032),
    ComFuc.ComControl("water", Vector2(50, 35), Vector2(386, 283), 255, SkinF.guild_033),
    ComFuc.ComButton("clean_goods", GetUTF8Text("UI_store_mainUI_blank_50"), Vector2(84, 39), Vector2(36, 208), 16),
    ComFuc.ComButton("transform", nil, Vector2(163, 63), Vector2(162, 479), 0, false, false, SkinF.guild_041),
    ComMoveInCB(1),
    ComMoveInCB(2),
    ComMoveInCB(3),
    ComMoveInCB(4),
    ComMoveInCB(5),
    ComMoveInCB(6),
    ComMoveInCB(7),
    ComMoveInCB(8),
    ComMoveInCB(9),
    ComMoveInCB(10),
    ComMoveInCB(11),
    ComMoveInCB(12),
    ComCanProduce(1),
    ComCanProduce(2),
    ComCanProduce(3),
    ComCanProduce(4)
  }),
  Gui.Control("depot")({
    Size = Vector2(592, 508),
    Location = Vector2(517, 111)
  })
})

function GetFirstNilSlot()
  for i = 1, 11 do
    if not hasInCombine[i] then
      return i
    end
  end
  return 12
end

function HasGoodsIn(i, td, type)
  if i == 0 then
    i = GetFirstNilSlot()
  end
  if hasInCombine[i] then
    CleanOneMoveIn(i)
  end
  hasInCombine[i] = td
  hasInCombine[i].type = type or 3
  ui["moveIn_p_" .. i].Visible = true
  ui["moveIn_p_" .. i].Skin = SkinF.personalInfo_quality[td.grade]
  ui["moveIn_b_" .. i].Skin = Gui.ButtonSkin({
    BackgroundImage = Gui.Image(resDir .. td.resource .. ".tga", Vector4(0, 0, 0, 0))
  })
  if td.quantity and td.quantity > 1 then
    ui["moveIn_l_" .. i].Text = td.quantity
  else
    ui["moveIn_l_" .. i].Text = nil
  end
  ComputePriceAndSafecall(true)
end

for i = 1, 12 do
  ui["moveIn_b_" .. i].EventRightClick = function(sender, e)
    gui:PlayAudio("cancel")
    CleanOneMoveIn(i, true)
  end
end

function ui.clean_goods.EventClick()
  CleanAllMoveIn()
end

function ui.transform.EventClick()
  rpc.safecall("guild_item_compose", {itemIds = ids}, function(data)
    CleanAllMoveIn()
    if not GainGoods then
      require("gainGoods.lua")
    end
    ui.coverControl2.Parent = gui
    gui:PlayAudio("convert_item")
    GainGoods.Show(data.list, GuildDepot.CombineGoodOK)
  end)
end

function FinishCompose()
  ui.coverControl2.Parent = nil
end

function Show(parentCtrl)
  if not GuildDepot then
    require("guildDepot.lua")
  end
  CleanAllMoveIn()
  GuildDepot.Show(ui.depot)
  ui.main.Parent = parentCtrl
end

function Hide()
  ui.main.Parent = nil
end
