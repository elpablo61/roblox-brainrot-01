-- Slap: the genre's signature defence. A Slap tool is handed out fresh on
-- every spawn (cloned tools lose their connections, so never clone one),
-- and slapping a thief knocks them back and drops whatever they carry.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Slap = {}

function Slap.slapPlayer(player, target)
	if not target or target == player then
		return false
	end
	local targetChar = target.Character
	local myChar = player.Character
	if not targetChar or not myChar then
		return false
	end
	local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
	local myRoot = myChar:FindFirstChild("HumanoidRootPart")
	if not targetRoot or not myRoot then
		return false
	end
	if (targetRoot.Position - myRoot.Position).Magnitude > 12 then
		return false
	end
	local dir = (targetRoot.Position - myRoot.Position).Unit
	targetRoot.AssemblyLinearVelocity = dir * 45 + Vector3.new(0, 20, 0)
	local Steal = require(script.Parent:WaitForChild("Steal"))
	Steal.dropCarried(target, "SLAPPED! Your stolen brainrot dropped!")
	return true
end

function Slap.giveTool(player)
	local char = player.Character
	if not char then
		return
	end
	for _, old in ipairs(player.Backpack:GetChildren()) do
		if old.Name == "Slap" then
			old:Destroy()
		end
	end
	local tool = Instance.new("Tool")
	tool.Name = "Slap"
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 1, 3)
	handle.Color = Color3.fromRGB(255, 220, 180)
	handle.Material = Enum.Material.SmoothPlastic
	handle.Parent = tool
	tool.Parent = player.Backpack
	tool.Activated:Connect(function()
		local myChar = player.Character
		local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
		if not myRoot then
			return
		end
		local nearest = nil
		local nearestDist = 12
		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= player then
				local otherChar = other.Character
				local otherRoot = otherChar and otherChar:FindFirstChild("HumanoidRootPart")
				if otherRoot then
					local dist = (otherRoot.Position - myRoot.Position).Magnitude
					if dist < nearestDist then
						nearestDist = dist
						nearest = other
					end
				end
			end
		end
		if nearest then
			Slap.slapPlayer(player, nearest)
		end
	end)
end

function Slap.start()
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
