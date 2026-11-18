-- Carry.luau
-- The hands of the game: buying a brainrot off the belt, carrying it home,
-- placing it in your base, and stealing one out of somebody else's base.
-- Every action is validated here on the server; the client only ever asks.
-- One E press does the right thing by context: place if carrying, steal if
-- standing by a rival's brainrot, buy if standing by a walking one.

local Economy = require(script.Parent.Economy)
local Bases = require(script.Parent.Bases)
local Spawner = require(script.Parent.Spawner)

local Carry = {}

local RunService = game:GetService("RunService")

-- player -> record they are currently carrying (or nil).
local carrying = {}

-- How close a player must be to interact, in studs.
local INTERACT_RANGE = 12

function Carry.GetCarried(player)
	return carrying[player]
end

function Carry.IsCarrying(player)
	return carrying[player] ~= nil
end

-- The brainrot floats just in front of its carrier, bobbing gently.
local function followCarrier(dt)
	for player, record in pairs(carrying) do
		if not record.Model then
			carrying[player] = nil
		else
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if not root then
				-- Carrier left or died: the brainrot is lost.
				Spawner.Despawn(record)
				carrying[player] = nil
			else
				local bob = math.sin(os.clock() * 3) * 0.4
				local target = root.CFrame * CFrame.new(0, 3 + bob, -3.5)
				record.Model:PivotTo(target)
			end
		end
	end
end

function Carry.Start()
	RunService.Heartbeat:Connect(followCarrier)
end

function Carry.DropCarried(player)
	local record = carrying[player]
	if record then
		carrying[player] = nil
		Spawner.Despawn(record)
		return record
	end
	return nil
end

-- Buy the walking brainrot: pay, then carry it. Returns true, or false + reason.
function Carry.TryBuy(player, record)
	if carrying[player] then
		return false, "Your hands are full! Place your brainrot first."
	end
	if not record or record.State ~= "walking" then
		return false, "That brainrot is gone."
	end
	if not Economy.TrySpend(player, record.Def.Cost) then
		return false, "Not enough cash! Need $" .. tostring(record.Def.Cost) .. "."
	end
	Spawner.RemoveFromWalking(record)
	record.State = "carried"
	record.Holder = player
	carrying[player] = record
	return true, "Bought " .. record.Def.Name .. "! Carry it home!"
end

-- Place the carried brainrot into a free slot of the player's own base.
function Carry.TryPlace(player)
	local record = carrying[player]
	if not record then
		return false, "You are not carrying anything."
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false, "No character."
	end
	local base = Bases.GetBase(player)
	if not base then
		return false, "You have no base yet."
	end
	if not Bases.IsInsideBase(base, root.Position) then
		return false, "Go inside your own base to place it!"
	end
	local slotIndex = Bases.FindFreeSlot(base)
	if not slotIndex then
		return false, "Your base is full! Rebirth or make room."
	end
	carrying[player] = nil
	record.Holder = nil
	if Bases.PlaceInSlot(base, slotIndex, record) then
		return true, record.Def.Name .. " moved in! +$" .. tostring(record.Def.Income * record.Mutation.Multiplier) .. "/s"
	end
	return false, "Could not place it."
end

-- Steal a brainrot out of a rival's unlocked base.
function Carry.TrySteal(player, record)
	if carrying[player] then
		return false, "Your hands are full! Place your brainrot first."
	end
	if not record or record.State ~= "based" then
		return false, "Nothing to steal there."
	end
	local base = record.Base
	if not base then
		return false, "That brainrot has no base."
	end
	local owner = Bases.GetOwner(base)
	if owner == player then
		return false, "That one is already yours!"
	end
	if Bases.IsLocked(base) then
		return false, "That base is LOCKED! Come back later."
	end
	Bases.RemoveFromSlot(base, record.SlotIndex)
	record.State = "carried"
	record.Holder = player
	carrying[player] = record
	if owner and Carry.Notify then
		Carry.Notify(owner, "THIEF! " .. player.DisplayName .. " stole your " .. record.Def.Name .. "!")
	end
	return true, "STOLEN! Run it back to your base before they catch you!"
end

-- The one E-press entry point. Figures out what the player means by context.
-- Returns true + message, or false + reason. Notify callback is wired by init.
Carry.Notify = nil

function Carry.Interact(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false, "Wait for your character to load."
	end
	local position = root.Position

	-- 1. Carrying something: try to place it in your own base.
	if carrying[player] then
		return Carry.TryPlace(player)
	end

	-- 2. Standing by a brainrot in a base: try to steal it (or admire your own).
	local baseAt = Bases.FindBaseAt(position)
	if baseAt then
		local owner = Bases.GetOwner(baseAt)
		if owner ~= player then
			-- Find the closest based brainrot in that base.
			local best = nil
			local bestDist = INTERACT_RANGE
			for _, contents in ipairs(Bases.GetBaseContents(baseAt)) do
				-- Contents are snapshots; find the live record by slot.
				local record = Carry.FindBasedRecord(baseAt, contents.Slot)
				if record and record.Model and record.Model.PrimaryPart then
					local dist = (record.Model.PrimaryPart.Position - position).Magnitude
					if dist < bestDist then
						bestDist = dist
						best = record
					end
				end
			end
			if best then
				return Carry.TrySteal(player, best)
			end
		end
	end

	-- 3. Standing by a walking brainrot on the belt: buy it.
	local walking, _ = Spawner.NearestWalking(position, INTERACT_RANGE)
	if walking then
		return Carry.TryBuy(player, walking)
	end

	return false, "Nothing to grab here. Walk up to a brainrot on the belt!"
end

-- Live record lookup for a slot (Bases stores records; this reads them back
-- through the contents snapshot's slot index via the module's own table).
-- Bases does not expose raw records, so Carry keeps a parallel lookup built
-- from the spawner registry: a based record is any registry record whose
-- State is "based" and whose Base/SlotIndex match.
function Carry.FindBasedRecord(base, slotIndex)
	for _, record in ipairs(Spawner.GetAllRecords()) do
		if record.State == "based" and record.Base == base and record.SlotIndex == slotIndex then
			return record
		end
	end
	return nil
end

return Carry
