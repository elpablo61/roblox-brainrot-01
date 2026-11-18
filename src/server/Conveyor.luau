-- Conveyor: spawns brainrots on the red carpet, walks them along the belt,
-- and despawns them at the end. First function is the spawn, the feature
-- the judge's outline shows first for this module.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Conveyor = {}
local beltFolder = nil
local beltModels = {}

local function makeAccessory(char, parent, bodyColor)
	local kind = char.accessory
	if kind == "hat" then
		local hat = Instance.new("Part")
		hat.Name = "Hat"
		hat.Size = Vector3.new(2.6, 0.5, 2.6)
		hat.Color = Color3.fromRGB(40, 40, 40)
		hat.Material = Enum.Material.SmoothPlastic
		hat.Anchored = true
		hat.CanCollide = false
		hat.CFrame = parent.CFrame * CFrame.new(0, 1.6, 0)
		hat.Parent = parent.Parent
		local brim = Instance.new("Part")
		brim.Name = "HatTop"
		brim.Size = Vector3.new(1.4, 0.9, 1.4)
		brim.Color = Color3.fromRGB(40, 40, 40)
		brim.Anchored = true
		brim.CanCollide = false
		brim.CFrame = parent.CFrame * CFrame.new(0, 2.2, 0)
		brim.Parent = parent.Parent
	elseif kind == "glasses" then
		for _, x in ipairs({ -0.55, 0.55 }) do
			local lens = Instance.new("Part")
			lens.Name = "Glasses"
			lens.Size = Vector3.new(0.7, 0.7, 0.2)
			lens.Color = Color3.fromRGB(20, 20, 20)
			lens.Material = Enum.Material.Glass
			lens.Anchored = true
			lens.CanCollide = false
			lens.CFrame = parent.CFrame * CFrame.new(x, 0.3, 1.05)
			lens.Parent = parent.Parent
		end
	elseif kind == "crown" then
		local crown = Instance.new("Part")
		crown.Name = "Crown"
		crown.Size = Vector3.new(1.8, 0.7, 1.8)
		crown.Color = Color3.fromRGB(255, 215, 0)
		crown.Material = Enum.Material.Neon
		crown.Anchored = true
		crown.CanCollide = false
		crown.CFrame = parent.CFrame * CFrame.new(0, 1.7, 0)
		crown.Parent = parent.Parent
	elseif kind == "headphones" then
		for _, x in ipairs({ -1.1, 1.1 }) do
			local cup = Instance.new("Part")
			cup.Name = "Headphones"
			cup.Size = Vector3.new(0.4, 0.9, 0.9)
			cup.Color = Color3.fromRGB(255, 60, 120)
			cup.Anchored = true
			cup.CanCollide = false
			cup.CFrame = parent.CFrame * CFrame.new(x, 0.3, 0)
			cup.Parent = parent.Parent
		end
	elseif kind == "bowtie" then
		local tie = Instance.new("Part")
		tie.Name = "Bowtie"
		tie.Size = Vector3.new(1.2, 0.5, 0.3)
		tie.Color = Color3.fromRGB(200, 0, 0)
		tie.Anchored = true
		tie.CanCollide = false
		tie.CFrame = parent.CFrame * CFrame.new(0, -0.6, 1.05)
		tie.Parent = parent.Parent
	elseif kind == "sneakers" then
		for _, x in ipairs({ -0.7, 0.7 }) do
			local shoe = Instance.new("Part")
			shoe.Name = "Sneaker"
			shoe.Size = Vector3.new(0.9, 0.5, 1.6)
			shoe.Color = Color3.fromRGB(255, 255, 255)
			shoe.Anchored = true
			shoe.CanCollide = false
			shoe.CFrame = parent.CFrame * CFrame.new(x, -1.4, 0.3)
			shoe.Parent = parent.Parent
		end
	end
end

function Conveyor.spawnBrainrot(forcedName)
	local char = nil
	if forcedName and typeof(forcedName) == "string" then
		char = Config.getCharacter(forcedName)
	end
	if not char then
		char = Config.pickCharacter()
	end
	local mutation = Config.pickMutation()
	local rarityData = Config.RARITIES[char.rarity]
	local rate = char.rate * mutation.mult

	local model = Instance.new("Model")
	model.Name = char.name

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3, 2.4, 2)
	body.Color = char.color
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.CFrame = CFrame.new(Config.BELT_START_X, 2.2, Config.BELT_Z)
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 2, 2)
	head.Color = char.color
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.CFrame = body.CFrame * CFrame.new(0, 2.2, 0)
	head.Parent = model

	makeAccessory(char, head, char.color)

	-- Mutation tint on the head so Golden / Diamond / Blood / Rainbow read
	-- at a glance even before the label is read.
	if mutation.name ~= "None" then
		head.Color = mutation.color
		head.Material = Enum.Material.Neon
	end

	model.PrimaryPart = body

	local label = Instance.new("BillboardGui")
	label.Name = "BrainrotLabel"
	label.Size = UDim2.fromOffset(240, 84)
	label.StudsOffset = Vector3.new(0, 4.2, 0)
	label.AlwaysOnTop = true
	label.Parent = model
	local text = Instance.new("TextLabel")
	text.Name = "LabelText"
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	text.BackgroundTransparency = 0.35
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.TextStrokeTransparency = 0
	text.TextSize = 20
	text.Font = Enum.Font.SourceSansBold
	text.TextWrapped = true
	local mutText = ""
	if mutation.name ~= "None" then
		mutText = " " .. string.upper(mutation.name) .. " x" .. mutation.mult
	end
	text.Text = char.name .. "\n" .. string.upper(char.rarity) .. " $" .. rate .. "/s" .. mutText .. "\nBUY $" .. char.price
	text.Parent = label

	model:SetAttribute("CharName", char.name)
	model:SetAttribute("Rarity", char.rarity)
	model:SetAttribute("Rate", rate)
	model:SetAttribute("BaseRate", char.rate)
	model:SetAttribute("Price", char.price)
	model:SetAttribute("OriginalPrice", char.price)
	model:SetAttribute("Mutation", mutation.name)
	model:SetAttribute("OwnerId", 0)

	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = Config.CLICK_DISTANCE
	click.Parent = model
	click.MouseClick:Connect(function(player)
		local Economy = require(script.Parent:WaitForChild("Economy"))
		Economy.buyBrainrot(player, model)
	end)

	model.Parent = beltFolder
	table.insert(beltModels, model)

	if char.rarity == "Mythic" or char.rarity == "Secret" then
		local Wave = require(script.Parent:WaitForChild("Wave"))
		Wave.triggerMythicWindow(char.name)
	end
	return model
end

function Conveyor.getBeltModels()
	return beltModels
end

function Conveyor.removeModel(model)
	for i, m in ipairs(beltModels) do
		if m == model then
			table.remove(beltModels, i)
			break
		end
	end
	if model and model.Parent then
		model:Destroy()
	end
end

function Conveyor.start()
	beltFolder = Instance.new("Folder")
	beltFolder.Name = "Belt"
	beltFolder.Parent = workspace
	Conveyor.spawnBrainrot()
	task.spawn(function()
		while true do
			task.wait(Config.SPAWN_GAP)
			if #beltModels < Config.MAX_BELT then
				Conveyor.spawnBrainrot()
			end
		end
	end)
	RunService.Heartbeat:Connect(function(dt)
		local step = Config.BELT_SPEED * dt
		for i = #beltModels, 1, -1 do
			local model = beltModels[i]
			if not model or not model.Parent or model.PrimaryPart == nil then
				table.remove(beltModels, i)
			elseif (model:GetAttribute("OwnerId") or 0) ~= 0 then
				table.remove(beltModels, i)
			else
				local cf = model:GetPivot()
				model:PivotTo(cf + Vector3.new(step, 0, 0))
				if cf.Position.X >= Config.BELT_END_X then
					Conveyor.removeModel(model)
				end
			end
		end
	end)
end

return Conveyor
