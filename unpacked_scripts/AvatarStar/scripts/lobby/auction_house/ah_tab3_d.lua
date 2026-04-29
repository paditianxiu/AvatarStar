module("AHTab3", package.seeall)
local _T = Tip._T
local _Value = Tip._Value
local _Key = Tip._Key
local _L = Tip._L
local _M = Tip._M
local format = string.format
local white = Tip.white
local black = Tip.black
local brown = Tip.brown
local GetIcon = Tip.GetIcon
local GetGradeImage = Tip.GetGradeImage
local GetCurrencyText = Tip.GetCurrencyText
local GetCurrencyKey = Tip.GetCurrencyKey
local GetBigCurrencyIcon = Tip.GetBigCurrencyIcon
local GetLeftTime = AHTab0.GetLeftTime
local tip_player_interface = AHTab0.tip_player_interface
local list_data
local gp_to_tk = 0
local tk_to_gp = 0
local max_currency = 0
local ctrl_currency = Gui.Control({
  Location = Vector2(0, 40),
  Size = Vector2(1128, 645)
})()
local ctrl_top = Gui.Control({
  Location = Vector2(20, 15),
  Size = Vector2(1088, 41),
  BackgroundColor = white,
  Skin = SkinF.shop_12
})(ctrl_currency, nil)
local btn_browse = Gui.Button({
  Location = Vector2(2, 0),
  Size = Vector2(120, 40),
  Text = _T("UI_store_AH_mainUI_blank_30")
})(ctrl_top, nil)
local lb_left = Gui.Label({
  Location = Vector2(527, 9),
  Size = Vector2(380, 24),
  FontSize = 16,
  TextColor = brown,
  TextAlign = "kAlignRightMiddle"
})(ctrl_top, nil)
local prop = Gui.ProportionBar({
  Location = Vector2(913, 14),
  Size = Vector2(159, 17),
  DrawValueText = true,
  Icon = SkinF.auction_05
})(ctrl_top, nil)
local ctrl_left = Gui.Control({
  Location = Vector2(20, 67),
  Size = Vector2(365, 563),
  BackgroundColor = white,
  Skin = SkinF.personalInfo_206
})(ctrl_currency, nil)

function Title(p, t)
  return Gui.Label({
    Dock = "kDockTop",
    Size = Vector2(0, 30),
    TextPadding = Vector4(10, 0, 0, 0),
    FontSize = 16,
    Text = t
  })(p, nil)
end

Title(ctrl_left, _T("UI_store_AH_mainUI_blank_31"))
local ctrl_sell = Gui.Control({
  Location = Vector2(14, 40),
  Size = Vector2(340, 516),
  BackgroundColor = white,
  Skin = SkinF.personalInfo_131
})(ctrl_left, nil)
local cb = Gui.CartBox({
  Location = Vector2(141, 24),
  Size = Vector2(80, 80),
  Skin = SkinF.auction_07,
  GradeImage = GetGradeImage(1),
  Icon = IconsF.BigGpIcon
})(ctrl_sell, nil)
cb.Skin = nil
cb.BackgroundColor = ARGB(0, 0, 0, 0)
local ctrl_price = Gui.Control({
  Location = Vector2(15, 123),
  Size = Vector2(310, 178),
  BackgroundColor = white,
  Skin = SkinF.openBox_002
})(ctrl_sell, nil)
Gui.Label({
  Location = Vector2(8, 26),
  Size = Vector2(80, 26),
  FontSize = 16,
  TextColor = brown,
  TextAlign = "kAlignRightMiddle",
  Text = _T("UI_store_AH_mainUI_blank_39")
})(ctrl_price, nil)
local txb_count = Gui.Textbox({
  Location = Vector2(96, 21),
  Size = Vector2(156, 34),
  Number = true,
  MaxLength = 9,
  FontSize = 16,
  CONTROL_BALLOON_FRAME_DURATION = 1
})(ctrl_price, nil)
local lb_count_icon = Gui.Label({
  Location = Vector2(255, 26),
  Size = Vector2(30, 30),
  Icon = IconsF.GpIcon
})(ctrl_price, nil)
Gui.Label({
  Location = Vector2(8, 65),
  Size = Vector2(80, 26),
  FontSize = 16,
  TextColor = brown,
  TextAlign = "kAlignRightMiddle",
  Text = _T("UI_store_AH_mainUI_blank_44")
})(ctrl_price, nil)
local txb_price = Gui.Textbox({
  Location = Vector2(96, 60),
  Size = Vector2(156, 34),
  Number = true,
  MaxLength = 9,
  FontSize = 16,
  CONTROL_BALLOON_FRAME_DURATION = 1
})(ctrl_price, nil)
local lb_price_icon = Gui.Label({
  Location = Vector2(254, 62),
  Size = Vector2(30, 30),
  Icon = IconsF.TkIcon
})(ctrl_price, nil)
Gui.Label({
  Location = Vector2(8, 103),
  Size = Vector2(80, 26),
  FontSize = 16,
  TextColor = brown,
  TextAlign = "kAlignRightMiddle",
  Text = _T("UI_store_mainUI_blank_49")
})(ctrl_price, nil)
local cmb_time = Gui.ComboBox({
  Location = Vector2(96, 97),
  Size = Vector2(190, 34)
})(ctrl_price, nil)
cmb_time:AddItem(_T("UI_store_mainUI_blank_52"))
cmb_time:AddItem(_T("UI_store_mainUI_blank_53"))
cmb_time.SelectedIndex = 0
Gui.Label({
  Location = Vector2(8, 138),
  Size = Vector2(80, 26),
  FontSize = 16,
  TextColor = brown,
  TextAlign = "kAlignRightMiddle",
  Text = _T("UI_store_AH_mainUI_blank_28")
})(ctrl_price, nil)
local lb_tax = Gui.Label({
  Location = Vector2(96, 138),
  Size = Vector2(152, 26),
  FontSize = 16,
  TextColor = brown,
  TextAlign = "kAlignRightMiddle"
})(ctrl_price, nil)
local lb_tax_icon = Gui.Label({
  Location = Vector2(255, 138),
  Size = Vector2(30, 30),
  Icon = IconsF.TkIcon
})(ctrl_price, nil)
local btn_reset = Gui.Button({
  Location = Vector2(30, 318),
  Size = Vector2(120, 44),
  Text = _T("UI_store_mainUI_blank_50")
})(ctrl_sell, nil)
local btn_sell = Gui.Button({
  Location = Vector2(190, 318),
  Size = Vector2(120, 44),
  Text = _T("UI_store_AH_mainUI_blank_31")
})(ctrl_sell, nil)
Gui.Label({
  Location = Vector2(18, 427),
  Size = Vector2(310, 24),
  FontSize = 16,
  TextColor = brown,
  Text = _T("UI_store_average_prece")
})(ctrl_sell, nil)
local ctrl_average = Gui.Control({
  Location = Vector2(15, 454),
  Size = Vector2(310, 38),
  BackgroundColor = white,
  Skin = SkinF.levelUpTipShow_002
})(ctrl_sell, nil)
local lb_mb_average = Gui.Label({
  Location = Vector2(12, 8),
  Size = Vector2(255, 26),
  FontSize = 16
})(ctrl_average, nil)
Gui.Label({
  Location = Vector2(275, 5),
  Size = Vector2(30, 30),
  Icon = IconsF.TkIcon
})(ctrl_average, nil)
local header_text = {
  {
    290,
    _T("UI_store_mainUI_blank_51")
  },
  {
    140,
    _T("UI_store_AH_mainUI_blank_44")
  },
  {
    160,
    _T("UI_store_AH_mainUI_blank_17")
  },
  {
    120,
    _T("UI_store_AH_mainUI_blank_09")
  }
}
local fl_list = Gui.FlowLayout({
  Location = Vector2(394, 67),
  Size = Vector2(710, 495),
  LineSpace = 4
})(ctrl_currency, nil)

function CreateHeader(p, text)
  local ah = Gui.AuctionHeader({
    SortIndex = 0,
    Size = Vector2(0, 31),
    Dock = "kDockTop",
    Margin = Vector4(0, 0, 0, 5),
    TextColor = white,
    FontSize = 16,
    TextShadowColor = ARGB(150, 0, 0, 0)
  })(p, nil)
  for _, vv in ipairs(text) do
    ah:AddItem(vv[1], vv[2])
  end
  return ah
end

local ah = CreateHeader(fl_list, header_text)
local item_list, CreateItem = {}, header_text

function CreateItem(p, ui, text)
  for i = 1, 8 do
    local at = Gui.AuctionItem({
      Size = Vector2(710, 54),
      TextColor = brown
    })(p, ui)
    for _, vv in ipairs(text) do
      at:SetIconRect(7, 7, 40, 40)
      at:AddItem(vv[1])
    end
  end
end

CreateItem(fl_list, item_list, header_text)
local pg = Gui.NewPagesBar({
  Location = Vector2(398, 587),
  Size = Vector2(260, 36)
})(ctrl_currency, nil)
local btn_update = Gui.Button({
  Location = Vector2(857, 575),
  Size = Vector2(120, 54),
  Text = _T("button_store_refresh_AH"),
  Skin = SkinF.select_character_038
})(ctrl_currency, nil)
local btn_buy = Gui.Button({
  Location = Vector2(983, 575),
  Size = Vector2(120, 54),
  Text = _T("UI_store_AH_mainUI_blank_32"),
  Skin = SkinF.select_character_038
})(ctrl_currency, nil)
local tax_rt, UpdateTax = {
  {1.25, 0.05},
  {1.5, 0.3},
  {1.6, 0.4},
  {1.7, 0.5},
  {0, 0.95}
}, {1.25, 0.05}

function UpdateTax()
  local count = tonumber(txb_count.Text) or 0
  local A = tonumber(txb_price.Text)
  local B = count * gp_to_tk / 10000
  if count and A then
    local num = {
      B * 1.05 * 0.05,
      B * 0.050000000000000044 * 0.2,
      B * 0.09999999999999987 * 0.4,
      B * 0.15000000000000013 * 0.5,
      B * 0.19999999999999996 * 0.6,
      B * 0.25 * 0.7
    }
    local tax = 0
    local clrText = ARGB(255, 152, 37, 10)
    if A < B * 1.05 then
      tax = A * 0.05
      clrText = brown
    end
    if A >= B * 1.05 and A < B * 1.1 then
      tax = (A - B * 1.05) * 0.2 + num[1]
    end
    if A >= B * 1.1 and A < B * 1.2 then
      tax = (A - B * 1.1) * 0.4 + num[2] + num[1]
    end
    if A >= B * 1.2 and A < B * 1.35 then
      tax = (A - B * 1.2) * 0.5 + num[3] + num[2] + num[1]
    end
    if A >= B * 1.35 and A < B * 1.55 then
      tax = (A - B * 1.35) * 0.6 + num[4] + num[3] + num[2] + num[1]
    end
    if A >= B * 1.55 and A < B * 1.8 then
      tax = (A - B * 1.55) * 0.7 + num[5] + num[4] + num[3] + num[2] + num[1]
    end
    if A >= B * 1.8 and A < B * 2.1 then
      tax = (A - B * 1.8) * 0.8 + num[6] + num[5] + num[4] + num[3] + num[2] + num[1]
    end
    if A >= B * 2.1 then
      tax = (A - B * 2.1) * 0.95 + B * 0.30000000000000004 * 0.8 + num[6] + num[5] + num[4] + num[3] + num[2] + num[1]
    end
    A = math.max(A, 0.001)
    lb_tax.TextColor = clrText
    lb_tax.Text = string.format("%d", math.max(1, math.floor(tax))) .. "(" .. tostring(math.floor(tax * 100 / A)) .. "%" .. ")"
  else
    lb_tax.Text = ""
  end
end

local order_field, GetListArgs = {
  "QUANTITY",
  "PRICE",
  "AUCTIONEER_NAME",
  "EXPIRE_TIME"
}, "QUANTITY"
local GetListArgs, GetItemCurrencyText = function()
  local args = {}
  args.p = pg.CurrIndex
  args.s = 8
  args.order = ah.SortUp and -1 or 1
  args.orderField = order_field[ah.SortIndex + 1]
  args.currency = 1
  return args
end, "PRICE"
local GetItemCurrencyText, GetItemCurrencyKey = function(c)
  return c == 1 and GetCurrencyText(4) or GetCurrencyText(1)
end, "AUCTIONEER_NAME"

function GetItemCurrencyKey(c)
  return c == 1 and GetCurrencyKey(4) or GetCurrencyKey(1)
end

local RequestList
local timer = Tip.CreateTimer(function()
  if ptr_cast(game.CurrentState, "Client.StateLobby") and AHMain.Active() then
    RequestList()
  end
end)

function RequestList()
  timer.Start()
  rpc.safecall("auction_currency_list", GetListArgs(), function(data)
    if list_data and list_data.sel then
      item_list[list_data.sel].Selected = false
    end
    list_data = data
    lb_left.Text = _T("UI_store_AH_mainUI_blank_41")
    prop.MaxValue = data.maxCount
    prop.CurrentValue = data.maxCount - data.onSell
    lb_mb_average.Text = _Value(_T("UI_store_AH_mainUI_blank_36"), {
      data.gpToTk
    })
    gp_to_tk = data.gpToTk
    tk_to_gp = data.tkToGp
    max_currency = data.maxCurrency
    pg.PageCount = data.pages
    pg.CurrIndex = data.page
    for i, v in ipairs(item_list) do
      local item = data.items[i]
      if item then
        v.Icon = GetBigCurrencyIcon(item.currency)
        v:SetItemText(0, item.quantity, brown)
        local rp = _Value(_T("UI_store_AH_price"), {
          item.reservePrice
        })
        rp = _Key(rp, {
          GetItemCurrencyText(item.currency)
        })
        v:SetItemText(1, rp, brown)
        v:SetItemText(2, item.auctioneerName, brown)
        v:SetItemText(3, GetLeftTime(item.leftTime), brown)
        v.Ready = true
      else
        v.Ready = false
      end
    end
  end)
end

function btn_browse.EventClick(sender, e)
  require("ah_self_currency.lua")
  timer.Stop()
  AHSelfCurrency.Show(RequestList)
end

function txb_count.EventTextChanged(sender, e)
  if txb_count.Text and string.len(txb_count.Text) > 0 and max_currency ~= 0 and tonumber(txb_count.Text) > max_currency then
    txb_count.Text = tostring(max_currency)
    MessageBox.ShowError(GetMatchedUTF8Text("UI_lobby_gold_sale_overflow," .. max_currency))
  else
    sender:CancelBalloon()
    UpdateTax()
  end
end

function txb_price.EventTextChanged(sender, e)
  sender:CancelBalloon()
  UpdateTax()
end

local btn_update.EventClick, CheckSellArgs = function(sender, e)
  RequestList()
end, function(sender, e)
  RequestList()
end
local CheckSellArgs, GetSellArgs = function()
  if not tonumber(txb_count.Text) then
    txb_count:Balloon(_T("msgbox_common_conditionkey_197"))
    txb_count.Focused = true
    return false
  end
  if not tonumber(txb_price.Text) then
    txb_price:Balloon(_T("msgbox_store_AH_002"))
    txb_price.Focused = true
    return false
  end
  return true
end, _T("UI_store_AH_mainUI_blank_09")

function GetSellArgs()
  local args = {}
  args.currency = 1
  args.quantity = txb_count.Text
  args.duration = cmb_time.SelectedIndex + 1
  args.reservePrice = txb_price.Text
  return args
end

local btn_sell.EventClick, Reset = function(sender, e)
  if CheckSellArgs() then
    local args = GetSellArgs()
    MessageBox.ShowWithConfirmCancel(_M(format("msgbox_store_AH_026,%d,%s,%s,%s", args.quantity, GetCurrencyKey(args.currency), lb_tax.Text, GetItemCurrencyKey(args.currency))), function()
      rpc.safecall("auction_currency_start", args, function(data)
        MessageBox.ShowError(_T("msgbox_store_AH_027"))
        RequestList()
      end)
    end)
  end
end, function(sender, e)
  if CheckSellArgs() then
    local args = GetSellArgs()
    MessageBox.ShowWithConfirmCancel(_M(format("msgbox_store_AH_026,%d,%s,%s,%s", args.quantity, GetCurrencyKey(args.currency), lb_tax.Text, GetItemCurrencyKey(args.currency))), function()
      rpc.safecall("auction_currency_start", args, function(data)
        MessageBox.ShowError(_T("msgbox_store_AH_027"))
        RequestList()
      end)
    end)
  end
end

function Reset()
  txb_count.Text = ""
  txb_price.Text = ""
  cmb_time.SelectedIndex = 0
  lb_tax.Text = ""
end

local btn_reset.EventClick, Buy = function(sender, e)
  Reset()
end, function(sender, e)
  Reset()
end

function Buy()
  if list_data and list_data.sel then
    local item = list_data.items[list_data.sel]
    timer.Stop()
    MessageBox.ShowWithConfirmCancel(_M(format("msgbox_store_AH_030,%d,%s,%d,%s", item.reservePrice, GetItemCurrencyKey(item.currency), item.quantity, GetCurrencyKey(item.currency))), function()
      rpc.safecall("auction_buy", {
        aid = item.aid,
        t = 7
      }, function(data)
        MessageBox.ShowError(_M(format("msgbox_store_AH_012,%d,%s", item.quantity, GetCurrencyKey(item.currency))))
        RequestList()
      end)
    end, function()
      timer.Start()
    end)
  else
    MessageBox.ShowError(_T("msgbox_common_num_1348"))
  end
end

function btn_buy.EventClick(sender, e)
  Buy()
end

for i, v in ipairs(item_list) do
  function v.EventClick(sender, e)
    if sender.Ready then
      sender.Selected = true
      
      list_data.sel = i
      local item = list_data.items[i]
      for ii, vv in ipairs(item_list) do
        if vv.Ready and vv.Selected and ii ~= i then
          vv.Selected = false
        end
      end
    end
  end
end

function pg.EventIndexChanged(sender, e)
  RequestList()
end

function ah.EventSortChanged(sender, e)
  RequestList()
end

function Show(p)
  ctrl_currency.Parent = p
  RequestList()
end

function Hide()
  ctrl_currency.Parent = nil
  timer.Stop()
end
