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


-- Upvalues
local L = CLL.L
local ChatMsg = CLL.Output.Print


--- Called on ADDON_LOADED
function ContainerLootLogger:OnInitialize()
	
	
	-- Register slash commands
	self:RegisterChatCommand("cll", CLL.SlashCmds.InputHandler)
	self:RegisterChatCommand("containerlootlogger", CLL.SlashCmds.InputHandler)

end

--- Called on PLAYER_LOGIN or ADDON_LOADED (if addon is loaded-on-demand)
function ContainerLootLogger:OnEnable()

	local clientVersion, clientBuild = GetBuildInfo()

	-- if settings.showLoginMessage then TotalAP.ChatMsg(format(L["%s %s for WOW %s loaded!"], addonName, TotalAP.versionString, clientVersion)); end
	ChatMsg(format(L["%s %s for WOW %s loaded! Type /cll or /containerlootlogger if you need help :)"], addonName, CLL.version, clientVersion))
	
	-- TotalAP.EventHandlers.RegisterAllEvents()
	
end

--- Called when addon is unloaded or disabled manually
function ContainerLootLogger:OnDisable()



end