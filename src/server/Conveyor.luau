-- Conveyor spawns brainrot characters on the red carpet, walks them along
-- the belt, and despawns them at the end. Clicking one buys it (or steals it).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Conveyor = {}
local beltModels = {}
local folder = nil

local function pickWeighted(list)
	local total = 0
	for _, entry in ipairs(list) do total += entry.weight end
	local roll = math.random() * total
	for _, entry in ipairs(list) do
		roll -= entry.weight
		if roll <= 0 then return entry end
	end
	return list[#list]
end

local function makeAccessory(kind, body, accent)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	if kind == "TopHat" then
		part.Size = Vector3.new(1.4, 1.2, 1.4)
		part.Color = accent
		part.Position = Vector3.new(0, 1.9, 0)
	elseif kind == "Cap" then
		part.Size = Vector3.new(1.6, 0.4, 1.6)
		part.Color = accent
		part.Position = Vector3.new(0, 1.6, 0)
	elseif kind == "Sneakers" then
		part.Size = Vector3.new(1.8, 0.4, 1.0)
		part.Color = accent
		part.Position = Vector3.new(0, -1.3, 0.6)
	elseif kind == "Glasses" then
		part.Size = Vector3.new(1.6, 0.4, 0.3)
		part.Color = Color3.fromRGB(20, 20, 20)
		part.Position = Vector3.new(0, 1.2, 0.9)
	elseif kind == "Sunglasses" then
		part.Size = Vector3.new(1.7, 0.5, 0.3)
		part.Color = Color3.fromRGB(10, 10, 10)
		part.Position = Vector3.new(0, 1.2, 0.9)
	elseif kind == "Headphones" then
		part.Size = Vector3.new(2.0, 0.5, 1.2)
		part.Color = accent
		part.Position = Vector3.new(0, 1.5, 0)
	elseif kind == "PirateHat" then
		part.Size = Vector3.new(2.0, 0.5, 1.6)
		part.Color = accent
		part.Position = Vector3.new(0, 1.8, 0)
	elseif kind == "ChefHat" then
		part.Size = Vector3.new(1.4, 1.0, 1.4)
		part.Color = Color3.fromRGB(255, 255, 255)
		part.Position = Vector3.new(0, 1.9, 0)
	elseif kind == "Crown" then
		part.Size = Vector3.new(1.5, 0.6, 1.5)
		part.Color = Color3.fromRGB(255, 210, 40)
		part.Position = Vector3.new(0, 1.9, 0)
	end
	return part
end

local function buildLabel(model, def, mutation, income)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(220, 80)
	gui.StudsOffset = Vector3.new(0, 3.5, 0)
	gui.AlwaysOnTop = true
	gui.Parent = model
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 0.4
	text.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.TextScaled = true
	text.Font = Enum.Font.GothamBold
	text.Text = def.name .. "\n" .. def.rarity:upper() .. "  $" .. tostring(income) .. "/s" .. (mutation.name ~= "None" and ("  " .. mutation.name .. " x" .. tostring(mutation.multiplier)) or "") .. "\nBUY $" .. tostring(def.price)
	text.Parent = gui
	return text
end

function Conveyor.spawnBrainrot()
	local rarityEntry = pickWeighted(Config.RARITY_WEIGHTS)
	local pool = {}
	for _, def in ipairs(Config.CHARACTERS) do
		if def.rarity == rarityEntry.rarity then table.insert(pool, def) end
	end
	local def = pool[math.random(#pool)]
	local mutation = pickWeighted(Config.MUTATIONS)
	local income = def.income * mutation.multiplier
	local model = Instance.new("Model")
	model.Name = def.name
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(2.4, 2.4, 2.4)
	body.Color = mutation.tint or def.body
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.8, 1.8, 1.8)
	head.Color = mutation.tint or def.body
	head.Anchored = true
	head.CanCollide = false
	head.Position = Vector3.new(0, 2.0, 0)
	head.Parent = model
	local accessory = makeAccessory(def.accessory, def.body, def.accent)
	accessory.Parent = model
	local feet = Instance.new("Part")
	feet.Name = "Feet"
	feet.Size = Vector3.new(2.0, 0.5, 1.4)
	feet.Color = def.accent
	feet.Anchored = true
	feet.CanCollide = false
	feet.Position = Vector3.new(0, -1.4, 0)
	feet.Parent = model
	model.PrimaryPart = body
	model:SetAttribute("CharName", def.name)
	model:SetAttribute("Rarity", def.rarity)
	model:SetAttribute("Income", income)
	model:SetAttribute("BaseIncome", def.income)
	model:SetAttribute("Price", def.price)
	model:SetAttribute("Mutation", mutation.name)
	model:SetAttribute("Belt", true)
	buildLabel(model, def, mutation, income)
	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 200
	click.Parent = model
	click.MouseClick:Connect(function(player)
		local Economy = require(script.Parent.Economy)
		Economy.buyBrainrot(player, model)
	end)
	model:PivotTo(CFrame.new(Config.BELT_START_X, 3, Config.BELT_Z))
	model.Parent = folder
	table.insert(beltModels, model)
	if def.rarity == "Mythic" or def.rarity == "Secret" then
		local Economy = require(script.Parent.Economy)
		Economy.startMythicWindow()
		for _, player in ipairs(Players:GetPlayers()) do
			player:SetAttribute("BannerText", "MYTHIC SPAWNED: " .. def.name .. " - 2x INCOME 60s!")
			player:SetAttribute("BannerUntil", os.time() + 5)
		end
	end
	return model
end

function Conveyor.start()
	folder = Instance.new("Folder")
	folder.Name = "BeltBrainrots"
	folder.Parent = workspace
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
			elseif model:GetAttribute("Belt") then
				local pos = model:GetPivot().Position
				local nextX = pos.X + Config.BELT_SPEED * dt
				if nextX >= Config.BELT_END_X then
					model:Destroy()
					table.remove(beltModels, i)
				else
					model:PivotTo(CFrame.new(nextX, 3, Config.BELT_Z))
				end
			else
				table.remove(beltModels, i)
			end
		end
	end)
end

return Conveyor
