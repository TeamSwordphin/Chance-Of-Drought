local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Input = require(game:GetService("ReplicatedStorage").Packages.Input)

local TweenService = game:GetService("TweenService")
local Player = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Lerp = require(ReplicatedStorage.Modules.Lerp)

local BaseController = Knit.CreateController({
	Name = "BaseController",
	Camera = workspace.Camera,
})

local BaseEquipment

local EMPTY_VECTOR = Vector3.new()

local BASE_MOVE_SPEED = 12
local BASE_SPRINT_FACTOR = 2

function BaseController:KnitStart()
	local character, humanoid, rootPart
	local rotation = CFrame.new()

	local keyboard = Input.Keyboard.new()

	local function onCharacterAdded(newCharacter)
		character = newCharacter
		humanoid = newCharacter:WaitForChild("Humanoid")
		rootPart = newCharacter:WaitForChild("HumanoidRootPart")
	end

	local function controlRenderStep(delta)
		if not rootPart or humanoid.Health <= 0 then
			return
		end

		local baseLerpCoeff = math.min(delta * 20, 1)
		local lookVector = self.Camera.CFrame.LookVector

		rotation = rotation:Lerp(CFrame.lookAt(EMPTY_VECTOR, Vector3.new(lookVector.X, 0, lookVector.Z)), baseLerpCoeff)

		--- Rotate the user
		if not rootPart.Anchored and not humanoid.AutoRotate then
			TweenService:Create(rootPart, TweenInfo.new(0.1), { CFrame = CFrame.new(rootPart.Position) * rotation })
				:Play()
		end

		--- Movement
		local stance = character:GetAttribute("Stance")
		local sprinting = stance == "Sprint"

		humanoid.WalkSpeed =
			Lerp(humanoid.WalkSpeed, BASE_MOVE_SPEED * (sprinting and BASE_SPRINT_FACTOR or 1), math.min(delta * 10, 1))

		--- Camera Field Of View
		Player.PlayerScripts.PlayerCameraMain:SetAttribute("FieldOfView", sprinting and 84 or 78)
	end

	local function onKeyDown(keyCode)
		if keyCode == Enum.KeyCode.LeftShift then
			character:SetAttribute("Stance", "Sprint")
		end
	end

	local function onKeyUp(keyCode)
		if keyCode == Enum.KeyCode.LeftShift then
			character:SetAttribute("Stance", "Walk")
		end
	end

	--- Init
	onCharacterAdded(Player.Character or Player.CharacterAdded:Wait())

	--- Connect events
	Player.CharacterAdded:Connect(onCharacterAdded)
	RunService:BindToRenderStep("Control", 3, controlRenderStep)
	keyboard.KeyDown:Connect(onKeyDown)
	keyboard.KeyUp:Connect(onKeyUp)
end

function BaseController:KnitInit()
	BaseEquipment = Knit.GetController("BaseEquipment")
end

return BaseController
