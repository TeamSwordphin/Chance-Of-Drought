local Controller = {}

local BASE_FOV = 70
local BASE_OFFSET = Vector3.new(0, 5, 0)
local BASE_SENSITIVITY = Vector2.new(1 / 250, 1 / 250)

local MIN_Y, MAX_Y = -1.4, 1.4

function Controller:Start()
	local character, humanoid, rootPart, raycastParams
	local x, y = 0, 0

	local mouse = self.Controllers.UserInput:Get("Mouse")

	local function onCharacterAdded(newCharacter)
		character = newCharacter
		humanoid = newCharacter:WaitForChild("Humanoid")
		rootPart = newCharacter:WaitForChild("HumanoidRootPart")

		raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = { character }

		self.Camera.CameraType = Enum.CameraType.Scriptable
	end

	local function controlRenderStep(delta)
		mouse:LockCenter()
		mouse:SetMouseIconEnabled(false)

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
	onCharacterAdded(self.Player.Character or self.Player.CharacterAdded:Wait())

	--- Connect events
	self.Player.CharacterAdded:Connect(onCharacterAdded)
	self.Shared.CommonServices.RunService:BindToRenderStep("Camera", 4, controlRenderStep)
	mouse.Moved:Connect(onMouseMoved)
end

function Controller:Init()
	self.Camera = workspace.Camera
	self.MouseWorldPosition = Vector3.new()
	self.Recoil = self.Shared.Spring:Create(1, 100, 10, 2)
end

return Controller
