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
local Statistics = {}

-- Locals and constants
local MODULE = "Statistics"

-- Upvalues
local L = CLL.L
local ChatMsg = CLL.Output.Print
local DebugMsg = CLL.Debug.Print
local tostring = tostring
local format = format
local GetCoinTextureString = GetCoinTextureString


-- Print a formatted message to display the gained Gold from Legion Order Halls
function Statistics.PrintGold(fqcn) -- TODO: Command for specific items of interest (PS, BOS, etc - and track resource consumption?), stats for ALL characters, by server, etc.

	fqcn = fqcn or CLL.GetFQCN()
	ChatMsg(format("Gold summary for %s:", tostring(fqcn))) -- TODO: L
	
	local db = ContainerLootLoggerDB[fqcn]
	if not db then
		DebugMsg(MODULE, "Failed to print summary because a DB entry for this character doesn't exist")
		return
	end
	
	local goldValue = db["LEGION_ORDER_HALL"] and db["LEGION_ORDER_HALL"]["GOLD"] and db["LEGION_ORDER_HALL"]["GOLD"]["amount"] or 0
	
	ChatMsg("Total: " .. GetCoinTextureString(goldValue)) -- TODO: L / different stats for each day (DAY/WEEK/TOTAL - AVG, MIN, MAX, STDEV etc)
	
end


-- Add module to shared environment
CLL.Statistics = Statistics