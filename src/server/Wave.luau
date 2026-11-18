-- Wave runs the tsunami: a 120s countdown, a 20s warning banner, then a
-- giant translucent water wall sweeps the plaza for ~8s. Players outside
-- their own base are knocked back and lose 10% of their coins.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Wave = {}
Wave.Timer = Config.WAVE_INTERVAL
local wall = nil

function Wave.startTsunami()
	for _, player in ipairs(Players:GetPlayers()) do
		player:SetAttribute("BannerText", "TSUNAMI! RUN HOME!")
		player:SetAttribute("BannerUntil", os.time() + 5)
	end
	wall = Instance.new("Part")
	wall.Name = "TsunamiWall"
	wall.Size = Vector3.new(10, 30, 180)
	wall.Color = Color3.fromRGB(40, 140, 255)
	wall.Material = Enum.Material.Glass
	wall.Transparency = 0.35
	wall.Anchored = true
	wall.CanCollide = false
	wall.CFrame = CFrame.new(-90, 15, 0)
	wall.Parent = workspace
	local wallRef = wall
	local tween = TweenService:Create(wallRef, TweenInfo.new(Config.WAVE_SWEEP_SECONDS, Enum.EasingStyle.Linear), { CFrame = CFrame.new(90, 15, 0) })
	tween:Play()
	local hit = {}
	task.spawn(function()
		local start = os.clock()
		while os.clock() - start < Config.WAVE_SWEEP_SECONDS do
			task.wait(0.2)
			if not wallRef.Parent then break end
			local wallX = wallRef.Position.X
			for _, player in ipairs(Players:GetPlayers()) do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root and math.abs(root.Position.X - wallX) < 8 and not hit[player] then
					hit[player] = true
					Wave.knockbackPlayer(player, root)
				end
			end
		end
	end)
	task.delay(Config.WAVE_SWEEP_SECONDS, function()
		if wallRef then
			wallRef:Destroy()
			wall = nil
		end
	end)
end

function Wave.knockbackPlayer(player, root)
	local Economy = require(script.Parent.Economy)
	local state = Economy.Players[player]
	if not state then return end
	local base = Config.BASES[state.baseIndex]
	if math.abs(root.Position.X - base.position.X) < 14 and math.abs(root.Position.Z - base.position.Z) < 14 then
		return
	end
	local loss = math.floor(state.coins * Config.WAVE_COIN_LOSS)
	state.coins -= loss
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local Steal = require(script.Parent.Steal)
	if Steal.isCarrying(player) then Steal.dropCarried(player) end
	local away = (root.Position - Vector3.new(0, 0, 0))
	away = Vector3.new(away.X, 0, away.Z)
	if away.Magnitude < 1 then away = Vector3.new(0, 0, 1) end
	away = away.Unit
	root.CFrame = root.CFrame + away * 20 + Vector3.new(0, 4, 0)
	if humanoid then humanoid:TakeDamage(0) end
	player:SetAttribute("BannerText", "TSUNAMI HIT! -" .. tostring(loss) .. " coins - RUN HOME!")
	player:SetAttribute("BannerUntil", os.time() + 5)
	Economy.refreshAttributes(player, state)
end

function Wave.start()
	task.spawn(function()
		while true do
			Wave.Timer = Config.WAVE_INTERVAL
			for _, player in ipairs(Players:GetPlayers()) do
				player:SetAttribute("WaveTimer", Wave.Timer)
			end
			while Wave.Timer > 0 do
				task.wait(1)
				Wave.Timer -= 1
				for _, player in ipairs(Players:GetPlayers()) do
					player:SetAttribute("WaveTimer", Wave.Timer)
				end
			end
			for _, player in ipairs(Players:GetPlayers()) do
				player:SetAttribute("BannerText", "TSUNAMI IN 20s - RUN HOME!")
				player:SetAttribute("BannerUntil", os.time() + 20)
			end
			for i = Config.WAVE_WARNING, 1, -1 do
				for _, player in ipairs(Players:GetPlayers()) do
					player:SetAttribute("WaveTimer", 0)
					player:SetAttribute("WaveWarning", i)
				end
				task.wait(1)
			end
			for _, player in ipairs(Players:GetPlayers()) do
				player:SetAttribute("WaveWarning", 0)
			end
			Wave.startTsunami()
			task.wait(Config.WAVE_SWEEP_SECONDS + 1)
		end
	end)
end

return Wave
