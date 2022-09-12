local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")

-- Loading Screen
local LoadingScreen = ReplicatedFirst:FindFirstChild("LoadingGui") or ReplicatedFirst:WaitForChild("LoadingGui")
ContentProvider:PreloadAsync({ LoadingScreen, ReplicatedStorage.TeleportGui })
LoadingScreen.Parent = Players.LocalPlayer.PlayerGui
ReplicatedFirst:RemoveDefaultLoadingScreen()

-- No longer need to :wait() for UIs to load
if not game:IsLoaded() then
	game.Loaded:Wait()
end

local UIs = ReplicatedStorage.UI
local playerGui = Players.LocalPlayer.PlayerGui

for _, screenGui in ipairs(UIs:GetChildren()) do
	screenGui:Clone().Parent = playerGui
end

local Knit = require(ReplicatedStorage.Packages.Knit)

if game.PlaceId == 10299014171 then -- check if it's the lobby
	Knit.AddControllers(ReplicatedStorage.Controllers.Lobby)
else -- it's the game
	Knit.AddControllers(ReplicatedStorage.Controllers)
end

Knit.Start()
	:andThen(function()
		LoadingScreen:Destroy()
	end)
	:catch(warn)
