-- Native hits provide the 1/2/3/4-kill sounds and xN counter. Give exactly five
-- consecutive kills a distinct rank-up accent using an existing audio event.
local P = PushCmd
if not P or not P.cmdTable then return end
local lastKey
P.cmdTable.kill_streak = function(data)
  local state = ptr_cast(game.CurrentState, "Client.StateMainGame")
  if not state or tonumber(data.streak) ~= 5 then return end
  local key = tostring(data.roomId) .. ":" .. tostring(data.generation) .. ":" .. tostring(data.kills)
  if key == lastKey then return end
  lastKey = key
  gui:PlayAudio("rank_up")
end
