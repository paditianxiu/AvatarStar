module("WeaponUpUI", package.seeall)
if not L_MoneyLessKey then
  require("moneyLessKey.lua")
end
ui = Gui.Create()({
  Gui.Control("ctl_root")({
    Dock = "kDockFill",
    BackgroundColor = ARGB(128, 0, 0, 0),
    Gui.Control("main")({
      Size = Vector2(808, 596),
      Dock = "kDockCenter",
      BackgroundColor = ComFuc.colw,
      Skin = SkinF.personalInfo_260,
      Gui.Control("new_weapon")({
        Skin = SkinF.avatar_main_086,
        Size = Vector2(80, 80),
        Location = Vector2(364, 202),
        BackgroundColor = ComFuc.colw,
        Skin = SkinF.skin_touming
      }),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_lobby_weapon_upgrade"), Vector2(300, 20), Vector2(21, 12), 0, 16, ARGB(255, 255, 253, 8), "kAlignLeft"),
      ComFuc.ComLabel("material_name_1", "", Vector2(64, 52), Vector2(65, 106), 0, 15, ARGB(255, 255, 253, 8), "kAlignLeft"),
      ComFuc.ComLabel("material_name_2", "", Vector2(64, 52), Vector2(65, 254), 0, 15, ARGB(255, 255, 253, 8), "kAlignLeft"),
      ComFuc.ComLabel("material_name_3", "", Vector2(64, 52), Vector2(65, 402), 0, 15, ARGB(255, 255, 253, 8), "kAlignLeft"),
      ComFuc.ComLabel("material_name_4", "", Vector2(67, 52), Vector2(671, 106), 0, 15, ARGB(255, 255, 253, 8), "kAlignLeft"),
      ComFuc.ComLabel("material_name_5", "", Vector2(67, 52), Vector2(671, 254), 0, 15, ARGB(255, 255, 253, 8), "kAlignLeft"),
      ComFuc.ComLabel("material_name_6", "", Vector2(67, 52), Vector2(671, 402), 0, 15, ARGB(255, 255, 253, 8), "kAlignLeft"),
      Gui.Control("check_control")({
        Size = Vector2(95, 28),
        Location = Vector2(389, 358),
        Gui.Control("check_bg_gold")({
          Skin = SkinF.avatar_main_086,
          Size = Vector2(95, 28),
          BackgroundColor = ComFuc.colw
        }),
        Gui.Control("gold")({
          Location = Vector2(0, -1),
          Size = Vector2(122, 31),
          Gui.Control("check_gold")({
            Skin = SkinF.avatar_main_088[1],
            Size = Vector2(30, 30),
            BackgroundColor = ComFuc.colw
          })
        }),
        ComFuc.ComLabel("check_label_gold", nil, Vector2(78, 24), Vector2(15, 6), 0, 16, ComFuc.coly, "kAlignRight")
      }),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_lobby_upgrade_cost"), Vector2(61, 16), Vector2(322, 364), 0, 15, ARGB(255, 228, 0, 255)),
      ComFuc.ComControlAddPt("weapon_flow_1", Vector2(100, 100), Vector2(280, 85), "weapon_right_up1"),
      ComFuc.ComControlAddPt("weapon_flow_2", Vector2(100, 100), Vector2(280, 370), "weapon_right_below1"),
      ComFuc.ComControlAddPt("weapon_flow_3", Vector2(100, 100), Vector2(255, 232), "weapon_right_among1"),
      ComFuc.ComControlAddPt("weapon_flow_4", Vector2(100, 100), Vector2(420, 85), "weapon_left_up1"),
      ComFuc.ComControlAddPt("weapon_flow_5", Vector2(100, 100), Vector2(420, 370), "weapon_left_below1"),
      ComFuc.ComControlAddPt("weapon_flow_6", Vector2(100, 100), Vector2(445, 232), "weapon_left_among1"),
      Gui.Control("material_1")({
        Size = Vector2(80, 80),
        Location = Vector2(130, 91),
        Gui.Control("material_1_border")({
          Size = Vector2(80, 80),
          BackgroundColor = ComFuc.colw,
          Skin = SkinF.personalInfo_quality[5]
        }),
        Gui.Control("material_1_icon")({
          Size = Vector2(80, 80),
          BackgroundColor = ComFuc.colw,
          Skin = SkinF.skin_touming
        }),
        ComFuc.ComLabel("material_1_count", "0/0", Vector2(72, 14), Vector2(0, 60), 0, 14, colw, "kAlignRightMiddle")
      }),
      Gui.Control("material_2")({
        Size = Vector2(80, 80),
        Location = Vector2(130, 240),
        Gui.Control("material_2_border")({
          Size = Vector2(80, 80),
          BackgroundColor = ComFuc.colw,
          Skin = SkinF.personalInfo_quality[5]
        }),
        Gui.Control("material_2_icon")({
          Size = Vector2(80, 80),
          BackgroundColor = ComFuc.colw,
          Skin = SkinF.skin_touming
        }),
        ComFuc.ComLabel("material_2_count", "0/0", Vector2(72, 14), Vector2(0, 60), 0, 14, colw, "kAlignRightMiddle")
      }),
      Gui.Control("material_3")({
        Size = Vector2(80, 80),
        Location = Vector2(130, 389),
        Gui.Control("material_3_border")({
          Size = Vector2(80, 80),
          BackgroundColor = ComFuc.colw,
          Skin = SkinF.personalInfo_quality[5]
        }),
        Gui.Control("material_3_icon")({
          Size = Vector2(80, 80),
          BackgroundColor = ComFuc.colw,
          Skin = SkinF.skin_touming
        }),
        ComFuc.ComLabel("material_3_count", "0/0", Vector2(72, 14), Vector2(0, 60), 0, 14, colw, "kAlignRightMiddle")
      }),
      Gui.Control("material_4")({
        Size = Vector2(80, 80),
        Location = Vector2(593, 91),
        Gui.Control("material_4_border")({
          Size = Vector2(80, 80),
          BackgroundColor = ComFuc.colw,
          Skin = SkinF.personalInfo_quality[5]
        }),
        Gui.Control("material_4_icon")({
          Size = Vector2(80, 80),
          BackgroundColor = ComFuc.colw,
          Skin = SkinF.skin_touming
        }),
        ComFuc.ComLabel("material_4_count", "0/0", Vector2(72, 14), Vector2(0, 60), 0, 14, colw, "kAlignRightMiddle")
      }),
      Gui.Control("material_5")({
        Size = Vector2(80, 80),
        Location = Vector2(593, 240),
        Gui.Control("material_5_border")({
          Size = Vector2(80, 80),
          BackgroundColor = ComFuc.colw,
          Skin = SkinF.personalInfo_quality[5]
        }),
        Gui.Control("material_5_icon")({
          Size = Vector2(80, 80),
          BackgroundColor = ComFuc.colw,
          Skin = SkinF.skin_touming
        }),
        ComFuc.ComLabel("material_5_count", "0/0", Vector2(72, 14), Vector2(0, 60), 0, 14, colw, "kAlignRightMiddle")
      }),
      Gui.Control("material_6")({
        Size = Vector2(80, 80),
        Location = Vector2(593, 389),
        Gui.Control("material_6_border")({
          Size = Vector2(80, 80),
          BackgroundColor = ComFuc.colw,
          Skin = SkinF.personalInfo_quality[5]
        }),
        Gui.Control("material_6_icon")({
          Size = Vector2(80, 80),
          BackgroundColor = ComFuc.colw,
          Skin = SkinF.skin_touming
        }),
        ComFuc.ComLabel("material_6_count", "0/0", Vector2(72, 14), Vector2(0, 60), 0, 14, colw, "kAlignRightMiddle")
      }),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_lobby_upgrade_details"), Vector2(740, 30), Vector2(30, 530), 0, 15, ARGB(255, 255, 253, 8), "kAlignCenterTop"),
      ComFuc.ComButton("weaponup_button", "", Vector2(163, 62), Vector2(322, 456), 16, false, false, SkinF.weaponup_button),
      ComFuc.ComButton("quit_button", nil, Vector2(24, 24), Vector2(773, 12), 16, false, false, SkinF.lookInfo_002)
    })
  })
})
ui.weapon_flow_1.Particle:SetEnable(true)
ui.weapon_flow_1.Particle:Reset()
ui.weapon_flow_2.Particle:SetEnable(true)
ui.weapon_flow_2.Particle:Reset()
ui.weapon_flow_3.Particle:SetEnable(true)
ui.weapon_flow_3.Particle:Reset()
ui.weapon_flow_4.Particle:SetEnable(true)
ui.weapon_flow_4.Particle:Reset()
ui.weapon_flow_5.Particle:SetEnable(true)
ui.weapon_flow_5.Particle:Reset()
ui.weapon_flow_6.Particle:SetEnable(true)
ui.weapon_flow_6.Particle:Reset()
ui.weapon_flow_1.Visible = false
ui.weapon_flow_2.Visible = false
ui.weapon_flow_3.Visible = false
ui.weapon_flow_4.Visible = false
ui.weapon_flow_5.Visible = false
ui.weapon_flow_6.Visible = false
ui.material_name_1.AutoWrap = true
ui.material_name_2.AutoWrap = true
ui.material_name_3.AutoWrap = true
ui.material_name_4.AutoWrap = true
ui.material_name_5.AutoWrap = true
ui.material_name_6.AutoWrap = true
local isEnough = false
local playerItemID

function DealWeapon(data)
  ui.new_weapon.Skin = Gui.ControlSkin({
    BackgroundImage = Gui.Image("ui/skinF/lobby/" .. data.equip.resource .. ".tga", Vector4(0, 0, 0, 0))
  })
  
  function ui.new_weapon.EventMouseEnter(sender, e)
    Tip.SetRpc("tip_sys_item", {
      t = data.equip.type,
      sid = data.equip.id
    })
    Tip.SetUseDescription(false)
    Tip.SetOwner(sender)
  end
  
  isEnough = true
  for i = 1, 6 do
    ui["material_name_" .. i].Visible = false
    ui["material_" .. i].Visible = false
  end
  for i, v in ipairs(data.materials) do
    ui["material_name_" .. i].Visible = true
    ui["material_" .. i].Visible = true
    local temp_text = GetUTF8Text(v.displayName)
    if 24 < #temp_text then
      temp_text = string.sub(temp_text, 1, 16) .. " ..."
    end
    ui["material_name_" .. i].Text = temp_text
    ui["material_" .. i .. "_icon"].Skin = Gui.ControlSkin({
      BackgroundImage = Gui.Image("ui/skinF/lobby/" .. v.resource .. ".tga", Vector4(0, 0, 0, 0))
    })
    local hc = v.ownNum
    local nc = v.needNum
    ui["material_" .. i .. "_count"].Text = string.format("%d/%d", hc, nc)
    if hc >= nc then
      ui["material_" .. i .. "_count"].TextureFont = SkinF.hecheng_number_5
    else
      ui["material_" .. i .. "_count"].TextureFont = SkinF.hecheng_number_6
      isEnough = false
    end
    ui["material_" .. i .. "_icon"].EventMouseEnter = function(sender, e)
      Tip.SetRpc("tip_sys_item", {
        t = v.type,
        sid = v.itemId
      })
      Tip.SetUseDescription(false)
      Tip.SetOwner(sender)
    end
    ui["material_" .. i .. "_border"].Skin = SkinF.personalInfo_quality[v.grade]
  end
  ui.check_label_gold.Text = data.equip.costGp
  ui.weaponup_button.Enable = true
  ui.quit_button.Enable = true
  
  function ui.weaponup_button.EventClick()
    if isEnough == false then
      MessageBox.ShowError(GetUTF8Text("UI_lobby_upgrade_M_less"))
    elseif ComFuc.globalGP < data.equip.costGp then
      Hide()
      local moneyType = "gold"
      local s = GetUTF8Text("UI_lobby_upgrade_G_less") .. "\n" .. GetUTF8Text(L_MoneyLessKey.HelpTextKey[moneyType])
      MessageBox.ShowNotEnough(s, moneyType, config.IsRecharge)
    else
      MessageBox.ShowWithConfirmCancel(GetUTF8Text("UI_lobby_upgrade_box"), function(sender, e)
        MessageBox.ShowWithConfirmCancel(GetMatchedUTF8Text(string.format("UI_lobby_upgrade_product,%s,%s", GetUTF8Text(data.oldEquip.displayName), GetUTF8Text(data.equip.displayName))), function(sender, e)
          ui.weapon_flow_1.Visible = true
          ui.weapon_flow_2.Visible = true
          ui.weapon_flow_3.Visible = true
          ui.weapon_flow_4.Visible = true
          ui.weapon_flow_5.Visible = true
          ui.weapon_flow_6.Visible = true
          timer = game.TimerMgr:AddTimer(2)
          timer.EventOnTimer = Request
          ui.weaponup_button.Enable = false
          ui.quit_button.Enable = false
        end)
      end)
    end
  end
end

function Request()
  rpc.safecall("weapon_advanced", {pid = playerItemID}, Success)
  game.TimerMgr:RemoveTimer(timer)
end

function Success(data)
  PersonalInfo.ReinWeaponUp()
  if not GainGoods then
    require("gainGoods.lua")
  end
  GainGoods.Show(data.items)
  PersonalInfo.ReflashMail()
  Hide()
end

function Show(id)
  ui.ctl_root.Parent = gui
  playerItemID = id
  rpc.safecall("advanced_equip_info", {pid = id}, DealWeapon)
end

function Hide()
  ui.ctl_root.Parent = nil
  ui.weapon_flow_1.Visible = false
  ui.weapon_flow_2.Visible = false
  ui.weapon_flow_3.Visible = false
  ui.weapon_flow_4.Visible = false
  ui.weapon_flow_5.Visible = false
  ui.weapon_flow_6.Visible = false
end

function ui.quit_button.EventClick(sender, e)
  Hide()
end
