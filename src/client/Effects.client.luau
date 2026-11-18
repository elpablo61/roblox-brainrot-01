-- Effects plays buy and wave feedback on the client: particles, a flash
-- of light at the bought brainrot, and a screen flash when the tsunami hits.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local Effects = {}

function Effects.playBuyEffect(position)
	local sparkle = Instance.new("Part")
	sparkle.Name = "BuySparkle"
	sparkle.Anchored = true
	sparkle.CanCollide = false
	sparkle.Transparency = 1
	sparkle.Size = Vector3.new(1, 1, 1)
	sparkle.CFrame = CFrame.new(position + Vector3.new(0, 2, 0))
	sparkle.Parent = workspace
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 210, 40))
	emitter.Size = NumberSequence.new(1.5)
	emitter.Lifetime = NumberRange.new(0.8)
	emitter.Rate = 60
	emitter.Speed = NumberRange.new(8)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Parent = sparkle
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 210, 40)
	light.Range = 18
	light.Brightness = 3
	light.Parent = sparkle
	TweenService:Create(light, TweenInfo.new(1), { Brightness = 0 }):Play()
	task.delay(1, function()
		emitter.Enabled = false
	end)
	Debris:AddItem(sparkle, 2)
end

local buyEvent = ReplicatedStorage:WaitForChild("BuyEffectEvent")
buyEvent.OnClientEvent:Connect(function(position)
	Effects.playBuyEffect(position)
end)

player:GetAttributeChangedSignal("BannerText"):Connect(function()
	local banner = player:GetAttribute("BannerText") or ""
	if string.find(banner, "TSUNAMI") then
		local gui = player:FindFirstChild("PlayerGui")
		if gui then
			local hud = gui:FindFirstChild("BrainrotHUD")
			if hud then
				local flash = Instance.new("Frame")
				flash.Name = "WaveFlash"
				flash.Size = UDim2.fromScale(1, 1)
				flash.BackgroundColor3 = Color3.fromRGB(40, 140, 255)
				flash.BackgroundTransparency = 0.7
				flash.BorderSizePixel = 0
				flash.Parent = hud
				TweenService:Create(flash, TweenInfo.new(1.5), { BackgroundTransparency = 1 }):Play()
				Debris:AddItem(flash, 2)
			end
		end
	end
end)

return Effects
