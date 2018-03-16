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
local pairs = pairs

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

-- Toggle debug mode
function SlashCmds.SlashDebug()
	
	if not CLL.SettingsDB.profile.settings.core.debugMode then -- Turn it on
		CLL.SettingsDB.profile.settings.core.debugMode = true
		ChatMsg("Debug Mode is now ON")
	else -- Turn it off
		CLL.SettingsDB.profile.settings.core.debugMode = false
		ChatMsg("Debug Mode is now OFF")
	end
	
end

local helpText = {
	["(on|off)"] = "Enable or disable the addon's logging functionality (e.g., to stop logging temporarily)",
	["(checkout|co)"] = "Print the Order Hall summary",
	["debug"] = "Show additional (mostly technical) info that can be used to troubleshoot problems",
}

-- Display the help text for each slash command
local function PrintSlashCmds()

	for command, text in pairs(helpText) do -- Print text if any exists
		if type(command) == "string" and type(text) == "string" then ChatMsg("/cll " .. command .. " - " .. text) end -- TODO: Alias or full slash command?
	end

end

-- List of supported slash commands
local validCommands = {
	
	["help"] = function()
		ChatMsg(L["List of valid slash commands:"])
		PrintSlashCmds()
	end,
	
	["start"] = CLL.Tracking.Start,
	["stop"] = CLL.Tracking.Stop,
	
	["on"] = SlashCmds.SlashOn,
	["off"] = SlashCmds.SlashOff,
	
	["gold"] = CLL.Statistics.PrintGold, -- TODO - useless? should replace checkout eventually with more statistics
	["checkout"] = CLL.DB.Checkout,
	["co"] = CLL.DB.Checkout, -- Alias
	["reset"] = CLL.DB.Reset,
	
	["debug"] = SlashCmds.SlashDebug,
	
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