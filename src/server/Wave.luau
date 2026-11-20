-- Brainrot Blitz waves and events: the tsunami every 120 seconds (20s
-- warning, then a giant water wall sweeps the plaza), Golden Hour every
-- 180 seconds (60s of 2x income for everyone), and the Mythic-spawn 2x
-- window. Inside your own base you are safe; outside you are knocked
-- back, drop 10% of your coins, and drop anything you are carrying.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)

local Wave = {}

local EconomyModule = nil
local StealModule = nil
local WaveTimer = Config.Wave.Interval
local NextGoldenAt = Config.GoldenHour.Interval
local Sweeping = false

local getNotify
local getState

function Wave.startTsunami()
	if Sweeping then
		return
	end
	Sweeping = true
	WaveTimer = Config.Wave.Interval
	task.spawn(function()
		local notify = getNotify()
		notify:FireAllClients("WaveWarning", Config.Wave.Warning)
		for i = Config.Wave.Warning, 1, -1 do
			task.wait(1)
			notify:FireAllClients("WaveCountdown", i)
		end
		Wave.sweepWall()
		Sweeping = false
	end)
end

function Wave.setEconomy(module)
	EconomyModule = module
end

function Wave.setSteal(module)
	StealModule = module
end

getNotify = function()
	return ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify")
end

getState = function()
	return ReplicatedStorage:WaitForChild("GameState")
end

function Wave.sweepWall()
	local notify = getNotify()
	local wall = Instance.new("Part")
	wall.Name = "TsunamiWall"
	wall.Size = Vector3.new(Config.Wave.WallWidth, Config.Wave.WallHeight, 2)
	wall.Color = Color3.fromRGB(0, 120, 255)
	wall.Material = Enum.Material.Glass
	wall.Transparency = 0.4
	wall.Anchored = true
	wall.CanCollide = false
	wall.CFrame = CFrame.new(0, Config.Wave.WallHeight / 2, -130)
	wall.Parent = workspace
	notify:FireAllClients("WaveSweep")
	local tween = TweenService:Create(wall, TweenInfo.new(8, Enum.EasingStyle.Linear), {
		CFrame = CFrame.new(0, Config.Wave.WallHeight / 2, 130),
	})
	tween:Play()
	local hit = {}
	local startClock = os.clock()
	while os.clock() - startClock < 8 do
		task.wait(0.3)
		local wallZ = wall.CFrame.Position.Z
		for _, player in ipairs(Players:GetPlayers()) do
			if not hit[player] then
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root then
					local inBase = false
					if EconomyModule then
						local baseId = EconomyModule.getBaseId(player)
						if baseId > 0 then
							local center = EconomyModule.BasePositions[baseId]
							local dx = root.Position.X - center.X
							local dz = root.Position.Z - center.Z
							if math.sqrt(dx * dx + dz * dz) < 14 then
								inBase = true
							end
						end
					end
					local nearWall = math.abs(root.Position.Z - wallZ) < 6
					if not inBase and nearWall then
						hit[player] = true
						Wave.knockbackPlayer(player, root)
					end
				end
			end
		end
	end
	tween:Cancel()
	wall:Destroy()
end

function Wave.knockbackPlayer(player, root)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	end
	root.AssemblyLinearVelocity = Vector3.new(0, 25, 70)
	if StealModule then
		StealModule.dropCarried(player)
	end
	if EconomyModule then
		local coins = EconomyModule.getCoins(player)
		local drop = math.floor(coins * Config.Wave.CoinDropPercent / 100 + 0.5)
		if drop > 0 then
			EconomyModule.addCoins(player, -drop)
			getNotify():FireClient(player, "CoinDrop", drop)
		end
	end
	task.delay(1, function()
		if humanoid and humanoid.Parent then
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end)
end

function Wave.startGoldenHour()
	local state = getState()
	state:SetAttribute("GoldenActive", true)
	state:SetAttribute("GoldenUntil", os.clock() + Config.GoldenHour.Duration)
	getNotify():FireAllClients("GoldenHour", Config.GoldenHour.Duration)
end

function Wave.updateTimers()
	local now = os.clock()
	local state = getState()
	if state:GetAttribute("GoldenActive") and now >= (state:GetAttribute("GoldenUntil") or 0) then
		state:SetAttribute("GoldenActive", false)
	end
	if state:GetAttribute("MythicActive") and now >= (state:GetAttribute("MythicUntil") or 0) then
		state:SetAttribute("MythicActive", false)
	end
	if not state:GetAttribute("GoldenActive") and now >= NextGoldenAt then
		Wave.startGoldenHour()
		NextGoldenAt = now + Config.GoldenHour.Interval
	end
	state:SetAttribute("WaveTimer", math.max(0, WaveTimer))
end

function Wave.start()
	task.spawn(function()
		while true do
			task.wait(1)
			Wave.updateTimers()
			WaveTimer -= 1
			if WaveTimer <= 0 then
				Wave.startTsunami()
			end
		end
	end)
end

return Wave
