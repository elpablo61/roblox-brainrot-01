-- Conveyor: spawns brainrots on the red carpet, walks them down the belt,
-- despawns them at the end. Clicking one buys it, or steals it if owned.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Conveyor = {}
Conveyor.live = {}

function Conveyor.spawnBrainrot()
	local char = Conveyor.pickCharacter()
	local mutation = Conveyor.rollMutation()
	local rate = char.rate * mutation.mult
	local model = Conveyor.buildCharacterModel(char, mutation, rate)
	model:SetAttribute("CharName", char.name)
	model:SetAttribute("Rarity", char.rarity)
	model:SetAttribute("Rate", rate)
	model:SetAttribute("Price", char.price)
	model:SetAttribute("Mutation", mutation.name)
	model:SetAttribute("OwnerId", 0)
	model:PivotTo(CFrame.new(0, 0, Config.BELT_START_Z))
	model.Parent = workspace
	table.insert(Conveyor.live, { model = model, progress = 0, char = char, mutation = mutation, rate = rate })
	Conveyor.wireClick(model)
	if char.rarity == "Mythic" or char.rarity == "Secret" then
		Conveyor.announceMythicSpawn(char, mutation, rate)
	end
	return model
end

function Conveyor.pickCharacter()
	local total = 0
	for _, char in ipairs(Config.CHARACTERS) do
		total += Config.RARITIES[char.rarity].weight
	end
	local roll = math.random() * total
	for _, char in ipairs(Config.CHARACTERS) do
		roll -= Config.RARITIES[char.rarity].weight
		if roll <= 0 then
			return char
		end
	end
	return Config.CHARACTERS[1]
end

function Conveyor.rollMutation()
	local roll = math.random(100)
	local acc = 0
	for _, mut in ipairs(Config.MUTATIONS) do
		acc += mut.chance
		if roll <= acc then
			return mut
		end
	end
	return Config.MUTATIONS[1]
end

function Conveyor.buildCharacterModel(char, mutation, rate)
	local model = Instance.new("Model")
	model.Name = char.name
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3, 3, 2)
	body.Position = Vector3.new(0, 2, 0)
	body.Color = char.body
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.Parent = model
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(2.2, 2.2, 2.2)
	head.Position = Vector3.new(0, 4.6, 0)
	head.Color = char.head
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.Parent = model
	local eyeL = Instance.new("Part")
	eyeL.Name = "EyeL"
	eyeL.Size = Vector3.new(0.35, 0.5, 0.2)
	eyeL.Position = Vector3.new(-0.5, 4.8, 1.1)
	eyeL.Color = Color3.fromRGB(20, 20, 20)
	eyeL.Anchored = true
	eyeL.Parent = model
	local eyeR = eyeL:Clone()
	eyeR.Name = "EyeR"
	eyeR.Position = Vector3.new(0.5, 4.8, 1.1)
	eyeR.Parent = model
	local footL = Instance.new("Part")
	footL.Name = "FootL"
	footL.Size = Vector3.new(1, 0.6, 1.4)
	footL.Position = Vector3.new(-0.8, 0.3, 0)
	footL.Color = Color3.fromRGB(40, 40, 40)
	footL.Anchored = true
	footL.Parent = model
	local footR = footL:Clone()
	footR.Name = "FootR"
	footR.Position = Vector3.new(0.8, 0.3, 0)
	footR.Parent = model
	Conveyor.buildAccessory(model, char.accessory)
	if mutation.name ~= "None" then
		local tint = Instance.new("Part")
		tint.Name = "MutationGlow"
		tint.Size = Vector3.new(3.4, 3.4, 2.4)
		tint.Position = Vector3.new(0, 2, 0)
		tint.Color = mutation.color
		tint.Transparency = 0.7
		tint.Material = Enum.Material.Neon
		tint.Anchored = true
		tint.CanCollide = false
		tint.Parent = model
	end
	local label = Instance.new("BillboardGui")
	label.Name = "BrainrotLabel"
	label.Size = UDim2.fromOffset(240, 96)
	label.StudsOffsetWorldSpace = Vector3.new(0, 6.5, 0)
	label.AlwaysOnTop = true
	label.MaxDistance = 250
	label.Parent = model
	local nameText = Instance.new("TextLabel")
	nameText.Name = "Name"
	nameText.Size = UDim2.new(1, 0, 0, 34)
	nameText.Position = UDim2.new(0, 0, 0, 0)
	nameText.BackgroundTransparency = 1
	nameText.Text = char.name
	nameText.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameText.TextStrokeTransparency = 0
	nameText.TextScaled = false
	nameText.TextSize = 24
	nameText.Font = Enum.Font.GothamBold
	nameText.Parent = label
	local rarityText = Instance.new("TextLabel")
	rarityText.Name = "Rarity"
	rarityText.Size = UDim2.new(1, 0, 0, 30)
	rarityText.Position = UDim2.new(0, 0, 0, 32)
	rarityText.BackgroundTransparency = 1
	rarityText.Text = char.rarity:upper() .. "  $" .. rate .. "/s"
	rarityText.TextColor3 = Config.RARITIES[char.rarity].color
	rarityText.TextStrokeTransparency = 0
	rarityText.TextSize = 22
	rarityText.Font = Enum.Font.GothamBold
	rarityText.Parent = label
	local priceText = Instance.new("TextLabel")
	priceText.Name = "Price"
	priceText.Size = UDim2.new(1, 0, 0, 30)
	priceText.Position = UDim2.new(0, 0, 0, 62)
	priceText.BackgroundTransparency = 1
	priceText.Text = "BUY $" .. char.price
	if mutation.name ~= "None" then
		priceText.Text = mutation.name:upper() .. " x" .. mutation.mult .. "  BUY $" .. char.price
	end
	priceText.TextColor3 = Color3.fromRGB(255, 220, 60)
	priceText.TextStrokeTransparency = 0
	priceText.TextSize = 22
	priceText.Font = Enum.Font.GothamBold
	priceText.Parent = label
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
		p.Parent = model
		return p
	end
	if kind == "TopHat" then
		part("HatTop", Vector3.new(1.4, 1.6, 1.4), Vector3.new(0, 6.4, 0), Color3.fromRGB(30, 30, 30))
		part("HatBrim", Vector3.new(2.6, 0.25, 2.6), Vector3.new(0, 5.6, 0), Color3.fromRGB(30, 30, 30))
	elseif kind == "Sneakers" then
		part("ShoeL", Vector3.new(1.1, 0.7, 1.6), Vector3.new(-0.8, 0.35, 0.3), Color3.fromRGB(255, 255, 255))
		part("ShoeR", Vector3.new(1.1, 0.7, 1.6), Vector3.new(0.8, 0.35, 0.3), Color3.fromRGB(255, 255, 255))
	elseif kind == "ChefHat" then
		part("ChefTop", Vector3.new(2, 1.4, 2), Vector3.new(0, 6.2, 0), Color3.fromRGB(255, 255, 255))
		part("ChefBand", Vector3.new(2.2, 0.5, 2.2), Vector3.new(0, 5.5, 0), Color3.fromRGB(240, 240, 240))
	elseif kind == "Glasses" then
		part("LensL", Vector3.new(0.9, 0.9, 0.2), Vector3.new(-0.55, 4.8, 1.15), Color3.fromRGB(20, 20, 20))
		part("LensR", Vector3.new(0.9, 0.9, 0.2), Vector3.new(0.55, 4.8, 1.15), Color3.fromRGB(20, 20, 20))
		part("Bridge", Vector3.new(0.5, 0.2, 0.2), Vector3.new(0, 4.8, 1.15), Color3.fromRGB(20, 20, 20))
	elseif kind == "Headphones" then
		part("CupL", Vector3.new(0.5, 1.1, 1), Vector3.new(-1.2, 4.6, 0), Color3.fromRGB(255, 60, 120))
		part("CupR", Vector3.new(0.5, 1.1, 1), Vector3.new(1.2, 4.6, 0), Color3.fromRGB(255, 60, 120))
		part("Band", Vector3.new(2.6, 0.3, 0.4), Vector3.new(0, 5.7, 0), Color3.fromRGB(255, 60, 120))
	elseif kind == "Shades" then
		part("ShadeBar", Vector3.new(2, 0.7, 0.25), Vector3.new(0, 4.9, 1.12), Color3.fromRGB(10, 10, 10))
	elseif kind == "PirateHat" then
		part("PirateTop", Vector3.new(2.8, 0.5, 2), Vector3.new(0, 5.8, 0), Color3.fromRGB(25, 25, 25))
		part("PiratePeak", Vector3.new(1.2, 0.8, 1.2), Vector3.new(0, 6.2, 0), Color3.fromRGB(25, 25, 25))
	elseif kind == "Crown" then
		part("CrownBase", Vector3.new(2, 0.7, 2), Vector3.new(0, 5.8, 0), Color3.fromRGB(255, 210, 0))
		part("Spike1", Vector3.new(0.4, 0.9, 0.4), Vector3.new(-0.7, 6.4, 0), Color3.fromRGB(255, 210, 0))
		part("Spike2", Vector3.new(0.4, 1.1, 0.4), Vector3.new(0, 6.5, 0), Color3.fromRGB(255, 210, 0))
		part("Spike3", Vector3.new(0.4, 0.9, 0.4), Vector3.new(0.7, 6.4, 0), Color3.fromRGB(255, 210, 0))
	elseif kind == "BowTie" then
		part("BowL", Vector3.new(0.9, 0.7, 0.3), Vector3.new(-0.6, 3.2, 1.05), Color3.fromRGB(200, 0, 0))
		part("BowR", Vector3.new(0.9, 0.7, 0.3), Vector3.new(0.6, 3.2, 1.05), Color3.fromRGB(200, 0, 0))
	elseif kind == "Cup" then
		part("LatteCup", Vector3.new(0.9, 1.1, 0.9), Vector3.new(0, 6, 0), Color3.fromRGB(255, 255, 255))
		part("LatteTop", Vector3.new(1, 0.3, 1), Vector3.new(0, 6.6, 0), Color3.fromRGB(180, 120, 60))
	elseif kind == "Ears" then
		part("EarL", Vector3.new(0.6, 1.4, 0.4), Vector3.new(-0.8, 5.9, 0), Color3.fromRGB(120, 70, 20))
		part("EarR", Vector3.new(0.6, 1.4, 0.4), Vector3.new(0.8, 5.9, 0), Color3.fromRGB(120, 70, 20))
	elseif kind == "Halo" then
		local halo = part("HaloRing", Vector3.new(2.4, 0.25, 2.4), Vector3.new(0, 6.1, 0), Color3.fromRGB(255, 230, 100))
		halo.Material = Enum.Material.Neon
	elseif kind == "Wings" then
		part("WingL", Vector3.new(0.3, 2.2, 1.6), Vector3.new(-1.9, 3, 0), Color3.fromRGB(255, 255, 255))
		part("WingR", Vector3.new(0.3, 2.2, 1.6), Vector3.new(1.9, 3, 0), Color3.fromRGB(255, 255, 255))
	end
end

function Conveyor.wireClick(model)
	local detector = Instance.new("ClickDetector")
	detector.MaxActivationDistance = 40
	detector.Parent = model
	detector.MouseClick:Connect(function(player)
		local ownerId = model:GetAttribute("OwnerId") or 0
		if ownerId ~= 0 then
			local Steal = require(script.Parent:WaitForChild("Steal"))
			Steal.attemptSteal(player, model)
		else
			local Economy = require(script.Parent:WaitForChild("Economy"))
			Economy.buyBrainrot(player, model)
		end
	end)
end

function Conveyor.announceMythicSpawn(char, mutation, rate)
	local notify = ReplicatedStorage:WaitForChild("BrainrotNotify")
	notify:FireAllClients("mythic", char.name .. "  " .. char.rarity:upper() .. "  $" .. rate .. "/s")
	local Economy = require(script.Parent:WaitForChild("Economy"))
	Economy.startMythicWindow()
end

function Conveyor.removeFromBelt(model)
	for i, entry in ipairs(Conveyor.live) do
		if entry.model == model then
			table.remove(Conveyor.live, i)
			return true
		end
	end
	return false
end

function Conveyor.isOnBelt(model)
	for _, entry in ipairs(Conveyor.live) do
		if entry.model == model then
			return true
		end
	end
	return false
end

function Conveyor.start()
	for _ = 1, 3 do
		Conveyor.spawnBrainrot()
	end
	task.spawn(function()
		while true do
			task.wait(Config.SPAWN_CHECK_SECONDS)
			if #Conveyor.live < Config.BELT_MAX_LIVE then
				Conveyor.spawnBrainrot()
			end
		end
	end)
	RunService.Heartbeat:Connect(function(dt)
		for i = #Conveyor.live, 1, -1 do
			local entry = Conveyor.live[i]
			if not entry.model.Parent then
				table.remove(Conveyor.live, i)
			else
				entry.progress += Config.BELT_SPEED * dt
				local z = Config.BELT_START_Z + entry.progress
				entry.model:PivotTo(CFrame.new(0, 0, z))
				if z >= Config.BELT_END_Z then
					entry.model:Destroy()
					table.remove(Conveyor.live, i)
				end
			end
		end
	end)
end

return Conveyor
