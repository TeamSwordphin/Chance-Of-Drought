local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Input = require(game:GetService("ReplicatedStorage").Packages.Input)

local UserInputService = game:GetService("UserInputService")
local Player = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")

local Spring

local BaseCamera = Knit.CreateController({
	Name = "BaseCamera",
	Camera = workspace.Camera,
	MouseWorldPosition = Vector3.new(),
	Recoil = nil, -- spring
})

local BASE_FOV = 70
local BASE_OFFSET = Vector3.new(0, 5, 0)
local BASE_SENSITIVITY = Vector2.new(1 / 250, 1 / 250)

local MIN_Y, MAX_Y = -1.4, 1.4

function BaseCamera:KnitStart()
	local character, humanoid, rootPart, raycastParams
	local x, y = 0, 0

	local mouse = Input.Mouse.new()

	local function onCharacterAdded(newCharacter)
		character = newCharacter
		humanoid = newCharacter:WaitForChild("Humanoid")
		rootPart = newCharacter:WaitForChild("HumanoidRootPart")

		raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = { character }

		mouse:LockCenter() -- if lock issues this might be it
		self.Camera.CameraType = Enum.CameraType.Scriptable
	end

	local function controlRenderStep(delta)
		UserInputService.MouseIconEnabled = false

		if not rootPart or humanoid.Health <= 0 then
			return
		end

		local stance = character:GetAttribute("Stance")
		local shoulder = character:GetAttribute("Shoulder")
		local height = character:GetAttribute("Height")
		local zoom = character:GetAttribute("Zoom")

		local center = rootPart.Position + BASE_OFFSET
		local cframe = CFrame.new(center)
			* CFrame.Angles(0, x, 0)
			* CFrame.Angles(y, 0, 0)
			* CFrame.new(shoulder, height, zoom)
		local rotation = cframe - cframe.Position

		local raycastResult = workspace:Raycast(center, cframe.Position - center)
		local position = center + (cframe.Position - center)

		if raycastResult then
			position = raycastResult.Position + raycastResult.Normal * 0.2
		end

		--- Update springs
		self.Recoil:Update(delta)

		local offset = Vector3.new(self.Recoil.Position.X * 0.5, self.Recoil.Position.Y, self.Recoil.Position.Z)
			* (self.Camera.FieldOfView / 70)

		self.Camera.FieldOfView = self.Shared.Lerp(
			self.Camera.FieldOfView,
			BASE_FOV + (stance == "Sprinting" and 5 or 0),
			math.min(delta * 10, 1)
		)
		self.Camera.CFrame = CFrame.new(position)
			* rotation
			* CFrame.new(offset)
			* CFrame.Angles(offset.Z / 20, -offset.X / 20, 0)
		self.Camera.Focus = self.Camera.CFrame * CFrame.new(0, 0, -20)

		local mouseRaycastResult = mouse:Raycast(raycastParams)
		self.MouseWorldPosition = mouseRaycastResult or Vector3.new()
	end

	local function onMouseMoved()
		local sensitivity = BASE_SENSITIVITY * math.min(2, UserSettings().GameSettings.MouseSensitivity)
		local delta = mouse:GetDelta()

		x = (x - delta.X * sensitivity.X) % (math.pi * 2)
		y = math.clamp(y - delta.Y * sensitivity.Y, MIN_Y, MAX_Y)
	end

	--- Init
	onCharacterAdded(Player.Character or Player.CharacterAdded:Wait())

	--- Connect events
	Player.CharacterAdded:Connect(onCharacterAdded)
	RunService:BindToRenderStep("Camera", 4, controlRenderStep)
	Player:GetMouse().Move:Connect(onMouseMoved)
end

function BaseCamera:KnitInit()
	Spring = Knit.GetController("SpringController")
	self.Recoil = Spring:Create(1, 100, 10, 2)
end

return BaseCamera
