module("AHTab1", package.seeall)
require("ah_register.lua")
local _T = Tip._T
local _Value = Tip._Value
local _M = Tip._M
local _Key = Tip._Key
local _L = Tip._L
local _LL = Tip._LL
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
local ctrl_register = Gui.Control({
  Location = Vector2(0, 40),
  Size = Vector2(1128, 645)
})()
local ctrl_top = Gui.Control({
  Location = Vector2(20, 15),
  Size = Vector2(1088, 41),
  BackgroundColor = white,
  Skin = SkinF.shop_12
})(ctrl_register, nil)
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
local fl_list = Gui.FlowLayout({
  Location = Vector2(20, 66),
  Size = Vector2(1087, 530),
  LineSpace = 5,
  Align = "kAlignCenterTop"
})(ctrl_register, nil)
local header_text = {
  {
    445,
    _T("UI_store_AH_mainUI_blank_04")
  },
  {
    96,
    _T("tips_abilities_Quality")
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
    _T("UI_common_Buyer")
  },
  {
    96,
    _T("tips_lobby_Common_Desc5")
  }
}
local ah = AHTab0.CreateHeader(fl_list, header_text)
local item_list = {}
AHTab0.CreateItem(fl_list, item_list, header_text)
Gui.Label({
  Location = Vector2(59, 596),
  Size = Vector2(200, 19),
  TextColor = brown,
  FontSize = 16,
  TextAlign = "kAlignLeftMiddle",
  Text = _T("UI_store_new_AH_UI_01")
})(ctrl_register, nil)
local ckb_unit_price = Gui.CheckBox({
  Location = Vector2(29, 594),
  Size = Vector2(29, 28),
  Check = true
})(ctrl_register, nil)
local btn_register = Gui.Button({
  Location = Vector2(9, 1),
  Size = Vector2(120, 40),
  Text = _T("UI_common_Register_Item")
})(ctrl_top, nil)
local pg = Gui.NewPagesBar({
  Location = Vector2(433, 592),
  Size = Vector2(260, 36)
})(ctrl_register, nil)
local btn_cancel = Gui.Button({
  Location = Vector2(883, 589),
  Size = Vector2(102, 40),
  Text = _T("UI_common_Cancel_login")
})(ctrl_register, nil)
local btn_cancel_all = Gui.Button({
  Location = Vector2(990, 589),
  Size = Vector2(117, 40),
  Text = _T("button_common_Cancel_all_registered")
})(ctrl_register, nil)
local RequestList, ResponseList

function ResponseList(data)
  for _, v in ipairs(item_list) do
    v.Selected = false
  end
  list_data = data
  SortList(list_data.items, ah)
  lb_left.Text = _T("UI_store_AH_mainUI_blank_19")
  prop.MaxValue = list_data.maxCount
  prop.CurrentValue = list_data.maxCount - list_data.onSell
  local page_count = math.ceil(#list_data.items / #item_list)
  pg.PageCount = 0 < page_count and page_count or 1
  local index = (pg.CurrIndex - 1) * 5
  for i, v in ipairs(item_list) do
    local item = data.items[index + i]
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
      local current_price = item.biddingPrice or item.reservePrice
      if ckb_unit_price.Check then
        current_price = format("%.2f", current_price / item.quantity)
      end
      local cp = _Value(_T("UI_store_AH_price"), {current_price})
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
      v.Self = not item.bidderId
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
  rpc.safecall("auction_self_list", {}, ResponseList)
end

function btn_register.EventClick(sender, e)
  timer.Stop()
  AHRegister.Show(RequestList)
end

function ah.EventSortChanged(sender, e)
  RequestList()
end

function btn_cancel.EventClick(sender, e)
  if list_data and list_data.sel then
    local item = list_data.items[list_data.sel]
    timer.Stop()
    MessageBox.ShowWithConfirmCancel(_M(format("msgbox_store_AH_032,%d,%s", item.quantity, _LL(item.display)), item.type == 5 and bit.bshift(1, 2) or 0), function(sender, e)
      rpc.safecall("auction_cancel", {
        aid = item.aid
      }, function(data)
        MessageBox.ShowError(_M(format("msgbox_store_AH_033,%d,%s", item.quantity, _LL(item.display)), item.type == 5 and bit.bshift(1, 2) or 0))
        RequestList()
      end)
    end, function(sender, e)
      timer.Start()
    end)
  else
    MessageBox.ShowError(_T("UI_common_Please_select_item_to_be_deregistered"))
  end
end

function btn_cancel_all.EventClick(sender, e)
  if not list_data or not list_data.items[1] then
    MessageBox.ShowError(_T("msgbox_common_num_1307"))
    return
  end
  timer.Start()
  MessageBox.ShowWithConfirmCancel(_T("msgbox_store_AH_034"), function(sender, e)
    rpc.safecall("auction_cancel_all", {}, function(data)
      MessageBox.ShowError(_T("msgbox_store_AH_035"))
      RequestList()
    end)
  end, function(sender, e)
    timer.Stop()
  end)
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
  ctrl_register.Parent = p
  RequestList()
end

function Hide()
  ctrl_register.Parent = nil
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
