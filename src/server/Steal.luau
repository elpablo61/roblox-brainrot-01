-- Steal lets a player click a rival's brainrot and carry it home on their
-- back, unless the owner's base lock is on or they are spawn-protected.
-- A carried brainrot drops if the thief is slapped or hit by the tsunami.

local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Steal = {}
local carried = {}

function Steal.attemptSteal(player, model)
	local ownerId = model:GetAttribute("OwnerId")
	if not ownerId or ownerId == player.UserId then return false end
	local victim = Players:GetPlayerByUserId(ownerId)
	if not victim then return false end
	local Economy = require(script.Parent.Economy)
	local victimState = Economy.Players[victim]
	if not victimState then return false end
	if victimState.lockLeft > 0 then return false end
	if victimState.protectLeft > 0 then return false end
	if carried[player] then return false end
	for _, owned in ipairs(victimState.owned) do
		if owned == model then
			table.remove(victimState.owned, table.find(victimState.owned, model))
			break
		end
	end
	local character = player.Character
	if not character then return false end
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then return false end
	local primary = model.PrimaryPart
	if primary then
		primary.Anchored = false
		primary.CFrame = root.CFrame * CFrame.new(0, 1, 1.5)
	end
	local weld = Instance.new("Weld")
	weld.Name = "CarryWeld"
	weld.Part0 = root
	weld.Part1 = primary
	weld.C0 = CFrame.new(0, 1, 1.5)
	weld.Parent = model
	carried[player] = model
	model:SetAttribute("CarriedBy", player.UserId)
	humanoid.WalkSpeed = Config.STEAL_SLOW_SPEED
	victim:SetAttribute("BannerText", "STOLEN! " .. (model:GetAttribute("CharName") or "Brainrot") .. " taken by " .. player.Name)
	victim:SetAttribute("BannerUntil", os.time() + 5)
	player:SetAttribute("BannerText", "STEAL! Run it home to your base!")
	player:SetAttribute("BannerUntil", os.time() + 5)
	Economy.refreshAttributes(victim, victimState)
	task.spawn(function()
		while carried[player] == model and model.Parent do
			task.wait(0.5)
			local state = Economy.Players[player]
			if not state then break end
			local base = Config.BASES[state.baseIndex]
			local pos = root.Position
			if math.abs(pos.X - base.position.X) < 14 and math.abs(pos.Z - base.position.Z) < 14 then
				Steal.deliverCarried(player)
				break
			end
		end
	end)
	return true
end

function Steal.lockBase(player)
	local Economy = require(script.Parent.Economy)
	local state = Economy.Players[player]
	if not state then return false end
	if state.lockCooldown > 0 or state.lockLeft > 0 then return false end
	state.lockLeft = Config.LOCK_SECONDS + Config.LOCK_PER_REBIRTH * state.rebirths
	state.lockCooldown = Config.LOCK_COOLDOWN + state.lockLeft
	Economy.refreshAttributes(player, state)
	return true
end

function Steal.dropCarried(player)
	local model = carried[player]
	if not model then return end
	carried[player] = nil
	local weld = model:FindFirstChild("CarryWeld")
	if weld then weld:Destroy() end
	local primary = model.PrimaryPart
	if primary then
		primary.Anchored = true
		primary.CFrame = CFrame.new(primary.Position.X, 3, primary.Position.Z)
	end
	model:SetAttribute("CarriedBy", nil)
	model:SetAttribute("OwnerId", nil)
	model:SetAttribute("Price", 0)
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid.WalkSpeed = Config.NORMAL_WALK_SPEED end
	end
	local label = model:FindFirstChild("Label", true)
	if label then
		local text = label:FindFirstChildOfClass("TextLabel")
		if text then text.Text = (model:GetAttribute("CharName") or "Brainrot") .. " - DROPPED! Click to claim FREE" end
	end
end

function Steal.deliverCarried(player)
	local model = carried[player]
	if not model then return end
	carried[player] = nil
	local weld = model:FindFirstChild("CarryWeld")
	if weld then weld:Destroy() end
	local Economy = require(script.Parent.Economy)
	local state = Economy.Players[player]
	if not state then return end
	if #state.owned >= state.slotsMax then
		Steal.dropCarried(player)
		return
	end
	model:SetAttribute("OwnerId", player.UserId)
	model:SetAttribute("CarriedBy", nil)
	table.insert(state.owned, model)
	local name = model:GetAttribute("CharName") or model.Name
	if not state.seen[name] then
		state.seen[name] = true
		state.indexCount += 1
	end
	local base = Config.BASES[state.baseIndex]
	local slot = #state.owned
	local ox = ((slot - 1) % 5) * 4 - 8
	local oz = math.floor((slot - 1) / 5) * 4 - 2
	local primary = model.PrimaryPart
	if primary then
		primary.Anchored = true
		primary.CFrame = CFrame.new(base.position + Vector3.new(ox, 3, oz))
	end
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid.WalkSpeed = Config.NORMAL_WALK_SPEED end
	end
	Economy.refreshAttributes(player, state)
end

function Steal.isCarrying(player)
	return carried[player] ~= nil
end

function Steal.onPlayerRemoving(player)
	if carried[player] then Steal.dropCarried(player) end
end

return Steal
