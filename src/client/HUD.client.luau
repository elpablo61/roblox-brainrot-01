-- HUD.client: builds the Brainrot Blitz interface — coins, income, wave timer, base panel,
-- index, lock and rebirth buttons, and the photo camera (P). HUD text stays clear of the
-- top-left corner where Roblox puts its menu buttons.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = playerGui

local coinsLabel = nil
local incomeLabel = nil
local waveLabel = nil
local baseLabel = nil
local indexLabel = nil
local lockButton = nil
local rebirthButton = nil
local photoOn = false

local function makeLabel(name, parent, pos, size, text, textSize, color)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Position = pos
	l.Size = size
	l.BackgroundTransparency = 0.35
	l.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	l.BorderSizePixel = 0
	l.Text = text
	l.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	l.TextSize = textSize
	l.Font = Enum.Font.GothamBold
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

local function makeButton(name, parent, pos, size, text, textSize)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Position = pos
	b.Size = size
	b.BackgroundColor3 = Color3.fromRGB(40, 120, 220)
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.TextSize = textSize
	b.Font = Enum.Font.GothamBold
	b.Parent = parent
	return b
end

function refreshStats()
	local coins = player:GetAttribute("Coins") or 0
	local income = player:GetAttribute("Income") or 0
	local waveIn = player:GetAttribute("WaveIn") or 120
	local golden = player:GetAttribute("GoldenActive")
	local slotsUsed = player:GetAttribute("SlotsUsed") or 0
	local slotsMax = player:GetAttribute("SlotsMax") or 8
	local indexOwned = player:GetAttribute("IndexOwned") or 0
	local indexTotal = player:GetAttribute("IndexTotal") or 16
	local rebirths = player:GetAttribute("Rebirths") or 0
	local mult = player:GetAttribute("Multiplier") or 1
	local lockLeft = player:GetAttribute("LockLeft") or 0
	local lockCd = player:GetAttribute("LockCooldown") or 0

	coinsLabel.Text = "COINS  $" .. tostring(coins)
	incomeLabel.Text = "EARNING  $" .. tostring(income) .. "/s" .. (golden and "  (GOLDEN 2x!)" or "")
	local mins = math.floor(waveIn / 60)
	local secs = waveIn % 60
	if golden then
		waveLabel.Text = "GOLDEN HOUR — 2x INCOME!"
		waveLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	else
		waveLabel.Text = string.format("NEXT WAVE %02d:%02d", mins, secs)
		waveLabel.TextColor3 = Color3.fromRGB(120, 200, 255)
	end
	baseLabel.Text = "MY BASE  •  SLOTS " .. tostring(slotsUsed) .. "/" .. tostring(slotsMax) .. "  •  REBIRTH x" .. string.format("%.2f", mult) .. " (" .. tostring(rebirths) .. ")"
	indexLabel.Text = "INDEX  " .. tostring(indexOwned) .. "/" .. tostring(indexTotal)
	if lockLeft > 0 then
		lockButton.Text = "LOCKED " .. tostring(lockLeft) .. "s"
		lockButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
	elseif lockCd > 0 then
		lockButton.Text = "LOCK  (" .. tostring(lockCd) .. "s)"
		lockButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	else
		lockButton.Text = "LOCK BASE  (60s)"
		lockButton.BackgroundColor3 = Color3.fromRGB(40, 120, 220)
	end
	rebirthButton.Text = "REBIRTH  $10,000"
end

local function buildGui()
	-- Top-centre: wave timer (never top-left)
	waveLabel = makeLabel("WaveTimer", gui, UDim2.new(0.5, -150, 0, 8), UDim2.fromOffset(300, 40), "NEXT WAVE 02:00", 28, Color3.fromRGB(120, 200, 255))
	waveLabel.TextXAlignment = Enum.TextXAlignment.Center

	-- Top-right: coins + income
	coinsLabel = makeLabel("Coins", gui, UDim2.new(1, -280, 0, 8), UDim2.fromOffset(272, 44), "COINS  $150", 32, Color3.fromRGB(255, 230, 80))
	incomeLabel = makeLabel("Income", gui, UDim2.new(1, -280, 0, 56), UDim2.fromOffset(272, 36), "EARNING  $0/s", 28, Color3.fromRGB(120, 255, 120))

	-- Right side: base panel
	baseLabel = makeLabel("BasePanel", gui, UDim2.new(1, -280, 0, 110), UDim2.fromOffset(272, 40), "MY BASE", 24, Color3.fromRGB(255, 255, 255))
	indexLabel = makeLabel("IndexPanel", gui, UDim2.new(1, -280, 0, 154), UDim2.fromOffset(272, 36), "INDEX  0/16", 24, Color3.fromRGB(200, 140, 255))

	-- Bottom-right: lock + rebirth buttons
	lockButton = makeButton("LockButton", gui, UDim2.new(1, -280, 1, -130), UDim2.fromOffset(272, 52), "LOCK BASE  (60s)", 26)
	rebirthButton = makeButton("RebirthButton", gui, UDim2.new(1, -280, 1, -72), UDim2.fromOffset(272, 52), "REBIRTH  $10,000", 26)
	rebirthButton.BackgroundColor3 = Color3.fromRGB(160, 60, 200)

	-- Bottom-left: hint
	local hint = makeLabel("Hint", gui, UDim2.new(0, 12, 1, -44), UDim2.fromOffset(460, 32), "Click a brainrot on the red carpet to buy it!  P = photo camera", 20, Color3.fromRGB(255, 255, 255))
	hint.BackgroundTransparency = 0.5

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	lockButton.MouseButton1Click:Connect(function()
		remotes.LockBase:FireServer()
	end)
	rebirthButton.MouseButton1Click:Connect(function()
		remotes.Rebirth:FireServer()
	end)
end

local function togglePhoto(_, state)
	if state ~= Enum.UserInputState.Begin then
		return
	end
	photoOn = not photoOn
	local camera = workspace.CurrentCamera
	if photoOn then
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = CFrame.lookAt(Vector3.new(62, 58, 88), Vector3.new(-10, 0, -10))
	else
		camera.CameraType = Enum.CameraType.Custom
	end
end

buildGui()
refreshStats()
ContextActionService:BindAction("BrainrotPhoto", togglePhoto, false, Enum.KeyCode.P)
task.spawn(function()
	while true do
		task.wait(0.25)
		refreshStats()
	end
end)
