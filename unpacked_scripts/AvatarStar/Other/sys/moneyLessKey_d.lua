module("L_MoneyLessKey", package.seeall)
local MoneyLessKeys = {
  gold = {},
  star = {},
  ticket = {},
  common = {msgbox_common_conditionkey_131 = 1}
}
local MoneyTypeKeys = {
  gold = {msgbox_common_conditionkey_128 = 1},
  star = {msgbox_common_conditionkey_129 = 1},
  ticket = {msgbox_common_conditionkey_195 = 1}
}
local HelpTextKey, CreateKeyList = {
  gold = "msgbox_common_help_01",
  star = "msgbox_common_help_03",
  ticket = "msgbox_common_help_02"
}, {
  gold = "msgbox_common_help_01",
  star = "msgbox_common_help_03",
  ticket = "msgbox_common_help_02"
}
local CreateKeyList, IsLessKeyOne = function(keyStr)
  local i = 1
  local keyList = {}
  while i <= #keyStr do
    local be = string.find(keyStr, ",", i)
    local k
    if be then
      k = string.sub(keyStr, i, be - 1)
      table.insert(keyList, k)
      i = be + 1
    else
      k = string.sub(keyStr, i)
      table.insert(keyList, k)
      break
    end
  end
  return keyList
end, nil

function IsLessKeyOne(key)
  local isLessKey = false
  for k, v in pairs(MoneyLessKeys) do
    if v[key] then
      isLessKey = true
    end
  end
  return isLessKey
end

function IsLessKey(keyStr)
  if type(keyStr) ~= "string" then
    keyStr = tostring(keyStr)
  end
  local isLessKeyFinal = false
  local keyList = CreateKeyList(keyStr)
  for i, v in ipairs(keyList) do
    local isLess = IsLessKeyOne(v)
    if isLess then
      isLessKeyFinal = true
      break
    end
  end
  return isLessKeyFinal
end

function MoneyLessType(keyStr)
  if type(keyStr) ~= "string" then
    keyStr = tostring(keyStr)
  end
  if IsLessKey(keyStr) then
    local ty
    local keyList = CreateKeyList(keyStr)
    for i, v in ipairs(keyList) do
      for k, v1 in pairs(MoneyLessKeys) do
        if v1[v] then
          ty = k
        end
      end
    end
    if ty == "common" then
      ty = nil
      for i, v in ipairs(keyList) do
        for k, v1 in pairs(MoneyTypeKeys) do
          if v1[v] then
            ty = k
          end
        end
      end
      if not ty then
        print("============this key has no type============")
      end
    end
    return ty
  else
    print("============Error:this is not moneyLessKey============")
    return nil
  end
end
