-- Brainrot Blitz effects: buy bursts, floating +$ income text, coin-drop
-- text, slap and wave feedback, and the Slap tool's click wiring. Every
-- feedback has a visible form; sound is decoration only.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Effects = {}

function Effects.playBuyEffect(position)
	local anchor = Instance.new("Part")
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CFrame = CFrame.new(position)
	anchor.Parent = workspace
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
	emitter.Size = NumberSequence.new(0.8)
	emitter.Lifetime = NumberRange.new(0.6, 1)
	emitter.Rate = 0
	emitter.Speed = NumberRange.new(12, 20)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Parent = anchor
	emitter:Emit(40)
	Effects.playSound("rbxasset://sounds/electronicpingshort.wav", position)
	task.delay(2, function()
		anchor:Destroy()
	end)
end

function Effects.playSound(soundId, position)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = 0.6
	sound.Parent = workspace
	if position then
		sound.Position = position
	end
	sound:Play()
	task.delay(3, function()
		sound:Destroy()
	end)
end

function Effects.floatText(position, text, color)
	local anchor = Instance.new("Part")
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
	anchor.Parent = workspace
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 160, 0, 50)
	gui.AlwaysOnTop = true
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.TextSize = 28
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
	local tween = TweenService:Create(anchor, TweenInfo.new(2, Enum.EasingStyle.Linear), {
		CFrame = CFrame.new(position + Vector3.new(0, 10, 0)),
	})
	tween:Play()
	task.delay(2, function()
		anchor:Destroy()
	end)
end

function Effects.playWaveEffect()
	Effects.playSound("rbxasset://sounds/electronicpingshort.wav")
	Effects.playSound("rbxasset://sounds/electronicpingshort.wav")
end

function Effects.playSlapEffect(position)
	local anchor = Instance.new("Part")
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CFrame = CFrame.new(position)
	anchor.Parent = workspace
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 80, 80))
	emitter.Size = NumberSequence.new(1)
	emitter.Lifetime = NumberRange.new(0.4, 0.8)
	emitter.Rate = 0
	emitter.Speed = NumberRange.new(15, 25)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Parent = anchor
	emitter:Emit(30)
	task.delay(2, function()
		anchor:Destroy()
	end)
end

local function wireSlapTool(tool)
	if tool.Name ~= "Slap" then
		return
	end
	tool.Activated:Connect(function()
		local remotes = ReplicatedStorage:WaitForChild("Remotes")
		remotes.SlapRequest:FireServer()
	end)
end

local function connectNotify()
	local notify = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify")
	notify.OnClientEvent:Connect(function(kind, a, b)
		if kind == "Income" then
			Effects.floatText(b, "+$" .. a, Color3.fromRGB(80, 255, 120))
		elseif kind == "CoinDrop" then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				Effects.floatText(root.Position, "-" .. a .. " coins", Color3.fromRGB(255, 80, 80))
			end
		elseif kind == "Buy" then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				Effects.playBuyEffect(root.Position)
			end
		elseif kind == "WaveWarning" then
			Effects.playSound("rbxasset://sounds/electronicpingshort.wav")
		elseif kind == "WaveSweep" then
			Effects.playWaveEffect()
		elseif kind == "SlapEffect" then
			Effects.playSlapEffect(a)
		elseif kind == "Rebirth" then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				Effects.playBuyEffect(root.Position)
			end
		end
	end)
end

local function connectSlapTool()
	local backpack = player:WaitForChild("Backpack")
	for _, tool in ipairs(backpack:GetChildren()) do
		wireSlapTool(tool)
	end
	backpack.ChildAdded:Connect(wireSlapTool)
end

connectNotify()
connectSlapTool()
