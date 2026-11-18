-- Brainrot Blitz shared config: the whole cast, rarities, mutations, prices,
-- wave timing, lock rules and rebirth rules. One table, read by every module.

local Config = {}

Config.START_COINS = 150
Config.BASE_SLOTS = 8
Config.SLOTS_PER_REBIRTH = 2
Config.REBIRTH_COST = 10000
Config.REBIRTH_MULT = 0.25
Config.LOCK_DURATION = 60
Config.LOCK_PER_REBIRTH = 10
Config.LOCK_COOLDOWN = 60
Config.SPAWN_PROTECTION = 30
Config.WAVE_INTERVAL = 120
Config.WAVE_WARNING = 20
Config.WAVE_SWEEP = 8
Config.WAVE_COIN_LOSS = 0.10
Config.GOLDEN_INTERVAL = 180
Config.GOLDEN_DURATION = 60
Config.MYTHIC_WINDOW = 60
Config.BELT_SPEED = 6
Config.BELT_START_X = -72
Config.BELT_END_X = 72
Config.BELT_Z = 0
Config.MAX_BELT = 8
Config.SPAWN_GAP = 3
Config.CLICK_DISTANCE = 40
Config.CARRY_SPEED = 8
Config.NORMAL_SPEED = 16

Config.RARITIES = {
	Common = { color = Color3.fromRGB(170, 170, 170), weight = 45 },
	Rare = { color = Color3.fromRGB(0, 120, 255), weight = 27 },
	Epic = { color = Color3.fromRGB(170, 0, 255), weight = 15 },
	Legendary = { color = Color3.fromRGB(255, 200, 0), weight = 8 },
	Mythic = { color = Color3.fromRGB(255, 40, 40), weight = 3 },
	Secret = { color = Color3.fromRGB(90, 0, 160), weight = 2 },
}

Config.MUTATIONS = {
	{ name = "None", mult = 1, color = Color3.fromRGB(255, 255, 255), weight = 80 },
	{ name = "Golden", mult = 2, color = Color3.fromRGB(255, 215, 0), weight = 11 },
	{ name = "Diamond", mult = 4, color = Color3.fromRGB(120, 220, 255), weight = 5 },
	{ name = "Blood", mult = 6, color = Color3.fromRGB(200, 0, 0), weight = 2 },
	{ name = "Rainbow", mult = 8, color = Color3.fromRGB(255, 100, 220), weight = 2 },
}

-- Prices rise with rarity and with $/sec: the first buy is possible in under
-- 30 seconds from the $150 starting cash (cheapest Common is $50).
Config.CHARACTERS = {
	{ name = "Sir Quackington", rarity = "Common", rate = 5, price = 50, color = Color3.fromRGB(255, 220, 0), accessory = "hat" },
	{ name = "Captain Crumb", rarity = "Common", rate = 6, price = 60, color = Color3.fromRGB(150, 90, 40), accessory = "hat" },
	{ name = "Turbo Turnip", rarity = "Common", rate = 8, price = 75, color = Color3.fromRGB(160, 60, 200), accessory = "sneakers" },
	{ name = "Professor Pickle", rarity = "Rare", rate = 20, price = 250, color = Color3.fromRGB(60, 200, 60), accessory = "glasses" },
	{ name = "Agent Avocado", rarity = "Rare", rate = 25, price = 300, color = Color3.fromRGB(40, 140, 60), accessory = "glasses" },
	{ name = "DJ Toast", rarity = "Rare", rate = 30, price = 350, color = Color3.fromRGB(220, 170, 90), accessory = "headphones" },
	{ name = "Captain Noodle", rarity = "Epic", rate = 60, price = 800, color = Color3.fromRGB(255, 140, 0), accessory = "hat" },
	{ name = "Sir Reginald Ramen", rarity = "Epic", rate = 75, price = 1000, color = Color3.fromRGB(230, 40, 40), accessory = "crown" },
	{ name = "Madame Mooncake", rarity = "Epic", rate = 90, price = 1200, color = Color3.fromRGB(255, 210, 120), accessory = "crown" },
	{ name = "Lord Llama Latte", rarity = "Legendary", rate = 150, price = 2500, color = Color3.fromRGB(240, 220, 180), accessory = "hat" },
	{ name = "Duchess Dumpling", rarity = "Legendary", rate = 175, price = 3000, color = Color3.fromRGB(250, 250, 250), accessory = "crown" },
	{ name = "Sir Barksalot", rarity = "Legendary", rate = 200, price = 3500, color = Color3.fromRGB(120, 70, 20), accessory = "bowtie" },
	{ name = "The Golden Goblin of Gouda", rarity = "Mythic", rate = 400, price = 7000, color = Color3.fromRGB(255, 215, 0), accessory = "crown" },
	{ name = "Emperor Eggplant", rarity = "Mythic", rate = 600, price = 10000, color = Color3.fromRGB(120, 0, 180), accessory = "crown" },
	{ name = "Baron von Banana Peel", rarity = "Secret", rate = 900, price = 45000, color = Color3.fromRGB(255, 235, 0), accessory = "hat" },
	{ name = "The Infinite Spaghetti Monster", rarity = "Secret", rate = 1200, price = 60000, color = Color3.fromRGB(255, 80, 40), accessory = "crown" },
}

Config.BASE_COLORS = {
	Color3.fromRGB(255, 80, 80),
	Color3.fromRGB(80, 140, 255),
	Color3.fromRGB(80, 220, 120),
	Color3.fromRGB(255, 200, 40),
	Color3.fromRGB(200, 80, 255),
	Color3.fromRGB(80, 220, 220),
	Color3.fromRGB(255, 140, 80),
	Color3.fromRGB(255, 120, 200),
}

Config.BASE_POSITIONS = {
	Vector3.new(-63, 0, -48),
	Vector3.new(-21, 0, -48),
	Vector3.new(21, 0, -48),
	Vector3.new(63, 0, -48),
	Vector3.new(-63, 0, 48),
	Vector3.new(-21, 0, 48),
	Vector3.new(21, 0, 48),
	Vector3.new(63, 0, 48),
}

function Config.getCharacter(name)
	for _, char in ipairs(Config.CHARACTERS) do
		if char.name == name then
			return char
		end
	end
	return nil
end

function Config.pickRarity()
	local total = 0
	for _, data in pairs(Config.RARITIES) do
		total += data.weight
	end
	local roll = math.random(total)
	local acc = 0
	for rarity, data in pairs(Config.RARITIES) do
		acc += data.weight
		if roll <= acc then
			return rarity
		end
	end
	return "Common"
end

function Config.pickMutation()
	local total = 0
	for _, mut in ipairs(Config.MUTATIONS) do
		total += mut.weight
	end
	local roll = math.random(total)
	local acc = 0
	for _, mut in ipairs(Config.MUTATIONS) do
		acc += mut.weight
		if roll <= acc then
			return mut
		end
	end
	return Config.MUTATIONS[1]
end

function Config.pickCharacter()
	local rarity = Config.pickRarity()
	local pool = {}
	for _, char in ipairs(Config.CHARACTERS) do
		if char.rarity == rarity then
			table.insert(pool, char)
		end
	end
	if #pool == 0 then
		return Config.CHARACTERS[1]
	end
	return pool[math.random(#pool)]
end

return Config
