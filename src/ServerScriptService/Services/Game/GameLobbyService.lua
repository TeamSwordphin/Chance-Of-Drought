local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local GameLobbyService = Knit.CreateService({
	Name = "GameLobbyService",
	Client = {},
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
		print("Game Start")
		resolve()
	end)
end

function GameLobbyService:KnitInit()
	Players.PlayerAdded:Connect(function(player)
		table.insert(self.Squad, player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		table.find(self.Squad, player)
		table.remove(self.Squad, player)
	end)
end

return GameLobbyService
