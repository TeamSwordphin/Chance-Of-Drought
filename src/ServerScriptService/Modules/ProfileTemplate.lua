local ProfileTemplate = {
	Coins = 0,
	ItemsPool = {},
	CharacterPool = {
		["Hammer"] = true,
		["Axe"] = false,
		["Staff"] = false,
		["Sword"] = false,
	},
	XP = 0,
	Achievements = {},
	Ban = {
		Banned = false,
		Reason = "",
		Score = 0,
	},
}

return ProfileTemplate
