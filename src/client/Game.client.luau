-- Game.client.luau
-- Noodle Brainrot Heist: the whole client HUD, built in code.
-- Top-centre cash, top-right Lock/Rebirth buttons, right-side base roster,
-- bottom-centre action prompt, bottom-right leaderboard, and a notification
-- feed. Everything sits clear of the top-left Roblox menu button.
-- Keys are bound with ContextActionService (E interact, Q lock, R rebirth).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")
local InteractEvent = remotes:WaitForChild("Interact")
local LockEvent = remotes:WaitForChild("LockBase")
local RebirthEvent = remotes:WaitForChild("Rebirth")
local StateEvent = remotes:WaitForChild("StateUpdate")
local NotifyEvent = remotes:WaitForChild("Notify")

local RARITY_COLORS = {
	Common = Color3.fromRGB(150, 200, 120),
	Rare = Color3.fromRGB(80, 160, 255),
	Epic = Color3.fromRGB(180, 90, 255),
	Legendary = Color3.fromRGB(255, 200, 40),
	Mythic = Color3.fromRGB(255, 80, 140),
	Secret = Color3.fromRGB(255, 90, 200),
}

local function money(n)
	local s = tostring(math.floor(n))
	local out = ""
	while #s > 3 do
		out = "," .. string.sub(s, -3) .. out
		s = string.sub(s, 1, -4)
	end
	return "$" .. s .. out
end

-- Root GUI.
local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local function makeLabel(parent, name, text, size, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextSize = size
	label.TextColor3 = color
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0.5
	label.Parent = parent
	return label
end

local function makePanel(parent, name, position, size)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = position
	frame.Size = size
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	frame.BackgroundTransparency = 0.25
	frame.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame
	frame.Parent = parent
	return frame
end

-- Top-centre: cash + income.
local cashPanel = makePanel(gui, "CashPanel", UDim2.new(0.5, 0, 0, 12), UDim2.fromOffset(360, 84))
local cashLabel = makeLabel(cashPanel, "Cash", "$100", 34, Color3.fromRGB(255, 220, 80))
cashLabel.Size = UDim2.new(1, 0, 0.6, 0)
cashLabel.TextScaled = true
local incomeLabel = makeLabel(cashPanel, "Income", "+$0/s  |  x1.0", 20, Color3.fromRGB(140, 255, 140))
incomeLabel.Position = UDim2.new(0, 0, 0.6, 0)
incomeLabel.Size = UDim2.new(1, 0, 0.4, 0)

-- Event banner, just under the cash panel.
local eventPanel = makePanel(gui, "EventPanel", UDim2.new(0.5, 0, 0, 104), UDim2.fromOffset(420, 40))
local eventLabel = makeLabel(eventPanel, "Event", "Next event in 90s", 20, Color3.fromRGB(255, 255, 255))
eventLabel.Size = UDim2.new(1, 0, 1, 0)
eventLabel.TextScaled = true

-- Top-right: Lock and Rebirth buttons.
local buttonsPanel = Instance.new("Frame")
buttonsPanel.Name = "Buttons"
buttonsPanel.AnchorPoint = Vector2.new(1, 0)
buttonsPanel.Position = UDim2.new(1, -12, 0, 12)
buttonsPanel.Size = UDim2.fromOffset(210, 130)
buttonsPanel.BackgroundTransparency = 1
buttonsPanel.Parent = gui

local function makeButton(name, text, y)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = UDim2.new(0, 0, 0, y)
	button.Size = UDim2.fromOffset(210, 56)
	button.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	button.BackgroundTransparency = 0.15
	button.Text = text
	button.TextSize = 20
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.GothamBold
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button
	button.Parent = buttonsPanel
	return button
end

local lockButton = makeButton("LockButton", "Lock Base [Q]", 0)
local rebirthButton = makeButton("RebirthButton", "Rebirth [R]\n$10,000", 66)

-- Right side: my base roster.
local basePanel = makePanel(gui, "BasePanel", UDim2.new(1, -120, 0.5, -110), UDim2.fromOffset(220, 240))
basePanel.AnchorPoint = Vector2.new(1, 0.5)
local baseTitle = makeLabel(basePanel, "Title", "MY BASE", 22, Color3.fromRGB(255, 255, 255))
baseTitle.Position = UDim2.new(0, 0, 0, 6)
baseTitle.Size = UDim2.new(1, 0, 0, 28)
local baseList = Instance.new("Frame")
baseList.Name = "List"
baseList.Position = UDim2.new(0, 8, 0, 40)
baseList.Size = UDim2.new(1, -16, 1, -48)
baseList.BackgroundTransparency = 1
baseList.Parent = basePanel

-- Bottom-centre: action prompt + carrying chip.
local promptPanel = makePanel(gui, "PromptPanel", UDim2.new(0.5, 0, 1, -84), UDim2.fromOffset(560, 44))
promptPanel.AnchorPoint = Vector2.new(0.5, 1)
local promptLabel = makeLabel(promptPanel, "Prompt", "Walk to the belt!", 20, Color3.fromRGB(255, 255, 255))
promptLabel.Size = UDim2.new(1, 0, 1, 0)
promptLabel.TextScaled = true

local carryPanel = makePanel(gui, "CarryPanel", UDim2.new(0.5, 0, 1, -136), UDim2.fromOffset(420, 40))
carryPanel.AnchorPoint = Vector2.new(0.5, 1)
carryPanel.Visible = false
local carryLabel = makeLabel(carryPanel, "Carrying", "Carrying: -", 20, Color3.fromRGB(255, 220, 80))
carryLabel.Size = UDim2.new(1, 0, 1, 0)
carryLabel.TextScaled = true

-- Bottom-right: leaderboard.
local boardPanel = makePanel(gui, "BoardPanel", UDim2.new(1, -120, 1, -150), UDim2.fromOffset(220, 140))
boardPanel.AnchorPoint = Vector2.new(1, 1)
local boardTitle = makeLabel(boardPanel, "Title", "RICHEST PLAYERS", 20, Color3.fromRGB(255, 220, 80))
boardTitle.Position = UDim2.new(0, 0, 0, 6)
boardTitle.Size = UDim2.new(1, 0, 0, 26)
local boardList = Instance.new("Frame")
boardList.Name = "List"
boardList.Position = UDim2.new(0, 8, 0, 36)
boardList.Size = UDim2.new(1, -16, 1, -44)
boardList.BackgroundTransparency = 1
boardList.Parent = boardPanel

-- Notification feed, centre, under the event banner.
local feed = Instance.new("Frame")
feed.Name = "Feed"
feed.AnchorPoint = Vector2.new(0.5, 0)
feed.Position = UDim2.new(0.5, 0, 0, 152)
feed.Size = UDim2.fromOffset(520, 120)
feed.BackgroundTransparency = 1
feed.Parent = gui
local feedLayout = Instance.new("UIListLayout")
feedLayout.SortOrder = Enum.SortOrder.LayoutOrder
feedLayout.Padding = UDim.new(0, 4)
feedLayout.Parent = feed

-- Notifications: newest on top, fade out after 5 seconds.
local function notify(message)
	local note = Instance.new("TextLabel")
	note.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	note.BackgroundTransparency = 0.15
	note.Text = message
	note.TextSize = 18
	note.TextColor3 = Color3.fromRGB(255, 255, 255)
	note.Font = Enum.Font.GothamBold
	note.TextWrapped = true
	note.Size = UDim2.new(1, 0, 0, 30)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = note
	note.Parent = feed
	task.delay(5, function()
		note:Destroy()
	end)
	-- Keep the feed short: drop the oldest notes.
	while #feed:GetChildren() > 5 do
		for _, child in ipairs(feed:GetChildren()) do
			if child:IsA("TextLabel") then
				child:Destroy()
				break
			end
		end
	end
end

NotifyEvent.OnClientEvent:Connect(notify)

-- Rebuild the base roster from the server's snapshot.
local function refreshBase(contents)
	for _, child in ipairs(baseList:GetChildren()) do
		child:Destroy()
	end
	if #contents == 0 then
		local empty = makeLabel(baseList, "Empty", "Empty — go buy a brainrot!", 16, Color3.fromRGB(200, 200, 200))
		empty.Size = UDim2.new(1, 0, 0, 24)
		return
	end
	for i, entry in ipairs(contents) do
		local row = makeLabel(baseList, "Row" .. tostring(i), "", 16, Color3.fromRGB(255, 255, 255))
		row.Position = UDim2.new(0, 0, 0, (i - 1) * 28)
		row.Size = UDim2.new(1, 0, 0, 26)
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Text = entry.Name .. "  $" .. tostring(entry.Income) .. "/s"
		local tag = Instance.new("TextLabel")
		tag.BackgroundTransparency = 1
		tag.Position = UDim2.new(1, -120, 0, 0)
		tag.Size = UDim2.new(0, 120, 0, 26)
		tag.Text = entry.Rarity .. " " .. entry.Mutation
		tag.TextSize = 14
		tag.TextColor3 = RARITY_COLORS[entry.Rarity] or Color3.fromRGB(255, 255, 255)
		tag.Font = Enum.Font.GothamBold
		tag.TextXAlignment = Enum.TextXAlignment.Right
		tag.Parent = row
	end
end

-- Rebuild the leaderboard from the server's snapshot.
local function refreshBoard(rows)
	for _, child in ipairs(boardList:GetChildren()) do
		child:Destroy()
	end
	for i, row in ipairs(rows) do
		local label = makeLabel(boardList, "Row" .. tostring(i), "", 16, Color3.fromRGB(255, 255, 255))
		label.Position = UDim2.new(0, 0, 0, (i - 1) * 22)
		label.Size = UDim2.new(1, 0, 0, 20)
		label.TextXAlignment = Enum.TextXAlignment.Left
		local medal = ""
		if i == 1 then
			medal = "1st "
		elseif i == 2 then
			medal = "2nd "
		elseif i == 3 then
			medal = "3rd "
		else
			medal = tostring(i) .. "th "
		end
		label.Text = medal .. row.Name .. "  " .. money(row.Cash)
		if row.Rebirths > 0 then
			label.Text = label.Text .. "  (x" .. tostring(1 + row.Rebirths * 0.5) .. ")"
		end
	end
end

-- Full HUD refresh from one StateUpdate.
StateEvent.OnClientEvent:Connect(function(state)
	cashLabel.Text = money(state.Cash)
	incomeLabel.Text = "+" .. money(state.Income) .. "/s  |  x" .. tostring(state.Multiplier)
		.. "  |  Rebirths: " .. tostring(state.Rebirths)

	if state.EventActive then
		eventLabel.Text = state.EventActive.Name .. " — " .. tostring(state.EventActive.Remaining) .. "s left! GET INSIDE!"
		eventPanel.BackgroundColor3 = Color3.fromRGB(160, 30, 30)
	else
		eventLabel.Text = "Next event in " .. tostring(state.EventIn) .. "s"
		eventPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	end

	if state.LockRemaining > 0 then
		lockButton.Text = "Locked! " .. tostring(math.ceil(state.LockRemaining)) .. "s left"
	elseif state.LockCooldown > 0 then
		lockButton.Text = "Lock cooldown " .. tostring(math.ceil(state.LockCooldown)) .. "s"
	else
		lockButton.Text = "Lock Base [Q]"
	end

	rebirthButton.Text = "Rebirth [R]\n" .. money(state.RebirthCost) .. " (x" .. tostring(state.Multiplier + 0.5) .. ")"

	if state.Carrying then
		carryPanel.Visible = true
		carryLabel.Text = "Carrying: " .. state.Carrying.Name .. " ($" .. tostring(state.Carrying.Income) .. "/s)"
	else
		carryPanel.Visible = false
	end

	promptLabel.Text = state.Prompt
	refreshBase(state.BaseContents)
	refreshBoard(state.Leaderboard)
end)

-- Input: ContextActionService so the default camera scripts never eat our keys.
local rebirthArmed = false

local function onInteract(_, inputState, _)
	if inputState == Enum.UserInputState.Begin then
		InteractEvent:FireServer()
	end
end

local function onLock(_, inputState, _)
	if inputState == Enum.UserInputState.Begin then
		LockEvent:FireServer()
	end
end

local function onRebirth(_, inputState, _)
	if inputState ~= Enum.UserInputState.Begin then
		return
	end
	if not rebirthArmed then
		rebirthArmed = true
		notify("Press R again within 5s to REBIRTH (wipes cash + base, +0.5x forever)!")
		task.delay(5, function()
			rebirthArmed = false
		end)
	else
		rebirthArmed = false
		RebirthEvent:FireServer()
	end
end

ContextActionService:BindAction("BrainrotInteract", onInteract, false, Enum.KeyCode.E)
ContextActionService:BindAction("BrainrotLock", onLock, false, Enum.KeyCode.Q)
ContextActionService:BindAction("BrainrotRebirth", onRebirth, false, Enum.KeyCode.R)

lockButton.MouseButton1Click:Connect(function()
	LockEvent:FireServer()
end)
rebirthButton.MouseButton1Click:Connect(function()
	onRebirth(nil, Enum.UserInputState.Begin, nil)
end)

notify("Welcome to Noodle Brainrot Heist! Buy brainrots, fill your base, steal wisely!")
