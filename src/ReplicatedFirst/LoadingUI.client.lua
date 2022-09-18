local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local PlayerGui = Players.LocalPlayer.PlayerGui

-- Loading Screen
local LoadingScreen = ReplicatedFirst:FindFirstChild("LoadingGui") or ReplicatedFirst:WaitForChild("LoadingGui")
local GetTeleportGui = TeleportService:GetArrivingTeleportGui()
ContentProvider:PreloadAsync({ LoadingScreen, GetTeleportGui })

if GetTeleportGui then
	GetTeleportGui.Parent = PlayerGui
else
	LoadingScreen.Parent = PlayerGui
end

ReplicatedFirst:RemoveDefaultLoadingScreen()

local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"))

Knit.OnStart()
	:andThen(function()
		task.wait(3)
		LoadingScreen:Destroy()
		if GetTeleportGui then
			GetTeleportGui:Destroy()
		end
	end)
	:catch(warn)
