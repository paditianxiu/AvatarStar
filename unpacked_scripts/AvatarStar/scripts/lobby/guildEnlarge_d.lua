module("GuildEnlarge", package.seeall)
local col0 = ComFuc.col0
local colw = ComFuc.colw
local colt = ComFuc.colt
local enlargeInfo, ComCoinItem = {}, nil

function ComCoinItem(i)
  return Gui.Control("coin_" .. i)({
    Size = Vector2(150, 31),
    Location = Vector2(104, 9 + 36 * i),
    ComFuc.ComLabel("cost_" .. i, "0 ", Vector2(122, 31), Vector2(28, 0), 255, 16, coly, "kAlignRightMiddle", SkinF.avatar_main_086),
    ComFuc.ComControl("icon_" .. i, Vector2(30, 30), Vector2(32, 1), 255, SkinF.avatar_main_088[i]),
    ComFuc.ComCheckBox("check_" .. i, nil, Vector2(24, 24), Vector2(0, 4), 0, nil, "Gui.CheckBox_01")
  })
end

local ui = Gui.Create()({
  ComFuc.ComControl("coverControl2", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(100, 0, 0, 0)),
  Gui.Control("main")({
    Size = Vector2(390, 401),
    Dock = "kDockCenter",
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_207,
    Gui.Control({
      Size = Vector2(390, 40),
      ComFuc.ComLabel(nil, "  " .. GetUTF8Text("UI_common_consortia_leaguer_01"), Vector2(382, 21), Vector2(4, 4), 0, 16, colw),
      ComFuc.ComButton("close", nil, Vector2(24, 24), Vector2(358, 4), 0, false, false, SkinF.lookInfo_002)
    }),
    Gui.Control({
      Size = Vector2(366, 138),
      Location = Vector2(12, 40),
      BackgroundColor = colw,
      Skin = SkinF.battle_005,
      ComFuc.ComLabel("label_1", GetUTF8Text("UI_common_online_03"), Vector2(266, 36), Vector2(18, 13), 0, 16, colt, "kAlignLeftMiddle"),
      ComFuc.ComLabel("label_2", GetUTF8Text("UI_common_consortia_leaguer_02"), Vector2(266, 36), Vector2(18, 50), 0, 16, colt, "kAlignLeftMiddle"),
      ComFuc.ComLabel("label_3", GetUTF8Text("UI_common_consortia_leaguer_03"), Vector2(266, 36), Vector2(18, 86), 0, 16, colt, "kAlignLeftMiddle"),
      ComFuc.ComLabel("text_1", nil, Vector2(330, 36), Vector2(18, 13), 0, 16, colt, "kAlignRightMiddle"),
      ComFuc.ComLabel("text_2", nil, Vector2(330, 36), Vector2(18, 50), 0, 16, colt, "kAlignRightMiddle"),
      ComFuc.ComLabel("text_3", nil, Vector2(330, 36), Vector2(18, 86), 0, 16, colt, "kAlignRightMiddle")
    }),
    Gui.Control("coin_content")({
      Size = Vector2(366, 138),
      Location = Vector2(12, 182),
      BackgroundColor = colw,
      Skin = SkinF.battle_005,
      ComFuc.ComLabel(nil, GetUTF8Text("UI_common_consortia_leaguer_04"), Vector2(330, 24), Vector2(18, 12), 0, 16, colt),
      ComCoinItem(1),
      ComCoinItem(2),
      ComCoinItem(3),
      ComCoinItem(4)
    }),
    ComFuc.ComButton("btn_enlarge", GetUTF8Text("UI_common_consortia_leaguer_01"), Vector2(140, 53), Vector2(125, 325), 16, false, true, SkinF.select_character_038)
  })
})
ui.label_1.AutoWrap = true
ui.label_2.AutoWrap = true
ui.label_3.AutoWrap = true
for i = 1, 4 do
  ui["check_" .. i].EventCheckChanged = function(sender, e)
    if "kTriggerMouse" == e.Trigger then
      for k = 1, 4 do
        ui["check_" .. k].Check = i == k
      end
    end
  end
end

function ui.btn_enlarge.EventClick()
  local t = 1
  for i = 1, 4 do
    if ui["check_" .. i].Check then
      t = i
      break
    end
  end
  rpc.safecall("guild_member_expansion", {
    guildId = enlargeInfo.id,
    currency = enlargeInfo[t]
  }, function(data)
    Guild.RpcCallGuildShow()
    Hide()
  end)
end

function ui.close.EventClick()
  Hide()
end

function Show(info)
  rpc.safecall("guild_member_expansion_detail", {
    guildId = info[3]
  }, function(data)
    enlargeInfo = {}
    enlargeInfo.id = info[3]
    local dataList = data.list
    ui.text_1.Text = info[1] .. "/" .. info[2]
    ui.text_2.Text = info[2]
    if dataList and dataList[1] and dataList[1].memberNum then
      ui.text_3.Text = dataList[1].memberNum
      ui.label_3.Text = GetUTF8Text("UI_common_consortia_leaguer_03")
    else
      ui.text_3.Text = ""
      ui.label_3.Text = GetUTF8Text("msgbox_common_backpack_02")
    end
    if dataList then
      for i = 1, 4 do
        local v = dataList[i]
        ui["coin_" .. i].Visible = v
        if v then
          enlargeInfo[i] = v.currency
          ui["cost_" .. i].Text = v.price .. " "
          ui["icon_" .. i].Skin = SkinF.avatar_main_088[v.currency]
        end
        ui["check_" .. i].Check = i == 1
      end
    end
    local t = math.max(0, #dataList)
    if t ~= 0 then
      ui.main.Size = Vector2(390, 329 + 36 * t)
      ui.coin_content.Size = Vector2(366, 66 + 36 * t)
      ui.btn_enlarge.Location = Vector2(125, 253 + 36 * t)
    else
      ui.main.Size = Vector2(390, 200)
      ui.coin_content.Size = Vector2(0, 0)
    end
    ui.coverControl2.Parent = gui
    ui.main.Parent = gui
  end)
end

function Hide()
  ui.coverControl2.Parent = nil
  ui.main.Parent = nil
end
