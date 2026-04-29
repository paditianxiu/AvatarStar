module("ExpeditionLookPrize", package.seeall)
local colw = ComFuc.colw
local resDir = "/ui/skinF/"
local resDir2 = "/ui/skinF/lobby/"
local goodsList, ComGoods = {}, nil

function ComGoods(i)
  return ComFuc.ComItemCB("goods_" .. i, ComFuc.ComputLocation(i, -72, -84, 3, 86, 84), i)
end

local ui, ShowGoodsPages = Gui.Create()({
  Gui.Control("main")({
    Size = Vector2(425, 480),
    Location = Vector2(412, 0),
    BackgroundColor = colw,
    Skin = SkinF.openBox_004[3],
    ComFuc.ComLabel(nil, GetUTF8Text("UI_lobby_explore_award"), Vector2(180, 20), Vector2(149, 28), 0, 16, colw, "kAlignCenterMiddle"),
    ComFuc.ComButton("close", nil, Vector2(24, 24), Vector2(374, 26), 0, false, false, SkinF.lookInfo_002),
    ComFuc.ComPagesBar("pages", Vector2(105, 416)),
    Gui.Control({
      Size = Vector2(281, 332),
      Location = Vector2(94, 67),
      ComGoods(1),
      ComGoods(2),
      ComGoods(3),
      ComGoods(4),
      ComGoods(5),
      ComGoods(6),
      ComGoods(7),
      ComGoods(8),
      ComGoods(9),
      ComGoods(10),
      ComGoods(11),
      ComGoods(12)
    })
  }),
  ComFuc.ComControl("coverControl2", Vector2(1600, 1200), Vector2(0, 0), 0)
}), Gui.Create()({
  Gui.Control("main")({
    Size = Vector2(425, 480),
    Location = Vector2(412, 0),
    BackgroundColor = colw,
    Skin = SkinF.openBox_004[3],
    ComFuc.ComLabel(nil, GetUTF8Text("UI_lobby_explore_award"), Vector2(180, 20), Vector2(149, 28), 0, 16, colw, "kAlignCenterMiddle"),
    ComFuc.ComButton("close", nil, Vector2(24, 24), Vector2(374, 26), 0, false, false, SkinF.lookInfo_002),
    ComFuc.ComPagesBar("pages", Vector2(105, 416)),
    Gui.Control({
      Size = Vector2(281, 332),
      Location = Vector2(94, 67),
      ComGoods(1),
      ComGoods(2),
      ComGoods(3),
      ComGoods(4),
      ComGoods(5),
      ComGoods(6),
      ComGoods(7),
      ComGoods(8),
      ComGoods(9),
      ComGoods(10),
      ComGoods(11),
      ComGoods(12)
    })
  }),
  ComFuc.ComControl("coverControl2", Vector2(1600, 1200), Vector2(0, 0), 0)
})
local ShowGoodsPages, DealBoxPrizeList = function()
  local t = #goodsList
  local b = (ui.pages.CurrIndex - 1) * 12
  local c = math.min(t - b, 12)
  for i = 1, c do
    local v = goodsList[b + i]
    v.grade = v.grade or 1
    ui["goods_" .. i .. "_lev"].Skin = SkinF.personalInfo_quality[v.grade]
    local res = v.resource
    if v.type == 2 and v.subType == 102 then
      local a = rpc.load_result("fuck = {" .. res .. "}")
      res = a.fuck[1]
    end
    ui["goods_" .. i .. "_res"].Skin = Gui.Gui.ControlSkin({
      BackgroundImage = Gui.Image(resDir2 .. res .. ".tga", Vector4(0, 0, 0, 0))
    })
    if v.unitType and v.unitType == 3 and 1 < v.unit then
      ui["goods_" .. i .. "_count"].Text = v.unit
    else
      ui["goods_" .. i .. "_count"].Text = nil
    end
    if v.type == 5 then
      if v.subType == 1 then
        ui["goods_" .. i .. "_res"].Skin = SkinF.personalInfo_095
      elseif v.subType == 2 then
        ui["goods_" .. i .. "_res"].Skin = SkinF.personalInfo_262
      end
    end
    ui["goods_" .. i .. "_res"].EventMouseEnter = function(sender, e)
      if v.type ~= 7 then
        if v.type == 5 then
          Tip.SetRpc("tip_sys_avatar", {
            t = v.type,
            sid = v.itemId
          })
        else
          Tip.SetRpc("tip_sys_level_reward", {
            t = v.type,
            rewardId = v.id
          })
        end
        Tip.SetUseDescription(false)
        Tip.SetOwner(sender)
      end
    end
    ui["goods_" .. i .. "_lev"].Visible = true
    ui["goods_" .. i .. "_res"].Visible = true
    ui["goods_" .. i .. "_count"].Visible = true
  end
  for i = c + 1, 12 do
    ui["goods_" .. i .. "_lev"].Visible = false
    ui["goods_" .. i .. "_res"].Visible = false
    ui["goods_" .. i .. "_count"].Visible = false
  end
end, {
  Gui.Control("main")({
    Size = Vector2(425, 480),
    Location = Vector2(412, 0),
    BackgroundColor = colw,
    Skin = SkinF.openBox_004[3],
    ComFuc.ComLabel(nil, GetUTF8Text("UI_lobby_explore_award"), Vector2(180, 20), Vector2(149, 28), 0, 16, colw, "kAlignCenterMiddle"),
    ComFuc.ComButton("close", nil, Vector2(24, 24), Vector2(374, 26), 0, false, false, SkinF.lookInfo_002),
    ComFuc.ComPagesBar("pages", Vector2(105, 416)),
    Gui.Control({
      Size = Vector2(281, 332),
      Location = Vector2(94, 67),
      ComGoods(1),
      ComGoods(2),
      ComGoods(3),
      ComGoods(4),
      ComGoods(5),
      ComGoods(6),
      ComGoods(7),
      ComGoods(8),
      ComGoods(9),
      ComGoods(10),
      ComGoods(11),
      ComGoods(12)
    })
  }),
  ComFuc.ComControl("coverControl2", Vector2(1600, 1200), Vector2(0, 0), 0)
}

function DealBoxPrizeList(data)
  goodsList = data.list
  ui.pages.CurrIndex = 1
  ui.pages.PageCount = math.floor((#goodsList - 0.1) / 12) + 1
  ShowGoodsPages()
  ui.coverControl2.Parent = gui
  ui.main.Parent = gui
  Gui.Align(ui.main, 0.5, 0.5)
end

function ui.close.EventClick(sender, e)
  Hide()
end

function ui.pages.EventIndexChanged(sender, e)
  ShowGoodsPages()
end

function Show(levelId)
  if not levelId then
    Hide()
  else
    rpc.safecall("level_reward_list", {
      mid = Expedition.selectLevel
    }, DealBoxPrizeList)
  end
end

function Hide()
  ui.coverControl2.Parent = nil
  ui.main.Parent = nil
end
