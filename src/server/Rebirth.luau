-- Brainrot Blitz rebirth: at $10,000 coins reset to zero and the player
-- gains a permanent +25% income multiplier and +2 base slots, forever.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Rebirth = {}

local EconomyModule = nil

local function getNotify()
	return ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify")
end

function Rebirth.setEconomy(module)
	EconomyModule = module
end

function Rebirth.applyRebirth(player)
	if not EconomyModule then
		return false
	end
	local coins = EconomyModule.getCoins(player)
	if coins < Config.Rebirth.Cost then
		getNotify():FireClient(player, "Deny", "REBIRTH needs $" .. Config.Rebirth.Cost .. " — you have $" .. coins)
		return false
	end
	EconomyModule.setCoins(player, 0)
	EconomyModule.addRebirth(player)
	local rebirths = EconomyModule.getRebirths(player)
	local slots = EconomyModule.getMaxSlots(player)
	getNotify():FireClient(player, "Rebirth", rebirths, slots)
	getNotify():FireAllClients("RebirthBanner", player.Name, rebirths)
	return true
end

function Rebirth.canRebirth(player)
	if not EconomyModule then
		return false
	end
	return EconomyModule.getCoins(player) >= Config.Rebirth.Cost
end

return Rebirth
