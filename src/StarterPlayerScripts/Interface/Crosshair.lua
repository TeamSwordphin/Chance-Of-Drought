local CrosshairService = {}

local MainGui

function CrosshairService:Start()
	MainGui = self.Player.PlayerGui.MainGui

	local crosshair = MainGui.Mouse.Gun
	local bottom = crosshair.Bottom
	local top = crosshair.Top
	local left = crosshair.Left
	local right = crosshair.Right

	local baseEquipment = self.Controllers.Character.BaseEquipment
	local lerp = self.Shared.Lerp
	local recoil = self.Controllers.Character.BaseCamera.Recoil

	-- Crosshair Logic

	self.Shared.CommonServices.RunService:BindToRenderStep("Crosshair", 11, function(delta)
		local offset = 0

		if baseEquipment.CurrentEquipped then
			offset += baseEquipment.CurrentEquipped.Config.Spread
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

function CrosshairService:Init()
	self.Camera = workspace.Camera
end

return CrosshairService
