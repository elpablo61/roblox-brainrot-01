-- Brainrot Blitz server bootstrap: creates the remotes and game state,
-- wires the modules together, and starts the conveyor, the economy tick,
-- the wave timer and the steal loop.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Conveyor = require(script.Conveyor)
local Economy = require(script.Economy)
local Wave = require(script.Wave)
local Steal = require(script.Steal)
local Rebirth = require(script.Rebirth)
local Slap = require(script.Slap)

local function createRemotes()
	local remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
	for _, name in ipairs({ "Notify", "LockRequest", "RebirthRequest", "SlapRequest" }) do
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = remotes
	end
	local state = Instance.new("Folder")
	state.Name = "GameState"
	state.Parent = ReplicatedStorage
	state:SetAttribute("WaveTimer", Config.Wave.Interval)
	state:SetAttribute("GoldenActive", false)
	state:SetAttribute("MythicActive", false)
	state:SetAttribute("GoldenUntil", 0)
	state:SetAttribute("MythicUntil", 0)
	local dropped = Instance.new("Folder")
	dropped.Name = "DroppedBrainrots"
	dropped.Parent = workspace
end

local function wireModules()
	Conveyor.setEconomy(Economy)
	Conveyor.setSteal(Steal)
	Economy.setSteal(Steal)
	Steal.setEconomy(Economy)
	Wave.setEconomy(Economy)
	Wave.setSteal(Steal)
	Rebirth.setEconomy(Economy)
	Slap.setSteal(Steal)
end

local function connectRemotes()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	remotes.LockRequest.OnServerEvent:Connect(function(player)
		Steal.lockBase(player)
	end)
	remotes.RebirthRequest.OnServerEvent:Connect(function(player)
		Rebirth.applyRebirth(player)
	end)
	remotes.SlapRequest.OnServerEvent:Connect(function(player)
		local victim = Slap.findVictim(player)
		if victim then
			Slap.slapPlayer(player, victim)
		end
	end)
end

local function updateNextTierBoard()
	local board = workspace:FindFirstChild("NextTierBoard")
	if not board then
		return
	end
	local gui = board:FindFirstChild("BoardGui")
	local label = gui and gui:FindFirstChild("TierLabel")
	if not label then
		return
	end
	local most = 0
	for _, player in ipairs(Players:GetPlayers()) do
		most = math.max(most, #Economy.getOwned(player))
	end
	local next = Config.getNextTier(most)
	label.Text = "NEXT: " .. string.upper(next.Rarity) .. " — " .. next.Name .. " — $" .. next.Rate .. "/s — $" .. next.Price
end

local function connectPlayers()
	Players.PlayerAdded:Connect(function(player)
		Economy.onPlayerAdded(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		Economy.onPlayerRemoving(player)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		Economy.onPlayerAdded(player)
	end
end

createRemotes()
wireModules()
connectRemotes()
connectPlayers()
Conveyor.start()
Economy.start()
Wave.start()
Steal.start()
task.spawn(function()
	while true do
		task.wait(5)
		updateNextTierBoard()
	end
end)
print("Brainrot Blitz server ready: 16 brainrots, 8 bases, conveyor live")
