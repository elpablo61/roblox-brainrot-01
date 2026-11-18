-- Brainrot Blitz server init: builds the 3D world and wires every module.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Conveyor = require(script:WaitForChild("Conveyor"))
local Economy = require(script:WaitForChild("Economy"))
local Wave = require(script:WaitForChild("Wave"))
local Steal = require(script:WaitForChild("Steal"))
local Rebirth = require(script:WaitForChild("Rebirth"))
local Slap = require(script:WaitForChild("Slap"))

local BASE_COLORS = {
	Color3.fromRGB(255, 80, 80), Color3.fromRGB(80, 140, 255), Color3.fromRGB(80, 220, 120),
	Color3.fromRGB(255, 200, 40), Color3.fromRGB(170, 80, 255), Color3.fromRGB(255, 140, 200),
	Color3.fromRGB(80, 220, 220), Color3.fromRGB(255, 140, 60),
}

local function makePart(name, size, cframe, color, material, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.Parent = parent or workspace
	return p
end

local function makeBoard(name, size, cframe, lines, textSize, parent)
	local board = makePart(name, size, cframe, Color3.fromRGB(120, 80, 40), Enum.Material.Wood, parent)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 12
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundColor3 = Color3.fromRGB(30, 20, 10)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBold
	label.TextSize = textSize or 28
	label.TextWrapped = true
	label.Text = table.concat(lines, "\n")
	label.Parent = gui
	return board
end

function buildWorld()
	Lighting.ClockTime = 14
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(150, 150, 150)
	Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
	Lighting.GlobalShadows = true

	makePart("Baseplate", Vector3.new(512, 20, 512), CFrame.new(0, -10, 0), Color3.fromRGB(80, 200, 90), Enum.Material.Grass)
	makePart("ConveyorCarpet", Vector3.new(120, 1, 12), CFrame.new(0, 0.5, 0), Color3.fromRGB(200, 30, 40), Enum.Material.Carpet)
	makePart("RailLeft", Vector3.new(120, 1, 1), CFrame.new(0, 1, -6.5), Color3.fromRGB(255, 215, 0), Enum.Material.Neon)
	makePart("RailRight", Vector3.new(120, 1, 1), CFrame.new(0, 1, 6.5), Color3.fromRGB(255, 215, 0), Enum.Material.Neon)

	for i, center in ipairs(Economy.BASE_CENTERS) do
		local color = BASE_COLORS[i]
		makePart("BaseFloor" .. i, Vector3.new(16, 1, 16), CFrame.new(center.X, 0.5, center.Z), color, Enum.Material.SmoothPlastic)
		makePart("BaseFrame" .. i, Vector3.new(17, 0.6, 17), CFrame.new(center.X, 0.2, center.Z), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
		local wallH = 1.5
		makePart("WallN" .. i, Vector3.new(16, wallH, 1), CFrame.new(center.X, wallH / 2 + 1, center.Z - 7.5), color)
		makePart("WallW" .. i, Vector3.new(1, wallH, 16), CFrame.new(center.X - 7.5, wallH / 2 + 1, center.Z), color)
		makePart("WallE" .. i, Vector3.new(1, wallH, 16), CFrame.new(center.X + 7.5, wallH / 2 + 1, center.Z), color)
		local sign = makeBoard("BaseSign" .. i, Vector3.new(10, 3, 0.5), CFrame.new(center.X, 4, center.Z - 7.5), { "BASE " .. i }, 40)
		sign.Parent = workspace
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.new(0, 0.5, 76)
	spawn.Color = Color3.fromRGB(255, 255, 255)
	spawn.Anchored = true
	spawn.Parent = workspace

	makePart("SignPostL", Vector3.new(1, 10, 1), CFrame.new(-8, 5, 62), Color3.fromRGB(90, 60, 30), Enum.Material.Wood)
	makePart("SignPostR", Vector3.new(1, 10, 1), CFrame.new(8, 5, 62), Color3.fromRGB(90, 60, 30), Enum.Material.Wood)
	makeBoard("MainSign", Vector3.new(18, 5, 0.5), CFrame.new(0, 11, 62), { "BRAINROT BLITZ" }, 48)

	makeBoard("HowToBoard", Vector3.new(16, 8, 0.5), CFrame.new(-18, 4.5, 48), {
		"HOW TO PLAY",
		"BUY brainrots - EARN $/sec",
		"STEAL rivals - LOCK your base",
		"SURVIVE the tsunami",
		"REBIRTH x1.25 - GOLDEN HOUR 2x",
	}, 26)

	local nextBoard = makeBoard("NextTierBoard", Vector3.new(12, 4, 0.5), CFrame.new(-10, 3, 10), { "NEXT: COMMON - Sir Quackington - $5/s - BUY $50" }, 24)
	nextBoard.Parent = workspace

	local treeSpots = { Vector3.new(70, 0, 70), Vector3.new(-70, 0, 70), Vector3.new(70, 0, -70), Vector3.new(-70, 0, -70), Vector3.new(0, 0, -70), Vector3.new(-70, 0, 0), Vector3.new(70, 0, 20), Vector3.new(-70, 0, -20), Vector3.new(20, 0, -70), Vector3.new(-20, 0, 70) }
	for _, spot in ipairs(treeSpots) do
		makePart("Trunk", Vector3.new(2, 8, 2), CFrame.new(spot.X, 4, spot.Z), Color3.fromRGB(120, 70, 30), Enum.Material.Wood)
		local leaves = makePart("Leaves", Vector3.new(7, 7, 7), CFrame.new(spot.X, 10, spot.Z), Color3.fromRGB(40, 160, 60), Enum.Material.SmoothPlastic)
		leaves.Shape = Enum.PartType.Ball
	end

	local lampSpots = { Vector3.new(20, 0, 20), Vector3.new(-20, 0, 20), Vector3.new(20, 0, -20), Vector3.new(-20, 0, -20), Vector3.new(0, 0, 30), Vector3.new(0, 0, -30), Vector3.new(30, 0, 0), Vector3.new(-30, 0, 0) }
	for _, spot in ipairs(lampSpots) do
		makePart("LampPole", Vector3.new(1, 9, 1), CFrame.new(spot.X, 4.5, spot.Z), Color3.fromRGB(60, 60, 60), Enum.Material.Metal)
		local lampHead = makePart("LampHead", Vector3.new(2, 1, 2), CFrame.new(spot.X, 9.5, spot.Z), Color3.fromRGB(255, 240, 150), Enum.Material.Neon)
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 240, 150)
		light.Range = 18
		light.Brightness = 1
		light.Parent = lampHead
	end

	for i = 1, 6 do
		local cloud = makePart("Cloud" .. i, Vector3.new(24, 3, 12), CFrame.new(-80 + i * 30, 45 + (i % 3) * 5, -60 + (i % 2) * 100), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
		cloud.Transparency = 0.15
	end

	local wall = makePart("TsunamiWall", Vector3.new(170, 30, 2), CFrame.new(-95, 15, 0), Color3.fromRGB(60, 140, 255), Enum.Material.Glass)
	wall.Transparency = 1
	return wall
end

local function setupRemotes()
	local remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
	for _, name in ipairs({ "LockEvent", "RebirthEvent", "HudEvent" }) do
		local ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = remotes
	end
	local gs = Instance.new("Folder")
	gs.Name = "GameState"
	gs.Parent = ReplicatedStorage
	gs:SetAttribute("WaveTimer", Config.WAVE_EVERY)
	gs:SetAttribute("WavePhase", "calm")
	gs:SetAttribute("GoldenLeft", 0)
	gs:SetAttribute("MythicLeft", 0)
end

local wallPart = buildWorld()
setupRemotes()

local remotes = ReplicatedStorage:WaitForChild("Remotes")
remotes:WaitForChild("LockEvent").OnServerEvent:Connect(function(player)
	Steal.lockBase(player)
end)
remotes:WaitForChild("RebirthEvent").OnServerEvent:Connect(function(player)
	Rebirth.applyRebirth(player)
end)

Players.PlayerAdded:Connect(function(player)
	Economy.addPlayer(player)
end)
Players.PlayerRemoving:Connect(function(player)
	Economy.removePlayer(player)
end)
for _, player in ipairs(Players:GetPlayers()) do
	Economy.addPlayer(player)
end

Slap.hookSpawns()
Conveyor.start()
Wave.startLoop(wallPart)
Steal.startDeliveryLoop()
task.spawn(Economy.collectIncome)

print("Brainrot Blitz server ready: 16 brainrots, 8 bases, conveyor live.")
