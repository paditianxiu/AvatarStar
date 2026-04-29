module("L_ActivityDraw", package.seeall)
local col0 = ComFuc.col0
local colw = ComFuc.colw
local colg = ComFuc.colg
local colt = ComFuc.colt
local ui = Gui.Create()({
  Gui.Control("ctl_root")({
    Dock = "kDockFill",
    BackgroundColor = ARGB(100, 0, 0, 0),
    Gui.Control("ctl_main")({
      Size = Vector2(1100, 600),
      Dock = "kDockCenter",
      BackgroundColor = colw,
      Skin = SkinF.activity_bg,
      ComFuc.ComControl(nil, Vector2(2, 487), Vector2(636, 86), 255, SkinF.activity_line),
      ComFuc.ComControl(nil, Vector2(420, 396), Vector2(660, 95), 255, SkinF.skin_playgame_033),
      ComFuc.ComControl(nil, Vector2(582, 461), Vector2(16, 93), 255, SkinF.skin_playgame_033),
      ComFuc.ComLabel("lbl_name", "", Vector2(405, 24), Vector2(670, 122), 0, 18, colt, "kAlignCenterMiddle"),
      ComFuc.ComLabel("lbl_details", "", Vector2(405, 286), Vector2(668, 177), 0, 16, colt, "kAlignLeftTop"),
      ComFuc.ComLabel("", GetUTF8Text("tips_common_bill_01"), Vector2(100, 20), Vector2(660, 510), 0, 16, colt),
      ComFuc.ComLabel("", GetUTF8Text("tips_common_bill_02"), Vector2(100, 20), Vector2(660, 532), 0, 16, colt),
      ComFuc.ComLabel("lbl_date_begin", "2014-3-27 00:00:00", Vector2(200, 20), Vector2(761, 510), 0, 16, colt),
      ComFuc.ComLabel("lbl_date_end", "2014-3-27 00:00:00", Vector2(200, 20), Vector2(761, 532), 0, 16, colt),
      ComFuc.ComButton("btn_close", nil, Vector2(24, 24), Vector2(1068, 23), 0, false, false, SkinF.lookInfo_002),
      ComFuc.ComButton("btn_web_details", GetUTF8Text("tips_common_bill_03"), Vector2(126, 47), Vector2(945, 510), 18, false, false, SkinF.select_character_038),
      Gui.ListTreeView("ltv_activity_list")({
        Style = "ActiveListTreeView_01",
        Size = Vector2(608, 461),
        Location = Vector2(16, 93)
      })
    })
  })
})
ui.btn_web_details.TextColor = colg
ui.lbl_details.AutoWrap = true
local list = ui.ltv_activity_list
list:DeleteColumns()
list:AddColumn("", 44, "kAlignLeftMiddle")
list:AddColumn("activity_name", 430, "kAlignLeftMiddle")
list:AddColumn("activity_statue", 90, "kAlignRightMiddle")
list.Columns.FontSize = 16

function GetUI()
  return ui
end
