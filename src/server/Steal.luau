-- Steal: click another player's brainrot to carry it home on your back.
-- A locked base (60s + 10s per rebirth, 60s cooldown) or spawn protection blocks the steal.
-- A carried brainrot drops if the thief is slapped or hit by the tsunami.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local Steal = {}

function Steal.attemptSteal(player, model)
	local Economy = require(script.Parent.Economy)
	local state = Economy.getState(player)
	if not state then
		return false
	end
	if state.carrying then
		Economy.banner(player, "Already carrying one!", "Red")
		return false
	end
	local ownerId = model:GetAttribute("OwnerId") or 0
	if ownerId == 0 or ownerId == player.UserId then
		return false
	end
	local owner = Players:GetPlayerByUserId(ownerId)
	local ownerState = owner and Economy.getState(owner)
	if ownerState then
		if os.time() < ownerState.lockUntil then
			Economy.banner(player, "BASE LOCKED! Come back later", "Red")
			return false
		end
		if os.time() < ownerState.spawnProtectedUntil then
			Economy.banner(player, "That player is spawn-protected", "Red")
			return false
		end
	end
	if ownerState then
		for i, owned in ipairs(ownerState.owned) do
			if owned == model then
				table.remove(ownerState.owned, i)
				break
			end
		end
		Economy.refreshAttributes(owner)
		Economy.banner(owner, "STOLEN! " .. (model:GetAttribute("CharName") or "brainrot") .. " was taken!", "Red")
	end
	Steal.attachToBack(player, model)
	state.carrying = model
	local char = player.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 10
	end
	Economy.banner(player, "RUN! Carry it to your base!", "Yellow")
	return true
end

function Steal.lockBase(player)
	local Economy = require(script.Parent.Economy)
	local state = Economy.getState(player)
	if not state then
		return false
	end
	local now = os.time()
	if now < state.lockCooldownUntil then
		Economy.banner(player, "Lock on cooldown: " .. tostring(state.lockCooldownUntil - now) .. "s", "Red")
		return false
	end
	if now < state.lockUntil then
		Economy.banner(player, "Base already locked", "Yellow")
		return false
	end
	local duration = Config.lockDuration + Config.lockPerRebirth * state.rebirths
	state.lockUntil = now + duration
	state.lockCooldownUntil = state.lockUntil + Config.lockCooldown
	Economy.banner(player, "BASE LOCKED for " .. tostring(duration) .. "s!", "Green")
	Steal.paintLock(state, true)
	task.delay(duration, function()
		Steal.paintLock(state, false)
	end)
	return true
end

function Steal.paintLock(state, locked)
	local folder = state.baseFolder
	if not folder then
		return
	end
	for _, part in ipairs(folder:GetDescendants()) do
		if part:IsA("BasePart") and part.Name == "BaseWall" then
			part.Color = locked and Color3.fromRGB(220, 40, 40) or state.baseColor
		end
	end
	local sign = folder:FindFirstChild("LockSign")
	if sign then
		sign.Transparency = locked and 0 or 1
	end
end

function Steal.attachToBack(player, model)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local oldWeld = model.PrimaryPart and model.PrimaryPart:FindFirstChild("CarryWeld")
	if oldWeld then
		oldWeld:Destroy()
	end
	model:PivotTo(CFrame.new(root.Position + Vector3.new(0, 1.5, 1.8)))
	local weld = Instance.new("Weld")
	weld.Name = "CarryWeld"
	weld.Part0 = root
	weld.Part1 = model.PrimaryPart
	weld.C0 = CFrame.new(0, 1.5, 1.8)
	weld.Parent = model.PrimaryPart
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
		end
	end
end

function Steal.dropCarried(player)
	local Economy = require(script.Parent.Economy)
	local state = Economy.getState(player)
	if not state or not state.carrying then
		return
	end
	local model = state.carrying
	state.carrying = nil
	local char = player.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16
	end
	local weld = model.PrimaryPart and model.PrimaryPart:FindFirstChild("CarryWeld")
	if weld then
		weld:Destroy()
	end
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root then
		model:PivotTo(CFrame.new(root.Position + Vector3.new(0, 2, 4)))
	end
	Economy.banner(player, "You DROPPED the brainrot!", "Red")
end

function Steal.deliverCheck()
	RunService.Heartbeat:Connect(function()
		local Economy = require(script.Parent.Economy)
		for _, player in ipairs(Players:GetPlayers()) do
			local state = Economy.getState(player)
			if state and state.carrying then
				local char = player.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if root then
					local dx = math.abs(root.Position.X - state.baseCenter.X)
					local dz = math.abs(root.Position.Z - state.baseCenter.Z)
					if dx <= 12 and dz <= 12 then
						local model = state.carrying
						state.carrying = nil
						local humanoid = char:FindFirstChildOfClass("Humanoid")
						if humanoid then
							humanoid.WalkSpeed = 16
						end
						local weld = model.PrimaryPart and model.PrimaryPart:FindFirstChild("CarryWeld")
						if weld then
							weld:Destroy()
						end
						for _, part in ipairs(model:GetDescendants()) do
							if part:IsA("BasePart") then
								part.Anchored = true
							end
						end
						local slot = Economy.nextSlot(state)
						if slot then
							model:SetAttribute("OwnerId", player.UserId)
							model:SetAttribute("SlotIndex", slot)
							table.insert(state.owned, model)
							state.ownedNames[model:GetAttribute("CharName")] = true
							model.Parent = state.baseFolder
							Economy.moveModelToSlot(model, state, slot)
							Economy.refreshAttributes(player)
							Economy.banner(player, "STOLE IT! +" .. (model:GetAttribute("CharName") or "brainrot"), "Green")
						else
							Steal.dropCarried(player)
						end
					end
				end
			end
		end
	end)
end

return Steal
