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
local DebugMsg = CLL.Debug.Print

-- Locals and constants
local MODULE = "Tracking"


-- Start tracking for item and currency updates
function Tracking:Start()

	DebugMsg(MODULE, "Tracking started")

end

-- Stop tracking and store the results
function Tracking:Stop()
	
	DebugMsg(MODULE, "Tracking stopped")

end

-- Return the results of the latest tracking process
function Tracking:GetResults()

	return Tracking.results

end


-- Add module to shared environment
CLL.Tracking = Tracking