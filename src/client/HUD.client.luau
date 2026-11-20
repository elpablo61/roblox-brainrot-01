-- Brainrot Blitz HUD: coins, EARNING $/s, wave timer, base panel, index
-- panel, lock and rebirth buttons, and every banner. All text stays clear
-- of the top-left corner, where Roblox puts its menu buttons.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local HUD = {}

local CoinsLabel
local EarningLabel
local WaveLabel
local LockButton
local RebirthButton
local BaseList
local SlotsLabel
local IndexLabel
local BannerLabel
local BoostLabel
local ToastLabel
local OwnedList = {}
local BannerUntil = 0

local function formatTime(seconds)
	seconds = math.max(0, math.floor(seconds + 0.5))
	local minutes = math.floor(seconds / 60)
	local rest = seconds % 60
	return string.format("%02d:%02d", minutes, rest)
end

function HUD.refreshStats()
	local coins = player:GetAttribute("Coins") or 150
	local income = player:GetAttribute("Income") or 0
	local rebirths = player:GetAttribute("Rebirths") or 0
	local slotsUsed = player:GetAttribute("SlotsUsed") or 0
	local slotsMax = player:GetAttribute("SlotsMax") or 8
	local indexCount = player:GetAttribute("IndexCount") or 0
	local lockSeconds = player:GetAttribute("LockSeconds") or 0
	local lockCooldown = player:GetAttribute("LockCooldown") or 0
	CoinsLabel.Text = "$" .. coins
	EarningLabel.Text = "EARNING $" .. income .. "/s"
	local state = ReplicatedStorage:FindFirstChild("GameState")
	local waveTimer = state and state:GetAttribute("WaveTimer") or 120
	WaveLabel.Text = "NEXT WAVE " .. formatTime(waveTimer)
	SlotsLabel.Text = "SLOTS " .. slotsUsed .. "/" .. slotsMax
	local percent = math.floor(indexCount / 16 * 100 + 0.5)
	IndexLabel.Text = "INDEX " .. indexCount .. "/16  •  " .. percent .. "%"
	if lockSeconds > 0 then
		LockButton.Text = "LOCKED " .. lockSeconds .. "s"
		LockButton.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
	else
		if lockCooldown > 0 then
			LockButton.Text = "LOCK (" .. lockCooldown .. "s)"
		else
			LockButton.Text = "LOCK BASE (60s)"
		end
		LockButton.BackgroundColor3 = Color3.fromRGB(40, 120, 220)
	end
	if rebirths > 0 then
		RebirthButton.Text = "REBIRTH $" .. 10000 .. "  •  x" .. (1 + rebirths * 0.25)
	else
		RebirthButton.Text = "REBIRTH $10,000  •  x1.25"
	end
	local boost = state and (state:GetAttribute("GoldenActive") or state:GetAttribute("MythicActive"))
	BoostLabel.Visible = boost == true
	if boost then
		BoostLabel.Text = "2x INCOME ACTIVE!"
	end
	HUD.refreshBaseList()
end

function HUD.refreshBaseList()
	for _, child in ipairs(BaseList:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	if #OwnedList == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, 0, 0, 26)
		empty.BackgroundTransparency = 1
		empty.Text = "No brainrots yet — buy one!"
		empty.TextColor3 = Color3.fromRGB(220, 220, 220)
		empty.TextSize = 20
		empty.Font = Enum.Font.Gotham
		empty.Parent = BaseList
		return
	end
	for _, entry in ipairs(OwnedList) do
		local row = Instance.new("TextLabel")
		row.Size = UDim2.new(1, 0, 0, 26)
		row.BackgroundTransparency = 1
		row.Text = entry.Name .. "  $" .. entry.Rate .. "/s"
		row.TextColor3 = Color3.fromRGB(255, 255, 255)
		row.TextSize = 20
		row.Font = Enum.Font.Gotham
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Parent = BaseList
	end
end

function HUD.showBanner(text, color, seconds)
	BannerLabel.Text = text
	BannerLabel.BackgroundColor3 = color
	BannerLabel.Visible = true
	BannerUntil = os.clock() + (seconds or 4)
end

function HUD.showToast(text, color)
	ToastLabel.Text = text
	ToastLabel.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	ToastLabel.Visible = true
	task.delay(3, function()
		ToastLabel.Visible = false
	end)
end

local function makeLabel(parent, name, text, size, position, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0
	label.TextSize = textSize
	label.Font = Enum.Font.GothamBold
	label.Parent = parent
	return label
end

local function buildGui()
	local gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotHUD"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")
	WaveLabel = makeLabel(gui, "WaveTimer", "NEXT WAVE 02:00", UDim2.new(0, 300, 0, 44),
		UDim2.new(0.5, -150, 0, 8), 30, Color3.fromRGB(120, 200, 255))
	WaveLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	WaveLabel.BackgroundTransparency = 0.4
	CoinsLabel = makeLabel(gui, "Coins", "$150", UDim2.new(0, 220, 0, 44),
		UDim2.new(1, -240, 0, 8), 32, Color3.fromRGB(255, 230, 0))
	CoinsLabel.TextXAlignment = Enum.TextXAlignment.Right
	EarningLabel = makeLabel(gui, "Earning", "EARNING $0/s", UDim2.new(0, 260, 0, 40),
		UDim2.new(1, -280, 0, 54), 30, Color3.fromRGB(80, 255, 120))
	EarningLabel.TextXAlignment = Enum.TextXAlignment.Right
	BoostLabel = makeLabel(gui, "Boost", "2x INCOME ACTIVE!", UDim2.new(0, 300, 0, 32),
		UDim2.new(0.5, -150, 0, 56), 24, Color3.fromRGB(255, 215, 0))
	BoostLabel.Visible = false
	BannerLabel = Instance.new("TextLabel")
	BannerLabel.Name = "Banner"
	BannerLabel.Size = UDim2.new(0, 640, 0, 52)
	BannerLabel.Position = UDim2.new(0.5, -320, 0, 96)
	BannerLabel.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
	BannerLabel.BackgroundTransparency = 0.15
	BannerLabel.Text = ""
	BannerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	BannerLabel.TextStrokeTransparency = 0
	BannerLabel.TextSize = 32
	BannerLabel.Font = Enum.Font.GothamBold
	BannerLabel.Visible = false
	BannerLabel.Parent = gui
	ToastLabel = makeLabel(gui, "Toast", "", UDim2.new(0, 600, 0, 34),
		UDim2.new(0.5, -300, 0, 156), 24, Color3.fromRGB(255, 255, 255))
	ToastLabel.Visible = false
	local basePanel = Instance.new("Frame")
	basePanel.Name = "BasePanel"
	basePanel.Size = UDim2.new(0, 300, 0, 330)
	basePanel.Position = UDim2.new(1, -320, 0, 110)
	basePanel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	basePanel.BackgroundTransparency = 0.35
	basePanel.Parent = gui
	local title = makeLabel(basePanel, "Title", "MY BASE", UDim2.new(1, 0, 0, 36),
		UDim2.new(0, 0, 0, 4), 28, Color3.fromRGB(255, 255, 255))
	title.TextXAlignment = Enum.TextXAlignment.Left
	SlotsLabel = makeLabel(basePanel, "Slots", "SLOTS 0/8", UDim2.new(1, 0, 0, 28),
		UDim2.new(0, 0, 0, 40), 22, Color3.fromRGB(255, 230, 0))
	SlotsLabel.TextXAlignment = Enum.TextXAlignment.Left
	IndexLabel = makeLabel(basePanel, "Index", "INDEX 0/16  •  0%", UDim2.new(1, 0, 0, 28),
		UDim2.new(0, 0, 0, 68), 22, Color3.fromRGB(120, 200, 255))
	IndexLabel.TextXAlignment = Enum.TextXAlignment.Left
	BaseList = Instance.new("Frame")
	BaseList.Name = "BaseList"
	BaseList.Size = UDim2.new(1, -8, 0, 220)
	BaseList.Position = UDim2.new(0, 4, 0, 100)
	BaseList.BackgroundTransparency = 1
	BaseList.Parent = basePanel
	local hint = makeLabel(gui, "Hint", "Click a brainrot on the RED conveyor to BUY it!",
		UDim2.new(0, 560, 0, 30), UDim2.new(0, 20, 1, -110), 20, Color3.fromRGB(255, 255, 255))
	hint.TextXAlignment = Enum.TextXAlignment.Left
	local hint2 = makeLabel(gui, "Hint2", "STEAL rivals, LOCK your base, SURVIVE the tsunami!",
		UDim2.new(0, 560, 0, 30), UDim2.new(0, 20, 1, -80), 20, Color3.fromRGB(255, 230, 0))
	hint2.TextXAlignment = Enum.TextXAlignment.Left
	LockButton = Instance.new("TextButton")
	LockButton.Name = "LockButton"
	LockButton.Size = UDim2.new(0, 220, 0, 52)
	LockButton.Position = UDim2.new(0.5, -240, 1, -64)
	LockButton.BackgroundColor3 = Color3.fromRGB(40, 120, 220)
	LockButton.Text = "LOCK BASE (60s)"
	LockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	LockButton.TextSize = 24
	LockButton.Font = Enum.Font.GothamBold
	LockButton.Parent = gui
	RebirthButton = Instance.new("TextButton")
	RebirthButton.Name = "RebirthButton"
	RebirthButton.Size = UDim2.new(0, 260, 0, 52)
	RebirthButton.Position = UDim2.new(0.5, 10, 1, -64)
	RebirthButton.BackgroundColor3 = Color3.fromRGB(170, 80, 255)
	RebirthButton.Text = "REBIRTH $10,000  •  x1.25"
	RebirthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	RebirthButton.TextSize = 24
	RebirthButton.Font = Enum.Font.GothamBold
	RebirthButton.Parent = gui
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	LockButton.MouseButton1Click:Connect(function()
		remotes.LockRequest:FireServer()
	end)
	RebirthButton.MouseButton1Click:Connect(function()
		remotes.RebirthRequest:FireServer()
	end)
end

local function connectNotify()
	local notify = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify")
	notify.OnClientEvent:Connect(function(kind, a, b)
		if kind == "Buy" then
			HUD.showToast("BOUGHT " .. a .. " — $" .. b .. "/s!", Color3.fromRGB(80, 255, 120))
		elseif kind == "Deny" then
			HUD.showToast(a, Color3.fromRGB(255, 80, 80))
		elseif kind == "WaveWarning" then
			HUD.showBanner("TSUNAMI IN " .. a .. "s — RUN HOME!", Color3.fromRGB(200, 0, 0), a)
		elseif kind == "WaveCountdown" then
			BannerLabel.Text = "TSUNAMI IN " .. a .. "s — RUN HOME!"
			BannerLabel.Visible = true
			BannerUntil = os.clock() + 2
		elseif kind == "WaveSweep" then
			HUD.showBanner("TSUNAMI! GET TO YOUR BASE!", Color3.fromRGB(0, 120, 255), 5)
		elseif kind == "GoldenHour" then
			HUD.showBanner("GOLDEN HOUR — 2x INCOME!", Color3.fromRGB(255, 200, 0), 6)
		elseif kind == "Mythic" then
			HUD.showBanner("MYTHIC SPAWN: " .. a .. " — 2x INCOME 60s!", Color3.fromRGB(255, 60, 60), 6)
		elseif kind == "Stolen" then
			HUD.showBanner("STOLEN! " .. b .. " took your " .. a .. "!", Color3.fromRGB(255, 0, 0), 5)
		elseif kind == "Steal" then
			HUD.showToast("You stole " .. a .. " — run it home!", Color3.fromRGB(255, 200, 0))
		elseif kind == "Deliver" then
			HUD.showToast("DELIVERED " .. a .. " to your base!", Color3.fromRGB(80, 255, 120))
		elseif kind == "Lock" then
			HUD.showToast("Base LOCKED for " .. a .. "s!", Color3.fromRGB(80, 255, 120))
		elseif kind == "Rebirth" then
			HUD.showBanner("REBIRTH x" .. (1 + a * 0.25) .. " — +" .. 2 .. " SLOTS!", Color3.fromRGB(170, 80, 255), 6)
		elseif kind == "Slap" then
			HUD.showToast("You SLAPPED " .. a .. "!", Color3.fromRGB(255, 200, 0))
		elseif kind == "Slapped" then
			HUD.showToast(a .. " SLAPPED you!", Color3.fromRGB(255, 80, 80))
		elseif kind == "BoughtBanner" then
			HUD.showToast(a .. " bought " .. b .. "!", Color3.fromRGB(220, 220, 220))
		elseif kind == "StealBanner" then
			HUD.showToast(a .. " STOLE " .. b .. "!", Color3.fromRGB(255, 150, 0))
		elseif kind == "RebirthBanner" then
			HUD.showToast(a .. " REBIRTHED x" .. (1 + b * 0.25) .. "!", Color3.fromRGB(200, 120, 255))
		elseif kind == "BaseList" then
			OwnedList = a or {}
			HUD.refreshBaseList()
		end
	end)
end

buildGui()
connectNotify()
player:GetAttributeChangedSignal("Coins"):Connect(HUD.refreshStats)
player:GetAttributeChangedSignal("Income"):Connect(HUD.refreshStats)
player:GetAttributeChangedSignal("LockSeconds"):Connect(HUD.refreshStats)
player:GetAttributeChangedSignal("LockCooldown"):Connect(HUD.refreshStats)
player:GetAttributeChangedSignal("SlotsUsed"):Connect(HUD.refreshStats)
player:GetAttributeChangedSignal("IndexCount"):Connect(HUD.refreshStats)
task.spawn(function()
	while true do
		task.wait(1)
		HUD.refreshStats()
		if BannerLabel.Visible and os.clock() > BannerUntil then
			BannerLabel.Visible = false
		end
	end
end)
HUD.refreshStats()
