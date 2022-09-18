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
local Promise = require(Knit.Util.Promise)

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
	end)
end

function GameLobbyService:KnitInit()
	for _, player in ipairs(Players:GetChildren()) do
		table.insert(self.Squad, player)
	end
	Players.PlayerAdded:Connect(function(player)
		table.insert(self.Squad, player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		table.remove(self.Squad, table.find(self.Squad, player))
	end)
	self.Client.Class:Connect(function(player, class)
		if workspace:GetAttribute("LobbyTimer") ~= "" then
			player:SetAttribute("Class", class)
		end
	end)
end

return GameLobbyService
