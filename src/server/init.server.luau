-- Brainrot Blitz server init: builds the 3D world, wires the modules,
-- remotes and player lifecycle. Lighting technology is set in
-- default.project.json, never here (writing it from a script is forbidden).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Conveyor = require(script.Conveyor)
local Economy = require(script.Economy)
local Wave = require(script.Wave)
local Steal = require(script.Steal)
local Rebirth = require(script.Rebirth)
local Slap = require(script.Slap)

local function buildWorld()
	Lighting.ClockTime = 14
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(120, 120, 120)
	Lighting.OutdoorAmbient = Color3.fromRGB(160, 160, 160)
	Lighting.GlobalShadows = true

	-- Baseplate comes from default.project.json (CFrame, not Position:
	-- Rojo ignores Position on the baseplate and it ends up buried).

	local carpet = Instance.new("Part")
	carpet.Name = "ConveyorCarpet"
	carpet.Anchored = true
	carpet.Size = Vector3.new(140, 1, 10)
	carpet.Color = Color3.fromRGB(200, 30, 40)
	carpet.Material = Enum.Material.Carpet
	carpet.CFrame = CFrame.new(0, 0.5, Config.BELT_Z)
	carpet.Parent = workspace
	for i = 1, 2 do
		local rail = Instance.new("Part")
		rail.Name = "ConveyorRail"
		rail.Anchored = true
		rail.Size = Vector3.new(140, 1, 1)
		rail.Color = Color3.fromRGB(255, 210, 40)
		rail.CFrame = CFrame.new(0, 1, Config.BELT_Z + (i == 1 and 5.5 or -5.5))
		rail.Parent = workspace
	end

	local function makeBoard(name, pos, size, title, lines, titleColor)
		local board = Instance.new("Part")
		board.Name = name
		board.Anchored = true
		board.Size = size
		board.Color = Color3.fromRGB(120, 80, 40)
		board.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(180), 0)
		board.Parent = workspace
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.Parent = board
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "BoardTitle"
		titleLabel.Size = UDim2.new(1, 0, 0, 50)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = title
		titleLabel.TextColor3 = titleColor
		titleLabel.TextScaled = true
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.Parent = gui
		local body = Instance.new("TextLabel")
		body.Name = "BoardBody"
		body.Position = UDim2.new(0, 0, 0, 50)
		body.Size = UDim2.new(1, 0, 1, -50)
		body.BackgroundTransparency = 1
		body.Text = table.concat(lines, "\n")
		body.TextColor3 = Color3.fromRGB(255, 255, 255)
		body.TextScaled = true
		body.Font = Enum.Font.GothamBold
		body.TextWrapped = true
		body.Parent = gui
		return board
	end

	makeBoard("HowToPlayBoard", Vector3.new(-20, 5, 30), Vector3.new(24, 10, 1), "HOW TO PLAY", {
		"BUY brainrots - EARN $/sec",
		"STEAL rivals - LOCK your base",
		"SURVIVE the tsunami",
		"REBIRTH x1.25 - GOLDEN HOUR 2x",
	}, Color3.fromRGB(255, 210, 40))
	makeBoard("NextTierBoard", Vector3.new(30, 5, 12), Vector3.new(20, 8, 1), "NEXT TIER", {
		"EPIC - Captain Noodle",
		"$60/s - $800",
		"Buy rarer, earn faster!",
	}, Color3.fromRGB(120, 220, 255))
	makeBoard("StealBoard", Vector3.new(-40, 5, -20), Vector3.new(18, 8, 1), "STEAL!", {
		"Click a rival brainrot",
		"Carry it home - SLAP drops it",
		"LOCK stops thieves 60s",
	}, Color3.fromRGB(255, 90, 90))

	local sign = Instance.new("Part")
	sign.Name = "BlitzSign"
	sign.Anchored = true
	sign.Size = Vector3.new(30, 8, 1)
	sign.Color = Color3.fromRGB(255, 210, 40)
	sign.CFrame = CFrame.new(0, 9, 45) * CFrame.Angles(0, math.rad(180), 0)
	sign.Parent = workspace
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.Parent = sign
	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.fromScale(1, 1)
	signText.BackgroundTransparency = 1
	signText.Text = "BRAINROT BLITZ"
	signText.TextColor3 = Color3.fromRGB(180, 30, 30)
	signText.TextScaled = true
	signText.Font = Enum.Font.GothamBlack
	signText.Parent = signGui
	for _, dx in ipairs({ -14, 14 }) do
		local post = Instance.new("Part")
		post.Name = "SignPost"
		post.Anchored = true
		post.Size = Vector3.new(1, 9, 1)
		post.Color = Color3.fromRGB(90, 60, 30)
		post.CFrame = CFrame.new(dx, 4.5, 45)
		post.Parent = workspace
	end

	for i, base in ipairs(Config.BASES) do
		local floor = Instance.new("Part")
		floor.Name = "BaseFloor" .. tostring(i)
		floor.Anchored = true
		floor.Size = Vector3.new(26, 1, 26)
		floor.Color = base.color
		floor.Material = Enum.Material.SmoothPlastic
		floor.CFrame = CFrame.new(base.position + Vector3.new(0, 0.5, 0))
		floor.Parent = workspace
		for tx = 1, 5 do
			for tz = 1, 5 do
				local tile = Instance.new("Part")
				tile.Name = "BaseTile"
				tile.Anchored = true
				tile.Size = Vector3.new(4, 0.3, 4)
				tile.Color = Color3.fromRGB(255, 255, 255)
				tile.CFrame = CFrame.new(base.position + Vector3.new((tx - 3) * 4.5, 1.1, (tz - 3) * 4.5))
				tile.Parent = workspace
			end
		end
		for _, wx in ipairs({ -13, 13 }) do
			local wall = Instance.new("Part")
			wall.Name = "BaseWall"
			wall.Anchored = true
			wall.Size = Vector3.new(1, 4, 26)
			wall.Color = base.color
			wall.Transparency = 0.4
			wall.CFrame = CFrame.new(base.position + Vector3.new(wx, 2, 0))
			wall.Parent = workspace
		end
		local labelPart = Instance.new("Part")
		labelPart.Name = "BaseLabelPart"
		labelPart.Anchored = true
		labelPart.Size = Vector3.new(10, 4, 1)
		labelPart.Transparency = 1
		labelPart.CFrame = CFrame.new(base.position + Vector3.new(0, 7, -13))
		labelPart.Parent = workspace
		local labelGui = Instance.new("BillboardGui")
		labelGui.Size = UDim2.fromOffset(200, 50)
		labelGui.AlwaysOnTop = true
		labelGui.Parent = labelPart
		local labelText = Instance.new("TextLabel")
		labelText.Size = UDim2.fromScale(1, 1)
		labelText.BackgroundTransparency = 0.5
		labelText.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		labelText.Text = "BASE " .. tostring(i)
		labelText.TextColor3 = Color3.fromRGB(255, 255, 255)
		labelText.TextScaled = true
		labelText.Font = Enum.Font.GothamBold
		labelText.Parent = labelGui
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "BaseSpawn" .. tostring(i)
		spawn.Anchored = true
		spawn.Size = Vector3.new(6, 1, 6)
		spawn.Color = base.color
		spawn.CFrame = CFrame.new(base.position + Vector3.new(0, 0.5, 0))
		spawn.Enabled = false
		spawn.Parent = workspace
	end
	local plazaSpawn = Instance.new("SpawnLocation")
	plazaSpawn.Name = "PlazaSpawn"
	plazaSpawn.Anchored = true
	plazaSpawn.Size = Vector3.new(6, 1, 6)
	plazaSpawn.Color = Color3.fromRGB(255, 255, 255)
	plazaSpawn.CFrame = CFrame.new(0, 0.5, 40)
	plazaSpawn.Parent = workspace

	for i = 1, 8 do
		local angle = (i - 1) * math.pi / 4
		local tx = math.cos(angle) * 95
		local tz = math.sin(angle) * 95
		local trunk = Instance.new("Part")
		trunk.Name = "TreeTrunk"
		trunk.Anchored = true
		trunk.Size = Vector3.new(2, 8, 2)
		trunk.Color = Color3.fromRGB(120, 80, 40)
		trunk.CFrame = CFrame.new(tx, 4, tz)
		trunk.Parent = workspace
		local leaves = Instance.new("Part")
		leaves.Name = "TreeLeaves"
		leaves.Shape = Enum.PartType.Ball
		leaves.Anchored = true
		leaves.Size = Vector3.new(10, 10, 10)
		leaves.Color = Color3.fromRGB(40, 180, 60)
		leaves.CFrame = CFrame.new(tx, 11, tz)
		leaves.Parent = workspace
		local lampPost = Instance.new("Part")
		lampPost.Name = "LampPost"
		lampPost.Anchored = true
		lampPost.Size = Vector3.new(1, 8, 1)
		lampPost.Color = Color3.fromRGB(60, 60, 60)
		lampPost.CFrame = CFrame.new(-tx * 0.6, 4, tz * 0.6)
		lampPost.Parent = workspace
		local lampLight = Instance.new("PointLight")
		lampLight.Color = Color3.fromRGB(255, 220, 120)
		lampLight.Range = 20
		lampLight.Parent = lampPost
	end

	for i = 1, 6 do
		local cloud = Instance.new("Part")
		cloud.Name = "Cloud"
		cloud.Shape = Enum.PartType.Ball
		cloud.Anchored = true
		cloud.Size = Vector3.new(24, 8, 12)
		cloud.Color = Color3.fromRGB(255, 255, 255)
		cloud.Transparency = 0.3
		cloud.CFrame = CFrame.new(-80 + i * 32, 45, -60 + (i % 2) * 40)
		cloud.Parent = workspace
	end

	for i = 1, 20 do
		local fence = Instance.new("Part")
		fence.Name = "FencePost"
		fence.Anchored = true
		fence.Size = Vector3.new(1, 3, 1)
		fence.Color = Color3.fromRGB(255, 255, 255)
		fence.CFrame = CFrame.new(-95 + i * 10, 1.5, 95)
		fence.Parent = workspace
	end
end

local function setupRemotes()
	local buyEffect = Instance.new("RemoteEvent")
	buyEffect.Name = "BuyEffectEvent"
	buyEffect.Parent = ReplicatedStorage
	local lockEvent = Instance.new("RemoteEvent")
	lockEvent.Name = "LockEvent"
	lockEvent.Parent = ReplicatedStorage
	lockEvent.OnServerEvent:Connect(function(player)
		Steal.lockBase(player)
	end)
	local rebirthEvent = Instance.new("RemoteEvent")
	rebirthEvent.Name = "RebirthEvent"
	rebirthEvent.Parent = ReplicatedStorage
	rebirthEvent.OnServerEvent:Connect(function(player)
		Rebirth.applyRebirth(player)
	end)
	local buyEvent = Instance.new("RemoteEvent")
	buyEvent.Name = "BuyEvent"
	buyEvent.Parent = ReplicatedStorage
	buyEvent.OnServerEvent:Connect(function(player, model)
		if typeof(model) ~= "Instance" or not model:IsA("Model") then return end
		if not model:GetAttribute("CharName") then return end
		if not model:IsDescendantOf(workspace) then return end
		Economy.buyBrainrot(player, model)
	end)
end

local function onPlayerAdded(player)
	Economy.registerPlayer(player)
	player.CharacterAdded:Connect(function(_character)
		task.wait(0.5)
		Slap.giveTool(player)
		local state = Economy.Players[player]
		if state then
			local base = Config.BASES[state.baseIndex]
			for _try = 1, 3 do
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if root then
					root.CFrame = CFrame.new(base.position + Vector3.new(0, 4, 0))
					task.wait(1)
					if (root.Position - base.position).Magnitude < 10 then break end
				else
					task.wait(1)
				end
			end
		end
	end)
end

buildWorld()
setupRemotes()
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
	Steal.onPlayerRemoving(player)
	Economy.removePlayer(player)
end)
for _, player in ipairs(Players:GetPlayers()) do onPlayerAdded(player) end
Economy.startLoops()
Conveyor.start()
Wave.start()
print("Brainrot Blitz server ready: 16 brainrots, 8 bases, conveyor live.")
