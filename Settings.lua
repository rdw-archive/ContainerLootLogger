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

local Settings = {}

-- Locals and constants
local MODULE = "Settings"
local settings = {
	global = {}, -- TODO: DB would belong here, but I'm not a fan of having AceDB blow up any existing metatables for this 

	profile = { -- Settings go here
		settings = defaultSettings,
	},
}

-- Initialise Settings in SavedVariables
function Settings.Init()

	-- Let AceDB handle this
	CLL.SettingsDB = LibStub("AceDB-3.0"):New("ContainerLootLoggerSettings", settings, true)
	
end

-- Add module to shared environment
CLL.Settings = Settings
