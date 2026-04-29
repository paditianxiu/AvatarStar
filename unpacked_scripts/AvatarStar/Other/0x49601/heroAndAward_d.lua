module("HeroAndAward", package.seeall)
local standard_x = 219
local playerRank = 1
local playerNum = 10
local temp_num = 1
local pType = 0
local resDir = "/ui/skinF/lobby/"
selectYear = nil
selectSeason = nil
rankInfo = {}
avatarInfo = {}
yearList = {}
seasonList = {}
local tempAvatar, ComputLocation = {}, {}
local ComputLocation, ComCharacterStaticCard = function(i)
  local lcx, lcy
  if 1 <= i then
    lcx = standard_x * (i - 1)
  else
    lcx = 0
  end
  lcy = 0
  return Vector2(lcx, lcy)
end, nil
local ComCharacterStaticCard, ListCardCB = function(name, i)
  return Gui.CharacterStaticCard(name)({
    Size = Vector2(198, 262),
    Location = Vector2(0, 0),
    BackgroundColor = ARGB(0, 0, 0, 0),
    ID = i + 18
  })
end, nil

function ListCardCB(i)
  return Gui.Control("rank_" .. i)({
    Size = Vector2(198, 334),
    Location = ComputLocation(i),
    BackgroundColor = ComFuc.colw,
    Skin = SkinF.hero_list_player_background,
    Visible = false,
    Gui.Control("player_card_" .. i)({
      Location = Vector2(0, 0),
      Size = Vector2(198, 262),
      BackgroundColor = colw,
      Skin = SkinF.personalInfo_083[1],
      Visible = false,
      Gui.DragBtn("player_card_b_" .. i)({
        Size = Vector2(198, 262),
        BackgroundColor = ARGB(0, 255, 255, 255),
        Visible = false,
        ComCharacterStaticCard("player_card_s_" .. i, i)
      }),
      Gui.Control("mouse_protect_" .. i)({
        Location = Vector2(0, 0),
        Size = Vector2(198, 262),
        BackgroundColor = ARGB(0, 255, 255, 255)
      })
    }),
    Gui.Control("group_" .. i)({
      Location = Vector2(0, 0),
      Size = Vector2(198, 262),
      BackgroundColor = colw,
      Visible = false,
      ComFuc.ComLabel("group_name_" .. i, nil, Vector2(198, 20), Vector2(0, 16), 0, 20, ARGB(255, 255, 0, 0), "kAlignCenterMiddle"),
      ComFuc.ComLabel("team_header_name_" .. i, nil, Vector2(198, 20), Vector2(0, 42), 0, 16, ARGB(255, 133, 83, 65), "kAlignCenterMiddle"),
      ComFuc.ComControl("group_resource_" .. i, Vector2(120, 120), Vector2(39, 107), 255)
    }),
    Gui.Control("rank_info_" .. i)({
      Size = Vector2(198, 72),
      Location = Vector2(0, 262),
      BackgroundColor = ComFuc.colw,
      ComFuc.ComLabel("rank_name_" .. i, nil, Vector2(96, 16), Vector2(88, 27), 0, 16, ARGB(255, 0, 0, 0)),
      ComFuc.ComLabel("rank_point_" .. i, nil, Vector2(80, 16), Vector2(88, 48), 0, 16, ARGB(255, 255, 0, 0))
    })
  })
end

local ui_hero, Show = Gui.Create()({
  Gui.Control("main")({
    Dock = "kDockFill",
    BackgroundColor = ARGB(128, 0, 0, 0),
    Gui.Control("background")({
      Size = Vector2(1098, 546),
      Dock = "kDockCenter",
      BackgroundColor = ComFuc.colw,
      Skin = SkinF.hero_list_background,
      ComFuc.ComButton("close", nil, Vector2(24, 24), Vector2(1059, 18), 16, false, false, SkinF.lookInfo_002),
      Gui.Control("tital")({
        Size = Vector2(229, 50),
        Location = Vector2(435, 39),
        BackgroundColor = ComFuc.colw,
        Skin = SkinF.hero_list_tital
      }),
      Gui.Control("show_window")({
        Size = Vector2(855, 334),
        Location = Vector2(121, 123),
        ListCardCB(1),
        ListCardCB(2),
        ListCardCB(3),
        ListCardCB(4)
      }),
      ComFuc.ComLabel("subhead", nil, Vector2(265, 16), Vector2(769, 78), 0, 16, ARGB(255, 82, 54, 44)),
      ComFuc.ComButton("left_button", nil, Vector2(39, 108), Vector2(66, 221), 16, false, false, SkinF.hero_list_left_button, false),
      ComFuc.ComButton("right_button", nil, Vector2(39, 108), Vector2(989, 221), 16, false, false, SkinF.hero_list_right_button, true),
      ComFuc.ComComboBox("years", Vector2(130, 30), Vector2(121, 484)),
      ComFuc.ComComboBox("season", Vector2(120, 30), Vector2(256, 484))
    })
  })
}), Gui.Create()({
  Gui.Control("main")({
    Dock = "kDockFill",
    BackgroundColor = ARGB(128, 0, 0, 0),
    Gui.Control("background")({
      Size = Vector2(1098, 546),
      Dock = "kDockCenter",
      BackgroundColor = ComFuc.colw,
      Skin = SkinF.hero_list_background,
      ComFuc.ComButton("close", nil, Vector2(24, 24), Vector2(1059, 18), 16, false, false, SkinF.lookInfo_002),
      Gui.Control("tital")({
        Size = Vector2(229, 50),
        Location = Vector2(435, 39),
        BackgroundColor = ComFuc.colw,
        Skin = SkinF.hero_list_tital
      }),
      Gui.Control("show_window")({
        Size = Vector2(855, 334),
        Location = Vector2(121, 123),
        ListCardCB(1),
        ListCardCB(2),
        ListCardCB(3),
        ListCardCB(4)
      }),
      ComFuc.ComLabel("subhead", nil, Vector2(265, 16), Vector2(769, 78), 0, 16, ARGB(255, 82, 54, 44)),
      ComFuc.ComButton("left_button", nil, Vector2(39, 108), Vector2(66, 221), 16, false, false, SkinF.hero_list_left_button, false),
      ComFuc.ComButton("right_button", nil, Vector2(39, 108), Vector2(989, 221), 16, false, false, SkinF.hero_list_right_button, true),
      ComFuc.ComComboBox("years", Vector2(130, 30), Vector2(121, 484)),
      ComFuc.ComComboBox("season", Vector2(120, 30), Vector2(256, 484))
    })
  })
})
local Show, giveNoPlayerInfo = function()
  DrawPlayer()
  if playerRank >= playerNum - 3 then
    ui_hero.right_button.Enable = false
  else
    ui_hero.right_button.Enable = true
  end
  if playerRank == 1 or playerNum < 4 then
    ui_hero.left_button.Enable = false
  else
    ui_hero.left_button.Enable = true
  end
  ui_hero.main.Parent = gui
end, {
  Gui.Control("main")({
    Dock = "kDockFill",
    BackgroundColor = ARGB(128, 0, 0, 0),
    Gui.Control("background")({
      Size = Vector2(1098, 546),
      Dock = "kDockCenter",
      BackgroundColor = ComFuc.colw,
      Skin = SkinF.hero_list_background,
      ComFuc.ComButton("close", nil, Vector2(24, 24), Vector2(1059, 18), 16, false, false, SkinF.lookInfo_002),
      Gui.Control("tital")({
        Size = Vector2(229, 50),
        Location = Vector2(435, 39),
        BackgroundColor = ComFuc.colw,
        Skin = SkinF.hero_list_tital
      }),
      Gui.Control("show_window")({
        Size = Vector2(855, 334),
        Location = Vector2(121, 123),
        ListCardCB(1),
        ListCardCB(2),
        ListCardCB(3),
        ListCardCB(4)
      }),
      ComFuc.ComLabel("subhead", nil, Vector2(265, 16), Vector2(769, 78), 0, 16, ARGB(255, 82, 54, 44)),
      ComFuc.ComButton("left_button", nil, Vector2(39, 108), Vector2(66, 221), 16, false, false, SkinF.hero_list_left_button, false),
      ComFuc.ComButton("right_button", nil, Vector2(39, 108), Vector2(989, 221), 16, false, false, SkinF.hero_list_right_button, true),
      ComFuc.ComComboBox("years", Vector2(130, 30), Vector2(121, 484)),
      ComFuc.ComComboBox("season", Vector2(120, 30), Vector2(256, 484))
    })
  })
}
local giveNoPlayerInfo, AddPlayerInfo = function(data)
  avatarInfo[playerRank + 3] = {}
  avatarInfo[playerRank + 3].id = data.playerId
  avatarInfo[playerRank + 3].name = data.playerName
  avatarInfo[playerRank + 3].equipAvatar = tempAvatar
  avatarInfo[playerRank + 3].avatarId = data.pAvatarId
  Show()
end, Gui.Control("main")({
  Dock = "kDockFill",
  BackgroundColor = ARGB(128, 0, 0, 0),
  Gui.Control("background")({
    Size = Vector2(1098, 546),
    Dock = "kDockCenter",
    BackgroundColor = ComFuc.colw,
    Skin = SkinF.hero_list_background,
    ComFuc.ComButton("close", nil, Vector2(24, 24), Vector2(1059, 18), 16, false, false, SkinF.lookInfo_002),
    Gui.Control("tital")({
      Size = Vector2(229, 50),
      Location = Vector2(435, 39),
      BackgroundColor = ComFuc.colw,
      Skin = SkinF.hero_list_tital
    }),
    Gui.Control("show_window")({
      Size = Vector2(855, 334),
      Location = Vector2(121, 123),
      ListCardCB(1),
      ListCardCB(2),
      ListCardCB(3),
      ListCardCB(4)
    }),
    ComFuc.ComLabel("subhead", nil, Vector2(265, 16), Vector2(769, 78), 0, 16, ARGB(255, 82, 54, 44)),
    ComFuc.ComButton("left_button", nil, Vector2(39, 108), Vector2(66, 221), 16, false, false, SkinF.hero_list_left_button, false),
    ComFuc.ComButton("right_button", nil, Vector2(39, 108), Vector2(989, 221), 16, false, false, SkinF.hero_list_right_button, true),
    ComFuc.ComComboBox("years", Vector2(130, 30), Vector2(121, 484)),
    ComFuc.ComComboBox("season", Vector2(120, 30), Vector2(256, 484))
  })
})
local AddPlayerInfo, avatar_card_exist = function(data)
  avatarInfo[playerRank + 3] = data.player
  Show()
end, Gui.Control("main")({
  Dock = "kDockFill",
  BackgroundColor = ARGB(128, 0, 0, 0),
  Gui.Control("background")({
    Size = Vector2(1098, 546),
    Dock = "kDockCenter",
    BackgroundColor = ComFuc.colw,
    Skin = SkinF.hero_list_background,
    ComFuc.ComButton("close", nil, Vector2(24, 24), Vector2(1059, 18), 16, false, false, SkinF.lookInfo_002),
    Gui.Control("tital")({
      Size = Vector2(229, 50),
      Location = Vector2(435, 39),
      BackgroundColor = ComFuc.colw,
      Skin = SkinF.hero_list_tital
    }),
    Gui.Control("show_window")({
      Size = Vector2(855, 334),
      Location = Vector2(121, 123),
      ListCardCB(1),
      ListCardCB(2),
      ListCardCB(3),
      ListCardCB(4)
    }),
    ComFuc.ComLabel("subhead", nil, Vector2(265, 16), Vector2(769, 78), 0, 16, ARGB(255, 82, 54, 44)),
    ComFuc.ComButton("left_button", nil, Vector2(39, 108), Vector2(66, 221), 16, false, false, SkinF.hero_list_left_button, false),
    ComFuc.ComButton("right_button", nil, Vector2(39, 108), Vector2(989, 221), 16, false, false, SkinF.hero_list_right_button, true),
    ComFuc.ComComboBox("years", Vector2(130, 30), Vector2(121, 484)),
    ComFuc.ComComboBox("season", Vector2(120, 30), Vector2(256, 484))
  })
})
local avatar_card_exist, HideHero = function(num)
  local flag = 0
  if pType == 5 or pType == 6 then
    for i = 1, num - 1 do
      if rankInfo[num].pAvatarId == avatarInfo[i].avatarId then
        flag = flag + 1
        break
      end
    end
  else
    for i = 1, num - 1 do
      if rankInfo[num].playerId == avatarInfo[i].id then
        flag = flag + 1
        break
      end
    end
  end
  if flag == 0 then
    if "0" == rankInfo[num].playerId then
      giveNoPlayerInfo(rankInfo[num])
    else
      gui:PlayAudio("prompt")
      if pType == 5 or pType == 6 then
        rpc.safecall("rank_playerinfo", {
          playerId = rankInfo[num].playerId,
          type = pType,
          avatarid = rankInfo[num].pAvatarId
        }, AddPlayerInfo)
      else
        rpc.safecall("player_info", {
          playerId = rankInfo[num].playerId
        }, AddPlayerInfo)
      end
    end
  else
    Show()
  end
end, Gui.Control("main")({
  Dock = "kDockFill",
  BackgroundColor = ARGB(128, 0, 0, 0),
  Gui.Control("background")({
    Size = Vector2(1098, 546),
    Dock = "kDockCenter",
    BackgroundColor = ComFuc.colw,
    Skin = SkinF.hero_list_background,
    ComFuc.ComButton("close", nil, Vector2(24, 24), Vector2(1059, 18), 16, false, false, SkinF.lookInfo_002),
    Gui.Control("tital")({
      Size = Vector2(229, 50),
      Location = Vector2(435, 39),
      BackgroundColor = ComFuc.colw,
      Skin = SkinF.hero_list_tital
    }),
    Gui.Control("show_window")({
      Size = Vector2(855, 334),
      Location = Vector2(121, 123),
      ListCardCB(1),
      ListCardCB(2),
      ListCardCB(3),
      ListCardCB(4)
    }),
    ComFuc.ComLabel("subhead", nil, Vector2(265, 16), Vector2(769, 78), 0, 16, ARGB(255, 82, 54, 44)),
    ComFuc.ComButton("left_button", nil, Vector2(39, 108), Vector2(66, 221), 16, false, false, SkinF.hero_list_left_button, false),
    ComFuc.ComButton("right_button", nil, Vector2(39, 108), Vector2(989, 221), 16, false, false, SkinF.hero_list_right_button, true),
    ComFuc.ComComboBox("years", Vector2(130, 30), Vector2(121, 484)),
    ComFuc.ComComboBox("season", Vector2(120, 30), Vector2(256, 484))
  })
})

function HideHero()
  ui_hero.years:RemoveAll()
  ui_hero.season:RemoveAll()
  ui_hero.right_button.Enable = true
  ui_hero.main.Parent = nil
end

function ui_hero.close.EventClick(sender, e)
  HideHero()
end

function ui_hero.right_button.EventClick(sender, e)
  if playerRank < playerNum - 3 then
    playerRank = playerRank + 1
    if playerRank >= playerNum - 3 then
      ui_hero.right_button.Enable = false
      ui_hero.left_button.Enable = true
    else
      ui_hero.right_button.Enable = true
      ui_hero.left_button.Enable = true
    end
    if 7 == pType then
      Show()
    else
      avatar_card_exist(3 + playerRank)
    end
  end
end

local ui_hero.left_button.EventClick, FourPlayerInfo = function(sender, e)
  if 1 < playerRank then
    playerRank = playerRank - 1
    if playerRank <= 1 then
      ui_hero.left_button.Enable = false
      ui_hero.right_button.Enable = true
    else
      ui_hero.left_button.Enable = true
      ui_hero.right_button.Enable = true
    end
    Show()
  end
end, ui_hero.left_button
local FourPlayerInfo, FourPlayerInfoDelete = function(data)
  avatarInfo[temp_num] = data.player
  if temp_num == 4 or temp_num == playerNum then
    Show()
  end
  temp_num = temp_num % 10 + 1
end, function(sender, e)
  if 1 < playerRank then
    playerRank = playerRank - 1
    if playerRank <= 1 then
      ui_hero.left_button.Enable = false
      ui_hero.right_button.Enable = true
    else
      ui_hero.left_button.Enable = true
      ui_hero.right_button.Enable = true
    end
    Show()
  end
end
local FourPlayerInfoDelete, DealHeroList = function(data)
  avatarInfo[temp_num] = {}
  avatarInfo[temp_num].id = data.playerId
  avatarInfo[temp_num].name = data.playerName
  avatarInfo[temp_num].equipAvatar = tempAvatar
  avatarInfo[temp_num].avatarId = data.pAvatarId
  if temp_num == 4 or temp_num == playerNum then
    Show()
  end
  temp_num = temp_num % 10 + 1
end, Gui.Control("main")({
  Dock = "kDockFill",
  BackgroundColor = ARGB(128, 0, 0, 0),
  Gui.Control("background")({
    Size = Vector2(1098, 546),
    Dock = "kDockCenter",
    BackgroundColor = ComFuc.colw,
    Skin = SkinF.hero_list_background,
    ComFuc.ComButton("close", nil, Vector2(24, 24), Vector2(1059, 18), 16, false, false, SkinF.lookInfo_002),
    Gui.Control("tital")({
      Size = Vector2(229, 50),
      Location = Vector2(435, 39),
      BackgroundColor = ComFuc.colw,
      Skin = SkinF.hero_list_tital
    }),
    Gui.Control("show_window")({
      Size = Vector2(855, 334),
      Location = Vector2(121, 123),
      ListCardCB(1),
      ListCardCB(2),
      ListCardCB(3),
      ListCardCB(4)
    }),
    ComFuc.ComLabel("subhead", nil, Vector2(265, 16), Vector2(769, 78), 0, 16, ARGB(255, 82, 54, 44)),
    ComFuc.ComButton("left_button", nil, Vector2(39, 108), Vector2(66, 221), 16, false, false, SkinF.hero_list_left_button, false),
    ComFuc.ComButton("right_button", nil, Vector2(39, 108), Vector2(989, 221), 16, false, false, SkinF.hero_list_right_button, true),
    ComFuc.ComComboBox("years", Vector2(130, 30), Vector2(121, 484)),
    ComFuc.ComComboBox("season", Vector2(120, 30), Vector2(256, 484))
  })
})
local DealHeroList, GetSeasonsUp = function(data)
  temp_num = 1
  playerRank = 1
  playerNum = 10
  rankInfo = {}
  avatarInfo = {}
  tempAvatar = data.avatar
  if pType == 7 then
    rankInfo = data.rankingGuildList
    playerNum = #rankInfo
    Show()
  else
    rankInfo = data.rankingList
    playerNum = #rankInfo
    for i = 1, 4 do
      if rankInfo[i] then
        if rankInfo[i].playerId == "0" then
          FourPlayerInfoDelete(rankInfo[i])
        elseif pType == 5 or pType == 6 then
          rpc.safecall("rank_playerinfo", {
            playerId = rankInfo[i].playerId,
            type = pType,
            avatarid = rankInfo[i].pAvatarId
          }, FourPlayerInfo)
        else
          rpc.safecall("player_info", {
            playerId = rankInfo[i].playerId
          }, FourPlayerInfo)
        end
      end
    end
  end
end, Gui.Control("main")({
  Dock = "kDockFill",
  BackgroundColor = ARGB(128, 0, 0, 0),
  Gui.Control("background")({
    Size = Vector2(1098, 546),
    Dock = "kDockCenter",
    BackgroundColor = ComFuc.colw,
    Skin = SkinF.hero_list_background,
    ComFuc.ComButton("close", nil, Vector2(24, 24), Vector2(1059, 18), 16, false, false, SkinF.lookInfo_002),
    Gui.Control("tital")({
      Size = Vector2(229, 50),
      Location = Vector2(435, 39),
      BackgroundColor = ComFuc.colw,
      Skin = SkinF.hero_list_tital
    }),
    Gui.Control("show_window")({
      Size = Vector2(855, 334),
      Location = Vector2(121, 123),
      ListCardCB(1),
      ListCardCB(2),
      ListCardCB(3),
      ListCardCB(4)
    }),
    ComFuc.ComLabel("subhead", nil, Vector2(265, 16), Vector2(769, 78), 0, 16, ARGB(255, 82, 54, 44)),
    ComFuc.ComButton("left_button", nil, Vector2(39, 108), Vector2(66, 221), 16, false, false, SkinF.hero_list_left_button, false),
    ComFuc.ComButton("right_button", nil, Vector2(39, 108), Vector2(989, 221), 16, false, false, SkinF.hero_list_right_button, true),
    ComFuc.ComComboBox("years", Vector2(130, 30), Vector2(121, 484)),
    ComFuc.ComComboBox("season", Vector2(120, 30), Vector2(256, 484))
  })
})
local GetSeasonsUp, GetSeasonsDown = function(data)
  ui_hero.season:RemoveAll()
  seasonList = data.monthList
  local total = #seasonList
  for i, v in ipairs(seasonList) do
    for j = 1, total - i do
      if tonumber(seasonList[j]) > tonumber(seasonList[j + 1]) then
        local temp = seasonList[j + 1]
        seasonList[j + 1] = seasonList[j]
        seasonList[j] = temp
      end
    end
  end
  for i, v in ipairs(seasonList) do
    ui_hero.season:AddItem(GetMatchedUTF8Text("UI_social_posted_month" .. "," .. seasonList[i]))
  end
  ui_hero.season.SelectedIndex = total - 1
  selectSeason = seasonList[total]
  local time = selectYear .. "-" .. selectSeason .. "-" .. "01 00:00:00"
  rpc.safecall("rank_hero_list", {
    type = pType,
    date = time,
    num = 10
  }, DealHeroList)
end, Gui.Control("main")({
  Dock = "kDockFill",
  BackgroundColor = ARGB(128, 0, 0, 0),
  Gui.Control("background")({
    Size = Vector2(1098, 546),
    Dock = "kDockCenter",
    BackgroundColor = ComFuc.colw,
    Skin = SkinF.hero_list_background,
    ComFuc.ComButton("close", nil, Vector2(24, 24), Vector2(1059, 18), 16, false, false, SkinF.lookInfo_002),
    Gui.Control("tital")({
      Size = Vector2(229, 50),
      Location = Vector2(435, 39),
      BackgroundColor = ComFuc.colw,
      Skin = SkinF.hero_list_tital
    }),
    Gui.Control("show_window")({
      Size = Vector2(855, 334),
      Location = Vector2(121, 123),
      ListCardCB(1),
      ListCardCB(2),
      ListCardCB(3),
      ListCardCB(4)
    }),
    ComFuc.ComLabel("subhead", nil, Vector2(265, 16), Vector2(769, 78), 0, 16, ARGB(255, 82, 54, 44)),
    ComFuc.ComButton("left_button", nil, Vector2(39, 108), Vector2(66, 221), 16, false, false, SkinF.hero_list_left_button, false),
    ComFuc.ComButton("right_button", nil, Vector2(39, 108), Vector2(989, 221), 16, false, false, SkinF.hero_list_right_button, true),
    ComFuc.ComComboBox("years", Vector2(130, 30), Vector2(121, 484)),
    ComFuc.ComComboBox("season", Vector2(120, 30), Vector2(256, 484))
  })
})
local GetSeasonsDown, GetYears = function(data)
  ui_hero.season:RemoveAll()
  seasonList = data.monthList
  local total = #seasonList
  for i, v in ipairs(seasonList) do
    for j = 1, total - i do
      if tonumber(seasonList[j]) > tonumber(seasonList[j + 1]) then
        local temp = seasonList[j + 1]
        seasonList[j + 1] = seasonList[j]
        seasonList[j] = temp
      end
    end
  end
  for i, v in ipairs(seasonList) do
    ui_hero.season:AddItem(GetMatchedUTF8Text("UI_social_posted_month" .. "," .. seasonList[i]))
  end
  ui_hero.season.SelectedIndex = 0
  selectSeason = seasonList[1]
  local time = selectYear .. "-" .. selectSeason .. "-" .. "01 00:00:00"
  rpc.safecall("rank_hero_list", {
    type = pType,
    date = time,
    num = 10
  }, DealHeroList)
end, Gui.Control("main")({
  Dock = "kDockFill",
  BackgroundColor = ARGB(128, 0, 0, 0),
  Gui.Control("background")({
    Size = Vector2(1098, 546),
    Dock = "kDockCenter",
    BackgroundColor = ComFuc.colw,
    Skin = SkinF.hero_list_background,
    ComFuc.ComButton("close", nil, Vector2(24, 24), Vector2(1059, 18), 16, false, false, SkinF.lookInfo_002),
    Gui.Control("tital")({
      Size = Vector2(229, 50),
      Location = Vector2(435, 39),
      BackgroundColor = ComFuc.colw,
      Skin = SkinF.hero_list_tital
    }),
    Gui.Control("show_window")({
      Size = Vector2(855, 334),
      Location = Vector2(121, 123),
      ListCardCB(1),
      ListCardCB(2),
      ListCardCB(3),
      ListCardCB(4)
    }),
    ComFuc.ComLabel("subhead", nil, Vector2(265, 16), Vector2(769, 78), 0, 16, ARGB(255, 82, 54, 44)),
    ComFuc.ComButton("left_button", nil, Vector2(39, 108), Vector2(66, 221), 16, false, false, SkinF.hero_list_left_button, false),
    ComFuc.ComButton("right_button", nil, Vector2(39, 108), Vector2(989, 221), 16, false, false, SkinF.hero_list_right_button, true),
    ComFuc.ComComboBox("years", Vector2(130, 30), Vector2(121, 484)),
    ComFuc.ComComboBox("season", Vector2(120, 30), Vector2(256, 484))
  })
})

function GetYears(data)
  ui_hero.years:RemoveAll()
  yearList = data.yearList
  local total = #yearList
  for i, v in ipairs(yearList) do
    for j = 1, total - i do
      if tonumber(yearList[j]) > tonumber(yearList[j + 1]) then
        local temp = yearList[j + 1]
        yearList[j + 1] = yearList[j]
        yearList[j] = temp
      end
    end
  end
  for i, v in ipairs(yearList) do
    ui_hero.years:AddItem(GetMatchedUTF8Text("UI_social_posted_year" .. "," .. yearList[i]))
  end
  ui_hero.years.SelectedIndex = total - 1
  selectYear = yearList[total]
  rpc.safecall("item_ranking_season", {
    type = pType,
    state = 1,
    year = selectYear
  }, GetSeasonsUp)
end

local ShowHero, ShowHeroList = function(num)
  pType = num
  selectYear = nil
  selectSeason = nil
  rpc.safecall("item_ranking_season", {
    type = pType,
    state = 0,
    year = selectYear
  }, GetYears)
end, function(num)
  pType = num
  selectYear = nil
  selectSeason = nil
  rpc.safecall("item_ranking_season", {
    type = pType,
    state = 0,
    year = selectYear
  }, GetYears)
end

function ShowHeroList(num)
  local j = num + 1 - playerRank
  ui_hero["player_card_" .. j].Visible = false
  ui_hero["group_" .. j].Visible = false
  if pType == 7 then
    ui_hero["group_name_" .. j].Text = rankInfo[num].name
    ui_hero["team_header_name_" .. j].Text = rankInfo[num].playerName
    ui_hero["group_resource_" .. j].Skin = Gui.ControlSkin({
      BackgroundImage = Gui.Image(resDir .. rankInfo[num].resource .. ".tga", Vector4(0, 0, 0, 0))
    })
    ui_hero["rank_name_" .. j].Text = rankInfo[num].teamName
    ui_hero["rank_point_" .. j].Text = rankInfo[num].teamPower or ""
    ui_hero.subhead.Text = GetUTF8Text("UI_lobby_team_writings")
    ui_hero["group_" .. j].Visible = true
  else
    lg:ClearPersonCardData(num + 19 - playerRank)
    if pType == 5 or pType == 6 then
      for i = 1, playerRank + 3 do
        if rankInfo[num].pAvatarId == avatarInfo[i].avatarId then
          ComFuc.SetPersonCardData(avatarInfo[i].equipAvatar, num + 19 - playerRank)
          break
        end
      end
    else
      for i = 1, playerRank + 3 do
        if rankInfo[num].playerId == avatarInfo[i].id then
          ComFuc.SetPersonCardData(avatarInfo[i].equipAvatar, num + 19 - playerRank)
          break
        end
      end
    end
    ui_hero["rank_name_" .. j].Text = rankInfo[num].playerName
    if pType == 0 then
      ui_hero["rank_point_" .. j].Text = rankInfo[num].battlePoint
      ui_hero.subhead.Text = GetUTF8Text("UI_lobby_victory_score_writings")
    elseif pType == 2 then
      ui_hero["rank_point_" .. j].Text = rankInfo[num].battleForce
      ui_hero.subhead.Text = GetUTF8Text("UI_lobby_fighting_writings")
    elseif pType == 3 then
      ui_hero["rank_point_" .. j].Text = rankInfo[num].mvpNum
      ui_hero.subhead.Text = GetUTF8Text("UI_lobby_MVP__writings")
    elseif pType == 4 then
      ui_hero["rank_point_" .. j].Text = rankInfo[num].rankPoint
      ui_hero.subhead.Text = GetUTF8Text("UI_lobby_military_writings")
    elseif pType == 5 then
      ui_hero["rank_point_" .. j].Text = rankInfo[num].praiseNum
      ui_hero.subhead.Text = GetUTF8Text("UI_lobby_praise__writings")
    elseif pType == 6 then
      ui_hero["rank_point_" .. j].Text = rankInfo[num].defameNum
      ui_hero.subhead.Text = GetUTF8Text("UI_lobby_taunt_writings")
    elseif pType == 9 then
      ui_hero["rank_point_" .. j].Text = rankInfo[num].ventureForce
      ui_hero.subhead.Text = GetUTF8Text("UI_lobby_Expedition_writings")
    elseif pType == 10 then
      ui_hero["rank_point_" .. j].Text = rankInfo[num].passPoint
      ui_hero.subhead.Text = GetUTF8Text("UI_lobby_cleard__writings")
    end
    ui_hero["player_card_" .. j].Visible = true
    ui_hero["player_card_b_" .. j].Visible = true
  end
  ui_hero["rank_" .. j].Visible = true
  ui_hero["rank_info_" .. j].Skin = SkinF.hero_list_rank[rankInfo[num].ranking]
end

function DrawPlayer()
  if 1 == playerRank and playerNum <= 4 then
    for i = 1, 4 do
      ui_hero["rank_" .. i].Visible = false
    end
    for i = 0, playerNum - 1 do
      ShowHeroList(i + playerRank)
    end
  else
    for i = 0, 3 do
      ShowHeroList(i + playerRank)
    end
  end
end

function ui_hero.years.EventItemSelected(sender, e)
  selectYear = yearList[ui_hero.years.SelectedIndex + 1]
  rpc.safecall("item_ranking_season", {
    type = pType,
    state = 1,
    year = selectYear
  }, GetSeasonsDown)
end

function ui_hero.season.EventItemSelected(sender, e)
  selectSeason = seasonList[ui_hero.season.SelectedIndex + 1]
  local time = selectYear .. "-" .. selectSeason .. "-" .. "01 00:00:00"
  rpc.safecall("rank_hero_list", {
    type = pType,
    date = time,
    num = 10
  }, DealHeroList)
end
