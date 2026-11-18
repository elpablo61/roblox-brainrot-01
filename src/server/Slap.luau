-- Slap knocks a rival back and drops whatever brainrot they are carrying.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Slap = {}

function Slap.slapPlayer(player, target)
	if not target or target == player then
		return false
	end
	local char = player.Character
	local targetChar = target.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
	if not root or not targetRoot then
		return false
	end
	local dir = (targetRoot.Position - root.Position)
	if dir.Magnitude > Config.SLAP_RANGE then
		return false
	end
	dir = dir.Unit
	targetRoot.AssemblyLinearVelocity = dir * Config.SLAP_FORCE + Vector3.new(0, 25, 0)
	local Steal = require(script.Parent:WaitForChild("Steal"))
	Steal.dropCarried(target, "slap")
	local Economy = require(script.Parent:WaitForChild("Economy"))
	Economy.banner(target, "SLAPPED by " .. player.DisplayName .. "!", Color3.fromRGB(255, 80, 80))
	return true
end

function Slap.giveTool(player)
	local char = player.Character
	if not char then
		return
	end
	local old = char:FindFirstChild("Slap") or player.Backpack:FindFirstChild("Slap")
	if old then
		old:Destroy()
	end
	local tool = Instance.new("Tool")
	tool.Name = "Slap"
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.6, 1.6, 0.6)
	handle.Color = Color3.fromRGB(255, 220, 120)
	handle.Material = Enum.Material.SmoothPlastic
	handle.Parent = tool
	tool.Parent = player.Backpack
	tool.Activated:Connect(function()
		local charNow = player.Character
		local root = charNow and charNow:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end
		local best = nil
		local bestDist = Config.SLAP_RANGE
		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= player then
				local otherChar = other.Character
				local otherRoot = otherChar and otherChar:FindFirstChild("HumanoidRootPart")
				if otherRoot then
					local d = (otherRoot.Position - root.Position).Magnitude
					if d < bestDist then
						bestDist = d
						best = other
					end
				end
			end
		end
		if best then
			Slap.slapPlayer(player, best)
		end
	end)
end

function Slap.hookSpawns()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.5)
			Slap.giveTool(player)
		end)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		player.CharacterAdded:Connect(function()
			task.wait(0.5)
			Slap.giveTool(player)
		end)
	end
end

return Slap
