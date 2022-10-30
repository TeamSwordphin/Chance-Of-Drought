local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local DataService = Knit.CreateService({
	Name = "DataService",
	Client = {
		DataChanged = Knit.CreateSignal(),
	},
	Profiles = {},
})

----- Loaded Modules -----

local ProfileService = require(game.ServerScriptService.Modules.ProfileService)
local ProfileTemplate = require(game:GetService("ServerScriptService").Modules.ProfileTemplate)

----- Private Variables -----

local Players = game:GetService("Players")

local ProfileStore = ProfileService.GetProfileStore("PlayerData", ProfileTemplate)

local function deepCopy(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			v = deepCopy(v)
		end
		copy[k] = v
	end
	return copy
end
----- Public Functions -----
function DataService.Client:Get(Player)
	local data = self.Server:Get(Player)
	if data then
		local clientData = deepCopy(data) -- create copy of the server data
		-- Remove data we don't want the client seeing
		-- clientData.BanScore = nil
		return clientData
	end
end

function DataService:Get(Player)
	local profile = self.Profiles[Player]

	if profile then
		return profile.Data
	end
end

----- Private Functions -----

local function PlayerAdded(player)
	local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
	if profile ~= nil then
		profile:AddUserId(player.UserId) -- GDPR compliance
		profile:Reconcile() -- Fill in missing variables from ProfileTemplate (optional)
		profile:ListenToRelease(function()
			DataService.Profiles[player] = nil
			-- The profile could've been loaded on another Roblox server:
			player:Kick()
		end)
		if player:IsDescendantOf(Players) == true then
			DataService.Profiles[player] = profile
			-- A profile has been successfully loaded:
		else
			-- Player left before the profile loaded:
			DataService.profile:Release()
		end
		player:SetAttribute("Coins", DataService.Profiles[player].Data.Coins)
		player:GetAttributeChangedSignal("Coins"):Connect(function()
			DataService.Profiles[player].Data.Coins = player:GetAttribute("Coins")
			print(DataService.Profiles[player].Data.Coins)
		end)
		player:SetAttribute("XP", DataService.Profiles[player].Data.XP)
		player:GetAttributeChangedSignal("XP"):Connect(function()
			DataService.Profiles[player].Data.XP = player:GetAttribute("XP")
			print(DataService.Profiles[player].Data.XP)
		end)
		print(DataService.Profiles)
	else
		-- The profile couldn't be loaded possibly due to other
		--   Roblox servers trying to load this profile at the same time:
		player:Kick()
	end
end

----- Initialize -----

-- In case Players have joined the server earlier than this script ran:
for _, player in ipairs(Players:GetPlayers()) do
	coroutine.wrap(PlayerAdded)(player)
end

function DataService:KnitStart() end

function DataService:KnitInit()
	Players.PlayerAdded:Connect(PlayerAdded)
	Players.PlayerRemoving:Connect(function(player)
		local profile = self.Profiles[player]
		if profile ~= nil then
			profile:Release()
		end
	end)
end

return DataService
