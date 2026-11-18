-- init.server.luau
-- Noodle Brainrot Heist: the bootstrap. Wires every module together:
-- creates the RemoteEvents, hands out bases on join, pays income every
-- second, broadcasts HUD state to each client, and answers the client's
-- Interact / LockBase / Rebirth requests. All rules live in the modules;
-- this file only connects them.

local Config = require(script.Parent.Config)
local Economy = require(script.Parent.Economy)
local Bases = require(script.Parent.Bases)
local Spawner = require(script.Parent.Spawner)
local Carry = require(script.Parent.Carry)
local Events = require(script.Parent.Events)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

math.randomseed(os.time())

-- RemoteEvents, created here so the client can always find them.
local remotes = Instance.new("Folder")
remotes.Name = "BrainrotRemotes"
remotes.Parent = ReplicatedStorage

local InteractEvent = Instance.new("RemoteEvent")
InteractEvent.Name = "Interact"
InteractEvent.Parent = remotes

local LockEvent = Instance.new("RemoteEvent")
LockEvent.Name = "LockBase"
LockEvent.Parent = remotes

local RebirthEvent = Instance.new("RemoteEvent")
RebirthEvent.Name = "Rebirth"
RebirthEvent.Parent = remotes

local StateEvent = Instance.new("RemoteEvent")
StateEvent.Name = "StateUpdate"
StateEvent.Parent = remotes

local NotifyEvent = Instance.new("RemoteEvent")
NotifyEvent.Name = "Notify"
NotifyEvent.Parent = remotes

local function notify(player, message)
	NotifyEvent:FireClient(player, message)
end

-- Wire the modules' notify hooks to the real RemoteEvent.
Carry.Notify = notify
Events.Notify = notify
Economy.GetBaseIncome = function(player)
	return Bases.GetBaseIncome(player)
end

Bases.Init()
Spawner.Start()
Carry.Start()
Events.Start()

-- One leaderboard: top 5 players by cash.
local function buildLeaderboard()
	local rows = {}
	for _, player in ipairs(Players:GetPlayers()) do
		table.insert(rows, {
			Name = player.DisplayName,
			Cash = Economy.GetCash(player),
			Rebirths = Economy.GetRebirths(player),
		})
	end
	table.sort(rows, function(a, b)
		return a.Cash > b.Cash
	end)
	while #rows > 5 do
		table.remove(rows)
	end
	return rows
end

-- Context hint for the E key: what would one press do right now?
local function buildPrompt(player)
	if Carry.IsCarrying(player) then
		local base = Bases.GetBase(player)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if base and root and Bases.IsInsideBase(base, root.Position) then
			return "[E] Place your brainrot in your base"
		end
		return "[E] Place — run inside your own base!"
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return ""
	end
	local position = root.Position
	local baseAt = Bases.FindBaseAt(position)
	if baseAt then
		local owner = Bases.GetOwner(baseAt)
		if owner and owner ~= player then
			if Bases.IsLocked(baseAt) then
				return "This base is LOCKED — come back later"
			end
			return "[E] Steal a brainrot from " .. owner.DisplayName .. "'s base!"
		end
	end
	local walking, _ = Spawner.NearestWalking(position, 12)
	if walking then
		return "[E] Buy " .. walking.Def.Name .. " — $" .. tostring(walking.Def.Cost)
			.. " (" .. walking.Def.Rarity .. ", $" .. tostring(walking.Def.Income * walking.Mutation.Multiplier) .. "/s)"
	end
	return "Walk to the belt and press [E] to buy a brainrot!"
end

-- Push fresh HUD state to one player.
local function sendState(player)
	local base = Bases.GetBase(player)
	local state = {
		Cash = Economy.GetCash(player),
		Income = Economy.GetIncomePerSecond(player),
		Rebirths = Economy.GetRebirths(player),
		RebirthCost = Config.RebirthCost(Economy.GetRebirths(player)),
		Multiplier = Config.RebirthMultiplier(Economy.GetRebirths(player)),
		Carrying = nil,
		BaseContents = {},
		LockRemaining = 0,
		LockCooldown = 0,
		EventActive = nil,
		EventIn = Events.SecondsUntilNext(),
		Prompt = buildPrompt(player),
		Leaderboard = buildLeaderboard(),
	}
	local carried = Carry.GetCarried(player)
	if carried then
		state.Carrying = {
			Name = carried.Def.Name,
			Rarity = carried.Def.Rarity,
			Mutation = carried.Mutation.Name,
			Income = carried.Def.Income * carried.Mutation.Multiplier,
		}
	end
	if base then
		state.BaseContents = Bases.GetBaseContents(base)
		state.LockRemaining = Bases.GetLockRemaining(base)
		state.LockCooldown = Bases.GetCooldownRemaining(base)
	end
	if Events.Active then
		state.EventActive = {
			Name = Events.Active.Def.Name,
			Remaining = math.max(0, math.ceil(Events.Active.EndsAt - os.clock())),
		}
	end
	StateEvent:FireClient(player, state)
end

-- Player lifecycle.
local function onPlayerAdded(player)
	Economy.AddPlayer(player)
	local base = Bases.ClaimFor(player)
	if base then
		notify(player, "Welcome to Noodle Brainrot Heist! This is your base — go buy a brainrot!")
	else
		notify(player, "Welcome! All 8 bases are taken — spectate and wait for a spot!")
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local cashValue = Instance.new("IntValue")
	cashValue.Name = "Cash"
	cashValue.Value = Economy.GetCash(player)
	cashValue.Parent = leaderstats

	local rebirthValue = Instance.new("IntValue")
	rebirthValue.Name = "Rebirths"
	rebirthValue.Value = 0
	rebirthValue.Parent = leaderstats

	-- Keep the leaderboard values in sync with the economy.
	task.spawn(function()
		while player.Parent do
			task.wait(1)
			cashValue.Value = Economy.GetCash(player)
			rebirthValue.Value = Economy.GetRebirths(player)
			sendState(player)
		end
	end)
end

local function onPlayerRemoving(player)
	-- Drop whatever they were carrying, free the base, forget the money.
	Carry.DropCarried(player)
	Bases.Release(player)
	Economy.RemovePlayer(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- The economy heartbeat: pay everyone once a second.
task.spawn(function()
	while true do
		task.wait(1)
		Economy.Tick()
	end
end)

-- Client requests.
InteractEvent.OnServerEvent:Connect(function(player)
	local ok, message = Carry.Interact(player)
	notify(player, message)
	if ok then
		sendState(player)
	end
end)

LockEvent.OnServerEvent:Connect(function(player)
	local base = Bases.GetBase(player)
	if not base then
		notify(player, "You have no base to lock!")
		return
	end
	local ok, message = Bases.TryLock(base)
	notify(player, message)
	if ok then
		sendState(player)
	end
end)

RebirthEvent.OnServerEvent:Connect(function(player)
	local base = Bases.GetBase(player)
	local ok, message = Economy.TryRebirth(player)
	if not ok then
		notify(player, message)
		return
	end
	-- Wipe the base: every brainrot vanishes, the multiplier stays forever.
	if base then
		local removed = Bases.ClearBase(base)
		for _, record in ipairs(removed) do
			Spawner.Despawn(record)
		end
	end
	Carry.DropCarried(player)
	notify(player, message .. " Your base is empty — build it back, richer!")
	sendState(player)
end)

print("[Noodle Brainrot Heist] Server ready: 8 bases, 12 brainrots, belt running.")
