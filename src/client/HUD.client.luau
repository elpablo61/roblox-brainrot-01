-- HUD: coins, earnings, wave timer, base panel, collection index, lock and
-- rebirth buttons. Kept clear of the top-left corner (Roblox menu sits there).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local gameState = ReplicatedStorage:WaitForChild("GameState")
local notify = ReplicatedStorage:WaitForChild("BrainrotNotify")

local HUD = {}

function HUD.refreshStats()
	local coinsLabel = HUD.gui and HUD.gui:FindFirstChild("TopBar") and HUD.gui.TopBar:FindFirstChild("CoinsLabel")
	if not coinsLabel then
		return
	end
	local coins = player:GetAttribute("Coins") or 150
	local income = player:GetAttribute("Income") or 0
	coinsLabel.Text = "$" .. coins .. "   EARNING $" .. income .. "/s"
	local waveLabel = HUD.gui.TopBar:FindFirstChild("WaveLabel")
	if waveLabel then
		local waveTime = gameState:GetAttribute("WaveTime") or 120
		local waveState = gameState:GetAttribute("WaveState") or "countdown"
		local minutes = math.floor(waveTime / 60)
		local seconds = waveTime % 60
		if waveState == "warning" then
			waveLabel.Text = "TSUNAMI IN " .. waveTime .. "s — RUN HOME!"
			waveLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
		elseif waveState == "sweep" then
			waveLabel.Text = "TSUNAMI SWEEPING!"
			waveLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
		else
			waveLabel.Text = "NEXT WAVE " .. string.format("%02d:%02d", minutes, seconds)
			waveLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end
	local basePanel = HUD.gui:FindFirstChild("BasePanel")
	if basePanel then
		local owned = player:GetAttribute("Owned") or 0
		local slots = player:GetAttribute("Slots") or 8
		local indexCount = player:GetAttribute("IndexCount") or 0
		local rebirths = player:GetAttribute("Rebirths") or 0
		local mult = player:GetAttribute("Multiplier") or 1
		local slotsLabel = basePanel:FindFirstChild("SlotsLabel")
		if slotsLabel then
			slotsLabel.Text = "MY BASE  •  SLOTS " .. owned .. "/" .. slots .. "  •  INDEX " .. indexCount .. "/16"
		end
		local rebirthLabel = basePanel:FindFirstChild("RebirthLabel")
		if rebirthLabel then
			rebirthLabel.Text = "REBIRTHS: " .. rebirths .. "  •  MULTIPLIER x" .. mult
		end
	end
	local lockButton = HUD.gui:FindFirstChild("LockButton")
	if lockButton then
		local lockLeft = player:GetAttribute("LockLeft") or 0
		local lockCooldown = player:GetAttribute("LockCooldown") or 0
		if lockLeft > 0 then
			lockButton.Text = "LOCKED " .. lockLeft .. "s"
			lockButton.BackgroundColor3 = Color3.fromRGB(60, 200, 80)
		elseif lockCooldown > 0 then
			lockButton.Text = "LOCK (" .. lockCooldown .. "s)"
			lockButton.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
		else
			lockButton.Text = "LOCK BASE 60s"
			lockButton.BackgroundColor3 = Color3.fromRGB(60, 140, 255)
		end
	end
	local rebirthButton = HUD.gui:FindFirstChild("RebirthButton")
	if rebirthButton then
		rebirthButton.Text = "REBIRTH $10,000  (+25% FOREVER)"
	end
end

function HUD.buildGui()
	local gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.Parent = player:WaitForChild("PlayerGui")
	HUD.gui = gui

	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.AnchorPoint = Vector2.new(0.5, 0)
	topBar.Position = UDim2.new(0.5, 0, 0, 8)
	topBar.Size = UDim2.new(0, 640, 0, 96)
	topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	topBar.BackgroundTransparency = 0.25
	topBar.BorderSizePixel = 0
	topBar.Parent = gui

	local coinsLabel = Instance.new("TextLabel")
	coinsLabel.Name = "CoinsLabel"
	coinsLabel.Size = UDim2.new(1, 0, 0, 48)
	coinsLabel.Position = UDim2.new(0, 0, 0, 4)
	coinsLabel.BackgroundTransparency = 1
	coinsLabel.Text = "$150   EARNING $0/s"
	coinsLabel.TextColor3 = Color3.fromRGB(255, 220, 60)
	coinsLabel.TextSize = 32
	coinsLabel.Font = Enum.Font.GothamBold
	coinsLabel.Parent = topBar

	local waveLabel = Instance.new("TextLabel")
	waveLabel.Name = "WaveLabel"
	waveLabel.Size = UDim2.new(1, 0, 0, 40)
	waveLabel.Position = UDim2.new(0, 0, 0, 52)
	waveLabel.BackgroundTransparency = 1
	waveLabel.Text = "NEXT WAVE 02:00"
	waveLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	waveLabel.TextSize = 28
	waveLabel.Font = Enum.Font.GothamBold
	waveLabel.Parent = topBar

	local basePanel = Instance.new("Frame")
	basePanel.Name = "BasePanel"
	basePanel.AnchorPoint = Vector2.new(1, 0)
	basePanel.Position = UDim2.new(1, -12, 0, 116)
	basePanel.Size = UDim2.new(0, 320, 0, 110)
	basePanel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	basePanel.BackgroundTransparency = 0.25
	basePanel.BorderSizePixel = 0
	basePanel.Parent = gui

	local slotsLabel = Instance.new("TextLabel")
	slotsLabel.Name = "SlotsLabel"
	slotsLabel.Size = UDim2.new(1, -16, 0, 44)
	slotsLabel.Position = UDim2.new(0, 8, 0, 8)
	slotsLabel.BackgroundTransparency = 1
	slotsLabel.Text = "MY BASE  •  SLOTS 0/8  •  INDEX 0/16"
	slotsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	slotsLabel.TextSize = 22
	slotsLabel.TextWrapped = true
	slotsLabel.Font = Enum.Font.GothamBold
	slotsLabel.Parent = basePanel

	local rebirthLabel = Instance.new("TextLabel")
	rebirthLabel.Name = "RebirthLabel"
	rebirthLabel.Size = UDim2.new(1, -16, 0, 40)
	rebirthLabel.Position = UDim2.new(0, 8, 0, 56)
	rebirthLabel.BackgroundTransparency = 1
	rebirthLabel.Text = "REBIRTHS: 0  •  MULTIPLIER x1"
	rebirthLabel.TextColor3 = Color3.fromRGB(160, 220, 255)
	rebirthLabel.TextSize = 22
	rebirthLabel.Font = Enum.Font.GothamBold
	rebirthLabel.Parent = basePanel

	local lockButton = Instance.new("TextButton")
	lockButton.Name = "LockButton"
	lockButton.AnchorPoint = Vector2.new(1, 1)
	lockButton.Position = UDim2.new(1, -12, 1, -64)
	lockButton.Size = UDim2.new(0, 220, 0, 52)
	lockButton.BackgroundColor3 = Color3.fromRGB(60, 140, 255)
	lockButton.Text = "LOCK BASE 60s"
	lockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	lockButton.TextSize = 26
	lockButton.Font = Enum.Font.GothamBold
	lockButton.Parent = gui
	lockButton.MouseButton1Click:Connect(function()
		local lockRequest = ReplicatedStorage:WaitForChild("LockRequest")
		lockRequest:FireServer()
	end)

	local rebirthButton = Instance.new("TextButton")
	rebirthButton.Name = "RebirthButton"
	rebirthButton.AnchorPoint = Vector2.new(1, 1)
	rebirthButton.Position = UDim2.new(1, -12, 1, -8)
	rebirthButton.Size = UDim2.new(0, 320, 0, 48)
	rebirthButton.BackgroundColor3 = Color3.fromRGB(200, 60, 200)
	rebirthButton.Text = "REBIRTH $10,000  (+25% FOREVER)"
	rebirthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	rebirthButton.TextSize = 24
	rebirthButton.Font = Enum.Font.GothamBold
	rebirthButton.Parent = gui
	rebirthButton.MouseButton1Click:Connect(function()
		local rebirthRequest = ReplicatedStorage:WaitForChild("RebirthRequest")
		rebirthRequest:FireServer()
	end)

	local hint = Instance.new("TextLabel")
	hint.Name = "HintLabel"
	hint.AnchorPoint = Vector2.new(0.5, 1)
	hint.Position = UDim2.new(0.5, 0, 1, -8)
	hint.Size = UDim2.new(0, 700, 0, 36)
	hint.BackgroundTransparency = 1
	hint.Text = "Click a brainrot on the red carpet to BUY it — click a rival's to STEAL it!"
	hint.TextColor3 = Color3.fromRGB(255, 255, 255)
	hint.TextStrokeTransparency = 0
	hint.TextSize = 22
	hint.Font = Enum.Font.GothamBold
	hint.Parent = gui

	local banner = Instance.new("TextLabel")
	banner.Name = "Banner"
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.Position = UDim2.new(0.5, 0, 0, 120)
	banner.Size = UDim2.new(0, 700, 0, 56)
	banner.BackgroundTransparency = 1
	banner.Text = ""
	banner.TextColor3 = Color3.fromRGB(255, 220, 60)
	banner.TextStrokeTransparency = 0
	banner.TextSize = 34
	banner.Font = Enum.Font.GothamBold
	banner.Parent = gui
end

function HUD.showBanner(text, color)
	local banner = HUD.gui and HUD.gui:FindFirstChild("Banner")
	if not banner then
		return
	end
	banner.Text = text
	if color then
		banner.TextColor3 = color
	end
	task.delay(4, function()
		if banner.Text == text then
			banner.Text = ""
		end
	end)
end

notify.OnClientEvent:Connect(function(kind, text)
	if kind == "wave-warning" then
		HUD.showBanner(text, Color3.fromRGB(255, 60, 60))
	elseif kind == "wave-sweep" then
		HUD.showBanner(text, Color3.fromRGB(0, 180, 255))
	elseif kind == "golden" then
		HUD.showBanner(text, Color3.fromRGB(255, 215, 0))
	elseif kind == "mythic" then
		HUD.showBanner("MYTHIC SPAWNED: " .. text .. " — 2x INCOME 60s!", Color3.fromRGB(255, 60, 255))
	elseif kind == "bought" or kind == "stolen" or kind == "rebirth" or kind == "locked" then
		HUD.showBanner(text, Color3.fromRGB(120, 255, 120))
	elseif kind == "denied" or kind == "wave-hit" or kind == "dropped" then
		HUD.showBanner(text, Color3.fromRGB(255, 120, 120))
	elseif kind == "carrying" then
		HUD.showBanner(text, Color3.fromRGB(255, 220, 60))
	end
	HUD.refreshStats()
end)

HUD.buildGui()
HUD.refreshStats()
RunService.Heartbeat:Connect(function()
	HUD.refreshStats()
end)
