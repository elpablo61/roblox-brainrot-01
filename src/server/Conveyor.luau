-- Conveyor: spawns brainrots on the red carpet, walks them along it, despawns at the end.
-- A Mythic or Secret spawn fires a server-wide banner and a 60s 2x income window (A19).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local Conveyor = {}
local rng = Random.new()
local beltModels = {}
local mythicWindowUntil = 0
local beltFolder = nil
local beltStartX = -100
local beltEndX = 100
local beltZ = 0
local beltY = 2.4

function Conveyor.spawnBrainrot(forceRarity)
	local rarity = forceRarity or Config.rollRarity(rng)
	local pool = Config.getCharactersByRarity(rarity)
	if #pool == 0 then
		pool = Config.getCharactersByRarity("Common")
	end
	local def = pool[rng:NextInteger(1, #pool)]
	local mutation = Config.rollMutation(rng)
	if forceRarity then
		mutation = "None"
	end
	local rate = Config.effectiveRate(def, mutation)
	local model = Conveyor.buildCharacter(def, mutation, rate)
	model:SetAttribute("CharName", def.name)
	model:SetAttribute("Rarity", rarity)
	model:SetAttribute("Rate", rate)
	model:SetAttribute("Price", def.price)
	model:SetAttribute("Mutation", mutation)
	model:SetAttribute("OwnerId", 0)
	model.Parent = beltFolder
	model:PivotTo(CFrame.new(beltStartX, beltY, beltZ))
	table.insert(beltModels, model)
	Conveyor.updateNextTierBoard(def, mutation, rate)
	if rarity == "Mythic" or rarity == "Secret" then
		mythicWindowUntil = os.time() + Config.mythicWindowDuration
		local banner = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Banner")
		banner:FireAllClients("MYTHIC SPAWNED: " .. def.name .. " — 2x INCOME 60s!", "Gold")
	end
	return model
end

function Conveyor.isMythicWindowActive()
	return os.time() < mythicWindowUntil
end

function Conveyor.buildCharacter(def, mutation, rate)
	local model = Instance.new("Model")
	model.Name = def.name
	local tint = Config.mutations[mutation] and Config.mutations[mutation].color
	local bodyColor = tint or def.body
	local headColor = tint or def.head

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(2.4, 2.2, 2.2)
	body.Color = bodyColor
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.7, 1.4, 1.7)
	head.Position = Vector3.new(0, 1.8, 0)
	head.Color = headColor
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.Parent = model

	Conveyor.buildAccessory(model, def.accessory)

	local label = Instance.new("BillboardGui")
	label.Name = "Label"
	label.Size = UDim2.fromOffset(240, 96)
	label.StudsOffsetWorldSpace = Vector3.new(0, 3.4, 0)
	label.AlwaysOnTop = true
	label.Parent = model

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, 0, 0.34, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = def.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = label

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "Rarity"
	rarityLabel.Position = UDim2.new(0, 0, 0.34, 0)
	rarityLabel.Size = UDim2.new(1, 0, 0.3, 0)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = string.upper(def.rarity) .. (mutation ~= "None" and (" • " .. string.upper(mutation) .. " x" .. tostring(Config.mutations[mutation].multiplier)) or "")
	rarityLabel.TextColor3 = Config.rarities[def.rarity].color
	rarityLabel.TextStrokeTransparency = 0
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.Parent = label

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "Rate"
	rateLabel.Position = UDim2.new(0, 0, 0.64, 0)
	rateLabel.Size = UDim2.new(1, 0, 0.36, 0)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = "$" .. tostring(rate) .. "/s  •  BUY $" .. tostring(def.price)
	rateLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
	rateLabel.TextStrokeTransparency = 0
	rateLabel.TextScaled = true
	rateLabel.Font = Enum.Font.GothamBold
	rateLabel.Parent = label

	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 40
	click.Parent = model
	click.MouseClick:Connect(function(player)
		local Economy = require(script.Parent.Economy)
		if Economy.buyBrainrot(player, model) then
			Conveyor.removeFromBelt(model)
		end
	end)

	model.PrimaryPart = body
	return model
end

function Conveyor.buildAccessory(model, kind)
	local function part(name, size, pos, color)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Position = pos
		p.Color = color
		p.Material = Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.Parent = model
		return p
	end
	if kind == "TopHat" then
		part("HatTop", Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 3.1, 0), Color3.fromRGB(30, 30, 30))
		part("HatBrim", Vector3.new(2.2, 0.2, 2.2), Vector3.new(0, 2.55, 0), Color3.fromRGB(30, 30, 30))
	elseif kind == "SailorHat" then
		part("HatTop", Vector3.new(1.6, 0.5, 1.6), Vector3.new(0, 2.7, 0), Color3.fromRGB(255, 255, 255))
		part("HatBand", Vector3.new(1.7, 0.25, 1.7), Vector3.new(0, 2.5, 0), Color3.fromRGB(40, 90, 200))
	elseif kind == "Sneakers" then
		part("ShoeL", Vector3.new(0.9, 0.5, 1.4), Vector3.new(-0.6, -1.2, 0.4), Color3.fromRGB(255, 255, 255))
		part("ShoeR", Vector3.new(0.9, 0.5, 1.4), Vector3.new(0.6, -1.2, 0.4), Color3.fromRGB(255, 80, 80))
	elseif kind == "Glasses" then
		part("LensL", Vector3.new(0.6, 0.6, 0.15), Vector3.new(-0.45, 1.9, 0.9), Color3.fromRGB(20, 20, 20))
		part("LensR", Vector3.new(0.6, 0.6, 0.15), Vector3.new(0.45, 1.9, 0.9), Color3.fromRGB(20, 20, 20))
		part("Bridge", Vector3.new(0.4, 0.12, 0.12), Vector3.new(0, 1.9, 0.9), Color3.fromRGB(20, 20, 20))
	elseif kind == "Sunglasses" then
		part("LensL", Vector3.new(0.7, 0.5, 0.15), Vector3.new(-0.45, 1.95, 0.9), Color3.fromRGB(10, 10, 10))
		part("LensR", Vector3.new(0.7, 0.5, 0.15), Vector3.new(0.45, 1.95, 0.9), Color3.fromRGB(10, 10, 10))
	elseif kind == "Headphones" then
		part("CupL", Vector3.new(0.4, 0.9, 0.9), Vector3.new(-0.95, 1.9, 0), Color3.fromRGB(200, 40, 120))
		part("CupR", Vector3.new(0.4, 0.9, 0.9), Vector3.new(0.95, 1.9, 0), Color3.fromRGB(200, 40, 120))
		part("Band", Vector3.new(2.2, 0.25, 0.4), Vector3.new(0, 2.55, 0), Color3.fromRGB(200, 40, 120))
	elseif kind == "PirateHat" then
		part("HatMain", Vector3.new(2.4, 0.5, 1.4), Vector3.new(0, 2.6, 0), Color3.fromRGB(25, 25, 25))
		part("HatPeak", Vector3.new(1.0, 0.9, 1.0), Vector3.new(0, 3.0, 0), Color3.fromRGB(25, 25, 25))
	elseif kind == "BowlHat" then
		local bowl = part("Bowl", Vector3.new(1.9, 0.7, 1.9), Vector3.new(0, 2.7, 0), Color3.fromRGB(255, 255, 255))
		bowl.Shape = Enum.PartType.Cylinder
		bowl.Rotation = Vector3.new(0, 0, 90)
		part("Noodle1", Vector3.new(0.3, 0.8, 0.3), Vector3.new(-0.4, 3.1, 0), Color3.fromRGB(255, 220, 120))
		part("Noodle2", Vector3.new(0.3, 0.8, 0.3), Vector3.new(0.4, 3.1, 0), Color3.fromRGB(255, 220, 120))
	elseif kind == "Crown" then
		part("CrownBase", Vector3.new(1.6, 0.4, 1.6), Vector3.new(0, 2.6, 0), Color3.fromRGB(255, 215, 0))
		part("Spike1", Vector3.new(0.3, 0.7, 0.3), Vector3.new(-0.6, 3.0, 0), Color3.fromRGB(255, 215, 0))
		part("Spike2", Vector3.new(0.3, 0.9, 0.3), Vector3.new(0, 3.1, 0), Color3.fromRGB(255, 215, 0))
		part("Spike3", Vector3.new(0.3, 0.7, 0.3), Vector3.new(0.6, 3.0, 0), Color3.fromRGB(255, 215, 0))
	elseif kind == "Bowtie" then
		part("TieL", Vector3.new(0.7, 0.5, 0.3), Vector3.new(-0.45, 0.6, 1.15), Color3.fromRGB(200, 30, 30))
		part("TieR", Vector3.new(0.7, 0.5, 0.3), Vector3.new(0.45, 0.6, 1.15), Color3.fromRGB(200, 30, 30))
	end
end

function Conveyor.updateNextTierBoard(def, mutation, rate)
	local board = workspace:FindFirstChild("World")
	if not board then
		return
	end
	local nextTier = board:FindFirstChild("NextTierBoard")
	if not nextTier then
		return
	end
	local gui = nextTier:FindFirstChild("SurfaceGui")
	if not gui then
		return
	end
	local line = gui:FindFirstChild("BeltLine")
	if line then
		line.Text = "ON BELT NOW: " .. def.name .. " • " .. string.upper(def.rarity) .. " • $" .. tostring(rate) .. "/s • $" .. tostring(def.price)
	end
end

function Conveyor.removeFromBelt(model)
	for i, m in ipairs(beltModels) do
		if m == model then
			table.remove(beltModels, i)
			return true
		end
	end
	return false
end

function Conveyor.start()
	beltFolder = Instance.new("Folder")
	beltFolder.Name = "Brainrots"
	beltFolder.Parent = workspace
	task.spawn(function()
		while true do
			task.wait(Config.spawnInterval)
			if #beltModels < Config.maxOnBelt then
				Conveyor.spawnBrainrot()
			end
		end
	end)
	RunService.Heartbeat:Connect(function(dt)
		local step = Config.beltSpeed * dt
		for i = #beltModels, 1, -1 do
			local model = beltModels[i]
			if not model.Parent then
				table.remove(beltModels, i)
			else
				local cf = model:GetPivot()
				local bob = math.sin(os.clock() * 4 + i) * 0.15
				local nx = cf.Position.X + step
				if nx >= beltEndX then
					model:Destroy()
					table.remove(beltModels, i)
				else
					model:PivotTo(CFrame.new(nx, beltY + bob, beltZ))
				end
			end
		end
	end)
end

return Conveyor
