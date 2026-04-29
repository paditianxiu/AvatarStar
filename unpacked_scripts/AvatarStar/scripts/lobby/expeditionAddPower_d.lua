module("ExpeditionAddPower", package.seeall)
local cols = ComFuc.cols
local dtDetail
ui = Gui.Create()({
  Gui.Control("insertTip_m")({
    Dock = "kDockFill",
    ComFuc.ComControl(nil, Vector2(322, 96), Vector2(12, 0), 255, SkinF.battle_005),
    ComFuc.ComButton("insertTip_sure", GetUTF8Text("button_lobby_restore_immediately"), Vector2(104, 44), Vector2(22, 102)),
    ComFuc.ComButton("insertTip_buy", GetUTF8Text("button_common_Buy"), Vector2(84, 44), Vector2(143, 102)),
    ComFuc.ComButton("insertTip_canc", GetUTF8Text("button_common_Cancel"), Vector2(84, 44), Vector2(244, 102)),
    ComFuc.ComLabel("insertTip_text", GetUTF8Text("msgbox_common_explore_msgbox_01"), Vector2(270, 80), Vector2(40, 8), 0, 16, cols, "kAlignCenterMiddle")
  }),
  ComFuc.PopControl("insertTip", Vector2(346, 206), GetUTF8Text("UI_avatar_avatar_UI_06"), 40, 1),
  ComFuc.ComControl("coverControl2", Vector2(1600, 1200), Vector2(0, 0), 0)
})
ui.insertTip_text.AutoWrap = true
local ui.insertTip_m.Parent, DealExpeditionDetail = ui.insertTip_son, ui.insertTip_m

function DealExpeditionDetail(data)
  Expedition.dtDetail = data
  ui.insertTip_sure.Enable = data.ownNum >= data.needNum and data.fitnessValue ~= data.fitnessMaxValue
  if data.fitnessMaxValue == 0 then
    data.fitnessMaxValue = 1
  end
  ExpBar.SetExpBar(Expedition.ui.bar_power, Expedition.ui.bar_power_c, Expedition.ui.bar_power_l, data.fitnessValue, data.fitnessMaxValue)
  ComFuc.globalFV = data.fitnessValue
end

function ui.insertTip_cha.EventClick(sender, e)
  Hide()
end

function ui.insertTip_sure.EventClick(sender, e)
  Hide()
  rpc.safecall("use_venture_property", {}, function(data)
    Expedition.RpcPlayerVentureDetail()
  end)
end

function ui.insertTip_buy.EventClick(sender, e)
  if not QuickBuy then
    require("shop/quick_buy.lua")
  end
  if dtDetail then
    QuickBuy.Show({
      t = dtDetail.type,
      st = dtDetail.subType,
      category = dtDetail.category
    })
    
    function QuickBuy.callback()
      rpc.safecall("player_venture_detail", {}, DealExpeditionDetail)
    end
    
    QuickBuy.call_back_failed = Hide
  end
end

function ui.insertTip_canc.EventClick(sender, e)
  Hide()
end

function Show(data)
  rpc.safecall("player_venture_detail", {}, DealExpeditionDetail)
  dtDetail = data
  if dtDetail then
    ui.insertTip_sure.Enable = dtDetail.ownNum >= dtDetail.needNum and data.fitnessValue ~= data.fitnessMaxValue
    ui.insertTip_text.Text = GetMatchedUTF8Text(GetUTF8Text("msgbox_common_explore_msgbox_01") .. "," .. dtDetail.needNum .. "," .. GetUTF8Text(dtDetail.displayName))
  end
  ui.coverControl2.Parent = gui
  ui.insertTip.Parent = gui
  Gui.Align(ui.insertTip, 0.5, 0.5)
end

function Hide()
  ui.coverControl2.Parent = nil
  ui.insertTip.Parent = nil
end
