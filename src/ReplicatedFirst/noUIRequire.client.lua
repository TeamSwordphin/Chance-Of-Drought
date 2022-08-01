-- No longer need to :wait() for UIs to load
if not game:IsLoaded() then
	game.Loaded:Wait()
end

local UIs = game:GetService("ReplicatedStorage").UI
local playerGui = game:GetService("Players").LocalPlayer.PlayerGui

for _, screenGui in ipairs(UIs:GetChildren()) do
	screenGui:Clone().Parent = playerGui
end
