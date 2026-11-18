-- Effects: visual feedback for buys, waves and events. No uploaded assets:
-- particles, tweens and screen flashes only, so the feedback survives on
-- any account that opens the place.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local gameState = ReplicatedStorage:WaitForChild("GameState")

local Effects = {}

function Effects.playBuyEffect(model)
	if not model or not model.PrimaryPart then
		return
	end
	local burst = Instance.new("ParticleEmitter")
	burst.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
	burst.Size = NumberSequence.new(1.2)
	burst.Lifetime = NumberRange.new(0.6)
	burst.Rate = 60
	burst.Speed = NumberRange.new(12)
	burst.SpreadAngle = Vector2.new(180, 180)
	burst.Parent = model.PrimaryPart
	task.delay(1, function()
		burst.Enabled = false
		task.wait(1)
		burst:Destroy()
	end)
	local startSize = model.PrimaryPart.Size
	local goal = { Size = startSize * 1.25 }
	local tween = TweenService:Create(model.PrimaryPart, TweenInfo.new(0.25), goal)
	tween:Play()
	tween.Completed:Connect(function()
		TweenService:Create(model.PrimaryPart, TweenInfo.new(0.25), { Size = startSize }):Play()
	end)
end

local flash = Instance.new("Frame")
flash.Name = "WaveFlash"
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundColor3 = Color3.fromRGB(40, 140, 255)
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.Parent = playerGui:WaitForChild("BrainrotHUD")

local lastOwned = 0
local lastPhase = "calm"

task.spawn(function()
	while true do
		task.wait(0.5)
		local owned = player:GetAttribute("OwnedCount") or 0
		if owned > lastOwned then
			local baseIndex = player:GetAttribute("BaseIndex") or 0
			local bases = workspace:FindFirstChild("Bases")
			local base = bases and bases:FindFirstChild("Base" .. baseIndex)
			if base then
				local newest = nil
				for _, desc in ipairs(base:GetDescendants()) do
					if desc:IsA("Model") and desc:GetAttribute("OwnerId") == player.UserId then
						newest = desc
					end
				end
				if newest then
					Effects.playBuyEffect(newest)
				end
			end
		end
		lastOwned = owned
		local phase = gameState:GetAttribute("WavePhase") or "calm"
		if phase == "sweep" and lastPhase ~= "sweep" then
			flash.BackgroundTransparency = 0.6
			TweenService:Create(flash, TweenInfo.new(1.5), { BackgroundTransparency = 1 }):Play()
		end
		if phase == "warning" and lastPhase ~= "warning" then
			flash.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
			flash.BackgroundTransparency = 0.75
			TweenService:Create(flash, TweenInfo.new(1), { BackgroundTransparency = 1 }):Play()
			flash.BackgroundColor3 = Color3.fromRGB(40, 140, 255)
		end
		lastPhase = phase
	end
end)

return Effects
