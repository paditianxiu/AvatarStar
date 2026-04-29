module("NumeralConst", package.seeall)
local occ_num = {
  1,
  1.22,
  0.83,
  1
}

function CharacterTransform(char_type, char_para, occ_type)
  local char_eff = 0
  if char_type == "护甲" then
    char_eff = string.format("%.1f", (1 - 1 / (1 + char_para ^ 1 / 470)) * 0.75 * 100)
  elseif char_type == "活力" then
    char_eff = string.format("%.1f", 0.20020000000000002 * char_para ^ 1)
  elseif char_type == "恢复力" then
    char_eff = math.floor(1.1076840000000001 * char_para ^ 1)
  elseif char_type == "耐力" then
    char_eff = math.floor(3.6198470000000005 * char_para ^ 1 * occ_num[occ_type])
  end
  return char_eff
end

max_stone_combine = 5

function ChangeExpToLev(exp, grade)
  local lev = 0
  local exp_per = {
    {
      400,
      1000,
      1800,
      2900,
      4400,
      6400,
      9100,
      12700,
      17500,
      23800,
      33100,
      49400,
      72700,
      103000,
      140300,
      198100,
      261900,
      331700,
      407500,
      489300
    },
    {
      2000,
      4700,
      8300,
      13100,
      19400,
      28700,
      45000,
      68300,
      98600,
      135900,
      193700,
      257500,
      327300,
      403100,
      484900,
      697400,
      929900,
      1182400,
      1655600,
      2228800
    },
    {
      9300,
      25600,
      48900,
      79200,
      116500,
      174300,
      238100,
      307900,
      383700,
      465500,
      678000,
      910500,
      1163000,
      1636200,
      2209400,
      2808200,
      3467000,
      4185800,
      4919600,
      5813400
    }
  }
  local exp_curr = exp_per[grade - 1]
  for i = 20, 1, -1 do
    if exp >= exp_curr[i] then
      return i
    end
  end
  return lev
end

lottery_prize_num_max = 50
