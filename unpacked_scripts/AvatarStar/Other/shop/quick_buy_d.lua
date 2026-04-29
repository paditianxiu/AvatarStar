module("QuickBuy", package.seeall)
local _T = GetUTF8Text
local _L = GetUTF8Text
local white = Tip.white
local brown = Tip.brown
local yellow = Tip.yellow
local GetIcon = Tip.GetIcon
local GetGradeImage = Tip.GetGradeImage
local GetPriceId = ShopBalance.GetPriceId
local GetCurrencyText = Tip.GetCurrencyText
local GetCurrencyIcon = Tip.GetCurrencyIcon
local SortPrice = Tip.SortPrice
local GetPrice = Tip.GetPrice
local fl_buy = Gui.FlowLayout({
  Dock = "kDockFill",
  Align = "kAlignCenterMiddle",
  BackgroundColor = ARGB(128, 0, 0, 0)
})()
local ctrl_buy = Gui.Control({
  Size = Vector2(407, 332),
  BackgroundColor = white,
  Skin = SkinF.personalInfo_207
})(fl_buy)
local title_ui = {}
Tip.CreateTitle(ctrl_buy, title_ui, _T("button_common_Buy"))
local bb = Gui.BuyBox({
  Style = "BuyBox_01",
  State = "kBSBalance",
  CanCancel = false,
  Location = Vector2(18, 44)
})(ctrl_buy, nil)
local ctrl_info = Gui.Control({
  Location = Vector2(18, 180),
  Size = Vector2(371, 97),
  BackgroundColor = white,
  Skin = SkinF.personalInfo_208
})(ctrl_buy, nil)
local fl_money, money_ui, my_money_ui = ShopBalance.CreateMoneyUI({2, 4})
fl_money.Parent = ctrl_info
fl_money.Location = Vector2(11, 17)
local btn_buy = Gui.Button({
  Style = "ButtonShopBuy",
  Location = Vector2(215, 281),
  Size = Vector2(84, 40),
  Text = _T("button_common_Buy")
})(ctrl_buy, nil)
local btn_cancel = Gui.Button({
  Location = Vector2(305, 281),
  Size = Vector2(84, 40),
  Text = _T("button_common_Cancel")
})(ctrl_buy, nil)

function title_ui.btn.EventClick(sender, e)
  Hide()
end

local item, UpdateMoney = nil, function(sender, e)
  Hide()
end

function UpdateMoney()
  local p = item.price[item.price_index]
  local c = p.currency
  for k, v in pairs(money_ui) do
    v.Text = k == c and -p.price or 0
  end
end

function bb.EventPriceChanged(sender, e)
  if item then
    item.price_index = sender.PriceIndex + 1
    UpdateMoney()
  end
end

local tip_player_interface = {
  "tip_sys_skill",
  "tip_sys_item",
  "tip_sys_item",
  "tip_sys_item",
  "tip_sys_avatar",
  "tip_sys_avatar"
}
local bb.EventTipActiveChanged, RequestShopList = function(sender, e)
  if item then
    Tip.SetRpc(tip_player_interface[item.type], {
      t = item.type,
      sid = item.sid
    })
    Tip.SetUseDescription(false)
    Tip.SetOwner(sender)
    Tip.SetOffset(Vector2(5, 33))
    Tip.SetAlignSize(Vector2(80, 80))
  end
end, function(sender, e)
  if item then
    Tip.SetRpc(tip_player_interface[item.type], {
      t = item.type,
      sid = item.sid
    })
    Tip.SetUseDescription(false)
    Tip.SetOwner(sender)
    Tip.SetOffset(Vector2(5, 33))
    Tip.SetAlignSize(Vector2(80, 80))
  end
end
local RequestShopList, RequestBuy = function(args)
  rpc.safecall("shop_item_list", args, function(data)
    item = data.items[1]
    item.price_index = 1
    item.type = data.t
    bb.Name = _L(item.display)
    bb.Icon = GetIcon(item.resource)
    bb.GradeImage = GetGradeImage(item.grade)
    bb.Desc = _L(item.description)
    bb:RemoveAllPrice()
    table.sort(item.price, SortPrice)
    for _, vv in ipairs(item.price) do
      bb:AddPrice(GetPrice(vv))
    end
    bb.PriceIndex = 0
    UpdateMoney()
    fl_buy.Parent = gui
  end)
end, "tip_sys_item"

function RequestBuy()
  if item then
    rpc.safecall("shop_buy", {
      buy = string.format("%d,%d,%d,%d;", item.type, item.subtype, item.sid, GetPriceId(item))
    }, function(data)
      Hide()
      MessageBox.ShowError(_T("msgbox_common_num_1210"))
      if Shop then
        Shop.ClearCart()
      end
    end, callbackfailed)
  end
end

function btn_buy.EventClick(sender, e)
  RequestBuy()
end

function btn_cancel.EventClick(sender, e)
  Hide()
end

function Show(args)
  args.p = 1
  args.pageSize = 1
  args.currency = "1,2,4"
  for k, v in pairs(my_money_ui) do
    v.Text = PushCmd.GetMyMoney(k)
  end
  RequestShopList(args)
end

callback = nil

function Hide()
  fl_buy.Parent = nil
  if callback then
    callback()
    callback = nil
  end
end

call_back_failed = nil

function callbackfailed()
  fl_buy.Parent = nil
  if call_back_failed then
    call_back_failed()
    call_back_failed = nil
  end
end
