module("AHExchange", package.seeall)
local _T = Tip._T
local _L = Tip._L
local _Value = Tip._Value
local white = Tip.white
local brown = Tip.brown
local fl_exchange = Gui.FlowLayout({
  Dock = "kDockFill",
  Align = "kAlignCenterMiddle"
})()
local ctrl_exchange = Gui.Control({
  Size = Vector2(400, 292),
  BackgroundColor = white,
  Skin = SkinF.personalInfo_206
})(fl_exchange, nil)
local title_ui = {}
Tip.CreateTitle(ctrl_exchange, title_ui, _T("button_store_exchange_voucher"))

function title_ui.btn.EventClick(sender, e)
  Hide()
end

local ctrl_price = Gui.Control({
  Location = Vector2(14, 42),
  Size = Vector2(372, 121),
  BackgroundColor = white,
  Skin = SkinF.openBox_002
})(ctrl_exchange, nil)
Gui.Label({
  Location = Vector2(20, 20),
  Size = Vector2(340, 26),
  FontSize = 16,
  TextColor = brown,
  Text = _T("UI_store_exchange_voucher_num")
})(ctrl_price, nil)
local txb_count = Gui.Textbox({
  Location = Vector2(89, 59),
  Size = Vector2(190, 34),
  Number = true,
  MaxLength = 9,
  FontSize = 16,
  CONTROL_BALLOON_FRAME_DURATION = 1
})(ctrl_price, nil)
Gui.Label({
  Location = Vector2(313, 61),
  Size = Vector2(30, 30),
  Icon = IconsF.TkIcon
})(ctrl_price, nil)
local lb_price = Gui.Label({
  Location = Vector2(32, 174),
  Size = Vector2(294, 45),
  FontSize = 16,
  TextColor = brown,
  TextAlign = "kAlignLeftTop"
})(ctrl_exchange, nil)
Gui.Label({
  Location = Vector2(327, 168),
  Size = Vector2(30, 30),
  Icon = IconsF.MbIcon
})(ctrl_exchange, nil)
local btn_exchange = Gui.Button({
  Location = Vector2(75, 230),
  Size = Vector2(100, 44),
  Text = _T("button_store_confirm_buy")
})(ctrl_exchange, nil)
local btn_cancle = Gui.Button({
  Location = Vector2(225, 230),
  Size = Vector2(100, 44),
  Text = _T("button_common_Cancel"),
  EventClick = function(sender, e)
    Hide()
  end
})(ctrl_exchange, nil)

function txb_count.EventTextChanged(sender, e)
  txb_count:CancelBalloon()
  lb_price.Text = _Value(_T("UI_store_CC_exchenge_voucher"), {
    1,
    1,
    sender.Text
  })
end

function btn_exchange.EventClick(sender, e)
  if not tonumber(txb_count.Text) then
    txb_count:Balloon(_T("UI_store_exchange_voucher_num"))
    txb_count.Focused = true
    return
  end
  local c = txb_count.Text
  MessageBox.ShowWithConfirmCancel(_Value(_T("msgbox_store_exchange_msgbox_02"), {c, c}), function(sender, e)
    rpc.safecall("auction_currency_exchange", {count = c}, function(data)
      MessageBox.ShowError(_T("msgbox_store_exchange_msgbox_03"))
    end)
  end)
end

local callback

function Show(cb)
  callback = cb
  fl_exchange.Parent = gui
  txb_count.Text = ""
  txb_count.Focused = true
end

function Hide()
  fl_exchange.Parent = nil
  if cb then
    cb()
  end
end
