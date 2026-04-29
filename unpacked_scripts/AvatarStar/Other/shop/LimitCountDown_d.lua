module("LimitCountDown", package.seeall)
local originalTime = 0
local curSecond = 0
local curMinute = 0
local curHour = 0
local curDay = 0
local TimeKey
ui = Gui.Create()({
  Gui.Control("main")({
    ComFuc.ComTimeLabel("day", "00", Vector2(20, 18), Vector2(0, 0), 0, 18, col0, "kAlignCenterMiddle", nil, true, SkinF.hecheng_number_1),
    ComFuc.ComTimeLabel("hour", "00", Vector2(20, 18), Vector2(24, 0), 0, 18, col0, "kAlignCenterMiddle", nil, true, SkinF.hecheng_number_1),
    ComFuc.ComTimeLabel("minute", "00", Vector2(20, 18), Vector2(26, 0), 0, 18, col0, "kAlignCenterMiddle", nil, true, SkinF.hecheng_number_1),
    ComFuc.ComTimeLabel("second", "00", Vector2(20, 18), Vector2(50, 0), 0, 18, col0, "kAlignCenterMiddle", nil, true, SkinF.hecheng_number_1)
  })
})

function InitShowTime(curTime, curDay, curHour, curMinute, curSecond)
  curSecond, curMinute, curHour, curDay = TimeTranslate(curTime)
  ui.day.Text = curDay
  ui.hour.Text = 10 <= curHour and curHour or "0" .. curHour
  ui.minute.Text = 10 <= curMinute and curMinute or "0" .. curMinute
  ui.second.Text = 10 <= curSecond and curSecond or "0" .. curSecond
end

function TimeTranslate(cur_time)
  local day = 0
  local hour = 0
  local minute = 0
  local second = 0
  local d, h, m, s = 0
  day = cur_time / 3600 / 24
  d = math.floor(day)
  hour = cur_time / 3600 - d * 24
  h = math.floor(hour)
  minute = cur_time / 60 - (d * 1440 + h * 60)
  m = math.floor(minute)
  second = cur_time - (d * 24 * 3600 + 3600 * h + m * 60)
  s = math.floor(second)
  return s, m, h, d
end

function DealTimeDown(cur_time)
  local timeup
  curSecond, curMinute, curHour, curDay = TimeTranslate(cur_time)
  if cur_time and cur_time <= 0 then
    Shop.RequestBuyList()
    timeup = true
  else
    timeup = false
  end
  if not timeup then
    if curSecond <= 0 then
      curSecond = 59
      if curMinute <= 0 then
        curMinute = 59
        if curHour <= 0 then
          curDay = curDay - 1
          curHour = 23
        else
          curHour = curHour - 1
        end
      else
        curMinute = curMinute - 1
      end
    else
      curSecond = curSecond - 1
    end
    ui.day.Text = curDay
    ui.hour.Text = 10 <= curHour and curHour or "0" .. curHour
    ui.minute.Text = 10 <= curMinute and curMinute or "0" .. curMinute
    ui.second.Text = 10 <= curSecond and curSecond or "0" .. curSecond
    cur_time = cur_time - 1
  end
  return cur_time
end

function SetTimeText()
  if tonumber(ui.day.Text) <= 0 then
    TimeKey = ui.hour.Text .. ":" .. ui.minute.Text .. ":" .. ui.second.Text
  else
    TimeKey = ui.day.Text .. GetUTF8Text("UI_common_Day") .. ui.hour.Text .. ":" .. ui.minute.Text .. ":" .. ui.second.Text
  end
  return TimeKey
end

function Show()
end

function Hide()
end
