local ui_mgr = {}

function ui_mgr:create()
  local o = {
    set = {}
  }
  self.__index = self
  setmetatable(o, self)
  return o
end

function ui_mgr:push(name, child)
  if self.set[name] == nil then
    self.set[name] = child
  else
    print("ui_mgr:push error")
  end
end

function ui_mgr:remove(name)
  if self.set[name] then
    self.set[name] = nil
  else
    print("ui_mgr:remove error")
  end
end

function ui_mgr:switch(name, winRoot)
  for k, v in pairs(self.set) do
    if k ~= name then
      v.Hide()
    end
  end
  self.set[name].Show(winRoot)
end

return ui_mgr
