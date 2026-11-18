-- Rebirth resets coins for a permanent +25% income multiplier and +2 base
-- slots. Owned brainrots stay; the player keeps earning while climbing.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Rebirth = {}

function Rebirth.applyRebirth(player)
	local Economy = require(script.Parent.Economy)
	local state = Economy.Players[player]
	if not state then return false end
	if state.coins < Config.REBIRTH_COST then return false end
	state.coins = Config.STARTING_COINS
	state.rebirths += 1
	state.slotsMax += Config.REBIRTH_EXTRA_SLOTS
	player:SetAttribute("BannerText", "REBIRTH x" .. tostring(state.rebirths) .. "! Income x" .. string.format("%.2f", Config.REBIRTH_MULTIPLIER ^ state.rebirths) .. " - SLOTS " .. tostring(state.slotsMax))
	player:SetAttribute("BannerUntil", os.time() + 5)
	Economy.refreshAttributes(player, state)
	return true
end

return Rebirth
