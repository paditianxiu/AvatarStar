module("SignPresent", package.seeall)
local col0 = ComFuc.col0
local colw = ComFuc.colw
local colt = ComFuc.colt
colh = ARGB(100, 255, 255, 255)
colbl = ARGB(255, 75, 75, 75)
colv = ARGB(255, 176, 53, 2)
local getSignGoodsId = {
  0,
  0,
  0,
  0
}
local tip_interface, ComDate = {
  nil,
  "tip_sys_checkin_reward",
  "tip_sys_checkin_reward",
  "tip_sys_checkin_reward",
  "tip_sys_avatar"
}, nil
local ComDate, ComCB = function(i)
  return Gui.Control("date_" .. i)({
    Size = Vector2(35, 30),
    Location = ComFuc.ComputLocation(i, -24, 54, 7, 35, 30),
    ComFuc.ComControl("date_today_" .. i, Vector2(35, 30), Vector2(0, 0), 255, SkinF.signPresent_006),
    ComFuc.ComLabel("date_lab_" .. i, nil, Vector2(35, 30), Vector2(0, 0), 0, 14, colt, "kAlignCenterMiddle"),
    ComFuc.ComControl("date_sign_" .. i, Vector2(35, 30), Vector2(0, 0), 255, SkinF.signPresent_007)
  })
end, "tip_sys_checkin_reward"
local ComCB, ComSingBar = function(name, lc)
  return Gui.Control(name)({
    Size = Vector2(48, 48),
    Location = lc,
    ComFuc.ComControl(name .. "_lev", Vector2(48, 48), Vector2(0, 0), 255, SkinF.personalInfo_quality[1]),
    ComFuc.ComControl(name .. "_res", Vector2(48, 48), Vector2(0, 0), 255, SkinF.skin_touming),
    ComFuc.ComLabel(name .. "_count", "x99", Vector2(48, 16), Vector2(0, 32), 0, 0, colw, "kAlignRightMiddle", 0, true, SkinF.info_number_2)
  })
end, "tip_sys_checkin_reward"

function ComSingBar(i)
  return Gui.Control("bar_" .. i)({
    Size = Vector2(795, 75),
    Location = Vector2(297, 11 + 82 * i),
    BackgroundColor = colw,
    Skin = SkinF.signPresent_011[1],
    ComFuc.ComControl("bar_icon_" .. i, Vector2(74, 27), Vector2(12, 26), 255, SkinF.SkinF.signPresent_010[1]),
    ComFuc.ComButton("btn_get_" .. i, GetUTF8Text("button_store_sign_newbutton"), Vector2(100, 55), Vector2(683, 10), 14, false, false, SkinF.signPresent_012),
    ComCB("goods_" .. i .. "_1", Vector2(146, 13)),
    ComCB("goods_" .. i .. "_2", Vector2(196, 13)),
    ComCB("goods_" .. i .. "_3", Vector2(246, 13)),
    ComCB("goods_" .. i .. "_4", Vector2(296, 13)),
    ComCB("goods_" .. i .. "_5", Vector2(346, 13)),
    ComCB("goods_" .. i .. "_6", Vector2(396, 13)),
    ComCB("goods_" .. i .. "_7", Vector2(446, 13)),
    ComCB("goods_" .. i .. "_8", Vector2(496, 13)),
    ComCB("goods_" .. i .. "_9", Vector2(546, 13)),
    ComCB("goods_" .. i .. "_10", Vector2(596, 13))
  })
end

local ui = Gui.Create()({
  ComFuc.ComControl("coverControl2", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(100, 0, 0, 0)),
  Gui.Control("main")({
    Size = Vector2(1100, 600),
    Dock = "kDockCenter",
    Skin = SkinF.signPresent_008,
    BackgroundColor = colw,
    ComFuc.ComButton("close", nil, Vector2(24, 24), Vector2(1068, 22), 0, false, false, SkinF.lookInfo_002),
    Gui.Control("my_vipLev_parent")({
      Size = Vector2(268, 40),
      Location = Vector2(17, 69),
      BackgroundColor = colw,
      Skin = SkinF.skin_playgame_033,
      ComFuc.ComControl(nil, Vector2(106, 26), Vector2(12, 5), 255, SkinF.vipPadShow_003),
      ComFuc.ComControl("my_level", Vector2(26, 26), Vector2(122, 5), 255, SkinF.vipPadShow_004[1])
    }),
    Gui.Control({
      Size = Vector2(268, 300),
      Location = Vector2(17, 114),
      BackgroundColor = colw,
      Skin = SkinF.signPresent_001,
      ComFuc.ComLabel("title_month", nil, Vector2(268, 20), Vector2(0, 10), 0, 14, colw, "kAlignCenterMiddle"),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_store_Sign_in_pad_week_7"), Vector2(35, 30), Vector2(11, 53), 0, 14, colw, "kAlignCenterMiddle"),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_store_Sign_in_pad_week_1"), Vector2(35, 30), Vector2(46, 53), 0, 14, colw, "kAlignCenterMiddle"),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_store_Sign_in_pad_week_2"), Vector2(35, 30), Vector2(81, 53), 0, 14, colw, "kAlignCenterMiddle"),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_store_Sign_in_pad_week_3"), Vector2(35, 30), Vector2(116, 53), 0, 14, colw, "kAlignCenterMiddle"),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_store_Sign_in_pad_week_4"), Vector2(35, 30), Vector2(151, 53), 0, 14, colw, "kAlignCenterMiddle"),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_store_Sign_in_pad_week_5"), Vector2(35, 30), Vector2(186, 53), 0, 14, colw, "kAlignCenterMiddle"),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_store_Sign_in_pad_week_6"), Vector2(35, 30), Vector2(221, 53), 0, 14, colw, "kAlignCenterMiddle"),
      ComDate(1),
      ComDate(2),
      ComDate(3),
      ComDate(4),
      ComDate(5),
      ComDate(6),
      ComDate(7),
      ComDate(8),
      ComDate(9),
      ComDate(10),
      ComDate(11),
      ComDate(12),
      ComDate(13),
      ComDate(14),
      ComDate(15),
      ComDate(16),
      ComDate(17),
      ComDate(18),
      ComDate(19),
      ComDate(20),
      ComDate(21),
      ComDate(22),
      ComDate(23),
      ComDate(24),
      ComDate(25),
      ComDate(26),
      ComDate(27),
      ComDate(28),
      ComDate(29),
      ComDate(30),
      ComDate(31),
      ComDate(32),
      ComDate(33),
      ComDate(34),
      ComDate(35),
      ComDate(36),
      ComDate(37),
      ComDate(38),
      ComDate(39),
      ComDate(40),
      ComDate(41),
      ComDate(42)
    }),
    Gui.Control({
      Size = Vector2(268, 104),
      Location = Vector2(17, 420),
      BackgroundColor = colw,
      Skin = SkinF.skin_playgame_033,
      ComFuc.ComLabel(nil, GetUTF8Text("UI_lobby_new_sign_in_desc"), Vector2(242, 24), Vector2(14, 6), 0, 13, colt, "kAlignCenterMiddle"),
      ComCB("prize_1", Vector2(36, 38)),
      ComCB("prize_2", Vector2(86, 38)),
      ComCB("prize_3", Vector2(136, 38)),
      ComCB("prize_4", Vector2(186, 38)),
      ComCB("prize_5", Vector2(236, 38))
    }),
    ComFuc.ComBtnHasPreIcon("btn_signP", "    " .. GetUTF8Text("UI_store_Sign_in_pad_button"), Vector2(100, 48), Vector2(38, 38), Vector2(23, 529), 13, false, true, SkinF.select_character_038, SkinF.signPresent_002, 6),
    ComFuc.ComBtnHasPreIcon("btn_signVIP", "    VIP " .. GetUTF8Text("UI_store_Sign_in_pad_button"), Vector2(136, 48), Vector2(38, 38), Vector2(141, 529), 13, false, true, SkinF.select_character_038, SkinF.signPresent_002, 6),
    ComFuc.ComControl(nil, Vector2(400, 24), Vector2(297, 61), 255, SkinF.signPresent_009),
    ComSingBar(1),
    ComSingBar(2),
    ComSingBar(3),
    ComSingBar(4),
    ComSingBar(5),
    ComSingBar(6)
  })
})
ui.my_vipLev_parent.Visible = config.IsNeedVip
ui.btn_signVIP.Visible = config.IsNeedVip
local ui.close.EventClick, Clear = function()
  ui.coverControl2.Parent = nil
  ui.main.Parent = nil
end, ui.close
local Clear, DealSignDateList = function()
  getSignGoodsId = {
    0,
    0,
    0,
    0
  }
  for i = 1, 42 do
    ui["date_today_" .. i].Visible = false
    ui["date_sign_" .. i].Visible = false
    ui["date_lab_" .. i].Text = nil
    ui["date_lab_" .. i].TextColor = colt
  end
  for i = 1, 5 do
    ui["prize_" .. i].Visible = false
  end
  for i = 1, 6 do
    for j = 1, 10 do
      ui["goods_" .. i .. "_" .. j].Visible = false
    end
    ui["btn_get_" .. i].Enable = false
    ui["bar_" .. i].Skin = SkinF.signPresent_011[1]
  end
end, function()
  ui.coverControl2.Parent = nil
  ui.main.Parent = nil
end
local DealSignDateList, ClickSignBtn = function(data)
  local t = os.date("*t", data.sysItemDate)
  t = {
    t.year,
    t.month,
    t.day,
    t.wday
  }
  ui.title_month.Text = string.format(GetUTF8Text("UI_store_Sign_in_pad_year"), t[1]) .. GetUTF8Text("UI_store_Sign_in_pad_month_" .. t[2])
  ui.btn_signP.Enable = data.isCheckin == "N" and ComFuc.VIPLevel == 0
  ui.btn_signVIP.Enable = data.isCheckin == "N" and (ComFuc.VIPLevel > 0 or ComFuc.VIPLevel == -1)
  local monthDaysNor = {
    31,
    28,
    31,
    30,
    31,
    30,
    31,
    31,
    30,
    31,
    30,
    31
  }
  local monthDaysAdd = {
    31,
    29,
    31,
    30,
    31,
    30,
    31,
    31,
    30,
    31,
    30,
    31
  }
  local begin = (t[4] + 35 - t[3]) % 7 + 1
  local monthDaysCurr = 31
  if t[1] % 4 == 0 then
    monthDaysCurr = monthDaysAdd[t[2]]
  else
    monthDaysCurr = monthDaysNor[t[2]]
  end
  for i = begin, begin + monthDaysCurr - 1 do
    ui["date_lab_" .. i].Text = i + 1 - begin
    if i + 1 - begin == t[3] then
      ui["date_today_" .. i].Visible = true
      ui["date_lab_" .. i].TextColor = colw
    end
  end
  for i, v in ipairs(data.days) do
    ui["date_sign_" .. v[1] + begin - 1].Visible = true
  end
  for k, v in ipairs(data.checkins) do
    if tonumber(v.name) == 1 then
      local c = math.min(5, #v.rewards)
      for i = 1, c do
        local p = v.rewards[i]
        ui["prize_" .. i].Visible = true
        ui["prize_" .. i].Location = Vector2((268 - 50 * c) / 2 + 50 * (i - 1), 38)
        ui["prize_" .. i .. "_lev"].Skin = SkinF.personalInfo_quality[p.grade]
        ui["prize_" .. i .. "_count"].Text = nil
        if p.unitType == 3 then
          ui["prize_" .. i .. "_count"].Text = "x" .. p.unit
        end
        if p.type == 7 then
          local resName
          if p.itemId == "1" then
            resName = "skin_common_icon_gold01"
          elseif p.itemId == "2" then
            resName = "xingbi"
          elseif p.itemId == "3" then
            resName = "xunzhang"
          elseif p.itemId == "4" then
            resName = "duihuanquan"
          end
          ui["prize_" .. i .. "_res"].Skin = Gui.ControlSkin({
            BackgroundImage = Gui.Image("/ui/skinF/" .. resName .. ".tga", Vector4(0, 0, 0, 0))
          })
        elseif p.type == 5 then
          if p.subType == 1 then
            ui["prize_" .. i .. "_res"].Skin = SkinF.personalInfo_095
          elseif p.subType == 2 then
            ui["prize_" .. i .. "_res"].Skin = SkinF.personalInfo_262
          end
        else
          local res = p.resource
          if p.type == 2 and p.subType == 102 then
            local a = rpc.load_result("fuck = {" .. res .. "}")
            res = a.fuck[1]
          end
          ui["prize_" .. i .. "_res"].Skin = Gui.ControlSkin({
            BackgroundImage = Gui.Image("/ui/skinF/lobby/" .. res .. ".tga", Vector4(0, 0, 0, 0))
          })
        end
        ui["prize_" .. i .. "_res"].EventMouseEnter = function(sender, e)
          if p.type ~= 7 then
            if p.type == 5 then
              Tip.SetRpc(tip_interface[p.type], {
                t = 5,
                sid = p.itemId
              })
            else
              Tip.SetRpc(tip_interface[p.type], {
                rewardId = p.id
              })
            end
            Tip.SetUseDescription(false)
            Tip.SetOwner(sender)
          end
        end
      end
    else
      local res = string.format("ui/skinF/skin_sign_icon_day%02d.tga", tonumber(v.name))
      local i = k - 1
      ui["bar_icon_" .. i].Skin = Gui.ControlSkin({
        BackgroundImage = Gui.Image(res, Vector4(0, 0, 0, 0))
      })
      getSignGoodsId[i] = v.id
      ui["btn_get_" .. i].Enable = v.canGetReward == "Y" and v.isGetReward == "N"
      if ui["btn_get_" .. i].Enable then
        ui["bar_" .. i].Skin = SkinF.signPresent_011[2]
      else
        ui["bar_" .. i].Skin = SkinF.signPresent_011[1]
      end
      for j, p in ipairs(v.rewards) do
        ui["goods_" .. i .. "_" .. j].Visible = true
        ui["goods_" .. i .. "_" .. j .. "_lev"].Skin = SkinF.personalInfo_quality[p.grade]
        ui["goods_" .. i .. "_" .. j .. "_count"].Text = nil
        if p.unitType == 3 then
          ui["goods_" .. i .. "_" .. j .. "_count"].Text = "x" .. p.unit
        end
        if p.type == 7 then
          local resName
          if p.itemId == "1" then
            resName = "skin_common_icon_gold01"
          elseif p.itemId == "2" then
            resName = "xingbi"
          elseif p.itemId == "3" then
            resName = "xunzhang"
          elseif p.itemId == "4" then
            resName = "duihuanquan"
          end
          ui["goods_" .. i .. "_" .. j .. "_res"].Skin = Gui.ControlSkin({
            BackgroundImage = Gui.Image("/ui/skinF/" .. resName .. ".tga", Vector4(0, 0, 0, 0))
          })
        elseif p.type == 5 then
          if p.subType == 1 then
            ui["goods_" .. i .. "_" .. j .. "_res"].Skin = SkinF.personalInfo_095
          elseif p.subType == 2 then
            ui["goods_" .. i .. "_" .. j .. "_res"].Skin = SkinF.personalInfo_262
          end
        else
          local res = p.resource
          local tp = string.find(res, ",")
          if tp then
            res = string.sub(res, 2, tp - 2)
          end
          ui["goods_" .. i .. "_" .. j .. "_res"].Skin = Gui.ControlSkin({
            BackgroundImage = Gui.Image("/ui/skinF/lobby/" .. res .. ".tga", Vector4(0, 0, 0, 0))
          })
        end
        ui["goods_" .. i .. "_" .. j .. "_res"].EventMouseEnter = function(sender, e)
          if p.type ~= 7 then
            if p.type == 5 then
              Tip.SetRpc(tip_interface[p.type], {
                t = 5,
                sid = p.itemId
              })
            else
              Tip.SetRpc(tip_interface[p.type], {
                rewardId = p.id
              })
            end
            Tip.SetUseDescription(false)
            Tip.SetOwner(sender)
          end
        end
      end
    end
  end
end, Gui.Control("main")({
  Size = Vector2(1100, 600),
  Dock = "kDockCenter",
  Skin = SkinF.signPresent_008,
  BackgroundColor = colw,
  ComFuc.ComButton("close", nil, Vector2(24, 24), Vector2(1068, 22), 0, false, false, SkinF.lookInfo_002),
  Gui.Control("my_vipLev_parent")({
    Size = Vector2(268, 40),
    Location = Vector2(17, 69),
    BackgroundColor = colw,
    Skin = SkinF.skin_playgame_033,
    ComFuc.ComControl(nil, Vector2(106, 26), Vector2(12, 5), 255, SkinF.vipPadShow_003),
    ComFuc.ComControl("my_level", Vector2(26, 26), Vector2(122, 5), 255, SkinF.vipPadShow_004[1])
  }),
  Gui.Control({
    Size = Vector2(268, 300),
    Location = Vector2(17, 114),
    BackgroundColor = colw,
    Skin = SkinF.signPresent_001,
    ComFuc.ComLabel("title_month", nil, Vector2(268, 20), Vector2(0, 10), 0, 14, colw, "kAlignCenterMiddle"),
    ComFuc.ComLabel(nil, GetUTF8Text("UI_store_Sign_in_pad_week_7"), Vector2(35, 30), Vector2(11, 53), 0, 14, colw, "kAlignCenterMiddle"),
    ComFuc.ComLabel(nil, GetUTF8Text("UI_store_Sign_in_pad_week_1"), Vector2(35, 30), Vector2(46, 53), 0, 14, colw, "kAlignCenterMiddle"),
    ComFuc.ComLabel(nil, GetUTF8Text("UI_store_Sign_in_pad_week_2"), Vector2(35, 30), Vector2(81, 53), 0, 14, colw, "kAlignCenterMiddle"),
    ComFuc.ComLabel(nil, GetUTF8Text("UI_store_Sign_in_pad_week_3"), Vector2(35, 30), Vector2(116, 53), 0, 14, colw, "kAlignCenterMiddle"),
    ComFuc.ComLabel(nil, GetUTF8Text("UI_store_Sign_in_pad_week_4"), Vector2(35, 30), Vector2(151, 53), 0, 14, colw, "kAlignCenterMiddle"),
    ComFuc.ComLabel(nil, GetUTF8Text("UI_store_Sign_in_pad_week_5"), Vector2(35, 30), Vector2(186, 53), 0, 14, colw, "kAlignCenterMiddle"),
    ComFuc.ComLabel(nil, GetUTF8Text("UI_store_Sign_in_pad_week_6"), Vector2(35, 30), Vector2(221, 53), 0, 14, colw, "kAlignCenterMiddle"),
    ComDate(1),
    ComDate(2),
    ComDate(3),
    ComDate(4),
    ComDate(5),
    ComDate(6),
    ComDate(7),
    ComDate(8),
    ComDate(9),
    ComDate(10),
    ComDate(11),
    ComDate(12),
    ComDate(13),
    ComDate(14),
    ComDate(15),
    ComDate(16),
    ComDate(17),
    ComDate(18),
    ComDate(19),
    ComDate(20),
    ComDate(21),
    ComDate(22),
    ComDate(23),
    ComDate(24),
    ComDate(25),
    ComDate(26),
    ComDate(27),
    ComDate(28),
    ComDate(29),
    ComDate(30),
    ComDate(31),
    ComDate(32),
    ComDate(33),
    ComDate(34),
    ComDate(35),
    ComDate(36),
    ComDate(37),
    ComDate(38),
    ComDate(39),
    ComDate(40),
    ComDate(41),
    ComDate(42)
  }),
  Gui.Control({
    Size = Vector2(268, 104),
    Location = Vector2(17, 420),
    BackgroundColor = colw,
    Skin = SkinF.skin_playgame_033,
    ComFuc.ComLabel(nil, GetUTF8Text("UI_lobby_new_sign_in_desc"), Vector2(242, 24), Vector2(14, 6), 0, 13, colt, "kAlignCenterMiddle"),
    ComCB("prize_1", Vector2(36, 38)),
    ComCB("prize_2", Vector2(86, 38)),
    ComCB("prize_3", Vector2(136, 38)),
    ComCB("prize_4", Vector2(186, 38)),
    ComCB("prize_5", Vector2(236, 38))
  }),
  ComFuc.ComBtnHasPreIcon("btn_signP", "    " .. GetUTF8Text("UI_store_Sign_in_pad_button"), Vector2(100, 48), Vector2(38, 38), Vector2(23, 529), 13, false, true, SkinF.select_character_038, SkinF.signPresent_002, 6),
  ComFuc.ComBtnHasPreIcon("btn_signVIP", "    VIP " .. GetUTF8Text("UI_store_Sign_in_pad_button"), Vector2(136, 48), Vector2(38, 38), Vector2(141, 529), 13, false, true, SkinF.select_character_038, SkinF.signPresent_002, 6),
  ComFuc.ComControl(nil, Vector2(400, 24), Vector2(297, 61), 255, SkinF.signPresent_009),
  ComSingBar(1),
  ComSingBar(2),
  ComSingBar(3),
  ComSingBar(4),
  ComSingBar(5),
  ComSingBar(6)
})

function ClickSignBtn()
  rpc.safecall("player_checkin", {}, function(data)
    MessageBox.ShowError(GetUTF8Text("msgbox_social_sign_in_success"))
    Lobby.SetIsCheckin(true)
  end)
  rpc.safecall("sys_checkin_list", {t = 3}, DealSignDateList)
end

function ui.btn_signP.EventClick(sender, e)
  ClickSignBtn()
end

function ui.btn_signVIP.EventClick(sender, e)
  ClickSignBtn()
end

for i = 1, 6 do
  ui["btn_get_" .. i].EventClick = function(sender, e)
    rpc.safecall("player_checkin_reward", {
      checkinId = getSignGoodsId[i]
    }, function(data)
      MessageBox.ShowError(GetUTF8Text("msgbox_social_receive_success"))
    end)
    rpc.safecall("sys_checkin_list", {t = 3}, DealSignDateList)
  end
end

function Show()
  Clear()
  ui.coverControl2.Parent = gui
  ui.main.Parent = gui
  if ComFuc.VIPLevel >= 0 then
    ui.my_level.Skin = SkinF.vipPadShow_004[math.max(1, ComFuc.VIPLevel + 1)]
  else
    ui.my_level.Skin = SkinF.vipPadShow_009
  end
  rpc.safecall("sys_checkin_list", {t = 3}, DealSignDateList)
end
