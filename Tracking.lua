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


-- Initialise Tracking environment
local Tracking = {}
Tracking.results = {}

-- Upvalues
local ChatMsg = CLL.Output.Print
local DebugMsg = CLL.Debug.Print
local match = string.match
local tostring = tostring
local pairs = pairs
local L = CLL.L
local wipe = wipe
local GetLocale = GetLocale
local GetCoinTextureString = GetCoinTextureString
local GetMoney = GetMoney

-- Locals and constants
local MODULE = "Tracking"
local LOOT_STRING = L["You receive item: "]
local CURRENCY_STRING = L["You receive currency: "] 
local currentGoldValue = 0

-- Parses a chat message and extracts the obtained item or currency info (if available)
-- @param msg The captured chat message
-- @return id, amount, type, link	Some info about the item or currency gained in the given message
local function ParseChatMsg(str)
	
	--	DebugMsg(MODULE, "ParseChatMsg with string " .. tostring(str) .. " -> isItem = " .. tostring(isItem) .. ", isCurrency = " .. tostring(isCurrency) .. ", type = " .. tostring(type))	
	if not str:match(LOOT_STRING) and not str:match(CURRENCY_STRING) then return end
	
	-- Extract item/currency ID and amount (if one was given)
	local id, amount = str:match("item:(%d+)"), str:match(".*" .. "x(%d+)")
	local type = "INVALID"
	if id then type = "item"
	else -- Maybe it's a currency?
		id, amount = str:match("currency:(%d+)"), str:match(".*" .. "x(%d*)")
		if id then type = "currency" end
	end
	
	amount = (amount and tonumber(amount)) or 1 -- Explicit typecasting is done here to allow direct calculations and validation before adding it later
	local link = str:match("\124c.*\124r") -- This stores much more information and can be used to retrieve bonuses etc. later (if needed)
	
	if type ~= "INVALID" then -- Can proceed as planned (with hopefully correct values)
		return id, amount, type, link
	end
	
	-- ... and in case there's something wrong...
	DebugMsg(MODULE, "Error while parsing string '" .. tostring(str) .. "' - is neither item nor currency?")

 end
 

 -- Adds a piece of loot (item or currency) as a result for the currently active scan, or the last one is none is in progress
 local function AddLoot(id, amount, type, link)

	DebugMsg(MODULE, "AddLoot with link - " .. tostring(link))
	local results = CLL.Tracking.results
	local entry = results[link]
	
	-- Add to existing entry, if one exists (create one otherwise)
	if entry then -- This item or currency has been scanned before -> increase its total amount if it matches the other data
	
		if entry.type ~= type or entry.id ~= id then -- Something isn't right -> Stop here to be safe
			DebugMsg("Mismatch in type or id for link - " .. tostring(link))
			return
		end
		
		-- Finally, increase the amount
		amount = amount or 0 -- Just to make sure
		entry.count = entry.count + 1
		entry.amount = entry.amount + tonumber(amount)
	
	else -- Create a new entry (no validation is necessary)
		results[link] = { id = id, type = type, amount = amount, count = 1 }
	end

	DebugMsg(MODULE, "Updated entry for type = " .. tostring(type) .. ", id = " .. tostring(id) .. ", with amount = " .. tostring(amount) .. ", count = " .. tostring(entry and entry.count or 1))
	-- Store the updated info in the shared table
	CLL.Tracking.results = results
 
 end
 
-- Event handlers (TODO: Move elsewhere?)
local function OnChatMsg(...)

	local args = { ... }
	local msg = args[2]
	
	-- Extract loot info (TODO: Gold isn't recognized, I believe)
	local id, amount, type, link = ParseChatMsg(msg)
	DebugMsg(MODULE, "Parsing link " .. tostring(link))
	DebugMsg(MODULE, "Extracted type = " .. tostring(type) .. ", id = " .. tostring(id) .. ", amount = " .. tostring(amount))
	
	-- Add loot to the current tracking process
	AddLoot(id, amount, type, tostring(link))
	
end

-- Start tracking for item and currency updates
function Tracking.Start()

	DebugMsg(MODULE, "Tracking started. Registering for events...")
	currentGoldValue = GetMoney()
	DebugMsg(MODULE, "Tracking started with " .. GetCoinTextureString(currentGoldValue) .. ". Registering for events...")
	
	-- Re-start the scan and scrub any previous results
	CLL.Tracking.isActive = true
	wipe(CLL.Tracking.results)
	
	-- Register for spell casts
	-- Register for loot containers
	-- Register for special loot toast windows

	-- GOLD? (not from salvage, but still...)
	ContainerLootLogger:RegisterEvent("CHAT_MSG_LOOT", OnChatMsg)
	ContainerLootLogger:RegisterEvent("CHAT_MSG_CURRENCY", OnChatMsg)

	
	-- ContainerLootLogger:RegisterEvent(key, eventHandler)
	--TotalAP.Debug("Registered for event = " .. key)
	
end

-- Helper function to make up for the # operator's shortcomings in hash tables
local function count(t)
	
	local c = 0
	
	for k,v in pairs(t) do
		c = c + 1
	end
	
	return c
	
end

-- Stop tracking and store the results
function Tracking.Stop(container)
	
	local oldGoldValue = currentGoldValue
	currentGoldValue = GetMoney()
	DebugMsg(MODULE, "Tracking stopped with " .. GetCoinTextureString(currentGoldValue) .. "Unregistering events...")
	local goldChange = currentGoldValue - oldGoldValue
	if goldChange > 0 then -- Update DB entry (TODO: Parse chat is still necessary to get all the rewards?)
		ChatMsg("Gold change detected: " .. GetCoinTextureString(goldChange))
		local goldEntry = { amount = goldChange, type = "gold", count = 1 }
		CLL.DB.AddEntry("GOLD", goldEntry, container)
	else
		if goldChange < 0 then
			DebugMsg(MODULE, "Negative gold change while tracking is in progress - you're doing it wrong!")
		end
	end
	
	CLL.Tracking.isActive = false
	
	-- Unregister all previously registered events
	ContainerLootLogger:UnregisterEvent("CHAT_MSG_LOOT")
	ContainerLootLogger:UnregisterEvent("CHAT_MSG_CURRENCY")
	
	-- Print results of the latest scan
	--Tracking.PrintResults() -- TODO: Manually only, to avoid spam
	
	-- Update DB with current results
	container = container or "UNKNOWN_CONTAINER" -- TODO: Actual opening detection is not added yet, so this is using the fallback mechanism for everything
	local clientLocale = GetLocale()
	local fqcn = CLL.GetFQCN()
	
	-- Increment container counter if there are any results
	if count(CLL.Tracking.results) > 0 then	
		
		DebugMsg(MODULE, "Saving results to DB... container = " .. container .. ", clientLocale = " .. clientLocale .. ", fqcn = " .. fqcn)
		
		for k, v in pairs(CLL.Tracking.results) do -- Add individual loot entry to the DB and increase statistics according to its amount/count
			DebugMsg(MODULE, "Attempting to add entry for key = " .. k)
			CLL.DB.AddEntry(k, v, container)
		end
	
		CLL.DB.AddOpening(container) -- TODO. This is inaccurate, count in the Detection module and simply add the total count here...
		return
		
	end	

	DebugMsg(MODULE, "Results are empty; nothing will be saved")
	
end

-- Return the results of the latest tracking process (only if no scan is currently active)
function Tracking.GetResults()

	if CLL.Tracking.isActive then -- Tracking is currently in process and the new results aren't yet available
		DebugMsg("Tracking is still in process. Results aren't updated yet!")
		return
	end
	
	return CLL.Tracking.results

end

-- Print out the currently saved results (this is also possible while a scan is still ongoing)
function Tracking.PrintResults()

	ChatMsg("-------------------------")
	ChatMsg("Tracking results: ") -- TODO: L
	for k, v in pairs(CLL.Tracking.results) do -- List this entry and all the saved data
		ChatMsg(tostring(k) .. ": " .. tostring(v.amount) .. " (" .. tostring(v.type) .. " with ID " .. tostring(v.id) .. ")")
	end
	ChatMsg("-------------------------")
	
end

-- Returns the status of the tracking process
function Tracking.IsActive()

	return CLL.Tracking.isActive
	
end


-- Add module to shared environment
CLL.Tracking = Tracking