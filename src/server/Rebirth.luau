-- Rebirth resets coins for a permanent income multiplier and +2 base slots.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Rebirth = {}

function Rebirth.applyRebirth(player)
	local Economy = require(script.Parent:WaitForChild("Economy"))
	local state = Economy.getState(player)
	if not state then
		return false
	end
	if state.coins < Config.REBIRTH_COST then
		Economy.banner(player, "REBIRTH costs $" .. Config.REBIRTH_COST .. " - you have $" .. math.floor(state.coins), Color3.fromRGB(255, 80, 80))
		return false
	end
	state.coins = 0
	state.rebirths += 1
	state.mult = Config.REBIRTH_MULT ^ state.rebirths
	state.slots += Config.SLOTS_PER_REBIRTH
	Economy.refreshAttributes(player)
	Economy.banner(player, "REBIRTH x" .. state.mult .. "! +" .. Config.SLOTS_PER_REBIRTH .. " slots!", Color3.fromRGB(255, 215, 0))
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	remotes:WaitForChild("HudEvent"):FireClient(player, "Rebirth", state.rebirths)
	return true
end

return Rebirth
