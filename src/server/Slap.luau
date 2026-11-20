-- Brainrot Blitz slap: the Slap tool shoves a thief back and makes them
-- drop whatever brainrot they are carrying. Your defence while the base
-- lock is on cooldown.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Slap = {}

local StealModule = nil
local SLAP_RANGE = 12
local SLAP_POWER = 55

local function getNotify()
	return ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify")
end

function Slap.setSteal(module)
	StealModule = module
end

function Slap.slapPlayer(attacker, victim)
	if not attacker or not victim or attacker == victim then
		return false
	end
	local attackerChar = attacker.Character
	local victimChar = victim.Character
	if not attackerChar or not victimChar then
		return false
	end
	local attackerRoot = attackerChar:FindFirstChild("HumanoidRootPart")
	local victimRoot = victimChar:FindFirstChild("HumanoidRootPart")
	local victimHumanoid = victimChar:FindFirstChildOfClass("Humanoid")
	if not attackerRoot or not victimRoot or not victimHumanoid then
		return false
	end
	local distance = (victimRoot.Position - attackerRoot.Position).Magnitude
	if distance > SLAP_RANGE then
		return false
	end
	local direction = (victimRoot.Position - attackerRoot.Position).Unit
	victimRoot.AssemblyLinearVelocity = Vector3.new(direction.X * SLAP_POWER, 18, direction.Z * SLAP_POWER)
	if StealModule then
		StealModule.dropCarried(victim)
	end
	getNotify():FireClient(attacker, "Slap", victim.Name)
	getNotify():FireClient(victim, "Slapped", attacker.Name)
	getNotify():FireAllClients("SlapEffect", victimRoot.Position)
	return true
end

function Slap.findVictim(attacker)
	local attackerChar = attacker.Character
	local attackerRoot = attackerChar and attackerChar:FindFirstChild("HumanoidRootPart")
	if not attackerRoot then
		return nil
	end
	local closest = nil
	local closestDistance = SLAP_RANGE
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= attacker then
			local victimChar = player.Character
			local victimRoot = victimChar and victimChar:FindFirstChild("HumanoidRootPart")
			if victimRoot then
				local distance = (victimRoot.Position - attackerRoot.Position).Magnitude
				if distance < closestDistance then
					closestDistance = distance
					closest = player
				end
			end
		end
	end
	return closest
end

return Slap
