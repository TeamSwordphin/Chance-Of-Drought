local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- No longer need to :wait() for UIs to load
if not game:IsLoaded() then
	game.Loaded:Wait()
end

local UIs = ReplicatedStorage.UI
local playerGui = game:GetService("Players").LocalPlayer.PlayerGui

for _, screenGui in ipairs(UIs:GetChildren()) do
	screenGui:Clone().Parent = playerGui
end
--

local Knit = require(ReplicatedStorage.Packages.Knit)

Knit.AddControllers(ReplicatedStorage.Controllers)

Knit.Start():catch(warn)
