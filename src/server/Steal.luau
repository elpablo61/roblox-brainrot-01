-- Steal: stealing a rival's brainrot, carrying it home, base locks, and
-- dropping a carried brainrot when the thief is slapped or hit by the wave.
-- A dropped or returned model always gets its original buy price back:
-- a stolen-then-dropped model must never be re-buyable for $0.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Steal = {}
local locks = {}
local carrying = {}

local function baseRect(baseIndex)
	local center = Config.BASE_POSITIONS[baseIndex]
	if not center then
		return nil
	end
	return { minX = center.X - 9, maxX = center.X + 9, minZ = center.Z - 9, maxZ = center.Z + 9 }
end

local function insideOwnBase(player)
	local Economy = require(script.Parent:WaitForChild("Economy"))
	local state = Economy.getState(player)
	if not state or state.baseIndex == 0 then
		return false
	end
	local char = player.Character
	if not char then
		return false
	end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local rect = baseRect(state.baseIndex)
	if not rect then
		return false
	end
	local p = root.Position
	return p.X >= rect.minX and p.X <= rect.maxX and p.Z >= rect.minZ and p.Z <= rect.maxZ
end

function Steal.attemptSteal(player, model)
	if not model or not model.Parent then
		return false
	end
	if carrying[player] then
		return false
	end
	local ownerId = model:GetAttribute("OwnerId") or 0
	if ownerId == 0 or ownerId == player.UserId then
		return false
	end
	local victim = Players:GetPlayerByUserId(ownerId)
	if not victim then
		return false
	end
	if Steal.isBaseLocked(victim) then
		return false
	end
	if (victim:GetAttribute("SpawnProtect") or 0) > 0 then
		return false
	end
	local Economy = require(script.Parent:WaitForChild("Economy"))
	Economy.removeOwned(victim, model)
	local char = player.Character
	if not char then
		return false
	end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	-- Remove any older carry weld first so the model never ends up double-welded.
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("WeldConstraint") then
			desc:Destroy()
		end
	end
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
		end
	end
	model:PivotTo(root.CFrame * CFrame.new(0, 3, 0))
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = model.PrimaryPart
	weld.Parent = model
	model:SetAttribute("CarriedBy", player.UserId)
	carrying[player] = model
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = Config.CARRY_SPEED
	end
	local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")
	remotes:WaitForChild("Banner"):FireClient(victim, "STOLEN! " .. (model:GetAttribute("CharName") or "Brainrot") .. " was stolen!", "red", 4)
	remotes:WaitForChild("Banner"):FireClient(player, "STOLEN! Carry it home to your base!", "green", 4)
	return true
end

function Steal.lockBase(player)
	local now = os.clock()
	local lock = locks[player]
	if lock and lock.cooldownUntil > now then
		return false
	end
	if lock and lock.untilTime > now then
		return false
	end
	local Economy = require(script.Parent:WaitForChild("Economy"))
	local state = Economy.getState(player)
	local rebirths = state and state.rebirths or 0
	local duration = Config.LOCK_DURATION + Config.LOCK_PER_REBIRTH * rebirths
	locks[player] = { untilTime = now + duration, cooldownUntil = now + duration + Config.LOCK_COOLDOWN }
	player:SetAttribute("LockLeft", duration)
	player:SetAttribute("LockCooldown", 0)
	return true
end

function Steal.isBaseLocked(player)
	local lock = locks[player]
	if not lock then
		return false
	end
	return lock.untilTime > os.clock()
end

function Steal.getLockLeft(player)
	local lock = locks[player]
	if not lock then
		return 0
	end
	return math.max(0, lock.untilTime - os.clock())
end

function Steal.dropCarried(player, reason)
	local model = carrying[player]
	if not model then
		return false
	end
	carrying[player] = nil
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("WeldConstraint") then
			desc:Destroy()
		end
	end
	-- Restore the original buy price: a dropped model is never $0.
	model:SetAttribute("Price", model:GetAttribute("OriginalPrice") or model:GetAttribute("Price") or 0)
	model:SetAttribute("CarriedBy", 0)
	local char = player.Character
	if char then
		local root = char:FindFirstChild("HumanoidRootPart")
		if root and model.PrimaryPart then
			model:PivotTo(CFrame.new(root.Position + Vector3.new(0, 2, 0)))
		end
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = Config.NORMAL_SPEED
		end
	end
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end
	-- A dropped model goes back on the belt so anyone can buy it again.
	local belt = workspace:FindFirstChild("Belt")
	if belt then
		model.Parent = belt
		model:SetAttribute("OwnerId", 0)
		local dropX = math.clamp(model:GetPivot().Position.X, Config.BELT_START_X, Config.BELT_END_X)
		model:PivotTo(CFrame.new(dropX, 2.2, Config.BELT_Z))
		local Conveyor = require(script.Parent:WaitForChild("Conveyor"))
		local list = Conveyor.getBeltModels()
		table.insert(list, model)
	end
	local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")
	remotes:WaitForChild("Banner"):FireClient(player, "DROPPED! " .. (reason or ""), "red", 3)
	return true
end

function Steal.deliverCarried(player)
	local model = carrying[player]
	if not model then
		return false
	end
	if not insideOwnBase(player) then
		return false
	end
	carrying[player] = nil
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("WeldConstraint") then
			desc:Destroy()
		end
	end
	local charName = model:GetAttribute("CharName") or "Brainrot"
	local rate = model:GetAttribute("Rate") or 0
	model:SetAttribute("Price", model:GetAttribute("OriginalPrice") or model:GetAttribute("Price") or 0)
	model:SetAttribute("CarriedBy", 0)
	local Economy = require(script.Parent:WaitForChild("Economy"))
	local state = Economy.getState(player)
	if not state then
		return false
	end
	if not Economy.addOwned(player, model, charName, rate) then
		Steal.dropCarried(player, "Base full!")
		return false
	end
	model:SetAttribute("OwnerId", player.UserId)
	local bases = workspace:WaitForChild("Bases")
	local base = bases:FindFirstChild("Base" .. state.baseIndex)
	if base then
		model.Parent = base
		local slot = #state.owned
		local spot = base:FindFirstChild("Slot" .. slot)
		if spot then
			model:PivotTo(CFrame.new(spot.Position + Vector3.new(0, 1.3, 0)))
		end
	end
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end
	local char = player.Character
	if char then
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = Config.NORMAL_SPEED
		end
	end
	local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")
	remotes:WaitForChild("Banner"):FireClient(player, "DELIVERED! " .. charName .. " is yours now!", "green", 4)
	return true
end

function Steal.isCarrying(player)
	return carrying[player] ~= nil
end

function Steal.start()
	task.spawn(function()
		while true do
			task.wait(0.5)
			local now = os.clock()
			for _, player in ipairs(Players:GetPlayers()) do
				local lock = locks[player]
				if lock then
					local left = math.max(0, lock.untilTime - now)
					local cd = 0
					if left <= 0 then
						cd = math.max(0, lock.cooldownUntil - now)
					end
					player:SetAttribute("LockLeft", math.floor(left))
					player:SetAttribute("LockCooldown", math.floor(cd))
				else
					player:SetAttribute("LockLeft", 0)
					player:SetAttribute("LockCooldown", 0)
				end
				if carrying[player] then
					Steal.deliverCarried(player)
				end
			end
		end
	end)
end

return Steal
