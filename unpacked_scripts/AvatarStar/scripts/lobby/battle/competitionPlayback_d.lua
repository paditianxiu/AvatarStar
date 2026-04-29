module("CompetitionPlayback", package.seeall)
local title_ui = {}
local colw = ComFuc.colw
local colt = ComFuc.colt
ui = Gui.Create()({
  Gui.FlowLayout("reniew_fl")({
    Dock = "kDockFill",
    Align = "kAlignCenterMiddle",
    BackgroundColor = ARGB(128, 0, 0, 0),
    Gui.Control("review_main")({
      Size = Vector2(900, 600),
      BackgroundColor = ARGB(255, 255, 255, 255),
      Skin = SkinF.personalInfo_207,
      ComFuc.ComLabel("contest_detailsTip", GetUTF8Text("tips_pet_worldcup_review_watch"), Vector2(500, 20), Vector2(50, 50), 0, 16, colw, "kAlignLeftMiddle"),
      Gui.TextButton("btn_review")({
        BackgroundColor = ARGB(0, 0, 0, 0),
        TextColor = colt,
        HoverTextColor = ARGB(255, 134, 25, 190),
        Text = GetUTF8Text("20150855555"),
        Location = Vector2(100, 100),
        Size = Vector2(100, 30),
        FontSize = 17
      })
    })
  })
})
Tip.CreateTitle(ui.review_main, title_ui, GetUTF8Text("UI_pet_worldcup_review"))

function title_ui.btn.EventClick(sender, e)
  ui.reniew_fl.Parent = nil
end

function ui.btn_review.EventClick(sender, e)
  local state = ptr_cast(game.CurrentState)
  state:ReplayWatch("2015_10_30_9_5_0_00000.asv", 0)
end

function Show()
  ui.reniew_fl.Parent = gui
end
