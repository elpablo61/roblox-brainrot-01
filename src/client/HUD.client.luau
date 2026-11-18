-- HUD builds the Brainrot Blitz interface: coins, income, wave timer, base panel, lock, rebirth.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local HUD = {}
local labels = {}
local bannerUntil = 0
local bannerConn = nil

function HUD.refreshStats()
	local coins = player:GetAttribute("Coins") or Config.START_COINS
	local income = player:GetAttribute("Income") or 0
	local rebirths = player:GetAttribute("Rebirths") or 0
	local owned = player:GetAttribute("Owned") or 0
	local slots = player:GetAttribute("Slots") or Config.BASE_SLOTS
	local lockLeft = player:GetAttribute("LockLeft") or 0
	local mult = player:GetAttribute("Multiplier") or 1
	local index = player:GetAttribute("IndexCount") or 0
	local gs = ReplicatedStorage:FindFirstChild("GameState")
	local waveTimer = gs and (gs:GetAttribute("WaveTimer") or Config.WAVE_EVERY) or Config.WAVE_EVERY
	local wavePhase = gs and (gs:GetAttribute("WavePhase") or "calm") or "calm"
	local goldenLeft = gs and (gs:GetAttribute("GoldenLeft") or 0) or 0
	local mythicLeft = gs and (gs:GetAttribute("MythicLeft") or 0) or 0

	if labels.coins then
		labels.coins.Text = "COINS: $" .. coins
	end
	if labels.income then
		labels.income.Text = "EARNING $" .. income .. "/s  x" .. mult
	end
	if labels.wave then
		if wavePhase == "warning" then
			labels.wave.Text = "TSUNAMI IN " .. waveTimer .. "s - RUN HOME!"
			labels.wave.TextColor3 = Color3.fromRGB(255, 80, 80)
		elseif wavePhase == "sweep" then
			labels.wave.Text = "TSUNAMI! GET INSIDE YOUR BASE!"
			labels.wave.TextColor3 = Color3.fromRGB(255, 80, 80)
		else
			local mins = math.floor(waveTimer / 60)
			local secs = waveTimer % 60
			labels.wave.Text = "NEXT WAVE " .. string.format("%02d:%02d", mins, secs)
			labels.wave.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end
	if labels.event then
		if goldenLeft > 0 and mythicLeft > 0 then
			labels.event.Text = "GOLDEN + MYTHIC 2x!"
			labels.event.Visible = true
		elseif goldenLeft > 0 then
			labels.event.Text = "GOLDEN HOUR 2x! " .. goldenLeft .. "s"
			labels.event.Visible = true
		elseif mythicLeft > 0 then
			labels.event.Text = "MYTHIC 2x! " .. mythicLeft .. "s"
			labels.event.Visible = true
		else
			labels.event.Visible = false
		end
	end
	if labels.base then
		labels.base.Text = "MY BASE  SLOTS " .. owned .. "/" .. slots .. "\nREBIRTHS: " .. rebirths .. "  (x" .. mult .. ")\nINDEX: " .. index .. "/16 brainrots"
	end
	if labels.lock then
		if lockLeft > 0 then
			labels.lock.Text = "LOCKED " .. lockLeft .. "s"
			labels.lock.BackgroundColor3 = Color3.fromRGB(60, 160, 80)
		else
			labels.lock.Text = "LOCK BASE (60s)"
			labels.lock.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
		end
	end
	if labels.rebirth then
		labels.rebirth.Text = "REBIRTH $" .. Config.REBIRTH_COST .. "  x1.25"
	end
end

function HUD.showBanner(text, color)
	local banner = labels.banner
	if not banner then
		return
	end
	banner.Text = text
	banner.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	banner.Visible = true
	bannerUntil = tick() + 5
	if bannerConn then
		task.cancel(bannerConn)
	end
	bannerConn = task.delay(5, function()
		if tick() >= bannerUntil then
			banner.Visible = false
		end
	end)
end

function HUD.showFloat(text)
	local gui = labels.gui
	if not gui then
		return
	end
	local float = Instance.new("TextLabel")
	float.Size = UDim2.new(0, 200, 0, 36)
	float.Position = UDim2.new(0.5, -100, 0.62, 0)
	float.BackgroundTransparency = 1
	float.Text = text
	float.TextColor3 = Color3.fromRGB(120, 255, 140)
	float.TextStrokeTransparency = 0
	float.Font = Enum.Font.GothamBold
	float.TextSize = 30
	float.Parent = gui
	local tween = TweenService:Create(float, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, -100, 0.5, 0), TextTransparency = 1 })
	tween:Play()
	tween.Completed:Connect(function()
		float:Destroy()
	end)
end

local function makeLabel(parent, name, text, pos, size, textSize, color)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Text = text
	l.Position = pos
	l.Size = size
	l.BackgroundTransparency = 0.4
	l.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	l.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	l.TextStrokeTransparency = 0
	l.Font = Enum.Font.GothamBold
	l.TextSize = textSize
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

local function makeButton(parent, name, text, pos, size, color)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Text = text
	b.Position = pos
	b.Size = size
	b.BackgroundColor3 = color
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.TextStrokeTransparency = 0
	b.Font = Enum.Font.GothamBold
	b.TextSize = 26
	b.Parent = parent
	return b
end

local function buildGui()
	local gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotHUD"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")
	labels.gui = gui

	labels.coins = makeLabel(gui, "Coins", "COINS: $150", UDim2.new(1, -330, 0, 12), UDim2.new(0, 320, 0, 44), 30)
	labels.income = makeLabel(gui, "Income", "EARNING $0/s  x1", UDim2.new(1, -330, 0, 62), UDim2.new(0, 320, 0, 40), 28)
	labels.wave = makeLabel(gui, "Wave", "NEXT WAVE 02:00", UDim2.new(0.5, -220, 0, 12), UDim2.new(0, 440, 0, 44), 30)
	labels.event = makeLabel(gui, "Event", "", UDim2.new(0.5, -180, 0, 62), UDim2.new(0, 360, 0, 36), 26, Color3.fromRGB(255, 215, 0))
	labels.event.Visible = false

	local banner = Instance.new("TextLabel")
	banner.Name = "Banner"
	banner.Size = UDim2.new(0, 700, 0, 54)
	banner.Position = UDim2.new(0.5, -350, 0, 110)
	banner.BackgroundTransparency = 0.4
	banner.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	banner.Text = ""
	banner.TextColor3 = Color3.fromRGB(255, 255, 255)
	banner.TextStrokeTransparency = 0
	banner.Font = Enum.Font.GothamBold
	banner.TextSize = 30
	banner.Visible = false
	banner.Parent = gui
	labels.banner = banner

	-- Base panel on the right, top at y=190 so every row stays visible above the lock button.
	labels.base = makeLabel(gui, "BasePanel", "MY BASE  SLOTS 0/8", UDim2.new(1, -330, 0, 190), UDim2.new(0, 320, 0, 110), 24)
	labels.base.TextYAlignment = Enum.TextYAlignment.Top

	labels.lock = makeButton(gui, "LockButton", "LOCK BASE (60s)", UDim2.new(1, -330, 1, -130), UDim2.new(0, 320, 0, 56), Color3.fromRGB(200, 60, 60))
	labels.rebirth = makeButton(gui, "RebirthButton", "REBIRTH $10000  x1.25", UDim2.new(1, -330, 1, -66), UDim2.new(0, 320, 0, 56), Color3.fromRGB(150, 80, 220))

	labels.hint = makeLabel(gui, "Hint", "Click a brainrot on the belt to BUY it - steal rivals when their lock is OFF", UDim2.new(0, 12, 1, -44), UDim2.new(0, 440, 0, 34), 20)
	labels.hint.BackgroundTransparency = 0.55

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	labels.lock.MouseButton1Click:Connect(function()
		remotes:WaitForChild("LockEvent"):FireServer()
	end)
	labels.rebirth.MouseButton1Click:Connect(function()
		remotes:WaitForChild("RebirthEvent"):FireServer()
	end)
	remotes:WaitForChild("HudEvent").OnClientEvent:Connect(function(kind, a, b)
		if kind == "Banner" then
			HUD.showBanner(a, b)
		elseif kind == "Float" then
			HUD.showFloat(a)
		elseif kind == "Buy" then
			HUD.showBanner("BOUGHT " .. a .. "!", Color3.fromRGB(80, 255, 120))
		elseif kind == "Rebirth" then
			HUD.showBanner("REBIRTH #" .. a .. "! Income x1.25 forever!", Color3.fromRGB(255, 215, 0))
		end
	end)
end

buildGui()
task.spawn(function()
	while true do
		task.wait(0.25)
		HUD.refreshStats()
	end
end)
