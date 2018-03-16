----------------------------------------------------------------------------------------------------------------------
    -- This program is free software: you can redistribute it and/or modify
    -- it under the terms of the GNU General Public License as published by
    -- the Free Software Foundation, either version 3 of the License, or
    -- (at your option) any later version.
	
    -- This program is distributed in the hope that it will be useful,
    -- but WITHOUT ANY WARRANTY; without even the implied warranty of
    -- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    -- GNU General Public License for more details.

    -- You should have received a copy of the GNU General Public License
    -- along with this program.  If not, see <http://www.gnu.org/licenses/>.
----------------------------------------------------------------------------------------------------------------------


local addonName, CLL = ...
if not CLL then return end


-- Initialise environment
local DB = {}

-- Locals and constants
local MODULE = "DB"
local DB_VERSION = 1

-- DB Versioning
local versions = {
	[1] = { changelog = "Initial version", changes = {} }
}

-- Upvalues
local type = type
local format = format
local tonumber = tonumber
local tostring = tostring
local pairs = pairs
local UnitName = UnitName
local GetRealmName = GetRealmName
local GetLocale = GetLocale
local ChatMsg = CLL.Output.Print
local DebugMsg = CLL.Debug.Print
local GetFQCN = CLL.GetFQCN


-- Print a formatted message
function DB.Init()

	-- Create DB tables if necessary
	ContainerLootLoggerDB = ContainerLootLoggerDB or {}
	
	local fqcn = GetFQCN()
	ContainerLootLoggerDB[fqcn] = ContainerLootLoggerDB[fqcn] or {}
	
	-- Update to current version (if outdated)
	local currentVersion = ContainerLootLoggerDB["DatabaseVersion"]
	DebugMsg(MODULE, "Initialising DB with currentVersion = " .. tostring(currentVersion))
	
	if not currentVersion or type(currentVersion) ~= "number" or (tonumber(currentVersion) < DB_VERSION) then -- DB needs upgrade to newer version
		DebugMsg(MODULE, "DatabaseVersion was found to be outdated (is " .. tostring(currentVersion) .. ", needs upgrading to " .. DB_VERSION .. ")")
		-- TODO: Apply changes where necessary
		ContainerLootLoggerDB["DatabaseVersion"] = DB_VERSION
	end	
	
end

-- Validates a given entry (must contain container name and loot info)
function DB.ValidateEntry(entry)
	-- A valid entry looks like this (for the current DB_VERSION; may be subject to change):
	-- <link> = { amount = <total amount>, type = <currency, item, etc.>, locale = <client locale>, count = <no. of opened containers> }
	local template = {
		amount = "number",
		type = "string",
		--locale = "string", -- Not needed, as it will be added by DB.AddEntry automatically if omitted
		count = "number", -- Will also be increased or initialised with 1 automatically
	}
	
	for k, v in pairs(template) do -- Compare entry with the template and make sure the fields exist
		if not entry[k] or type(entry[k]) ~= v then -- This part of the template doesn't exist or is invalid -> reject entry
			DebugMsg(MODULE, "Failed to validate entry " .. tostring(entry[k]) .. " for key '" .. k .. "' (should be " .. v .. ", but is " .. type(entry[k]) .. ")")
			return false
		end
	end
	
	return true
	
end


-- Add one instance of opened container
function DB.AddOpening(container, fqcn)

	fqcn = fqcn or GetFQCN()
	
	container = container or "UNKNOWN_SOURCE" -- TODO
	DebugMsg(MODULE, "Adding opening for fqcn = " .. tostring(fqcn) .. ", container = " .. tostring(container))
	ContainerLootLoggerDB[fqcn][container] = ContainerLootLoggerDB[fqcn][container] or {} -- Init table if this container hasn't been added before
	

	ContainerLootLoggerDB[fqcn][container].numContainersOpened = ContainerLootLoggerDB[fqcn][container].numContainersOpened and (ContainerLootLoggerDB[fqcn][container].numContainersOpened + 1 ) or 1 -- TODO: Wrong for missions, should consider each mission instead of the "table opening"?
	
end

-- Adds a loot entry for the given fqcn (or the current player if none was given)
-- @param entry
-- @param fqcn
function DB.AddEntry(key, entry, container, fqcn)

	container = container or "UNKNOWN_CONTAINER"
	fqcn = fqcn or GetFQCN()

	local isValid = DB.ValidateEntry(entry)
	if not isValid then -- Can't add this to the DB
		DebugMsg(MODULE, "Failed to add entry to the DB because it was invalid")
		return
	end
	
	-- Update existing entry or create anew with default values to add the given loot info
	DebugMsg(MODULE, "Adding entry for fqcn = " .. tostring(fqcn) .. ", container = " .. tostring(container))
	ContainerLootLoggerDB[fqcn][container] = ContainerLootLoggerDB[fqcn][container] or {} -- Init table if this container hasn't been added before
	
	ContainerLootLoggerDB[fqcn][container][key] = ContainerLootLoggerDB[fqcn][container][key] or {}
	ContainerLootLoggerDB[fqcn][container][key].count = ContainerLootLoggerDB[fqcn][container][key].count or 0
	
	DebugMsg(MODULE, "Count was " .. ContainerLootLoggerDB[fqcn][container][key].count .. ", is now " .. (ContainerLootLoggerDB[fqcn][container][key].count and (ContainerLootLoggerDB[fqcn][container][key].count + entry.count) or entry.count))	
	ContainerLootLoggerDB[fqcn][container][key].count = ContainerLootLoggerDB[fqcn][container][key].count and (ContainerLootLoggerDB[fqcn][container][key].count + entry.count) or entry.count
	--ContainerLootLoggerDB[fqcn][container][key].count = (ContainerLootLoggerDB[fqcn][container][key].count + 1)
	ContainerLootLoggerDB[fqcn][container][key].amount = ContainerLootLoggerDB[fqcn][container][key].amount and (ContainerLootLoggerDB[fqcn][container][key].amount + entry.amount) or entry.amount
	ContainerLootLoggerDB[fqcn][container][key].type = ContainerLootLoggerDB[fqcn][container][key].type or entry.type -- Types shouldn't be able to change, no need to check this
	ContainerLootLoggerDB[fqcn][container][key].locale = ContainerLootLoggerDB[fqcn][container][key].locale or GetLocale() -- ditto
	
	--ContainerLootLoggerDB[fqcn][container].numContainersOpened = ContainerLootLoggerDB[fqcn][container].numContainersOpened + numOpenings
	
end

-- TODO: Format numbers according to locale (use Blizzard functions)


-- TODO: Ordering
local ABC_DESC, ABC_ASC, GOLD_DESC, GOLD_ASC, OR_DESC, GOLD_ASC, CUSTOM = 1, 2, 3, 4, 5, 6, 7

-- TODO: Settings
local settings = {
	showEmptyAll = false, -- Display characters that haven't earned any gold since last reset
	showEmptyToday = false, -- Display characters that haven't earned any gold ever
	sortType = ABC_DESC, -- TODO: Possible types = abc, custom ordering, by gold earned, by OR spent?
	
}

-- Checkout the current and total gold logged (read-only, so this can be used at will)
function DB.Checkout()

	-- Print summary of the gold earnings since last reset
	local showEmpty = settings and settings.showEmptyAll or false -- TODO: all/today
	local goldSinceLastReset, goldTotalSum = 0, 0
	DebugMsg(MODULE, "Checking out characters...")	
	for toon, entry in pairs(ContainerLootLoggerDB) do -- Check if this toon has an entry that needs to be printed
	
		-- Calculate gold earned since last reset (TODO: Not really "today" as it doesn't save data in the daily format yet)
		local goldToday = type(entry) == "table" and entry["LEGION_ORDER_HALL"] and entry["LEGION_ORDER_HALL"]["GOLD"] and entry["LEGION_ORDER_HALL"]["GOLD"]["amount"] or 0
		if goldToday > 0 then -- This character has earned gold since last reset -> Always print it
			goldSinceLastReset = goldSinceLastReset + goldToday			
			entry["LEGION_ORDER_HALL"]["GOLD_TOTAL"] = entry["LEGION_ORDER_HALL"]["GOLD_TOTAL"] or {}
			entry["LEGION_ORDER_HALL"]["GOLD_TOTAL"]["amount"] = entry["LEGION_ORDER_HALL"]["GOLD_TOTAL"]["amount"] or 0-- entry["LEGION_ORDER_HALL"]["GOLD"]["amount"]
			entry["LEGION_ORDER_HALL"]["GOLD_TOTAL"]["count"] = (entry["LEGION_ORDER_HALL"]["GOLD_TOTAL"]["count"] or 0) -- entry["LEGION_ORDER_HALL"]["GOLD"]["count"]
			-- TODO: locale, type can remain unchanged?
		end
		
		-- Calculate gold earned in total
		local goldAfterNextReset = (type(entry) == "table" and entry["LEGION_ORDER_HALL"] and entry["LEGION_ORDER_HALL"]["GOLD_TOTAL"] and entry["LEGION_ORDER_HALL"]["GOLD_TOTAL"]["amount"] or 0) + goldToday -- Add today's gold in the displayed total, without altering the DB entry (this will be done during resets)
		if (goldToday > 0 or goldAfterNextReset > 0) or showEmpty then -- Also display empty character entries in the summary
			DebugMsg(MODULE, "[" .. tostring(toon) .. "] TODAY: " .. GetCoinTextureString(goldToday) .. " - TOTAL: " .. GetCoinTextureString(goldAfterNextReset))
		end
		goldTotalSum = goldTotalSum + goldAfterNextReset - goldToday
		
	end
	
	-- Format numbers (TODO) for readability
	local formattedGoldSinceLastReset = GetCoinTextureString(goldSinceLastReset)
	local formattedGoldTotalSum = GetCoinTextureString(goldTotalSum)
	local formattedGoldAfterNextReset = GetCoinTextureString(goldTotalSum + goldSinceLastReset)
	
	-- Print summary
	DebugMsg(MODULE,"Gold earned - TODAY: " .. formattedGoldSinceLastReset .. " - OLD TOTAL: " .. formattedGoldTotalSum .. " - NEW TOTAL: " .. formattedGoldAfterNextReset)
	ChatMsg("Gold earned (total): " .. formattedGoldTotalSum)
	ChatMsg("Gold earned (since last reset): " .. formattedGoldSinceLastReset)
	ChatMsg("Gold earned (after next reset): " .. formattedGoldAfterNextReset)

end

-- Add module to shared environment
CLL.DB = DB