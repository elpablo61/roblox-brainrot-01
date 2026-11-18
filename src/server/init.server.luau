-- Brainrot Blitz server: builds the whole 3D world (plaza, red-carpet
-- conveyor, 8 base plots, trees, lamps, sign and how-to boards), creates the
-- remotes and the shared game state, then wires every module together.

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

local function newPart(name, size, color, pos, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Position = pos
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = true
	part.Parent = workspace
	return part
end

local function buildWorld()
	Lighting.ClockTime = 14
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(178, 168, 150)
	Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
	Lighting.GlobalShadows = true

	local baseplate = newPart("Baseplate", Vector3.new(512, 20, 512), Color3.fromRGB(80, 200, 80), Vector3.new(0, -10, 0), Enum.Material.Grass)
	baseplate.Locked = true

	-- Plaza tiles: a checker of light and dark green across the plaza.
	local tileParent = Instance.new("Folder")
	tileParent.Name = "PlazaTiles"
	tileParent.Parent = workspace
	for x = -78, 78, 6 do
		for z = -58, 62, 6 do
			if math.abs(z) >= 7 then
				local onBase = false
				for _, center in ipairs(Config.BASE_POSITIONS) do
					if math.abs(x - center.X) <= 10 and math.abs(z - center.Z) <= 10 then
						onBase = true
						break
					end
				end
				if not onBase then
					local tile = Instance.new("Part")
					tile.Name = "Tile"
					tile.Size = Vector3.new(5.8, 0.2, 5.8)
					tile.Color = ((x + z) / 6) % 2 == 0 and Color3.fromRGB(95, 215, 95) or Color3.fromRGB(70, 185, 70)
					tile.Material = Enum.Material.Grass
					tile.Anchored = true
					tile.CanCollide = false
					tile.Position = Vector3.new(x, 0.1, z)
					tile.Parent = tileParent
				end
			end
		end
	end

	-- Red-carpet conveyor down the middle of the plaza.
	local carpet = newPart("ConveyorCarpet", Vector3.new(150, 0.5, 10), Color3.fromRGB(200, 0, 0), Vector3.new(0, 0.75, 0), Enum.Material.Carpet)
	carpet.CanCollide = false
	for _, z in ipairs({ -5.2, 5.2 }) do
		newPart("ConveyorRail", Vector3.new(150, 0.6, 0.6), Color3.fromRGB(255, 215, 0), Vector3.new(0, 1, z), Enum.Material.Metal)
	end
	for x = -72, 72, 6 do
		local slat = newPart("ConveyorSlat", Vector3.new(1, 0.15, 10), Color3.fromRGB(150, 0, 0), Vector3.new(x, 1.05, 0), Enum.Material.Carpet)
		slat.CanCollide = false
	end

	-- Eight base plots around the edges, each with its own colour, low walls
	-- (open on the plaza side) and 16 slot markers.
	local bases = Instance.new("Folder")
	bases.Name = "Bases"
	bases.Parent = workspace
	for i, center in ipairs(Config.BASE_POSITIONS) do
		local baseColor = Config.BASE_COLORS[i]
		local baseFolder = Instance.new("Folder")
		baseFolder.Name = "Base" .. i
		baseFolder.Parent = bases
		baseFolder:SetAttribute("OwnerId", 0)
		baseFolder:SetAttribute("Center", center)
		local floor = Instance.new("Part")
		floor.Name = "Floor"
		floor.Size = Vector3.new(18, 1, 18)
		floor.Color = baseColor
		floor.Material = Enum.Material.SmoothPlastic
		floor.Anchored = true
		floor.Position = Vector3.new(center.X, 0.5, center.Z)
		floor.Parent = baseFolder
		local openSide = center.Z < 0 and 1 or -1
		for _, side in ipairs({ { -9, 0 }, { 9, 0 }, { 0, -9 * openSide } }) do
			local wall = Instance.new("Part")
			wall.Name = "Wall"
			wall.Size = side[2] == 0 and Vector3.new(0.6, 2, 18) or Vector3.new(18, 2, 0.6)
			wall.Color = baseColor
			wall.Anchored = true
			wall.Position = Vector3.new(center.X + side[1], 2, center.Z + side[2])
			wall.Parent = baseFolder
		end
		local slot = 1
		for _, ox in ipairs({ -6, -2, 2, 6 }) do
			for _, oz in ipairs({ -6, -2, 2, 6 }) do
				local marker = Instance.new("Part")
				marker.Name = "Slot" .. slot
				marker.Size = Vector3.new(3.5, 0.2, 3.5)
				marker.Color = Color3.fromRGB(255, 255, 255)
				marker.Transparency = 0.6
				marker.Anchored = true
				marker.CanCollide = false
				marker.Position = Vector3.new(center.X + ox, 1.1, center.Z + oz)
				marker.Parent = baseFolder
				slot += 1
			end
		end
		local sign = Instance.new("Part")
		sign.Name = "BaseSign"
		sign.Size = Vector3.new(8, 2, 0.5)
		sign.Color = Color3.fromRGB(30, 30, 30)
		sign.Anchored = true
		sign.Position = Vector3.new(center.X, 4.5, center.Z + openSide * -9)
		sign.Parent = baseFolder
		local signGui = Instance.new("SurfaceGui")
		signGui.Face = Enum.NormalId.Front
		signGui.Parent = sign
		local signText = Instance.new("TextLabel")
		signText.Size = UDim2.fromScale(1, 1)
		signText.BackgroundTransparency = 1
		signText.Text = "BASE " .. i
		signText.TextColor3 = Color3.fromRGB(255, 255, 255)
		signText.TextSize = 36
		signText.Font = Enum.Font.SourceSansBold
		signText.Parent = signGui
	end

	-- Trees and lamps around the plaza.
	local treeSpots = { { -84, -60 }, { -84, 60 }, { 84, -60 }, { 84, 60 }, { -40, -66 }, { 40, -66 }, { -40, 68 }, { 40, 68 }, { -88, 0 }, { 88, 0 }, { -70, -66 }, { 70, 68 } }
	for _, spot in ipairs(treeSpots) do
		local trunk = Instance.new("Part")
		trunk.Name = "TreeTrunk"
		trunk.Size = Vector3.new(1.5, 6, 1.5)
		trunk.Color = Color3.fromRGB(120, 70, 20)
		trunk.Anchored = true
		trunk.Position = Vector3.new(spot[1], 3, spot[2])
		trunk.Parent = workspace
		local leaves = Instance.new("Part")
		leaves.Name = "TreeLeaves"
		leaves.Shape = Enum.PartType.Ball
		leaves.Size = Vector3.new(7, 7, 7)
		leaves.Color = Color3.fromRGB(30, 160, 40)
		leaves.Anchored = true
		leaves.Position = Vector3.new(spot[1], 9, spot[2])
		leaves.Parent = workspace
	end
	local lampSpots = { { -20, -14 }, { 20, -14 }, { -20, 14 }, { 20, 14 }, { -55, -14 }, { 55, -14 }, { -55, 14 }, { 55, 14 } }
	for _, spot in ipairs(lampSpots) do
		local pole = Instance.new("Part")
		pole.Name = "LampPole"
		pole.Size = Vector3.new(0.6, 7, 0.6)
		pole.Color = Color3.fromRGB(40, 40, 40)
		pole.Anchored = true
		pole.Position = Vector3.new(spot[1], 3.5, spot[2])
		pole.Parent = workspace
		local head = Instance.new("Part")
		head.Name = "LampHead"
		head.Size = Vector3.new(1.6, 1, 1.6)
		head.Color = Color3.fromRGB(255, 240, 180)
		head.Material = Enum.Material.Neon
		head.Anchored = true
		head.Position = Vector3.new(spot[1], 7.2, spot[2])
		head.Parent = workspace
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 240, 180)
		light.Range = 18
		light.Brightness = 1
		light.Parent = head
	end

	-- Fence posts around the plaza edge.
	for x = -84, 84, 12 do
		for _, z in ipairs({ -66, 70 }) do
			newPart("FencePost", Vector3.new(1, 3, 1), Color3.fromRGB(200, 200, 200), Vector3.new(x, 1.5, z))
		end
	end
	for z = -66, 70, 12 do
		for _, x in ipairs({ -84, 84 }) do
			newPart("FencePost", Vector3.new(1, 3, 1), Color3.fromRGB(200, 200, 200), Vector3.new(x, 1.5, z))
		end
	end

	-- Clouds drifting high above the plaza.
	for i, cloud in ipairs({ { -50, 45, -40 }, { 30, 55, -60 }, { 70, 48, 30 }, { -60, 52, 40 }, { 0, 60, -20 }, { 10, 46, 60 } }) do
		local puff = Instance.new("Part")
		puff.Name = "Cloud"
		puff.Shape = Enum.PartType.Ball
		puff.Size = Vector3.new(22, 7, 12)
		puff.Color = Color3.fromRGB(255, 255, 255)
		puff.Material = Enum.Material.SmoothPlastic
		puff.Anchored = true
		puff.CanCollide = false
		puff.Position = Vector3.new(cloud[1], cloud[2], cloud[3])
		puff.Parent = workspace
	end

	-- Big BRAINROT BLITZ entrance sign over the spawn walkway.
	for _, x in ipairs({ -12, 12 }) do
		newPart("SignPost", Vector3.new(1.5, 12, 1.5), Color3.fromRGB(60, 60, 60), Vector3.new(x, 6, 58))
	end
	local signBoard = newPart("BlitzSign", Vector3.new(28, 6, 1), Color3.fromRGB(255, 60, 60), Vector3.new(0, 11, 58), Enum.Material.SmoothPlastic)
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Back
	signGui.Parent = signBoard
	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.fromScale(1, 1)
	signText.BackgroundTransparency = 1
	signText.Text = "BRAINROT BLITZ"
	signText.TextColor3 = Color3.fromRGB(255, 255, 255)
	signText.TextSize = 60
	signText.Font = Enum.Font.SourceSansBold
	signText.Parent = signGui

	-- HOW TO PLAY board near spawn, readable in the cover shot.
	local howBoard = newPart("HowToBoard", Vector3.new(16, 9, 0.6), Color3.fromRGB(120, 70, 20), Vector3.new(16, 4.5, 56))
	local howGui = Instance.new("SurfaceGui")
	howGui.Face = Enum.NormalId.Front
	howGui.Parent = howBoard
	local howText = Instance.new("TextLabel")
	howText.Size = UDim2.fromScale(1, 1)
	howText.BackgroundColor3 = Color3.fromRGB(255, 250, 220)
	howText.TextColor3 = Color3.fromRGB(20, 20, 20)
	howText.TextSize = 26
	howText.Font = Enum.Font.SourceSansBold
	howText.TextWrapped = true
	howText.Text = "HOW TO PLAY\nBUY brainrots - EARN $/sec\nSTEAL rivals - LOCK your base\nSURVIVE the tsunami\nREBIRTH x1.25"
	howText.Parent = howGui

	-- NEXT TIER board beside the conveyor.
	local nextBoard = newPart("NextTierBoard", Vector3.new(14, 7, 0.6), Color3.fromRGB(40, 40, 90), Vector3.new(-32, 3.5, -9))
	local nextGui = Instance.new("SurfaceGui")
	nextGui.Face = Enum.NormalId.Front
	nextGui.Parent = nextBoard
	local nextText = Instance.new("TextLabel")
	nextText.Size = UDim2.fromScale(1, 1)
	nextText.BackgroundColor3 = Color3.fromRGB(20, 20, 50)
	nextText.TextColor3 = Color3.fromRGB(255, 220, 0)
	nextText.TextSize = 26
	nextText.Font = Enum.Font.SourceSansBold
	nextText.TextWrapped = true
	nextText.Text = "NEXT TIER\nEPIC - Captain Noodle\n$60/s - BUY $800\nON THE BELT!"
	nextText.Parent = nextGui

	-- Spawn at the entrance, facing the plaza.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Color = Color3.fromRGB(80, 220, 120)
	spawn.Anchored = true
	spawn.Position = Vector3.new(0, 0.5, 66)
	spawn.Parent = workspace
end

local function setupRemotes()
	local remotes = Instance.new("Folder")
	remotes.Name = "BrainrotRemotes"
	remotes.Parent = ReplicatedStorage
	for _, name in ipairs({ "Banner", "LockRequest", "RebirthRequest" }) do
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = remotes
	end
	local gs = Instance.new("Folder")
	gs.Name = "GameState"
	gs.Parent = ReplicatedStorage
	gs:SetAttribute("WaveTimer", Config.WAVE_INTERVAL)
	gs:SetAttribute("WavePhase", "calm")
	gs:SetAttribute("GoldenLeft", 0)
	gs:SetAttribute("MythicLeft", 0)
end

buildWorld()
setupRemotes()

local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")
remotes:WaitForChild("LockRequest").OnServerEvent:Connect(function(player)
	Steal.lockBase(player)
end)

Economy.start()
Conveyor.start()
Wave.start()
Steal.start()
Rebirth.start()
Slap.start()

print("Brainrot Blitz server ready: 16 brainrots, 8 bases, conveyor live.")
