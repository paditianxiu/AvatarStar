module("LobbyStartGame", package.seeall)
btn_1_Skin = Gui.ButtonSkin({
  BackgroundImage = Gui.Image("ui/skinF/skin_playgame_bg30.tga", Vector4(70, 0, 70, 0))
})
btn_2_Skin = Gui.ButtonSkin({
  BackgroundImage = Gui.Image("ui/skinF/skin_playgame_bg29.tga", Vector4(70, 0, 70, 0))
})
btn_3_Skin = Gui.ButtonSkin({
  BackgroundImage = Gui.Image("ui/skinF/skin_playgame_bg36.tga", Vector4(70, 0, 70, 0))
})
btn_4_Skin = Gui.ButtonSkin({
  BackgroundImage = Gui.Image("ui/skinF/skin_playgame_bg37.tga", Vector4(70, 0, 70, 0))
})
ui = Gui.Create()({
  Gui.Control("main")({
    Size = Vector2(1142, 694),
    ComFuc.ComControl("main_mid", Vector2(1128, 645), Vector2(7, 45), 255, SkinF.personalInfo_098),
    ComFuc.ComControl("item_di_title", Vector2(1120, 33), Vector2(12, 32), 255, SkinF.battle_020[6]),
    Gui.Button("btn_main_1")({
      Size = Vector2(354, 67),
      Location = Vector2(386, 11),
      Skin = btn_1_Skin,
      Enable = false,
      Gui.Label("lbl_game_type")({
        Location = Vector2(30, 13),
        Size = Vector2(294, 26),
        BackgroundColor = ARGB(0, 0, 0, 0),
        Text = GetUTF8Text("button_common_Arena"),
        TextColor = ARGB(255, 62, 26, 1),
        TextAlign = "kAlignCenterMiddle",
        FontSize = 18
      })
    })
  })
})

function SetTitlePart(is_change)
  if is_change then
    ui.main_mid.Location = Vector2(7, 29)
    ui.btn_main_1.Size = Vector2(306, 58)
    ui.btn_main_1.Location = Vector2(416, 0)
    ui.lbl_game_type.Size = Vector2(260, 20)
    ui.main_mid.Size = Vector2(1128, 664)
    ui.item_di_title.Size = Vector2(1120, 33)
    ui.item_di_title.Location = Vector2(12, 32)
    ui.item_di_title.Visible = true
  else
    ui.main_mid.Location = Vector2(7, 45)
    ui.btn_main_1.Size = Vector2(354, 67)
    ui.btn_main_1.Location = Vector2(386, 11)
    ui.lbl_game_type.Size = Vector2(294, 26)
    ui.main_mid.Size = Vector2(1128, 645)
    ui.item_di_title.Visible = false
    ui.item_di_title.Size = Vector2(1118, 40)
    ui.item_di_title.Location = Vector2(12, 50)
  end
end

function ChangeBackMusic()
  if game.IsjoinedBattle == 0 then
    game:PlayAudioMusic(0)
  else
    game:PlayAudioMusic(6)
  end
end

function SelectMainBtn(i)
  print("SelectMainBtn i=" .. i)
  if i == 1 then
    if ComFuc.isInRoom then
    else
      SetTitlePart(true)
      ui.lbl_game_type.Text = GetUTF8Text("button_common_Arena")
      ui.btn_main_1.Skin = btn_4_Skin
      if Expedition then
        Expedition.Hide()
      end
      if LobbyPlayGame then
        LobbyPlayGame.Hide()
      end
      if CompetitionSystem then
        CompetitionSystem.Hide()
      end
      LobbyBattleGame.Show(ui.main_mid)
    end
  elseif i == 2 then
    if ComFuc.isReadyStart or ComFuc.isReadyMatch then
      MessageBox.ShowWithConfirmCancel(GetUTF8Text("msgbox_common_num_1187"), function()
        SetTitlePart(false)
        ui.lbl_game_type.Text = GetUTF8Text("button_common_Freestyle_Combat")
        ui.btn_main_1.Skin = btn_2_Skin
        LobbyBattleGame.OnCloseWaitting(true)
        LobbyBattleGame.CloseTeamMatch(true)
        if LobbyBattleGame then
          LobbyBattleGame.Hide()
        end
        if Expedition then
          Expedition.Hide()
        end
        if CompetitionSystem then
          CompetitionSystem.Hide()
        end
        game.IsjoinedBattle = 1
        ChangeBackMusic()
        LobbyPlayGame.Show(ui.main_mid)
      end)
    else
      SetTitlePart(false)
      ui.lbl_game_type.Text = GetUTF8Text("button_common_Freestyle_Combat")
      ui.btn_main_1.Skin = btn_2_Skin
      if LobbyBattleGame then
        LobbyBattleGame.Hide()
      end
      if Expedition then
        Expedition.Hide()
      end
      if CompetitionSystem then
        CompetitionSystem.Hide()
      end
      game.IsjoinedBattle = 1
      ChangeBackMusic()
      LobbyPlayGame.Show(ui.main_mid)
      LobbyPlayGame.SwitchRoomListPanel()
      LobbyPlayGame.RequestRoomList()
    end
  elseif i == 3 then
    SetTitlePart(false)
    ui.lbl_game_type.Text = GetUTF8Text("UI_lobby_explore_mode")
    ui.btn_main_1.Skin = btn_1_Skin
    if LobbyBattleGame then
      LobbyBattleGame.Hide()
    end
    if LobbyPlayGame then
      LobbyPlayGame.Hide()
    end
    if CompetitionSystem then
      CompetitionSystem.Hide()
    end
    Expedition.Show(ui.main_mid)
  else
    SetTitlePart(true)
    ui.lbl_game_type.Text = GetUTF8Text("UI_pet_as_worldcup")
    ui.btn_main_1.Skin = btn_1_Skin
    ui.item_di_title.Visible = false
    if LobbyBattleGame then
      LobbyBattleGame.Hide()
    end
    if LobbyPlayGame then
      LobbyPlayGame.Hide()
    end
    if Expedition then
      Expedition.Hide()
    end
    if not CompetitionSystem then
      require("battle/competitionSystem.lua")
    end
    CompetitionSystem.Show(ui.main_mid)
  end
end

function CanSwitch()
  return true, GetUTF8Text("msgbox_common_num_1398")
end

function Show(winRoot)
  ui.main.Parent = winRoot
end

function Hide()
  ui.main.Parent = nil
end
