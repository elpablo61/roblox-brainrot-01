-- init.server.luau
-- Brainrot Blitz server entrypoint: require every server module, make
-- sure the shared remotes and attributes exist, start each system,
-- hand every player a Slap tool, and open the conveyor for business.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(script.Economy)
local Conveyor = require(script.Conveyor)
local Steal = require(script.Steal)
local Rebirth = require(script.Rebirth)
local Wave = require(script.Wave)
local Slap = require(script.Slap)

-- Shared remotes: every client talks to the server through these.
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end
if not remotes:FindFirstChild("Notify") then
	local notify = Instance.new("RemoteEvent")
	notify.Name = "Notify"
	notify.Parent = remotes
end

-- Shared attributes the HUD reads: wave countdown, event flags, income multiplier.
ReplicatedStorage:SetAttribute("WaveTimer", 120)
ReplicatedStorage:SetAttribute("GoldenActive", false)
ReplicatedStorage:SetAttribute("MythicActive", false)
ReplicatedStorage:SetAttribute("IncomeMultiplier", 1)

-- Start the systems: the economy owns coins and player state, the
-- conveyor walks brainrots past the plaza, steal and rebirth wire
-- their remotes, the wave runs its countdown, and every player gets
-- a Slap tool to defend their base with.
Economy.init()
Conveyor.init()
Steal.init()
Rebirth.init()
Wave.init()
Slap.createTool()

-- How many brainrots and bases this place offers (for the ready line).
local brainrotCount = 16
local baseCount = 8
local shared = ReplicatedStorage:FindFirstChild("Shared")
local configModule = shared and shared:FindFirstChild("Config")
if configModule then
	local ok, Config = pcall(require, configModule)
	if ok and type(Config) == "table" then
		if type(Config.Characters) == "table" then
			brainrotCount = #Config.Characters
		end
		if type(Config.BaseCount) == "number" then
			baseCount = Config.BaseCount
		end
	end
end

print(("Brainrot Blitz server ready: %d brainrots, %d bases, conveyor live."):format(brainrotCount, baseCount))
