module("AHTab2", package.seeall)
local _T = Tip._T
local _Value = Tip._Value
local _Key = Tip._Key
local _L = Tip._L
local format = string.format
local white = Tip.white
local black = Tip.black
local brown = Tip.brown
local GetIcon = Tip.GetIcon
local GetGradeImage = Tip.GetGradeImage
local GetGradeText = Tip.GetGradeText
local GetGradeColor = Tip.GetGradeColor
local GetCurrencyText = Tip.GetCurrencyText
local GetCurrencyIcon = Tip.GetCurrencyIcon
local GetLeftTime = AHTab0.GetLeftTime
local tip_player_interface = AHTab0.tip_player_interface
local GetItemDisplay = AHTab0.GetItemDisplay
local SortList = AHTab0.SortList
local list_data
local ctrl_balance = Gui.Control({
  Location = Vector2(0, 40),
  Size = Vector2(1128, 645)
})()
local ctrl_top = Gui.Control({
  Location = Vector2(20, 15),
  Size = Vector2(1088, 41),
  BackgroundColor = white,
  Skin = SkinF.shop_12
})(ctrl_balance, nil)
local fl_list = Gui.FlowLayout({
  Location = Vector2(20, 66),
  Size = Vector2(1087, 530),
  LineSpace = 5,
  Align = "kAlignCenterTop"
})(ctrl_balance, nil)
local balance_text = {
  {
    445,
    _T("UI_store_AH_mainUI_blank_04")
  },
  {
    96,
    _T("UI_store_AH_mainUI_blank_05")
  },
  {
    160,
    _T("UI_store_new_AH_UI_02")
  },
  {
    160,
    _T("UI_store_new_AH_UI_04")
  },
  {
    130,
    _T("UI_store_AH_mainUI_blank_08")
  },
  {
    96,
    _T("UI_store_AH_mainUI_blank_09")
  }
}
local ah = AHTab0.CreateHeader(fl_list, balance_text)
local item_list = {}
AHTab0.CreateItem(fl_list, item_list, balance_text)
Gui.Label({
  Location = Vector2(59, 596),
  Size = Vector2(200, 19),
  TextColor = brown,
  FontSize = 16,
  TextAlign = "kAlignLeftMiddle",
  Text = _T("UI_store_new_AH_UI_01")
})(ctrl_balance, nil)
local ckb_unit_price = Gui.CheckBox({
  Location = Vector2(29, 594),
  Size = Vector2(29, 28),
  Check = true
})(ctrl_balance, nil)
local lb_balance = Gui.Label({
  Location = Vector2(18, 12),
  Size = Vector2(520, 19),
  FontSize = 16,
  TextColor = brown,
  Text = _T("UI_store_AH_mainUI_blank_11")
})(ctrl_top, nil)
pg = Gui.NewPagesBar({
  Location = Vector2(433, 592),
  Size = Vector2(260, 36)
})(ctrl_balance, nil)
local btn_rebid = Gui.Button({
  Location = Vector2(1005, 589),
  Size = Vector2(102, 40),
  Text = _T("UI_store_AH_mainUI_blank_10")
})(ctrl_balance, nil)
local RequestList, ResponseList

function ResponseList(data)
  for _, v in ipairs(item_list) do
    v.Selected = false
  end
  list_data = data
  SortList(list_data.items, ah)
  local page_count = math.ceil(#list_data.items / #item_list)
  pg.PageCount = 0 < page_count and page_count or 1
  local index = (pg.CurrIndex - 1) * 5
  for i, v in ipairs(item_list) do
    local item = list_data.items[index + i]
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
      v:SetItemText(4, item.bidderName, brown)
      v:SetItemText(5, GetLeftTime(item.leftTime), brown)
      v.Self = self
      v.Ready = true
    else
      v.Ready = false
    end
  end
end

local timer = Tip.CreateTimer(function()
  if ptr_cast(game.CurrentState, "Client.StateLobby") and AHMain.Active() then
    RequestList()
  end
end)

function RequestList()
  timer.Start()
  rpc.safecall("auction_settlement_list", {}, ResponseList)
end

local ah.EventSortChanged, Rebid = function(sender, e)
  RequestList()
end, function(sender, e)
  RequestList()
end

function Rebid()
  if list_data and list_data.sel then
    local item = list_data.items[list_data.sel]
    if not AHBid then
      require("ah_bid.lua")
    end
    AHBid.Show(item, RequestList)
  else
    MessageBox.ShowError(_T("UI_common_Please_select_item_to_be_auctioned"))
  end
end

function btn_rebid.EventClick(sender, e)
  Rebid()
end

function pg.EventIndexChanged(sender, e)
  RequestList()
end

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
      local index = (pg.CurrIndex - 1) * 5
      list_data.sel = index + i
      local item = list_data.items[i]
      for ii, vv in ipairs(item_list) do
        if vv.Ready and vv.Selected and ii ~= i then
          vv.Selected = false
        end
      end
    end
  end
end

function Show(p)
  ctrl_balance.Parent = p
  RequestList()
end

function Hide()
  ctrl_balance.Parent = nil
  timer.Stop()
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
