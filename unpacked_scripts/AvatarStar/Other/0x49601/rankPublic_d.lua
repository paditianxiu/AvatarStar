module("RankPublic", package.seeall)
local col0 = ComFuc.col0
local colw = ComFuc.colw
local colt = ComFuc.colt
local mainCurrTab = 0
local subCurrTab = 0
local Deta = {}
local temDt = {}
local pPage = 10
local pType = 1
local itemPid = 0
local testRR = {
  GetUTF8Text("UI_social_rank_actor"),
  GetUTF8Text("UI_lobby_consortia_02")
}
local textRP = {
  GetUTF8Text("UI_lobby_victory_score"),
  GetUTF8Text("tips_abilities_Power"),
  GetUTF8Text("UI_lobby_MVP_times"),
  GetUTF8Text("UI_lobby_rank_total_score"),
  GetUTF8Text("UI_social_add_rank_button_01"),
  GetUTF8Text("UI_social_add_rank_button_02"),
  GetUTF8Text("UI_lobby_consortia_04"),
  GetUTF8Text("tips_lobby_explore_strength_tips"),
  GetUTF8Text("UI_lobby_explore_max_rank")
}
local testRN = {
  GetUTF8Text("UI_social_military_rank"),
  GetUTF8Text("button_common_Avatar_Card"),
  GetUTF8Text("UI_lobby_consortia_03")
}
local onlyFriend = 0
local tip_player_interface = {
  "tip_player_skill",
  "tip_player_item",
  "tip_player_item",
  "tip_player_item",
  "tip_player_avatar_other",
  "tip_player_avatar_other"
}
local player_rank_type, ComBar = {
  "UI_lobby_Bronze_military",
  "UI_lobby_Silver_military",
  "UI_lobby_Gold_military",
  "UI_lobby_Diamond_military"
}, "UI_lobby_Bronze_military"
local ComBar, ComCB = function(i)
  return Gui.LcButton("bar_" .. i)({
    Size = Vector2(670, 34),
    Location = Vector2(0, 36 * i),
    BackgroundColor = colw,
    Skin = SkinF.rank_005,
    CanPushDown = true,
    Visible = false,
    ClickAudio = "selecttask",
    ComFuc.ComLabel("bar_NO_" .. i, nil, Vector2(52, 36), Vector2(8, -1), 0, 16, colt, "kAlignCenterMiddle"),
    ComFuc.ComControl("bar_job" .. i, Vector2(30, 30), Vector2(74, 2), 255, SkinF.personalInfo_job[i % 4 + 1]),
    ComFuc.ComControl("bar_rank_i_" .. i, Vector2(32, 32), Vector2(106, 1), 255, SkinF.rank_006[1][i]),
    ComFuc.ComLabel("bar_lv_" .. i, nil, Vector2(42, 34), Vector2(148, 0), 0, 16, colt),
    ComFuc.ComLabel("bar_name_" .. i, nil, Vector2(250, 34), Vector2(196, 0), 0, 16, colt),
    ComFuc.ComControl("bar_vip" .. i, Vector2(32, 32), Vector2(346, 1), 255, SkinF.vipPadShow_004[i % 6 + 1]),
    ComFuc.ComLabel("bar_rank_n_" .. i, nil, Vector2(160, 34), Vector2(379, 0), 0, 16, colt),
    ComFuc.ComLabel("bar_power_" .. i, nil, Vector2(112, 34), Vector2(526, 0), 0, 16, colt, "kAlignCenterMiddle"),
    ComFuc.ComButton("bar_btn_" .. i, nil, Vector2(30, 30), Vector2(637, 2), 0, false, false, SkinF.rank_013[1])
  })
end, "UI_lobby_Silver_military"
local ComCB, ComSubTab = function(name, size, lc)
  return Gui.Button(name)({
    Size = size,
    Location = lc,
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_103[3],
    ComFuc.ComControl(name .. "_son", size, Vector2(0, 0), 255, SkinF.skin_touming),
    ComFuc.ComControl(name .. "_s", size, Vector2(0, 0), 255, SkinF.skin_touming),
    Gui.Control(name .. "_level")({
      Size = Vector2(27, 29),
      Location = Vector2(29, 0),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_245[1],
      Visible = false,
      Enable = false,
      ComFuc.ComLabel(name .. "_level_text", nil, Vector2(27, 14), Vector2(0, 6), 0, 12, colw, "kAlignCenterMiddle")
    }),
    ComFuc.ComControl(name .. "_cover", size, Vector2(0, 0), 255, SkinF.skin_touming)
  })
end, "UI_lobby_Gold_military"

function ComSubTab(name, size1, lc1, size2, lc2, skin1, skin2)
  return Gui.Button(name)({
    Size = size1,
    Location = lc1,
    Skin = skin1,
    CanPushDown = true,
    ComFuc.ComControl(nil, size2, lc2, 255, skin2),
    ClickAudio = "menu3rd"
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
      ComFuc.ComControl(nil, Vector2(1128, 645), Vector2(0, 0), 255, SkinF.rank_009),
      Gui.CharacterAnimCard({
        ID = 8,
        Location = Vector2(722, 10),
        Size = Vector2(397, 625)
      }),
      Gui.Control({
        Size = Vector2(819, 611),
        Location = Vector2(8, 17),
        BackgroundColor = colw,
        Skin = SkinF.rank_001,
        ComFuc.ComControl(nil, Vector2(300, 35), Vector2(260, 14), 255, SkinF.rank_002),
        ComFuc.ComLabel(nil, GetUTF8Text("UI_social_add_rank_button_04"), Vector2(160, 34), Vector2(560, 14), 0, 16, colt, "kAlignRightMiddle"),
        ComFuc.ComCheckBox("showOnlyFriend", nil, Vector2(30, 30), Vector2(728, 14)),
        ComSubTab("mod_1_1", Vector2(155, 93), Vector2(92, 58), Vector2(133, 20), Vector2(11, 73), SkinF.rank_003[1], SkinF.rank_014[1]),
        ComSubTab("mod_1_2", Vector2(155, 93), Vector2(332, 58), Vector2(133, 20), Vector2(11, 73), SkinF.rank_003[2], SkinF.rank_014[2]),
        ComSubTab("mod_1_3", Vector2(155, 93), Vector2(572, 58), Vector2(133, 20), Vector2(11, 73), SkinF.rank_003[3], SkinF.rank_014[3]),
        ComFuc.ComButton("mod_2_1", GetUTF8Text("button_social_my_rank"), Vector2(150, 50), Vector2(334, 56), 16, false, false, SkinF.signPresent_012),
        ComFuc.ComControl("cover_mod_2_1", Vector2(150, 50), Vector2(334, 56)),
        ComSubTab("mod_4_1", Vector2(104, 94), Vector2(230, 57), Vector2(69, 21), Vector2(17, 73), SkinF.rank_012[1], SkinF.rank_015[1]),
        ComSubTab("mod_4_2", Vector2(104, 94), Vector2(486, 57), Vector2(69, 21), Vector2(17, 73), SkinF.rank_012[2], SkinF.rank_015[2]),
        ComFuc.ComPagesBar("pb_rank", Vector2(279, 563)),
        ComFuc.ComLabel("leave_times", "", Vector2(220, 40), Vector2(62, 562), 0, 16, colt),
        ComSubTab("mod_5_1", Vector2(155, 93), Vector2(203, 58), Vector2(133, 20), Vector2(11, 73), SkinF.rank_016[1], SkinF.rank_017[1]),
        ComSubTab("mod_5_2", Vector2(155, 93), Vector2(459, 58), Vector2(133, 20), Vector2(11, 73), SkinF.rank_016[2], SkinF.rank_017[2]),
        ComFuc.ComLabel("left_info", nil, Vector2(220, 40), Vector2(62, 10), 0, 16, colt, "kAlignLeftMiddle"),
        Gui.Control("main_left_son")({
          Size = Vector2(670, 394),
          Location = Vector2(74, 150),
          Gui.Control({
            Size = Vector2(670, 34),
            BackgroundColor = colw,
            Skin = SkinF.rank_004,
            ComFuc.ComLabel(nil, GetUTF8Text("UI_social_rank_title"), Vector2(62, 34), Vector2(8, 0), 0, 16, colw),
            ComFuc.ComLabel("R_R", testRR[1], Vector2(160, 34), Vector2(75, 0), 0, 16, colw),
            ComFuc.ComLabel("R_N", testRN[1], Vector2(160, 34), Vector2(379, 0), 0, 16, colw),
            ComFuc.ComLabel("R_G", GetUTF8Text("UI_lobby_Guild"), Vector2(160, 34), Vector2(395, 0), 0, 16, colw),
            ComFuc.ComLabel("R_P", textRP[1], Vector2(142, 34), Vector2(516, 0), 0, 16, colw, "kAlignCenterMiddle")
          }),
          ComBar(1),
          ComBar(2),
          ComBar(3),
          ComBar(4),
          ComBar(5),
          ComBar(6),
          ComBar(7),
          ComBar(8),
          ComBar(9),
          ComBar(10),
          ComBar(11),
          ComBar(12)
        })
      }),
      ComCB("equip_1", Vector2(56, 56), Vector2(831, 38), 2, 1),
      ComCB("equip_2", Vector2(56, 56), Vector2(889, 38), 2, 2),
      ComCB("equip_3", Vector2(56, 56), Vector2(947, 38), 2, 3),
      ComCB("equip_4", Vector2(56, 56), Vector2(1005, 38), 5, 1),
      ComFuc.ComLabel("ability_power", textRP[2], Vector2(168, 24), Vector2(760, 461), 0, 18, colt, "kAlignRightMiddle"),
      ComFuc.ComLabel("fight_lf", 0, Vector2(160, 36), Vector2(934, 454), 0, 0, colw, nil, nil, true, SkinF.info_number_1),
      ComFuc.ComLabel("power_adventure", 0, Vector2(160, 36), Vector2(934, 454), 0, 0, colw, nil, nil, true, SkinF.info_number_1),
      ComFuc.ComControl(nil, Vector2(330, 32), Vector2(787, 492), 255, SkinF.rank_007),
      ComFuc.ComLabel("rankp_no", nil, Vector2(52, 36), Vector2(821, 490), 255, 16, colw, "kAlignCenterMiddle", SkinF.rank_008[1]),
      ComFuc.ComControl("rankp_job", Vector2(30, 30), Vector2(874, 493), 255, SkinF.personalInfo_job[2]),
      ComFuc.ComLabel("rankp_lv", "LV" .. 1, Vector2(42, 24), Vector2(910, 496), 0, 16, colw),
      ComFuc.ComLabel("rankp_name", 1, Vector2(250, 24), Vector2(952, 496), 0, 16, colw),
      ComFuc.ComLabel("bonus_map", 0, Vector2(352, 32), Vector2(768, 536), 255, 20, colw, "kAlignCenterMiddle", SkinF.rank_018),
      Gui.Control("right_button")({
        Size = Vector2(97, 38),
        Location = Vector2(650, 579),
        Visible = false,
        ComFuc.ComButton("herolist", GetUTF8Text("msgbox_enhance_hero_directory"), Vector2(97, 38), Vector2(0, 0), 16, false, false)
      })
    }),
    ComFuc.ComMenu("menu_1"),
    ComFuc.MainTabBtn("btn_main_1", GetUTF8Text("tips_social_rank_01"), Vector2(28, 5)),
    ComFuc.MainTabBtn("btn_main_2", GetUTF8Text("tips_social_rank_03"), Vector2(448, 5)),
    ComFuc.MainTabBtn("btn_main_3", GetUTF8Text("UI_lobby_consortia_01"), Vector2(658, 5)),
    ComFuc.MainTabBtn("btn_main_4", GetUTF8Text("UI_social_add_rank_name_01"), Vector2(868, 5)),
    ComFuc.MainTabBtn("btn_main_5", GetUTF8Text("UI_social_add_rank_explore"), Vector2(238, 5))
  })
})
ui.leave_times.AutoWrap = true
ui.mod_1_1.Hint = GetUTF8Text("UI_social_rank_01_02")
ui.mod_1_2.Hint = GetUTF8Text("UI_social_rank_01_01")
ui.mod_1_3.Hint = GetUTF8Text("UI_social_rank_01_03")
ui.cover_mod_2_1.Hint = GetUTF8Text("tips_social_rank_error")
ui.mod_4_1.Hint = GetUTF8Text("UI_social_add_rank_name_02")
ui.mod_4_2.Hint = GetUTF8Text("UI_social_add_rank_name_03")
ui.mod_5_1.Hint = GetUTF8Text("UI_social_add_rank_explore_strength")
ui.mod_5_2.Hint = GetUTF8Text("UI_social_add_rank_explore_pass_mark")
ui["menu_" .. 1]:AddItem(GetUTF8Text("button_common_Chat"))
ui["menu_" .. 1]:AddItem(GetUTF8Text("button_common_Add_Friends"))
ui["menu_" .. 1]:AddItem(GetUTF8Text("button_common_Info"))
ui.menu_1:Close()
for i = 1, 12 do
  ui["bar_rank_n_" .. i].AutoWrap = false
  local DealPlayerInfo = GetUTF8Text("button_common_Info")
end
local DealItemInfo = function(data)
  ComFuc.DealRankInfoEquip(data.player.equipAvatar)
  ComFuc.ClearRankInfoIndependentTrinket()
  if data.player.equips then
    for i, v in ipairs(data.player.equips) do
      lg:Set_Rank_Player_Independent_Trinket(v.type, v.resource)
    end
  end
  ui.equip_4_son.Skin = SkinF.personalInfo_quality[data.player.equipAvatarGrade] or SkinF.personalInfo_quality[1]
  if data.player.avatarSubType == 1 then
    ui.equip_4_s.Skin = SkinF.personalInfo_095
  elseif data.player.avatarSubType == 2 then
    ui.equip_4_s.Skin = SkinF.personalInfo_262
  end
  
  function ui.equip_4_cover.EventMouseEnter(sender, e)
    sender.Skin = SkinF.personalInfo_pet_preview
    Tip.SetRpc(tip_player_interface[5], {
      t = 5,
      pid = itemPid,
      aid = data.player.avatarId
    })
    Tip.SetUseDescription(false)
    Tip.SetOwner(sender)
  end
  
  function ui.equip_4_cover.EventMouseLeave(sender, e)
    sender.Skin = SkinF.skin_touming
  end
end
local SelItem = function(data)
  for i, v in ipairs(data.slots) do
    if v.type == 2 then
      for i = 1, 3 do
        ui["equip_" .. i .. "_s"].Visible = i <= #v
        ui["equip_" .. i .. "_level"].Visible = false
        ui["equip_" .. i].Enable = i <= #v
        if i <= #v then
          local p = v[i]
          ui["equip_" .. i .. "_son"].Skin = SkinF.personalInfo_quality[tonumber(p.grade)]
          ui["equip_" .. i .. "_s"].Skin = Gui.ControlSkin({
            BackgroundImage = Gui.Image("ui/skinF/lobby/" .. p.resource .. ".tga", Vector4(0, 0, 0, 0))
          })
          ui["equip_" .. i .. "_cover"].EventMouseEnter = function(sender, e)
            sender.Skin = SkinF.personalInfo_pet_preview
            Tip.SetRpc(tip_player_interface[2], {
              t = 2,
              pid = p.itemid
            })
            Tip.SetUseDescription(false)
            Tip.SetOwner(sender)
          end
          ui["equip_" .. i .. "_cover"].EventMouseLeave = function(sender, e)
            sender.Skin = SkinF.skin_touming
          end
          ui["equip_" .. i].EventClick = function(sender, e)
            lg:RankSetWeapon(p.subType, p.resource, p.refitLevel or 0, false)
          end
          ComFuc.ShowUpgradeLevel(p, 2, ui["equip_" .. i .. "_level"], ui["equip_" .. i .. "_level_text"])
        else
          ui["equip_" .. i .. "_son"].Skin = SkinF.skin_touming
          ui["equip_" .. i .. "_s"].Skin = SkinF.skin_touming
          ui["equip_" .. i .. "_cover"].Skin = SkinF.skin_touming
        end
      end
    end
  end
end
local UpOrDownClick = function(i)
  if not Deta[i] then
    return
  end
  temDt = Deta[i]
  itemPid = temDt.playerId
  for j = 1, 12 do
    ui["bar_" .. j].PushDown = i == j
  end
  ui.rankp_job.Skin = SkinF.personalInfo_job[temDt.occupation % 4 + 1]
  ui.rankp_lv.Text = "LV" .. temDt.playerLevel
  ui.rankp_name.Text = temDt.playerName
  if mainCurrTab ~= 4 then
    ui.fight_lf.Text = temDt.battleForce
  elseif subCurrTab == 1 then
    ui.fight_lf.Text = temDt.praiseNum
  elseif subCurrTab == 2 then
    ui.fight_lf.Text = temDt.defameNum
  end
  ui.power_adventure.Text = temDt.ventureForce
  tm = temDt.ranking
  if tm <= 3 then
    ui.rankp_no.Text = nil
    ui.rankp_no.BackgroundColor = colw
    ui.rankp_no.Skin = SkinF.rank_008[tm]
  else
    ui.rankp_no.Text = tm
    ui.rankp_no.BackgroundColor = col0
  end
  ui.menu_1:SetEnable(0, temDt.playerId ~= SelectCharacter.roleServerId)
  ui.menu_1:SetEnable(1, temDt.playerId ~= SelectCharacter.roleServerId)
  ui.menu_1:SetEnable(2, temDt.playerId ~= SelectCharacter.roleServerId)
  if mainCurrTab ~= 4 then
    rpc.safecall("player_info", {
      playerId = temDt.playerId
    }, DealPlayerInfo)
  else
    rpc.safecall("rank_playerinfo", {
      playerId = temDt.playerId,
      avatarid = temDt.pAvatarId,
      type = subCurrTab + 4
    }, DealPlayerInfo)
  end
  rpc.safecall("item_info", {
    playerId = temDt.playerId
  }, DealItemInfo)
end
local DealPlayerInfo, DealOnePage = function(i)
  rpc.safecall("avatar_praise", {
    playerId = Deta[i].playerId,
    avatarid = Deta[i].pAvatarId,
    ispraise = subCurrTab == 1
  }, function()
    if mainCurrTab == 4 then
      if subCurrTab == 1 then
        Deta.time1 = Deta.time1 - 1
        ui.leave_times.Text = string.format(GetUTF8Text("UI_common_ballot_01"), Deta.time1)
      elseif subCurrTab == 2 then
        Deta.time2 = Deta.time2 - 1
        ui.leave_times.Text = string.format(GetUTF8Text("UI_common_ballot_02"), Deta.time2)
      end
    end
  end)
end, ui["bar_rank_n_" .. i]
local DealOnePage, ShowBonusMap = function()
  ui.bonus_map.Visible = false
  local t = #Deta
  for i = 1, pPage do
    ui["bar_" .. i].Visible = i <= t
    if i <= t then
      local td = Deta[i]
      if mainCurrTab ~= 3 then
        ui["bar_job" .. i].Skin = SkinF.personalInfo_job[td.occupation % 4 + 1]
        ui["bar_rank_i_" .. i].Skin = SkinF.rank_006[math.max(1, td.rankType)][math.max(1, td.rankLevel)]
        ui["bar_lv_" .. i].Text = "LV" .. td.playerLevel
        if 1 <= td.vipLevel then
          ui["bar_vip" .. i].Skin = SkinF.vipPadShow_004[td.vipLevel + 1]
        else
          ui["bar_vip" .. i].Skin = SkinF.vipPadShow_009
        end
      else
        ui["bar_lv_" .. i].Text = td.teamName or ""
      end
      ui["bar_vip" .. i].Visible = mainCurrTab ~= 3 and (1 <= td.vipLevel or td.vipLevel == -1)
      ui["bar_name_" .. i].Text = td.playerName or ""
      tm = td.ranking
      if 3 >= tm then
        ui["bar_NO_" .. i].Text = nil
        ui["bar_NO_" .. i].BackgroundColor = colw
        ui["bar_NO_" .. i].Skin = SkinF.rank_008[tm]
      else
        ui["bar_NO_" .. i].Text = tm
        ui["bar_NO_" .. i].BackgroundColor = col0
      end
      if mainCurrTab == 2 then
        if td.rankLevel <= 9 then
          ui["bar_rank_n_" .. i].Text = GetUTF8Text(player_rank_type[td.rankType]) .. GetUTF8Text("UI_social_rank_lv_0" .. math.max(1, td.rankLevel))
        else
          ui["bar_rank_n_" .. i].Text = GetUTF8Text(player_rank_type[td.rankType]) .. GetUTF8Text("UI_social_rank_lv_" .. math.max(1, td.rankLevel))
        end
      elseif mainCurrTab == 3 then
        ui["bar_rank_n_" .. i].Text = td.name or ""
      elseif mainCurrTab == 4 then
        ui["bar_rank_n_" .. i].Text = Tip._LL(td.pAvatarName)
        ui["bar_rank_n_" .. i].AutoEllipsis = true
      end
      if mainCurrTab == 1 then
        if subCurrTab == 1 then
          ui["bar_power_" .. i].Text = td.battlePoint
        elseif subCurrTab == 2 then
          ui["bar_power_" .. i].Text = td.battleForce
        elseif subCurrTab == 3 then
          ui["bar_power_" .. i].Text = td.mvpNum
        end
      elseif mainCurrTab == 2 then
        ui["bar_power_" .. i].Text = td.rankPoint
      elseif mainCurrTab == 3 then
        ui["bar_power_" .. i].Text = td.teamPower or ""
      elseif mainCurrTab == 4 then
        if subCurrTab == 1 then
          ui["bar_power_" .. i].Text = td.praiseNum
          ui.leave_times.Text = string.format(GetUTF8Text("UI_common_ballot_01"), Deta.time1)
        elseif subCurrTab == 2 then
          ui["bar_power_" .. i].Text = td.defameNum
          ui.leave_times.Text = string.format(GetUTF8Text("UI_common_ballot_02"), Deta.time2)
        end
      end
      if mainCurrTab == 5 then
        if subCurrTab == 1 then
          ui["bar_power_" .. i].Text = td.ventureForce
        elseif subCurrTab == 2 then
          ui["bar_power_" .. i].Text = td.passPoint
        end
      end
    end
  end
end, "bar_rank_n_" .. i
local ShowBonusMap, DealRankingList = function(index)
  local mapInfo = Deta[index]
  if mainCurrTab == 5 and subCurrTab == 2 and mapInfo and mapInfo.ventureMapName then
    if GetUTF8Text(mapInfo.ventureMapName) == "0" then
      ui.bonus_map.Visible = false
    else
      ui.bonus_map.Visible = true
      ui.bonus_map.Text = GetUTF8Text(ComFuc.difficulty_list[mapInfo.ventureMapDifficulty + 1]) .. GetUTF8Text("UI_lobby_player_raid") .. GetUTF8Text(mapInfo.ventureMapName)
    end
  end
end, i
local DealRankingList, rpc_DealRanklist = function(data)
  ui.right_button.Visible = false
  local t = os.date("*t", os.time())
  ui.left_info.Text = GetUTF8Text("UI_lobby_paihangbang_text") .. GetMatchedUTF8Text("UI_social_posted_year," .. t.year) .. GetMatchedUTF8Text("UI_social_posted_month," .. t.month)
  if ComFuc.isOpenHeroList then
    for i = 1, #ComFuc.isOpenHeroList do
      if ComFuc.isOpenHeroList[i].value == pType then
        ui.right_button.Visible = true
        break
      end
    end
  end
  Deta = data.rankingList or data.rankingGuildList
  ui.pb_rank.CurrIndex = data.page
  ui.pb_rank.PageCount = data.pageCount
  Deta.time1 = data.thisDayPraiseNum
  Deta.time2 = data.thisDayDefameNum
  DealOnePage()
  SelItem(1)
  ShowBonusMap(1)
end, GetUTF8Text("button_common_Info")
local rpc_DealRanklist, SelSecTab = function(pg)
  local tif = "player_ranking_list"
  if pType == 7 then
    tif = "guild_power_rank"
  end
  rpc.safecall(tif, {
    t = pType,
    onlyf = onlyFriend,
    page = pg or 1,
    pageSize = pPage
  }, DealRankingList)
end, GetUTF8Text("button_common_Info")
local SelSecTab, SelMainTab = function(i)
  if subCurrTab ~= i then
    subCurrTab = i
  end
  ui.R_R.Text = testRR[1]
  ui.leave_times.Visible = mainCurrTab == 4
  if mainCurrTab == 1 then
    for j = 1, 3 do
      ui["mod_1_" .. j].PushDown = i == j
      if i == j and i ~= 3 then
        ui.ability_power.Text = textRP[i]
      elseif i == 3 then
        ui.ability_power.Text = GetUTF8Text("UI_lobby_MVP_times_01")
      end
    end
    ui.R_P.Text = textRP[i]
    pType = i
    if i == 1 then
      pType = 0
    end
  elseif mainCurrTab == 2 then
    pType = 4
    ui.R_N.Text = testRN[1]
    ui.R_P.Text = textRP[4]
    ui.ability_power.Text = textRP[4]
  elseif mainCurrTab == 3 then
    pType = 7
    ui.R_R.Text = testRR[2]
    ui.R_N.Text = testRN[3]
    ui.R_P.Text = textRP[7]
    ui.ability_power.Text = textRP[7]
  elseif mainCurrTab == 4 then
    for j = 1, 2 do
      ui["mod_4_" .. j].PushDown = i == j
      if i == j then
        ui.ability_power.Text = textRP[4 + i]
      end
    end
    for k = 1, 12 do
      ui["bar_btn_" .. k].Skin = SkinF.rank_013[i]
    end
    pType = i + 4
    ui.R_N.Text = testRN[2]
    ui.R_P.Text = textRP[i + 4]
  elseif mainCurrTab == 5 then
    for j = 1, 2 do
      ui["mod_5_" .. j].PushDown = i == j
      ui.R_P.Text = textRP[7 + i]
      if i == j then
        ui.ability_power.Text = textRP[7 + i]
      end
    end
    pType = i + 8
  end
  rpc_DealRanklist()
end, GetUTF8Text("button_common_Info")

function SelMainTab(i)
  subCurrTab = 0
  if mainCurrTab ~= i then
    mainCurrTab = i
  end
  for j = 1, 5 do
    ui["btn_main_" .. j].PushDown = i == j
  end
  ui.power_adventure.Visible = i == 5
  ui.fight_lf.Visible = i ~= 5
  for k = 1, 3 do
    ui["mod_1_" .. k].Visible = i == 1
  end
  ui.mod_2_1.Visible = i == 2
  for k = 1, 2 do
    ui["mod_4_" .. k].Visible = i == 4
  end
  for k = 1, 2 do
    ui["mod_5_" .. k].Visible = i == 5
  end
  for k = 1, 12 do
    ui["bar_job" .. k].Visible = i ~= 3
    ui["bar_rank_i_" .. k].Visible = i ~= 3
    ui["bar_rank_n_" .. k].Visible = i ~= 1 and i ~= 5
    ui["bar_btn_" .. k].Visible = i == 4
    if i == 3 then
      ui["bar_lv_" .. k].Size = Vector2(160, 34)
      ui["bar_lv_" .. k].Location = Vector2(75, 0)
      ui["bar_name_" .. k].Size = Vector2(160, 34)
      ui["bar_name_" .. k].Location = Vector2(235, 0)
      ui["bar_rank_n_" .. k].Size = Vector2(160, 34)
      ui["bar_rank_n_" .. k].Location = Vector2(395, 0)
      ui["bar_power_" .. k].Size = Vector2(112, 34)
      ui["bar_power_" .. k].Location = Vector2(555, 0)
    else
      ui["bar_lv_" .. k].Size = Vector2(42, 34)
      ui["bar_lv_" .. k].Location = Vector2(148, 0)
      ui["bar_name_" .. k].Size = Vector2(250, 34)
      ui["bar_name_" .. k].Location = Vector2(196, 0)
      ui["bar_rank_n_" .. k].Size = Vector2(160, 34)
      ui["bar_rank_n_" .. k].Location = Vector2(379, 0)
      ui["bar_power_" .. k].Size = Vector2(112, 34)
      ui["bar_power_" .. k].Location = Vector2(526, 0)
    end
  end
  ui.R_N.Visible = i ~= 1 and i ~= 5
  ui.R_G.Visible = i == 3
  if i == 3 then
    ui.R_N.Location = Vector2(235, 0)
    ui.R_P.Location = Vector2(526, 0)
  else
    ui.R_N.Location = Vector2(379, 0)
    ui.R_P.Location = Vector2(526, 0)
  end
  if i == 1 then
    pPage = 10
    ui.main_left_son.Size = Vector2(670, 394)
    ui.main_left_son.Location = Vector2(74, 150)
  elseif i == 2 then
    pPage = 11
    ui.main_left_son.Size = Vector2(670, 430)
    ui.main_left_son.Location = Vector2(74, 106)
  elseif i == 3 then
    pPage = 12
    ui.main_left_son.Size = Vector2(670, 466)
    ui.main_left_son.Location = Vector2(74, 70)
  elseif i == 4 then
    pPage = 10
    ui.main_left_son.Size = Vector2(670, 394)
    ui.main_left_son.Location = Vector2(74, 150)
  elseif i == 5 then
    ui.main_left_son.Size = Vector2(670, 394)
    ui.main_left_son.Location = Vector2(74, 150)
  end
  SelSecTab(1)
end

for i = 1, 5 do
  ui["btn_main_" .. i].EventClick = function(sender, e)
    SelMainTab(i)
  end
end
for i = 1, 3 do
  ui["mod_1_" .. i].EventClick = function(sender, e)
    SelSecTab(i)
  end
end
for i = 1, 2 do
  ui["mod_4_" .. i].EventClick = function(sender, e)
    SelSecTab(i)
  end
end
for i = 1, 2 do
  ui["mod_5_" .. i].EventClick = function(sender, e)
    SelSecTab(i)
  end
end
for i = 1, 12 do
  ui["bar_" .. i].EventClick = function(sender, e)
    SelItem(i)
    ShowBonusMap(i)
  end
  ui["bar_" .. i].EventRightClick = function(sender, e)
    gui:PlayAudio("selecttask")
    if mainCurrTab ~= 3 then
      ui.menu_1.Location = sender.CurrentCursorPosition + Vector2(ComFuc.locationChanged, 0)
      ui.menu_1:Open()
    end
    SelItem(i)
  end
end
for i = 1, 12 do
  ui["bar_btn_" .. i].EventClick = function(sender, e)
    UpOrDownClick(i)
  end
end

function ui.showOnlyFriend.EventCheckChanged(sender, e)
  if sender.Check then
    onlyFriend = 1
  else
    onlyFriend = 0
  end
  SelSecTab(subCurrTab)
end

function ui.menu_1.EventClick(sender, e)
  local t = sender.SelectedIndex
  if t == 0 then
    ChatBar.OpenFriendChatPair(temDt.playerId, temDt.playerName)
  elseif t == 1 then
    Sociality.AddFriend(temDt.playerId, temDt.playerLevel)
  elseif t == 2 then
    LookInfo.Show(temDt.playerId)
  end
end

function ui.pb_rank.EventIndexChanged(sender, e)
  rpc_DealRanklist(ui.pb_rank.CurrIndex)
end

function ui.mod_2_1.EventClick(sender, e)
  require("rank/rank.lua")
  Rank.Show()
end

function Show(winRoot)
  mainCurrTab = 0
  subCurrTab = 0
  SelMainTab(1)
  ui.cover_mod_2_1.Visible = false
  ui.main.Parent = winRoot
  game.EnterRankList = true
end

function Hide()
  ui.main.Parent = nil
  game.EnterRankList = false
end

function ui.herolist.EventClick(send, e)
  if not HeroAndAward then
    require("HeroAndAward.lua")
  end
  HeroAndAward.ShowHero(pType)
end
