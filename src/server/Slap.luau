-- Slap.luau
-- Brainrot Blitz slap tool: a glove a player swings at a thief.
-- Clicking while the tool is equipped shoves the nearest player in
-- range backwards, stuns them briefly, and knocks loose any brainrot
-- they are carrying, so it drops on the floor for anyone to grab.
-- The tool itself is built fresh on every spawn by Slap.createTool,
-- never cloned from starter gear, so its activation stays connected.

local Slap = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SLAP_RANGE_STUDS = 12
local SLAP_COOLDOWN_SECONDS = 1.5
local KNOCKBACK_SPEED = 55
local KNOCKBACK_UP = 18
local STUN_SECONDS = 1.5

local lastSlapAt = {}

local findNearestPlayer
local dropCarriedBrainrot
local giveSlapTool
local getNotify

local function notifyPlayer(player, message)
	local notify = getNotify()
	if notify then
		notify:FireClient(player, message)
	end
end

function Slap.slapPlayer(slapper, target)
	if typeof(slapper) ~= "Instance" or not slapper:IsA("Player") then
		return false
	end
	if typeof(target) ~= "Instance" or not target:IsA("Player") then
		return false
	end
	if slapper == target then
		return false
	end
	local slapperCharacter = slapper.Character
	local targetCharacter = target.Character
	if not slapperCharacter or not targetCharacter then
		return false
	end
	local slapperRoot = slapperCharacter:FindFirstChild("HumanoidRootPart")
	local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
	local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
	if not slapperRoot or not targetRoot or not targetHumanoid then
		return false
	end
	if targetHumanoid.Health <= 0 then
		return false
	end
	local now = os.clock()
	if lastSlapAt[slapper] and now - lastSlapAt[slapper] < SLAP_COOLDOWN_SECONDS then
		return false
	end
	local offset = targetRoot.Position - slapperRoot.Position
	if offset.Magnitude > SLAP_RANGE_STUDS then
		return false
	end
	lastSlapAt[slapper] = now

	-- Shove the target away from the slapper, with a little lift.
	local direction = slapperRoot.CFrame.LookVector
	if offset.Magnitude > 0.001 then
		direction = offset.Unit
	end
	targetRoot.AssemblyLinearVelocity = direction * KNOCKBACK_SPEED + Vector3.new(0, KNOCKBACK_UP, 0)

	-- Brief stun: freeze walking, then restore the speed they had.
	local previousSpeed = targetHumanoid.WalkSpeed
	targetHumanoid.WalkSpeed = 0
	task.delay(STUN_SECONDS, function()
		if targetHumanoid.Parent then
			targetHumanoid.WalkSpeed = previousSpeed
		end
	end)

	-- A slapped thief drops whatever brainrot they are carrying.
	local dropped = dropCarriedBrainrot(target)
	if dropped then
		notifyPlayer(slapper, "SLAP! They dropped the brainrot!")
		notifyPlayer(target, "SLAPPED! You dropped the brainrot!")
	else
		notifyPlayer(target, "SLAPPED by " .. slapper.DisplayName .. "!")
	end
	return true
end

getNotify = function()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		return nil
	end
	local notify = remotes:FindFirstChild("Notify")
	if notify and notify:IsA("RemoteEvent") then
		return notify
	end
	return nil
end

findNearestPlayer = function(player)
	local character = player.Character
	if not character then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	local nearest = nil
	local nearestDistance = SLAP_RANGE_STUDS
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			local otherCharacter = other.Character
			local otherRoot = otherCharacter and otherCharacter:FindFirstChild("HumanoidRootPart")
			local otherHumanoid = otherCharacter and otherCharacter:FindFirstChildOfClass("Humanoid")
			if otherRoot and otherHumanoid and otherHumanoid.Health > 0 then
				local distance = (otherRoot.Position - root.Position).Magnitude
				if distance <= nearestDistance then
					nearest = other
					nearestDistance = distance
				end
			end
		end
	end
	return nearest
end

dropCarriedBrainrot = function(thief)
	local character = thief.Character
	if not character then
		return nil
	end
	-- A carried brainrot is welded to the thief. The weld can live under
	-- the character or under the brainrot model, so scan the whole world
	-- for a weld with one end in the thief and the other end in a model
	-- that is not the thief's own character.
	local carriedModel = nil
	local carryWeld = nil
	for _, descendant in ipairs(workspace:GetDescendants()) do
		if descendant:IsA("Weld") or descendant:IsA("WeldConstraint") then
			local part0 = descendant.Part0
			local part1 = descendant.Part1
			if part0 and part1 then
				local inCharacter0 = part0:IsDescendantOf(character)
				local inCharacter1 = part1:IsDescendantOf(character)
				if inCharacter0 ~= inCharacter1 then
					local foreign = inCharacter0 and part1 or part0
					local model = foreign:FindFirstAncestorOfClass("Model")
					if model and model ~= character and model:IsDescendantOf(workspace) then
						carriedModel = model
						carryWeld = descendant
						break
					end
				end
			end
		end
	end
	if not carriedModel then
		return nil
	end
	if carryWeld then
		carryWeld:Destroy()
	end
	carriedModel:SetAttribute("State", "Dropped")
	-- Lay it on the floor beside the thief so anyone can grab it again.
	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		local _, size = carriedModel:GetBoundingBox()
		local dropAt = root.Position + root.CFrame.LookVector * 3
		carriedModel:PivotTo(CFrame.new(dropAt.X, size.Y / 2 + 0.1, dropAt.Z))
	end
	-- Rewrite its label so the world shows it can be grabbed again.
	for _, descendant in ipairs(carriedModel:GetDescendants()) do
		if descendant:IsA("BillboardGui") then
			for _, label in ipairs(descendant:GetDescendants()) do
				if label:IsA("TextLabel") then
					local text = label.Text
					if string.find(text, "CARRIED") then
						label.Text = string.gsub(text, "CARRIED", "DROPPED — CLICK TO GRAB")
					elseif string.find(text, "STOLEN!") then
						label.Text = string.gsub(text, "STOLEN!", "DROPPED — CLICK TO GRAB")
					elseif string.find(text, "STOLEN") then
						label.Text = string.gsub(text, "STOLEN", "DROPPED — CLICK TO GRAB")
					elseif string.find(text, "YOURS") then
						label.Text = string.gsub(text, "YOURS", "DROPPED — CLICK TO GRAB")
					end
				end
			end
		end
	end
	return carriedModel
end

giveSlapTool = function(player, character)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end
	-- One fresh tool per spawn; drop any stale copy first so the tool
	-- never doubles up and its activation never goes stale.
	for _, old in ipairs(backpack:GetChildren()) do
		if old:IsA("Tool") and old.Name == "Slap" then
			old:Destroy()
		end
	end
	for _, old in ipairs(character:GetChildren()) do
		if old:IsA("Tool") and old.Name == "Slap" then
			old:Destroy()
		end
	end
	local tool = Instance.new("Tool")
	tool.Name = "Slap"
	tool.ToolTip = "Slap a thief to make them drop what they carry!"
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 0.4, 1.4)
	handle.Color = Color3.fromRGB(220, 60, 60)
	handle.Material = Enum.Material.SmoothPlastic
	handle.CanCollide = false
	handle.Parent = tool
	tool.Parent = backpack
	tool.Activated:Connect(function()
		local target = findNearestPlayer(player)
		if target then
			Slap.slapPlayer(player, target)
		end
	end)
end

function Slap.createTool()
	local function onPlayerAdded(player)
		player.CharacterAdded:Connect(function(character)
			giveSlapTool(player, character)
		end)
		if player.Character then
			giveSlapTool(player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
end

return Slap
