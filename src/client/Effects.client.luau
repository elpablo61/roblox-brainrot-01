-- Effects plays buy, wave, rebirth and Golden Hour feedback: particles, flashes, banners.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local Effects = {}

function Effects.playBuyEffect(position)
	if not position then
		return
	end
	local anchor = Instance.new("Part")
	anchor.Name = "BuyBurst"
	anchor.Size = Vector3.new(0.5, 0.5, 0.5)
	anchor.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Transparency = 1
	anchor.Parent = workspace
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/fire_main.dds"
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
	emitter.Size = NumberSequence.new(1.2)
	emitter.Lifetime = NumberRange.new(0.6, 1)
	emitter.Rate = 60
	emitter.Speed = NumberRange.new(8, 16)
	emitter.Parent = anchor
	task.delay(1.5, function()
		anchor:Destroy()
	end)
end

function Effects.playWaveEffect()
	local gui = player.PlayerGui:FindFirstChild("BrainrotHUD")
	if not gui then
		return
	end
	local flash = Instance.new("Frame")
	flash.Name = "WaveFlash"
	flash.Size = UDim2.new(1, 0, 1, 0)
	flash.BackgroundColor3 = Color3.fromRGB(60, 140, 255)
	flash.BackgroundTransparency = 0.7
	flash.Parent = gui
	local tween = TweenService:Create(flash, TweenInfo.new(1.2), { BackgroundTransparency = 1 })
	tween:Play()
	tween.Completed:Connect(function()
		flash:Destroy()
	end)
end

function Effects.playGoldenEffect()
	local gui = player.PlayerGui:FindFirstChild("BrainrotHUD")
	if not gui then
		return
	end
	local flash = Instance.new("Frame")
	flash.Name = "GoldenFlash"
	flash.Size = UDim2.new(1, 0, 1, 0)
	flash.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	flash.BackgroundTransparency = 0.75
	flash.Parent = gui
	local tween = TweenService:Create(flash, TweenInfo.new(1.5), { BackgroundTransparency = 1 })
	tween:Play()
	tween.Completed:Connect(function()
		flash:Destroy()
	end)
end

local remotes = ReplicatedStorage:WaitForChild("Remotes")
remotes:WaitForChild("HudEvent").OnClientEvent:Connect(function(kind, a, b)
	if kind == "Buy" then
		Effects.playBuyEffect(b)
	elseif kind == "Wave" then
		Effects.playWaveEffect()
	elseif kind == "Golden" then
		Effects.playGoldenEffect()
	end
end)

return Effects
