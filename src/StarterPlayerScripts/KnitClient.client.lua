local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local UIs = ReplicatedStorage.UI
local PlayerGui = Players.LocalPlayer.PlayerGui

-- No longer need to :wait() for UIs to load
if not game:IsLoaded() then
	game.Loaded:Wait()
end

for _, screenGui in ipairs(UIs:GetChildren()) do
	screenGui:Clone().Parent = PlayerGui
end

local Knit = require(ReplicatedStorage.Packages.Knit)

if game.PlaceId == 10299014171 then -- check if it's the lobby
	Knit.AddControllers(ReplicatedStorage.Controllers.Lobby)
else -- it's the game
	Knit.AddControllers(ReplicatedStorage.Controllers)
end

Knit.Start():catch(warn)
