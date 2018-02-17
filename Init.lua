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


-- Initialise shared resources
ContainerLootLogger = LibStub("AceAddon-3.0"):NewAddon("ContainerLootLogger", "AceConsole-3.0", "AceEvent-3.0")
CLL.L = LibStub("AceLocale-3.0"):GetLocale("ContainerLootLogger")
CLL.version = GetAddOnMetadata("ContainerLootLogger", "Version")
--@debug@
CLL.version = "DEBUG"
--@end-debug@
CLL.obj = ContainerLootLogger

-- Initialise modules
CLL.DB = CLL.DB or {}
CLL.Debug = CLL.Debug or {}
CLL.Output = CLL.Output or {}
CLL.SlashCmds = CLL.SlashCmds or {}
CLL.Tracking = CLL.Tracking or {}
CLL.Statistics = CLL.Statistics or {}