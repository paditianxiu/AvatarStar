module("OpenBox", package.seeall)
require("bufList.lua")
col0 = ARGB(0, 0, 0, 0)
colw = ARGB(255, 255, 255, 255)
colt = ARGB(255, 113, 83, 65)
local resDir = "/ui/skinF/"
local resDir2 = "/ui/skinF/lobby/"
local goodsList = {}
local timer, boxTimer, showGoodTimer, showGiftTimer, drawerTimer, progressTimer, ptBar
local frameC = 100
local lightGoods, lightGoods1, boxRes
local boxGrade = 1
local boxPid = 1
local keyNumber = 0
local allBoxTbl = {}
local giftBoxTbl = {}
local giftBoxPrice = {}
local last_gift_point = 0
local screen_offset = ComFuc.locationChanged
local BOX = {
  size = Vector2(609, 480),
  middle = {
    x = 212 + screen_offset,
    y = 103
  },
  left = {
    x = -30 + screen_offset,
    y = 103
  }
}
local GOOD = {
  middle = nil,
  size = Vector2(425, 707),
  left = {
    x = 575 + screen_offset,
    y = 104
  }
}
local GIFT = {
  size = Vector2(573, 232),
  middle = {
    x = 333 + screen_offset,
    y = 573
  },
  left = {
    x = 89 + screen_offset,
    y = 573
  }
}
local GIFT_BOX = {
  Vector2(60, 84),
  Vector2(149, 84),
  Vector2(238, 84),
  Vector2(330, 84),
  Vector2(416, 84)
}
local CONNECTOR = {
  size = Vector2(195, 227),
  middle = nil,
  left = {x = 150, y = 470}
}
local DRAWER_GOLD = {
  size = Vector2(181, 116),
  middle = {x = 185, y = 10},
  left = {x = 50, y = 10}
}
local DRAWER_SILVER = {
  size = Vector2(181, 116),
  middle = {x = 185, y = 130},
  left = {x = 50, y = 130}
}
local DRAWER_COPPER = {
  size = Vector2(181, 116),
  middle = {x = 185, y = 250},
  left = {x = 50, y = 250}
}
local PROGRESS_SIZE = Vector2(450, 13)
local GIFT_BOX_FLASH = {
  x = GIFT.middle.x,
  y = GIFT.middle.y,
  frame_cnt = 20,
  frame_flx1 = 30,
  frame_finish = 40,
  frame_step = 59,
  frame_flx1_step = -8,
  frame_flx2_step = 7,
  alpha_scale = 1,
  timer = 0.01
}
local GOOD_FLASH, ComGoods = {
  x = GOOD.left.x,
  y = GOOD.left.y,
  connect_x = CONNECTOR.left.x,
  connect_y = CONNECTOR.left.y,
  frame_finish1 = 60,
  frame_finish2 = 108,
  frame_finish3 = 114,
  frame_finish4 = 120,
  frame_step1 = 10,
  frame_step2 = 10,
  frame_step3 = -6,
  frame_step4 = 6,
  alpha_scale = 1,
  timer = 0.01
}, CONNECTOR.left.y

function ComGoods(i)
  return ComFuc.ComItemCB("goods_" .. i, ComFuc.ComputLocation(i, -72, -84, 3, 86, 84), i)
end

local ui = Gui.Create()({
  ComFuc.ComControl("coverControl2", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(150, 0, 0, 0)),
  Gui.Control("mainCtrl_1")({
    Location = Vector2(BOX.middle.x, BOX.middle.y),
    Size = BOX.size,
    Gui.Control("drawer_gold")({
      Size = Vector2(181, 116),
      Location = Vector2(0, 0),
      Gui.Control("drawer_gold_tab")({
        Size = Vector2(181, 73),
        Location = Vector2(0, 20),
        BackgroundColor = colw,
        Skin = SkinF.openBox_004[5]
      }),
      Gui.Control("drawer_gold_box")({
        Size = Vector2(76, 76),
        Location = Vector2(51, 0),
        BackgroundColor = colw,
        Skin = SkinF.openBox_004[6]
      }),
      ComFuc.ComButton("drawer_gold_btn", GetUTF8Text("button_datalist_xuanzejinbx"), Vector2(120, 40), Vector2(36, 57), 16, false, true, SkinF.select_box_btn)
    }),
    Gui.Control("drawer_silver")({
      Size = Vector2(181, 116),
      Location = Vector2(DRAWER_SILVER.left.x, DRAWER_SILVER.left.y),
      Gui.Control("drawer_silver_tab")({
        Size = Vector2(181, 73),
        Location = Vector2(0, 20),
        BackgroundColor = colw,
        Skin = SkinF.openBox_004[5]
      }),
      Gui.Control("drawer_silver_box")({
        Size = Vector2(76, 76),
        Location = Vector2(51, 0),
        BackgroundColor = colw,
        Skin = SkinF.openBox_004[7]
      }),
      ComFuc.ComButton("drawer_silver_btn", GetUTF8Text("button_datalist_xuanzeyinbx"), Vector2(120, 40), Vector2(36, 57), 16, false, true, SkinF.select_box_btn)
    }),
    Gui.Control("drawer_copper")({
      Size = Vector2(181, 116),
      Location = Vector2(DRAWER_COPPER.left.x, DRAWER_COPPER.left.y),
      Gui.Control("drawer_copper_tab")({
        Size = Vector2(181, 73),
        Location = Vector2(0, 20),
        BackgroundColor = colw,
        Skin = SkinF.openBox_004[5]
      }),
      Gui.Control("drawer_copper_box")({
        Size = Vector2(76, 76),
        Location = Vector2(51, 0),
        BackgroundColor = colw,
        Skin = SkinF.openBox_004[8]
      }),
      ComFuc.ComButton("drawer_copper_btn", GetUTF8Text("button_datalist_xuanzetongbx"), Vector2(120, 40), Vector2(36, 57), 16, false, true, SkinF.select_box_btn)
    }),
    Gui.Control("box")({
      Size = Vector2(428, 480),
      BackgroundColor = colw,
      Location = Vector2(181, 0),
      Skin = SkinF.openBox_004[1],
      ComFuc.ComButton("bBox_open", nil, Vector2(70, 71), Vector2(93, 303), 16, false, false, SkinF.openBox_005),
      ComFuc.ComButton("bBox_open10", nil, Vector2(70, 71), Vector2(288, 303), 16, false, false, SkinF.openBox_006),
      ComFuc.ComButton("bKey_buy", GetUTF8Text("button_common_Buy_Key"), Vector2(80, 41), Vector2(92, 395), 16, false, true, SkinF.personalInfo_200),
      ComFuc.ComButton("look_good", GetUTF8Text("button_common_Check_Reward"), Vector2(82, 41), Vector2(279, 395), 16, false, true, SkinF.personalInfo_200),
      ComFuc.ComControl("box_res", Vector2(40, 40), Vector2(185, 360), 255, SkinF.skin_touming),
      ComFuc.ComControl("box_key", Vector2(40, 40), Vector2(185, 396), 255, SkinF.skin_touming),
      ComFuc.ComLabel("box_count", nil, Vector2(40, 15), Vector2(228, 376), 0, 16, colw),
      ComFuc.ComLabel("key_count", nil, Vector2(40, 15), Vector2(228, 409), 0, 16, colw),
      ComFuc.ComLabel("openB_name", nil, Vector2(180, 20), Vector2(135, 28), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComButton("close", nil, Vector2(24, 24), Vector2(360, 26), 0, false, false, SkinF.lookInfo_002),
      ComFuc.ComControl("box_res_big", Vector2(251, 206), Vector2(98, 116), 255, SkinF.skin_touming)
    })
  }),
  Gui.Control("mainCtrl_2")({
    Size = GOOD.size,
    Location = Vector2(10 + BOX.left.x, GOOD.left.y),
    Gui.Control("connector")({
      Size = CONNECTOR.size,
      Location = Vector2(CONNECTOR.left.x, 0),
      BackgroundColor = colw,
      Skin = SkinF.openBox_004[9]
    }),
    Gui.Control("good")({
      Size = Vector2(425, 480),
      Location = Vector2(0, 0),
      BackgroundColor = colw,
      Skin = SkinF.openBox_004[2],
      ComFuc.ComLabel("openB_good", nil, Vector2(180, 20), Vector2(149, 28), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComButton("close_2", nil, Vector2(24, 24), Vector2(374, 26), 0, false, false, SkinF.lookInfo_002),
      ComFuc.ComPagesBar("pages", Vector2(105, 416)),
      Gui.Control({
        Size = Vector2(281, 332),
        Location = Vector2(94, 67),
        ComGoods(1),
        ComGoods(2),
        ComGoods(3),
        ComGoods(4),
        ComGoods(5),
        ComGoods(6),
        ComGoods(7),
        ComGoods(8),
        ComGoods(9),
        ComGoods(10),
        ComGoods(11),
        ComGoods(12)
      })
    })
  }),
  Gui.Control("gift_box")({
    Size = GIFT.size,
    Location = Vector2(GIFT.middle.x, 0),
    BackgroundColor = colw,
    Skin = SkinF.openBox_004[4],
    ComFuc.ComButton("gift_look1", GetUTF8Text("button_common_Check_Reward"), Vector2(80, 41), Vector2(60, 159), 16, false, true, SkinF.personalInfo_200),
    ComFuc.ComButton("gift_look2", GetUTF8Text("button_common_Check_Reward"), Vector2(80, 41), Vector2(149, 159), 16, false, true, SkinF.personalInfo_200),
    ComFuc.ComButton("gift_look3", GetUTF8Text("button_common_Check_Reward"), Vector2(80, 41), Vector2(238, 159), 16, false, true, SkinF.personalInfo_200),
    ComFuc.ComButton("gift_look4", GetUTF8Text("button_common_Check_Reward"), Vector2(80, 41), Vector2(327, 159), 16, false, true, SkinF.personalInfo_200),
    ComFuc.ComButton("gift_look5", GetUTF8Text("button_common_Check_Reward"), Vector2(80, 41), Vector2(416, 159), 16, false, true, SkinF.personalInfo_200),
    ComFuc.ComButton("gift_box1", nil, Vector2(80, 80), GIFT_BOX[1], 16, false, true, SkinF.openBox_007[1]),
    ComFuc.ComButton("gift_box2", nil, Vector2(80, 80), GIFT_BOX[2], 16, false, true, SkinF.openBox_007[2]),
    ComFuc.ComButton("gift_box3", nil, Vector2(80, 80), GIFT_BOX[3], 16, false, true, SkinF.openBox_007[3]),
    ComFuc.ComButton("gift_box4", nil, Vector2(80, 80), GIFT_BOX[4], 16, false, true, SkinF.openBox_007[4]),
    ComFuc.ComButton("gift_box5", nil, Vector2(80, 80), GIFT_BOX[5], 16, false, true, SkinF.openBox_007[5]),
    ComFuc.ComControl("dummy_gift_box1", Vector2(80, 80), GIFT_BOX[1]),
    ComFuc.ComControl("dummy_gift_box2", Vector2(80, 80), GIFT_BOX[2]),
    ComFuc.ComControl("dummy_gift_box3", Vector2(80, 80), GIFT_BOX[3]),
    ComFuc.ComControl("dummy_gift_box4", Vector2(80, 80), GIFT_BOX[4]),
    ComFuc.ComControl("dummy_gift_box5", Vector2(80, 80), GIFT_BOX[5]),
    Gui.Control("progress2")({
      Size = Vector2(0, 13),
      Location = Vector2(54, 73),
      BackgroundColor = colw,
      Skin = SkinF.openBox_008[1]
    }),
    Gui.Control("progress1")({
      Size = Vector2(0, 13),
      Location = Vector2(54, 73),
      BackgroundColor = colw,
      Skin = SkinF.openBox_008[2]
    }),
    ComFuc.ComLabel("progress_text", "", PROGRESS_SIZE, Vector2(54, 73), 0, PROGRESS_SIZE.y, ARGB(255, 255, 0, 0), "kAlignCenterMiddle"),
    ComFuc.ComFlashArrow("gift_box_tip1", Vector2(80, 42), GIFT_BOX[1] - Vector2(0, 60), 255, SkinF.lobbyMain_073, false, GetUTF8Text("tips_store_baoxiang_kaiqi")),
    ComFuc.ComFlashArrow("gift_box_tip2", Vector2(80, 42), GIFT_BOX[2] - Vector2(0, 60), 255, SkinF.lobbyMain_073, false, GetUTF8Text("tips_store_baoxiang_kaiqi")),
    ComFuc.ComFlashArrow("gift_box_tip3", Vector2(80, 42), GIFT_BOX[3] - Vector2(0, 60), 255, SkinF.lobbyMain_073, false, GetUTF8Text("tips_store_baoxiang_kaiqi")),
    ComFuc.ComFlashArrow("gift_box_tip4", Vector2(80, 42), GIFT_BOX[4] - Vector2(0, 60), 255, SkinF.lobbyMain_073, false, GetUTF8Text("tips_store_baoxiang_kaiqi")),
    ComFuc.ComFlashArrow("gift_box_tip5", Vector2(80, 42), GIFT_BOX[5] - Vector2(0, 60), 255, SkinF.lobbyMain_073, false, GetUTF8Text("tips_store_baoxiang_kaiqi"))
  }),
  ComFuc.ComControlAddPt("light_box1", Vector2(80, 72), Vector2(0, 0), "ui_lightning_box"),
  ComFuc.ComControlAddPt("light_box2", Vector2(80, 72), Vector2(0, 0), "ui_lightning_box"),
  ComFuc.ComControlAddPt("light_box3", Vector2(200, 70), Vector2(0, 0), "ui_lightning_box_1"),
  ComFuc.ComControlAddPt("light_box4", Vector2(320, 70), Vector2(0, 0), "ui_lightning_box_2"),
  ComFuc.ComControl("disableUI", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(0, 0, 0, 0))
})
ui.drawer_gold_btn.Padding = Vector4(0, 0, 0, 6)
ui.drawer_silver_btn.Padding = Vector4(0, 0, 0, 6)
ui.drawer_copper_btn.Padding = Vector4(0, 0, 0, 6)
for i = 1, 5 do
  ui["dummy_gift_box" .. i].Visible = false
  local TimerShowGiftPoint = 0
end
local ShowGiftPoint = function(curr, total)
  local frame_curr = last_gift_point
  local frame_cnt = curr
  ui.progress2.Size = Vector2(PROGRESS_SIZE.x * curr / total, PROGRESS_SIZE.y)
  return function()
    if frame_curr < frame_cnt then
      ui.progress1.Size = Vector2(PROGRESS_SIZE.x * frame_curr / total, PROGRESS_SIZE.y)
    else
      ui.progress1.Size = ui.progress2.Size
      game.TimerMgr:RemoveTimer(progressTimer)
      progressTimer = nil
      last_gift_point = curr
    end
    frame_curr = frame_curr + 1
  end
end
local EnableGiftBox = function(curr, total)
  ui.progress_text.Text = curr .. "/" .. total
  if progressTimer then
    game.TimerMgr:RemoveTimer(progressTimer)
  end
  progressTimer = game.TimerMgr:AddTimer(0.01)
  progressTimer.EventOnTimer = TimerShowGiftPoint(curr, total)
end
local DisableGiftBox = function(currPoint, pointList)
  for i = 1, #pointList do
    if currPoint < pointList[i].unit then
      ui["dummy_gift_box" .. i].Visible = true
    else
      ui["dummy_gift_box" .. i].Visible = false
      ui["gift_box_tip" .. i].Visible = true
      ui["gift_box" .. i].Enable = true
    end
  end
end
local TimerShowGiftPoint, GainGoodsFuc = function()
  for i = 1, 5 do
    ui["gift_box" .. i].Enable = false
  end
end, ui["dummy_gift_box" .. i]

function GainGoodsFuc()
  ui.box_res_big.Skin = Gui.ControlSkin({
    BackgroundImage = Gui.Image(resDir .. "skin_" .. boxRes .. "_close.tga", Vector4(0, 0, 0, 0))
  })
  if ptBar then
    gui:RemoveParticle(ptBar)
    ptBar = nil
  end
end

function TimerRemove()
  if timer then
    game.TimerMgr:RemoveTimer(timer)
  end
  frameC = 10
  timer = nil
end

function TimerRemoveIt(t)
  if t then
    game.TimerMgr:RemoveTimer(t)
  end
end

local TimerRefresh, TimerShowBox = function(openType)
  return function()
    if frameC <= 8 then
      if frameC == 0 then
        gui:AddParticle("ui_bao_ray", ui.mainCtrl_1:ClientToScreen(Vector2(364, 240)), Vector3(0, 0, -1))
      end
      if frameC == 4 then
        if ptBar then
          gui:RemoveParticle(ptBar)
          ptBar = nil
        end
        ptBar = gui:AddParticle("ui_bao_star", ui.mainCtrl_1:ClientToScreen(Vector2(364, 240)), Vector3(0, 0, -1))
      end
      if frameC == 5 then
      end
      frameC = frameC + 1
    else
      TimerRemove()
    end
  end
end, function(openType)
  return function()
    if frameC <= 8 then
      if frameC == 0 then
        gui:AddParticle("ui_bao_ray", ui.mainCtrl_1:ClientToScreen(Vector2(364, 240)), Vector3(0, 0, -1))
      end
      if frameC == 4 then
        if ptBar then
          gui:RemoveParticle(ptBar)
          ptBar = nil
        end
        ptBar = gui:AddParticle("ui_bao_star", ui.mainCtrl_1:ClientToScreen(Vector2(364, 240)), Vector3(0, 0, -1))
      end
      if frameC == 5 then
      end
      frameC = frameC + 1
    else
      TimerRemove()
    end
  end
end
local TimerShowBox, _update_gift_box_tips = function()
  local frame_curr = 1
  local frame_cnt = 7
  local box_res_pos = ui.box_res_big.Location
  return function()
    frame_curr = frame_curr + 1
    if frame_curr < frame_cnt then
      local offset
      if frame_curr % 2 == 0 then
        offset = -5
      else
        offset = 5
      end
      ui.box_res_big.Location = Vector2(box_res_pos.x, box_res_pos.y + offset)
    else
      ui.box_res_big.Location = Vector2(box_res_pos.x, box_res_pos.y)
      if boxTimer then
        game.TimerMgr:RemoveTimer(boxTimer)
      end
      boxTimer = nil
    end
  end
end, ComFuc.ComControlAddPt("light_box2", Vector2(80, 72), Vector2(0, 0), "ui_lightning_box")
local _update_gift_box_tips, DealBoxInfo = function(box_info_tbl)
  for i = 1, #box_info_tbl do
    ui["gift_box" .. i].Hint = GetMatchedUTF8Text("tips_store_baoxiang_nengliangkaiqi" .. "," .. box_info_tbl[i].unit)
    ui["dummy_gift_box" .. i].Hint = ui["gift_box" .. i].Hint
  end
end, ComFuc.ComControlAddPt("light_box3", Vector2(200, 70), Vector2(0, 0), "ui_lightning_box_1")
local DealBoxInfo, ShowGoodsPages = function(no_ani, keep_big_box)
  return function(data)
    if keep_big_box ~= true then
      ui.box_res_big.Skin = Gui.ControlSkin({
        BackgroundImage = Gui.Image(resDir .. "skin_" .. data.boxResource .. "_close.tga", Vector4(0, 0, 0, 0))
      })
    end
    ui.box_res.Skin = Gui.ControlSkin({
      BackgroundImage = Gui.Image(resDir .. "skin_" .. data.boxResource .. "_02.tga", Vector4(0, 0, 0, 0))
    })
    ui.box_key.Skin = Gui.ControlSkin({
      BackgroundImage = Gui.Image(resDir .. "skin_baoxiang_" .. data.keyResource .. "_02.tga", Vector4(0, 0, 0, 0))
    })
    keyNumber = data.keyNum or "0"
    boxRes = data.boxResource or ""
    ui.box_res.Visible = true
    ui.box_key.Visible = true
    ui.openB_name.Text = GetUTF8Text(data.boxName)
    ui.openB_good.Text = string.format(GetUTF8Text("UI_store_additional_string_119"), "")
    ui.box_count.Text = "x " .. data.boxNum
    ui.key_count.Text = "x " .. data.keyNum
    ui.box_key.Hint = GetUTF8Text(data.keyName)
    ui.bBox_open.Enable = 0 < data.boxNum
    ui.bBox_open10.Enable = data.boxCategory <= 3
    giftBoxPrice.category = data.boxCategory
    giftBoxPrice.price = data.price
    ShowGiftPoint(data.currentPoint, data.maxPoint)
    EnableGiftBox(data.currentPoint, data.pointList)
    giftBoxTbl = data.pointList
    _update_gift_box_tips(giftBoxTbl)
    if boxTimer then
      game.TimerMgr:RemoveTimer(boxTimer)
    end
    if no_ani == nil or no_ani == false then
      boxTimer = game.TimerMgr:AddTimer(0.04)
      boxTimer.EventOnTimer = TimerShowBox()
    end
  end
end, ComFuc.ComControlAddPt("light_box4", Vector2(320, 70), Vector2(0, 0), "ui_lightning_box_2")
local ShowGoodsPages, DealBoxPrizeList = function()
  local t = #goodsList
  local b = (ui.pages.CurrIndex - 1) * 12
  local c = math.min(t - b, 12)
  for i = 1, c do
    local v = goodsList[b + i]
    v.grade = v.grade or 1
    ui["goods_" .. i .. "_lev"].Skin = SkinF.personalInfo_quality[v.grade]
    local res = v.resource
    if v.type == 2 and v.subType == 102 then
      local a = rpc.load_result("fuck = {" .. res .. "}")
      res = a.fuck[1]
    end
    ui["goods_" .. i .. "_res"].Skin = Gui.Gui.ControlSkin({
      BackgroundImage = Gui.Image(resDir2 .. res .. ".tga", Vector4(0, 0, 0, 0))
    })
    if v.unitType and v.unitType == 3 and 1 < v.unit then
      ui["goods_" .. i .. "_count"].Text = v.unit
    else
      ui["goods_" .. i .. "_count"].Text = nil
    end
    if v.type == 5 then
      if v.subType == 1 then
        ui["goods_" .. i .. "_res"].Skin = SkinF.personalInfo_095
      elseif v.subType == 2 then
        ui["goods_" .. i .. "_res"].Skin = SkinF.personalInfo_262
      end
    end
    ui["goods_" .. i .. "_res"].EventMouseEnter = function(sender, e)
      if v.type ~= 7 then
        if v.type == 5 then
          Tip.SetRpc("tip_sys_avatar", {
            t = v.type,
            sid = v.id
          })
        else
          Tip.SetRpc("tip_sys_box_prize", {
            t = v.type,
            prizeId = v.prizeId
          })
        end
        Tip.SetUseDescription(false)
        Tip.SetOwner(sender)
      end
    end
    ui["goods_" .. i .. "_lev"].Visible = true
    ui["goods_" .. i .. "_res"].Visible = true
    ui["goods_" .. i .. "_count"].Visible = true
  end
  for i = c + 1, 12 do
    ui["goods_" .. i .. "_lev"].Visible = false
    ui["goods_" .. i .. "_res"].Visible = false
    ui["goods_" .. i .. "_count"].Visible = false
  end
end, ComFuc.ComControl("disableUI", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(0, 0, 0, 0))
local DealBoxPrizeList, RemoveAllParticle = function(data)
  goodsList = data.list
  ui.pages.CurrIndex = 1
  ui.pages.PageCount = math.floor((#goodsList - 0.1) / 12) + 1
  ShowGoodsPages()
end, ComFuc.ComControl("disableUI", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(0, 0, 0, 0))
local RemoveAllParticle, UpdateLightPos = function()
  ui.light_box1.Visible = false
  ui.light_box2.Visible = false
  ui.light_box3.Visible = false
  ui.light_box4.Visible = false
end, ComFuc.ComControl("disableUI", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(0, 0, 0, 0))
local UpdateLightPos, SwitchParticle = function(light_index)
  local pos
  if light_index == 1 then
    pos = Vector2(ui.box.Location.x + ui.box.Size.x - 28, ui.box.Location.y + 82)
    pos = ui.mainCtrl_1:ClientToScreen(pos)
    ui.light_box1.Location = pos
  elseif light_index == 2 then
    pos = Vector2(ui.box.Location.x + ui.box.Size.x - 28, ui.box.Location.y + 343)
    pos = ui.mainCtrl_1:ClientToScreen(pos)
    ui.light_box2.Location = pos
  elseif light_index == 3 then
    pos = Vector2(ui.gift_box.Location.x + ui.gift_box.Size.x - 50, ui.gift_box.Location.y + 120)
    ui.light_box3.Location = pos
  elseif light_index == 4 then
    pos = Vector2(ui.gift_box.Location.x + ui.gift_box.Size.x - 110, ui.gift_box.Location.y + 155)
    ui.light_box4.Location = pos
  end
end, ComFuc.ComControl("disableUI", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(0, 0, 0, 0))
local SwitchParticle, TimerShowGood = function(openType)
  local pos
  RemoveAllParticle()
  if openType == "normal_look" then
    gui:PlayAudio("luckydraw_expand_sq4_lp", true)
    gui:PlayAudio("luckydraw_expand_sq3_lp")
    ui.light_box3.Visible = false
    ui.light_box4.Visible = false
    UpdateLightPos(1)
    UpdateLightPos(2)
    ui.light_box1.Particle:Reset()
    ui.light_box2.Particle:Reset()
    ui.light_box1.Visible = true
    ui.light_box2.Visible = true
  elseif openType == "gift_look" then
    gui:PlayAudio("luckydraw_expand_sq3_lp", true)
    gui:PlayAudio("luckydraw_expand_sq4_lp")
    ui.light_box1.Visible = false
    ui.light_box2.Visible = false
    UpdateLightPos(3)
    UpdateLightPos(4)
    ui.light_box3.Particle:Reset()
    ui.light_box4.Particle:Reset()
    ui.light_box3.Visible = true
    ui.light_box4.Visible = true
  end
end, ComFuc.ComControl("disableUI", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(0, 0, 0, 0))
local TimerShowGood, ShowGood = function(openType)
  local frameC = 20
  local timer_connector_pos
  return function()
    local ts = 1
    local pos
    frameC = frameC + 1
    if frameC < GOOD_FLASH.frame_finish1 then
      if frameC == 21 then
        gui:PlayAudio("luckydraw_expand_sq1")
      end
      pos = Vector2(frameC * GOOD_FLASH.frame_step1 + ui.mainCtrl_1.Location.x, GOOD_FLASH.y)
      ui.mainCtrl_2.Location = pos
    elseif frameC < GOOD_FLASH.frame_finish2 then
      if frameC == 90 then
        gui:PlayAudio("luckydraw_expand_sq2")
      end
      pos = Vector2(GOOD.left.x, GOOD.left.y)
      ui.mainCtrl_2.Location = pos
      if 3 < boxGrade then
        TimerRemoveIt(showGoodTimer)
        showGoodTimer = nil
        SwitchParticle(openType)
        ui.disableUI.Parent = nil
        return
      end
      ui.connector.Location = Vector2(CONNECTOR.left.x, (frameC - GOOD_FLASH.frame_finish1) * GOOD_FLASH.frame_step2)
      timer_connector_pos = ui.connector.Location
    elseif frameC < GOOD_FLASH.frame_finish3 then
      timer_connector_pos.y = timer_connector_pos.y + GOOD_FLASH.frame_step3
      ui.connector.Location = timer_connector_pos
    elseif frameC < GOOD_FLASH.frame_finish4 then
      timer_connector_pos.y = timer_connector_pos.y + GOOD_FLASH.frame_step4
      ui.connector.Location = timer_connector_pos
    else
      ui.connector.Location = Vector2(CONNECTOR.left.x, CONNECTOR.left.y)
    end
    if frameC >= GOOD_FLASH.frame_finish4 then
      if ptBar then
        gui:UpdateLayout(true)
        local pos = ui.mainCtrl_1:ClientToScreen(Vector2(214, 240))
        gui:UpdateParticlePosition(ptBar, pos)
      end
      SwitchParticle(openType)
      TimerRemoveIt(showGoodTimer)
      showGoodTimer = nil
      ui.disableUI.Parent = nil
    end
  end
end, ComFuc.ComControl("disableUI", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(0, 0, 0, 0))
local ShowGood, _rpc_box_info = function(action, openType)
  local already_show = false
  if action == "force_hide" then
    RemoveAllParticle()
    if ui.mainCtrl_2.Visible == false then
      return
    end
    ui.mainCtrl_2.Visible = false
  elseif action == "force_show" then
    if ui.mainCtrl_2.Visible then
      SwitchParticle(openType)
      return
    end
    ui.mainCtrl_2.Visible = true
  elseif action == "force_toggle" then
    ui.mainCtrl_2.Visible = not ui.mainCtrl_2.Visible
  end
  if ui.mainCtrl_2.Visible then
    ui.mainCtrl_1.Location = Vector2(BOX.left.x, BOX.left.y)
    ui.gift_box.Location = Vector2(GIFT.left.x, GIFT.left.y)
    ui.connector.Location = Vector2(CONNECTOR.left.x, 0), assert(showGoodtimer == nil)
    ui.disableUI.Parent = gui
    showGoodTimer = game.TimerMgr:AddTimer(GOOD_FLASH.timer)
    showGoodTimer.EventOnTimer = TimerShowGood(openType)
  else
    ui.mainCtrl_1.Location = Vector2(BOX.middle.x, BOX.middle.y)
    ui.gift_box.Location = Vector2(GIFT.middle.x, GIFT.middle.y)
  end
end, ComFuc.ComControl("disableUI", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(0, 0, 0, 0))
local _rpc_box_info, _rpc_box_prize = function(category, no_ani, keep_big_box)
  for i = 1, 5 do
    ui["gift_box" .. i].Enable = false
    ui["gift_box_tip" .. i].Visible = false
  end
  local func = DealBoxInfo(no_ani, keep_big_box)
  rpc.safecall("box_info", {
    type = 3,
    subType = 400,
    category = category
  }, func)
end, ComFuc.ComControl("disableUI", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(0, 0, 0, 0))
local _rpc_box_prize, TimerSwitchDrawer = function(category)
  rpc.safecall("box_prize_list", {
    type = 3,
    subType = 400,
    category = category
  }, DealBoxPrizeList)
end, ComFuc.ComControl("disableUI", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(0, 0, 0, 0))
local TimerSwitchDrawer, SwitchDrawer = function(n, no_ani)
  gui:PlayAudio("luckydraw_expand_sq3_lp", true)
  gui:PlayAudio("luckydraw_expand_sq4_lp", true)
  local frame_cnt1 = 10
  local frame_curr = 1
  return function()
    frame_curr = frame_curr + 1
    local gold_pos, silver_pos, copper_pos
    local box_res_name = allBoxTbl[n] and allBoxTbl[n].boxRes or ""
    if no_ani then
      if n == 3 then
        gold_pos = Vector2(DRAWER_GOLD.middle.x, DRAWER_GOLD.middle.y)
        silver_pos = Vector2(DRAWER_SILVER.left.x, DRAWER_SILVER.left.y)
        copper_pos = Vector2(DRAWER_COPPER.left.x, DRAWER_COPPER.left.y)
      elseif n == 2 then
        gold_pos = Vector2(DRAWER_GOLD.left.x, DRAWER_GOLD.left.y)
        silver_pos = Vector2(DRAWER_SILVER.middle.x, DRAWER_SILVER.middle.y)
        copper_pos = Vector2(DRAWER_COPPER.left.x, DRAWER_COPPER.left.y)
      elseif n == 1 then
        gold_pos = Vector2(DRAWER_GOLD.left.x, DRAWER_GOLD.left.y)
        silver_pos = Vector2(DRAWER_SILVER.left.x, DRAWER_SILVER.left.y)
        copper_pos = Vector2(DRAWER_COPPER.middle.x, DRAWER_COPPER.middle.y)
      else
        gold_pos = Vector2(DRAWER_GOLD.left.x, DRAWER_GOLD.left.y)
        silver_pos = Vector2(DRAWER_SILVER.left.x, DRAWER_SILVER.left.y)
        copper_pos = Vector2(DRAWER_COPPER.left.x, DRAWER_COPPER.left.y)
      end
    elseif frame_curr < frame_cnt1 then
      local offset
      gold_pos = Vector2(DRAWER_GOLD.left.x, DRAWER_GOLD.left.y)
      silver_pos = Vector2(DRAWER_SILVER.left.x, DRAWER_SILVER.left.y)
      copper_pos = Vector2(DRAWER_COPPER.left.x, DRAWER_COPPER.left.y)
      offset = DRAWER_GOLD.middle.x - DRAWER_GOLD.left.x
      offset = frame_curr * offset / frame_cnt1
      if n == 3 then
        gold_pos.x = gold_pos.x + offset
      elseif n == 2 then
        silver_pos.x = silver_pos.x + offset
      elseif n == 1 then
        copper_pos.x = copper_pos.x + offset
      end
    elseif frame_curr >= frame_cnt1 then
      if frame_curr == frame_cnt1 then
        gui:PlayAudio("luckydraw_case")
      end
      if n == 3 then
        gold_pos = Vector2(DRAWER_GOLD.middle.x, DRAWER_GOLD.middle.y)
        silver_pos = Vector2(DRAWER_SILVER.left.x, DRAWER_SILVER.left.y)
        copper_pos = Vector2(DRAWER_COPPER.left.x, DRAWER_COPPER.left.y)
      elseif n == 2 then
        gold_pos = Vector2(DRAWER_GOLD.left.x, DRAWER_GOLD.left.y)
        silver_pos = Vector2(DRAWER_SILVER.middle.x, DRAWER_SILVER.middle.y)
        copper_pos = Vector2(DRAWER_COPPER.left.x, DRAWER_COPPER.left.y)
      elseif n == 1 then
        gold_pos = Vector2(DRAWER_GOLD.left.x, DRAWER_GOLD.left.y)
        silver_pos = Vector2(DRAWER_SILVER.left.x, DRAWER_SILVER.left.y)
        copper_pos = Vector2(DRAWER_COPPER.middle.x, DRAWER_COPPER.middle.y)
      else
        gold_pos = Vector2(DRAWER_GOLD.left.x, DRAWER_GOLD.left.y)
        silver_pos = Vector2(DRAWER_SILVER.left.x, DRAWER_SILVER.left.y)
        copper_pos = Vector2(DRAWER_COPPER.left.x, DRAWER_COPPER.left.y)
      end
      TimerRemoveIt(drawerTimer)
      drawerTimer = nil
    end
    ui.drawer_gold.Location = gold_pos
    ui.drawer_silver.Location = silver_pos
    ui.drawer_copper.Location = copper_pos
    if no_ani or frame_curr >= frame_cnt1 then
      _rpc_box_info(n, no_ani, false)
      _rpc_box_prize(n)
    else
      ui.box_res_big.Skin = Gui.ControlSkin({
        BackgroundImage = Gui.Image(nil, Vector4(0, 0, 0, 0))
      })
    end
  end
end, ComFuc.ComControl("disableUI", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(0, 0, 0, 0))
local SwitchDrawer, GenDrawerSel = function(n, no_ani)
  boxGrade = n
  ShowGood("force_hide")
  ui.gift_box.Visible = false
  ui.connector.Visible = false
  if n <= 3 then
    ui.bBox_open10.Enable = true
    ui.gift_box.Visible = true
    ui.gift_box.Location = Vector2(GIFT_BOX_FLASH.x, GIFT_BOX_FLASH.y)
    ui.connector.Visible = true
    boxPid = 0
    if no_ani ~= nil and no_ani == true then
      local show = TimerSwitchDrawer(n, no_ani)
      show()
    else
      if drawerTimer then
        TimerRemoveIt(drawerTimer)
      end
      drawerTimer = game.TimerMgr:AddTimer(0.05)
      drawerTimer.EventOnTimer = TimerSwitchDrawer(n, no_ani)
    end
  else
    ui.bBox_open10.Enable = false
    ui.gift_box.Visible = false
    ui.connector.Visible = false
    local show = TimerSwitchDrawer(n, no_ani)
    show()
  end
end, ComFuc.ComControl("disableUI", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(0, 0, 0, 0))
local GenDrawerSel, DealBoxOpen = function(n)
  return function(sender, e)
    SwitchDrawer(n)
  end
end, ComFuc.ComControl("disableUI", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(0, 0, 0, 0))
local DealBoxOpen, DealGiftBoxOpen = function(openType)
  return function(data)
    if openType == 0 then
      gui:PlayAudio("luckydraw_up_sg")
    else
      gui:PlayAudio("luckydraw_up_mp")
    end
    ui.box_res_big.Skin = Gui.ControlSkin({
      BackgroundImage = Gui.Image(resDir .. "skin_" .. boxRes .. "_open.tga", Vector4(0, 0, 0, 0))
    })
    frameC = 0
    timer = game.TimerMgr:AddTimer(0.1)
    local timer_func = TimerRefresh(openType)
    timer.EventOnTimer = timer_func
    if not GainGoods then
      require("gainGoods.lua")
    end
    GainGoods.Show(data.list, GainGoodsFuc, "tip_sys_box_prize")
    _rpc_box_info(boxGrade, true, true)
  end
end, ComFuc.ComControl("disableUI", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(0, 0, 0, 0))
local DealGiftBoxOpen, DealEndQuickBuy = function(category, openType)
  return function(data)
    frameC = 0
    timer = game.TimerMgr:AddTimer(0.1)
    local timer_func = TimerRefresh(openType)
    timer.EventOnTimer = timer_func
    if not GainGoods then
      require("gainGoods.lua")
    end
    gui:PlayAudio("convert_item")
    GainGoods.Show(data.list, GainGoodsFuc, "tip_sys_box_prize")
    _rpc_box_info(boxGrade, true, true)
  end
end, ComFuc.ComControl("disableUI", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(0, 0, 0, 0))

function DealEndQuickBuy()
  rpc.safecall("box_info", {
    type = 3,
    subType = 400,
    category = boxGrade
  }, DealBoxInfo(true))
  PersonalInfo.ReflashMail()
end

function ui.close.EventClick(sender, e)
  Hide()
end

ui.drawer_gold_btn.EventClick = GenDrawerSel(3)
ui.drawer_silver_btn.EventClick = GenDrawerSel(2)
ui.drawer_copper_btn.EventClick = GenDrawerSel(1)

function ui.close_2.EventClick(sender, e)
  gui:PlayAudio("luckydraw_expand_sq3_lp", true)
  gui:PlayAudio("luckydraw_expand_sq4_lp", true)
  ShowGood("force_hide")
  if ptBar then
    ui.main:UpdateLayout(true)
    gui:UpdateParticlePosition(ptBar, ui.mainCtrl_1:ClientToScreen(Vector2(214, 240)))
  end
end

function ui.look_good.EventClick(sender, e)
  _rpc_box_prize(boxGrade)
  ShowGood("force_show", "normal_look")
end

function ui.bKey_buy.EventClick(sender, e)
  if not QuickBuy then
    require("shop/quick_buy.lua")
  end
  QuickBuy.Show({
    t = 3,
    st = "401",
    category = boxGrade
  })
  QuickBuy.callback = DealEndQuickBuy
  QuickBuy.call_back_failed = Hide
end

local ui.bBox_open.EventClick, box_open10 = function(sender, e)
  if keyNumber <= 0 then
    MessageBox.ShowError(GetUTF8Text("msgbox_common_num_1275"))
  else
    sender.Enable = false
    DisableGiftBox()
    local func = DealBoxOpen(0)
    rpc.safecall("box_open", {
      type = 3,
      subType = 400,
      category = boxGrade,
      playerItemId = boxPid,
      openType = 0
    }, func)
    PersonalInfo.ReflashMail()
  end
end, ui.bBox_open

function box_open10(sender)
  return function()
    sender.Enable = false
    DisableGiftBox()
    ui.bBox_open.Enable = false
    local func = DealBoxOpen(1)
    rpc.safecall("box_open", {
      type = 3,
      subType = 400,
      category = boxGrade,
      playerItemId = boxPid,
      openType = 1
    }, func, Hide)
    PersonalInfo.ReflashMail()
  end
end

function ui.bBox_open10.EventClick(sender, e)
  local func = box_open10(sender)
  str = string.format(GetUTF8Text("msgbox_common_baoxiang_shiliankai"), giftBoxPrice.price)
  MessageBox.ShowWithConfirmCancel(str, func)
end

local ui.pages.EventIndexChanged, ShowGiftGood = function(sender, e)
  ShowGoodsPages()
end, ui.pages
local ShowGiftGood, OpenGiftGood = function(n)
  return function(sender, e)
    ShowGood("force_show", "gift_look")
    _rpc_box_prize(giftBoxTbl[n].category)
  end
end, function(sender, e)
  ShowGoodsPages()
end

function OpenGiftGood(n)
  return function(sender, e)
    local func = DealGiftBoxOpen(giftBoxTbl[n].category, 2)
    ui.bBox_open.Enable = false
    ui.bBox_open10.Enable = false
    rpc.safecall("box_open", {
      type = 3,
      subType = 400,
      category = giftBoxTbl[n].category,
      playerItemId = boxPid,
      openType = 2
    }, func)
  end
end

for i = 1, 5 do
  ui["gift_look" .. i].EventClick = ShowGiftGood(i)
end
for i = 1, 5 do
  ui["gift_box" .. i].EventClick = OpenGiftGood(i)
  local TimerShowGiftBox = ComFuc.ComControl("disableUI", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(0, 0, 0, 0))
end

function Resize()
  local offset = 0
  if 0 <= ComFuc.locationChanged then
    offset = ComFuc.locationChanged - screen_offset
    screen_offset = ComFuc.locationChanged
  end
  BOX.middle.x = BOX.middle.x + offset
  BOX.left.x = BOX.left.x + offset
  GOOD.left.x = GOOD.left.x + offset
  GIFT.middle.x = GIFT.middle.x + offset
  GIFT.left.x = GIFT.left.x + offset
  GIFT_BOX_FLASH.x = GIFT.middle.x
  GOOD_FLASH.x = GOOD.left.x
  ui.mainCtrl_1.Location = Vector2(ui.mainCtrl_1.Location.x + offset, ui.mainCtrl_1.Location.y)
  ui.mainCtrl_2.Location = Vector2(ui.mainCtrl_2.Location.x + offset, ui.mainCtrl_2.Location.y)
  ui.gift_box.Location = Vector2(ui.gift_box.Location.x + offset, ui.gift_box.Location.y)
  UpdateLightPos(1)
  UpdateLightPos(2)
  UpdateLightPos(3)
  UpdateLightPos(4)
end

function Show(category, pid, quantity)
  Resize()
  if 1 <= category and category <= 3 then
    gui:PlayAudio("luckydraw_drop")
  else
    gui:PlayAudio("prompt")
  end
  boxPid = pid
  ui.box_res.Visible = false
  ui.box_key.Visible = false
  ui.mainCtrl_2.Visible = false
  SwitchDrawer(category, true)
  ui.coverControl2.Parent = gui
  if timer then
    TimerRemove()
  end
  local refresh = TimerRefresh(0)
  refresh()
  assert(timer == nil)
  showGiftTimer = game.TimerMgr:AddTimer(GIFT_BOX_FLASH.timer)
  showGiftTimer.EventOnTimer = TimerShowGiftBox()
  ui.mainCtrl_1.Location = Vector2(BOX.middle.x, BOX.middle.y)
  ui.gift_box.Parent = gui
  ui.mainCtrl_2.Parent = gui
  ui.mainCtrl_1.Parent = gui
  ui.light_box1.Parent = gui
  ui.light_box2.Parent = gui
  ui.light_box3.Parent = gui
  ui.light_box4.Parent = gui
end

function Hide()
  gui:PlayAudio("luckydraw_expand_sq3_lp", true)
  gui:PlayAudio("luckydraw_expand_sq4_lp", true)
  TimerRemove()
  TimerRemoveIt(boxTimer)
  TimerRemoveIt(showGoodTimer)
  TimerRemoveIt(drawerTimer)
  TimerRemoveIt(progressTimer)
  ui.box_res.Visible = false
  ui.box_key.Visible = false
  ui.coverControl2.Parent = nil
  ui.gift_box.Parent = nil
  ui.mainCtrl_1.Parent = nil
  ui.mainCtrl_2.Parent = nil
  RemoveAllParticle()
end

function SetBoxTbl(tbl)
  allBoxTbl = tbl or {}
end
