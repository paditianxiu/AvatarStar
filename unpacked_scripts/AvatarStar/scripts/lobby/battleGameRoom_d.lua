module("BattleGameRoom", package.seeall)
local what_map_name_select
local game_mode = 0
map_keys_of_game_type = {}
game_type_key = {}
map_id_of_key = {}
map_key_of_map_id = {}
ui = Gui.Create()({
  Gui.Control("root")({
    Location = Vector2(50, 196),
    Size = Vector2(614, 280),
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
ui.ib_map.LeftBtn.Visible = false
local ui.ib_map.RightBtn.Visible, setup_ui_map_picture = false, ui.ib_map.RightBtn

function setup_ui_map_picture(ib, row, col, map_key)
  local pic = ib:GetDisplayPicture(row, col)
  pic.Text = map_key
  pic.ForeGroundImage = Icons.PreviewMaps[string.lower(pic.Text)]
  pic.BeStatic = string.len(pic.Text) == 0
  pic.Highlighted = pic.Text == what_map_name_select
  
  function pic.EventClick(sender, e)
    what_map_name_select = pic.Text
    ib:AllPictureHL(false)
    pic.Highlighted = true
    local state = ptr_cast(game.CurrentState, "Client.StateLobby")
    state:RequestTeamChangeGameMode(game_mode, map_id_of_key[ComFuc.level_difficulty][what_map_name_select])
  end
end

function SetBattleRoomInfo(type, game_type)
  game_mode = game_type
  what_map_name_select = "level_random"
  local ib = ui.ib_map
  local game_type = "kRandow"
  if 2 <= type then
    game_type = game_type_key[type - 1]
  end
  local randowType = {
    "level_random",
    nil,
    nil,
    nil,
    nil,
    nil
  }
  local ib_display_pic_count, OnPageChanged = ib.DisplayRowAndCol.x * ib.DisplayRowAndCol.y, ib.DisplayRowAndCol.y
  
  function OnPageChanged(newPage)
    local start_map_key_index = ib_display_pic_count * (newPage - 1)
    for row = 1, ib.DisplayRowAndCol.x do
      for col = 1, ib.DisplayRowAndCol.y do
        if 2 <= type then
          setup_ui_map_picture(ib, row, col, map_keys_of_game_type[game_type][0][start_map_key_index + (row - 1) * ib.DisplayRowAndCol.y + col])
        else
          setup_ui_map_picture(ib, row, col, randowType[start_map_key_index + (row - 1) * ib.DisplayRowAndCol.y + col])
        end
      end
    end
  end
  
  ib.Enable = true
  
  function ui.page_bar.EventIndexChanged(sender, e)
    OnPageChanged(sender.CurrIndex)
  end
  
  if 2 <= type then
    ui.page_bar.PageCount = math.ceil(#map_keys_of_game_type[game_type][0] / ib_display_pic_count)
  else
    ui.page_bar.PageCount = 1
  end
  ui.page_bar.CurrIndex = 1
  OnPageChanged(1)
end

function SetLevelIdAndMapInfo(level_id)
  local ib = ui.ib_map
  local randowType = {
    map_key_of_map_id[tostring(level_id)],
    nil,
    nil,
    nil,
    nil,
    nil
  }
  what_map_name_select = map_key_of_map_id[tostring(level_id)]
  ib.Enable = false
  for row = 1, ib.DisplayRowAndCol.x do
    for col = 1, ib.DisplayRowAndCol.y do
      setup_ui_map_picture(ib, row, col, randowType[(row - 1) * ib.DisplayRowAndCol.y + col])
    end
  end
  ui.page_bar.PageCount = 1
  ui.page_bar.CurrIndex = 1
end

function Show(parent)
  ui.root.Parent = parent
end

function Hide()
  ui.root.Parent = nil
end
