--[[
	Looking for the camera script? It is called PlayerCameraMain and is decoupled from Visual Studio.
]]

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Spring

local BaseCamera = Knit.CreateController({ Name = "BaseCamera", Recoil = nil })

function BaseCamera:KnitStart() end

function BaseCamera:KnitInit()
	Spring = Knit.GetController("SpringController")
	self.Recoil = Spring:Create(1, 100, 10, 2)
end

return BaseCamera
