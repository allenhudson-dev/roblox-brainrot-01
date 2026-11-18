-- Economy.luau
-- Owns every player's money: cash, income per second, rebirths.
-- Income is computed from the brainrots sitting in the player's base
-- (Bases.luau owns the slots; this module only reads them through the
-- callback the bootstrap wires up, so the two modules never require
-- each other in a circle).

local Config = require(script.Parent.Config)

local Economy = {}

-- player -> { Cash, Rebirths }
local players = {}

-- Set by init.server.luau: function(player) -> total $/s from base brainrots.
Economy.GetBaseIncome = nil

function Economy.AddPlayer(player)
	players[player] = {
		Cash = Config.START_CASH,
		Rebirths = 0,
	}
end

function Economy.RemovePlayer(player)
	players[player] = nil
end

function Economy.GetData(player)
	return players[player]
end

function Economy.GetCash(player)
	local data = players[player]
	if data then
		return data.Cash
	end
	return 0
end

function Economy.GetRebirths(player)
	local data = players[player]
	if data then
		return data.Rebirths
	end
	return 0
end

-- Income per second, before any payment: base income x rebirth multiplier.
function Economy.GetIncomePerSecond(player)
	local data = players[player]
	if not data then
		return 0
	end
	local baseIncome = 0
	if Economy.GetBaseIncome then
		baseIncome = Economy.GetBaseIncome(player)
	end
	return math.floor(baseIncome * Config.RebirthMultiplier(data.Rebirths))
end

-- One economy tick (called once per second): pay everyone their income.
function Economy.Tick()
	for player, data in pairs(players) do
		if player.Parent then
			data.Cash += Economy.GetIncomePerSecond(player)
		end
	end
end

-- Try to spend. Returns true and deducts, or false and deducts nothing.
function Economy.TrySpend(player, amount)
	local data = players[player]
	if not data then
		return false
	end
	if amount <= 0 then
		return true
	end
	if data.Cash < amount then
		return false
	end
	data.Cash -= amount
	return true
end

function Economy.AddCash(player, amount)
	local data = players[player]
	if data then
		data.Cash += amount
	end
end

-- Rebirth: wipe cash and the base, gain a permanent +0.5x multiplier.
-- Returns true on success, or false plus a reason string.
function Economy.TryRebirth(player)
	local data = players[player]
	if not data then
		return false, "No player data"
	end
	local cost = Config.RebirthCost(data.Rebirths)
	if data.Cash < cost then
		return false, "Need $" .. tostring(cost) .. " to rebirth"
	end
	data.Cash = 0
	data.Rebirths += 1
	return true, "Reborn! Income is now x" .. tostring(Config.RebirthMultiplier(data.Rebirths))
end

return Economy
