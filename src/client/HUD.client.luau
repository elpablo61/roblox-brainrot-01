-- Brainrot Blitz HUD: coins, earnings, wave timer, base panel, index,
-- lock and rebirth buttons, hint and banners. Text stays clear of the
-- top-left corner where Roblox puts its menu buttons.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local HUD = {}

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function makeLabel(name, parent, pos, size, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = pos
	label.Size = size
	label.BackgroundTransparency = 0.4
	label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	label.TextColor3 = color
	label.TextSize = textSize
	label.Font = Enum.Font.GothamBold
	label.Text = ""
	label.Parent = parent
	return label
end

local waveLabel = makeLabel("WaveTimer", gui, UDim2.new(0.5, -150, 0, 10), UDim2.fromOffset(300, 44), 30, Color3.fromRGB(120, 220, 255))
waveLabel.AnchorPoint = Vector2.new(0.5, 0)
local goldenLabel = makeLabel("GoldenHour", gui, UDim2.new(0.5, -120, 0, 58), UDim2.fromOffset(240, 36), 20, Color3.fromRGB(255, 210, 40))
goldenLabel.AnchorPoint = Vector2.new(0.5, 0)
local bannerLabel = makeLabel("Banner", gui, UDim2.new(0.5, -260, 0, 110), UDim2.fromOffset(520, 56), 30, Color3.fromRGB(255, 90, 90))
bannerLabel.AnchorPoint = Vector2.new(0.5, 0)
bannerLabel.Visible = false

local coinsLabel = makeLabel("Coins", gui, UDim2.new(1, -330, 0, 10), UDim2.fromOffset(320, 52), 32, Color3.fromRGB(255, 220, 80))
coinsLabel.TextXAlignment = Enum.TextXAlignment.Right
local earningLabel = makeLabel("Earning", gui, UDim2.new(1, -330, 0, 66), UDim2.fromOffset(320, 40), 28, Color3.fromRGB(80, 255, 120))
earningLabel.TextXAlignment = Enum.TextXAlignment.Right
local floatLabel = makeLabel("IncomeFloat", gui, UDim2.new(1, -330, 0, 110), UDim2.fromOffset(320, 36), 28, Color3.fromRGB(80, 255, 120))
floatLabel.TextXAlignment = Enum.TextXAlignment.Right
floatLabel.BackgroundTransparency = 1
floatLabel.Visible = false

local basePanel = Instance.new("Frame")
basePanel.Name = "BasePanel"
basePanel.Position = UDim2.new(1, -320, 0, 190)
basePanel.Size = UDim2.fromOffset(310, 300)
basePanel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
basePanel.BackgroundTransparency = 0.4
basePanel.BorderSizePixel = 2
basePanel.BorderColor3 = Color3.fromRGB(255, 255, 255)
basePanel.Parent = gui
local baseTitle = makeLabel("BaseTitle", basePanel, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 36), 22, Color3.fromRGB(255, 255, 255))
baseTitle.BackgroundTransparency = 1
local baseList = makeLabel("BaseList", basePanel, UDim2.new(0, 6, 0, 40), UDim2.new(1, -12, 1, -46), 16, Color3.fromRGB(220, 220, 220))
baseList.BackgroundTransparency = 1
baseList.TextXAlignment = Enum.TextXAlignment.Left
baseList.TextYAlignment = Enum.TextYAlignment.Top
baseList.TextWrapped = true

local lockButton = Instance.new("TextButton")
lockButton.Name = "LockButton"
lockButton.Position = UDim2.new(1, -220, 1, -140)
lockButton.Size = UDim2.fromOffset(200, 50)
lockButton.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
lockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
lockButton.TextSize = 24
lockButton.Font = Enum.Font.GothamBold
lockButton.Text = "LOCK BASE (60s)"
lockButton.Parent = gui
local rebirthButton = Instance.new("TextButton")
rebirthButton.Name = "RebirthButton"
rebirthButton.Position = UDim2.new(1, -220, 1, -80)
rebirthButton.Size = UDim2.fromOffset(200, 50)
rebirthButton.BackgroundColor3 = Color3.fromRGB(170, 80, 255)
rebirthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rebirthButton.TextSize = 24
rebirthButton.Font = Enum.Font.GothamBold
rebirthButton.Text = "REBIRTH $10,000"
rebirthButton.Parent = gui

local hintLabel = makeLabel("Hint", gui, UDim2.new(0, 12, 1, -8), UDim2.fromOffset(620, 36), 20, Color3.fromRGB(255, 255, 255))
hintLabel.AnchorPoint = Vector2.new(0, 1)
hintLabel.Text = "Click a brainrot to BUY it - click a rival's to STEAL it - SLAP drops thieves!"
hintLabel.BackgroundTransparency = 0.4

local lastCoins = 0

function HUD.refreshStats()
	local coins = player:GetAttribute("Coins") or 0
	local income = player:GetAttribute("IncomePerSec") or 0
	local slotsUsed = player:GetAttribute("SlotsUsed") or 0
	local slotsMax = player:GetAttribute("SlotsMax") or 8
	local indexCount = player:GetAttribute("IndexCount") or 0
	local rebirths = player:GetAttribute("Rebirths") or 0
	local lockLeft = player:GetAttribute("LockLeft") or 0
	local lockCooldown = player:GetAttribute("LockCooldown") or 0
	local waveTimer = player:GetAttribute("WaveTimer")
	local waveWarning = player:GetAttribute("WaveWarning") or 0
	local goldenLeft = player:GetAttribute("GoldenLeft") or 0
	local mythicLeft = player:GetAttribute("MythicLeft") or 0
	local mult = player:GetAttribute("Multiplier") or 1
	coinsLabel.Text = "COINS $" .. tostring(coins)
	earningLabel.Text = "EARNING $" .. tostring(income) .. "/s  x" .. string.format("%.2f", mult)
	if coins > lastCoins and income > 0 then
		floatLabel.Text = "+$" .. tostring(income)
		floatLabel.Visible = true
		task.delay(1, function() floatLabel.Visible = false end)
	end
	lastCoins = coins
	if waveWarning > 0 then
		waveLabel.Text = "TSUNAMI IN " .. tostring(waveWarning) .. "s - RUN HOME!"
		waveLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
	elseif waveTimer ~= nil then
		local mins = math.floor(waveTimer / 60)
		local secs = waveTimer % 60
		waveLabel.Text = "NEXT WAVE " .. string.format("%02d:%02d", mins, secs)
		waveLabel.TextColor3 = Color3.fromRGB(120, 220, 255)
	else
		waveLabel.Text = "NEXT WAVE --:--"
	end
	if goldenLeft > 0 then
		goldenLabel.Text = "GOLDEN HOUR 2x! " .. tostring(goldenLeft) .. "s"
		goldenLabel.Visible = true
	elseif mythicLeft > 0 then
		goldenLabel.Text = "MYTHIC 2x! " .. tostring(mythicLeft) .. "s"
		goldenLabel.Visible = true
	else
		goldenLabel.Visible = false
	end
	local bannerText = player:GetAttribute("BannerText")
	local bannerUntil = player:GetAttribute("BannerUntil") or 0
	if bannerText and bannerText ~= "" and os.time() < bannerUntil then
		bannerLabel.Text = bannerText
		bannerLabel.Visible = true
	else
		bannerLabel.Visible = false
	end
	baseTitle.Text = "MY BASE - SLOTS " .. tostring(slotsUsed) .. "/" .. tostring(slotsMax) .. " - INDEX " .. tostring(indexCount) .. "/16"
	local lines = {}
	local character = player.Character
	if character then
		for _, model in ipairs(workspace:GetDescendants()) do
			if model:IsA("Model") and model:GetAttribute("OwnerId") == player.UserId then
				table.insert(lines, (model:GetAttribute("CharName") or model.Name) .. "  $" .. tostring(model:GetAttribute("Income") or 0) .. "/s")
			end
		end
	end
	if #lines == 0 then
		baseList.Text = "No brainrots yet!\nBuy one on the red carpet."
	else
		baseList.Text = table.concat(lines, "\n")
	end
	if lockLeft > 0 then
		lockButton.Text = "LOCKED " .. tostring(lockLeft) .. "s"
	elseif lockCooldown > 0 then
		lockButton.Text = "LOCK CD " .. tostring(lockCooldown) .. "s"
	else
		lockButton.Text = "LOCK BASE (60s)"
	end
	if rebirths > 0 then
		rebirthButton.Text = "REBIRTH x" .. tostring(rebirths) .. " - $10,000"
	else
		rebirthButton.Text = "REBIRTH $10,000"
	end
end

lockButton.MouseButton1Click:Connect(function()
	local event = ReplicatedStorage:WaitForChild("LockEvent")
	event:FireServer()
end)
rebirthButton.MouseButton1Click:Connect(function()
	local event = ReplicatedStorage:WaitForChild("RebirthEvent")
	event:FireServer()
end)

task.spawn(function()
	while true do
		task.wait(0.25)
		HUD.refreshStats()
	end
end)

-- Clicking a brainrot in the 3D world buys it (or steals it from a rival):
-- the client raycasts the mouse, the server validates and applies the buy.
local buyEvent = ReplicatedStorage:WaitForChild("BuyEvent")
local mouse = player:GetMouse()
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	local target = mouse.Target
	if not target then return end
	local model = target:FindFirstAncestorOfClass("Model")
	if not model or not model:GetAttribute("CharName") then return end
	buyEvent:FireServer(model)
end)
