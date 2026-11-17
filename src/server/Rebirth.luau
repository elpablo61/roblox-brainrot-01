-- Rebirth: at $10,000 coins, reset coins to zero for a permanent +25% income multiplier
-- and +2 base slots. The next tier of the ladder only opens after rebirth.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Rebirth = {}

function Rebirth.applyRebirth(player)
	local Economy = require(script.Parent.Economy)
	local state = Economy.getState(player)
	if not state then
		return false
	end
	if state.coins < Config.rebirthCost then
		Economy.banner(player, "REBIRTH needs $" .. tostring(Config.rebirthCost) .. " (you have $" .. tostring(state.coins) .. ")", "Red")
		return false
	end
	state.coins = 0
	state.rebirths += 1
	state.multiplier = state.multiplier * Config.rebirthMultiplier
	state.slotsMax += Config.slotsPerRebirth
	Economy.refreshAttributes(player)
	Economy.banner(player, "REBIRTH x" .. string.format("%.2f", state.multiplier) .. " — +" .. tostring(Config.slotsPerRebirth) .. " base slots!", "Gold")
	return true
end

return Rebirth
