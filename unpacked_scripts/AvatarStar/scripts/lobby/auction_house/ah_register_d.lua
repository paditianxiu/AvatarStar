module("AHRegister", package.seeall)
local _T = Tip._T
local _L = Tip._L
local _LL = Tip._LL
local _Value = Tip._Value
local _M = Tip._M
local format = string.format
local white = ARGB(255, 255, 255, 255)
local brown = ARGB(255, 62, 26, 1)
local GetIcon = Tip.GetIcon
local GetGradeImage = Tip.GetGradeImage
local args = {}
local tax = 0
local fee = 0
local tkToGpRate = 1
local register_item
local fl_register = Gui.FlowLayout({
  Dock = "kDockFill",
  Align = "kAlignCenterMiddle",
  ControlSpace = 10,
  BackgroundColor = ARGB(128, 0, 0, 0)
})()
local ctrl_register = Gui.Control({
  Size = Vector2(888, 510),
  BackgroundColor = white,
  Skin = SkinF.personalInfo_207
})(fl_register, nil)
local title_ui = {}
Tip.CreateTitle(ctrl_register, title_ui, _T("button_common_Register"))

function title_ui.btn.EventClick(sender, e)
  Hide()
end

local ctrl_bg = Gui.Control({
  Location = Vector2(8, 51),
  Size = Vector2(294, 394),
  BackgroundColor = white,
  Skin = SkinF.personalInfo_131
})(ctrl_register, nil)
local tip_player_interface = {
  nil,
  "tip_player_item",
  "tip_player_item",
  "tip_player_item",
  "tip_player_avatar",
  "tip_player_avatar"
}
local cb = Gui.CartBox({
  Location = Vector2(118, 34),
  Size = Vector2(80, 80),
  CONTROL_BALLOON_FRAME_DURATION = 1,
  Skin = SkinF.auction_07,
  EventMouseEnter = function(sender, e)
    if sender.Icon then
      Tip.SetRpc(tip_player_interface[args.t], {
        t = args.t,
        pid = args.pid
      })
      Tip.SetUseDescription(false)
      Tip.SetOwner(sender)
    end
  end
})(ctrl_bg, nil)
local ctrl_money = Gui.Control({
  Location = Vector2(10, 146),
  Size = Vector2(274, 234),
  BackgroundColor = white,
  Skin = SkinF.battle_005
})(ctrl_bg, nil)
Gui.Label({
  Location = Vector2(12, 15),
  Size = Vector2(107, 26),
  FontSize = 16,
  TextColor = brown,
  Text = _T("UI_store_AH_mainUI_blank_24")
})(ctrl_money, nil)
local lb_average = Gui.Label({
  Location = Vector2(119, 15),
  Size = Vector2(110, 26),
  FontSize = 16,
  TextColor = brown,
  TextAlign = "kAlignRightMiddle"
})(ctrl_money, nil)
Gui.Label({
  Location = Vector2(229, 13),
  Size = Vector2(30, 30),
  Icon = IconsF.TkIcon
})(ctrl_money, nil)
Gui.Label({
  Location = Vector2(12, 47),
  Size = Vector2(97, 26),
  FontSize = 16,
  TextColor = brown,
  Text = _T("UI_common_Start_Price")
})(ctrl_money, nil)
local txb_reserve_price = Gui.Textbox({
  Location = Vector2(119, 47),
  Size = Vector2(140, 26),
  Number = true,
  MaxLength = 9,
  FontSize = 16,
  CONTROL_BALLOON_FRAME_DURATION = 1
})(ctrl_money, nil)
Gui.Label({
  Location = Vector2(12, 79),
  Size = Vector2(97, 26),
  FontSize = 16,
  TextColor = brown,
  Text = _T("tips_common_additional_tips14")
})(ctrl_money, nil)
local txb_fixed_price = Gui.Textbox({
  Location = Vector2(119, 79),
  Size = Vector2(140, 26),
  Number = true,
  MaxLength = 9,
  FontSize = 16,
  CONTROL_BALLOON_FRAME_DURATION = 1
})(ctrl_money, nil)
Gui.Label({
  Location = Vector2(12, 111),
  Size = Vector2(97, 26),
  FontSize = 16,
  TextColor = brown,
  Text = _T("UI_common_Auction_Period")
})(ctrl_money, nil)
local cmb_time = Gui.ComboBox({
  Location = Vector2(119, 111),
  Size = Vector2(140, 26)
})(ctrl_money, nil)
Gui.Label({
  Location = Vector2(10, 144),
  Size = Vector2(254, 2),
  BackgroundColor = white,
  Skin = SkinF.auction_06
})(ctrl_money, nil)
Gui.Label({
  Location = Vector2(12, 155),
  Size = Vector2(97, 26),
  FontSize = 16,
  TextColor = brown,
  Text = _T("UI_store_AH_mainUI_blank_28")
})(ctrl_money, nil)
local lb_tax = Gui.Label({
  Location = Vector2(119, 155),
  Size = Vector2(110, 26),
  FontSize = 16,
  TextColor = brown,
  TextAlign = "kAlignRightMiddle"
})(ctrl_money, nil)
Gui.Label({
  Location = Vector2(229, 153),
  Size = Vector2(30, 30),
  Icon = IconsF.TkIcon
})(ctrl_money, nil)
Gui.Label({
  Location = Vector2(12, 187),
  Size = Vector2(97, 26),
  FontSize = 16,
  TextColor = brown,
  Text = _T("UI_common_Admin_Fee")
})(ctrl_money, nil)
local lb_fee = Gui.Label({
  Location = Vector2(119, 187),
  Size = Vector2(110, 26),
  FontSize = 16,
  TextColor = brown,
  TextAlign = "kAlignRightMiddle"
})(ctrl_money, nil)
Gui.Label({
  Location = Vector2(229, 185),
  Size = Vector2(30, 30),
  Icon = IconsF.GpIcon
})(ctrl_money, nil)
local btn_register, UpdateExpense = Gui.Button({
  Location = Vector2(77, 454),
  Size = Vector2(182, 40),
  Text = _T("UI_store_AH_mainUI_blank_23")
})(ctrl_register, nil), ctrl_register

function UpdateExpense()
  local c = cb.Count > 0 and cb.Count or 1
  local p = tonumber(txb_reserve_price.Text)
  if cb.Icon and p then
    lb_tax.Text = string.format("%d%%", tax * 100)
    lb_fee.Text = string.format("%d", math.ceil(math.ceil(p * 0.01) * fee))
  else
    lb_tax.Text = ""
    lb_fee.Text = ""
  end
end

function txb_reserve_price.EventTextChanged(sender, e)
  sender:CancelBalloon()
  UpdateExpense()
end

function SetArgs(t, p, ps, s, item)
  cb:CancelBalloon()
  register_item = item
  args.t = t
  args.p = p
  args.s = ps
  args.slot = s
  args.pid = item.pid
  if t == 5 then
    cb.Icon = GetIcon(item.subType == 1 and "humancard" or item.subType == 2 and "herocard")
  else
    cb.Icon = GetIcon(item.resource)
  end
  cb.GradeImage = GetGradeImage(item.grade)
  cb.PlusLevel = item.refitLevel
  cb.Level = tostring(cb.PlusLevel)
  cb.PlusLevelBg = Tip.GetLevelImageBg(cb.PlusLevel)
  local count = item.unitType == 3 and item.quantity or 1
  cb.Count = count
  rpc.safecall("auction_value", {
    t = t,
    p = p,
    slot = s,
    s = ps,
    currency = 4
  }, function(data)
    lb_average.Text = data.averagePrice
    tax = data.tax
    fee = data.fee
    temp_gpToTk = data.gpToTk
    if temp_gpToTk <= 0 then
      temp_gpToTk = 10000
    end
    tkToGpRate = 10000 / temp_gpToTk
    UpdateExpense()
  end)
  txb_reserve_price.Focused = true
end

cmb_time:AddItem(_T("UI_store_mainUI_blank_52"))
cmb_time:AddItem(_T("UI_store_mainUI_blank_53"))
local cmb_time.SelectedIndex, CheckArgs = 0, cmb_time.AddItem
local CheckArgs, Reset = function()
  if not cb.Icon then
    cb:Balloon(_T("tips_lobby_Common_Desc30"))
    return false
  end
  args.duration = cmb_time.SelectedIndex + 1
  local p = tonumber(txb_reserve_price.Text)
  if p == nil then
    txb_reserve_price:Balloon(_T("msgbox_common_num_1339"))
    txb_reserve_price.Focused = true
    return false
  end
  args.reservePrice = p
  args.fixedPrice = tonumber(txb_fixed_price.Text)
  return true
end, cmb_time

function Reset()
  cb.Icon = nil
  cb.GradeImage = nil
  cb.Count = 0
  cb.GradeImage = nil
  cb.PlusLevel = 0
  lb_average.Text = ""
  txb_reserve_price.Text = ""
  txb_fixed_price.Text = ""
  cmb_time.SelectedIndex = 0
  lb_tax.Text = ""
  lb_fee.Text = ""
  Tip.SetOwner(nil)
end

local cb.EventClick, Register = function(sender, e)
  Reset()
end, function(sender, e)
  Reset()
end

function Register()
  if CheckArgs() then
    MessageBox.ShowWithConfirmCancel(_M(format("msgbox_store_AH_019,%d,%s,%s,%s", cb.Count, register_item.isSys and _L(register_item.display) or _LL(register_item.display), lb_fee.Text, lb_tax.Text), register_item.type == 5 and bit.bshift(1, 2) or 0), function()
      rpc.safecall("auction_start", args, function(data)
        Reset()
        MessageBox.ShowError(_T("msgbox_common_num_1389"))
        UpdateStorageList()
        ComFuc.TestIsFinishOneTask(1022)
      end)
    end)
  end
end

function btn_register.EventClick(sender, e)
  Register()
end

local callback

function Show(cbk)
  callback = cbk
  Reset()
  if not MailDepot then
    require("../mailDepot.lua")
  end
  MailDepot.ShowAction(ctrl_register, Vector2(298, 0))
  title_ui.lb.Parent = ctrl_register
  fl_register.Parent = gui
end

function Hide()
  if callback then
    callback()
  end
  fl_register.Parent = nil
end
