-- Effects.client: buy/wave particles, floating income text, and the big centre banners.
-- Sound is decoration only; every piece of feedback here is visual first.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local bannerLabel = nil

local function makeBanner()
	local gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotEffects"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui
	bannerLabel = Instance.new("TextLabel")
	bannerLabel.Name = "Banner"
	bannerLabel.AnchorPoint = Vector2.new(0.5, 0)
	bannerLabel.Position = UDim2.new(0.5, 0, 0, 64)
	bannerLabel.Size = UDim2.fromOffset(760, 56)
	bannerLabel.BackgroundTransparency = 0.3
	bannerLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	bannerLabel.Text = ""
	bannerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	bannerLabel.TextSize = 34
	bannerLabel.Font = Enum.Font.GothamBold
	bannerLabel.Visible = false
	bannerLabel.Parent = gui
end

function playBuyEffect(position)
	local spark = Instance.new("Part")
	spark.Name = "BuySpark"
	spark.Size = Vector3.new(0.5, 0.5, 0.5)
	spark.Position = position + Vector3.new(0, 2, 0)
	spark.Anchored = true
	spark.CanCollide = false
	spark.Transparency = 1
	spark.Parent = workspace
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/fire_main.dds"
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
	emitter.Size = NumberSequence.new(1.5)
	emitter.Rate = 60
	emitter.Lifetime = NumberRange.new(0.6)
	emitter.Speed = NumberRange.new(8)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Parent = spark
	task.delay(1, function()
		emitter.Enabled = false
		task.wait(0.7)
		spark:Destroy()
	end)
	local ring = Instance.new("Part")
	ring.Name = "BuyRing"
	ring.Size = Vector3.new(1, 0.3, 1)
	ring.Position = position + Vector3.new(0, 1.2, 0)
	ring.Anchored = true
	ring.CanCollide = false
	ring.Color = Color3.fromRGB(255, 215, 0)
	ring.Material = Enum.Material.Neon
	ring.Parent = workspace
	local tween = TweenService:Create(ring, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(10, 0.3, 10), Transparency = 1 })
	tween:Play()
	tween.Completed:Connect(function()
		ring:Destroy()
	end)
end

local function showBanner(text, colorName)
	local colors = {
		Red = Color3.fromRGB(255, 80, 80),
		Green = Color3.fromRGB(120, 255, 120),
		Blue = Color3.fromRGB(120, 200, 255),
		Gold = Color3.fromRGB(255, 215, 0),
		Yellow = Color3.fromRGB(255, 240, 120),
		White = Color3.fromRGB(255, 255, 255),
	}
	bannerLabel.Text = text
	bannerLabel.TextColor3 = colors[colorName] or colors.White
	bannerLabel.Visible = true
	task.delay(3, function()
		bannerLabel.Visible = false
	end)
end

local function showFloatText(amount, position)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(160, 44)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 0, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = nil
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	if amount >= 0 then
		label.Text = "+$" .. tostring(amount)
		label.TextColor3 = Color3.fromRGB(120, 255, 120)
	else
		label.Text = "-$" .. tostring(-amount)
		label.TextColor3 = Color3.fromRGB(255, 80, 80)
	end
	label.TextSize = 30
	label.Font = Enum.Font.GothamBold
	label.Parent = billboard
	local anchor = Instance.new("Part")
	anchor.Name = "FloatAnchor"
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Position = position
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Transparency = 1
	anchor.Parent = workspace
	billboard.Adornee = anchor
	billboard.Parent = anchor
	local tween = TweenService:Create(anchor, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = position + Vector3.new(0, 8, 0) })
	tween:Play()
	tween.Completed:Connect(function()
		anchor:Destroy()
	end)
end

makeBanner()
local remotes = ReplicatedStorage:WaitForChild("Remotes")
remotes.Banner.OnClientEvent:Connect(showBanner)
remotes.BuyFx.OnClientEvent:Connect(playBuyEffect)
remotes.FloatText.OnClientEvent:Connect(showFloatText)
