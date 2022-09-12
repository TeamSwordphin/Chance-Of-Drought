local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local QueueController = Knit.CreateController({ Name = "QueueController" })

local QueueService
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

function QueueController:KnitStart()
	local lobbys = workspace.Lobbys:GetChildren()
	local LobbyId
	local isIn = false
	local ExitLobby = Players.LocalPlayer.PlayerGui.ExitLobby
	ExitLobby.TextButton.Activated:Connect(function()
		QueueService:Remove()
		ExitLobby.Enabled = false
		Players.LocalPlayer.Character:PivotTo(
			CFrame.lookAt(
				Vector3.new(LobbyId.ExitNode.Position.X, LobbyId.ExitNode.Position.Y, LobbyId.ExitNode.Position.Z),
				Vector3.new(LobbyId.Gate.Position.X, LobbyId.ExitNode.Position.Y, LobbyId.Gate.Position.Z)
			)
		)
		LobbyId = nil
		isIn = false
	end)
	local function onDeathRemove(character)
		character:WaitForChild("Humanoid").Died:Connect(function()
			QueueService:Remove(Players.LocalPlayer)
			ExitLobby.Enabled = false
			isIn = false
			LobbyId = nil
		end)
	end
	onDeathRemove(Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait())
	Players.LocalPlayer.CharacterAdded:Connect(onDeathRemove)

	for _, lobby in ipairs(lobbys) do
		lobby.Gate.Touched:Connect(function(hit)
			if
				hit.parent:FindFirstChild("Humanoid")
				and hit.parent.Humanoid.Health > 0
				and hit.parent.Name == Players.LocalPlayer.Name
				and isIn == false
			then
				QueueService:Add(lobby)
				ExitLobby.Enabled = true
				isIn = true
				LobbyId = lobby
				task.wait(1)
			end
		end)
	end
end

function QueueController:KnitInit()
	QueueService = Knit.GetService("QueueService")
	TeleportService:SetTeleportGui(ReplicatedStorage.TeleportGui)
end

return QueueController
