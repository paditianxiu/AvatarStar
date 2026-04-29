module("VipPadShow", package.seeall)
require("vipPad.lua")
local td = VipPad.GetVipPadList()
local colw = ComFuc.colw
local colt = ComFuc.colt
local uiS = Vector2(1132, 542)
local baseCS = Vector2(130, 42)
local tryUseTime = 2
local vipLv, BaseC1 = 0, nil
local BaseC1, BaseC2 = function(i, t)
  size = Vector2(40, 40)
  lc = Vector2(0, 1)
  if i == 1 then
    size = Vector2(30, 30)
    lc = Vector2(5, 6)
  end
  local tsk = Gui.ControlSkin({
    BackgroundImage = Gui.Image("ui/skinF/" .. t.res, Vector4(0, 0, 0, 0))
  })
  return Gui.Control({
    Size = baseCS + Vector2(45, 0),
    ComFuc.ComControl(nil, size, lc, 255, tsk),
    ComFuc.ComLabel(nil, t.name, Vector2(135, 30), Vector2(40, 7), 0, 16, colw)
  })
end, nil
local BaseC2, BaseLine = function(i, j, t, p)
  size = Vector2(40, 40)
  lc = Vector2(25, 1)
  if j == 1 or j == 7 or j == 3 then
    size = Vector2(30, 30)
    lc = Vector2(30, 6)
  end
  local tsk = Gui.ControlSkin({
    BackgroundImage = Gui.Image("ui/skinF/" .. t[1].res, Vector4(0, 0, 0, 0))
  })
  if i == 4 and j == 5 then
    local tsk2 = Gui.ControlSkin({
      BackgroundImage = Gui.Image("ui/skinF/" .. t[2].res, Vector4(0, 0, 0, 0))
    })
    return Gui.Control("base_c2_" .. i .. "_" .. j)({
      Size = baseCS,
      Location = Vector2(46 + 132 * p, 0),
      ComFuc.ComControl("bsl_c_" .. i .. "_" .. j, size, lc - Vector2(10, 0), 255, tsk, true, true, nil, t[1].hint),
      ComFuc.ComLabel("bsl_l_" .. i .. "_" .. j, t[1].content, Vector2(60, 30), Vector2(52, 6), 0, 16, colt),
      ComFuc.ComControl("bsl_c2_" .. i .. "_" .. j, size, Vector2(80, 0), 255, tsk2, true, true, nil, t[2].hint)
    })
  end
  return Gui.Control("base_c2_" .. i .. "_" .. j)({
    Size = baseCS,
    Location = Vector2(46 + 132 * p, 0),
    ComFuc.ComControl("bsl_c_" .. i .. "_" .. j, size, lc, 255, tsk, true, true, nil, t[1].hint),
    ComFuc.ComLabel("bsl_l_" .. i .. "_" .. j, t[1].content, Vector2(60, 30), Vector2(62, 6), 0, 16, colt)
  })
end, nil

function BaseLine(i)
  return Gui.Control("base_line_" .. i)({
    Location = Vector2(8, 7 + i * 42),
    Size = Vector2(1100, 42),
    BaseC1(i, td["line" .. i]),
    BaseC2(1, i, td["line" .. i].row1, 1),
    BaseC2(2, i, td["line" .. i].row2, 3),
    BaseC2(3, i, td["line" .. i].row3, 4),
    BaseC2(4, i, td["line" .. i].row4, 5),
    BaseC2(5, i, td["line" .. i].row5, 6),
    BaseC2(6, i, td["line" .. i].row6, 7),
    BaseC2(7, i, td["line" .. i].row7, 2)
  })
end

local ui = Gui.Create()({
  ComFuc.ComControl("coverControl2", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(100, 0, 0, 0)),
  Gui.Control("main")({
    Dock = "kDockCenter",
    Size = uiS + Vector2(0, 4),
    Gui.Control("main_son")({
      Location = Vector2(0, 4),
      Size = uiS,
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_207,
      ComFuc.ComControl(nil, Vector2(132, 32), Vector2(14, 43), 255, SkinF.vipPadShow_003),
      ComFuc.ComControl("my_level", Vector2(32, 32), Vector2(174, 47), 255, SkinF.vipPadShow_004[1]),
      ComFuc.ComControl("next_tip", Vector2(452, 32), Vector2(330, 43), 255, SkinF.vipPadShow_005[1]),
      ComFuc.ComButton("close", nil, Vector2(24, 24), Vector2(uiS.x - 33, 4), 0, false, false, SkinF.lookInfo_002),
      ComFuc.ComButton("upGrade", "upgrade", Vector2(140, 44), Vector2(850, 39), 18, false, true),
      Gui.Control("tab_pad")({
        Location = Vector2(8, 89),
        Size = Vector2(1116, 436),
        BackgroundColor = colw,
        Skin = SkinF.vipPadShow_001,
        ComFuc.ComControl("level_tt_0", Vector2(80, 32), Vector2(208, 10), 255, SkinF.vipPadShow_008[1]),
        ComFuc.ComControl("level_tt_1", Vector2(80, 32), Vector2(472, 10), 255, SkinF.vipPadShow_008[2]),
        ComFuc.ComControl("level_tt_2", Vector2(80, 32), Vector2(604, 10), 255, SkinF.vipPadShow_008[3]),
        ComFuc.ComControl("level_tt_3", Vector2(80, 32), Vector2(736, 10), 255, SkinF.vipPadShow_008[4]),
        ComFuc.ComControl("level_tt_4", Vector2(80, 32), Vector2(868, 10), 255, SkinF.vipPadShow_008[5]),
        ComFuc.ComControl("level_tt_5", Vector2(80, 32), Vector2(1000, 10), 255, SkinF.vipPadShow_008[6]),
        ComFuc.ComControl("level_tt_6", Vector2(80, 32), Vector2(340, 10), 255, SkinF.vipPadShow_008[7]),
        ComFuc.ComControl("level_bg_0", Vector2(130, 378), Vector2(184, 49), 255, SkinF.vipPadShow_006[1]),
        ComFuc.ComControl("level_bg_1", Vector2(130, 378), Vector2(448, 49), 255, SkinF.vipPadShow_006[1]),
        ComFuc.ComControl("level_bg_2", Vector2(130, 378), Vector2(580, 49), 255, SkinF.vipPadShow_006[1]),
        ComFuc.ComControl("level_bg_3", Vector2(130, 378), Vector2(712, 49), 255, SkinF.vipPadShow_006[1]),
        ComFuc.ComControl("level_bg_4", Vector2(130, 378), Vector2(844, 49), 255, SkinF.vipPadShow_006[1]),
        ComFuc.ComControl("level_bg_5", Vector2(130, 378), Vector2(976, 49), 255, SkinF.vipPadShow_006[1]),
        ComFuc.ComControl("level_bg_6", Vector2(130, 378), Vector2(316, 49), 255, SkinF.vipPadShow_006[1]),
        ComFuc.ComControl("tab_pad_son", Vector2(1116, 436), Vector2(0, 0), 255, SkinF.vipPadShow_007),
        BaseLine(1),
        BaseLine(2),
        BaseLine(3),
        BaseLine(4),
        BaseLine(5),
        BaseLine(6),
        BaseLine(7),
        BaseLine(8),
        BaseLine(9)
      })
    }),
    ComFuc.ComButton("try_use", GetUTF8Text("button_store_VIP_temp_button_02"), Vector2(120, 44), Vector2(329, 96), 18, false, true),
    ComFuc.ComControl("main_vip_icon", Vector2(55, 31), Vector2(475, 0), 255, SkinF.vipPadShow_002)
  })
})
ui.try_use.Visible = false

function ui.close.EventClick()
  Hide()
end

function ui.upGrade.EventClick()
  if vipLv < 5 then
    local t = math.max(1, vipLv + 1)
    MessageBox.ShowWithConfirmCancel(VipPad.GetOpenMessage(t), function()
      rpc.safecall("add_vip_level", {}, function(data)
        Hide()
        Show(math.min(5, t))
        MessageBox.ShowError(VipPad.GetFinishOpenVipMesg(vipLv))
      end)
    end)
  else
    local t = math.max(1, vipLv + 1)
    MessageBox.ShowError(VipPad.GetFinishOpenVipMesg(t))
  end
end

function ui.try_use.EventClick()
  MessageBox.ShowWithTwoButtons(string.format(GetUTF8Text("msgbox_store_VIP_temp_01"), tonumber(tryUseTime) or 2), GetUTF8Text("button_store_VIP_temp_button_01"), GetUTF8Text("button_common_Cancel"), function()
    rpc.safecall("trial_vip", {}, function(data)
      ComFuc.isTrialingVip = true
      SetUISizeLocation()
      MessageBox.ShowError(string.format(GetUTF8Text("msgbox_store_VIP_temp_02"), tonumber(tryUseTime) or 2))
    end)
  end)
end

local SetUISizeLocation, InitData = function()
  local tempX = 132
  if ComFuc.isTrialedVip or ComFuc.VIPLevel >= 1 then
    ui.try_use.Visible = false
    tempX = 0
  elseif ComFuc.isTrialingVip then
    ui.my_level.Skin = SkinF.vipPadShow_009
    ui.level_bg_0.Skin = SkinF.vipPadShow_006[1]
    ui.level_bg_6.Skin = SkinF.vipPadShow_006[2]
    ui.try_use.Visible = false
  else
    ui.try_use.Visible = true
  end
  uiS = Vector2(1000 + tempX, 542)
  ui.main.Size = uiS + Vector2(0, 4)
  ui.main_son.Size = uiS
  ui.close.Location = Vector2(uiS.x - 33, 4)
  ui.next_tip.Location = Vector2(330 + tempX, 43)
  ui.upGrade.Location = Vector2(850 + tempX, 39)
  ui.main_vip_icon.Location = Vector2(475 + tempX / 2, 0)
  ui.tab_pad.Size = Vector2(984 + tempX, 436)
  ui.tab_pad_son.Size = Vector2(984 + tempX, 436)
  ui["level_tt_" .. 6].Visible = tempX == 132
  ui["level_bg_" .. 6].Visible = tempX == 132
  for i = 1, 5 do
    ui["level_tt_" .. i].Location = Vector2(208 + 132 * i + tempX, 10)
    ui["level_bg_" .. i].Location = Vector2(184 + 132 * i + tempX, 49)
  end
  for i = 2, 6 do
    for j = 1, 9 do
      ui["base_c2_" .. i .. "_" .. j].Location = Vector2(46 + 132 * i + tempX, 0)
    end
  end
  for i = 1, 9 do
    ui["base_c2_7_" .. i].Visible = tempX == 132
    ui["base_line_" .. i].Size = Vector2(968 + tempX, 42)
  end
end, function()
  local tempX = 132
  if ComFuc.isTrialedVip or ComFuc.VIPLevel >= 1 then
    ui.try_use.Visible = false
    tempX = 0
  elseif ComFuc.isTrialingVip then
    ui.my_level.Skin = SkinF.vipPadShow_009
    ui.level_bg_0.Skin = SkinF.vipPadShow_006[1]
    ui.level_bg_6.Skin = SkinF.vipPadShow_006[2]
    ui.try_use.Visible = false
  else
    ui.try_use.Visible = true
  end
  uiS = Vector2(1000 + tempX, 542)
  ui.main.Size = uiS + Vector2(0, 4)
  ui.main_son.Size = uiS
  ui.close.Location = Vector2(uiS.x - 33, 4)
  ui.next_tip.Location = Vector2(330 + tempX, 43)
  ui.upGrade.Location = Vector2(850 + tempX, 39)
  ui.main_vip_icon.Location = Vector2(475 + tempX / 2, 0)
  ui.tab_pad.Size = Vector2(984 + tempX, 436)
  ui.tab_pad_son.Size = Vector2(984 + tempX, 436)
  ui["level_tt_" .. 6].Visible = tempX == 132
  ui["level_bg_" .. 6].Visible = tempX == 132
  for i = 1, 5 do
    ui["level_tt_" .. i].Location = Vector2(208 + 132 * i + tempX, 10)
    ui["level_bg_" .. i].Location = Vector2(184 + 132 * i + tempX, 49)
  end
  for i = 2, 6 do
    for j = 1, 9 do
      ui["base_c2_" .. i .. "_" .. j].Location = Vector2(46 + 132 * i + tempX, 0)
    end
  end
  for i = 1, 9 do
    ui["base_c2_7_" .. i].Visible = tempX == 132
    ui["base_line_" .. i].Size = Vector2(968 + tempX, 42)
  end
end
local InitData, DealOneColumn = function(n)
  ui.my_level.Skin = SkinF.vipPadShow_004[n + 1]
  for i = 0, 6 do
    local t = 1
    if n == i then
      t = 2
    end
    ui["level_bg_" .. i].Skin = SkinF.vipPadShow_006[t]
  end
  local t = 1
  if 1 <= n then
    t = 2
  end
  ui.next_tip.Skin = SkinF.vipPadShow_005[t]
  if n <= 0 then
    ui.upGrade.Text = GetUTF8Text("button_store_get_VIP")
  elseif n == 5 then
    ui.upGrade.Text = GetUTF8Text("button_store_VIP_MAX")
  else
    ui.upGrade.Text = GetUTF8Text("button_store_lvup_VIP")
  end
  SetUISizeLocation()
end, function()
  MessageBox.ShowWithTwoButtons(string.format(GetUTF8Text("msgbox_store_VIP_temp_01"), tonumber(tryUseTime) or 2), GetUTF8Text("button_store_VIP_temp_button_01"), GetUTF8Text("button_common_Cancel"), function()
    rpc.safecall("trial_vip", {}, function(data)
      ComFuc.isTrialingVip = true
      SetUISizeLocation()
      MessageBox.ShowError(string.format(GetUTF8Text("msgbox_store_VIP_temp_02"), tonumber(tryUseTime) or 2))
    end)
  end)
end
local DealOneColumn, ShowBaseLine = function(i, v)
  ui["bsl_c_" .. i .. "_1"].Visible = v.price >= 0
  ui["bsl_c_" .. i .. "_2"].Visible = 0 < v.addCard
  ui["bsl_c_" .. i .. "_3"].Visible = 0 < v.addStageQuitGp
  ui["bsl_c_" .. i .. "_4"].Visible = 0 < v.addStageQuitExp
  ui["bsl_c_" .. i .. "_5"].Visible = 0 < v.addAuctionItem
  ui["bsl_c_" .. i .. "_7"].Visible = 0 < v.addQuestGp
  ui["bsl_c_" .. i .. "_8"].Visible = 0 < v.addMailAttachment
  ui["bsl_c_" .. i .. "_9"].Visible = 0 < #v.rewards
  if v.price >= 0 then
    j = 1
    ui["bsl_l_" .. i .. "_" .. j].Text = v.price
    if i == 2 then
      VipPad.openVipCost = v.price
    end
    if v.price > 0 then
      ui["bsl_c_" .. i .. "_" .. j].Hint = string.format(GetUTF8Text("UI_store_VIP_new_UI_01"), v.price)
    end
  end
  if 0 < v.addCard then
    j = 2
    ui["bsl_l_" .. i .. "_" .. j].Text = "+" .. v.addCard
    ui["bsl_c_" .. i .. "_" .. j].Hint = string.format(GetUTF8Text("UI_store_VIP_new_UI_02"), v.addCard)
  end
  if 0 < v.addStageQuitGp then
    j = 3
    ui["bsl_l_" .. i .. "_" .. j].Text = "+" .. tostring(v.addStageQuitGp * 100) .. "%"
    ui["bsl_c_" .. i .. "_" .. j].Hint = string.gsub(GetUTF8Text("tips_common_bewrite_Card_01"), "%%d", v.addStageQuitGp * 100)
  end
  if 0 < v.addStageQuitExp then
    j = 4
    ui["bsl_l_" .. i .. "_" .. j].Text = "+" .. tostring(v.addStageQuitExp * 100) .. "%"
    ui["bsl_c_" .. i .. "_" .. j].Hint = string.gsub(GetUTF8Text("tips_common_bewrite_Card_02"), "%%d", v.addStageQuitExp * 100)
  end
  if 0 < v.addAuctionItem then
    j = 5
    ui["bsl_l_" .. i .. "_" .. j].Text = "+" .. v.addAuctionItem
    ui["bsl_c_" .. i .. "_" .. j].Hint = string.format(GetUTF8Text("UI_store_VIP_new_UI_04"), v.addAuctionItem)
  end
  if 3 <= i and i <= 6 then
    j = 6
    local t = v.avatarCards[1]
    ui["bsl_l_" .. i .. "_" .. j].Text = "+" .. t.unit
    ui["bsl_c_" .. i .. "_" .. j].Skin = Gui.ControlSkin({
      BackgroundImage = Gui.Image("ui/skinF/lobby/" .. t.resource .. ".tga", Vector4(0, 0, 0, 0))
    })
    ui["bsl_c_" .. i .. "_" .. j].Hint = GetUTF8Text(t.displayName) .. "*" .. t.unit
  end
  if 0 < v.addQuestGp then
    j = 7
    ui["bsl_l_" .. i .. "_" .. j].Text = "+" .. v.addQuestGp * 100 .. "%"
    ui["bsl_c_" .. i .. "_" .. j].Hint = string.format(GetUTF8Text("UI_store_VIP_new_UI_06"), tostring(v.addQuestGp * 100) .. "%")
  end
  if 0 < v.addMailAttachment then
    j = 8
    ui["bsl_l_" .. i .. "_" .. j].Text = "+" .. v.addMailAttachment
    ui["bsl_c_" .. i .. "_" .. j].Hint = string.format(GetUTF8Text("UI_store_VIP_new_UI_07"), tonumber(v.addMailAttachment))
  end
  if 0 < #v.rewards then
    j = 9
    ui["bsl_l_" .. i .. "_" .. j].Text = "*1"
    local s = GetUTF8Text("UI_store_VIP_new_UI_08") .. "\n"
    for p, k in ipairs(v.rewards) do
      s = s .. GetUTF8Text(k.displayName) .. "*" .. k.unit .. ","
    end
    ui["bsl_c_" .. i .. "_" .. j].Hint = s
  end
end, Gui.Control("main")({
  Dock = "kDockCenter",
  Size = uiS + Vector2(0, 4),
  Gui.Control("main_son")({
    Location = Vector2(0, 4),
    Size = uiS,
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_207,
    ComFuc.ComControl(nil, Vector2(132, 32), Vector2(14, 43), 255, SkinF.vipPadShow_003),
    ComFuc.ComControl("my_level", Vector2(32, 32), Vector2(174, 47), 255, SkinF.vipPadShow_004[1]),
    ComFuc.ComControl("next_tip", Vector2(452, 32), Vector2(330, 43), 255, SkinF.vipPadShow_005[1]),
    ComFuc.ComButton("close", nil, Vector2(24, 24), Vector2(uiS.x - 33, 4), 0, false, false, SkinF.lookInfo_002),
    ComFuc.ComButton("upGrade", "upgrade", Vector2(140, 44), Vector2(850, 39), 18, false, true),
    Gui.Control("tab_pad")({
      Location = Vector2(8, 89),
      Size = Vector2(1116, 436),
      BackgroundColor = colw,
      Skin = SkinF.vipPadShow_001,
      ComFuc.ComControl("level_tt_0", Vector2(80, 32), Vector2(208, 10), 255, SkinF.vipPadShow_008[1]),
      ComFuc.ComControl("level_tt_1", Vector2(80, 32), Vector2(472, 10), 255, SkinF.vipPadShow_008[2]),
      ComFuc.ComControl("level_tt_2", Vector2(80, 32), Vector2(604, 10), 255, SkinF.vipPadShow_008[3]),
      ComFuc.ComControl("level_tt_3", Vector2(80, 32), Vector2(736, 10), 255, SkinF.vipPadShow_008[4]),
      ComFuc.ComControl("level_tt_4", Vector2(80, 32), Vector2(868, 10), 255, SkinF.vipPadShow_008[5]),
      ComFuc.ComControl("level_tt_5", Vector2(80, 32), Vector2(1000, 10), 255, SkinF.vipPadShow_008[6]),
      ComFuc.ComControl("level_tt_6", Vector2(80, 32), Vector2(340, 10), 255, SkinF.vipPadShow_008[7]),
      ComFuc.ComControl("level_bg_0", Vector2(130, 378), Vector2(184, 49), 255, SkinF.vipPadShow_006[1]),
      ComFuc.ComControl("level_bg_1", Vector2(130, 378), Vector2(448, 49), 255, SkinF.vipPadShow_006[1]),
      ComFuc.ComControl("level_bg_2", Vector2(130, 378), Vector2(580, 49), 255, SkinF.vipPadShow_006[1]),
      ComFuc.ComControl("level_bg_3", Vector2(130, 378), Vector2(712, 49), 255, SkinF.vipPadShow_006[1]),
      ComFuc.ComControl("level_bg_4", Vector2(130, 378), Vector2(844, 49), 255, SkinF.vipPadShow_006[1]),
      ComFuc.ComControl("level_bg_5", Vector2(130, 378), Vector2(976, 49), 255, SkinF.vipPadShow_006[1]),
      ComFuc.ComControl("level_bg_6", Vector2(130, 378), Vector2(316, 49), 255, SkinF.vipPadShow_006[1]),
      ComFuc.ComControl("tab_pad_son", Vector2(1116, 436), Vector2(0, 0), 255, SkinF.vipPadShow_007),
      BaseLine(1),
      BaseLine(2),
      BaseLine(3),
      BaseLine(4),
      BaseLine(5),
      BaseLine(6),
      BaseLine(7),
      BaseLine(8),
      BaseLine(9)
    })
  }),
  ComFuc.ComButton("try_use", GetUTF8Text("button_store_VIP_temp_button_02"), Vector2(120, 44), Vector2(329, 96), 18, false, true),
  ComFuc.ComControl("main_vip_icon", Vector2(55, 31), Vector2(475, 0), 255, SkinF.vipPadShow_002)
})

function ShowBaseLine(data)
  tryUseTime = data.trialVipTime
  ComFuc.isTrialedVip = true
  for i, v in ipairs(data.vipList) do
    if v.vipLevel == "0" then
      DealOneColumn(1, v)
    elseif v.vipLevel == "1" then
      DealOneColumn(2, v)
    elseif v.vipLevel == "2" then
      DealOneColumn(3, v)
    elseif v.vipLevel == "3" then
      DealOneColumn(4, v)
    elseif v.vipLevel == "4" then
      DealOneColumn(5, v)
    elseif v.vipLevel == "5" then
      DealOneColumn(6, v)
    elseif v.vipLevel == "-1" then
      DealOneColumn(7, v)
      ComFuc.isTrialedVip = false
    end
  end
end

function Show(n)
  vipLv = n
  ComFuc.VIPLevel = n
  rpc.safecall("sys_vip_list", nil, ShowBaseLine)
  InitData(n)
  ui.coverControl2.Parent = gui
  ui.main.Parent = gui
end

function Hide()
  ui.coverControl2.Parent = nil
  ui.main.Parent = nil
end
