-- Wave: the tsunami timer, the 20s warning, the giant water wall sweep, knockback + coin drop,
-- and the Golden Hour event (60s of 2x income every ~180s).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)

local Wave = {}
local waveIn = Config.waveInterval
local goldenIn = Config.goldenHourInterval
local goldenUntil = 0
local wall = nil
local sweeping = false

function Wave.startTsunami(warningSeconds)
	if sweeping then
		return
	end
	sweeping = true
	local warn = warningSeconds or Config.waveWarning
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	remotes.Banner:FireAllClients("TSUNAMI IN " .. tostring(warn) .. "s — RUN HOME!", "Blue")
	local t = warn
	while t > 0 do
		for _, player in ipairs(Players:GetPlayers()) do
			player:SetAttribute("WaveIn", t)
		end
		task.wait(1)
		t -= 1
	end
	Wave.sweepWall(remotes)
	sweeping = false
	waveIn = Config.waveInterval
end

function Wave.sweepWall(remotes)
	if not wall then
		return
	end
	remotes.Banner:FireAllClients("TSUNAMI! GET TO YOUR BASE!", "Blue")
	wall.Transparency = 0.35
	wall.CFrame = CFrame.new(0, 15, -130)
	local tween = TweenService:Create(wall, TweenInfo.new(8, Enum.EasingStyle.Linear), { CFrame = CFrame.new(0, 15, 130) })
	tween:Play()
	local Economy = require(script.Parent.Economy)
	local Steal = require(script.Parent.Steal)
	local hit = {}
	local conn
	conn = game:GetService("RunService").Heartbeat:Connect(function()
		for _, player in ipairs(Players:GetPlayers()) do
			if hit[player] then
				continue
			end
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if not root then
				continue
			end
			local state = Economy.getState(player)
			local safe = false
			if state then
				local dx = math.abs(root.Position.X - state.baseCenter.X)
				local dz = math.abs(root.Position.Z - state.baseCenter.Z)
				safe = dx <= 12 and dz <= 12
			end
			if not safe and math.abs(root.Position.Z - wall.Position.Z) < 8 then
				hit[player] = true
				root.AssemblyLinearVelocity = Vector3.new(0, 35, 80)
				if state then
					local lost = math.floor(state.coins * 0.1)
					if lost > 0 then
						state.coins -= lost
						Economy.refreshAttributes(player)
						remotes.FloatText:FireClient(player, -lost, root.Position + Vector3.new(0, 4, 0))
					end
				end
				Steal.dropCarried(player)
				Economy.banner(player, "-COINS! The wave got you!", "Blue")
			end
		end
	end)
	tween.Completed:Wait()
	conn:Disconnect()
	wall.Transparency = 1
	wall.CFrame = CFrame.new(0, 15, -130)
end

function Wave.startGoldenHour()
	goldenUntil = os.time() + Config.goldenHourDuration
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	remotes.Banner:FireAllClients("GOLDEN HOUR — 2x INCOME!", "Gold")
	local lighting = game:GetService("Lighting")
	lighting.Ambient = Color3.fromRGB(255, 220, 140)
	task.delay(Config.goldenHourDuration, function()
		lighting.Ambient = Color3.fromRGB(200, 190, 170)
	end)
end

function Wave.isGoldenHourActive()
	return os.time() < goldenUntil
end

function Wave.tick()
	while true do
		task.wait(1)
		if not sweeping then
			waveIn -= 1
			if waveIn <= 0 then
				task.spawn(function()
					Wave.startTsunami()
				end)
			end
		end
		goldenIn -= 1
		if goldenIn <= 0 then
			goldenIn = Config.goldenHourInterval
			Wave.startGoldenHour()
		end
		for _, player in ipairs(Players:GetPlayers()) do
			player:SetAttribute("WaveIn", math.max(waveIn, 0))
			player:SetAttribute("GoldenActive", Wave.isGoldenHourActive())
			local state = require(script.Parent.Economy).getState(player)
			if state then
				player:SetAttribute("LockLeft", math.max(0, state.lockUntil - os.time()))
				player:SetAttribute("LockCooldown", math.max(0, state.lockCooldownUntil - os.time()))
			end
		end
	end
end

function Wave.setWall(wallPart)
	wall = wallPart
end

return Wave
