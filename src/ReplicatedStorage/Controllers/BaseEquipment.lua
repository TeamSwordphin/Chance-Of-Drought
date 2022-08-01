local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Input = require(game:GetService("ReplicatedStorage").Packages.Input)

local Player = game:GetService("Players").LocalPlayer

local BaseEquipment = Knit.CreateController({
	Name = "BaseEquipment",
	CurrentEquipped = nil,
	Weapons = {},
})

function BaseEquipment:KnitStart()
	local character, humanoid, rootPart
	local mouse = Input.Mouse.new()

	local function onCharacterAdded(newCharacter)
		character = newCharacter
		humanoid = newCharacter:WaitForChild("Humanoid")
		rootPart = newCharacter:WaitForChild("HumanoidRootPart")

		character:SetAttribute("LastActivationTime", 0)

		local weaponDirectory = character:WaitForChild("Weapons")

		local function onEquippedChanged()
			local equipped = character:GetAttribute("Equipped")
			local weapon = weaponDirectory:FindFirstChild(equipped)

			if not weapon then
				return
			end

			--- Unequip the old weapon if active
			if self.CurrentEquipped then
				self.CurrentEquipped:Unequip()
			end

			--- Create weapon class if it hasn't been loaded
			if not self.Weapons[equipped] then
				local config = require(weapon:WaitForChild("Config"))
				local load = self:WrapModule(self.Shared.ItemClasses[config.Type])
				local class = load:Create(weapon)

				self.Weapons[equipped] = class
			end

			self.CurrentEquipped = self.Weapons[equipped]
			self.CurrentEquipped:Equip()
		end

		local function onAnchored()
			if rootPart.Anchored then
				if self.CurrentEquipped then
					self.CurrentEquipped:Unequip()
				end
			else
				if self.CurrentEquipped then
					self.CurrentEquipped:Equip()
				end
			end
		end

		onEquippedChanged()
		weaponDirectory.ChildAdded:Connect(onEquippedChanged)
		rootPart:GetPropertyChangedSignal("Anchored"):Connect(onAnchored)
	end

	local function onKeyDown(keyCode)
		self.CurrentEquipped:Activate()
	end

	local function onKeyUp(keyCode)
		self.CurrentEquipped:Deactivate()
	end

	--- Init
	onCharacterAdded(Player.Character or Player.CharacterAdded:Wait())

	--- Connect events
	Player.CharacterAdded:Connect(onCharacterAdded)
	mouse.LeftDown:Connect(onKeyDown)
	mouse.LeftUp:Connect(onKeyUp)
end

function BaseEquipment:KnitInit() end

return BaseEquipment
