module("AHMain", package.seeall)
if not AHTab0 then
  require("ah_tab0.lua")
end
if not AHTab1 then
  require("ah_tab1.lua")
end
if not AHTab2 then
  require("ah_tab2.lua")
end
if not AHTab3 then
  require("ah_tab3.lua")
end
local _T = Tip._T
local a_text = {
  _T("button_common_Browse"),
  _T("button_common_Register"),
  _T("button_common_Auction"),
  _T("UI_store_AH_mainUI_blank_38")
}
local n_np = -1
if config then
  n_np = config:GetNP()
  if n_np == 2 then
    a_text[4] = nil
  end
end
local tc_auction = Gui.TabControl({
  Style = "TabControl_03",
  Location = Vector2(7, 5),
  Size = Vector2(1128, 685),
  ClickAudio = "menu2nd"
})()
for _, v in ipairs(a_text) do
  tc_auction:AddItem(v)
end
local current_tab = AHTab0
local tab = {
  AHTab0,
  AHTab1,
  AHTab2,
  AHTab3
}
local SetIndex, UpdateTab = function(index)
  if index < #tab and 0 <= index then
    tc_auction.SelectedIndex = index
  end
end, function(index)
  if index < #tab and 0 <= index then
    tc_auction.SelectedIndex = index
  end
end

function UpdateTab()
  current_tab.Hide()
  local index = tc_auction.SelectedIndex
  current_tab = tab[index + 1]
  current_tab.Show(tc_auction)
end

function tc_auction.EventSelectedChanged(sender, e)
  if "kTriggerMouse" == e.Trigger then
    UpdateTab()
  end
end

function CanSwitch()
  return true, _T("msgbox_common_num_1398")
end

tc_auction.SelectedIndex = 0

function Init()
  tc_auction.SelectedIndex = 0
  AHTab0.Reset()
end

function Active()
  return tc_auction.Parent ~= nil
end

function Show(p)
  UpdateTab()
  tc_auction.Parent = p
end

function Hide()
  tc_auction.Parent = nil
end
