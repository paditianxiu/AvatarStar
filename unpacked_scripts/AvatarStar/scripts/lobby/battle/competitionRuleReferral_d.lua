module("RuleReferral", package.seeall)
local _T = GetUTF8Text
local white = Tip.white
local competition_ruleType = {
  _T("UI_pet_paiweisaiguize"),
  _T("UI_pet_fuhuosaiguize"),
  _T("UI_pet_juesaiguize")
}
local fl_Rule = Gui.FlowLayout({
  Dock = "kDockFill",
  Align = "kAlignCenterMiddle",
  BackgroundColor = ARGB(128, 0, 0, 0)
})()
local ctrl_balance = Gui.Control({
  Size = Vector2(966, 635),
  BackgroundColor = white,
  Skin = SkinF.personalInfo_207
})(fl_Rule, nil)
local title_ui = {}
Tip.CreateTitle(ctrl_balance, title_ui, _T("UI_pet_guizejieshao"))

function title_ui.btn.EventClick(sender, e)
  Hide()
end

local rule_caption = Gui.Label({
  Size = Vector2(300, 45),
  Location = Vector2(333, 50),
  Text = _T("UI_pet_paiweisaiguize"),
  BackgroundColor = ARGB(0, 255, 255, 255),
  FontSize = 25,
  TextColor = ARGB(255, 62, 26, 1),
  TextAlign = "kAlignCenterMiddle"
})(ctrl_balance, nil)
local rule_content = Gui.TextArea(name)({
  Style = "Mail.TextArea",
  Size = Vector2(926, 500),
  Location = Vector2(20, 100),
  Text = "kan shen me kan !",
  FontSize = 16,
  TextColor = white,
  MaxLength = 3000,
  Readonly = true
})(ctrl_balance, nil)

function Show(rule_type)
  rule_caption.Text = competition_ruleType[rule_type]
  fl_Rule.Parent = gui
end

function Hide()
  fl_Rule.Parent = nil
end
