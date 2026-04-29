module("Shop", package.seeall)
local _T = GetUTF8Text
local _L = GetUTF8Text
local white = Tip.white
local black = Tip.black
local brown = Tip.brown
local yellow = Tip.yellow
local GetIcon = Tip.GetIcon
local GetCount = Tip.GetCount
local GetGradeImage = Tip.GetGradeImage
local GetCurrencyText = Tip.GetCurrencyText
local GetCurrencyIcon = Tip.GetCurrencyIcon
local SortPrice = Tip.SortPrice
local shop_list = {}
local cart_list = {}
local refresh_rate = {
  _T("UI_store_meirishuaxin"),
  _T("UI_store_meizhoushuaxin"),
  _T("UI_store_meiyueshuaxin")
}
local LimitMsgError = {}
require("ShopGive.lua")
require("LimitCountDown.lua")
local ctrl_shop = Gui.Control({
  Location = Vector2(7, 5),
  Size = Vector2(1139, 773)
})()
local buy_t = {
  {
    nil,
    _T("button_common_Recommend")
  },
  {
    2,
    _T("button_store_equipment_button")
  },
  {
    3,
    _T("button_common_Item")
  },
  {
    4,
    _T("button_common_Gesture")
  },
  {
    5,
    _T("button_common_Avatar_Card")
  }
}
local tc_buy_t = Gui.TabControl({
  Style = "TabControl_01",
  Size = Vector2(802, 685),
  ClickAudio = "menu2nd"
})(ctrl_shop, nil)
for _, v in ipairs(buy_t) do
  tc_buy_t:AddItem(v[2])
end
Gui.Control({
  Location = Vector2(19, 55),
  Size = Vector2(766, 41),
  BackgroundColor = white,
  Skin = SkinF.shop_12
})(tc_buy_t, nil)
local buy_st = {
  {
    {
      2,
      _T("button_common_Hot")
    },
    {
      1,
      _T("button_common_New")
    },
    {
      8,
      _T("UI_store_shopbuytime")
    },
    {
      4,
      _T("button_common_Discount")
    },
    {
      5,
      _T("UI_common_Task_guide_19"),
      1
    }
  },
  {
    {
      "1,2,3,4,5,6,10,11,12,13,14,15,16",
      _T("button_common_Weapon")
    },
    {
      "103",
      _T("button_common_Ring")
    },
    {
      "102",
      _T("tips_abilities_Equipment_for_back")
    }
  },
  {
    {
      "100,101,102,103,104,105,106,107,108,109,110,200,300,301,302,303,401,400",
      _T("button_common_Normal_Item")
    },
    {
      "111",
      _T("UI_common_gift_02")
    }
  },
  {
    {
      "",
      _T("button_common_Normal_Gesture")
    }
  },
  {
    {
      "1",
      _T("button_common_Normal_Avatar_Card")
    }
  }
}
local max_st = 1
for _, v in ipairs(buy_st) do
  if max_st < #buy_st then
    max_st = #buy_st
  end
end
local st_sel = {}
local st_page = {}
for i in ipairs(buy_t) do
  st_page[i] = {}
  for ii in ipairs(buy_st) do
    st_page[i][ii] = {1, 1}
  end
end
local tc_buy_st = Gui.TabControl({
  Style = "TabControl_02",
  Location = Vector2(10, 56),
  Size = Vector2(781, 620),
  TextPadding = Vector4(0, 0, 0, 2),
  ClickAudio = "menu3rd"
})(tc_buy_t, nil)
for i = 1, max_st do
  tc_buy_st:AddItem("")
end
local lb_filter = Gui.Label({
  Location = Vector2(515, 6),
  Size = Vector2(100, 29),
  FontSize = 16,
  TextColor = brown,
  TextAlign = "kAlignRightMiddle",
  Text = _T("UI_store_Filter")
})(tc_buy_st, nil)
local filter_t = {
  {
    nil,
    _T("UI_common_All_Classes")
  },
  {
    0,
    _T("UI_profession_Guardian")
  },
  {
    1,
    _T("UI_profession_Gunner")
  },
  {
    2,
    _T("UI_profession_Assassin")
  },
  {
    3,
    _T("UI_profession_Biochemical")
  }
}
local cmb_filter = Gui.ComboBox({
  Location = Vector2(621, 6),
  Size = Vector2(147, 29)
})(tc_buy_st, nil)
for i, v in ipairs(filter_t) do
  cmb_filter:AddItem(v[2])
end
local fl_bb = Gui.FlowLayout({
  Location = Vector2(0, 35),
  Size = Vector2(781, 583),
  Padding = Vector4(0, 6, 0, 4),
  ControlSpace = 3,
  LineSpace = 3,
  Align = "kAlignCenterTop"
})(tc_buy_st, nil)
local bb_ui = {}
for i = 1, 8 do
  Gui.BuyBox({Style = "BuyBox_01"})(fl_bb, bb_ui)
end
local pg_buy = Gui.NewPagesBar({
  Size = Vector2(260, 36),
  Dock = "kDockBottomCenter"
})(fl_bb, nil)
local tc_right = Gui.TabControl({
  Style = "TabControl_01",
  Location = Vector2(806, 0),
  Size = Vector2(322, 685),
  ClickAudio = "menu2nd"
})(ctrl_shop, nil)
tc_right:AddItem(_T("button_common_Preview"))
tc_right:AddItem(_T("button_common_Shopping_Card"))
local ctrl_avatar = Gui.Control({
  Location = Vector2(21, 56),
  Size = Vector2(279, 454)
})()
local cv = Gui.CharacterAnimCard({
  ID = 1,
  Size = Vector2(279, 454),
  BackgroundColor = ARGB(0, 0, 0, 0)
})(ctrl_avatar, nil)
local btn_reset = Gui.Button({
  Location = Vector2(187, 410),
  Size = Vector2(84, 40),
  Text = _T("button_common_Reset"),
  EventClick = function(sender, e)
    lg:ResetVanRotation()
    lg:SetREId(1)
    lg:LoadInfoByTag()
    lg:SetWeapon(0, "")
    lg:PlayAnim("idlea")
  end
})(ctrl_avatar, nil)
local btn_left = Gui.RotateBtn({
  Location = Vector2(9, 412),
  Size = Vector2(32, 36),
  Skin = SkinF.personalInfo_101,
  ClickAudio = "button",
  EventMouseDown = function(sender, e)
    lg:SetVanRotateSpeed(-0.3)
  end,
  EventMouseUp = function(sender, e)
    lg:SetVanRotateSpeed(0)
  end
})(cv, nil)
local btn_right = Gui.RotateBtn({
  Location = Vector2(47, 412),
  Size = Vector2(32, 36),
  Skin = SkinF.personalInfo_102,
  ClickAudio = "button",
  EventMouseDown = function(sender, e)
    lg:SetVanRotateSpeed(0.3)
  end,
  EventMouseUp = function(sender, e)
    lg:SetVanRotateSpeed(0)
  end
})(cv, nil)
local btn_prepaid = Gui.Button({
  Style = "ButtonShopPrepaid",
  Location = Vector2(21, 628),
  Size = Vector2(279, 43),
  Text = _T("button_common_Online_Topup"),
  Enable = config.IsRecharge,
  EventClick = function(sender, e)
    game:OpenUrl(config.RechargeUrl)
  end
})(tc_right, nil)
local ctrl_cart = Gui.Control({
  Location = Vector2(21, 56),
  Size = Vector2(279, 454),
  Padding = Vector4(0, 8, 6, 8),
  BackgroundColor = white,
  Skin = SkinF.shop_01
})()
local scr_cart = Gui.ScrollableControl({Dock = "kDockFill"})(ctrl_cart, nil)
local fl_price = Gui.FlowLayout({
  ControlAlign = "kAlignMiddle"
})(scr_cart, nil)
local tlbl_online = Gui.TimerLabel({
  Timer = 1,
  Text = "0",
  Visible = false
})(ctrl_shop, nil)
local price_ui = {}
local tip_interface = {
  nil,
  "tip_sys_item",
  "tip_sys_item",
  "tip_sys_item",
  "tip_sys_avatar"
}
local UpdateCartList, UpdateTab = function()
  fl_price.Size = Vector2(244, 35 * #cart_list)
  for i, v in ipairs(cart_list) do
    if not price_ui[i] then
      price_ui[i] = {}
      price_ui[i][1] = Gui.Label({
        Size = Vector2(223, 35),
        FontSize = 16,
        TextPadding = Vector4(8, 0, 0, 0),
        AutoEllipsis = true,
        EventMouseEnter = function(sender, e)
          local item = cart_list[i]
          local szInterface = tip_interface[item.type]
          if item.type == 3 and item.subtype == 111 then
            szInterface = "tip_sys_gift"
          end
          Tip.SetRpc(szInterface, {
            t = item.type,
            sid = item.sid
          })
          Tip.SetUseDescription(false)
          Tip.SetOwner(sender)
        end
      })()
      price_ui[i][2] = Gui.Button({
        Style = "Gui.ButtonCancel",
        Size = Vector2(21, 21),
        ClickAudio = "button",
        EventClick = function(sender, e)
          table.remove(cart_list, i)
          UpdateCartList()
        end
      })()
    end
    if v.type == 5 then
      price_ui[i][1].Text = string.format("%d. %s", i, _L(v.display))
    else
      price_ui[i][1].Text = string.format("%d. %s", i, _L(v.display))
    end
    price_ui[i][1].Parent = fl_price
    price_ui[i][2].Parent = fl_price
  end
  for i = #cart_list + 1, #price_ui do
    local pui = price_ui[i]
    if pui then
      pui[1].Parent = nil
      pui[2].Parent = nil
    end
  end
end, function()
  fl_price.Size = Vector2(244, 35 * #cart_list)
  for i, v in ipairs(cart_list) do
    if not price_ui[i] then
      price_ui[i] = {}
      price_ui[i][1] = Gui.Label({
        Size = Vector2(223, 35),
        FontSize = 16,
        TextPadding = Vector4(8, 0, 0, 0),
        AutoEllipsis = true,
        EventMouseEnter = function(sender, e)
          local item = cart_list[i]
          local szInterface = tip_interface[item.type]
          if item.type == 3 and item.subtype == 111 then
            szInterface = "tip_sys_gift"
          end
          Tip.SetRpc(szInterface, {
            t = item.type,
            sid = item.sid
          })
          Tip.SetUseDescription(false)
          Tip.SetOwner(sender)
        end
      })()
      price_ui[i][2] = Gui.Button({
        Style = "Gui.ButtonCancel",
        Size = Vector2(21, 21),
        ClickAudio = "button",
        EventClick = function(sender, e)
          table.remove(cart_list, i)
          UpdateCartList()
        end
      })()
    end
    if v.type == 5 then
      price_ui[i][1].Text = string.format("%d. %s", i, _L(v.display))
    else
      price_ui[i][1].Text = string.format("%d. %s", i, _L(v.display))
    end
    price_ui[i][1].Parent = fl_price
    price_ui[i][2].Parent = fl_price
  end
  for i = #cart_list + 1, #price_ui do
    local pui = price_ui[i]
    if pui then
      pui[1].Parent = nil
      pui[2].Parent = nil
    end
  end
end
local UpdateTab, BuyAll = function()
  if tc_right.SelectedIndex == 0 then
    ctrl_cart.Parent = nil
    ctrl_avatar.Parent = tc_right
  else
    ctrl_avatar.Parent = nil
    ctrl_cart.Parent = tc_right
  end
end, "tip_sys_item"
local BuyAll, ButtonIcon = function(sender, e, g)
  if #cart_list == 0 then
    MessageBox.ShowError(_T("msgbox_common_num_1359"))
    return
  end
  ShopBalance.list = cart_list
  if tc_buy_st.SelectedIndex == 3 then
    ShopBalance.Show("Buy_type", "freshEquip")
  else
    ShopBalance.Show("Buy_type")
  end
end, "tip_sys_item"

function ButtonIcon(p, icon, text)
  Gui.Label({
    Location = Vector2(4, 9),
    Size = Vector2(137, 48),
    Icon = icon,
    FontSize = 16,
    TextPadding = Vector4(0, 0, 0, 0),
    Text = text,
    IconTextSpace = 0
  })(p, nil)
end

local btn_buy = Gui.Button({
  Style = "ButtonShopBuyAll",
  Location = Vector2(21, 517),
  Size = Vector2(278, 66),
  ClickAudio = "button",
  Text = _T("button_common_Buy_All"),
  EventClick = function(sender, e)
    BuyAll(sender, e, false)
  end
})(tc_right, nil)
ButtonIcon(btn_buy, SkinF.shop_17, "")
local GetBuyT = ButtonIcon
local GetBuyT, GetBuySt = function()
  return buy_t[tc_buy_t.SelectedIndex + 1][1]
end, btn_buy
local GetBuySt, GetBuyStType = function()
  return buy_st[tc_buy_t.SelectedIndex + 1][tc_buy_st.SelectedIndex + 1][1]
end, SkinF.shop_17
local GetBuyStType, GetO = function()
  return buy_st[tc_buy_t.SelectedIndex + 1][tc_buy_st.SelectedIndex + 1][3]
end, ""
local GetO, GetBuyP = function()
  if tc_buy_t.SelectedIndex == 1 and tc_buy_st.SelectedIndex == 0 then
    return filter_t[cmb_filter.SelectedIndex + 1][1]
  end
  return nil
end, _T("button_common_Shopping_Card")
local GetBuyP, UpdateSt = function()
  return pg_buy.CurrIndex
end, _T("button_common_Shopping_Card")

function UpdateSt()
  local v = buy_st[tc_buy_t.SelectedIndex + 1]
  for i = 1, max_st do
    if v[i] then
      tc_buy_st:SetVisible(i - 1, true)
      tc_buy_st:SetText(i - 1, v[i][2])
    else
      tc_buy_st:SetVisible(i - 1, false)
    end
  end
  tc_buy_st.SelectedIndex = st_sel[tc_buy_t.SelectedIndex + 1]
end

local i = 1
local FORCE_LEAD_FRESH_MAN = i
i = i + 1
local FORCE_LEAD_GOING_BUY = i
i = i + 1
local FORCE_LEAD_BUY_DETAIL, Buy = i, _T("button_common_Shopping_Card")
local Buy, Give = function(sender, e, g)
  ShopBalance.list = {}
  ShopBalance.list[1] = shop_list[sender.Index]
  ShopBalance.list[1].isFreshmanEquip = GetBuyStType()
  ShopBalance.give = g
  ShopBalance.Show("Buy_type")
  ForceLead(FORCE_LEAD_BUY_DETAIL)
end, _T("button_common_Shopping_Card")
local Give, ClearPreview = function(sender, e, g)
  ShopGive.Show(shop_list[sender.Index])
end, _T("button_common_Shopping_Card")
local ClearPreview, PreviewWeapon = function()
  lg:PlayAnim("idlea")
  lg:SetWeapon(0, "")
  ComFuc.ClearIndependentTrinket()
  for _, v in ipairs(PersonalInfo.independentTrinket) do
    lg:Set_Independent_Trinket(v.type, v.resource, false, 0, true)
  end
end, _T("button_common_Shopping_Card")
local PreviewWeapon, PreviewAvatar = function(item)
  lg:SetWeapon(item.subtype, item.resource, 0, false)
  gui:PlayAudio("putdown")
end, _T("button_common_Shopping_Card")
local PreviewAvatar, GetPreviewTrinket = function(item)
  gui:PlayAudio("buyavatar")
  ComFuc.DealAvatarPreviewEquip(item.avatar)
end, _T("button_common_Shopping_Card")

function GetPreviewTrinket(index)
  return function(item)
    lg:Set_Independent_Trinket(index, item.resource, false, 0)
    gui:PlayAudio("putdown")
  end
end

local preview = {
  [2] = {},
  [3] = {}
}
for _, v in ipairs({
  1,
  2,
  3,
  4,
  5,
  6,
  10,
  11,
  12,
  13,
  14,
  15,
  16
}) do
  preview[2][v] = {}
  preview[2][v].image = SkinF.shop_19
  preview[2][v].func = PreviewWeapon
end
preview[2][101] = {}
preview[2][101].image = SkinF.shop_19
preview[2][101].func = GetPreviewTrinket(4)
preview[2][102] = {}
preview[2][102].image = SkinF.shop_19
preview[2][102].func = GetPreviewTrinket(1)
preview[2][103] = {}
preview[2][103].image = SkinF.shop_19
preview[2][103].func = GetPreviewTrinket(3)
preview[4] = {}
preview[4].image = SkinF.shop_19
preview[4].func = function(item)
  lg:PlayAnim(item.resource, false, 0.2, 0.2)
  gui:PlayAudio("buyavatar")
end
preview[5] = {}
preview[5].image = SkinF.shop_20
local preview[5].func, GetPreviewImage = PreviewAvatar, preview[5]
local GetPreviewImage, GetPreviewFunc = function(item)
  local pi = preview[item.type]
  if type(pi) == "table" then
    pi = pi.image or pi[item.subtype]
    if type(pi) == "table" then
      pi = pi.image
    end
  end
  return pi
end, SkinF.shop_20

function GetPreviewFunc(item)
  local pf = preview[item.type]
  if type(pf) == "table" then
    pf = pf.func or pf[item.subtype]
    if type(pf) == "table" then
      pf = pf.func
    end
  end
  return pf
end

for i, v in ipairs(bb_ui) do
  v.AvatarIndex = 9 + i
  
  function v.EventIconClick(sender, e)
    local item = shop_list[sender.Index]
    local pf = GetPreviewFunc(item)
    if pf then
      ClearPreview()
      pf(item)
      tc_right.SelectedIndex = 0
      UpdateTab()
    end
  end
  
  function v.EventCartClick(sender, e)
    if LimitMsgError[i] then
      MessageBox.ShowError(LimitMsgError[i])
    else
      tc_right.SelectedIndex = 1
      UpdateTab()
      if #cart_list < 50 then
        local item = {}
        for k, v in pairs(shop_list[sender.Index]) do
          item[k] = v
        end
        item.isFreshmanEquip = GetBuyStType()
        table.insert(cart_list, item)
        UpdateCartList()
      else
        MessageBox.ShowError(_T("msgbox_common_num_1318"))
      end
    end
  end
  
  function v.EventBuyClick(sender, e)
    if LimitMsgError[i] then
      MessageBox.ShowError(LimitMsgError[i])
    else
      Buy(sender, e, false)
    end
  end
  
  function v.EventGiveClick(sender, e)
    Give(sender, e, true)
  end
  
  function v.EventTipActiveChanged(sender, e)
    if sender.TipActive then
      local item = shop_list[sender.Index]
      local szInterface = tip_interface[item.type]
      if item.type == 3 and item.subtype == 111 then
        szInterface = "tip_sys_gift"
      end
      Tip.SetRpc(szInterface, {
        t = item.type,
        sid = item.sid
      })
      Tip.SetUseDescription(false)
      Tip.SetOwner(sender)
      Tip.SetOffset(Vector2(5, 33))
      Tip.SetAlignSize(GetBuyT() == 5 and Vector2(104, 163) or Vector2(80, 80))
      sender.PreviewImage = GetPreviewImage(item)
    else
      Tip.SetOwner(nil)
    end
  end
end
local GetOccupationNA, GetNA = Tip.GetOccupationNA, ipairs(bb_ui)
local GetNA, DealLimitTime = function(lv, o)
  if lv and lv > PushCmd.GetLevel() then
    return true
  end
  return GetOccupationNA(o)
end, ipairs(bb_ui)
local DealLimitTime, DealReverseTime = function(item, LimitTimeKey, IsUse)
  item.LimitTime = LimitTimeKey
  item.UseTimeDown = IsUse
end, preview[2][v]

function DealReverseTime(item, Section, Index)
  item.TimeDownSection = Section
  LimitCountDown.InitShowTime(item.TimeDownSection)
  item.TimeDownIndex = Index
  tlbl_online.Timer = 1
  tlbl_online:Start()
end

local RequestBuyList, UpdateFilter = function()
  pg_buy.PageCount = st_page[tc_buy_t.SelectedIndex + 1][tc_buy_st.SelectedIndex + 1][2]
  pg_buy.CurrIndex = st_page[tc_buy_t.SelectedIndex + 1][tc_buy_st.SelectedIndex + 1][1]
  local args = {}
  args.t = GetBuyT()
  if not args.t then
    args.sellState = GetBuySt()
    args.st = ""
  else
    args.st = GetBuySt()
  end
  args.occupation = GetO()
  args.currency = "1,2,4"
  args.p = GetBuyP()
  for _, v in ipairs(bb_ui) do
    v.Parent = nil
  end
  local n = args.t == 5 and 6 or 8
  args.pageSize = n
  local interface = args.t == 5 and "shop_avatar_list" or "shop_item_list"
  if GetBuyStType() then
    interface = "get_freshman_item_list"
  end
  local t = args.t == 5 and "kBTCard" or "kBTWeapon"
  fl_bb.ControlSpace = args.t == 5 and 3 or 17
  for i = 1, n do
    local bb = bb_ui[i]
    bb.Type = t
    bb.State = "kBSLoading"
    bb.Parent = fl_bb
  end
  shop_list = {}
  rpc.safecall(interface, args, function(data)
    pg_buy.PageCount = data.pages
    LimitMsgError = {}
    if not GetBuyT() then
      if data.page ~= GetBuyP() then
        return
      end
    elseif data.t ~= GetBuyT() or data.st ~= GetBuySt() or data.page ~= GetBuyP() or data.occupation ~= GetO() then
      return
    end
    st_page[tc_buy_t.SelectedIndex + 1][tc_buy_st.SelectedIndex + 1][2] = pg_buy.PageCount
    local n = data.t == 5 and 6 or 8
    shop_list = data.items
    for i = 1, n do
      local item = shop_list[i]
      local v = bb_ui[i]
      if item ~= nil then
        if data.t == 5 then
          ComFuc.SetPersonCardData(item.avatar, 9 + i)
          if item.subtype == 1 then
            item.resource = "humancard"
          elseif item.subtype == 2 then
            item.resource = "herocard"
          end
        end
        v.Index = i
        v.Name = _L(item.display)
        v.Icon = GetIcon(item.resource)
        table.sort(item.price, SortPrice)
        v.LevelImage = nil
        v.Level = nil
        v.Renew = nil
        if item.subtype == 1 then
          if item.avatarLevel then
            v.LevelImage = Gui.Image("ui/skinF/skin_avatarcard_level.tga", Vector4(0, 0, 0, 0))
            v.Level = item.avatarLevel
          end
        elseif item.subtype == 2 and item.avatarLevel then
          v.LevelImage = Gui.Image("ui/skinF/skin_avatarcard_level_hero.tga", Vector4(0, 0, 0, 0))
          v.Level = item.avatarLevel
        end
        v.CurrencyCount = 0
        v.TabNum = buy_st[tc_buy_t.SelectedIndex + 1][tc_buy_st.SelectedIndex + 1][1]
        local currency = {}
        local sell_state = 0
        for ii, vv in ipairs(item.price) do
          currency[vv.currency] = true
          if sell_state == 0 then
            sell_state = vv.sellState
          end
        end
        if sell_state == 8 then
          v.FeatureImage = SkinF.shop_feature[5]
        else
          v.FeatureImage = SkinF.shop_feature[sell_state]
        end
        if item.subtype == 1 then
          v.Style = "BuyBox_01"
        elseif item.subtype == 2 then
          v.Style = "BuyBox_02"
        end
        for ii = 1, 4 do
          if currency[ii] then
            v:AddCurrency(GetCurrencyIcon(ii), GetCurrencyText(ii))
          end
        end
        if item.price[1].unitType == 1 then
          v.Count = _T("tips_lobby_Common_Desc7")
        else
          v.Count = GetCount(item.price[1].unitType, item.price[1].unit)
        end
        if item.price[1].unitType == 4 then
          if item.price[1].isRenew then
            v.Renew = _T("tips_buff_u_can_renew")
          else
            v.Renew = _T("tips_buff_u_cannot_renew")
          end
        end
        if item.type == 5 then
          v.Price = item.price[1].price
        else
          v.Price = _T("UI_lobby_goods_price") .. item.price[1].price
        end
        v.CurrencyIcon = GetCurrencyIcon(item.price[1].currency)
        v.Discounting = item.price[1].rebatePrice
        if data.modulus ~= 0 and v.Discounting == 0 and v.TabNum ~= 8 then
          v.InvalidDiscount = 1
          v.NewPrice = _T("tips_datalist_key_nosale")
          v.NewPriceTextColor = ARGB(255, 62, 26, 1)
        else
          v.InvalidDiscount = 0
        end
        if 0 < v.Discounting then
          v.Price = _T("UI_lobby_original_cost") .. item.price[1].price
          v.NewPrice = _T("UI_lobby_current_price") .. v.Discounting
        end
        if 0 < v.Discounting then
          if item.price[1].isCardPrice then
            v.NewPriceTextColor = ARGB(255, 0, 217, 0)
          else
            v.NewPriceTextColor = ARGB(255, 255, 0, 0)
          end
        end
        local canGive = false
        for _, p in ipairs(item.price) do
          if p.currency == 2 then
            canGive = true
          end
        end
        v:SetBtnGiveState(false)
        for _, p in ipairs(item.price) do
          if p.isGive and canGive then
            v:SetBtnGiveState(true)
            break
          end
        end
        v.NA = GetNA(item.level, item.occupation)
        v.State = "kBSShop"
        v.GradeImage = GetGradeImage(item.grade)
        v.LimitNumTextColor = ARGB(255, 255, 0, 0)
        v.LimitTimeTextColor = ARGB(255, 255, 0, 0)
        if v.TabNum == 8 then
          v.VipIcon = IconsF.vipIcons[item.price[1].vipLevel]
          if 0 < item.price[1].startDateTime and 0 < item.price[1].endDateTime then
            if item.now < item.price[1].startDateTime then
              DealReverseTime(v, (item.price[1].startDateTime - item.now) / 1000, 2)
              DealLimitTime(v, _T("UI_store_xiangouweikaishi"), true)
              if not LimitMsgError[i] then
                LimitMsgError[i] = _T("id_abilities_guanzhuxiangoushijian")
              else
                LimitMsgError[i] = _T("id_abilities_bufuhetiaojian")
              end
            elseif item.now >= item.price[1].endDateTime then
              v.LimitTimeTextColor = ARGB(255, 128, 128, 128)
              DealLimitTime(v, _T("UI_store_xiangouguoqi"), false)
              if not LimitMsgError[i] then
                LimitMsgError[i] = _T("id_abilities_shijianyijieshu")
              else
                LimitMsgError[i] = _T("id_abilities_bufuhetiaojian")
              end
            else
              DealReverseTime(v, (item.price[1].endDateTime - item.now) / 1000, 1)
              DealLimitTime(v, _T("UI_store_shopbuy_time") .. LimitCountDown.SetTimeText(), true)
            end
          else
            DealLimitTime(v, refresh_rate[item.price[1].repeatDuration], false)
          end
          v.LimitNum = string.format(_T("UI_store_shopbuy_times"), item.price[1].playerAccomplishCount, item.price[1].accomplishCount)
          if item.price[1].accomplishCount == 0 then
            v.LimitNum = _T("UI_store_xianliangbuxian")
          elseif 0 < item.price[1].accomplishCount and item.price[1].playerAccomplishCount == 0 then
            v.LimitNumTextColor = ARGB(255, 128, 128, 128)
            if not LimitMsgError[i] then
              LimitMsgError[i] = _T("id_abilities_xianliangshangxian")
            else
              LimitMsgError[i] = _T("id_abilities_bufuhetiaojian")
            end
          end
        end
      else
        v.Index = 0
        v.State = "kBSEmpty"
      end
    end
    if tc_buy_st.SelectedIndex == #buy_st[1] - 1 then
      ForceLead(FORCE_LEAD_GOING_BUY)
    end
  end)
end, function()
  pg_buy.PageCount = st_page[tc_buy_t.SelectedIndex + 1][tc_buy_st.SelectedIndex + 1][2]
  pg_buy.CurrIndex = st_page[tc_buy_t.SelectedIndex + 1][tc_buy_st.SelectedIndex + 1][1]
  local args = {}
  args.t = GetBuyT()
  if not args.t then
    args.sellState = GetBuySt()
    args.st = ""
  else
    args.st = GetBuySt()
  end
  args.occupation = GetO()
  args.currency = "1,2,4"
  args.p = GetBuyP()
  for _, v in ipairs(bb_ui) do
    v.Parent = nil
  end
  local n = args.t == 5 and 6 or 8
  args.pageSize = n
  local interface = args.t == 5 and "shop_avatar_list" or "shop_item_list"
  if GetBuyStType() then
    interface = "get_freshman_item_list"
  end
  local t = args.t == 5 and "kBTCard" or "kBTWeapon"
  fl_bb.ControlSpace = args.t == 5 and 3 or 17
  for i = 1, n do
    local bb = bb_ui[i]
    bb.Type = t
    bb.State = "kBSLoading"
    bb.Parent = fl_bb
  end
  shop_list = {}
  rpc.safecall(interface, args, function(data)
    pg_buy.PageCount = data.pages
    LimitMsgError = {}
    if not GetBuyT() then
      if data.page ~= GetBuyP() then
        return
      end
    elseif data.t ~= GetBuyT() or data.st ~= GetBuySt() or data.page ~= GetBuyP() or data.occupation ~= GetO() then
      return
    end
    st_page[tc_buy_t.SelectedIndex + 1][tc_buy_st.SelectedIndex + 1][2] = pg_buy.PageCount
    local n = data.t == 5 and 6 or 8
    shop_list = data.items
    for i = 1, n do
      local item = shop_list[i]
      local v = bb_ui[i]
      if item ~= nil then
        if data.t == 5 then
          ComFuc.SetPersonCardData(item.avatar, 9 + i)
          if item.subtype == 1 then
            item.resource = "humancard"
          elseif item.subtype == 2 then
            item.resource = "herocard"
          end
        end
        v.Index = i
        v.Name = _L(item.display)
        v.Icon = GetIcon(item.resource)
        table.sort(item.price, SortPrice)
        v.LevelImage = nil
        v.Level = nil
        v.Renew = nil
        if item.subtype == 1 then
          if item.avatarLevel then
            v.LevelImage = Gui.Image("ui/skinF/skin_avatarcard_level.tga", Vector4(0, 0, 0, 0))
            v.Level = item.avatarLevel
          end
        elseif item.subtype == 2 and item.avatarLevel then
          v.LevelImage = Gui.Image("ui/skinF/skin_avatarcard_level_hero.tga", Vector4(0, 0, 0, 0))
          v.Level = item.avatarLevel
        end
        v.CurrencyCount = 0
        v.TabNum = buy_st[tc_buy_t.SelectedIndex + 1][tc_buy_st.SelectedIndex + 1][1]
        local currency = {}
        local sell_state = 0
        for ii, vv in ipairs(item.price) do
          currency[vv.currency] = true
          if sell_state == 0 then
            sell_state = vv.sellState
          end
        end
        if sell_state == 8 then
          v.FeatureImage = SkinF.shop_feature[5]
        else
          v.FeatureImage = SkinF.shop_feature[sell_state]
        end
        if item.subtype == 1 then
          v.Style = "BuyBox_01"
        elseif item.subtype == 2 then
          v.Style = "BuyBox_02"
        end
        for ii = 1, 4 do
          if currency[ii] then
            v:AddCurrency(GetCurrencyIcon(ii), GetCurrencyText(ii))
          end
        end
        if item.price[1].unitType == 1 then
          v.Count = _T("tips_lobby_Common_Desc7")
        else
          v.Count = GetCount(item.price[1].unitType, item.price[1].unit)
        end
        if item.price[1].unitType == 4 then
          if item.price[1].isRenew then
            v.Renew = _T("tips_buff_u_can_renew")
          else
            v.Renew = _T("tips_buff_u_cannot_renew")
          end
        end
        if item.type == 5 then
          v.Price = item.price[1].price
        else
          v.Price = _T("UI_lobby_goods_price") .. item.price[1].price
        end
        v.CurrencyIcon = GetCurrencyIcon(item.price[1].currency)
        v.Discounting = item.price[1].rebatePrice
        if data.modulus ~= 0 and v.Discounting == 0 and v.TabNum ~= 8 then
          v.InvalidDiscount = 1
          v.NewPrice = _T("tips_datalist_key_nosale")
          v.NewPriceTextColor = ARGB(255, 62, 26, 1)
        else
          v.InvalidDiscount = 0
        end
        if 0 < v.Discounting then
          v.Price = _T("UI_lobby_original_cost") .. item.price[1].price
          v.NewPrice = _T("UI_lobby_current_price") .. v.Discounting
        end
        if 0 < v.Discounting then
          if item.price[1].isCardPrice then
            v.NewPriceTextColor = ARGB(255, 0, 217, 0)
          else
            v.NewPriceTextColor = ARGB(255, 255, 0, 0)
          end
        end
        local canGive = false
        for _, p in ipairs(item.price) do
          if p.currency == 2 then
            canGive = true
          end
        end
        v:SetBtnGiveState(false)
        for _, p in ipairs(item.price) do
          if p.isGive and canGive then
            v:SetBtnGiveState(true)
            break
          end
        end
        v.NA = GetNA(item.level, item.occupation)
        v.State = "kBSShop"
        v.GradeImage = GetGradeImage(item.grade)
        v.LimitNumTextColor = ARGB(255, 255, 0, 0)
        v.LimitTimeTextColor = ARGB(255, 255, 0, 0)
        if v.TabNum == 8 then
          v.VipIcon = IconsF.vipIcons[item.price[1].vipLevel]
          if 0 < item.price[1].startDateTime and 0 < item.price[1].endDateTime then
            if item.now < item.price[1].startDateTime then
              DealReverseTime(v, (item.price[1].startDateTime - item.now) / 1000, 2)
              DealLimitTime(v, _T("UI_store_xiangouweikaishi"), true)
              if not LimitMsgError[i] then
                LimitMsgError[i] = _T("id_abilities_guanzhuxiangoushijian")
              else
                LimitMsgError[i] = _T("id_abilities_bufuhetiaojian")
              end
            elseif item.now >= item.price[1].endDateTime then
              v.LimitTimeTextColor = ARGB(255, 128, 128, 128)
              DealLimitTime(v, _T("UI_store_xiangouguoqi"), false)
              if not LimitMsgError[i] then
                LimitMsgError[i] = _T("id_abilities_shijianyijieshu")
              else
                LimitMsgError[i] = _T("id_abilities_bufuhetiaojian")
              end
            else
              DealReverseTime(v, (item.price[1].endDateTime - item.now) / 1000, 1)
              DealLimitTime(v, _T("UI_store_shopbuy_time") .. LimitCountDown.SetTimeText(), true)
            end
          else
            DealLimitTime(v, refresh_rate[item.price[1].repeatDuration], false)
          end
          v.LimitNum = string.format(_T("UI_store_shopbuy_times"), item.price[1].playerAccomplishCount, item.price[1].accomplishCount)
          if item.price[1].accomplishCount == 0 then
            v.LimitNum = _T("UI_store_xianliangbuxian")
          elseif 0 < item.price[1].accomplishCount and item.price[1].playerAccomplishCount == 0 then
            v.LimitNumTextColor = ARGB(255, 128, 128, 128)
            if not LimitMsgError[i] then
              LimitMsgError[i] = _T("id_abilities_xianliangshangxian")
            else
              LimitMsgError[i] = _T("id_abilities_bufuhetiaojian")
            end
          end
        end
      else
        v.Index = 0
        v.State = "kBSEmpty"
      end
    end
    if tc_buy_st.SelectedIndex == #buy_st[1] - 1 then
      ForceLead(FORCE_LEAD_GOING_BUY)
    end
  end)
end

function UpdateFilter()
  if tc_buy_t.SelectedIndex == 1 and tc_buy_st.SelectedIndex == 0 then
    lb_filter.Parent = tc_buy_st
    cmb_filter.Parent = tc_buy_st
  else
    lb_filter.Parent = nil
    cmb_filter.Parent = nil
  end
end

local force_lead_step = 0

function ForceLead(step)
  if bit.band(512, ComFuc.leadList) == 512 or bit.band(1024, ComFuc.leadList) ~= 1024 then
    return
  end
  if tc_buy_t.SelectedIndex ~= 0 then
    tc_buy_t.SelectedIndex = 0
    UpdateSt()
    RequestBuyList()
  end
  if step <= force_lead_step then
    return
  end
  force_lead_step = step
  if step == FORCE_LEAD_FRESH_MAN then
    NewLead.ShowNewLeadHasLock(Vector2(640, 215), Vector2(150, 40), GetUTF8Text("UI_common_Click"), 1)
  elseif step == FORCE_LEAD_GOING_BUY then
    NewLead.ShowNewLeadHasLock(Vector2(328, 323), Vector2(85, 25), GetUTF8Text("UI_common_Task_guide_12"), 1)
  elseif step == FORCE_LEAD_BUY_DETAIL and tc_buy_t.SelectedIndex == 0 and tc_buy_st.SelectedIndex == #buy_st[1] - 1 then
    NewLead.ShowNewLeadHasLock(Vector2(700, 710), Vector2(180, 40), GetUTF8Text("UI_common_Task_guide_13"), 1)
  end
end

function tc_buy_t.EventSelectedChanged(sender, e)
  ClearPreview()
  UpdateFilter()
  if sender.SelectedIndex > -1 then
    tc_buy_st.Parent = sender
  else
    tc_buy_st.Parent = nil
  end
  if "kTriggerMouse" == e.Trigger then
    UpdateSt()
    RequestBuyList()
  end
  tlbl_online:Stop()
end

function cmb_filter.EventItemSelected(sender, e)
  tlbl_online:Stop()
  RequestBuyList()
end

function tc_buy_st.EventSelectedChanged(sender, e)
  ClearPreview()
  UpdateFilter()
  if "kTriggerMouse" == e.Trigger then
    st_sel[tc_buy_t.SelectedIndex + 1] = sender.SelectedIndex
    RequestBuyList()
  end
end

function tc_right.EventSelectedChanged(sender, e)
  if "kTriggerMouse" == e.Trigger then
    UpdateTab()
  end
end

function pg_buy.EventIndexChanged(sender, e)
  st_page[tc_buy_t.SelectedIndex + 1][tc_buy_st.SelectedIndex + 1][1] = sender.CurrIndex
  tlbl_online:Stop()
  RequestBuyList()
end

function tlbl_online.EventTimeUp(sender, e)
  for i = 1, 8 do
    if bb_ui[i].UseTimeDown then
      bb_ui[i].TimeDownSection = LimitCountDown.DealTimeDown(bb_ui[i].TimeDownSection)
      if bb_ui[i].TimeDownIndex == 1 then
        bb_ui[i].LimitTime = _T("UI_store_shopbuy_time") .. LimitCountDown.SetTimeText()
      end
      sender.Timer = 1
      sender:Start()
    end
  end
end

function ClearCart()
  cart_list = {}
  UpdateCartList()
end

function CanSwitch()
  return #cart_list == 0, _T("msgbox_common_num_1280")
end

function SwitchToTab(iIndex)
  tc_buy_t.SelectedIndex = iIndex
  UpdateSt()
  RequestBuyList()
end

local init = false

function Show(p)
  lg:ResetVanRotation()
  lg:SetREId(1)
  lg:SaveInfoToTag()
  if ComFuc.fromSelToLobby then
    ComFuc.fromSelToLobby = false
    init = false
  end
  if tc_buy_t.SelectedIndex >= 0 then
    RequestBuyList()
  end
  ForceLead(FORCE_LEAD_FRESH_MAN)
  if not init then
    tc_buy_t.SelectedIndex = 0
    tc_buy_st.SelectedIndex = 0
    cmb_filter.SelectedIndex = 0
    for i = 1, #buy_t do
      st_sel[i] = 0
    end
    for _, v in ipairs(st_page) do
      for _, vv in ipairs(v) do
        vv[1] = 1
        vv[2] = 1
      end
    end
    UpdateSt()
    RequestBuyList()
    ClearCart()
    tc_right.SelectedIndex = 0
    UpdateTab()
    init = true
  end
  ctrl_shop.Parent = p
end

function Hide()
  ClearPreview()
  lg:LoadInfoByTag()
  ctrl_shop.Parent = nil
end
