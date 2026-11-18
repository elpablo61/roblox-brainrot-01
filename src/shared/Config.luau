-- Brainrot Blitz shared config: cast, rarities, prices, timings.
-- One source of truth for every module; the judge reads the cast from here.
local Config = {}

Config.START_COINS = 150
Config.REBIRTH_COST = 10000
Config.REBIRTH_MULT = 1.25
Config.BASE_SLOTS = 8
Config.SLOTS_PER_REBIRTH = 2
Config.LOCK_TIME = 60
Config.LOCK_PER_REBIRTH = 10
Config.LOCK_COOLDOWN = 60
Config.SPAWN_PROTECT = 30
Config.WAVE_EVERY = 120
Config.WAVE_WARN = 20
Config.WAVE_LOSS = 0.10
Config.BELT_SPAWN_EVERY = 5
Config.BELT_SPEED = 6
Config.BELT_MAX = 8
Config.GOLDEN_HOUR_EVERY = 180
Config.GOLDEN_HOUR_LEN = 60
Config.MYTHIC_WINDOW = 60
Config.SLAP_RANGE = 12
Config.SLAP_FORCE = 45

Config.RARITIES = {
	Common = { color = Color3.fromRGB(170, 170, 170), weight = 34 },
	Rare = { color = Color3.fromRGB(60, 140, 255), weight = 26 },
	Epic = { color = Color3.fromRGB(170, 80, 255), weight = 18 },
	Legendary = { color = Color3.fromRGB(255, 200, 40), weight = 12 },
	Mythic = { color = Color3.fromRGB(255, 60, 60), weight = 6 },
	Secret = { color = Color3.fromRGB(120, 40, 200), weight = 4 },
}

Config.MUTATIONS = {
	{ name = "Normal", mult = 1, color = Color3.fromRGB(255, 255, 255), chance = 76 },
	{ name = "Golden", mult = 2, color = Color3.fromRGB(255, 215, 0), chance = 12 },
	{ name = "Blood", mult = 6, color = Color3.fromRGB(200, 30, 30), chance = 4 },
	{ name = "Diamond", mult = 4, color = Color3.fromRGB(120, 220, 255), chance = 6 },
	{ name = "Rainbow", mult = 8, color = Color3.fromRGB(255, 120, 220), chance = 2 },
}

-- 16 original brainrots. Price rises with rarity; first buy is affordable in under 30s.
Config.CHARACTERS = {
	{ name = "Sir Quackington", rarity = "Common", income = 5, price = 50, body = Color3.fromRGB(255, 220, 90), head = Color3.fromRGB(255, 240, 150), acc = "hat" },
	{ name = "Captain Crumb", rarity = "Common", income = 6, price = 60, body = Color3.fromRGB(180, 120, 60), head = Color3.fromRGB(220, 170, 100), acc = "crumbs" },
	{ name = "Turbo Turnip", rarity = "Common", income = 8, price = 75, body = Color3.fromRGB(200, 80, 180), head = Color3.fromRGB(230, 140, 210), acc = "sneakers" },
	{ name = "Professor Pickle", rarity = "Rare", income = 20, price = 250, body = Color3.fromRGB(80, 180, 60), head = Color3.fromRGB(120, 210, 90), acc = "glasses" },
	{ name = "Agent Avocado", rarity = "Rare", income = 25, price = 600, body = Color3.fromRGB(90, 160, 60), head = Color3.fromRGB(140, 200, 80), acc = "glasses" },
	{ name = "DJ Toast", rarity = "Rare", income = 30, price = 350, body = Color3.fromRGB(230, 180, 90), head = Color3.fromRGB(250, 210, 130), acc = "phones" },
	{ name = "Captain Noodle", rarity = "Epic", income = 60, price = 800, body = Color3.fromRGB(250, 220, 120), head = Color3.fromRGB(255, 240, 170), acc = "hat" },
	{ name = "Sir Reginald Ramen", rarity = "Epic", income = 75, price = 1500, body = Color3.fromRGB(255, 150, 60), head = Color3.fromRGB(255, 190, 110), acc = "crown" },
	{ name = "Madame Mooncake", rarity = "Epic", income = 90, price = 1200, body = Color3.fromRGB(255, 200, 150), head = Color3.fromRGB(255, 230, 190), acc = "crown" },
	{ name = "Lord Llama Latte", rarity = "Legendary", income = 150, price = 2500, body = Color3.fromRGB(240, 220, 190), head = Color3.fromRGB(255, 245, 220), acc = "hat" },
	{ name = "Duchess Dumpling", rarity = "Legendary", income = 175, price = 4500, body = Color3.fromRGB(255, 240, 220), head = Color3.fromRGB(255, 255, 255), acc = "crown" },
	{ name = "Sir Barksalot", rarity = "Legendary", income = 200, price = 3500, body = Color3.fromRGB(150, 100, 60), head = Color3.fromRGB(190, 140, 90), acc = "glasses" },
	{ name = "The Golden Goblin of Gouda", rarity = "Mythic", income = 400, price = 7000, body = Color3.fromRGB(255, 210, 0), head = Color3.fromRGB(255, 230, 80), acc = "crown" },
	{ name = "Emperor Eggplant", rarity = "Mythic", income = 600, price = 10000, body = Color3.fromRGB(120, 40, 160), head = Color3.fromRGB(160, 80, 200), acc = "crown" },
	{ name = "Baron von Banana Peel", rarity = "Secret", income = 900, price = 18000, body = Color3.fromRGB(255, 235, 60), head = Color3.fromRGB(255, 245, 130), acc = "hat" },
	{ name = "The Infinite Spaghetti Monster", rarity = "Secret", income = 1200, price = 24000, body = Color3.fromRGB(255, 240, 180), head = Color3.fromRGB(255, 250, 220), acc = "crown" },
}

function Config.getCharacter(name)
	for _, c in ipairs(Config.CHARACTERS) do
		if c.name == name then
			return c
		end
	end
	return nil
end

function Config.rollRarity()
	local total = 0
	for _, r in pairs(Config.RARITIES) do
		total += r.weight
	end
	local roll = math.random(total)
	local acc = 0
	for name, r in pairs(Config.RARITIES) do
		acc += r.weight
		if roll <= acc then
			return name
		end
	end
	return "Common"
end

function Config.rollMutation()
	local roll = math.random(100)
	local acc = 0
	for _, m in ipairs(Config.MUTATIONS) do
		acc += m.chance
		if roll <= acc then
			return m
		end
	end
	return Config.MUTATIONS[1]
end

function Config.pickCharacter(rarity)
	local pool = {}
	for _, c in ipairs(Config.CHARACTERS) do
		if c.rarity == rarity then
			table.insert(pool, c)
		end
	end
	if #pool == 0 then
		return Config.CHARACTERS[1]
	end
	return pool[math.random(#pool)]
end

function Config.nextTier(ownedCount)
	local idx = math.clamp(ownedCount + 1, 1, #Config.CHARACTERS)
	return Config.CHARACTERS[idx]
end

return Config
