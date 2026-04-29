module("Expedition", package.seeall)
require("expeditionAddPower.lua")
require("expeditionLookIntroduce.lua")
require("expeditionLookPrize.lua")
require("expeditionRoomCreate.lua")
require("expeditionRoomEnter.lua")
expeditionState = 0
if not CreateRoom then
  require("CreateRoom.lua")
end
boss_game_type = #CreateRoom.game_type_key - 1
selectLevel = 38
local col0 = ComFuc.col0
local colw = ComFuc.colw
local coly = ComFuc.coly
local colb = ARGB(255, 0, 0, 0)
local colr, level_difficulty = ARGB(255, 180, 0, 0), 255

function level_difficulty(i)
  return Gui.Button("level_difficulty_" .. i)({
    Size = Vector2(89, 54),
    Location = Vector2(0, 22 + 55 * (i - 1)),
    Text = nil,
    FontSize = 16,
    CanPushDown = false,
    CanMove = false,
    Skin = SkinF.level_difficulty[i]
  })
end

level_difficulty_num = 2
bad_count = false
limit_name = ""
dtDetail = nil
ui = Gui.Create()({
  Gui.Control("main")({
    Size = Vector2(1128, 645),
    BackgroundColor = colw,
    Skin = SkinF.expedition_001,
    ComFuc.ComControl("item_di_title", Vector2(1118, 40), Vector2(5, 5), 255, SkinF.battle_020[6]),
    ComFuc.ComLabel(nil, GetUTF8Text("UI_lobby_explore_today_stamina"), Vector2(135, 22), Vector2(726, 14), 0, 16, colw),
    ExpBar.ComExpBar("bar_power", Vector2(212, 23), Vector2(863, 13), 0.5, 1, SkinF.lobbyMain_expbar[3], SkinF.lobbyMain_expbar[2], "kAlignCenterMiddle", true),
    Gui.Control("plane_content")({
      Size = Vector2(1128, 645),
      Gui.Control("main_plane")({
        Size = Vector2(1128, 645),
        Gui.Control({
          Size = Vector2(607, 557),
          Location = Vector2(508, 61),
          BackgroundColor = colw,
          Skin = SkinF.expedition_003,
          ComFuc.ComLabel("intro_text", "", Vector2(605, 85), Vector2(1, 5), 0, 16, colw, "kAlignLeftMiddle"),
          ComFuc.ComBtnHasPreIcon("btn_backto_battle", "   " .. GetUTF8Text("button_common_Back"), Vector2(122, 50), Vector2(48, 48), Vector2(13, 491), 16, false, true, SkinF.select_character_038_02, SkinF.icon_expedition[1], 4),
          ComFuc.ComBtnHasPreIcon("btn_create_room", "   " .. GetUTF8Text("UI_inGame_create_team"), Vector2(157, 50), Vector2(48, 48), Vector2(437, 491), 16, false, true, SkinF.SkinStartGame_02, SkinF.icon_expedition[2], 4),
          ComFuc.ComBtnHasPreIcon("btn_enter_room", "   " .. GetUTF8Text("UI_inGame_join_team"), Vector2(157, 50), Vector2(48, 48), Vector2(267, 491), 16, false, true, SkinF.SkinStartGame_02, SkinF.icon_expedition[3], 4)
        }),
        Gui.Control("levels")({
          Size = Vector2(698, 334),
          level_difficulty(1),
          level_difficulty(2),
          Gui.Control("level_select")({
            Size = Vector2(612, 334),
            Location = Vector2(86, 0),
            BackgroundColor = colw,
            Skin = SkinF.skin_playgame_030_1,
            ComFuc.ComLabel(nil, GetUTF8Text("UI_battlefield_Map_Selection"), Vector2(132, 16), Vector2(152, 23), 0, 16, colw, "kAlignCenterMiddle"),
            ComFuc.ComLabel("role_level", GetUTF8Text("tips_abilities_Character_Level"), Vector2(130, 20), Vector2(444, 50), 0, 16, colw),
            ComFuc.ComLabel("count_limit", GetUTF8Text("UI_lobby_people_limit"), Vector2(130, 20), Vector2(444, 74), 0, 16, colw),
            ComFuc.ComLabel("exp_power", GetUTF8Text("UI_abilities_explore_strength"), Vector2(130, 20), Vector2(444, 98), 0, 16, colw),
            ComFuc.ComLabel("power_consume", GetUTF8Text("UI_lobby_stamina_consume"), Vector2(130, 20), Vector2(444, 122), 0, 16, colw),
            ComFuc.ComButton("intro_btn", GetUTF8Text("button_lobby_map_introduced"), Vector2(115, 36), Vector2(452, 230), 16, false, true, SkinF.button_about_map),
            ComFuc.ComButton("look_prize", GetUTF8Text("button_common_Check_Reward"), Vector2(115, 36), Vector2(452, 270), 16, false, true, SkinF.button_about_map),
            Gui.Control("selected_level_background")({
              Size = Vector2(361, 271),
              Location = Vector2(46, 40),
              Visible = false,
              ComFuc.ComControl("selected_difficulty_style", Vector2(318, 184), Vector2(22, 8), 255, SkinF.level_difficulty_style[1]),
              Gui.Picture("selected_level")({
                Size = Vector2(306, 172),
                Location = Vector2(28, 14),
                BackgroundColor = colw,
                KeepAspect = true,
                ForeGroundImage = nil
              }),
              ComFuc.ComControl("selected_difficulty_bg", Vector2(123, 45), Vector2(119, 210), 255, SkinF.level_difficulty_bg[1]),
              ComFuc.ComLabel("selected_difficulty", GetUTF8Text("UI_mission_Elite"), Vector2(123, 45), Vector2(119, 210), 0, 30, ARGB(255, 82, 54, 44), "kAlignCenterMiddle")
            })
          })
        })
      })
    }),
    ComFuc.ComButton("add_power", nil, Vector2(28, 28), Vector2(1087, 11), 0, false, false, SkinF.expedition_002)
  })
})
ui.intro_text.TextPadding = Vector4(12, 8, 12, 12)
ui.intro_text.AutoWrap = true
ui.intro_btn.TextColor = ComFuc.colw
ui.look_prize.TextColor = ComFuc.colw

function ShowLevelDifficultyButton()
  for i = 1, level_difficulty_num do
    if ExpeditionRoom.IsExist(i - 1) then
      ui["level_difficulty_" .. i].Enable = true
      if i == ComFuc.level_difficulty + 1 then
        ui["level_difficulty_" .. i].PushDown = true
      else
        ui["level_difficulty_" .. i].PushDown = false
      end
    else
      ui["level_difficulty_" .. i].Enable = false
    end
  end
end

for i = 1, level_difficulty_num do
  ui["level_difficulty_" .. i].EventClick = function(sender, e)
    if ui["level_difficulty_" .. i].PushDown then
      return
    end
    local state = ptr_cast(game.CurrentState)
    local room_info = state:GetSelfRoomInfo()
    if room_info.RoomState == 2 then
      MessageBox.ShowError(GetUTF8Text("msgbox_battlefield_additional_string_133"), show_error_time)
      return
    end
    ComFuc.level_difficulty = i - 1
    ShowLevelDifficultyButton()
    ExpeditionRoom.Show(ui.levels)
  end
  local DealExpeditionDetail = 8
end

function ui.add_power.EventClick(sender, e)
  ExpeditionAddPower.Show(dtDetail)
end

function ui.intro_btn.EventClick(sender, e)
  ExpeditionLookIntroduce.Show(selectLevel)
end

function ui.look_prize.EventClick(sender, e)
  ExpeditionLookPrize.Show(selectLevel)
end

function ui.btn_backto_battle.EventClick(sender, e)
  LobbyStartGame.SelectMainBtn(1)
end

function ui.btn_create_room.EventClick(sender, e)
  if ComFuc.globalLV >= ComFuc.venture_lv then
    local state = ptr_cast(game.CurrentState)
    local room_info_desc = ptr_new("Client.RoomInfoDesc")
    room_info_desc.room_name = string.format(GetUTF8Text("UI_battlefield_strings_Room"), state:GetCharacterName())
    room_info_desc.use_password = 0
    room_info_desc.game_type = "kBoss"
    room_info_desc.max_client_num = ExpeditionRoom.level_map_data.maxCount
    room_info_desc.spawn_time = 3
    room_info_desc.join_halfway = false
    room_info_desc.check_balance = false
    room_info_desc.level_id = ExpeditionRoom.map_id_of_key[ComFuc.level_difficulty][ExpeditionRoom.what_map_name_select]
    room_info_desc.enter_limit = 3
    state:CreateRoom(room_info_desc)
    ui.main_plane.Parent = nil
    ExpeditionRoomCreate.Show(ui.plane_content)
  else
    MessageBox.ShowWithTwoButtons(GetMatchedUTF8Text("msgbox_battlefield_level10_pveopen" .. "," .. ComFuc.venture_lv), GetUTF8Text("button_common_OK"))
  end
end

local ui.btn_enter_room.EventClick, NormalLimitText = function(sender, e)
  ui.main_plane.Parent = nil
  ExpeditionRoomEnter.Show(ui.plane_content)
end, function(data)
  if data and data.type then
    dtDetail = data
    ui.intro_text.Text = GetUTF8Text(data.detailKey)
    if data.fitnessMaxValue == 0 then
      data.fitnessMaxValue = 1
    end
    ExpBar.SetExpBar(ui.bar_power, ui.bar_power_c, ui.bar_power_l, data.fitnessValue, data.fitnessMaxValue)
    ComFuc.globalFV = data.fitnessValue
  end
end

function ShowSelectLevel(level_id)
  local map_key = CreateRoom.find_map_key_from_id(level_id)
  ui.selected_difficulty_style.Skin = nil
  if map_key then
    ui.selected_level.ForeGroundImage = Icons.PreviewMaps[string.lower(map_key)]
    ui.selected_difficulty_style.Skin = SkinF.level_difficulty_style[CreateRoom.map_difficulty_of_map_id[level_id] + 1]
  else
    ui.selected_level.ForeGroundImage = Icons.PreviewMaps.level_random
  end
end

function SetLimitText(isStart, isPlay)
  local count = 0
  local ids = ""
  local d = ExpeditionRoom.level_map_data
  if not d.minCount or not d.maxCount then
    return
  end
  NormalLimitText()
  local state = ptr_cast(game.CurrentState)
  for i = 1, 8 do
    local t = state:GetSlot(i).client
    if t then
      count = count + 1
      ids = ids .. t.character_id .. ","
    end
  end
  if count < d.minCount or count > d.maxCount then
    ui.role_level.TextColor = colr
    bad_count = true
  end
  if ids ~= "" then
    rpc.safecall("get_room_player_info", {playerIds = ids}, function(data)
      for i = 1, 8 do
        local t1 = data.playerList[i]
        if t1 and t1.id then
          for j = 1, 8 do
            local t2 = data.playerExtraList[j]
            if t2 and t2.id and t2.id == t1.id then
              data.playerList[i].fitness = t2.fitness
              break
            end
          end
        end
      end
      for i = 1, 8 do
        local t = data.playerList[i]
        if t then
          if t.level < d.level or t.ventureForce < d.venturePower or t.fitness < d.fitnessConsumer then
            limit_name = limit_name .. t.name .. ","
          end
          if t.level < d.level then
            ui.role_level.TextColor = colr
          end
          if t.ventureForce < d.venturePower then
            ui.exp_power.TextColor = colr
          end
          if t.fitness < d.fitnessConsumer then
            ui.power_consume.TextColor = colr
          end
        end
      end
      if isStart then
        if not LobbyPlayGame then
          require("playgame.lua")
        end
        if not LobbyPlayGame.boss_game_can_begin and not isPlay then
          MessageBox.ShowError(GetUTF8Text("UI_lobby_explore_no_ready"))
        elseif bad_count then
          MessageBox.ShowError(GetUTF8Text("msgbox_lobby_explore_player_num_unfit"))
        elseif limit_name ~= "" then
          limit_name = string.sub(limit_name, 1, -2)
          MessageBox.ShowError(string.format(GetMatchedUTF8Text("msgbox_lobby_explore_player_unfit"), limit_name))
        else
          MessageBox.ShowWaiter(GetUTF8Text("msgbox_battlefield_additional_string_136"))
          if not isPlay then
            state:StartGame()
          else
            state:EnterGame()
          end
        end
      end
    end)
  end
end

function RpcPlayerVentureDetail()
  rpc.safecall("player_venture_detail", {}, DealExpeditionDetail)
end

function HideExpeditionMainPlane()
  ui.main_plane.Parent = nil
end

function Show(winRoot)
  if not winRoot then
    Hide()
  else
    if ExpeditionRoomCreate then
      ExpeditionRoomCreate.Hide()
    end
    if ExpeditionRoomEnter then
      ExpeditionRoomEnter.Hide()
    end
    NormalLimitText()
    RpcPlayerVentureDetail()
    expeditionState = 1
    for i = 1, level_difficulty_num do
      ComFuc.level_difficulty = i - 1
      if ExpeditionRoom.IsExist(i - 1) then
        break
      end
    end
    ShowLevelDifficultyButton()
    ExpeditionRoom.Show(ui.levels)
    ui.main_plane.Parent = ui.plane_content
    ui.main.Parent = winRoot
  end
end

function Hide()
  ui.main.Parent = nil
end
