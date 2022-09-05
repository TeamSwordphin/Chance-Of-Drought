local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local QueueService = Knit.CreateService({
	Name = "QueueService",
	Client = {},
})

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local Promise = require(Knit.Util.Promise)
local SafeTeleport = require(game:GetService("ReplicatedStorage").Modules.SafeTeleport)
local playersInQueue = {}

function QueueService.Client:Add(player, lobby)
	self.Server:Add(player, lobby)
end

function QueueService.Client:Remove(player)
	self.Server:Remove(player)
end

function QueueService:Add(player, lobby)
	-- check max users
	if #playersInQueue[lobby].Players >= 5 then
		return
	end
	-- check if already in queue
	for _, data in pairs(playersInQueue) do
		for _, value in ipairs(data.Players) do
			if player == value then
				return
			end
		end
	end

	player.Character:PivotTo(
		CFrame.lookAt(
			Vector3.new(lobby.InQueue.Position.X, lobby.InQueue.Position.Y + 4, lobby.InQueue.Position.Z),
			Vector3.new(lobby.Gate.Position.X, lobby.InQueue.Position.Y + 4, lobby.Gate.Position.Z)
		)
	)

	table.insert(playersInQueue[lobby].Players, player)
	lobby.Gate.PlayerCap.Counter.Text = #playersInQueue[lobby].Players .. "/5"

	if #playersInQueue[lobby].Players > 0 and not playersInQueue[lobby].Going then
		playersInQueue[lobby].Going = true
		playersInQueue[lobby].Timer = Promise.new(function(resolve, reject, onCancel)
			onCancel(function()
				playersInQueue[lobby].Going = false
				lobby.Gate.Timer.Counter.Text = ""
			end)

			for i = 20, 0, -1 do
				if #playersInQueue[lobby].Players > 0 then
					lobby.Gate.Timer.Counter.Text = tostring(i)
					task.wait(1)
				else
					lobby.Gate.Timer.Counter.Text = ""
					playersInQueue[lobby].Going = false
					resolve()
				end
				if i == 0 then
					--Teleport players
					local teleportOptions = Instance.new("TeleportOptions")
					teleportOptions.ShouldReserveServer = true
					SafeTeleport(10813419765, playersInQueue[lobby].Players, teleportOptions)
					print("TELE")
					playersInQueue[lobby].Players = {}
					playersInQueue[lobby].Going = false
					lobby.Gate.Timer.Counter.Text = ""
					resolve()
				end
			end
		end)
	end
	print(playersInQueue)
end

function QueueService:Remove(player)
	for lobby, data in pairs(playersInQueue) do
		for i, value in ipairs(data.Players) do
			if player == value then
				table.remove(playersInQueue[lobby].Players, i)
				lobby.Gate.PlayerCap.Counter.Text = #playersInQueue[lobby].Players .. "/5"
				if #playersInQueue[lobby].Players == 0 then
					playersInQueue[lobby].Timer:cancel()
				end
			end
		end
	end
	print(playersInQueue)
end

function QueueService:KnitStart()
	Players.PlayerRemoving:Connect(function(player)
		self:Remove(player)
	end)
end

function QueueService:KnitInit()
	local lobbys = workspace.Lobbys:GetChildren()
	for _, lobby in ipairs(lobbys) do
		playersInQueue[lobby] = {
			Players = {},
			Timer = nil, -- Promise
			Going = false,
		}
	end
end

return QueueService
