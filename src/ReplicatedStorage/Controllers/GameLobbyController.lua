local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Janitor = require(game:GetService("ReplicatedStorage").Packages.Janitor)

local GameLobbyController = Knit.CreateController({
	Name = "GameLobbyController",
	Camera = workspace.Camera,
	Squad = {}, -- CreateCard()
	ToCleanConnections = Janitor.new(),
})

local GameLobbyService
local DataService
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local CharScreen = Player.PlayerGui.CharacterScreen
local PlayerList = CharScreen.PlayerList.Players
local CountdownGui = CharScreen.Countdown
local ClassSelect = CharScreen.ClassSelect

local function CreateCard(player)
	local plrCard = ReplicatedStorage.UIModules.PlayerCard:Clone()
	GameLobbyController.Squad[player] = {
		PlayerCard = plrCard,
		Class = "Hammer",
	}
	plrCard.TextFrame.NameLabel.Text = player.Name
	plrCard.TextFrame.ClassLabel.Text = player:GetAttribute("Class") or ""
	local userId = player.UserId
	local thumbType = Enum.ThumbnailType.HeadShot
	local thumbSize = Enum.ThumbnailSize.Size180x180
	local content, isReady = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
	plrCard.Icon.Image = content
	plrCard.Parent = PlayerList
	player:GetAttributeChangedSignal("Class"):Connect(function()
		plrCard.TextFrame.ClassLabel.Text = player:GetAttribute("Class") or ""
	end)
	return plrCard
end

local function RemoveCard(player)
	GameLobbyController.Squad[player].PlayerCard:Destroy()
	GameLobbyController.Squad[player] = nil
end

local function CharacterSetup()
	for _, frame in ipairs(ClassSelect:GetChildren()) do
		if frame:IsA("ImageButton") then
			if DataService:Get():expect()["CharacterPool"][frame.Name] == true then
				frame.Active = true
				frame.Lock.Visible = false
			else
				frame.Active = false
				frame.Lock.Visible = true
			end
		end
	end
end

function GameLobbyController:KnitStart()
	CharacterSetup()
end

function GameLobbyController:KnitInit()
	GameLobbyService = Knit.GetService("GameLobbyService")
	DataService = Knit.GetService("DataService")
	CharScreen.Enabled = true
	-- Camera Focus
	local look = workspace:WaitForChild("GameLobbyPreview"):WaitForChild("Look")
	self.Camera.CameraType = Enum.CameraType.Watch
	self.Camera.CameraSubject = look
	self.Camera.CFrame =
		CFrame.lookAt(Vector3.new(look.Position.X, look.Position.Y, look.Position.Z + 30), look.Position)
	-- PlayerCard Setup
	Players.PlayerAdded:Connect(function(player)
		CreateCard(player)
	end)
	for _, player in ipairs(Players:GetChildren()) do
		CreateCard(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		RemoveCard(player)
	end)
	-- Class select
	for _, gui in ipairs(ClassSelect:GetChildren()) do
		if gui:IsA("ImageButton") then
			gui.Activated:Connect(function()
				for _, ui in ipairs(ClassSelect:GetChildren()) do
					if ui:IsA("ImageButton") then
						ui.UIStroke.Thickness = 0
					end
				end
				gui.UIStroke.Thickness = 4
				GameLobbyService.Class:Fire(gui.Name)
			end)
		end
	end
	-- Countdown Attribute Connection
	CountdownGui.Text = workspace:GetAttribute("LobbyTimer")
	workspace:GetAttributeChangedSignal("LobbyTimer"):Connect(function()
		CountdownGui.Text = workspace:GetAttribute("LobbyTimer")
		if workspace:GetAttribute("LobbyTimer") == "" then
			CharScreen.Enabled = false
			local podCam = workspace:WaitForChild("DropPods"):WaitForChild("PodCam")
			local pod = workspace:WaitForChild("DropPods"):WaitForChild("Pods"):WaitForChild("Pod")
			self.Camera.CameraType = Enum.CameraType.Scriptable
			GameLobbyController.ToCleanConnections:Add(
				RunService.RenderStepped:Connect(function(delta)
					self.Camera.CFrame = CFrame.lookAt(podCam.Position, pod.Position)
				end),
				"Disconnect"
			)
		end
	end)

	workspace:GetAttributeChangedSignal("PodHasDropped"):Connect(function()
		if workspace:GetAttribute("PodHasDropped") == true then
			print("Pod Finished Dropping")
			GameLobbyController.ToCleanConnections:Cleanup()
		end
	end)
end

return GameLobbyController
