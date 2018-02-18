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
local Detection = {}
local trackedSpells = { -- Spells that should be tracked by the addon (and can't be detected via regular loot events)
	-- Format: spell ID -> spellID OR isEnabled (TODO: settings, slashcmd etc)
	-- [13262] = true, -- Disenchant
	[31252] = true, -- Prospecting
	[51005] = true, -- Milling 
	[190385] = true, -- Mass Mill: Nagrand Arrowbloom
	[190384] = true, -- Mass Mill: Starflower
	[190383] = true, -- Mass Mill: Gorgrond Flytrap
	[190386] = true, -- Mass Mill: Talador Orchid
	[190381] = true, -- Mass Mill: Frostweed
	[190382] = true, -- Mass Mill: Fireweed
	[209662] = true, -- Mass Mill: Starlight Rose
	[209661] = true, -- Mass Mill: Fjarnskaggl
	[209660] = true, -- Mass Mill: Foxflowers
	[209659] = true, -- Mass Mill: Dreamleaf
	[210116] = true, -- Mass Mill: Yseralline Seeds
	[209664] = true, -- Mass Mill: Felwort
	[209658] = true, -- Mass Mill: Aethril
	[114120] = true, -- Salvage = Big Crate of Salvage (no longer obtainable)
	[168178] = true, -- Bag of Salvaged Goods (no longer obtainable)
	[168179] = true, -- Salvage = Crate of Salvage (no longer obtainable?)
	[220971] = 139593, -- Sack of Salvaged Goods
	[220972] = 139594, -- Salvage = Salvage Crate
	[220973] = 140590, -- Salvage = Large Crate of Salvage
	[175767] = 118697, -- Big Bag of Pet Supplies (WOD Menagerie)
	[127751] = 187534, -- Fel-touched Pet Supplies (Tanaan Jungle) TODO: Doesn't detect the loot events??
}

local containerLUT = { -- TODO: Messy / duplicate code
-- TODO: These are only valid for enUS -> need a better solution
	[220971] = "\124cffffffff\124Hitem:139593::::::::110:::::\124h[Sack of Salvaged Goods]\124h\124r", -- Sack of Salvaged Goods
	[220972] = "\124cff1eff00\124Hitem:139594::::::::::0\124h[Salvage Crate]\124h\124r", -- Salvage = Salvage Crate
	[220973] = "\124cff1eff00\124Hitem:140590::::::::::0\124h[Large Crate of Salvage]\124h\124r", -- Salvage = Large Crate of Salvage
	[175767] = "\124cffffffff\124Hitem:118697::::::::::0\124h[Big Bag of Pet Supplies]\124h\124r", -- Big Bag of Pet Supplies (WOD Menagerie)
	--[127751] = 187534, -- Fel-touched Pet Supplies (Tanaan Jungle) TODO: Doesn't detect the loot events??
}

-- Upvalues
local ChatMsg = CLL.Output.Print
local DebugMsg = CLL.Debug.Print
local L = CLL.L
local tostring = tostring


-- Locals and constants
local MODULE = "Detection"

-- Called when a spell is being cast
function Detection.OnUnitSpellcastSucceeded(...)

	--local args = { ... }
	local event, unit, spell, rank, lineID, spellID = ...
	if unit == "player" and trackedSpells[spellID] then -- Player cast a spell that will lead to them looting stuff
	
		local container, numContainersOpened-- = "UNKNOWN_CONTAINER" -- TODO: DRY...
		if type(trackedSpells[spellID]) ~= "boolean" then -- Use the given itemID as container when saving results to the DB
			container = containerLUT[spellID] -- can be nil, as the container parameter is optional
		end
		
		DebugMsg(MODULE, "SPELLCAST_SUCCEEDED for spell " .. tostring(spellID) .. " (" .. tostring(spell) .. ") - container = " .. tostring(container))
		
		-- TODO: This only works if the spell automatically loots things (and sends them to the mailbox if the inventory is already full), e.g. Salvage - NOT for disenchant or things that trigger an actual loot window - this will be detected separately, including checks for the loot window closing - KNOWN ISSUE: If items are sent they will not be tracked. The user simply has to make sure their inventory isn't cramped when opening them, :/
		
		-- Start tracking and give it a bit to detect loot (todo: may bug out if lag is an issue?)
		DebugMsg(MODULE, "Starting Tracking process to detect loot...")
		CLL.Tracking.Start() -- TODO: Set container properly
		local secs = 1 -- TODO: If this delay is longer than the shortest cast time (e.g., 1.5sec for Salvage), then a new cast can finish while tracking is still in progress/locked, which means the 2nd cast will either mess up the first one's results, or go (partially) undetected
		C_Timer.After(secs, function(self)
			DebugMsg(MODULE, "Stopped Tracking process after " .. secs .. " seconds") -- TODO. Settings to account for latency?
			CLL.Tracking.Stop(container)
		end)
	
	end
	
end

local followerTypes = { -- Simple LUT to match Blizzard's follower types to loot sources in the DB (so they don't show as UNKNOWN_CONTAINER)

	[LE_FOLLOWER_TYPE_GARRISON_6_0] = "WOD_GARRISON",
	[LE_FOLLOWER_TYPE_GARRISON_7_0] = "LEGION_ORDER_HALL",
	
}

local container = "NOT_INITIALISED"
local isOpening = false

-- Called when a mission table is opened -> Start tracking process to detect loot
function Detection.OnGarrisonMissionNPCOpened(...)

	local _, followerType = ...
	container = followerTypes[followerType] or  "UNKNOWN_FOLLOWER_TYPE"
	DebugMsg(MODULE, "OnGarrisonMissionNPCOpened with followerType = " .. followerType .. ", container = " .. container)
	
	if isOpening then
		DebugMsg(MODULE, "Mission table is already open!")
		return
	end
	isOpening = true
	
	DebugMsg(MODULE, "Starting Tracking process to detect loot...")
	CLL.Tracking.Start()
	
end

-- Called when a mission table is closed -> Stop tracking process and save results to DB
function Detection.OnGarrisonMissionNPCClosed(...)

	DebugMsg(MODULE, "OnGarrisonMissionNPCClosed with container = " .. container)
	
	if not isOpening then
		DebugMsg(MODULE, "Mission table is not open!")
		return
	end
	
	DebugMsg(MODULE, "Stopped tracking process after mission table was closed...")
	CLL.Tracking.Stop(container)
	
	isOpening = false
	
end


-- Add module to shared environment
CLL.Detection = Detection