-- Brainrot Blitz shared config: cast, rarities, mutations, prices, timings.
-- One place holds every number the game runs on, so client and server agree.

local Config = {}

Config.STARTING_COINS = 150
Config.BASE_SLOTS = 8
Config.REBIRTH_COST = 10000
Config.REBIRTH_BONUS = 0.25
Config.REBIRTH_EXTRA_SLOTS = 2

Config.LOCK_DURATION = 60
Config.LOCK_PER_REBIRTH = 10
Config.LOCK_COOLDOWN = 60
Config.SPAWN_PROTECTION = 30

Config.BELT_SPEED = 6
Config.BELT_START_Z = -60
Config.BELT_END_Z = 60
Config.BELT_MAX_LIVE = 7
Config.SPAWN_CHECK_SECONDS = 2

Config.WAVE_INTERVAL = 120
Config.WAVE_WARNING = 20
Config.WAVE_COIN_LOSS = 0.10

Config.GOLDEN_INTERVAL = 180
Config.GOLDEN_DURATION = 60
Config.MYTHIC_WINDOW = 60

Config.RARITIES = {
	Common = { color = Color3.fromRGB(170, 170, 170), weight = 40 },
	Rare = { color = Color3.fromRGB(0, 140, 255), weight = 28 },
	Epic = { color = Color3.fromRGB(170, 60, 255), weight = 16 },
	Legendary = { color = Color3.fromRGB(255, 200, 0), weight = 9 },
	Mythic = { color = Color3.fromRGB(255, 45, 45), weight = 5 },
	Secret = { color = Color3.fromRGB(120, 0, 190), weight = 2 },
}

Config.MUTATIONS = {
	{ name = "None", mult = 1, color = Color3.fromRGB(255, 255, 255), chance = 70 },
	{ name = "Golden", mult = 2, color = Color3.fromRGB(255, 215, 0), chance = 15 },
	{ name = "Diamond", mult = 4, color = Color3.fromRGB(120, 220, 255), chance = 7 },
	{ name = "Rainbow", mult = 8, color = Color3.fromRGB(255, 90, 220), chance = 4 },
	{ name = "Blood", mult = 6, color = Color3.fromRGB(200, 0, 0), chance = 4 },
}

-- Prices rise with rarity and stay roughly 10x-50x the $/sec rate.
-- The first buy (Sir Quackington, $50) is affordable from the $150 start.
Config.CHARACTERS = {
	{ name = "Sir Quackington", rarity = "Common", rate = 5, price = 50, body = Color3.fromRGB(255, 220, 60), head = Color3.fromRGB(255, 240, 150), accessory = "TopHat" },
	{ name = "Turbo Turnip", rarity = "Common", rate = 8, price = 75, body = Color3.fromRGB(150, 60, 200), head = Color3.fromRGB(190, 120, 230), accessory = "Sneakers" },
	{ name = "Captain Crumb", rarity = "Common", rate = 6, price = 100, body = Color3.fromRGB(140, 90, 40), head = Color3.fromRGB(190, 140, 80), accessory = "ChefHat" },
	{ name = "Professor Pickle", rarity = "Rare", rate = 20, price = 250, body = Color3.fromRGB(60, 180, 60), head = Color3.fromRGB(100, 220, 100), accessory = "Glasses" },
	{ name = "DJ Toast", rarity = "Rare", rate = 30, price = 350, body = Color3.fromRGB(220, 170, 90), head = Color3.fromRGB(240, 200, 130), accessory = "Headphones" },
	{ name = "Agent Avocado", rarity = "Rare", rate = 25, price = 500, body = Color3.fromRGB(40, 120, 50), head = Color3.fromRGB(80, 170, 70), accessory = "Shades" },
	{ name = "Captain Noodle", rarity = "Epic", rate = 60, price = 800, body = Color3.fromRGB(255, 140, 40), head = Color3.fromRGB(255, 190, 100), accessory = "PirateHat" },
	{ name = "Madame Mooncake", rarity = "Epic", rate = 90, price = 1200, body = Color3.fromRGB(255, 150, 200), head = Color3.fromRGB(255, 200, 225), accessory = "Crown" },
	{ name = "Sir Reginald Ramen", rarity = "Epic", rate = 75, price = 1500, body = Color3.fromRGB(220, 50, 50), head = Color3.fromRGB(255, 120, 120), accessory = "BowTie" },
	{ name = "Lord Llama Latte", rarity = "Legendary", rate = 150, price = 2500, body = Color3.fromRGB(240, 230, 200), head = Color3.fromRGB(255, 245, 220), accessory = "Cup" },
	{ name = "Sir Barksalot", rarity = "Legendary", rate = 200, price = 3500, body = Color3.fromRGB(120, 70, 20), head = Color3.fromRGB(170, 110, 50), accessory = "Ears" },
	{ name = "Duchess Dumpling", rarity = "Legendary", rate = 175, price = 4500, body = Color3.fromRGB(250, 250, 250), head = Color3.fromRGB(255, 255, 255), accessory = "Halo" },
	{ name = "The Golden Goblin of Gouda", rarity = "Mythic", rate = 400, price = 7000, body = Color3.fromRGB(255, 200, 0), head = Color3.fromRGB(255, 220, 80), accessory = "Crown" },
	{ name = "Emperor Eggplant", rarity = "Mythic", rate = 600, price = 10000, body = Color3.fromRGB(90, 30, 140), head = Color3.fromRGB(140, 70, 200), accessory = "Halo" },
	{ name = "Baron von Banana Peel", rarity = "Secret", rate = 900, price = 45000, body = Color3.fromRGB(255, 235, 60), head = Color3.fromRGB(255, 245, 140), accessory = "Wings" },
	{ name = "The Infinite Spaghetti Monster", rarity = "Secret", rate = 1200, price = 60000, body = Color3.fromRGB(255, 100, 160), head = Color3.fromRGB(255, 160, 200), accessory = "TopHat" },
}

Config.BASE_COLORS = {
	Color3.fromRGB(255, 80, 80),
	Color3.fromRGB(80, 140, 255),
	Color3.fromRGB(80, 220, 120),
	Color3.fromRGB(255, 200, 40),
	Color3.fromRGB(200, 80, 255),
	Color3.fromRGB(255, 140, 40),
	Color3.fromRGB(60, 220, 220),
	Color3.fromRGB(255, 120, 200),
}

-- Eight base plots in a ring around the plaza, 70 studs from the centre.
Config.BASES = {
	{ x = 70, z = 0 },
	{ x = 50, z = 50 },
	{ x = 0, z = 70 },
	{ x = -50, z = 50 },
	{ x = -70, z = 0 },
	{ x = -50, z = -50 },
	{ x = 0, z = -70 },
	{ x = 50, z = -50 },
}

function Config.getCharacter(name)
	for _, char in ipairs(Config.CHARACTERS) do
		if char.name == name then
			return char
		end
	end
	return nil
end

function Config.getNextTier(afterName)
	local sorted = {}
	for _, char in ipairs(Config.CHARACTERS) do
		table.insert(sorted, char)
	end
	table.sort(sorted, function(a, b)
		return a.price < b.price
	end)
	for i, char in ipairs(sorted) do
		if char.name == afterName then
			return sorted[math.min(i + 1, #sorted)]
		end
	end
	return sorted[4]
end

return Config
