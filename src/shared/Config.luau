-- Brainrot Blitz shared config: cast, rarities, prices, wave, rebirth, events.
-- All numbers are the single source of truth; server modules read them here.

local Config = {}

Config.STARTING_COINS = 150
Config.REBIRTH_COST = 10000
Config.REBIRTH_MULTIPLIER = 1.25
Config.REBIRTH_EXTRA_SLOTS = 2
Config.BASE_SLOTS = 8
Config.LOCK_SECONDS = 60
Config.LOCK_PER_REBIRTH = 10
Config.LOCK_COOLDOWN = 60
Config.SPAWN_PROTECTION = 30
Config.WAVE_INTERVAL = 120
Config.WAVE_WARNING = 20
Config.WAVE_SWEEP_SECONDS = 8
Config.WAVE_COIN_LOSS = 0.10
Config.GOLDEN_HOUR_CYCLE = 180
Config.GOLDEN_HOUR_SECONDS = 60
Config.MYTHIC_WINDOW_SECONDS = 60
Config.BELT_SPAWN_EVERY = 5
Config.BELT_SPEED = 6
Config.BELT_START_X = -65
Config.BELT_END_X = 65
Config.BELT_Z = 0
Config.STEAL_SLOW_SPEED = 8
Config.NORMAL_WALK_SPEED = 16

Config.RARITY_COLORS = {
	Common = Color3.fromRGB(170, 170, 170),
	Rare = Color3.fromRGB(60, 140, 255),
	Epic = Color3.fromRGB(170, 80, 255),
	Legendary = Color3.fromRGB(255, 200, 40),
	Mythic = Color3.fromRGB(255, 60, 60),
	Secret = Color3.fromRGB(120, 40, 200),
}

Config.RARITY_WEIGHTS = {
	{ rarity = "Common", weight = 55 },
	{ rarity = "Rare", weight = 25 },
	{ rarity = "Epic", weight = 12 },
	{ rarity = "Legendary", weight = 5 },
	{ rarity = "Mythic", weight = 2 },
	{ rarity = "Secret", weight = 1 },
}

-- Price ladder rises with $/sec, so the first buy is possible in <30s.
Config.CHARACTERS = {
	{ name = "Sir Quackington", rarity = "Common", income = 5, price = 50, body = Color3.fromRGB(255, 220, 80), accent = Color3.fromRGB(40, 40, 40), accessory = "TopHat" },
	{ name = "Captain Crumb", rarity = "Common", income = 6, price = 60, body = Color3.fromRGB(190, 140, 90), accent = Color3.fromRGB(120, 70, 30), accessory = "Cap" },
	{ name = "Turbo Turnip", rarity = "Common", income = 8, price = 75, body = Color3.fromRGB(180, 80, 220), accent = Color3.fromRGB(255, 255, 255), accessory = "Sneakers" },
	{ name = "Professor Pickle", rarity = "Rare", income = 20, price = 250, body = Color3.fromRGB(80, 200, 60), accent = Color3.fromRGB(30, 30, 30), accessory = "Glasses" },
	{ name = "Agent Avocado", rarity = "Rare", income = 25, price = 300, body = Color3.fromRGB(60, 140, 60), accent = Color3.fromRGB(20, 20, 20), accessory = "Sunglasses" },
	{ name = "DJ Toast", rarity = "Rare", income = 30, price = 350, body = Color3.fromRGB(220, 170, 90), accent = Color3.fromRGB(255, 80, 180), accessory = "Headphones" },
	{ name = "Captain Noodle", rarity = "Epic", income = 60, price = 800, body = Color3.fromRGB(255, 180, 60), accent = Color3.fromRGB(30, 30, 30), accessory = "PirateHat" },
	{ name = "Sir Reginald Ramen", rarity = "Epic", income = 75, price = 1000, body = Color3.fromRGB(230, 60, 60), accent = Color3.fromRGB(255, 220, 120), accessory = "ChefHat" },
	{ name = "Madame Mooncake", rarity = "Epic", income = 90, price = 1200, body = Color3.fromRGB(255, 150, 200), accent = Color3.fromRGB(255, 220, 40), accessory = "Crown" },
	{ name = "Lord Llama Latte", rarity = "Legendary", income = 150, price = 2500, body = Color3.fromRGB(240, 220, 190), accent = Color3.fromRGB(150, 90, 40), accessory = "Crown" },
	{ name = "Duchess Dumpling", rarity = "Legendary", income = 175, price = 3000, body = Color3.fromRGB(255, 255, 255), accent = Color3.fromRGB(255, 120, 180), accessory = "ChefHat" },
	{ name = "Sir Barksalot", rarity = "Legendary", income = 200, price = 3500, body = Color3.fromRGB(150, 100, 50), accent = Color3.fromRGB(30, 30, 90), accessory = "TopHat" },
	{ name = "The Golden Goblin of Gouda", rarity = "Mythic", income = 400, price = 7000, body = Color3.fromRGB(255, 210, 40), accent = Color3.fromRGB(255, 140, 0), accessory = "Crown" },
	{ name = "Emperor Eggplant", rarity = "Mythic", income = 600, price = 10000, body = Color3.fromRGB(120, 40, 180), accent = Color3.fromRGB(255, 220, 40), accessory = "Crown" },
	{ name = "Baron von Banana Peel", rarity = "Secret", income = 900, price = 15000, body = Color3.fromRGB(255, 240, 80), accent = Color3.fromRGB(60, 60, 60), accessory = "TopHat" },
	{ name = "The Infinite Spaghetti Monster", rarity = "Secret", income = 1200, price = 20000, body = Color3.fromRGB(255, 90, 90), accent = Color3.fromRGB(255, 220, 120), accessory = "PirateHat" },
}

Config.MUTATIONS = {
	{ name = "None", multiplier = 1, weight = 70, tint = nil },
	{ name = "Golden", multiplier = 2, weight = 15, tint = Color3.fromRGB(255, 210, 40) },
	{ name = "Diamond", multiplier = 4, weight = 8, tint = Color3.fromRGB(120, 220, 255) },
	{ name = "Blood", multiplier = 6, weight = 4, tint = Color3.fromRGB(200, 30, 30) },
	{ name = "Rainbow", multiplier = 8, weight = 3, tint = Color3.fromRGB(255, 80, 220) },
}

-- Eight base plots around the plaza edges: corners plus edge midpoints.
Config.BASES = {
	{ position = Vector3.new(-70, 0, -70), color = Color3.fromRGB(255, 90, 90) },
	{ position = Vector3.new(0, 0, -70), color = Color3.fromRGB(90, 160, 255) },
	{ position = Vector3.new(70, 0, -70), color = Color3.fromRGB(90, 255, 130) },
	{ position = Vector3.new(70, 0, 0), color = Color3.fromRGB(255, 200, 60) },
	{ position = Vector3.new(70, 0, 70), color = Color3.fromRGB(200, 90, 255) },
	{ position = Vector3.new(0, 0, 70), color = Color3.fromRGB(90, 230, 230) },
	{ position = Vector3.new(-70, 0, 70), color = Color3.fromRGB(255, 140, 90) },
	{ position = Vector3.new(-70, 0, 0), color = Color3.fromRGB(180, 255, 90) },
}

return Config
