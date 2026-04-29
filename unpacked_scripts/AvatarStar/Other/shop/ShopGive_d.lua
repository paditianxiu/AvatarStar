module("ShopGive", package.seeall)
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
local CurrentGivedCid
local gmConfigFriendTime = ComFuc.giveTime
local ShopGive = {}
local give_ui = Gui.Create()({
  Gui.FlowLayout("fl_buy")({
    Dock = "kDockFill",
    Align = "kAlignCenterMiddle",
    BackgroundColor = ARGB(128, 0, 0, 0),
    Gui.Control("ctrl_buy")({
      Size = Vector2(407, 332),
      BackgroundColor = white,
      Skin = SkinF.personalInfo_207,
      Gui.BuyBox("bb")({
        Style = "BuyBox_01",
        State = "kBSBalance",
        CanCancel = false,
        Location = Vector2(18, 44)
      }),
      Gui.Control("ctrl_info")({
        Location = Vector2(18, 180),
        Size = Vector2(371, 97),
        BackgroundColor = white,
        Skin = SkinF.personalInfo_208
      }),
      Gui.Button("btn_give")({
        Style = "ButtonShopBuy",
        Location = Vector2(215, 281),
        Size = Vector2(84, 40),
        Text = _T("button_common_Gift")
      }),
      Gui.Button("btn_cancel")({
        Location = Vector2(305, 281),
        Size = Vector2(84, 40),
        Text = _T("button_common_Cancel")
      })
    }),
    Gui.Control("friend_list")({
      Location = Vector2(268, 100),
      Size = Vector2(248, 331),
      BackgroundColor = ARGB(255, 255, 255, 255),
      Skin = SkinF.personalInfo_131,
      Gui.Control({
        Location = Vector2(5, 5),
        Size = Vector2(238, 273),
        BackgroundColor = ARGB(255, 255, 255, 255),
        Skin = SkinF.personalInfo_068,
        Padding = Vector4(5, 6, 5, 6),
        Gui.ListTreeView("list")({
          Dock = "kDockFill",
          Style = "Sociality.FriendsList"
        })
      }),
      Gui.Button("btn_confirm")({
        Location = Vector2(82, 278),
        Size = Vector2(84, 43),
        Text = GetUTF8Text("button_common_OK"),
        FontSize = 16,
        CanMove = true,
        TextColor = crTextColor,
        DisabledTextColor = crDisabledTextColor,
        TextShadowWhenNormal = true,
        TextShadowColor = ARGB(150, 0, 0, 0)
      })
    })
  })
})
local friend_list = give_ui.friend_list
local fl_buy = give_ui.fl_buy
local ctrl_buy = give_ui.ctrl_buy
local bb = give_ui.bb
local ctrl_info = give_ui.ctrl_info
local btn_give = give_ui.btn_give
local btn_cancel = give_ui.btn_cancel
bb.BtnFriend.Visible = true
bb.TbFriend.Visible = true
bb.TbFriend.Readonly = true
local title_ui = {}
Tip.CreateTitle(ctrl_buy, title_ui, _T("button_common_Buy"))
local fl_money, money_ui, my_money_ui = ShopBalance.CreateMoneyUI({2})
fl_money.Parent = ctrl_info
fl_money.Location = Vector2(11, 17)

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
    v.Text = k == c and (p.rebatePrice > 0 and -p.rebatePrice or -p.price) or 0
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
local bb.EventTipActiveChanged, RequestGive = function(sender, e)
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

function RequestGive(item)
  if bb.TbFriend.Text == "" then
    MessageBox.ShowError(_T("msgbox_store_zengsong"))
    return
  end
  if item then
    local args = {
      receiverId = CurrentGivedCid,
      give = string.format("%d,%d,%d,%d;", item.type, item.subtype, item.sid, GetPriceId(item))
    }
    rpc.safecall("shop_give", args, function(data)
      Hide()
      MessageBox.ShowError(_T("msgbox_store_zengsong_chenggong"))
      if Shop then
        Shop.ClearCart()
      end
    end, Hide)
  end
end

function btn_give.EventClick(sender, e)
  RequestGive(item)
end

function btn_cancel.EventClick(sender, e)
  Hide()
end

local FRIEND_TYPE = 2
local MYFRIEND_GROUP = 1
local OFFLINE = 1
local ONLINE = 2
local INGAMING, AddFriendsGroupItem = 3, _T("button_common_Buy")
local AddFriendsGroupItem, RefreshFriendList = function(group_list, online_state, player_level, player_name, player_id)
  local list = group_list
  local root = list.RootItem
  local item
  item = list:AddItem(root, "")
  if tonumber(online_state) == ONLINE then
    item:SetIcon(0, IconsF.SocialityStatusIcons.OnlineA)
  elseif tonumber(online_state) == INGAMING then
    item:SetIcon(0, IconsF.SocialityStatusIcons.PlayingA)
  else
    item:SetIcon(0, IconsF.SocialityStatusIcons.OnlineN)
  end
  list:AddSubItem(item, player_name)
  item:SetTextColor(1, ARGB(255, 255, 255, 255))
  item:SetHighLightTextColor(1, ARGB(255, 62, 26, 1))
  list:AddSubItem(item, player_id)
  list:AddSubItem(item, online_state)
  return item
end, _T("button_common_Buy")

function RefreshFriendList()
  local nIndex = 0
  local pItem
  local chat = ptr_cast(game.ChatConnect)
  if not chat then
    return
  end
  give_ui.list:DeleteAll()
  while true do
    pItem = chat:GetFriendGroupItem(FRIEND_TYPE, MYFRIEND_GROUP, 0, nIndex)
    if not pItem then
      break
    end
    if os.time() - pItem.FriendTime >= gmConfigFriendTime then
      AddFriendsGroupItem(give_ui.list, pItem.Online_state, pItem.Player_level, pItem.Player_name, pItem.PlayerID)
    end
    nIndex = nIndex + 1
  end
end

local bb.BtnFriend.EventClick, tbl_copy = function(sender, e)
  if friend_list.Parent ~= nil then
    friend_list.Parent = nil
  else
    RefreshFriendList()
    friend_list.Parent = fl_buy
  end
end, bb.BtnFriend
local tbl_copy, ShowBuy = function(dst, src)
  local d = dst or {}
  local s = src or {}
  for k, v in pairs(s) do
    d[k] = v
  end
end, function(sender, e)
  if friend_list.Parent ~= nil then
    friend_list.Parent = nil
  else
    RefreshFriendList()
    friend_list.Parent = fl_buy
  end
end
local ShowBuy, ShowFriendList = function(buy_item)
  local item_price = {}
  for k, v in pairs(my_money_ui) do
    v.Text = PushCmd.GetMyMoney(k)
  end
  tbl_copy(item_price, buy_item)
  item_price.price_index = 1
  item_price.type = buy_item.type
  bb.Name = _L(buy_item.display)
  bb.Icon = GetIcon(buy_item.resource)
  bb.GradeImage = GetGradeImage(buy_item.grade)
  bb.Desc = _L(buy_item.description)
  bb.TbFriend.Text = ""
  bb:RemoveAllPrice()
  local pl = {}
  for k, v in pairs(buy_item.price) do
    if v.isGive == true then
      pl[#pl + 1] = v
    end
  end
  item_price.price = pl
  item = item_price
  table.sort(item.price, SortPrice)
  for _, vv in ipairs(item.price) do
    if vv.isGive == true then
      bb:AddPrice(GetPrice(vv))
    end
  end
  bb.PriceIndex = 0
  UpdateMoney()
  RefreshFriendList()
  fl_buy.Parent = gui
end, _T("button_common_Buy")
local ShowFriendList, HideFriendList = function()
  friend_list.Parent = fl_buy
end, _T("button_common_Buy")

function HideFriendList()
  friend_list.Parent = nil
end

function Show(buy_item)
  CommonUtility.InitLtvHeader(give_ui.list, {
    {
      "",
      32,
      "kAlignLeftMiddle"
    },
    {
      "",
      160,
      "kAlignLeftMiddle"
    },
    {
      "",
      1,
      "kAlignLeftMiddle"
    },
    {
      "",
      1,
      "kAlignLeftMiddle"
    }
  })
  ShowBuy(buy_item)
end

callback = nil

function Hide()
  fl_buy.Parent = nil
  if callback then
    callback()
    callback = nil
  end
end

function give_ui.list.EventDoubleClick(sender, e)
  local item = sender.SelectedItem
  if item then
    bb.TbFriend.Text = item:GetText(1)
    CurrentGivedCid = item:GetText(2)
    HideFriendList()
  end
end

function give_ui.btn_confirm.EventClick(sender, e)
  local sel_item = give_ui.list.SelectedItem
  if sel_item then
    bb.TbFriend.Text = sel_item:GetText(1)
    CurrentGivedCid = sel_item:GetText(2)
  end
  HideFriendList()
end

return ShopGive
