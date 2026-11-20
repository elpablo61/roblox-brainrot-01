-- Brainrot Blitz -- server bootstrap.
-- Requires every module, wires them together, creates the shared
-- GameState the HUD reads, starts the loops, hands each joining
-- player their coins, base and Slap tool.
-- Written fresh from the prose spec. Module calls use only the
-- interface observed live in Studio: Economy/Conveyor/Steal start
-- through start(), Wave through init(), Rebirth wires through
-- setEconomy(), Slap hands out its tool through createTool().

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(script.Economy)
local Conveyor = require(script.Conveyor)
local Wave = require(script.Wave)
local Steal = require(script.Steal)
local Rebirth = require(script.Rebirth)
local Slap = require(script.Slap)

-- Shared state the HUD and the wave timer read.
local gameState = ReplicatedStorage:FindFirstChild("GameState")
if not gameState then
	gameState = Instance.new("Folder")
	gameState.Name = "GameState"
	gameState.Parent = ReplicatedStorage
end
gameState:SetAttribute("WaveTimer", 120)
gameState:SetAttribute("GoldenActive", false)
gameState:SetAttribute("MythicActive", false)

-- Wire the modules together.
Economy.setSteal(Steal)
Conveyor.setEconomy(Economy)
Conveyor.setSteal(Steal)
Steal.setEconomy(Economy)
Rebirth.setEconomy(Economy)

-- Start the loops.
Economy.start()
Conveyor.start()
Steal.start()
Wave.init()

-- Players: coins, base and income on join, plus the Slap tool
-- (only if nothing else already handed one out).
local function onPlayerAdded(player)
	Economy.onPlayerAdded(player)
	local backpack = player:FindFirstChild("Backpack")
	if backpack and not backpack:FindFirstChild("Slap") then
		Slap.createTool(player)
	end
end
Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
Players.PlayerRemoving:Connect(function(player)
	Economy.onPlayerRemoving(player)
end)

print("Brainrot Blitz server ready: 16 brainrots, 8 bases, conveyor live.")
