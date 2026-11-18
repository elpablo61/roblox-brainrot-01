-- Economy owns all player state: coins, owned brainrots, rebirth count, lock timers.
-- Income ticks once per second. Buying deducts coins and moves the brainrot
-- to the buyer's base. State is mirrored to player attributes for the HUD.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Economy = {}
Economy.Players = {}
Economy.GoldenLeft = 0
Economy.GoldenCycle = 0
Economy.MythicLeft = 0

local function refreshAttributes(player, state)
	player:SetAttribute("Coins", math.floor(state.coins))
	player:SetAttribute("IncomePerSec", Economy.getIncome(player))
	player:SetAttribute("SlotsUsed", #state.owned)
	player:SetAttribute("SlotsMax", state.slotsMax)
	player:SetAttribute("IndexCount", state.indexCount)
	player:SetAttribute("Rebirths", state.rebirths)
	player:SetAttribute("LockLeft", math.max(0, math.floor(state.lockLeft)))
	player:SetAttribute("LockCooldown", math.max(0, math.floor(state.lockCooldown)))
	player:SetAttribute("ProtectLeft", math.max(0, math.floor(state.protectLeft)))
	player:SetAttribute("BaseIndex", state.baseIndex)
	player:SetAttribute("GoldenLeft", Economy.GoldenLeft)
	player:SetAttribute("MythicLeft", Economy.MythicLeft)
	local mult = (Config.REBIRTH_MULTIPLIER ^ state.rebirths)
	if Economy.GoldenLeft > 0 then mult *= 2 end
	if Economy.MythicLeft > 0 then mult *= 2 end
	player:SetAttribute("Multiplier", mult)
end
Economy.refreshAttributes = refreshAttributes

function Economy.buyBrainrot(player, model)
	local state = Economy.Players[player]
	if not state or not model or not model.Parent then return false end
	if model:GetAttribute("OwnerId") and model:GetAttribute("OwnerId") ~= 0 then
		local Steal = require(script.Parent.Steal)
		return Steal.attemptSteal(player, model)
	end
	if #state.owned >= state.slotsMax then return false end
	local price = model:GetAttribute("Price") or 0
	if state.coins < price then return false end
	state.coins -= price
	model:SetAttribute("OwnerId", player.UserId)
	table.insert(state.owned, model)
	local seen = state.seen
	local name = model:GetAttribute("CharName") or model.Name
	if not seen[name] then
		seen[name] = true
		state.indexCount += 1
	end
	local base = Config.BASES[state.baseIndex]
	local slot = #state.owned
	local ox = ((slot - 1) % 5) * 4 - 8
	local oz = math.floor((slot - 1) / 5) * 4 - 2
	local dest = base.position + Vector3.new(ox, 3, oz)
	model:SetAttribute("Belt", false)
	local primary = model.PrimaryPart
	if primary then
		primary.CFrame = CFrame.new(dest)
		primary.Anchored = true
	end
	local label = model:FindFirstChild("Label", true)
	if label then
		local text = label:FindFirstChildOfClass("TextLabel")
		if text then text.Text = name .. "  $" .. tostring(model:GetAttribute("Income")) .. "/s" end
	end
	refreshAttributes(player, state)
	local Effects = ReplicatedStorage:FindFirstChild("BuyEffectEvent")
	if Effects then Effects:FireClient(player, dest) end
	return true
end

function Economy.collectIncome(player)
	local state = Economy.Players[player]
	if not state then return 0 end
	local income = Economy.getIncome(player)
	if income > 0 then
		state.coins += income
		local base = Config.BASES[state.baseIndex]
		local floatPart = Instance.new("Part")
		floatPart.Name = "IncomeFloat"
		floatPart.Anchored = true
		floatPart.CanCollide = false
		floatPart.Transparency = 1
		floatPart.Size = Vector3.new(1, 1, 1)
		floatPart.CFrame = CFrame.new(base.position + Vector3.new(0, 6, 0))
		floatPart.Parent = workspace
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromOffset(120, 40)
		gui.StudsOffset = Vector3.new(0, 0, 0)
		gui.AlwaysOnTop = true
		gui.Parent = floatPart
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = "+$" .. tostring(income)
		label.TextColor3 = Color3.fromRGB(80, 255, 120)
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.Parent = gui
		TweenService:Create(floatPart, TweenInfo.new(1.4), { CFrame = CFrame.new(base.position + Vector3.new(0, 10, 0)) }):Play()
		Debris:AddItem(floatPart, 1.5)
	end
	refreshAttributes(player, state)
	return income
end

function Economy.getIncome(player)
	local state = Economy.Players[player]
	if not state then return 0 end
	local base = 0
	for _, model in ipairs(state.owned) do
		if model.Parent then base += model:GetAttribute("Income") or 0 end
	end
	local mult = Config.REBIRTH_MULTIPLIER ^ state.rebirths
	if Economy.GoldenLeft > 0 then mult *= 2 end
	if Economy.MythicLeft > 0 then mult *= 2 end
	return math.floor(base * mult)
end

function Economy.startMythicWindow()
	Economy.MythicLeft = Config.MYTHIC_WINDOW_SECONDS
	for _, player in ipairs(Players:GetPlayers()) do
		local state = Economy.Players[player]
		if state then refreshAttributes(player, state) end
	end
end

function Economy.registerPlayer(player)
	local used = {}
	for _, state in pairs(Economy.Players) do used[state.baseIndex] = true end
	local baseIndex = 1
	for i = 1, #Config.BASES do
		if not used[i] then baseIndex = i break end
	end
	Economy.Players[player] = {
		coins = Config.STARTING_COINS,
		owned = {},
		seen = {},
		indexCount = 0,
		rebirths = 0,
		slotsMax = Config.BASE_SLOTS,
		baseIndex = baseIndex,
		lockLeft = 0,
		lockCooldown = 0,
		protectLeft = Config.SPAWN_PROTECTION,
	}
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local coinsValue = Instance.new("IntValue")
	coinsValue.Name = "Coins"
	coinsValue.Value = Config.STARTING_COINS
	coinsValue.Parent = leaderstats
	refreshAttributes(player, Economy.Players[player])
	task.spawn(function()
		local character = player.Character or player.CharacterAdded:Wait()
		local root = character:WaitForChild("HumanoidRootPart")
		local base = Config.BASES[baseIndex]
		root.CFrame = CFrame.new(base.position + Vector3.new(0, 4, 0))
	end)
end

function Economy.removePlayer(player)
	Economy.Players[player] = nil
end

function Economy.nextTierText(player)
	local state = Economy.Players[player]
	local ownedIncome = 0
	if state then
		for _, model in ipairs(state.owned) do ownedIncome += model:GetAttribute("Income") or 0 end
	end
	for _, def in ipairs(Config.CHARACTERS) do
		if def.income > ownedIncome then
			return "NEXT: " .. def.rarity:upper() .. " - " .. def.name .. " - $" .. tostring(def.income) .. "/s - $" .. tostring(def.price)
		end
	end
	return "NEXT: SECRET MAXED - You own the best!"
end

function Economy.startLoops()
	task.spawn(function()
		while true do
			task.wait(1)
			Economy.GoldenCycle += 1
			if Economy.GoldenCycle >= Config.GOLDEN_HOUR_CYCLE then
				Economy.GoldenCycle = 0
				Economy.GoldenLeft = Config.GOLDEN_HOUR_SECONDS
			end
			if Economy.GoldenLeft > 0 then Economy.GoldenLeft -= 1 end
			if Economy.MythicLeft > 0 then Economy.MythicLeft -= 1 end
			for _, player in ipairs(Players:GetPlayers()) do
				local state = Economy.Players[player]
				if state then
					if state.lockLeft > 0 then state.lockLeft -= 1 end
					if state.lockCooldown > 0 then state.lockCooldown -= 1 end
					if state.protectLeft > 0 then state.protectLeft -= 1 end
					Economy.collectIncome(player)
					local board = workspace:FindFirstChild("NextTierBoard")
					if board then
						local gui = board:FindFirstChildOfClass("SurfaceGui")
						local body = gui and gui:FindFirstChild("BoardBody")
						if body then body.Text = Economy.nextTierText(player) end
					end
					local leader = player:FindFirstChild("leaderstats")
					if leader then
						local coinsValue = leader:FindFirstChild("Coins")
						if coinsValue then coinsValue.Value = math.floor(state.coins) end
					end
				end
			end
		end
	end)
end

return Economy
