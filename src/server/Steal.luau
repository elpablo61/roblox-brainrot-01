-- Steal handles stealing, carrying, delivering, dropping, and the base lock.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Steal = {}
local carried = {}

function Steal.attemptSteal(player, model)
	local Economy = require(script.Parent:WaitForChild("Economy"))
	local ownerId = model:GetAttribute("OwnerId") or 0
	if ownerId == 0 or ownerId == player.UserId then
		return false
	end
	local victim = Players:GetPlayerByUserId(ownerId)
	if not victim then
		return false
	end
	local victimState = Economy.getState(victim)
	if victimState and victimState.lockLeft > 0 then
		Economy.banner(player, "BASE LOCKED! Come back later.", Color3.fromRGB(255, 80, 80))
		return false
	end
	if carried[player] then
		Economy.banner(player, "Already carrying one - deliver it first!", Color3.fromRGB(255, 80, 80))
		return false
	end
	if victimState then
		for i, owned in ipairs(victimState.owned) do
			if owned == model then
				table.remove(victimState.owned, i)
				break
			end
		end
		Economy.refreshAttributes(victim)
	end
	Steal.carryModel(player, model)
	Economy.banner(victim, "STOLEN! " .. (model:GetAttribute("CharName") or "Brainrot") .. " was taken!", Color3.fromRGB(255, 80, 80))
	Economy.banner(player, "STOLE " .. (model:GetAttribute("CharName") or "Brainrot") .. " - RUN HOME!", Color3.fromRGB(255, 200, 40))
	return true
end

function Steal.lockBase(player)
	local Economy = require(script.Parent:WaitForChild("Economy"))
	local state = Economy.getState(player)
	if not state then
		return false
	end
	if state.cooldownLeft > 0 then
		Economy.banner(player, "LOCK COOLDOWN: " .. state.cooldownLeft .. "s", Color3.fromRGB(255, 80, 80))
		return false
	end
	if state.lockLeft > 0 then
		Economy.banner(player, "Base already locked: " .. state.lockLeft .. "s left", Color3.fromRGB(255, 200, 40))
		return false
	end
	state.lockLeft = Config.LOCK_TIME + Config.LOCK_PER_REBIRTH * state.rebirths
	state.cooldownLeft = Config.LOCK_COOLDOWN + state.lockLeft
	Economy.refreshAttributes(player)
	Economy.banner(player, "BASE LOCKED for " .. state.lockLeft .. "s!", Color3.fromRGB(80, 255, 120))
	return true
end

function Steal.carryModel(player, model)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not root then
		return
	end
	local oldWeld = model:FindFirstChild("CarryWeld")
	if oldWeld then
		oldWeld:Destroy()
	end
	model:SetAttribute("Carried", true)
	model:SetAttribute("OwnerId", 0)
	local weld = Instance.new("Weld")
	weld.Name = "CarryWeld"
	weld.Part0 = root
	weld.Part1 = model.PrimaryPart
	weld.C0 = CFrame.new(0, 1.5, -1.8)
	weld.Parent = model
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
		end
	end
	carried[player] = model
	if humanoid then
		humanoid.WalkSpeed = 10
	end
end

function Steal.dropCarried(player, reason)
	local model = carried[player]
	if not model then
		return
	end
	carried[player] = nil
	local weld = model:FindFirstChild("CarryWeld")
	if weld then
		weld:Destroy()
	end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if root then
		local pos = root.Position + root.CFrame.LookVector * 3 + Vector3.new(0, 2, 0)
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
			end
		end
		model:PivotTo(CFrame.new(pos))
	end
	if humanoid then
		humanoid.WalkSpeed = 16
	end
	-- A dropped model is buyable again at its ORIGINAL price, never $0.
	model:SetAttribute("Carried", false)
	model:SetAttribute("OwnerId", 0)
	model:SetAttribute("Price", model:GetAttribute("OriginalPrice") or 0)
	local Economy = require(script.Parent:WaitForChild("Economy"))
	Economy.banner(player, "DROPPED! (" .. (reason or "slap") .. ")", Color3.fromRGB(255, 80, 80))
end

function Steal.deliverCarried(player)
	local model = carried[player]
	if not model then
		return
	end
	local Economy = require(script.Parent:WaitForChild("Economy"))
	local state = Economy.getState(player)
	if not state then
		return
	end
	if #state.owned >= state.slots then
		Economy.banner(player, "BASE FULL! Cannot deliver.", Color3.fromRGB(255, 80, 80))
		return
	end
	carried[player] = nil
	local weld = model:FindFirstChild("CarryWeld")
	if weld then
		weld:Destroy()
	end
	local char = player.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16
	end
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end
	model:SetAttribute("Carried", false)
	model:SetAttribute("OwnerId", player.UserId)
	model:SetAttribute("Price", model:GetAttribute("OriginalPrice") or 0)
	table.insert(state.owned, model)
	Economy.placeAtBase(player, model)
	Economy.refreshAttributes(player)
	Economy.updateNextTierBoard(player)
	Economy.banner(player, "DELIVERED! " .. (model:GetAttribute("CharName") or "Brainrot") .. " is yours!", Color3.fromRGB(80, 255, 120))
end

function Steal.startDeliveryLoop()
	RunService.Heartbeat:Connect(function()
		for player, model in pairs(carried) do
			if not player.Parent or not model.Parent then
				carried[player] = nil
			else
				local Economy = require(script.Parent:WaitForChild("Economy"))
				local state = Economy.getState(player)
				local char = player.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if state and root then
					local center = Economy.getBaseCenter(state.baseIndex)
					local d = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(center.X, 0, center.Z)).Magnitude
					if d < 9 then
						Steal.deliverCarried(player)
					end
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		if carried[player] then
			Steal.dropCarried(player, "left")
		end
	end)
end

return Steal
