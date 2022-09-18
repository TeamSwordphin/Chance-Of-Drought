local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local GameLobbyController = Knit.CreateController({
	Name = "GameLobbyController",
	Camera = workspace.Camera,
	Squad = {}, -- Squad[player] =  {PlayerCard = Instance}
})

local GameLobbyService
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
		Champion = "Hawk Eye",
	}
	plrCard.NameLabel.Text = player.Name
	local userId = player.UserId
	local thumbType = Enum.ThumbnailType.HeadShot
	local thumbSize = Enum.ThumbnailSize.Size180x180
	local content, isReady = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
	plrCard.Icon.Image = content
	plrCard.Parent = PlayerList
end

local function RemoveCard(player)
	GameLobbyController.Squad[player].PlayerCard:Destroy()
	GameLobbyController.Squad[player] = nil
end

function GameLobbyController:KnitStart() end

function GameLobbyController:KnitInit()
	GameLobbyService = Knit.GetService("GameLobbyService")
	CharScreen.Enabled = true
	-- Camera Focus
	local look = workspace:WaitForChild("GameLobbyPreview"):WaitForChild("Look")
	self.Camera.CameraType = Enum.CameraType.Watch
	self.Camera.CameraSubject = look
	self.Camera.CFrame = CFrame.new(Vector3.new(look.Position.X, look.Position.Y, look.Position.Z + 30), look.Position)
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
	-- Countdown Attribute Connection
	CountdownGui.Text = workspace:GetAttribute("LobbyTimer")
	workspace:GetAttributeChangedSignal("LobbyTimer"):Connect(function()
		CountdownGui.Text = workspace:GetAttribute("LobbyTimer")
		if workspace:GetAttribute("LobbyTimer") == "" then
			CharScreen.Enabled = false
		end
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
end

return GameLobbyController
