module("bufList", package.seeall)
local WIDTH = 200
local HEIGHT_SINGLE = 50
local bufListParent
local colw = ARGB(255, 255, 255, 255)
local colb = ARGB(255, 0, 0, 0)
local buf_item_pool = {
  control = {},
  label = {}
}
local buf_tbl = {
  control = {},
  label = {}
}
ui = Gui.Create()({
  Gui.Control("buf_list")({
    Size = Vector2(150, 150),
    Location = Vector2(10, 140),
    Skin = SkinF.battle_005,
    BackgroundColor = ARGB(255, 255, 255, 255)
  })
})
local curr_pos, _buf_item_mouse_enter = 0, {
  Gui.Control("buf_list")({
    Size = Vector2(150, 150),
    Location = Vector2(10, 140),
    Skin = SkinF.battle_005,
    BackgroundColor = ARGB(255, 255, 255, 255)
  })
}
local _buf_item_mouse_enter, _add_one_buf = function()
  ui.buf_list.Visible = true
  ui.buf_list.Parent = bufListParent
end, Gui.Control("buf_list")({
  Size = Vector2(150, 150),
  Location = Vector2(10, 140),
  Skin = SkinF.battle_005,
  BackgroundColor = ARGB(255, 255, 255, 255)
})

function _add_one_buf(skin, hint, last)
  local curr_pos = #buf_item_pool.control * HEIGHT_SINGLE
  Gui.Control({
    Size = Vector2(44, 34),
    Location = Vector2(10, curr_pos + 10),
    Skin = skin,
    BackgroundColor = colw,
    Hint = hint
  })(ui.buf_list, buf_item_pool.control)
  Gui.Label({
    Size = Vector2(110, 34),
    Location = Vector2(70, curr_pos + 10),
    Text = last,
    BackgroundColor = ARGB(0, 255, 255, 255),
    FontSize = 16,
    TextColor = colb
  })(ui.buf_list, buf_item_pool.label)
  buf_item_pool.control[#buf_item_pool.control].EventMouseEnter = _buf_item_mouse_enter
end

local curr_buf_item, _append_one_buf = 1, Gui.Control("buf_list")({
  Size = Vector2(150, 150),
  Location = Vector2(10, 140),
  Skin = SkinF.battle_005,
  BackgroundColor = ARGB(255, 255, 255, 255)
})
local _append_one_buf, _reset_all_buf = function(skin, hint, last)
  if #buf_item_pool.control < curr_buf_item then
    _add_one_buf()
  end
  buf_item_pool.control[curr_buf_item].Skin = skin
  buf_item_pool.control[curr_buf_item].Hint = hint
  buf_item_pool.label[curr_buf_item].Text = last
  buf_item_pool.label[curr_buf_item].TextAlign = "kAlignCenter"
  curr_buf_item = curr_buf_item + 1
end, Gui.Control("buf_list")({
  Size = Vector2(150, 150),
  Location = Vector2(10, 140),
  Skin = SkinF.battle_005,
  BackgroundColor = ARGB(255, 255, 255, 255)
})

function _reset_all_buf()
  curr_buf_item = 1
end

function Show(parent, buf_list)
  bufListParent = parent
  for i = 1, #buf_list do
    _append_one_buf(buf_list[i].skin, buf_list[i].hint, buf_list[i].last)
  end
  ui.buf_list.Size = Vector2(WIDTH, HEIGHT_SINGLE * #buf_list)
  ui.buf_list.Visible = true
  ui.buf_list.Parent = parent
end

function Hide()
  ui.buf_list.Parent = nil
  _reset_all_buf()
end

function ui.buf_list.EventMouseEnter(sender, e)
  ui.buf_list.Visible = true
  ui.buf_list.Parent = bufListParent
end

function ui.buf_list.EventMouseLeave(sender, e)
  Hide()
end

return bufList
