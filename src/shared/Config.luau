-- Brainrot Blitz shared config: the whole cast, prices, rarities, mutations and timings.
-- Every number the game uses lives here so the other modules never guess one.

local Config = {}

Config.startingCash = 150
Config.rebirthCost = 10000
Config.rebirthMultiplier = 1.25
Config.baseSlots = 8
Config.slotsPerRebirth = 2
Config.lockDuration = 60
Config.lockPerRebirth = 10
Config.lockCooldown = 60
Config.spawnProtection = 30
Config.waveInterval = 120
Config.waveWarning = 20
Config.goldenHourInterval = 180
Config.goldenHourDuration = 60
Config.mythicWindowDuration = 60
Config.beltSpeed = 4
Config.beltLength = 200
Config.spawnInterval = 6
Config.maxOnBelt = 8

Config.rarities = {
	Common = { color = Color3.fromRGB(170, 170, 170), order = 1 },
	Rare = { color = Color3.fromRGB(80, 160, 255), order = 2 },
	Epic = { color = Color3.fromRGB(180, 90, 255), order = 3 },
	Legendary = { color = Color3.fromRGB(255, 200, 40), order = 4 },
	Mythic = { color = Color3.fromRGB(255, 60, 60), order = 5 },
	Secret = { color = Color3.fromRGB(120, 40, 200), order = 6 },
}

Config.rarityWeights = {
	Common = 45,
	Rare = 28,
	Epic = 15,
	Legendary = 7,
	Mythic = 3.5,
	Secret = 1.5,
}

-- mutation name -> {multiplier, tint color, roll weight}
Config.mutations = {
	None = { multiplier = 1, color = nil, weight = 70 },
	Golden = { multiplier = 2, color = Color3.fromRGB(255, 215, 0), weight = 12 },
	Diamond = { multiplier = 4, color = Color3.fromRGB(140, 220, 255), weight = 8 },
	Rainbow = { multiplier = 8, color = Color3.fromRGB(255, 120, 220), weight = 6 },
	Blood = { multiplier = 6, color = Color3.fromRGB(160, 0, 0), weight = 4 },
}

-- The cast: 16 original brainrots. price is the buy price, rate is $/sec.
-- Prices rise monotonically with rate (A17 ladder).
Config.characters = {
	{ name = "Sir Quackington", rarity = "Common", rate = 5, price = 50, body = Color3.fromRGB(255, 220, 80), head = Color3.fromRGB(255, 240, 160), accessory = "TopHat" },
	{ name = "Captain Crumb", rarity = "Common", rate = 6, price = 60, body = Color3.fromRGB(190, 130, 70), head = Color3.fromRGB(220, 170, 110), accessory = "SailorHat" },
	{ name = "Turbo Turnip", rarity = "Common", rate = 8, price = 75, body = Color3.fromRGB(220, 90, 220), head = Color3.fromRGB(240, 140, 240), accessory = "Sneakers" },
	{ name = "Professor Pickle", rarity = "Rare", rate = 20, price = 250, body = Color3.fromRGB(90, 200, 90), head = Color3.fromRGB(130, 220, 130), accessory = "Glasses" },
	{ name = "Agent Avocado", rarity = "Rare", rate = 25, price = 300, body = Color3.fromRGB(70, 160, 70), head = Color3.fromRGB(110, 190, 110), accessory = "Sunglasses" },
	{ name = "DJ Toast", rarity = "Rare", rate = 30, price = 350, body = Color3.fromRGB(230, 180, 90), head = Color3.fromRGB(245, 210, 140), accessory = "Headphones" },
	{ name = "Captain Noodle", rarity = "Epic", rate = 60, price = 800, body = Color3.fromRGB(255, 230, 140), head = Color3.fromRGB(255, 245, 190), accessory = "PirateHat" },
	{ name = "Sir Reginald Ramen", rarity = "Epic", rate = 75, price = 1000, body = Color3.fromRGB(255, 160, 60), head = Color3.fromRGB(255, 190, 110), accessory = "BowlHat" },
	{ name = "Madame Mooncake", rarity = "Epic", rate = 90, price = 1200, body = Color3.fromRGB(255, 190, 210), head = Color3.fromRGB(255, 220, 230), accessory = "Crown" },
	{ name = "Lord Llama Latte", rarity = "Legendary", rate = 150, price = 2500, body = Color3.fromRGB(240, 220, 190), head = Color3.fromRGB(250, 240, 220), accessory = "TopHat" },
	{ name = "Duchess Dumpling", rarity = "Legendary", rate = 175, price = 3000, body = Color3.fromRGB(255, 240, 200), head = Color3.fromRGB(255, 250, 230), accessory = "Crown" },
	{ name = "Sir Barksalot", rarity = "Legendary", rate = 200, price = 3500, body = Color3.fromRGB(180, 130, 80), head = Color3.fromRGB(205, 160, 110), accessory = "Bowtie" },
	{ name = "The Golden Goblin of Gouda", rarity = "Mythic", rate = 400, price = 7000, body = Color3.fromRGB(255, 215, 0), head = Color3.fromRGB(255, 230, 90), accessory = "Crown" },
	{ name = "Emperor Eggplant", rarity = "Mythic", rate = 600, price = 10000, body = Color3.fromRGB(120, 50, 180), head = Color3.fromRGB(160, 90, 210), accessory = "Crown" },
	{ name = "Baron von Banana Peel", rarity = "Secret", rate = 900, price = 15000, body = Color3.fromRGB(255, 235, 60), head = Color3.fromRGB(255, 245, 130), accessory = "TopHat" },
	{ name = "The Infinite Spaghetti Monster", rarity = "Secret", rate = 1200, price = 20000, body = Color3.fromRGB(255, 220, 120), head = Color3.fromRGB(255, 240, 180), accessory = "BowlHat" },
}

function Config.getCharacter(name)
	for _, def in ipairs(Config.characters) do
		if def.name == name then
			return def
		end
	end
	return nil
end

function Config.getCharactersByRarity(rarity)
	local out = {}
	for _, def in ipairs(Config.characters) do
		if def.rarity == rarity then
			table.insert(out, def)
		end
	end
	return out
end

function Config.rollRarity(rng)
	local total = 0
	for _, w in pairs(Config.rarityWeights) do
		total += w
	end
	local roll = rng:NextNumber(0, total)
	local acc = 0
	for rarity, w in pairs(Config.rarityWeights) do
		acc += w
		if roll <= acc then
			return rarity
		end
	end
	return "Common"
end

function Config.rollMutation(rng)
	local total = 0
	for _, m in pairs(Config.mutations) do
		total += m.weight
	end
	local roll = rng:NextNumber(0, total)
	local acc = 0
	for name, m in pairs(Config.mutations) do
		acc += m.weight
		if roll <= acc then
			return name
		end
	end
	return "None"
end

function Config.effectiveRate(def, mutation)
	local m = Config.mutations[mutation]
	if m then
		return def.rate * m.multiplier
	end
	return def.rate
end

return Config
