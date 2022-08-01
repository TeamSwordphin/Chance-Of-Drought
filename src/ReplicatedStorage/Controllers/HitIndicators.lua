local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local Player = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")

local HitIndicators = Knit.CreateController({
	Name = "HitIndicators",
	Camera = workspace.Camera,
	Indicators = {},
})

local EMPTY_VECTOR = Vector3.new()
local HIT_INDICATOR_LIFE = 2

local MainGui

function IndicatorService:_NewIndicator(direction, damage)
	local indicator = {
		Start = os.clock(),
		Direction = direction,
		Damage = damage,
	}

	local frame = MainGui.Templates.HitFrame:Clone()
	frame.Indicator.Size = UDim2.new((damage / 100) * 0.2, 0, 0.4, 0)
	frame.Indicator.Position = UDim2.new(1.5, 0, 0.5, 0)
	frame.Visible = true
	frame.Parent = MainGui.HitIndicator
	frame.Indicator:TweenPosition(UDim2.new(1, 0, 0.5, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.1)

	indicator.Frame = frame

	table.insert(self.Indicators, indicator)
end

function HitIndicators:KnitStart()
	MainGui = Player.PlayerGui.MainGui

	--- Bind the indicators to render
	RunService:BindToRenderStep("HitIndicators", 10, function()
		local cameraLookVector = self.Camera.CFrame.LookVector
		local cframeDirection = CFrame.lookAt(EMPTY_VECTOR, Vector3.new(cameraLookVector.X, 0, cameraLookVector.Z))
		local osClock = os.clock()

		for i = #self.Indicators, 1, -1 do
			local indicator = self.Indicators[i]
			local lifetime = osClock - indicator.Start

			if lifetime >= HIT_INDICATOR_LIFE then
				table.remove(self.Indicators, i)
				continue
			end

			local relativeDirection = cframeDirection:VectorToObjectSpace(-indicator.Direction)
			local angle = math.deg(math.atan2(relativeDirection.Z, relativeDirection.X))

			indicator.Frame.Rotation = angle
			indicator.Frame.Indicator.ImageTransparency = lifetime / HIT_INDICATOR_LIFE
		end
	end)

	local function onSelfDamaged(direction, damage)
		self:_NewIndicator(direction, damage)
	end

	--- Connect events
end

function HitIndicators:KnitInit() end

return HitIndicators
