-- Slap hands every player a Slap tool on spawn. Clicking it shoves the
-- nearest rival back and drops any brainrot they are carrying.

local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Slap = {}

function Slap.slapPlayer(player, targetPlayer)
	if not player or not targetPlayer or player == targetPlayer then return false end
	local character = player.Character
	local targetChar = targetPlayer.Character
	if not character or not targetChar then return false end
	local root = character:FindFirstChild("HumanoidRootPart")
	local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
	if not root or not targetRoot then return false end
	if (targetRoot.Position - root.Position).Magnitude > 10 then return false end
	local Steal = require(script.Parent.Steal)
	if Steal.isCarrying(targetPlayer) then Steal.dropCarried(targetPlayer) end
	local away = targetRoot.Position - root.Position
	away = Vector3.new(away.X, 0, away.Z)
	if away.Magnitude < 1 then away = Vector3.new(0, 0, 1) end
	targetRoot.CFrame = targetRoot.CFrame + away.Unit * 12 + Vector3.new(0, 3, 0)
	targetPlayer:SetAttribute("BannerText", "SLAPPED by " .. player.Name .. "!")
	targetPlayer:SetAttribute("BannerUntil", os.time() + 3)
	return true
end

function Slap.giveTool(player)
	local character = player.Character
	if not character then return end
	if character:FindFirstChild("Slap") then return end
	local tool = Instance.new("Tool")
	tool.Name = "Slap"
	tool.RequiresHandle = false
	tool.CanBeDropped = false
	tool.Parent = character
	tool.Activated:Connect(function()
		local nearest = nil
		local nearestDist = 10
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then return end
		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= player and other.Character then
				local otherRoot = other.Character:FindFirstChild("HumanoidRootPart")
				if otherRoot then
					local dist = (otherRoot.Position - root.Position).Magnitude
					if dist < nearestDist then
						nearestDist = dist
						nearest = other
					end
				end
			end
		end
		if nearest then Slap.slapPlayer(player, nearest) end
	end)
end

return Slap
