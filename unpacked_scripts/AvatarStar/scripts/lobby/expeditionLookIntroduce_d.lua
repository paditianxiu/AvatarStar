module("ExpeditionLookIntroduce", package.seeall)
local colw = ComFuc.colw
local colt = ComFuc.colt
pic = nil
ui = Gui.Create()({
  Gui.Control("main")({
    Size = Vector2(658, 550),
    BackgroundColor = colw,
    Skin = SkinF.skin_playgame_030_2,
    ComFuc.ComButton("close", nil, Vector2(24, 24), Vector2(626, 4), 0, false, false, SkinF.lookInfo_002),
    ComFuc.ComLabel(nil, GetUTF8Text("button_lobby_map_introduced"), Vector2(136, 16), Vector2(268, 31), 0, 16, colt, "kAlignCenterMiddle"),
    ComFuc.ComTextArea("info_text", Vector2(581, 191), Vector2(39, 310), 16, colw, 3000),
    Gui.ImageBrowser("ib_map")({
      Location = Vector2(170, 76),
      Size = Vector2(330, 190),
      DisplayRowAndCol = Vector2(1, 1),
      PictureStyle = "Gui.PictureMapInBrowser0",
      Margin = Vector4(0, 0, 0, 0)
    })
  }),
  ComFuc.ComControl("coverControl2", Vector2(1600, 1200), Vector2(0, 0), 0)
})
ui.ib_map.LeftBtn.Visible = false
ui.ib_map.RightBtn.Visible = false
ui.info_text.Readonly = true

function ui.close.EventClick(sender, e)
  Hide()
end

function Show(levelId)
  if not levelId then
    Hide()
  else
    pic = ui.ib_map:GetDisplayPicture(1, 1)
    pic.Highlighted = true
    pic.Text = ExpeditionRoom.mapInfo.Text
    pic.ForeGroundImage = ExpeditionRoom.mapInfo.ForeGroundImage
    pic.BeStatic = ExpeditionRoom.mapInfo.BeStatic
    
    function pic.EventClick(sender, e)
      pic.Highlighted = true
    end
    
    ui.coverControl2.Parent = gui
    ui.main.Parent = gui
    Gui.Align(ui.main, 0.5, 0.5)
  end
end

function Hide()
  ui.coverControl2.Parent = nil
  ui.main.Parent = nil
end
