-- Steal: carry a rival's brainrot home on your back. A locked base cannot be
-- stolen from, and a slap or a tsunami drops whatever you are carrying.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Steal = {}
Steal.carried = {}

function Steal.attemptSteal(player, model)
	local ownerId = model:GetAttribute("OwnerId") or 0
	if ownerId == 0 or ownerId == player.UserId then
		return false
	end
	local Economy = require(script.Parent:WaitForChild("Economy"))
	local owner = Players:GetPlayerByUserId(ownerId)
	if owner then
		local ownerState = Economy.players[owner]
		if ownerState and os.time() < ownerState.lockUntil then
			Economy.notify(player, "denied", "That base is LOCKED!")
			return false
		end
		if ownerState and os.time() < ownerState.protectedUntil then
			Economy.notify(player, "denied", "Spawn protection is on!")
			return false
		end
	end
	if Steal.carried[player] then
		Economy.notify(player, "denied", "You are already carrying one!")
		return false
	end
	for carrier, carriedModel in pairs(Steal.carried) do
		if carriedModel == model then
			Steal.detachModel(carrier, model)
			break
		end
	end
	Steal.attachModel(player, model)
	Steal.carried[player] = model
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 10
	end
	if owner then
		Economy.notify(owner, "stolen", "STOLEN! " .. player.Name .. " took your " .. (model:GetAttribute("CharName") or "brainrot") .. "!")
	end
	Economy.notify(player, "carrying", "Run it home to your base!")
	return true
end

function Steal.lockBase(player)
	local Economy = require(script.Parent:WaitForChild("Economy"))
	local state = Economy.players[player]
	if not state then
		return false
	end
	local now = os.time()
	if now < state.lockCooldownUntil then
		Economy.notify(player, "denied", "Lock recharging: " .. (state.lockCooldownUntil - now) .. "s left")
		return false
	end
	if now < state.lockUntil then
		Economy.notify(player, "denied", "Base is already locked!")
		return false
	end
	local duration = Config.LOCK_DURATION + Config.LOCK_PER_REBIRTH * state.rebirths
	state.lockUntil = now + duration
	state.lockCooldownUntil = state.lockUntil + Config.LOCK_COOLDOWN
	Economy.refreshAttributes(player)
	Economy.notify(player, "locked", "Base LOCKED for " .. duration .. "s!")
	return true
end

function Steal.attachModel(player, model)
	local character = player.Character
	local torso = character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"))
	if not torso then
		return
	end
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
		end
	end
	local primary = model.PrimaryPart
	if primary then
		local weld = Instance.new("Weld")
		weld.Name = "CarryWeld"
		weld.Part0 = torso
		weld.Part1 = primary
		weld.C0 = CFrame.new(0, 0, 1.6)
		weld.Parent = primary
	end
end

function Steal.detachModel(player, model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("Weld") and descendant.Name == "CarryWeld" then
			descendant:Destroy()
		end
	end
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = true
		end
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16
	end
end

function Steal.dropCarried(player)
	local model = Steal.carried[player]
	if not model then
		return
	end
	Steal.carried[player] = nil
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	Steal.detachModel(player, model)
	if root and model.Parent then
		model:PivotTo(CFrame.new(root.Position + Vector3.new(3, 1, 0)))
	end
	local Economy = require(script.Parent:WaitForChild("Economy"))
	Economy.notify(player, "dropped", "You dropped the brainrot!")
end

function Steal.completeSteal(player, model)
	local Economy = require(script.Parent:WaitForChild("Economy"))
	local ownerId = model:GetAttribute("OwnerId") or 0
	local oldOwner = Players:GetPlayerByUserId(ownerId)
	Steal.carried[player] = nil
	Steal.detachModel(player, model)
	local state = Economy.players[player]
	if state and oldOwner and Economy.players[oldOwner] then
		local oldState = Economy.players[oldOwner]
		for i, owned in ipairs(oldState.owned) do
			if owned == model then
				table.remove(oldState.owned, i)
				break
			end
		end
		Economy.refreshAttributes(oldOwner)
	end
	if state then
		model:SetAttribute("OwnerId", player.UserId)
		table.insert(state.owned, model)
		Economy.placeInBase(player, model)
		local charName = model:GetAttribute("CharName") or "Brainrot"
		if not state.index[charName] then
			state.index[charName] = true
			state.indexCount += 1
		end
		Economy.refreshAttributes(player)
		Economy.notify(player, "stolen", "You stole " .. charName .. "!")
	end
end

function Steal.start()
	RunService.Heartbeat:Connect(function()
		for player, model in pairs(Steal.carried) do
			if not model.Parent or not player.Parent then
				Steal.carried[player] = nil
			else
				local Economy = require(script.Parent:WaitForChild("Economy"))
				local state = Economy.players[player]
				if state then
					local character = player.Character
					local root = character and character:FindFirstChild("HumanoidRootPart")
					if root then
						local base = Config.BASES[state.baseIndex]
						if math.abs(root.Position.X - base.x) <= 11 and math.abs(root.Position.Z - base.z) <= 11 then
							Steal.completeSteal(player, model)
						end
					end
				end
			end
		end
	end)
end

return Steal
