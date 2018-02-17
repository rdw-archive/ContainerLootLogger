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
Tracking = {}
Tracking.results = {}

-- Upvalues
local ChatMsg = CLL.Output.Print
local DebugMsg = CLL.Debug.Print
local match = string.match
local tostring = tostring
local L = CLL.L

-- Locals and constants
local MODULE = "Tracking"
local LOOT_STRING = L["You receive item: "]
local CURRENCY_STRING = L["You receive currency: "] 

-- Parses a chat message and extracts the obtained item or currency info (if available)
-- @param msg The captured chat message
-- @return id, amount, type, link	Some info about the item or currency gained in the given message
local function ParseChatMsg(str)
	
	--	DebugMsg(MODULE, "ParseChatMsg with string " .. tostring(str) .. " -> isItem = " .. tostring(isItem) .. ", isCurrency = " .. tostring(isCurrency) .. ", type = " .. tostring(type))	
	if not str:match(LOOT_STRING) and not str:match(CURRENCY_STRING) then return end
	
	-- Extract item/currency ID and amount (if one was given)
	local id, amount = str:match("item:(%d+).*(%d+)")
	local type = "INVALID"
	if id then type = "item"
	else -- Maybe it's a currency?
		id, amount = str:match("currency:(%d+).*x(%d+)")
		if id then type = "currency" end
	end
	amount = amount or 1
	local link = str:match("\124c.*\124r") -- This stores much more information and can be used to retrieve bonuses etc. later (if needed)
	
	if type ~= "INVALID" then -- Can proceed as planned (with hopefully correct values)
		return id, amount, type, link
	end
	-- ... and in case there's something wrong...
	DebugMsg(MODULE, "Error while parsing string '" .. tostring(str) .. "' - is neither item nor currency?")

 end
 

-- Event handlers (TODO: Move elsewhere?)
local function OnChatMsg(...)

	local args = { ... }
	local msg = args[2]
	
	local id, amount, type, link = ParseChatMsg(msg)
	DebugMsg(MODULE, "Parsing link " .. tostring(link))
	DebugMsg(MODULE, "Extracted type = " .. tostring(type) .. ", id = " .. tostring(id) .. ", amount = " .. tostring(amount))
	
end

-- Start tracking for item and currency updates
function Tracking.Start()

	DebugMsg(MODULE, "Tracking started. Registering for events...")
	
	CLL.Tracking.isActive = true

	-- Register for spell casts
	-- Register for loot containers
	-- Register for special loot toast windows

	-- GOLD? (not from salvage, but still...)
	ContainerLootLogger:RegisterEvent("CHAT_MSG_LOOT", OnChatMsg)
	ContainerLootLogger:RegisterEvent("CHAT_MSG_CURRENCY", OnChatMsg)

	
	-- ContainerLootLogger:RegisterEvent(key, eventHandler)
	--TotalAP.Debug("Registered for event = " .. key)
	
end

-- Stop tracking and store the results
function Tracking.Stop()
	
	DebugMsg(MODULE, "Tracking stopped. Unregistering events...")

	CLL.Tracking.isActive = false
	
	-- Unregister all previously registered events
	ContainerLootLogger:UnregisterEvent("CHAT_MSG_LOOT")
	ContainerLootLogger:UnregisterEvent("CHAT_MSG_CURRENCY")
	
end

-- Return the results of the latest tracking process
function Tracking.GetResults()

	if CLL.Tracking.isActive then -- Tracking is currently in process and the new results aren't yet available
		DebugMsg("Tracking is still in process. Results aren't updated yet!")
		return
	end
	
	return CLL.Tracking.results

end

-- Returns the status of the tracking process
function Tracking.IsActive()

	return CLL.Tracking.isActive
	
end


-- Add module to shared environment
CLL.Tracking = Tracking