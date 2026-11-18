-- Economy owns all player state: coins, owned brainrots, rebirth count, lock timers.
-- State lives here only; clients read it through player attributes and HudEvent.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Economy = {}
local states = {}
local baseCount = 0

Economy.BASE_CENTERS = {
	Vector3.new(52, 0, 0),
	Vector3.new(37, 0, 37),
	Vector3.new(0, 0, 52),
	Vector3.new(-37, 0, 37),
	Vector3.new(-52, 0, 0),
	Vector3.new(-37, 0, -37),
	Vector3.new(0, 0, -52),
	Vector3.new(37, 0, -37),
}

local SLOT_OFFSETS = {
	Vector3.new(-6, 0, -2), Vector3.new(-2, 0, -2), Vector3.new(2, 0, -2), Vector3.new(6, 0, -2),
	Vector3.new(-6, 0, 2), Vector3.new(-2, 0, 2), Vector3.new(2, 0, 2), Vector3.new(6, 0, 2),
}

function Economy.buyBrainrot(player, model)
	local state = states[player]
	if not state or not model or not model.Parent then
		return false
	end
	local ownerId = model:GetAttribute("OwnerId") or 0
	if ownerId ~= 0 then
		local Steal = require(script.Parent:WaitForChild("Steal"))
		return Steal.attemptSteal(player, model)
	end
	if model:GetAttribute("Carried") then
		return false
	end
	-- Price is always the original buy price; a dropped model never stays at $0.
	local price = model:GetAttribute("OriginalPrice") or model:GetAttribute("Price") or 0
	if price <= 0 then
		price = model:GetAttribute("OriginalPrice") or 0
	end
	if price <= 0 then
		return false
	end
	if state.coins < price then
		Economy.banner(player, "NOT ENOUGH COINS! Need $" .. price, Color3.fromRGB(255, 80, 80))
		return false
	end
	if #state.owned >= state.slots then
		Economy.banner(player, "BASE FULL! Rebirth for +2 slots.", Color3.fromRGB(255, 80, 80))
		return false
	end
	state.coins -= price
	model:SetAttribute("OwnerId", player.UserId)
	model:SetAttribute("Price", price)
	table.insert(state.owned, model)
	Economy.placeAtBase(player, model)
	Economy.refreshAttributes(player)
	Economy.updateNextTierBoard(player)
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	remotes:WaitForChild("HudEvent"):FireClient(player, "Buy", model:GetAttribute("CharName") or "Brainrot", model:GetPivot().Position)
	Economy.banner(player, "BOUGHT " .. (model:GetAttribute("CharName") or "Brainrot") .. "!", Color3.fromRGB(80, 255, 120))
	return true
end

function Economy.collectIncome()
	while true do
		task.wait(1)
		for player, state in pairs(states) do
			if player.Parent then
				local income = Economy.getIncome(player)
				if income > 0 then
					state.coins += math.floor(income)
					local remotes = ReplicatedStorage:WaitForChild("Remotes")
					remotes:WaitForChild("HudEvent"):FireClient(player, "Float", "+$" .. math.floor(income))
				end
				if state.lockLeft > 0 then
					state.lockLeft -= 1
				end
				if state.cooldownLeft > 0 then
					state.cooldownLeft -= 1
				end
				Economy.refreshAttributes(player)
			end
		end
	end
end

function Economy.getIncome(player)
	local state = states[player]
	if not state then
		return 0
	end
	local base = 0
	for _, model in ipairs(state.owned) do
		if model.Parent then
			base += model:GetAttribute("Income") or 0
		end
	end
	return base * state.mult * Economy.getEventMultiplier()
end

function Economy.getEventMultiplier()
	local gs = ReplicatedStorage:FindFirstChild("GameState")
	if not gs then
		return 1
	end
	local mult = 1
	if (gs:GetAttribute("GoldenLeft") or 0) > 0 then
		mult *= 2
	end
	if (gs:GetAttribute("MythicLeft") or 0) > 0 then
		mult *= 2
	end
	return mult
end

function Economy.addPlayer(player)
	baseCount += 1
	local baseIndex = ((baseCount - 1) % 8) + 1
	states[player] = {
		coins = Config.START_COINS,
		owned = {},
		rebirths = 0,
		mult = 1,
		slots = Config.BASE_SLOTS,
		lockLeft = Config.SPAWN_PROTECT,
		cooldownLeft = 0,
		baseIndex = baseIndex,
	}
	player:SetAttribute("Coins", Config.START_COINS)
	player:SetAttribute("Income", 0)
	player:SetAttribute("Rebirths", 0)
	player:SetAttribute("Owned", 0)
	player:SetAttribute("Slots", Config.BASE_SLOTS)
	player:SetAttribute("LockLeft", Config.SPAWN_PROTECT)
	player:SetAttribute("Multiplier", 1)
	player:SetAttribute("IndexCount", 0)
	player:SetAttribute("BaseIndex", baseIndex)
	Economy.updateNextTierBoard(player)
end

function Economy.removePlayer(player)
	local state = states[player]
	if state then
		for _, model in ipairs(state.owned) do
			if model.Parent then
				model:SetAttribute("OwnerId", 0)
				model:SetAttribute("Price", model:GetAttribute("OriginalPrice") or 0)
			end
		end
	end
	states[player] = nil
end

function Economy.getState(player)
	return states[player]
end

function Economy.getBaseCenter(index)
	return Economy.BASE_CENTERS[math.clamp(index or 1, 1, 8)]
end

function Economy.getSlotPosition(player, slotIndex)
	local state = states[player]
	local center = Economy.getBaseCenter(state and state.baseIndex or 1)
	local off = SLOT_OFFSETS[((slotIndex - 1) % 8) + 1]
	return center + off + Vector3.new(0, 2, 0)
end

function Economy.placeAtBase(player, model)
	local state = states[player]
	if not state then
		return
	end
	local slot = #state.owned
	local pos = Economy.getSlotPosition(player, slot)
	model:PivotTo(CFrame.new(pos))
end

function Economy.refreshAttributes(player)
	local state = states[player]
	if not state then
		return
	end
	local owned = 0
	local distinct = {}
	for _, model in ipairs(state.owned) do
		if model.Parent then
			owned += 1
			distinct[model:GetAttribute("CharName") or ""] = true
		end
	end
	local count = 0
	for _ in pairs(distinct) do
		count += 1
	end
	player:SetAttribute("Coins", math.floor(state.coins))
	player:SetAttribute("Income", math.floor(Economy.getIncome(player)))
	player:SetAttribute("Rebirths", state.rebirths)
	player:SetAttribute("Owned", owned)
	player:SetAttribute("Slots", state.slots)
	player:SetAttribute("LockLeft", state.lockLeft)
	player:SetAttribute("Multiplier", state.mult)
	player:SetAttribute("IndexCount", count)
end

function Economy.banner(player, text, color)
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	remotes:WaitForChild("HudEvent"):FireClient(player, "Banner", text, color)
end

function Economy.bannerAll(text, color)
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	remotes:WaitForChild("HudEvent"):FireAllClients("Banner", text, color)
end

function Economy.updateNextTierBoard(player)
	local board = workspace:FindFirstChild("NextTierBoard")
	if not board then
		return
	end
	local label = board:FindFirstChild("Label", true)
	if not label then
		return
	end
	local state = states[player]
	local owned = state and #state.owned or 0
	local next = Config.nextTier(owned)
	local rarityColor = Config.RARITIES[next.rarity].color
	label.Text = "NEXT: " .. string.upper(next.rarity) .. " - " .. next.name .. " - $" .. next.income .. "/s - BUY $" .. next.price
	label.TextColor3 = rarityColor
end

return Economy
