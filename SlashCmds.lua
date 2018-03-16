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
local SlashCmds = {}


-- Upvalues
local L = CLL.L
local ChatMsg = CLL.Output.Print
local type = type

-- Configuration slash commands
-- Manually disables logging
function SlashCmds.SlashOff()
	
	if CLL.SettingsDB.profile.settings.core.isEnabled then -- Turn it off
		CLL.SettingsDB.profile.settings.core.isEnabled = false
		ChatMsg("Logging is now disabled")
	else
		ChatMsg("Logging is already disabled")
	end
	
end

-- Manually enables logging
function SlashCmds.SlashOn()
	
	if not CLL.SettingsDB.profile.settings.core.isEnabled then -- Turn it on
		CLL.SettingsDB.profile.settings.core.isEnabled = true
		ChatMsg("Logging is now enabled")
	else
		ChatMsg("Logging is already enabled")
	end
	
end


-- List of supported slash commands
local validCommands = {
	
	["help"] = function()
		ChatMsg(L["List of valid slash commands:"])
		ChatMsg("--- TODO ---")
	end,
	
	["start"] = CLL.Tracking.Start,
	["stop"] = CLL.Tracking.Stop,
	
	["gold"] = CLL.Statistics.PrintGold,
	["on"] = SlashCmds.SlashOn,
	["off"] = SlashCmds.SlashOff,
	["checkout"] = CLL.DB.Checkout,
	["co"] = CLL.DB.Checkout, -- Alias
	["reset"] = CLL.DB.Reset,
	
}

-- Print a formatted message
function SlashCmds.InputHandler(input)

	-- Parse input (via AceConsole)
	local command = ContainerLootLogger:GetArgs(input)
	local handlerFunction = validCommands[command]
	
	if handlerFunction ~= nil and type(handlerFunction) == "function" then -- Is a valid slash command -> execute it
	

		handlerFunction()
	
	else -- Display help command
	
		validCommands["help"]()
	
	end
	
end


-- Add module to shared environment
CLL.SlashCmds = SlashCmds