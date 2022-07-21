local Controller = {}

local EMPTY_VECTOR = Vector3.new()

local BASE_MOVE_SPEED = 12
local BASE_SPRINT_FACTOR = 2

local BASE_ROTATION_TIMER = 2

function Controller:Start()
	local character, humanoid, rootPart
	local rotation = CFrame.new()

	local keyboard = self.Controllers.UserInput:Get("Keyboard")
	local equipment = self.Controllers.Character.BaseEquipment
	local tweenService = self.Shared.CommonServices.TweenService

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
			tweenService
				:Create(rootPart, TweenInfo.new(0.1), { CFrame = CFrame.new(rootPart.Position) * rotation })
				:Play()
		end

		--- Movement
		local stance = character:GetAttribute("Stance")

		humanoid.WalkSpeed = self.Shared.Lerp(
			humanoid.WalkSpeed,
			BASE_MOVE_SPEED * (stance == "Sprint" and BASE_SPRINT_FACTOR or 1),
			math.min(delta * 10, 1)
		)
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
	onCharacterAdded(self.Player.Character or self.Player.CharacterAdded:Wait())

	--- Connect events
	self.Player.CharacterAdded:Connect(onCharacterAdded)
	self.Shared.CommonServices.RunService:BindToRenderStep("Control", 3, controlRenderStep)
	keyboard.KeyDown:Connect(onKeyDown)
	keyboard.KeyUp:Connect(onKeyUp)
end

function Controller:Init()
	self.Camera = workspace.Camera
end

return Controller
