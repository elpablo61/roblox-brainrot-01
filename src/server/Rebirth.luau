-- Rebirth: spend $10,000 to reset your coins for a permanent +25% income
-- multiplier and +2 base slots. The ladder never ends.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Rebirth = {}

function Rebirth.applyRebirth(player)
	local Economy = require(script.Parent:WaitForChild("Economy"))
	local state = Economy.players[player]
	if not state then
		return false
	end
	if state.coins < Config.REBIRTH_COST then
		Economy.notify(player, "denied", "Rebirth costs $" .. Config.REBIRTH_COST .. " — you have $" .. state.coins)
		return false
	end
	for _, model in ipairs(state.owned) do
		if model.Parent then
			model:Destroy()
		end
	end
	state.owned = {}
	state.index = {}
	state.indexCount = 0
	state.coins = 0
	state.rebirths += 1
	state.slots += Config.REBIRTH_EXTRA_SLOTS
	Economy.refreshAttributes(player)
	local mult = 1 + Config.REBIRTH_BONUS * state.rebirths
	Economy.notify(player, "rebirth", "REBIRTH x" .. mult .. "! +" .. Config.REBIRTH_EXTRA_SLOTS .. " base slots!")
	Economy.notifyAll("effect-rebirth", player.Name)
	return true
end

return Rebirth
