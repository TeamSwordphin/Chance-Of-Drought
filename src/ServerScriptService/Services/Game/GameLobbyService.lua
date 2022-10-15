local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local GameLobbyService = Knit.CreateService({
	Name = "GameLobbyService",
	Client = {
		Class = Knit.CreateSignal(),
	},
	Squad = {},
	Timer = nil,
})

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Promise = require(Knit.Util.Promise)

local podCam = workspace:WaitForChild("DropPods"):WaitForChild("PodCam")
local pod = workspace:WaitForChild("DropPods"):WaitForChild("Pod")

Players.CharacterAutoLoads = false

function GameLobbyService:KnitStart()
	self.Timer = Promise.new(function(resolve, reject, onCancel)
		for i = 40, 0, -1 do
			workspace:SetAttribute("LobbyTimer", i)
			task.wait(1)
		end
		workspace:SetAttribute("LobbyTimer", "")
		print("Game Start")
		resolve()
	end):andThen(function()
		for _, player in ipairs(self.Squad) do
			local playerPod = pod:Clone()
			playerPod.Name = player.Name
			playerPod:PivotTo(
				CFrame.new(Vector3.new(podCam.Position.X + 50, podCam.Position.Y + 400, podCam.Position.Z + 50))
			)
			playerPod.Parent = workspace.DropPods.Pods
			local podTween = TweenService:Create(
				playerPod,
				TweenInfo.new(3),
				{ Position = Vector3.new(podCam.Position.X + 50, podCam.Position.Y, podCam.Position.Z + 50) }
			)
			task.defer(function()
				podTween:Play()
				podTween.Completed:Wait()
				workspace:SetAttribute("PodHasDropped", true)
			end)
		end
	end)
end

function GameLobbyService:KnitInit()
	for _, player in ipairs(Players:GetChildren()) do
		table.insert(self.Squad, player)
	end
	Players.PlayerAdded:Connect(function(player)
		table.insert(self.Squad, player)
		player:SetAttribute("Class", "Hammer")
	end)
	Players.PlayerRemoving:Connect(function(player)
		table.remove(self.Squad, table.find(self.Squad, player))
	end)
	self.Client.Class:Connect(function(player, class)
		if workspace:GetAttribute("LobbyTimer") ~= "" then
			--TODO: Validate
			player:SetAttribute("Class", class)
		end
	end)
end

return GameLobbyService
