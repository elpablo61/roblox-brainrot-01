-- Economy: owns every player's coins, owned brainrots, rebirths and income.
-- State lives here alone; the HUD only reads the player attributes this
-- module refreshes. First function is the buy, the core of the loop.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Economy = {}
local states = {}

local function getGameState()
	return ReplicatedStorage:WaitForChild("GameState")
end

local function eventMultiplier()
	local gs = getGameState()
	local mult = 1
	if gs:GetAttribute("GoldenLeft") and gs:GetAttribute("GoldenLeft") > 0 then
		mult *= 2
	end
	if gs:GetAttribute("MythicLeft") and gs:GetAttribute("MythicLeft") > 0 then
		mult *= 2
	end
	return mult
end

function Economy.getEventMultiplier()
	return eventMultiplier()
end

function Economy.getState(player)
	return states[player]
end

function Economy.getIncome(player)
	local state = states[player]
	if not state then
		return 0
	end
	local base = 0
	for _, owned in ipairs(state.owned) do
		base += owned.rate
	end
	return math.floor(base * (1 + Config.REBIRTH_MULT * state.rebirths) * eventMultiplier())
end

function Economy.refreshAttributes(player)
	local state = states[player]
	if not state then
		return
	end
	local ownedNames = {}
	for _, owned in ipairs(state.owned) do
		ownedNames[owned.name] = true
	end
	local index = 0
	for _ in pairs(ownedNames) do
		index += 1
	end
	player:SetAttribute("Coins", math.floor(state.coins))
	player:SetAttribute("Income", Economy.getIncome(player))
	player:SetAttribute("Rebirths", state.rebirths)
	player:SetAttribute("OwnedCount", #state.owned)
	player:SetAttribute("Slots", Config.BASE_SLOTS + Config.SLOTS_PER_REBIRTH * state.rebirths)
	player:SetAttribute("Multiplier", 1 + Config.REBIRTH_MULT * state.rebirths)
	player:SetAttribute("IndexCount", index)
	player:SetAttribute("BaseIndex", state.baseIndex or 0)
end

function Economy.buyBrainrot(player, model)
	local state = states[player]
	if not state or not model or not model.Parent then
		return false
	end
	local ownerId = model:GetAttribute("OwnerId")
	if ownerId and ownerId ~= 0 and ownerId ~= player.UserId then
		local Steal = require(script.Parent:WaitForChild("Steal"))
		return Steal.attemptSteal(player, model)
	end
	if ownerId == player.UserId then
		return false
	end
	local price = model:GetAttribute("Price") or 0
	local rate = model:GetAttribute("Rate") or 0
	local charName = model:GetAttribute("CharName") or "Brainrot"
	if state.coins < price then
		return false
	end
	if #state.owned >= Config.BASE_SLOTS + Config.SLOTS_PER_REBIRTH * state.rebirths then
		return false
	end
	state.coins -= price
	local slot = #state.owned + 1
	table.insert(state.owned, { model = model, name = charName, rate = rate })
	model:SetAttribute("OwnerId", player.UserId)
	model:SetAttribute("OriginalPrice", price)
	local bases = workspace:WaitForChild("Bases")
	local base = bases:FindFirstChild("Base" .. state.baseIndex)
	if base then
		local spot = base:FindFirstChild("Slot" .. slot)
		local target = spot and spot.Position or (base:GetAttribute("Center") and Vector3.new(base:GetAttribute("Center").X, 2, base:GetAttribute("Center").Z) or Vector3.new(0, 2, 0))
		model:PivotTo(CFrame.new(target + Vector3.new(0, 1.3, 0)))
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
			end
		end
	end
	Economy.refreshAttributes(player)
	local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")
	remotes:WaitForChild("Banner"):FireClient(player, "BOUGHT " .. charName .. " for $" .. price .. "!", "green", 3)
	return true
end

function Economy.collectIncome(player)
	local state = states[player]
	if not state then
		return
	end
	local income = Economy.getIncome(player)
	if income > 0 then
		state.coins += income
	end
	Economy.refreshAttributes(player)
end

function Economy.removeOwned(player, model)
	local state = states[player]
	if not state then
		return
	end
	for i, owned in ipairs(state.owned) do
		if owned.model == model then
			table.remove(state.owned, i)
			break
		end
	end
	Economy.refreshAttributes(player)
end

function Economy.addOwned(player, model, charName, rate)
	local state = states[player]
	if not state then
		return false
	end
	if #state.owned >= Config.BASE_SLOTS + Config.SLOTS_PER_REBIRTH * state.rebirths then
		return false
	end
	table.insert(state.owned, { model = model, name = charName, rate = rate })
	Economy.refreshAttributes(player)
	return true
end

function Economy.deductCoins(player, amount)
	local state = states[player]
	if not state then
		return 0
	end
	local taken = math.min(state.coins, amount)
	state.coins -= taken
	Economy.refreshAttributes(player)
	return taken
end

function Economy.setupPlayer(player)
	states[player] = {
		coins = Config.START_COINS,
		owned = {},
		rebirths = 0,
		baseIndex = 0,
		joinedAt = os.clock(),
	}
	-- Assign the first free base plot.
	local bases = workspace:WaitForChild("Bases")
	for i = 1, 8 do
		local base = bases:FindFirstChild("Base" .. i)
		if base and (base:GetAttribute("OwnerId") or 0) == 0 then
			base:SetAttribute("OwnerId", player.UserId)
			states[player].baseIndex = i
			break
		end
	end
	Economy.refreshAttributes(player)
	player:SetAttribute("LockLeft", 0)
	player:SetAttribute("LockCooldown", 0)
	player:SetAttribute("SpawnProtect", Config.SPAWN_PROTECTION)
end

function Economy.removePlayer(player)
	local state = states[player]
	if state and state.baseIndex > 0 then
		local bases = workspace:FindFirstChild("Bases")
		if bases then
			local base = bases:FindFirstChild("Base" .. state.baseIndex)
			if base then
				base:SetAttribute("OwnerId", 0)
			end
		end
	end
	states[player] = nil
end

function Economy.start()
	Players.PlayerAdded:Connect(function(player)
		Economy.setupPlayer(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		Economy.removePlayer(player)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		Economy.setupPlayer(player)
	end
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				Economy.collectIncome(player)
				local protect = player:GetAttribute("SpawnProtect") or 0
				if protect > 0 then
					player:SetAttribute("SpawnProtect", protect - 1)
				end
			end
		end
	end)
end

return Economy
