module("CreateRoom", package.seeall)
require("battleGameRoom.lua")
require("expeditionRoom.lua")
colw = ComFuc.colw
colt = ARGB(255, 81, 59, 45)
local kGameTypeRandom = 0
local kGameTypeContention = 1
local kGameTypeOccupy = 2
local kGameTypeSnatch = 3
local kGameTypeTeamDead = 4
local kGameTypeHero = 5
local kGameTypeRound = 6
local kGameTypeNovice = 7
local kGameTypeBlast = 8
local kGameTypeBoss = 9
local kGameTypeBioche = 10
local kGameTypeKillAll = 11
local kGameTypeWerewolf = 12
local kGameTypeBiocheHunter, ComModeSelBtn = 13, nil

function ComModeSelBtn(i, p)
  return Gui.Button("btn_mode_" .. i)({
    Visible = false,
    Size = Vector2(74, 74),
    Location = Vector2(-70 + 88 * i, 9),
    Skin = SkinF.battle_004[p],
    CanMove = true,
    ClickAudio = "menu2nd",
    EventClick = function(sender, e)
      ui.cb_game_type.SelectedIndex = i - 1
      print("ComModeSelBtn() ui.cb_game_type.SelectedIndex = " .. ui.cb_game_type.SelectedIndex)
    end
  })
end

ui = Gui.Create()({
  Gui.Control("root")({
    Location = Vector2(0, 0),
    Size = Vector2(730, 566),
    BackgroundColor = colw,
    Skin = SkinF.skin_playgame_030,
    ComFuc.ComLabel(nil, GetUTF8Text("button_common_Create_Room"), Vector2(100, 18), Vector2(16, 7), 0, 16, colw),
    ComFuc.ComButton("btn_confirm", GetUTF8Text("button_common_OK"), Vector2(84, 40), Vector2(540, 516)),
    ComFuc.ComButton("btn_close", GetUTF8Text("button_common_Cancel"), Vector2(84, 40), Vector2(630, 516)),
    Gui.Control({
      Location = Vector2(0, 48),
      Size = Vector2(730, 30),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_battlefield_Room_Name"), Vector2(69, 21), Vector2(21, 5), 0, 16, colt),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_battlefield_Password"), Vector2(100, 21), Vector2(472, 5), 0, 16, colt, "kAlignRightMiddle"),
      ComFuc.ComTextBox("tb_room_name", nil, Vector2(306, 30), Vector2(100, 0), 18),
      ComFuc.ComTextBox("tb_password", nil, Vector2(134, 30), Vector2(580, 0), 6)
    }),
    Gui.Control({
      Location = Vector2(0, 88),
      Size = Vector2(730, 30),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_battlefield_Size"), Vector2(69, 21), Vector2(21, 5), 0, 16, colt),
      ComFuc.ComLabel("lbl_break_join", GetUTF8Text("UI_battlefield_Join_Midway"), Vector2(69, 21), Vector2(262, 5), 0, 16, colt),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_battlefield_Auto_Balance"), Vector2(190, 21), Vector2(492, 5), 0, 16, colt, "kAlignRightMiddle"),
      ComFuc.ComLabel("lbl_is_watch", GetUTF8Text("UI_lobby_ingame_visitor_allowed"), Vector2(190, 21), Vector2(346, 5), 0, 16, colt, "kAlignLeftMiddle"),
      ComFuc.ComComboBox("cb_client_count", Vector2(198, 30), Vector2(100, 0)),
      ComFuc.ComCheckBox("cx_break_join", nil, Vector2(24, 24), Vector2(340, 3)),
      ComFuc.ComCheckBox("cx_balance", nil, Vector2(24, 24), Vector2(690, 3)),
      ComFuc.ComCheckBox("cx_is_watch", nil, Vector2(24, 24), Vector2(320, 3))
    }),
    Gui.Control({
      Location = Vector2(0, 128),
      Size = Vector2(730, 92),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_battlefield_Mode_Selection"), Vector2(69, 21), Vector2(21, 5), 0, 16, colt),
      Gui.Control({
        Location = Vector2(100, 0),
        Size = Vector2(614, 92),
        BackgroundColor = ARGB(255, 255, 255, 255),
        Skin = SkinF.skin_playgame_033,
        ComFuc.ComComboBox("cb_game_type", Vector2(114, 45), Vector2(370, 5)),
        ComModeSelBtn(1, 3),
        ComModeSelBtn(2, 5),
        ComModeSelBtn(3, 2),
        ComModeSelBtn(4, 4),
        ComModeSelBtn(5, 7),
        ComModeSelBtn(6, 8)
      })
    }),
    Gui.Control({
      Location = Vector2(0, 230),
      Size = Vector2(730, 280),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_battlefield_Map_Selection"), Vector2(69, 21), Vector2(21, 5), 0, 16, colt),
      ComFuc.ComComboBox("cb_spawn_time", Vector2(131, 34), Vector2(659, 230)),
      Gui.Control({
        Location = Vector2(100, 0),
        Size = Vector2(614, 280),
        BackgroundColor = colw,
        Skin = SkinF.skin_playgame_033,
        ComFuc.ComPagesBar("page_bar", Vector2(177, 238)),
        Gui.ImageBrowser("ib_map")({
          Location = Vector2(18, 10),
          Size = Vector2(578, 222),
          DisplayRowAndCol = Vector2(2, 3),
          PictureStyle = "Gui.PictureMapInBrowser0",
          Margin = Vector4(0, 0, 0, 0)
        })
      })
    })
  })
})
ui.lbl_break_join.Visible = false
ui.cx_break_join.Visible = false
ui.btn_mode_4.Visible = false
ui.cb_game_type.Visible = false
ui.cb_spawn_time.Visible = false
game_type_key = {
  "kTeamDead",
  "kContention",
  "kOccupy",
  "kSnatch",
  "kGameTypeKillAll",
  "kGameTypeBlast",
  "kGameTypeBiocheHunter",
  "kGameTypeBioche",
  "kGameTypeWerewolf",
  "kBoss",
  "kNovice"
}

function fill_cbx_game_type(cbx)
  cbx:RemoveAll()
  for i = 1, #game_type_key do
    cbx:AddItem(Text.GameMode[game_type_key[i]])
  end
end

local max_player, fill_cbx_max_player = {
  8,
  12,
  16
}, 8
local fill_cbx_max_player, max_player_index = function(cbx)
  cbx:RemoveAll()
  for i = 1, #max_player do
    cbx:AddItem(string.format(GetUTF8Text("button_common_num_people"), max_player[i]))
  end
end, 12

function max_player_index(v)
  for k, vv in ipairs(max_player) do
    if vv == v then
      return k
    end
  end
end

local rebirth_time, fill_cbx_rebirth_time = {
  3,
  5,
  10
}, 3
local fill_cbx_rebirth_time, rebirth_time_index = function(cbx)
  cbx:RemoveAll()
  for i = 1, #rebirth_time do
    cbx:AddItem(rebirth_time[i] .. GetUTF8Text("tips_abilities_Sec"))
  end
end, 5
local rebirth_time_index, what_map_select = function(v)
  for k, vv in ipairs(rebirth_time) do
    if vv == v then
      return k
    end
  end
  return 1
end, 10
local what_map_select, setup_ui_map_picture = function(pic, gtk)
  if pic.Text == what_map_name_select then
    pic.Highlighted = true
  else
    pic.Highlighted = false
  end
end, "kGameTypeBiocheHunter"
local setup_ui_map_picture, setup_ui_map_browser = function(ib, row, col, map_key)
  local pic = ib:GetDisplayPicture(row, col)
  pic.Text = map_key
  pic.ForeGroundImage = Icons.PreviewMaps[string.lower(pic.Text)]
  if string.len(pic.Text) ~= 0 then
    pic.BeStatic = false
  else
    pic.BeStatic = true
  end
  
  function pic.EventClick(sender, e)
    what_map_name_select = pic.Text
    print(what_map_name_select)
    ib:AllPictureHL(false)
    pic.Highlighted = true
  end
end, "kGameTypeBioche"

function setup_ui_map_browser(ib, game_type)
  local ib_display_pic_count = ib.DisplayRowAndCol.x * ib.DisplayRowAndCol.y
  
  function OnPageChanged(newPage)
    local start_map_key_index = ib_display_pic_count * (newPage - 1)
    for row = 1, ib.DisplayRowAndCol.x do
      for col = 1, ib.DisplayRowAndCol.y do
        setup_ui_map_picture(ib, row, col, map_keys_of_game_type[game_type][0][start_map_key_index + (row - 1) * ib.DisplayRowAndCol.y + col])
        what_map_select(ib:GetDisplayPicture(row, col), game_type)
      end
    end
  end
  
  function ui.page_bar.EventIndexChanged(sender, e)
    if sender.CurrIndex >= 1 and sender.CurrIndex <= sender.PageCount then
      OnPageChanged(sender.CurrIndex)
    end
  end
  
  local pagenum = 1
  for i = 1, #map_keys_of_game_type[game_type][0] do
    if what_map_name_select == map_keys_of_game_type[game_type][0][i] then
      pagenum = math.floor((i - 1) / ib_display_pic_count) + 1
      break
    end
  end
  ui.page_bar.PageCount = math.ceil(#map_keys_of_game_type[game_type][0] / ib_display_pic_count)
  ui.page_bar.CurrIndex = pagenum
  OnPageChanged(pagenum)
  ib.LeftBtn.Visible = false
  ib.RightBtn.Visible = false
end

level_count = 0
map_id_of_key = {}
map_show_name_of_key = {}
map_desc_of_key = {}
map_keys_of_game_type = {}
game_type_of_map_id = {}
map_show_name_of_map_id = {}
map_key_of_map_id = {}
map_difficulty_of_map_id = {}

function print_level_info(level_info)
  print("level info.id:", level_info.id)
  print("level info.name:", level_info.name)
  print("level info.game_type:", level_info.game_type)
  print("level info.show_name:", level_info.show_name)
  print("level info.description:", level_info.description)
end

function print_room_info_desc(room_info_desc)
  print("room_info_desc.room_name:", room_info_desc.room_name)
  print("room_info_desc.use_password:", room_info_desc.use_password)
  print("room_info_desc.password:", room_info_desc.password)
  print("room_info_desc.level_id:", room_info_desc.level_id)
  print("room_info_desc.max_client_num:", room_info_desc.max_client_num)
  print("room_info_desc.spawn_time:", room_info_desc.spawn_time)
  print("room_info_desc.join_halfway:", room_info_desc.join_halfway)
  print("room_info_desc.check_balance:", room_info_desc.check_balance)
end

function print_room_info(room_info)
  print("        room_info.RoomUid", room_info.RoomUid)
  print("        room_info.RoomState", room_info.RoomState)
  print("        room_info.MapName", map_show_name_of_map_id[room_info.LevelId])
  print("        room_info.HostName", room_info.HostName)
  print("        room_info.UsePassword", room_info.UsePassword)
  print("        room_info.LevelId", room_info.LevelId .. "[" .. map_key_of_map_id[room_info.LevelId] .. "]")
  print("        room_info.HostId", room_info.HostId)
  print("        room_info.GameType", room_info.GameType)
  print("        room_info.SpawnTime", room_info.SpawnTime)
  print("        room_info.JoinHalfWay", room_info.JoinHalfWay)
  print("        room_info.CheckBalance", room_info.CheckBalance)
  print("        room_info.Matching", room_info.Matching)
  print("        room_info.Password", room_info.Password)
  print("        room_info.MaxClientNum", room_info.MaxClientNum)
  print("        room_info.CurrentClientNum", room_info.CurrentClientNum)
end

function print_client_info(client_info)
  print("client_info, character_id", client_info.character_id)
  print("client_info, character_name", client_info.character_name)
  print("client_info, character_guild", client_info.character_guild)
  print("client_info, career", client_info.career)
  print("client_info, ready", client_info.ready)
  print("client_info, host", client_info.host)
  print("client_info, level", client_info.level)
  print("client_info, vip level", client_info.vip_level)
  print("client_info, level", client_info.level)
  print("client_info, venture force", client_info.ventureForce)
  print("client_info, fitness value", client_info.fitnessValue)
end

function find_map_key_from_id(id)
  ComFuc.level_difficulty = 0
  for i = 0, #map_id_of_key do
    for k, v in pairs(map_id_of_key[i]) do
      if v == id then
        ComFuc.level_difficulty = i
        return k
      end
    end
  end
end

function find_level_difficulty(type, level_id)
  local map_key = find_map_key_from_id(level_id)
  local game_type = game_type_key[type - 1]
  ComFuc.level_difficulty = 0
  for i = 0, #map_keys_of_game_type[game_type] do
    for j = 1, #map_keys_of_game_type[game_type][i] do
      if map_key == map_keys_of_game_type[game_type][i][j] then
        ComFuc.level_difficulty = i
        break
      end
    end
  end
end

local game_type_array = {}
local CheckGameType, RandomMapKey = function(key)
  if game_type_array == nil then
    return false
  end
  local game_type = "kRandom"
  if key == 1 then
    game_type = "kContention"
  elseif key == 2 then
    game_type = "kOccupy"
  elseif key == 3 then
    game_type = "kSnatch"
  elseif key == 4 then
    game_type = "kTeamDead"
  elseif key == kGameTypeBioche then
    game_type = "kGameTypeBioche"
  elseif key == kGameTypeBoss then
    game_type = "kBoss"
  elseif key == kGameTypeKillAll then
    game_type = "kGameTypeKillAll"
  elseif key == kGameTypeWerewolf then
    game_type = "kGameTypeWerewolf"
  elseif key == kGameTypeBiocheHunter then
    game_type = "kGameTypeBiocheHunter"
  elseif key == kGameTypeBlast then
    game_type = "kGameTypeBlast"
  else
    game_type = "kRandom"
  end
  for k, v in pairs(game_type_array) do
    if tostring(v) == tostring(game_type) then
      return true
    end
  end
  return false
end, function(key)
  if game_type_array == nil then
    return false
  end
  local game_type = "kRandom"
  if key == 1 then
    game_type = "kContention"
  elseif key == 2 then
    game_type = "kOccupy"
  elseif key == 3 then
    game_type = "kSnatch"
  elseif key == 4 then
    game_type = "kTeamDead"
  elseif key == kGameTypeBioche then
    game_type = "kGameTypeBioche"
  elseif key == kGameTypeBoss then
    game_type = "kBoss"
  elseif key == kGameTypeKillAll then
    game_type = "kGameTypeKillAll"
  elseif key == kGameTypeWerewolf then
    game_type = "kGameTypeWerewolf"
  elseif key == kGameTypeBiocheHunter then
    game_type = "kGameTypeBiocheHunter"
  elseif key == kGameTypeBlast then
    game_type = "kGameTypeBlast"
  else
    game_type = "kRandom"
  end
  for k, v in pairs(game_type_array) do
    if tostring(v) == tostring(game_type) then
      return true
    end
  end
  return false
end

function RandomMapKey(gtk)
  local map_key = map_keys_of_game_type and map_keys_of_game_type[gtk] or nil
  print(gtk, map_keys_of_game_type, map_key)
  if map_key then
    local i = math.random(2, #map_key)
    print("which:", i, map_key[i])
    return map_key[i]
  end
  return ""
end

function UpdateLevelList()
  local state = ptr_cast(game.CurrentState)
  level_count = state:GetLevelCount()
  map_id_of_key = {}
  map_show_name_of_key = {}
  map_desc_of_key = {}
  map_keys_of_game_type = {}
  game_type_of_map_id = {}
  map_show_name_of_map_id = {}
  map_key_of_map_id = {}
  map_difficulty_of_map_id = {}
  map_id_of_key.level_random = "0"
  map_show_name_of_key.level_random = GetUTF8Text("UI_common_Random_Map")
  map_desc_of_key.level_random = ""
  map_show_name_of_map_id["0"] = GetUTF8Text("UI_common_Random_Map")
  map_key_of_map_id["0"] = "level_random"
  for i = 1, level_count do
    local level_info = state:GetLevelInfo(i - 1)
    if not map_id_of_key[level_info.difficulty] then
      map_id_of_key[level_info.difficulty] = {}
    end
    map_id_of_key[level_info.difficulty][level_info.name] = level_info.id
    map_show_name_of_key[level_info.name] = level_info.show_name
    map_desc_of_key[level_info.name] = level_info.description
    if not map_keys_of_game_type[level_info.game_type] then
      map_keys_of_game_type[level_info.game_type] = {}
    end
    if not map_keys_of_game_type[level_info.game_type][level_info.difficulty] then
      map_keys_of_game_type[level_info.game_type][level_info.difficulty] = {}
    end
    table.insert(map_keys_of_game_type[level_info.game_type][level_info.difficulty], level_info.name)
    game_type_of_map_id[level_info.id] = level_info.game_type
    map_show_name_of_map_id[level_info.id] = GetUTF8Text(level_info.show_name)
    map_key_of_map_id[level_info.id] = level_info.name
    map_difficulty_of_map_id[level_info.id] = level_info.difficulty
    if game_type_array[level_info.game_type] == nil then
      game_type_array[level_info.game_type] = level_info.game_type
    end
  end
  for _, v in ipairs(game_type_key) do
    if map_keys_of_game_type[v] then
      table.sort(map_keys_of_game_type[v], function(lhs, rhs)
        return tonumber(string.match(lhs, "%d+")) < tonumber(string.match(rhs, "%d+"))
      end)
      for i = 0, #map_keys_of_game_type[v] do
        if map_keys_of_game_type[v][i] then
          table.insert(map_keys_of_game_type[v][i], 1, "level_random")
        end
      end
    else
      map_keys_of_game_type[v] = {}
    end
  end
  for _, v in ipairs(game_type_key) do
    for i = 0, #map_keys_of_game_type[v] do
      if map_keys_of_game_type[v][i] then
        for j = 1, #map_keys_of_game_type[v][i] do
        end
      end
    end
  end
  if LobbyBattleGame then
    LobbyBattleGame.ShowGameType()
  end
  if LobbyPlayGame then
    LobbyPlayGame.ShowGameType()
  end
  ShowGameType()
  BattleGameRoom.map_keys_of_game_type = map_keys_of_game_type
  BattleGameRoom.game_type_key = game_type_key
  BattleGameRoom.map_id_of_key = map_id_of_key
  BattleGameRoom.map_key_of_map_id = map_key_of_map_id
  ExpeditionRoom.map_keys_of_game_type = map_keys_of_game_type
  ExpeditionRoom.game_type_key = game_type_key
  ExpeditionRoom.map_id_of_key = map_id_of_key
  ExpeditionRoom.map_key_of_map_id = map_key_of_map_id
  for i = 0, #ExpeditionRoom.map_keys_of_game_type.kBoss do
    if ExpeditionRoom.map_keys_of_game_type.kBoss[i] then
      table.remove(ExpeditionRoom.map_keys_of_game_type.kBoss[i], 1)
    end
  end
end

function ShowGameType()
  if ui.root.Parent == nil then
    return
  end
  local _i = 1
  if CheckGameType(kGameTypeTeamDead) then
    ui.btn_mode_1.Visible = true
    ui.btn_mode_1.Location = Vector2(-70 + 88 * _i, 9)
    _i = _i + 1
  end
  if CheckGameType(kGameTypeContention) then
    ui.btn_mode_2.Visible = true
    ui.btn_mode_2.Location = Vector2(-70 + 88 * _i, 9)
    _i = _i + 1
  end
  if CheckGameType(kGameTypeOccupy) then
    ui.btn_mode_3.Visible = true
    ui.btn_mode_3.Location = Vector2(-70 + 88 * _i, 9)
    _i = _i + 1
  end
  if CheckGameType(kGameTypeSnatch) then
    ui.btn_mode_4.Visible = true
    ui.btn_mode_4.Location = Vector2(-70 + 88 * _i, 9)
    _i = _i + 1
  end
  if CheckGameType(kGameTypeKillAll) then
    ui.btn_mode_5.Visible = true
    ui.btn_mode_5.Location = Vector2(-70 + 88 * _i, 9)
    _i = _i + 1
  end
  if CheckGameType(kGameTypeBlast) then
    ui.btn_mode_6.Visible = true
    ui.btn_mode_6.Location = Vector2(-70 + 88 * _i, 9)
    _i = _i + 1
  end
end

function SetCreateRoomInfo(room_info_desc)
  for i = 1, 6 do
    ui["btn_mode_" .. i].PushDown = ui.cb_game_type.SelectedIndex + 1 == i
  end
  fill_cbx_max_player(ui.cb_client_count)
  fill_cbx_rebirth_time(ui.cb_spawn_time)
  what_map_name_select = find_map_key_from_id(room_info_desc.level_id)
  setup_ui_map_browser(ui.ib_map, game_type_key[ui.cb_game_type.SelectedIndex + 1])
  ui.cb_client_count.SelectedIndex = max_player_index(room_info_desc.max_client_num) - 1
  ui.cb_spawn_time.SelectedIndex = rebirth_time_index(room_info_desc.spawn_time) - 1
  ui.cx_break_join.Check = room_info_desc.join_halfway
  ui.cx_balance.Check = room_info_desc.check_balance
  ui.cx_is_watch.Visible = game.gmCtrl:CheckPrivilege("kGMRoomWatch")
  ui.lbl_is_watch.Visible = game.gmCtrl:CheckPrivilege("kGMRoomWatch")
end

function SetRoomOption(room_info_desc)
  ui.tb_room_name.Text = room_info_desc.room_name
  if room_info_desc.use_password ~= 0 then
    ui.tb_password.Text = room_info_desc.password
  else
    ui.tb_password.Text = ""
  end
  fill_cbx_game_type(ui.cb_game_type)
  
  function ui.cb_game_type.EventValueChanged(sender, e)
    SetCreateRoomInfo(room_info_desc)
  end
  
  local game_type = room_info_desc.game_type
  game_type = game_type or "kTeamDead"
  ui.cb_game_type.Text = Text.GameMode[game_type]
  SetCreateRoomInfo(room_info_desc)
end

function GetRoomOption(return_room_info_desc)
  return_room_info_desc.room_name = ui.tb_room_name.Text
  return_room_info_desc.password = ui.tb_password.Text
  if string.len(ui.tb_password.Text) > 0 then
    return_room_info_desc.use_password = 1
  else
    return_room_info_desc.use_password = 0
  end
  local gtk = game_type_key[ui.cb_game_type.SelectedIndex + 1]
  return_room_info_desc.max_client_num = max_player[ui.cb_client_count.SelectedIndex + 1]
  return_room_info_desc.spawn_time = rebirth_time[ui.cb_spawn_time.SelectedIndex + 1]
  return_room_info_desc.join_halfway = ui.cx_break_join.Check
  return_room_info_desc.check_balance = ui.cx_balance.Check
  return_room_info_desc.can_be_watched = ui.cx_is_watch.Check and 1 or 0
  if not what_map_name_select or what_map_name_select == "level_random" then
    return_room_info_desc.level_id = map_id_of_key.level_random
    return_room_info_desc.game_type = gtk
  else
    return_room_info_desc.level_id = map_id_of_key[ComFuc.level_difficulty][what_map_name_select]
    return_room_info_desc.game_type = game_type_of_map_id[return_room_info_desc.level_id]
  end
end

function ShowModal(ConfirmEvent)
  local mw = ModalWindow.GetNew(1)
  mw.screen.AllowEscToExit = true
  mw.screen.AllowF1 = false
  mw.root.Size = ui.root.Size
  ui.root.Parent = mw.root
  mw.screen.Visible = true
  ShowGameType()
  
  function CloseModal()
    ui.root.Parent = nil
    mw.Close()
  end
  
  function ui.btn_close.EventClick(sender, e)
    CloseModal()
  end
  
  function mw.screen.EventEscPressed(sender, e)
    CloseModal()
  end
  
  if ConfirmEvent then
    function ui.btn_confirm.EventClick(sender, e)
      ConfirmEvent()
      
      CloseModal()
    end
  end
end
