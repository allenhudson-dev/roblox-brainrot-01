-- Spawner.luau
-- Runs the Noodle-O-Matic: every SPAWN_INTERVAL seconds a fresh original
-- brainrot walks out of the machine and strolls east along the belt.
-- Each brainrot is a Model built here from plain Parts (no meshes, no
-- downloaded assets), with a BillboardGui price tag floating over it.

local Config = require(script.Parent.Config)

local Spawner = {}

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- id counter for brainrot records.
local nextId = 1
-- Walking brainrots: array of records { Id, Def, Mutation, Model, State }
local walking = {}
-- Every live brainrot record by id, whatever its state.
local byId = {}

-- Size of the body part by rarity tier (Secret brainrots loom large).
local RARITY_SIZE = {
	Common = 2.2,
	Rare = 2.6,
	Epic = 3.0,
	Legendary = 3.4,
	Mythic = 3.8,
	Secret = 4.4,
}

-- Mutation tint applied to the body: Golden shines, Rainbow cycles,
-- Glitch flickers dark purple, Normal keeps the character's own colour.
local function mutationColor(mutation, baseColor)
	if mutation.Name == "Golden" then
		return Color3.fromRGB(255, 215, 0)
	elseif mutation.Name == "Rainbow" then
		return Color3.fromRGB(255, 90, 200)
	elseif mutation.Name == "Glitch" then
		return Color3.fromRGB(90, 40, 160)
	end
	return baseColor
end

local function makePart(name, size, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	return part
end

-- Bolt a silly accessory on top of the head, by name.
local function addAccessory(model, kind, headTopY, headSize)
	if kind == "CaptainHat" then
		local hat = makePart("Hat", Vector3.new(2.4, 0.5, 2.4), Color3.fromRGB(255, 255, 255))
		hat.Position = Vector3.new(0, headTopY + 0.25, 0)
		hat.Parent = model
		local brim = makePart("Brim", Vector3.new(3.2, 0.2, 3.2), Color3.fromRGB(40, 60, 120))
		brim.Position = Vector3.new(0, headTopY, 0)
		brim.Parent = model
	elseif kind == "TopHat" then
		local hat = makePart("Hat", Vector3.new(1.6, 2.0, 1.6), Color3.fromRGB(30, 30, 30))
		hat.Position = Vector3.new(0, headTopY + 1.0, 0)
		hat.Parent = model
		local brim = makePart("Brim", Vector3.new(3.0, 0.2, 3.0), Color3.fromRGB(30, 30, 30))
		brim.Position = Vector3.new(0, headTopY, 0)
		brim.Parent = model
	elseif kind == "Headphones" then
		local band = makePart("Band", Vector3.new(0.4, 1.6, 2.6), Color3.fromRGB(220, 40, 60))
		band.Position = Vector3.new(0, headTopY + 0.4, 0)
		band.Parent = model
		for _, side in ipairs({ -1, 1 }) do
			local cup = makePart("Cup", Vector3.new(0.6, 1.2, 1.2), Color3.fromRGB(220, 40, 60))
			cup.Position = Vector3.new(side * (headSize.X / 2 + 0.2), headTopY - 0.2, 0)
			cup.Parent = model
		end
	elseif kind == "Crown" then
		local crown = makePart("Crown", Vector3.new(2.2, 0.8, 2.2), Color3.fromRGB(255, 215, 0), Enum.Material.Metal)
		crown.Position = Vector3.new(0, headTopY + 0.4, 0)
		crown.Parent = model
	elseif kind == "Saxophone" then
		local sax = makePart("Sax", Vector3.new(0.7, 2.6, 0.7), Color3.fromRGB(255, 215, 0), Enum.Material.Metal)
		sax.Position = Vector3.new(headSize.X / 2 + 0.4, headTopY - 1.2, 0.6)
		sax.Rotation = Vector3.new(0, 0, -25)
		sax.Parent = model
	elseif kind == "Wings" then
		for _, side in ipairs({ -1, 1 }) do
			local wing = makePart("Wing", Vector3.new(0.3, 1.6, 2.2), Color3.fromRGB(255, 255, 255))
			wing.Position = Vector3.new(side * 1.6, headTopY - 1.6, 0)
			wing.Rotation = Vector3.new(0, 0, side * 30)
			wing.Parent = model
		end
	elseif kind == "WizardHat" then
		local cone = makePart("Cone", Vector3.new(2.0, 2.6, 2.0), Color3.fromRGB(90, 40, 160))
		cone.Position = Vector3.new(0, headTopY + 1.3, 0)
		cone.Parent = model
	elseif kind == "Helmet" then
		local helmet = makePart("Helmet", Vector3.new(2.6, 1.0, 2.6), Color3.fromRGB(220, 230, 240), Enum.Material.Metal)
		helmet.Position = Vector3.new(0, headTopY + 0.3, 0)
		helmet.Parent = model
	elseif kind == "Halo" then
		local halo = makePart("Halo", Vector3.new(2.6, 0.3, 2.6), Color3.fromRGB(255, 240, 150), Enum.Material.Neon)
		halo.Position = Vector3.new(0, headTopY + 0.9, 0)
		halo.Parent = model
	elseif kind == "Suit" then
		local tie = makePart("Tie", Vector3.new(0.5, 1.6, 0.3), Color3.fromRGB(180, 30, 30))
		tie.Position = Vector3.new(0, headTopY - 2.4, 1.2)
		tie.Parent = model
	end
end

-- Build the visible Model for one brainrot record. All Parts, no assets.
function Spawner.BuildModel(record)
	local def = record.Def
	local size = RARITY_SIZE[def.Rarity] or 2.2
	local bodyColor = mutationColor(record.Mutation, def.BodyColor)

	local model = Instance.new("Model")
	model.Name = def.Name

	local body = makePart("Body", Vector3.new(size, size, size), bodyColor)
	body.Shape = Enum.PartType.Ball
	body.Position = Vector3.new(0, size / 2 + 1, 0)
	body.Parent = model
	model.PrimaryPart = body

	local headSize = Vector3.new(size * 0.7, size * 0.7, size * 0.7)
	local head = makePart("Head", headSize, def.HeadColor)
	head.Shape = Enum.PartType.Ball
	head.Position = Vector3.new(0, size + 1 + headSize.Y / 2, 0)
	head.Parent = model

	-- Two googly eyes on the head.
	for _, side in ipairs({ -1, 1 }) do
		local eye = makePart("Eye", Vector3.new(0.35, 0.5, 0.2), Color3.fromRGB(20, 20, 20))
		eye.Position = Vector3.new(side * headSize.X * 0.22, head.Position.Y + 0.1, headSize.Z / 2)
		eye.Parent = model
	end

	addAccessory(model, def.Accessory, head.Position.Y + headSize.Y / 2, headSize)

	-- Floating name + price tag.
	local tag = Instance.new("BillboardGui")
	tag.Name = "Tag"
	tag.Size = UDim2.fromOffset(220, 64)
	tag.StudsOffset = Vector3.new(0, size + 3.5, 0)
	tag.AlwaysOnTop = true
	tag.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = record.Mutation.Name .. " " .. def.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Parent = tag

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "PriceLabel"
	priceLabel.Position = UDim2.new(0, 0, 0.5, 0)
	priceLabel.Size = UDim2.new(1, 0, 0.5, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = "$" .. tostring(def.Cost) .. "  |  $" .. tostring(def.Income * record.Mutation.Multiplier) .. "/s  |  " .. def.Rarity
	priceLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
	priceLabel.TextScaled = true
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.TextStrokeTransparency = 0
	priceLabel.Parent = tag

	model.Parent = Workspace
	return model
end

-- Roll a brand-new brainrot and set it walking on the belt.
function Spawner.SpawnOne()
	if #walking >= Config.MAX_WALKING then
		return nil
	end
	local rarity = Config.RollRarity()
	local def = Config.PickBrainrot(rarity)
	local mutation = Config.RollMutation()
	local id = nextId
	nextId += 1

	local record = {
		Id = id,
		Def = def,
		Mutation = mutation,
		Model = nil,
		State = "walking",
		Owner = nil,
		Holder = nil,
		Base = nil,
		SlotIndex = nil,
	}
	record.Model = Spawner.BuildModel(record)
	-- Rest the body on top of the belt (belt top is y = 1): body centre sits
	-- one radius above it, so the brainrot strolls on the belt, not in it.
	local size = RARITY_SIZE[def.Rarity] or 2.2
	record.Model:PivotTo(CFrame.new(Config.BELT_START_X, 1 + size / 2 + 0.1, Config.BELT_Z))
	byId[id] = record
	table.insert(walking, record)
	return record
end

-- Remove a brainrot from the world entirely (walked off, dropped, wiped).
function Spawner.Despawn(record)
	if not record then
		return
	end
	byId[record.Id] = nil
	for i, item in ipairs(walking) do
		if item == record then
			table.remove(walking, i)
			break
		end
	end
	if record.Model then
		record.Model:Destroy()
		record.Model = nil
	end
end

function Spawner.RemoveFromWalking(record)
	for i, item in ipairs(walking) do
		if item == record then
			table.remove(walking, i)
			return
		end
	end
end

function Spawner.GetById(id)
	return byId[id]
end

function Spawner.GetWalking()
	return walking
end

-- Every live brainrot record, whatever its state (walking, carried, based).
function Spawner.GetAllRecords()
	local out = {}
	for _, record in pairs(byId) do
		table.insert(out, record)
	end
	return out
end

-- Nearest walking brainrot to a position, within maxDistance studs.
function Spawner.NearestWalking(position, maxDistance)
	local best = nil
	local bestDist = maxDistance
	for _, record in ipairs(walking) do
		if record.Model and record.Model.PrimaryPart then
			local dist = (record.Model.PrimaryPart.Position - position).Magnitude
			if dist < bestDist then
				bestDist = dist
				best = record
			end
		end
	end
	return best, bestDist
end

-- Move every walking brainrot one step east; despawn any that reach the end.
local function stepWalking(dt)
	local i = 1
	while i <= #walking do
		local record = walking[i]
		local model = record.Model
		if not model or not model.PrimaryPart then
			table.remove(walking, i)
		else
			local pivot = model:GetPivot()
			local nextX = pivot.Position.X + Config.WALK_SPEED * dt
			if nextX >= Config.BELT_END_X then
				Spawner.Despawn(record)
			else
				model:PivotTo(CFrame.new(nextX, pivot.Position.Y, Config.BELT_Z))
				i += 1
			end
		end
	end
end

function Spawner.Start()
	task.spawn(function()
		while true do
			task.wait(Config.SPAWN_INTERVAL)
			Spawner.SpawnOne()
		end
	end)
	RunService.Heartbeat:Connect(stepWalking)
end

return Spawner
