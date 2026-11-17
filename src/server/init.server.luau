-- init.server: builds the Brainrot Blitz world, wires every module, runs the game loops.
-- Rojo-first: the whole 3D world is built here at runtime, so the place file stays small
-- while the running game is dense: plaza, red-carpet conveyor, 8 bases, trees, lamps,
-- fences, clouds, signs, a rival dummy, and the tsunami wall.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Config = require(ReplicatedStorage.Shared.Config)
local Conveyor = require(script.Parent.Conveyor)
local Economy = require(script.Parent.Economy)
local Wave = require(script.Parent.Wave)
local Steal = require(script.Parent.Steal)
local Rebirth = require(script.Parent.Rebirth)
local Slap = require(script.Parent.Slap)

local BASE_CENTERS = {
	Vector3.new(28, 0, 60), Vector3.new(-28, 0, 60),
	Vector3.new(84, 0, 60), Vector3.new(-84, 0, 60),
	Vector3.new(28, 0, -60), Vector3.new(-28, 0, -60),
	Vector3.new(84, 0, -60), Vector3.new(-84, 0, -60),
}
local BASE_COLORS = {
	Color3.fromRGB(60, 200, 80), Color3.fromRGB(60, 120, 255),
	Color3.fromRGB(255, 210, 40), Color3.fromRGB(180, 90, 255),
	Color3.fromRGB(255, 120, 40), Color3.fromRGB(255, 90, 160),
	Color3.fromRGB(40, 220, 220), Color3.fromRGB(230, 60, 60),
}

local world = nil
local bases = {}
local nextBase = 1

local function part(name, size, pos, color, material, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = pos
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.Parent = parent
	return p
end

local function surfaceText(parentPart, face, text, textSize, textColor, bgColor)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "SurfaceGui"
	gui.Face = face
	gui.AlwaysOnTop = false
	gui.Parent = parentPart
	local label = Instance.new("TextLabel")
	label.Name = "SignText"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = bgColor or Color3.fromRGB(40, 30, 20)
	label.BackgroundTransparency = 0.1
	label.Text = text
	label.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
	label.TextSize = textSize or 32
	label.TextWrapped = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
	return label
end

function buildWorld()
	world = Instance.new("Folder")
	world.Name = "World"
	world.Parent = workspace

	Lighting.ClockTime = 14
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(200, 190, 170)
	Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 160)
	Lighting.GlobalShadows = true
	Lighting.Technology = Enum.Technology.ShadowMap

	-- Green baseplate plaza
	part("Baseplate", Vector3.new(260, 2, 260), Vector3.new(0, -1, 0), Color3.fromRGB(110, 200, 90), Enum.Material.Grass, world).CanCollide = true

	-- Red carpet conveyor down the middle (z = 0), belt from x -105 to +105
	local belt = part("ConveyorBelt", Vector3.new(210, 1, 12), Vector3.new(0, 0.5, 0), Color3.fromRGB(200, 30, 40), Enum.Material.Carpet, world)
	belt.CanCollide = true
	part("BeltRailL", Vector3.new(210, 1.5, 1), Vector3.new(0, 0.75, -6.5), Color3.fromRGB(255, 215, 0), Enum.Material.Metal, world)
	part("BeltRailR", Vector3.new(210, 1.5, 1), Vector3.new(0, 0.75, 6.5), Color3.fromRGB(255, 215, 0), Enum.Material.Metal, world)
	for i = 0, 10 do
		part("BeltStripe", Vector3.new(1.5, 0.2, 12), Vector3.new(-100 + i * 20, 1.05, 0), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, world)
	end

	-- 8 base plots
	local basesFolder = Instance.new("Folder")
	basesFolder.Name = "Bases"
	basesFolder.Parent = world
	for i, center in ipairs(BASE_CENTERS) do
		local color = BASE_COLORS[i]
		local folder = Instance.new("Folder")
		folder.Name = "Base" .. tostring(i)
		folder.Parent = basesFolder
		local floor = part("BaseFloor", Vector3.new(22, 1, 22), Vector3.new(center.X, 0.5, center.Z), color, Enum.Material.SmoothPlastic, folder)
		floor.CanCollide = true
		for tx = -1, 1, 2 do
			for tz = -1, 1, 2 do
				part("BaseTile", Vector3.new(9, 0.2, 9), Vector3.new(center.X + tx * 5.5, 1.05, center.Z + tz * 5.5), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, folder)
			end
		end
		part("BaseWall", Vector3.new(22, 2, 1), Vector3.new(center.X, 1.5, center.Z - 11), color, Enum.Material.SmoothPlastic, folder)
		part("BaseWall", Vector3.new(22, 2, 1), Vector3.new(center.X, 1.5, center.Z + 11), color, Enum.Material.SmoothPlastic, folder)
		part("BaseWall", Vector3.new(1, 2, 22), Vector3.new(center.X - 11, 1.5, center.Z), color, Enum.Material.SmoothPlastic, folder)
		part("BaseWall", Vector3.new(1, 2, 22), Vector3.new(center.X + 11, 1.5, center.Z), color, Enum.Material.SmoothPlastic, folder)
		part("FlagPole", Vector3.new(0.6, 10, 0.6), Vector3.new(center.X - 9, 6, center.Z - 9), Color3.fromRGB(80, 80, 80), Enum.Material.Metal, folder)
		part("Flag", Vector3.new(4, 2.5, 0.2), Vector3.new(center.X - 6.8, 9.5, center.Z - 9), color, Enum.Material.Fabric, folder)
		local lockDome = part("LockSign", Vector3.new(22, 9, 22), Vector3.new(center.X, 5.5, center.Z), Color3.fromRGB(220, 40, 40), Enum.Material.ForceField, folder)
		lockDome.Transparency = 1
		local sign = part("BaseSign", Vector3.new(10, 3, 0.6), Vector3.new(center.X, 4, center.Z + 11.5), Color3.fromRGB(40, 30, 20), Enum.Material.Wood, folder)
		local label = surfaceText(sign, Enum.NormalId.Back, "BASE " .. tostring(i), 36, Color3.fromRGB(255, 255, 255))
		label.Name = "BaseSignText"
		bases[i] = { folder = folder, center = center, color = color, claimedBy = nil, signLabel = label }
	end

	-- Spawn at the south entrance
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = Vector3.new(0, 0.5, 100)
	spawn.Color = Color3.fromRGB(120, 200, 255)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = world

	-- HOW TO PLAY board near spawn (faces south, toward the player)
	local howTo = part("HowToBoard", Vector3.new(22, 10, 1), Vector3.new(-16, 5.5, 82), Color3.fromRGB(60, 40, 20), Enum.Material.Wood, world)
	surfaceText(howTo, Enum.NormalId.Back, "HOW TO PLAY\nBUY brainrots • EARN $/sec • STEAL rivals • LOCK your base • SURVIVE the tsunami • REBIRTH x1.25", 30, Color3.fromRGB(255, 240, 120))
	part("HowToPostL", Vector3.new(1, 5, 1), Vector3.new(-25, 2.5, 82), Color3.fromRGB(60, 40, 20), Enum.Material.Wood, world)
	part("HowToPostR", Vector3.new(1, 5, 1), Vector3.new(-7, 2.5, 82), Color3.fromRGB(60, 40, 20), Enum.Material.Wood, world)

	-- NEXT TIER board beside the conveyor
	local nextTier = part("NextTierBoard", Vector3.new(18, 7, 1), Vector3.new(34, 4, 14), Color3.fromRGB(40, 30, 60), Enum.Material.Wood, world)
	nextTier.Name = "NextTierBoard"
	local gui = Instance.new("SurfaceGui")
	gui.Name = "SurfaceGui"
	gui.Face = Enum.NormalId.Back
	gui.Parent = nextTier
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.4, 0)
	title.BackgroundTransparency = 1
	title.Text = "NEXT: EPIC — Captain Noodle — $60/s — $800"
	title.TextColor3 = Color3.fromRGB(200, 140, 255)
	title.TextSize = 26
	title.TextWrapped = true
	title.Font = Enum.Font.GothamBold
	title.Parent = gui
	local beltLine = Instance.new("TextLabel")
	beltLine.Name = "BeltLine"
	beltLine.Position = UDim2.new(0, 0, 0.45, 0)
	beltLine.Size = UDim2.new(1, 0, 0.55, 0)
	beltLine.BackgroundTransparency = 1
	beltLine.Text = "ON BELT NOW: —"
	beltLine.TextColor3 = Color3.fromRGB(255, 255, 255)
	beltLine.TextSize = 24
	beltLine.TextWrapped = true
	beltLine.Font = Enum.Font.GothamBold
	beltLine.Parent = gui

	-- Big BRAINROT BLITZ sign over the entrance (double-sided)
	part("SignPostL", Vector3.new(1.5, 14, 1.5), Vector3.new(-14, 7, 95), Color3.fromRGB(60, 40, 20), Enum.Material.Wood, world)
	part("SignPostR", Vector3.new(1.5, 14, 1.5), Vector3.new(14, 7, 95), Color3.fromRGB(60, 40, 20), Enum.Material.Wood, world)
	local bigSign = part("BigSign", Vector3.new(30, 7, 1), Vector3.new(0, 13, 95), Color3.fromRGB(200, 30, 40), Enum.Material.SmoothPlastic, world)
	surfaceText(bigSign, Enum.NormalId.Front, "BRAINROT BLITZ", 48, Color3.fromRGB(255, 230, 60), Color3.fromRGB(200, 30, 40))
	surfaceText(bigSign, Enum.NormalId.Back, "BRAINROT BLITZ", 48, Color3.fromRGB(255, 230, 60), Color3.fromRGB(200, 30, 40))

	-- Trees around the edges
	local treeSpots = { {-118, -118}, {-60, -118}, {0, -118}, {60, -118}, {118, -118}, {-118, 0}, {118, 0}, {-118, 118}, {-60, 118}, {60, 118}, {118, 118}, {0, 118} }
	for _, spot in ipairs(treeSpots) do
		part("TreeTrunk", Vector3.new(2, 7, 2), Vector3.new(spot[1], 3.5, spot[2]), Color3.fromRGB(120, 70, 30), Enum.Material.Wood, world)
		part("TreeTop", Vector3.new(7, 7, 7), Vector3.new(spot[1], 10, spot[2]), Color3.fromRGB(40, 160, 60), Enum.Material.SmoothPlastic, world)
		part("TreeTop2", Vector3.new(5, 4, 5), Vector3.new(spot[1], 14, spot[2]), Color3.fromRGB(60, 190, 80), Enum.Material.SmoothPlastic, world)
	end

	-- Lamps along the conveyor
	for _, x in ipairs({ -80, -40, 0, 40, 80 }) do
		for _, z in ipairs({ -12, 12 }) do
			part("LampPole", Vector3.new(0.8, 7, 0.8), Vector3.new(x, 3.5, z), Color3.fromRGB(60, 60, 60), Enum.Material.Metal, world)
			local bulb = part("LampBulb", Vector3.new(2, 2, 2), Vector3.new(x, 7.5, z), Color3.fromRGB(255, 240, 150), Enum.Material.Neon, world)
			local light = Instance.new("PointLight")
			light.Brightness = 1
			light.Range = 18
			light.Color = Color3.fromRGB(255, 240, 150)
			light.Parent = bulb
		end
	end

	-- Fence posts around the perimeter
	for x = -120, 120, 16 do
		part("FencePost", Vector3.new(1, 3, 1), Vector3.new(x, 1.5, -128), Color3.fromRGB(255, 255, 255), Enum.Material.Wood, world)
		part("FencePost", Vector3.new(1, 3, 1), Vector3.new(x, 1.5, 128), Color3.fromRGB(255, 255, 255), Enum.Material.Wood, world)
	end
	for z = -112, 112, 16 do
		part("FencePost", Vector3.new(1, 3, 1), Vector3.new(-128, 1.5, z), Color3.fromRGB(255, 255, 255), Enum.Material.Wood, world)
		part("FencePost", Vector3.new(1, 3, 1), Vector3.new(128, 1.5, z), Color3.fromRGB(255, 255, 255), Enum.Material.Wood, world)
	end

	-- Clouds drifting overhead
	for i, spot in ipairs({ {-80, -70}, {0, -90}, {80, -60}, {-90, 40}, {90, 50}, {-40, 90}, {50, 95}, {0, 0} }) do
		part("Cloud", Vector3.new(18, 3, 10), Vector3.new(spot[1], 42 + (i % 3) * 4, spot[2]), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, world)
	end

	-- Bushes and rocks for density
	local rng = Random.new(7)
	for _ = 1, 16 do
		local x = rng:NextNumber(-120, 120)
		local z = rng:NextNumber(-120, 120)
		if math.abs(z) > 20 and math.abs(x) < 120 then
			part("Bush", Vector3.new(4, 3, 4), Vector3.new(x, 1.5, z), Color3.fromRGB(50, 150, 70), Enum.Material.SmoothPlastic, world)
		end
	end
	for _ = 1, 10 do
		local x = rng:NextNumber(-120, 120)
		local z = rng:NextNumber(-120, 120)
		if math.abs(z) > 20 then
			part("Rock", Vector3.new(3, 2, 3), Vector3.new(x, 1, z), Color3.fromRGB(150, 150, 150), Enum.Material.Slate, world)
		end
	end

	-- Tsunami wall (hidden until a wave comes)
	local wall = part("WaveWall", Vector3.new(260, 30, 2), Vector3.new(0, 15, -130), Color3.fromRGB(60, 140, 255), Enum.Material.Glass, world)
	wall.Transparency = 1
	Wave.setWall(wall)

	-- Rival dummy in base 2 with one stealable brainrot (single-player steal demo)
	local dummy = Instance.new("Model")
	dummy.Name = "RIVAL"
	local dBody = part("Body", Vector3.new(2.4, 2.6, 1.6), Vector3.new(-28, 2.3, 60), Color3.fromRGB(200, 60, 60), Enum.Material.SmoothPlastic, dummy)
	dBody.Anchored = true
	part("Head", Vector3.new(1.7, 1.4, 1.7), Vector3.new(-28, 4.3, 60), Color3.fromRGB(240, 200, 150), Enum.Material.SmoothPlastic, dummy)
	local tag = Instance.new("BillboardGui")
	tag.Name = "Label"
	tag.Size = UDim2.fromOffset(120, 40)
	tag.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
	tag.AlwaysOnTop = true
	tag.Parent = dummy
	local tagText = Instance.new("TextLabel")
	tagText.Size = UDim2.fromScale(1, 1)
	tagText.BackgroundTransparency = 1
	tagText.Text = "RIVAL"
	tagText.TextColor3 = Color3.fromRGB(255, 80, 80)
	tagText.TextStrokeTransparency = 0
	tagText.TextScaled = true
	tagText.Font = Enum.Font.GothamBold
	tagText.Parent = tag
	dummy.PrimaryPart = dBody
	dummy.Parent = world
	local dummyBrainrot = Conveyor.buildCharacter(Config.getCharacter("Sir Quackington"), "None", 5)
	dummyBrainrot:SetAttribute("OwnerId", 999999999)
	dummyBrainrot:SetAttribute("SlotIndex", 1)
	dummyBrainrot.Parent = bases[2].folder
	dummyBrainrot:PivotTo(CFrame.new(-28 + 2.5, 2.4, 60))
end

local function setupPlayer(player)
	local base = bases[nextBase]
	if not base then
		base = bases[1]
	end
	nextBase += 1
	if nextBase > #bases then
		nextBase = 1
	end
	base.claimedBy = player
	base.signLabel.Text = "BASE — " .. player.Name
	Economy.createState(player, base.folder, base.center, base.color)
	player.CharacterAdded:Connect(function(char)
		local humanoid = char:WaitForChild("Humanoid")
		humanoid.WalkSpeed = 16
		Slap.giveTool(player)
	end)
	if player.Character then
		Slap.giveTool(player)
	end
end

local function removePlayer(player)
	local state = Economy.getState(player)
	if state then
		for _, model in ipairs(state.owned) do
			if model.Parent then
				model:Destroy()
			end
		end
		for i, base in ipairs(bases) do
			if base.claimedBy == player then
				base.claimedBy = nil
				base.signLabel.Text = "BASE " .. tostring(i)
				Steal.paintLock(state, false)
			end
		end
	end
	Economy.removeState(player)
end

local function setupRemotes()
	local remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
	for _, name in ipairs({ "Banner", "FloatText", "BuyFx", "LockBase", "Rebirth" }) do
		local ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = remotes
	end
	Economy.setRemotes(remotes)
	remotes.LockBase.OnServerEvent:Connect(function(player)
		Steal.lockBase(player)
	end)
	remotes.Rebirth.OnServerEvent:Connect(function(player)
		Rebirth.applyRebirth(player)
	end)
end

buildWorld()
setupRemotes()
Conveyor.start()
Steal.deliverCheck()
task.spawn(function()
	Wave.tick()
end)
task.spawn(function()
	while true do
		task.wait(1)
		Economy.collectIncome()
	end
end)
task.spawn(function()
	task.wait(2)
	Conveyor.spawnBrainrot()
	Conveyor.spawnBrainrot()
end)

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(removePlayer)
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end
