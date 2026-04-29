module("AHBid", package.seeall)
local _T = Tip._T
local _L = Tip._L
local _LL = Tip._LL
local _Value = Tip._Value
local _M = Tip._M
local format = string.format
local white = Tip.white
local brown = Tip.brown
local callback
local fl_bid = Gui.FlowLayout({
  Dock = "kDockFill",
  Align = "kAlignCenterMiddle"
})()
local ctrl_bid = Gui.Control({
  Size = Vector2(330, 230),
  BackgroundColor = white,
  Skin = SkinF.personalInfo_206
})(fl_bid, nil)
local title_ui = {}
Tip.CreateTitle(ctrl_bid, title_ui, _T("button_common_Auction"))

function title_ui.btn.EventClick(sender, e)
  Hide()
end

Gui.Label({
  Location = Vector2(10, 39),
  Size = Vector2(310, 24),
  FontSize = 16,
  TextAlign = "kAlignCenterMiddle",
  TextColor = brown,
  Text = _T("msgbox_store_AH_002")
})(ctrl_bid, nil)
local txb_bid = Gui.Textbox({
  Location = Vector2(70, 66),
  Size = Vector2(190, 34),
  Number = true,
  MaxLength = 9,
  FontSize = 16,
  CONTROL_BALLOON_FRAME_DURATION = 1
})(ctrl_bid, nil)
Gui.Label({
  Location = Vector2(261, 67),
  Size = Vector2(30, 30),
  Icon = IconsF.TkIcon
})(ctrl_bid, nil)
local btn_bid = Gui.Button({
  Location = Vector2(115, 112),
  Size = Vector2(100, 34),
  Text = _T("button_common_Auction")
})(ctrl_bid, nil)
Gui.Label({
  Location = Vector2(10, 160),
  Size = Vector2(310, 48),
  FontSize = 16,
  TextColor = brown,
  Text = _T("msgbox_store_AH_001")
})(ctrl_bid, nil)

function txb_bid.EventTextChanged(sender, e)
  sender:CancelBalloon()
end

local bid_item, Bid = nil, ctrl_bid

function Bid()
  local bid_price = tonumber(txb_bid.Text)
  if not bid_price then
    txb_bid:Balloon(_T("UI_common_Enter_bid"))
    txb_bid.Focused = true
    return
  end
  if not bid_item.fixedPrice or bid_price < bid_item.fixedPrice then
    MessageBox.ShowWithConfirmCancel(_M(format("msgbox_store_AH_005,%s,%d,%s", txb_bid.Text, bid_item.quantity, _LL(bid_item.display)), bid_item.type == 5 and bit.bshift(1, 3) or 0), function()
      rpc.safecall("auction_bid", {
        aid = bid_item.aid,
        price = tonumber(txb_bid.Text)
      }, function(data)
        MessageBox.ShowError(_M(format("msgbox_store_AH_006,%d,%s", bid_item.quantity, _LL(bid_item.display)), bid_item.type == 5 and bit.bshift(1, 3) or 0))
        Hide()
      end, function()
        Hide()
      end)
    end)
  else
    rpc.safecall("auction_buy", {
      aid = bid_item.aid,
      t = bid_item.type
    }, function(data)
      MessageBox.ShowError(_T("msgbox_store_AH_009"))
      Hide()
    end, function()
      Hide()
    end)
  end
end

function btn_bid.EventClick(sender, e)
  Bid()
end

function Show(item, cb)
  callback = cb
  bid_item = item
  txb_bid.Text = math.ceil(item.minBidPrice)
  fl_bid.Parent = gui
  txb_bid.Focused = true
end

function Hide()
  if callback then
    callback()
  end
  fl_bid.Parent = nil
end
