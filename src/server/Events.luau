-- Events.luau
-- The map-event show: every EVENT_INTERVAL seconds a wave sweeps the map.
-- A 10-second warning goes out first, then the event runs for
-- EVENT_DURATION seconds. Anyone caught outside their own base walks slow,
-- and anyone carrying a brainrot risks dropping it mid-stride.
-- The two events are announced to every player through the Notify callback
-- the bootstrap wires up.

local Config = require(script.Parent.Config)
local Bases = require(script.Parent.Bases)
local Carry = require(script.Parent.Carry)

local Events = {}

local Players = game:GetService("Players")

Events.Notify = nil
-- Called once per event tick by the bootstrap so other modules can react;
-- kept here so the event owns its own timer state.
Events.Active = nil -- { Def, EndsAt } while an event is running
Events.NextAt = os.clock() + Config.EVENT_INTERVAL

local function notifyAll(message)
	if Events.Notify then
		for _, player in ipairs(Players:GetPlayers()) do
			Events.Notify(player, message)
		end
	end
end

-- Slow every player who is standing outside their own base.
local function applySlow()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local base = Bases.GetBase(player)
			local root = character:FindFirstChild("HumanoidRootPart")
			local insideOwn = false
			if base and root then
				insideOwn = Bases.IsInsideBase(base, root.Position)
			end
			if insideOwn then
				humanoid.WalkSpeed = 16
			else
				humanoid.WalkSpeed = 8
			end
		end
	end
end

local function restoreSpeed()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 16
		end
	end
end

-- One drop-risk tick: each carrier rolls the dice.
local function dropTick()
	for _, player in ipairs(Players:GetPlayers()) do
		if Carry.IsCarrying(player) then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local base = Bases.GetBase(player)
			local insideOwn = false
			if base and root then
				insideOwn = Bases.IsInsideBase(base, root.Position)
			end
			if not insideOwn and math.random() < Config.EVENT_DROP_CHANCE then
				local dropped = Carry.DropCarried(player)
				if dropped and Events.Notify then
					Events.Notify(player, "The storm knocked " .. dropped.Def.Name .. " out of your hands!")
				end
			end
		end
	end
end

-- Run one full event: warn, rage for EVENT_DURATION, then clean up.
function Events.RunOnce()
	local def = Config.EVENTS[math.random(1, #Config.EVENTS)]
	notifyAll("WARNING: " .. def.Name .. " in " .. tostring(Config.EVENT_WARN_SECONDS) .. "s! " .. def.Blurb)
	task.wait(Config.EVENT_WARN_SECONDS)
	Events.Active = { Def = def, EndsAt = os.clock() + Config.EVENT_DURATION }
	notifyAll(def.Name .. " IS HERE! Get inside your base!")
	local endsAt = Events.Active.EndsAt
	while os.clock() < endsAt do
		applySlow()
		dropTick()
		task.wait(Config.EVENT_TICK)
	end
	Events.Active = nil
	restoreSpeed()
	notifyAll("The " .. def.Name .. " has passed. Back to business!")
	Events.NextAt = os.clock() + Config.EVENT_INTERVAL
end

function Events.Start()
	task.spawn(function()
		while true do
			local waitFor = Events.NextAt - os.clock()
			if waitFor > 0 then
				task.wait(waitFor)
			end
			Events.RunOnce()
		end
	end)
end

-- Seconds until the next event starts (0 while one is running).
function Events.SecondsUntilNext()
	if Events.Active then
		return 0
	end
	return math.max(0, math.ceil(Events.NextAt - os.clock()))
end

return Events
