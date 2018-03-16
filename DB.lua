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
local date = date
local math_abs = math.abs
local str_match = string.match
local UnitName = UnitName
local GetRealmName = GetRealmName
local GetLocale = GetLocale
local ChatMsg = CLL.Output.Print
local DebugMsg = CLL.Debug.Print
local GetFQCN = CLL.GetFQCN

-- Helper function (TODO: Upvalue)
local function IsFQCN(str)

	if not str or not str:match(".*%s-%s.*") then return false end
	return true
	
end

-- Initialise DB in SavedVariables
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
		type = "string", -- TODO: Temp workaround for GOLD_TOTAL not having it
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
	
	-- Add entry for the current day (to allow statistical analysis later on)
	local today = date("%d-%m-%Y") -- e.g., 09-11-2001 -> to be used as key
	ContainerLootLoggerDB[fqcn][container][key][today] = ContainerLootLoggerDB[fqcn][container][key][today] or {} -- Create new entry if none exists
	ContainerLootLoggerDB[fqcn][container][key][today].count = (ContainerLootLoggerDB[fqcn][container][key][today].count or 0) + (entry.count or 0)
	ContainerLootLoggerDB[fqcn][container][key][today].amount = (ContainerLootLoggerDB[fqcn][container][key][today].amount or 0) + (entry.amount or 0)

	local countToday = ContainerLootLoggerDB[fqcn][container][key][today].count
	local amountToday = ContainerLootLoggerDB[fqcn][container][key][today].amount
	DebugMsg(MODULE, "Updated entry for " .. container ..  " with date [" .. today .. "]: count = " .. countToday .. ", amount = " .. amountToday)
	
end

-- TODO: Format numbers according to locale (use Blizzard functions)

-- Sums up the daily entries for a given character and container and returns some statistics
function DB.GetTotalAmount(container, fqcn)

	-- Parameter validation (well, sort of)
	if not container then return  end
	fqcn = fqcn or GetFQCN()
	
	-- Sum up all entries
	local numEntries, totalAmount = 0, 0
	local today = date("%d-%m-%Y") -- e.g., 09-11-2001 -> to be used as key
	local datePattern = "%d+-%d+-%d+" -- all other entries are actual words, so it doesn't need to be overly restrictive
	
	local entry = ContainerLootLoggerDB[fqcn] -- Check if this toon has an entry that needs to be printed
	
	if type(entry) == "table" and IsFQCN(fqcn) then -- is potential character DB
	
		local orderHallLog = entry.LEGION_ORDER_HALL or {}
		local containerLog = orderHallLog[container] or {}
--print(container, fqcn)
		for k, v in pairs(containerLog) do -- Check if entry is a daily log
--print(1, k, v)		
			if str_match(k, datePattern) then -- Is a daily log entry
--print(2)
				numEntries = numEntries + (((v.amount ~= nil) and 1) or 0) -- If the daily log exists but is empty, don't count this day
				totalAmount = totalAmount + (v.amount or 0)
			end
		end
	end
	
--	DebugMsg(MODULE, "GetTotalAmount for toon = " .. fqcn .. " and container = " .. container .. " found numEntries = " .. numEntries .. ", totalAmount = " .. totalAmount)
	
	return totalAmount, numEntries

end

-- TODO: Ordering
local ABC_DESC, ABC_ASC, GOLD_DESC, GOLD_ASC, OR_DESC, GOLD_ASC, CUSTOM = 1, 2, 3, 4, 5, 6, 7

-- TODO: Settings
local settings = {
	showEmptyAll = false, -- Display characters that haven't earned any gold since last reset
	showEmptyToday = false, -- Display characters that haven't earned any gold ever
	sortType = ABC_DESC, -- TODO: Possible types = abc, custom ordering, by gold earned, by OR spent?
	showCurrentPlayerOnly = true, -- Only display summary for the logged-in character
}

-- Checkout the current and total gold logged (read-only, so this can be used deliberately)
function DB.Checkout()

	-- Print summary of the gold earnings since last reset
	local showEmpty = settings and settings.showEmptyAll or false -- TODO: all/today
	local showCurrentPlayerOnly = settings and settings.showCurrentPlayerOnly or false
	local player = GetFQCN()
	
	local goldSinceLastReset, goldTotalSum = 0, 0
	DebugMsg(MODULE, "Checking out characters...")	
	for toon, entry in pairs(ContainerLootLoggerDB) do -- Check if this toon has an entry that needs to be printed
	
		-- TODO: WIP - Read today's DB entry and output its data
		local today = date("%d-%m-%Y") -- e.g., 09-11-2001 -> to be used as key	
		
		local goldToday = type(entry) == "table" and entry["LEGION_ORDER_HALL"] and entry["LEGION_ORDER_HALL"]["GOLD"] and entry["LEGION_ORDER_HALL"]["GOLD"]["amount"] and entry["LEGION_ORDER_HALL"]["GOLD"][today] and entry["LEGION_ORDER_HALL"]["GOLD"][today].amount or 0
		local orderResourcesToday = type(entry) == "table" and entry["LEGION_ORDER_HALL"] and entry["LEGION_ORDER_HALL"]["ORDER_RESOURCES"] and entry["LEGION_ORDER_HALL"]["ORDER_RESOURCES"]["amount"] and entry["LEGION_ORDER_HALL"]["ORDER_RESOURCES"][today] and entry["LEGION_ORDER_HALL"]["ORDER_RESOURCES"][today].amount or 0
		
		if goldToday > 0 or orderResourcesToday < 0 then
--			DebugMsg(MODULE, toon .. " --- > NEW_GOLD_TODAY is " .. goldToday .. ", orderResourcesToday is " .. orderResourcesToday)
		end
		
		if goldToday > 0 then -- This character has earned gold since last reset -> Always print it
			goldSinceLastReset = goldSinceLastReset + goldToday			
			entry["LEGION_ORDER_HALL"]["GOLD_TOTAL"] = entry["LEGION_ORDER_HALL"]["GOLD_TOTAL"] or {}
			entry["LEGION_ORDER_HALL"]["GOLD_TOTAL"]["amount"] = entry["LEGION_ORDER_HALL"]["GOLD_TOTAL"]["amount"] or 0-- entry["LEGION_ORDER_HALL"]["GOLD"]["amount"]
			entry["LEGION_ORDER_HALL"]["GOLD_TOTAL"]["count"] = (entry["LEGION_ORDER_HALL"]["GOLD_TOTAL"]["count"] or 0) -- entry["LEGION_ORDER_HALL"]["GOLD"]["count"]
			-- TODO: locale, type can remain unchanged?
		end
		
		-- Calculate gold earned in total
		local goldAfterNextReset = (type(entry) == "table" and entry["LEGION_ORDER_HALL"] and entry["LEGION_ORDER_HALL"]["GOLD_TOTAL"] and entry["LEGION_ORDER_HALL"]["GOLD_TOTAL"]["amount"] or 0) + goldToday -- Add today's gold in the displayed total, without altering the DB entry (this will be done during resets)
		if (goldToday > 0 or goldAfterNextReset > 0) or showEmpty then -- Display character in the summary
			
			-- Format numbers (TODO: thousands separator) for readability
			local formattedGoldToday = GetCoinTextureString(goldToday)
			local formattedGoldTotal = GetCoinTextureString(goldAfterNextReset)
			local formattedOrderResourcesToday = math_abs(orderResourcesToday) .. " |TInterface\\Icons\\inv_orderhall_orderresources:12|t"
			local formattedOrderResourcesTotal = math_abs(orderResourcesTotal or orderResourcesToday or 0) .. " |TInterface\\Icons\\inv_orderhall_orderresources:12|t" -- TODO. Read total from DB
			
			if not showCurrentPlayerOnly or (showCurrentPlayerOnly and toon == player) then -- Display data for this toon
			
				DebugMsg(MODULE, "[" .. tostring(toon) .. "] Gold earned since last reset: " .. formattedGoldToday .. " (Total: " .. formattedGoldTotal .. ")")
				DebugMsg(MODULE, "[" .. tostring(toon) .. "] OR spent today: " .. formattedOrderResourcesToday .. " (Total: " .. formattedOrderResourcesTotal .. ")")			
				ChatMsg("-----------------------------------------------------------------------------------------------------------")
				ChatMsg("Showing data for [" .. tostring(toon) .. "]")
				ChatMsg("Gold earned (today): " .. formattedGoldToday)
				ChatMsg("Gold earned (total): " .. formattedGoldTotal)
				ChatMsg("OR spent (today): " .. formattedOrderResourcesToday)
				ChatMsg("OR spent (total): " .. formattedOrderResourcesTotal)
				
				-- Display detailed character statistics (but only if there are some entries)
				local STATISTICAL_SIGNIFICANT_THRESHOLD = 1 -- TODO - This is just to avoid Division by Zero errors, for now, but could become a setting later
				local totalGoldAmount, numGoldEntries = DB.GetTotalAmount("GOLD", toon)
				local totalOrderResourcesAmount, numOrderResourcesEntries = DB.GetTotalAmount("ORDER_RESOURCES", toon)

				-- Calculate statistics
				local goldPerDay = (numGoldEntries >= STATISTICAL_SIGNIFICANT_THRESHOLD) and (totalGoldAmount / numGoldEntries) or 0
				local orderResourcesPerDay = (numOrderResourcesEntries >= STATISTICAL_SIGNIFICANT_THRESHOLD) and (totalOrderResourcesAmount / numOrderResourcesEntries) or 0
				
				-- Format for output
				local formattedTotalGoldAmount = GetCoinTextureString(totalGoldAmount)
				local formattedGoldPerDay = GetCoinTextureString(goldPerDay)
				local formattedTotalOrderResourcesAmount = math_abs(totalOrderResourcesAmount) .. " |TInterface\\Icons\\inv_orderhall_orderresources:12|t"
				local formattedTotalOrderResourcesPerDay = math_abs(orderResourcesPerDay) .. " |TInterface\\Icons\\inv_orderhall_orderresources:12|t"
				--ChatMsg("Total gold earned: " .. formattedTotalGoldAmount .. ((numGoldEntries > 1) and (" over " .. numGoldEntries .. " days ( " .. goldPerDay .. " per day)") or ""))

				local goldBaseString = format("Total gold earned: %s", formattedTotalGoldAmount)
				local goldNumEntriesString = (numGoldEntries > 1) and format(" over %d days", numGoldEntries) or "" -- Show if there is data for several days
				local goldPerDayString = (numGoldEntries > 0) and format(" (%s per day)", formattedGoldPerDay) or "" -- Show if there is any data
				local goldSummaryString = goldBaseString .. goldNumEntriesString .. goldPerDayString
				ChatMsg(goldSummaryString)
				
				local orderResourcesBaseString = format("Total OR spent: %s", formattedTotalOrderResourcesAmount)
				local orderResourcesNumEntriesString = (numOrderResourcesEntries > 1) and format(" over %d days", numOrderResourcesEntries) or "" -- Show if there is data for several days
				local orderResourcesPerDayString = (numOrderResourcesEntries > 0) and format(" (%s per day)", formattedTotalOrderResourcesPerDay) or "" -- Show if there is any data
				local orderResourcesSummaryString = orderResourcesBaseString .. orderResourcesNumEntriesString .. orderResourcesPerDayString
				ChatMsg(orderResourcesSummaryString)	
				
				--ChatMsg("Total gold earned: " .. formattedTotalGoldAmount .. ((numGoldEntries > 1) and (" over " .. numGoldEntries .. " days") or "") .. ((numGoldEntries > 0 and totalGoldAmount > 0) and (" (" .. goldPerDay .. " per day)")) or "")
				--ChatMsg("Total OR spent: " .. formattedTotalOrderResourcesAmount .. ((numOrderResourcesEntries > 1) and (" over " .. numOrderResourcesEntries .. " days") or "") .. ((numOrderResourcesEntries > 0 and totalOrderResourcesAmount > 0) and (" (" .. math_abs(orderResourcesPerDay) .. " per day)")) or "")
				--ChatMsg("Total OR spent: " .. formattedTotalOrderResourcesAmount .. " over " .. numOrderResourcesEntries .. " day" .. ((numOrderResourcesEntries ~= 1) and "s" or "") .. " (" .. math_abs(orderResourcesPerDay) .. " per day)" )
				
				--- TODO: More stats?
			end
			
		end
		goldTotalSum = goldTotalSum + goldAfterNextReset - goldToday
		
	end
	
	-- Format numbers (TODO: thousands separator for large numbers) for readability
	local formattedGoldSinceLastReset = GetCoinTextureString(goldSinceLastReset)
	local formattedGoldTotalSum = GetCoinTextureString(goldTotalSum)
	local formattedGoldAfterNextReset = GetCoinTextureString(goldTotalSum + goldSinceLastReset)
	
	-- Print summary
	ChatMsg("-----------------------------------------------------------------------------------------------------------")
	DebugMsg(MODULE,"Gold earned since last reset: " .. formattedGoldSinceLastReset .. " - old total: " .. formattedGoldTotalSum .. " - new total: " .. formattedGoldAfterNextReset)
	ChatMsg("Gold earned (total): " .. formattedGoldTotalSum)
	ChatMsg("Gold earned (since last reset): " .. formattedGoldSinceLastReset)
	ChatMsg("Gold earned (after next reset): " .. formattedGoldAfterNextReset)

end

function DB.Reset() -- TODO: Reset other parts, too?

	for toon, entry in pairs(ContainerLootLoggerDB) do
		
		if IsFQCN(toon) then -- Is a an entry for a character, and not a general DB setting (TODO: DB structured into toons/settings part for v2?)
			
			local goldToday = type(entry) == "table" and entry["LEGION_ORDER_HALL"] and entry["LEGION_ORDER_HALL"]["GOLD"] and entry["LEGION_ORDER_HALL"]["GOLD"]["amount"] or 0
			if goldToday > 0 then
				
				local goldTotal = entry["LEGION_ORDER_HALL"]["GOLD_TOTAL"] and entry["LEGION_ORDER_HALL"]["GOLD_TOTAL"]["amount"] or 0
				local newGoldTotal = goldTotal + goldToday
				DebugMsg(MODULE, "Resetting entry for character " .. toon .. " - " .. GetCoinTextureString(entry["LEGION_ORDER_HALL"]["GOLD"]["amount"]) .. " earned today ( " .. GetCoinTextureString(newGoldTotal) .. " in total, was " .. GetCoinTextureString(goldTotal) .. " at the time of the last reset)") 

				-- Copy entry from GOLD to GOLD_TOTAL and add counts
				entry["LEGION_ORDER_HALL"]["GOLD_TOTAL"] = entry["LEGION_ORDER_HALL"]["GOLD_TOTAL"] or {}
				entry["LEGION_ORDER_HALL"]["GOLD_TOTAL"]["amount"] = (entry["LEGION_ORDER_HALL"]["GOLD_TOTAL"]["amount"] or 0) + entry["LEGION_ORDER_HALL"]["GOLD"]["amount"]
				entry["LEGION_ORDER_HALL"]["GOLD_TOTAL"]["count"] = (entry["LEGION_ORDER_HALL"]["GOLD_TOTAL"]["count"] or 0) + entry["LEGION_ORDER_HALL"]["GOLD"]["count"]
				
				-- Reset the current entry
				entry["LEGION_ORDER_HALL"]["GOLD"]["amount"] = 0
				entry["LEGION_ORDER_HALL"]["GOLD"]["count"] = 0
				
			else
				DebugMsg(MODULE, "Nothing to reset for character " .. toon)
			end
		end
	end
	
end

-- Add module to shared environment
CLL.DB = DB