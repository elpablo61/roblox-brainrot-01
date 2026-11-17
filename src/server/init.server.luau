-- Brainrot Blitz server init: builds the whole 3D world, creates the remotes
-- and the shared game state, then wires every module together.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local buildBaseplate
local buildPlazaTiles
local buildConveyor
local buildBase
local buildTrees
local buildLamps
local buildFence
local buildClouds
local buildSign
local buildBoards
local buildSpawn
local makeBoardText

function buildWorld()
	Lighting.ClockTime = 14
	Lighting.Brightness = 3
	Lighting.Ambient = Color3.fromRGB(200, 200, 200)
	Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
	Lighting.GlobalShadows = true
	buildBaseplate()
	buildPlazaTiles()
	buildConveyor()
	for i, base in ipairs(Config.BASES) do
		buildBase(i, base)
	end
	buildTrees()
	buildLamps()
	buildFence()
	buildClouds()
	buildSign()
	buildBoards()
	buildSpawn()
end

buildBaseplate = function()
	local plate = Instance.new("Part")
	plate.Name = "Baseplate"
	plate.Size = Vector3.new(400, 4, 400)
	plate.Position = Vector3.new(0, -2, 0)
	plate.Color = Color3.fromRGB(90, 200, 90)
	plate.Material = Enum.Material.Grass
	plate.Anchored = true
	plate.Locked = true
	plate.Parent = workspace
end

buildPlazaTiles = function()
	for gx = 1, 20 do
		for gz = 1, 20 do
			local tile = Instance.new("Part")
			tile.Name = "PlazaTile"
			tile.Size = Vector3.new(4, 0.2, 4)
			tile.Position = Vector3.new((gx - 10.5) * 4, 0.1, (gz - 10.5) * 4)
			if (gx + gz) % 2 == 0 then
				tile.Color = Color3.fromRGB(120, 220, 120)
			else
				tile.Color = Color3.fromRGB(100, 200, 100)
			end
			tile.Material = Enum.Material.SmoothPlastic
			tile.Anchored = true
			tile.CanCollide = false
			tile.Parent = workspace
		end
	end
end

buildConveyor = function()
	local carpet = Instance.new("Part")
	carpet.Name = "ConveyorCarpet"
	carpet.Size = Vector3.new(14, 1, 124)
	carpet.Position = Vector3.new(0, 0.5, 0)
	carpet.Color = Color3.fromRGB(200, 30, 40)
	carpet.Material = Enum.Material.Carpet
	carpet.Anchored = true
	carpet.Parent = workspace
	local railL = Instance.new("Part")
	railL.Name = "ConveyorRailL"
	railL.Size = Vector3.new(1, 2, 124)
	railL.Position = Vector3.new(-7.5, 1, 0)
	railL.Color = Color3.fromRGB(255, 215, 0)
	railL.Material = Enum.Material.Metal
	railL.Anchored = true
	railL.Parent = workspace
	local railR = railL:Clone()
	railR.Name = "ConveyorRailR"
	railR.Position = Vector3.new(7.5, 1, 0)
	railR.Parent = workspace
	local startPad = Instance.new("Part")
	startPad.Name = "ConveyorStart"
	startPad.Size = Vector3.new(14, 0.4, 4)
	startPad.Position = Vector3.new(0, 1.1, -62)
	startPad.Color = Color3.fromRGB(255, 215, 0)
	startPad.Anchored = true
	startPad.Parent = workspace
	local endPad = startPad:Clone()
	endPad.Name = "ConveyorEnd"
	endPad.Position = Vector3.new(0, 1.1, 62)
	endPad.Parent = workspace
end

buildBase = function(index, base)
	local color = Config.BASE_COLORS[index]
	local floor = Instance.new("Part")
	floor.Name = "BaseFloor" .. index
	floor.Size = Vector3.new(22, 1, 22)
	floor.Position = Vector3.new(base.x, 0.5, base.z)
	floor.Color = color
	floor.Transparency = 0.35
	floor.Material = Enum.Material.SmoothPlastic
	floor.Anchored = true
	floor.Parent = workspace
	for _, offset in ipairs({ -11, 11 }) do
		local wallX = Instance.new("Part")
		wallX.Name = "BaseWall"
		wallX.Size = Vector3.new(22, 3, 1)
		wallX.Position = Vector3.new(base.x, 1.5, base.z + offset)
		wallX.Color = color
		wallX.Anchored = true
		wallX.Parent = workspace
		local wallZ = Instance.new("Part")
		wallZ.Name = "BaseWall"
		wallZ.Size = Vector3.new(1, 3, 22)
		wallZ.Position = Vector3.new(base.x + offset, 1.5, base.z)
		wallZ.Color = color
		wallZ.Anchored = true
		wallZ.Parent = workspace
	end
	for tx = 1, 4 do
		for tz = 1, 4 do
			local tile = Instance.new("Part")
			tile.Name = "BaseTile"
			tile.Size = Vector3.new(4, 0.2, 4)
			tile.Position = Vector3.new(base.x - 7.5 + (tx - 1) * 5, 1.1, base.z - 7.5 + (tz - 1) * 5)
			tile.Color = Color3.fromRGB(255, 255, 255)
			tile.Transparency = 0.5
			tile.Anchored = true
			tile.CanCollide = false
			tile.Parent = workspace
		end
	end
	local signPost = Instance.new("Part")
	signPost.Name = "BaseSignPost"
	signPost.Size = Vector3.new(1, 6, 1)
	signPost.Position = Vector3.new(base.x, 3, base.z - 11)
	signPost.Color = Color3.fromRGB(100, 70, 40)
	signPost.Anchored = true
	signPost.Parent = workspace
	local sign = Instance.new("Part")
	sign.Name = "BaseSign" .. index
	sign.Size = Vector3.new(10, 4, 0.5)
	sign.Position = Vector3.new(base.x, 7, base.z - 11)
	sign.Color = color
	sign.Anchored = true
	sign.Parent = workspace
	makeBoardText(sign, "BASE " .. index, 36, Color3.fromRGB(255, 255, 255))
end

buildTrees = function()
	for i = 1, 20 do
		local angle = (i / 20) * math.pi * 2
		local radius = 88 + (i % 3) * 8
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		local trunk = Instance.new("Part")
		trunk.Name = "TreeTrunk"
		trunk.Size = Vector3.new(2, 8, 2)
		trunk.Position = Vector3.new(x, 4, z)
		trunk.Color = Color3.fromRGB(120, 70, 30)
		trunk.Anchored = true
		trunk.Parent = workspace
		local leaves = Instance.new("Part")
		leaves.Name = "TreeLeaves"
		leaves.Shape = Enum.PartType.Ball
		leaves.Size = Vector3.new(9, 9, 9)
		leaves.Position = Vector3.new(x, 11, z)
		leaves.Color = Color3.fromRGB(40, 160, 50)
		leaves.Anchored = true
		leaves.Parent = workspace
		local top = Instance.new("Part")
		top.Name = "TreeTop"
		top.Shape = Enum.PartType.Ball
		top.Size = Vector3.new(6, 6, 6)
		top.Position = Vector3.new(x, 15, z)
		top.Color = Color3.fromRGB(60, 190, 70)
		top.Anchored = true
		top.Parent = workspace
	end
	for i = 1, 24 do
		local angle = (i / 24) * math.pi * 2 + 0.3
		local radius = 78 + (i % 4) * 6
		local bush = Instance.new("Part")
		bush.Name = "Bush"
		bush.Shape = Enum.PartType.Ball
		bush.Size = Vector3.new(4, 3, 4)
		bush.Position = Vector3.new(math.cos(angle) * radius, 1.5, math.sin(angle) * radius)
		bush.Color = Color3.fromRGB(50, 180, 60)
		bush.Anchored = true
		bush.Parent = workspace
	end
end

buildLamps = function()
	for i = 1, 12 do
		local angle = (i / 12) * math.pi * 2
		local x = math.cos(angle) * 46
		local z = math.sin(angle) * 46
		local pole = Instance.new("Part")
		pole.Name = "LampPole"
		pole.Size = Vector3.new(1, 9, 1)
		pole.Position = Vector3.new(x, 4.5, z)
		pole.Color = Color3.fromRGB(60, 60, 60)
		pole.Anchored = true
		pole.Parent = workspace
		local bulb = Instance.new("Part")
		bulb.Name = "LampBulb"
		bulb.Shape = Enum.PartType.Ball
		bulb.Size = Vector3.new(2.5, 2.5, 2.5)
		bulb.Position = Vector3.new(x, 9.5, z)
		bulb.Color = Color3.fromRGB(255, 240, 150)
		bulb.Material = Enum.Material.Neon
		bulb.Anchored = true
		bulb.Parent = workspace
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 230, 150)
		light.Range = 18
		light.Brightness = 1
		light.Parent = bulb
	end
end

buildFence = function()
	for i = 0, 35 do
		local t = (i / 36) * 360
		local x = 0
		local z = 0
		if t < 90 then
			x = -90 + t * 2
			z = -90
		elseif t < 180 then
			x = 90
			z = -90 + (t - 90) * 2
		elseif t < 270 then
			x = 90 - (t - 180) * 2
			z = 90
		else
			x = -90
			z = 90 - (t - 270) * 2
		end
		local post = Instance.new("Part")
		post.Name = "FencePost"
		post.Size = Vector3.new(1, 4, 1)
		post.Position = Vector3.new(x, 2, z)
		post.Color = Color3.fromRGB(255, 255, 255)
		post.Anchored = true
		post.Parent = workspace
	end
end

buildClouds = function()
	for i = 1, 8 do
		local cloud = Instance.new("Part")
		cloud.Name = "Cloud"
		cloud.Size = Vector3.new(18, 4, 10)
		cloud.Position = Vector3.new(-80 + i * 22, 42 + (i % 3) * 4, -70 + (i % 4) * 35)
		cloud.Color = Color3.fromRGB(255, 255, 255)
		cloud.Transparency = 0.15
		cloud.Anchored = true
		cloud.CanCollide = false
		cloud.Parent = workspace
	end
end

buildSign = function()
	local postL = Instance.new("Part")
	postL.Name = "SignPostL"
	postL.Size = Vector3.new(1.5, 12, 1.5)
	postL.Position = Vector3.new(-11, 6, -85)
	postL.Color = Color3.fromRGB(100, 70, 40)
	postL.Anchored = true
	postL.Parent = workspace
	local postR = postL:Clone()
	postR.Name = "SignPostR"
	postR.Position = Vector3.new(11, 6, -85)
	postR.Parent = workspace
	local board = Instance.new("Part")
	board.Name = "EntranceSign"
	board.Size = Vector3.new(26, 9, 1)
	board.Position = Vector3.new(0, 12, -85)
	board.Color = Color3.fromRGB(255, 200, 0)
	board.Anchored = true
	board.Parent = workspace
	makeBoardText(board, "BRAINROT BLITZ", 48, Color3.fromRGB(160, 30, 30))
end

buildBoards = function()
	local howTo = Instance.new("Part")
	howTo.Name = "HowToBoard"
	howTo.Size = Vector3.new(18, 9, 1)
	howTo.Position = Vector3.new(-26, 5, -68)
	howTo.Color = Color3.fromRGB(120, 80, 40)
	howTo.Anchored = true
	howTo.Parent = workspace
	makeBoardText(howTo, "HOW TO PLAY: BUY brainrots - EARN $/sec - STEAL rivals - LOCK your base - SURVIVE the tsunami - REBIRTH x1.25", 28, Color3.fromRGB(255, 255, 255))
	local nextTier = Instance.new("Part")
	nextTier.Name = "NextTierBoard"
	nextTier.Size = Vector3.new(16, 7, 1)
	nextTier.Position = Vector3.new(16, 4, -42)
	nextTier.Color = Color3.fromRGB(40, 40, 60)
	nextTier.Anchored = true
	nextTier.Parent = workspace
	makeBoardText(nextTier, "NEXT TIER: RARE - Professor Pickle - $20/s - $250", 26, Color3.fromRGB(255, 220, 60))
end

buildSpawn = function()
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(0, 0.5, -78)
	spawn.Color = Color3.fromRGB(120, 220, 120)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Parent = workspace
end

makeBoardText = function(part, text, textSize, textColor)
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local gui = Instance.new("SurfaceGui")
		gui.Name = "BoardGui"
		gui.Face = face
		gui.AlwaysOnTop = false
		gui.Parent = part
		local label = Instance.new("TextLabel")
		label.Name = "BoardText"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = textColor
		label.TextStrokeTransparency = 0
		label.TextSize = textSize
		label.TextWrapped = true
		label.Font = Enum.Font.GothamBold
		label.Parent = gui
	end
end

-- Build the world first, then the remotes, then wire the modules.
buildWorld()

local gameState = Instance.new("Folder")
gameState.Name = "GameState"
gameState:SetAttribute("WaveTime", Config.WAVE_INTERVAL)
gameState:SetAttribute("WaveState", "countdown")
gameState:SetAttribute("GoldenActive", false)
gameState:SetAttribute("MythicActive", false)
gameState:SetAttribute("NextTier", "Professor Pickle")
gameState.Parent = ReplicatedStorage

local notify = Instance.new("RemoteEvent")
notify.Name = "BrainrotNotify"
notify.Parent = ReplicatedStorage

local lockRequest = Instance.new("RemoteEvent")
lockRequest.Name = "LockRequest"
lockRequest.Parent = ReplicatedStorage

local rebirthRequest = Instance.new("RemoteEvent")
rebirthRequest.Name = "RebirthRequest"
rebirthRequest.Parent = ReplicatedStorage

local Conveyor = require(script.Conveyor)
local Economy = require(script.Economy)
local Wave = require(script.Wave)
local Steal = require(script.Steal)
local Rebirth = require(script.Rebirth)
local Slap = require(script.Slap)

lockRequest.OnServerEvent:Connect(function(player)
	Steal.lockBase(player)
end)

rebirthRequest.OnServerEvent:Connect(function(player)
	Rebirth.applyRebirth(player)
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		Economy.refreshAttributes(player)
	end)
end)

Economy.start()
Conveyor.start()
Wave.start()
Steal.start()
Slap.start()

print("Brainrot Blitz server ready: 16 brainrots, 8 bases, conveyor live.")
