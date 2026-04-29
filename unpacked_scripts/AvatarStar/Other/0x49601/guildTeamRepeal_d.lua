module("GuildTeamRepeal", package.seeall)
local white = Tip.white
local fl_guild = Gui.FlowLayout({
  Dock = "kDockFill",
  Align = "kAlignCenterMiddle",
  BackgroundColor = ARGB(128, 0, 0, 0)
})()
local ctrl_guild = Gui.Control({
  Size = Vector2(300, 370),
  BackgroundColor = white,
  Skin = SkinF.personalInfo_207
})(fl_guild, nil)
local title_ui = {}
Tip.CreateTitle(ctrl_guild, title_ui, "")

function title_ui.btn.EventClick(sender, e)
  Hide()
end

local ctrl_list = Gui.Control({
  Size = Vector2(280, 280),
  Location = Vector2(9, 33),
  Skin = SkinF.personalInfo_068,
  BackgroundColor = white
})(ctrl_guild, nil)
local team_list = Gui.ListTreeView({
  Dock = "kDockFill",
  Style = "Sociality.FriendsList"
})(ctrl_list, nil)
local btn_ok = Gui.Button({
  Size = Vector2(70, 34),
  Location = Vector2(65, 320),
  Text = GetUTF8Text("button_common_OK")
})(ctrl_guild, nil)
local btn_cancel = Gui.Button({
  Size = Vector2(70, 34),
  Location = Vector2(175, 320),
  Text = GetUTF8Text("button_common_Cancel")
})(ctrl_guild, nil)

function Show()
  fl_guild.Parent = gui
end

function Hide()
  fl_guild.Parent = nil
end
