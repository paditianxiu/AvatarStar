module("StcMsg", package.seeall)

function GetVipLevelLimitMsg()
  msgclass = 0
  timeLeave = 1
  return msgclass, timeLeave, "你未满5级， 无法使用VIP贵宾卡"
end

function GetMoney()
  if a == 1 then
    return "你未满5级" .. tostring(b)
  else
  end
end
