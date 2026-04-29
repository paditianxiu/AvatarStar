module("AHTab0", package.seeall)
local _T = Tip._T
local _Key = Tip._Key
local _Value = Tip._Value
local _M = Tip._M
local format = string.format
local _L = Tip._L
local _LL = Tip._LL
local white = Tip.white
local black = Tip.black
local brown = Tip.brown
local GetIcon = Tip.GetIcon
local GetGradeImage = Tip.GetGradeImage
local GetGradeText = Tip.GetGradeText
local GetGradeColor = Tip.GetGradeColor
local GetCurrencyText = Tip.GetCurrencyText
local GetCurrencyKey = Tip.GetCurrencyKey
local GetCurrencyIcon = Tip.GetCurrencyIcon
local selected_aid = ""
local list_data
local lang = Tip.lang

function GetItemDisplay(item)
  return item.type == 5 and _LL(item.display) or _L(item.display)
end

local left_time = {
  {
    1,
    _T("UI_store_banlance_time_very_short")
  },
  {
    3,
    _T("UI_store_banlance_time_short")
  },
  {
    12,
    _T("UI_store_balance_time_long_02")
  },
  {
    24,
    _T("UI_store_balance_time_long_01")
  },
  {
    0,
    _T("UI_store_balance_time_very_long")
  }
}

function GetLeftTime(t)
  local lt = left_time[#left_time][2]
  for _, v in ipairs(left_time) do
    if t < v[1] * 3600 then
      return v[2]
    end
  end
  return lt
end

local sort_func, GetSortFunc = {
  function(t1, t2)
    return t1.sid < t2.sid
  end,
  function(t1, t2)
    return t1.grade < t2.grade
  end,
  function(t1, t2)
    local rp1 = t1.biddingPrice or t1.reservePrice
    local rp2 = t2.biddingPrice or t2.reservePrice
    return rp1 < rp2
  end,
  function(t1, t2)
    local fp1 = t1.fixedPrice or 0
    local fp2 = t2.fixedPrice or 0
    return fp1 < fp2
  end,
  function(t1, t2)
    local bn1 = t1.bidderName or ""
    local bn2 = t2.bidderName or ""
    return StrCmpI(bn1, bn2) < 0
  end,
  function(t1, t2)
    return t1.leftTime < t2.leftTime
  end
}, function(t1, t2)
  return t1.sid < t2.sid
end

function GetSortFunc(ah)
  if ah.SortUp then
    return function(t1, t2)
      return sort_func[ah.SortIndex + 1](t1, t2)
    end
  else
    return function(t1, t2)
      return sort_func[ah.SortIndex + 1](t2, t1)
    end
  end
end

function SortList(list, ah)
  table.sort(list, GetSortFunc(ah))
end

local ctrl_browse = Gui.Control({
  Location = Vector2(0, 40),
  Size = Vector2(1128, 645)
})()
local ctrl_top = Gui.Control({
  Location = Vector2(20, 15),
  Size = Vector2(1088, 41),
  BackgroundColor = white,
  Skin = SkinF.shop_12
})(ctrl_browse, nil)
Gui.Label({
  Location = Vector2(10, 11),
  Size = Vector2(43, 19),
  FontSize = 16,
  TextColor = brown,
  Text = _T("UI_lobby_Level")
})(ctrl_top, nil)
local txb_lv_1 = Gui.Textbox({
  Location = Vector2(59, 6),
  Size = Vector2(49, 30),
  MaxLength = 2,
  Number = true,
  FontSize = 16,
  CONTROL_BALLOON_FRAME_DURATION = 1
})(ctrl_top, nil)
Gui.Label({
  Location = Vector2(114, 11),
  Size = Vector2(13, 19),
  FontSize = 16,
  TextColor = brown,
  Text = "~"
})(ctrl_top, nil)
local txb_lv_2 = Gui.Textbox({
  Location = Vector2(133, 6),
  Size = Vector2(49, 30),
  MaxLength = 2,
  Number = true,
  FontSize = 16,
  CONTROL_BALLOON_FRAME_DURATION = 1
})(ctrl_top, nil)
Gui.Label({
  Location = Vector2(190, 11),
  Size = Vector2(47, 19),
  FontSize = 16,
  TextColor = brown,
  Text = _T("UI_lobby_Name")
})(ctrl_top, nil)
local txb_name = Gui.Textbox({
  Location = Vector2(244, 6),
  Size = Vector2(163, 30),
  MaxLength = 128,
  FontSize = 16,
  CONTROL_BALLOON_FRAME_DURATION = 1
})(ctrl_top, nil)
local btn_search = Gui.Button({
  Location = Vector2(425, 1),
  Size = Vector2(84, 40),
  Text = _T("UI_common_Search")
})(ctrl_top, nil)
local btn_reset = Gui.Button({
  Location = Vector2(520, 1),
  Size = Vector2(84, 40),
  Text = _T("UI_common_Initialize")
})(ctrl_top, nil)
local btn_exchange = Gui.Button({
  Style = "ButtonShopExchange",
  Location = Vector2(944, 1),
  Size = Vector2(144, 40),
  Text = _T("button_store_exchange_voucher")
})(ctrl_top, nil)
local ctrl_filter = Gui.Control({
  Location = Vector2(20, 66),
  Size = Vector2(220, 562),
  BackgroundColor = white,
  Skin = SkinF.auction_01
})(ctrl_browse, nil)
Gui.Label({
  Location = Vector2(9, 6),
  Size = Vector2(202, 19),
  FontSize = 16,
  Text = _T("UI_common_Setting_Filter")
})(ctrl_filter, nil)
local lv = Gui.ListTreeView({
  Style = "AuctionListTreeView",
  Location = Vector2(10, 35),
  Size = Vector2(200, 520)
})(ctrl_filter, nil)
local filter = {
  {
    1,
    _T("button_store_equipment_button"),
    {nil, 2}
  },
  {
    2,
    _T("tips_abilities_Rifle"),
    {
      nil,
      2,
      1
    }
  },
  {
    2,
    _T("tips_abilities_Sniper_Rifle"),
    {
      nil,
      2,
      2
    }
  },
  {
    2,
    _T("UI_common_M_G"),
    {
      nil,
      2,
      3
    }
  },
  {
    2,
    _T("UI_datalist_m32_type"),
    {
      nil,
      2,
      14
    }
  },
  {
    2,
    _T("tips_abilities_Shotgun"),
    {
      nil,
      2,
      4
    }
  },
  {
    2,
    _T("tips_abilities_Pistol"),
    {
      nil,
      2,
      5
    }
  },
  {
    2,
    _T("tips_abilities_Bazooka"),
    {
      nil,
      2,
      11
    }
  },
  {
    2,
    _T("UI_datalist_penwuqi_type"),
    {
      nil,
      2,
      15
    }
  },
  {
    2,
    _T("tips_abilities_Grenade"),
    {
      nil,
      2,
      10
    }
  },
  {
    2,
    _T("tips_abilities_Bow"),
    {
      nil,
      2,
      12
    }
  },
  {
    2,
    _T("tips_abilities_Shield_Weapon"),
    {
      nil,
      2,
      13
    }
  },
  {
    2,
    _T("UI_datalist_nu_type"),
    {
      nil,
      2,
      16
    }
  },
  {
    2,
    _T("tips_abilities_Knife"),
    {
      nil,
      2,
      6
    }
  },
  {
    2,
    _T("tips_abilities_Equipment_for_back"),
    {
      nil,
      2,
      102
    }
  },
  {
    2,
    _T("button_common_Ring"),
    {
      nil,
      2,
      103
    }
  },
  {
    1,
    _T("button_common_Item"),
    {nil, 3}
  },
  {
    2,
    _T("tips_abilities_Food"),
    {
      nil,
      3,
      103
    }
  },
  {
    2,
    _T("id_datalist_Bandage"),
    {
      nil,
      3,
      101
    }
  },
  {
    2,
    _T("tips_store_Enhancement_Material_lottery"),
    {
      nil,
      3,
      300
    }
  },
  {
    2,
    _T("tips_lobby_Common_Desc24"),
    {
      nil,
      3,
      301
    }
  },
  {
    2,
    _T("tips_store_Gem_lottery"),
    {
      nil,
      3,
      302
    }
  },
  {
    2,
    _T("UI_common_make_07"),
    {
      nil,
      3,
      303
    }
  },
  {
    2,
    _T("UI_common_blueprint_01"),
    {
      nil,
      3,
      112
    }
  },
  {
    2,
    _T("UI_common_chip_01"),
    {
      nil,
      3,
      304
    }
  },
  {
    2,
    _T("tips_abilities_Pharmacy"),
    {
      nil,
      3,
      102
    }
  },
  {
    2,
    _T("tips_abilities_Bonus_Card"),
    {
      nil,
      3,
      106
    }
  },
  {
    2,
    _T("tips_abilities_Device"),
    {
      nil,
      3,
      105
    }
  },
  {
    2,
    _T("tips_common_additional_tips8"),
    {
      nil,
      3,
      100
    }
  },
  {
    1,
    _T("tips_abilities_Treasure_Chest"),
    {
      nil,
      3,
      400
    }
  },
  {
    1,
    _T("button_common_Gesture"),
    {nil, 4}
  },
  {
    1,
    _T("button_common_Avatar_Card"),
    {nil, 5}
  }
}
lv:AddColumn("", 200, "kAlignLeftMiddle")
local yellow = ARGB(255, 252, 221, 49)
local gray = ARGB(255, 164, 165, 165)
local node_1, node_2, node_3
for i, v in ipairs(filter) do
  if v[1] == 1 then
    node_1 = lv:AddItem(lv.RootItem, v[2])
    node_1.ID = i
    node_1:SetTextColor(0, yellow)
    node_1:SetHighLightTextColor(0, brown)
  elseif v[1] == 2 then
    if node_1 then
      node_2 = lv:AddItem(node_1, v[2])
      node_2.ID = i
      node_2:SetTextColor(0, white)
      node_2:SetHighLightTextColor(0, brown)
    end
  elseif v[1] == 3 and node_2 then
    node_2:SetTextColor(0, yellow)
    node_3 = lv:AddItem(node_2, v[2])
    node_3.ID = i
    node_3:SetTextColor(0, white)
    node_3:SetHighLightTextColor(0, brown)
  end
end
local fl_list = Gui.FlowLayout({
  Location = Vector2(253, 66),
  Size = Vector2(854, 530),
  LineSpace = 5,
  Align = "kAlignCenterTop"
})(ctrl_browse, nil)
local header_text = {
  {
    292,
    _T("UI_store_AH_mainUI_blank_04")
  },
  {
    96,
    _T("tips_abilities_Quality")
  },
  {
    120,
    _T("UI_store_new_AH_UI_02")
  },
  {
    120,
    _T("UI_store_new_AH_UI_04")
  },
  {
    130,
    _T("UI_store_Seller")
  },
  {
    96,
    _T("tips_lobby_Common_Desc5")
  }
}

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
  ah:SetItemTextPadding(0, Vector4(85, 0, 0, 0))
  return ah
end

local ah = CreateHeader(fl_list, header_text)
local item_list = {}

function CreateItem(p, ui, text)
  for i = 1, 5 do
    local at = Gui.AuctionItem({
      Size = Vector2(p.Size.x, 93)
    })(p, ui)
    for _, vv in ipairs(text) do
      at:SetIconRect(5, 5, 80, 80)
      at:AddItem(vv[1])
    end
    at:SetItemTextPadding(0, Vector4(90, 0, 0, 0))
  end
end

CreateItem(fl_list, item_list, header_text)
Gui.Label({
  Location = Vector2(288, 596),
  Size = Vector2(200, 19),
  TextColor = brown,
  FontSize = 16,
  TextAlign = "kAlignLeftMiddle",
  Text = _T("UI_store_new_AH_UI_01")
})(ctrl_browse, nil)
local ckb_unit_price = Gui.CheckBox({
  Location = Vector2(258, 594),
  Size = Vector2(29, 28),
  Check = true
})(ctrl_browse, nil)
local pg = Gui.NewPagesBar({
  Location = Vector2(524, 592),
  Size = Vector2(260, 36)
})(ctrl_browse, nil)
local btn_bid = Gui.Button({
  Location = Vector2(892, 589),
  Size = Vector2(104, 40),
  Text = _T("button_common_Auction")
})(ctrl_browse, nil)
local btn_buy = Gui.Button({
  Location = Vector2(1005, 589),
  Size = Vector2(102, 40),
  Text = _T("button_common_Fixed_Price")
})(ctrl_browse, nil)
local order_field = {
  "NAME",
  "GRADE",
  "BIDDING_PRICE",
  "FIXED_PRICE",
  "AUCTIONEER_NAME",
  "EXPIRE_TIME"
}
local list_args, GetRefreshArgs = {}, "GRADE"

function GetRefreshArgs()
  list_args.occupation = nil
  list_args.t = nil
  list_args.st = nil
  local item = lv.SelectedItem
  if item then
    local f = filter[item.ID][3]
    list_args.occupation = f[1]
    list_args.t = f[2]
    if not list_args.t then
      return nil
    end
    list_args.st = f[3]
  end
  list_args.p = pg.CurrIndex
  list_args.s = 5
  list_args.order = ah.SortUp and -1 or 1
  if ah.SortIndex + 1 == 3 then
    list_args.orderField = ckb_unit_price.Check and "SINGLE_BIDDING_PRICE" or "BIDDING_PRICE"
  elseif ah.SortIndex + 1 == 4 then
    list_args.orderField = ckb_unit_price.Check and "SINGLE_FIXED_PRICE" or "FIXED_PRICE"
  else
    list_args.orderField = order_field[ah.SortIndex + 1]
  end
  list_args.locale = lang[game.local_language]
  return list_args
end

function txb_lv_1.EventTextChanged(sender, e)
  sender:CancelBalloon()
end

local txb_lv_2.EventTextChanged, ResponseList = function(sender, e)
  sender:CancelBalloon()
end, function(sender, e)
  sender:CancelBalloon()
end

function ResponseList(data)
  if list_data and list_data.sel then
    item_list[list_data.sel].Selected = false
  end
  list_data = data
  pg.PageCount = list_data.pages
  pg.CurrIndex = list_data.page
  for i, v in ipairs(item_list) do
    local item = data.items[i]
    if item then
      v.Type = item.type
      v.Id = item.itemId
      v.AuctioneerId = item.auctioneerId
      if item.type == 5 or item.type == 6 then
        if item.subType == 1 then
          item.resource = "humancard"
        elseif item.subType == 2 then
          item.resource = "herocard"
        end
      end
      v.Icon = GetIcon(item.resource)
      v.Count = item.quantity
      v.GradeImage = GetGradeImage(item.grade)
      v.PlusLevel = item.refitedNum
      v.Level = tostring(v.PlusLevel)
      v.PlusLevelBg = Tip.GetLevelImageBg(v.PlusLevel)
      v:SetItemText(0, GetItemDisplay(item), brown)
      v:SetItemText(1, GetGradeText(item.grade), GetGradeColor(item.grade))
      local self = item.bidderId == SelectCharacter.roleServerId
      item.minBidPrice = (item.biddingPrice or item.reservePrice) * list_data.minReservePricePercent
      local current_price = item.biddingPrice or item.reservePrice
      if ckb_unit_price.Check then
        current_price = format("%.2f", current_price / item.quantity)
      end
      local cp = _Value(self and _T("UI_store_AH_my_price") or _T("UI_store_AH_price"), {current_price})
      cp = _Key(cp, {
        GetCurrencyText(item.currency)
      })
      v:SetItemText(2, cp, brown)
      local fix_price = item.fixedPrice
      if fix_price and ckb_unit_price.Check then
        fix_price = format("%.2f", fix_price / item.quantity)
      end
      local fp = item.fixedPrice and _Value(_T("UI_store_AH_price"), {fix_price}) or _T("tips_abilities_None")
      if item.fixedPrice then
        fp = _Key(fp, {
          GetCurrencyText(item.currency)
        })
      end
      v:SetItemText(3, fp, brown)
      v:SetItemText(4, item.auctioneerName, brown)
      v:SetItemText(5, GetLeftTime(item.leftTime), brown)
      v.Self = self
      v.Ready = true
      if item.aid == selected_aid then
        list_data.sel = i
        v.Selected = true
      end
    else
      v.Ready = false
    end
  end
end

local timer, RefreshSearch = Tip.CreateTimer(function()
  if ptr_cast(game.CurrentState, "Client.StateLobby") and AHMain.Active() then
    ah.SortEnable = true
    local args = GetRefreshArgs()
    if args then
      rpc.safecall("auction_list", args, ResponseList)
    end
  end
end), function()
  if ptr_cast(game.CurrentState, "Client.StateLobby") and AHMain.Active() then
    ah.SortEnable = true
    local args = GetRefreshArgs()
    if args then
      rpc.safecall("auction_list", args, ResponseList)
    end
  end
end

function RefreshSearch()
  ah.SortEnable = true
  local args = GetRefreshArgs()
  if args then
    txb_lv_1.Text = args.minLevel
    txb_lv_2.Text = args.maxLevel
    txb_name.Text = args.itemName
    rpc.safecall("auction_list", args, ResponseList)
  end
  timer.Start()
end

function Search()
  list_args.minLevel = tonumber(txb_lv_1.Text)
  list_args.maxLevel = tonumber(txb_lv_2.Text)
  list_args.itemName = txb_name.Text
  RefreshSearch()
  timer.Start()
end

function Reset()
  txb_lv_1.Text = ""
  txb_lv_2.Text = ""
  txb_name.Text = ""
  ah.SortIndex = 0
  lv.SelectedItem = nil
  local item = lv.RootItem.FirstChild
  while item do
    item.Expanded = false
    item = item:GetNextNode()
  end
  list_args.minLevel = tonumber(txb_lv_1.Text)
  list_args.maxLevel = tonumber(txb_lv_2.Text)
  list_args.itemName = txb_name.Text
  if list_data then
    if list_data.sel then
      item_list[list_data.sel].Selected = false
    end
    list_data = nil
  end
  for _, v in ipairs(item_list) do
    v.Ready = false
  end
  pg.PageCount = 0
  timer.Stop()
end

function btn_reset.EventClick(sender, e)
  Reset()
end

function btn_exchange.EventClick(sender, e)
  if not AHExchange then
    require("ah_exchange.lua")
  end
  AHExchange.Show()
end

function txb_name.EventTextChanged(sender, e)
  sender:CancelBalloon()
end

function txb_name.EventValueEnter(sender, e)
  Search()
end

function btn_search.EventClick(sender, e)
  Search()
end

function ckb_unit_price.EventCheckChanged(sender, e)
  if e.Trigger == "kTriggerMouse" then
    ah.SortEnable = false
    ah:SetItemText(2, sender.Check and _T("UI_store_new_AH_UI_02") or _T("UI_store_new_AH_UI_03"))
    ah:SetItemText(3, sender.Check and _T("UI_store_new_AH_UI_04") or _T("UI_store_new_AH_UI_05"))
    if list_data then
      ResponseList(list_data)
    end
  end
end

function lv.EventSelectItemChange(sender, e)
  if lv.SelectedItem then
    if GetRefreshArgs() then
      btn_search.Enable = true
      pg.Enable = true
      RefreshSearch()
    else
      list_data = nil
      for _, v in ipairs(item_list) do
        v.Ready = false
      end
      btn_search.Enable = false
      pg.Enable = false
      pg.PageCount = 0
    end
  else
    btn_search.Enable = true
    pg.Enable = true
  end
end

function ah.EventSortChanged(sender, e)
  RefreshSearch()
end

local btn_bid.EventClick, Buy = function(sender, e)
  if list_data and list_data.sel then
    local item = list_data.items[list_data.sel]
    if not AHBid then
      require("ah_bid.lua")
    end
    timer.Stop()
    AHBid.Show(item, RefreshSearch)
  else
    MessageBox.ShowError(_T("UI_common_Please_select_item_to_be_auctioned"))
  end
end, function(sender, e)
  if list_data and list_data.sel then
    local item = list_data.items[list_data.sel]
    if not AHBid then
      require("ah_bid.lua")
    end
    timer.Stop()
    AHBid.Show(item, RefreshSearch)
  else
    MessageBox.ShowError(_T("UI_common_Please_select_item_to_be_auctioned"))
  end
end

function Buy()
  if list_data and list_data.sel then
    local item = list_data.items[list_data.sel]
    if item.fixedPrice then
      timer.Stop()
      MessageBox.ShowWithConfirmCancel(_M(format("msgbox_store_AH_010,%d,%d,%s", item.fixedPrice, item.quantity, _LL(item.display)), item.type == 5 and bit.bshift(1, 3) or 0), function()
        rpc.safecall("auction_buy", {
          aid = item.aid,
          t = item.type
        }, function(data)
          MessageBox.ShowError(_M(format("msgbox_store_AH_012,%d,%s", item.quantity, _LL(item.display)), item.type == 5 and bit.bshift(1, 2) or 0))
          RefreshSearch()
        end, function()
          RefreshSearch()
        end)
      end, function()
        timer.Start()
      end)
    else
      MessageBox.ShowError(_T("msgbox_store_no_auction_price"))
    end
  else
    MessageBox.ShowError(_T("msgbox_common_num_1348"))
  end
end

function btn_buy.EventClick(sender, e)
  Buy()
end

function pg.EventIndexChanged(sender, e)
  RefreshSearch()
end

tip_player_interface = {
  nil,
  "tip_player_item_auction",
  "tip_player_item_auction",
  "tip_player_item_auction",
  "tip_player_avatar_auction",
  "tip_player_avatar_auction"
}
for i, v in ipairs(item_list) do
  function v.EventTipActiveChanged(sender, e)
    if sender.Ready then
      Tip.SetRpc(tip_player_interface[sender.Type], {
        t = sender.Type,
        
        pid = sender.Id,
        aid = sender.AuctioneerId
      })
      Tip.SetUseDescription(false)
      Tip.SetOwner(sender)
      Tip.SetOffset(Vector2(5, 4))
      Tip.SetAlignSize(Vector2(80, 80))
    end
  end
  
  function v.EventClick(sender, e)
    if sender.Ready then
      sender.Selected = true
      list_data.sel = i
      local item = list_data.items[i]
      selected_aid = item.aid
      for ii, vv in ipairs(item_list) do
        if vv.Ready and vv.Selected and ii ~= i then
          vv.Selected = false
        end
      end
    end
  end
end

function Show(p)
  ctrl_browse.Parent = p
  if list_data then
    timer.Start()
  end
end

function Hide()
  timer.Stop()
  ctrl_browse.Parent = nil
end
