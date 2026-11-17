-- Economy: owns every player's coins, owned brainrots, income ticking,
-- buying, leaderstats and the Golden Hour / Mythic double-income windows.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Economy = {}
Economy.players = {}
Economy.goldenActive = false
Economy.mythicActive = false
Economy.takenBases = {}

function Economy.buyBrainrot(player, model)
	local state = Economy.players[player]
	if not state then
		return false
	end
	local Conveyor = require(script.Parent:WaitForChild("Conveyor"))
	if not Conveyor.isOnBelt(model) then
		return false
	end
	local price = model:GetAttribute("Price") or 0
	if state.coins < price then
		Economy.notify(player, "denied", "Need $" .. price .. " — you have $" .. state.coins)
		return false
	end
	if #state.owned >= state.slots then
		Economy.notify(player, "denied", "Base full! Rebirth for +2 slots.")
		return false
	end
	state.coins -= price
	Conveyor.removeFromBelt(model)
	Economy.placeInBase(player, model)
	model:SetAttribute("OwnerId", player.UserId)
	local label = model:FindFirstChild("BrainrotLabel")
	if label then
		local priceText = label:FindFirstChild("Price")
		if priceText then
			priceText.Text = "OWNED  •  $" .. (model:GetAttribute("Rate") or 0) .. "/s"
			priceText.TextColor3 = Color3.fromRGB(120, 255, 120)
		end
	end
	local charName = model:GetAttribute("CharName") or "Brainrot"
	if not state.index[charName] then
		state.index[charName] = true
		state.indexCount += 1
	end
	table.insert(state.owned, model)
	Economy.refreshAttributes(player)
	Economy.updateNextTierBoard(charName)
	Economy.notify(player, "bought", "Bought " .. charName .. "!")
	Economy.notifyAll("effect-buy", player.Name)
	return true
end

function Economy.collectIncome()
	while true do
		task.wait(1)
		for player, state in pairs(Economy.players) do
			if player.Parent then
				local income = Economy.getIncome(player)
				if income > 0 then
					state.coins += income
					Economy.refreshAttributes(player)
					Economy.floatIncomeText(player, income)
				end
			end
		end
	end
end

function Economy.getIncome(player)
	local state = Economy.players[player]
	if not state then
		return 0
	end
	local total = 0
	for _, model in ipairs(state.owned) do
		if model.Parent then
			total += model:GetAttribute("Rate") or 0
		end
	end
	local mult = 1 + Config.REBIRTH_BONUS * state.rebirths
	if Economy.goldenActive then
		mult *= 2
	end
	if Economy.mythicActive then
		mult *= 2
	end
	return math.floor(total * mult)
end

function Economy.addPlayer(player)
	local baseIndex = 1
	for i = 1, #Config.BASES do
		if not Economy.takenBases[i] then
			baseIndex = i
			break
		end
	end
	Economy.takenBases[baseIndex] = player
	Economy.players[player] = {
		coins = Config.STARTING_COINS,
		owned = {},
		index = {},
		indexCount = 0,
		rebirths = 0,
		slots = Config.BASE_SLOTS,
		baseIndex = baseIndex,
		lockUntil = 0,
		lockCooldownUntil = 0,
		protectedUntil = os.time() + Config.SPAWN_PROTECTION,
	}
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local coinsStat = Instance.new("IntValue")
	coinsStat.Name = "Coins"
	coinsStat.Value = Config.STARTING_COINS
	coinsStat.Parent = leaderstats
	local rebirthStat = Instance.new("IntValue")
	rebirthStat.Name = "Rebirths"
	rebirthStat.Value = 0
	rebirthStat.Parent = leaderstats
	Economy.refreshAttributes(player)
end

function Economy.removePlayer(player)
	local state = Economy.players[player]
	if state then
		for _, model in ipairs(state.owned) do
			if model.Parent then
				model:Destroy()
			end
		end
		Economy.takenBases[state.baseIndex] = nil
	end
	Economy.players[player] = nil
end

function Economy.refreshAttributes(player)
	local state = Economy.players[player]
	if not state then
		return
	end
	player:SetAttribute("Coins", state.coins)
	player:SetAttribute("Income", Economy.getIncome(player))
	player:SetAttribute("Rebirths", state.rebirths)
	player:SetAttribute("Slots", state.slots)
	player:SetAttribute("Owned", #state.owned)
	player:SetAttribute("IndexCount", state.indexCount)
	player:SetAttribute("BaseIndex", state.baseIndex)
	local now = os.time()
	player:SetAttribute("LockLeft", math.max(0, state.lockUntil - now))
	player:SetAttribute("LockCooldown", math.max(0, state.lockCooldownUntil - now))
	player:SetAttribute("Multiplier", 1 + Config.REBIRTH_BONUS * state.rebirths)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coinsStat = leaderstats:FindFirstChild("Coins")
		if coinsStat then
			coinsStat.Value = state.coins
		end
		local rebirthStat = leaderstats:FindFirstChild("Rebirths")
		if rebirthStat then
			rebirthStat.Value = state.rebirths
		end
	end
end

function Economy.placeInBase(player, model)
	local state = Economy.players[player]
	if not state then
		return
	end
	local base = Config.BASES[state.baseIndex]
	local slot = #state.owned
	local col = slot % 4
	local row = math.floor(slot / 4)
	local x = base.x - 6 + col * 4
	local z = base.z - 4 + row * 4
	model:PivotTo(CFrame.new(x, 0, z))
end

function Economy.floatIncomeText(player, income)
	local state = Economy.players[player]
	if not state then
		return
	end
	local base = Config.BASES[state.baseIndex]
	local anchor = Instance.new("Part")
	anchor.Name = "IncomeFloat"
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Transparency = 1
	anchor.CanCollide = false
	anchor.Anchored = true
	anchor.Position = Vector3.new(base.x, 8, base.z)
	anchor.Parent = workspace
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(160, 44)
	gui.AlwaysOnTop = true
	gui.Parent = anchor
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = "+$" .. income
	text.TextColor3 = Color3.fromRGB(120, 255, 120)
	text.TextStrokeTransparency = 0
	text.TextSize = 30
	text.Font = Enum.Font.GothamBold
	text.Parent = gui
	task.spawn(function()
		for _ = 1, 20 do
			task.wait(0.075)
			if anchor.Parent then
				anchor.Position += Vector3.new(0, 0.25, 0)
			end
		end
		anchor:Destroy()
	end)
end

function Economy.startMythicWindow()
	if Economy.mythicActive then
		return
	end
	Economy.mythicActive = true
	Economy.setGameState("MythicActive", true)
	task.delay(Config.MYTHIC_WINDOW, function()
		Economy.mythicActive = false
		Economy.setGameState("MythicActive", false)
	end)
end

function Economy.startGoldenHour()
	while true do
		task.wait(Config.GOLDEN_INTERVAL)
		Economy.goldenActive = true
		Economy.setGameState("GoldenActive", true)
		Economy.notifyAll("golden", "GOLDEN HOUR — 2x INCOME!")
		local lighting = game:GetService("Lighting")
		lighting.Ambient = Color3.fromRGB(255, 220, 130)
		task.wait(Config.GOLDEN_DURATION)
		Economy.goldenActive = false
		Economy.setGameState("GoldenActive", false)
		lighting.Ambient = Color3.fromRGB(200, 200, 200)
		for player, _ in pairs(Economy.players) do
			Economy.refreshAttributes(player)
		end
	end
end

function Economy.setGameState(name, value)
	local folder = ReplicatedStorage:FindFirstChild("GameState")
	if folder then
		folder:SetAttribute(name, value)
	end
end

function Economy.notify(player, kind, text)
	local notify = ReplicatedStorage:WaitForChild("BrainrotNotify")
	notify:FireClient(player, kind, text)
end

function Economy.notifyAll(kind, text)
	local notify = ReplicatedStorage:WaitForChild("BrainrotNotify")
	notify:FireAllClients(kind, text)
end

function Economy.updateNextTierBoard(afterName)
	local next = Config.getNextTier(afterName)
	if not next then
		return
	end
	local board = workspace:FindFirstChild("NextTierBoard")
	if not board then
		return
	end
	local gui = board:FindFirstChild("BoardGui")
	if not gui then
		return
	end
	local label = gui:FindFirstChild("BoardText")
	if label then
		label.Text = "NEXT TIER: " .. next.rarity:upper() .. " — " .. next.name .. " — $" .. next.rate .. "/s — $" .. next.price
	end
	Economy.setGameState("NextTier", next.name)
end

function Economy.start()
	Players.PlayerAdded:Connect(function(player)
		Economy.addPlayer(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		Economy.removePlayer(player)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		Economy.addPlayer(player)
	end
	task.spawn(function()
		Economy.collectIncome()
	end)
	task.spawn(function()
		Economy.startGoldenHour()
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			for player, _ in pairs(Economy.players) do
				Economy.refreshAttributes(player)
			end
		end
	end)
end

return Economy
