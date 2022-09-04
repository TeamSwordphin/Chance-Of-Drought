local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local RunService = game:GetService("RunService")
local Player = game:GetService("Players").LocalPlayer

local Crosshair = Knit.CreateController({
	Name = "Crosshair",
	Camera = workspace.Camera,
})

local MainGui

function Crosshair:KnitStart()
	MainGui = Player.PlayerGui.Crosshair

	local crosshair = MainGui.Mouse.Gun
	local bottom = crosshair.Bottom
	local top = crosshair.Top
	local left = crosshair.Left
	local right = crosshair.Right

	local BaseEquipment = Knit.GetController("BaseEquipment")
	local lerp = self.Shared.Lerp
	local recoil = Knit.GetController("BaseCamera").Recoil

	--- Crosshair Logic

	RunService:BindToRenderStep("Crosshair", 11, function(delta)
		local offset = 0

		if BaseEquipment.CurrentEquipped then
			offset += BaseEquipment.CurrentEquipped.Config.Spread
		end

		local recoilOffset = Vector3.new(recoil.Position.X * 0.5, recoil.Position.Y, recoil.Position.Z)
			* (self.Camera.FieldOfView / 70)
		offset += (recoilOffset.Magnitude * 70)

		bottom.Position = UDim2.new(0.5, 0, 1, lerp(bottom.Position.Y.Offset, 0 + offset, math.min(delta * 10, 1)))
		crosshair.BottomShadow.Position = bottom.Position

		top.Position = UDim2.new(0.5, 0, 0, lerp(top.Position.Y.Offset, 0 - offset, math.min(delta * 10, 1)))
		crosshair.TopShadow.Position = top.Position

		left.Position = UDim2.new(0, lerp(left.Position.X.Offset, 0 - offset, math.min(delta * 10, 1)), 0.5, 0)
		crosshair.LeftShadow.Position = left.Position

		right.Position = UDim2.new(1, lerp(right.Position.X.Offset, 0 + offset, math.min(delta * 10, 1)), 0.5, 0)
		crosshair.RightShadow.Position = right.Position
	end)

	--- Connect events
end

function Crosshair:KnitInit() end

return Crosshair
