-- Economy: coins, income ticking, buying, leaderstats. The single place player state lives.
-- Other server modules read state through Economy.getState; they never keep their own copy.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Economy = {}
local states = {}
local remotes = nil

function Economy.buyBrainrot(player, model)
	local state = states[player]
	if not state then
		return false
	end
	if not model or not model.Parent then
		return false
	end
	local ownerId = model:GetAttribute("OwnerId") or 0
	if ownerId ~= 0 then
		local Steal = require(script.Parent.Steal)
		return Steal.attemptSteal(player, model)
	end
	local price = model:GetAttribute("Price") or 0
	if state.coins < price then
		Economy.banner(player, "NOT ENOUGH COINS! Need $" .. tostring(price), "Red")
		return false
	end
	if #state.owned >= state.slotsMax then
		Economy.banner(player, "BASE FULL! Rebirth for +2 slots", "Red")
		return false
	end
	state.coins -= price
	local slot = Economy.nextSlot(state)
	if not slot then
		state.coins += price
		return false
	end
	model:SetAttribute("OwnerId", player.UserId)
	model:SetAttribute("SlotIndex", slot)
	table.insert(state.owned, model)
	state.ownedNames[model:GetAttribute("CharName")] = true
	model.Parent = state.baseFolder
	Economy.moveModelToSlot(model, state, slot)
	Economy.refreshAttributes(player)
	Economy.banner(player, "BOUGHT " .. (model:GetAttribute("CharName") or "brainrot") .. "!", "Green")
	if remotes then
		remotes.BuyFx:FireAllClients(model:GetPivot().Position)
	end
	return true
end

function Economy.collectIncome()
	local Conveyor = require(script.Parent.Conveyor)
	local Wave = require(script.Parent.Wave)
	local golden = Wave.isGoldenHourActive()
	local mythic = Conveyor.isMythicWindowActive()
	for _, player in ipairs(Players:GetPlayers()) do
		local state = states[player]
		if state then
			local total = 0
			for _, model in ipairs(state.owned) do
				if model.Parent then
					total += model:GetAttribute("Rate") or 0
				end
			end
			local earned = math.floor(total * state.multiplier * (golden and 2 or 1) * (mythic and 2 or 1))
			if earned > 0 then
				state.coins += earned
				state.income = total
				if remotes then
					remotes.FloatText:FireClient(player, earned, state.baseCenter + Vector3.new(0, 6, 0))
				end
			else
				state.income = total
			end
			Economy.refreshAttributes(player)
		end
	end
end

function Economy.getState(player)
	return states[player]
end

function Economy.getIncome(player)
	local state = states[player]
	if not state then
		return 0
	end
	local total = 0
	for _, model in ipairs(state.owned) do
		if model.Parent then
			total += model:GetAttribute("Rate") or 0
		end
	end
	return math.floor(total * state.multiplier)
end

function Economy.addCoins(player, amount)
	local state = states[player]
	if state then
		state.coins += amount
		Economy.refreshAttributes(player)
	end
end

function Economy.nextSlot(state)
	for i = 1, state.slotsMax do
		local used = false
		for _, model in ipairs(state.owned) do
			if (model:GetAttribute("SlotIndex") or 0) == i then
				used = true
				break
			end
		end
		if not used then
			return i
		end
	end
	return nil
end

function Economy.slotPosition(state, slot)
	local row = (slot - 1) % 4
	local col = math.floor((slot - 1) / 4)
	local cx = state.baseCenter.X + (row - 1.5) * 5
	local cz = state.baseCenter.Z + (col - 1) * 5
	return Vector3.new(cx, 2.4, cz)
end

function Economy.moveModelToSlot(model, state, slot)
	local target = Economy.slotPosition(state, slot)
	local start = model:GetPivot()
	task.spawn(function()
		local steps = 20
		for i = 1, steps do
			local t = i / steps
			local pos = start.Position:Lerp(target, t)
			pos = Vector3.new(pos.X, pos.Y + math.sin(t * math.pi) * 6, pos.Z)
			if model.Parent then
				model:PivotTo(CFrame.new(pos))
			else
				return
			end
			task.wait(0.03)
		end
		if model.Parent then
			model:PivotTo(CFrame.new(target))
		end
	end)
end

function Economy.refreshAttributes(player)
	local state = states[player]
	if not state then
		return
	end
	player:SetAttribute("Coins", state.coins)
	player:SetAttribute("Income", Economy.getIncome(player))
	player:SetAttribute("SlotsUsed", #state.owned)
	player:SetAttribute("SlotsMax", state.slotsMax)
	player:SetAttribute("Rebirths", state.rebirths)
	player:SetAttribute("Multiplier", state.multiplier)
	local ownedCount = 0
	for _ in pairs(state.ownedNames) do
		ownedCount += 1
	end
	player:SetAttribute("IndexOwned", ownedCount)
	player:SetAttribute("IndexTotal", #Config.characters)
	local leader = player:FindFirstChild("leaderstats")
	if leader then
		local cash = leader:FindFirstChild("Cash")
		if cash then
			cash.Value = state.coins
		end
		local income = leader:FindFirstChild("Income")
		if income then
			income.Value = Economy.getIncome(player)
		end
	end
end

function Economy.banner(player, text, colorName)
	if remotes then
		remotes.Banner:FireClient(player, text, colorName or "White")
	end
end

function Economy.createState(player, baseFolder, baseCenter, baseColor)
	local leader = Instance.new("Folder")
	leader.Name = "leaderstats"
	leader.Parent = player
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = Config.startingCash
	cash.Parent = leader
	local income = Instance.new("IntValue")
	income.Name = "Income"
	income.Value = 0
	income.Parent = leader
	states[player] = {
		coins = Config.startingCash,
		multiplier = 1,
		rebirths = 0,
		owned = {},
		ownedNames = {},
		slotsMax = Config.baseSlots,
		lockUntil = 0,
		lockCooldownUntil = 0,
		spawnProtectedUntil = os.time() + Config.spawnProtection,
		baseFolder = baseFolder,
		baseCenter = baseCenter,
		baseColor = baseColor,
		income = 0,
		carrying = nil,
		slapCooldownUntil = 0,
	}	Economy.refreshAttributes(player)
	return states[player]
end

function Economy.removeState(player)
	states[player] = nil
end

function Economy.setRemotes(r)
	remotes = r
end

return Economy
