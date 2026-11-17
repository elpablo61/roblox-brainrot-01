-- Wave: the tsunami. 120s countdown, 20s warning with a siren banner, then a
-- giant water wall sweeps the plaza. Inside your own base you are safe;
-- outside it you are knocked back, lose 10% of your coins and drop your catch.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Wave = {}

function Wave.startTsunami()
	local wall = Instance.new("Part")
	wall.Name = "TsunamiWall"
	wall.Size = Vector3.new(4, 30, 180)
	wall.Position = Vector3.new(-75, 15, 0)
	wall.Color = Color3.fromRGB(0, 150, 255)
	wall.Transparency = 0.45
	wall.Material = Enum.Material.Glass
	wall.Anchored = true
	wall.CanCollide = false
	wall.Parent = workspace
	local notify = ReplicatedStorage:WaitForChild("BrainrotNotify")
	notify:FireAllClients("wave-sweep", "TSUNAMI! RUN HOME!")
	local hit = {}
	local startTime = os.clock()
	local duration = 8
	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		local t = os.clock() - startTime
		local x = -75 + (150 * math.clamp(t / duration, 0, 1))
		if wall.Parent then
			wall.Position = Vector3.new(x, 15, 0)
		end
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and not hit[player] and not Wave.isInOwnBase(player) then
				if math.abs(root.Position.X - x) < 6 then
					hit[player] = true
					Wave.knockPlayer(player, root)
				end
			end
		end
		if t >= duration then
			connection:Disconnect()
			wall:Destroy()
		end
	end)
end

function Wave.isInOwnBase(player)
	local Economy = require(script.Parent:WaitForChild("Economy"))
	local state = Economy.players[player]
	if not state then
		return false
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local base = Config.BASES[state.baseIndex]
	return math.abs(root.Position.X - base.x) <= 11 and math.abs(root.Position.Z - base.z) <= 11
end

function Wave.knockPlayer(player, root)
	local Economy = require(script.Parent:WaitForChild("Economy"))
	local state = Economy.players[player]
	if state then
		local lost = math.floor(state.coins * Config.WAVE_COIN_LOSS)
		state.coins -= lost
		Economy.refreshAttributes(player)
		if lost > 0 then
			Economy.notify(player, "wave-hit", "-" .. lost .. " coins! The wave got you!")
		end
	end
	root:ApplyImpulse(Vector3.new(4000, 2500, 0))
	local Steal = require(script.Parent:WaitForChild("Steal"))
	Steal.dropCarried(player)
end

function Wave.runLoop()
	local folder = ReplicatedStorage:WaitForChild("GameState")
	while true do
		local remaining = Config.WAVE_INTERVAL
		folder:SetAttribute("WaveState", "countdown")
		while remaining > 0 do
			folder:SetAttribute("WaveTime", remaining)
			task.wait(1)
			remaining -= 1
		end
		folder:SetAttribute("WaveState", "warning")
		folder:SetAttribute("WaveTime", Config.WAVE_WARNING)
		local notify = ReplicatedStorage:WaitForChild("BrainrotNotify")
		notify:FireAllClients("wave-warning", "TSUNAMI IN 20s — RUN HOME!")
		for i = Config.WAVE_WARNING, 1, -1 do
			folder:SetAttribute("WaveTime", i)
			task.wait(1)
		end
		folder:SetAttribute("WaveState", "sweep")
		Wave.startTsunami()
		task.wait(9)
	end
end

function Wave.start()
	task.spawn(function()
		Wave.runLoop()
	end)
end

return Wave
