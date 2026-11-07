local function original() end

local function install()
  local marker = "/finalcombat/actors.mounted"
  local filename = "C:/Game/AvatarStar/AvatarStar_actors.pde"
  assert(Path and Path.MountVFS and Path.Exists, "Core.Path is unavailable")
  if not Path.Exists(marker) then
    assert(Path.MountVFS("/", filename, "kVirtualRead", 2), "Cannot mount " .. filename)
    assert(Path.Exists(marker), "Actor archive marker is not visible after mounting")
  end
  AS_ACTORS_PACK_MOUNTED = true
end

local ok, err = pcall(install)
local message = ok and "Actor resource archive mounted successfully" or ("Actor resource archive: " .. tostring(err))
print(message)
-- Keep a local diagnostic so a mount failure can be checked without injecting
-- into the running client. Failure to write the diagnostic cannot block startup.
if io and io.open then
  local opened, file = pcall(io.open, "C:/Game/AvatarStar/actors-pack-status.log", "w")
  if opened and file then
    pcall(file.write, file, message .. "\n")
    pcall(file.close, file)
  end
end
original()
