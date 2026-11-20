-- Brainrot Blitz conveyor: spawns absurd characters on the red carpet,
-- walks them from one end to the other, and routes clicks to buy or steal.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Conveyor = {}

local EconomyModule = nil
local StealModule = nil
local BeltFolder = nil
local OnBelt = 0

local function getNotify()
	return ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify")
end

local function getState()
	return ReplicatedStorage:WaitForChild("GameState")
end

function Conveyor.setEconomy(module)
	EconomyModule = module
end

function Conveyor.setSteal(module)
	StealModule = module
end

function Conveyor.spawnBrainrot()
	if OnBelt >= Config.Conveyor.MaxOnBelt then
		return nil
	end
	local char = Config.pickCharacter()
	local mutation = Config.rollMutation()
	local rate = char.Rate * mutation.Multiplier
	local model = Instance.new("Model")
	model.Name = char.Name
	model:SetAttribute("CharName", char.Name)
	model:SetAttribute("Rarity", char.Rarity)
	model:SetAttribute("Rate", rate)
	model:SetAttribute("Price", char.Price)
	model:SetAttribute("Mutation", mutation.Name)
	model:SetAttribute("State", "Belt")
	model:SetAttribute("Owner", "")
	local bodyColor = char.Body
	if mutation.Tint then
		bodyColor = mutation.Tint
	end
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3, 2.5, 2)
	body.Color = bodyColor
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.CFrame = CFrame.new(Config.Conveyor.Start + Vector3.new(0, 1.5, 0))
	body.Parent = model
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 2, 2)
	head.Color = char.Head
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.CFrame = CFrame.new(Config.Conveyor.Start + Vector3.new(0, 3.8, 0))
	head.Parent = model
	Conveyor.buildAccessory(model, char.Accessory, head.CFrame)
	Conveyor.buildLabel(model, char, rate, mutation)
	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 80
	click.Parent = body
	click.MouseClick:Connect(function(player)
		Conveyor.onBrainrotClicked(player, model)
	end)
	model.PrimaryPart = body
	model.Parent = BeltFolder
	OnBelt += 1
	if char.Rarity == "Mythic" then
		local state = getState()
		state:SetAttribute("MythicActive", true)
		state:SetAttribute("MythicUntil", os.clock() + Config.MythicBoost.Duration)
		getNotify():FireAllClients("Mythic", char.Name)
	end
	task.spawn(function()
		Conveyor.walkBrainrot(model)
	end)
	return model
end

function Conveyor.buildAccessory(model, kind, headCFrame)
	local function addPart(name, size, color, offset, material)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.Color = color
		part.Material = material or Enum.Material.SmoothPlastic
		part.Anchored = true
		part.CanCollide = false
		part.CFrame = headCFrame * CFrame.new(offset)
		part.Parent = model
		return part
	end
	if kind == "TopHat" then
		addPart("HatTop", Vector3.new(1.4, 1.2, 1.4), Color3.fromRGB(20, 20, 20), Vector3.new(0, 1.4, 0))
		addPart("HatBrim", Vector3.new(2.4, 0.2, 2.4), Color3.fromRGB(20, 20, 20), Vector3.new(0, 0.9, 0))
	elseif kind == "Cap" then
		addPart("CapTop", Vector3.new(2.2, 0.6, 2.2), Color3.fromRGB(220, 40, 40), Vector3.new(0, 1.1, 0))
		addPart("CapBrim", Vector3.new(2.2, 0.2, 1.2), Color3.fromRGB(220, 40, 40), Vector3.new(0, 0.9, 1.2))
	elseif kind == "Sneakers" then
		addPart("ShoeL", Vector3.new(1, 0.6, 2), Color3.fromRGB(255, 255, 255), Vector3.new(-0.8, -3.4, 0.3))
		addPart("ShoeR", Vector3.new(1, 0.6, 2), Color3.fromRGB(255, 255, 255), Vector3.new(0.8, -3.4, 0.3))
	elseif kind == "Glasses" then
		addPart("LensL", Vector3.new(0.7, 0.7, 0.2), Color3.fromRGB(10, 10, 10), Vector3.new(-0.5, 0.2, 1.05))
		addPart("LensR", Vector3.new(0.7, 0.7, 0.2), Color3.fromRGB(10, 10, 10), Vector3.new(0.5, 0.2, 1.05))
	elseif kind == "Tie" then
		addPart("Tie", Vector3.new(0.6, 1.4, 0.2), Color3.fromRGB(200, 0, 0), Vector3.new(0, -1.6, 1.05))
	elseif kind == "Headphones" then
		addPart("PhoneL", Vector3.new(0.4, 1, 1), Color3.fromRGB(20, 20, 20), Vector3.new(-1.1, 0.3, 0))
		addPart("PhoneR", Vector3.new(0.4, 1, 1), Color3.fromRGB(20, 20, 20), Vector3.new(1.1, 0.3, 0))
		addPart("PhoneBand", Vector3.new(2.4, 0.3, 0.6), Color3.fromRGB(20, 20, 20), Vector3.new(0, 1.1, 0))
	elseif kind == "PirateHat" then
		addPart("PirateTop", Vector3.new(2.6, 0.5, 2.2), Color3.fromRGB(15, 15, 15), Vector3.new(0, 1.2, 0))
		addPart("PirateSkull", Vector3.new(0.6, 0.6, 0.2), Color3.fromRGB(255, 255, 255), Vector3.new(0, 1.2, 1.1))
	elseif kind == "Crown" then
		addPart("CrownBase", Vector3.new(2, 0.5, 2), Color3.fromRGB(255, 215, 0), Vector3.new(0, 1.2, 0), Enum.Material.Neon)
		addPart("CrownSpike", Vector3.new(0.4, 0.8, 0.4), Color3.fromRGB(255, 215, 0), Vector3.new(0, 1.7, 0), Enum.Material.Neon)
	elseif kind == "Flower" then
		addPart("Flower", Vector3.new(0.9, 0.9, 0.9), Color3.fromRGB(255, 120, 200), Vector3.new(0.8, 1, 0.5), Enum.Material.Neon)
	elseif kind == "Tiara" then
		addPart("Tiara", Vector3.new(1.6, 0.4, 1.6), Color3.fromRGB(255, 215, 0), Vector3.new(0, 1.2, 0), Enum.Material.Neon)
	elseif kind == "Monocle" then
		addPart("Monocle", Vector3.new(0.6, 0.6, 0.2), Color3.fromRGB(10, 10, 10), Vector3.new(0.5, 0.2, 1.05))
	end
end

function Conveyor.buildLabel(model, char, rate, mutation)
	local gui = Instance.new("BillboardGui")
	gui.Name = "BrainrotLabel"
	gui.Size = UDim2.new(0, 220, 0, 90)
	gui.StudsOffset = Vector3.new(0, 5.5, 0)
	gui.AlwaysOnTop = true
	gui.Parent = model
	local rarityColor = Config.getRarityColor(char.Rarity)
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0, 30)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = char.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextScaled = false
	nameLabel.TextSize = 22
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = gui
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Size = UDim2.new(1, 0, 0, 26)
	rarityLabel.Position = UDim2.new(0, 0, 0, 30)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = char.Rarity .. (mutation.Name ~= "None" and (" • " .. mutation.Name .. " x" .. mutation.Multiplier) or "")
	rarityLabel.TextColor3 = rarityColor
	rarityLabel.TextStrokeTransparency = 0
	rarityLabel.TextSize = 20
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.Parent = gui
	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "RateLabel"
	rateLabel.Size = UDim2.new(1, 0, 0, 30)
	rateLabel.Position = UDim2.new(0, 0, 0, 56)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = "$" .. rate .. "/s  •  BUY $" .. char.Price
	rateLabel.TextColor3 = Color3.fromRGB(255, 230, 0)
	rateLabel.TextStrokeTransparency = 0
	rateLabel.TextSize = 22
	rateLabel.Font = Enum.Font.GothamBold
	rateLabel.Parent = gui
end

function Conveyor.walkBrainrot(model)
	local step = Config.Conveyor.Speed * 0.05
	while model.Parent == BeltFolder and model:GetAttribute("State") == "Belt" do
		task.wait(0.05)
		local pos = model.PrimaryPart.CFrame.Position
		local nextX = pos.X + step
		if nextX >= Config.Conveyor.Finish.X then
			break
		end
		model:PivotTo(CFrame.new(nextX, pos.Y, pos.Z))
	end
	if model.Parent == BeltFolder and model:GetAttribute("State") == "Belt" then
		model:Destroy()
	end
	OnBelt = math.max(0, OnBelt - 1)
end

function Conveyor.onBrainrotClicked(player, model)
	local state = model:GetAttribute("State")
	if state == "Belt" then
		if EconomyModule then
			EconomyModule.buyBrainrot(player, model)
		end
	elseif state == "Owned" then
		if model:GetAttribute("Owner") ~= player.Name and StealModule then
			StealModule.attemptSteal(player, model)
		end
	elseif state == "Carried" then
		if StealModule then
			StealModule.pickupDropped(player, model)
		end
	end
end

function Conveyor.start()
	BeltFolder = workspace:FindFirstChild("ConveyorBelt")
	if not BeltFolder then
		BeltFolder = Instance.new("Folder")
		BeltFolder.Name = "ConveyorBelt"
		BeltFolder.Parent = workspace
	end
	task.spawn(function()
		while true do
			task.wait(Config.Conveyor.SpawnInterval)
			Conveyor.spawnBrainrot()
		end
	end)
end

return Conveyor
