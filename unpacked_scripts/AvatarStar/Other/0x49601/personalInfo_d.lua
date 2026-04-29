module("PersonalInfo", package.seeall)
require("playercardinherit.lua")
require("openBox.lua")
require("shop/shop_balance.lua")
colGrade = {
  ARGB(255, 180, 180, 180),
  ARGB(255, 54, 255, 0),
  ARGB(255, 0, 180, 255),
  ARGB(255, 198, 0, 255),
  ARGB(255, 255, 128, 0),
  ARGB(255, 255, 255, 255)
}
isDoEquip = false
reinState = 0
reinK = 0
reinKAdd = true
timer = nil
equipAvatarId = 0
isEnough = true
skillLeave = 0
slotRenforceId = {
  0,
  0,
  0,
  0,
  0
}
slotRenforceBf = {}
openSlotCurr = 0
mixNeed = 0
mixHas = 0
insCost = 0
oldDestText = 1
oldTipSlot = -1
skillCost = {}
tableInsP = {}
tableInsB = {}
tableDepot = {}
equipGrade = {
  1,
  1,
  1,
  1,
  1,
  1
}
resDir = "/ui/skinF/lobby/"
equipSkinRes = {
  "",
  "humancard",
  "",
  "",
  "",
  ""
}
refitPtLev = 0
retitState = nil
fastUseTask = false
refitLevBeg = 1
refitLevEnd = 0
refitMoveDir = 0
refitContentN = 1
isOpenRefitWeaponSound = false
refitWeaponGrades = ""
refitDetail = {}
canUpGrade = true
dptDt = {}
dptDt2 = {}
htkDt = {}
sklDt = {}
bossSkillDt = {}
posDt = {}
menDt = {}
menDt2 = {}
preTempDt = {}
insDt = {}
refitDt = {}
hangDt = {}
hangAddDt = {}
hangMentDt = {}
blueprintDt = {}
blueSigleCost = 0
isBlueUpdate = false
isBlueListUpdate = false
HangProNth = 1
HangProHas = 1
mainCurr = 0
depotCurr = 0
reinforceCurr = 0
skillTemLevel = {}
independentTrinket = {}
isAddMore = false
isHangFirst = true
refitLevelExp = {}
col0 = ComFuc.col0
colw = ComFuc.colw
colg = ComFuc.colg
coly = ComFuc.coly
cols = ComFuc.cols
colh = ComFuc.colh
colb = ComFuc.colb
ComMenu = ComFuc.ComMenu
DepotCB = ComFuc.DepotCB
EquipCB = ComFuc.EquipCB
DepotPetSlot = ComFuc.DepotPetSlot
MixSlot = ComFuc.MixSlot
ComLabel = ComFuc.ComLabel
ComButton = ComFuc.ComButton
ComColorButton = ComFuc.ComColorButton
ComControl = ComFuc.ComControl
MainTabBtn = ComFuc.MainTabBtn
InsertSlot = ComFuc.InsertSlot
ComFlashNew = ComFuc.ComFlashNew
LimitControl = ComFuc.LimitControl
RefitMetrial = ComFuc.RefitMetrial
SecMainTabBtn = ComFuc.SecMainTabBtn
SkillPointItem = ComFuc.SkillPointItem
BossSkillShow = ComFuc.BossSkillShow
IsInAABB = ComFuc.IsInAABB
IsOutAABB = ComFuc.IsOutAABB
GetMoveMesg = ComFuc.GetMoveMesg
ShowDepotTips = ComFuc.ShowDepotTips
ShowOneButton = ComFuc.ShowOneButton
ComputeInsertP = ComFuc.ComputeInsertP
local SetCtrlColorLcSize, ReinDepotCtrl = ComFuc.SetCtrlColorLcSize, ComFuc.SetCtrlColorLcSize

function ReinDepotCtrl(size, lc, lc2, text, name, fuc, count, bx, by, type)
  return ComFuc.ReinDepotCtrl(size, lc, lc2, text, name, fuc, count, bx, by, type, PersonalInfo)
end

tip_sys_interface = {
  "tip_sys_skill",
  "tip_sys_item",
  "tip_sys_item",
  "tip_sys_item",
  "tip_sys_avatar",
  "tip_sys_avatar"
}
tip_player_interface = {
  "tip_player_skill",
  "tip_player_item",
  "tip_player_item",
  "tip_player_item",
  "tip_player_avatar",
  "tip_player_avatar"
}
SelectedPetSlot = 1
SelectedCandidate = nil
local PetFoodCost
local PetRenamePrice = {}
PlayerPetsData = {}
local CurrentPetSkillData = {}
local CurrentPetOpConditions = {}
local CurrentPetOpSettings = {}
SysPetsData = {}
ToBeDeletePetSlot = nil
EquippedPetResource = nil
EquippedPetGrade = nil
currentSysPetPrice = {}
currentPlacatePrice = {}
currentPetSkillUpdatePrice = {}
currentPetSlotExpandPrice = {}
CurrentPlayerPetPage = 1
TotalPlayerPetPage = 1
CurrentSysPetPage = 1
TotalSysPetPage = 1
UnlockedPetSlotNum = 4
local EnhancePageTitleSize = 5
local EnhancePageTitleTotal = 6
local offset = 0
local LocationTable = {}
local AvtarSkillId = 0
local AvtarSkillLevel = 0
local AvtarStype, ComRefitLveContent = {}, ARGB(255, 255, 255, 255)

function ComRefitLveContent(i, lc)
  return Gui.Control("refit_lev_content_" .. i)({
    Size = Vector2(171, 60),
    Location = lc,
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_239,
    ComControl("refit_lev_" .. (i - 1) * 5 + 1, Vector2(23, 15), Vector2(6, 28), 255, SkinF.personalInfo_221),
    ComControl("refit_lev_" .. (i - 1) * 5 + 2, Vector2(23, 15), Vector2(40, 28), 255, SkinF.personalInfo_221),
    ComControl("refit_lev_" .. (i - 1) * 5 + 3, Vector2(23, 15), Vector2(74, 28), 255, SkinF.personalInfo_221),
    ComControl("refit_lev_" .. (i - 1) * 5 + 4, Vector2(23, 15), Vector2(108, 28), 255, SkinF.personalInfo_221),
    ComControl("refit_lev_" .. (i - 1) * 5 + 5, Vector2(23, 15), Vector2(142, 28), 255, SkinF.personalInfo_221),
    ComControl("refit_lev_n" .. i, Vector2(171, 60), Vector2(0, 0), 255, SkinF.personalInfo_240[i]),
    ComFuc.ComControlAddPt("refit_pt_" .. (i - 1) * 5 + 1, Vector2(27, 19), Vector2(4, 26), "ui_hecheng3"),
    ComFuc.ComControlAddPt("refit_pt_" .. (i - 1) * 5 + 2, Vector2(27, 19), Vector2(38, 26), "ui_hecheng3"),
    ComFuc.ComControlAddPt("refit_pt_" .. (i - 1) * 5 + 3, Vector2(27, 19), Vector2(72, 26), "ui_hecheng3"),
    ComFuc.ComControlAddPt("refit_pt_" .. (i - 1) * 5 + 4, Vector2(27, 19), Vector2(106, 26), "ui_hecheng3"),
    ComFuc.ComControlAddPt("refit_pt_" .. (i - 1) * 5 + 5, Vector2(27, 19), Vector2(140, 26), "ui_hecheng3")
  })
end

remove_box_bg = Gui.ControlSkin({
  BackgroundImage = Gui.Image("ui/skinF/skin_baoxiang_bg03.tga", Vector4(20, 20, 20, 20))
})
remove_background = Gui.ControlSkin({
  BackgroundImage = Gui.Image("ui/skinF/skin_common_background02_01.tga", Vector4(20, 20, 20, 20))
})
remove_stone_index = nil
remove_stone_of_avatar_id = 0
local removeStoneRpcGetData, ComCB = nil, {
  BackgroundImage = Gui.Image("ui/skinF/skin_common_background02_01.tga", Vector4(20, 20, 20, 20))
}

function ComCB(name, size, lc)
  return Gui.Control(name .. "_son")({
    Location = lc,
    Size = size,
    BackgroundColor = colw,
    Skin = SkinF.skin_touming,
    Gui.Control(name .. "_s")({
      Size = size,
      BackgroundColor = colw,
      Skin = SkinF.skin_touming,
      ComLabel(name .. "_l", nil, Vector2(60, 18), Vector2(20, 59), 0, 0, col0, "kAlignRightMiddle", nil, true, SkinF.hecheng_number_1)
    })
  })
end

local cutHeight = 270
ui_cancel_binding = Gui.Create()({
  Gui.Control("ctl_root")({
    Dock = "kDockFill",
    BackgroundColor = ARGB(128, 0, 0, 0),
    Gui.Control("main")({
      Size = Vector2(385, 490 - cutHeight),
      Dock = "kDockCenter",
      BackgroundColor = ComFuc.colw,
      Skin = SkinF.personalInfo_207,
      ComFuc.ComLabel(nil, GetUTF8Text("UI_lobby_prop_state_09"), Vector2(332, 24), Vector2(12, 4), 0, 16, ComFuc.colw),
      Gui.Button("close_button")({
        Size = Vector2(24, 24),
        Location = Vector2(353, 4),
        Skin = SkinF.lookInfo_002
      }),
      ComCB("r_stone", Vector2(80, 80), Vector2(18, 324 - cutHeight)),
      Gui.Control("backGround")({
        Size = Vector2(266, 94),
        Location = Vector2(104, 317 - cutHeight),
        BackgroundColor = ComFuc.colw,
        Skin = remove_box_bg,
        Gui.Control("r_stone_extirpate")({
          Size = Vector2(80, 80),
          Location = Vector2(12, 7),
          ComFuc.ComControl("r_stone_extirpate_lev", Vector2(80, 80), Vector2(0, 0), 255),
          ComFuc.ComControl("r_stone_extirpate_res", Vector2(80, 80), Vector2(0, 0), 255),
          ComFuc.ComLabel("r_stone_extirpate_count", "0/0", Vector2(79, 18), Vector2(0, 59), 0, 0, ComFuc.colw, "kAlignRightMiddle", 0, true, SkinF.hecheng_number_1),
          EventMouseEnter = function(sender, e)
            if UnbindDetailData then
              Tip.SetRpc(tip_sys_interface[3], {
                t = 3,
                sid = UnbindDetailData.stoneId
              })
              Tip.SetUseDescription(false)
              Tip.SetOwner(sender)
            end
          end
        }),
        Gui.Control("check_control")({
          Size = Vector2(150, 67),
          Location = Vector2(104, 13),
          Gui.CheckBox("checkBox_gold")({
            Style = "Gui.CheckBox_01",
            Location = Vector2(0, 4),
            Size = Vector2(24, 24),
            Check = true
          }),
          Gui.Control("check_bg_gold")({
            Skin = SkinF.avatar_main_086,
            Location = Vector2(28, 0),
            Size = Vector2(122, 31),
            BackgroundColor = ComFuc.colw
          }),
          Gui.Control("gold")({
            Location = Vector2(28, 0),
            Size = Vector2(122, 31),
            Gui.Control("check_gold")({
              Skin = SkinF.avatar_main_088[1],
              Location = Vector2(0, 1),
              Size = Vector2(30, 30),
              BackgroundColor = ComFuc.colw
            }),
            ComFuc.ComLabel("check_label_gold", nil, Vector2(78, 24), Vector2(34, 3), 0, 16, ComFuc.coly, "kAlignRight")
          }),
          Gui.CheckBox("checkBox_star")({
            Style = "Gui.CheckBox_01",
            Location = Vector2(0, 40),
            Size = Vector2(24, 24),
            Check = false
          }),
          Gui.Control("check_bg_star")({
            Skin = SkinF.avatar_main_086,
            Location = Vector2(28, 36),
            Size = Vector2(122, 31),
            BackgroundColor = ComFuc.colw
          }),
          Gui.Control("star")({
            Location = Vector2(28, 36),
            Size = Vector2(122, 31),
            Gui.Control("check_star")({
              Skin = SkinF.avatar_main_088[2],
              Location = Vector2(0, 1),
              Size = Vector2(30, 30),
              BackgroundColor = ComFuc.colw
            }),
            ComFuc.ComLabel("check_label_star", nil, Vector2(78, 24), Vector2(34, 3), 0, 16, ComFuc.coly, "kAlignRight")
          })
        })
      }),
      ComButton("removeButton", GetUTF8Text("UI_lobby_prop_state_09"), Vector2(140, 53), Vector2(123, 419 - cutHeight), 16, false, false, SkinF.skin_playgame_037)
    })
  })
})
ui_cancel_binding.r_stone_extirpate_lev.Enable = false
ui_cancel_binding.r_stone_extirpate_res.Enable = false
ui_cancel_binding.r_stone_extirpate_count.Enable = false
cutHeight1 = 240
ui_stone = Gui.Create()({
  Gui.Control("ctl_root")({
    Dock = "kDockFill",
    BackgroundColor = ARGB(128, 0, 0, 0),
    Gui.Control("main")({
      Size = Vector2(385, 490 - cutHeight1),
      Dock = "kDockCenter",
      BackgroundColor = ComFuc.colw,
      Skin = SkinF.personalInfo_207,
      ComFuc.ComLabel(nil, GetUTF8Text("button_common_extirpate_02"), Vector2(332, 24), Vector2(12, 4), 0, 16, ComFuc.colw),
      Gui.Button("close_button")({
        Size = Vector2(24, 24),
        Location = Vector2(353, 4),
        Skin = SkinF.lookInfo_002
      }),
      ComFuc.ComLabel("descText", GetUTF8Text("button_common_extirpate_communication"), Vector2(357, 46), Vector2(14, 267 - cutHeight1), 0, 16, ComFuc.cols),
      ComCB("r_stone", Vector2(80, 80), Vector2(18, 324 - cutHeight1)),
      Gui.Control("backGround")({
        Size = Vector2(266, 94),
        Location = Vector2(104, 317 - cutHeight1),
        BackgroundColor = ComFuc.colw,
        Skin = remove_box_bg,
        Gui.Control("r_stone_extirpate")({
          Size = Vector2(80, 80),
          Location = Vector2(12, 7),
          ComFuc.ComControl("r_stone_extirpate_lev", Vector2(80, 80), Vector2(0, 0), 255),
          ComFuc.ComControl("r_stone_extirpate_res", Vector2(80, 80), Vector2(0, 0), 255),
          ComFuc.ComLabel("r_stone_extirpate_count", "0/0", Vector2(79, 18), Vector2(0, 59), 0, 0, ComFuc.colw, "kAlignRightMiddle", 0, true, SkinF.hecheng_number_1),
          EventMouseEnter = function(sender, e)
            if removeStoneRpcGetData and removeStoneRpcGetData.extirpate_sid ~= "null" then
              Tip.SetRpc(tip_sys_interface[3], {
                t = 3,
                sid = removeStoneRpcGetData.extirpate_sid
              })
              Tip.SetUseDescription(false)
              Tip.SetOwner(sender)
            end
          end
        }),
        Gui.Control("check_control")({
          Size = Vector2(150, 67),
          Location = Vector2(104, 13),
          Gui.CheckBox("checkBox_gold")({
            Style = "Gui.CheckBox_01",
            Location = Vector2(0, 4),
            Size = Vector2(24, 24),
            Check = true
          }),
          Gui.Control("check_bg_gold")({
            Skin = SkinF.avatar_main_086,
            Location = Vector2(28, 0),
            Size = Vector2(122, 31),
            BackgroundColor = ComFuc.colw
          }),
          Gui.Control("gold")({
            Location = Vector2(28, 0),
            Size = Vector2(122, 31),
            Gui.Control("check_gold")({
              Skin = SkinF.avatar_main_088[1],
              Location = Vector2(0, 1),
              Size = Vector2(30, 30),
              BackgroundColor = ComFuc.colw
            }),
            ComFuc.ComLabel("check_label_gold", nil, Vector2(78, 24), Vector2(34, 3), 0, 16, ComFuc.coly, "kAlignRight")
          }),
          Gui.CheckBox("checkBox_star")({
            Style = "Gui.CheckBox_01",
            Location = Vector2(0, 40),
            Size = Vector2(24, 24),
            Check = false
          }),
          Gui.Control("check_bg_star")({
            Skin = SkinF.avatar_main_086,
            Location = Vector2(28, 36),
            Size = Vector2(122, 31),
            BackgroundColor = ComFuc.colw
          }),
          Gui.Control("star")({
            Location = Vector2(28, 36),
            Size = Vector2(122, 31),
            Gui.Control("check_star")({
              Skin = SkinF.avatar_main_088[2],
              Location = Vector2(0, 1),
              Size = Vector2(30, 30),
              BackgroundColor = ComFuc.colw
            }),
            ComFuc.ComLabel("check_label_star", nil, Vector2(78, 24), Vector2(34, 3), 0, 16, ComFuc.coly, "kAlignRight")
          })
        })
      }),
      ComButton("removeButton", GetUTF8Text("button_common_extirpate_02"), Vector2(140, 53), Vector2(123, 419 - cutHeight1), 16, false, false, SkinF.skin_playgame_037)
    })
  })
})
ui_stone.r_stone_extirpate_lev.Enable = false
ui_stone.r_stone_extirpate_res.Enable = false
ui_stone.r_stone_extirpate_count.Enable = false
ui_stone.descText.AutoWrap = true
local ui_mw, ComManuMaterial = Gui.Create()({
  Gui.Control("main")({
    Size = Vector2(332, 398),
    BackgroundColor = ComFuc.colw,
    Skin = SkinF.personalInfo_207,
    ComFuc.ComLabel(nil, GetUTF8Text("mingwen"), Vector2(280, 24), Vector2(12, 4), 0, 16, ComFuc.colw),
    Gui.Button("close_button")({
      Size = Vector2(24, 24),
      Location = Vector2(300, 4),
      Skin = SkinF.lookInfo_002
    }),
    Gui.Control("backGround")({
      Size = Vector2(310, 235),
      Location = Vector2(12, 40),
      BackgroundColor = ComFuc.colw,
      Skin = remove_box_bg
    }),
    Gui.Control("backGround")({
      Size = Vector2(180, 74),
      Location = Vector2(123, 60),
      BackgroundColor = ComFuc.colw,
      Skin = remove_background
    }),
    Gui.Control("gold_btm")({
      Size = Vector2(30, 30),
      Location = Vector2(290, 280),
      BackgroundColor = ComFuc.colw,
      Skin = SkinF.shop_10
    }),
    ComButton("fujiaButton", GetUTF8Text("remove"), Vector2(140, 53), Vector2(96, 318), 16, false, false, SkinF.skin_playgame_037)
  })
}), {
  Gui.Control("main")({
    Size = Vector2(332, 398),
    BackgroundColor = ComFuc.colw,
    Skin = SkinF.personalInfo_207,
    ComFuc.ComLabel(nil, GetUTF8Text("mingwen"), Vector2(280, 24), Vector2(12, 4), 0, 16, ComFuc.colw),
    Gui.Button("close_button")({
      Size = Vector2(24, 24),
      Location = Vector2(300, 4),
      Skin = SkinF.lookInfo_002
    }),
    Gui.Control("backGround")({
      Size = Vector2(310, 235),
      Location = Vector2(12, 40),
      BackgroundColor = ComFuc.colw,
      Skin = remove_box_bg
    }),
    Gui.Control("backGround")({
      Size = Vector2(180, 74),
      Location = Vector2(123, 60),
      BackgroundColor = ComFuc.colw,
      Skin = remove_background
    }),
    Gui.Control("gold_btm")({
      Size = Vector2(30, 30),
      Location = Vector2(290, 280),
      BackgroundColor = ComFuc.colw,
      Skin = SkinF.shop_10
    }),
    ComButton("fujiaButton", GetUTF8Text("remove"), Vector2(140, 53), Vector2(96, 318), 16, false, false, SkinF.skin_playgame_037)
  })
}

function ComManuMaterial(i)
  return Gui.Control("manu_tiao_" .. i)({
    Size = Vector2(230, 80),
    Location = Vector2(19, 181 + 80 * i),
    ComControl("manu_tiao_lev_" .. i, Vector2(80, 80), Vector2(2, 0), 255, SkinF.personalInfo_quality[1]),
    ComControl("manu_tiao_res_" .. i, Vector2(80, 80), Vector2(2, 0), 255, SkinF.skin_touming),
    ComLabel("manu_tiao_count_" .. i, "", Vector2(74, 16), Vector2(2, 60), 0, 0, colw, "kAlignRightMiddle", 0, true, SkinF.info_number_2),
    ComLabel("manu_tiao_name_" .. i, "", Vector2(130, 64), Vector2(90, 5), 0, 16, colw),
    Gui.Control("manu_tiao_level_" .. i)({
      Size = Vector2(27, 29),
      Location = Vector2(53, 0),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_245[1],
      Visible = false,
      ComLabel("manu_tiao_level_text_" .. i, nil, Vector2(27, 14), Vector2(0, 6), 0, 12, colw, "kAlignCenterMiddle")
    })
  })
end

ui = Gui.Create()({
  Gui.Control("main")({
    Size = Vector2(1142, 694),
    Gui.Control("main_mid")({
      Size = Vector2(1128, 645),
      Location = Vector2(7, 45),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_098,
      ComControl("mid_all", Vector2(1128, 645), Vector2(0, 0)),
      ComControl("left", Vector2(508, 490), Vector2(13, 16)),
      ComControl("right", Vector2(592, 508), Vector2(525, 16)),
      Gui.Control("btm")({
        Size = Vector2(1104, 125),
        Location = Vector2(13, 510),
        BackgroundColor = colw,
        Skin = SkinF.personalInfo_099,
        ComLabel(nil, GetUTF8Text("UI_character_Quick_Key_Slot"), Vector2(180, 21), Vector2(14, 3), 0, 16, colw),
        ComFuc.HotKeyCB(1),
        ComFuc.HotKeyCB(2),
        ComFuc.HotKeyCB(3),
        ComFuc.HotKeyCB(4),
        ComFuc.HotKeyCB(5),
        ComFuc.HotKeyCB(6),
        ComFuc.HotKeyCB(7),
        ComFuc.HotKeyCB(8),
        ComFuc.HotKeyCB(9),
        ComFuc.HotKeyCB(10),
        ComFuc.HotKeyCB(11),
        ComFuc.HotKeyCB(12)
      })
    }),
    MainTabBtn("btn_main_2", GetUTF8Text("button_common_Bag"), Vector2(28, 5)),
    MainTabBtn("btn_main_3", GetUTF8Text("button_common_Skill"), Vector2(238, 5)),
    MainTabBtn("btn_main_4", GetUTF8Text("UI_inGame_pet_string_01"), Vector2(448, 5)),
    ComControl("btn_main_4_disable_hint", Vector2(206, 42), Vector2(448, 5), 255, SkinF.skin_touming, false, true, nil, GetMatchedUTF8Text(string.format("UI_pet_system_unlock_01,%d", 3)))
  }),
  Gui.Control("left_main_1")({
    Size = Vector2(508, 490),
    Gui.CharacterAnimCard({
      Size = Vector2(508, 490)
    }),
    Gui.Control("equip_pp_" .. 2)({
      Location = Vector2(389, 98),
      Size = Vector2(104, 163),
      BackgroundColor = colw,
      Visible = false,
      Skin = SkinF.personalInfo_103[1],
      ComControl("equip_p_" .. 2, Vector2(104, 163), Vector2(0, 0), 255, SkinF.skin_touming),
      Gui.DragBtn("equip_b_" .. 2)({
        Size = Vector2(104, 163),
        BackgroundColor = colw,
        Skin = SkinF.personalInfo_143,
        ComFuc.ComCharacterStaticCard(nil, 0),
        ComControl(nil, Vector2(104, 163), Vector2(0, 0), 255, SkinF.personalInfo_144),
        Gui.Control("equip_card_level")({
          Size = Vector2(45, 20),
          Location = Vector2(30, 131),
          BackgroundColor = colw,
          Skin = SkinF.avatar_level,
          Visible = false,
          ComLabel("equit_card_level_text", nil, Vector2(45, 20), Vector2(0, 0), 0, 15, colw, "kAlignCenterMiddle")
        }),
        Gui.Control("equip_c_" .. 2)({
          Size = Vector2(104, 163),
          BackgroundColor = colw,
          Skin = SkinF.skin_touming,
          EventMouseEnter = function(sender, e)
            sender.Skin = SkinF.personalInfo_210
            ShowDepotTips(sender, equipAvatarId, 5, equipAvatarId)
          end,
          EventMouseLeave = function(sender, e)
            sender.Skin = SkinF.skin_touming
          end
        })
      }),
      ComFlashNew("equip_c2_" .. 2, Vector2(104, 163), Vector2(0, 0), 255, SkinF.personalInfo_104, false)
    }),
    Gui.DragBtn("avtar_skill")({
      Size = Vector2(70, 70),
      Location = Vector2(405, 276),
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
    }),
    ComButton("mingwen", GetUTF8Text("mingwen"), Vector2(70, 40), Vector2(20, 129), 16, false, true),
    EquipCB(GetUTF8Text("tips_lobby_Slot_Desc3"), 1, Vector2(413, 265), SkinF.personalInfo_089, 2, 2),
    EquipCB(GetUTF8Text("tips_lobby_Slot_Desc3"), 3, Vector2(15, 265), SkinF.personalInfo_089, 2, 3),
    EquipCB(GetUTF8Text("tips_lobby_Slot_Desc2"), 4, Vector2(413, 171), SkinF.personalInfo_090, 2, 1),
    EquipCB("5         ", 5, Vector2(0, 0), nil),
    EquipCB(GetUTF8Text("tips_lobby_Slot_Desc1"), 6, Vector2(15, 171), SkinF.personalInfo_138, 2, 4),
    EquipCB(GetUTF8Text("UI_lobby_additional_string_141"), 7, Vector2(214, 18), SkinF.personalInfo_138, 4),
    EquipCB(GetUTF8Text("UI_lobby_additional_string_141"), 8, Vector2(413, 119), SkinF.personalInfo_138, 4),
    EquipCB(GetUTF8Text("UI_lobby_additional_string_141"), 9, Vector2(413, 225), SkinF.personalInfo_138, 4),
    EquipCB(GetUTF8Text("UI_lobby_additional_string_141"), 10, Vector2(214, 320), SkinF.personalInfo_138, 4),
    EquipCB(GetUTF8Text("UI_lobby_additional_string_141"), 11, Vector2(15, 225), SkinF.personalInfo_138, 4),
    EquipCB(GetUTF8Text("UI_lobby_additional_string_141"), 12, Vector2(15, 119), SkinF.personalInfo_138, 4),
    ComFuc.ComRotateBtn("left_rotate", nil, Vector2(32, 36), Vector2(418, 373), 0, false, SkinF.personalInfo_101),
    ComFuc.ComRotateBtn("right_rotate", nil, Vector2(32, 36), Vector2(456, 373), 0, false, SkinF.personalInfo_102),
    ComButton("reset_anim", GetUTF8Text("button_common_Reset"), Vector2(70, 40), Vector2(343, 372), 16, false, true),
    ComControl(nil, Vector2(180, 93), Vector2(8, 12), 255, SkinF.personalInfo_225),
    ComControl(nil, Vector2(172, 81), Vector2(12, 16), 255, SkinF.personalInfo_panel_bg_001),
    ComLabel(nil, GetUTF8Text("tips_abilities_Power"), Vector2(61, 14), Vector2(18, 21), 0, 14, coly),
    ComLabel(nil, GetUTF8Text("tips_lobby_explore_strength_tips"), Vector2(61, 14), Vector2(18, 57), 0, 14, colb),
    ComLabel("info_power", 0, Vector2(103, 30), Vector2(77, 23), 0, 0, colw, nil, nil, true, SkinF.info_number_1),
    ComLabel("info_adventure", 0, Vector2(103, 30), Vector2(77, 62), 0, 0, colw, nil, nil, true, SkinF.info_number_3),
    ComControl(nil, Vector2(130, 31), Vector2(9, 391), 255, SkinF.personalInfo_259),
    ComLabel(nil, GetUTF8Text("UI_lobby_Character_Attribute"), Vector2(130, 31), Vector2(45, 389), 0, 15, colw),
    Gui.Control({
      Size = Vector2(494, 70),
      Location = Vector2(7, 415),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_225,
      ComControl(nil, Vector2(480, 60), Vector2(10, 3), 255, SkinF.personalInfo_228),
      ComControl(nil, Vector2(20, 17), Vector2(20, 25), 255, SkinF.personalInfo_229[1]),
      ComControl(nil, Vector2(20, 17), Vector2(199, 25), 255, SkinF.personalInfo_229[6]),
      ComControl(nil, Vector2(20, 17), Vector2(373, 25), 255, SkinF.personalInfo_229[2]),
      ComControl(nil, Vector2(20, 17), Vector2(20, 46), 255, SkinF.personalInfo_229[3]),
      ComControl(nil, Vector2(20, 17), Vector2(199, 46), 255, SkinF.personalInfo_229[4]),
      ComControl(nil, Vector2(20, 17), Vector2(373, 46), 255, SkinF.personalInfo_229[5]),
      ComColorButton("btn_common_character_1", GetUTF8Text("button_common_Arena"), Vector2(90, 20), Vector2(13, 5), 14, true, false, ARGB(255, 255, 255, 0), SkinF.personalInfo_role_attrib),
      ComColorButton("btn_common_character_2", GetUTF8Text("UI_lobby_explore_mode"), Vector2(90, 20), Vector2(106, 5), 14, true, false, ARGB(255, 204, 170, 0), SkinF.personalInfo_role_attrib),
      ComLabel(nil, GetUTF8Text("tips_abilities_HP"), Vector2(48, 17), Vector2(41, 23), 0, 14, colw),
      ComLabel(nil, GetUTF8Text("tips_abilities_Stamina"), Vector2(48, 17), Vector2(220, 23), 0, 14, colw),
      ComLabel(nil, GetUTF8Text("tips_abilities_Vitality"), Vector2(48, 17), Vector2(394, 23), 0, 14, colw),
      ComLabel(nil, GetUTF8Text("tips_abilities_Recovery"), Vector2(48, 17), Vector2(41, 43), 0, 14, colw),
      ComLabel(nil, GetUTF8Text("tips_abilities_Amor"), Vector2(48, 17), Vector2(220, 43), 0, 14, colw),
      ComLabel(nil, GetUTF8Text("tips_abilities_Armor_Penetration"), Vector2(48, 17), Vector2(394, 43), 0, 14, colw),
      ComLabel("main_par_1", nil, Vector2(90, 17), Vector2(38, 23), 0, 14, colw, "kAlignRightMiddle"),
      ComLabel("main_par_6", nil, Vector2(90, 17), Vector2(218, 23), 0, 14, colw, "kAlignRightMiddle"),
      ComLabel("main_par_2", nil, Vector2(90, 17), Vector2(394, 23), 0, 14, colw, "kAlignRightMiddle"),
      ComLabel("main_par_3", nil, Vector2(90, 17), Vector2(38, 43), 0, 14, colw, "kAlignRightMiddle"),
      ComLabel("main_par_4", nil, Vector2(90, 17), Vector2(218, 43), 0, 14, colw, "kAlignRightMiddle"),
      ComLabel("main_par_5", nil, Vector2(90, 17), Vector2(394, 43), 0, 14, colw, "kAlignRightMiddle"),
      ComLabel("explore_main_par_1", nil, Vector2(90, 17), Vector2(38, 23), 0, 14, colw, "kAlignRightMiddle"),
      ComLabel("explore_main_par_6", nil, Vector2(90, 17), Vector2(218, 23), 0, 14, colw, "kAlignRightMiddle"),
      ComLabel("explore_main_par_2", nil, Vector2(90, 17), Vector2(394, 23), 0, 14, colw, "kAlignRightMiddle"),
      ComLabel("explore_main_par_3", nil, Vector2(90, 17), Vector2(38, 43), 0, 14, colw, "kAlignRightMiddle"),
      ComLabel("explore_main_par_4", nil, Vector2(90, 17), Vector2(218, 43), 0, 14, colw, "kAlignRightMiddle"),
      ComLabel("explore_main_par_5", nil, Vector2(90, 17), Vector2(394, 43), 0, 14, colw, "kAlignRightMiddle")
    }),
    Gui.Control("power_hits")({
      Size = Vector2(400, 120),
      Location = Vector2(38, 60),
      BackgroundColor = colw,
      Skin = SkinF.lookInfo_004,
      Visible = false,
      ComLabel(nil, GetUTF8Text("tips_lobby_Ability_Desc1"), Vector2(140, 21), Vector2(10, 6), 0, 16, colw),
      ComLabel(nil, GetUTF8Text("tips_lobby_Ability_Desc2"), Vector2(140, 21), Vector2(210, 6), 0, 16, colw),
      ComLabel("pow_pf", 0, Vector2(100, 21), Vector2(150, 6), 0, 16, coly),
      ComLabel("pow_wf", 0, Vector2(100, 21), Vector2(350, 6), 0, 16, coly),
      ComLabel("pow_text", GetUTF8Text("tips_lobby_Ability_Desc3"), Vector2(380, 78), Vector2(10, 32), 0, 16, colw)
    }),
    Gui.Control("adventure_hints")({
      Size = Vector2(400, 120),
      Location = Vector2(45, 101),
      BackgroundColor = colw,
      Skin = SkinF.lookInfo_004,
      Visible = false,
      ComLabel(nil, GetUTF8Text("tips_lobby_character_explore"), Vector2(140, 21), Vector2(10, 6), 0, 16, colw),
      ComLabel(nil, GetUTF8Text("tips_lobby_explore_equipment_strength"), Vector2(140, 21), Vector2(210, 6), 0, 16, colw),
      ComLabel("label_tips_explore_hints", GetUTF8Text("tips_lobby_explore_master_strength"), Vector2(140, 21), Vector2(210, 6), 0, 16, colw),
      ComLabel("advent_wf", 0, Vector2(100, 21), Vector2(150, 6), 0, 16, colb),
      ComLabel("advent_pf", 0, Vector2(100, 21), Vector2(350, 6), 0, 16, colb),
      ComLabel("advent_text", GetUTF8Text("tips_lobby_explore_tips_01"), Vector2(380, 78), Vector2(10, 32), 0, 16, colw)
    })
  }),
  Gui.Control("left_main_2")({
    Size = Vector2(1142, 694),
    ComControl(nil, Vector2(1128, 645), Vector2(7, 45), 255, SkinF.personalInfo_098),
    ComControl("left_main_2_s1", Vector2(1127, 644), Vector2(17, 61)),
    MainTabBtn("btn_reinforce_" .. 1, GetUTF8Text("button_common_Avatar_Card"), Vector2(0, 5)),
    MainTabBtn("btn_reinforce_" .. 2, GetUTF8Text("button_common_Create_Gem"), Vector2(61, 5)),
    MainTabBtn("btn_reinforce_" .. 3, GetUTF8Text("button_common_Weapon"), Vector2(481, 5)),
    MainTabBtn("btn_reinforce_" .. 4, GetUTF8Text("id_datalist_weapon_padlock_02"), Vector2(691, 5)),
    MainTabBtn("btn_reinforce_" .. 5, GetUTF8Text("UI_common_make_01"), Vector2(901, 5)),
    MainTabBtn("btn_reinforce_" .. 6, GetUTF8Text("msgbox_enhance_mastered"), Vector2(901, 5))
  }),
  Gui.Control("left_main_pet")({
    Size = Vector2(508, 645),
    Location = Vector2(13, 16),
    Gui.CharacterAnimCard({
      Size = Vector2(508, 490)
    }),
    ComFuc.ComRotateBtn("left_rotate_2", nil, Vector2(32, 36), Vector2(418, 373), 0, false, SkinF.personalInfo_101),
    ComFuc.ComRotateBtn("right_rotate_2", nil, Vector2(32, 36), Vector2(456, 373), 0, false, SkinF.personalInfo_102),
    Gui.Control({
      Size = Vector2(494, 70),
      Location = Vector2(7, 415),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_225,
      ComControl(nil, Vector2(120, 60), Vector2(5, 3), 255, SkinF.personalInfo_228),
      ComControl(nil, Vector2(364, 60), Vector2(125, 3), 255, SkinF.personalInfo_228),
      ComControl(nil, Vector2(20, 17), Vector2(133, 26), 255, SkinF.personalInfo_229[1]),
      ComControl(nil, Vector2(20, 17), Vector2(253, 25), 255, SkinF.personalInfo_229[6]),
      ComControl(nil, Vector2(20, 17), Vector2(373, 25), 255, SkinF.personalInfo_229[2]),
      ComControl(nil, Vector2(20, 17), Vector2(133, 46), 255, SkinF.personalInfo_229[3]),
      ComControl(nil, Vector2(20, 17), Vector2(253, 46), 255, SkinF.personalInfo_229[4]),
      ComControl(nil, Vector2(20, 17), Vector2(373, 46), 255, SkinF.personalInfo_229[5]),
      ComLabel(nil, GetUTF8Text("tips_abilities_Power"), Vector2(70, 20), Vector2(14, 5), 0, 14, coly),
      ComLabel(nil, GetUTF8Text("UI_lobby_Character_Attribute"), Vector2(70, 20), Vector2(134, 5), 0, 14, coly),
      ComLabel("info_power_pet", 0, Vector2(120, 36), Vector2(10, 29), 0, 0, colw, nil, nil, true, SkinF.info_number_1),
      ComLabel(nil, GetUTF8Text("tips_abilities_HP"), Vector2(48, 17), Vector2(154, 23), 0, 14, colw),
      ComLabel(nil, GetUTF8Text("tips_abilities_Stamina"), Vector2(48, 17), Vector2(274, 23), 0, 14, colw),
      ComLabel(nil, GetUTF8Text("tips_abilities_Vitality"), Vector2(48, 17), Vector2(394, 23), 0, 14, colw),
      ComLabel(nil, GetUTF8Text("tips_abilities_Recovery"), Vector2(48, 17), Vector2(154, 43), 0, 14, colw),
      ComLabel(nil, GetUTF8Text("tips_abilities_Amor"), Vector2(48, 17), Vector2(274, 43), 0, 14, colw),
      ComLabel(nil, GetUTF8Text("tips_abilities_Armor_Penetration"), Vector2(48, 17), Vector2(394, 43), 0, 14, colw),
      ComLabel("main_par_1_pet", nil, Vector2(90, 17), Vector2(154, 23), 0, 14, colw, "kAlignRightMiddle"),
      ComLabel("main_par_6_pet", nil, Vector2(90, 17), Vector2(274, 23), 0, 14, colw, "kAlignRightMiddle"),
      ComLabel("main_par_2_pet", nil, Vector2(90, 17), Vector2(394, 23), 0, 14, colw, "kAlignRightMiddle"),
      ComLabel("main_par_3_pet", nil, Vector2(90, 17), Vector2(154, 43), 0, 14, colw, "kAlignRightMiddle"),
      ComLabel("main_par_4_pet", nil, Vector2(90, 17), Vector2(274, 43), 0, 14, colw, "kAlignRightMiddle"),
      ComLabel("main_par_5_pet", nil, Vector2(90, 17), Vector2(394, 43), 0, 14, colw, "kAlignRightMiddle")
    }),
    Gui.Control("power_hints_pet")({
      Size = Vector2(400, 120),
      Location = Vector2(6, 330),
      BackgroundColor = colw,
      Skin = SkinF.lookInfo_004,
      Visible = false,
      ComLabel(nil, GetUTF8Text("tips_lobby_Ability_Desc1"), Vector2(140, 21), Vector2(10, 6), 0, 16, colw),
      ComLabel(nil, GetUTF8Text("tips_lobby_Ability_Desc2"), Vector2(140, 21), Vector2(210, 6), 0, 16, colw),
      ComLabel("pow_pf_pet", 0, Vector2(100, 21), Vector2(150, 6), 0, 16, coly),
      ComLabel("pow_wf_pet", 0, Vector2(100, 21), Vector2(350, 6), 0, 16, coly),
      ComLabel("pow_text_pet", GetUTF8Text("tips_lobby_Ability_Desc3"), Vector2(380, 78), Vector2(10, 32), 0, 16, colw)
    }),
    Gui.Control("pet_left_bottom")({
      Size = Vector2(508, 126),
      Location = Vector2(0, 493),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComLabel("pet_left_bottom_title", GetUTF8Text("UI_inGame_pet_string_02"), Vector2(488, 24), Vector2(12, 4), 0, 16, colw),
      DepotPetSlot(1, -42, -50, PersonalInfo),
      DepotPetSlot(2, -42, -50, PersonalInfo),
      DepotPetSlot(3, -42, -50, PersonalInfo),
      DepotPetSlot(4, -42, -50, PersonalInfo),
      DepotPetSlot(5, -42, -50, PersonalInfo),
      ComButton("btn_pet_slot_expand", "", Vector2(32, 36), Vector2(8, 32), 16, false, false, SkinF.add_bag_button),
      ComButton("btn_pet_list_previous_page", "", Vector2(32, 36), Vector2(8, 80), 16, false, false, SkinF.page_001),
      ComButton("btn_pet_list_next_page", "", Vector2(32, 36), Vector2(470, 80), 16, false, false, SkinF.page_002)
    }),
    ComFuc.ComControl("coverControlpet", Vector2(1600, 1200), Vector2(0, 0), 0),
    ComFuc.ComControl("coverControlpet2", Vector2(1600, 1200), Vector2(0, 0), 0)
  }),
  Gui.Control("right_main_2")({
    Size = Vector2(592, 508),
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_206,
    ComLabel("sep_1", GetUTF8Text("button_common_Bag"), Vector2(582, 21), Vector2(14, 4), 0, 16, colw),
    ComControl("right_main_2_son", Vector2(573, 357), Vector2(10, 87), 255, SkinF.personalInfo_131),
    SecMainTabBtn("btn_depot_" .. 1, "   " .. GetUTF8Text("button_store_equipment_button"), Vector2(136, 38), Vector2(22, 52)),
    SecMainTabBtn("btn_depot_" .. 2, "   " .. GetUTF8Text("button_common_Item"), Vector2(136, 38), Vector2(160, 52)),
    SecMainTabBtn("btn_depot_" .. 3, "   " .. GetUTF8Text("button_common_Gesture"), Vector2(136, 38), Vector2(298, 52)),
    SecMainTabBtn("btn_depot_" .. 4, " " .. GetUTF8Text("button_common_Avatar_Card"), Vector2(136, 38), Vector2(436, 52)),
    ComButton("btn_depot_reorder", GetUTF8Text("button_common_Sort"), Vector2(71, 43), Vector2(501, 454), 16, false, true),
    ComFuc.ComPagesBar("pb_depot", Vector2(120, 458)),
    ComControl(nil, Vector2(38, 47), Vector2(20, 40), 255, SkinF.personalInfo_203[1], true, false),
    ComControl(nil, Vector2(38, 47), Vector2(158, 40), 255, SkinF.personalInfo_203[2], true, false),
    ComControl(nil, Vector2(38, 47), Vector2(296, 40), 255, SkinF.personalInfo_203[3], true, false),
    ComControl(nil, Vector2(38, 47), Vector2(434, 40), 255, SkinF.personalInfo_203[4], true, false),
    ComButton("btn_depot_repair_all", nil, Vector2(32, 36), Vector2(460, 458), 0, false, true, SkinF.personalInfo_213),
    ComButton("renew", GetUTF8Text("UI_common_Renewals_all"), Vector2(146, 38), Vector2(432, 6), 16, false, false, SkinF.renew_button),
    Gui.DepotDelBtn("btn_depot_del")({
      Size = Vector2(32, 36),
      Location = Vector2(23, 458),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_211[1],
      ComControl("btn_depot_del_c", Vector2(32, 36), Vector2(0, 0), 255, SkinF.skin_touming)
    }),
    ComFuc.ComButton("add_bag", nil, Vector2(32, 36), Vector2(63, 458), 0, false, false, SkinF.add_bag_button),
    Gui.DepotWeaponUpBtn("btn_depot_weapon_up")({
      Size = Vector2(32, 36),
      Location = Vector2(390, 458),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_weaponup[1],
      ComControl("btn_depot_weapon_up_c", Vector2(32, 36), Vector2(0, 0), 255, SkinF.skin_touming)
    }),
    Gui.DepotRepairBtn("btn_depot_repair")({
      Size = Vector2(32, 36),
      Location = Vector2(425, 458),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_212[1],
      ComControl("btn_depot_repair_c", Vector2(32, 36), Vector2(0, 0), 255, SkinF.skin_touming)
    })
  }),
  Gui.Control("right_main_3")({
    Size = Vector2(592, 508),
    Gui.Control("boss_skill")({
      Size = Vector2(592, 508),
      BackgroundColor = ComFuc.colw,
      Skin = SkinF.skill_type_select_background,
      ComButton("profession_skill_button_1", GetUTF8Text("UI_lobby_Class_Skill"), Vector2(127, 31), Vector2(0, 0), 16, false, false, SkinF.skill_type_select_button),
      ComButton("boss_skill_button_1", GetUTF8Text("UI_mission_copy_skill"), Vector2(127, 31), Vector2(127, 0), 16, false, false, SkinF.skill_type_select_button),
      Gui.Control({
        Size = Vector2(592, 477),
        Location = Vector2(0, 31),
        BackgroundColor = ARGB(0, 0, 0, 0),
        BossSkillShow(1),
        BossSkillShow(2),
        BossSkillShow(3),
        BossSkillShow(4),
        BossSkillShow(5),
        BossSkillShow(6),
        ComFuc.ComFlashArrow("boss_skill_drag_tip_1", Vector2(106, 42), Vector2(8, -5), 255, SkinF.lobbyMain_073, true, GetUTF8Text("button_common_skill_02")),
        ComFuc.ComFlashArrow("boss_skill_drag_tip_2", Vector2(106, 42), Vector2(296, -5), 255, SkinF.lobbyMain_073, true, GetUTF8Text("button_common_skill_02")),
        ComFuc.ComFlashArrow("boss_skill_drag_tip_3", Vector2(106, 42), Vector2(8, 136), 255, SkinF.lobbyMain_073, true, GetUTF8Text("button_common_skill_02")),
        ComFuc.ComFlashArrow("boss_skill_drag_tip_4", Vector2(106, 42), Vector2(296, 136), 255, SkinF.lobbyMain_073, true, GetUTF8Text("button_common_skill_02")),
        ComFuc.ComFlashArrow("boss_skill_drag_tip_5", Vector2(106, 42), Vector2(8, 277), 255, SkinF.lobbyMain_073, true, GetUTF8Text("button_common_skill_02")),
        ComFuc.ComFlashArrow("boss_skill_drag_tip_6", Vector2(106, 42), Vector2(296, 277), 255, SkinF.lobbyMain_073, true, GetUTF8Text("button_common_skill_02")),
        ComFuc.ComPagesBar("boss_skill_pages_bar", Vector2(160, 435))
      })
    }),
    Gui.Control("profession_skill")({
      Size = Vector2(592, 508),
      BackgroundColor = ComFuc.colw,
      Skin = SkinF.skill_type_select_background,
      ComButton("profession_skill_button_2", GetUTF8Text("UI_lobby_Class_Skill"), Vector2(127, 31), Vector2(0, 0), 16, false, false, SkinF.skill_type_select_button),
      ComButton("boss_skill_button_2", GetUTF8Text("UI_mission_copy_skill"), Vector2(127, 31), Vector2(127, 0), 16, false, false, SkinF.skill_type_select_button),
      ComButton("btn_skill_reset", GetUTF8Text("button_common_Reset"), Vector2(71, 43), Vector2(10, 459), 16, false, true),
      ComButton("btn_skill_finish", GetUTF8Text("button_common_Complete"), Vector2(84, 43), Vector2(494, 459), 16, false, true),
      SkillPointItem(1),
      SkillPointItem(2),
      SkillPointItem(3),
      SkillPointItem(4),
      SkillPointItem(5),
      ComFuc.ComFlashArrow("skill_drag_tip_1", Vector2(106, 42), Vector2(0, -10), 255, SkinF.lobbyMain_073, false, GetUTF8Text("button_common_skill_02")),
      ComFuc.ComFlashArrow("skill_drag_tip_2", Vector2(106, 42), Vector2(0, 74), 255, SkinF.lobbyMain_073, false, GetUTF8Text("button_common_skill_02")),
      ComFuc.ComFlashArrow("skill_drag_tip_3", Vector2(106, 42), Vector2(0, 158), 255, SkinF.lobbyMain_073, false, GetUTF8Text("button_common_skill_02")),
      ComFuc.ComFlashArrow("skill_drag_tip_4", Vector2(106, 42), Vector2(0, 242), 255, SkinF.lobbyMain_073, false, GetUTF8Text("button_common_skill_02")),
      ComFuc.ComFlashArrow("skill_drag_tip_5", Vector2(106, 42), Vector2(0, 326), 255, SkinF.lobbyMain_073, false, GetUTF8Text("button_common_skill_02")),
      ComFuc.ComControl(nil, Vector2(400, 38), Vector2(87, 463), 255, SkinF.personalInfo_088),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_abilities_Balance_Skill_Points"), Vector2(160, 21), Vector2(101, 471), 0, 16, colw),
      ComFuc.ComLabel("remain_skills", nil, Vector2(100, 21), Vector2(257, 471), 0, 16, coly)
    })
  }),
  Gui.Control("right_main_pet_1")({
    Size = Vector2(592, 618),
    Location = Vector2(525, 16),
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_pet_001,
    ComControl(nil, Vector2(592, 59), Vector2(0, 2), 255, SkinF.personalInfo_pet_002),
    ComLabel("pet_1_title", GetUTF8Text("UI_inGame_pet_string_03"), Vector2(520, 24), Vector2(24, 7), 0, 16, colw),
    Gui.CharacterAnimCard("pet_mesh_preview_1")({
      Size = Vector2(206, 216),
      Location = Vector2(193, 67),
      ID = 9
    }),
    ComControl("pet_mesh_preview_1_empty", Vector2(206, 216), Vector2(193, 67), 255, SkinF.personalInfo_pet_014),
    ComFuc.ComRotateBtn("left_rotate_pet_1", nil, Vector2(32, 36), Vector2(319, 237), 0, false, SkinF.personalInfo_101),
    ComFuc.ComRotateBtn("right_rotate_pet_1", nil, Vector2(32, 36), Vector2(357, 237), 0, false, SkinF.personalInfo_102),
    ComLabel("pet_desc", GetUTF8Text("UI_pet_choice"), Vector2(378, 79), Vector2(107, 294), 0, 16, ARGB(255, 82, 54, 44), "kAlignCenterMiddle"),
    Gui.Control({
      Size = Vector2(464, 110),
      Location = Vector2(64, 381),
      BackgroundColor = colw,
      Skin = SkinF.battle_005,
      ComFuc.DepotPetCandidateBox(1, -66, -67, PersonalInfo),
      ComFuc.DepotPetCandidateBox(2, -66, -67, PersonalInfo),
      ComFuc.DepotPetCandidateBox(3, -66, -67, PersonalInfo),
      ComFuc.DepotPetCandidateBox(4, -66, -67, PersonalInfo),
      ComFuc.DepotPetCandidateBox(5, -66, -67, PersonalInfo)
    }),
    ComFuc.ComPagesBar("page_bar_sys_pet", Vector2(164, 500)),
    ComButton("btn_create_new_pet", GetUTF8Text("UI_common_buy_adopt"), Vector2(200, 53), Vector2(196, 540), 16, false, true, SkinF.select_character_038, false)
  }),
  Gui.Control("right_main_pet_2")({
    Size = Vector2(592, 618),
    Location = Vector2(525, 16),
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_pet_001,
    ComControl(nil, Vector2(592, 59), Vector2(0, 2), 255, SkinF.personalInfo_pet_002),
    ComLabel("pet_2_title1", GetUTF8Text("UI_inGame_pet_string_06"), Vector2(520, 24), Vector2(24, 7), 0, 16, colw),
    Gui.Control({
      Size = Vector2(336, 270),
      Location = Vector2(23, 41),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_pet_003,
      ComLabel(nil, GetUTF8Text("UI_inGame_pet_string_07"), Vector2(64, 30), Vector2(12, 18), 0, 16, colw),
      ComLabel(nil, GetUTF8Text("UI_inGame_pet_string_08"), Vector2(64, 30), Vector2(12, 56), 0, 16, colw),
      ComLabel(nil, GetUTF8Text("UI_inGame_pet_string_09"), Vector2(64, 30), Vector2(12, 94), 0, 16, colw),
      ComLabel("pet_info_name", "PlaceHolder", Vector2(150, 30), Vector2(80, 18), 0, 16, colw),
      ComControl("pet_info_mood", Vector2(37, 31), Vector2(80, 56), 255, SkinF.personalInfo_pet_mood[4]),
      ComControl("pet_quality_1", Vector2(30, 30), Vector2(80, 94), 255, SkinF.personalInfo_pet_star[1]),
      ComControl("pet_quality_2", Vector2(30, 30), Vector2(108, 94), 255, SkinF.personalInfo_pet_star[1]),
      ComControl("pet_quality_3", Vector2(30, 30), Vector2(136, 94), 255, SkinF.personalInfo_pet_star[1]),
      ComControl("pet_quality_4", Vector2(30, 30), Vector2(164, 94), 255, SkinF.personalInfo_pet_star[1]),
      ComControl("pet_quality_5", Vector2(30, 30), Vector2(192, 94), 255, SkinF.personalInfo_pet_star[1]),
      ExpBar.ComExpBar("pet_info_exp", Vector2(308, 18), Vector2(16, 134), 50, 100, SkinF.personalInfo_pet_expbar[1], SkinF.personalInfo_pet_expbar[2], "kAlignLeftMiddle", true),
      Gui.Control({
        Size = Vector2(92, 122),
        Location = Vector2(234, 10),
        BackgroundColor = colw,
        Skin = SkinF.personalInfo_pet_005,
        ComButton("btn_pet_rename", GetUTF8Text("UI_inGame_pet_string_10"), Vector2(84, 40), Vector2(4, 2), 16, false, true),
        ComButton("btn_pet_pacify", GetUTF8Text("UI_inGame_pet_string_11"), Vector2(84, 40), Vector2(4, 40), 16, false, true),
        ComButton("btn_pet_feed", GetUTF8Text("UI_inGame_pet_string_12"), Vector2(84, 40), Vector2(4, 78), 16, false, true)
      }),
      Gui.Control("pet_food_page")({
        Size = Vector2(308, 96),
        Location = Vector2(16, 159),
        BackgroundColor = colw,
        Skin = SkinF.personalInfo_pet_005,
        Gui.Control({
          Size = Vector2(80, 80),
          Location = Vector2(8, 8),
          BackgroundColor = col0,
          Skin = SkinF.personalInfo_083[1],
          ComControl("pet_food_grade", Vector2(80, 80), Vector2(0, 0), 255, SkinF.skin_touming),
          ComControl("pet_food_icon", Vector2(80, 80), Vector2(0, 0), 255, SkinF.skin_touming),
          ComLabel("pet_food_number", nil, Vector2(60, 18), Vector2(20, 59), 0, 0, col0, "kAlignRightMiddle", nil, false, SkinF.hecheng_number_1)
        }),
        ComLabel("pet_food_name", "Green Food", Vector2(205, 39), Vector2(96, 8), 0, 16, colw, "kAlignLeftMiddle"),
        Gui.Button("buy_pet_food")({
          Style = "ButtonShopBuy",
          Location = Vector2(96, 44),
          Size = Vector2(74, 40),
          Text = GetUTF8Text("UI_inGame_pet_string_13"),
          ClickAudio = "buy"
        })
      })
    }),
    ComButton("battle_or_rest", GetUTF8Text("UI_pet_switch_02"), Vector2(206, 53), Vector2(366, 38), 16, false, true, SkinF.select_character_038),
    Gui.CharacterAnimCard("pet_mesh_preview_2")({
      Size = Vector2(206, 216),
      Location = Vector2(366, 94),
      ID = 9
    }),
    ComControl("pet_mesh_bad_cover", Vector2(206, 216), Vector2(366, 94), 255, SkinF.personalInfo_pet_015, false, true, ARGB(255, 255, 255, 255), GetUTF8Text("UI_pet_predicable_04")),
    ComFuc.ComRotateBtn("left_rotate_pet_2", nil, Vector2(32, 36), Vector2(492, 264), 0, false, SkinF.personalInfo_101),
    ComFuc.ComRotateBtn("right_rotate_pet_2", nil, Vector2(32, 36), Vector2(530, 264), 0, false, SkinF.personalInfo_102),
    ComControl(nil, Vector2(592, 59), Vector2(0, 317), 255, SkinF.personalInfo_pet_002),
    ComLabel("pet_2_title2", GetUTF8Text("UI_inGame_pet_string_15"), Vector2(520, 24), Vector2(24, 322), 0, 16, colw),
    Gui.Control({
      Size = Vector2(544, 100),
      Location = Vector2(22, 356),
      BackgroundColor = colw,
      Skin = SkinF.battle_005,
      Gui.Control({
        Size = Vector2(525, 82),
        Location = Vector2(10, 11),
        BackgroundColor = colw,
        Skin = SkinF.personalInfo_pet_008,
        Gui.Control("pet_info_skill_icon")({
          Size = Vector2(70, 70),
          Location = Vector2(7, 2),
          BackgroundColor = colw,
          Skin = SkinF.skin_touming
        }),
        ComLabel("pet_info_skill_name", "Ao Ao", Vector2(364, 22), Vector2(107, 8), 0, 16, colw),
        ComControl(nil, Vector2(364, 31), Vector2(111, 33), 255, SkinF.personalInfo_135),
        ComFuc.LimitControl("pet_info_skill_level", Vector2(364, 31), Vector2(111, 33), SkinF.personalInfo_137),
        ComButton("btn_pet_skill_setting", "", Vector2(32, 60), Vector2(485, 7), 16, false, true, SkinF.personalInfo_134)
      })
    }),
    ComControl(nil, Vector2(592, 59), Vector2(0, 462), 255, SkinF.personalInfo_pet_002),
    ComLabel("pet_2_title3", GetUTF8Text("UI_inGame_pet_string_18"), Vector2(520, 24), Vector2(24, 467), 0, 16, colw),
    Gui.Control({
      Size = Vector2(456, 100),
      Location = Vector2(22, 504),
      BackgroundColor = colw,
      Skin = SkinF.battle_005,
      ComFuc.DepotPetOpShowBox(1, -71, -75),
      ComFuc.DepotPetOpShowBox(2, -71, -75),
      ComFuc.DepotPetOpShowBox(3, -71, -75),
      ComFuc.DepotPetOpShowBox(4, -71, -75),
      ComFuc.DepotPetOpShowBox(5, -71, -75)
    }),
    ComButton("pet_op_setting", GetUTF8Text("UI_inGame_pet_string_19"), Vector2(100, 53), Vector2(480, 527), 16, false, true, SkinF.select_character_038)
  }),
  ComFuc.ComControl("pet_coverControl", Vector2(1600, 1200), Vector2(0, 0), 0, nil, true, true, ARGB(100, 0, 0, 0)),
  Gui.Control("pet_op_ui_main")({
    Size = Vector2(757, 538),
    Dock = "kDockCenter",
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_207,
    Gui.Control({
      Size = Vector2(757, 32),
      Location = Vector2(0, 0),
      ComFuc.ComLabel("pet_op_title", GetUTF8Text("UI_inGame_pet_string_20"), Vector2(708, 24), Vector2(12, 4), 0, 16, colw),
      ComFuc.ComButton("pet_op_close", nil, Vector2(24, 24), Vector2(726, 4), 0, false, false, SkinF.lookInfo_002)
    }),
    ComFuc.DepotPetOpBar(1, 14, 41),
    ComFuc.DepotPetOpBar(2, 14, 137),
    ComFuc.DepotPetOpBar(3, 14, 233),
    ComFuc.DepotPetOpBar(4, 14, 329),
    ComFuc.DepotPetOpBar(5, 14, 425),
    Gui.Control({
      Size = Vector2(270, 378),
      Location = Vector2(468, 39),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_pet_011,
      ComFuc.ComLabel(nil, GetUTF8Text("UI_character_Quick_Key_Slot"), Vector2(239, 22), Vector2(12, 4), 0, 16, colw),
      ComFuc.DepotPetOpItem(1, -76, -48, PersonalInfo),
      ComFuc.DepotPetOpItem(2, -76, -48, PersonalInfo),
      ComFuc.DepotPetOpItem(3, -76, -48, PersonalInfo),
      ComFuc.DepotPetOpItem(4, -76, -48, PersonalInfo),
      ComFuc.DepotPetOpItem(5, -76, -48, PersonalInfo),
      ComFuc.DepotPetOpItem(6, -76, -48, PersonalInfo),
      ComFuc.DepotPetOpItem(7, -76, -48, PersonalInfo),
      ComFuc.DepotPetOpItem(8, -76, -48, PersonalInfo),
      ComFuc.DepotPetOpItem(9, -76, -48, PersonalInfo),
      ComFuc.DepotPetOpItem(10, -76, -48, PersonalInfo),
      ComFuc.DepotPetOpItem(11, -76, -48, PersonalInfo),
      ComFuc.DepotPetOpItem(12, -76, -48, PersonalInfo)
    }),
    Gui.Control({
      Size = Vector2(272, 94),
      Location = Vector2(468, 425),
      BackgroundColor = colw,
      Skin = SkinF.battle_005,
      ComFuc.ComLabel("pet_op_setting_hint", GetUTF8Text("UI_pet_function_08"), Vector2(262, 94), Vector2(5, 0), 0, 16, ARGB(255, 82, 54, 44), "kAlignCenterMiddle")
    })
  }),
  Gui.Control("pet_skill_ui_main")({
    Size = Vector2(412, 220),
    Dock = "kDockCenter",
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_206,
    ComControl(nil, Vector2(386, 100), Vector2(12, 40), 255, SkinF.battle_005),
    ComLabel(nil, "  " .. GetUTF8Text("UI_avatar_avatar_UI_06"), Vector2(302, 21), Vector2(5, 4), 0, 16, colw),
    ComLabel("pet_skill_upgrade_popup_msg", "", Vector2(366, 80), Vector2(22, 50), 0, 16, cols, "kAlignCenterMiddle"),
    ComButton("pet_skill_upgrade_btn", GetUTF8Text("UI_inGame_pet_string_28"), Vector2(140, 53), Vector2(136, 148), 16, false, false, SkinF.avatar_main_089),
    ComButton("pet_skill_upgrade_cancel_btn", GetUTF8Text("button_common_Cancel"), Vector2(140, 53), Vector2(136, 148), 16),
    ComButton("pet_skill_close", nil, Vector2(24, 24), Vector2(380, 4), 0, false, false, SkinF.lookInfo_002)
  }),
  ComFuc.MainTabBtn("card_tab_embed", GetUTF8Text("button_common_Embed"), Vector2(21, 1), Vector2(129, 31), SkinF.level_master_btn, true),
  ComFuc.MainTabBtn("card_tab_inheirt", GetUTF8Text("UI_lobby_explore_inherit"), Vector2(150, 1), Vector2(129, 31), SkinF.level_master_btn, true),
  Gui.Control("ctrl_reinforce_1")({
    Size = Vector2(1105, 619),
    Gui.Control({
      Size = Vector2(592, 307),
      Location = Vector2(512, 0),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComLabel(nil, GetUTF8Text("button_common_Avatar_Card"), Vector2(582, 21), Vector2(14, 4), 0, 16, colw),
      ComFuc.ComPagesBar("pb_reinPerson", Vector2(166, 250)),
      ComFuc.CardKeyCB(1, "reinPerson", -79, -111, 0, PersonalInfo),
      ComFuc.CardKeyCB(2, "reinPerson", -79, -111, 0, PersonalInfo),
      ComFuc.CardKeyCB(3, "reinPerson", -79, -111, 0, PersonalInfo),
      ComFuc.CardKeyCB(4, "reinPerson", -79, -111, 0, PersonalInfo),
      ComFuc.CardKeyCB(5, "reinPerson", -79, -111, 0, PersonalInfo)
    }),
    Gui.Control({
      Size = Vector2(592, 307),
      Location = Vector2(512, 312),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_206,
      ComLabel(nil, GetUTF8Text("UI_enhance_Usable_Material"), Vector2(582, 21), Vector2(14, 4), 0, 16, colw),
      ComFuc.ComPagesBar("pb_reinStone", Vector2(166, 250)),
      DepotCB(1, "reinStone", -45, -29, 3, PersonalInfo),
      DepotCB(2, "reinStone", -45, -29, 3, PersonalInfo),
      DepotCB(3, "reinStone", -45, -29, 3, PersonalInfo),
      DepotCB(4, "reinStone", -45, -29, 3, PersonalInfo),
      DepotCB(5, "reinStone", -45, -29, 3, PersonalInfo),
      DepotCB(6, "reinStone", -45, -29, 3, PersonalInfo),
      DepotCB(7, "reinStone", -45, -29, 3, PersonalInfo),
      DepotCB(8, "reinStone", -45, -29, 3, PersonalInfo),
      DepotCB(9, "reinStone", -45, -29, 3, PersonalInfo),
      DepotCB(10, "reinStone", -45, -29, 3, PersonalInfo),
      DepotCB(11, "reinStone", -45, -29, 3, PersonalInfo),
      DepotCB(12, "reinStone", -45, -29, 3, PersonalInfo)
    }),
    Gui.Control({
      Size = Vector2(491, 590),
      Location = Vector2(8, 30),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_214,
      ComControl(nil, Vector2(30, 30), Vector2(204, 537), 255, SkinF.shop_02),
      ComLabel(nil, " " .. GetUTF8Text("UI_enhance_Embed_Fee"), Vector2(80, 20), Vector2(20, 542), 0, 16, colw),
      ComLabel("combIns_cost", "100  ", Vector2(105, 30), Vector2(100, 537), 255, 16, colw, "kAlignRightMiddle", SkinF.personalInfo_215),
      ComButton("btn_insert", nil, Vector2(163, 63), Vector2(307, 515), 0, false, true, SkinF.personalInfo_184, true, "inlay"),
      Gui.Control({
        Size = Vector2(468, 512),
        Location = Vector2(11, 11),
        BackgroundColor = colw,
        Skin = SkinF.personalInfo_171,
        ComLabel(nil, GetUTF8Text("UI_avatar_Avatar_Card_Attribute"), Vector2(200, 20), Vector2(134, 22), 0, 16, coly, "kAlignCenterMiddle"),
        ComLabel(nil, GetUTF8Text("tips_abilities_Stamina"), Vector2(150, 22), Vector2(140, 48), 0, 16, coly),
        ComLabel(nil, GetUTF8Text("tips_abilities_Vitality"), Vector2(150, 22), Vector2(140, 70), 0, 16, coly),
        ComLabel(nil, GetUTF8Text("tips_abilities_Amor"), Vector2(150, 22), Vector2(140, 92), 0, 16, coly),
        ComLabel(nil, GetUTF8Text("tips_abilities_Recovery"), Vector2(150, 22), Vector2(140, 114), 0, 16, coly),
        ComLabel("insert_life", "+0", Vector2(60, 22), Vector2(300, 48), 0, 16, colw, "kAlignRightMiddle"),
        ComLabel("insert_add", "+0", Vector2(60, 22), Vector2(300, 70), 0, 16, colw, "kAlignRightMiddle"),
        ComLabel("insert_protect", "+0", Vector2(60, 22), Vector2(300, 92), 0, 16, colw, "kAlignRightMiddle"),
        ComLabel("insert_recover", "+0", Vector2(60, 22), Vector2(300, 114), 0, 16, colw, "kAlignRightMiddle"),
        ComFlashNew("ins_ti_1", Vector2(24, 31), Vector2(224, 347), 255, SkinF.personalInfo_232[1], false),
        ComFlashNew("ins_ti_2", Vector2(49, 46), Vector2(130, 207), 255, SkinF.personalInfo_232[2], false),
        ComFlashNew("ins_ti_3", Vector2(49, 46), Vector2(291, 207), 255, SkinF.personalInfo_232[3], false),
        ComFlashNew("ins_ti_4", Vector2(49, 68), Vector2(130, 291), 255, SkinF.personalInfo_232[4], false),
        ComFlashNew("ins_ti_5", Vector2(49, 68), Vector2(291, 291), 255, SkinF.personalInfo_232[5], false),
        InsertSlot(1, Vector2(189, 376)),
        InsertSlot(2, Vector2(40, 166)),
        InsertSlot(3, Vector2(337, 166)),
        InsertSlot(4, Vector2(40, 313)),
        InsertSlot(5, Vector2(337, 313)),
        ComButton("remove_stone_btn_1", GetUTF8Text("button_common_extirpate_01"), Vector2(72, 41), Vector2(199, 472), 16, false, false, SkinF.skin_playgame_037),
        ComButton("remove_stone_btn_2", GetUTF8Text("button_common_extirpate_01"), Vector2(72, 41), Vector2(50, 262), 16, false, false, SkinF.skin_playgame_037),
        ComButton("remove_stone_btn_3", GetUTF8Text("button_common_extirpate_01"), Vector2(72, 41), Vector2(347, 262), 16, false, false, SkinF.skin_playgame_037),
        ComButton("remove_stone_btn_4", GetUTF8Text("button_common_extirpate_01"), Vector2(72, 41), Vector2(50, 409), 16, false, false, SkinF.skin_playgame_037),
        ComButton("remove_stone_btn_5", GetUTF8Text("button_common_extirpate_01"), Vector2(72, 41), Vector2(347, 409), 16, false, false, SkinF.skin_playgame_037),
        Gui.Control("insert_card_p")({
          Size = Vector2(104, 163),
          Location = Vector2(183, 180),
          Hint = GetUTF8Text("UI_enhance_additional_string_142"),
          BackgroundColor = colw,
          Skin = SkinF.skin_touming,
          Gui.DragBtn("insert_card")({
            Size = Vector2(104, 163),
            BackgroundColor = colw,
            Skin = SkinF.personalInfo_143,
            ComFuc.ComCharacterStaticCard("insert_card_s", 9),
            ComControl("insert_card_s2", Vector2(104, 163), Vector2(0, 0), 255, SkinF.personalInfo_144),
            Gui.Control("insert_card_level")({
              Size = Vector2(45, 20),
              Location = Vector2(30, 131),
              BackgroundColor = colw,
              Skin = SkinF.avatar_level,
              Visible = false,
              ComLabel("insert_card_level_text", nil, Vector2(45, 20), Vector2(0, 0), 0, 15, colw, "kAlignCenterMiddle")
            })
          })
        }),
        ComFlashNew("insert_card_hight", Vector2(104, 163), Vector2(183, 180), 255, SkinF.personalInfo_175)
      })
    })
  }),
  Gui.Control("ctrl_reinforce_2")({
    Size = Vector2(1105, 619),
    ReinDepotCtrl(Vector2(592, 619), Vector2(512, 0), Vector2(166, 568), GetUTF8Text("UI_enhance_Usable_Material"), "reinMedal", DepotCB, 36, -45, -29, 3),
    Gui.Control({
      Size = Vector2(491, 604),
      Location = Vector2(8, 7),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_214,
      ComControl(nil, Vector2(30, 30), Vector2(204, 537), 255, SkinF.shop_02),
      ComLabel(nil, " " .. GetUTF8Text("UI_enhance_Compound_Fee"), Vector2(80, 20), Vector2(20, 542), 0, 16, colw),
      ComLabel("combMix_cost", "100  ", Vector2(105, 30), Vector2(100, 537), 255, 16, colw, "kAlignRightMiddle", SkinF.personalInfo_215),
      ComButton("btn_combMix", nil, Vector2(163, 63), Vector2(307, 519), 0, false, true, SkinF.personalInfo_185, true, "gem_compound"),
      Gui.Control({
        Size = Vector2(440, 440),
        Location = Vector2(25, 51),
        BackgroundColor = colw,
        Skin = SkinF.personalInfo_176,
        ComFlashNew("mix_daqu", Vector2(440, 440), Vector2(0, 0), 255, SkinF.personalInfo_177, false),
        ComFlashNew("mix_ti_1", Vector2(30, 48), Vector2(205, 112), 255, SkinF.personalInfo_179, false),
        ComFlashNew("mix_ti_2", Vector2(46, 50), Vector2(274, 158), 255, SkinF.personalInfo_180, false),
        ComFlashNew("mix_ti_3", Vector2(58, 38), Vector2(258, 261), 255, SkinF.personalInfo_181, false),
        ComFlashNew("mix_ti_4", Vector2(58, 38), Vector2(124, 261), 255, SkinF.personalInfo_182, false),
        ComFlashNew("mix_ti_5", Vector2(46, 50), Vector2(120, 158), 255, SkinF.personalInfo_183, false),
        ComControl(nil, Vector2(114, 130), Vector2(163, 155), 255, SkinF.personalInfo_202[1]),
        Gui.ElasticCtrl("mix_center")({
          Size = Vector2(114, 0),
          GoalSize = Vector2(114, 0),
          Location = Vector2(163, 155),
          BackgroundColor = col0,
          ComControl(nil, Vector2(114, 130), Vector2(0, 0), 255, SkinF.personalInfo_202[2])
        }),
        MixSlot(1, Vector2(180, 28)),
        MixSlot(2, Vector2(324, 132)),
        MixSlot(3, Vector2(277, 301)),
        MixSlot(4, Vector2(81, 301)),
        MixSlot(5, Vector2(36, 132)),
        ComLabel("need_to_medal", nil, Vector2(80, 80), Vector2(180, 180), 0, 16, coly, "kAlignCenterMiddle")
      }),
      ComLabel(nil, " " .. GetUTF8Text("UI_enhance_Gem_Compound_Tips"), Vector2(450, 20), Vector2(20, 25), 0, 16, colw)
    })
  }),
  Gui.Control("ctrl_reinforce_3")({
    ComFuc.MainTabBtn("ctrl_reinforce_3_1", GetUTF8Text("button_common_Enhance_Weapon"), Vector2(25, 5), Vector2(169, 33), SkinF.level_master_btn, true),
    ComFuc.MainTabBtn("ctrl_reinforce_4_1", GetUTF8Text("id_datalist_weapon_padlock_02"), Vector2(194, 5), Vector2(169, 33), SkinF.level_master_btn, true),
    Size = Vector2(1128, 645),
    Gui.Control({
      Size = Vector2(1083, 581),
      Location = Vector2(11, 38),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_243,
      ComControl("red_bar", Vector2(0, 0), Vector2(40, 16), 255, SkinF.personalInfo_244[1]),
      ComControl("blue_bar", Vector2(0, 0), Vector2(40, 16), 255, SkinF.personalInfo_244[2]),
      ComControl("yellow_bar", Vector2(0, 0), Vector2(40, 16), 255, SkinF.personalInfo_244[3]),
      ComLabel("yellow_text", nil, Vector2(1000, 32), Vector2(40, 13), 0, 16, colw, "kAlignCenterMiddle"),
      ComLabel(nil, GetUTF8Text("UI_social_new_enhance_desc_02"), Vector2(285, 24), Vector2(45, 15), 0, 16, ARGB(255, 0, 54, 255), "kAlignLeftMiddle"),
      ComLabel("next_refitExpLevel", GetUTF8Text("UI_social_new_enhance_desc_03"), Vector2(65, 24), Vector2(969, 15), 0, 16, ARGB(255, 0, 54, 255), "kAlignRightMiddle"),
      ComLabel(nil, GetUTF8Text("button_common_Weapon"), Vector2(232, 24), Vector2(48, 85), 0, 16, colw, "kAlignCenterMiddle"),
      ComLabel(nil, GetUTF8Text("UI_social_new_enhance_desc_04"), Vector2(232, 24), Vector2(804, 85), 0, 16, colw, "kAlignCenterMiddle"),
      ComControl("refit_Rhand", Vector2(69, 100), Vector2(645, 50), 255, SkinF.personalInfo_218),
      RefitMetrial(1, Vector2(319, 326)),
      RefitMetrial(2, Vector2(543, 326)),
      RefitMetrial(3, Vector2(319, 406)),
      RefitMetrial(4, Vector2(543, 406)),
      Gui.Label("refit_opTip")({
        Size = Vector2(448, 146),
        Location = Vector2(320, 330),
        BackgroundColor = colw,
        Skin = SkinF.personalInfo_226,
        FontSize = 16,
        AutoWrap = true,
        TextPadding = Vector4(12, 8, 12, 8)
      }),
      ComLabel("refit_opTip_2", " " .. GetUTF8Text("UI_enhance_additional_string_144"), Vector2(448, 146), Vector2(320, 357), 255, 16, colg, "kAlignCenterMiddle", SkinF.personalInfo_215),
      Gui.Control({
        Size = Vector2(420, 60),
        Location = Vector2(333, 266),
        ComRefitLveContent(1, Vector2(0, 0)),
        ComRefitLveContent(2, Vector2(249, 0)),
        ComRefitLveContent(3, Vector2(478, 0)),
        ComRefitLveContent(4, Vector2(728, 0))
      }),
      Gui.Control({
        Size = Vector2(420, 336),
        Location = Vector2(308, 11),
        ComLabel(nil, GetUTF8Text("tips_store_Weapon_lottery"), Vector2(80, 80), Vector2(168, 113), 0, 16, colh, "kAlignCenterMiddle"),
        ComControl("equip_pd_13", Vector2(80, 80), Vector2(168, 113), 0),
        ComFuc.ComDragBtn("equip_b_13", nil, Vector2(80, 80), Vector2(168, 113), 0, 255),
        Gui.Control("equip_level_13")({
          Size = Vector2(27, 29),
          Location = Vector2(221, 113),
          BackgroundColor = colw,
          Skin = SkinF.personalInfo_245[1],
          Visible = false,
          Enable = false,
          ComFuc.ComLabel("equip_level_text_13", nil, Vector2(27, 14), Vector2(0, 6), 0, 12, colw, "kAlignCenterMiddle")
        }),
        ComFlashNew("equip_c_13", Vector2(80, 80), Vector2(168, 113), 255, SkinF.personalInfo_173, false),
        ComControl("refit_point", Vector2(42, 42), Vector2(64, 165), 255, SkinF.personalInfo_219[1]),
        ComControl("refit_Ldoor", Vector2(88, 161), Vector2(70, 74), 255, SkinF.personalInfo_223[1]),
        ComControl("refit_Rdoor", Vector2(87, 161), Vector2(262, 74), 255, SkinF.personalInfo_223[2]),
        LimitControl("refit_Tbar", Vector2(66, 24), Vector2(175, 39), SkinF.personalInfo_220[1], 255),
        LimitControl("refit_water", Vector2(48, 68), Vector2(19, 117), SkinF.personalInfo_227, 255)
      }),
      ComControl("equip_pd_14", Vector2(80, 80), Vector2(666, 152), 0),
      ComFuc.ComDragBtn("equip_b_14", nil, Vector2(80, 80), Vector2(666, 152), 0, 255),
      Gui.Control("equip_level_14")({
        Size = Vector2(27, 29),
        Location = Vector2(716, 152),
        BackgroundColor = colw,
        Skin = SkinF.personalInfo_245[1],
        Visible = false,
        Enable = false,
        ComFuc.ComLabel("equip_level_text_14", nil, Vector2(27, 14), Vector2(0, 6), 0, 12, colw, "kAlignCenterMiddle")
      }),
      ComFlashNew("equip_c_14", Vector2(80, 80), Vector2(666, 152), 255, SkinF.personalInfo_173, false),
      DepotCB(1, "reinWeapon", -53, 55, 2, PersonalInfo, 3, SkinF.skin_touming, -1),
      DepotCB(2, "reinWeapon", -53, 55, 2, PersonalInfo, 3, SkinF.skin_touming, -1),
      DepotCB(3, "reinWeapon", -53, 55, 2, PersonalInfo, 3, SkinF.skin_touming, -1),
      DepotCB(4, "reinWeapon", -53, 55, 2, PersonalInfo, 3, SkinF.skin_touming, -1),
      DepotCB(5, "reinWeapon", -53, 55, 2, PersonalInfo, 3, SkinF.skin_touming, -1),
      DepotCB(6, "reinWeapon", -53, 55, 2, PersonalInfo, 3, SkinF.skin_touming, -1),
      DepotCB(7, "reinWeapon", -53, 55, 2, PersonalInfo, 3, SkinF.skin_touming, -1),
      DepotCB(8, "reinWeapon", -53, 55, 2, PersonalInfo, 3, SkinF.skin_touming, -1),
      DepotCB(9, "reinWeapon", -53, 55, 2, PersonalInfo, 3, SkinF.skin_touming, -1),
      DepotCB(10, "reinWeapon", -53, 55, 2, PersonalInfo, 3, SkinF.skin_touming, -1),
      DepotCB(11, "reinWeapon", -53, 55, 2, PersonalInfo, 3, SkinF.skin_touming, -1),
      DepotCB(12, "reinWeapon", -53, 55, 2, PersonalInfo, 3, SkinF.skin_touming, -1),
      ComFuc.ComPagesBar("pb_reinWeapon", Vector2(26, 496)),
      DepotCB(1, "reinMaterial", 715, 55, 2, PersonalInfo, 3, SkinF.skin_touming, -1),
      DepotCB(2, "reinMaterial", 715, 55, 2, PersonalInfo, 3, SkinF.skin_touming, -1),
      DepotCB(3, "reinMaterial", 715, 55, 2, PersonalInfo, 3, SkinF.skin_touming, -1),
      DepotCB(4, "reinMaterial", 715, 55, 2, PersonalInfo, 3, SkinF.skin_touming, -1),
      DepotCB(5, "reinMaterial", 715, 55, 2, PersonalInfo, 3, SkinF.skin_touming, -1),
      DepotCB(6, "reinMaterial", 715, 55, 2, PersonalInfo, 3, SkinF.skin_touming, -1),
      DepotCB(7, "reinMaterial", 715, 55, 2, PersonalInfo, 3, SkinF.skin_touming, -1),
      DepotCB(8, "reinMaterial", 715, 55, 2, PersonalInfo, 3, SkinF.skin_touming, -1),
      DepotCB(9, "reinMaterial", 715, 55, 2, PersonalInfo, 3, SkinF.skin_touming, -1),
      DepotCB(10, "reinMaterial", 715, 55, 2, PersonalInfo, 3, SkinF.skin_touming, -1),
      DepotCB(11, "reinMaterial", 715, 55, 2, PersonalInfo, 3, SkinF.skin_touming, -1),
      DepotCB(12, "reinMaterial", 715, 55, 2, PersonalInfo, 3, SkinF.skin_touming, -1),
      ComFuc.ComPagesBar("pb_reinMaterial", Vector2(797, 496)),
      ComLabel(nil, " " .. GetUTF8Text("UI_enhance_additional_string_143"), Vector2(80, 20), Vector2(316, 514), 0, 16, colw),
      ComLabel("refit_cost", "0  ", Vector2(105, 30), Vector2(396, 514), 255, 16, colw, "kAlignRightMiddle", SkinF.personalInfo_215),
      ComControl(nil, Vector2(30, 30), Vector2(500, 514), 255, SkinF.shop_02),
      ComButton("btn_combRefit", nil, Vector2(163, 63), Vector2(603, 496), 0, false, true, SkinF.personalInfo_186, true),
      ComFuc.ComAutoLcLabel("Tips_To_DragMetrailWeapon", 255, SkinF.lookInfo_004, false, GetUTF8Text("UI_datalist_UP05"))
    })
  }),
  Gui.Control("ctrl_reinforce_4")({
    Size = Vector2(1128, 645),
    Gui.Control({
      Size = Vector2(1083, 583),
      Location = Vector2(11, 36),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_246,
      ComControl("hang_bar", Vector2(225, 30), Vector2(812, 28), 255, SkinF.personalInfo_244[3]),
      ComLabel("hang_value", "+ 0", Vector2(70, 26), Vector2(810, 70), 0, 16, colt, "kAlignCenterMiddle"),
      ComControl(nil, Vector2(35, 31), Vector2(851, 182), 255, SkinF.personalInfo_248[1]),
      ComControl(nil, Vector2(35, 31), Vector2(1022, 182), 255, SkinF.personalInfo_248[2]),
      Gui.Control("hang_opTip_p")({
        Size = Vector2(510, 198),
        Location = Vector2(525, 286),
        BackgroundColor = colw,
        Skin = SkinF.personalInfo_258,
        ComLabel("hang_opTip", GetUTF8Text("id_datalist_weapon_padlock_07"), Vector2(448, 146), Vector2(31, 26), 255, 16, colw, nil, SkinF.personalInfo_226)
      }),
      Gui.Control({
        Size = Vector2(420, 336),
        Location = Vector2(479, -9),
        ComLabel(nil, GetUTF8Text("tips_store_Weapon_lottery"), Vector2(80, 80), Vector2(170, 127), 0, 16, colh, "kAlignCenterMiddle"),
        ComControl("equip_pd_15", Vector2(80, 80), Vector2(170, 127), 0),
        ComFuc.ComDragBtn("equip_b_15", nil, Vector2(80, 80), Vector2(170, 127), 0, 255),
        Gui.Control("equip_level_15")({
          Size = Vector2(27, 29),
          Location = Vector2(223, 127),
          BackgroundColor = colw,
          Skin = SkinF.personalInfo_245[1],
          Visible = false,
          Enable = false,
          ComFuc.ComLabel("equip_level_text_15", nil, Vector2(27, 14), Vector2(0, 6), 0, 12, colw, "kAlignCenterMiddle")
        }),
        ComFlashNew("equip_c_15", Vector2(80, 80), Vector2(170, 127), 255, SkinF.personalInfo_173, false),
        ComControl("hang_point", Vector2(42, 42), Vector2(64, 177), 255, SkinF.personalInfo_219[1]),
        ComControl("hang_Ldoor", Vector2(88, 161), Vector2(70, 92), 255, SkinF.personalInfo_249[1]),
        ComControl("hang_Rdoor", Vector2(87, 161), Vector2(262, 92), 255, SkinF.personalInfo_249[2]),
        LimitControl("hang_water", Vector2(46, 68), Vector2(21, 132), SkinF.personalInfo_227, 255)
      }),
      ComLabel(nil, GetUTF8Text("button_common_Weapon"), Vector2(402, 26), Vector2(59, 58), 0, 16, colw, "kAlignCenterMiddle"),
      DepotCB(1, "hangWeapon", -44, 28, 2, PersonalInfo, 5, SkinF.skin_touming, 3),
      DepotCB(2, "hangWeapon", -44, 28, 2, PersonalInfo, 5, SkinF.skin_touming, 3),
      DepotCB(3, "hangWeapon", -44, 28, 2, PersonalInfo, 5, SkinF.skin_touming, 3),
      DepotCB(4, "hangWeapon", -44, 28, 2, PersonalInfo, 5, SkinF.skin_touming, 3),
      DepotCB(5, "hangWeapon", -44, 28, 2, PersonalInfo, 5, SkinF.skin_touming, 3),
      DepotCB(6, "hangWeapon", -44, 28, 2, PersonalInfo, 5, SkinF.skin_touming, 3),
      DepotCB(7, "hangWeapon", -44, 28, 2, PersonalInfo, 5, SkinF.skin_touming, 3),
      DepotCB(8, "hangWeapon", -44, 28, 2, PersonalInfo, 5, SkinF.skin_touming, 3),
      DepotCB(9, "hangWeapon", -44, 28, 2, PersonalInfo, 5, SkinF.skin_touming, 3),
      DepotCB(10, "hangWeapon", -44, 28, 2, PersonalInfo, 5, SkinF.skin_touming, 3),
      DepotCB(11, "hangWeapon", -44, 28, 2, PersonalInfo, 5, SkinF.skin_touming, 3),
      DepotCB(12, "hangWeapon", -44, 28, 2, PersonalInfo, 5, SkinF.skin_touming, 3),
      DepotCB(13, "hangWeapon", -44, 28, 2, PersonalInfo, 5, SkinF.skin_touming, 3),
      DepotCB(14, "hangWeapon", -44, 28, 2, PersonalInfo, 5, SkinF.skin_touming, 3),
      DepotCB(15, "hangWeapon", -44, 28, 2, PersonalInfo, 5, SkinF.skin_touming, 3),
      DepotCB(16, "hangWeapon", -44, 28, 2, PersonalInfo, 5, SkinF.skin_touming, 3),
      DepotCB(17, "hangWeapon", -44, 28, 2, PersonalInfo, 5, SkinF.skin_touming, 3),
      DepotCB(18, "hangWeapon", -44, 28, 2, PersonalInfo, 5, SkinF.skin_touming, 3),
      DepotCB(19, "hangWeapon", -44, 28, 2, PersonalInfo, 5, SkinF.skin_touming, 3),
      DepotCB(20, "hangWeapon", -44, 28, 2, PersonalInfo, 5, SkinF.skin_touming, 3),
      ComFuc.ComPagesBar("pb_hangWeapon", Vector2(110, 489)),
      ComLabel(nil, " " .. GetUTF8Text("id_datalist_weapon_padlock_03"), Vector2(80, 26), Vector2(571, 518), 0, 16, colw),
      ComLabel("hang_cost", "0  ", Vector2(105, 30), Vector2(656, 516), 255, 16, colw, "kAlignRightMiddle", SkinF.personalInfo_215),
      ComControl(nil, Vector2(30, 30), Vector2(763, 516), 255, SkinF.shop_02),
      ComButton("btn_combHang", nil, Vector2(163, 63), Vector2(874, 498), 0, false, true, SkinF.personalInfo_247, true),
      RefitMetrial(5, Vector2(541, 300)),
      RefitMetrial(6, Vector2(796, 300)),
      RefitMetrial(7, Vector2(541, 396)),
      RefitMetrial(8, Vector2(796, 396)),
      Gui.Control("hang_por_parent")({
        Size = Vector2(134, 126),
        Location = Vector2(887, 133),
        ComControl("hang_por_1", Vector2(134, 54), Vector2(0, 0), 255, SkinF.personalInfo_251[1]),
        ComControl("hang_por_2", Vector2(134, 54), Vector2(0, 54), 255, SkinF.personalInfo_251[2]),
        ComControl("hang_por_3", Vector2(134, 54), Vector2(0, 108), 255, SkinF.personalInfo_251[3]),
        ComControl("hang_por_4", Vector2(134, 54), Vector2(0, 162), 255, SkinF.personalInfo_251[4]),
        ComControl("hang_por_5", Vector2(134, 54), Vector2(0, 216), 255, SkinF.personalInfo_251[5]),
        ComControl("hang_por_6", Vector2(134, 54), Vector2(0, 270), 255, SkinF.personalInfo_251[6]),
        ComControl("hang_por_7", Vector2(134, 54), Vector2(0, 324), 255, SkinF.personalInfo_251[7]),
        ComControl("hang_por_8", Vector2(134, 54), Vector2(0, 378), 255, SkinF.personalInfo_251[8]),
        ComControl("hang_por_9", Vector2(134, 54), Vector2(0, 432), 255, SkinF.personalInfo_251[9])
      }),
      ComControl(nil, Vector2(134, 126), Vector2(887, 133), 255, SkinF.personalInfo_250)
    })
  }),
  Gui.Control("ctrl_reinforce_5")({
    Size = Vector2(1105, 619),
    ComControl("depotParent", Vector2(592, 508), Vector2(506, 46), 0),
    Gui.Control({
      Size = Vector2(491, 604),
      Location = Vector2(8, 7),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_214,
      ComControl(nil, Vector2(30, 30), Vector2(440, 480), 255, SkinF.shop_02),
      ComControl(nil, Vector2(200, 158), Vector2(263, 280), 255, SkinF.personalInfo_253),
      ComLabel(nil, GetUTF8Text("UI_common_make_02"), Vector2(152, 22), Vector2(55, 239), 0, 16, colw, "kAlignCenterMiddle"),
      ComLabel(nil, GetUTF8Text("UI_common_make_03"), Vector2(166, 22), Vector2(282, 239), 0, 16, colw, "kAlignCenterMiddle"),
      ComLabel(nil, GetUTF8Text("UI_common_make_04"), Vector2(72, 28), Vector2(256, 444), 0, 16, colw),
      ComLabel(nil, GetUTF8Text("UI_common_make_05"), Vector2(80, 20), Vector2(256, 485), 0, 16, colw),
      ComLabel("combManuf_cost", "100  ", Vector2(105, 30), Vector2(336, 480), 255, 16, colw, "kAlignRightMiddle", SkinF.personalInfo_215),
      ComButton("btn_combManuf", nil, Vector2(163, 63), Vector2(307, 519), 0, false, true, SkinF.personalInfo_252, true),
      ComControl(nil, Vector2(88, 88), Vector2(319, 320), 255, SkinF.personalInfo_255),
      ComFuc.ComTextBox("manu_text", nil, Vector2(52, 28), Vector2(318, 444)),
      ComLabel("manu_has", "/0", Vector2(64, 28), Vector2(372, 444), 0, 16, colw),
      ComButton("btn_manuAll", GetUTF8Text("UI_common_make_06"), Vector2(74, 40), Vector2(405, 436), 16),
      Gui.Control("manu_tudi")({
        Size = Vector2(80, 80),
        Location = Vector2(323, 324),
        BackgroundColor = colw,
        Skin = SkinF.skin_touming,
        ComControl("manu_tudi_res", Vector2(80, 80), Vector2(0, 0), 255, SkinF.skin_touming),
        Gui.Control("manu_tudi_level")({
          Size = Vector2(27, 29),
          Location = Vector2(53, 0),
          BackgroundColor = colw,
          Skin = SkinF.personalInfo_245[1],
          Visible = false,
          ComLabel("manu_tudi_level_text", nil, Vector2(27, 14), Vector2(0, 6), 0, 12, colw, "kAlignCenterMiddle")
        })
      }),
      ComControl("manu_tuwu", Vector2(24, 39), Vector2(351, 341), 255, SkinF.personalInfo_257),
      ComControl("", Vector2(230, 80), Vector2(19, 261), 255, SkinF.personalInfo_256),
      ComControl("", Vector2(230, 80), Vector2(19, 341), 255, SkinF.personalInfo_256),
      ComControl("", Vector2(230, 80), Vector2(19, 421), 255, SkinF.personalInfo_256),
      ComControl("", Vector2(230, 80), Vector2(19, 501), 255, SkinF.personalInfo_256),
      ComManuMaterial(1),
      ComManuMaterial(2),
      ComManuMaterial(3),
      ComManuMaterial(4),
      Gui.Control({
        Size = Vector2(465, 226),
        Location = Vector2(13, 13),
        BackgroundColor = colw,
        Skin = SkinF.personalInfo_254,
        Gui.ListTreeView("manu_draw_list")({
          Style = "AuctionListTreeView",
          Size = Vector2(453, 208),
          Location = Vector2(6, 9),
          AutoEllipsis = true
        })
      })
    })
  }),
  PlayerCardInherit.PlayerCardInherit_UI("ctrl_reinforce_6"),
  Gui.Control("insertTip_m")({
    Dock = "kDockFill",
    ComControl(nil, Vector2(322, 96), Vector2(12, 0), 255, SkinF.battle_005),
    ComButton("insertTip_sure", GetUTF8Text("button_common_Punch"), Vector2(84, 44), Vector2(22, 102)),
    ComButton("insertTip_buy", GetUTF8Text("button_common_Buy"), Vector2(84, 44), Vector2(123, 102)),
    ComButton("insertTip_canc", GetUTF8Text("button_common_Cancel"), Vector2(84, 44), Vector2(224, 102)),
    ComLabel("insertTip_text", GetUTF8Text("msgbox_common_num_1144"), Vector2(270, 80), Vector2(40, 8), 0, 16, cols, "kAlignCenterMiddle")
  }),
  Gui.Control("destruct_num")({
    Size = Vector2(286, 154),
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_131,
    ComLabel("dest_name", nil, Vector2(276, 27), Vector2(5, 5), 255, 16, colw, "kAlignCenterMiddle", SkinF.skin_playgame_024),
    ComFuc.ComTextBox("dest_text", nil, Vector2(71, 38), Vector2(68, 41)),
    ComButton("dest_left", nil, Vector2(38, 43), Vector2(22, 39), nil, false, true, SkinF.page_001),
    ComButton("dest_right", nil, Vector2(38, 43), Vector2(147, 39), nil, false, true, SkinF.page_002),
    ComButton("dest_max", GetUTF8Text("button_common_Max_Value"), Vector2(72, 43), Vector2(193, 39), nil, false, true),
    ComButton("dest_sure", GetUTF8Text("button_common_OK"), Vector2(72, 43), Vector2(35, 93), nil, false, true, nil, true, "recyclebin"),
    ComButton("dest_cancel", GetUTF8Text("button_common_Cancel"), Vector2(72, 43), Vector2(175, 93), nil, false, true)
  }),
  Gui.Control("lound_speaker")({
    Size = Vector2(592, 200),
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_206,
    ComControl(nil, Vector2(566, 100), Vector2(12, 40), 255, SkinF.battle_005),
    ComLabel(nil, "  " .. GetUTF8Text("id_datalist_Megaphone"), Vector2(582, 21), Vector2(5, 4), 0, 16, colw),
    ComLabel(nil, GetUTF8Text("msgbox_common_num_1312"), Vector2(276, 22), Vector2(32, 52), 0, 16, cols),
    ComFuc.ComTextBox("speak_text", nil, Vector2(528, 38), Vector2(32, 84), 60),
    ComButton("speak_sure", GetUTF8Text("button_common_OK"), Vector2(84, 43), Vector2(400, 148), nil, false, true),
    ComButton("speak_cancel", GetUTF8Text("button_common_Cancel"), Vector2(84, 43), Vector2(496, 148), nil, false, true),
    ComButton("speak_close", nil, Vector2(24, 24), Vector2(560, 4), 0, false, false, SkinF.lookInfo_002)
  }),
  Gui.Control("change_pet_name")({
    Size = Vector2(412, 420),
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_206,
    ComControl(nil, Vector2(386, 100), Vector2(12, 40), 255, SkinF.battle_005),
    ComLabel(nil, " " .. GetUTF8Text("UI_pet_function_02"), Vector2(402, 21), Vector2(5, 4), 0, 16, colw),
    ComLabel(nil, GetUTF8Text("UI_pet_function_03"), Vector2(396, 22), Vector2(32, 52), 0, 16, cols),
    ComFuc.ComTextBox("change_pet_name_text", nil, Vector2(348, 38), Vector2(32, 84), 14),
    ComButton("change_pet_name_sure", GetUTF8Text("button_common_OK"), Vector2(84, 43), Vector2(65, 364), nil, false, true),
    ComButton("change_pet_name_cancel", GetUTF8Text("button_common_Cancel"), Vector2(84, 43), Vector2(263, 364), nil, false, true),
    ComButton("change_pet_name_close", nil, Vector2(24, 24), Vector2(380, 4), 0, false, false, SkinF.lookInfo_002),
    Gui.Control("pet_rename_price_area")({
      Size = Vector2(386, 206),
      Location = Vector2(12, 148),
      BackgroundColor = colw,
      Skin = SkinF.battle_005,
      ComLabel("change_pet_name_price", GetUTF8Text("msgbox_pet_clew_14"), Vector2(326, 50), Vector2(30, 148), 0, 16, cols, "kAlignCenterMiddle"),
      Gui.Control("pet_rename_costP_1")({
        Size = Vector2(150, 31),
        Location = Vector2(113, 10),
        ComFuc.ComLabel("pet_rename_costL_1", "0 ", Vector2(122, 31), Vector2(28, 0), 255, 16, coly, "kAlignRightMiddle", SkinF.avatar_main_086),
        ComFuc.ComControl(nil, Vector2(30, 30), Vector2(32, 1), 255, SkinF.avatar_main_088[1]),
        ComFuc.ComCheckBox("pet_rename_costCB_1", nil, Vector2(24, 24), Vector2(0, 4), 0, nil, "Gui.CheckBox_01")
      }),
      Gui.Control("pet_rename_costP_2")({
        Size = Vector2(150, 31),
        Location = Vector2(113, 46),
        ComFuc.ComLabel("pet_rename_costL_2", "0 ", Vector2(122, 31), Vector2(28, 0), 255, 16, coly, "kAlignRightMiddle", SkinF.avatar_main_086),
        ComFuc.ComControl(nil, Vector2(30, 30), Vector2(32, 1), 255, SkinF.avatar_main_088[2]),
        ComFuc.ComCheckBox("pet_rename_costCB_2", nil, Vector2(24, 24), Vector2(0, 4), 0, nil, "Gui.CheckBox_01")
      }),
      Gui.Control("pet_rename_costP_3")({
        Size = Vector2(150, 31),
        Location = Vector2(113, 82),
        ComFuc.ComLabel("pet_rename_costL_3", "0 ", Vector2(122, 31), Vector2(28, 0), 255, 16, coly, "kAlignRightMiddle", SkinF.avatar_main_086),
        ComFuc.ComControl(nil, Vector2(30, 30), Vector2(32, 1), 255, SkinF.avatar_main_088[3]),
        ComFuc.ComCheckBox("pet_rename_costCB_3", nil, Vector2(24, 24), Vector2(0, 4), 0, nil, "Gui.CheckBox_01")
      }),
      Gui.Control("pet_rename_costP_4")({
        Size = Vector2(150, 31),
        Location = Vector2(113, 118),
        ComFuc.ComLabel("pet_rename_costL_4", "0 ", Vector2(122, 31), Vector2(28, 0), 255, 16, coly, "kAlignRightMiddle", SkinF.avatar_main_086),
        ComFuc.ComControl(nil, Vector2(30, 30), Vector2(32, 1), 255, SkinF.avatar_main_088[4]),
        ComFuc.ComCheckBox("pet_rename_costCB_4", nil, Vector2(24, 24), Vector2(0, 4), 0, nil, "Gui.CheckBox_01")
      })
    })
  }),
  Gui.Control("pet_slot_expand_price_ui")({
    Size = Vector2(412, 420),
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_206,
    ComControl(nil, Vector2(386, 100), Vector2(12, 40), 255, SkinF.battle_005),
    ComLabel(nil, GetUTF8Text("msgbox_pet_add_01"), Vector2(402, 21), Vector2(5, 4), 0, 16, colw),
    ComLabel(nil, GetUTF8Text("msgbox_pet_add_02"), Vector2(346, 22), Vector2(32, 52), 0, 16, cols),
    ComLabel(nil, GetUTF8Text("msgbox_pet_add_03"), Vector2(346, 22), Vector2(32, 80), 0, 16, cols),
    ComLabel(nil, GetUTF8Text("msgbox_pet_add_04"), Vector2(346, 22), Vector2(32, 108), 0, 16, cols),
    ComLabel("pet_slot_expand_num_now", nil, Vector2(340, 22), Vector2(32, 52), 0, 16, cols, "kAlignRightMiddle"),
    ComLabel("pet_slot_expand_num_next", nil, Vector2(340, 22), Vector2(32, 80), 0, 16, cols, "kAlignRightMiddle"),
    ComLabel("pet_slot_expand_num_max", "30", Vector2(340, 22), Vector2(32, 108), 0, 16, cols, "kAlignRightMiddle"),
    ComButton("pet_slot_expand_sure", GetUTF8Text("msgbox_pet_add_06"), Vector2(144, 43), Vector2(128, 364), nil, false, true),
    ComButton("pet_slot_expand_close", nil, Vector2(24, 24), Vector2(380, 4), 0, false, false, SkinF.lookInfo_002),
    Gui.Control("pet_slot_expand_price_area")({
      Size = Vector2(386, 206),
      Location = Vector2(12, 148),
      BackgroundColor = colw,
      Skin = SkinF.battle_005,
      ComLabel("pet_slot_expand_price_choose", GetUTF8Text("msgbox_pet_add_05"), Vector2(326, 40), Vector2(30, 10), 0, 16, cols, "kAlignCenterMiddle"),
      Gui.Control("pet_slot_expand_costP_1")({
        Size = Vector2(150, 31),
        Location = Vector2(113, 54),
        ComFuc.ComLabel("pet_slot_expand_costL_1", "0 ", Vector2(122, 31), Vector2(28, 0), 255, 16, coly, "kAlignRightMiddle", SkinF.avatar_main_086),
        ComFuc.ComControl(nil, Vector2(30, 30), Vector2(32, 1), 255, SkinF.avatar_main_088[1]),
        ComFuc.ComCheckBox("pet_slot_expand_costCB_1", nil, Vector2(24, 24), Vector2(0, 4), 0, nil, "Gui.CheckBox_01")
      }),
      Gui.Control("pet_slot_expand_costP_2")({
        Size = Vector2(150, 31),
        Location = Vector2(113, 90),
        ComFuc.ComLabel("pet_slot_expand_costL_2", "0 ", Vector2(122, 31), Vector2(28, 0), 255, 16, coly, "kAlignRightMiddle", SkinF.avatar_main_086),
        ComFuc.ComControl(nil, Vector2(30, 30), Vector2(32, 1), 255, SkinF.avatar_main_088[2]),
        ComFuc.ComCheckBox("pet_slot_expand_costCB_2", nil, Vector2(24, 24), Vector2(0, 4), 0, nil, "Gui.CheckBox_01")
      }),
      Gui.Control("pet_slot_expand_costP_3")({
        Size = Vector2(150, 31),
        Location = Vector2(113, 126),
        ComFuc.ComLabel("pet_slot_expand_costL_3", "0 ", Vector2(122, 31), Vector2(28, 0), 255, 16, coly, "kAlignRightMiddle", SkinF.avatar_main_086),
        ComFuc.ComControl(nil, Vector2(30, 30), Vector2(32, 1), 255, SkinF.avatar_main_088[3]),
        ComFuc.ComCheckBox("pet_slot_expand_costCB_3", nil, Vector2(24, 24), Vector2(0, 4), 0, nil, "Gui.CheckBox_01")
      }),
      Gui.Control("pet_slot_expand_costP_4")({
        Size = Vector2(150, 31),
        Location = Vector2(113, 162),
        ComFuc.ComLabel("pet_slot_expand_costL_4", "0 ", Vector2(122, 31), Vector2(28, 0), 255, 16, coly, "kAlignRightMiddle", SkinF.avatar_main_086),
        ComFuc.ComControl(nil, Vector2(30, 30), Vector2(32, 1), 255, SkinF.avatar_main_088[4]),
        ComFuc.ComCheckBox("pet_slot_expand_costCB_4", nil, Vector2(24, 24), Vector2(0, 4), 0, nil, "Gui.CheckBox_01")
      })
    })
  }),
  ComFuc.PopControl("insertTip", Vector2(346, 206), GetUTF8Text("UI_avatar_avatar_UI_06"), 40, 1),
  ComMenu("menu_1"),
  ComMenu("menu_2"),
  ComMenu("menu_3"),
  ComMenu("menu_4"),
  ComMenu("menu_5"),
  ComMenu("menu_6"),
  ComMenu("menu_7"),
  ComMenu("menu_8"),
  ComMenu("menu_9"),
  ComMenu("menu_10"),
  ComMenu("menu_11"),
  ComMenu("menu_12"),
  ComMenu("menu_13"),
  ComMenu("menu_14"),
  ComMenu("menu_15"),
  ComMenu("menu_16"),
  ComMenu("menu_17"),
  ComMenu("menu_18"),
  ComMenu("menu_19"),
  Gui.Control("ctrl_depot_1")({
    Size = Vector2(573, 357),
    DepotCB(1, "weapon", -54, -74, 2, PersonalInfo),
    DepotCB(2, "weapon", -54, -74, 2, PersonalInfo),
    DepotCB(3, "weapon", -54, -74, 2, PersonalInfo),
    DepotCB(4, "weapon", -54, -74, 2, PersonalInfo),
    DepotCB(5, "weapon", -54, -74, 2, PersonalInfo),
    DepotCB(6, "weapon", -54, -74, 2, PersonalInfo),
    DepotCB(7, "weapon", -54, -74, 2, PersonalInfo),
    DepotCB(8, "weapon", -54, -74, 2, PersonalInfo),
    DepotCB(9, "weapon", -54, -74, 2, PersonalInfo),
    DepotCB(10, "weapon", -54, -74, 2, PersonalInfo),
    DepotCB(11, "weapon", -54, -74, 2, PersonalInfo),
    DepotCB(12, "weapon", -54, -74, 2, PersonalInfo),
    DepotCB(13, "weapon", -54, -74, 2, PersonalInfo),
    DepotCB(14, "weapon", -54, -74, 2, PersonalInfo),
    DepotCB(15, "weapon", -54, -74, 2, PersonalInfo),
    DepotCB(16, "weapon", -54, -74, 2, PersonalInfo),
    DepotCB(17, "weapon", -54, -74, 2, PersonalInfo),
    DepotCB(18, "weapon", -54, -74, 2, PersonalInfo),
    DepotCB(19, "weapon", -54, -74, 2, PersonalInfo),
    DepotCB(20, "weapon", -54, -74, 2, PersonalInfo),
    DepotCB(21, "weapon", -54, -74, 2, PersonalInfo),
    DepotCB(22, "weapon", -54, -74, 2, PersonalInfo),
    DepotCB(23, "weapon", -54, -74, 2, PersonalInfo),
    DepotCB(24, "weapon", -54, -74, 2, PersonalInfo)
  }),
  Gui.Control("ctrl_depot_4")({
    Size = Vector2(573, 357),
    ComFuc.CardKeyCB(1, "person", -86, -154, 0, PersonalInfo),
    ComFuc.CardKeyCB(2, "person", -86, -154, 0, PersonalInfo),
    ComFuc.CardKeyCB(3, "person", -86, -154, 0, PersonalInfo),
    ComFuc.CardKeyCB(4, "person", -86, -154, 0, PersonalInfo),
    ComFuc.CardKeyCB(5, "person", -86, -154, 0, PersonalInfo),
    ComFuc.CardKeyCB(6, "person", -86, -154, 0, PersonalInfo),
    ComFuc.CardKeyCB(7, "person", -86, -154, 0, PersonalInfo),
    ComFuc.CardKeyCB(8, "person", -86, -154, 0, PersonalInfo),
    ComFuc.CardKeyCB(9, "person", -86, -154, 0, PersonalInfo),
    ComFuc.CardKeyCB(10, "person", -86, -154, 0, PersonalInfo)
  }),
  Gui.Control("reset_skill_m")({
    Dock = "kDockFill",
    ComFuc.ComControl("reset_skill_check_di", Vector2(376, 170), Vector2(12, 0), 255, SkinF.battle_005),
    ComFuc.ComButton("reset_skill_sure", GetUTF8Text("button_common_OK"), Vector2(84, 44), Vector2(93, 180)),
    ComFuc.ComButton("reset_skill_canc", GetUTF8Text("button_common_Cancel"), Vector2(84, 44), Vector2(223, 180)),
    ComFuc.ComLabel("reset_skill_text", "", Vector2(345, 50), Vector2(30, 112), 0, 16, cols),
    Gui.Control("reset_skill_costP_1")({
      Size = Vector2(150, 31),
      Location = Vector2(113, 10),
      ComFuc.ComLabel("reset_skill_costL_1", "0 ", Vector2(122, 31), Vector2(28, 0), 255, 16, coly, "kAlignRightMiddle", SkinF.avatar_main_086),
      ComFuc.ComControl(nil, Vector2(30, 30), Vector2(32, 1), 255, SkinF.avatar_main_088[1]),
      ComFuc.ComCheckBox("reset_skill_costCB_1", nil, Vector2(24, 24), Vector2(0, 4), 0, nil, "Gui.CheckBox_01")
    }),
    Gui.Control("reset_skill_costP_2")({
      Size = Vector2(150, 31),
      Location = Vector2(113, 46),
      ComFuc.ComLabel("reset_skill_costL_2", "0 ", Vector2(122, 31), Vector2(28, 0), 255, 16, coly, "kAlignRightMiddle", SkinF.avatar_main_086),
      ComFuc.ComControl(nil, Vector2(30, 30), Vector2(32, 1), 255, SkinF.avatar_main_088[2]),
      ComFuc.ComCheckBox("reset_skill_costCB_2", nil, Vector2(24, 24), Vector2(0, 4), 0, nil, "Gui.CheckBox_01")
    }),
    Gui.Control("reset_skill_costP_3")({
      Size = Vector2(150, 31),
      Location = Vector2(113, 82),
      ComFuc.ComLabel("reset_skill_costL_3", "0 ", Vector2(122, 31), Vector2(28, 0), 255, 16, coly, "kAlignRightMiddle", SkinF.avatar_main_086),
      ComFuc.ComControl(nil, Vector2(30, 30), Vector2(32, 1), 255, SkinF.avatar_main_088[3]),
      ComFuc.ComCheckBox("reset_skill_costCB_3", nil, Vector2(24, 24), Vector2(0, 4), 0, nil, "Gui.CheckBox_01")
    }),
    Gui.Control("reset_skill_costP_4")({
      Size = Vector2(150, 31),
      Location = Vector2(113, 118),
      ComFuc.ComLabel("reset_skill_costL_4", "0 ", Vector2(122, 31), Vector2(28, 0), 255, 16, coly, "kAlignRightMiddle", SkinF.avatar_main_086),
      ComFuc.ComControl(nil, Vector2(30, 30), Vector2(32, 1), 255, SkinF.avatar_main_088[4]),
      ComFuc.ComCheckBox("reset_skill_costCB_4", nil, Vector2(24, 24), Vector2(0, 4), 0, nil, "Gui.CheckBox_01")
    })
  }),
  Gui.Control("reinStateCtrl")({
    Size = Vector2(289, 296),
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_209[1],
    ComControl("reinStateCtrl_son", Vector2(289, 296), Vector2(0, 0), 255, SkinF.personalInfo_209[6])
  }),
  ComFuc.PopControl("reset_skill", Vector2(400, 314), GetUTF8Text("UI_avatar_avatar_UI_06"), 40, 1),
  ComControl("equip_s_13", Vector2(80, 80), Vector2(0, 0)),
  ComControl("equip_s_14", Vector2(80, 80), Vector2(0, 0)),
  ComControl("equip_s_15", Vector2(80, 80), Vector2(0, 0)),
  ComControl("coverControl2", Vector2(1600, 1200), Vector2(0, 0), 0),
  ComControl("coverControl3", Vector2(1600, 1200), Vector2(0, 0), 0),
  ComControl("coverControlNew", Vector2(1600, 1200), Vector2(0, 0), 0),
  ComFuc.ComFloatingControl("moveMix"),
  ComFuc.ComMoveControl(),
  ComFuc.ComMoveCard()
})
ui.reset_skill_m.Parent = ui.reset_skill_son
ui.refit_buy_1.Visible = false
ui.refit_buy_2.Visible = false
ui.refit_buy_6.Visible = false
ui.refit_buy_7.Visible = false
ui.refit_buy_8.Visible = false
ui.mingwen.Visible = false
ui.pow_text.AutoWrap = true
ui.advent_text.AutoWrap = true
ui.insertTip_text.AutoWrap = true
ui.refit_water.Size = Vector2(46, 68)
ui.refit_opTip.Text = GetUTF8Text("UI_datalist_UP02")
ui.equip_s_13.Parent = ui.equip_b_13
ui.equip_s_14.Parent = ui.equip_b_14
ui.equip_s_15.Parent = ui.equip_b_15
ui.insertTip_m.Parent = ui.insertTip_son
ui.need_to_medal.Text = "0" .. "/" .. "0"
ui.insert_card_hight.Visible = false
ui.btn_depot_del_c.Hint = GetUTF8Text("tips_lobby_Button_Decs1")
ui.btn_depot_weapon_up_c.Hint = GetUTF8Text("UI_lobby_weapon_upgrade")
ui.btn_depot_repair_c.Hint = GetUTF8Text("tips_lobby_Button_Decs2")
ui.btn_depot_repair_all.Hint = GetUTF8Text("tips_lobby_Button_Decs3")
ui.pet_op_setting_hint.AutoWrap = true
ui.equip_c_14.IsReady = true
ui.Tips_To_DragMetrailWeapon.DirState = 0
ui.Tips_To_DragMetrailWeapon.MiddCenter = Vector2(706, 154)
ui.Tips_To_DragMetrailWeapon.Visible = false
ui.Tips_To_DragMetrailWeapon.TextPadding = Vector4(9, 6, 9, 12)
ui.reset_anim.ClickAudio = "clean"
ui.hang_opTip.TextPadding = Vector4(12, 8, 12, 8)
ui.hang_opTip.AutoWrap = true
ui.refit_buy_5.Hint = GetUTF8Text("msgbox_common_attribute_10")
ui.profession_skill_button_1.ClickAudio = "menu3rd"
ui.boss_skill_button_1.ClickAudio = "menu3rd"
ui.profession_skill_button_2.ClickAudio = "menu3rd"
ui.boss_skill_button_2.ClickAudio = "menu3rd"
for i = 1, 2 do
  ui["profession_skill_button_" .. i].HighlightTextColor = ARGB(255, 82, 54, 44)
  ui["profession_skill_button_" .. i].TextShadowColor = ARGB(0, 0, 0, 0)
  ui["boss_skill_button_" .. i].HighlightTextColor = ARGB(255, 82, 54, 44)
  ui["boss_skill_button_" .. i].TextShadowColor = ARGB(0, 0, 0, 0)
end
for i = 1, 4 do
  ui["manu_tiao_name_" .. i].AutoWrap = true
  ui["manu_tiao_name_" .. i].AutoEllipsis = true
end
for i = 1, 20 do
  ui["refit_pt_" .. i].Particle:Reset()
  ui["refit_pt_" .. i].Particle:SetEnable(false)
end
for i = 1, 5 do
  ui["remove_stone_btn_" .. i].Visible = false
  ui["skill_dec_" .. i].ClickAudio = ""
  ui["skill_add_" .. i].ClickAudio = ""
  ui["skill_drag_tip_" .. i .. "_l"].AutoEllipsis = true
end
for i = 1, 8 do
  if ui["refMtr_name_" .. i] then
    ui["refMtr_name_" .. i].AutoEllipsis = true
  end
  local InitLocationTable = "msgbox_common_attribute_10"
end
local DealPageItem = function()
  LocationTable[1] = Vector2(48, 5)
  LocationTable[2] = Vector2(258, 5)
  LocationTable[3] = Vector2(468, 5)
  LocationTable[4] = Vector2(678, 5)
  LocationTable[5] = Vector2(888, 5)
end, (function()
  LocationTable[1] = Vector2(48, 5)
  LocationTable[2] = Vector2(258, 5)
  LocationTable[3] = Vector2(468, 5)
  LocationTable[4] = Vector2(678, 5)
  LocationTable[5] = Vector2(888, 5)
end)()
local DealChangePageBtn = function()
  ui["btn_reinforce_" .. 2].Location = LocationTable[1]
  ui["btn_reinforce_" .. 1].Location = LocationTable[2]
  ui["btn_reinforce_" .. 3].Location = LocationTable[3]
  ui.btn_reinforce_4.Visible = false
  ui["btn_reinforce_" .. 5].Location = LocationTable[4]
  ui["btn_reinforce_" .. 6].Location = LocationTable[5]
end
local IniPagebarClick = function()
end
local InitLocationTable, EnhancePagebarLeftPageClick = function()
  offset = 0
  DealPageItem()
  DealChangePageBtn()
end, ui["refMtr_name_" .. i]
local EnhancePagebarLeftPageClick, EnhancePagebarRightPageClick = function()
  offset = offset - 1
  DealPageItem()
  DealChangePageBtn()
end, "AutoEllipsis"
local EnhancePagebarRightPageClick, ShowMoveControl = function()
  offset = offset + 1
  DealPageItem()
  DealChangePageBtn()
end, true
local ShowMoveControl, ShowMoveCard = function(size, lc, dir, name, quiltyLevel)
  ComFuc.ShowMoveControl(size, lc, dir, name, quiltyLevel, ui.moveControl, ui.moveControl_son)
end, "_l"
local ShowMoveCard, ShowWeaponEnhanceBar = function(size, lc, up, grade, subType)
  ComFuc.ShowMoveCard(size, lc, up, grade, ui.moveCard, ui.moveCard_son, ui.moveCard_s, ui.moveCard_c, false, subType)
end, 0
local ShowWeaponEnhanceBar, ComputeWeaponEnhanceBar = function(need, yellow, blue, red, text)
  ui.red_bar.Size = Vector2(1000 * red / need, 22)
  ui.blue_bar.Size = Vector2(1000 * blue / need, 22)
  ui.yellow_bar.Size = Vector2(1000 * yellow / need, 22)
  ui.yellow_text.Text = tostring(yellow) .. "/" .. tostring(need)
end, 0
local ComputeWeaponEnhanceBar, ShowMessageEquipButton = function()
  ui.next_refitExpLevel.Text = GetUTF8Text("UI_social_new_enhance_desc_03")
  if ui.equip_b_13.Skin == SkinF.skin_touming2 then
    ShowWeaponEnhanceBar(1, 0, 0, 0)
    ui.yellow_text.Text = ""
  elseif ui.equip_b_14.Skin == SkinF.skin_touming2 then
    ShowWeaponEnhanceBar(refitDt.currentExpNextLevelOffset or 1, refitDt.currentExpCurrentLevelOffset or 0, 0, 0)
  else
    local need = refitDt.currentExpNextLevelOffset
    local yellow = refitDt.currentExpCurrentLevelOffset
    local blue = 0
    local red = 0
    for i, v in ipairs(refitDetail.grades) do
      if v.grade == menDt2.grade then
        blue = v.exp
      end
    end
    if ui.useLucyReel.Enable and ui.useLucyReel.Check then
      red = blue * refitDetail.fixReelRate
    else
      red = blue
    end
    if menDt.sid == menDt2.sid then
      red = red * refitDetail.sameItemRate
    end
    if ui.useInheritAtri.Enable and ui.useInheritAtri.Check then
      if menDt.grade == menDt2.grade then
        if menDt.baseRank <= menDt2.baseRank then
          red = red + menDt2.refitTotalExp
        else
          local local_ratio = refitDetail.maxHeirloomRate - 0.01 * (menDt.baseRank - menDt2.baseRank)
          if local_ratio < refitDetail.minHeirloomRate then
            local_ratio = refitDetail.minHeirloomRate
          end
          red = red + menDt2.refitTotalExp * local_ratio
        end
      else
        red = red + menDt2.refitTotalExp * refitDetail.useHeirloomRate
      end
    else
      red = red + menDt2.refitTotalExp * refitDetail.noHeirloomRate
    end
    local exp_curr = refitLevelExp[refitDt.grade]
    local texp = exp_curr[refitDt.currentLevel] + yellow + red
    for i = 20, 1, -1 do
      if texp >= exp_curr[i] then
        if i > refitDt.currentLevel then
          ui.next_refitExpLevel.Text = "LV" .. i
        end
        break
      end
    end
    isAddMore = blue < red
    yellow = math.min(yellow, need)
    blue = math.min(yellow + blue, need)
    red = math.min(yellow + red, need)
    ShowWeaponEnhanceBar(need, yellow, blue, red)
  end
end, 0
local ShowMessageEquipButton, LighterOrNarmal = function()
  if independentTrinket then
    for i, v in ipairs(independentTrinket) do
      if v.type == 1 then
        equipSkinRes[4] = ComFuc.DoWingRes(v.resource, true, true, 1)
        equipGrade[4] = v.grade
        ShowOneButton(ui.equip_p_4, ui.equip_b_4, resDir, equipSkinRes[4], v.grade)
      elseif v.type == 2 then
        equipSkinRes[1] = v.resource
        equipGrade[1] = v.grade
        ShowOneButton(ui.equip_p_1, ui.equip_b_1, resDir, v.resource, v.grade)
      elseif v.type == 3 then
        equipSkinRes[3] = v.resource
        equipGrade[3] = v.grade
        ShowOneButton(ui.equip_p_3, ui.equip_b_3, resDir, v.resource, v.grade)
      elseif v.type == 4 then
        equipSkinRes[6] = v.resource
        equipGrade[6] = v.grade
        ShowOneButton(ui.equip_p_6, ui.equip_b_6, resDir, v.resource, v.grade)
      end
    end
  end
end, ComFuc.ComMoveCard()
local LighterOrNarmal, OnMouseMove = function(isHigh, type, subtype, p, q)
  if type == 1 then
    for i = 1, 12 do
      ui["hot_key_c_" .. i].IsBegin = isHigh
      ui["hot_key_c_" .. i].IsReady = isHigh
      ui["hot_key_c_" .. i].Skin = SkinF.personalInfo_065[subtype]
      ui["hot_key_c_" .. i].BackgroundColor = colw
    end
  elseif type == 2 then
    for i = p, q do
      ui["equip_c2_" .. i].IsReady = isHigh
      ui["equip_c2_" .. i].Visible = isHigh
    end
  elseif type == 3 then
    ui.insert_card_hight.IsReady = isHigh
    ui.insert_card_hight.Visible = isHigh
  elseif type == 4 then
    for i = 1, 5 do
      if ui["insert_kb_" .. i].Visible == false then
        ui["insert_c_" .. i].IsReady = isHigh
        ui["insert_c_" .. i].Visible = isHigh
      end
    end
  elseif type == 5 then
    for i = 1, 5 do
      ui["mix_c_" .. i].IsReady = isHigh
      ui["mix_c_" .. i].Visible = isHigh
    end
  elseif type == 6 then
    ui.equip_c_13.IsReady = isHigh
    ui.equip_c_13.Visible = isHigh
  elseif type == 7 then
    ui.equip_c_14.Visible = isHigh
  elseif type == 8 then
    ui.equip_c_15.IsReady = isHigh
    ui.equip_c_15.Visible = isHigh
  end
end, ComFuc.ComMoveCard()
local OnMouseMove, SwitchALLLighter = function(up, isCard)
  ComFuc.OnMouseMove(up, isCard, ui.moveCard, ui.moveControl)
end, ComFuc.ComMoveCard()
local SwitchALLLighter, ShowMenu = function(type, isHigh, subtype, c1, c2)
  if type == 1 then
    if c1 == 101 then
      LighterOrNarmal(isHigh, 2, 0, 6, 6)
    elseif c1 == 102 then
      LighterOrNarmal(isHigh, 2, 0, 4, 4)
    elseif c1 == 103 then
      LighterOrNarmal(isHigh, 2, 0, 1, 1)
      LighterOrNarmal(isHigh, 2, 0, 3, 3)
    elseif c2 and c2 == 3 then
      for k = 1, 12 do
        if htkDt[k] and htkDt[k].type and htkDt[k].type == 2 then
          ui["hot_key_c_" .. k].IsReady = isHigh
          ui["hot_key_c_" .. k].Skin = SkinF.personalInfo_065[2]
        end
      end
    else
      LighterOrNarmal(isHigh, 1, subtype)
    end
  elseif type == 2 then
    LighterOrNarmal(true, 1, 2)
  elseif type == 3 then
    LighterOrNarmal(true, 2, 0, 7, 12)
  end
end, ComFuc.ComMoveCard()
local ShowMenu, ShowPetDelMenu = function(i, c, isEqiup, isDecompose, count, bindReset, isBind, isLock)
  gui:PlayAudio("dropdownlist")
  Tip.SetOwner(nil)
  ui["menu_" .. i]:RemoveItemById(MenuItemUnbindId)
  if bindReset and isBind then
    ui["menu_" .. i]:AddItem(GetUTF8Text("UI_lobby_prop_state_09"), MenuItemUnbindId)
  end
  ui["menu_" .. i]:RemoveItemById(MenuItemUnlockId)
  ui["menu_" .. i]:RemoveItemById(MenuItemLockId)
  ui["menu_" .. i]:RemoveItemById(MenuItemWaitUnbindId)
  if depotCurr + 1 >= 2 and depotCurr + 1 <= 5 then
    if isLock == 1 then
      ui["menu_" .. i]:AddItem(GetUTF8Text("UI_lobby_unlock"), MenuItemUnlockId)
    elseif isLock == 0 then
      ui["menu_" .. i]:AddItem(GetUTF8Text("UI_lobby_lock"), MenuItemLockId)
    elseif isLock == 2 then
      ui["menu_" .. i]:AddItem(GetUTF8Text("UI_lobby_unlock"), MenuItemWaitUnbindId)
    end
  end
  ui["menu_" .. i].Location = c + Vector2(ComFuc.locationChanged, 0)
  ui["menu_" .. i]:Open()
  ui["menu_" .. i]:SetEnable(0, not isEqiup and isDecompose)
  if not (i ~= 1 and i ~= 18 and i ~= 2 and 4 <= i) or i <= 16 then
  end
  if 5 <= i and i <= 7 then
    ui["menu_" .. i]:SetEnable(1, not isEqiup)
  end
  if 10 <= i and i <= 16 or i == 2 or i == 4 or i == 18 then
    ui["menu_" .. i]:SetEnable(1, not count)
  end
  if i == 2 or i == 4 or i ~= 17 and 10 <= i and i <= 19 then
    ui["menu_" .. i]:SetEnable(1, isLock == 0)
  end
  ui.menu_12:SetEnable(2, not game.isNoSpeak)
end, ComFuc.ComMoveCard()
local ShowPetDelMenu, SwitchAllMenu = function(menuLocation)
  ui.menu_17.Location = menuLocation + Vector2(ComFuc.locationChanged, 0)
  ui.menu_17:Open()
  ui.menu_17:SetEnable(0, true)
end, ComFuc.ComMoveCard()
local SwitchAllMenu, ShowQuaity = function(type, c, c1, isEqiup, c3, count, bindReset, isBind, isLock)
  local isDecompose = false
  if type == 1 then
    isDecompose = true
    if c1 == 101 then
      ShowMenu(5, c, isEqiup, isDecompose, nil, bindReset, isBind, isLock)
    elseif c1 == 102 then
      ShowMenu(6, c, isEqiup, isDecompose, nil, bindReset, isBind, isLock)
    elseif c1 == 103 then
      ShowMenu(7, c, isEqiup, isDecompose, nil, bindReset, isBind, isLock)
    elseif c1 == 10 then
      ShowMenu(9, c, isEqiup, isDecompose, nil, bindReset, isBind, isLock)
    else
      ShowMenu(1, c, isEqiup, isDecompose, nil, bindReset, isBind, isLock)
    end
  elseif type == 2 then
    isDecompose = true
    if c1 == 302 then
      ShowMenu(2, c, isEqiup, isDecompose, count, bindReset, isBind, isLock)
    elseif c1 == 400 then
      ShowMenu(10, c, isEqiup, isDecompose, count, bindReset, isBind, isLock)
    elseif c1 == 106 then
      ShowMenu(11, c, isEqiup, isDecompose, count, bindReset, isBind, isLock)
    elseif c1 == 107 then
      ShowMenu(13, c, isEqiup, isDecompose, count, bindReset, isBind, isLock)
    elseif c1 == 109 then
      ShowMenu(14, c, isEqiup, isDecompose, count, bindReset, isBind, isLock)
    elseif c1 == 100 and c3 == 101 then
      ShowMenu(12, c, isEqiup, isDecompose, count, bindReset, isBind, isLock)
    elseif c1 == 110 and c3 == 1 then
      ShowMenu(15, c, isEqiup, isDecompose, count, bindReset, isBind, isLock)
    elseif c1 == 100 and c3 == 102 then
      ShowMenu(16, c, isEqiup, isDecompose, count, bindReset, isBind, isLock)
    elseif c1 == 112 then
      ShowMenu(18, c, isEqiup, isDecompose, count, bindReset, isBind, isLock)
    elseif c1 == 104 then
      ShowMenu(19, c, isEqiup, isDecompose, count, bindReset, isBind, isLock)
    else
      ShowMenu(4, c, isEqiup, isDecompose, count, bindReset, isBind, isLock)
    end
  elseif type == 3 then
    ShowMenu(8, c, isEqiup, isDecompose, nil, bindReset, isBind, isLock)
  elseif type == 4 then
    ShowPetDelMenu(c)
  end
end, ComFuc.ComMoveCard()
local ShowQuaity, ShowOneClassCtrl = function(name, i, c, isShowOne)
  ComFuc.ShowQuaity(ui[name .. i], c, isShowOne)
end, ComFuc.ComMoveCard()
local ShowOneClassCtrl, ShowIsEquiped = function(name, c, isShow, p)
  p = p or 1
  for i = p, c do
    ui[name .. i].Visible = isShow
  end
end, ComFuc.ComMoveCard()
local ShowIsEquiped, SetSkillLeave = function(v, name, k)
  ComFuc.ShowIsEquiped(v, name, k, ui[name .. "_c_" .. v.slot], ui[name .. "_new_" .. v.slot])
end, ComFuc.ComMoveCard()
local SetSkillLeave, SetSkillVSize = function(p)
  skillLeave = p
  ui.remain_skills.Text = p
end, ComFuc.ComMoveCard()
local SetSkillVSize, SetDestRightEnable = function(i, p)
  skillTemLevel[i] = p
  ui["skill_size_v_" .. i].Size = Vector2(ComFuc.skillPointL[p + 1], 31)
  ui["skill_b_" .. i].Enable = 0 < p
end, ComFuc.ComMoveCard()
local SetDestRightEnable, ShowDestructNum = function()
  ui.dest_right.Enable = true
  local tq = 1
  if tonumber(ui.dest_text.Text) then
    tq = tonumber(ui.dest_text.Text)
  end
  if tq >= menDt.quantity then
    ui.dest_right.Enable = false
  end
end, ComFuc.ComMoveCard()
local ShowDestructNum, HideDestructNum = function(text, lc)
  gui:PlayAudio("prompt")
  ui.coverControl2.Parent = gui
  ui.destruct_num.Parent = gui
  Gui.Align(ui.destruct_num, 0.5, 0.5)
  ui.dest_name.Text = text
  ui.dest_text.Text = 1
  ui.dest_text.Focused = true
  ui.dest_left.Enable = false
  SetDestRightEnable()
end, ComFuc.ComMoveCard()
local HideDestructNum, ShowLoundSpeaker = function()
  ui.coverControl2.Parent = nil
  ui.destruct_num.Parent = nil
  oldDestText = 1
end, ComFuc.ComMoveCard()
local ShowLoundSpeaker, HideLoundSpeaker = function()
  ui.coverControl2.Parent = gui
  ui.lound_speaker.Parent = gui
  ui.speak_text.Text = ""
  Gui.Align(ui.lound_speaker, 0.5, 0.5)
end, ComFuc.ComMoveCard()

function HideLoundSpeaker()
  ui.coverControl2.Parent = nil
  ui.lound_speaker.Parent = nil
  ui.speak_text.Text = ""
end

local ShowChangePetName, HideChangePetName = function()
  ui.coverControl2.Parent = gui
  ui.change_pet_name.Parent = gui
  ui.change_pet_name_text.Text = ""
  ui.change_pet_name_price.AutoWrap = true
  local skillCostTb = PetRenamePrice
  local tk = 0
  ui.pet_rename_costP_1.Visible = skillCostTb[1] and 0 < skillCostTb[1]
  ui.pet_rename_costP_2.Visible = skillCostTb[2] and 0 < skillCostTb[2]
  ui.pet_rename_costP_3.Visible = skillCostTb[3] and 0 < skillCostTb[3]
  ui.pet_rename_costP_4.Visible = skillCostTb[4] and 0 < skillCostTb[4]
  if skillCostTb[1] and 0 < skillCostTb[1] then
    ui.pet_rename_costL_1.Text = skillCostTb[1] .. " "
    ui.pet_rename_costP_1.Location = Vector2(113, 10 + 36 * tk)
    tk = tk + 1
  end
  ui.pet_rename_costCB_1.Check = skillCostTb[1] and 0 < skillCostTb[1] and tk == 1
  if skillCostTb[2] and 0 < skillCostTb[2] then
    ui.pet_rename_costL_2.Text = skillCostTb[2] .. " "
    ui.pet_rename_costP_2.Location = Vector2(113, 10 + 36 * tk)
    tk = tk + 1
  end
  ui.pet_rename_costCB_2.Check = skillCostTb[2] and 0 < skillCostTb[2] and tk == 1
  if skillCostTb[3] and 0 < skillCostTb[3] then
    ui.pet_rename_costL_3.Text = skillCostTb[3] .. " "
    ui.pet_rename_costP_3.Location = Vector2(113, 10 + 36 * tk)
    tk = tk + 1
  end
  ui.pet_rename_costCB_3.Check = skillCostTb[3] and 0 < skillCostTb[3] and tk == 1
  if skillCostTb[4] and 0 < skillCostTb[4] then
    ui.pet_rename_costL_4.Text = skillCostTb[4] .. " "
    ui.pet_rename_costP_4.Location = Vector2(113, 10 + 36 * tk)
    tk = tk + 1
  end
  ui.pet_rename_costCB_4.Check = skillCostTb[4] and 0 < skillCostTb[4] and tk == 1
  ui.change_pet_name.Size = Vector2(412, 276 + 36 * tk)
  ui.pet_rename_price_area.Size = Vector2(386, 62 + 36 * tk)
  ui.change_pet_name_price.Location = Vector2(30, 4 + 36 * tk)
  ui.change_pet_name_sure.Location = Vector2(93, 220 + 36 * tk)
  ui.change_pet_name_cancel.Location = Vector2(223, 220 + 36 * tk)
  Gui.Align(ui.change_pet_name, 0.5, 0.5)
end, function()
  ui.coverControl2.Parent = gui
  ui.change_pet_name.Parent = gui
  ui.change_pet_name_text.Text = ""
  ui.change_pet_name_price.AutoWrap = true
  local skillCostTb = PetRenamePrice
  local tk = 0
  ui.pet_rename_costP_1.Visible = skillCostTb[1] and 0 < skillCostTb[1]
  ui.pet_rename_costP_2.Visible = skillCostTb[2] and 0 < skillCostTb[2]
  ui.pet_rename_costP_3.Visible = skillCostTb[3] and 0 < skillCostTb[3]
  ui.pet_rename_costP_4.Visible = skillCostTb[4] and 0 < skillCostTb[4]
  if skillCostTb[1] and 0 < skillCostTb[1] then
    ui.pet_rename_costL_1.Text = skillCostTb[1] .. " "
    ui.pet_rename_costP_1.Location = Vector2(113, 10 + 36 * tk)
    tk = tk + 1
  end
  ui.pet_rename_costCB_1.Check = skillCostTb[1] and 0 < skillCostTb[1] and tk == 1
  if skillCostTb[2] and 0 < skillCostTb[2] then
    ui.pet_rename_costL_2.Text = skillCostTb[2] .. " "
    ui.pet_rename_costP_2.Location = Vector2(113, 10 + 36 * tk)
    tk = tk + 1
  end
  ui.pet_rename_costCB_2.Check = skillCostTb[2] and 0 < skillCostTb[2] and tk == 1
  if skillCostTb[3] and 0 < skillCostTb[3] then
    ui.pet_rename_costL_3.Text = skillCostTb[3] .. " "
    ui.pet_rename_costP_3.Location = Vector2(113, 10 + 36 * tk)
    tk = tk + 1
  end
  ui.pet_rename_costCB_3.Check = skillCostTb[3] and 0 < skillCostTb[3] and tk == 1
  if skillCostTb[4] and 0 < skillCostTb[4] then
    ui.pet_rename_costL_4.Text = skillCostTb[4] .. " "
    ui.pet_rename_costP_4.Location = Vector2(113, 10 + 36 * tk)
    tk = tk + 1
  end
  ui.pet_rename_costCB_4.Check = skillCostTb[4] and 0 < skillCostTb[4] and tk == 1
  ui.change_pet_name.Size = Vector2(412, 276 + 36 * tk)
  ui.pet_rename_price_area.Size = Vector2(386, 62 + 36 * tk)
  ui.change_pet_name_price.Location = Vector2(30, 4 + 36 * tk)
  ui.change_pet_name_sure.Location = Vector2(93, 220 + 36 * tk)
  ui.change_pet_name_cancel.Location = Vector2(223, 220 + 36 * tk)
  Gui.Align(ui.change_pet_name, 0.5, 0.5)
end

function HideChangePetName()
  ui.coverControl2.Parent = nil
  ui.change_pet_name.Parent = nil
  ui.change_pet_name_text.Text = ""
end

local ShowPetSlotExpandUI, HidePetSlotExpandUI = function()
  ui.coverControl2.Parent = gui
  ui.pet_slot_expand_price_ui.Parent = gui
  ui.pet_slot_expand_price_choose.AutoWrap = true
  ui.pet_slot_expand_num_now.Text = UnlockedPetSlotNum
  ui.pet_slot_expand_num_next.Text = UnlockedPetSlotNum + 1
  if UnlockedPetSlotNum >= 30 then
    ui.pet_slot_expand_num_now.Text = 30
    ui.pet_slot_expand_num_next.Text = 30
  end
  local skillCostTb = currentPetSlotExpandPrice
  local tk = 0
  ui.pet_slot_expand_costP_1.Visible = skillCostTb[1] and skillCostTb[1] > 0
  ui.pet_slot_expand_costP_2.Visible = skillCostTb[2] and 0 < skillCostTb[2]
  ui.pet_slot_expand_costP_3.Visible = skillCostTb[3] and 0 < skillCostTb[3]
  ui.pet_slot_expand_costP_4.Visible = skillCostTb[4] and 0 < skillCostTb[4]
  if skillCostTb[1] and skillCostTb[1] > 0 then
    ui.pet_slot_expand_costL_1.Text = skillCostTb[1] .. " "
    ui.pet_slot_expand_costP_1.Location = Vector2(113, 54 + 36 * tk)
    tk = tk + 1
  end
  ui.pet_slot_expand_costCB_1.Check = skillCostTb[1] and skillCostTb[1] > 0 and tk == 1
  if skillCostTb[2] and 0 < skillCostTb[2] then
    ui.pet_slot_expand_costL_2.Text = skillCostTb[2] .. " "
    ui.pet_slot_expand_costP_2.Location = Vector2(113, 54 + 36 * tk)
    tk = tk + 1
  end
  ui.pet_slot_expand_costCB_2.Check = skillCostTb[2] and 0 < skillCostTb[2] and tk == 1
  if skillCostTb[3] and 0 < skillCostTb[3] then
    ui.pet_slot_expand_costL_3.Text = skillCostTb[3] .. " "
    ui.pet_slot_expand_costP_3.Location = Vector2(113, 54 + 36 * tk)
    tk = tk + 1
  end
  ui.pet_slot_expand_costCB_3.Check = skillCostTb[3] and 0 < skillCostTb[3] and tk == 1
  if skillCostTb[4] and 0 < skillCostTb[4] then
    ui.pet_slot_expand_costL_4.Text = skillCostTb[4] .. " "
    ui.pet_slot_expand_costP_4.Location = Vector2(113, 54 + 36 * tk)
    tk = tk + 1
  end
  ui.pet_slot_expand_costCB_4.Check = skillCostTb[4] and 0 < skillCostTb[4] and tk == 1
  ui.pet_slot_expand_price_ui.Size = Vector2(412, 276 + 36 * tk)
  ui.pet_slot_expand_price_area.Size = Vector2(386, 62 + 36 * tk)
  ui.pet_slot_expand_price_choose.Location = Vector2(30, 10)
  ui.pet_slot_expand_sure.Location = Vector2(128, 220 + 36 * tk)
  Gui.Align(ui.pet_slot_expand_price_ui, 0.5, 0.5)
end, function()
  ui.coverControl2.Parent = gui
  ui.pet_slot_expand_price_ui.Parent = gui
  ui.pet_slot_expand_price_choose.AutoWrap = true
  ui.pet_slot_expand_num_now.Text = UnlockedPetSlotNum
  ui.pet_slot_expand_num_next.Text = UnlockedPetSlotNum + 1
  if UnlockedPetSlotNum >= 30 then
    ui.pet_slot_expand_num_now.Text = 30
    ui.pet_slot_expand_num_next.Text = 30
  end
  local skillCostTb = currentPetSlotExpandPrice
  local tk = 0
  ui.pet_slot_expand_costP_1.Visible = skillCostTb[1] and skillCostTb[1] > 0
  ui.pet_slot_expand_costP_2.Visible = skillCostTb[2] and 0 < skillCostTb[2]
  ui.pet_slot_expand_costP_3.Visible = skillCostTb[3] and 0 < skillCostTb[3]
  ui.pet_slot_expand_costP_4.Visible = skillCostTb[4] and 0 < skillCostTb[4]
  if skillCostTb[1] and skillCostTb[1] > 0 then
    ui.pet_slot_expand_costL_1.Text = skillCostTb[1] .. " "
    ui.pet_slot_expand_costP_1.Location = Vector2(113, 54 + 36 * tk)
    tk = tk + 1
  end
  ui.pet_slot_expand_costCB_1.Check = skillCostTb[1] and skillCostTb[1] > 0 and tk == 1
  if skillCostTb[2] and 0 < skillCostTb[2] then
    ui.pet_slot_expand_costL_2.Text = skillCostTb[2] .. " "
    ui.pet_slot_expand_costP_2.Location = Vector2(113, 54 + 36 * tk)
    tk = tk + 1
  end
  ui.pet_slot_expand_costCB_2.Check = skillCostTb[2] and 0 < skillCostTb[2] and tk == 1
  if skillCostTb[3] and 0 < skillCostTb[3] then
    ui.pet_slot_expand_costL_3.Text = skillCostTb[3] .. " "
    ui.pet_slot_expand_costP_3.Location = Vector2(113, 54 + 36 * tk)
    tk = tk + 1
  end
  ui.pet_slot_expand_costCB_3.Check = skillCostTb[3] and 0 < skillCostTb[3] and tk == 1
  if skillCostTb[4] and 0 < skillCostTb[4] then
    ui.pet_slot_expand_costL_4.Text = skillCostTb[4] .. " "
    ui.pet_slot_expand_costP_4.Location = Vector2(113, 54 + 36 * tk)
    tk = tk + 1
  end
  ui.pet_slot_expand_costCB_4.Check = skillCostTb[4] and 0 < skillCostTb[4] and tk == 1
  ui.pet_slot_expand_price_ui.Size = Vector2(412, 276 + 36 * tk)
  ui.pet_slot_expand_price_area.Size = Vector2(386, 62 + 36 * tk)
  ui.pet_slot_expand_price_choose.Location = Vector2(30, 10)
  ui.pet_slot_expand_sure.Location = Vector2(128, 220 + 36 * tk)
  Gui.Align(ui.pet_slot_expand_price_ui, 0.5, 0.5)
end
local HidePetSlotExpandUI, HidePetOpUI = function()
  ui.coverControl2.Parent = nil
  ui.pet_slot_expand_price_ui.Parent = nil
end, ComFuc.ComMoveCard()
local HidePetOpUI, HidePetSkillUI = function()
  ui.pet_coverControl.Parent = nil
  ui.pet_op_ui_main.Parent = nil
end, ComFuc.ComMoveCard()
local HidePetSkillUI, ShowParAdd = function()
  ui.pet_coverControl.Parent = nil
  ui.pet_skill_ui_main.Parent = nil
end, ComFuc.ComMoveCard()
local ShowParAdd, ShowExploreParAdd = function(i, p)
  return ComFuc.ShowParAdd(p, ui["main_par_" .. i], ui["main_par_" .. i .. "_pet"])
end, ComFuc.ComMoveCard()

function ShowExploreParAdd(i, p)
  if p and math.floor(p) > 0 then
    ui["explore_main_par_" .. i].TextColor = colg
    return math.floor(p)
  end
  ui["explore_main_par_" .. i].TextColor = colw
  return 0
end

local filter = {
  {
    1,
    {2, 1},
    GetUTF8Text("tips_abilities_Rifle")
  },
  {
    2,
    {2, 2},
    GetUTF8Text("tips_abilities_Sniper_Rifle")
  },
  {
    3,
    {2, 3},
    GetUTF8Text("UI_common_M_G")
  },
  {
    4,
    {2, 14},
    GetUTF8Text("UI_datalist_m32_type")
  },
  {
    5,
    {2, 4},
    GetUTF8Text("tips_abilities_Shotgun")
  },
  {
    6,
    {2, 5},
    GetUTF8Text("tips_abilities_Pistol")
  },
  {
    7,
    {2, 11},
    GetUTF8Text("tips_abilities_Bazooka")
  },
  {
    8,
    {2, 15},
    GetUTF8Text("UI_datalist_penwuqi_type")
  },
  {
    9,
    {2, 10},
    GetUTF8Text("tips_abilities_Grenade")
  },
  {
    10,
    {2, 12},
    GetUTF8Text("tips_abilities_Bow")
  },
  {
    11,
    {2, 13},
    GetUTF8Text("tips_abilities_Shield_Weapon")
  },
  {
    12,
    {2, 16},
    GetUTF8Text("UI_datalist_nu_type")
  },
  {
    13,
    {2, 6},
    GetUTF8Text("tips_abilities_Knife")
  },
  {
    14,
    {2, 102},
    GetUTF8Text("tips_abilities_Equipment_for_back")
  },
  {
    15,
    {2, 103},
    GetUTF8Text("button_common_Ring")
  },
  {
    16,
    {3, 103},
    GetUTF8Text("button_common_Item")
  },
  {
    17,
    {3, 303},
    GetUTF8Text("UI_common_make_07")
  },
  {
    18,
    {5, 2},
    GetUTF8Text("button_common_Avatar_Card")
  }
}
yellow = ARGB(255, 252, 221, 49)
gray = ARGB(255, 164, 165, 165)
brown = ARGB(255, 113, 83, 65)
node_1 = {}
node_2 = nil
lv = ui.manu_draw_list
lv:AddColumn("", 250, "kAlignLeftMiddle")
lv:AddColumn("", 150, "kAlignRightMiddle")
local SetReinFinish = lv.AddColumn
local SetReinFinish, SetMixCount = function(p, name, size, lc)
  TimerRemove()
  reinState = p
  ui.reinStateCtrl.Size = size
  ui.reinStateCtrl.Location = lc
  ui.reinStateCtrl_son.Visible = p == 1 and isAddMore
  if p == 1 and isAddMore then
    ui.reinStateCtrl.Skin = SkinF.personalInfo_209[5]
  else
    ui.reinStateCtrl.Skin = SkinF.personalInfo_209[p]
  end
  ui.reinStateCtrl.Parent = gui
  gui:AddParticle(name, Vector2(ComFuc.locationChanged + 600, 450), Vector3(0, 1, 0))
  timer = game.TimerMgr:AddTimer(0.05)
  timer.EventOnTimer = TimerRefresh1
end, lv
local SetMixCount, OpenWeaponDoor = function(a, b, tc)
  if a then
    mixHas = a
  end
  if b then
    mixNeed = b
  end
  if tc then
    ui.mix_daqu.Visible = tc == 5
    for i = 1, 5 do
      ui["mix_b_" .. i].Visible = i <= tc
      ui["mix_ti_" .. i].Visible = i <= tc
      if i <= tc then
        ui["mix_p_" .. i].BackgroundColor = colw
        ShowOneButton(ui["mix_p_" .. i], ui["mix_b_" .. i], resDir, menDt.resource, menDt.grade)
        ui["mix_b_s_" .. i].EventMouseEnter = function(sender, e)
          Tip.SetRpc(tip_sys_interface[3], {
            t = 3,
            sid = menDt.sid
          })
          Tip.SetUseDescription(false)
          Tip.SetOwner(sender)
        end
      else
        ui["mix_p_" .. i].BackgroundColor = col0
      end
    end
  end
  ui.mix_center.Size = Vector2(114, 130)
  if mixNeed ~= 0 then
    ui.mix_center.GoalSize = Vector2(114, (1 - math.min(5, mixHas) * 1 / mixNeed) * 130)
  else
    ui.mix_center.GoalSize = Vector2(114, 130)
  end
  ui.need_to_medal.Text = mixHas .. "/" .. mixNeed
  ui.btn_combMix.Enable = mixHas >= mixNeed and mixNeed ~= 0
end, ""
local OpenWeaponDoor, ShowRefitTiao = function()
  TimerRemove()
  timer = game.TimerMgr:AddTimer(0.05)
  timer.EventOnTimer = TimerRefresh3
end, 150
local ShowRefitTiao, SetDecomposition = function(i, res, hc, nc, na, id, gr)
  ui["tiao_" .. i].Visible = nc and 0 < nc
  ui["refMtr_res_" .. i].Skin = Gui.ControlSkin({
    BackgroundImage = Gui.Image("ui/skinF/lobby/" .. res .. ".tga", Vector4(0, 0, 0, 0))
  })
  ui["refMtr_count_" .. i].Text = string.format("%d/%d", hc, nc)
  if nc <= hc then
    ui["refMtr_count_" .. i].TextureFont = SkinF.hecheng_number_5
  else
    ui["refMtr_count_" .. i].TextureFont = SkinF.hecheng_number_6
    if i == 1 or i == 2 or i == 6 or i == 7 or i == 8 then
      isEnough = false
    end
  end
  if na then
    ui["refMtr_name_" .. i].Text = na
  end
  ui["refMtr_res_p_" .. i].Skin = SkinF.personalInfo_quality[gr]
  ui["refMtr_res_" .. i].EventMouseEnter = function(sender, e)
    Tip.SetRpc(tip_sys_interface[3], {t = 3, sid = id})
    Tip.SetUseDescription(false)
    Tip.SetOwner(sender)
  end
end, "kAlignRightMiddle"
local SetDecomposition, ReMoveRefitPt = function(p)
  local msg = GetUTF8Text("UI_common_Confirm_to_disassemble")
  if p == 1 then
    msg = GetUTF8Text("msgbox_store_open_confirm")
  end
  MessageBox.ShowWithConfirmCancel(msg, function(sender, e)
    rpc_weapon_decomposition()
    rpc_storage_storage_list(ui.pb_depot.CurrIndex)
  end)
end, {
  6,
  {2, 5},
  GetUTF8Text("tips_abilities_Pistol")
}
local ReMoveRefitPt, AddRefitPt = function()
  for i = 1, 20 do
    ui["refit_pt_" .. i].Particle:SetEnable(false)
  end
end, {
  7,
  {2, 11},
  GetUTF8Text("tips_abilities_Bazooka")
}
local AddRefitPt, SetBtnRefitClick = function(p)
  ReMoveRefitPt()
  refitPtLev = p
  for i = 1, p do
    ui["refit_pt_" .. i].Particle:SetEnable(true)
  end
end, {
  8,
  {2, 15},
  GetUTF8Text("UI_datalist_penwuqi_type")
}
local SetBtnRefitClick, SetBtnHangClick = function()
  if ui.useLucyReel.Enable and ui.useLucyReel.Check then
    gui:PlayAudio("upgrade_2")
  else
    gui:PlayAudio("upgrade")
  end
  ui.btn_combRefit.Enable = false
  ui.coverControlNew.Parent = gui
  local tlr = "N"
  local tlh = "N"
  if ui.useLucyReel.Check then
    tlr = "Y"
  end
  if ui.useInheritAtri.Check then
    tlh = "Y"
  end
  rpc_refit_finish(tlr, tlh)
end, {
  9,
  {2, 10},
  GetUTF8Text("tips_abilities_Grenade")
}
local SetBtnHangClick, CleanSkillList = function()
  if ui.usePropertyLock.Enable and ui.usePropertyLock.Check then
    gui:PlayAudio("upgrade_2")
  else
    gui:PlayAudio("upgrade")
  end
  ui.btn_combHang.Enable = false
  ui.coverControl3.Parent = gui
  local tlr = 0
  if ui.usePropertyLock.Check then
    tlr = 1
  end
  rpc_weapon_add_property(tlr)
end, {
  10,
  {2, 12},
  GetUTF8Text("tips_abilities_Bow")
}
local CleanSkillList, CleanHotKyeList = function()
  skillCost = {}
  ui.btn_skill_finish.Enable = false
  for i = 1, 5 do
    ui["skill_dec_" .. i].Enable = false
    ui["skill_add_" .. i].Enable = false
  end
end, {
  11,
  {2, 13},
  GetUTF8Text("tips_abilities_Shield_Weapon")
}
local CleanHotKyeList, CleanInsertCard = function()
  ComFuc.hasWeaponCount = 0
  ComFuc.hasWeaponNoTime = 0
  htkDt = {}
  for i = 1, 12 do
    ui["hot_key_b_" .. i].Skin = SkinF.skin_touming2
    ui["hot_key_bs_" .. i].Visible = false
    ui["hot_key_p_" .. i].Visible = true
    ui["hot_key_p_" .. i].Skin = SkinF.personalInfo_094
    ui["hot_key_l2_" .. i].Visible = false
    ui["hot_key_level_" .. i].Visible = false
    ui["pet_op_hotkey_b_" .. i].Skin = SkinF.skin_touming2
    ui["pet_op_hotkey_bs_" .. i].Visible = false
    ui["pet_op_hotkey_p_" .. i].Visible = true
    ui["pet_op_hotkey_p_" .. i].Skin = SkinF.personalInfo_094
    ui["pet_op_hotkey_l2_" .. i].Visible = false
  end
end, {
  12,
  {2, 16},
  GetUTF8Text("UI_datalist_nu_type")
}
local CleanInsertCard, CleanMixSlot = function(is0, is1)
  tableInsP = {}
  tableInsB = {}
  tableDepot = {}
  insDt = {}
  slotRenforceId = {
    0,
    0,
    0,
    0,
    0
  }
  slotRenforceBf = {}
  insCost = 0
  ui.insert_card_p.Visible = false
  ui.combIns_cost.Text = "0  "
  ui.insert_life.Text = "+0"
  ui.insert_add.Text = "+0"
  ui.insert_protect.Text = "+0"
  ui.insert_recover.Text = "+0"
  for i = 1, 5 do
    if is1 then
      ui["insert_p_" .. i].BackgroundColor = colw
      ui["insert_pd_" .. i].Text = " "
      ui["insert_pd_" .. i].BackgroundColor = col0
      ui["insert_b_" .. i].Visible = false
      ui["insert_c2_" .. i].Visible = false
      ui["insert_kb_" .. i].Visible = true
    end
    ui["ins_ti_" .. i].Visible = false
    ui["insert_kb_" .. i].Enable = not is0
    ui["insert_p_" .. i].Hint = ""
  end
end, {
  13,
  {2, 6},
  GetUTF8Text("tips_abilities_Knife")
}
local CleanMixSlot, CleanReinforce = function()
  menDt = {}
  SetMixCount(0, 0, 0)
  ui.combMix_cost.Text = "0  "
end, {
  14,
  {2, 102},
  GetUTF8Text("tips_abilities_Equipment_for_back")
}
local CleanReinforce, CleanHang = function()
  ui.yellow_text.Text = ""
  refitDt = {}
  ReMoveRefitPt()
  ShowOneClassCtrl("tiao_", 4, false)
  ShowOneClassCtrl("refit_lev_", 10, false)
  ui.refit_cost.Text = "0  "
  ui.refit_point.Skin = SkinF.personalInfo_219[1]
  ui.refit_Tbar_s.Skin = SkinF.personalInfo_220[1]
  ui.equip_b_13.Skin = SkinF.skin_touming2
  ui.equip_b_14.Skin = SkinF.skin_touming2
  ui.equip_c_14.Visible = false
  ui.Tips_To_DragMetrailWeapon.Visible = false
  ui.equip_pd_13.BackgroundColor = col0
  ui.equip_pd_14.BackgroundColor = col0
  ui.refit_Tbar.Size = Vector2(66, 24)
  ui.btn_combRefit.Enable = false
  ui.coverControl3.Parent = nil
  ui.refit_opTip.Visible = true
  ui.refit_opTip_2.Visible = false
  ui.equip_level_13.Visible = false
  ui.equip_level_14.Visible = false
  ui.btn_combRefit.Hint = ""
  if refitMoveDir == 0 then
    ui.refit_lev_content_1.Location = Vector2(0, 0)
    ui.refit_lev_content_2.Location = Vector2(249, 0)
    ui.refit_lev_content_3.Location = Vector2(478, 0)
    ui.refit_lev_content_4.Location = Vector2(728, 0)
  end
  ComputeWeaponEnhanceBar()
end, {
  15,
  {2, 103},
  GetUTF8Text("button_common_Ring")
}
local CleanHang, CleanManuItem = function()
  hangDt = {}
  hangAddDt = {}
  hangMentDt = {}
  HangProNth = 1
  HangProHas = 1
  ShowOneClassCtrl("tiao_", 8, false, 5)
  ui.hang_bar.Size = Vector2(0, 30)
  ui.hang_value.Text = "+ 0"
  ui.hang_cost.Text = "0  "
  ui.equip_b_15.Skin = SkinF.skin_touming2
  ui.equip_pd_15.BackgroundColor = col0
  ui.equip_level_15.Visible = false
  ui.hang_opTip_p.Visible = true
  ui.hang_por_parent.Visible = false
  ui.hang_value.Visible = false
  ui.coverControl3.Parent = nil
  ui.btn_combHang.Enable = false
  ui.btn_combHang.Hint = nil
end, {
  16,
  {3, 103},
  GetUTF8Text("button_common_Item")
}
local CleanManuItem, CleanManu = function()
  for i = 1, 4 do
    ui["manu_tiao_" .. i].Visible = false
  end
  ui.btn_combManuf.Enable = false
  ui.combManuf_cost.Text = "0  "
  ui.manu_text.Text = ""
  ui.manu_has.Text = "/0"
  ui.manu_tudi.Visible = false
  ui.manu_tuwu.Visible = true
  ui.manu_text.Enable = false
  ui.btn_manuAll.Enable = false
  ui.manu_tuwu.EventMouseEnter = nil
end, {
  17,
  {3, 303},
  GetUTF8Text("UI_common_make_07")
}
local CleanManu, CleanReinforceTap = function()
  lv:DeleteAll()
  CleanManuItem()
end, {
  18,
  {5, 2},
  GetUTF8Text("button_common_Avatar_Card")
}
local CleanReinforceTap, CleanMainTap = function(i)
  ReMoveRefitPt()
  if reinforceCurr == 1 then
    CleanInsertCard(true, true)
  elseif reinforceCurr == 2 then
    CleanMixSlot()
  elseif reinforceCurr == 3 then
    CleanReinforce()
  elseif reinforceCurr == 4 then
    CleanHang()
  elseif reinforceCurr == 5 then
    CleanManu()
  end
end, 18
local CleanMainTap, DealPlayerInfo = function(i)
  if 2 == i then
    ComFuc.CleanDepotTap(ui, PersonalInfo, depotCurr)
  elseif 3 == i then
    CleanSkillList()
  elseif 4 == i then
    CleanReinforceTap(reinforceCurr)
  end
  ui.left.Visible = true
  ui.right.Visible = true
  ui.btm.Visible = true
  ui.mid_all.Parent = nil
  ui.left_main_1.Parent = nil
  ui.left_main_2.Parent = nil
  ui.left_main_pet.Parent = nil
  ui.right_main_2.Parent = nil
  ui.right_main_3.Parent = nil
  ui.right_main_pet_1.Parent = nil
  ui.right_main_pet_2.Parent = nil
end, {5, 2}
local DealPlayerInfo, SetPetMood = function(data)
  ui.main_par_2.Text = math.floor(data.player.cureQuantity) + ShowParAdd(2, data.player.cureQuantity_p)
  ui.main_par_3.Text = math.floor(data.player.recoveryCapacity) + ShowParAdd(3, data.player.recoveryCapacity_p)
  ui.main_par_4.Text = math.floor(data.player.armor) + ShowParAdd(4, data.player.armor_p)
  ui.main_par_5.Text = math.floor(data.player.arp) + ShowParAdd(5, data.player.arp_p)
  ui.main_par_6.Text = math.floor(data.player.stamina) + ShowParAdd(6, data.player.stamina_p)
  local tp = NumeralConst.CharacterTransform("耐力", data.player.stamina + data.player.stamina_p, data.player.occupation + 1)
  ui.main_par_1.Text = data.player.life + ShowParAdd(1, tp)
  ComFuc.info_table.stamina = data.player.stamina + data.player.stamina_p
  ComFuc.info_table.cure = tonumber(ui.main_par_2.Text)
  ComFuc.info_table.recovery = tonumber(ui.main_par_3.Text)
  ComFuc.info_table.armor = tonumber(ui.main_par_4.Text)
  ComFuc.info_table.arp = tonumber(ui.main_par_5.Text)
  local tj = 0
  ui.main_par_1.Hint = string.format(GetUTF8Text("tips_lobby_Ability_Desc4"), data.player.life + tp)
  tj = NumeralConst.CharacterTransform("活力", data.player.cureQuantity + data.player.cureQuantity_p)
  local tt, n = string.gsub(GetUTF8Text("tips_lobby_Ability_Desc6"), "%%d", tj)
  ui.main_par_2.Hint = tt
  tj = NumeralConst.CharacterTransform("恢复力", data.player.recoveryCapacity + data.player.recoveryCapacity_p)
  ui.main_par_3.Hint = string.format(GetUTF8Text("tips_lobby_Ability_Desc7"), tj)
  tj = NumeralConst.CharacterTransform("护甲", data.player.armor + data.player.armor_p)
  tt, n = string.gsub(GetUTF8Text("tips_lobby_Ability_Desc8"), "%%d", tj)
  ui.main_par_4.Hint = tt
  ui.main_par_5.Hint = string.format(GetUTF8Text("tips_lobby_Ability_Desc9"), math.floor(data.player.arp) + math.floor(data.player.arp_p))
  ui.main_par_6.Hint = string.format(GetUTF8Text("tips_lobby_Ability_Desc5"), tp)
  ui.explore_main_par_2.Text = math.floor(data.player.cureQuantity) + ShowExploreParAdd(2, data.player.cureQuantity_v)
  ui.explore_main_par_3.Text = math.floor(data.player.recoveryCapacity) + ShowExploreParAdd(3, data.player.recoveryCapacity_v)
  ui.explore_main_par_4.Text = math.floor(data.player.armor) + ShowExploreParAdd(4, data.player.armor_v)
  ui.explore_main_par_5.Text = math.floor(data.player.arp) + ShowExploreParAdd(5, data.player.arp_v)
  ui.explore_main_par_6.Text = math.floor(data.player.stamina) + ShowExploreParAdd(6, data.player.stamina_v)
  tp = NumeralConst.CharacterTransform("耐力", data.player.stamina + data.player.stamina_v, data.player.occupation + 1)
  ui.explore_main_par_1.Text = data.player.life + ShowExploreParAdd(1, tp)
  tj = 0
  ui.explore_main_par_1.Hint = string.format(GetUTF8Text("tips_lobby_Ability_Desc4"), data.player.life + tp)
  tj = NumeralConst.CharacterTransform("活力", data.player.cureQuantity + data.player.cureQuantity_v)
  tt, n = string.gsub(GetUTF8Text("tips_lobby_Ability_Desc6"), "%%d", tj)
  ui.explore_main_par_2.Hint = tt
  tj = NumeralConst.CharacterTransform("恢复力", data.player.recoveryCapacity + data.player.recoveryCapacity_v)
  ui.explore_main_par_3.Hint = string.format(GetUTF8Text("tips_lobby_Ability_Desc7"), tj)
  tj = NumeralConst.CharacterTransform("护甲", data.player.armor + data.player.armor_v)
  tt, n = string.gsub(GetUTF8Text("tips_lobby_Ability_Desc8"), "%%d", tj)
  ui.explore_main_par_4.Hint = tt
  ui.explore_main_par_5.Hint = string.format(GetUTF8Text("tips_lobby_Ability_Desc9"), math.floor(data.player.arp) + math.floor(data.player.arp_v))
  ui.explore_main_par_6.Hint = string.format(GetUTF8Text("tips_lobby_Ability_Desc5"), tp)
  ExpBar.SetExpBar(Lobby.ui.bar_exp, Lobby.ui.bar_exp_c, Lobby.ui.bar_exp_l, data.player.expCurrentLevelOffset, data.player.expNextLevelOffset)
  ui["equip_p_" .. 2].Skin = SkinF.personalInfo_quality[data.player.equipAvatarGrade or 1]
  if ComFuc.selToLobbyState == 0 then
    ComFuc.selToLobbyState = 1
    equipAvatarId = data.player.avatarId
    ComFuc.DealAvatarEquip(data.player.equipAvatar)
    ComFuc.SetHeadPhotoCardData(data.player.equipAvatar, 0)
    ComFuc.SetHeadPhotoCardData(data.player.equipAvatar, 7)
    ComFuc.SetPersonCardData(data.player.equipAvatar, 0, data.player.position)
    ComFuc.ShowUpgradeLevel(data.player, 5, ui.equip_card_level, ui.equit_card_level_text)
  end
  independentTrinket = data.player.equips
  ShowMessageEquipButton()
  ComFuc.ResetAnim()
  ComFuc.hasEquipNoTime = 0
  for i, v in ipairs(data.player.equips) do
    if v.unitType and v.unit and v.unitType == 2 and 0 >= v.unit then
      ComFuc.hasEquipNoTime = ComFuc.hasEquipNoTime + 1
    end
  end
  ui.main_par_1_pet.Text = ui.main_par_1.Text
  ui.main_par_2_pet.Text = ui.main_par_2.Text
  ui.main_par_3_pet.Text = ui.main_par_3.Text
  ui.main_par_4_pet.Text = ui.main_par_4.Text
  ui.main_par_5_pet.Text = ui.main_par_5.Text
  ui.main_par_6_pet.Text = ui.main_par_6.Text
  ui.main_par_1_pet.Hint = ui.main_par_1.Hint
  ui.main_par_2_pet.Hint = ui.main_par_2.Hint
  ui.main_par_3_pet.Hint = ui.main_par_3.Hint
  ui.main_par_4_pet.Hint = ui.main_par_4.Hint
  ui.main_par_5_pet.Hint = ui.main_par_5.Hint
  ui.main_par_6_pet.Hint = ui.main_par_6.Hint
  if data.player.avatarSubType == 1 then
    ui.equip_b_2.Skin = SkinF.personalInfo_143
    ui.equip_card_level.Skin = SkinF.avatar_level
  elseif data.player.avatarSubType == 2 then
    ui.equip_b_2.Skin = SkinF.personalInfo_261
    ui.equip_card_level.Skin = SkinF.avatar_level_hero
  end
  AvtarSkillId = data.player.avatarSkill.skillId
  AvtarSkillLevel = data.player.avatarSkill.level
  if AvtarSkillId == 0 then
    ui.avtar_skill.Visible = false
  else
    if PersonalInfo.mainCurr == 2 and PersonalInfo.depotCurr == 4 then
      ui.avtar_skill.Visible = true
    end
    ui.avtar_skill.Skin = Gui.ButtonSkin({
      BackgroundImage = Gui.Image(resDir .. data.player.avatarSkill.resource .. ".tga", Vector4(0, 0, 0, 0))
    })
  end
  if menDt and menDt.position and mainCurr == 2 and depotCurr == 4 then
    lg:PlayPoseAnimation(menDt.position)
  end
end, GetUTF8Text("button_common_Avatar_Card")
local SetPetMood, SetPetQualityUI = function(iMood)
  if iMood < 0 then
    iMood = 0
  end
  if 100 <= iMood then
    iMood = 99
  end
  local iMoodLevel = math.floor(iMood / 25) + 1
  ui.pet_info_mood.Skin = SkinF.personalInfo_pet_mood[iMoodLevel]
  if iMood == 0 then
    ui.pet_mesh_bad_cover.Visible = true
  else
    ui.pet_mesh_bad_cover.Visible = false
  end
end, GetUTF8Text("button_common_Avatar_Card")
local SetPetQualityUI, ClearPetOpBar = function(iQuality)
  if iQuality < 0 then
    iQuality = 0
  end
  if 5 < iQuality then
    iQuality = 5
  end
  for i = 1, iQuality do
    ui["pet_quality_" .. i].Skin = SkinF.personalInfo_pet_star[2]
  end
  for i = iQuality + 1, 5 do
    ui["pet_quality_" .. i].Skin = SkinF.personalInfo_pet_star[1]
  end
end, GetUTF8Text("button_common_Avatar_Card")
local ClearPetOpBar, FillUpPetOpBar = function(iIndex)
  if 0 < iIndex and iIndex < 6 then
    ui["pet_op_on_off_" .. iIndex].Skin = SkinF.personalInfo_pet_button_off
    ui["pet_op_condition_" .. iIndex]:RemoveAll()
    ui["pet_op_slot_l_" .. iIndex].Text = ""
    ui["pet_op_slot_l_" .. iIndex].Visible = false
    ui["pet_op_slot_bg_" .. iIndex].Visible = false
    ui["pet_op_show_l_" .. iIndex].Text = ""
    ui["pet_op_show_l_" .. iIndex].Visible = false
    ui["pet_op_show_bg_" .. iIndex].Visible = false
  end
end, GetUTF8Text("button_common_Avatar_Card")
local FillUpPetOpBar, ChangePetCandidateSelection = function(iIndex)
  if 0 < iIndex and iIndex < 6 then
    if CurrentPetOpSettings[iIndex].isActive == 1 then
      ui["pet_op_on_off_" .. iIndex].Skin = SkinF.personalInfo_pet_button_on
    else
      ui["pet_op_on_off_" .. iIndex].Skin = SkinF.personalInfo_pet_button_off
    end
    ui["pet_op_condition_" .. iIndex]:RemoveAll()
    if CurrentPetOpConditions then
      local selected_con = 0
      for con_i = 1, #CurrentPetOpConditions do
        ui["pet_op_condition_" .. iIndex]:AddItem(GetUTF8Text(CurrentPetOpConditions[con_i].displayName))
        if CurrentPetOpSettings[iIndex].sysPetCustomSkillId == CurrentPetOpConditions[con_i].id then
          selected_con = con_i - 1
        end
      end
      ui["pet_op_condition_" .. iIndex].SelectedIndexSilent = selected_con
    end
    ui["pet_op_slot_l_" .. iIndex].Text = ""
    if CurrentPetOpSettings[iIndex].playerPackSlot then
      if 0 < CurrentPetOpSettings[iIndex].playerPackSlot and CurrentPetOpSettings[iIndex].playerPackSlot < 13 then
        ui["pet_op_slot_l_" .. iIndex].Text = config:GetSlotKeyName(CurrentPetOpSettings[iIndex].playerPackSlot)
        ui["pet_op_slot_l_" .. iIndex].AutoWrap = true
        ui["pet_op_slot_l_" .. iIndex].Visible = true
        ui["pet_op_slot_bg_" .. iIndex].Visible = true
        ui["pet_op_show_l_" .. iIndex].Text = config:GetSlotKeyName(CurrentPetOpSettings[iIndex].playerPackSlot)
        ui["pet_op_show_l_" .. iIndex].AutoWrap = true
        ui["pet_op_show_l_" .. iIndex].Visible = true
        ui["pet_op_show_bg_" .. iIndex].Visible = true
      else
        ui["pet_op_slot_l_" .. iIndex].Text = ""
        ui["pet_op_slot_l_" .. iIndex].Visible = false
        ui["pet_op_slot_bg_" .. iIndex].Visible = false
        ui["pet_op_show_l_" .. iIndex].Text = ""
        ui["pet_op_show_l_" .. iIndex].Visible = false
        ui["pet_op_show_bg_" .. iIndex].Visible = false
      end
    else
      ui["pet_op_slot_l_" .. iIndex].Text = ""
      ui["pet_op_slot_l_" .. iIndex].Visible = false
      ui["pet_op_slot_bg_" .. iIndex].Visible = false
      ui["pet_op_show_l_" .. iIndex].Text = ""
      ui["pet_op_show_l_" .. iIndex].Visible = false
      ui["pet_op_show_bg_" .. iIndex].Visible = false
    end
  end
end, GetUTF8Text("button_common_Avatar_Card")
local ChangePetCandidateSelection, FillPetInfoPage1 = function(i)
  SelectedCandidate = i
  for j = 1, 5 do
    ui["pet_cand_selected_" .. j].Skin = SkinF.skin_touming
  end
  local ui_slot_i = i - (CurrentSysPetPage - 1) * 5
  if 1 <= ui_slot_i and ui_slot_i <= 5 then
    ui["pet_cand_selected_" .. ui_slot_i].Skin = SkinF.personalInfo_210
  end
  if i and SysPetsData and SysPetsData[i] then
    lg:SetPetInfo(SysPetsData[i].resource, SysPetsData[i].grade)
    ui.pet_desc.Text = GetUTF8Text(SysPetsData[i].displayName)
    ui.pet_mesh_preview_1_empty.Visible = false
    if SysPetsData[i].price and #SysPetsData[i].price > 0 then
      ui.btn_create_new_pet.Text = GetUTF8Text("UI_inGame_pet_attain_02")
    else
      ui.btn_create_new_pet.Text = GetUTF8Text("UI_inGame_pet_attain_01")
    end
    ui.btn_create_new_pet.Enable = true
  else
    ui.pet_desc.Text = GetUTF8Text("UI_pet_choice")
    ui.pet_mesh_preview_1_empty.Visible = true
    ui.btn_create_new_pet.Text = GetUTF8Text("UI_common_buy_adopt")
    ui.btn_create_new_pet.Enable = false
  end
end, GetUTF8Text("button_common_Avatar_Card")
local FillPetInfoPage1, FillPetInfoPage2 = function()
  if SysPetsData then
    for i = 1, 5 do
      ui["pet_cand_lock_" .. i].Visible = false
      ui["pet_cand_btn_" .. i].Enable = true
      ui["pet_cand_preview_" .. i].Enable = true
      if SysPetsData[i] then
        ui["pet_cand_grade_" .. i].Skin = SkinF.personalInfo_quality[SysPetsData[i].grade]
        ui["pet_cand_fg_" .. i].Skin = Gui.ControlSkin({
          BackgroundImage = Gui.Image(resDir .. SysPetsData[i].icon .. ".tga", Vector4(0, 0, 0, 0))
        })
        if SysPetsData[i].isOwn == "Y" then
          ui["pet_cand_lock_" .. i].Visible = true
          ui["pet_cand_lock_" .. i].Hint = GetUTF8Text("UI_pet_already_adopt")
          ui["pet_cand_btn_" .. i].Enable = false
          ui["pet_cand_preview_" .. i].Enable = false
        end
      else
        ui["pet_cand_grade_" .. i].Skin = SkinF.skin_touming
        ui["pet_cand_fg_" .. i].Skin = SkinF.skin_touming
      end
    end
  end
  if SelectedCandidate and SysPetsData and SysPetsData[SelectedCandidate] and SysPetsData[SelectedCandidate].isOwn == "Y" then
    ChangePetCandidateSelection(0)
  end
  if SelectedCandidate and 0 < SelectedCandidate and SysPetsData and SysPetsData[SelectedCandidate] then
    lg:SetPetInfo(SysPetsData[SelectedCandidate].resource, SysPetsData[SelectedCandidate].grade)
  else
    lg:SetPetInfo("", 1)
  end
end, GetUTF8Text("button_common_Avatar_Card")
local FillPetInfoPage2, ChangePetSlotSelection = function()
  if SelectedPetSlot ~= nil and PlayerPetsData[SelectedPetSlot] ~= nil then
    lg:SetPetInfo(PlayerPetsData[SelectedPetSlot].resource, PlayerPetsData[SelectedPetSlot].grade)
    ui.pet_info_name.Text = ComFuc.GetPetDisplayName(PlayerPetsData[SelectedPetSlot].name)
    SetPetQualityUI(PlayerPetsData[SelectedPetSlot].grade)
    SetPetMood(PlayerPetsData[SelectedPetSlot].unit)
    if PlayerPetsData[SelectedPetSlot].grade < 5 then
      ExpBar.SetExpBar(ui.pet_info_exp, ui.pet_info_exp_c, ui.pet_info_exp_l, PlayerPetsData[SelectedPetSlot].exp, PlayerPetsData[SelectedPetSlot].upgradeExp)
    else
      ExpBar.SetExpBar(ui.pet_info_exp, ui.pet_info_exp_c, ui.pet_info_exp_l, 2100000001, 2100000001)
    end
    if PlayerPetsData[SelectedPetSlot].grade < 5 then
      ui.pet_food_page.Visible = true
      ui.pet_food_grade.Skin = SkinF.personalInfo_quality[PlayerPetsData[SelectedPetSlot].food.grade]
      ui.pet_food_icon.Skin = Gui.ControlSkin({
        BackgroundImage = Gui.Image(resDir .. PlayerPetsData[SelectedPetSlot].food.resource .. ".tga", Vector4(0, 0, 0, 0))
      })
      ui.pet_food_number.Visible = true
      ui.pet_food_number.Text = PlayerPetsData[SelectedPetSlot].food.quantity .. "/" .. PetFoodCost
      ui.pet_food_name.Text = GetUTF8Text(PlayerPetsData[SelectedPetSlot].food.displayName)
    else
      ui.pet_food_page.Visible = false
    end
    if PlayerPetsData[SelectedPetSlot].isEquipped == "Y" then
      ui.battle_or_rest.Text = GetUTF8Text("UI_pet_switch_03")
    else
      ui.battle_or_rest.Text = GetUTF8Text("UI_pet_switch_02")
    end
    rpc_player_pet_skill(PlayerPetsData[SelectedPetSlot].id)
    rpc_player_pet_custom_skill_list(PlayerPetsData[SelectedPetSlot].id)
  end
end, GetUTF8Text("button_common_Avatar_Card")

function ChangePetSlotSelection(i)
  local ui_slot_i = i - (CurrentPlayerPetPage - 1) * 5
  SelectedPetSlot = i
  for j = 1, 5 do
    ui["pet_slot_highlight_" .. j].Skin = SkinF.skin_touming
  end
  if 1 <= ui_slot_i and ui_slot_i <= 5 then
    ui["pet_slot_highlight_" .. ui_slot_i].Skin = SkinF.personalInfo_210
  end
  if PlayerPetsData and PlayerPetsData[i] then
    ui.right_main_pet_1.Parent = nil
    ui.right_main_pet_2.Parent = ui.main_mid
    FillPetInfoPage2()
  else
    ui.right_main_pet_1.Parent = ui.main_mid
    ui.right_main_pet_2.Parent = nil
    FillPetInfoPage1()
  end
end

local ui.pet_desc.AutoWrap, DealPlayerPetList = true, ui.pet_desc
local DealPlayerPetList, DealPlayerPetOpen = function(data)
  ui.coverControlpet.Parent = gui
  CurrentPlayerPetPage = data.page
  TotalPlayerPetPage = data.pages
  UnlockedPetSlotNum = data.unlockedSlot
  local unlocked_currentpage = UnlockedPetSlotNum - (CurrentPlayerPetPage - 1) * 5
  ui.btn_pet_list_previous_page.Enable = CurrentPlayerPetPage ~= 1
  ui.btn_pet_list_next_page.Enable = CurrentPlayerPetPage < TotalPlayerPetPage
  PetFoodCost = data.foodCost
  PetRenamePrice = {}
  for i, v in ipairs(data.renamePrice) do
    PetRenamePrice[v.currency] = v.price
  end
  currentPetSlotExpandPrice = {}
  for i, v in ipairs(data.expandSlotPrice) do
    currentPetSlotExpandPrice[v.currency] = v.price
  end
  PlayerPetsData = {}
  for i, v in pairs(data.pets) do
    if data.pets[i].seq then
      PlayerPetsData[data.pets[i].seq] = data.pets[i]
    end
  end
  local old_EquippedPetResource = EquippedPetResource
  local old_EquippedPetGrade = EquippedPetGrade
  EquippedPetResource = nil
  EquippedPetGrade = nil
  if PlayerPetsData ~= nil then
    for i = 1, 30 do
      if PlayerPetsData[i] and PlayerPetsData[i].isEquipped == "Y" then
        EquippedPetResource = PlayerPetsData[i].resource
        EquippedPetGrade = PlayerPetsData[i].grade
      end
    end
    for i = 1, 5 do
      if unlocked_currentpage < i then
        ui["pet_slot_btn_" .. i].Enable = false
        ui["pet_slot_highlight_" .. i].Enable = false
        ui["pet_slot_lock_" .. i].Visible = true
        ui["pet_slot_lock_" .. i].Hint = GetUTF8Text("UI_pet_close")
        ui["pet_slot_grade_" .. i].Skin = SkinF.skin_touming
        ui["pet_slot_fg_" .. i].Skin = SkinF.personalInfo_pet_013
        ui["pet_slot_equip_" .. i].BackgroundColor = col0
      else
        ui["pet_slot_btn_" .. i].Enable = true
        ui["pet_slot_highlight_" .. i].Enable = true
        ui["pet_slot_lock_" .. i].Visible = false
        ui["pet_slot_lock_" .. i].Hint = ""
        local current_pet_seq = i + (CurrentPlayerPetPage - 1) * 5
        if PlayerPetsData[current_pet_seq] then
          ui["pet_slot_grade_" .. i].Skin = SkinF.personalInfo_quality[PlayerPetsData[current_pet_seq].grade]
          ui["pet_slot_fg_" .. i].Skin = Gui.ControlSkin({
            BackgroundImage = Gui.Image(resDir .. PlayerPetsData[current_pet_seq].icon .. ".tga", Vector4(0, 0, 0, 0))
          })
          if PlayerPetsData[current_pet_seq].isEquipped == "Y" then
            ui["pet_slot_equip_" .. i].BackgroundColor = colw
          else
            ui["pet_slot_equip_" .. i].BackgroundColor = col0
          end
        else
          ui["pet_slot_grade_" .. i].Skin = SkinF.skin_touming
          ui["pet_slot_fg_" .. i].Skin = SkinF.personalInfo_pet_013
          ui["pet_slot_equip_" .. i].BackgroundColor = col0
        end
      end
    end
  else
    for i = 1, 5 do
      ui["pet_slot_grade_" .. i].Skin = SkinF.skin_touming
      ui["pet_slot_fg_" .. i].Skin = SkinF.personalInfo_pet_013
      ui["pet_slot_equip_" .. i].BackgroundColor = col0
    end
  end
  if SelectedPetSlot == nil then
    SelectedPetSlot = 1
  end
  if EquippedPetResource ~= old_EquippedPetResource or EquippedPetGrade ~= old_EquippedPetGrade then
    lg:SetEquipmentPetInfo(EquippedPetResource, EquippedPetGrade)
  end
  ChangePetSlotSelection(SelectedPetSlot)
  ui.coverControlpet.Parent = nil
end, true
local DealPlayerPetOpen, DealSysPetList = function(data)
  MessageBox.ShowError(GetUTF8Text("UI_pet_apellation_03"))
  DealPlayerPetList(data)
  if bit.band(256, ComFuc.leadList) == 256 then
    if NewLead.leadVisible then
      NewLead.HideLead()
    end
    ComFuc.SetOneLeadFinish(256)
  end
end, GetUTF8Text("button_common_Avatar_Card")
local DealSysPetList, DealPlayerPetBuy = function(data)
  CurrentSysPetPage = data.page
  TotalSysPetPage = data.pages
  ui.page_bar_sys_pet.CurrIndex = data.page
  ui.page_bar_sys_pet.PageCount = data.pages
  SysPetsData = data.pets
  FillPetInfoPage1()
end, GetUTF8Text("button_common_Avatar_Card")
local DealPlayerPetBuy, DealPlayerPetDel = function(data)
  gui:PlayAudio("pet_unpack")
  rpc_sys_pet_list(1)
  rpc_player_pet_list(CurrentPlayerPetPage)
end, GetUTF8Text("button_common_Avatar_Card")
local DealPlayerPetDel, DealPlayerPetRename = function(data)
  MessageBox.ShowError(GetUTF8Text("button_pet_clew_11"))
  rpc_sys_pet_list(1)
  rpc_player_pet_list(CurrentPlayerPetPage)
end, GetUTF8Text("button_common_Avatar_Card")
local DealPlayerPetRename, DealPlayerPetPlacate = function(data)
  rpc_player_pet_list(CurrentPlayerPetPage)
  MessageBox.ShowError(GetUTF8Text("UI_pet_apellation_02"))
end, GetUTF8Text("button_common_Avatar_Card")
local DealPlayerPetPlacate, DealPlayerPetFeed = function(data)
  rpc_player_pet_list(CurrentPlayerPetPage)
  MessageBox.ShowError(GetUTF8Text("UI_pet_apellation_01"))
end, GetUTF8Text("button_common_Avatar_Card")
local DealPlayerPetFeed, DealPlayerPetFight = function(data)
  rpc_player_pet_list(CurrentPlayerPetPage)
  ReinSuccess()
end, GetUTF8Text("button_common_Avatar_Card")
local DealPlayerPetFight, DealPlayerPetSkill = function(data)
  rpc_player_pet_list(CurrentPlayerPetPage)
  MessageBox.ShowError(GetUTF8Text("UI_pet_function_10"))
end, GetUTF8Text("button_common_Avatar_Card")
local DealPlayerPetSkill, DealPlayerPetSkillUpgrade = function(data)
  CurrentPetSkillData = data.skill
  if CurrentPetSkillData then
    ui.pet_info_skill_icon.Skin = Gui.ControlSkin({
      BackgroundImage = Gui.Image(resDir .. CurrentPetSkillData.resource .. ".tga", Vector4(0, 0, 0, 0))
    })
    ui.pet_info_skill_name.Text = " " .. GetUTF8Text(CurrentPetSkillData.displayName)
    ui.pet_info_skill_level.Size = Vector2(ComFuc.skillPointL[CurrentPetSkillData.level + 1], 31)
    currentPetSkillUpdatePrice = {}
    for i, v in ipairs(CurrentPetSkillData.nextLevel.price) do
      currentPetSkillUpdatePrice[v.currency] = v.price
    end
    if CurrentPetSkillData.isMaximum == "Y" then
      ui.pet_skill_upgrade_popup_msg.Text = GetUTF8Text("UI_inGame_pet_string_29")
      ui.pet_skill_upgrade_btn.Visible = false
      ui.pet_skill_upgrade_cancel_btn.Visible = true
    else
      ui.pet_skill_upgrade_btn.Visible = true
      ui.pet_skill_upgrade_cancel_btn.Visible = false
    end
  end
end, GetUTF8Text("button_common_Avatar_Card")
local DealPlayerPetSkillUpgrade, DealPlayerPetOPS = function(data)
  if SelectedPetSlot and PlayerPetsData and PlayerPetsData[SelectedPetSlot] then
    gui:PlayAudio("ability_point_lv" .. tostring(CurrentPetSkillData.level + 1))
    rpc_player_pet_skill(PlayerPetsData[SelectedPetSlot].id)
  end
end, GetUTF8Text("button_common_Avatar_Card")
local DealPlayerPetOPS, DealPlayerPetOpUpdate = function(data)
  CurrentPetOpConditions = data.sysPetCustomSkills
  CurrentPetOpSettings = {}
  for i, v in pairs(data.playerPetCustomSkills) do
    if data.playerPetCustomSkills[i].slot then
      CurrentPetOpSettings[data.playerPetCustomSkills[i].slot] = data.playerPetCustomSkills[i]
    end
  end
  for i = 1, 5 do
    if i > #CurrentPetOpSettings then
      EnablePetOpBar(i, false)
    else
      EnablePetOpBar(i, true)
      FillUpPetOpBar(i)
    end
  end
end, GetUTF8Text("button_common_Avatar_Card")
local DealPlayerPetOpUpdate, DealPlayerPetOpUpdateFailed = function(data)
  if SelectedPetSlot and PlayerPetsData and PlayerPetsData[SelectedPetSlot] then
    rpc_player_pet_custom_skill_list(PlayerPetsData[SelectedPetSlot].id)
  end
end, GetUTF8Text("button_common_Avatar_Card")
local DealPlayerPetOpUpdateFailed, DealPlayerPetSlotExpand = function(data)
  if SelectedPetSlot and PlayerPetsData and PlayerPetsData[SelectedPetSlot] then
    rpc_player_pet_custom_skill_list(PlayerPetsData[SelectedPetSlot].id)
  end
end, GetUTF8Text("button_common_Avatar_Card")
local DealPlayerPetSlotExpand, DealBattleForce = function(data)
  local jump_page = math.ceil(data.expandedSlot / 5)
  rpc_player_pet_list(jump_page)
  MessageBox.ShowError(GetUTF8Text("UI_common_consortia_leaguer_06"))
end, GetUTF8Text("button_common_Avatar_Card")

function DealBattleForce(data)
  ui.info_power.Text = data.pf + data.wf
  ui.info_adventure.Text = data.vf
  ComFuc.globalVF = data.vf
  ComFuc.info_table.weapon_force = data.bwf
  ui.pow_pf.Text = data.pf
  ui.pow_wf.Text = data.wf
  local tmpnum1, tmpnum2 = math.modf(data.ev + data.cv)
  if 0.5 < tmpnum2 then
    tmpnum1 = tmpnum1 + 1
  end
  ui.advent_pf.Text = tmpnum1
  tmpnum1, tmpnum2 = math.modf(data.pv)
  if 0.5 < tmpnum2 then
    tmpnum1 = tmpnum1 + 1
  end
  ui.advent_wf.Text = tmpnum1
  ui.label_tips_explore_hints.Visible = false
  ui.info_power_pet.Text = data.pf + data.wf
  ui.pow_pf_pet.Text = data.pf
  ui.pow_wf_pet.Text = data.wf
end

skillListData = {}
hotKeyListData = {}
bossSkllHelpData = {}
bossSkillListData = {}
local playerBossSkillListData, SetActiveSkillDragTip = {}, {}
local SetActiveSkillDragTip, DealSkillList = function()
  for i = 1, 5 do
    ui["skill_drag_tip_" .. i].Visible = false
  end
  if mainCurr == 3 then
    for i, v in ipairs(skillListData) do
      if v.isActive == "Y" then
        local k = 0
        for j, p in ipairs(hotKeyListData.slots) do
          if p.type == 1 and v.display == p.display then
            k = 1
            break
          end
        end
        ui["skill_drag_tip_" .. i].Visible = k == 0 and 0 < v.level
      end
    end
  end
end, GetUTF8Text("button_common_Avatar_Card")

function DealSkillList(data)
  ui.boss_skill.Parent = nil
  ui.profession_skill.Parent = ui.right_main_3
  ui.profession_skill_button_2.PushDown = true
  local professionSkill = 1
  local bossSkill = 1
  CleanSkillList()
  playerBossSkillListData = {}
  bossSkllHelpData = data.bossList
  SetSkillLeave(data.leftpoints)
  for i, v in ipairs(data.costMap) do
    skillCost[v.currency] = v.cost
  end
  ui.btn_skill_reset.Enable = data.leftpoints ~= math.floor((ComFuc.globalLV + 1) / 2)
  ComFuc.hasLeftPoint = data.leftpoints
  for i = 1, #data.skills do
    if data.skills[i].subType == 1 then
      skillListData[professionSkill] = data.skills[i]
      professionSkill = professionSkill + 1
    elseif data.skills[i].subType == 2 then
      playerBossSkillListData[bossSkill] = data.skills[i]
      bossSkill = bossSkill + 1
    end
  end
  local active_skill_index = 1
  for i, v in ipairs(skillListData) do
    sklDt[i] = v
    skillTemLevel[i] = v.level
    if 5 < i then
      break
    end
    if data.leftpoints > 0 then
      ui["skill_add_" .. i].Enable = true
    end
    if v.isActive == "Y" then
      ui["skill_name_" .. i].Text = GetUTF8Text(v.display) .. "(" .. GetUTF8Text("UI_common_Active") .. ")"
      if v.level > 0 then
        active_skill_index = active_skill_index + 1
      end
    elseif v.isActive == "N" then
      ui["skill_name_" .. i].Text = GetUTF8Text(v.display) .. "(" .. GetUTF8Text("UI_common_Passive") .. ")"
    end
    ui["skill_size_v_" .. i].Size = Vector2(0, 0)
    ui["skill_size_" .. i].Size = Vector2(ComFuc.skillPointL[v.level + 1], 31)
    ui["skill_b_" .. i].Skin = Gui.ButtonSkin({
      BackgroundImage = Gui.Image(resDir .. v.resource .. ".tga", Vector4(0, 0, 0, 0)),
      DisabledImage = Gui.Image(resDir .. v.resource .. "_disabled" .. ".tga", Vector4(0, 0, 0, 0))
    })
    if v.level <= 0 then
      ui["skill_b_" .. i].Enable = false
      ui["skill_c2_" .. i].Visible = true
    else
      ui["skill_b_" .. i].Enable = true
      ui["skill_c2_" .. i].Visible = false
      if v.level >= 5 then
        ui["skill_add_" .. i].Enable = false
      end
    end
  end
  rpc_slot_get()
end

local i = 1
FORCE_LEAD_EASYUSE_TAG = i
i = i + 1
FORCE_LEAD_EASYUSE_TABLE = i
i = i + 1
FORCE_LEAD_EASYUSE_PLACE = i

function ForceLeadEasyUse(step)
  if bit.band(2, ComFuc.leadList) ~= 2 then
    return
  end
  if step == FORCE_LEAD_EASYUSE_TAG then
    NewLead.ShowNewLeadHasLock(Vector2(720, 272), Vector2(136, 35), GetUTF8Text("UI_common_Click"), 0)
  elseif step == FORCE_LEAD_EASYUSE_TABLE then
    NewLead.ShowNewLeadHasLock(Vector2(602, 314), Vector2(510, 332), GetUTF8Text("UI_common_Task_guide_04"), 0, false, 40)
  elseif step == FORCE_LEAD_EASYUSE_PLACE then
    NewLead.ShowNewLeadHasLock(Vector2(64, 736), Vector2(1064, 96), GetUTF8Text("UI_common_Task_guide_05"), 0)
  end
end

i = 1
FORCE_LEAD_SKILLLEARN_TAG = i
i = i + 1
FORCE_LEAD_SKILLLEARN_SKILL_INFO = i
i = i + 1
FORCE_LEAD_SKILLLEARN_SKILL_ADD = i
i = i + 1
FORCE_LEAD_SKILLLEARN_SKILL_FINISH = i
i = i + 1
FORCE_LEAD_SKILLLEARN_PICK = i
i = i + 1
FORCE_LEAD_SKILLLEARN_PLACE = i
i = i + 1
FORCE_LEAD_SKILLLEARN_PLACED = i
local lead_skill_learn_current

function ForceLeadSkillLearn(step)
  if bit.band(4, ComFuc.leadList) ~= 4 then
    return
  end
  if step == FORCE_LEAD_SKILLLEARN_TAG then
    local l = PersonalInfo.ui.btn_main_3.Location
    l = l + Vector2(25, 155)
    local s = PersonalInfo.ui.btn_main_3.Size
    NewLead.ShowNewLeadHasLock(l, s, GetUTF8Text("UI_common_Click"), 0)
  elseif step == FORCE_LEAD_SKILLLEARN_SKILL_INFO then
    if lead_skill_learn_current ~= FORCE_LEAD_SKILLLEARN_TAG then
      return
    end
    local l = ui.profession_skill.Location
    l = l + Vector2(565, 250)
    NewLead.ShowNewLeadHasLock(l, ui.profession_skill.Size - Vector2(500, 90), GetUTF8Text("UI_common_Task_guide_06"), 0, false, 50)
  elseif step == FORCE_LEAD_SKILLLEARN_SKILL_ADD then
    if lead_skill_learn_current ~= FORCE_LEAD_SKILLLEARN_SKILL_INFO then
      return
    end
    local l = ui.profession_skill.Location
    l = l + Vector2(560, 250)
    NewLead.ShowNewLeadHasLock(l, ui.profession_skill.Size - Vector2(0, 30), GetUTF8Text("UI_common_Task_guide_07"), 0, false, 540)
  elseif step == FORCE_LEAD_SKILLLEARN_SKILL_FINISH then
    if lead_skill_learn_current ~= FORCE_LEAD_SKILLLEARN_SKILL_ADD then
      return
    end
    local l = ui.profession_skill.Location
    l = l + Vector2(560, 250)
    NewLead.ShowNewLeadHasLock(l, ui.profession_skill.Size - Vector2(0, 30), GetUTF8Text("UI_common_Task_guide_08"), 1, false, 540)
  elseif step == FORCE_LEAD_SKILLLEARN_PICK then
    if lead_skill_learn_current ~= FORCE_LEAD_SKILLLEARN_SKILL_FINISH and lead_skill_learn_current ~= FORCE_LEAD_SKILLLEARN_PLACE then
      return
    end
    local l = ui.profession_skill.Location
    l = l + Vector2(560, 220)
    NewLead.ShowNewLeadHasLock(l, ui.profession_skill.Size, GetUTF8Text("UI_common_Task_guide_09"), 3, false)
  elseif step == FORCE_LEAD_SKILLLEARN_PLACE then
    if lead_skill_learn_current ~= FORCE_LEAD_SKILLLEARN_PICK then
      return
    end
    NewLead.ShowNewLeadHasLock(Vector2(64, 736), Vector2(1064, 96), GetUTF8Text("UI_common_Task_guide_10"), 0)
  elseif step == FORCE_LEAD_SKILLLEARN_PLACED then
    Lobby.ForceLeadGotoStartGame()
    ComFuc.SetOneLeadFinish(4)
  end
  lead_skill_learn_current = step
end

i = 1
FORCE_LEAD_SHOP_SEE = i
i = i + 1
FORCE_LEAD_SHOP_PLACE = i
local ForceLeadShopCheck, DealSkillListLead = function(step)
  if bit.band(512, ComFuc.leadList) == 512 then
    return
  end
  if bit.band(1024, ComFuc.leadList) ~= 1024 then
    return
  end
  if step == FORCE_LEAD_SHOP_SEE then
    NewLead.ShowNewLeadHasLock(Vector2(602, 314), Vector2(510, 332), GetUTF8Text("UI_common_Task_guide_15"), 0)
  elseif step == FORCE_LEAD_SHOP_PLACE then
    NewLead.ShowNewLeadHasLock(Vector2(64, 736), Vector2(1064, 96), GetUTF8Text("UI_common_Task_guide_16"), 0, false, 90)
  end
end, function(step)
  if bit.band(512, ComFuc.leadList) == 512 then
    return
  end
  if bit.band(1024, ComFuc.leadList) ~= 1024 then
    return
  end
  if step == FORCE_LEAD_SHOP_SEE then
    NewLead.ShowNewLeadHasLock(Vector2(602, 314), Vector2(510, 332), GetUTF8Text("UI_common_Task_guide_15"), 0)
  elseif step == FORCE_LEAD_SHOP_PLACE then
    NewLead.ShowNewLeadHasLock(Vector2(64, 736), Vector2(1064, 96), GetUTF8Text("UI_common_Task_guide_16"), 0, false, 90)
  end
end
local DealSkillListLead, DealHotKeyList = function(data)
  DealSkillList(data)
  ForceLeadSkillLearn(FORCE_LEAD_SKILLLEARN_PICK)
end, GetUTF8Text("button_common_Avatar_Card")

function DealHotKeyList(data)
  hotKeyListData = data
  CleanHotKyeList()
  for i, v in ipairs(data.slots) do
    if v.type ~= 0 then
      htkDt[v.slot] = v
      ShowOneButton(ui["hot_key_p_" .. v.slot], ui["hot_key_b_" .. v.slot], resDir, v.resource, v.grade, v, ui["hot_key_bs_" .. v.slot])
      ShowQuaity("hot_key_l2_", v.slot, v.quantity)
      ComFuc.ShowUpgradeLevel(v, v.type, ui["hot_key_level_" .. v.slot], ui["hot_key_level_text_" .. v.slot])
      ShowOneButton(ui["pet_op_hotkey_p_" .. v.slot], ui["pet_op_hotkey_b_" .. v.slot], resDir, v.resource, v.grade, v, ui["pet_op_hotkey_bs_" .. v.slot])
      ShowQuaity("pet_op_hotkey_l2_", v.slot, v.quantity)
      if v.type == 2 then
        ComFuc.hasWeaponCount = ComFuc.hasWeaponCount + 1
        if v.unitType and v.unit and v.unitType == 2 and 0 >= v.unit then
          ComFuc.hasWeaponNoTime = ComFuc.hasWeaponNoTime + 1
        end
      end
    end
  end
  if ui.profession_skill.Parent then
    SetActiveSkillDragTip()
  elseif ui.boss_skill.Parent then
    SetActiveBossSkillDragTip()
  end
end

local Rennew_DownEvent, DealDepotList = function()
  rpc_storage_storage_list(ui.pb_depot.CurrIndex)
end, function()
  rpc_storage_storage_list(ui.pb_depot.CurrIndex)
end
local DealDepotList, DealHandPoseList = function(data)
  local box_tbl = {}
  if not isDoEquip and depotCurr == 4 or depotCurr ~= 4 then
    ComFuc.CleanDepotTap(ui, PersonalInfo, depotCurr)
  end
  if depotCurr > 0 and depotCurr <= 3 and 0 < data.page then
    for i = 1, 24 do
      ui["weapon_renew_one_" .. i].Visible = false
    end
  elseif depotCurr == 4 and 0 < data.page then
    for i = 1, 10 do
      ui["person_renew_one_" .. i].Visible = false
    end
  end
  ui.pb_depot.CurrIndex = data.page
  ui.pb_depot.PageCount = data.pages
  for i, v in ipairs(data.items) do
    dptDt[v.slot] = v
    if depotCurr == 1 or depotCurr == 2 or depotCurr == 3 then
      local resname = ComFuc.DoWingRes(v.resource, v.subtype, 102, depotCurr)
      if v.remain and 0 > v.remain and v.isRenew then
        ui["weapon_renew_one_" .. v.slot].Visible = true
        ui["weapon_renew_one_" .. v.slot].EventClick = function(sender, e)
          rpc.safecall("get_renew_item", {
            pid = v.pid,
            t = 2
          }, function(data)
            ShopBalance.list = {}
            ShopBalance.list[1] = data.itemList[1]
            if #ShopBalance.list == 0 then
              MessageBox.ShowError(GetUTF8Text("msgbox_lobby_renew_single"), 3, true)
            else
              ShopBalance.Show("Renew_type")
            end
          end)
        end
      end
      ShowOneButton(ui["weapon_p_" .. v.slot], ui["weapon_b_" .. v.slot], resDir, resname, v.grade, v, ui["weapon_bs_" .. v.slot], ui["weapon_locked_" .. v.slot])
      ShowQuaity("weapon_l_", v.slot, v.quantity, false)
      ShowIsEquiped(v, "weapon", depotCurr)
      ComFuc.ShowUpgradeLevel(v, depotCurr + 1, ui["weapon_level_" .. v.slot], ui["weapon_level_text_" .. v.slot])
      if depotCurr == 2 and v.subtype == 400 then
        if box_tbl[v.category] == nil then
          box_tbl[v.category] = {
            boxNumber = v.unit,
            boxRes = v.resource
          }
        elseif box_tbl[v.category].boxNumber then
          box_tbl[v.category].boxNumber = box_tbl[v.category].boxNumber + v.unit
        else
          box_tbl[v.category].boxNumber = v.unit
        end
      elseif depotCurr == 2 and v.subtype == 401 then
        if box_tbl[v.category] == nil then
          box_tbl[v.category] = {
            keyNumber = v.unit
          }
        elseif box_tbl[v.category].keyNumber then
          box_tbl[v.category].keyNumber = box_tbl[v.category].keyNumber + v.unit
        else
          box_tbl[v.category].keyNumber = v.unit
        end
      end
    elseif depotCurr == 4 and 10 >= v.slot then
      ui["person_card_p_" .. v.slot].Skin = SkinF.personalInfo_quality[v.grade]
      ShowIsEquiped(v, "person_card", 4)
      AvtarStype[v.slot] = v.subType
      if v.subType == 1 then
        ui["person_card_b_" .. v.slot].Skin = SkinF.personalInfo_143
        ui["person_card_level_" .. v.slot].Skin = SkinF.avatar_level
      elseif v.subType == 2 then
        ui["person_card_b_" .. v.slot].Skin = SkinF.personalInfo_261
        ui["person_card_level_" .. v.slot].Skin = SkinF.avatar_level_hero
      end
      if v.remain and 0 > v.remain and v.isRenew then
        ui["person_renew_one_" .. v.slot].Visible = true
        ui["person_renew_one_" .. v.slot].EventClick = function(sender, e)
          rpc.safecall("get_renew_item", {
            pid = v.pid,
            t = 5
          }, function(data)
            ShopBalance.list = {}
            ShopBalance.list[1] = data.avatarList[1]
            if #ShopBalance.list == 0 then
              MessageBox.ShowError(GetUTF8Text("msgbox_lobby_renew_single"), 3, true)
            else
              ShopBalance.Show("Renew_type")
            end
          end)
        end
      end
      if not isDoEquip then
        ComFuc.SetPersonCardData(v.avatar, ComFuc.CardId(v.slot), v.position)
        ui["person_card_b_" .. v.slot].Visible = true
        ui["person_card_bs_" .. v.slot].Visible = v.unitType == 2 and v.unit <= 20
      end
      ShowOneButton(nil, nil, nil, nil, v.grade, v, nil, ui["person_card_locked_" .. v.slot])
      ComFuc.ShowUpgradeLevel(v, depotCurr + 1, ui["person_card_level_" .. v.slot], ui["person_card_level_text_" .. v.slot])
    end
  end
  OpenBox.SetBoxTbl(box_tbl)
  isDoEquip = false
end, GetUTF8Text("button_common_Avatar_Card")
local DealHandPoseList, DealReinPersonList = function(data)
  ComFuc.ClearEquipButton(ui, 7, 12)
  for i, v in ipairs(data.items) do
    posDt[v.slot] = v
    local tS = v.slot + 6
    ShowOneButton(ui["equip_p_" .. tS], ui["equip_b_" .. tS], resDir, v.resource)
    if not v.resource or v.resource == "" or v.resource == "null" then
      ui["equip_b_" .. tS].Skin = SkinF.skin_touming2
    end
  end
end, GetUTF8Text("button_common_Avatar_Card")
local DealReinPersonList, DealReinStoneList = function(data)
  dptDt2 = {}
  ComFuc.HideCardBtn(ui, "reinPerson", 5)
  ui.pb_reinPerson.CurrIndex = data.page
  ui.pb_reinPerson.PageCount = data.pages
  for i, v in ipairs(data.items) do
    dptDt2[i] = v
    AvtarStype[i] = v.subType
    ui["reinPerson_card_b_" .. i].Visible = true
    if v and v.unitType and v.unit and v.unitType == 2 and v.unit <= 20 then
      ui["reinPerson_card_bs_" .. v.slot].Visible = true
    end
    ui["reinPerson_card_p_" .. i].Skin = SkinF.personalInfo_quality[v.grade]
    ComFuc.SetPersonCardData(v.avatar, i, v.position)
    if menDt.pid == v.pid then
      ui["reinPerson_card_b_" .. i].BackgroundColor = colh
      ui["reinPerson_card_p_" .. i].BackgroundColor = colh
    else
      ui["reinPerson_card_b_" .. i].BackgroundColor = colw
      ui["reinPerson_card_p_" .. i].BackgroundColor = colw
    end
    ComFuc.ShowUpgradeLevel(v, 5, ui["reinPerson_card_level_" .. i], ui["reinPerson_card_level_text_" .. i])
    if v.subType == 1 then
      ui["reinPerson_card_b_" .. i].Skin = SkinF.personalInfo_143
      ui["reinPerson_card_level_" .. i].Skin = SkinF.avatar_level
    elseif v.subType == 2 then
      ui["reinPerson_card_b_" .. i].Skin = SkinF.personalInfo_261
      ui["reinPerson_card_level_" .. i].Skin = SkinF.avatar_level_hero
    end
  end
end, GetUTF8Text("button_common_Avatar_Card")
local DealReinStoneList, DealReinMedalList = function(data)
  dptDt = {}
  ComFuc.HideDepotBtn(ui, "reinStone", 12)
  ui.pb_reinStone.CurrIndex = data.page
  ui.pb_reinStone.PageCount = data.pages
  for i, v in ipairs(data.items) do
    dptDt[i] = v
    local p = ui.pb_reinStone.CurrIndex
    if tableDepot["T" .. p .. i] then
      dptDt[i].quantity = dptDt[i].quantity - tableDepot["T" .. p .. i]
    end
    ShowOneButton(ui["reinStone_p_" .. i], ui["reinStone_b_" .. i], resDir, v.resource, v.grade, v, ui["reinStone_bs_" .. i])
    ShowQuaity("reinStone_l_", i, dptDt[i].quantity, true)
    if dptDt[i].quantity == 0 then
      ui["reinStone_b_" .. i].BackgroundColor = colh
      ui["reinStone_p_" .. i].BackgroundColor = colh
    else
      ui["reinStone_b_" .. i].BackgroundColor = colw
      ui["reinStone_p_" .. i].BackgroundColor = colw
    end
  end
end, GetUTF8Text("button_common_Avatar_Card")
local DealReinMedalList, DealReinWeaponList = function(data)
  dptDt = {}
  ComFuc.HideDepotBtn(ui, "reinMedal", 36)
  ui.pb_reinMedal.CurrIndex = data.page
  ui.pb_reinMedal.PageCount = data.pages
  for i, v in ipairs(data.items) do
    dptDt[i] = v
    local p = ui.pb_reinMedal.CurrIndex
    if tableDepot["T" .. p .. i] then
      dptDt[i].quantity = dptDt[i].quantity - tableDepot["T" .. p .. i]
    end
    ShowOneButton(ui["reinMedal_p_" .. i], ui["reinMedal_b_" .. i], resDir, v.resource, v.grade, v, ui["reinMedal_bs_" .. i])
    ShowQuaity("reinMedal_l_", i, dptDt[i].quantity, true)
  end
end, GetUTF8Text("button_common_Avatar_Card")
local DealReinWeaponList, CleanReinMaterial = function(data)
  dptDt = {}
  ComFuc.HideDepotBtn(ui, "reinWeapon", 12, SkinF.skin_touming)
  ui.pb_reinWeapon.CurrIndex = data.page
  ui.pb_reinWeapon.PageCount = data.pages
  for i, v in ipairs(data.items) do
    dptDt[i] = v
    ShowOneButton(ui["reinWeapon_p_" .. i], ui["reinWeapon_b_" .. i], resDir, v.resource, v.grade, v, ui["reinWeapon_bs_" .. i])
    ComFuc.ShowUpgradeLevel(v, 2, ui["reinWeapon_level_" .. i], ui["reinWeapon_level_text_" .. i])
    if menDt.pid == v.pid then
      ui["reinWeapon_p_" .. i].BackgroundColor = colh
      ui["reinWeapon_b_" .. i].BackgroundColor = colh
    else
      ui["reinWeapon_p_" .. i].BackgroundColor = colw
      ui["reinWeapon_b_" .. i].BackgroundColor = colw
    end
  end
end, GetUTF8Text("button_common_Avatar_Card")
local CleanReinMaterial, DealReinMaterialList = function(p)
  dptDt2 = {}
  ComFuc.HideDepotBtn(ui, "reinMaterial", 12, SkinF.skin_touming)
  if p then
    ui.pb_reinMaterial.PageCount = 0
  end
end, GetUTF8Text("button_common_Avatar_Card")
local DealReinMaterialList, DealHangWeaponList = function(data)
  dptDt2 = {}
  ComFuc.HideDepotBtn(ui, "reinMaterial", 12, SkinF.skin_touming)
  ui.pb_reinMaterial.CurrIndex = data.page
  ui.pb_reinMaterial.PageCount = data.pages
  for i, v in ipairs(data.items) do
    dptDt2[i] = v
    ShowOneButton(ui["reinMaterial_p_" .. i], ui["reinMaterial_b_" .. i], resDir, v.resource, v.grade, v, ui["reinMaterial_bs_" .. i], ui["reinMaterial_locked_" .. i])
    ComFuc.ShowUpgradeLevel(v, 2, ui["reinMaterial_level_" .. i], ui["reinMaterial_level_text_" .. i])
  end
  ui.coverControlNew.Parent = nil
end, GetUTF8Text("button_common_Avatar_Card")

function DealHangWeaponList(data)
  dptDt = {}
  ComFuc.HideDepotBtn(ui, "hangWeapon", 20, SkinF.skin_touming)
  ui.pb_hangWeapon.CurrIndex = data.page
  ui.pb_hangWeapon.PageCount = data.pages
  for i, v in ipairs(data.items) do
    dptDt[i] = v
    ShowOneButton(ui["hangWeapon_p_" .. i], ui["hangWeapon_b_" .. i], resDir, v.resource, v.grade, v, ui["hangWeapon_bs_" .. i])
    ComFuc.ShowUpgradeLevel(v, 2, ui["hangWeapon_level_" .. i], ui["hangWeapon_level_text_" .. i])
    if menDt.pid == v.pid then
      ui["hangWeapon_p_" .. i].BackgroundColor = colh
      ui["hangWeapon_b_" .. i].BackgroundColor = colh
    else
      ui["hangWeapon_p_" .. i].BackgroundColor = colw
      ui["hangWeapon_b_" .. i].BackgroundColor = colw
    end
  end
end

local SlotList, DealCardSlotList = {}, {}
local DealCardSlotList, ResetRemoveStoneButton = function(data)
  insCost = data.price
  ui.insert_life.Text = "+0"
  ui.insert_add.Text = "+0"
  ui.insert_protect.Text = "+0"
  ui.insert_recover.Text = "+0"
  SlotList = data.slots
  for i, v in ipairs(data.slots) do
    insDt[i] = v
    slotRenforceBf[i] = v.pluses
    ui["insert_l_" .. i].Visible = v.isEnable ~= "Y"
    if v.isEnable == "Y" then
      ui["insert_kb_" .. i].Visible = false
      ui["insert_p_" .. i].BackgroundColor = col0
      ui["insert_pd_" .. i].Text = GetUTF8Text("tips_store_Gem_lottery")
      ui["insert_p_" .. i].Hint = GetUTF8Text("tips_lobby_Common_Desc15")
    end
    if tonumber(v.itemId) ~= 0 then
      slotRenforceId[i] = v.itemId
      ui["insert_c2_" .. i].Visible = true
      ui["insert_pd_" .. i].BackgroundColor = colw
      ShowOneButton(ui["insert_pd_" .. i], ui["insert_b_" .. i], resDir, v.resource, v.grade or 1)
      ui["insert_c2_" .. i].EventMouseEnter = function(sender, e)
        Tip.SetRpc(tip_sys_interface[3], {
          t = 3,
          sid = v.sid
        })
        Tip.SetUseDescription(false)
        Tip.SetOwner(sender)
      end
      ComputeInsertP(v.pluses.stamina, ui.insert_life)
      ComputeInsertP(v.pluses.cureQuantity, ui.insert_add)
      ComputeInsertP(v.pluses.armor, ui.insert_protect)
      ComputeInsertP(v.pluses.recovery, ui.insert_recover)
    end
  end
  for i = 1, 5 do
    if data.slots[i].isEnable == "Y" and 0 < data.slots[i].grade then
      ui["remove_stone_btn_" .. i].Visible = true
    end
  end
end, GetUTF8Text("button_common_Avatar_Card")
local ResetRemoveStoneButton, DealItemCount = function()
  for i = 1, 5 do
    ui["remove_stone_btn_" .. i].Visible = false
  end
end, GetUTF8Text("button_common_Avatar_Card")
local DealItemCount, DealOpenSlotCreate = function(data)
  if reinforceCurr == 1 then
    ui.coverControl2.Parent = gui
    ui.insertTip.Parent = gui
    Gui.Align(ui.insertTip, 0.5, 0.5)
    if 1 <= data.count then
      ui.insertTip_sure.Enable = true
    else
      ui.insertTip_sure.Enable = false
    end
  else
    SetMixCount(data.count, nil, math.min(5, data.count))
    if data.count >= 5 then
      if menDt.grade == 1 then
        gui:PlayAudio("gem_spread")
      else
        gui:PlayAudio("gem_spread_2")
      end
    else
      gui:PlayAudio("gem_put")
    end
  end
end, GetUTF8Text("button_common_Avatar_Card")
local DealOpenSlotCreate, DealCombineMixInfo = function(data)
  if data.isSuccess == "Y" then
    gui:PlayAudio("slottingsuccessful")
    ReinSuccess()
    ui["insert_kb_" .. openSlotCurr].Visible = false
    ui["insert_p_" .. openSlotCurr].BackgroundColor = col0
    ui["insert_pd_" .. openSlotCurr].Text = GetUTF8Text("tips_store_Gem_lottery")
    menDt.grade = menDt.grade + 1
    ui.insert_card_p.Skin = SkinF.personalInfo_quality[menDt.grade]
    rpc_storage_storage_list_no_empty(ui.pb_reinPerson.CurrIndex)
  elseif data.isSuccess == "N" then
    gui:PlayAudio("slottingfailed")
    ReinFail()
  end
end, GetUTF8Text("button_common_Avatar_Card")
local DealCombineMixInfo, DealPropMix = function(data)
  ui.combMix_cost.Text = data.price .. "  "
  SetMixCount(nil, data.count)
end, GetUTF8Text("button_common_Avatar_Card")
local DealPropMix, DealRefitNeed = function(data)
  if not data.successFlag or data.successFlag == "false" then
    ReinFail()
  else
    ReinSuccess()
    ShowOneButton(ui.moveMix, ui.moveMix.BriefControl, resDir, data.resource, data.grade)
    ui.moveMix.Parent = ui.ctrl_reinforce_2
    ui.moveMix.Size = Vector2(100, 100)
    ui.moveMix.IsBegin = true
    ui.moveMix.IsFirst = true
    ui.moveMix.Location = Vector2(180, 180)
    ui.moveMix.EndSize = Vector2(40, 40)
    ui.moveMix.EndLocation = Vector2(788, 118)
    ui.moveMix.HB = 2
    ui.moveMix.TopCenterY = 50
    ui.moveMix.T1 = 0.5
  end
  if not data.error or data.error == "" then
    SetMixCount(mixHas - mixNeed, nil, math.min(5, mixHas - mixNeed))
  end
end, GetUTF8Text("button_common_Avatar_Card")
local DealRefitNeed, DealRefitWeaponOK = function(data)
  if isOpenRefitWeaponSound then
    isOpenRefitWeaponSound = false
    gui:PlayAudio("weapon_put")
  end
  CleanReinforce()
  ui.refit_opTip.Visible = false
  ui.equip_pd_13.BackgroundColor = colw
  ShowOneButton(ui.equip_pd_13, ui.equip_b_13, resDir, menDt.resource, menDt.grade)
  refitDt = data
  local dt = {}
  dt.refitLevel = data.currentLevel
  ComFuc.ShowUpgradeLevel(dt, 2, ui.equip_level_13, ui.equip_level_text_13)
  refitLevEnd = data.currentLevel
  refitLevBeg = math.min(11, math.max(1, math.floor((refitLevEnd - 0.1) / 5) * 5 + 1))
  for i = 1, 20 do
    ui["refit_lev_" .. i].Visible = i <= data.currentLevel
  end
  AddRefitPt(data.currentLevel)
  if refitMoveDir == 0 then
    for i = 1, 4 do
      if (refitLevBeg - 1) / 5 + 1 == i then
        ui["refit_lev_content_" .. i].Location = Vector2(0, 0)
      elseif (refitLevBeg - 1) / 5 + 1 == i - 1 then
        ui["refit_lev_content_" .. i].Location = Vector2(249, 0)
      else
        ui["refit_lev_content_" .. i].Location = Vector2(478, 0)
      end
    end
  end
  canUpGrade = data.currentLevel < data.maxLevel
  if data.currentLevel < data.maxLevel then
    isEnough = true
    ui.coverControl3.Parent = nil
    ui.refit_cost.Text = data.plusGP .. "  "
    for i, v in ipairs(data.list) do
      ShowRefitTiao(i, v.resource, v.ownNum, v.needNum, GetUTF8Text(v.displayName), v.itemId, v.grade)
    end
    ShowRefitTiao(3, data.fixReelResource, data.ownFixReelNum, data.fixReelNum, nil, data.fixReelId, data.fixReelGrade)
    ShowRefitTiao(4, data.heirloomResource, data.ownHeirloomNum, data.heirloomNum, nil, data.heirloomId, data.heirloomGrade)
    ui.useLucyReel.Enable = data.ownFixReelNum and data.ownFixReelNum >= data.fixReelNum
    if not ui.useLucyReel.Enable then
      ui.useLucyReel.Check = false
    end
    ui.useInheritAtri.Enable = data.ownHeirloomNum and data.ownHeirloomNum >= data.heirloomNum
    if not ui.useInheritAtri.Enable or not ui.tiao_4.Visible then
      ui.useInheritAtri.Check = false
    end
    ComputeWeaponEnhanceBar()
    refitWeaponGrades = ""
    local arr = {
      1,
      10,
      100,
      1000,
      10000,
      100000
    }
    for i = 6, 1, -1 do
      if math.floor(data.grades / arr[i]) == 1 then
        data.grades = data.grades - arr[i]
        refitWeaponGrades = refitWeaponGrades .. tostring(i) .. ","
      end
    end
    rpc_storage_item_filter(2, ui.pb_reinMaterial.CurrIndex)
  else
    dptDt2 = {}
    ComFuc.HideDepotBtn(ui, "reinMaterial", 12, SkinF.skin_touming)
    ui.pb_reinMaterial.CurrIndex = 1
    ui.pb_reinMaterial.PageCount = 1
    ui.refit_opTip_2.Visible = true
    ui.coverControlNew.Parent = nil
  end
  rpc_storage_item_filter(1, ui.pb_reinWeapon.CurrIndex)
  if NewLead.leadVisible then
    NewLead.HideLead()
  end
  ui.equip_c_14.Visible = ui.equip_b_13.Skin ~= SkinF.skin_touming2 and ui.equip_b_14.Skin == SkinF.skin_touming2
  ui.Tips_To_DragMetrailWeapon.Visible = ui.equip_b_13.Skin ~= SkinF.skin_touming2 and ui.equip_b_14.Skin == SkinF.skin_touming2
end, GetUTF8Text("button_common_Avatar_Card")
local DealRefitWeaponOK, ComputeBar = function(data)
  if data.result then
    retitState = data.result
    TimerRemove()
    timer = game.TimerMgr:AddTimer(0.05)
    timer.EventOnTimer = TimerRefresh4
  end
end, GetUTF8Text("button_common_Avatar_Card")

function ComputeBar(type, value, total)
  local preSpeed = hangDt.xFireSpeed
  local preSpread = hangDt.xShootSpread
  if type == "addition_xShootSpread" then
    value = (2 - preSpread) / 1.99 * 100 * value / preSpread
    total = (2 - preSpread) / 1.99 * 100 * total / preSpread
  elseif type == "addition_xFireSpeed" then
    value = (2 - preSpeed) / 1.9 * 100 * value / preSpeed
    total = (2 - preSpeed) / 1.9 * 100 * total / preSpeed
  elseif type == "addition_xAttackSpeed" then
    value = (5 - preSpeed) / 4.9 * 100 * value / preSpeed
    total = (5 - preSpeed) / 4.9 * 100 * total / preSpeed
  elseif type == "addition_xCriticalRate" then
    value = value * 100
    return string.format(" +%.2f", value) .. "%", value / (total * 100)
  elseif type == "addition_xCoolDown" then
    return string.format(" -%.2f", value), value / total
  end
  if menDt.subtype == 4 and type == "addition_xOutPut" then
    value = value * 8
    total = total * 8
  end
  return string.format(" +%.2f", value), value / total
end

local deta, ComputeRollLocation = 0, GetUTF8Text("button_common_Avatar_Card")
local ComputeRollLocation, DealAdditionMaterial = function(ts)
  local tk = 1 - ts
  if ts == 0 or 1 <= ts then
    deta = 0
    for i = 1, HangProHas do
      ui["hang_por_" .. i].Location = Vector2(0, 36 + (i - HangProNth) * 54)
    end
    if HangProNth == 1 then
      ui["hang_por_" .. HangProHas].Location = Vector2(0, -18)
    elseif HangProNth == HangProHas then
      ui.hang_por_1.Location = Vector2(0, 90)
    end
    for i = HangProHas, 1, -1 do
      local ly = ui["hang_por_" .. i].Location.y
      if 126 < ly then
        ly = ui["hang_por_" .. tostring(i % HangProHas + 1)].Location.y - 54
      end
      ui["hang_por_" .. i].Location = Vector2(0, ly)
    end
  else
    for i = HangProHas, 1, -1 do
      local td = 27
      local ly = ui["hang_por_" .. i].Location.y + tk * 40 + td
      if 126 < ly then
        ly = ui["hang_por_" .. tostring(i % HangProHas + 1)].Location.y - 54
        if i == HangProHas then
          ly = ly + tk * 40 + td
        end
      end
      ui["hang_por_" .. i].Location = Vector2(0, ly)
    end
  end
end, GetUTF8Text("button_common_Avatar_Card")
local DealAdditionMaterial, DealWeaponAddProOK = function(data)
  if isOpenRefitWeaponSound then
    isOpenRefitWeaponSound = false
    gui:PlayAudio("weapon_put")
  end
  if isHangFirst then
    CleanHang()
    ui.hang_opTip_p.Visible = false
    ui.equip_pd_15.BackgroundColor = colw
    ShowOneButton(ui.equip_pd_15, ui.equip_b_15, resDir, menDt.resource, menDt.grade)
    ui.btn_combHang.Enable = true
    isEnough = true
    ui.coverControl3.Parent = nil
  end
  hangMentDt = menDt
  ui.hang_cost.Text = data.costGP .. "  "
  ShowRefitTiao(5, data.propertyLock.resource, data.ownPropertyLockNum, data.propertyLock.num, nil, data.propertyLock.id, data.propertyLock.grade)
  for i, v in ipairs(data.materials) do
    ShowRefitTiao(i + 5, v.resource, v.ownNum, v.needNum, GetUTF8Text(v.displayName), v.itemId, v.grade)
  end
  if isHangFirst then
    hangDt = data
    local isHasPro = hangDt.additionMap and hangDt.additionMap[1]
    ui.hang_value.Visible = isHasPro
    ui.hang_por_parent.Visible = isHasPro
    ui.usePropertyLock.Enable = hangDt.ownPropertyLockNum and hangDt.ownPropertyLockNum >= hangDt.propertyLock.num and isHasPro
    if not ui.usePropertyLock.Enable then
      ui.usePropertyLock.Check = false
    end
    local SkinPro = {
      addition_xCriticalRate = SkinF.personalInfo_251[1],
      addition_xAmmoOneClip = SkinF.personalInfo_251[2],
      addition_xShootSpread = SkinF.personalInfo_251[3],
      addition_xOutPut = SkinF.personalInfo_251[4],
      addition_xFireSpeed = SkinF.personalInfo_251[5],
      addition_xCoolDown = SkinF.personalInfo_251[6],
      addition_xDamageRadius = SkinF.personalInfo_251[7],
      addition_xDistance = SkinF.personalInfo_251[8],
      addition_xAttackSpeed = SkinF.personalInfo_251[9]
    }
    HangProHas = #hangDt.properties
    for i = 1, 9 do
      ui["hang_por_" .. i].Visible = false
      if i <= HangProHas then
        if menDt.subtype == 6 or menDt.subtype == 13 then
          if hangDt.properties[i].displayName == "addition_xFireSpeed" then
            hangDt.properties[i].displayName = "addition_xAttackSpeed"
          end
          if isHasPro and isHasPro.name == "addition_xFireSpeed" then
            isHasPro.name = "addition_xAttackSpeed"
          end
        end
        if menDt.subtype == 11 or menDt.subtype == 12 or menDt.subtype == 14 then
          if hangDt.properties[i].displayName == "addition_xDistance" then
            hangDt.properties[i].displayName = "addition_xDamageRadius"
          end
          if isHasPro and isHasPro.name == "addition_xDistance" then
            isHasPro.name = "addition_xDamageRadius"
          end
        end
        local t = hangDt.properties[i].displayName
        ui["hang_por_" .. i].Skin = SkinPro[t]
        if isHasPro and t == isHasPro.name then
          HangProNth = i
        end
      end
    end
    if isHasPro then
      local value, rate = ComputeBar(isHasPro.name, isHasPro.value, hangDt.propertyMaxValueMap[1].value)
      ui.hang_value.Text = value
      ui.hang_bar.Size = Vector2(225 * rate, 30)
      ComputeRollLocation(1)
      for i = 1, HangProHas do
        ui["hang_por_" .. i].Visible = true
      end
      ui.btn_combHang.Hint = GetUTF8Text("id_datalist_weapon_padlock_08")
    end
    rpc_storage_item_filter(5, ui.pb_hangWeapon.CurrIndex)
  end
end, GetUTF8Text("button_common_Avatar_Card")
local DealWeaponAddProOK, DealOneRepairPrice = function(data)
  if data.properties then
    hangAddDt = data
    if (hangMentDt.subtype == 6 or hangMentDt.subtype == 13) and hangAddDt.properties[1].displayName == "addition_xFireSpeed" then
      hangAddDt.properties[1].displayName = "addition_xAttackSpeed"
    end
    if (hangMentDt.subtype == 11 or hangMentDt.subtype == 12 or hangMentDt.subtype == 14) and hangAddDt.properties[1].displayName == "addition_xDistance" then
      hangAddDt.properties[1].displayName = "addition_xDamageRadius"
    end
    for i = 1, HangProHas do
      if hangAddDt.properties[1].displayName == hangDt.properties[i].displayName then
        HangProNth = i
      end
    end
    hangAddDt.value, hangAddDt.rate = ComputeBar(hangAddDt.properties[1].displayName, hangAddDt.properties[1].value, hangAddDt.propertyMaxValueMap[1].value)
    ui.hang_value.Text = ""
    ui.hang_bar.Size = Vector2(0, 30)
    TimerRemove()
    timer = game.TimerMgr:AddTimer(0.005)
    timer.EventOnTimer = TimerRefresh5
  else
    ui.coverControl3.Parent = nil
  end
  ui.btn_combHang.Enable = true
  ui.btn_combHang.Hint = GetUTF8Text("id_datalist_weapon_padlock_08")
end, GetUTF8Text("button_common_Avatar_Card")
local DealOneRepairPrice, DealAllRepairPrice = function(data)
  MessageBox.ShowWithConfirmCancel(string.format(GetUTF8Text("msgbox_enhance_additional_string_145"), data.price), function(sender, e)
    gui:PlayAudio("pointdone")
    rpc_item_repair(1, menDt.pid)
    rpc_storage_storage_list(ui.pb_depot.CurrIndex)
  end)
end, GetUTF8Text("button_common_Avatar_Card")
local DealAllRepairPrice, SetBlueprintQuantity = function(data)
  if data.price and data.price > 0 then
    MessageBox.ShowWithConfirmCancel(string.format(GetUTF8Text("UI_lobby_additional_string_146"), data.price), function(sender, e)
      gui:PlayAudio("pointdone")
      rpc_item_repair(2)
      rpc_storage_storage_list(ui.pb_depot.CurrIndex)
    end)
  else
    MessageBox.ShowError(GetUTF8Text("msgbox_common_num_1355"))
  end
end, GetUTF8Text("button_common_Avatar_Card")
local SetBlueprintQuantity, DealBlueprintList = function(q)
  ui.manu_has.Text = "/" .. q
  ui.manu_text.Enable = 0 < q
  ui.btn_manuAll.Enable = 0 < q
  ui.combManuf_cost.Text = blueSigleCost .. "  "
  if 0 < q then
    ui.manu_text.Text = 1
    
    function ui.btn_manuAll.EventClick()
      ui.manu_text.Text = q
      ui.combManuf_cost.Text = q * blueSigleCost .. "  "
    end
  end
  local s = lv.SelectedItem:GetText(0)
  local t = string.find(s, "]")
  s = string.sub(s, t + 2, -1)
  s = string.format("[%s] %s", tostring(q), s)
  lv.SelectedItem:SetText(0, s, true)
end, GetUTF8Text("button_common_Avatar_Card")
local DealBlueprintList, DealBlueprintInfo = function(data)
  if not isBlueListUpdate then
    CleanManu()
    for i, v in ipairs(filter) do
      lv.AutoEllipsis = true
      node_1[i] = lv:AddItem(lv.RootItem, v[3])
      node_1[i].ID = v[1]
      node_1[i]:SetTextColor(0, yellow)
      node_1[i]:SetHighLightTextColor(0, brown)
    end
  end
  blueprintDt = data.items
  table.sort(blueprintDt, function(t1, t2)
    return t1.grade < t2.grade
  end)
  local typeSmall = {}
  typeSmall[100] = GetUTF8Text("tips_common_additional_tips8")
  typeSmall[101] = GetUTF8Text("id_datalist_Bandage")
  typeSmall[102] = GetUTF8Text("tips_abilities_Pharmacy")
  typeSmall[103] = GetUTF8Text("tips_abilities_Food")
  typeSmall[104] = GetUTF8Text("UI_common_Skill_Enhancement_Manual")
  typeSmall[105] = GetUTF8Text("tips_abilities_Device")
  typeSmall[106] = GetUTF8Text("tips_abilities_Bonus_Card")
  typeSmall[107] = GetUTF8Text("tips_abilities_VIP")
  typeSmall[108] = GetUTF8Text("tips_abilities_Bag_Type")
  typeSmall[109] = GetUTF8Text("tips_abilities_Bag_Type")
  typeSmall[110] = GetUTF8Text("id_datalist_voucher_new")
  typeSmall[111] = GetUTF8Text("UI_common_gift_02")
  typeSmall[112] = GetUTF8Text("UI_common_blueprint_01")
  typeSmall[200] = GetUTF8Text("tips_common_additional_tips9")
  typeSmall[300] = GetUTF8Text("tips_store_Enhancement_Material_lottery")
  typeSmall[301] = GetUTF8Text("tips_lobby_Common_Desc24")
  typeSmall[302] = GetUTF8Text("tips_store_Gem_lottery")
  typeSmall[303] = GetUTF8Text("UI_common_make_07")
  typeSmall[400] = GetUTF8Text("tips_abilities_Treasure_Chest")
  typeSmall[401] = GetUTF8Text("tips_abilities_Key")
  for i, v in ipairs(blueprintDt) do
    local bigId = 16
    for k, p in ipairs(filter) do
      if v.type == p[2][1] and v.subType == p[2][2] then
        bigId = p[1]
        break
      end
    end
    local bigFilter = filter[bigId]
    local coltext = ARGB(255, 255, 0, 0)
    if v.canUse == "Y" then
      coltext = colGrade[v.grade]
    end
    local name = string.format("[%s] %s", tostring(v.quantity), GetUTF8Text(v.displayName))
    local tname = bigFilter[3]
    if bigId == 16 then
      tname = typeSmall[tonumber(v.subType)]
    end
    if not isBlueListUpdate then
      lv.AutoEllipsis = true
      node_2 = lv:AddItem(node_1[bigId], name)
      node_2.ID = bigId * 1000 + i
      node_2:SetTextColor(0, coltext)
      node_2:SetHighLightTextColor(0, brown)
      node_2:AddSubItem(tname)
      node_2:SetTextColor(1, coltext)
      node_2:SetHighLightTextColor(1, brown)
    elseif lv.SelectedItem.ID == bigId * 1000 + i then
      SetBlueprintQuantity(v.quantity)
    end
  end
end, GetUTF8Text("button_common_Avatar_Card")
local DealBlueprintInfo, rpc_sys_blueprint_info = function(data)
  if ComFuc.produce_guide then
    NewLead.ShowNewLeadNoLock(Vector2(361, 740), Vector2(160, 63), GetUTF8Text("UI_common_Click"), 0)
  end
  local materailIsEnough = true
  for i, v in ipairs(data.materials) do
    local res = v.resource
    local tp = string.find(res, ",")
    if tp then
      res = string.sub(res, 2, tp - 2)
    end
    ComFuc.ShowUpgradeLevel(v, 2, ui["manu_tiao_level_" .. i], ui["manu_tiao_level_text_" .. i])
    ui["manu_tiao_" .. i].Visible = true
    ui["manu_tiao_lev_" .. i].Skin = SkinF.personalInfo_quality[v.grade]
    ui["manu_tiao_res_" .. i].Skin = Gui.ControlSkin({
      BackgroundImage = Gui.Image("/ui/skinF/lobby/" .. res .. ".tga", Vector4(0, 0, 0, 0))
    })
    ui["manu_tiao_count_" .. i].Text = string.format("%d/%d", v.ownNum, v.needNum)
    if v.ownNum >= v.needNum then
      ui["manu_tiao_count_" .. i].TextureFont = SkinF.hecheng_number_5
    else
      ui["manu_tiao_count_" .. i].TextureFont = SkinF.hecheng_number_6
      isEnough = false
    end
    ui["manu_tiao_name_" .. i].Text = GetUTF8Text(v.displayName)
    ui["manu_tiao_res_" .. i].EventMouseEnter = function(sender, e)
      Tip.SetRpc(tip_sys_interface[tonumber(v.type)], {
        t = v.type,
        sid = v.itemId
      })
      Tip.SetUseDescription(false)
      Tip.SetOwner(sender)
    end
  end
  ui.btn_combManuf.Enable = materailIsEnough
  blueSigleCost = data.blueprint.costGp
  local itemBP = blueprintDt[lv.SelectedItem.ID % 1000]
  SetBlueprintQuantity(itemBP.quantity)
  ui.manu_tudi.Skin = SkinF.personalInfo_quality[tonumber(itemBP.grade)]
  local res = data.blueprint.resource
  local tp = string.find(res, ",")
  if tp then
    res = string.sub(res, 2, tp - 2)
  end
  ui.manu_tudi_res.Skin = Gui.ControlSkin({
    BackgroundImage = Gui.Image("/ui/skinF/lobby/" .. res .. ".tga", Vector4(0, 0, 0, 0))
  })
  ui.manu_tudi.Visible = true
  local itemId = data.blueprint.blueprintId
  if res == "humancard" then
    itemId = data.blueprint.id
  end
  ComFuc.ShowUpgradeLevel(data.blueprint, 2, ui.manu_tudi_level, ui.manu_tudi_level_text)
  local SetTips = ComFuc.ShowUpgradeLevel
  
  function SetTips(sender)
    if res == "humancard" then
      Tip.SetRpc("tip_sys_avatar", {
        t = 5,
        sid = data.blueprint.id
      })
    elseif data.blueprint.isRandomOutPut == "N" then
      Tip.SetRpc("tip_sys_blueprint_output", {
        sid = data.blueprint.blueprintId
      })
    else
      Tip.SetRpc("tip_sys_blueprint", {
        sid = data.blueprint.blueprintId
      })
    end
    Tip.SetUseDescription(false)
    Tip.SetOwner(sender)
  end
  
  if data.blueprint.isRandomOutPut == "N" then
    ui.manu_tuwu.Visible = false
    
    function ui.manu_tudi_res.EventMouseEnter(sender, e)
      SetTips(sender)
    end
  else
    function ui.manu_tudi_res.EventMouseEnter(sender, e)
      SetTips(sender)
    end
    
    function ui.manu_tuwu.EventMouseEnter(sender, e)
      SetTips(sender)
    end
  end
end, GetUTF8Text("button_common_Avatar_Card")
local rpc_sys_blueprint_info, UpdateBluePrintMake = function()
  local bpSid = blueprintDt[lv.SelectedItem.ID % 1000].id
  rpc.safecall("blueprint_info", {sid = bpSid}, DealBlueprintInfo)
end, GetUTF8Text("button_common_Avatar_Card")
local UpdateBluePrintMake, DealBluePrintMake = function()
  isBlueUpdate = true
  isBlueListUpdate = true
  rpc_sys_blueprint_info()
  rpc.safecall("blueprint_list", nil, DealBlueprintList)
  ManufactureDepot.ManufOK()
end, GetUTF8Text("button_common_Avatar_Card")

function DealBluePrintMake(data)
  if not GainGoods then
    require("gainGoods.lua")
  end
  GainGoods.Show(data.items, UpdateBluePrintMake)
end

function SetHotKeyName()
  for i = 1, 12 do
    ui["hot_key_l_" .. i].Text = config:GetSlotKeyName(i)
    ui["pet_op_hotkey_l_" .. i].Text = config:GetSlotKeyName(i)
  end
end

function SelDepotBtn(i)
  for j = 1, 4 do
    ui["btn_depot_" .. j].PushDown = i == j
  end
  if depotCurr ~= i then
    if i == 1 or i == 3 then
      gui:PlayAudio("inventory")
    end
    ui.ctrl_depot_1.Parent = i ~= 4 and ui.right_main_2_son
    ui.ctrl_depot_4.Parent = i == 4 and ui.right_main_2_son
    TimerRemove()
    if i == 1 then
      reinState = 1
      reinKAdd = true
    elseif i == 3 then
      reinState = 2
      reinKAdd = true
    else
      reinKAdd = false
    end
    timer = game.TimerMgr:AddTimer(0.05)
    timer.EventOnTimer = TimerRefresh2
    NewLead.HideLead()
    ComFuc.CleanDepotTap(ui, PersonalInfo, depotCurr)
    depotCurr = i
    ui.add_bag.Visible = depotCurr ~= 3
    ComFuc.ShowEquipButton(ui, AvtarSkillId)
    rpc_storage_storage_list(1)
    if i == 3 then
      rpc_player_gesture_list()
    end
    if i == 2 and fastUseTask then
      if bit.band(4, ComFuc.leadList) == 4 then
        ForceLeadEasyUse(FORCE_LEAD_EASYUSE_TABLE)
      elseif bit.band(1024, ComFuc.leadList) == 1024 then
        ForceLeadShopCheck(FORCE_LEAD_SHOP_SEE)
      end
    end
    ComFuc.ResetAnim()
  end
end

function ReflashMail()
  rpc_slot_get()
  if mainCurr == 2 then
    rpc_storage_storage_list(ui.pb_depot.CurrIndex)
  end
end

function ReinSuccess()
  gui:PlayAudio("success")
  if refitLevBeg == 1 and refitLevEnd == 6 or refitLevBeg == 6 and refitLevEnd == 11 then
    refitContentN = (refitLevBeg - 1) / 5 + 1
    refitMoveDir = 1
  end
  SetReinFinish(1, "ui_success", Vector2(0, 0), Vector2(ComFuc.locationChanged + 600, 450))
end

function ReinLevelUp()
  gui:PlayAudio("success")
  SetReinFinish(7, "ui_success", Vector2(0, 0), Vector2(ComFuc.locationChanged + 600, 450))
end

function ReinWeaponUp()
  gui:PlayAudio("success")
  SetReinFinish(8, "ui_success", Vector2(0, 0), Vector2(ComFuc.locationChanged + 600, 450))
end

function ReinFail()
  gui:PlayAudio("failure")
  SetReinFinish(2, "ui_fail", Vector2(289, 296), Vector2(ComFuc.locationChanged + 455, 222))
end

function SetRefitDoor(ts, tp)
  if mainCurr == 5 and reinforceCurr == 3 then
    ui.refit_Ldoor.Location = Vector2(70, 74) + Vector2(60 * (1 - ts), 0)
    ui.refit_Rdoor.Location = Vector2(262, 74) + Vector2(-60 * (1 - ts), 0)
    if ui.refit_water.Size.y < 68 then
      ui.refit_water.Size = Vector2(46, 68) * Vector2(1, ts)
    end
    if refitMoveDir == 1 then
      ui["refit_lev_content_" .. refitContentN].Location = Vector2(0 - tp * 229, 0)
      ui["refit_lev_content_" .. refitContentN + 1].Location = Vector2(249 - tp * 249, 0)
      ui["refit_lev_content_" .. refitContentN + 2].Location = Vector2(478 - tp * 229, 0)
    end
    if refitMoveDir == -1 then
      ui["refit_lev_content_" .. refitContentN - 1].Location = Vector2(-229 + tp * 229, 0)
      ui["refit_lev_content_" .. refitContentN].Location = Vector2(0 + tp * 249, 0)
      ui["refit_lev_content_" .. refitContentN + 1].Location = Vector2(249 + tp * 229, 0)
    end
  end
  if mainCurr == 5 and reinforceCurr == 4 then
    ui.hang_Ldoor.Location = Vector2(70, 92) + Vector2(60 * (1 - ts), 0)
    ui.hang_Rdoor.Location = Vector2(262, 92) + Vector2(-60 * (1 - ts), 0)
    if 68 > ui.hang_water.Size.y then
      ui.hang_water.Size = Vector2(46, 68) * Vector2(1, ts)
    end
  end
end

local refMoveFactor = {
  0,
  0.1,
  0.2,
  0.2,
  0.4,
  0.5,
  0.6,
  0.7,
  0.8,
  0.9,
  1
}

function TimerRefresh1()
  if reinK <= 21 then
    if reinK <= 10 then
      local ts = reinK / 10
      SetRefitDoor(ts, ts * refMoveFactor[reinK + 1])
      if reinK <= 5 then
        ts = reinK / 5
        if reinState == 1 then
          ui.reinStateCtrl.Size = Vector2(289 * ts, 296 * ts)
          ui.reinStateCtrl.Location = Vector2(ComFuc.locationChanged + (1200 - 289 * ts) * 0.5, (900 - 296 * ts) * 0.5)
          if isAddMore then
            ui.reinStateCtrl_son.Size = Vector2(289 * ts, 296 * ts)
          end
        elseif reinState == 2 then
          ui.reinStateCtrl.Location = Vector2(ComFuc.locationChanged + 455, 222 + reinK * 8)
        elseif reinState == 7 or reinState == 8 then
          ui.reinStateCtrl.Size = Vector2(289 * ts, 296 * ts)
          ui.reinStateCtrl.Location = Vector2(ComFuc.locationChanged + (1200 - 289 * ts) * 0.5, (900 - 296 * ts) * 0.5)
        end
      end
    end
    if mainCurr == 5 and reinforceCurr == 3 and reinState == 1 and reinK == 11 then
      gui:PlayAudio("upgraded")
      if refitLevEnd > 0 then
        gui:AddParticle("ui_hecheng4", ui["refit_lev_" .. refitLevEnd]:ClientToScreen(Vector2(15, 0)), Vector3(0, 1, 0))
      end
    end
    reinK = reinK + 1
  else
    isAddMore = false
    ui.coverControl3.Parent = nil
    TimerRemove()
  end
end

function TimerRefresh2()
  if reinK >= 0 and reinK <= 5 then
    local ts = reinK / 5
    if reinState == 1 then
      SetCtrlColorLcSize(ui.equip_pp_1, ui.equip_pp_1.Size, ComFuc.epBC + (Vector2(413, 265) - ComFuc.epBC) * Vector2(ts, ts), ARGB(ts * 255, 255, 255, 255))
      SetCtrlColorLcSize(ui.equip_pp_3, ui.equip_pp_3.Size, ComFuc.epBC + (Vector2(15, 265) - ComFuc.epBC) * Vector2(ts, ts), ARGB(ts * 255, 255, 255, 255))
      SetCtrlColorLcSize(ui.equip_pp_4, ui.equip_pp_4.Size, ComFuc.epBC + (Vector2(413, 171) - ComFuc.epBC) * Vector2(ts, ts), ARGB(ts * 255, 255, 255, 255))
      SetCtrlColorLcSize(ui.equip_pp_6, ui.equip_pp_6.Size, ComFuc.epBC + (Vector2(15, 171) - ComFuc.epBC) * Vector2(ts, ts), ARGB(ts * 255, 255, 255, 255))
    elseif reinState == 2 then
      SetCtrlColorLcSize(ui.equip_pp_7, ui.equip_pp_7.Size, ComFuc.hpBC + (Vector2(214, 18) - ComFuc.hpBC) * Vector2(ts, ts), ARGB(ts * 255, 255, 255, 255))
      SetCtrlColorLcSize(ui.equip_pp_8, ui.equip_pp_8.Size, ComFuc.hpBC + (Vector2(413, 119) - ComFuc.hpBC) * Vector2(ts, ts), ARGB(ts * 255, 255, 255, 255))
      SetCtrlColorLcSize(ui.equip_pp_9, ui.equip_pp_9.Size, ComFuc.hpBC + (Vector2(413, 225) - ComFuc.hpBC) * Vector2(ts, ts), ARGB(ts * 255, 255, 255, 255))
      SetCtrlColorLcSize(ui.equip_pp_10, ui.equip_pp_10.Size, ComFuc.hpBC + (Vector2(214, 320) - ComFuc.hpBC) * Vector2(ts, ts), ARGB(ts * 255, 255, 255, 255))
      SetCtrlColorLcSize(ui.equip_pp_11, ui.equip_pp_11.Size, ComFuc.hpBC + (Vector2(15, 225) - ComFuc.hpBC) * Vector2(ts, ts), ARGB(ts * 255, 255, 255, 255))
      SetCtrlColorLcSize(ui.equip_pp_12, ui.equip_pp_12.Size, ComFuc.hpBC + (Vector2(15, 119) - ComFuc.hpBC) * Vector2(ts, ts), ARGB(ts * 255, 255, 255, 255))
    end
    if reinKAdd then
      reinK = reinK + 1
    else
      reinK = reinK - 1
    end
  else
    TimerRemove()
  end
end

function TimerRefresh3()
  if reinK <= 10 then
    SetRefitDoor(reinK / 10)
    if reinK == 0 then
      gui:PlayAudio("hatch_open")
    end
    reinK = reinK + 1
  else
    TimerRemove()
  end
end

function TimerRefresh4()
  if reinK <= 38 then
    if reinK <= 10 then
      local ts = reinK / 10
      ui.refit_Ldoor.Location = Vector2(70, 74) + Vector2(60 * ts, 0)
      ui.refit_Rdoor.Location = Vector2(262, 74) + Vector2(-60 * ts, 0)
      if ui.useLucyReel.Enable and ui.useLucyReel.Check then
        ui.refit_water.Size = Vector2(46, 68) * Vector2(1, 1 - ts)
      end
    end
    if reinK >= 5 and reinK <= 35 then
      if reinK == 6 then
        ui.refit_Tbar_s.Skin = SkinF.personalInfo_220[2]
      end
      if reinK == 7 then
        gui:AddParticle("ui_hecheng", Vector2(ComFuc.locationChanged + 759, 320), Vector3(0, 1, 0))
        if ui.useLucyReel.Enable and ui.useLucyReel.Check then
          gui:AddParticle("ui_hecheng2", Vector2(ComFuc.locationChanged + 410, 360), Vector3(0, 1, 0))
        end
      end
      local ts = (reinK - 5) / 30
      ui.refit_Tbar.Size = Vector2(66, 24) * Vector2(math.floor((ts + 0.1) * 5) / 5, 1)
      ui.refit_Rhand.Size = Vector2(69, 100) * Vector2(1 + ts * 0.2, 1 + ts * 0.2)
      ui.refit_Rhand.Location = Vector2(645, 50) - Vector2(69, 100) * Vector2(0.5 * ts * 0.2, 0.5 * ts * 0.2)
      local tp = math.floor((reinK - 5) / 1) % 4
      if tp % 2 == 0 then
        tp = -tp
      end
      ui.refit_point.Skin = SkinF.personalInfo_219[4 + tp]
      if reinK >= 20 then
        local ts = (reinK - 20) / 75
        ui.refit_Rhand.Size = Vector2(69, 100) * Vector2(1.2 - ts, 1.2 - ts)
        ui.refit_Rhand.Location = Vector2(645, 50) - Vector2(69, 100) * Vector2(0.5 * (0.2 - ts), 0.5 * (0.2 - ts))
      end
    end
    reinK = reinK + 1
  else
    TimerRemove()
    if retitState == 0 then
      ReinSuccess()
    end
    CleanReinMaterial()
    rpc_storage_item_filter(1, ui.pb_reinWeapon.CurrIndex)
    if retitState ~= 3 then
      rpc_refit_need()
    end
  end
end

function TimerRefresh5()
  if reinK <= 730 then
    if reinK <= 100 then
      local ts = reinK / 100
      ui.hang_Ldoor.Location = Vector2(70, 92) + Vector2(60 * ts, 0)
      ui.hang_Rdoor.Location = Vector2(262, 92) + Vector2(-60 * ts, 0)
      if ui.usePropertyLock.Enable and ui.usePropertyLock.Check then
        ui.hang_water.Size = Vector2(46, 68) * Vector2(1, 1 - ts)
      end
    end
    if reinK >= 100 and reinK <= 500 and (not ui.usePropertyLock.Enable or not ui.usePropertyLock.Check) then
      ui.hang_value.Visible = true
      ui.hang_por_parent.Visible = true
      for i = 1, HangProHas do
        ui["hang_por_" .. i].Visible = true
      end
      local ts = (reinK - 100) / 400
      ComputeRollLocation(ts)
    end
    if reinK >= 500 and reinK <= 700 then
      local ts = (reinK - 500) / 200
      ui.hang_bar.Size = Vector2(225 * hangAddDt.rate * ts, 30)
      if reinK == 700 then
        ui.hang_value.Text = hangAddDt.value
        ui.hang_bar.Size = Vector2(225 * hangAddDt.rate, 30)
      end
    end
    if reinK >= 50 and reinK <= 350 then
      if reinK == 70 and ui.usePropertyLock.Enable and ui.usePropertyLock.Check then
        gui:AddParticle("ui_hecheng2", Vector2(ComFuc.locationChanged + 581, 350), Vector3(0, 1, 0))
      end
      if reinK % 10 == 0 then
        local tp = math.floor((reinK - 50) / 10) % 4
        if tp % 2 == 0 then
          tp = -tp
        end
        ui.hang_point.Skin = SkinF.personalInfo_219[4 + tp]
      end
    end
    reinK = reinK + 1
  else
    TimerRemove()
    ReinSuccess()
    isHangFirst = false
    ui.usePropertyLock.Enable = true
    rpc_weapon_addition_material()
  end
end

function TimerRemove()
  game.TimerMgr:RemoveTimer(timer)
  ui.reinStateCtrl.Parent = nil
  reinState = 0
  reinK = 0
  timer = nil
end

function rpc_avatar_slot_create()
  rpc.safecall("avatar_slot_create", {
    aid = menDt.pid,
    slotNum = insDt[openSlotCurr].num
  }, DealOpenSlotCreate)
end

function rpc_get_avatar_slot_list()
  rpc.safecall("get_avatar_slot_list", {
    aid = menDt.pid
  }, DealCardSlotList)
end

function rpc_get_item_synthesis_info()
  rpc.safecall("get_item_synthesis_info", {
    sid = menDt.sid
  }, DealCombineMixInfo)
end

function rpc_item_repair(i, id)
  local tab = {
    {
      t = depotCurr + 1,
      pid = id
    },
    {}
  }
  local msg = {
    GetUTF8Text("msgbox_common_num_1213"),
    GetUTF8Text("msgbox_common_num_1218")
  }
  rpc.safecall("item_repair", tab[i], function(data)
    if not data.error then
      rpc_player_info()
      rpc_slot_get()
      MessageBox.ShowError(msg[i])
    end
  end)
end

function rpc_item_synthesize()
  rpc.safecall("item_synthesize", {
    sid = menDt.sid
  }, DealPropMix)
end

function rpc_medal_enchase(ps)
  rpc.safecall("medal_enchase", {
    aid = menDt.pid,
    pos = ps
  }, function(data)
    ComFuc.TestIsFinishOneTask(1015)
    menDt.isBind = "true"
  end, function()
    ShowReinPersonCard(menDt, ui["person_card_s_" .. menDt.slot].ID, false, true)
    rpc_get_avatar_slot_list()
  end)
end

function rpc_player_avatar_equip(id)
  rpc.safecall("player_avatar_equip", {avatarId = id}, nil)
end

function rpc_player_battle_force_get()
  rpc.safecall("player_battle_force_get", {
    ccid = SelectCharacter.roleServerId
  }, DealBattleForce)
end

function rpc_player_equip(s, id, t)
  rpc.safecall("player_equip", {
    resource = s,
    itemId = id,
    equip_type = t
  }, nil)
end

function rpc_player_gesture_equip(id, ts)
  rpc.safecall("player_gesture_equip", {itemId = id, toSlot = ts}, nil)
end

function rpc_player_gesture_list()
  rpc.safecall("player_gesture_list", nil, DealHandPoseList)
end

function rpc_player_gesture_unequip(fs)
  rpc.safecall("player_gesture_unequip", {fromSlot = fs}, nil)
end

function rpc_player_info()
  rpc.safecall("player_info", nil, DealPlayerInfo)
end

function rpc_player_item_count(i, t, st, ct, sid)
  local tab = {
    {
      t = t,
      st = st,
      category = ct
    },
    {t = t, sid = sid}
  }
  rpc.safecall("player_item_count", tab[i], DealItemCount)
end

function rpc_player_unequip(p)
  rpc.safecall("player_unequip", {equip_type = p}, nil)
end

function rpc_refit_need()
  rpc.safecall("refit_need", {
    itemId = menDt.pid
  }, DealRefitNeed, function(data)
    if ui.equip_b_13.Skin ~= SkinF.skin_touming2 then
      menDt = preTempDt
      isOpenRefitWeaponSound = false
      rpc.safecall("refit_need", {
        itemId = menDt.pid
      }, DealRefitNeed)
    end
  end)
end

function rpc_refit_finish(tlr, tlh)
  rpc.safecall("refit_finish", {
    playerItemId = menDt.pid,
    useFixReel = tlr,
    useHeirloom = tlh,
    materialItemId = menDt2.pid
  }, DealRefitWeaponOK, function(data)
    ui.coverControlNew.Parent = nil
  end)
end

function rpc_weapon_addition_material()
  rpc.safecall("weapon_addition_material", {
    pid = menDt.pid
  }, DealAdditionMaterial, function(data)
    if ui.equip_b_15.Skin ~= SkinF.skin_touming2 then
      menDt = preTempDt
      isOpenRefitWeaponSound = false
      rpc.safecall("weapon_addition_material", {
        pid = menDt.pid
      }, DealAdditionMaterial)
    end
  end)
end

function rpc_weapon_add_property(tlr)
  rpc.safecall("weapon_add_property", {
    pid = menDt.pid,
    usedPropertyLock = tlr
  }, DealWeaponAddProOK, function(data)
    ui.coverControl3.Parent = nil
  end)
end

function rpc_repair_price_get(i, id)
  local tab = {
    {
      t = depotCurr + 1,
      pid = id
    },
    {}
  }
  local fuc = {DealOneRepairPrice, DealAllRepairPrice}
  rpc.safecall("repair_price_get", tab[i], fuc[i])
end

function rpc_skill_adjust(as)
  rpc.safecall("skill_adjust", {adjustSkills = as}, nil)
end

function rpc_skill_equip(id, s)
  rpc.safecall("skill_equip", {skillId = id, slot = s}, nil)
end

function rpc_skill_list(lead)
  if lead and lead == 1 then
    rpc.safecall("skill_list", nil, DealSkillListLead)
  else
    rpc.safecall("skill_list", nil, DealSkillList)
  end
end

function rpc_skill_reset(t)
  rpc.safecall("skill_reset", {currency = t}, nil)
end

function rpc_skill_unequip(i)
  rpc.safecall("skill_unequip", {slot = i}, nil)
end

function rpc_slot_drag(i, ts)
  if i and ts and htkDt and htkDt[i] and htkDt[i].type and htkDt[i].itemid then
    rpc.safecall("slot_drag", {
      fromSlot = i,
      toSlot = ts,
      t = htkDt[i].type,
      id = htkDt[i].itemid
    }, nil)
  end
end

function rpc_slot_equip(pid, fs, s)
  rpc.safecall("slot_equip", {
    t = depotCurr + 1,
    id = pid,
    p = ui.pb_depot.CurrIndex,
    s = ComFuc.depotS[depotCurr],
    fromSlot = fs,
    slot = s
  }, nil)
end

function rpc_slot_get()
  rpc.safecall("slot_get", nil, DealHotKeyList)
end

function rpc_slot_unequip(i)
  rpc.safecall("slot_unequip", {
    t = htkDt[i].type,
    id = htkDt[i].itemid,
    p = ui.pb_depot.CurrIndex,
    fromSlot = i,
    quantity = htkDt[i].quantity
  }, nil)
end

function rpc_storage_drag(i, fs, id, tp, ts, qt)
  local tab = {
    {
      fromPage = ui.pb_depot.CurrIndex,
      s = ComFuc.depotS[depotCurr],
      t = depotCurr + 1,
      fromSlot = fs,
      id = id,
      toPage = tp,
      toSlot = ts
    },
    {
      fromPage = ui.pb_depot.CurrIndex,
      s = ComFuc.depotS[depotCurr],
      t = depotCurr + 1,
      fromSlot = fs,
      id = id,
      quantity = qt
    }
  }
  rpc.safecall("storage_drag", tab[i], nil)
end

function rpc_storage_item_filter(i, pg)
  local tab = {
    {
      t = 2,
      s = ComFuc.reinfS[4],
      p = pg,
      grade = 0,
      subType = "1,0;2,0;3,0;4,0;5,0;6,0;11,0;12,0;13,0;14,0;15,0;16,0;"
    },
    {
      t = 2,
      s = ComFuc.reinfS[5],
      p = pg,
      grade = refitWeaponGrades,
      subType = "1,0;2,0;3,0;4,0;5,0;6,0;11,0;12,0;13,0;14,0;15,0;16,0;",
      refitFilterItemId = menDt.pid
    },
    {
      t = 3,
      s = ComFuc.reinfS[2],
      p = pg,
      grade = 0,
      subType = "301,1;302,;303,;"
    },
    {
      t = 3,
      s = ComFuc.reinfS[3],
      p = pg,
      grade = 0,
      subType = "302,;"
    },
    {
      t = 2,
      s = ComFuc.reinfS[6],
      p = pg,
      grade = 0,
      subType = "1,0;2,0;3,0;4,0;5,0;6,0;11,0;12,0;13,0;14,0;15,0;16,0;"
    }
  }
  local fuc = {
    DealReinWeaponList,
    DealReinMaterialList,
    DealReinStoneList,
    DealReinMedalList,
    DealHangWeaponList
  }
  rpc.safecall("storage_item_filter", tab[i], fuc[i])
end

function rpc_storage_neaten()
  rpc.safecall("storage_neaten", {
    t = depotCurr + 1,
    p = ui.pb_depot.CurrIndex,
    s = ComFuc.depotS[depotCurr]
  }, nil)
end

function rpc_storage_remove(i)
  rpc.safecall("storage_remove", {
    t = depotCurr + 1,
    p = ui.pb_depot.CurrIndex,
    s = ComFuc.depotS[depotCurr],
    slot = i,
    pid = dptDt[i].pid
  }, nil)
end

function rpc_storage_storage_list(i)
  rpc.safecall("storage_storage_list", {
    t = depotCurr + 1,
    p = i,
    s = ComFuc.depotS[depotCurr]
  }, DealDepotList)
end

function rpc_storage_storage_list_no_empty(i)
  rpc.safecall("storage_storage_list_no_empty", {
    t = 5,
    s = ComFuc.reinfS[1],
    p = i,
    f = 0
  }, DealReinPersonList)
end

function rpc_weapon_decomposition()
  ComFuc.isOnDecomposition = true
  rpc.safecall("weapon_decomposition", {
    itemId = menDt.pid,
    itemType = depotCurr + 1
  }, function(data)
    if not GainGoods then
      require("gainGoods.lua")
    end
    gui:PlayAudio("convert_item")
    GainGoods.Show(data.list, nil, "tip_sys_decomposition_prize")
  end)
end

function rpc_pet_module_open()
  rpc.safecall("player_pet_open", {}, DealPlayerPetOpen)
end

function rpc_player_pet_list(page_index)
  rpc.safecall("player_pet_list", {p = page_index, pageSize = 5}, DealPlayerPetList)
end

function rpc_sys_pet_list(page_index)
  rpc.safecall("sys_pet_list", {p = page_index, pageSize = 5}, DealSysPetList)
end

function rpc_player_pet_buy(slot_index, pet_sysid, price_id)
  rpc.safecall("player_pet_buy", {
    sid = pet_sysid,
    seq = slot_index,
    priceId = price_id
  }, DealPlayerPetBuy)
end

function rpc_player_pet_del(pet_slot_seq)
  if PlayerPetsData and pet_slot_seq and PlayerPetsData[pet_slot_seq] then
    rpc.safecall("player_pet_del", {
      pid = PlayerPetsData[pet_slot_seq].id
    }, DealPlayerPetDel)
  end
end

function rpc_player_pet_rename(pet_id, new_name, currency_id)
  if pet_id then
    rpc.safecall("player_pet_rename", {
      pid = pet_id,
      name = new_name,
      c = currency_id
    }, DealPlayerPetRename)
  end
end

function rpc_player_pet_placate(pet_id, currency_id)
  if pet_id then
    rpc.safecall("player_pet_placate", {pid = pet_id, c = currency_id}, DealPlayerPetPlacate)
  end
end

function rpc_player_pet_feed(pet_id)
  if pet_id then
    rpc.safecall("player_pet_feed", {pid = pet_id}, DealPlayerPetFeed)
  end
end

function rpc_player_pet_fight(pet_id, is_on)
  if pet_id then
    rpc.safecall("player_pet_fight", {pid = pet_id, isEquipped = is_on}, DealPlayerPetFight)
  end
end

function rpc_player_pet_skill(pet_id)
  if pet_id then
    rpc.safecall("player_pet_skill", {pid = pet_id}, DealPlayerPetSkill)
  end
end

function rpc_player_pet_skill_upgrade(pet_id, currency_id)
  if pet_id then
    rpc.safecall("player_pet_skill_upgrade", {pid = pet_id, c = currency_id}, DealPlayerPetSkillUpgrade)
  end
end

function rpc_player_pet_custom_skill_list(pet_id)
  if pet_id then
    rpc.safecall("player_pet_custom_skill_list", {pid = pet_id}, DealPlayerPetOPS)
  end
end

function rpc_player_pet_custom_skill_update(pet_id, slot_index, new_setting)
  if pet_id then
    rpc.safecall("player_pet_custom_skill_update", {
      pid = pet_id,
      skillId = new_setting.sysPetCustomSkillId,
      slot = slot_index,
      packSlot = new_setting.playerPackSlot,
      isActive = new_setting.isActive
    }, DealPlayerPetOpUpdate, DealPlayerPetOpUpdateFailed)
  end
end

local rpc_player_pet_slot_expand, SelReinforceCtrl_6 = function(currency_id)
  if currency_id then
    rpc.safecall("player_pet_expand_slot", {c = currency_id}, DealPlayerPetSlotExpand)
  end
end, function(currency_id)
  if currency_id then
    rpc.safecall("player_pet_expand_slot", {c = currency_id}, DealPlayerPetSlotExpand)
  end
end
local SelReinforceCtrl_6, SelReinforceBtn_6 = function()
  for j = 1, 6 do
    ui["btn_reinforce_" .. j].PushDown = false
  end
  for j = 1, 6 do
    ui["ctrl_reinforce_" .. j].Parent = 6 == j and ui.left_main_2_s1
  end
  MasterSystem.Hide()
  PlayerCardInherit.ClearInheritStatistics()
  PlayerCardInherit.rpc_storage_storage_list_no_empty_target_card(1)
  PlayerCardInherit.rpc_storage_storage_list_no_empty_material_card(1)
  ui.card_tab_embed.Parent = ui["ctrl_reinforce_" .. 6].Parent
  ui.card_tab_inheirt.Parent = ui["ctrl_reinforce_" .. 6].Parent
  ui.btn_reinforce_1.PushDown = true
end, 0.1
local SelReinforceBtn_6, SelReinforceBtn = function()
  MasterSystem.Hide()
  for j = 1, 6 do
    ui["btn_reinforce_" .. j].PushDown = false
  end
  for j = 1, 6 do
    ui["ctrl_reinforce_" .. j].Parent = nil
  end
  ui.card_tab_embed.Parent = nil
  ui.card_tab_inheirt.Parent = nil
  ui.btn_reinforce_6.PushDown = true
  MasterSystem.Show()
end, 0.2
local SelReinforceBtn, SelReinforceButton = function(i)
  require("masterSystem.lua")
  for j = 1, 6 do
    ui["btn_reinforce_" .. j].PushDown = false
  end
  for j = 1, 6 do
    ui["ctrl_reinforce_" .. j].Parent = i == j and ui.left_main_2_s1
  end
  if MasterSystem then
    MasterSystem.Hide()
  end
  ResetRemoveStoneButton()
  menDt = {}
  isAddMore = false
  NewLead.HideLead()
  CleanReinforceTap(reinforceCurr)
  reinforceCurr = i
  if i == 1 then
    rpc_storage_storage_list_no_empty(1)
    rpc_storage_item_filter(3, 1)
    ui.card_tab_embed.Parent = ui["ctrl_reinforce_" .. i].Parent
    ui.card_tab_inheirt.Parent = ui["ctrl_reinforce_" .. i].Parent
    ui.card_tab_embed.PushDown = true
    ui.card_tab_inheirt.PushDown = false
    ui.btn_reinforce_1.PushDown = true
  elseif i == 2 then
    rpc_storage_item_filter(4, 1)
    ui.card_tab_embed.Parent = nil
    ui.card_tab_inheirt.Parent = nil
    ui.btn_reinforce_2.PushDown = true
  elseif i == 3 then
    ui.ctrl_reinforce_3_1.Parent = ui.ctrl_reinforce_3
    ui.ctrl_reinforce_4_1.Parent = ui.ctrl_reinforce_3
    ui.ctrl_reinforce_3_1.PushDown = true
    ui.ctrl_reinforce_4_1.PushDown = false
    rpc.safecall("refit_detail", {}, function(data)
      refitDetail = data
      local dt = {}
      for k, p in ipairs(data.expList) do
        dt = string.gsub(p.exp, "}", "")
        for i = 1, 20 do
          dt = string.gsub(dt, "{" .. tostring(i) .. "=", "")
        end
        dt = string.gsub(dt, "]", "")
        dt = string.sub(dt, 2, string.len(dt))
        dt = rpc.load_result("a={" .. dt .. "}")
        refitLevelExp[tonumber(p.grade)] = {}
        refitLevelExp[tonumber(p.grade)][0] = 0
        for m = 1, #dt.a do
          refitLevelExp[tonumber(p.grade)][m] = refitLevelExp[tonumber(p.grade)][m - 1] + dt.a[m]
        end
      end
    end)
    refitMoveDir = 0
    OpenWeaponDoor()
    CleanReinMaterial(true)
    rpc_storage_item_filter(1, 1)
    ui.card_tab_embed.Parent = nil
    ui.card_tab_inheirt.Parent = nil
    ui.btn_reinforce_3.PushDown = true
  elseif i == 4 then
    OpenWeaponDoor()
    ui.ctrl_reinforce_3_1.Parent = ui.ctrl_reinforce_4
    ui.ctrl_reinforce_4_1.Parent = ui.ctrl_reinforce_4
    rpc_storage_item_filter(5, 1)
    ui.card_tab_embed.Parent = nil
    ui.card_tab_inheirt.Parent = nil
    ui.btn_reinforce_3.PushDown = true
  elseif i == 5 then
    CleanManuItem()
    isBlueListUpdate = false
    rpc.safecall("blueprint_list", nil, DealBlueprintList)
    if not ManufactureDepot then
      require("manufactureDepot.lua")
    end
    ManufactureDepot.Show(ui.depotParent)
    ui.card_tab_embed.Parent = nil
    ui.card_tab_inheirt.Parent = nil
    ui.btn_reinforce_5.PushDown = true
  elseif i == 6 then
    PlayerCardInherit.ClearInheritStatistics()
    PlayerCardInherit.rpc_storage_storage_list_no_empty_target_card(1)
    PlayerCardInherit.rpc_storage_storage_list_no_empty_material_card(1)
    ui.card_tab_embed.Parent = ui["ctrl_reinforce_" .. i].Parent
    ui.card_tab_inheirt.Parent = ui["ctrl_reinforce_" .. i].Parent
    ui.btn_reinforce_1.PushDown = true
  end
  if i == 1 then
    if bit.band(8, ComFuc.leadList) == 8 then
      NewLead.ShowNewLeadNoLock(ComFuc.icB, Vector2(104, 163), GetUTF8Text("UI_enhance_Please_drag_in_the_avatar_card"), 0)
    end
    if ComFuc.inherit_guide then
      NewLead.ShowNewLeadNoLock(Vector2(199, 217), Vector2(110, 31), GetUTF8Text("UI_common_Click"), 1)
    end
  end
  if i == 2 then
    if bit.band(16, ComFuc.leadList) == 16 then
      NewLead.ShowNewLeadNoLock(Vector2(262, 304), Vector2(80, 80), GetUTF8Text("UI_enhance_Please_drag_in_the_gem"), 2)
    end
    if ComFuc.inherit_guide then
      NewLead.ShowNewLeadNoLock(Vector2(287, 163), Vector2(206, 42), GetUTF8Text("UI_common_Click"), 1)
    end
    if ComFuc.boss_skill_master then
      NewLead.ShowNewLeadNoLock(Vector2(914, 163), Vector2(206, 42), GetUTF8Text("UI_common_Click"), 1)
    end
    if ComFuc.produce_guide then
      NewLead.ShowNewLeadNoLock(Vector2(708, 163), Vector2(206, 42), GetUTF8Text("UI_common_Click"), 1)
    end
    if ComFuc.weapon_remake_guide then
      NewLead.ShowNewLeadNoLock(Vector2(502, 163), Vector2(206, 42), GetUTF8Text("UI_common_Click"), 1)
    end
  end
  if i == 3 then
    if bit.band(32, ComFuc.leadList) == 32 then
      NewLead.ShowNewLeadNoLock(Vector2(535, 376), Vector2(80, 80), GetUTF8Text("tips_lobby_Common_Desc29"), 0)
    end
    if ComFuc.weapon_remake_guide then
      NewLead.ShowNewLeadNoLock(Vector2(243, 220), Vector2(170, 38), GetUTF8Text("UI_common_Click"), 1)
    end
  end
  if i == 4 and ComFuc.weapon_remake_guide then
    NewLead.ShowNewLeadNoLock(Vector2(703, 370), Vector2(82, 82), GetUTF8Text("tips_lobby_Common_Desc29"), 0)
  end
  if i == 5 and ComFuc.produce_guide then
    NewLead.ShowNewLeadNoLock(Vector2(65, 228), Vector2(472, 240), GetUTF8Text("UI_lobby_build_product"), 1)
  end
end, 0.2

function SelReinforceButton(i)
  if i <= 5 then
    SelReinforceBtn(i)
  end
  if i == 6 then
    SelReinforceBtn_6()
  end
end

function ui.ctrl_reinforce_3_1.EventClick()
  if ui.ctrl_reinforce_3_1.PushDown == false then
    ui.ctrl_reinforce_3_1.PushDown = true
  end
  if ui.ctrl_reinforce_4_1.PushDown then
    ui.ctrl_reinforce_4_1.PushDown = false
    SelReinforceBtn(3)
  end
end

function ui.ctrl_reinforce_4_1.EventClick()
  if ui.ctrl_reinforce_4_1.PushDown == false then
    ui.ctrl_reinforce_4_1.PushDown = true
  end
  if ui.ctrl_reinforce_3_1.PushDown then
    ui.ctrl_reinforce_3_1.PushDown = false
    SelReinforceBtn(4)
  end
end

local ShowLeftPointTips, SelMainBtn = function()
  Lobby.ShowLeftPointTips(mainCurr ~= 5 and mainCurr ~= 3 and ComFuc.hasLeftPoint > 0)
end, function()
  Lobby.ShowLeftPointTips(mainCurr ~= 5 and mainCurr ~= 3 and ComFuc.hasLeftPoint > 0)
end
local SelMainBtn, DelItem = function(i)
  if mainCurr ~= i then
    NewLead.HideLead()
    CleanMainTap(mainCurr)
    mainCurr = i
    if 2 == i then
      local p = depotCurr
      depotCurr = 0
      SelDepotBtn(p)
    elseif 3 == i then
      rpc_skill_list()
      if bit.band(4, ComFuc.leadList) == 4 then
        NewLead.ShowSkillLead()
        ForceLeadSkillLearn(FORCE_LEAD_SKILLLEARN_SKILL_INFO)
      end
    elseif 4 == i then
      if 3 <= ComFuc.globalLV and ComFuc.isOpenPet then
        if Lobby.petModuleOpened == "N" then
          rpc_pet_module_open()
          Lobby.petModuleOpened = "Y"
          rpc_sys_pet_list(1)
        else
          rpc_sys_pet_list(1)
          rpc_player_pet_list(1)
        end
      end
    elseif 5 == i then
      CleanInsertCard(true, true)
      CleanMixSlot()
      CleanReinforce()
      CleanHang()
      reinforceCurr = 0
      SelReinforceBtn(2)
    end
    ComFuc.ShowEquipButton(ui, AvtarSkillId)
  end
  for j = 2, 4 do
    ui["btn_main_" .. j].PushDown = i == j
  end
  if i == 2 then
    ui.left_main_1.Parent = ui.left
    ui.right_main_2.Parent = ui.right
    lg:SetEquipmentPetInfo("", -1)
  elseif i == 3 then
    ui.left_main_1.Parent = ui.left
    if ui.profession_skill.Parent then
      ui.right_main_3.Parent = ui.right
      ui.boss_skill.Parent = nil
    elseif ui.boss_skill.Parent then
      ui.right_main_3.Parent = ui.right
      ui.profession_skill.Parent = nil
    end
    lg:SetEquipmentPetInfo("", -1)
  elseif i == 4 then
    ui.coverControlpet2.Parent = gui
    ui.left.Visible = false
    ui.left_main_pet.Parent = ui.main_mid
    ui.btm.Visible = false
    ui.right.Visible = false
    if EquippedPetResource and EquippedPetGrade then
      lg:SetEquipmentPetInfo(EquippedPetResource, EquippedPetGrade)
    else
      lg:SetEquipmentPetInfo("", -1)
    end
    local ui_slot_i = SelectedPetSlot - (CurrentPlayerPetPage - 1) * 5
    if SelectedPetSlot and PlayerPetsData and PlayerPetsData[SelectedPetSlot] then
      ui.right_main_pet_2.Parent = ui.main_mid
      if 1 <= ui_slot_i and ui_slot_i <= 5 then
        for erase_i = 1, 5 do
          ui["pet_slot_highlight_" .. erase_i].Skin = SkinF.skin_touming
        end
        ui["pet_slot_highlight_" .. ui_slot_i].Skin = SkinF.personalInfo_210
      end
      FillPetInfoPage2()
    else
      ui.right_main_pet_1.Parent = ui.main_mid
      FillPetInfoPage1()
    end
    ui.coverControlpet2.Parent = nil
  elseif i == 5 then
    ui.left.Visible = false
    ui.left_main_2.Parent = ui.main_mid
    ui.btm.Visible = false
  end
  ShowLeftPointTips()
end, "EventClick"
local DelItem, DragItem = function(c, b, s, i)
  if IsInAABB(c, b, s) then
    local msg = GetUTF8Text("msgbox_common_num_1219")
    if dptDt[i].grade >= 3 then
      msg = GetUTF8Text("msgbox_lobby_delete_highgrade_confirm")
    end
    MessageBox.ShowWithConfirmCancel(msg, function(sender, e)
      gui:PlayAudio("recyclebin")
      rpc_storage_remove(i)
      rpc_storage_storage_list(ui.pb_depot.CurrIndex)
    end)
  end
end, function()
  if ui.ctrl_reinforce_4_1.PushDown == false then
    ui.ctrl_reinforce_4_1.PushDown = true
  end
  if ui.ctrl_reinforce_3_1.PushDown then
    ui.ctrl_reinforce_3_1.PushDown = false
    SelReinforceBtn(4)
  end
end
local DragItem, ShowIdentEquip = function(c, db, ds, dc, i)
  if IsInAABB(c, db, Vector2(ds.x * dc.x, ds.y * dc.y)) then
    local k2 = math.floor((c.y - db.y) / ds.y) * dc.x + math.floor((c.x + (ds.x - db.x)) / ds.x)
    if i ~= k2 then
      rpc_storage_drag(1, i, dptDt[i].pid, ui.pb_depot.CurrIndex, k2)
      rpc_storage_storage_list(ui.pb_depot.CurrIndex)
    end
    ForceLeadEasyUse(FORCE_LEAD_EASYUSE_TABLE)
    ForceLeadShopCheck(FORCE_LEAD_SHOP_SEE)
  end
end, 0.7
local ShowIdentEquip, DragToEquip = function(data, i, k, type, isWing)
  if ui["weapon_c_" .. i].BackgroundColor.a == 255 and ui["weapon_c_" .. i].Skin == SkinF.personalInfo_140[2] then
    MessageBox.ShowError(GetUTF8Text("msgbox_common_num_1368"))
  else
    rpc_player_equip(data.resource, data.pid, type)
    rpc_storage_storage_list(ui.pb_depot.CurrIndex)
    lg:Set_Independent_Trinket(type, data.resource, false, 0, true)
    rpc_player_info()
    rpc_player_battle_force_get()
  end
end, 0.8
local DragToEquip, DragToHot = function(c, i, k, type, isWing, isHalf)
  local isOk = IsInAABB(c, ComFuc.csB, ComFuc.csS) or IsInAABB(c, ComFuc.epBL[k], ComFuc.elS)
  if isHalf then
    isOk = IsInAABB(c, ComFuc.epBL[k], ComFuc.elS)
  end
  print("----DragToEquip", isOK, isHalf)
  if isOk then
    if dptDt[i].unitType and (dptDt[i].unitType == 2 or dptDt[i].unitType == 3 or dptDt[i].unitType == 4 or dptDt[i].unitType == 5) and dptDt[i].unit and dptDt[i].unit <= 0 then
      MessageBox.ShowError(GetUTF8Text("msgbox_enhance_additional_string_148"))
    else
      ShowIdentEquip(dptDt[i], i, k, type, isWing)
    end
  end
end, 0.9
local DragToHot, PlayerIndependentUnequip = function(c, i, type)
  if IsInAABB(c, ComFuc.hkB, Vector2(ComFuc.hkS.x * 12, ComFuc.hkS.y)) then
    if ComFuc.isReadyStart or ComFuc.isReadyMatch then
      MessageBox.ShowError(GetUTF8Text("tips_common_operation_forbidden"))
      return
    end
    local k2 = math.floor((c.x + (ComFuc.hkS.x - ComFuc.hkB.x)) / ComFuc.hkS.x)
    if type == 1 then
      rpc_skill_equip(sklDt[i].id, k2)
      if NewLead.leadVisible then
        NewLead.HideLead()
        ForceLeadSkillLearn(FORCE_LEAD_SKILLLEARN_PLACED)
      end
    elseif type == 2 then
      if NewLead.leadVisible then
        NewLead.HideLead()
        fastUseTask = false
        if bit.band(2, ComFuc.leadList) == 2 then
          ComFuc.SetOneLeadFinish(2)
          ForceLeadSkillLearn(FORCE_LEAD_SKILLLEARN_TAG)
        elseif bit.band(1024, ComFuc.leadList) == 1024 then
          ComFuc.SetOneLeadFinish(1024)
          if not ComFuc.Is_FirstPrintLog[9] then
            rpc.safecall("user_retention", {
              sign = ComFuc.First_Log[9]
            }, function(data)
            end)
            ComFuc.Is_FirstPrintLog[9] = true
          end
          MessageBox.Show(GetUTF8Text("msgbox_common_Task_guide_17"), GetUTF8Text("button_common_OK"))
        end
      end
      ComFuc.TestIsFinishOneTask(1001)
      if dptDt[i].unitType and (dptDt[i].unitType == 2 or dptDt[i].unitType == 3 or dptDt[i].unitType == 4 or dptDt[i].unitType == 5) and dptDt[i].unit and dptDt[i].unit <= 0 then
        MessageBox.ShowError(GetUTF8Text("msgbox_enhance_additional_string_148"))
      else
        rpc_slot_equip(dptDt[i].pid, i, k2)
        rpc_storage_storage_list(ui.pb_depot.CurrIndex)
        rpc_player_battle_force_get()
      end
    elseif type == 3 then
      rpc_slot_drag(i, k2)
    elseif type == 10 then
      rpc_skill_equip(bossSkillDt[i].skillId, k2)
    end
    rpc_slot_get()
  elseif type == 1 then
    ForceLeadSkillLearn(FORCE_LEAD_SKILLLEARN_PICK)
  elseif type == 2 then
    ForceLeadEasyUse(FORCE_LEAD_EASYUSE_TABLE)
    ForceLeadShopCheck(FORCE_LEAD_SHOP_SEE)
  end
end, 1
local PlayerIndependentUnequip, SetDraveStoneToIns = function(i, p)
  if i <= 6 then
    if i ~= 2 and i ~= 5 then
      rpc_player_unequip(p)
      rpc_storage_storage_list(ui.pb_depot.CurrIndex)
      lg:Set_Independent_Trinket(p, "", false)
      ui["equip_b_" .. i].Skin = SkinF.skin_touming2
      if i == 1 or i == 3 then
        ui["equip_p_" .. i].Skin = SkinF.personalInfo_089
      elseif i == 4 then
        ui["equip_p_" .. i].Skin = SkinF.personalInfo_090
      elseif i == 6 then
        ui["equip_p_" .. i].Skin = SkinF.personalInfo_138
      end
      rpc_player_info()
      rpc_player_battle_force_get()
    end
  else
    local tS = i - 6
    rpc_player_gesture_unequip(tS)
    rpc_player_gesture_list()
    rpc_storage_storage_list(ui.pb_depot.CurrIndex)
  end
end, GetUTF8Text("button_common_Avatar_Card")
local SetDraveStoneToIns, DraveStoneToIns = function(i, k, isReplace)
  ui.btn_insert.Enable = true
  ComputeInsertP(slotRenforceBf[k].stamina, ui.insert_life, -1)
  ComputeInsertP(slotRenforceBf[k].cureQuantity, ui.insert_add, -1)
  ComputeInsertP(slotRenforceBf[k].armor, ui.insert_protect, -1)
  ComputeInsertP(slotRenforceBf[k].recovery, ui.insert_recover, -1)
  ComputeInsertP(dptDt[i].pluses.stamina, ui.insert_life)
  ComputeInsertP(dptDt[i].pluses.cureQuantity, ui.insert_add)
  ComputeInsertP(dptDt[i].pluses.armor, ui.insert_protect)
  ComputeInsertP(dptDt[i].pluses.recovery, ui.insert_recover)
  local p = ui.pb_reinStone.CurrIndex
  if not tableDepot["T" .. p .. i] then
    tableDepot["T" .. p .. i] = 0
  end
  if isReplace then
    tableDepot["T" .. tableInsP[k] .. tableInsB[k]] = tableDepot["T" .. tableInsP[k] .. tableInsB[k]] - 1
  end
  tableInsP[k] = p
  tableInsB[k] = i
  tableDepot["T" .. p .. i] = tableDepot["T" .. p .. i] + 1
  slotRenforceId[k] = dptDt[i].pid
  slotRenforceBf[k] = dptDt[i].pluses
  ui["insert_pd_" .. k].BackgroundColor = colw
  ui["insert_pd_" .. k].Skin = SkinF.personalInfo_quality[dptDt[i].grade]
  ShowOneButton(ui["insert_c2_" .. k], ui["insert_b_" .. k], resDir, dptDt[i].resource)
  local count = 0
  for i = 1, 5 do
    if tableInsP[i] and tableInsP[i] >= 1 then
      count = count + 1
    end
  end
  ui["insert_c3_" .. k].EventMouseEnter = function(sender, e)
    Tip.SetRpc(tip_player_interface[3], {
      t = 3,
      pid = dptDt[i].pid
    })
    Tip.SetUseDescription(false)
    Tip.SetOwner(sender)
  end
  ui.combIns_cost.Text = count * insCost .. "  "
  rpc_storage_item_filter(3, p)
end, GetUTF8Text("button_common_Avatar_Card")
local DraveStoneToIns, SetDestNumSure = function(i, k, isReplace)
  if ComFuc.globalLV < dptDt[i].level then
    MessageBox.ShowWithConfirmCancel(GetUTF8Text("msgbox_enhance_additional_string_149"), function(sender, e)
      SetDraveStoneToIns(i, k, isReplace)
    end)
  else
    SetDraveStoneToIns(i, k, isReplace)
  end
end, GetUTF8Text("button_common_Avatar_Card")
local SetDestNumSure, ShowPersonCard = function()
  if not tonumber(ui.dest_text.Text) or tonumber(ui.dest_text.Text) > menDt.quantity - 1 or tonumber(ui.dest_text.Text) <= 0 then
    MessageBox.ShowError(string.format(GetUTF8Text("msgbox_common_additional_string_150"), menDt.quantity - 1))
  else
    rpc_storage_drag(2, menDt.slot, menDt.pid, nil, nil, ui.dest_text.Text)
    rpc_storage_storage_list(ui.pb_depot.CurrIndex)
    ComFuc.TestIsFinishOneTask(1019)
  end
  HideDestructNum()
end, GetUTF8Text("button_common_Avatar_Card")

function ShowPersonCard(dt)
  menDt = dt
  rpc_player_avatar_equip(dt.pid)
  rpc_storage_storage_list(ui.pb_depot.CurrIndex)
  ComFuc.selToLobbyState = 0
  rpc_player_info()
  rpc_player_battle_force_get()
end

local ShowReinPersonCard, bossSkillUp = function(dt, ID, is0, is1)
  CleanInsertCard(is0, is1)
  ui.insert_card_p.Visible = true
  if dt then
    menDt = dt
    lg:CopyStaticCard(ID, 9)
    lg:UpdateStaticCardByInfoString(9, dt.position)
    ComFuc.ShowUpgradeLevel(dt, 5, ui.insert_card_level, ui.insert_card_level_text)
    ui.insert_card_p.Skin = SkinF.personalInfo_quality[dt.grade]
    
    function ui.insert_card_s2.EventMouseEnter(sender, e)
      Tip.SetRpc(tip_player_interface[5], {
        t = 5,
        pid = dt.pid
      })
      Tip.SetUseDescription(false)
      Tip.SetOwner(sender)
    end
    
    if dt.subType == 1 then
      ui.insert_card.Skin = SkinF.personalInfo_143
      ui.insert_card_level.Skin = SkinF.avatar_level
    elseif dt.subType == 2 then
      ui.insert_card.Skin = SkinF.personalInfo_261
      ui.insert_card_level.Skin = SkinF.avatar_level_hero
    end
  end
  rpc_get_avatar_slot_list()
end, function(dt, ID, is0, is1)
  CleanInsertCard(is0, is1)
  ui.insert_card_p.Visible = true
  if dt then
    menDt = dt
    lg:CopyStaticCard(ID, 9)
    lg:UpdateStaticCardByInfoString(9, dt.position)
    ComFuc.ShowUpgradeLevel(dt, 5, ui.insert_card_level, ui.insert_card_level_text)
    ui.insert_card_p.Skin = SkinF.personalInfo_quality[dt.grade]
    
    function ui.insert_card_s2.EventMouseEnter(sender, e)
      Tip.SetRpc(tip_player_interface[5], {
        t = 5,
        pid = dt.pid
      })
      Tip.SetUseDescription(false)
      Tip.SetOwner(sender)
    end
    
    if dt.subType == 1 then
      ui.insert_card.Skin = SkinF.personalInfo_143
      ui.insert_card_level.Skin = SkinF.avatar_level
    elseif dt.subType == 2 then
      ui.insert_card.Skin = SkinF.personalInfo_261
      ui.insert_card_level.Skin = SkinF.avatar_level_hero
    end
  end
  rpc_get_avatar_slot_list()
end
local bossSkillUp, SkillUp = function(i, c)
  gui:PlayAudio("putdown")
  LighterOrNarmal(false, 1, 1)
  DragToHot(c, i, 10)
  ui.moveControl.Parent = nil
end, GetUTF8Text("button_common_Avatar_Card")
local SkillUp, WeaponUp = function(i, c)
  gui:PlayAudio("putdown")
  LighterOrNarmal(false, 1, 1)
  DragToHot(c, i, 1)
  ui.moveControl.Parent = nil
end, GetUTF8Text("button_common_Avatar_Card")
local WeaponUp, PropUp = function(i, c)
  gui:PlayAudio("putdown")
  SwitchALLLighter(1, false, 1, dptDt[i].subtype)
  DelItem(c, ComFuc.dtB, ComFuc.dtS, i)
  DragItem(c, ComFuc.dpB, ComFuc.dpS, ComFuc.dpC, i)
  if dptDt[i].subtype == 101 then
    DragToEquip(c, i, 6, 4)
  elseif dptDt[i].subtype == 102 then
    DragToEquip(c, i, 4, 1, true)
  elseif dptDt[i].subtype == 103 then
    DragToEquip(c, i, 3, 3)
    DragToEquip(c, i, 1, 2, false, true)
  else
    DragToHot(c, i, 2)
  end
  ui.moveControl.Parent = nil
end, GetUTF8Text("button_common_Avatar_Card")
local PropUp, PoseUp = function(i, c)
  gui:PlayAudio("putdown")
  LighterOrNarmal(false, 1, 1)
  DelItem(c, ComFuc.dtB, ComFuc.dtS, i)
  DragItem(c, ComFuc.dpB, ComFuc.dpS, ComFuc.dpC, i)
  DragToHot(c, i, 2)
  ui.moveControl.Parent = nil
end, GetUTF8Text("button_common_Avatar_Card")
local PoseUp, PersonUp = function(i, c)
  gui:PlayAudio("putdown")
  LighterOrNarmal(false, 2, 0, 7, 12)
  DelItem(c, ComFuc.dtB, ComFuc.dtS, i)
  DragItem(c, ComFuc.dpB, ComFuc.dpS, ComFuc.dpC, i)
  for k = 1, 6 do
    if IsInAABB(c, ComFuc.hpBL[k], ComFuc.elS) then
      if dptDt[i].unitType and (dptDt[i].unitType == 2 or dptDt[i].unitType == 3 or dptDt[i].unitType == 4 or dptDt[i].unitType == 5) and dptDt[i].unit and 0 >= dptDt[i].unit then
        MessageBox.ShowError(GetUTF8Text("msgbox_enhance_additional_string_148"))
        break
      end
      lg:PlayAnim(dptDt[i].resource, false)
      rpc_player_gesture_equip(dptDt[i].pid, k)
      rpc_player_gesture_list()
      rpc_storage_storage_list(ui.pb_depot.CurrIndex)
      break
    end
  end
  ui.moveControl.Parent = nil
end, GetUTF8Text("button_common_Avatar_Card")
local PersonUp, HotKeyUp = function(i, c)
  gui:PlayAudio("putdown")
  LighterOrNarmal(false, 2, 0, 2, 2)
  DelItem(c, ComFuc.dtB, ComFuc.dtS, i)
  DragItem(c, ComFuc.cdB, ComFuc.cdS, ComFuc.cdC, i)
  if IsInAABB(c, ComFuc.csB, ComFuc.csS) or IsInAABB(c, ComFuc.epBL[2], ComFuc.cdS) then
    if dptDt[i].unitType and (dptDt[i].unitType == 2 or dptDt[i].unitType == 3 or dptDt[i].unitType == 4 or dptDt[i].unitType == 5) and dptDt[i].unit and 0 >= dptDt[i].unit then
      MessageBox.ShowError(GetUTF8Text("msgbox_enhance_additional_string_148"))
    else
      isDoEquip = true
      ShowPersonCard(dptDt[i])
    end
  end
  ui.moveCard.Parent = nil
  ui.moveCard_s.ID = -1
end, GetUTF8Text("button_common_Avatar_Card")
local HotKeyUp, ReinPersonUp = function(i, c)
  gui:PlayAudio("putdown")
  LighterOrNarmal(false, 1, 1)
  if ComFuc.isReadyStart or ComFuc.isReadyMatch then
    MessageBox.ShowError(GetUTF8Text("tips_common_operation_forbidden"))
    ui.moveControl.Parent = nil
    return
  end
  if ptr_cast(game.CurrentState, "Client.StateLobby") then
    DragToHot(c, i, 3)
    if IsOutAABB(c, ComFuc.hkB, Vector2(ComFuc.hkS.x * 12, ComFuc.hkS.y)) then
      if htkDt[i].type >= 2 then
        rpc_slot_unequip(i)
        rpc_storage_storage_list(ui.pb_depot.CurrIndex)
        rpc_slot_get()
      elseif tonumber(htkDt[i].type) == 1 or tonumber(htkDt[i].type) == 10 then
        rpc_skill_unequip(i)
        rpc_slot_get()
      end
    end
  end
  ui.moveControl.Parent = nil
end, GetUTF8Text("button_common_Avatar_Card")
local ReinPersonUp, ReinStoneUp = function(i, c)
  ResetRemoveStoneButton()
  gui:PlayAudio("putdown")
  LighterOrNarmal(false, 3)
  if not c or IsInAABB(c, ComFuc.icB, ComFuc.cdS) then
    menDt = dptDt2[i]
    ShowReinPersonCard(dptDt2[i], ui["reinPerson_card_s_" .. i].ID, false, true)
    rpc_storage_item_filter(3, ui.pb_reinStone.CurrIndex)
    rpc_storage_storage_list_no_empty(ui.pb_reinPerson.CurrIndex)
    if NewLead.leadVisible then
      NewLead.HideLead()
      NewLead.ShowNewLeadNoLock(ComFuc.ilBL[1], Vector2(80, 80), GetUTF8Text("UI_enhance_Please_drag_in_the_gem_1"), 0)
    end
  end
  ui.moveCard.Parent = nil
  ui.moveCard_s.ID = -1
end, GetUTF8Text("button_common_Avatar_Card")
local ReinStoneUp, ReinMedalUp = function(i, c)
  gui:PlayAudio("gem_put")
  LighterOrNarmal(false, 4)
  for k = 1, 5 do
    if IsInAABB(c, ComFuc.ilBL[k], ComFuc.ilS) and ui["insert_kb_" .. k].Visible == false then
      if tonumber(insDt[k].itemId) ~= 0 or tableInsP[k] and 1 <= tonumber(tableInsP[k]) then
        if tableInsP[k] and 1 <= tableInsP[k] then
          DraveStoneToIns(i, k, true)
        else
          DraveStoneToIns(i, k, false)
        end
      else
        DraveStoneToIns(i, k, false)
      end
      if NewLead.leadVisible then
        NewLead.HideLead()
      end
      break
    end
  end
  ui.moveControl.Parent = nil
end, GetUTF8Text("button_common_Avatar_Card")
local ReinMedalUp, ReinWeaponUp = function(i, c)
  LighterOrNarmal(false, 5)
  for k = 1, 5 do
    if not c or IsInAABB(c, ComFuc.mlBL[k], ComFuc.mlS) then
      local tempDt = menDt
      if i then
        menDt = dptDt[i]
      end
      if menDt.grade < NumeralConst.max_stone_combine then
        rpc_player_item_count(2, 3, 302, 1, menDt.sid)
        rpc_get_item_synthesis_info()
        break
      end
      MessageBox.ShowError(GetUTF8Text("msgbox_common_num_1342"))
      if tempDt and tempDt.subtype and tonumber(tempDt.subtype) == 302 then
        menDt = tempDt
      end
      break
    end
  end
  ui.moveControl.Parent = nil
end, GetUTF8Text("button_common_Avatar_Card")
local ReinWeaponUp, ReinMaterialUp = function(i, c)
  LighterOrNarmal(false, 6)
  if not c or IsInAABB(c, ComFuc.rwB, ComFuc.rwS) then
    if ui.equip_b_13.Skin ~= SkinF.skin_touming2 then
      preTempDt = menDt
    end
    menDt = dptDt[i]
    refitMoveDir = 0
    isOpenRefitWeaponSound = true
    rpc_refit_need()
  end
  ui.moveControl.Parent = nil
end, GetUTF8Text("button_common_Avatar_Card")
local ReinMaterialUp, HangWeaponUp = function(i, c)
  LighterOrNarmal(false, 7)
  if not c or IsInAABB(c, ComFuc.rmB, ComFuc.rwS) then
    gui:PlayAudio("weapon_put")
    menDt2 = dptDt2[i]
    ui.equip_pd_14.BackgroundColor = colw
    ShowOneButton(ui.equip_pd_14, ui.equip_b_14, resDir, menDt2.resource, menDt2.grade)
    ComFuc.ShowUpgradeLevel(menDt2, 2, ui.equip_level_14, ui.equip_level_text_14)
    ComputeWeaponEnhanceBar()
    if menDt2.refitTotalExp > 0 then
      ui.btn_combRefit.Hint = GetUTF8Text("UI_abilities_Enhancement_experience_01")
    else
      ui.btn_combRefit.Hint = ""
    end
    ui.btn_combRefit.Enable = canUpGrade
  end
  ui.equip_c_14.Visible = ui.equip_b_13.Skin ~= SkinF.skin_touming2 and ui.equip_b_14.Skin == SkinF.skin_touming2
  ui.Tips_To_DragMetrailWeapon.Visible = ui.equip_b_13.Skin ~= SkinF.skin_touming2 and ui.equip_b_14.Skin == SkinF.skin_touming2
  ui.moveControl.Parent = nil
end, GetUTF8Text("button_common_Avatar_Card")
local HangWeaponUp, EquipButonUp = function(i, c)
  LighterOrNarmal(false, 8)
  if not c or IsInAABB(c, ComFuc.hwB, ComFuc.hwS) then
    if ui.equip_b_15.Skin ~= SkinF.skin_touming2 then
      preTempDt = menDt
    end
    menDt = dptDt[i]
    isOpenRefitWeaponSound = true
    isHangFirst = true
    NewLead.HideLead()
    if ui.btn_combHang.Skin == SkinF.personalInfo_247 and ComFuc.weapon_remake_guide then
      NewLead.ShowNewLeadNoLock(Vector2(935, 750), Vector2(160, 61), GetUTF8Text("UI_common_Click"), 0)
    end
    rpc_weapon_addition_material()
  end
  ui.moveControl.Parent = nil
end, GetUTF8Text("button_common_Avatar_Card")
local EquipButonUp, btn_insertClick = function(i, c)
  gui:PlayAudio("putdown")
  if i <= 6 then
    if IsOutAABB(c, ComFuc.epBL[i], ComFuc.elS) then
      PlayerIndependentUnequip(i, ComFuc.equipMapKey[i])
    end
  elseif IsOutAABB(c, ComFuc.hpBL[i - 6], ComFuc.elS) then
    PlayerIndependentUnequip(i, nil)
  end
  ui.moveControl.Parent = nil
end, GetUTF8Text("button_common_Avatar_Card")
local btn_insertClick, GetDepotSlot = function(sender)
  local func = function()
    sender.Enable = false
    position = ""
    for i = 1, 5 do
      if tableInsP[i] and 1 <= tableInsP[i] then
        position = position .. i - 1 .. "," .. slotRenforceId[i] .. ";"
      end
    end
    rpc_medal_enchase(position)
    ShowReinPersonCard()
    rpc_storage_item_filter(3, 1)
    if bit.band(8, ComFuc.leadList) == 8 then
      ComFuc.SetOneLeadFinish(8)
    end
  end
  if menDt.isBind == "true" or menDt.isBind == "Y" or menDt.grade > 1 then
    func()
  else
    MessageBox.ShowWithConfirmCancel(GetUTF8Text("msgbox_avatar_colligation_01"), func)
  end
end, GetUTF8Text("button_common_Avatar_Card")
local GetDepotSlot, GetDepotSlotCurr = function(c, tb, ts, tc)
  if IsInAABB(c, tb, ts * tc - Vector2(1, 1)) then
    return math.floor((c.y - tb.y) / ts.y) * tc.x + math.floor((c.x - tb.x) / ts.x) + 1
  end
  return 0
end, GetUTF8Text("button_common_Avatar_Card")
local GetDepotSlotCurr, DepotDelUp = function(c)
  local k = 0
  if depotCurr == 4 then
    k = GetDepotSlot(c, ComFuc.cdB, ComFuc.cdS, ComFuc.cdC)
  else
    k = GetDepotSlot(c, ComFuc.dpB, ComFuc.dpS, ComFuc.dpC)
  end
  return k
end, GetUTF8Text("button_common_Avatar_Card")
local DepotDelUp, DepotRepairUp = function(c)
  Tip.SetOwner(nil)
  local k = GetDepotSlotCurr(c)
  if 0 < k and dptDt[k] then
    local msg = GetUTF8Text("msgbox_common_num_1219")
    if dptDt[k].grade >= 3 then
      msg = GetUTF8Text("msgbox_lobby_delete_highgrade_confirm")
    end
    if dptDt[k].isEquip == "N" then
      MessageBox.ShowWithConfirmCancel(msg, function(sender, e)
        gui:PlayAudio("recyclebin")
        rpc_storage_remove(k)
        rpc_storage_storage_list(ui.pb_depot.CurrIndex)
      end, nil, true)
    else
      MessageBox.ShowError(GetUTF8Text("msgbox_common_num_1222"))
    end
  end
  oldTipSlot = -1
  ui.btn_depot_del.Skin = SkinF.personalInfo_211[1]
end, GetUTF8Text("button_common_Avatar_Card")
local DepotRepairUp, DepotWeaponUpShow = function(c)
  Tip.SetOwner(nil)
  local k = GetDepotSlotCurr(c)
  if 0 < k and dptDt[k] then
    if dptDt[k].unitType == 2 then
      if dptDt[k].unit < 100 then
        menDt = dptDt[k]
        rpc_repair_price_get(1, dptDt[k].pid)
      else
        MessageBox.ShowError(GetUTF8Text("msgbox_common_num_1305"))
      end
    else
      MessageBox.ShowError(GetUTF8Text("msgbox_common_num_1214"))
    end
  end
  oldTipSlot = -1
  ui.btn_depot_repair.Skin = SkinF.personalInfo_212[1]
end, GetUTF8Text("button_common_Avatar_Card")
local DepotWeaponUpShow, DepotWeaponUp = function()
  for i = 1, 24 do
    if dptDt[i] and dptDt[i].canAdvanced == true then
      ui["weapon_weaponup_" .. i].Skin = SkinF.weaponup_icon
      ui["weapon_weaponup_" .. i].Visible = true
    elseif dptDt[i] then
      ui["weapon_weaponup_" .. i].Skin = SkinF.weaponup_icon_disable
      ui["weapon_weaponup_" .. i].Visible = true
    end
  end
end, GetUTF8Text("button_common_Avatar_Card")
local DepotWeaponUp, OnDepotDelMove = function(c)
  for i = 1, 24 do
    if dptDt[i] then
      ui["weapon_weaponup_" .. i].Visible = false
    end
  end
  Tip.SetOwner(nil)
  local k = GetDepotSlotCurr(c)
  if 0 < k and dptDt[k] then
    if dptDt[k].canAdvanced == true then
      if "Y" == dptDt[k].isEquip then
        MessageBox.Show(GetMatchedUTF8Text("UI_lobby_unable_to_upgrade"), GetUTF8Text("button_common_OK"))
      else
        if not WeaponUpUI then
          require("weaponUp.lua")
        end
        WeaponUpUI.Show(dptDt[k].pid)
      end
    else
      MessageBox.ShowError(GetUTF8Text("UI_lobby_upgrade_permit"))
    end
  end
  oldTipSlot = -1
  ui.btn_depot_weapon_up.Skin = SkinF.personalInfo_weaponup[1]
end, GetUTF8Text("button_common_Avatar_Card")
local OnDepotDelMove, HideResetSkillCost = function(c)
  local k = GetDepotSlotCurr(c)
  local tN = {
    "weapon",
    "weapon",
    "weapon",
    "person_card"
  }
  if 0 < k and dptDt[k] and oldTipSlot ~= k then
    Tip.SetOwner(nil)
    Tip.SetRpc(tip_player_interface[depotCurr + 1], {
      t = depotCurr + 1,
      pid = dptDt[k].pid
    })
    Tip.SetUseDescription(false)
    Tip.SetOwner(gui)
    Tip.SetAlignSize(Vector2(80, 80))
    local globalLc = ui[tN[depotCurr] .. "_b_" .. k]:ClientToScreen(Vector2(0, 0))
    Tip.SetOffset(globalLc)
  end
  if k == 0 or not dptDt[k] then
    Tip.SetOwner(nil)
  end
  if oldTipSlot ~= k then
    oldTipSlot = k
  end
end, GetUTF8Text("button_common_Avatar_Card")

function HideResetSkillCost()
  ui.coverControl2.Parent = nil
  ui.reset_skill.Parent = nil
end

local whereType, ShowResetSkillCost
local ShowResetSkillCost, GetSysPetPriceID = function(type)
  whereType = type
  local skillCostTb, textKey
  if type == 1 then
    skillCostTb = skillCost
    textKey = "msgbox_abilities_reset_skill_under"
  elseif type == 2 then
    skillCostTb = addBagCostTb
    textKey = "UI_lobby_consortia_05"
  elseif type == 3 then
    skillCostTb = currentSysPetPrice
    textKey = "UI_pet_predicable_01"
  elseif type == 4 then
    skillCostTb = currentPlacatePrice
    textKey = "UI_pet_predicable_03"
  elseif type == 5 then
    skillCostTb = currentPetSkillUpdatePrice
    textKey = "msgbox_pet_clew_13"
  elseif type == 6 then
    skillCostTb = currentPetSlotExpandPrice
    textKey = "Choose a price to expand pet slots"
  end
  ui.coverControl2.Parent = gui
  ui.reset_skill.Parent = gui
  local tk = 0
  ui.reset_skill_costP_1.Visible = skillCostTb[1] and skillCostTb[1] > 0
  ui.reset_skill_costP_2.Visible = skillCostTb[2] and skillCostTb[2] > 0
  ui.reset_skill_costP_3.Visible = skillCostTb[3] and skillCostTb[3] > 0
  ui.reset_skill_costP_4.Visible = skillCostTb[4] and skillCostTb[4] > 0
  if skillCostTb[1] and skillCostTb[1] > 0 then
    ui.reset_skill_costL_1.Text = skillCostTb[1] .. " "
    ui.reset_skill_costP_1.Location = Vector2(113, 10 + 36 * tk)
    tk = tk + 1
  end
  ui.reset_skill_costCB_1.Check = skillCostTb[1] and skillCostTb[1] > 0 and tk == 1
  if skillCostTb[2] and skillCostTb[2] > 0 then
    ui.reset_skill_costL_2.Text = skillCostTb[2] .. " "
    ui.reset_skill_costP_2.Location = Vector2(113, 10 + 36 * tk)
    tk = tk + 1
  end
  ui.reset_skill_costCB_2.Check = skillCostTb[2] and skillCostTb[2] > 0 and tk == 1
  if skillCostTb[3] and skillCostTb[3] > 0 then
    ui.reset_skill_costL_3.Text = skillCostTb[3] .. " "
    ui.reset_skill_costP_3.Location = Vector2(113, 10 + 36 * tk)
    tk = tk + 1
  end
  ui.reset_skill_costCB_3.Check = skillCostTb[3] and skillCostTb[3] > 0 and tk == 1
  if skillCostTb[4] and skillCostTb[4] > 0 then
    ui.reset_skill_costL_4.Text = skillCostTb[4] .. " "
    ui.reset_skill_costP_4.Location = Vector2(113, 10 + 36 * tk)
    tk = tk + 1
  end
  ui.reset_skill_costCB_4.Check = skillCostTb[4] and skillCostTb[4] > 0 and tk == 1
  ui.reset_skill.Size = Vector2(400, 170 + 36 * tk)
  ui.reset_skill_check_di.Size = Vector2(376, 62 + 36 * tk)
  ui.reset_skill_text.Location = Vector2(30, 4 + 36 * tk)
  ui.reset_skill_sure.Location = Vector2(93, 72 + 36 * tk)
  ui.reset_skill_canc.Location = Vector2(223, 72 + 36 * tk)
  ui.reset_skill_text.Text = GetUTF8Text(textKey)
  ui.reset_skill_text.AutoWrap = true
  Gui.Align(ui.reset_skill, 0.5, 0.5)
end, GetUTF8Text("button_common_Avatar_Card")

function GetSysPetPriceID(in_currency)
  local priceId = -1
  if SysPetsData and SelectedPetSlot and SelectedCandidate and SysPetsData[SelectedCandidate] then
    for i, v in ipairs(SysPetsData[SelectedCandidate].price) do
      if v.currency == in_currency then
        priceId = v.priceId
      end
    end
  end
  return priceId
end

function ui.pet_info_skill_icon.EventMouseEnter(sender, e)
  if PlayerPetsData and SelectedPetSlot and PlayerPetsData[SelectedPetSlot] and PlayerPetsData[SelectedPetSlot].id and not ComFuc.isOnDecomposition then
    ComFuc.ShowPetSkillTips(sender, PlayerPetsData[SelectedPetSlot].id)
  end
end

function lv.EventSelectItemChange(sender, e)
  CleanManuItem()
  if sender.SelectedItem and sender.SelectedItem.ID > 1000 then
    isBlueUpdate = false
    rpc_sys_blueprint_info()
  end
end

function ui.reset_skill_cha.EventClick(sender, e)
  HideResetSkillCost()
end

function ui.reset_skill_sure.EventClick(sender, e)
  local skillCostTb, textKey
  if whereType == 1 then
    skillCostTb = skillCost
    textKey = "msgbox_common_num_1360"
  elseif whereType == 2 then
    skillCostTb = addBagCostTb
    textKey = "UI_lobby_consortia_06"
  elseif whereType == 3 then
    skillCostTb = currentSysPetPrice
    textKey = "UI_pet_buy_clew"
  elseif whereType == 4 then
    skillCostTb = currentPlacatePrice
    textKey = "UI_pet_function_07"
  elseif whereType == 5 then
    skillCostTb = currentPetSkillUpdatePrice
    textKey = "UI_pet_function_11"
  elseif whereType == 6 then
    skillCostTb = currentPetSlotExpandPrice
    textKey = "Confirm Price of slot expanding"
  end
  local t = 1
  local mesgl = GetUTF8Text("id_common_Gold")
  if ui.reset_skill_costCB_2.Check then
    t = 2
    mesgl = GetUTF8Text("id_common_CC")
  elseif ui.reset_skill_costCB_3.Check then
    t = 3
    mesgl = GetUTF8Text("id_common_Medal")
  elseif ui.reset_skill_costCB_4.Check then
    t = 4
    mesgl = GetUTF8Text("id_common_Ticket")
  end
  local mesg = string.format(GetUTF8Text(textKey), skillCostTb[t], mesgl)
  if whereType == 3 or whereType == 4 or whereType == 5 then
    mesg = GetMatchedUTF8Text(string.format("%s,%d,%s", textKey, skillCostTb[t], mesgl))
  end
  if whereType ~= 3 and not skillCostTb[1] and not skillCostTb[2] and not skillCostTb[3] and skillCostTb[4] then
    mesg = string.format(GetUTF8Text("msgbox_common_num_1361"), 3)
  end
  MessageBox.ShowWithConfirmCancel(mesg, function(sender, e)
    if whereType == 1 then
      ui.btn_skill_reset.Enable = false
      rpc_skill_reset(t)
      rpc_skill_list()
      rpc_slot_get()
    elseif whereType == 2 then
      rpc.safecall("storage_expand", {
        t = depotCurr + 1,
        c = t
      }, DealAddBag)
    elseif whereType == 3 then
      if SysPetsData and SelectedPetSlot and SelectedCandidate and SysPetsData[SelectedCandidate] then
        local pet_sysid = SysPetsData[SelectedCandidate].id
        local priceId = GetSysPetPriceID(t)
        if 0 <= priceId then
          rpc_player_pet_buy(SelectedPetSlot, pet_sysid, priceId)
        end
      end
    elseif whereType == 4 then
      if PlayerPetsData and SelectedPetSlot and PlayerPetsData[SelectedPetSlot] then
        local pet_id = PlayerPetsData[SelectedPetSlot].id
        rpc_player_pet_placate(pet_id, t)
      end
    elseif whereType == 5 then
      if PlayerPetsData and SelectedPetSlot and PlayerPetsData[SelectedPetSlot] then
        local pet_id = PlayerPetsData[SelectedPetSlot].id
        rpc_player_pet_skill_upgrade(pet_id, t)
      end
    elseif whereType == 6 then
      rpc_player_pet_slot_expand(t)
    end
  end, nil, true)
  HideResetSkillCost()
end

function ui.reset_skill_canc.EventClick(sender, e)
  HideResetSkillCost()
end

for i = 1, 4 do
  ui["reset_skill_costCB_" .. i].EventCheckChanged = function(sender, e)
    if "kTriggerMouse" == e.Trigger then
      for k = 1, 4 do
        ui["reset_skill_costCB_" .. k].Check = i == k
      end
    end
  end
end
for i = 1, 4 do
  ui["pet_rename_costCB_" .. i].EventCheckChanged = function(sender, e)
    if "kTriggerMouse" == e.Trigger then
      for k = 1, 4 do
        ui["pet_rename_costCB_" .. k].Check = i == k
      end
    end
  end
end
for i = 1, 4 do
  ui["pet_slot_expand_costCB_" .. i].EventCheckChanged = function(sender, e)
    if "kTriggerMouse" == e.Trigger then
      for k = 1, 4 do
        ui["pet_slot_expand_costCB_" .. k].Check = i == k
      end
    end
  end
end

function ui.useLucyReel.EventCheckChanged(sender, e)
  ComputeWeaponEnhanceBar()
end

local ui.useInheritAtri.EventCheckChanged, SetChangeNameSure = function(sender, e)
  if ui.useInheritAtri.Check then
    MessageBox.ShowWithTwoButtons(GetUTF8Text("UI_lobby_transform_tips"), GetUTF8Text("button_common_OK"))
  end
  ComputeWeaponEnhanceBar()
end, ui.useInheritAtri

function SetChangeNameSure()
  MessageBox.ShowWithConfirmCancel(GetUTF8Text("msgbox_store_rename_confirm"), function(sender, e)
    rpc.safecall("name_modify", {
      itemId = menDt.pid,
      newName = NameCreate.GetInputName()
    }, function(data)
      rpc_storage_storage_list(ui.pb_depot.CurrIndex)
      Lobby.rpc_player_detail(true)
      HideChangeRoleName()
      MessageBox.ShowError(GetUTF8Text("msgbox_store_rename_over"))
    end)
  end)
end

local inputNameInfo = {
  title = GetUTF8Text("id_datalist_rename_card"),
  tips = GetUTF8Text("UI_store_rename_please_enter_new_name"),
  funcSure = SetChangeNameSure
}
MenuItemUnbindId = "IDC_MENU_UNBIND"
MenuItemUnlockId = "IDC_MENU_UNLOCK"
MenuItemLockId = "IDC_MENU_LOCK"
MenuItemWaitUnbindId = "IDC_MENU_WAIT_UNBIND"
ui["menu_" .. 1]:AddItem(GetUTF8Text("button_common_Disassemble"))
ui["menu_" .. 1]:AddItem(GetUTF8Text("button_common_Enhance_Right_Menu"))
ui["menu_" .. 1]:AddItem(GetUTF8Text("button_common_Preview_at_once"))
ui["menu_" .. 2]:AddItem(GetUTF8Text("button_common_Disassemble"))
ui["menu_" .. 2]:AddItem(GetUTF8Text("button_common_Split"))
ui["menu_" .. 2]:AddItem(GetUTF8Text("UI_mission_Quest_Name_1017"))
ui["menu_" .. 3]:AddItem(GetUTF8Text("button_lobby_equipment_button"))
ui["menu_" .. 3]:AddItem(GetUTF8Text("button_common_Drill_and_Embed"))
ui["menu_" .. 4]:AddItem(GetUTF8Text("button_common_Disassemble"))
ui["menu_" .. 4]:AddItem(GetUTF8Text("button_common_Split"))
ui["menu_" .. 5]:AddItem(GetUTF8Text("button_common_Disassemble"))
ui["menu_" .. 5]:AddItem(GetUTF8Text("button_lobby_equipment_button"))
ui["menu_" .. 5]:AddItem(GetUTF8Text("button_common_Preview_at_once"))
ui["menu_" .. 6]:AddItem(GetUTF8Text("button_common_Disassemble"))
ui["menu_" .. 6]:AddItem(GetUTF8Text("button_lobby_equipment_button"))
ui["menu_" .. 6]:AddItem(GetUTF8Text("button_common_Preview_at_once"))
ui["menu_" .. 7]:AddItem(GetUTF8Text("button_common_Disassemble"))
ui["menu_" .. 7]:AddItem(GetUTF8Text("button_lobby_equipment_button"))
ui["menu_" .. 7]:AddItem(GetUTF8Text("button_common_Preview_at_once"))
ui["menu_" .. 8]:AddItem(GetUTF8Text("button_common_Disassemble"))
ui["menu_" .. 8]:AddItem(GetUTF8Text("button_common_Preview_at_once"))
ui["menu_" .. 9]:AddItem(GetUTF8Text("button_common_Disassemble"))
ui["menu_" .. 9]:AddItem(GetUTF8Text("button_common_Preview_at_once"))
ui["menu_" .. 10]:AddItem(GetUTF8Text("button_common_Disassemble"))
ui["menu_" .. 10]:AddItem(GetUTF8Text("button_common_Split"))
ui["menu_" .. 10]:AddItem(GetUTF8Text("button_common_Open_Chest"))
ui["menu_" .. 11]:AddItem(GetUTF8Text("button_common_Disassemble"))
ui["menu_" .. 11]:AddItem(GetUTF8Text("button_common_Split"))
ui["menu_" .. 11]:AddItem(GetUTF8Text("button_common_Use"))
ui["menu_" .. 12]:AddItem(GetUTF8Text("button_common_Disassemble"))
ui["menu_" .. 12]:AddItem(GetUTF8Text("button_common_Split"))
ui["menu_" .. 12]:AddItem(GetUTF8Text("button_common_Use"))
ui["menu_" .. 13]:AddItem(GetUTF8Text("button_common_Disassemble"))
ui["menu_" .. 13]:AddItem(GetUTF8Text("button_common_Split"))
ui["menu_" .. 13]:AddItem(GetUTF8Text("button_common_Use"))
ui["menu_" .. 14]:AddItem(GetUTF8Text("button_common_Disassemble"))
ui["menu_" .. 14]:AddItem(GetUTF8Text("button_common_Split"))
ui["menu_" .. 14]:AddItem(GetUTF8Text("tips_datalist_gift_open"))
ui["menu_" .. 15]:AddItem(GetUTF8Text("button_common_Disassemble"))
ui["menu_" .. 15]:AddItem(GetUTF8Text("button_common_Split"))
ui["menu_" .. 15]:AddItem(GetUTF8Text("tips_datalist_avatarroom_tips_link"))
ui["menu_" .. 16]:AddItem(GetUTF8Text("button_common_Disassemble"))
ui["menu_" .. 16]:AddItem(GetUTF8Text("button_common_Split"))
ui["menu_" .. 16]:AddItem(GetUTF8Text("button_common_Use"))
ui.menu_17:AddItem(GetUTF8Text("UI_pet_disband_01"))
ui["menu_" .. 18]:AddItem(GetUTF8Text("button_common_Disassemble"))
ui["menu_" .. 18]:AddItem(GetUTF8Text("button_common_Split"))
ui["menu_" .. 18]:AddItem(GetUTF8Text("UI_common_make_08"))
ui["menu_" .. 19]:AddItem(GetUTF8Text("button_common_Disassemble"))
ui["menu_" .. 19]:AddItem(GetUTF8Text("button_common_Split"))
ui["menu_" .. 19]:AddItem(GetUTF8Text("tips_datalist_gift_open"))
for i = 1, 19 do
  ui["menu_" .. i]:Close()
  ui["menu_" .. i].EventOpen = function(sender, e)
    ComFuc.hasRightMenu = true
  end
  ui["menu_" .. i].EventClose = function(sender, e)
    ComFuc.hasRightMenu = false
  end
  ui["menu_" .. i].EventClick = function(sender, e)
    local t = sender.SelectedIndex
    local p = menDt
    if i == 1 then
      if t == 0 then
        SetDecomposition()
      elseif t == 1 then
        Lobby.OnComSwitch(7)
        SelReinforceBtn(3)
        menDt = p
        refitMoveDir = 0
        rpc_refit_need()
      elseif t == 2 then
        gui:PlayAudio("putdown")
        lg:SetWeapon(menDt.subtype, menDt.resource, menDt.refitLevel or 0, false)
      end
    elseif i == 2 then
      if t == 0 then
        SetDecomposition()
      elseif t == 1 then
        ShowDestructNum(GetUTF8Text("msgbox_common_num_1364"), Vector2(0, 0))
      elseif t == 2 then
        Lobby.OnComSwitch(7)
        SelReinforceBtn(2)
        menDt = p
        ReinMedalUp()
      end
    elseif i == 3 then
      if t == 0 then
        if menDt.unitType and (menDt.unitType == 2 or menDt.unitType == 3 or menDt.unitType == 4 or menDt.unitType == 5) and menDt.unit and 0 >= menDt.unit then
          MessageBox.ShowError(GetUTF8Text("msgbox_enhance_additional_string_148"))
        else
          gui:PlayAudio("buyavatar")
          isDoEquip = true
          ShowPersonCard(menDt)
        end
      elseif t == 1 then
        Lobby.OnComSwitch(7)
        SelReinforceBtn(1)
        menDt = p
        ShowReinPersonCard(menDt, ui["person_card_s_" .. menDt.slot].ID)
      end
    elseif i == 4 then
      if t == 0 then
        SetDecomposition()
      elseif t == 1 then
        ShowDestructNum(GetUTF8Text("msgbox_common_num_1364"), Vector2(0, 0))
      end
    elseif i == 5 then
      if t == 0 then
        SetDecomposition()
      elseif t == 1 then
        if menDt.unitType and (menDt.unitType == 2 or menDt.unitType == 3 or menDt.unitType == 4 or menDt.unitType == 5) and menDt.unit and 0 >= menDt.unit then
          MessageBox.ShowError(GetUTF8Text("msgbox_enhance_additional_string_148"))
        else
          gui:PlayAudio("putdown")
          ShowIdentEquip(menDt, menDt.slot, 6, 4)
        end
      elseif t == 2 then
        lg:SetWeapon(0, "")
        lg:Set_Independent_Trinket(4, menDt.resource, false, 5)
      end
    elseif i == 6 then
      if t == 0 then
        SetDecomposition()
      elseif t == 1 then
        if menDt.unitType and (menDt.unitType == 2 or menDt.unitType == 3 or menDt.unitType == 4 or menDt.unitType == 5) and menDt.unit and 0 >= menDt.unit then
          MessageBox.ShowError(GetUTF8Text("msgbox_enhance_additional_string_148"))
        else
          gui:PlayAudio("putdown")
          ShowIdentEquip(menDt, menDt.slot, 4, 1, true)
        end
      elseif t == 2 then
        lg:SetWeapon(0, "")
        lg:Set_Independent_Trinket(1, menDt.resource, false, 5)
      end
    elseif i == 7 then
      if t == 0 then
        SetDecomposition()
      elseif t == 1 then
        if menDt.unitType and (menDt.unitType == 2 or menDt.unitType == 3 or menDt.unitType == 4 or menDt.unitType == 5) and menDt.unit and 0 >= menDt.unit then
          MessageBox.ShowError(GetUTF8Text("msgbox_enhance_additional_string_148"))
        else
          gui:PlayAudio("putdown")
          ShowIdentEquip(menDt, menDt.slot, 3, 3)
        end
      elseif t == 2 then
        gui:PlayAudio("putdown")
        lg:SetWeapon(0, "")
        lg:Set_Independent_Trinket(3, menDt.resource, false, 5)
      end
    elseif i == 8 then
      if t == 0 then
        SetDecomposition()
      elseif t == 1 then
        gui:PlayAudio("button")
        lg:PlayAnim(menDt.resource, false, 0.2, 0.2)
      end
    elseif i == 9 then
      if t == 0 then
        SetDecomposition()
      elseif t == 1 then
        gui:PlayAudio("putdown")
        lg:SetWeapon(menDt.subtype, menDt.resource, menDt.refitLevel or 0, false)
      end
    elseif i == 10 then
      if t == 0 then
        SetDecomposition()
      elseif t == 1 then
        ShowDestructNum(GetUTF8Text("msgbox_common_num_1364"), Vector2(0, 0))
      elseif t == 2 then
        OpenBox.Show(menDt.category, menDt.pid, menDt.quantity)
      end
    elseif i == 11 then
      if t == 0 then
        SetDecomposition()
      elseif t == 1 then
        ShowDestructNum(GetUTF8Text("msgbox_common_num_1364"), Vector2(0, 0))
      elseif t == 2 then
        gui:PlayAudio("prompt_tutorial_b")
        rpc.safecall("use_card", {
          pid = menDt.pid
        }, function(data)
          rpc_storage_storage_list(ui.pb_depot.CurrIndex)
          Lobby.rpc_player_detail(true)
          rpc_player_info()
        end)
      end
    elseif i == 12 then
      if t == 0 then
        SetDecomposition()
      elseif t == 1 then
        ShowDestructNum(GetUTF8Text("msgbox_common_num_1364"), Vector2(0, 0))
      elseif t == 2 then
        gui:PlayAudio("prompt_tutorial_b")
        ShowLoundSpeaker()
      end
    elseif i == 13 then
    elseif i == 14 then
      if t == 0 then
        SetDecomposition()
      elseif t == 1 then
        ShowDestructNum(GetUTF8Text("msgbox_common_num_1364"), Vector2(0, 0))
      elseif t == 2 then
        SetDecomposition(1)
      end
    elseif i == 15 then
      if t == 0 then
        SetDecomposition()
      elseif t == 1 then
        ShowDestructNum(GetUTF8Text("msgbox_common_num_1364"), Vector2(0, 0))
      elseif t == 2 then
        Lobby.MainBtnSelect(6)
      end
    elseif i == 16 then
      if t == 0 then
        SetDecomposition()
      elseif t == 1 then
        ShowDestructNum(GetUTF8Text("msgbox_common_num_1364"), Vector2(0, 0))
      elseif t == 2 then
        gui:PlayAudio("prompt_tutorial_b")
        if not NameCreate then
          require("nameCreate.lua")
        end
        NameCreate.Show(inputNameInfo)
      end
    elseif i == 17 then
      if ToBeDeletePetSlot and PlayerPetsData and PlayerPetsData[ToBeDeletePetSlot] then
        local pop_msg1 = GetMatchedUTF8Text(string.format("button_pet_clew_09,%s", ComFuc.GetPetDisplayName(PlayerPetsData[ToBeDeletePetSlot].name)))
        local pop_msg2 = GetUTF8Text("button_pet_clew_10")
        MessageBox.ShowWithConfirmCancel(pop_msg1, function(sender, e)
          if PlayerPetsData[ToBeDeletePetSlot].grade > 3 then
            MessageBox.ShowWithConfirmCancel(pop_msg2, function(sender, e)
              rpc_player_pet_del(ToBeDeletePetSlot)
            end)
          else
            rpc_player_pet_del(ToBeDeletePetSlot)
          end
        end)
      end
    elseif i == 18 then
      if t == 0 then
        SetDecomposition()
      elseif t == 1 then
        ShowDestructNum(GetUTF8Text("msgbox_common_num_1364"), Vector2(0, 0))
      elseif t == 2 then
        rpc.safecall("blueprint_learn", {
          pid = menDt.pid
        }, function(data)
          ReinSuccess()
        end)
        rpc_storage_storage_list(ui.pb_depot.CurrIndex)
      end
    elseif i == 19 then
      if t == 0 then
        SetDecomposition()
      elseif t == 1 then
        ShowDestructNum(GetUTF8Text("msgbox_common_num_1364"), Vector2(0, 0))
      elseif t == 2 then
        rpc.safecall("item_book_open", {
          playerItemId = menDt.pid
        }, OpenBook)
      end
    end
    local id = sender:GetId(t)
    if id == MenuItemUnbindId then
      gui:PlayAudio("prompt")
      UnbindDetailData = nil
      rpc.safecall("item_unbind_detail", {
        playerItemId = menDt.pid
      }, DealItemUnbindDetail)
    elseif id == MenuItemUnlockId then
      gui:PlayAudio("prompt")
      if not LockItem then
        require("lockItem.lua")
      end
      LockItem.LockDetailData = nil
      rpc.safecall("item_lock_detail", nil, DealItemUnlockDetail)
    elseif id == MenuItemLockId then
      gui:PlayAudio("prompt")
      if not LockItem then
        require("lockItem.lua")
      end
      LockItem.UnlockDetailData = nil
      rpc.safecall("item_lock_detail", nil, DealItemLockDetail)
    elseif id == MenuItemWaitUnbindId then
      gui:PlayAudio("prompt")
      if not LockItem then
        require("lockItem.lua")
      end
      rpc.safecall("player_item_lock", {
        pid = menDt.pid,
        l = 0,
        t = depotCurr + 1,
        lockState = menDt.isLock
      }, DealItemWaitUnbindtail)
    end
  end
end
for i = 2, 4 do
  ui["btn_main_" .. i].EventClick = function(sender, e)
    SelMainBtn(i)
  end
end
for i = 1, 4 do
  ui["btn_depot_" .. i].EventClick = function(sender, e)
    SelDepotBtn(i)
  end
end
for i = 1, 6 do
  ui["btn_reinforce_" .. i].EventClick = function(sender, e)
    SelReinforceButton(i)
  end
end
for i = 1, 5 do
  ui["skill_b_" .. i].EventMouseDown = function(sender, e)
    if sklDt[i].isActive == "Y" then
      local s, l, c = GetMoveMesg(sender)
      if sender.IsCapture then
        LighterOrNarmal(true, 1, 2)
        ShowMoveControl(s, l, resDir, sklDt[i].resource)
        ForceLeadSkillLearn(FORCE_LEAD_SKILLLEARN_PLACE)
      else
        SkillUp(i, c)
      end
    end
  end
  ui["skill_b_" .. i].EventMouseMove = function(sender, e)
    OnMouseMove(sender)
  end
  ui["skill_b_" .. i].EventMouseUp = function(sender, e)
    SkillUp(i, sender.CurrentCursorPosition)
  end
end
local dealMouseUp = {
  WeaponUp,
  PropUp,
  PoseUp
}
for i = 1, 24 do
  ui["weapon_b_" .. i].EventMouseDown = function(sender, e)
    if dptDt[i] and dptDt[i].isEquip == "N" then
      local s, l, c = GetMoveMesg(sender)
      if sender.IsCapture then
        SwitchALLLighter(depotCurr, true, 2, dptDt[i].subtype, ComFuc.hasWeaponCount)
        if depotCurr == 2 and NewLead.leadVisible then
          ForceLeadEasyUse(FORCE_LEAD_EASYUSE_PLACE)
        elseif depotCurr == 1 then
          ForceLeadShopCheck(FORCE_LEAD_SHOP_PLACE)
        end
        local resname = ComFuc.DoWingRes(dptDt[i].resource, dptDt[i].subtype, 102, depotCurr)
        ShowMoveControl(s, l, resDir, resname, dptDt[i].grade)
      else
        dealMouseUp[depotCurr](i, c)
      end
    end
  end
  ui["weapon_b_" .. i].EventMouseMove = function(sender, e)
    OnMouseMove(sender)
  end
  ui["weapon_b_" .. i].EventMouseUp = function(sender, e)
    dealMouseUp[depotCurr](i, sender.CurrentCursorPosition)
  end
  ui["weapon_b_" .. i].EventRightClick = function(sender, e)
    if dptDt and dptDt[i] then
      Tip.SetOwner(nil)
      menDt = dptDt[i]
      SwitchAllMenu(depotCurr, sender.CurrentCursorPosition, dptDt[i].subtype, dptDt[i].isEquip == "Y", dptDt[i].category, dptDt[i].quantity <= 1, dptDt[i].canUnbind == "Y", dptDt[i].isBind == "Y", dptDt[i].isLock)
    end
  end
end
for i = 1, 10 do
  ui["person_card_b_" .. i].EventMouseDown = function(sender, e)
    if dptDt[i] and dptDt[i].isEquip == "N" then
      local s, l, c = GetMoveMesg(sender)
      if sender.IsCapture then
        LighterOrNarmal(true, 2, 0, 2, 2)
        ShowMoveCard(s, l, ui["person_card_s_" .. i], dptDt[i].grade, AvtarStype[i])
      else
        PersonUp(i, c)
      end
    end
  end
  ui["person_card_b_" .. i].EventMouseMove = function(sender, e)
    OnMouseMove(sender, true)
  end
  ui["person_card_b_" .. i].EventMouseUp = function(sender, e)
    PersonUp(i, sender.CurrentCursorPosition)
  end
  ui["person_card_b_" .. i].EventRightClick = function(sender, e)
    if dptDt and dptDt[i] then
      Tip.SetOwner(nil)
      menDt = dptDt[i]
      ShowMenu(3, sender.CurrentCursorPosition, dptDt[i].isEquip == "Y", true, nil, nil, nil, menDt.isLock)
    end
  end
end
for i = 1, 12 do
  ui["hot_key_b_" .. i].EventMouseDown = function(sender, e)
    if htkDt[i] and htkDt[i].type and htkDt[i].type ~= 0 then
      local s, l, c = GetMoveMesg(sender)
      if sender.IsCapture then
        LighterOrNarmal(true, 1, 2)
        ShowMoveControl(s, l, resDir, htkDt[i].resource, htkDt[i].grade)
      else
        HotKeyUp(i, c)
        rpc_player_battle_force_get()
      end
    end
  end
  ui["hot_key_b_" .. i].EventMouseMove = function(sender, e)
    OnMouseMove(sender)
  end
  ui["hot_key_b_" .. i].EventMouseUp = function(sender, e)
    HotKeyUp(i, sender.CurrentCursorPosition)
    rpc_player_battle_force_get()
  end
  ui["hot_key_b_" .. i].EventRightClick = function(sender, e)
    if htkDt[i] and htkDt[i].type and htkDt[i].type ~= 0 then
      gui:PlayAudio("cancel")
      if ComFuc.isReadyStart or ComFuc.isReadyMatch then
        MessageBox.ShowError(GetUTF8Text("tips_common_operation_forbidden"))
        return
      end
      if htkDt[i].type >= 2 then
        rpc_slot_unequip(i)
        rpc_storage_storage_list(ui.pb_depot.CurrIndex)
        rpc_slot_get()
        if htkDt[i].type == 2 then
          rpc_player_battle_force_get()
        end
      elseif tonumber(htkDt[i].type) == 1 or tonumber(htkDt[i].type) == 10 then
        rpc_skill_unequip(i)
        rpc_slot_get()
      end
    end
  end
end
local HighlightPetOpSlot, DragToPetOpSlot = function(bHighlight)
  for i = 1, 5 do
    ui["pet_op_slot_c_" .. i].IsBegin = bHighlight
    ui["pet_op_slot_c_" .. i].IsReady = bHighlight
    if bHighlight then
      ui["pet_op_slot_c_" .. i].Skin = SkinF.personalInfo_210
      ui["pet_op_slot_c_" .. i].BackgroundColor = colw
    else
      ui["pet_op_slot_c_" .. i].Skin = SkinF.skin_touming
      ui["pet_op_slot_c_" .. i].BackgroundColor = col0
    end
  end
end, function(bHighlight)
  for i = 1, 5 do
    ui["pet_op_slot_c_" .. i].IsBegin = bHighlight
    ui["pet_op_slot_c_" .. i].IsReady = bHighlight
    if bHighlight then
      ui["pet_op_slot_c_" .. i].Skin = SkinF.personalInfo_210
      ui["pet_op_slot_c_" .. i].BackgroundColor = colw
    else
      ui["pet_op_slot_c_" .. i].Skin = SkinF.skin_touming
      ui["pet_op_slot_c_" .. i].BackgroundColor = col0
    end
  end
end

function DragToPetOpSlot(c, iSourceIndex, dragSource)
  local result_slot = -1
  for i = 1, #CurrentPetOpSettings do
    if IsInAABB(c, Vector2(594, 130 + 96 * i), Vector2(80, 80)) then
      result_slot = i
      if dragSource == 1 then
        CurrentPetOpSettings[i].playerPackSlot = iSourceIndex
        CurrentPetOpSettings[i].isActive = 1
        FillUpPetOpBar(i)
      elseif dragSource == 2 then
        local target_previous_slot = CurrentPetOpSettings[i].playerPackSlot
        CurrentPetOpSettings[i].playerPackSlot = CurrentPetOpSettings[iSourceIndex].playerPackSlot
        CurrentPetOpSettings[i].isActive = 1
        CurrentPetOpSettings[iSourceIndex].playerPackSlot = target_previous_slot
        FillUpPetOpBar(i)
        FillUpPetOpBar(iSourceIndex)
      end
    end
  end
  return result_slot
end

function DragEndPetOpSlot(iIndex, cursorPos, dragSource)
  gui:PlayAudio("putdown")
  HighlightPetOpSlot(false)
  local isWeapon = false
  if dragSource == 1 and htkDt[iIndex].type == 2 then
    isWeapon = true
  end
  if dragSource == 2 and htkDt[CurrentPetOpSettings[iIndex].playerPackSlot] and htkDt[CurrentPetOpSettings[iIndex].playerPackSlot].type == 2 then
    isWeapon = true
  end
  if not isWeapon then
    if ptr_cast(game.CurrentState, "Client.StateLobby") then
      local result_slot = DragToPetOpSlot(cursorPos, iIndex, dragSource)
      if result_slot <= 0 and dragSource == 2 then
        CurrentPetOpSettings[iIndex].playerPackSlot = -1
        FillUpPetOpBar(iIndex)
        if SelectedPetSlot and PlayerPetsData and PlayerPetsData[SelectedPetSlot] then
          rpc_player_pet_custom_skill_update(PlayerPetsData[SelectedPetSlot].id, iIndex, CurrentPetOpSettings[iIndex])
        end
      end
      if 0 < result_slot then
        rpc_player_pet_custom_skill_update(PlayerPetsData[SelectedPetSlot].id, result_slot, CurrentPetOpSettings[result_slot])
        if dragSource == 2 then
          rpc_player_pet_custom_skill_update(PlayerPetsData[SelectedPetSlot].id, iIndex, CurrentPetOpSettings[iIndex])
        end
      end
    end
  else
    MessageBox.ShowError(GetUTF8Text("msgbox_pet_skill_cue_01"))
  end
  ui.moveControl.Parent = nil
end

for i = 1, 12 do
  ui["pet_op_hotkey_b_" .. i].EventMouseDown = function(sender, e)
    if htkDt[i] and htkDt[i].type and htkDt[i].type ~= 0 then
      local s, l, c = GetMoveMesg(sender)
      l = l + Vector2(222, 184)
      c = c + Vector2(222, 184)
      if sender.IsCapture then
        HighlightPetOpSlot(true)
        ShowMoveControl(s, l, "/ui/skinF/", "skin_pet_icon11", nil)
      else
        DragEndPetOpSlot(i, c, 1)
      end
    end
  end
  ui["pet_op_hotkey_b_" .. i].EventMouseMove = function(sender, e)
    OnMouseMove(sender)
    ui.moveControl.Location = ui.moveControl.Location + Vector2(222, 184)
  end
  ui["pet_op_hotkey_b_" .. i].EventMouseUp = function(sender, e)
    DragEndPetOpSlot(i, sender.CurrentCursorPosition + Vector2(222, 184), 1)
  end
end
for i = 1, 5 do
  ui["pet_op_slot_b_" .. i].EventMouseDown = function(sender, e)
    if CurrentPetOpSettings[i].playerPackSlot and CurrentPetOpSettings[i].playerPackSlot > 0 and CurrentPetOpSettings[i].playerPackSlot < 13 then
      local s, l, c = GetMoveMesg(sender)
      l = l + Vector2(222, 184)
      c = c + Vector2(222, 184)
      if sender.IsCapture then
        HighlightPetOpSlot(true)
        ShowMoveControl(s, l, "/ui/skinF/", "skin_pet_icon11", nil)
      else
        DragEndPetOpSlot(i, c, 2)
      end
    end
  end
  ui["pet_op_slot_b_" .. i].EventMouseMove = function(sender, e)
    OnMouseMove(sender)
    ui.moveControl.Location = ui.moveControl.Location + Vector2(222, 184)
  end
  ui["pet_op_slot_b_" .. i].EventMouseUp = function(sender, e)
    DragEndPetOpSlot(i, sender.CurrentCursorPosition + Vector2(222, 184), 2)
  end
end

function ui.btn_create_new_pet.EventClick(sender, e)
  if SysPetsData and SelectedPetSlot and SelectedCandidate and SysPetsData[SelectedCandidate] then
    local pet_sysid = SysPetsData[SelectedCandidate].id
    local pet_is_royal = SysPetsData[SelectedCandidate].isNoble == "Y"
    local pet_price = SysPetsData[SelectedCandidate].price
    local popupmsg = GetUTF8Text("button_pet_clew_01")
    if pet_is_royal then
      currentSysPetPrice = {}
      for i, v in ipairs(pet_price) do
        currentSysPetPrice[v.currency] = v.price
      end
      ShowResetSkillCost(3)
    else
      MessageBox.ShowWithConfirmCancel(popupmsg, function(sender, e)
        rpc_player_pet_buy(SelectedPetSlot, pet_sysid, 1)
      end)
    end
  end
end

ui.btn_pet_list_previous_page.Enable = false
ui.btn_pet_list_next_page.Enable = false

function ui.btn_pet_list_previous_page.EventClick(sender, e)
  if CurrentPlayerPetPage > 1 then
    rpc_player_pet_list(CurrentPlayerPetPage - 1)
  end
end

function ui.btn_pet_list_next_page.EventClick(sender, e)
  if CurrentPlayerPetPage < TotalPlayerPetPage then
    rpc_player_pet_list(CurrentPlayerPetPage + 1)
  end
end

function ui.page_bar_sys_pet.EventIndexChanged(sender, e)
  rpc_sys_pet_list(ui.page_bar_sys_pet.CurrIndex)
end

ui.btn_pet_slot_expand.Hint = GetUTF8Text("msgbox_pet_add_01")

function ui.btn_pet_slot_expand.EventClick(sender, e)
  ShowPetSlotExpandUI()
end

for i = 1, 5 do
  ui["pet_slot_btn_" .. i].EventClick = function(sender, e)
    local slot_i = i + (CurrentPlayerPetPage - 1) * 5
    ChangePetSlotSelection(slot_i)
  end
  ui["pet_slot_btn_" .. i].EventRightClick = function(sender, e)
    local seq_i = i + (CurrentPlayerPetPage - 1) * 5
    if PlayerPetsData and PlayerPetsData[seq_i] then
      ToBeDeletePetSlot = seq_i
      Tip.SetOwner(nil)
      SwitchAllMenu(4, sender.CurrentCursorPosition)
    end
  end
end
for i = 1, 5 do
  ui["pet_cand_btn_" .. i].EventClick = function(sender, e)
    if SysPetsData[i] then
      ChangePetCandidateSelection(i)
    end
  end
end

function ui.pet_op_setting.EventClick(sender, e)
  ui.pet_coverControl.Parent = gui
  ui.pet_op_ui_main.Parent = gui
end

function ui.pet_op_close.EventClick(sender, e)
  HidePetOpUI()
end

function ui.btn_pet_skill_setting.EventClick(sender, e)
  if CurrentPetSkillData then
    if CurrentPetSkillData.isMaximum == "Y" then
      ui.pet_coverControl.Parent = gui
      ui.pet_skill_ui_main.Parent = gui
    else
      ShowResetSkillCost(5)
    end
  end
end

function ui.pet_skill_close.EventClick(sender, e)
  HidePetSkillUI()
end

function ui.pet_skill_upgrade_cancel_btn.EventClick(sender, e)
  HidePetSkillUI()
end

for i = 1, 5 do
  ui["pet_op_on_off_" .. i].EventClick = function(sender, e)
    if CurrentPetOpSettings[i].isActive == 1 then
      CurrentPetOpSettings[i].isActive = 0
    else
      CurrentPetOpSettings[i].isActive = 1
    end
    if SelectedPetSlot and PlayerPetsData and PlayerPetsData[SelectedPetSlot] then
      rpc_player_pet_custom_skill_update(PlayerPetsData[SelectedPetSlot].id, i, CurrentPetOpSettings[i])
    end
  end
  ui["pet_op_condition_" .. i].EventItemSelected = function(sender, e)
    local condition_index = ui["pet_op_condition_" .. i].SelectedIndex
    if 0 <= condition_index then
      CurrentPetOpSettings[i].sysPetCustomSkillId = CurrentPetOpConditions[condition_index + 1].id
      if SelectedPetSlot and PlayerPetsData and PlayerPetsData[SelectedPetSlot] then
        rpc_player_pet_custom_skill_update(PlayerPetsData[SelectedPetSlot].id, i, CurrentPetOpSettings[i])
      end
    end
  end
end

function EnablePetOpBar(iIndex, bEnable)
  if 0 < iIndex and iIndex < 6 then
    ClearPetOpBar(iIndex)
    ui["pet_op_on_off_" .. iIndex].Enable = bEnable
    ui["pet_op_condition_" .. iIndex].Enable = bEnable
    ui["pet_op_slot_b_" .. iIndex].Enable = bEnable
    ui["pet_op_slot_c_" .. iIndex].Enable = bEnable
    ui["pet_op_slot_h_" .. iIndex].Enable = bEnable
    ui["pet_op_slot_bs_" .. iIndex].Visible = not bEnable
    ui["pet_op_slot_l_" .. iIndex].Visible = false
    ui["pet_op_slot_bg_" .. iIndex].Visible = false
    ui["pet_op_show_lock_" .. iIndex].Visible = not bEnable
    if bEnable then
      ui["pet_op_hint_" .. iIndex].Text = GetUTF8Text("UI_pet_ply")
      ui["pet_op_hint_" .. iIndex].TextColor = ARGB(255, 82, 54, 44)
    else
      ui["pet_op_hint_" .. iIndex].Text = GetUTF8Text("UI_lobby_pet_account_for_04")
      ui["pet_op_hint_" .. iIndex].TextColor = ARGB(255, 100, 100, 100)
    end
  end
end

for i = 1, 5 do
  ui["reinPerson_card_b_" .. i].EventMouseDown = function(sender, e)
    remove_stone_of_avatar_id = dptDt2[i].pid
    local s, l, c = GetMoveMesg(sender)
    if sender.IsCapture then
      LighterOrNarmal(true, 3)
      ShowMoveCard(s, l, ui["reinPerson_card_s_" .. i], dptDt2[i].grade, AvtarStype[i])
    else
      ReinPersonUp(i, c)
    end
  end
  ui["reinPerson_card_b_" .. i].EventMouseMove = function(sender, e)
    OnMouseMove(sender, true)
  end
  ui["reinPerson_card_b_" .. i].EventMouseUp = function(sender, e)
    ReinPersonUp(i, sender.CurrentCursorPosition)
  end
  ui["reinPerson_card_b_" .. i].EventRightClick = function(sender, e)
    ReinPersonUp(i)
    remove_stone_of_avatar_id = dptDt2[i].pid
  end
end
for i = 1, 12 do
  ui["reinStone_b_" .. i].EventMouseDown = function(sender, e)
    if dptDt[i] and dptDt[i].quantity >= 1 and (dptDt[i].subtype == 302 or dptDt[i].subtype == 303) then
      local s, l, c = GetMoveMesg(sender)
      if sender.IsCapture then
        LighterOrNarmal(true, 4)
        ShowMoveControl(s, l, resDir, dptDt[i].resource, dptDt[i].grade)
      else
        ReinStoneUp(i, c)
      end
    end
  end
  ui["reinStone_b_" .. i].EventMouseMove = function(sender, e)
    OnMouseMove(sender)
  end
  ui["reinStone_b_" .. i].EventMouseUp = function(sender, e)
    ReinStoneUp(i, sender.CurrentCursorPosition)
  end
end
for i = 1, 36 do
  ui["reinMedal_b_" .. i].EventMouseDown = function(sender, e)
    if dptDt[i] and dptDt[i].quantity >= 1 then
      local s, l, c = GetMoveMesg(sender)
      if sender.IsCapture then
        LighterOrNarmal(true, 5)
        ShowMoveControl(s, l, resDir, dptDt[i].resource, dptDt[i].grade)
      else
        ReinMedalUp(i, c)
      end
    end
  end
  ui["reinMedal_b_" .. i].EventMouseMove = function(sender, e)
    OnMouseMove(sender)
  end
  ui["reinMedal_b_" .. i].EventMouseUp = function(sender, e)
    ReinMedalUp(i, sender.CurrentCursorPosition)
  end
  ui["reinMedal_b_" .. i].EventRightClick = function(sender, e)
    if dptDt[i] and dptDt[i].quantity >= 1 then
      ReinMedalUp(i)
    end
  end
end
for i = 1, 12 do
  ui["reinWeapon_b_" .. i].EventMouseDown = function(sender, e)
    if dptDt[i] and dptDt[i].quantity >= 1 then
      local s, l, c = GetMoveMesg(sender)
      if sender.IsCapture then
        LighterOrNarmal(true, 6)
        ShowMoveControl(s, l, resDir, dptDt[i].resource, dptDt[i].grade)
      else
        ReinWeaponUp(i, c)
      end
    end
  end
  ui["reinWeapon_b_" .. i].EventMouseMove = function(sender, e)
    OnMouseMove(sender)
  end
  ui["reinWeapon_b_" .. i].EventMouseUp = function(sender, e)
    ReinWeaponUp(i, sender.CurrentCursorPosition)
  end
  ui["reinWeapon_b_" .. i].EventRightClick = function(sender, e)
    if dptDt[i] and dptDt[i].quantity >= 1 then
      ReinWeaponUp(i)
    end
  end
end
for i = 1, 12 do
  ui["reinMaterial_b_" .. i].EventMouseDown = function(sender, e)
    if dptDt2[i] and dptDt2[i].quantity >= 1 then
      local s, l, c = GetMoveMesg(sender)
      if sender.IsCapture then
        LighterOrNarmal(true, 7)
        ShowMoveControl(s, l, resDir, dptDt2[i].resource, dptDt2[i].grade)
      else
        ReinMaterialUp(i, c)
      end
    end
  end
  ui["reinMaterial_b_" .. i].EventMouseMove = function(sender, e)
    OnMouseMove(sender)
  end
  ui["reinMaterial_b_" .. i].EventMouseUp = function(sender, e)
    ReinMaterialUp(i, sender.CurrentCursorPosition)
  end
  ui["reinMaterial_b_" .. i].EventRightClick = function(sender, e)
    if dptDt2[i] and dptDt2[i].quantity >= 1 then
      ReinMaterialUp(i)
    end
  end
end
for i = 1, 20 do
  ui["hangWeapon_b_" .. i].EventMouseDown = function(sender, e)
    if dptDt[i] and dptDt[i].quantity >= 1 then
      local s, l, c = GetMoveMesg(sender)
      if sender.IsCapture then
        LighterOrNarmal(true, 8)
        ShowMoveControl(s, l, resDir, dptDt[i].resource, dptDt[i].grade)
      else
        HangWeaponUp(i, c)
      end
    end
  end
  ui["hangWeapon_b_" .. i].EventMouseMove = function(sender, e)
    OnMouseMove(sender)
  end
  ui["hangWeapon_b_" .. i].EventMouseUp = function(sender, e)
    HangWeaponUp(i, sender.CurrentCursorPosition)
  end
  ui["hangWeapon_b_" .. i].EventRightClick = function(sender, e)
    if dptDt[i] and dptDt[i].quantity >= 1 then
      HangWeaponUp(i)
    end
  end
end
for i = 1, 5 do
  ui["skill_add_" .. i].EventClick = function(sender, e)
    ui["skill_dec_" .. i].Enable = true
    ui.btn_skill_finish.Enable = true
    SetSkillLeave(skillLeave - 1)
    SetSkillVSize(i, skillTemLevel[i] + 1)
    if skillTemLevel[i] >= 5 then
      sender.Enable = false
    end
    if skillLeave <= 0 then
      for j = 1, 5 do
        ui["skill_add_" .. j].Enable = false
      end
    end
    local t = math.min(5, skillTemLevel[i])
    gui:PlayAudio("ability_point_lv" .. tonumber(t))
    ForceLeadSkillLearn(FORCE_LEAD_SKILLLEARN_SKILL_FINISH)
  end
end
for i = 1, 5 do
  ui["skill_dec_" .. i].EventClick = function(sender, e)
    SetSkillLeave(skillLeave + 1)
    if skillTemLevel[i] > sklDt[i].level then
      SetSkillVSize(i, skillTemLevel[i] - 1)
    end
    if skillTemLevel[i] <= sklDt[i].level then
      sender.Enable = false
    end
    for j = 1, 5 do
      if skillTemLevel[j] < 5 and sklDt[j].level < 5 then
        ui["skill_add_" .. j].Enable = true
      end
    end
    tempK = 0
    for j = 1, 5 do
      if skillTemLevel[j] == sklDt[j].level then
        tempK = tempK + 1
      end
    end
    if tempK == 5 then
      ui.btn_skill_finish.Enable = false
    end
    local t = math.max(1, skillTemLevel[i])
    gui:PlayAudio("ability_point_lv" .. tonumber(t))
  end
end
for i = 1, 12 do
  if i ~= 2 then
    ui["equip_b_" .. i].EventMouseDown = function(sender, e)
      if sender.Skin ~= SkinF.skin_touming2 then
        local s, l, c = GetMoveMesg(sender)
        if sender.IsCapture then
          if i <= 6 then
            ShowMoveControl(s, l, resDir, equipSkinRes[i], equipGrade[i])
          else
            ShowMoveControl(s, l, resDir, posDt[i - 6].resource)
          end
        else
          EquipButonUp(i, c)
        end
      end
    end
    ui["equip_b_" .. i].EventMouseMove = function(sender, e)
      OnMouseMove(sender)
    end
    ui["equip_b_" .. i].EventMouseUp = function(sender, e)
      EquipButonUp(i, sender.CurrentCursorPosition)
    end
    ui["equip_b_" .. i].EventRightClick = function(sender, e)
      if sender.Skin ~= SkinF.skin_touming2 then
        gui:PlayAudio("cancel")
        if i <= 6 then
          PlayerIndependentUnequip(i, ComFuc.equipMapKey[i])
        else
          PlayerIndependentUnequip(i, nil)
        end
      end
    end
  end
end
for i = 1, 5 do
  ui["insert_kb_" .. i].EventClick = function(sender, e)
    openSlotCurr = i
    rpc_player_item_count(1, 3, 301, 1)
  end
end
for i = 1, 5 do
  ui["insert_b_" .. i].EventRightClick = function(sender, e)
    gui:PlayAudio("cancel")
    tableDepot["T" .. tableInsP[i] .. tableInsB[i]] = tableDepot["T" .. tableInsP[i] .. tableInsB[i]] - 1
    tableInsP[i] = 0
    tableInsB[i] = 0
    ui.combIns_cost.Text = ui.combIns_cost.Text - insCost .. "  "
    if tonumber(insDt[i].itemId) ~= 0 then
      ui["insert_c2_" .. i].Visible = true
      ShowOneButton(ui["insert_pd_" .. i], sender, resDir, insDt[i].resource, insDt[i].grade or 1)
    else
      ui["insert_pd_" .. i].BackgroundColor = col0
      sender.Visible = false
    end
    rpc_storage_item_filter(3, 1)
    ComputeInsertP(slotRenforceBf[i].stamina, ui.insert_life, -1)
    ComputeInsertP(slotRenforceBf[i].cureQuantity, ui.insert_add, -1)
    ComputeInsertP(slotRenforceBf[i].armor, ui.insert_protect, -1)
    ComputeInsertP(slotRenforceBf[i].recovery, ui.insert_recover, -1)
    ComputeInsertP(insDt[i].pluses.stamina, ui.insert_life)
    ComputeInsertP(insDt[i].pluses.cureQuantity, ui.insert_add)
    ComputeInsertP(insDt[i].pluses.armor, ui.insert_protect)
    ComputeInsertP(insDt[i].pluses.recovery, ui.insert_recover)
    slotRenforceBf[i] = insDt[i].pluses
    if tableInsP[1] and 1 <= tableInsP[1] or tableInsP[2] and 1 <= tableInsP[2] or tableInsP[3] and 1 <= tableInsP[3] or tableInsP[4] and 1 <= tableInsP[4] or tableInsP[5] and 1 <= tableInsP[5] then
      ui.btn_insert.Enable = true
    else
      ui.btn_insert.Enable = false
    end
  end
end
for i = 1, 5 do
  ui["mix_b_" .. i].EventRightClick = function(sender, e)
    gui:PlayAudio("cancel")
    sender.Visible = false
    ui.btn_combMix.Enable = false
    CleanMixSlot()
  end
end
for i = 1, 8 do
  ui["refit_buy_" .. i].EventClick = function(sender, e)
    if not QuickBuy then
      require("shop/quick_buy.lua")
    end
    if i == 3 then
      QuickBuy.Show({
        t = 3,
        st = "301",
        category = 3
      })
    elseif i == 4 then
      QuickBuy.Show({
        t = 3,
        st = "301",
        category = 6
      })
    elseif i == 5 then
      QuickBuy.Show({
        t = 3,
        st = "301",
        category = 7
      })
    end
    
    function QuickBuy.callback()
      refitMoveDir = 0
      if i <= 4 then
        rpc_refit_need()
      else
        isHangFirst = true
        rpc_weapon_addition_material()
      end
    end
  end
end

function ui.equip_s_13.EventMouseEnter(sender, e)
  ShowDepotTips(sender, ui.equip_b_13.Skin ~= SkinF.skin_touming2, 2, menDt.pid)
end

function ui.equip_s_14.EventMouseEnter(sender, e)
  ShowDepotTips(sender, ui.equip_b_14.Skin ~= SkinF.skin_touming2, 2, menDt2.pid)
end

function ui.equip_s_15.EventMouseEnter(sender, e)
  ShowDepotTips(sender, ui.equip_b_15.Skin ~= SkinF.skin_touming2, 2, menDt.pid)
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

function ui.left_rotate_2.EventMouseDown(sender, e)
  lg:SetVanRotateSpeed(-0.3)
end

function ui.left_rotate_2.EventMouseUp(sender, e)
  lg:SetVanRotateSpeed(0)
end

function ui.right_rotate_2.EventMouseDown(sender, e)
  lg:SetVanRotateSpeed(0.3)
end

function ui.right_rotate_2.EventMouseUp(sender, e)
  lg:SetVanRotateSpeed(0)
end

function ui.left_rotate_pet_1.EventMouseDown(sender, e)
  lg:SetPetRotateSpeed(-0.3)
end

function ui.left_rotate_pet_1.EventMouseUp(sender, e)
  lg:SetPetRotateSpeed(0)
end

function ui.right_rotate_pet_1.EventMouseDown(sender, e)
  lg:SetPetRotateSpeed(0.3)
end

function ui.right_rotate_pet_1.EventMouseUp(sender, e)
  lg:SetPetRotateSpeed(0)
end

function ui.left_rotate_pet_2.EventMouseDown(sender, e)
  lg:SetPetRotateSpeed(-0.3)
end

function ui.left_rotate_pet_2.EventMouseUp(sender, e)
  lg:SetPetRotateSpeed(0)
end

function ui.right_rotate_pet_2.EventMouseDown(sender, e)
  lg:SetPetRotateSpeed(0.3)
end

function ui.right_rotate_pet_2.EventMouseUp(sender, e)
  lg:SetPetRotateSpeed(0)
end

function ui.reset_anim.EventClick(sender, e)
  ComFuc.ResetAnim()
end

function ui.insert_card.EventRightClick(sender, e)
  ResetRemoveStoneButton()
  gui:PlayAudio("cancel")
  CleanInsertCard(true, true)
  menDt = {}
  rpc_storage_storage_list_no_empty(ui.pb_reinPerson.CurrIndex)
  rpc_storage_item_filter(3, ui.pb_reinStone.CurrIndex)
  if NewLead.leadVisible then
    NewLead.ShowNewLeadNoLock(ComFuc.icB, Vector2(104, 163), GetUTF8Text("UI_enhance_Please_drag_in_the_avatar_card"), 0)
  end
end

function ui.insertTip_cha.EventClick(sender, e)
  ui.coverControl2.Parent = nil
  ui.insertTip.Parent = nil
end

function ui.insertTip_sure.EventClick(sender, e)
  local func = function()
    ui.coverControl2.Parent = nil
    ui.insertTip.Parent = nil
    rpc_avatar_slot_create()
    rpc_storage_item_filter(3, 1)
  end
  if menDt.isBind == "true" or menDt.isBind == "Y" or menDt.grade > 1 then
    func()
  else
    MessageBox.ShowWithConfirmCancel(GetUTF8Text("msgbox_avatar_avatar_colligation_01"), func)
  end
end

function ui.insertTip_buy.EventClick(sender, e)
  if not QuickBuy then
    require("shop/quick_buy.lua")
  end
  QuickBuy.Show({
    t = 3,
    st = "301",
    category = 1
  })
  
  function QuickBuy.callback()
    rpc_player_item_count(1, 3, 301, 1)
    rpc_storage_item_filter(3, 1)
  end
end

function ui.insertTip_canc.EventClick(sender, e)
  ui.coverControl2.Parent = nil
  ui.insertTip.Parent = nil
end

function ui.dest_left.EventClick(sender, e)
  ui.dest_right.Enable = true
  ui.dest_text.Text = ui.dest_text.Text - 1
  if 1 >= tonumber(ui.dest_text.Text) then
    sender.Enable = false
  end
end

function ui.dest_right.EventClick(sender, e)
  ui.dest_left.Enable = true
  ui.dest_text.Text = ui.dest_text.Text + 1
  SetDestRightEnable()
end

function ui.dest_sure.EventClick(sender, e)
  SetDestNumSure()
end

function ui.dest_text.EventValueEnter(sender, e)
  SetDestNumSure()
end

function ui.dest_text.EventTextChanged(sender, e)
  ui.dest_sure.Enable = true
  if sender.Text ~= "" then
    if not tonumber(ui.dest_text.Text) or tonumber(ui.dest_text.Text) <= 0 then
      sender.Text = oldDestText
    end
    ui.dest_right.Enable = not tonumber(ui.dest_text.Text) or tonumber(ui.dest_text.Text) < menDt.quantity - 1
    oldDestText = sender.Text
  else
    oldDestText = ""
    ui.dest_sure.Enable = false
    ui.dest_right.Enable = false
  end
  ui.dest_left.Enable = tonumber(ui.dest_text.Text) and tonumber(ui.dest_text.Text) > 1
end

function ui.manu_text.EventTextChanged(sender, e)
  if sender.Text ~= "" and lv and lv.SelectedItem then
    if not tonumber(sender.Text) or tonumber(sender.Text) > blueprintDt[lv.SelectedItem.ID % 1000].quantity or tonumber(sender.Text) <= 0 then
      sender.Text = oldDestText
    end
    oldDestText = sender.Text
    ui.combManuf_cost.Text = tonumber(sender.Text) * blueSigleCost .. "  "
  else
    oldDestText = ""
    ui.combManuf_cost.Text = blueSigleCost .. "  "
  end
end

function ui.dest_cancel.EventClick(sender, e)
  HideDestructNum()
end

local ui.dest_max.EventClick, SetSpeakSure = function(sender, e)
  ui.dest_text.Text = menDt.quantity - 1
end, ui.dest_max

function SetSpeakSure()
  rpc.safecall("use_loudspeaker", {
    pid = menDt.pid,
    msg = ui.speak_text.Text
  }, function(data)
    rpc_storage_storage_list(ui.pb_depot.CurrIndex)
  end)
  HideLoundSpeaker()
end

function ui.speak_sure.EventClick(sender, e)
  SetSpeakSure()
end

function ui.speak_cancel.EventClick(sender, e)
  HideLoundSpeaker()
end

function ui.speak_close.EventClick(sender, e)
  HideLoundSpeaker()
end

local ui.speak_text.EventValueEnter, PetSlotExpandSure = function(sender, e)
  SetSpeakSure()
end, ui.speak_text
local PetSlotExpandSure, SetChangePetNameSure = function()
  local t = 1
  local skillCostTb = currentPetSlotExpandPrice
  local textKey = "msgbox_pet_add_07"
  local mesgl = GetUTF8Text("id_common_Gold")
  if ui.pet_slot_expand_costCB_2.Check then
    t = 2
    mesgl = GetUTF8Text("id_common_CC")
  elseif ui.pet_slot_expand_costCB_3.Check then
    t = 3
    mesgl = GetUTF8Text("id_common_Medal")
  elseif ui.pet_slot_expand_costCB_4.Check then
    t = 4
    mesgl = GetUTF8Text("id_common_Ticket")
  end
  local mesg = GetMatchedUTF8Text(string.format("%s,%d,%s", textKey, skillCostTb[t], mesgl))
  MessageBox.ShowWithConfirmCancel(mesg, function(sender, e)
    rpc_player_pet_slot_expand(t)
    HidePetSlotExpandUI()
  end, nil, true)
end, "EventValueEnter"

function SetChangePetNameSure()
  local isOpenIme = false
  for i = 1, 100 do
    if string.byte(ui.change_pet_name_text.Text, i) and string.byte(ui.change_pet_name_text.Text, i) > 128 then
      isOpenIme = true
      break
    end
  end
  if ui.change_pet_name_text.Text == "" then
    MessageBox.ShowError(GetUTF8Text("UI_pet_function_05"))
  elseif game.local_language == "en_sg" and (isOpenIme or string.len(ui.change_pet_name_text.Text) < 3) then
    if isOpenIme then
      MessageBox.ShowError(GetUTF8Text("msgbox_pet_name_format_01"))
    elseif string.len(ui.change_pet_name_text.Text) < 3 then
      MessageBox.ShowError(GetUTF8Text("msgbox_pet_name_format_03"))
    end
  elseif PlayerPetsData and SelectedPetSlot and PlayerPetsData[SelectedPetSlot] then
    local pet_id = PlayerPetsData[SelectedPetSlot].id
    local skillCostTb = PetRenamePrice
    local textKey = "UI_pet_function_06"
    local t = 1
    local mesgl = GetUTF8Text("id_common_Gold")
    if ui.pet_rename_costCB_2.Check then
      t = 2
      mesgl = GetUTF8Text("id_common_CC")
    elseif ui.pet_rename_costCB_3.Check then
      t = 3
      mesgl = GetUTF8Text("id_common_Medal")
    elseif ui.pet_rename_costCB_4.Check then
      t = 4
      mesgl = GetUTF8Text("id_common_Ticket")
    end
    local mesg = GetMatchedUTF8Text(string.format("%s,%d,%s", textKey, skillCostTb[t], mesgl))
    MessageBox.ShowWithConfirmCancel(mesg, function(sender, e)
      rpc_player_pet_rename(pet_id, ui.change_pet_name_text.Text, t)
      HideChangePetName()
    end, nil, true)
  end
end

function ui.change_pet_name_sure.EventClick(sender, e)
  SetChangePetNameSure()
end

function ui.change_pet_name_cancel.EventClick(sender, e)
  HideChangePetName()
end

function ui.change_pet_name_close.EventClick(sender, e)
  HideChangePetName()
end

function ui.change_pet_name_text.EventValueEnter(sender, e)
  SetChangePetNameSure()
end

function ui.pet_slot_expand_sure.EventClick(sender, e)
  PetSlotExpandSure()
end

function ui.pet_slot_expand_close.EventClick(sender, e)
  HidePetSlotExpandUI()
end

function ui.btn_pet_rename.EventClick(sender, e)
  ShowChangePetName()
end

function ui.btn_pet_pacify.EventClick(sender, e)
  if PlayerPetsData and SelectedPetSlot and PlayerPetsData[SelectedPetSlot] then
    if PlayerPetsData[SelectedPetSlot].needPlacate == "Y" then
      currentPlacatePrice = {}
      for i, v in ipairs(PlayerPetsData[SelectedPetSlot].placatePrice) do
        currentPlacatePrice[v.currency] = v.price
      end
      ShowResetSkillCost(4)
    else
      MessageBox.ShowError(GetUTF8Text("msgbox_pet_clew_12"))
    end
  end
end

function ui.card_tab_embed.EventClick(sender, e)
  if ui.card_tab_inheirt.PushDown then
    SelReinforceBtn(1)
    ui.card_tab_embed.PushDown = true
    ui.card_tab_inheirt.PushDown = false
  else
    ui.card_tab_embed.PushDown = true
  end
end

function ui.card_tab_inheirt.EventClick(sender, e)
  if ui.card_tab_embed.PushDown then
    ui.card_tab_embed.PushDown = false
    ui.card_tab_inheirt.PushDown = true
    SelReinforceCtrl_6()
    if ComFuc.inherit_guide then
      NewLead.ShowNewLeadNoLock(Vector2(79, 361), Vector2(104, 163), GetUTF8Text("UI_enhance_Please_drag_in_the_avatar_card"), 0)
    else
      NewLead.HideLead()
    end
  else
    ui.card_tab_inheirt.PushDown = true
  end
end

function ui.btn_pet_feed.EventClick(sender, e)
  if PlayerPetsData and SelectedPetSlot and PlayerPetsData[SelectedPetSlot] then
    if PlayerPetsData[SelectedPetSlot].grade < 5 then
      local pet_id = PlayerPetsData[SelectedPetSlot].id
      rpc_player_pet_feed(pet_id)
    else
      MessageBox.ShowError(GetUTF8Text("msgbox_pet_food_01"))
    end
  end
end

function ui.battle_or_rest.EventClick(sender, e)
  if PlayerPetsData and SelectedPetSlot and PlayerPetsData[SelectedPetSlot] then
    local new_fight_state
    if PlayerPetsData[SelectedPetSlot].isEquipped == "Y" then
      new_fight_state = 0
    else
      new_fight_state = 1
    end
    if 0 >= PlayerPetsData[SelectedPetSlot].unit and new_fight_state == 1 then
      MessageBox.ShowError(GetUTF8Text("UI_pet_predicable_04"))
    else
      rpc_player_pet_fight(PlayerPetsData[SelectedPetSlot].id, new_fight_state)
    end
    rpc_player_battle_force_get()
  end
end

function DealEndFoodQuickBuy()
  rpc_player_pet_list(CurrentPlayerPetPage)
end

function ui.buy_pet_food.EventClick(sender, e)
  if not QuickBuy then
    require("shop/quick_buy.lua")
  end
  if PlayerPetsData and SelectedPetSlot and PlayerPetsData[SelectedPetSlot] and PlayerPetsData[SelectedPetSlot].food then
    QuickBuy.Show({
      t = PlayerPetsData[SelectedPetSlot].food.type,
      st = PlayerPetsData[SelectedPetSlot].food.subType,
      category = PlayerPetsData[SelectedPetSlot].food.category,
      grade = PlayerPetsData[SelectedPetSlot].food.grade
    })
    QuickBuy.callback = DealEndFoodQuickBuy
  end
end

function ui.btn_insert.EventClick(sender, e)
  local isReplace = false
  for i = 1, 5 do
    if tonumber(insDt[i].itemId) ~= 0 and tableInsP[i] and 1 <= tonumber(tableInsP[i]) then
      isReplace = true
      break
    end
  end
  if isReplace then
    MessageBox.ShowWithConfirmCancel(GetUTF8Text("msgbox_enhance_additional_string_151"), function(sender, e)
      btn_insertClick(ui.btn_insert)
    end)
  else
    btn_insertClick(ui.btn_insert)
  end
end

function ui.btn_combMix.EventClick(sender, e)
  sender.Enable = false
  rpc_item_synthesize()
  rpc_storage_item_filter(4, 1)
  if NewLead.leadVisible then
    NewLead.HideLead()
    ComFuc.SetOneLeadFinish(16)
  end
  ComFuc.TestIsFinishOneTask(1017)
end

function ui.btn_skill_reset.EventClick(sender, e)
  if ComFuc.globalLV <= 0 then
    mesg = string.format(GetUTF8Text("msgbox_common_num_1361"), 3)
    MessageBox.ShowWithConfirmCancel(mesg, function(sender, e)
      ui.btn_skill_reset.Enable = false
      rpc_skill_reset(t)
      rpc_skill_list()
      rpc_slot_get()
    end, nil, true)
  else
    ShowResetSkillCost(1)
  end
end

ui.btn_common_character_1.PushDown = true
for i = 1, 2 do
  ui["btn_common_character_" .. i].EventClick = function(sender, e)
    ui["btn_common_character_" .. i].PushDown = false
    for j = 1, 2 do
      ui["btn_common_character_" .. j].PushDown = i == j
    end
    if ui.btn_common_character_1.PushDown == true then
      for k = 1, 6 do
        ui["main_par_" .. k].Visible = true
        ui["explore_main_par_" .. k].Visible = false
      end
    else
      for k = 1, 6 do
        ui["main_par_" .. k].Visible = false
        ui["explore_main_par_" .. k].Visible = true
      end
    end
  end
end
for k = 1, 6 do
  ui["main_par_" .. k].Visible = true
  ui["explore_main_par_" .. k].Visible = false
end

function ui.btn_skill_finish.EventClick(sender, e)
  sender.Enable = false
  ui.btn_skill_reset.Enable = true
  local ptl = {
    "ui_skills",
    "ui_skillp",
    "ui_skillt",
    "ui_skillb"
  }
  tempStr = ""
  for i = 1, 5 do
    if sklDt[i].id and skillTemLevel[i] ~= sklDt[i].level then
      tempStr = tempStr .. sklDt[i].id .. "," .. skillTemLevel[i] - sklDt[i].level .. ";"
      gui:AddParticle(ptl[SelectCharacter.role_job_id + 1], ui["skill_b_" .. i]:ClientToScreen(Vector2(35, 35)), Vector3(0, 1, 0))
    end
  end
  if not ComFuc.Is_FirstPrintLog[4] then
    rpc.safecall("user_retention", {
      sign = ComFuc.First_Log[4]
    }, function(data)
    end)
    ComFuc.Is_FirstPrintLog[4] = true
  end
  ComFuc.TestIsFinishOneTask(1003)
  gui:PlayAudio("pointdone")
  rpc_skill_adjust(tempStr)
  rpc_skill_list(1)
end

function ui.btn_depot_del.EventMouseDown(sender, e)
  local s, l, c = GetMoveMesg(sender)
  if sender.IsCapture then
    gui:PlayAudio("button_recyclebin")
    sender.Skin = SkinF.personalInfo_211[2]
  else
    DepotDelUp(c)
  end
end

function ui.btn_depot_del.EventMouseMove(sender, e)
  OnDepotDelMove(sender.CurrentCursorPosition)
end

function ui.btn_depot_del.EventMouseUp(sender, e)
  DepotDelUp(sender.CurrentCursorPosition)
end

function ui.btn_depot_repair.EventMouseDown(sender, e)
  local s, l, c = GetMoveMesg(sender)
  if sender.IsCapture then
    gui:PlayAudio("button")
    sender.Skin = SkinF.personalInfo_212[2]
  else
    DepotRepairUp(c)
  end
end

function ui.btn_depot_weapon_up.EventMouseDown(sender, e)
  local s, l, c = GetMoveMesg(sender)
  if sender.IsCapture then
    gui:PlayAudio("button")
    sender.Skin = SkinF.personalInfo_weaponup[2]
    DepotWeaponUpShow()
  else
    DepotWeaponUp(c)
  end
end

function ui.btn_depot_repair.EventMouseMove(sender, e)
  OnDepotDelMove(sender.CurrentCursorPosition)
end

function ui.btn_depot_weapon_up.EventMouseMove(sender, e)
  OnDepotDelMove(sender.CurrentCursorPosition)
end

function ui.btn_depot_repair.EventMouseUp(sender, e)
  DepotRepairUp(sender.CurrentCursorPosition)
end

function ui.btn_depot_weapon_up.EventMouseUp(sender, e)
  DepotWeaponUp(sender.CurrentCursorPosition)
end

function ui.btn_depot_repair_all.EventClick(sender, e)
  rpc_repair_price_get(2)
end

function ui.btn_depot_reorder.EventClick(sender, e)
  gui:PlayAudio("clean")
  rpc_storage_neaten()
  rpc_storage_storage_list(1)
end

function ui.renew.EventClick(sender, e)
  rpc.safecall("get_renew_item", {pid = 0, t = "2, 5"}, function(data)
    ShopBalance.list = {}
    if data.itemList then
      for i = 1, #data.itemList do
        ShopBalance.list[#ShopBalance.list + 1] = data.itemList[i]
      end
    end
    if data.avatarList then
      for i = 1, #data.avatarList do
        ShopBalance.list[#ShopBalance.list + 1] = data.avatarList[i]
      end
    end
    if #ShopBalance.list == 0 then
      MessageBox.ShowError(GetUTF8Text("msgbox_lobby_renew_all"), 3, true)
    else
      ShopBalance.Show("Renew_type")
    end
  end)
end

function ui.equip_b_13.EventRightClick(sender, e)
  if sender.Skin ~= SkinF.skin_touming2 then
    gui:PlayAudio("weapon_put")
    CleanReinforce()
    menDt = {}
    CleanReinMaterial(true)
    rpc_storage_item_filter(1, ui.pb_reinWeapon.CurrIndex)
    if NewLead.leadVisible then
      NewLead.HideLead()
      NewLead.ShowNewLeadNoLock(Vector2(535, 376), Vector2(80, 80), GetUTF8Text("tips_lobby_Common_Desc29"), 0)
    end
    ComputeWeaponEnhanceBar()
  end
end

function ui.equip_b_14.EventRightClick(sender, e)
  if sender.Skin ~= SkinF.skin_touming2 then
    gui:PlayAudio("weapon_put")
    menDt2 = {}
    ui.btn_combRefit.Enable = false
    ui.equip_pd_14.BackgroundColor = col0
    ui.equip_b_14.Skin = SkinF.skin_touming2
    ui.equip_level_14.Visible = false
    ui.btn_combRefit.Hint = ""
    ComputeWeaponEnhanceBar()
    ui.equip_c_14.Visible = ui.equip_b_13.Skin ~= SkinF.skin_touming2 and ui.equip_b_14.Skin == SkinF.skin_touming2
    ui.Tips_To_DragMetrailWeapon.Visible = ui.equip_b_13.Skin ~= SkinF.skin_touming2 and ui.equip_b_14.Skin == SkinF.skin_touming2
  end
end

function ui.btn_combRefit.EventClick(sender, e)
  refitMoveDir = 0
  if isEnough then
    if refitDt.currentLevel == 0 and refitDt.currentExpCurrentLevelOffset == 0 then
      MessageBox.ShowWithTwoButtons(GetUTF8Text("msgbox_common_intensify_01"), GetUTF8Text("msgbox_common_intensify_02"), GetUTF8Text("msgbox_common_intensify_03"), function()
        SetBtnRefitClick()
      end)
    else
      SetBtnRefitClick()
    end
  else
    MessageBox.ShowError(GetUTF8Text("msgbox_enhance_Insufficient_enhance_material"))
  end
  if bit.band(32, ComFuc.leadList) == 32 then
    NewLead.HideLead()
    ComFuc.SetOneLeadFinish(32)
  end
  ComFuc.TestIsFinishOneTask(1018)
end

function ui.equip_b_15.EventRightClick(sender, e)
  if sender.Skin ~= SkinF.skin_touming2 then
    gui:PlayAudio("weapon_put")
    CleanHang()
    menDt = {}
    if ComFuc.weapon_remake_guide then
      NewLead.ShowNewLeadNoLock(Vector2(703, 370), Vector2(82, 82), GetUTF8Text("tips_lobby_Common_Desc29"), 0)
    end
    rpc_storage_item_filter(5, ui.pb_hangWeapon.CurrIndex)
  end
end

function ui.btn_combHang.EventClick(sender, e)
  if ComFuc.weapon_remake_guide then
    ComFuc.TestIsFinishOneTask(ComFuc.quest_id[4])
    ComFuc.weapon_remake_guide = false
    NewLead.ShowNewLeadNoLock(Vector2(521, 78), Vector2(72, 73), GetUTF8Text("UI_common_Click"), 1)
  end
  if ComFuc.globalLV >= 8 then
    if isEnough then
      if isHangFirst and hangDt and hangDt.additionMap and not hangDt.additionMap[1] then
        MessageBox.ShowWithTwoButtons(GetUTF8Text("id_datalist_weapon_padlock_04"), GetUTF8Text("msgbox_common_intensify_02"), GetUTF8Text("msgbox_common_intensify_03"), function()
          SetBtnHangClick()
        end)
      else
        SetBtnHangClick()
      end
    else
      MessageBox.ShowError(GetUTF8Text("msgbox_common_attribute_05"))
    end
  else
    MessageBox.ShowError(GetUTF8Text("msgbox_common_padlock_max_01"))
  end
end

function ui.btn_combManuf.EventClick(sender, e)
  if ComFuc.produce_guide then
    ComFuc.TestIsFinishOneTask(ComFuc.quest_id[3])
    NewLead.ShowNewLeadNoLock(Vector2(521, 78), Vector2(72, 73), GetUTF8Text("UI_common_Click"), 1)
    ComFuc.produce_guide = false
  else
    NewLead.HideLead()
  end
  if lv and lv.SelectedItem then
    local itemBP = blueprintDt[lv.SelectedItem.ID % 1000]
    if itemBP.canUse == "Y" then
      if not ui.manu_text.Enable then
        MessageBox.ShowError(GetUTF8Text("msgbox_common_blueprint_clew_03"))
      elseif not tonumber(ui.manu_text.Text) or tonumber(ui.manu_text.Text) and tonumber(ui.manu_text.Text) == 0 then
        MessageBox.ShowError(GetUTF8Text("msgbox_common_make_clew_01"))
      else
        do
          local msg = GetUTF8Text("UI_enhance_conform_produce")
          MessageBox.ShowWithConfirmCancel(msg, function(sender, e)
            msg = GetMatchedUTF8Text("UI_common_make_10," .. ui.manu_text.Text .. "," .. GetMatchedUTF8Text(itemBP.displayName))
            MessageBox.ShowWithConfirmCancel(msg, function(sender, e)
              rpc.safecall("blueprint_make", {
                sid = itemBP.id,
                q = ui.manu_text.Text
              }, DealBluePrintMake)
            end)
          end)
        end
      end
    else
      MessageBox.ShowError(GetUTF8Text("UI_common_make_12"))
    end
  end
end

function ui.pb_depot.EventIndexChanged(sender, e)
  rpc_storage_storage_list(ui.pb_depot.CurrIndex)
end

function ui.pb_reinPerson.EventIndexChanged(sender, e)
  rpc_storage_storage_list_no_empty(sender.CurrIndex)
end

function ui.pb_reinStone.EventIndexChanged(sender, e)
  rpc_storage_item_filter(3, sender.CurrIndex)
end

function ui.pb_reinMedal.EventIndexChanged(sender, e)
  rpc_storage_item_filter(4, sender.CurrIndex)
end

function ui.pb_reinWeapon.EventIndexChanged(sender, e)
  rpc_storage_item_filter(1, sender.CurrIndex)
end

function ui.pb_reinMaterial.EventIndexChanged(sender, e)
  rpc_storage_item_filter(2, sender.CurrIndex)
end

function ui.pb_hangWeapon.EventIndexChanged(sender, e)
  rpc_storage_item_filter(5, sender.CurrIndex)
end

function ui.info_power.EventMouseEnter(sender, e)
  ui.power_hits.Visible = true
end

function ui.info_power.EventMouseLeave(sender, e)
  ui.power_hits.Visible = false
end

function ui.info_adventure.EventMouseEnter(sender, e)
  ui.adventure_hints.Visible = true
end

function ui.info_adventure.EventMouseLeave(sender, e)
  ui.adventure_hints.Visible = false
end

function ui.info_power_pet.EventMouseEnter(sender, e)
  ui.power_hints_pet.Visible = true
end

function ui.info_power_pet.EventMouseLeave(sender, e)
  ui.power_hints_pet.Visible = false
end

function EnablePetModule(bEnable)
  if ComFuc.isOpenPet then
    ui.btn_main_4.Enable = bEnable
    ui.btn_main_4_disable_hint.Visible = not bEnable
    if ui.main.Parent and bEnable and Lobby.petModuleOpened == "N" and bit.band(256, ComFuc.leadList) == 256 and ComFuc.isOpenPet then
      NewLead.ShowNewLeadNoLock(Vector2(475, 160), Vector2(206, 42), GetUTF8Text("UI_pet_system_unlock_02"), 0)
    end
  end
end

function CanSwitch()
  return true, GetUTF8Text("msgbox_common_num_1398")
end

function Show(winRoot)
  if not ComFuc.Is_FirstPrintLog[3] then
    ComFuc.Is_FirstPrintLog[3] = true
    rpc.safecall("user_retention", {
      sign = ComFuc.First_Log[3]
    }, function(data)
    end)
  end
  ui.main.Parent = winRoot
  mainCurr = 0
  depotCurr = 0
  equipSkinRes = {
    "",
    "humancard",
    "",
    "",
    "",
    ""
  }
  SetHotKeyName()
  ComFuc.ClearEquipButton(ui, 1, 12)
  rpc_player_info()
  rpc_player_battle_force_get()
  rpc_slot_get()
  lg:ResetVanRotation()
  lg:SetREId(0)
  lg:UpdateVanByInfoString()
  SelMainBtn(2)
  SelDepotBtn(1)
  if ComFuc.isOpenPet then
    ui.btn_main_4.Visible = true
    if 3 > ComFuc.globalLV then
      ui.btn_main_4.Enable = false
      ui.btn_main_4_disable_hint.Visible = true
    else
      ui.btn_main_4.Enable = true
      ui.btn_main_4_disable_hint.Visible = false
      if Lobby.petModuleOpened == "N" and bit.band(256, ComFuc.leadList) == 256 and ComFuc.isOpenPet then
        NewLead.ShowNewLeadNoLock(Vector2(475, 160), Vector2(206, 42), GetUTF8Text("UI_pet_system_unlock_02"), 0)
      end
    end
  else
    ui.btn_main_4.Visible = false
    ui.btn_main_4_disable_hint.Visible = false
  end
  if ComFuc.fastTaskTn == 1 and bit.band(4, ComFuc.leadList) == 4 then
    ForceLeadEasyUse(FORCE_LEAD_EASYUSE_TAG)
  end
  ForceLeadShopCheck(FORCE_LEAD_SHOP_SEE)
end

function ShowRefit(winRoot)
  IniPagebarClick()
  ui.btn_insert.Enable = false
  ui.btn_combMix.Enable = false
  ui.mix_daqu.Visible = false
  mainCurr = 0
  reinforceCurr = 0
  SelMainBtn(5)
  ui.left_main_2.Parent = winRoot
  lg:ResetVanRotation()
  lg:SetREId(0)
  lg:UpdateVanByInfoString()
end

function Hide()
  lg:PlayAnim("idlea")
  lg:SetWeapon(0, "")
  lg:SetEquipmentPetInfo("", -1)
  TimerRemove()
  Lobby.ShowLeftPointTips(false)
  ui.main.Parent = nil
end

function HideRefit()
  TimerRemove()
  ReMoveRefitPt()
  ui.left_main_2.Parent = nil
end

function CleanStone()
  ResetRemoveStoneButton()
  rpc_get_avatar_slot_list()
  ui["insert_b_" .. remove_stone_index].Visible = false
  ui["insert_c2_" .. remove_stone_index].Visible = false
  ui["insert_pd_" .. remove_stone_index].Skin = SkinF.personalInfo_quality[6]
end

for i = 1, 5 do
  ui["remove_stone_btn_" .. i].EventClick = function(sender, e)
    remove_stone_index = i
    remove_stone_of_avatar_id = menDt.pid
    rpc.safecall("medal_extirpate_info", {
      aid = remove_stone_of_avatar_id,
      pos = i - 1
    }, DealStoneRemovePrice)
    ShowRemoveStoneDialog()
  end
end

function ui_stone.checkBox_gold.EventCheckChanged(sender, e)
  ui_stone.checkBox_gold.MuteCheck = true
  ui_stone.checkBox_star.MuteCheck = false
end

function ui_stone.checkBox_star.EventCheckChanged(sender, e)
  ui_stone.checkBox_gold.MuteCheck = false
  ui_stone.checkBox_star.MuteCheck = true
end

function ShowGoldPrice(isShow)
  ui_stone.check_bg_gold.Visible = isShow
  ui_stone.gold.Visible = isShow
  ui_stone.checkBox_gold.Visible = isShow
end

function ShowStarPrice(isShow)
  ui_stone.check_bg_star.Visible = isShow
  ui_stone.star.Visible = isShow
  ui_stone.checkBox_star.Visible = isShow
end

function DealStoneRemovePrice(data)
  removeStoneRpcGetData = data
  ui_stone.check_label_gold.Text = data.extirpate_need_gp
  ui_stone.check_label_star.Text = data.extirpate_need_mb
  ShowGoldPrice(data.extirpate_need_gp > 0)
  ShowStarPrice(data.extirpate_need_mb > 0)
  ui_stone.checkBox_gold.Check = data.extirpate_need_gp > 0
  ui_stone.checkBox_star.Check = data.extirpate_need_gp <= 0
  ShowGoldPrice(data.extirpate_need_gp > 0)
  ShowStarPrice(data.extirpate_need_mb > 0)
  ui_stone.checkBox_gold.Check = data.extirpate_need_gp > 0
  ui_stone.checkBox_star.Check = data.extirpate_need_gp <= 0
  ShowOneButton(ui_stone.r_stone_son, ui_stone.r_stone_s, resDir, insDt[remove_stone_index].resource, insDt[remove_stone_index].grade or 1)
  ShowOneButton(ui_stone.r_stone_extirpate_lev, ui_stone.r_stone_extirpate_res, resDir, data.extirpate_icon, data.extirpate_level)
  ui_stone.r_stone_extirpate_count.Text = data.extirpate_own_num .. "/" .. data.extirpate_need_num
  local isBigFont = string.len(ui_stone.r_stone_extirpate_count.Text) <= 7
  if data.extirpate_own_num >= data.extirpate_need_num then
    ui_stone.r_stone_extirpate_count.TextureFont = isBigFont and SkinF.hecheng_number_1 or SkinF.hecheng_number_5
  else
    ui_stone.r_stone_extirpate_count.TextureFont = isBigFont and SkinF.hecheng_number_2 or SkinF.hecheng_number_6
  end
end

function ui_stone.close_button.EventClick(sender, e)
  HideRemoveStoneDialog()
end

function ui_stone.removeButton.EventClick(sender, e)
  if ui_stone.checkBox_gold.Check == true then
    rpc.safecall("medal_extirpate", {
      aid = remove_stone_of_avatar_id,
      pos = remove_stone_index - 1,
      currency = 1
    }, freshStoneUI)
  else
    rpc.safecall("medal_extirpate", {
      aid = remove_stone_of_avatar_id,
      pos = remove_stone_index - 1,
      currency = 2
    }, freshStoneUI)
  end
end

function ui_stone.r_stone_s.EventMouseEnter(sender, e)
  Tip.SetRpc(tip_sys_interface[3], {
    t = 3,
    sid = insDt[remove_stone_index].sid
  })
  Tip.SetUseDescription(false)
  Tip.SetOwner(sender)
end

function freshStoneUI(data)
  CleanStone()
  rpc_storage_item_filter(3, 1)
  HideRemoveStoneDialog()
  MessageBox.ShowError(GetUTF8Text("button_common_extirpate_04"))
end

function ShowRemoveStoneDialog()
  ui_stone.ctl_root.Parent = gui
end

function HideRemoveStoneDialog()
  ui_stone.ctl_root.Parent = nil
end

function ui.mingwen.EventClick(sender, e)
  ShowMWDialog()
end

local mw_dialog_model

function ShowMWDialog()
  mw_dialog_model = ModalWindow.GetNew("transparent")
  mw_dialog_model.screen.AllowEscToExit = true
  mw_dialog_model.root.Size = Vector2(332, 398)
  ui_mw.main.Parent = mw_dialog_model.root
end

function ui_cancel_binding.checkBox_gold.EventCheckChanged(sender, e)
  ui_cancel_binding.checkBox_gold.MuteCheck = true
  ui_cancel_binding.checkBox_star.MuteCheck = false
end

function ui_cancel_binding.checkBox_star.EventCheckChanged(sender, e)
  ui_cancel_binding.checkBox_gold.MuteCheck = false
  ui_cancel_binding.checkBox_star.MuteCheck = true
end

UnbindDetailData = nil

function DealItemUnbindDetail(data)
  UnbindDetailData = data
  if #data.currency == 0 then
    ui_cancel_binding.check_control.Visible = false
  else
    ui_cancel_binding.check_control.Visible = true
    ui_cancel_binding.check_bg_gold.Visible = false
    ui_cancel_binding.gold.Visible = false
    ui_cancel_binding.checkBox_gold.Visible = false
    ui_cancel_binding.check_bg_star.Visible = false
    ui_cancel_binding.star.Visible = false
    ui_cancel_binding.checkBox_star.Visible = false
    for i, v in ipairs(data.currency) do
      if v.currencyType == 1 then
        ui_cancel_binding.check_bg_gold.Visible = true
        ui_cancel_binding.gold.Visible = true
        ui_cancel_binding.checkBox_gold.Visible = true
        ui_cancel_binding.checkBox_gold.Check = true
        ui_cancel_binding.checkBox_star.Check = false
        ui_cancel_binding.check_label_gold.Text = v.unit
      elseif v.currencyType == 2 then
        ui_cancel_binding.check_bg_star.Visible = true
        ui_cancel_binding.star.Visible = true
        ui_cancel_binding.checkBox_star.Visible = true
        if #data.currency == 1 then
          ui_cancel_binding.checkBox_gold.Check = false
          ui_cancel_binding.checkBox_star.Check = true
        end
        ui_cancel_binding.check_label_star.Text = v.unit
      end
    end
  end
  local resname = ComFuc.DoWingRes(menDt.resource, menDt.subtype, 102, depotCurr)
  ShowOneButton(ui_cancel_binding.r_stone_son, ui_cancel_binding.r_stone_s, resDir, resname, menDt.grade or 1)
  ShowOneButton(ui_cancel_binding.r_stone_extirpate_lev, ui_cancel_binding.r_stone_extirpate_res, resDir, data.stoneResource, data.stoneGrade)
  ui_cancel_binding.r_stone_extirpate_count.Text = data.stoneOwnNum .. "/" .. data.stoneNeedNum * menDt.quantity
  local isBigFont = string.len(ui_cancel_binding.r_stone_extirpate_count.Text) <= 7
  if data.stoneOwnNum >= data.stoneNeedNum * menDt.quantity then
    ui_cancel_binding.r_stone_extirpate_count.TextureFont = isBigFont and SkinF.hecheng_number_1 or SkinF.hecheng_number_5
  else
    ui_cancel_binding.r_stone_extirpate_count.TextureFont = isBigFont and SkinF.hecheng_number_2 or SkinF.hecheng_number_6
  end
  ui_cancel_binding.r_stone_l.Text = menDt.quantity
  ShowBindingDialog()
end

function ShowBindingDialog()
  ui_cancel_binding.ctl_root.Parent = gui
end

function HideBindingDialog()
  ui_cancel_binding.ctl_root.Parent = nil
  UnbindDetailData = nil
end

function ui_cancel_binding.close_button.EventClick(sender, e)
  HideBindingDialog()
end

function DealItemUnbind(data)
  rpc_storage_storage_list(ui.pb_depot.CurrIndex)
  MessageBox.ShowError(GetUTF8Text("UI_common_colligation_deliquesce"))
  HideBindingDialog()
end

function ui_cancel_binding.removeButton.EventClick(sender, e)
  if #UnbindDetailData.currency > 0 then
    rpc.safecall("item_unbind", {
      playerItemId = menDt.pid,
      currencyType = UnbindDetailData.currency[1].currencyType
    }, DealItemUnbind)
  else
    rpc.safecall("item_unbind", {
      playerItemId = menDt.pid
    }, DealItemUnbind)
  end
end

function ui_cancel_binding.r_stone_s.EventMouseEnter(sender, e)
  Tip.SetRpc(tip_player_interface[depotCurr + 1], {
    t = depotCurr + 1,
    pid = menDt.pid
  })
  Tip.SetUseDescription(false)
  Tip.SetOwner(sender)
end

depotTabText = {
  [1] = GetUTF8Text("button_store_equipment_button"),
  [2] = GetUTF8Text("button_common_Item"),
  [3] = GetUTF8Text("button_common_Gesture"),
  [4] = GetUTF8Text("button_common_Avatar_Card")
}
addBagCostTb = {}

function DealAddBagPrice(data)
  addBagCostTb = {}
  for i, v in ipairs(data.price) do
    addBagCostTb[v.currency] = v.price
  end
  ShowResetSkillCost(2)
end

function DealAddBag(data)
  ui.pb_depot.PageCount = data.pageCount
  local msgText = string.format(GetUTF8Text("UI_lobby_consortia_07"), depotTabText[depotCurr])
  MessageBox.ShowError(msgText)
end

function ui.add_bag.EventClick(sender, e)
  rpc.safecall("storage_expand_price", {
    t = depotCurr + 1
  }, DealAddBagPrice)
end

function ClearPetsData()
  ChangePetCandidateSelection(0)
  PetFoodCost = nil
  PetRenamePrice = {}
  PlayerPetsData = {}
  CurrentPetSkillData = {}
  CurrentPetOpConditions = {}
  CurrentPetOpSettings = {}
  SysPetsData = {}
  SelectedPetSlot = 1
  EquippedPetResource = nil
  EquippedPetGrade = nil
  currentSysPetPrice = {}
  currentPlacatePrice = {}
  currentPetSkillUpdatePrice = {}
  currentPetSlotExpandPrice = {}
end

function DealItemLockDetail(data)
  LockItem.DealItemLockDetail(data)
end

function DealItemUnlockDetail(data)
  LockItem.DealItemUnlockDetail(data)
end

function DealItemWaitUnbindtail(data)
  LockItem.DealItemWaitUnbindtail(data)
end

function ui.profession_skill_button_1.EventClick(sender, e)
  rpc_skill_list()
end

function SetActiveBossSkillDragTip()
  for i = 1, 6 do
    ui["boss_skill_drag_tip_" .. i].Visible = false
  end
  for i, v in ipairs(bossSkillListData) do
    local flag = 0
    for j = 1, #bossSkllHelpData do
      if bossSkillDt[i].skillId == playerBossSkillListData[j].id then
        flag = j
        break
      end
    end
    if 0 < flag then
      for k = 1, #bossSkllHelpData do
        if bossSkllHelpData[k].id == playerBossSkillListData[flag].id and bossSkillDt[i].isActive == "Y" and bossSkllHelpData[k].activate == 1 then
          local k = 0
          for j, p in ipairs(hotKeyListData.slots) do
            if p.type == 1 and playerBossSkillListData[flag].display == p.display then
              k = 1
              break
            end
          end
          ui["boss_skill_drag_tip_" .. i].Visible = k == 0
        end
      end
    end
  end
  ui.profession_skill.Parent = nil
  ui.boss_skill.Parent = ui.right_main_3
end

local ShowBossSkillList, DealBossSkillList = function()
  for i = 1, 6 do
    ui["skill_" .. i].Visible = false
  end
  ui.boss_skill_pages_bar.CurrIndex = 1
  ui.boss_skill_pages_bar.PageCount = 1
  for i, v in ipairs(bossSkillListData) do
    bossSkillDt[i] = v
    ui["skill_" .. i].Visible = true
    ui["boss_skill_name_" .. i].Text = GetUTF8Text(v.displayName)
    if v.isActive == "Y" then
      ui["Boss_skill_active" .. i].Text = GetUTF8Text("UI_common_Active")
    elseif v.isActive == "N" then
      ui["Boss_skill_active" .. i].Text = GetUTF8Text("UI_common_Passive")
    end
    ui["boss_skill_b_" .. i].Skin = Gui.ButtonSkin({
      BackgroundImage = Gui.Image(resDir .. v.resource .. ".tga", Vector4(0, 0, 0, 0)),
      DisabledImage = Gui.Image(resDir .. v.resource .. "_disabled" .. ".tga", Vector4(0, 0, 0, 0))
    })
    local flag = 0
    for j = 1, #bossSkllHelpData do
      if v.skillId == bossSkllHelpData[j].id then
        if bossSkllHelpData[j].activate == 1 then
          ui["boss_skill_c2_" .. i].Visible = false
          ui["boss_skill_b_" .. i].Enable = true
          ui["select_skill_button_" .. i].Skin = SkinF.personalInfo_200
          ui["select_skill_button_" .. i].Text = GetUTF8Text("button_common_actived_skill")
          ui["select_skill_button_" .. i].Enable = false
        elseif bossSkllHelpData[j].activate == 0 then
          ui["boss_skill_c2_" .. i].Visible = true
          ui["boss_skill_b_" .. i].Enable = false
          ui["select_skill_button_" .. i].Skin = SkinF.personalInfo_200
          ui["select_skill_button_" .. i].Text = GetUTF8Text("button_common_active_skill")
          ui["select_skill_button_" .. i].Enable = true
        end
        flag = j
        break
      end
    end
    if flag == 0 then
      ui["boss_skill_b_" .. i].Enable = false
      ui["boss_skill_c2_" .. i].Visible = true
      ui["select_skill_button_" .. i].Enable = true
      ui["select_skill_button_" .. i].Skin = SkinF.activate_skill_button
      ui["select_skill_button_" .. i].Text = GetUTF8Text("button_common_get_skill")
    end
  end
  ui.boss_skill_button_1.PushDown = true
  SetActiveBossSkillDragTip()
end, function()
  for i = 1, 6 do
    ui["skill_" .. i].Visible = false
  end
  ui.boss_skill_pages_bar.CurrIndex = 1
  ui.boss_skill_pages_bar.PageCount = 1
  for i, v in ipairs(bossSkillListData) do
    bossSkillDt[i] = v
    ui["skill_" .. i].Visible = true
    ui["boss_skill_name_" .. i].Text = GetUTF8Text(v.displayName)
    if v.isActive == "Y" then
      ui["Boss_skill_active" .. i].Text = GetUTF8Text("UI_common_Active")
    elseif v.isActive == "N" then
      ui["Boss_skill_active" .. i].Text = GetUTF8Text("UI_common_Passive")
    end
    ui["boss_skill_b_" .. i].Skin = Gui.ButtonSkin({
      BackgroundImage = Gui.Image(resDir .. v.resource .. ".tga", Vector4(0, 0, 0, 0)),
      DisabledImage = Gui.Image(resDir .. v.resource .. "_disabled" .. ".tga", Vector4(0, 0, 0, 0))
    })
    local flag = 0
    for j = 1, #bossSkllHelpData do
      if v.skillId == bossSkllHelpData[j].id then
        if bossSkllHelpData[j].activate == 1 then
          ui["boss_skill_c2_" .. i].Visible = false
          ui["boss_skill_b_" .. i].Enable = true
          ui["select_skill_button_" .. i].Skin = SkinF.personalInfo_200
          ui["select_skill_button_" .. i].Text = GetUTF8Text("button_common_actived_skill")
          ui["select_skill_button_" .. i].Enable = false
        elseif bossSkllHelpData[j].activate == 0 then
          ui["boss_skill_c2_" .. i].Visible = true
          ui["boss_skill_b_" .. i].Enable = false
          ui["select_skill_button_" .. i].Skin = SkinF.personalInfo_200
          ui["select_skill_button_" .. i].Text = GetUTF8Text("button_common_active_skill")
          ui["select_skill_button_" .. i].Enable = true
        end
        flag = j
        break
      end
    end
    if flag == 0 then
      ui["boss_skill_b_" .. i].Enable = false
      ui["boss_skill_c2_" .. i].Visible = true
      ui["select_skill_button_" .. i].Enable = true
      ui["select_skill_button_" .. i].Skin = SkinF.activate_skill_button
      ui["select_skill_button_" .. i].Text = GetUTF8Text("button_common_get_skill")
    end
  end
  ui.boss_skill_button_1.PushDown = true
  SetActiveBossSkillDragTip()
end

function DealBossSkillList(data)
  bossSkillListData = data.skills
  for i = 1, #bossSkillListData do
    for j = 1, #bossSkillListData - i do
      if tonumber(bossSkillListData[j].id) >= tonumber(bossSkillListData[j + 1].id) then
        local temp = bossSkillListData[j + 1]
        bossSkillListData[j + 1] = bossSkillListData[j]
        bossSkillListData[j] = temp
      end
    end
  end
  ShowBossSkillList()
end

local ui.boss_skill_button_2.EventClick, UpdateBossSkillList = function(sender, e)
  rpc.safecall("boss_skill_list", nil, DealBossSkillList)
end, ui.boss_skill_button_2

function UpdateBossSkillList(data)
  bossSkllHelpData = data.skills
  ShowBossSkillList()
end

for i = 1, 6 do
  ui["boss_skill_b_" .. i].EventMouseDown = function(sender, e)
    if bossSkillDt[i].isActive == "Y" then
      local s, l, c = GetMoveMesg(sender)
      if sender.IsCapture then
        LighterOrNarmal(true, 1, 2)
        ShowMoveControl(s, l, resDir, bossSkillDt[i].resource)
      else
        bossSkillUp(i, c)
      end
    end
  end
  ui["boss_skill_b_" .. i].EventMouseMove = function(sender, e)
    OnMouseMove(sender)
  end
  ui["boss_skill_b_" .. i].EventMouseUp = function(sender, e)
    bossSkillUp(i, sender.CurrentCursorPosition)
  end
  ui["select_skill_button_" .. i].EventClick = function(sender, e)
    local flag = 0
    for j = 1, #bossSkllHelpData do
      if bossSkillDt[i].skillId == bossSkllHelpData[j].id then
        flag = j
        break
      end
    end
    if flag == 0 then
      Lobby.MainBtnSelect(7)
      if not MasterSystem then
        require("MasterSystem.lua")
      end
      for j = 1, 6 do
        ui["btn_reinforce_" .. j].PushDown = false
      end
      MasterSystem.FinishShow(bossSkillDt[i].levelId)
    elseif 0 < flag and bossSkllHelpData[flag].activate == 0 then
      rpc.safecall("boss_skill_activate", {
        skillId = bossSkillDt[i].skillId,
        t = 10
      }, UpdateBossSkillList)
      rpc_slot_get()
    end
  end
end

function OpenBook(data)
  if not BookItem then
    require("BookItem.lua")
  end
  BookItem.OpenBook(data)
end

function activeBossSkill(tempSkillId)
  SelMainBtn(3)
  rpc.safecall("boss_skill_list", nil, DealBossSkillList)
  rpc.safecall("boss_skill_activate", {skillId = tempSkillId, t = 10}, UpdateBossSkillList)
end

PlayerCardInherit.PlayerCardInheritUICallback()
