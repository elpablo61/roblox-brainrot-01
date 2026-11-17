-- Slap: every player spawns with a Slap tool. Click to shove the nearest
-- rival backwards — and knock loose any brainrot they are carrying.

local Players = game:GetService("Players")

local Slap = {}

function Slap.slapPlayer(player, target)
	if not target or target == player then
		return false
	end
	local character = player.Character
	local targetCharacter = target.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
	if not root or not targetRoot then
		return false
	end
	local distance = (targetRoot.Position - root.Position).Magnitude
	if distance > 14 then
		return false
	end
	local direction = (targetRoot.Position - root.Position).Unit
	targetRoot:ApplyImpulse(direction * 6000 + Vector3.new(0, 2000, 0))
	local Steal = require(script.Parent:WaitForChild("Steal"))
	Steal.dropCarried(target)
	return true
end

function Slap.giveSlapTool(player)
	local function onCharacter(character)
		local tool = Instance.new("Tool")
		tool.Name = "Slap"
		tool.RequiresHandle = true
		tool.CanBeDropped = false
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(1, 0.4, 2.5)
		handle.Color = Color3.fromRGB(255, 220, 100)
		handle.Material = Enum.Material.SmoothPlastic
		handle.Parent = tool
		tool.Parent = player:WaitForChild("Backpack")
		tool.Activated:Connect(function()
			local nearest = nil
			local nearestDistance = 14
			local root = character:FindFirstChild("HumanoidRootPart")
			if not root then
				return
			end
			for _, other in ipairs(Players:GetPlayers()) do
				if other ~= player then
					local otherRoot = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
					if otherRoot then
						local d = (otherRoot.Position - root.Position).Magnitude
						if d < nearestDistance then
							nearestDistance = d
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
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		onCharacter(player.Character)
	end
end

function Slap.start()
	Players.PlayerAdded:Connect(function(player)
		Slap.giveSlapTool(player)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		Slap.giveSlapTool(player)
	end
end

return Slap
