-- Brainrot Blitz: one source of truth for the whole game.
-- Characters, rarities, prices, mutations, wave, lock and rebirth rules.
-- Every other module reads this; nothing else hardcodes a number.

local Config = {}

Config.StartingCash = 150
Config.BaseSlots = 8
Config.MaxPlayers = 8

Config.Rarities = {
	Common = { Color = Color3.fromRGB(170, 170, 170), Weight = 45 },
	Rare = { Color = Color3.fromRGB(60, 120, 255), Weight = 25 },
	Epic = { Color = Color3.fromRGB(170, 80, 255), Weight = 15 },
	Legendary = { Color = Color3.fromRGB(255, 200, 0), Weight = 9 },
	Mythic = { Color = Color3.fromRGB(255, 60, 60), Weight = 4 },
	Secret = { Color = Color3.fromRGB(40, 0, 80), Weight = 2 },
}

Config.RarityOrder = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Secret" }

-- Buy price is roughly 10-50x the $/sec rate and strictly rises with rarity.
-- Starting cash $150 buys the first Common within 30 seconds of spawning.
Config.Characters = {
	{ Name = "Sir Quackington", Rarity = "Common", Rate = 5, Price = 50,
		Body = Color3.fromRGB(255, 220, 80), Head = Color3.fromRGB(255, 200, 40), Accessory = "TopHat" },
	{ Name = "Captain Crumb", Rarity = "Common", Rate = 6, Price = 75,
		Body = Color3.fromRGB(180, 120, 60), Head = Color3.fromRGB(200, 150, 90), Accessory = "Cap" },
	{ Name = "Turbo Turnip", Rarity = "Common", Rate = 8, Price = 150,
		Body = Color3.fromRGB(200, 80, 200), Head = Color3.fromRGB(220, 120, 220), Accessory = "Sneakers" },
	{ Name = "Professor Pickle", Rarity = "Rare", Rate = 20, Price = 250,
		Body = Color3.fromRGB(80, 200, 80), Head = Color3.fromRGB(100, 220, 100), Accessory = "Glasses" },
	{ Name = "Agent Avocado", Rarity = "Rare", Rate = 25, Price = 350,
		Body = Color3.fromRGB(60, 160, 60), Head = Color3.fromRGB(90, 190, 90), Accessory = "Tie" },
	{ Name = "DJ Toast", Rarity = "Rare", Rate = 30, Price = 750,
		Body = Color3.fromRGB(220, 180, 120), Head = Color3.fromRGB(235, 200, 140), Accessory = "Headphones" },
	{ Name = "Captain Noodle", Rarity = "Epic", Rate = 60, Price = 800,
		Body = Color3.fromRGB(255, 220, 100), Head = Color3.fromRGB(255, 230, 130), Accessory = "PirateHat" },
	{ Name = "Sir Reginald Ramen", Rarity = "Epic", Rate = 75, Price = 1200,
		Body = Color3.fromRGB(230, 90, 60), Head = Color3.fromRGB(240, 120, 80), Accessory = "Crown" },
	{ Name = "Madame Mooncake", Rarity = "Epic", Rate = 90, Price = 2000,
		Body = Color3.fromRGB(240, 210, 160), Head = Color3.fromRGB(250, 225, 180), Accessory = "Flower" },
	{ Name = "Lord Llama Latte", Rarity = "Legendary", Rate = 150, Price = 2500,
		Body = Color3.fromRGB(245, 235, 215), Head = Color3.fromRGB(255, 245, 225), Accessory = "Crown" },
	{ Name = "Duchess Dumpling", Rarity = "Legendary", Rate = 175, Price = 3500,
		Body = Color3.fromRGB(250, 220, 230), Head = Color3.fromRGB(255, 235, 240), Accessory = "Tiara" },
	{ Name = "Sir Barksalot", Rarity = "Legendary", Rate = 200, Price = 5000,
		Body = Color3.fromRGB(150, 100, 60), Head = Color3.fromRGB(170, 120, 70), Accessory = "TopHat" },
	{ Name = "The Golden Goblin of Gouda", Rarity = "Mythic", Rate = 400, Price = 7000,
		Body = Color3.fromRGB(255, 200, 0), Head = Color3.fromRGB(255, 215, 40), Accessory = "Crown" },
	{ Name = "Emperor Eggplant", Rarity = "Mythic", Rate = 600, Price = 10000,
		Body = Color3.fromRGB(120, 40, 180), Head = Color3.fromRGB(140, 60, 200), Accessory = "Crown" },
	{ Name = "Baron von Banana Peel", Rarity = "Secret", Rate = 900, Price = 45000,
		Body = Color3.fromRGB(255, 230, 0), Head = Color3.fromRGB(255, 240, 60), Accessory = "Monocle" },
	{ Name = "The Infinite Spaghetti Monster", Rarity = "Secret", Rate = 1200, Price = 60000,
		Body = Color3.fromRGB(230, 120, 60), Head = Color3.fromRGB(240, 150, 80), Accessory = "Crown" },
}

Config.Mutations = {
	{ Name = "None", Multiplier = 1, Weight = 70, Tint = nil },
	{ Name = "Golden", Multiplier = 2, Weight = 15, Tint = Color3.fromRGB(255, 215, 0) },
	{ Name = "Diamond", Multiplier = 4, Weight = 8, Tint = Color3.fromRGB(180, 230, 255) },
	{ Name = "Rainbow", Multiplier = 8, Weight = 4, Tint = Color3.fromRGB(255, 100, 220) },
	{ Name = "Blood", Multiplier = 6, Weight = 3, Tint = Color3.fromRGB(200, 0, 0) },
}

Config.Conveyor = {
	Start = Vector3.new(-70, 0.45, 0),
	Finish = Vector3.new(70, 0.45, 0),
	Speed = 4,
	SpawnInterval = 4,
	MaxOnBelt = 10,
}

Config.Wave = {
	Interval = 120,
	Warning = 20,
	WallHeight = 30,
	WallWidth = 260,
	CoinDropPercent = 10,
}

Config.Lock = {
	Duration = 60,
	PerRebirth = 10,
	Cooldown = 60,
	SpawnProtection = 30,
}

Config.Rebirth = {
	Cost = 10000,
	Multiplier = 1.25,
	SlotsPerRebirth = 2,
}

Config.GoldenHour = {
	Interval = 180,
	Duration = 60,
}

Config.MythicBoost = {
	Duration = 60,
}

function Config.getCharacter(name)
	for _, char in ipairs(Config.Characters) do
		if char.Name == name then
			return char
		end
	end
	return nil
end

function Config.getRarityColor(rarity)
	local entry = Config.Rarities[rarity]
	if entry then
		return entry.Color
	end
	return Color3.fromRGB(170, 170, 170)
end

function Config.pickRarity()
	local total = 0
	for _, rarity in ipairs(Config.RarityOrder) do
		total += Config.Rarities[rarity].Weight
	end
	local roll = math.random(1, total)
	for _, rarity in ipairs(Config.RarityOrder) do
		roll -= Config.Rarities[rarity].Weight
		if roll <= 0 then
			return rarity
		end
	end
	return "Common"
end

function Config.pickCharacter()
	local rarity = Config.pickRarity()
	local pool = {}
	for _, char in ipairs(Config.Characters) do
		if char.Rarity == rarity then
			table.insert(pool, char)
		end
	end
	if #pool == 0 then
		return Config.Characters[1]
	end
	return pool[math.random(1, #pool)]
end

function Config.rollMutation()
	local total = 0
	for _, mutation in ipairs(Config.Mutations) do
		total += mutation.Weight
	end
	local roll = math.random(1, total)
	for _, mutation in ipairs(Config.Mutations) do
		roll -= mutation.Weight
		if roll <= 0 then
			return mutation
		end
	end
	return Config.Mutations[1]
end

function Config.getNextTier(ownedCount)
	local sorted = {}
	for _, char in ipairs(Config.Characters) do
		table.insert(sorted, char)
	end
	table.sort(sorted, function(a, b)
		return a.Price < b.Price
	end)
	local index = math.min(ownedCount + 1, #sorted)
	return sorted[index]
end

return Config
