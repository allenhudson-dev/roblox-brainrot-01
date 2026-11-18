-- Bases.luau
-- Owns the 8 base plots: who owns which plot, which slots hold which
-- brainrot, and the lock (door shut for LOCK_DURATION, then a cooldown).
-- The plots themselves are built in default.project.json under
-- Workspace.Bases.Base1..Base8; this module finds them by name.

local Config = require(script.Parent.Config)

local Bases = {}

-- player -> base folder (Workspace.Bases.BaseN)
local ownerToBase = {}
-- base folder -> player (or nil while unclaimed)
local baseToOwner = {}
-- base folder -> { LockedUntil, CooldownUntil }
local lockState = {}
-- base folder -> array of slot records { Brainrot = <record or nil>, Pad = <Part> }
local slots = {}

local Workspace = game:GetService("Workspace")

-- A brainrot record is the table Spawner/Carry pass around:
-- { Id, Def, Mutation, Model, State, Owner, SlotIndex, Base }

function Bases.Init()
	local basesFolder = Workspace:WaitForChild("Bases")
	for i = 1, 8 do
		local base = basesFolder:FindFirstChild("Base" .. tostring(i))
		if base then
			baseToOwner[base] = nil
			lockState[base] = { LockedUntil = 0, CooldownUntil = 0 }
			local baseSlots = {}
			local pads = base:FindFirstChild("Slots")
			for slotIndex = 1, Config.SLOTS_PER_BASE do
				local pad = nil
				if pads then
					pad = pads:FindFirstChild("Slot" .. tostring(slotIndex))
				end
				baseSlots[slotIndex] = { Brainrot = nil, Pad = pad }
			end
			slots[base] = baseSlots
		end
	end
end

-- Give a joining player the first free base. Returns the base folder or nil.
function Bases.ClaimFor(player)
	for base, owner in pairs(baseToOwner) do
		if owner == nil then
			baseToOwner[base] = player
			ownerToBase[player] = base
			local sign = base:FindFirstChild("OwnerSign")
			if sign then
				local label = sign:FindFirstChildWhichIsA("SurfaceGui")
				if label then
					local text = label:FindFirstChildWhichIsA("TextLabel")
					if text then
						text.Text = player.DisplayName .. "'s Base"
					end
				end
			end
			return base
		end
	end
	return nil
end

function Bases.Release(player)
	local base = ownerToBase[player]
	if base then
		baseToOwner[base] = nil
		ownerToBase[player] = nil
		Bases.ClearBase(base)
		lockState[base] = { LockedUntil = 0, CooldownUntil = 0 }
	end
end

function Bases.GetBase(player)
	return ownerToBase[player]
end

function Bases.GetOwner(base)
	return baseToOwner[base]
end

-- First free slot index in a base, or nil when the base is full.
function Bases.FindFreeSlot(base)
	local baseSlots = slots[base]
	if not baseSlots then
		return nil
	end
	for index, slot in ipairs(baseSlots) do
		if slot.Brainrot == nil then
			return index
		end
	end
	return nil
end

-- Put a brainrot record into a slot. Returns true on success.
function Bases.PlaceInSlot(base, slotIndex, record)
	local baseSlots = slots[base]
	if not baseSlots then
		return false
	end
	local slot = baseSlots[slotIndex]
	if not slot or slot.Brainrot ~= nil then
		return false
	end
	slot.Brainrot = record
	record.Base = base
	record.SlotIndex = slotIndex
	record.State = "based"
	if slot.Pad and record.Model then
		local padTop = slot.Pad.Position + Vector3.new(0, slot.Pad.Size.Y / 2, 0)
		local root = record.Model.PrimaryPart
		if root then
			local height = root.Size.Y / 2
			record.Model:PivotTo(CFrame.new(padTop + Vector3.new(0, height + 0.5, 0)))
		end
	end
	return true
end

-- Take a brainrot out of its slot (steal or rebirth wipe). Returns the record.
function Bases.RemoveFromSlot(base, slotIndex)
	local baseSlots = slots[base]
	if not baseSlots then
		return nil
	end
	local slot = baseSlots[slotIndex]
	if not slot then
		return nil
	end
	local record = slot.Brainrot
	slot.Brainrot = nil
	if record then
		record.Base = nil
		record.SlotIndex = nil
	end
	return record
end

-- Remove every brainrot from a base (rebirth). Returns the removed records.
function Bases.ClearBase(base)
	local removed = {}
	local baseSlots = slots[base]
	if not baseSlots then
		return removed
	end
	for index, slot in ipairs(baseSlots) do
		if slot.Brainrot ~= nil then
			table.insert(removed, Bases.RemoveFromSlot(base, index))
		end
	end
	return removed
end

-- Snapshot of a base for the HUD: one entry per slot.
function Bases.GetBaseContents(base)
	local out = {}
	local baseSlots = slots[base]
	if not baseSlots then
		return out
	end
	for index, slot in ipairs(baseSlots) do
		if slot.Brainrot ~= nil then
			local record = slot.Brainrot
			table.insert(out, {
				Slot = index,
				Name = record.Def.Name,
				Rarity = record.Def.Rarity,
				Mutation = record.Mutation.Name,
				Income = record.Def.Income * record.Mutation.Multiplier,
			})
		end
	end
	return out
end

-- Total raw $/s of the brainrots in a player's base (no multipliers).
function Bases.GetBaseIncome(player)
	local base = ownerToBase[player]
	if not base then
		return 0
	end
	local total = 0
	local baseSlots = slots[base]
	if baseSlots then
		for _, slot in ipairs(baseSlots) do
			if slot.Brainrot ~= nil then
				local record = slot.Brainrot
				total += record.Def.Income * record.Mutation.Multiplier
			end
		end
	end
	return total
end

-- Is this base's door locked right now?
function Bases.IsLocked(base)
	local state = lockState[base]
	if not state then
		return false
	end
	return os.clock() < state.LockedUntil
end

function Bases.GetLockRemaining(base)
	local state = lockState[base]
	if not state then
		return 0
	end
	return math.max(0, state.LockedUntil - os.clock())
end

function Bases.GetCooldownRemaining(base)
	local state = lockState[base]
	if not state then
		return 0
	end
	return math.max(0, state.CooldownUntil - os.clock())
end

-- Try to lock a base. Returns true, or false plus a reason string.
function Bases.TryLock(base)
	local state = lockState[base]
	if not state then
		return false, "No such base"
	end
	local now = os.clock()
	if now < state.LockedUntil then
		return false, "Base is already locked"
	end
	if now < state.CooldownUntil then
		return false, "Lock is cooling down (" .. tostring(math.ceil(state.CooldownUntil - now)) .. "s)"
	end
	state.LockedUntil = now + Config.LOCK_DURATION
	state.CooldownUntil = state.LockedUntil + Config.LOCK_COOLDOWN
	Bases.ApplyDoor(base, true)
	task.delay(Config.LOCK_DURATION, function()
		Bases.ApplyDoor(base, false)
	end)
	return true, "Base locked for " .. tostring(Config.LOCK_DURATION) .. "s!"
end

-- Show or hide the door: locked = solid red door, unlocked = open (faded, walk-through).
function Bases.ApplyDoor(base, locked)
	local door = base:FindFirstChild("Door")
	if not door then
		return
	end
	if locked then
		door.CanCollide = true
		door.Transparency = 0
		door.Color = Color3.fromRGB(200, 40, 40)
	else
		door.CanCollide = false
		door.Transparency = 0.75
		door.Color = Color3.fromRGB(120, 200, 120)
	end
end

-- Is a world position inside this base's floor rectangle?
function Bases.IsInsideBase(base, position)
	local floor = base:FindFirstChild("Floor")
	if not floor then
		return false
	end
	local halfX = floor.Size.X / 2
	local halfZ = floor.Size.Z / 2
	return math.abs(position.X - floor.Position.X) <= halfX
		and math.abs(position.Z - floor.Position.Z) <= halfZ
end

-- Is a world position inside ANY base? Returns that base, or nil.
function Bases.FindBaseAt(position)
	for base, _ in pairs(baseToOwner) do
		if Bases.IsInsideBase(base, position) then
			return base
		end
	end
	return nil
end

return Bases
