module("LockItem", package.seeall)
LockDetailData = nil
UnlockDetailData = nil
ui_unlock = Gui.Create()({
  Gui.Control("ctl_root")({
    Dock = "kDockFill",
    BackgroundColor = ARGB(128, 0, 0, 0),
    Gui.Control("main")({
      Size = Vector2(398, 307),
      Dock = "kDockCenter",
      BackgroundColor = ComFuc.colw,
      Skin = SkinF.personalInfo_207,
      ComFuc.ComLabel(nil, GetUTF8Text("UI_avatar_avatar_UI_06"), Vector2(332, 24), Vector2(12, 4), 0, 16, ComFuc.colw),
      ComFuc.ComButton("quit_button", nil, Vector2(24, 24), Vector2(366, 4), 16, false, false, SkinF.lookInfo_002),
      Gui.Control("warning_background")({
        Size = Vector2(368, 135),
        Location = Vector2(15, 35),
        BackgroundColor = ARGB(255, 255, 255, 255),
        Skin = SkinF.battle_005,
        Gui.Label("warning")({
          Size = Vector2(338, 40),
          Location = Vector2(15, 10),
          TextColor = ARGB(255, 82, 54, 44),
          FontSize = 16,
          AutoWrap = true
        })
      }),
      ComFuc.ComLabel(nil, GetUTF8Text("tips_common_unlock_cost"), Vector2(70, 20), Vector2(30, 183), 0, 16, ARGB(255, 82, 54, 44)),
      Gui.Control("check_control")({
        Size = Vector2(130, 32),
        Location = Vector2(110, 179),
        Gui.Control("check_bg_gold")({
          Skin = SkinF.avatar_main_086,
          Location = Vector2(10, 0),
          Size = Vector2(110, 32),
          BackgroundColor = ComFuc.colw
        }),
        Gui.Control("gold")({
          Location = Vector2(0, 0),
          Size = Vector2(122, 31),
          Gui.Control("check_gold")({
            Skin = SkinF.avatar_main_088[1],
            Location = Vector2(10, 1),
            Size = Vector2(30, 30),
            BackgroundColor = ComFuc.colw
          }),
          ComFuc.ComLabel("check_label_gold", nil, Vector2(78, 24), Vector2(34, 6), 0, 16, ComFuc.coly, "kAlignRight")
        })
      }),
      ComFuc.ComLabel(nil, GetUTF8Text("msgbox_lobby_confirm_unlock"), Vector2(200, 20), Vector2(30, 219), 0, 16, ARGB(255, 82, 54, 44)),
      ComFuc.ComButton("Unlock_button", GetUTF8Text("UI_social_punish_050_title_mainpage"), Vector2(90, 45), Vector2(85, 247), 16, false, false),
      ComFuc.ComButton("close_button", GetUTF8Text("button_common_Cancel"), Vector2(90, 45), Vector2(223, 247), 16, false, false)
    })
  })
})

function DealItemUnlockDetail(data)
  UnlockDetailData = data
  ui_unlock.check_control.Visible = true
  ui_unlock.check_bg_gold.Visible = true
  ui_unlock.gold.Visible = true
  for i = 1, 3 do
    if data.itemLockMap[i].property == "unbindGP" then
      ui_unlock.check_label_gold.Text = data.itemLockMap[i].value
    end
  end
  ui_unlock.warning.AutoWrap = true
  for i = 1, 3 do
    if data.itemLockMap[i].property == "lockTime" then
      local x = Tip.GetLeftTime(data.itemLockMap[i].value * 60 * 60)
      ui_unlock.warning.Text = GetMatchedUTF8Text("msgbox_lobby_start_unlock" .. "," .. x)
    end
  end
  ShowUnlockDialog()
end

function ShowUnlockDialog()
  ui_unlock.ctl_root.Parent = gui
end

function HideUnlockDialog()
  ui_unlock.ctl_root.Parent = nil
  UnlockDetailData = nil
end

function ui_unlock.close_button.EventClick(sender, e)
  HideUnlockDialog()
end

function ui_unlock.quit_button.EventClick(sender, e)
  HideUnlockDialog()
end

function DealItemUnlock(data)
  PersonalInfo.rpc_storage_storage_list(PersonalInfo.ui.pb_depot.CurrIndex)
  HideUnlockDialog()
end

function ui_unlock.Unlock_button.EventClick(sender, e)
  rpc.safecall("player_item_lock", {
    pid = PersonalInfo.menDt.pid,
    l = 0,
    t = PersonalInfo.depotCurr + 1,
    lockState = PersonalInfo.menDt.isLock
  }, DealItemUnlock, HideUnlockDialog)
end

ui_lock = Gui.Create()({
  Gui.Control("ctl_root")({
    Dock = "kDockFill",
    BackgroundColor = ARGB(128, 0, 0, 0),
    Gui.Control("main")({
      Size = Vector2(398, 307),
      Dock = "kDockCenter",
      BackgroundColor = ComFuc.colw,
      Skin = SkinF.personalInfo_207,
      ComFuc.ComLabel(nil, GetUTF8Text("UI_avatar_avatar_UI_06"), Vector2(332, 24), Vector2(12, 4), 0, 16, ComFuc.colw),
      ComFuc.ComButton("quit_button", nil, Vector2(24, 24), Vector2(366, 4), 16, false, false, SkinF.lookInfo_002),
      Gui.Control("warning_background")({
        Size = Vector2(368, 135),
        Location = Vector2(15, 35),
        BackgroundColor = ARGB(255, 255, 255, 255),
        Skin = SkinF.battle_005,
        Gui.Label("warning")({
          Size = Vector2(338, 90),
          Location = Vector2(15, 10),
          TextColor = ARGB(255, 82, 54, 44),
          FontSize = 16,
          AutoWrap = true
        })
      }),
      ComFuc.ComLabel(nil, GetUTF8Text("tips_common_lock_cost"), Vector2(70, 20), Vector2(30, 183), 0, 16, ARGB(255, 82, 54, 44)),
      Gui.Control("check_control")({
        Size = Vector2(130, 32),
        Location = Vector2(110, 179),
        Gui.Control("check_bg_gold")({
          Skin = SkinF.avatar_main_086,
          Location = Vector2(10, 0),
          Size = Vector2(110, 32),
          BackgroundColor = ComFuc.colw
        }),
        Gui.Control("gold")({
          Location = Vector2(0, 0),
          Size = Vector2(122, 31),
          Gui.Control("check_gold")({
            Skin = SkinF.avatar_main_088[1],
            Location = Vector2(10, 1),
            Size = Vector2(30, 30),
            BackgroundColor = ComFuc.colw
          }),
          ComFuc.ComLabel("check_label_gold", nil, Vector2(78, 24), Vector2(34, 6), 0, 16, ComFuc.coly, "kAlignRight")
        })
      }),
      ComFuc.ComLabel(nil, GetUTF8Text("tips_common_confirm_lock"), Vector2(200, 20), Vector2(30, 219), 0, 16, ARGB(255, 82, 54, 44)),
      ComFuc.ComButton("Lock_button", GetUTF8Text("UI_social_punish_050_title_mainpage"), Vector2(90, 45), Vector2(85, 247), 16, false, false),
      ComFuc.ComButton("close_button", GetUTF8Text("button_common_Cancel"), Vector2(90, 45), Vector2(223, 247), 16, false, false)
    })
  })
})

function DealItemLockDetail(data)
  LockDetailData = data
  ui_lock.check_control.Visible = true
  ui_lock.check_bg_gold.Visible = true
  ui_lock.gold.Visible = true
  for i = 1, 3 do
    if data.itemLockMap[i].property == "lockGP" then
      ui_lock.check_label_gold.Text = data.itemLockMap[i].value
    end
  end
  ui_unlock.warning.AutoWrap = true
  for i = 1, 3 do
    if data.itemLockMap[i].property == "lockTime" then
      local x = Tip.GetLeftTime(data.itemLockMap[i].value * 60 * 60)
      ui_lock.warning.Text = GetMatchedUTF8Text("msgbox_lobby_ready_lock" .. "," .. x)
    end
  end
  ShowLockDialog()
end

function ShowLockDialog()
  ui_lock.ctl_root.Parent = gui
end

function HideLockDialog()
  ui_lock.ctl_root.Parent = nil
  LockDetailData = nil
end

function ui_lock.close_button.EventClick(sender, e)
  HideLockDialog()
end

function ui_lock.quit_button.EventClick(sender, e)
  HideLockDialog()
end

function DealItemLock()
  PersonalInfo.rpc_storage_storage_list(PersonalInfo.ui.pb_depot.CurrIndex)
  MessageBox.ShowError(GetUTF8Text("msgbox_common_successful_locked"))
  HideLockDialog()
end

function ui_lock.Lock_button.EventClick(sender, e)
  rpc.safecall("player_item_lock", {
    pid = PersonalInfo.menDt.pid,
    l = 1,
    t = PersonalInfo.depotCurr + 1,
    lockState = PersonalInfo.menDt.isLock
  }, DealItemLock, HideLockDialog)
end

function DealItemWaitUnbindtail(data)
  if data.lockExpireTime > 0 and 0 < data.lockTime.lockTime then
    local x, time
    time = data.lockExpireTime - data.now / 1000
    PersonalInfo.rpc_storage_storage_list(PersonalInfo.ui.pb_depot.CurrIndex)
    x = Tip.GetLeftTime(time)
    MessageBox.ShowError(GetMatchedUTF8Text("msgbox_lobby_ready_unlock" .. "," .. x))
  end
end
