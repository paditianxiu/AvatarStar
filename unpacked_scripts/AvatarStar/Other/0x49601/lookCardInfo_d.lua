module("LookCardInfo", package.seeall)
local col0 = ComFuc.col0
local colw = ComFuc.colw
local colt = ComFuc.colt
local coly = ARGB(255, 255, 214, 50)
local colg = ComFuc.colg
local colb = ARGB(255, 0, 187, 221)
local resDir = "/ui/skinF/lobby/"
local show_weapon = false
local REId = 0
local AvatarId = ""
local AvtarSkillId = ""
local AvtarSkillLevel = 1
local hero_info
local ui = Gui.Create()({
  ComFuc.ComControl("coverControl2", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(100, 0, 0, 0)),
  Gui.Control("main")({
    Size = Vector2(888, 498),
    Dock = "kDockCenter",
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_207,
    Gui.Control({
      Size = Vector2(880, 31),
      Location = Vector2(4, 4),
      ComFuc.ComLabel("name_t", GetUTF8Text("UI_common_yingxiongjieshao"), Vector2(218, 22), Vector2(16, 0), 0, 16, colw),
      ComFuc.ComButton("close", nil, Vector2(24, 24), Vector2(848, 1), 0, false, false, SkinF.lookInfo_002)
    }),
    Gui.Control({
      Size = Vector2(458, 442),
      Location = Vector2(6, 40),
      Gui.CharacterAnimCard({
        ID = 3,
        Size = Vector2(458, 442)
      }),
      ComFuc.ComButton("reset_anim", GetUTF8Text("button_common_Reset"), Vector2(70, 40), Vector2(156, 383), 16, false, true),
      ComFuc.ComRotateBtn("left_rotate", nil, Vector2(32, 36), Vector2(230, 384), 0, false, SkinF.personalInfo_101),
      ComFuc.ComRotateBtn("right_rotate", nil, Vector2(32, 36), Vector2(269, 384), 0, false, SkinF.personalInfo_102),
      Gui.Control("equip_pp_" .. 2)({
        Location = Vector2(342, 78),
        Size = Vector2(104, 163),
        BackgroundColor = colw,
        Skin = SkinF.personalInfo_103[1],
        ComFuc.ComControl("equip_p_" .. 2, Vector2(104, 163), Vector2(0, 0), 255, SkinF.skin_touming),
        Gui.DragBtn("equip_b_" .. 2)({
          Size = Vector2(104, 163),
          BackgroundColor = colw,
          Skin = SkinF.personalInfo_261,
          ComFuc.ComCharacterStaticCard(nil, 23),
          ComFuc.ComControl(nil, Vector2(104, 163), Vector2(0, 0), 255, SkinF.personalInfo_144),
          Gui.Control("equip_card_level")({
            Size = Vector2(45, 20),
            Location = Vector2(30, 131),
            BackgroundColor = colw,
            Skin = SkinF.avatar_level_hero,
            ComFuc.ComLabel("equit_card_level_text", nil, Vector2(45, 20), Vector2(0, 0), 0, 15, colw, "kAlignCenterMiddle")
          }),
          Gui.Control({
            Size = Vector2(104, 163),
            EventMouseEnter = function(sender, e)
              Tip.SetRpc("tip_sys_avatar", {sid = AvatarId, t = 5})
              Tip.SetUseDescription(true)
              Tip.SetOwner(sender)
            end
          })
        })
      }),
      Gui.DragBtn("avtar_skill")({
        Size = Vector2(70, 70),
        Location = Vector2(358, 261),
        Gui.Control("avtar_skill_tip")({
          Size = Vector2(70, 70),
          EventMouseEnter = function(sender, e)
            Tip.SetRpc("tip_sys_skill", {
              sid = AvtarSkillId,
              t = 1,
              level = AvtarSkillLevel
            })
            Tip.SetUseDescription(true)
            Tip.SetOwner(sender)
          end
        })
      })
    }),
    Gui.Control({
      Size = Vector2(414, 445),
      Location = Vector2(468, 40),
      BackgroundColor = colw,
      Skin = SkinF.battle_005,
      Gui.Control({
        Size = Vector2(399, 399),
        Location = Vector2(8, 40),
        BackgroundColor = colw,
        Skin = SkinF.personalInfo_131,
        Gui.Control("tab_1")({
          Size = Vector2(399, 399),
          ComFuc.ComTextArea("info_dela", Vector2(366, 360), Vector2(17, 20), 15, colw, 3000)
        })
      }),
      ComFuc.SecMainTabBtn("btn_1", GetUTF8Text("button_common_Character_Info") .. " ", Vector2(94, 38), Vector2(20, 4))
    })
  })
})
ui.btn_1.PushDown = true
ui.reset_anim.ClickAudio = "clean"
ui.info_dela.Readonly = true
ui.info_dela.TextPadding = Vector4(12, 8, 8, 8)
ui.info_dela.Skin = SkinF.mail_textarea_001_readonly
ui.info_dela.Text = GetUTF8Text("UI_common_boss_02_desc")

function ui.reset_anim.EventClick(sender, e)
  ComFuc.ResetAnim()
end

function ui.left_rotate.EventMouseDown(sender, e)
  lg:SetVanRotateSpeed(-0.3)
end

function ui.left_rotate.EventMouseUp(sender, e)
  lg:SetVanRotateSpeed(0)
end

function ui.right_rotate.EventMouseDown(sender, e)
  lg:SetVanRotateSpeed(0.3)
end

function ui.right_rotate.EventMouseUp(sender, e)
  lg:SetVanRotateSpeed(0)
end

function ui.close.EventClick(sender, e)
  Hide()
end

function DealHeroAvatar(data)
  ComFuc.DealLookInfoEquip(data.avatar)
  ComFuc.ClearLookInfoIndependentTrinket()
  ComFuc.SetPersonCardData(data.avatar, 23, 0)
  ui.info_dela.Text = GetUTF8Text(hero_info.describe or "")
  ui["equip_p_" .. 2].Skin = SkinF.personalInfo_quality[data.grade or 1]
  ui.equit_card_level_text.Text = data.level
  AvtarSkillLevel = data.level
  AvtarSkillId = data.skillId
  if data.subType == 1 then
    ui.equip_b_2.Skin = SkinF.personalInfo_143
    ui.equip_card_level.Skin = SkinF.avatar_level
  elseif data.subType == 2 then
    ui.equip_b_2.Skin = SkinF.personalInfo_261
    ui.equip_card_level.Skin = SkinF.avatar_level_hero
  end
  if AvtarSkillId == "0" then
    ui.avtar_skill.Visible = false
  else
    ui.avtar_skill.Visible = true
    ui.avtar_skill.Skin = Gui.ButtonSkin({
      BackgroundImage = Gui.Image(resDir .. data.skillResource .. ".tga", Vector4(0, 0, 0, 0))
    })
  end
  ui.coverControl2.Parent = gui
  ui.main.Parent = gui
  Gui.Align(ui.main, 0.5, 0.5)
end

function Show(info)
  hero_info = info
  gui:PlayAudio("prompt")
  show_weapon = lg:SetShowWeapon(false)
  REId = lg:GetREId()
  lg:SetREId(3)
  AvatarId = hero_info.avatarId
  rpc.safecall("hero_avatar", {aid = AvatarId}, DealHeroAvatar)
end

function Hide()
  ComFuc.ResetAnim()
  lg:SetREId(REId)
  lg:SetShowWeapon(show_weapon)
  ui.coverControl2.Parent = nil
  ui.main.Parent = nil
end
