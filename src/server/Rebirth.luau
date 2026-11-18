-- Rebirth: spend $10,000 to reset coins and gain a permanent +25% income
-- multiplier plus 2 extra base slots. Owned brainrots are kept.

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
		return false
	end
	state.coins = Config.START_COINS
	state.rebirths += 1
	Economy.refreshAttributes(player)
	local mult = 1 + Config.REBIRTH_MULT * state.rebirths
	local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")
	remotes:WaitForChild("Banner"):FireClient(player, "REBIRTH! x" .. mult .. " income forever! Slots +" .. Config.SLOTS_PER_REBIRTH .. "!", "gold", 5)
	return true
end

function Rebirth.start()
	local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")
	remotes:WaitForChild("RebirthRequest").OnServerEvent:Connect(function(player)
		Rebirth.applyRebirth(player)
	end)
end

return Rebirth
