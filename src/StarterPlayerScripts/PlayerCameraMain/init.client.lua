--- Controls the main aspects of the Player's camera. Can toggle between First Person and Third Person.
-- @author Swordphin

if game.PlaceId == 10813419765 then -- if in the game
	local Players: Players = game:GetService("Players")
	local RunService: RunService = game:GetService("RunService")
	local UserInputService: UserInputService = game:GetService("UserInputService")
	local TweenService: TweenService = game:GetService("TweenService")
	local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Knit = require(ReplicatedStorage.Packages.Knit)
	local Input = require(Knit.Util.Input)

	local BaseCamera
	local Recoil

	local LocalPlayer: any = Players.LocalPlayer
	local Camera: Camera = workspace.Camera

	local Character: Model
	local RootPart: BasePart
	local Humanoid: Humanoid

	local Mouse, Gamepad, Touch
	local Device: number = 1

	local InputEnums = {
		Mouse = 1,
		Touch = 2,
		Gamepad = 3,
	}

	--- Starting camera rotation values
	local X: number = 3.14
	local Y: number = 0
	local Sine: number = 0

	--- Previous values
	local Height: number = 0
	local Shoulder: number = 0
	local Zoom: number = 0
	local SineX: number = 0
	local SineY: number = 0
	local Tilt: number = 0
	local Rotation: Vector3

	local PopperRaycastParams: RaycastParams = RaycastParams.new()

	--- Spectating stuff
	local LastSpectateSend: number = 0
	local SpectatingPlayer: Player
	local PlayerCameraList = {}
	local RemoteEvent = ReplicatedStorage:WaitForChild("PlayerCameraMainNetwork"):WaitForChild("SendCameraCoordinates")

	--- Typical lerp function to smoothly tween between two numbers
	local function lerp(a, b, d)
		return a + (b - a) * d
	end

	--- Switch device if the input changes
	local function onLastInputChanged(inputDevice)
		if string.match(inputDevice.Name, "^Mouse") then
			Device = InputEnums.Mouse
		elseif string.match(inputDevice.Name, "^Gamepad") then
			Device = InputEnums.Gamepad
		elseif inputDevice == Enum.UserInputType.Touch then
			Device = InputEnums.Touch
		end
	end

	local function transparentAccessoriesInModel(character, forceModifier)
		if not character then
			return
		end

		local transparencyModifier: number = forceModifier or (script:GetAttribute("FirstPersonMode") and 1 or 0)

		for _, accessory in ipairs(character:GetChildren()) do
			if accessory:IsA("Accessory") then
				for _, part in ipairs(accessory:GetDescendants()) do
					if part:IsA("BasePart") then
						TweenService
							:Create(part, TweenInfo.new(0.5), { LocalTransparencyModifier = transparencyModifier })
							:Play()
					end
				end
			end
		end

		character.Head.LocalTransparencyModifier = transparencyModifier

		for _, face in ipairs(character.Head:GetChildren()) do
			if face:IsA("Decal") then
				face.Transparency = transparencyModifier
			end
		end
	end

	--- Hide accessories upon going first person mode
	local function onModeChanged()
		if SpectatingPlayer then
			transparentAccessoriesInModel(Character, 0)
			transparentAccessoriesInModel(SpectatingPlayer.Character)
		else
			transparentAccessoriesInModel(Character)
		end
	end

	--- Runs everytime a character ancestry changes
	local function updatePopperCamParams()
		local characters: { Instance } = {}
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character then
				table.insert(characters, player.Character)
			end
		end
		PopperRaycastParams.FilterDescendantsInstances = characters
		PopperRaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	end

	--- Update the popper cam params if characters changes
	local function onPlayerAdded(player)
		local function onCharacterAdded(character)
			updatePopperCamParams()

			if player == LocalPlayer then
				Character = character
				RootPart = character:WaitForChild("HumanoidRootPart")
				Humanoid = character:WaitForChild("Humanoid")
				Camera.CameraType = Enum.CameraType.Scriptable
			end
		end

		onCharacterAdded(player.Character or player.CharacterAdded:Wait())
		player.CharacterAdded:Connect(onCharacterAdded)
	end

	--- The camera angles of other players
	local function onInformationReceived(data)
		PlayerCameraList = data
	end

	--- Math stuff to calculate the camera bobs
	local function calculateSineBobbing(speed, intensity)
		Sine += speed

		if Sine > (math.pi * 2) then
			Sine = 0
		end

		local sineY = intensity * math.sin(2 * Sine)
		local sineX = intensity * math.sin(Sine)

		return CFrame.new(sineX, sineY, 0)
	end

	local function toggleFirstPerson()
		script:SetAttribute("FirstPersonMode", not script:GetAttribute("FirstPersonMode"))
	end

	local function toggleController(keyCode)
		if keyCode == Enum.KeyCode.ButtonR3 then
			toggleFirstPerson()
		end
	end

	local function onSpectatorChanged()
		local spectatorName = script:GetAttribute("SpectatingPlayerName")

		if Players:FindFirstChild(spectatorName) then
			script:SetAttribute("FirstPersonMode", false)
			SpectatingPlayer = Players[spectatorName]
		else
			script:SetAttribute("SpectatingPlayerName", "")
		end
	end

	--- Mouse function that activates whenever a user moves their mouse
	local function mouseMoved()
		local delta = Mouse:GetDelta()
		local baseMouseSens = script:GetAttribute("MouseSensitivity")
		local sensitivity = Vector2.new(baseMouseSens, baseMouseSens)
			* math.min(2, UserSettings().GameSettings.MouseSensitivity)
		local angleLimits = script:GetAttribute("MaxUpDownLookAngles")

		X = math.clamp(((X - delta.X * sensitivity.X) % (math.pi * 2)), -1, 10)
		Y = math.clamp(Y - delta.Y * sensitivity.Y, angleLimits.Min, angleLimits.Max)
	end

	--- Touch function only for touch compatible devices
	-- @param position of the screen that the user has touched
	-- @param delta how fast the user is swiping across the screen
	local function onScreenTouchMoved(position, delta)
		if position.X < (Camera.ViewportSize.X * 0.5) then
			return
		end --- Makes sure the player is tapping the right side of the screen to move the camera

		local baseTouchSens = script:GetAttribute("TouchSensitivity")
		local touchSens = Vector2.new(baseTouchSens, baseTouchSens)
		local angleLimits = script:GetAttribute("MaxUpDownLookAngles")

		X = math.clamp(((X - delta.X * touchSens.X) % (math.pi * 2)), -1, 10)
		Y = math.clamp(Y - delta.Y * touchSens.Y, angleLimits.Min, angleLimits.Max)
	end

	--- Main camera loop
	-- @param delta is the amount of time it took from the previous frame to the next
	local function mainCamera(delta)
		if not script:GetAttribute("CameraEnabled") or not RootPart then
			return
		end

		local TargetRoot = RootPart

		if SpectatingPlayer then
			if SpectatingPlayer.Character then
				if SpectatingPlayer.Character.PrimaryPart then
					TargetRoot = SpectatingPlayer.Character.PrimaryPart
				else
					return
				end
			end
		end

		if script:GetAttribute("MouseLock") then
			Mouse:LockCenter()
		else
			Mouse:Unlock()
		end

		--- Control the camera with gamepad if connected. Unike the Touch or Mouse, gamepads need constant polling
		if Device == InputEnums.Gamepad then
			local input = Gamepad:GetState(Enum.KeyCode.Thumbstick2)
			local position = input.Position
			local deadzone = Gamepad:ApplyDeadzone(position.Magnitude, script:GetAttribute("GamepadDeadzone"))

			if deadzone > 0 then
				local invert = UserSettings().GameSettings:GetCameraYInvertValue()
				local rotationSpeed = script:GetAttribute("GamepadSensitivity")
					* UserSettings().GameSettings.GamepadCameraSensitivity
				local angleLimits = script:GetAttribute("MaxUpDownLookAngles")

				X = math.clamp(((X - position.X * rotationSpeed * delta) % (math.pi * 2)), -1, 10)
				Y = math.clamp(Y + position.Y * rotationSpeed * delta * invert, angleLimits.Min, angleLimits.Max)
			end
		end

		local isFP = script:GetAttribute("FirstPersonMode")
		local shoulder = isFP and script:GetAttribute("OffsetFirstPersonShoulder")
			or script:GetAttribute("OffsetShoulder")
		local height = isFP and script:GetAttribute("OffsetFirstPersonHeight") or script:GetAttribute("OffsetHeight")
		local zoom = isFP and script:GetAttribute("OffsetFirstPersonZoom") or script:GetAttribute("OffsetZoom")
		local tilt = isFP and script:GetAttribute("OffsetFirstPersonTilt") or 0

		Shoulder = lerp(Shoulder, shoulder, math.min(delta * 5, 1))
		Height = lerp(Height, height, math.min(delta * 10, 1))
		Zoom = lerp(Zoom, zoom, math.min(delta * 10, 1))
		Tilt = lerp(Tilt, tilt, math.min(delta * 5, 1))

		local XRotation = SpectatingPlayer and PlayerCameraList[SpectatingPlayer.Name].X or X
		local YRotation = SpectatingPlayer and PlayerCameraList[SpectatingPlayer.Name].Y or Y

		--- Calculate center of rotation
		local center = TargetRoot.Position
			+ Vector3.new(
				0,
				isFP and script:GetAttribute("BaseFirstPersonHeight") or script:GetAttribute("BaseHeight"),
				0
			)
		local cframe = CFrame.new(center)
			* CFrame.Angles(0, XRotation, 0)
			* CFrame.Angles(YRotation, 0, 0)
			* CFrame.new(Shoulder, Height, Zoom)
		local rotation = cframe - cframe.Position
		local position = center + (cframe.Position - center)

		if not Rotation or not script:GetAttribute("FirstPersonMode") then
			Rotation = rotation
		else
			Rotation = Rotation:Lerp(rotation, script:GetAttribute("Smoothness"))
		end

		--- Poppercam
		if script:GetAttribute("PopperCamEnabled") then
			local raycastResult: RaycastResult =
				workspace:Raycast(center, cframe.Position - center, PopperRaycastParams)
			if raycastResult then
				position = raycastResult.Position
					+ raycastResult.Normal * script:GetAttribute("PopperCamMinimumSpacing")
			end
		end

		--- Bobbing head effect
		if script:GetAttribute("BobbingEnabled") then
			local movementVector =
				Camera.CFrame:VectorToWorldSpace(TargetRoot.AssemblyLinearVelocity / math.max(Humanoid.WalkSpeed, 0.01))
			local speedModifier = Humanoid.WalkSpeed / 16

			local sineCFrame = calculateSineBobbing(
				((0.1 * speedModifier) * script:GetAttribute("BobbingSpeed")) * delta,
				((movementVector.Z * speedModifier) * script:GetAttribute("BobbingIntensity")) * delta
			)
			SineX = lerp(SineX, sineCFrame.X, 0.1)
			SineY = lerp(SineY, sineCFrame.Y, 0.1)
		end

		--- Push Recoil update
		if Recoil then
			Recoil:Update(delta)
		end

		--- Finalize camera changes
		local camGoal = CFrame.new(position) * Rotation
		Camera.CFrame = camGoal
		Camera.CFrame *= CFrame.new(
			SineX * script:GetAttribute("BobbingSwayXScale"),
			SineY * script:GetAttribute("BobbingSwayYScale"),
			0
		) --- Adjust local sway
		Camera.CFrame *= CFrame.Angles(0, 0, math.rad(-Tilt)) --- Adjust Local Tilt
		Camera.FieldOfView = lerp(Camera.FieldOfView, script:GetAttribute("FieldOfView"), math.min(delta * 10, 1))

		--- Send camera angles to the server
		if not SpectatingPlayer then
			RemoteEvent:FireServer(X, Y)
		end
	end

	--- Initialization function, setup the connections and main variables upon startup
	function Init()
		Mouse = Input.Mouse.new()
		Gamepad = Input.Gamepad.new()
		Touch = Input.Touch.new()

		for _, player in ipairs(Players:GetPlayers()) do
			onPlayerAdded(player)
		end

		--- Hook up functions and events
		updatePopperCamParams()
		onModeChanged()

		--- Knit stuff
		Knit.OnStart()
			:andThen(function()
				BaseCamera = Knit.GetController("BaseCamera")
				Recoil = BaseCamera.Recoil
			end)
			:catch(warn)

		--- Event listeners
		Players.PlayerAdded:Connect(onPlayerAdded)
		Players.LocalPlayer:GetMouse().Move:Connect(mouseMoved)
		Touch.TouchMoved:Connect(onScreenTouchMoved)
		UserInputService.LastInputTypeChanged:Connect(onLastInputChanged)
		RunService:BindToRenderStep("PlayerCameraMain", 4, mainCamera)
		script:GetAttributeChangedSignal("FirstPersonMode"):Connect(onModeChanged)
		script:GetAttributeChangedSignal("SpectatingPlayerName"):Connect(onSpectatorChanged)
		RemoteEvent.OnClientEvent:Connect(onInformationReceived)
	end

	task.defer(Init)
end
