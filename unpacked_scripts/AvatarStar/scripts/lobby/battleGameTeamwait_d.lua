module("BattleGameTeamWait", package.seeall)
local colw = ComFuc.colw
local colt = ComFuc.colt
local timeNum = 0
local totalNum = 0
local timer, partilce
local winType = 1
local timerPiece = 1
local mapS = {}
local modeText, ComImageBrowser = {
  [0] = GetUTF8Text("button_common_Random"),
  GetUTF8Text("button_common_King_of_the_Hill"),
  GetUTF8Text("button_common_Domination"),
  GetUTF8Text("button_common_Capture_the_Treasure"),
  GetUTF8Text("button_common_Team_Death_Match")
}, GetUTF8Text("button_common_King_of_the_Hill")

function ComImageBrowser(name, lc)
  return Gui.ImageBrowser(name)({
    Size = Vector2(312, 178),
    Location = lc,
    DisplayRowAndCol = Vector2(1, 1),
    PictureStyle = "Gui.PictureMapInBrowser0",
    Margin = Vector4(0, 0, 0, 0)
  })
end

ui = Gui.Create()({
  ComFuc.ComControl("coverControl2", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(100, 0, 0, 0)),
  Gui.Control("root")({
    Size = Vector2(928, 423),
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_207,
    ComFuc.ComControl(nil, Vector2(902, 297), Vector2(13, 41), 255, SkinF.battle_005),
    ComFuc.ComControl(nil, Vector2(906, 2), Vector2(11, 354), 255, SkinF.battle_024),
    ComImageBrowser("left_map", Vector2(25, 118)),
    ComImageBrowser("right_map", Vector2(591, 118)),
    ComFuc.ComLabel(nil, GetUTF8Text("UI_common_judge_01"), Vector2(900, 24), Vector2(12, 4), 0, 16, colw),
    ComFuc.ComLabel(nil, GetUTF8Text("UI_common_judge_02"), Vector2(237, 24), Vector2(62, 51), 0, 16, colt, "kAlignCenterMiddle"),
    ComFuc.ComLabel(nil, GetUTF8Text("UI_common_judge_03"), Vector2(237, 24), Vector2(628, 51), 0, 16, colt, "kAlignCenterMiddle"),
    ComFuc.ComLabel("tip", GetUTF8Text("UI_common_judge_04"), Vector2(146, 64), Vector2(390, 243), 0, 16, colt, "kAlignCenterMiddle"),
    ComFuc.ComLabel("team_1", "", Vector2(264, 24), Vector2(49, 82), 0, 16, colt, "kAlignCenterMiddle"),
    ComFuc.ComLabel("team_2", "", Vector2(264, 24), Vector2(615, 82), 0, 16, colt, "kAlignCenterMiddle"),
    ComFuc.ComLabel("mode_1", "", Vector2(264, 24), Vector2(40, 306), 0, 16, colt),
    ComFuc.ComLabel("mode_2", "", Vector2(264, 24), Vector2(606, 306), 0, 16, colt),
    ComFuc.ComLabel("time", "", Vector2(322, 24), Vector2(303, 370), 0, 16, colt, "kAlignCenterMiddle"),
    ComFuc.ComControl("pointer", Vector2(108, 108), Vector2(410, 100), 255, SkinF.battle_025[1], false)
  })
})
ui.left_map.LeftBtn.Visible = false
ui.left_map.RightBtn.Visible = false
ui.right_map.LeftBtn.Visible = false
ui.right_map.RightBtn.Visible = false
local ui.tip.AutoWrap, SelectOneWin = true, ui.tip
local SelectOneWin, CloseClockTimer = function()
  local pic1 = ui.left_map:GetDisplayPicture(1, 1)
  local pic2 = ui.right_map:GetDisplayPicture(1, 1)
  if winType == 1 then
    pic2.ForeGroundImage = Icons.PreviewMapsDisable[string.lower(mapS[2])]
  else
    pic1.ForeGroundImage = Icons.PreviewMapsDisable[string.lower(mapS[1])]
  end
end, {
  ComFuc.ComControl("coverControl2", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(100, 0, 0, 0)),
  Gui.Control("root")({
    Size = Vector2(928, 423),
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_207,
    ComFuc.ComControl(nil, Vector2(902, 297), Vector2(13, 41), 255, SkinF.battle_005),
    ComFuc.ComControl(nil, Vector2(906, 2), Vector2(11, 354), 255, SkinF.battle_024),
    ComImageBrowser("left_map", Vector2(25, 118)),
    ComImageBrowser("right_map", Vector2(591, 118)),
    ComFuc.ComLabel(nil, GetUTF8Text("UI_common_judge_01"), Vector2(900, 24), Vector2(12, 4), 0, 16, colw),
    ComFuc.ComLabel(nil, GetUTF8Text("UI_common_judge_02"), Vector2(237, 24), Vector2(62, 51), 0, 16, colt, "kAlignCenterMiddle"),
    ComFuc.ComLabel(nil, GetUTF8Text("UI_common_judge_03"), Vector2(237, 24), Vector2(628, 51), 0, 16, colt, "kAlignCenterMiddle"),
    ComFuc.ComLabel("tip", GetUTF8Text("UI_common_judge_04"), Vector2(146, 64), Vector2(390, 243), 0, 16, colt, "kAlignCenterMiddle"),
    ComFuc.ComLabel("team_1", "", Vector2(264, 24), Vector2(49, 82), 0, 16, colt, "kAlignCenterMiddle"),
    ComFuc.ComLabel("team_2", "", Vector2(264, 24), Vector2(615, 82), 0, 16, colt, "kAlignCenterMiddle"),
    ComFuc.ComLabel("mode_1", "", Vector2(264, 24), Vector2(40, 306), 0, 16, colt),
    ComFuc.ComLabel("mode_2", "", Vector2(264, 24), Vector2(606, 306), 0, 16, colt),
    ComFuc.ComLabel("time", "", Vector2(322, 24), Vector2(303, 370), 0, 16, colt, "kAlignCenterMiddle"),
    ComFuc.ComControl("pointer", Vector2(108, 108), Vector2(410, 100), 255, SkinF.battle_025[1], false)
  })
}
local CloseClockTimer, OnTimer = function()
  if timer then
    game.TimerMgr:RemoveTimer(timer)
    timer = nil
    timeNum = 0
    ui.pointer.Visible = false
    if partilce then
      gui:RemoveParticle(partilce)
      partilce = nil
    end
  end
end, ComFuc.ComControl("coverControl2", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(100, 0, 0, 0))

function OnTimer()
  timeNum = timeNum - 1
  ui.time.Text = GetUTF8Text("msgbox_battlefield_additional_string_023") .. " " .. math.floor(timeNum / timerPiece)
  if timeNum == totalNum - 3 * timerPiece then
    ui.pointer.Visible = true
    SelectOneWin()
  end
  if timeNum <= 0 then
    Hide()
  end
end

function ShowLevel()
  local pic1 = ui.left_map:GetDisplayPicture(1, 1)
  local pic2 = ui.right_map:GetDisplayPicture(1, 1)
  pic1.ForeGroundImage = Icons.PreviewMaps[string.lower(mapS[1])]
  pic2.ForeGroundImage = Icons.PreviewMaps[string.lower(mapS[2])]
  pic1.BeStatic = true
  pic2.BeStatic = true
  ui.time.Text = GetUTF8Text("msgbox_battlefield_additional_string_023") .. " " .. math.floor(timeNum / timerPiece)
  ui.pointer.Skin = SkinF.battle_025[winType]
  if 3 <= totalNum / timerPiece then
    partilce = gui:AddParticle("jinbi_00" .. winType, Vector2(600 + ComFuc.locationChanged, 392), Vector3(0, 1, 0))
  else
    ui.pointer.Visible = true
    SelectOneWin()
  end
end

function Show(msg)
  CloseClockTimer()
  timeNum = msg.Value * timerPiece
  totalNum = msg.Value * timerPiece
  if msg.winTeam == msg.selfTeam then
    winType = 1
  else
    winType = 2
  end
  if msg.selfTeam == 0 then
    ui.team_1.Text = GetUTF8Text(msg.teamName1)
    ui.team_2.Text = GetUTF8Text(msg.teamName2)
    ui.mode_1.Text = modeText[msg.mode1]
    ui.mode_2.Text = modeText[msg.mode2]
    mapS = {
      CreateRoom.map_key_of_map_id[tostring(msg.levelId1)],
      CreateRoom.map_key_of_map_id[tostring(msg.levelId2)]
    }
  else
    ui.team_1.Text = GetUTF8Text(msg.teamName2)
    ui.team_2.Text = GetUTF8Text(msg.teamName1)
    ui.mode_1.Text = modeText[msg.mode2]
    ui.mode_2.Text = modeText[msg.mode1]
    mapS = {
      CreateRoom.map_key_of_map_id[tostring(msg.levelId2)],
      CreateRoom.map_key_of_map_id[tostring(msg.levelId1)]
    }
  end
  ShowLevel()
  timer = game.TimerMgr:AddTimer(1 / timerPiece)
  timer.EventOnTimer = OnTimer
  ui.coverControl2.Parent = gui
  ui.root.Parent = gui
  Gui.Align(ui.root, 0.5, 0.5)
end

function Hide()
  CloseClockTimer()
  ui.root.Parent = nil
  ui.coverControl2.Parent = nil
end
