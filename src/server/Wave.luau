-- Wave.luau — Brainrot Blitz tsunami wave + Golden Hour event.
-- Rebuild #9, written fresh from prose (builder brief + rebuild notes).
-- The wave sweeps the plaza every 120 seconds with a 20 second warning;
-- Golden Hour fires about 180 seconds after the server starts (NOT at
-- start) and gives every player 2x income for 60 seconds. A Mythic spawn
-- opens a separate 60 second 2x window for everyone.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local Wave = {}

-- Timing. Wave.Interval is the Golden Hour interval (seconds); the next
-- Golden Hour is scheduled relative to process uptime, so it lands about
-- 180 seconds after the server starts instead of firing immediately.
Wave.Interval = 180
Wave.GoldenDuration = 60
Wave.WaveInterval = 120
Wave.WarningTime = 20
Wave.CoinDropPercent = 0.10
Wave.NextGoldenAt = os.clock() + Wave.Interval
Wave.GoldenActive = false
Wave.MythicActive = false
Wave.MythicUntil = 0
Wave.Sweeping = false
Wave.WaveTimer = 120
Wave._running = false
Wave._goldenUntil = 0

-- Timing values from Config when it exposes them; the defaults above are
-- the prose values, so the game behaves the same either way.
local configOk, sharedConfig = pcall(function()
	return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
end)
if configOk and type(sharedConfig) == "table" then
	local waveCfg = sharedConfig.Wave
	if type(waveCfg) == "table" then
		Wave.WaveInterval = waveCfg.Interval or waveCfg.WaveInterval or Wave.WaveInterval
		Wave.WarningTime = waveCfg.Warning or waveCfg.WarningTime or Wave.WarningTime
		Wave.CoinDropPercent = waveCfg.CoinDrop or waveCfg.CoinDropPercent or Wave.CoinDropPercent
	end
	Wave.Interval = sharedConfig.GoldenInterval or sharedConfig.GoldenHourInterval or Wave.Interval
	Wave.GoldenDuration = sharedConfig.GoldenDuration or Wave.GoldenDuration
	Wave.WaveInterval = sharedConfig.WaveInterval or Wave.WaveInterval
	Wave.WarningTime = sharedConfig.WarningTime or Wave.WarningTime
	Wave.CoinDropPercent = sharedConfig.CoinDropPercent or Wave.CoinDropPercent
end
Wave.WaveTimer = Wave.WaveInterval

-- Base plot centres (same layout as default.project.json). Used only as a
-- fallback when the Bases folder cannot be found in the workspace.
local BASE_CENTERS = {
	Vector3.new(-80, 0, -80),
	Vector3.new(0, 0, -80),
	Vector3.new(80, 0, -80),
	Vector3.new(-80, 0, 0),
	Vector3.new(80, 0, 0),
	Vector3.new(-80, 0, 80),
	Vector3.new(0, 0, 80),
	Vector3.new(80, 0, 80),
}
local BASE_HALF = 13

-- Forward declarations so the feature verb below stays the first function.
local getNotify
local notifyAll
local updateMultiplierAttribute
local getBaseCenter
local isPlayerSafe
local dropCoins
local knockbackPlayer
local sweepWall
local startGoldenHour
local stopGoldenHour
local tickLoop

function Wave.startTsunami()
	if Wave.Sweeping then
		return
	end
	Wave.Sweeping = true
	Wave.WaveTimer = Wave.WaveInterval
	notifyAll("TSUNAMI! RUN HOME!")
	task.spawn(function()
		sweepWall()
		Wave.Sweeping = false
	end)
end

getNotify = function()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = ReplicatedStorage
	end
	local notify = remotes:FindFirstChild("Notify")
	if not notify then
		notify = Instance.new("RemoteEvent")
		notify.Name = "Notify"
		notify.Parent = remotes
	end
	return notify
end

notifyAll = function(message)
	pcall(function()
		getNotify():FireAllClients(message)
	end)
end

updateMultiplierAttribute = function()
	pcall(function()
		ReplicatedStorage:SetAttribute("IncomeMultiplier", Wave.getIncomeMultiplier())
		ReplicatedStorage:SetAttribute("GoldenActive", Wave.GoldenActive)
		ReplicatedStorage:SetAttribute("MythicActive", Wave.MythicActive)
	end)
end

getBaseCenter = function(player)
	local baseId = player:GetAttribute("BaseId")
	if type(baseId) == "number" and BASE_CENTERS[baseId] then
		local bases = workspace:FindFirstChild("Bases")
		if bases then
			local base = bases:FindFirstChild("Base" .. tostring(baseId))
			if base then
				local floor = base:FindFirstChild("Floor")
				if floor and floor:IsA("BasePart") then
					return floor.Position
				end
				local _, boxCenter = base:GetBoundingBox()
				if boxCenter then
					return boxCenter
				end
			end
		end
		return BASE_CENTERS[baseId]
	end
	return nil
end

isPlayerSafe = function(player)
	local character = player.Character
	if not character then
		return true
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return true
	end
	local center = getBaseCenter(player)
	if not center then
		return false
	end
	return math.abs(root.Position.X - center.X) <= BASE_HALF
		and math.abs(root.Position.Z - center.Z) <= BASE_HALF
end

dropCoins = function(player)
	local coins = player:GetAttribute("Coins") or 0
	local drop = math.floor(coins * Wave.CoinDropPercent)
	if drop <= 0 then
		return
	end
	local left = coins - drop
	player:SetAttribute("Coins", left)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coinValue = leaderstats:FindFirstChild("Coins")
		if coinValue then
			coinValue.Value = left
		end
	end
	local character = player.Character
	if not character then
		return
	end
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "CoinDropText"
	gui.Size = UDim2.fromOffset(140, 40)
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.AlwaysOnTop = true
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "-" .. tostring(drop) .. " coins"
	label.TextColor3 = Color3.fromRGB(255, 60, 60)
	label.TextSize = 28
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
	gui.Parent = head
	task.spawn(function()
		for _ = 1, 20 do
			gui.StudsOffset += Vector3.new(0, 0.15, 0)
			task.wait(0.1)
		end
		gui:Destroy()
	end)
end

knockbackPlayer = function(player)
	local character = player.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	root.AssemblyLinearVelocity = Vector3.new(70, 30, 0)
	local stealOk, stealModule = pcall(function()
		return require(script.Parent.Steal)
	end)
	if stealOk and stealModule and stealModule.dropCarried then
		pcall(stealModule.dropCarried, player)
	end
end

sweepWall = function()
	local wall = Instance.new("Part")
	wall.Name = "TsunamiWall"
	wall.Anchored = true
	wall.CanCollide = false
	wall.CanTouch = false
	wall.CanQuery = false
	wall.Material = Enum.Material.Glass
	wall.Color = Color3.fromRGB(40, 120, 255)
	wall.Transparency = 0.35
	wall.Size = Vector3.new(6, 30, 240)
	wall.CFrame = CFrame.new(-115, 15, 0)
	wall.Parent = workspace
	local hit = {}
	local tween = TweenService:Create(
		wall,
		TweenInfo.new(12, Enum.EasingStyle.Linear),
		{ CFrame = CFrame.new(115, 15, 0) }
	)
	tween:Play()
	local startedAt = os.clock()
	while os.clock() - startedAt < 12 do
		for _, player in ipairs(Players:GetPlayers()) do
			if not hit[player] and player.Character then
				local root = player.Character:FindFirstChild("HumanoidRootPart")
				if root and math.abs(root.Position.X - wall.Position.X) < 8 then
					hit[player] = true
					if not isPlayerSafe(player) then
						knockbackPlayer(player)
						dropCoins(player)
					end
				end
			end
		end
		task.wait(0.1)
	end
	wall:Destroy()
end

local savedAmbient = Lighting.Ambient
local savedShift = Lighting.ColorShift_Top

startGoldenHour = function()
	Wave.GoldenActive = true
	Wave._goldenUntil = os.clock() + Wave.GoldenDuration
	savedAmbient = Lighting.Ambient
	savedShift = Lighting.ColorShift_Top
	Lighting.Ambient = Color3.fromRGB(255, 210, 120)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 200, 100)
	updateMultiplierAttribute()
	notifyAll("GOLDEN HOUR — 2x INCOME!")
end

stopGoldenHour = function()
	Wave.GoldenActive = false
	Lighting.Ambient = savedAmbient
	Lighting.ColorShift_Top = savedShift
	Wave.NextGoldenAt = os.clock() + Wave.Interval
	updateMultiplierAttribute()
	notifyAll("GOLDEN HOUR OVER — income back to normal!")
end

function Wave.startMythicWindow()
	Wave.MythicActive = true
	Wave.MythicUntil = os.clock() + 60
	updateMultiplierAttribute()
	notifyAll("MYTHIC BRAINROT! 2x INCOME FOR 60s!")
end

function Wave.getIncomeMultiplier()
	if Wave.GoldenActive then
		return 2
	end
	if Wave.MythicActive and os.clock() < Wave.MythicUntil then
		return 2
	end
	return 1
end

function Wave.getMultiplier()
	return Wave.getIncomeMultiplier()
end

function Wave.isGoldenActive()
	return Wave.GoldenActive
end

tickLoop = function()
	while true do
		task.wait(1)
		if Wave.WaveTimer > 0 then
			Wave.WaveTimer -= 1
		end
		if Wave.WaveTimer == Wave.WarningTime then
			notifyAll("TSUNAMI IN 20s — RUN HOME!")
		elseif Wave.WaveTimer <= 0 then
			if not Wave.Sweeping then
				Wave.startTsunami()
			else
				Wave.WaveTimer = 0
			end
		end
		pcall(function()
			ReplicatedStorage:SetAttribute("WaveTimer", Wave.WaveTimer)
		end)
		if Wave.MythicActive and os.clock() >= Wave.MythicUntil then
			Wave.MythicActive = false
			updateMultiplierAttribute()
		end
		if not Wave.GoldenActive and os.clock() >= Wave.NextGoldenAt then
			startGoldenHour()
		elseif Wave.GoldenActive and os.clock() >= Wave._goldenUntil then
			stopGoldenHour()
		end
	end
end

function Wave.init()
	if Wave._running then
		return
	end
	Wave._running = true
	pcall(function()
		ReplicatedStorage:SetAttribute("WaveTimer", Wave.WaveTimer)
		ReplicatedStorage:SetAttribute("GoldenActive", false)
		ReplicatedStorage:SetAttribute("MythicActive", false)
		ReplicatedStorage:SetAttribute("IncomeMultiplier", 1)
	end)
	task.spawn(tickLoop)
end

function Wave.start()
	Wave.init()
end

task.spawn(function()
	Wave.init()
end)

return Wave
