--- Controls the sending of information of camera angles to the clients
-- @author Swordphin
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local PlayerCameraSpectator = Knit.CreateService({
	Name = "PlayerCameraSpectator",
	Client = {},
})

local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService: RunService = game:GetService("RunService")
local Players: Players = game:GetService("Players")

local SEND_FREQUENCY = 1 / 50

local PlayerCameraData = {}
local _LastSent = 0

local folder: Folder = Instance.new("Folder")
folder.Name = "PlayerCameraMainNetwork"

local remoteEvent: RemoteEvent = Instance.new("RemoteEvent")
remoteEvent.Name = "SendCameraCoordinates"
remoteEvent.Parent = folder

--- Creates a table that houses the last camera angle information of the player.
local function onPlayerAdded(player: Player)
	PlayerCameraData[player.Name] = { X = 0, Y = 0 }
end

--- Removes the player from the table upon leaving
local function onPlayerRemoving(player: Player)
	PlayerCameraData[player.Name] = nil
end

--- Player sends their camera information over to the server
local function onInformationSend(player: Player, x: number, y: number)
	if type(x) ~= "number" or type(y) ~= "number" then --- Make sure the clients are sending over valid numbers.
		return
	end

	PlayerCameraData[player.Name].X = x
	PlayerCameraData[player.Name].Y = y
end

--- Main run loop that periodically sends camera information to players
local function sendCameraPositions(delta: number)
	local currentClock = os.clock()

	if currentClock - _LastSent < SEND_FREQUENCY then
		return
	end

	remoteEvent:FireAllClients(PlayerCameraData)
end

function PlayerCameraSpectator:KnitStart() end

function PlayerCameraSpectator:KnitInit()
	remoteEvent.OnServerEvent:Connect(onInformationSend)
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	RunService.Heartbeat:Connect(sendCameraPositions)

	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end

	folder.Parent = ReplicatedStorage
end

return PlayerCameraSpectator
