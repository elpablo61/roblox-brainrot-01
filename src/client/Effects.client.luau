-- Effects: buy/wave/steal/rebirth feedback — particle bursts, banners and
-- sounds. Every game event has a visible form, never sound alone.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local notify = ReplicatedStorage:WaitForChild("BrainrotNotify")

local Effects = {}

function Effects.playBuyEffect(data)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 220, 60))
	emitter.Size = NumberSequence.new(1.2)
	emitter.Lifetime = NumberRange.new(0.6, 1)
	emitter.Rate = 60
	emitter.Speed = NumberRange.new(8, 16)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Parent = root
	Effects.playSound("rbxasset://sounds/electronicpingshort.wav", 0.7)
	task.delay(1.2, function()
		emitter:Destroy()
	end)
end

function Effects.playWaveEffect()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(0, 150, 255))
	emitter.Size = NumberSequence.new(2)
	emitter.Lifetime = NumberRange.new(0.8, 1.4)
	emitter.Rate = 80
	emitter.Speed = NumberRange.new(10, 20)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Parent = root
	Effects.playSound("rbxasset://sounds/impact_water.mp3", 0.7)
	task.delay(1.6, function()
		emitter:Destroy()
	end)
end

function Effects.playSound(soundId, volume)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.5
	sound.Parent = player:WaitForChild("PlayerGui")
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	task.delay(5, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end

notify.OnClientEvent:Connect(function(kind, text)
	if kind == "bought" then
		Effects.playBuyEffect(text)
	elseif kind == "wave-warning" or kind == "wave-sweep" then
		Effects.playWaveEffect()
	elseif kind == "effect-buy" then
		if text ~= player.Name then
			Effects.playBuyEffect(text)
		end
	elseif kind == "rebirth" or kind == "effect-rebirth" then
		Effects.playSound("rbxasset://sounds/electronicpingshort.wav", 0.8)
	elseif kind == "golden" or kind == "mythic" then
		Effects.playSound("rbxasset://sounds/electronicpingshort.wav", 0.8)
	end
end)
