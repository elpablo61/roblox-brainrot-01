-- Brainrot Blitz stealing: click a rival's brainrot, carry it home on your
-- back (slower while carrying), deliver it into your own base. A lock, a
-- slap or the tsunami makes the thief drop it, and anyone can pick it up.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Steal = {}

local EconomyModule = nil
local Carrying = {}
local Locks = {}

local getNotify

function Steal.attemptSteal(player, model)
	if not model or not model.Parent then
		return false
	end
	if model:GetAttribute("State") ~= "Owned" then
		return false
	end
	if Carrying[player] then
		getNotify():FireClient(player, "Deny", "Already carrying a brainrot!")
		return false
	end
	local ownerName = model:GetAttribute("Owner")
	local victim = Players:FindFirstChild(ownerName)
	if victim and Steal.isLocked(victim) then
		getNotify():FireClient(player, "Deny", ownerName .. "'s base is LOCKED!")
		return false
	end
	if victim and EconomyModule and #EconomyModule.getOwned(player) >= EconomyModule.getMaxSlots(player) then
		getNotify():FireClient(player, "Deny", "Your base is full! REBIRTH for +2 slots")
		return false
	end
	if victim and EconomyModule then
		EconomyModule.removeOwned(victim, model)
	end
	Steal.attachCarried(player, model)
	getNotify():FireClient(player, "Steal", model:GetAttribute("CharName"))
	if victim then
		getNotify():FireClient(victim, "Stolen", model:GetAttribute("CharName"), player.Name)
	end
	getNotify():FireAllClients("StealBanner", player.Name, model:GetAttribute("CharName"))
	return true
end

function Steal.setEconomy(module)
	EconomyModule = module
end

getNotify = function()
	return ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify")
end

function Steal.lockBase(player)
	local now = os.clock()
	local lock = Locks[player] or { Until = 0, CooldownUntil = 0 }
	if now < lock.CooldownUntil then
		local left = math.ceil(lock.CooldownUntil - now)
		getNotify():FireClient(player, "Deny", "Lock cooling down: " .. left .. "s")
		return false
	end
	local rebirths = 0
	if EconomyModule then
		rebirths = EconomyModule.getRebirths(player)
	end
	local duration = Config.Lock.Duration + rebirths * Config.Lock.PerRebirth
	lock.Until = now + duration
	lock.CooldownUntil = lock.Until + Config.Lock.Cooldown
	Locks[player] = lock
	player:SetAttribute("LockSeconds", duration)
	player:SetAttribute("LockCooldown", Config.Lock.Cooldown)
	getNotify():FireClient(player, "Lock", duration)
	return true
end

function Steal.isLocked(player)
	local now = os.clock()
	local protectedUntil = player:GetAttribute("SpawnProtectedUntil") or 0
	if now < protectedUntil then
		return true
	end
	local lock = Locks[player]
	if lock and now < lock.Until then
		return true
	end
	return false
end

function Steal.lockSecondsLeft(player)
	local lock = Locks[player]
	if not lock then
		return 0
	end
	return math.max(0, math.ceil(lock.Until - os.clock()))
end

function Steal.cooldownLeft(player)
	local lock = Locks[player]
	if not lock then
		return 0
	end
	return math.max(0, math.ceil(lock.CooldownUntil - os.clock()))
end

function Steal.attachCarried(player, model)
	local character = player.Character
	if not character then
		return false
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		return false
	end
	model:SetAttribute("State", "Carried")
	local gui = model:FindFirstChild("BrainrotLabel")
	if gui then
		local rateLabel = gui:FindFirstChild("RateLabel")
		if rateLabel then
			rateLabel.Text = "$" .. (model:GetAttribute("Rate") or 0) .. "/s  •  STOLEN!"
		end
	end
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
		end
	end
	local body = model.PrimaryPart or model:FindFirstChild("Body")
	if body then
		body.CFrame = root.CFrame * CFrame.new(0, 1.5, 1.8)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = body
		weld.Part1 = root
		weld.Parent = body
	end
	model.Parent = character
	humanoid.WalkSpeed = 10
	Carrying[player] = model
	return true
end

function Steal.dropCarried(player)
	local model = Carrying[player]
	if not model then
		return false
	end
	Carrying[player] = nil
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16
	end
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("WeldConstraint") then
			part:Destroy()
		end
	end
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local dropPos = root and (root.CFrame.Position + Vector3.new(0, 2, 3)) or Vector3.new(0, 4, 0)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end
	model:SetAttribute("State", "Dropped")
	local gui = model:FindFirstChild("BrainrotLabel")
	if gui then
		local rateLabel = gui:FindFirstChild("RateLabel")
		if rateLabel then
			rateLabel.Text = "$" .. (model:GetAttribute("Rate") or 0) .. "/s  •  DROPPED — CLICK TO GRAB"
		end
	end
	model:PivotTo(CFrame.new(dropPos))
	model.Parent = workspace:FindFirstChild("DroppedBrainrots") or workspace
	return true
end

function Steal.pickupDropped(player, model)
	if not model or not model.Parent then
		return false
	end
	if model:GetAttribute("State") ~= "Dropped" then
		return false
	end
	if Carrying[player] then
		return false
	end
	if EconomyModule and #EconomyModule.getOwned(player) >= EconomyModule.getMaxSlots(player) then
		getNotify():FireClient(player, "Deny", "Your base is full! REBIRTH for +2 slots")
		return false
	end
	Steal.attachCarried(player, model)
	getNotify():FireClient(player, "Steal", model:GetAttribute("CharName"))
	return true
end

function Steal.deliverCarried(player)
	local model = Carrying[player]
	if not model then
		return false
	end
	Carrying[player] = nil
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16
	end
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("WeldConstraint") then
			part:Destroy()
		end
	end
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end
	if EconomyModule then
		if EconomyModule.registerOwned(player, model) then
			getNotify():FireClient(player, "Deliver", model:GetAttribute("CharName"))
			return true
		end
	end
	Steal.dropCarried(player)
	return false
end

function Steal.wireOwned(_model)
	-- The ClickDetector made at spawn stays connected through every
	-- reparent, so a bought brainrot is stealable with no extra wiring.
end

function Steal.isCarrying(player)
	return Carrying[player] ~= nil
end

function Steal.start()
	task.spawn(function()
		while true do
			task.wait(0.5)
			for player, _model in pairs(Carrying) do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root and EconomyModule then
					local baseId = EconomyModule.getBaseId(player)
					if baseId > 0 then
						local center = EconomyModule.BasePositions[baseId]
						local dx = root.Position.X - center.X
						local dz = root.Position.Z - center.Z
						if math.sqrt(dx * dx + dz * dz) < 14 then
							Steal.deliverCarried(player)
						end
					end
				end
			end
			for _, player in ipairs(Players:GetPlayers()) do
				player:SetAttribute("LockSeconds", Steal.lockSecondsLeft(player))
				player:SetAttribute("LockCooldown", Steal.cooldownLeft(player))
			end
		end
	end)
end

return Steal
