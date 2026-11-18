-- Config.luau
-- Noodle Brainrot Heist: the single source of truth for the whole game.
-- Every brainrot, rarity, price, mutation and tuning number lives here so
-- the economy, spawner, bases and client all agree on the same facts.
-- ALL characters, names and gags are original inventions for this game.

local Config = {}

-- How often a new brainrot walks out of the Noodle-O-Matic, in seconds.
Config.SPAWN_INTERVAL = 6
-- Most brainrots allowed walking on the belt at once.
Config.MAX_WALKING = 10
-- Belt speed in studs per second.
Config.WALK_SPEED = 4
-- Belt runs from west (spawn) to east (exit) along the X axis.
Config.BELT_START_X = -72
Config.BELT_END_X = 78
Config.BELT_Z = 0

-- Base lock: locked for this long, then a cooldown before it can lock again.
Config.LOCK_DURATION = 45
Config.LOCK_COOLDOWN = 60
-- Brainrot slots inside each base.
Config.SLOTS_PER_BASE = 6

-- Map event: one wave every EVENT_INTERVAL seconds, lasting EVENT_DURATION.
Config.EVENT_INTERVAL = 90
Config.EVENT_DURATION = 20
Config.EVENT_WARN_SECONDS = 10
-- During an event, a carrying player has this chance per tick to drop the brainrot.
Config.EVENT_DROP_CHANCE = 0.25
Config.EVENT_TICK = 5

-- Rebirth: cost grows with each rebirth, multiplier grows by this much.
Config.REBIRTH_BASE_COST = 10000
Config.REBIRTH_MULTIPLIER_STEP = 0.5
-- Starting cash for a fresh player.
Config.START_CASH = 100

-- Rarity tiers, in order. Weight controls how often the spawner picks the tier.
Config.RARITIES = {
	{ Name = "Common",    Color = Color3.fromRGB(150, 200, 120), Weight = 40 },
	{ Name = "Rare",      Color = Color3.fromRGB(80, 160, 255),  Weight = 25 },
	{ Name = "Epic",      Color = Color3.fromRGB(180, 90, 255),  Weight = 15 },
	{ Name = "Legendary", Color = Color3.fromRGB(255, 200, 40),  Weight = 10 },
	{ Name = "Mythic",    Color = Color3.fromRGB(255, 80, 140),  Weight = 7 },
	{ Name = "Secret",    Color = Color3.fromRGB(40, 40, 40),    Weight = 3 },
}

-- Mutations: rolled when a brainrot spawns. Chance is the roll weight out of 100.
Config.MUTATIONS = {
	{ Name = "Normal",  Multiplier = 1,  Chance = 88 },
	{ Name = "Golden",  Multiplier = 2,  Chance = 8 },
	{ Name = "Rainbow", Multiplier = 5,  Chance = 3 },
	{ Name = "Glitch",  Multiplier = 10, Chance = 1 },
}

-- The roster: 12 original brainrots, 2 per rarity tier.
-- Income is dollars per second once the brainrot sits in your base.
-- Cost is what you pay on the belt. BodyColor tints the model, Accessory
-- picks the silly hat/prop the builder bolts on top.
Config.BRAINROTS = {
	-- Common
	{
		Name = "Captain Sofa Spud",
		Rarity = "Common",
		Income = 1,
		Cost = 25,
		BodyColor = Color3.fromRGB(190, 150, 90),
		HeadColor = Color3.fromRGB(240, 220, 180),
		Accessory = "CaptainHat",
		Blurb = "A potato who became a sofa, then a captain. In that order.",
	},
	{
		Name = "Sir Wobbly Teacup",
		Rarity = "Common",
		Income = 2,
		Cost = 50,
		BodyColor = Color3.fromRGB(220, 230, 240),
		HeadColor = Color3.fromRGB(255, 255, 255),
		Accessory = "TopHat",
		Blurb = "Spills tea on everyone. Knighted anyway.",
	},
	-- Rare
	{
		Name = "DJ Sour Pickle",
		Rarity = "Rare",
		Income = 5,
		Cost = 150,
		BodyColor = Color3.fromRGB(90, 180, 60),
		HeadColor = Color3.fromRGB(140, 220, 90),
		Accessory = "Headphones",
		Blurb = "Drops beats. Drops brine. Never drops the aux cord.",
	},
	{
		Name = "Madam Moon Pie",
		Rarity = "Rare",
		Income = 8,
		Cost = 250,
		BodyColor = Color3.fromRGB(230, 210, 160),
		HeadColor = Color3.fromRGB(250, 240, 210),
		Accessory = "Crown",
		Blurb = "Ruler of the midnight snack drawer.",
	},
	-- Epic
	{
		Name = "Jazz Macaroni Fish",
		Rarity = "Epic",
		Income = 15,
		Cost = 500,
		BodyColor = Color3.fromRGB(255, 170, 60),
		HeadColor = Color3.fromRGB(255, 210, 120),
		Accessory = "Saxophone",
		Blurb = "Swims in cheese sauce. Plays only in 7/8 time.",
	},
	{
		Name = "Grandma's Flying Slipper",
		Rarity = "Epic",
		Income = 20,
		Cost = 750,
		BodyColor = Color3.fromRGB(200, 120, 180),
		HeadColor = Color3.fromRGB(230, 170, 210),
		Accessory = "Wings",
		Blurb = "It knows what you did. It flies now. Run.",
	},
	-- Legendary
	{
		Name = "Professor Noodle Wizard",
		Rarity = "Legendary",
		Income = 40,
		Cost = 1500,
		BodyColor = Color3.fromRGB(240, 200, 90),
		HeadColor = Color3.fromRGB(255, 230, 150),
		Accessory = "WizardHat",
		Blurb = "Turned his own homework into spaghetti. Tenured.",
	},
	{
		Name = "Turbo Toilet Racer",
		Rarity = "Legendary",
		Income = 60,
		Cost = 2500,
		BodyColor = Color3.fromRGB(120, 200, 255),
		HeadColor = Color3.fromRGB(200, 230, 255),
		Accessory = "Helmet",
		Blurb = "0 to flush in 2.1 seconds. Do not ask about the track.",
	},
	-- Mythic
	{
		Name = "The Infinite Dumpling",
		Rarity = "Mythic",
		Income = 120,
		Cost = 6000,
		BodyColor = Color3.fromRGB(255, 220, 190),
		HeadColor = Color3.fromRGB(255, 240, 220),
		Accessory = "Halo",
		Blurb = "Every bite reveals another, smaller dumpling inside.",
	},
	{
		Name = "Chairman Croissant",
		Rarity = "Mythic",
		Income = 180,
		Cost = 9000,
		BodyColor = Color3.fromRGB(220, 160, 80),
		HeadColor = Color3.fromRGB(245, 200, 120),
		Accessory = "Suit",
		Blurb = "Flaky on the outside. Iron-fisted on the inside.",
	},
	-- Secret
	{
		Name = "Sir Bananaphone the Third",
		Rarity = "Secret",
		Income = 500,
		Cost = 25000,
		BodyColor = Color3.fromRGB(255, 230, 60),
		HeadColor = Color3.fromRGB(255, 245, 140),
		Accessory = "Crown",
		Blurb = "Answers every call. Nobody knows who is calling.",
	},
	{
		Name = "The Forbidden Left Sock",
		Rarity = "Secret",
		Income = 800,
		Cost = 40000,
		BodyColor = Color3.fromRGB(120, 120, 200),
		HeadColor = Color3.fromRGB(170, 170, 230),
		Accessory = "Halo",
		Blurb = "It was never lost. It was waiting. It chose you.",
	},
}

-- Map events. Each one slows players caught outside and can knock a
-- carried brainrot clean out of their hands.
Config.EVENTS = {
	{
		Name = "Noodle Tsunami",
		Blurb = "A wave of spaghetti is rolling across the map! Get inside!",
	},
	{
		Name = "Giggle Storm",
		Blurb = "A storm of uncontrollable giggles! You can barely walk straight!",
	},
}

-- Base plot colours, one per base slot (8 bases).
Config.BASE_COLORS = {
	Color3.fromRGB(255, 120, 120),
	Color3.fromRGB(120, 180, 255),
	Color3.fromRGB(120, 220, 140),
	Color3.fromRGB(255, 210, 90),
	Color3.fromRGB(200, 140, 255),
	Color3.fromRGB(255, 160, 90),
	Color3.fromRGB(90, 220, 210),
	Color3.fromRGB(255, 130, 200),
}

-- Look up a rarity tier table by name.
function Config.GetRarity(name)
	for _, tier in ipairs(Config.RARITIES) do
		if tier.Name == name then
			return tier
		end
	end
	return Config.RARITIES[1]
end

-- Pick a rarity tier by weight.
function Config.RollRarity()
	local total = 0
	for _, tier in ipairs(Config.RARITIES) do
		total += tier.Weight
	end
	local roll = math.random(1, total)
	local running = 0
	for _, tier in ipairs(Config.RARITIES) do
		running += tier.Weight
		if roll <= running then
			return tier.Name
		end
	end
	return "Common"
end

-- Pick a mutation by chance.
function Config.RollMutation()
	local roll = math.random(1, 100)
	local running = 0
	for _, mutation in ipairs(Config.MUTATIONS) do
		running += mutation.Chance
		if roll <= running then
			return mutation
		end
	end
	return Config.MUTATIONS[1]
end

-- Pick a random brainrot of the given rarity.
function Config.PickBrainrot(rarityName)
	local pool = {}
	for _, entry in ipairs(Config.BRAINROTS) do
		if entry.Rarity == rarityName then
			table.insert(pool, entry)
		end
	end
	if #pool == 0 then
		return Config.BRAINROTS[1]
	end
	return pool[math.random(1, #pool)]
end

-- Rebirth price for a player who has already rebirthed this many times.
function Config.RebirthCost(rebirths)
	return Config.REBIRTH_BASE_COST * (rebirths + 1) * (rebirths + 1)
end

-- Total income multiplier from rebirths.
function Config.RebirthMultiplier(rebirths)
	return 1 + rebirths * Config.REBIRTH_MULTIPLIER_STEP
end

return Config
