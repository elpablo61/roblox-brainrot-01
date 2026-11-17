-- Slap: the genre's signature defence. Click (or tap) with the Slap tool to shove the
-- nearest rival backwards — and knock any brainrot they are carrying out of their hands.

local Players = game:GetService("Players")

local Slap = {}
local RANGE = 10
local COOLDOWN = 1.5

function Slap.slapPlayer(player)
	if not player or not player.Character then
		return false
	end
	local Economy = require(script.Parent.Economy)
	local state = Economy.getState(player)
	if not state then
		return false
	end
	if os.clock() < state.slapCooldownUntil then
		return false
	end
	state.slapCooldownUntil = os.clock() + COOLDOWN
	local root = player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local best = nil
	local bestDist = RANGE
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player and other.Character then
			local otherRoot = other.Character:FindFirstChild("HumanoidRootPart")
			if otherRoot then
				local dist = (otherRoot.Position - root.Position).Magnitude
				if dist < bestDist then
					best = other
					bestDist = dist
				end
			end
		end
	end
	if not best then
		return false
	end
	local otherRoot = best.Character:FindFirstChild("HumanoidRootPart")
	local dir = (otherRoot.Position - root.Position).Unit
	otherRoot.AssemblyLinearVelocity = dir * 45 + Vector3.new(0, 20, 0)
	local Steal = require(script.Parent.Steal)
	Steal.dropCarried(best)
	Economy.banner(best, "You got SLAPPED!", "Red")
	return true
end

function Slap.giveTool(player)
	local tool = Instance.new("Tool")
	tool.Name = "Slap"
	tool.RequiresHandle = true
	tool.ToolTip = "Slap rivals to drop what they carry!"
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.6, 2.2, 0.6)
	handle.Color = Color3.fromRGB(150, 90, 40)
	handle.Material = Enum.Material.Wood
	handle.Parent = tool
	tool.Activated:Connect(function()
		Slap.slapPlayer(player)
	end)
	tool.Parent = player:WaitForChild("Backpack")
end

return Slap
