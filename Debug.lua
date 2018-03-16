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
local Debug = {}


-- Upvalues
local print = print
local format = format


-- Print a formatted debug message
function Debug.Print(MODULE, msg)

	if not CLL.SettingsDB.profile.settings.core.debugMode then return end

	if not MODULE and msg then
		msg = msg or MODULE or "UNKNOWN_MESSAGE"
		MODULE = "UNKNOWN_MODULE"
	end
	
	print(format("|c000072CA" .. "%s-|c0033A5FD" .. MODULE .. ": " .. "|c00E6CC80%s", "CLL", msg))
	
end


-- Add module to shared environment
CLL.Debug = Debug