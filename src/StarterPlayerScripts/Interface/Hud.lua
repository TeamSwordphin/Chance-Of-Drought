local UIService = {}

function UIService:Start()
	self.GameUI = self.Player.PlayerGui.GameUI

	local bars = self.GameUI.Bottom.Bars
	local controls = self.GameUI.Bottom.Controls
	local gameInfo = self.GameUI.Top.GameUI
	local character, humanoid, rootPart

	local function onShieldChanged()
		local bar = bars.BarShield
		local shield = character:GetAttribute("Shield")
		local shieldMax = character:GetAttribute("ShieldMax")

		bar.Visible = shieldMax > 0
		bar.Value.Text = string.format("%s / %s", shield, shieldMax)
		bar.BarBehind.Bar.Size = UDim2.new(shield / shieldMax, 0, 1, 0)
	end

	local function onHealthChanged()
		local bar = bars.BarHealth
		local health = humanoid.Health
		local healthMax = humanoid.MaxHealth

		bar.Value.Text = string.format("%s / %s", health, healthMax)
		bar.BarBehind.Bar.Size = UDim2.new(health / healthMax, 0, 1, 0)
	end

	local function onTimerChanged()
		local seconds = workspace:GetAttribute("GameTime")
		local stage = workspace:GetAttribute("GameStage")

		local hours = math.floor(seconds / 3600)
		local mins = math.floor(seconds / 60 - (hours * 60))
		local secs = math.floor(seconds - hours * 3600 - mins * 60)

		if mins <= 0 then
			gameInfo.Timer.Value.Text = string.format("%s s", secs)
		else
			gameInfo.Timer.Value.Text = string.format("%s m %s s", mins, secs)
		end

		gameInfo.Stage.Value.Text = string.format("Stage %s", stage)
	end

	local function onGoldChanged()
		local gold = character:GetAttribute("Gold")
		local currency = bars.Currency

		currency.Value.Text = string.format("%s Gold", gold)
	end

	local function onCharacterAdded(newCharacter)
		character = newCharacter
		humanoid = newCharacter:WaitForChild("Humanoid")
		rootPart = newCharacter:WaitForChild("HumanoidRootPart")

		onShieldChanged()
		onHealthChanged()
		onTimerChanged()
		onGoldChanged()
	end

	--- Init
	onCharacterAdded(self.Player.Character or self.Player.CharacterAdded:Wait())

	--- Connect events
	self.Player.CharacterAdded:Connect(onCharacterAdded)
	workspace:GetAttributeChangedSignal("GameTime"):Connect(onTimerChanged)
	character:GetAttributeChangedSignal("Shield"):Connect(onShieldChanged)
	character:GetAttributeChangedSignal("ShieldMax"):Connect(onShieldChanged)
	character:GetAttributeChangedSignal("Gold"):Connect(onGoldChanged)
	humanoid:GetPropertyChangedSignal("Health"):Connect(onHealthChanged)
end

function UIService:Init() end

return UIService
