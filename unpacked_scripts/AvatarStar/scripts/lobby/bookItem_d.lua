module("BookItem", package.seeall)
bookInfo = {}
totalnum = nil
ui = Gui.Create()({
  Gui.Control("main")({
    Size = Vector2(1600, 900),
    Dock = "kDockCenter",
    Gui.Control({
      Size = Vector2(920, 900),
      Dock = "kDockCenter",
      Gui.Control("book")({
        Size = Vector2(920, 613),
        Location = Vector2(0, 175),
        BackgroundColor = ComFuc.colw,
        Skin = SkinF.book_background,
        ComFuc.ComButton("close_button", nil, Vector2(24, 24), Vector2(885, 14), 16, false, false, SkinF.lookInfo_002),
        Gui.Control("book_left_picture")({
          Size = Vector2(419, 565),
          Location = Vector2(64, 0),
          BackgroundColor = ComFuc.colw
        }),
        Gui.Control("book_right_picture")({
          Size = Vector2(419, 565),
          Location = Vector2(448, 0),
          BackgroundColor = ComFuc.colw
        }),
        Gui.Control("book_left")({
          Size = Vector2(310, 435),
          Location = Vector2(113, 65),
          ComFuc.ComLabel("book_left_word", nil, Vector2(300, 435), Vector2(0, 0), 0, 16, ARGB(200, 55, 37, 0), "kAlignLeft")
        }),
        Gui.Control("book_right")({
          Size = Vector2(310, 435),
          Location = Vector2(507, 65),
          ComFuc.ComLabel("book_right_word", nil, Vector2(300, 435), Vector2(0, 0), 0, 16, ARGB(200, 55, 37, 0), "kAlignLeft")
        }),
        ComFuc.ComPagesBar("book_pages_bar", Vector2(330, 551))
      })
    })
  })
})

function ShowBook()
  ui.main.Parent = gui
end

function Hide()
  ui.main.Parent = nil
end

local ui.close_button.EventClick, DealData = function(sender, e)
  Hide()
end, ui.close_button

function DealData()
  local k = ui.book_pages_bar.CurrIndex * 2 - 1
  k = tostring(k)
  local value
  for i = 1, totalnum do
    if bookInfo[i].id == k then
      value = bookInfo[i].value
      break
    end
  end
  if value then
    local b, e = string.find(value, value)
    local flag = string.sub(value, 1, 1)
    if flag == "p" then
      local p = string.sub(value, b + 2, e)
      ui.book_left_picture.Visible = true
      ui.book_left_picture.Skin = Gui.ControlSkin({
        BackgroundImage = Gui.Image("ui/skinF/" .. p .. ".tga", Vector4(10, 10, 10, 10))
      })
      ui.book_right_picture.Visible = false
      ui.book_left.Visible = false
      ui.book_right.Visible = false
    elseif "w" == flag then
      local w = string.sub(value, b + 2, e)
      ui.book_left.Visible = true
      ui.book_right.Visible = false
      ui.book_left_picture.Visible = false
      ui.book_right_picture.Visible = false
      ui.book_left_word.AutoWrap = true
      ui.book_left_word.Text = GetUTF8Text(w)
    else
      print("error: ", flag, " is not a valid value!!!!!!!!!!!!!")
    end
  end
  k = tostring(k + 1)
  value = nil
  for i = 1, totalnum do
    if bookInfo[i].id == k then
      value = bookInfo[i].value
      break
    end
  end
  if value then
    local b, e = string.find(value, value)
    local flag = string.sub(value, 1, 1)
    if flag == "p" then
      local p = string.sub(value, b + 2, e)
      ui.book_right_picture.Visible = true
      ui.book_right_picture.Skin = Gui.ControlSkin({
        BackgroundImage = Gui.Image("ui/skinF/" .. p .. ".tga", Vector4(10, 10, 10, 10))
      })
    elseif "w" == flag then
      local w = string.sub(value, b + 2, e)
      ui.book_right.Visible = true
      ui.book_right_word.AutoWrap = true
      ui.book_right_word.Text = GetUTF8Text(w)
    end
  end
end

function ui.book_pages_bar.EventIndexChanged(sender, e)
  DealData()
  ShowBook()
end

function OpenBook(data)
  bookInfo = data.paramMap
  totalnum = #data.paramMap
  ui.book_pages_bar.CurrIndex = 1
  if 0 == totalnum % 2 then
    ui.book_pages_bar.PageCount = totalnum / 2
  else
    ui.book_pages_bar.PageCount = (totalnum + 1) / 2
  end
  DealData()
  ShowBook()
end
