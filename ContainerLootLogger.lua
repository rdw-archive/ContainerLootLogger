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
CLL.version = GetAddOnMetadata("ContainerLootLogger", "Version")
CLL.obj = ContainerLootLogger

-- Initialise modules
CLL.DB = CLL.DB or {}
CLL.Debug = CLL.Debug or {}
CLL.Output = CLL.Output or {}
CLL.SlashCmds = CLL.SlashCmds or {}
CLL.Tracking = CLL.Tracking or {}
CLL.Statistics = CLL.Statistics or {}


-- Upvalues
local L = LibStub("AceLocale-3.0"):GetLocale("ContainerLootLogger")


--- Called on ADDON_LOADED
function ContainerLootLogger:OnInitialize()
	
end

--- Called on PLAYER_LOGIN or ADDON_LOADED (if addon is loaded-on-demand)
function ContainerLootLogger:OnEnable()
	
end

--- Called when addon is unloaded or disabled manually
function ContainerLootLogger:OnDisable()

end


-- TODO: debug msg = use addon name
-- if container is opened but item not cleared / bags full, it needs to discard the attempt
-- Bug if looting mobs (gold - warden tower quest) after mouseovering but not opening container (bloodhunter's quarry)

 -- Default locale = enGB (also US), most others are still TODO

local currentItem = "<none>";
local lastUsedSpell = "<none>";
local lastUsedItemSpell = "<none>";

-- Initialise savedVars DB
if not ContainerLootLoggerDB then ContainerLootLoggerDB = {} end;
local db = ContainerLootLoggerDB;

-- TODO: SlashCommand to toggle this
local debugMode = false;
local verbose = true;


-- TODO: Library for these utility functions and others to come
function GetItemIDFromLink(itemLink)
	local _, _, _, _, itemID =  string.find(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?") -- TODO: GetItemIDFromLink or sth.
	return itemID or 0;
end

function Debug(msg)
	if debugMode then
		print(format("|c000072CA" .. "CLL-Debug: " .. "|c00FFFFFF%s", msg));
	end
end

local function ChatMsg(msg)
	if verbose then
		print(format("|c00CC5500" .. "ContainerLootLogger: " .. "|c00E6CC80%s", msg));
	end
end

-- TODO: THis doesn't belong here
-- Print contents of `tbl`, with indentation.
-- `indent` sets the initial level of indentation.
function tprint (tbl, indent)
   if not indent then indent = 0 end
   for k, v in pairs(tbl) do
      formatting = string.rep("  ", indent) .. k .. ": "
      if type(v) == "table" then
         print(formatting)
         tprint(v, indent+1)
      elseif type(v) == 'boolean' then
         print(formatting .. tostring(v))      
      else
         print(formatting .. v)
      end
   end
end

-- TODO: Combine, with toggle arg
local function RegisterLootEvents(frame)
		if not frame then
			Debug("RegisterLootEvents failed: No frame reference given");
			return false;
		else			
			Debug("RegisterLootEvents called");
			
			frame:RegisterEvent("LOOT_OPENED") -- TODO: Salvage crates don't trigger loot window, and therefore don't work with this
			frame:RegisterEvent("SHOW_LOOT_TOAST");
			frame:RegisterEvent("CHAT_MSG_LOOT"); 
		--	frame:RegisterEvent("CHAT_MSG_CURRENCY"); 
			frame:RegisterEvent("CHAT_MSG_MONEY"); 
		end
end

local function UnregisterLootEvents(frame)
	if not frame then
		Debug("UnregisterLootEvents failed: No frame reference given");
		return false;
	else
		Debug("UnregisterLootEvents called");

		frame:UnregisterEvent("LOOT_OPENED");
		frame:UnregisterEvent("SHOW_LOOT_TOAST"); 
		frame:UnregisterEvent("CHAT_MSG_LOOT"); 
	--	frame:UnregisterEvent("CHAT_MSG_CURRENCY");				
		frame:UnregisterEvent("CHAT_MSG_MONEY"); 
	--	frame:UnregisterEvent("BAG_UPDATE_DELAYED");
	end
end

-- TODO: sourceItem is itemLink? Should be ID...
-- TODO: Imperial Silk -> Garrison Herbalism BUG
-- TODO: parameter for currentItem
-- TODO: Currencies need reworking. They aren't tracked properly because events are unregistered after loot, but currencies can be added later; also DB saves only ids = possible conflicts here. 
-- Counter is inaccurate, if only currency "drops" it isn't increased as they're not detected,,,
local function SaveToDB(typeString, itemOrCurrencyID, amount)
	
	Debug("Called SaveToDB with args: " .. typeString .. ", " .. itemOrCurrencyID .. ", " .. amount);
	local characterName, realm, sourceItem, result, quantity = UnitName("player"), GetRealmName() or "", currentItem, itemOrCurrencyID, amount;
	local charRealm = characterName .. " - " .. realm;
	local sourceItemLink = sourceItem;
	local sourceItemID = GetItemIDFromLink(sourceItem);
	
--	local _, _, _, _, sourceItemID = string.find(sourceItem, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?");
	Debug("SourceItemID is " .. sourceItemID .. " and currentItem was " .. currentItem .. ", while lastUsedItemSpell = " .. lastUsedItemSpell .. ", lastUsedSpell = " .. lastUsedSpell);
	if itemOrCurrencyID == 0 then -- money
		Debug(format("Saving entry of type = %s to DB for character %s - %s: Obtained %d copper from %s after using spell %s", typeString, characterName, realm, quantity, sourceItem, lastUsedSpell)); -- skip quantity, as it is always 0?
		result = "money";
	else
		Debug(format("Saving entry of type = %s to DB for character %s - %s: Obtained %d x %s from %s after using spell %s", typeString, characterName, realm, quantity, result, sourceItem, lastUsedSpell));
	end
	-- TODO: SavedVars only save when exiting, not reloading? (BUG)
	if db[charRealm] == nil then -- Create loot log table for this character
		Debug(format("Creating DB entry for character: %s", charRealm));
		db[charRealm] = {}
	else
		Debug(format("DB entry already exists for character: %s", charRealm)); 
	end
	
	if db[charRealm][sourceItemID] == nil then -- Create entry for this source item / container / spell
		Debug(format("Creating DB entry for sourceItemID: %s", sourceItemID));
		db[charRealm][sourceItemID] = {}
		db[charRealm][sourceItemID]["count"] = 1;
	else
		Debug(format("DB entry exists for sourceItemID: %s (looted %d times)", sourceItemID,  db[charRealm][sourceItemID]["count"]));
		db[charRealm][sourceItemID]["count"]  = db[charRealm][sourceItemID]["count"] + 1;
	end
	
	if db[charRealm][sourceItemID][result] == nil then -- Create entry for this particular item obtained from sourceItemID
		Debug(format("Creating entry for result: %s", result));
		db[charRealm][sourceItemID][result] = 0;
	else
		Debug(format("DB entry exists for item %s from sourceItemID %s with quantity %d. Adding %d to it", result, sourceItemID, db[charRealm][sourceItemID][result]))
	end
	
	Debug(format("Adding data for item %s: Received %d x %s", sourceItemID, result, quantity)); -- TODO: Last used spell necessary for prospecting, salvage crates etc?
	local tempAmount = db[charRealm][sourceItemID][result] + quantity;
	Debug(format("Old amount was %d, new amount is %d", db[charRealm][sourceItemID][result], tempAmount));
	db[charRealm][sourceItemID][result] = tempAmount;
end
-- All spells that can be tracked by the addon (and that aren't detected via regular loot events)
-- Format: spell ID -> isEnabled (TODO: settings, slashcmd etc)
local openContainerSpells = { 
	--[13262] = true, -- Disenchant
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

-- TODO: reset db, reset entries, show output (in frame, ideally)
local function SlashFunction(msg)

	msg = string.lower(msg)
	local command, param = msg:match("^(%S*)%s*(.-)$")
	
	if command == "reset" then
		-- TODO: reset (entry), and confirmation
		db = {};
		
			ChatMsg(L["All data has been reset."]);
			-- TODO: Reset char data, item data, results, anything
			--ChatMsg(L["Data for spell %s on target %s has been reset."]);
	-- Toggle debug mode (TODO: setting instead of local var that resets to default)
	elseif command == "dump" then
		ChatMsg("Dumping ContainerLootLoggerDB...")
			tprint(db, 2)
	elseif command == "debug" then
		if debugMode then
			ChatMsg(L["Debug mode disabled."]);
		else
			ChatMsg(L["Debug mode enabled."]);
		end
		debugMode = not debugMode;
	else
			ChatMsg("Commands: reset, debug, dump"); -- TODO: AceLocale for all outputs
			ChatMsg(L["At this point, no slash commands have been implemented. Sorry about that!"]);
	end
end

-- TODO. save data for each character, but allow output for global as well as chars

-- TODO: Unregister events after everything is done, split by types:
-- Prospecting, Milling etc.: UNIT_SPELLCAST_SUCCEEDED -> LOOT_OPENED -> BAG_UPDATE_DELAYED to finish?
-- Container: ITEM_LOCKED / ITEM_LOCK_CHANGED -> LOOT_OPENED or SHOW_LOOT_TOAST -> BAG_UPDATE_DELAYED to finish?
-- Salvage Crates: UNIT_SPELLCAST_SUCCEEDED -> CHAT_MSG_X -> BAG_UPDATE_DELAYED to finish?

-- One-time execution on load TODO: events are obviously called more often, remove them from do-end-block

	local f = CreateFrame("Frame", "InvisibleContainerLootLoggerFrame")
	f:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
	f:RegisterEvent("ITEM_LOCKED")
	f:RegisterEvent("ITEM_LOCK_CHANGED")

	f:SetScript("OnEvent", function(self, event, ...)
		if event == "PLAYER_LOGIN" then -- TODO: ADDON_LOADED (arg1 = CLL)
			ChatMsg(format("ContainerLootLogger v%s loaded!", version));
		elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
			local unit, spell, rank, lineID, spellID = ...

			lastUsedItemSpell = openContainerSpells[tonumber(spellID)] ;
			if lastUsedItemSpell then
			
				Debug("Detected event: UNIT_SPELLCAST_SUCCEEDED with spellID = " .. spellID .. " (" .. spell .. ")");
				Debug("Spell is being tracked, registering loot-related events now...")
					
				local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(lastUsedItemSpell);
				currentItem = itemLink
				lastUsedSpell = spell; -- redundant?
				
				Debug("Detected spell: " .. spellID .. " (" .. spell .. ") after UNIT_SPELLCAST_SUCCEEDED from using item = " .. lastUsedItemSpell .. " (" .. itemName .. ")" .. " cast by unit = " .. unit);

				RegisterLootEvents(self);
				
				-- Unregister unneeded events after detecting what type of spell was cast: disenchant/mill/prospect = loot window, salvage crate = chat_msg
				if spellID == 13262 then -- TODO: Prospecting, milling, mass milling ?
					Debug("Detected spell: Disenchant - locked/loot window event handling - TODO?")
				else
				--	Debug("Detected spell: NOT Disenchant - TODO?")
				end
			else -- spell not tracked (because it's not in the table, i.e. not "of interest")
				lastUsedItemSpell = "<irrelevant spell>";
				UnregisterLootEvents(self);
			end
			
		elseif event == "ITEM_LOCKED" then -- check if the locked item is on the list of tracked containers, and if tracking for it is enabled
			
			local bag, slot = ...
			
			if not bag or not slot then
				Debug("Item is likely equipped and therefore NOT a container. Doing nothing...")
			else
				local itemID = GetContainerItemID(bag, slot);
				local texture, itemCount, locked, quality, readable, lootable, itemLink, isFiltered = GetContainerItemInfo(bag, slot);
				
				if lootable then 
					Debug("Item " .. itemLink .. " is lootable. Registering LOOT_OPENED and SHOW_LOOT_TOAST...")
					RegisterLootEvents(self);
					--self:RegisterEvent("LOOT_OPENED");
					--self:RegisterEvent("SHOW_LOOT_TOAST");
				else
					Debug("Item " .. itemLink .. " is NOT lootable. Doing nothing...");
				end
		
				currentItem = itemLink; -- TODO: if nil = <nil> ? redundant?
				Debug("ITEM_LOCKED detected for bag = " .. bag .. ", slot = ".. slot .. " -> itemId = " .. itemID .. " ( ".. itemLink .. " ) ");
			end
			
		elseif event == "SHOW_LOOT_TOAST" then -- fancy containers, essentially (after ITEM_LOCKED it can't be bonus rolls)
			local typeIdentifier, itemLink, quantity = ... -- itemLink is "" for typeIdentifier money
			local _, _, _, _, itemID =  string.find(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?") -- TODO: GetItemIDFromLink or sth.
				
			--if not itemLink then itemLink = "<nil>"; end
				Debug("SHOW_LOOT_TOAST detected with typeIdentifier = " .. typeIdentifier .. ", quantity = " .. quantity .. ", itemLink = " .. itemLink)

			-- Money needs to be logged differently
			if typeIdentifier == "money" then
			    local formattedQuantity = GetCoinTextureString(quantity, 10); -- insert coin texture and format appropriately; TODO: font size from UI/chat frame		
				ChatMsg(format(L["Looted %s from %s: %s"], typeIdentifier, currentItem, formattedQuantity, itemLink));
				SaveToDB("money", 0, quantity);
			else
				ChatMsg(format(L["Looted %s from %s: %d x %s"], typeIdentifier, currentItem, quantity, itemLink));
				SaveToDB("item", itemID, quantity);
			end
		
		self:RegisterEvent("BAG_UPDATE_DELAYED");
		--UnregisterLootEvents(self);
		
		elseif event == "LOOT_OPENED" then -- Disenchanting & containers?

			Debug("LOOT_OPENED detected")
		
		for i = 1, GetNumLootItems() do
			local typeIdentifier = GetLootSlotType(i)
			local texture, item, quantity, quality, locked = GetLootSlotInfo(i)
			local itemLink = GetLootSlotLink(i);
			if typeIdentifier == LOOT_SLOT_MONEY then
				-- For coins, the quantity is always 0 and item contains the amount AND text
				Debug("<PreGSUB> Loot in this slot is gold, not item: " .. item);
				-- Format: X Gold\nY Silver\nZ Copper --> change to integer for easier storage and formatting via API GetCoinTextureString
				local temp = string.gsub(item,"\n","");
				--quantity = string.gsub(quantity,"","")
				temp = string.gsub(temp, " Copper", "");
				temp = string.gsub(temp, " Silver", "");
				temp = string.gsub(temp, " Gold", "");
				Debug("<PostGSUB> Loot in this slot is gold, not item: " .. item);
				quantity = temp; -- Format: XXYYZZ {integer = copper implied}
				local formattedQuantity = GetCoinTextureString(quantity, 10); -- insert coin texture and format appropriately; TODO: font size from UI/chat frame
				
				ChatMsg(format(L["Looted %s from %s: %s"], typeIdentifier, currentItem, formattedQuantity, itemLink));
				SaveToDB("money", 0, quantity);
			elseif typeIdentifier == LOOT_SLOT_CURRENCY  then
				Debug("LOOT_SLOT_CURRENCY: Not implemented yet? Apparently currency dropped from this loot window but it wasn't caught via CHAT_MSG_CURRENCY") -- TODO: circumvent chat_msg hack? Perhaps there is a way to get currency from toasts also
			else -- LOOT_SLOT_ITEM
			--	Debug(GetLootSlotLink(i), "x", quantity)
				ChatMsg(format(L["Looted %s from %s: %d x %s"], typeIdentifier, currentItem, quantity, itemLink));
			
				local _, _, _, _, itemID =  GetItemIDFromLink(itemLink); -- TODO: GetItemIDFromLink or sth.
				SaveToDB("item", itemID, quantity)
			--		Debug("|c00CC5500" .. "ContainerLootLogger: " .. "|c00E6CC80" .. format(L["Used spell %s on target item %s - %s x%d"],  lastUsedSpell, currentItem, currentItem, quantity))
			end
			
				Debug("At this point, lastUsedSpell = " .. lastUsedSpell  .. " - Is this correct? Especially for containers via LOOT_OPENED");
		
		end
	
		self:RegisterEvent("BAG_UPDATE_DELAYED");
		--UnregisterLootEvents(self);
		-- Save looted items in DB
		-- if db[lastUsedSpell] then -- spell has logged data -> add to it
		--	TODO
			-- Debug("Entries exists in DB for spell: " .. lastUsedSpell)
		-- end
	
	elseif event == "CHAT_MSG_LOOT" then -- all ITEMS will be saved here
		if not containerItemSpells[lastUsedItemSpell] == nil then 
			local msg, player, lineID = ...;
		
			Debug("CHAT_MSG_LOOT detected with msg = " .. msg .. ", player = " .. player .. ", lineID = " .. lineID);
			
			local comboString = string.match(msg, "You receive item: (.*)%.")  -- TODO: Localisation for this?? There needs to be a better way.
			-- TODO: Bugs out when harvesting herbs from the garrison Herb garden (after opening salvage crates)
			Debug("comboString extracted: " .. comboString);
			
			local itemLink;
			-- extract item link and amount from partial chat message
			if string.match(comboString, "x") then -- multiple items
				itemLink, amount = string.match(comboString, "^(.*)x(%d*)$"); 
			else -- just one item
				Debug("Contained just one item!")
				itemLink, amount  = comboString, 1; -- TODO: Bug when receiving just one item from salvage crate (after opening several?)
			--	local itemName, itemID = string.match(itemLink, "c[a-fA-F0-9]{8}|H(item:%d:{*})|h%[(.*)%]|h|r"); -- extract itemID and displayName from item link
			end
			
		local _, _, Color, Ltype, Id, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, reforging, Name = string.find(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?") -- err what? Copied from wow.gamepedia.com/ItemLink ... TODO: Understand this
		
		local itemName, itemID = Name, Id; 
			--if not amount then amount = 1; end -- x1 is never displayed as such
			
			Debug("itemID = " .. itemID .. ", itemName = " .. itemName .. ", amount = " .. amount);
			ChatMsg(format(L["Received loot from %s: %d x %s"], lastUsedItemSpell, amount, itemLink));
			SaveToDB("item", itemID, amount);
			-- TODO: Combine item and currency, as only minor differences exist
			
		self:RegisterEvent("BAG_UPDATE_DELAYED");
		--UnregisterLootEvents(self);
				
		-- elseif event == "CHAT_MSG_CURRENCY" then -- All CURRENCIES will be saved here. For now, isn't this garrison resources only? Cooking bag?
			
			-- local msg = ...;
			-- Debug("CHAT_MSG_CURRENCY detected with msg = " .. msg);
			
			-- --Debug("|c00CC5500" .. "ContainerLootLogger: " .. "|c00E6CC80" .. format(L["Looted %s from %s: %d x %s"], typeIdentifier, currentItem, quantity, itemLink));
			-- local comboString = string.match(msg, "You receive currency: (.*)%.")  -- TODO: Localisation for this?? There needs to be a better way.
			
			-- Debug("comboString extracted: " .. comboString);
			
			-- local currencyLink, amount = string.match(comboString, "^(.*)x(%d*)$");
			-- local _, _, Color, Ltype, Id, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, reforging, Name = string.find(currencyLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?");
			-- local currencyName, currencyID = Name, Id;
			
			-- Debug("currencyID = " .. currencyID .. ", currencyName = " .. currencyName .. ", amount = " .. amount);
			
			-- SaveToDB("currency", currencyID, amount)
			
			-- Debug("Done with this currency. Unregistering now...")
		
			-- -- TODO: put in function that is called by all event handlers?
			-- UnregisterLootEvents(self)
		end
		
	elseif event == "CHAT_MSG_MONEY" then -- What is this needed for?
		local msg = ...;
		Debug("CHAT_MSG_MONEY detected with msg = " .. msg);

		local amount = "0"; -- TODO 
		--Debug("|c00CC5500" .. "ContainerLootLogger: " .. "|c00E6CC80" .. format(L["Looted %s from %s: %d x %s"], typeIdentifier, currentItem, quantity, itemLink));
		SaveToDB("money", 0, amount);
		
	--	UnregisterLootEvents(self);
	-- elseif event == "BAG_UPDATE_DELAYED" then -- TODO: if only currencies are looted, these events are still being listened to!
		
		-- Debug("BAG_UPDATE_DELAYED detected: Unregistering all item-related loot events now.")
		-- -- Unregister events used for loot detection.. CHAT_MSG_CURRENCY is fired after this event, so it can't be disabled yet
		-- UnregisterLootEvents(self);
		
		-- -- Reset globals to not carry over items (and find possible bugs with this implementation) - TODO: Are these still needed if CHAT_MSG_CURRENCY follows?
		-- lastUsedItemSpell = "<reset after BAG_UPDATE>";
		-- lastUsedSpell = "<reset after BAG_UPDATE>";
			self:RegisterEvent("BAG_UPDATE_DELAYED");
	elseif event == "BAG_UPDATE_DELAYED" then
		Debug("Unregistering loot events after BAG_UPDATE_DELAYED");
		UnregisterLootEvents(self);
	end
end)

SLASH_CONTAINERLOOTLOGGER1 = "/cll";
SlashCmdList["CONTAINERLOOTLOGGER"] = SlashFunction;

