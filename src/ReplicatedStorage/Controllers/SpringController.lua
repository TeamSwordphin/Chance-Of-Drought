local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local SpringController = Knit.CreateController({ Name = "SpringController" })

local ITERATIONS = 8

function SpringController.Create(self, mass, force, damping, speed)
	local spring = {
		Target = Vector3.new(),
		Position = Vector3.new(),
		Velocity = Vector3.new(),

		Mass = mass or 1,
		Force = force or 50,
		Damping = damping or 2,
		Speed = speed or 1,
	}

	function spring.Shove(self, force)
		local x, y, z = force.X, force.Y, force.Z
		if x ~= x or x == math.huge or x == -math.huge then
			x = 0
		end
		if y ~= y or y == math.huge or y == -math.huge then
			y = 0
		end
		if z ~= z or z == math.huge or z == -math.huge then
			z = 0
		end
		self.Velocity += Vector3.new(x, y, z)
	end

	function spring.Update(self, dt)
		local scaledDeltaTime = math.min(dt * self.Speed, 0.1) / ITERATIONS

		for i = 1, ITERATIONS do
			local force = self.Target - self.Position
			local acceleration = (force * self.Force) / self.Mass

			acceleration = acceleration - self.Velocity * self.Damping

			self.Velocity += acceleration * scaledDeltaTime
			self.Position += self.Velocity * scaledDeltaTime
		end

		return self.Position
	end

	return spring
end

function SpringController:KnitStart() end

function SpringController:KnitInit() end

return SpringController
