module("AHSelfCurrency", package.seeall)
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
local fl_currency = Gui.FlowLayout({
  Dock = "kDockFill",
  Align = "kAlignCenterMiddle"
})()
local ctrl_currency = Gui.Control({
  Size = Vector2(590, 606),
  BackgroundColor = white,
  Skin = SkinF.personalInfo_206
})(fl_currency, nil)
local title_ui = {}
Tip.CreateTitle(ctrl_currency, title_ui, _T("UI_store_AH_mainUI_blank_30"))

function title_ui.btn.EventClick(sender, e)
  Hide()
end

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
    120,
    _T("UI_store_AH_mainUI_blank_09")
  }
}
local fl_list = Gui.FlowLayout({
  Location = Vector2(22, 39),
  Size = Vector2(550, 495),
  LineSpace = 4
})(ctrl_currency, nil)
local item_list = {}
if not AHTab3 then
  require("ah_tab3.lua")
end
local ah, CreateItem = AHTab3.CreateHeader(fl_list, header_text), fl_list

function CreateItem(p, ui, text)
  for i = 1, 8 do
    local at = Gui.AuctionItem({
      Size = Vector2(550, 54),
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
  Location = Vector2(26, 548),
  Size = Vector2(260, 36)
})(ctrl_currency, nil)
local btn_cancel, GetItemCurrencyText = Gui.Button({
  Location = Vector2(458, 545),
  Size = Vector2(100, 44),
  Text = _T("UI_common_Cancel_login")
})(ctrl_currency, nil), ctrl_currency

function GetItemCurrencyText(c)
  return c == 1 and GetCurrencyText(4) or GetCurrencyText(1)
end

local RequestList
local timer = Tip.CreateTimer(function()
  if ptr_cast(game.CurrentState, "Client.StateLobby") and AHMain.Active() then
    RequestList()
  end
end)
local sort_func, GetSortFunc = {
  function(t1, t2)
    return t1.quantity < t2.quantity
  end,
  function(t1, t2)
    return t1.reservePrice < t2.reservePrice
  end,
  function(t1, t2)
    return t1.leftTime < t2.leftTime
  end
}, function(t1, t2)
  return t1.quantity < t2.quantity
end
local GetSortFunc, SortList = function()
  if ah.SortUp then
    return function(t1, t2)
      return sort_func[ah.SortIndex + 1](t1, t2)
    end
  else
    return function(t1, t2)
      return sort_func[ah.SortIndex + 1](t2, t1)
    end
  end
end, function(t1, t2)
  return t1.reservePrice < t2.reservePrice
end

function SortList()
  table.sort(list_data.items, GetSortFunc())
end

function RequestList()
  timer.Start()
  rpc.safecall("auction_currency_self_list", {}, function(data)
    if list_data and list_data.sel then
      item_list[list_data.sel].Selected = false
    end
    list_data = data
    SortList()
    local page_count = math.ceil(#list_data.items / #item_list)
    pg.PageCount = 0 < page_count and page_count or 1
    local index = (pg.CurrIndex - 1) * 5
    for i, v in ipairs(item_list) do
      local item = data.items[index + i]
      if item then
        v.Icon = Tip.GetBigCurrencyIcon(item.currency)
        v:SetItemText(0, item.quantity, brown)
        local rp = _Value(_T("UI_store_AH_price"), {
          item.reservePrice
        })
        rp = _Key(rp, {
          GetItemCurrencyText(item.currency)
        })
        v:SetItemText(1, rp, brown)
        v:SetItemText(2, GetLeftTime(item.leftTime), brown)
        v.Ready = true
      else
        v.Ready = false
      end
    end
  end)
end

function pg.EventIndexChanged(sender, e)
  RequestList()
end

function ah.EventSortChanged(sender, e)
  RequestList()
end

function btn_cancel.EventClick(sender, e)
  if list_data and list_data.sel then
    local item = list_data.items[list_data.sel]
    timer.Start()
    MessageBox.ShowWithConfirmCancel(_M(format("msgbox_store_AH_036,%d,%s", item.quantity, GetCurrencyKey(item.currency))), function(sender, e)
      rpc.safecall("auction_cancel_currency", {
        aid = item.aid
      }, function(data)
        MessageBox.ShowError(_M(format("msgbox_store_AH_037,%d,%s", item.quantity, GetCurrencyKey(item.currency))))
        RequestList()
        if not AHTab3 then
          require("ah_tab3.lua")
        end
        AHTab3.RequestList()
      end)
    end, function()
      timer.Stop()
    end)
  else
    MessageBox.ShowError(_T("UI_common_Please_select_item_to_be_deregistered"))
  end
end

for i, v in ipairs(item_list) do
  function v.EventClick(sender, e)
    if sender.Ready then
      sender.Selected = true
      
      list_data.sel = i
      for ii, vv in ipairs(item_list) do
        if vv.Ready and vv.Selected and ii ~= i then
          vv.Selected = false
        end
      end
    end
  end
end
local callback

function Show(cb)
  callback = cb
  fl_currency.Parent = gui
  RequestList()
end

function Hide()
  fl_currency.Parent = nil
  timer.Stop()
  if callback then
    callback()
  end
end
