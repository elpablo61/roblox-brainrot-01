-- Wave runs the tsunami cycle, Golden Hour, and the Mythic 2x window timers.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Wave = {}
local wall = nil
local hitThisWave = {}

function Wave.startTsunami()
	local gs = ReplicatedStorage:WaitForChild("GameState")
	local Economy = require(script.Parent:WaitForChild("Economy"))
	local Steal = require(script.Parent:WaitForChild("Steal"))
	Economy.bannerAll("TSUNAMI IN 20s - RUN HOME!", Color3.fromRGB(80, 160, 255))
	gs:SetAttribute("WavePhase", "warning")
	for t = Config.WAVE_WARN, 1, -1 do
		gs:SetAttribute("WaveTimer", t)
		task.wait(1)
	end
	gs:SetAttribute("WavePhase", "sweep")
	gs:SetAttribute("WaveTimer", 0)
	hitThisWave = {}
	if wall then
		wall.Transparency = 0.25
		wall.CFrame = CFrame.new(-95, 15, 0)
		local tween = TweenService:Create(wall, TweenInfo.new(8, Enum.EasingStyle.Linear), { CFrame = CFrame.new(95, 15, 0) })
		tween:Play()
		for step = 1, 16 do
			task.wait(0.5)
			local wallX = wall.Position.X
			for _, player in ipairs(Players:GetPlayers()) do
				local char = player.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if root and not hitThisWave[player] then
					local state = Economy.getState(player)
					local inside = false
					if state then
						local center = Economy.getBaseCenter(state.baseIndex)
						local d = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(center.X, 0, center.Z)).Magnitude
						inside = d < 10
					end
					if not inside and math.abs(root.Position.X - wallX) < 14 then
						hitThisWave[player] = true
						Wave.knockPlayer(player, root)
						Steal.dropCarried(player, "wave")
					end
				end
			end
		end
		tween:Cancel()
		wall.Transparency = 1
	end
	gs:SetAttribute("WavePhase", "calm")
	Economy.bannerAll("WAVE PASSED - back to the belt!", Color3.fromRGB(80, 255, 120))
end

function Wave.knockPlayer(player, root)
	local Economy = require(script.Parent:WaitForChild("Economy"))
	local state = Economy.getState(player)
	if not state then
		return
	end
	local loss = math.floor(state.coins * Config.WAVE_LOSS)
	state.coins -= loss
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Sit = false
	end
	local center = Economy.getBaseCenter(state.baseIndex)
	local dir = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(center.X, 0, center.Z))
	if dir.Magnitude < 1 then
		dir = Vector3.new(1, 0, 0)
	end
	dir = dir.Unit
	root.AssemblyLinearVelocity = dir * 60 + Vector3.new(0, 30, 0)
	Economy.banner(player, "HIT! -" .. loss .. " coins - RUN HOME!", Color3.fromRGB(255, 80, 80))
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	remotes:WaitForChild("HudEvent"):FireClient(player, "Float", "-" .. loss .. " coins")
	Economy.refreshAttributes(player)
end

function Wave.startLoop(wallPart)
	wall = wallPart
	local gs = ReplicatedStorage:WaitForChild("GameState")
	task.spawn(function()
		while true do
			for t = Config.WAVE_EVERY, 1, -1 do
				gs:SetAttribute("WaveTimer", t)
				gs:SetAttribute("WavePhase", "calm")
				task.wait(1)
			end
			Wave.startTsunami()
		end
	end)
	task.spawn(function()
		local goldenIn = Config.GOLDEN_HOUR_EVERY
		while true do
			task.wait(1)
			local goldenLeft = gs:GetAttribute("GoldenLeft") or 0
			local mythicLeft = gs:GetAttribute("MythicLeft") or 0
			if goldenLeft > 0 then
				gs:SetAttribute("GoldenLeft", goldenLeft - 1)
			else
				goldenIn -= 1
				if goldenIn <= 0 then
					goldenIn = Config.GOLDEN_HOUR_EVERY
					gs:SetAttribute("GoldenLeft", Config.GOLDEN_HOUR_LEN)
					local Economy = require(script.Parent:WaitForChild("Economy"))
					Economy.bannerAll("GOLDEN HOUR - 2x INCOME!", Color3.fromRGB(255, 215, 0))
				end
			end
			if mythicLeft > 0 then
				gs:SetAttribute("MythicLeft", mythicLeft - 1)
			end
		end
	end)
end

return Wave
