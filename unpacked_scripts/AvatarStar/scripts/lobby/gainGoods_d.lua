module("GainGoods", package.seeall)
col0 = ARGB(0, 0, 0, 0)
colw = ARGB(255, 255, 255, 255)
coly = ARGB(255, 255, 255, 0)
colt = {
  ARGB(255, 180, 180, 180),
  ARGB(255, 54, 255, 0),
  ARGB(255, 0, 180, 255),
  ARGB(255, 198, 0, 255),
  ARGB(255, 255, 128, 0),
  ARGB(255, 255, 255, 255)
}
local resDir2 = "/ui/skinF/lobby/"
local callFuc, timer
local frameC = 0
local isRemain = false
local tip_sys_interface, ComCB = {
  "tip_sys_skill",
  "tip_sys_item",
  "tip_sys_item",
  "tip_sys_item",
  "tip_sys_avatar",
  "tip_sys_avatar"
}, "tip_sys_skill"

function ComCB(i, row)
  local index = i + (row - 1) * 10
  return Gui.Control("gain_" .. index)({
    Size = Vector2(80, 80),
    Location = Vector2(86 * (i - 1), 0),
    Skin = SkinF.skin_touming,
    ComFuc.ComControl("gain_" .. index .. "_lev", Vector2(80, 80), Vector2(0, 0), 255),
    ComFuc.ComControl("gain_" .. index .. "_res", Vector2(80, 80), Vector2(0, 0), 255),
    ComFuc.ComLabel("gain_" .. index .. "_count", nil, Vector2(76, 18), Vector2(3, 59), 0, 0, colw, "kAlignRightMiddle", SkinF.skin_touming, true, SkinF.hecheng_number_1)
  })
end

local ui = Gui.Create()({
  Gui.Control("main")({
    Size = Vector2(1180, 441),
    Dock = "kDockTopCenter",
    Gui.Control("main_son")({
      Size = Vector2(1200, 181),
      Location = Vector2(-10, 260),
      Gui.Control("main_sson")({
        Size = Vector2(1200, 181),
        BackgroundColor = colw,
        Skin = SkinF.gainGoods_001,
        Gui.Control("goods_content1")({
          Skin = SkinF.skin_touming,
          ComCB(1, 1),
          ComCB(2, 1),
          ComCB(3, 1),
          ComCB(4, 1),
          ComCB(5, 1),
          ComCB(6, 1),
          ComCB(7, 1),
          ComCB(8, 1),
          ComCB(9, 1),
          ComCB(10, 1)
        }),
        Gui.Control("goods_content2")({
          Skin = SkinF.skin_touming,
          ComCB(1, 2),
          ComCB(2, 2),
          ComCB(3, 2),
          ComCB(4, 2),
          ComCB(5, 2),
          ComCB(6, 2),
          ComCB(7, 2),
          ComCB(8, 2),
          ComCB(9, 2),
          ComCB(10, 2)
        })
      })
    })
  })
})

function TimerRemove()
  game.TimerMgr:RemoveTimer(timer)
  frameC = 0
  ui.main.Parent = nil
  timer = nil
end

local TimerRefresh, AdjustGoodsContent = function()
  local ts = math.min(1, frameC / 8)
  ComFuc.SetCtrlColorLcSize(ui.main_son, ui.main_son.Size, Vector2(-10, 60 + 200 * (1 - ts)), ARGB(ts * 255, 255, 255, 255))
  if not isRemain or frameC < 20 then
    frameC = frameC + 1
  end
  if 40 <= frameC then
    callFuc()
    ui.main.Parent = nil
    ComFuc.SetCtrlColorLcSize(ui.main_son, ui.main_son.Size, Vector2(-10, 260), ARGB(0, 255, 255, 255))
    TimerRemove()
  end
end, function()
  local ts = math.min(1, frameC / 8)
  ComFuc.SetCtrlColorLcSize(ui.main_son, ui.main_son.Size, Vector2(-10, 60 + 200 * (1 - ts)), ARGB(ts * 255, 255, 255, 255))
  if not isRemain or frameC < 20 then
    frameC = frameC + 1
  end
  if 40 <= frameC then
    callFuc()
    ui.main.Parent = nil
    ComFuc.SetCtrlColorLcSize(ui.main_son, ui.main_son.Size, Vector2(-10, 260), ARGB(0, 255, 255, 255))
    TimerRemove()
  end
end

function AdjustGoodsContent()
  local width = ui.main_sson.Size.x
  local height = ui.main_sson.Size.y
  local width_good1 = ui.goods_content1.Size.x
  local height_good1 = ui.goods_content1.Size.y
  local width_good2 = ui.goods_content2.Size.x
  local height_good2 = ui.goods_content2.Size.y
  local delta_x1 = (width - width_good1) / 2
  local delta_y1 = (height - height_good1 - height_good2) / 2
  local delta_x2 = (width - width_good2) / 2
  local delta_y2 = delta_y1 + 90
  ui.goods_content1.Location = Vector2(delta_x1, delta_y1)
  ui.goods_content2.Location = Vector2(delta_x2, delta_y2)
end

function Show(data, fuc, interf, interf2)
  callFuc = fuc or function()
  end
  if 10 < #data then
    ui.goods_content1.Size = Vector2(854, 80)
    ui.goods_content2.Size = Vector2((#data - 10) * 86 - 6, 80)
  else
    ui.goods_content1.Size = Vector2(#data * 86 - 6, 80)
    ui.goods_content2.Size = Vector2(0, 0)
  end
  AdjustGoodsContent()
  for i, v in ipairs(data) do
    v.grade = v.grade or 1
    ui["gain_" .. i .. "_lev"].Skin = SkinF.personalInfo_quality[v.grade]
    local tnum = v.quantity or v.num or v.type ~= 2 and v.type ~= 5 and v.unit or 0
    if tonumber(v.type) == 7 and (tonumber(v.id) == 1 or tonumber(v.id) == 2 or tonumber(v.id) == 3) then
      ui["gain_" .. i .. "_count"].Text = tnum
      ui["gain_" .. i .. "_res"].Skin = Gui.Gui.ControlSkin({
        BackgroundImage = Gui.Image("ui/skinF/skin_common_icon_gold01.tga", Vector4(0, 0, 0, 0))
      })
    else
      local res = v.resource
      local tp = string.find(res, ",")
      if tp then
        res = string.sub(res, 2, tp - 2)
      end
      ui["gain_" .. i .. "_res"].Skin = Gui.Gui.ControlSkin({
        BackgroundImage = Gui.Image(resDir2 .. res .. ".tga", Vector4(0, 0, 0, 0))
      })
      if v.type == 5 then
        if v.subType == 1 then
          ui["gain_" .. i .. "_res"].Skin = SkinF.personalInfo_095
        elseif v.subType == 2 then
          ui["gain_" .. i .. "_res"].Skin = SkinF.personalInfo_262
        end
      end
    end
    if 1 < tnum then
      ui["gain_" .. i .. "_count"].Text = tnum
    else
      ui["gain_" .. i .. "_count"].Text = nil
    end
    ui["gain_" .. i .. "_res"].EventMouseEnter = function(sender, e)
      if tonumber(v.type) ~= 7 then
        local temp = interf
        if not temp then
          temp = tip_sys_interface[v.type]
          if v.type == 5 then
            Tip.SetRpc("tip_sys_avatar", {
              t = v.type,
              sid = v.id
            })
          else
            Tip.SetRpc(temp, {
              t = v.type,
              sid = v.sid
            })
          end
        else
          if interf2 and i == 1 then
            temp = interf2
          end
          if v.type == 5 then
            Tip.SetRpc("tip_sys_avatar", {
              t = v.type,
              sid = v.id
            })
          else
            Tip.SetRpc(temp, {
              t = v.type,
              prizeId = v.prizeId
            })
          end
        end
        Tip.SetUseDescription(false)
        Tip.SetOwner(sender)
      end
    end
  end
  if timer then
    TimerRemove()
  end
  isRemain = false
  ComFuc.SetCtrlColorLcSize(ui.main_son, ui.main_son.Size, Vector2(-10, 260), ARGB(0, 255, 255, 255))
  timer = game.TimerMgr:AddTimer(0.05)
  timer.EventOnTimer = TimerRefresh
  ui.main.Parent = gui
end
