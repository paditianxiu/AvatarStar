module("ShopBalance", package.seeall)
local _T = GetUTF8Text
local _L = GetUTF8Text
local white = Tip.white
local brown = Tip.brown
local yellow = Tip.yellow
local GetIcon = Tip.GetIcon
local GetPrice = Tip.GetPrice
local GetRenewPrice = Tip.GetRenewPrice
local GetGradeImage = Tip.GetGradeImage
local GetCurrencyText = Tip.GetCurrencyText
local GetCurrencyIcon = Tip.GetCurrencyIcon
local format = string.format
local User_type
list = {}
local friend_list = {}

function GetPriceId(item)
  return item.price[item.price_index].priceId
end

local fl_balance = Gui.FlowLayout({
  Dock = "kDockFill",
  Align = "kAlignCenterMiddle",
  BackgroundColor = ARGB(128, 0, 0, 0)
})()
local ctrl_balance = Gui.Control({
  Size = Vector2(966, 635),
  BackgroundColor = white,
  Skin = SkinF.personalInfo_207
})(fl_balance, nil)
local title_ui = {}
Tip.CreateTitle(ctrl_balance, title_ui, "")

function title_ui.btn.EventClick(sender, e)
  Hide()
end

local ctrl_bb = Gui.Control({
  Location = Vector2(9, 44),
  Size = Vector2(375, 573)
})(ctrl_balance, nil)
local fl_bb = Gui.FlowLayout({
  Size = Vector2(371, 527),
  LineSpace = 1
})(ctrl_bb, nil)
local bb_ui = {}
for i = 1, 4 do
  Gui.BuyBox({Style = "BuyBox_01", State = "kBSBalance"})(nil, bb_ui)
end
local pg_list = Gui.NewPagesBar({
  Location = Vector2(60, 534),
  Size = Vector2(260, 36)
})(ctrl_bb, nil)
local ctrl_price = Gui.Control({
  Location = Vector2(386, 44),
  Size = Vector2(571, 527),
  BackgroundColor = white,
  Skin = SkinF.personalInfo_208
})(ctrl_balance, nil)
local ctrl_list = Gui.Label({
  Location = Vector2(10, 7),
  Size = Vector2(301, 21),
  FontSize = 16,
  TextColor = brown,
  TextPadding = Vector4(0, 0, 0, 0)
})(ctrl_price, nil)
local ctrl_scr = Gui.Control({
  Location = Vector2(7, 32),
  Size = Vector2(558, 386),
  Padding = Vector4(0, 8, 6, 8),
  BackgroundColor = white,
  Skin = SkinF.shop_01
})(ctrl_price, nil)
local scr = Gui.ScrollableControl({Dock = "kDockFill"})(ctrl_scr, nil)
local fl_price = Gui.FlowLayout({
  LineSpace = 9,
  Align = "kAlignTopMiddle"
})(scr, nil)
local name_ui = {}
local price_ui, UpdatePrice = {}, 6

function UpdatePrice(clear)
  fl_price.Size = Vector2(519, #list * 19 + (#list - 1) * 9)
  if clear then
    Gui.Clear(fl_price)
  end
  for i, v in ipairs(list) do
    if clear then
      if not name_ui[i] then
        Gui.Label({
          Size = Vector2(253, 19),
          FontSize = 16,
          TextPadding = Vector4(10, 0, 0, 0),
          AutoEllipsis = true
        })(nil, name_ui)
        Gui.Label({
          Size = Vector2(266, 19),
          FontSize = 16,
          TextAlign = "kAlignRightMiddle",
          TextPadding = Vector4(0, 0, 0, 0)
        })(nil, price_ui)
      end
      name_ui[i].Parent = fl_price
      price_ui[i].Parent = fl_price
    end
    name_ui[i].Text = format("%d.  %s", i, _L(v.display))
    if User_type == "Buy_type" then
      price_ui[i].Text = GetPrice(v.price[v.price_index])
    elseif User_type == "Renew_type" then
      price_ui[i].Text = GetRenewPrice(v.price[v.price_index])
    end
  end
end

function CreateMoneyUI(currency_list)
  local fl = Gui.FlowLayout({
    Size = Vector2(61 + #currency_list * 144, 63),
    ControlSpace = 6,
    LineSpace = 1
  })()
  Gui.Label({
    Size = Vector2(61, 31),
    FontSize = 16,
    TextColor = brown,
    Text = _T("UI_store_Consume")
  })(fl, nil)
  local ui = {}
  for _, v in ipairs(currency_list) do
    local lb = Gui.Label({
      Size = Vector2(138, 31),
      TextPadding = Vector4(0, 0, 6, 0),
      TextAlign = "kAlignRightMiddle",
      FontSize = 16,
      TextColor = c,
      BackgroundColor = white,
      Skin = SkinF.avatar_main_086,
      Gui.Label({
        Location = Vector2(2, 0),
        Size = Vector2(30, 30),
        Icon = Tip.GetCurrencyIcon(v)
      })
    })(fl, nil)
    ui[v] = lb
  end
  Gui.Label({
    Size = Vector2(61, 31),
    FontSize = 16,
    TextColor = brown,
    Text = _T("UI_store_My")
  })(fl, nil)
  local my_ui = {}
  for _, v in ipairs(currency_list) do
    local lb = Gui.Label({
      Size = Vector2(138, 31),
      TextPadding = Vector4(0, 0, 6, 0),
      TextAlign = "kAlignRightMiddle",
      FontSize = 16,
      TextColor = c,
      BackgroundColor = white,
      Skin = SkinF.avatar_main_086,
      Gui.Label({
        Location = Vector2(2, 0),
        Size = Vector2(30, 30),
        Icon = Tip.GetCurrencyIcon(v)
      })
    })(fl, nil)
    PushCmd.SubscribeMoney(function(ct)
      lb.Text = ct[v]
    end)
    my_ui[v] = lb
  end
  return fl, ui, my_ui
end

local fl_money, money_ui, my_money_ui = CreateMoneyUI({
  1,
  2,
  4
})
fl_money.Parent = ctrl_price
local fl_money.Location, UpdateMoney = Vector2(20, 429), Vector2(20, 429)

function UpdateMoney()
  local money = {
    0,
    0,
    0,
    0
  }
  for _, v in ipairs(list) do
    local price = v.price[v.price_index]
    local c = price.currency
    local p = price.price
    if User_type == "Buy_type" and 0 < price.rebatePrice then
      p = price.rebatePrice
    end
    money[c] = money[c] - p
  end
  for i, v in ipairs(money) do
    if money_ui[i] then
      money_ui[i].Text = v
    end
  end
end

local btn_prepaid = Gui.Button({
  Style = "ButtonShopPrepaid",
  Location = Vector2(769, 576),
  Size = Vector2(92, 43),
  Text = _T("button_common_Online_Topup"),
  Enable = config.IsRecharge,
  EventClick = function(sender, e)
    game:OpenUrl(config.RechargeUrl)
  end
})(ctrl_balance, nil)
local btn_cancel, UpdateMaxPage = Gui.Button({
  Location = Vector2(866, 576),
  Size = Vector2(92, 43),
  Text = _T("button_common_Cancel"),
  EventClick = function(sender, e)
    Hide()
  end
})(ctrl_balance, nil), ctrl_balance
local UpdateMaxPage, SetBuyBox = function()
  pg_list.PageCount = math.ceil(#list / 4)
end, nil
local SetBuyBox, UpdateList = function(bb, item)
  bb.Name = _L(item.display)
  bb.Icon = GetIcon(item.resource)
  bb.GradeImage = GetGradeImage(item.grade)
  bb:RemoveAllPrice()
  for _, v in ipairs(item.price) do
    if User_type == "Buy_type" then
      bb:AddPrice(GetPrice(v))
    elseif User_type == "Renew_type" then
      bb:AddPrice(GetRenewPrice(v))
    end
  end
  bb.PriceIndex = item.price_index - 1
end, "button_common_Cancel"
local UpdateList, GetListIndex = function()
  for i, v in ipairs(bb_ui) do
    local index = (pg_list.CurrIndex - 1) * 4 + i
    local item = list[index]
    if item then
      if User_type == "Buy_type" then
        SetBuyBox(v, item)
      else
        if item.type == 5 or item.type == 6 then
          if item.subType == 1 then
            item.resource = "humancard"
          elseif item.subType == 2 then
            item.resource = "herocard"
          end
        end
        SetBuyBox(v, item)
      end
      v.Parent = fl_bb
    else
      v.Parent = nil
    end
  end
end, 43

function GetListIndex(index)
  return (pg_list.CurrIndex - 1) * 4 + index
end

local fl_process = Gui.FlowLayout({
  Dock = "kDockFill",
  Align = "kAlignCenterMiddle",
  BackgroundColor = ARGB(128, 0, 0, 0)
})()
local bb_process = Gui.BuyBox({
  Style = "BuyBox_01",
  State = "kBSBalance",
  CanCancel = false,
  Size = Vector2(371, 146)
})(fl_process, nil)
bb_process.CmbPrice.Enable = false
local prop_icon = Gui.ProportionIcon("/ui/skinF/skin_shop_bar_bg.tga", "/ui/skinF/skin_shop_bar_01.tga", Vector4(0, 0, 0, 0), Vector4(0, 0, 0, 0))
prop_icon.BgBorder = Vector4(15, 0, 15, 0)
prop_icon.FgBorder = Vector4(15, 0, 15, 0)
local lb_prop = Gui.Label({
  Location = Vector2(4, 115),
  Size = Vector2(363, 22),
  Icon = prop_icon
})(bb_process, nil)
local list_len = 0
local btn_Execute, Create_Text = Gui.Button({
  Style = "ButtonShopBuy",
  Location = Vector2(586, 576),
  Size = Vector2(178, 43),
  ClickAudio = "buy"
})(ctrl_balance, nil), ctrl_balance

function Create_Text()
  if User_type == "Buy_type" then
    title_ui.lb.Text = _T("button_common_Buy")
    btn_Execute.Text = _T("button_common_Buy")
    ctrl_list.Text = _T("UI_store_Pricing_list")
  elseif User_type == "Renew_type" then
    title_ui.lb.Text = _T("UI_lobby_Items_renewals")
    btn_Execute.Text = _T("button_store_Renewals")
    ctrl_list.Text = _T("UI_common_Renewals_list")
  end
end

local Callbackfaile, Execute_Inter = function(data)
  if User_type == "Renew_type" then
    PersonalInfo.Rennew_DownEvent()
  end
  fl_process.Parent = nil
end, function(data)
  if User_type == "Renew_type" then
    PersonalInfo.Rennew_DownEvent()
  end
  fl_process.Parent = nil
end
local Execute_Inter, Request_Execute = function()
  table.remove(list, 1)
  prop_icon.Proportion = #list / list_len
  UpdateMaxPage()
  UpdateList()
  UpdatePrice(true)
  UpdateMoney()
end, 178

function Request_Execute()
  local item = list[1]
  SetBuyBox(bb_process, item)
  if User_type == "Buy_type" then
    local args = format("%d,%d,%d,%d;", item.type, item.subtype, item.sid, GetPriceId(item))
    local cmd = item.isFreshmanEquip and "freshman_item_buy" or "shop_buy"
    rpc.safecall(cmd, {buy = args}, function(data)
      Execute_Inter()
      if Shop then
        Shop.UpdateCartList()
      end
      if #list > 0 then
        Request_Execute()
      else
        Shop.RequestBuyList()
        Hide()
        MessageBox.ShowError(_T("msgbox_common_num_1210"), 3, true)
        fl_process.Parent = nil
      end
    end, function(data)
      fl_process.Parent = nil
      Shop.RequestBuyList()
      if bit.band(512, ComFuc.leadList) == 0 and bit.band(1024, ComFuc.leadList) == 1024 then
        NewLead.SkipForceLead()
      end
      Hide()
    end)
  elseif User_type == "Renew_type" then
    rpc.safecall("item_renew", {
      pid = item.pid,
      priceId = item.price[item.price_index].priceId,
      t = item.type
    }, function(data)
      Execute_Inter()
      if #list > 0 then
        Request_Execute()
      else
        PersonalInfo.Rennew_DownEvent()
        Hide()
        MessageBox.ShowError(_T("msgbox_common_Renewals_success"), 3, true)
        fl_process.Parent = nil
      end
    end, function(data)
      PersonalInfo.Rennew_DownEvent()
      fl_process.Parent = nil
      Hide()
    end)
  end
end

function btn_Execute.EventClick(sender, e)
  fl_process.Parent = gui
  list_len = #list
  prop_icon.Proportion = 1
  Request_Execute()
  Lobby.ForceLeadGotoPersonalInfo(GetUTF8Text("UI_common_Task_guide_14"))
end

local tip_sys_interface = {
  nil,
  "tip_sys_item",
  "tip_sys_item",
  "tip_sys_item",
  "tip_sys_avatar"
}
for i, v in ipairs(bb_ui) do
  function v.EventPriceChanged(sender, e)
    local index = GetListIndex(i)
    
    local item = list[index]
    item.price_index = sender.PriceIndex + 1
    UpdatePrice(false)
    UpdateMoney()
  end
  
  function v.EventTipActiveChanged(sender, e)
    if sender.TipActive then
      local index = GetListIndex(i)
      local item = list[index]
      if User_type == "Renew_type" then
        if item.type == 5 then
          szInterface = "tip_player_avatar"
        elseif item.type == 2 then
          szInterface = "tip_player_item"
        end
        Tip.SetRpc(szInterface, {
          t = item.type,
          pid = item.pid
        })
      else
        local szInterface = tip_sys_interface[item.type]
        if item.type == 3 and item.subtype == 111 then
          szInterface = "tip_sys_gift"
        end
        Tip.SetRpc(szInterface, {
          t = item.type,
          sid = item.sid
        })
      end
      Tip.SetUseDescription(false)
      Tip.SetOwner(sender)
      Tip.SetOffset(Vector2(5, 33))
      Tip.SetAlignSize(Vector2(80, 80))
    else
      Tip.SetOwner(nil)
    end
  end
  
  function v.EventCancelClick(sender, e)
    local index = GetListIndex(i)
    table.remove(list, index)
    if User_type == "Buy_type" then
      print("Update")
      if Shop then
        Shop.UpdateCartList()
      end
    end
    if #list > 0 then
      UpdateMaxPage()
      UpdateList()
      UpdatePrice(true)
      UpdateMoney()
    else
      Hide()
    end
  end
end

function pg_list.EventIndexChanged(sender, e)
  UpdateList()
end

function Show(Use_type)
  User_type = Use_type
  for k, v in pairs(my_money_ui) do
    v.Text = PushCmd.GetMyMoney(k)
  end
  UpdateMaxPage()
  pg_list.CurrIndex = 1
  for i, v in ipairs(list) do
    v.price_index = 1
  end
  Create_Text()
  UpdateList()
  UpdatePrice(true)
  UpdateMoney()
  fl_balance.Parent = gui
end

function Hide()
  list = {}
  fl_balance.Parent = nil
end
