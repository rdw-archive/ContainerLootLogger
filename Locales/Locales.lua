local L;
L = LibStub("AceLocale-3.0"):NewLocale("ContainerLootLogger", "enGB", true);

L["Used spell %s on target item %s - %s x%d"] = true;
L["At this point, no slash commands have been implemented. Sorry about that!"] = true;
L["All data has been reset."] = true;
L["Data for spell %s has been reset."] = true;
L["Data for spell %s on target %s has been reset."] = true;
L["Looted %s from %s: %s"] = true;
L["Looted %s from %s: %d x %s"] = true;
L["Received loot from %s: %d x %s"] = true;
L["Debug mode enabled."] = true;
L["Debug mode disabled."] = true;

-- Rewritten stuff below (TODO: Remove the rest once the rewrite is done)
L["%s %s for WOW %s loaded! Type /cll or /containerlootlogger if you need help :)"] = true
L["[List of available commands]"] = true
L["You receive item: "] = true
L["You receive currency: "] = true
L["You receive (%d+) Gold"] = true