-- Wave: the 120-second tsunami countdown, the 20-second warning, the wall
-- sweep that knocks players outside their base back and drops 10% of their
-- coins, plus the Golden Hour and Mythic 2x income events. First function
-- is the tsunami itself.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Wave = {}
local running = false
local wall = nil

local function getGameState()
	return ReplicatedStorage:WaitForChild("GameState")
end

local function broadcastBanner(text, color, duration)
	local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")
	remotes:WaitForChild("Banner"):FireAllClients(text, color, duration)
end

local function makeWall()
	if wall then
		wall:Destroy()
	end
	wall = Instance.new("Part")
	wall.Name = "TsunamiWall"
	wall.Size = Vector3.new(170, 30, 2)
	wall.Color = Color3.fromRGB(40, 140, 255)
	wall.Material = Enum.Material.Neon
	wall.Transparency = 0.4
	wall.Anchored = true
	wall.CanCollide = false
	wall.CFrame = CFrame.new(0, 15, -85)
	wall.Parent = workspace
	return wall
end

function Wave.startTsunami(_arg)
	if running then
		return false
	end
	running = true
	local gs = getGameState()
	task.spawn(function()
		gs:SetAttribute("WavePhase", "warning")
		for remaining = Config.WAVE_WARNING, 1, -1 do
			gs:SetAttribute("WaveTimer", remaining)
			if remaining == Config.WAVE_WARNING or remaining <= 5 then
				broadcastBanner("TSUNAMI IN " .. remaining .. "s - RUN HOME!", "blue", 2)
			end
			task.wait(1)
		end
		gs:SetAttribute("WavePhase", "sweep")
		broadcastBanner("TSUNAMI! RUN HOME!", "blue", 4)
		local wallPart = makeWall()
		local hitPlayers = {}
		local steps = 40
		for i = 1, steps do
			local z = -85 + (170 * i / steps)
			wallPart.CFrame = CFrame.new(0, 15, z)
			for _, player in ipairs(Players:GetPlayers()) do
				if not hitPlayers[player] then
					local char = player.Character
					local root = char and char:FindFirstChild("HumanoidRootPart")
					if root then
						local p = root.Position
						-- Safe inside your own base; anywhere else the wave gets you.
						local Economy = require(script.Parent:WaitForChild("Economy"))
						local state = Economy.getState(player)
						local safe = false
						if state and state.baseIndex > 0 then
							local center = Config.BASE_POSITIONS[state.baseIndex]
							if center and math.abs(p.X - center.X) <= 9 and math.abs(p.Z - center.Z) <= 9 then
								safe = true
							end
						end
						if not safe and math.abs(p.Z - z) < 6 then
							hitPlayers[player] = true
							local humanoid = char:FindFirstChildOfClass("Humanoid")
							if humanoid then
								humanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
							end
							root.AssemblyLinearVelocity = Vector3.new(0, 25, 60)
							local taken = Economy.deductCoins(player, math.floor((player:GetAttribute("Coins") or 0) * Config.WAVE_COIN_LOSS))
							local Steal = require(script.Parent:WaitForChild("Steal"))
							Steal.dropCarried(player, "The wave knocked your stolen brainrot loose!")
							local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")
							remotes:WaitForChild("Banner"):FireClient(player, "HIT! -" .. taken .. " coins - RUN HOME!", "red", 4)
						end
					end
				end
			end
			task.wait(Config.WAVE_SWEEP / steps)
		end
		if wallPart then
			wallPart:Destroy()
		end
		wall = nil
		gs:SetAttribute("WavePhase", "calm")
		gs:SetAttribute("WaveTimer", Config.WAVE_INTERVAL)
		running = false
	end)
	return true
end

function Wave.triggerMythicWindow(charName)
	local gs = getGameState()
	gs:SetAttribute("MythicLeft", Config.MYTHIC_WINDOW)
	broadcastBanner("MYTHIC SPAWNED: " .. charName .. "! 2x INCOME 60s!", "gold", 5)
end

function Wave.startEvents()
	local gs = getGameState()
	gs:SetAttribute("GoldenLeft", 0)
	gs:SetAttribute("MythicLeft", 0)
	task.spawn(function()
		while true do
			task.wait(Config.GOLDEN_INTERVAL - Config.GOLDEN_DURATION)
			gs:SetAttribute("GoldenLeft", Config.GOLDEN_DURATION)
			broadcastBanner("GOLDEN HOUR - 2x INCOME!", "gold", 5)
			for _ = 1, Config.GOLDEN_DURATION do
				task.wait(1)
				local left = (gs:GetAttribute("GoldenLeft") or 0) - 1
				gs:SetAttribute("GoldenLeft", math.max(0, left))
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			local left = gs:GetAttribute("MythicLeft") or 0
			if left > 0 then
				gs:SetAttribute("MythicLeft", left - 1)
			end
		end
	end)
end

function Wave.start()
	local gs = getGameState()
	gs:SetAttribute("WavePhase", "calm")
	gs:SetAttribute("WaveTimer", Config.WAVE_INTERVAL)
	Wave.startEvents()
	task.spawn(function()
		while true do
			for remaining = Config.WAVE_INTERVAL, 1, -1 do
				if (gs:GetAttribute("WavePhase") or "calm") ~= "calm" then
					break
				end
				gs:SetAttribute("WaveTimer", remaining)
				task.wait(1)
			end
			if (gs:GetAttribute("WavePhase") or "calm") == "calm" then
				Wave.startTsunami()
				repeat
					task.wait(1)
				until running == false
			end
		end
	end)
end

return Wave
