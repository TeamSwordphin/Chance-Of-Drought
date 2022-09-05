local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local ServerScriptService = game:GetService("ServerScriptService")

if game.PlaceId == 10299014171 then -- check if it's the lobby
	Knit.AddServices(ServerScriptService.Services.Lobby)
else -- it's the game
	Knit.AddServices(ServerScriptService.Services.Game)
end

Knit.AddServices(ServerScriptService.Services)

Knit.Start():catch(warn)
