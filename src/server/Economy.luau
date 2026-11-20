-- Brainrot Blitz economy: coins, buying, income ticking, bases, leaderstats.
-- One table per player holds coins, rebirths, owned brainrots and base id.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Economy = {}

Economy.BasePositions = {
	Vector3.new(70, 0, 95),
	Vector3.new(-70, 0, 95),
	Vector3.new(70, 0, -95),
	Vector3.new(-70, 0, -95),
	Vector3.new(100, 0, 0),
	Vector3.new(-100, 0, 0),
	Vector3.new(0, 0, 95),
	Vector3.new(0, 0, -95),
}

local Data = {}
local TakenBases = {}
local StealModule = nil

local function getNotify()
	return ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify")
end

local function getState()
	return ReplicatedStorage:WaitForChild("GameState")
end

function Economy.setSteal(module)
	StealModule = module
end

function Economy.buyBrainrot(player, model)
	if not model or not model.Parent then
		return false
	end
	if model:GetAttribute("State") ~= "Belt" then
		return false
	end
	local data = Data[player]
	if not data then
		return false
	end
	local price = model:GetAttribute("Price") or 0
	local rate = model:GetAttribute("Rate") or 0
	if data.Coins < price then
		getNotify():FireClient(player, "Deny", "Need $" .. price .. " — you have $" .. data.Coins)
		return false
	end
	if #data.Owned >= Economy.getMaxSlots(player) then
		getNotify():FireClient(player, "Deny", "Base full! REBIRTH for +2 slots")
		return false
	end
	data.Coins -= price
	data.OwnedNames[model:GetAttribute("CharName")] = true
	table.insert(data.Owned, model)
	model:SetAttribute("State", "Owned")
	model:SetAttribute("Owner", player.Name)
	local slot = #data.Owned
	model:PivotTo(CFrame.new(Economy.getSlotPosition(data.BaseId, slot)))
	local baseFolder = workspace:WaitForChild("Bases"):WaitForChild("Base" .. data.BaseId)
	model.Parent = baseFolder:WaitForChild("Brainrots")
	if StealModule then
		StealModule.wireOwned(model)
	end
	Economy.refreshPlayer(player)
	getNotify():FireClient(player, "Buy", model:GetAttribute("CharName"), rate, model:GetAttribute("Price"))
	getNotify():FireAllClients("BoughtBanner", player.Name, model:GetAttribute("CharName"))
	return true
end

function Economy.collectIncome(player)
	local data = Data[player]
	if not data then
		return 0
	end
	local rate = Economy.getRate(player)
	if rate > 0 then
		data.Coins += rate
		local basePos = Economy.BasePositions[data.BaseId]
		getNotify():FireClient(player, "Income", rate, basePos)
	end
	Economy.refreshPlayer(player)
	return rate
end

function Economy.getRate(player)
	local data = Data[player]
	if not data then
		return 0
	end
	local total = 0
	for _, model in ipairs(data.Owned) do
		if model.Parent then
			total += model:GetAttribute("Rate") or 0
		end
	end
	local multiplier = 1
	multiplier *= (Config.Rebirth.Multiplier ^ data.Rebirths)
	local state = getState()
	if state:GetAttribute("GoldenActive") then
		multiplier *= 2
	end
	if state:GetAttribute("MythicActive") then
		multiplier *= 2
	end
	return math.floor(total * multiplier + 0.5)
end

function Economy.getMaxSlots(player)
	local data = Data[player]
	if not data then
		return Config.BaseSlots
	end
	return Config.BaseSlots + data.Rebirths * Config.Rebirth.SlotsPerRebirth
end

function Economy.getSlotPosition(baseId, slotIndex)
	local center = Economy.BasePositions[baseId]
	local col = (slotIndex - 1) % 4
	local row = math.floor((slotIndex - 1) / 4)
	local x = center.X + (col - 1.5) * 5
	local z = center.Z + (row - 1) * 5
	return Vector3.new(x, 2, z)
end

function Economy.getCoins(player)
	local data = Data[player]
	if data then
		return data.Coins
	end
	return 0
end

function Economy.addCoins(player, amount)
	local data = Data[player]
	if data then
		data.Coins = math.max(0, data.Coins + amount)
		Economy.refreshPlayer(player)
	end
end

function Economy.setCoins(player, amount)
	local data = Data[player]
	if data then
		data.Coins = math.max(0, amount)
		Economy.refreshPlayer(player)
	end
end

function Economy.getRebirths(player)
	local data = Data[player]
	if data then
		return data.Rebirths
	end
	return 0
end

function Economy.addRebirth(player)
	local data = Data[player]
	if data then
		data.Rebirths += 1
		Economy.refreshPlayer(player)
	end
end

function Economy.getBaseId(player)
	local data = Data[player]
	if data then
		return data.BaseId
	end
	return 0
end

function Economy.getOwned(player)
	local data = Data[player]
	if data then
		return data.Owned
	end
	return {}
end

function Economy.getIndexCount(player)
	local data = Data[player]
	if not data then
		return 0
	end
	local count = 0
	for _ in pairs(data.OwnedNames) do
		count += 1
	end
	return count
end

function Economy.registerOwned(player, model)
	local data = Data[player]
	if not data then
		return false
	end
	if #data.Owned >= Economy.getMaxSlots(player) then
		return false
	end
	data.OwnedNames[model:GetAttribute("CharName")] = true
	table.insert(data.Owned, model)
	model:SetAttribute("State", "Owned")
	model:SetAttribute("Owner", player.Name)
	local slot = #data.Owned
	model:PivotTo(CFrame.new(Economy.getSlotPosition(data.BaseId, slot)))
	local baseFolder = workspace:WaitForChild("Bases"):WaitForChild("Base" .. data.BaseId)
	model.Parent = baseFolder:WaitForChild("Brainrots")
	if StealModule then
		StealModule.wireOwned(model)
	end
	Economy.refreshPlayer(player)
	return true
end

function Economy.removeOwned(player, model)
	local data = Data[player]
	if not data then
		return
	end
	for i, owned in ipairs(data.Owned) do
		if owned == model then
			table.remove(data.Owned, i)
			break
		end
	end
	Economy.refreshPlayer(player)
end

function Economy.refreshPlayer(player)
	local data = Data[player]
	if not data then
		return
	end
	local rate = Economy.getRate(player)
	player:SetAttribute("Coins", data.Coins)
	player:SetAttribute("Income", rate)
	player:SetAttribute("Rebirths", data.Rebirths)
	player:SetAttribute("SlotsUsed", #data.Owned)
	player:SetAttribute("SlotsMax", Economy.getMaxSlots(player))
	player:SetAttribute("IndexCount", Economy.getIndexCount(player))
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		if coins then
			coins.Value = data.Coins
		end
		local income = leaderstats:FindFirstChild("Income")
		if income then
			income.Value = rate
		end
	end
	local list = {}
	for _, model in ipairs(data.Owned) do
		if model.Parent then
			table.insert(list, { Name = model:GetAttribute("CharName"), Rate = model:GetAttribute("Rate") })
		end
	end
	getNotify():FireClient(player, "BaseList", list)
end

function Economy.assignBase(player)
	for i = 1, Config.MaxPlayers do
		if not TakenBases[i] then
			TakenBases[i] = player
			return i
		end
	end
	return 1
end

function Economy.freeBase(player)
	local data = Data[player]
	if data and TakenBases[data.BaseId] == player then
		TakenBases[data.BaseId] = nil
	end
end

function Economy.onPlayerAdded(player)
	local baseId = Economy.assignBase(player)
	Data[player] = {
		Coins = Config.StartingCash,
		Rebirths = 0,
		Owned = {},
		OwnedNames = {},
		BaseId = baseId,
	}
	player:SetAttribute("BaseId", baseId)
	player:SetAttribute("SpawnProtectedUntil", os.clock() + Config.Lock.SpawnProtection)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = Config.StartingCash
	coins.Parent = leaderstats
	local income = Instance.new("IntValue")
	income.Name = "Income"
	income.Value = 0
	income.Parent = leaderstats
	leaderstats.Parent = player
	Economy.refreshPlayer(player)
end

function Economy.onPlayerRemoving(player)
	Economy.freeBase(player)
	Data[player] = nil
end

function Economy.start()
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				Economy.collectIncome(player)
			end
		end
	end)
end

return Economy
