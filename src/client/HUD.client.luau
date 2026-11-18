-- Brainrot Blitz HUD: coins, earnings, wave timer, base panel, collection
-- index, lock and rebirth buttons, event banner and hint. All text stays
-- clear of the top-left corner where Roblox puts its menu buttons.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")
local gameState = ReplicatedStorage:WaitForChild("GameState")

local HUD = {}

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = playerGui

local function makeLabel(name, parent, pos, size, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = pos
	label.Size = size
	label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	label.BackgroundTransparency = 0.4
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.TextSize = textSize
	label.Font = Enum.Font.SourceSansBold
	label.TextStrokeTransparency = 0
	label.Text = ""
	label.Parent = parent
	return label
end

-- Top-centre: persistent wave timer (never top-left).
local waveLabel = makeLabel("WaveTimer", gui, UDim2.new(0.5, -140, 0, 8), UDim2.fromOffset(280, 44), 28)
waveLabel.Text = "NEXT WAVE 02:00"

-- Top-right: coins + earnings.
local coinsLabel = makeLabel("Coins", gui, UDim2.new(1, -300, 0, 8), UDim2.fromOffset(288, 44), 30, Color3.fromRGB(255, 220, 0))
coinsLabel.Text = "COINS $150"
local incomeLabel = makeLabel("Income", gui, UDim2.new(1, -300, 0, 56), UDim2.fromOffset(288, 36), 26, Color3.fromRGB(120, 255, 120))
incomeLabel.Text = "EARNING $0/s"

-- Event banner: narrow (360px) so it never overlaps the income label.
local bannerLabel = makeLabel("EventBanner", gui, UDim2.new(0.5, -180, 0, 60), UDim2.fromOffset(360, 40), 26, Color3.fromRGB(255, 215, 0))
bannerLabel.Visible = false

-- Left panel: your base, slots, owned brainrots and their rates.
local basePanel = Instance.new("Frame")
basePanel.Name = "BasePanel"
basePanel.Position = UDim2.new(0, 12, 0, 120)
basePanel.Size = UDim2.fromOffset(250, 260)
basePanel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
basePanel.BackgroundTransparency = 0.4
basePanel.Parent = gui
local baseTitle = makeLabel("BaseTitle", basePanel, UDim2.new(0, 8, 0, 6), UDim2.fromOffset(234, 30), 22)
baseTitle.Text = "MY BASE"
local slotsLabel = makeLabel("Slots", basePanel, UDim2.new(0, 8, 0, 40), UDim2.fromOffset(234, 28), 22)
slotsLabel.Text = "SLOTS 0/8"
local indexLabel = makeLabel("Index", basePanel, UDim2.new(0, 8, 0, 72), UDim2.fromOffset(234, 28), 22, Color3.fromRGB(255, 200, 0))
indexLabel.Text = "INDEX 0/16"
local ownedLabel = makeLabel("Owned", basePanel, UDim2.new(0, 8, 0, 104), UDim2.fromOffset(234, 148), 20)
ownedLabel.TextWrapped = true
ownedLabel.TextXAlignment = Enum.TextXAlignment.Left
ownedLabel.TextYAlignment = Enum.TextYAlignment.Top
ownedLabel.Text = "No brainrots yet - buy one on the belt!"

-- Bottom-right: lock and rebirth buttons.
local lockButton = Instance.new("TextButton")
lockButton.Name = "LockButton"
lockButton.AnchorPoint = Vector2.new(1, 1)
lockButton.Position = UDim2.new(1, -12, 1, -64)
lockButton.Size = UDim2.fromOffset(200, 48)
lockButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
lockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
lockButton.TextSize = 24
lockButton.Font = Enum.Font.SourceSansBold
lockButton.Text = "LOCK BASE (60s)"
lockButton.Parent = gui

local rebirthButton = Instance.new("TextButton")
rebirthButton.Name = "RebirthButton"
rebirthButton.AnchorPoint = Vector2.new(1, 1)
rebirthButton.Position = UDim2.new(1, -12, 1, -8)
rebirthButton.Size = UDim2.fromOffset(200, 48)
rebirthButton.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
rebirthButton.TextColor3 = Color3.fromRGB(0, 0, 0)
rebirthButton.TextSize = 24
rebirthButton.Font = Enum.Font.SourceSansBold
rebirthButton.Text = "REBIRTH $10,000"
rebirthButton.Parent = gui

-- Bottom-left: short hint, wrapped so it never runs under the buttons.
local hintLabel = makeLabel("Hint", gui, UDim2.new(0, 12, 1, -44), UDim2.fromOffset(420, 36), 20)
hintLabel.TextWrapped = true
hintLabel.Text = "Click a brainrot on the belt to BUY it"

local bannerThread = nil

local function showBanner(text, colorName, duration)
	local colors = {
		blue = Color3.fromRGB(120, 200, 255),
		gold = Color3.fromRGB(255, 215, 0),
		green = Color3.fromRGB(120, 255, 120),
		red = Color3.fromRGB(255, 90, 90),
	}
	bannerLabel.Text = text
	bannerLabel.TextColor3 = colors[colorName] or Color3.fromRGB(255, 255, 255)
	bannerLabel.Visible = true
	-- task.delay returns a thread, not a connection: cancel it, never Disconnect it.
	if bannerThread then
		task.cancel(bannerThread)
	end
	bannerThread = task.delay(duration or 4, function()
		bannerLabel.Visible = false
		bannerThread = nil
	end)
end

remotes:WaitForChild("Banner").OnClientEvent:Connect(showBanner)

local function fmtTime(seconds)
	seconds = math.max(0, math.floor(seconds or 0))
	local mins = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%02d:%02d", mins, secs)
end

local function listOwned()
	local baseIndex = player:GetAttribute("BaseIndex") or 0
	if baseIndex == 0 then
		return {}
	end
	local bases = workspace:FindFirstChild("Bases")
	if not bases then
		return {}
	end
	local base = bases:FindFirstChild("Base" .. baseIndex)
	if not base then
		return {}
	end
	local found = {}
	for _, desc in ipairs(base:GetDescendants()) do
		if desc:IsA("Model") and desc:GetAttribute("OwnerId") == player.UserId then
			table.insert(found, (desc:GetAttribute("CharName") or "?") .. " $" .. (desc:GetAttribute("Rate") or 0) .. "/s")
		end
	end
	return found
end

function HUD.refreshStats()
	local coins = player:GetAttribute("Coins") or 0
	local income = player:GetAttribute("Income") or 0
	coinsLabel.Text = "COINS $" .. coins
	incomeLabel.Text = "EARNING $" .. income .. "/s"
	local phase = gameState:GetAttribute("WavePhase") or "calm"
	local timer = gameState:GetAttribute("WaveTimer") or 120
	if phase == "warning" then
		waveLabel.Text = "TSUNAMI IN " .. math.floor(timer) .. "s - RUN HOME!"
		waveLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
	elseif phase == "sweep" then
		waveLabel.Text = "TSUNAMI! RUN HOME!"
		waveLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
	else
		waveLabel.Text = "NEXT WAVE " .. fmtTime(timer)
		waveLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
	local golden = gameState:GetAttribute("GoldenLeft") or 0
	local mythic = gameState:GetAttribute("MythicLeft") or 0
	if golden > 0 and mythic > 0 then
		bannerLabel.Text = "GOLDEN + MYTHIC 2x!"
		bannerLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		bannerLabel.Visible = true
	elseif golden > 0 then
		bannerLabel.Text = "GOLDEN HOUR 2x! " .. math.floor(golden) .. "s"
		bannerLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		bannerLabel.Visible = true
	elseif mythic > 0 then
		bannerLabel.Text = "MYTHIC 2x! " .. math.floor(mythic) .. "s"
		bannerLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		bannerLabel.Visible = true
	elseif not bannerThread then
		bannerLabel.Visible = false
	end
	local owned = player:GetAttribute("OwnedCount") or 0
	local slots = player:GetAttribute("Slots") or 8
	slotsLabel.Text = "SLOTS " .. owned .. "/" .. slots
	indexLabel.Text = "INDEX " .. (player:GetAttribute("IndexCount") or 0) .. "/16"
	local ownedList = listOwned()
	if #ownedList > 0 then
		ownedLabel.Text = table.concat(ownedList, "\n")
	else
		ownedLabel.Text = "No brainrots yet - buy one on the belt!"
	end
	local lockLeft = player:GetAttribute("LockLeft") or 0
	local lockCd = player:GetAttribute("LockCooldown") or 0
	local protect = player:GetAttribute("SpawnProtect") or 0
	if lockLeft > 0 then
		lockButton.Text = "LOCKED " .. lockLeft .. "s"
		lockButton.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
	elseif lockCd > 0 then
		lockButton.Text = "LOCK CD " .. lockCd .. "s"
		lockButton.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
	elseif protect > 0 then
		lockButton.Text = "PROTECTED " .. protect .. "s"
		lockButton.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
	else
		lockButton.Text = "LOCK BASE (60s)"
		lockButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
	end
	local rebirths = player:GetAttribute("Rebirths") or 0
	rebirthButton.Text = "REBIRTH $10,000 (x" .. (1 + 0.25 * rebirths) .. ")"
end

lockButton.MouseButton1Click:Connect(function()
	remotes:WaitForChild("LockRequest"):FireServer()
end)

rebirthButton.MouseButton1Click:Connect(function()
	remotes:WaitForChild("RebirthRequest"):FireServer()
end)

-- Floating +$X text whenever coins tick up.
local lastCoins = 150
task.spawn(function()
	while true do
		task.wait(0.5)
		HUD.refreshStats()
		local coins = player:GetAttribute("Coins") or 0
		local gain = coins - lastCoins
		if gain > 0 and gain < 100000 then
			local float = Instance.new("TextLabel")
			float.Size = UDim2.fromOffset(160, 36)
			float.Position = UDim2.new(0.5, -80, 0.5, -40)
			float.BackgroundTransparency = 1
			float.Text = "+$" .. gain
			float.TextColor3 = Color3.fromRGB(120, 255, 120)
			float.TextSize = 28
			float.Font = Enum.Font.SourceSansBold
			float.TextStrokeTransparency = 0
			float.Parent = gui
			task.spawn(function()
				for _ = 1, 20 do
					task.wait(0.05)
					float.Position += UDim2.fromOffset(0, -2)
				end
				float:Destroy()
			end)
		end
		lastCoins = coins
	end
end)
