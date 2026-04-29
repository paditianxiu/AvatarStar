require("GmCameraControlA.lua")
require("GmCameraControlB.lua")
local WatchCameraControl = require("WatchCameraControl.lua")
local GMCamera = {}
local currentA = GmCameraControlA
local currentB = GmCameraControlB
GmCameraControlA.Hide()
WatchCameraControl.Hide()
GmCameraControlB.Hide()

function GMCamera.Switch(mode)
  if mode == "GM" then
    currentA = GmCameraControlA
    currentB = GmCameraControlB
  elseif mode == "WATCH" then
    currentA = GmCameraControlA
    currentB = WatchCameraControl
  end
  return
end

function GMCamera.ShowControlA()
  currentA.Show()
end

function GMCamera.HideControlA()
  currentA.Hide()
end

function GMCamera.RefreshControl()
  currentA.RefreshPlayerList()
  if currentB.RefreshPlayerList then
    currentB.RefreshPlayerList()
  end
end

function GMCamera.ShowControlB()
  currentB.Show()
end

function GMCamera.HideControlB()
  currentB.Hide()
end

function GMCamera.Initialize()
  currentA.Initialize()
  currentB.Initialize()
end

function GMCamera.Finalize()
  currentA.Finalize()
  currentB.Finalize()
  GMCamera.Switch("GM")
end

function GMCamera.ResetParam()
  currentB.ResetParam()
end

function GMCamera.RelocateWindows()
  currentA.RelocateWindows()
end

return GMCamera
