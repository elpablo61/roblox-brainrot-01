-- Conveyor spawns brainrots on the red carpet, walks them along it, despawns at the end.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Conveyor = {}
local beltModels = {}
local BELT_START = Vector3.new(-56, 2, 0)
local BELT_END_X = 56

function Conveyor.spawnBrainrot()
	local count = 0
	for _, m in ipairs(beltModels) do
		if m.Parent then
			count += 1
		end
	end
	if count >= Config.BELT_MAX then
		return nil
	end
	local rarity = Config.rollRarity()
	local char = Config.pickCharacter(rarity)
	local mutation = Config.rollMutation()
	local model = Conveyor.buildModel(char, mutation)
	model:PivotTo(CFrame.new(BELT_START))
	model.Parent = workspace:WaitForChild("Belt")
	table.insert(beltModels, model)
	if rarity == "Mythic" or rarity == "Secret" then
		local gs = ReplicatedStorage:WaitForChild("GameState")
		gs:SetAttribute("MythicLeft", Config.MYTHIC_WINDOW)
		local Economy = require(script.Parent:WaitForChild("Economy"))
		Economy.bannerAll("MYTHIC SPAWNED: " .. char.name .. " - 2x INCOME 60s!", Color3.fromRGB(255, 60, 60))
	end
	return model
end

function Conveyor.buildModel(char, mutation)
	local rarityInfo = Config.RARITIES[char.rarity]
	local income = char.income * mutation.mult
	local model = Instance.new("Model")
	model.Name = char.name
	model:SetAttribute("CharName", char.name)
	model:SetAttribute("Rarity", char.rarity)
	model:SetAttribute("Income", income)
	model:SetAttribute("Price", char.price)
	model:SetAttribute("OriginalPrice", char.price)
	model:SetAttribute("OwnerId", 0)
	model:SetAttribute("Mutation", mutation.name)
	model:SetAttribute("Carried", false)

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(2.4, 2.4, 2.4)
	body.Color = char.body
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.CFrame = CFrame.new(0, 1.2, 0)
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.6, 1.6, 1.6)
	head.Color = char.head
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.CFrame = CFrame.new(0, 3.2, 0)
	head.Parent = model
	model.PrimaryPart = body

	Conveyor.addAccessory(model, char.acc, char)
	if mutation.name ~= "Normal" then
		local tint = Instance.new("Part")
		tint.Name = "MutationGlow"
		tint.Size = Vector3.new(2.8, 0.4, 2.8)
		tint.Color = mutation.color
		tint.Material = Enum.Material.Neon
		tint.Anchored = true
		tint.CanCollide = false
		tint.CFrame = CFrame.new(0, 2.5, 0)
		tint.Parent = model
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.new(0, 220, 0, 90)
	gui.StudsOffset = Vector3.new(0, 3.4, 0)
	gui.AlwaysOnTop = true
	gui.Parent = model
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 0.35
	label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	local mutText = mutation.name ~= "Normal" and (" - " .. string.upper(mutation.name) .. " x" .. mutation.mult) or ""
	label.Text = char.name .. "\n" .. string.upper(char.rarity) .. " - $" .. income .. "/s" .. mutText .. "\nBUY $" .. char.price
	label.Parent = gui
	local rarityTag = Instance.new("TextLabel")
	rarityTag.Name = "RarityTag"
	rarityTag.Size = UDim2.new(1, 0, 0, 14)
	rarityTag.Position = UDim2.new(0, 0, 0, 0)
	rarityTag.BackgroundColor3 = rarityInfo.color
	rarityTag.Text = ""
	rarityTag.Parent = gui

	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 40
	click.Parent = model
	click.MouseClick:Connect(function(player)
		local Economy = require(script.Parent:WaitForChild("Economy"))
		Economy.buyBrainrot(player, model)
	end)
	return model
end

function Conveyor.addAccessory(model, kind, char)
	local function part(size, pos, color, material)
		local p = Instance.new("Part")
		p.Size = size
		p.CFrame = CFrame.new(pos)
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.Parent = model
		return p
	end
	if kind == "hat" then
		part(Vector3.new(2.2, 0.4, 2.2), Vector3.new(0, 4.2, 0), Color3.fromRGB(40, 40, 40))
		part(Vector3.new(1.2, 1, 1.2), Vector3.new(0, 4.8, 0), Color3.fromRGB(40, 40, 40))
	elseif kind == "glasses" then
		part(Vector3.new(0.6, 0.6, 0.2), Vector3.new(-0.45, 3.3, 0.85), Color3.fromRGB(20, 20, 20))
		part(Vector3.new(0.6, 0.6, 0.2), Vector3.new(0.45, 3.3, 0.85), Color3.fromRGB(20, 20, 20))
	elseif kind == "crown" then
		part(Vector3.new(1.6, 0.5, 1.6), Vector3.new(0, 4.2, 0), Color3.fromRGB(255, 215, 0), Enum.Material.Neon)
	elseif kind == "sneakers" then
		part(Vector3.new(0.9, 0.5, 1.4), Vector3.new(-0.6, 0.1, 0.3), Color3.fromRGB(255, 255, 255))
		part(Vector3.new(0.9, 0.5, 1.4), Vector3.new(0.6, 0.1, 0.3), Color3.fromRGB(255, 255, 255))
	elseif kind == "phones" then
		part(Vector3.new(0.4, 1, 1.8), Vector3.new(-0.9, 3.2, 0), Color3.fromRGB(255, 60, 120), Enum.Material.Neon)
		part(Vector3.new(0.4, 1, 1.8), Vector3.new(0.9, 3.2, 0), Color3.fromRGB(255, 60, 120), Enum.Material.Neon)
	elseif kind == "crumbs" then
		part(Vector3.new(0.4, 0.4, 0.4), Vector3.new(-0.7, 4.1, 0.4), Color3.fromRGB(120, 70, 30))
		part(Vector3.new(0.4, 0.4, 0.4), Vector3.new(0.7, 4.1, -0.3), Color3.fromRGB(120, 70, 30))
	end
end

function Conveyor.start()
	local belt = Instance.new("Folder")
	belt.Name = "Belt"
	belt.Parent = workspace
	task.spawn(function()
		while true do
			task.wait(Config.BELT_SPAWN_EVERY)
			Conveyor.spawnBrainrot()
		end
	end)
	RunService.Heartbeat:Connect(function(dt)
		for i = #beltModels, 1, -1 do
			local model = beltModels[i]
			if not model.Parent then
				table.remove(beltModels, i)
			elseif (model:GetAttribute("OwnerId") or 0) == 0 and not model:GetAttribute("Carried") then
				local pivot = model:GetPivot()
				local nextX = pivot.Position.X + Config.BELT_SPEED * dt
				if nextX >= BELT_END_X then
					model:Destroy()
					table.remove(beltModels, i)
				else
					model:PivotTo(CFrame.new(nextX, pivot.Position.Y, 0))
				end
			end
		end
	end)
end

return Conveyor
