--[[
4.0
Transmogrification for Classic & TBC & WoTLK - Gossip Menu
By Rochet2

Eluna version

TODO:
Make DB saving even better (Deleting)? What about coding?

Fix the cost formula

TODO in the distant future:

Are the qualities right? Blizzard might have changed the quality requirements.
What can and cant be used as source or target..?

Cant transmogrify:
rediculus items -- Foereaper: would be fun to stab people with a fish
-- Cant think of any good way to handle this easily

Cataclysm:
Test on cata : implement UI xD?
Item link icon to Are You sure text

Forked by mostly nick :) to include UI, saving, applying and deleting sets, hiding items, and support for certain new weapon combinations.
]]

local itemIconCache = require("itemIconCache")
-- Multistate: login (3) runs globally, map change (28) / equip (29) / gossip run
-- in map states. The mog caches are populated per state by the login/map-change
-- handler each state sees; the packet repair handler below reads live DB data.

---------------------------------------------------------------------------------
-- Transmog item vendor vars
---------------------------------------------------------------------------------

local TRANSMOG_VENDOR_NPC_ID = 190089
local CURRENCY_ID = 37742
local CURRENCY_NAME = "Activity Token"
local ItemCache = {} 
local itemsPerPage = 10
local currentSearchTerm = " " 


---------------------------------------------------------------------------------
-- Transmogrify items vars start
---------------------------------------------------------------------------------


local NPC_Entry = 190009

local PrepareDBTable = false -- Set to true if enabling module for the first time

local RequireGold = 1
local GoldModifier = 1.0
local GoldCost = 100000
local SetCostModifier = 3

local RequireToken = false
local TokenEntry = 37742
local TokenAmount = 1

local AllowMixedArmorTypes          = true
local AllowMixedWeaponTypes         = true
local AllowUnusable                 = true
local AllowWeaponOnShield           = true
local AllowMixedWeaponsAndOffhands  = true

local MaxSets = 10
local CurrencyName = "Gold"

local Qualities =
{
    [0]  = true, -- AllowPoor
    [1]  = true, -- AllowCommon
    [2]  = true, -- AllowUncommon
    [3]  = true, -- AllowRare
    [4]  = true, -- AllowEpic
    [5]  = true, -- AllowLegendary
    [6]  = true, -- AllowArtifact
    [7]  = true, -- AllowHeirloom
}

local _items = {}

local EQUIPMENT_SLOT_START        = 0
local EQUIPMENT_SLOT_HEAD         = 0
local EQUIPMENT_SLOT_NECK         = 1
local EQUIPMENT_SLOT_SHOULDERS    = 2
local EQUIPMENT_SLOT_BODY         = 3
local EQUIPMENT_SLOT_CHEST        = 4
local EQUIPMENT_SLOT_WAIST        = 5
local EQUIPMENT_SLOT_LEGS         = 6
local EQUIPMENT_SLOT_FEET         = 7
local EQUIPMENT_SLOT_WRISTS       = 8
local EQUIPMENT_SLOT_HANDS        = 9
local EQUIPMENT_SLOT_FINGER1      = 10
local EQUIPMENT_SLOT_FINGER2      = 11
local EQUIPMENT_SLOT_TRINKET1     = 12
local EQUIPMENT_SLOT_TRINKET2     = 13
local EQUIPMENT_SLOT_BACK         = 14
local EQUIPMENT_SLOT_MAINHAND     = 15
local EQUIPMENT_SLOT_OFFHAND      = 16
local EQUIPMENT_SLOT_RANGED       = 17
local EQUIPMENT_SLOT_TABARD       = 18
local EQUIPMENT_SLOT_END          = 19
local PRESETS                     = 5000000
local HIDE                        = 5000050
local HOW                         = 6000000

local INVENTORY_SLOT_BAG_START    = 19
local INVENTORY_SLOT_BAG_END      = 23

local INVENTORY_SLOT_ITEM_START   = 23
local INVENTORY_SLOT_ITEM_END     = 39

local INVTYPE_CHEST               = 5
local INVTYPE_WEAPON              = 13
local INVTYPE_ROBE                = 20
local INVTYPE_WEAPONMAINHAND      = 21
local INVTYPE_WEAPONOFFHAND       = 22
local INVTYPE_HELDOFFHAND         = 23
local INVTYPE_WAND                = 26

local ITEM_CLASS_WEAPON           = 2
local ITEM_CLASS_ARMOR            = 4

local ITEM_SUBCLASS_WEAPON_BOW          = 2
local ITEM_SUBCLASS_WEAPON_GUN          = 3
local ITEM_SUBCLASS_SHIELD              = 6
local ITEM_SUBCLASS_WEAPON_GUN          = 16
local ITEM_SUBCLASS_WEAPON_CROSSBOW     = 18
local ITEM_SUBCLASS_WEAPON_WAND         = 19
local ITEM_SUBCLASS_WEAPON_FISHING_POLE = 20

local EXPANSION_WOTLK = 2
local EXPANSION_TBC = 1
local PLAYER_VISIBLE_ITEM_1_ENTRYID
local ITEM_SLOT_MULTIPLIER

if GetCoreExpansion() < EXPANSION_TBC then
    PLAYER_VISIBLE_ITEM_1_ENTRYID = 260
    ITEM_SLOT_MULTIPLIER = 12
elseif GetCoreExpansion() < EXPANSION_WOTLK then
    PLAYER_VISIBLE_ITEM_1_ENTRYID = 346
    ITEM_SLOT_MULTIPLIER = 16
else
    PLAYER_VISIBLE_ITEM_1_ENTRYID = 283
    ITEM_SLOT_MULTIPLIER = 2
end

local INVENTORY_SLOT_BAG_0        = 255


---------------------------------------------------------------------------------
-- Transmogrify items script start
---------------------------------------------------------------------------------


local SlotNames = {
    [EQUIPMENT_SLOT_HEAD      ] = {"Head",         nil, nil, nil, nil, nil, nil, nil, nil},
    [EQUIPMENT_SLOT_SHOULDERS ] = {"Shoulders",    nil, nil, nil, nil, nil, nil, nil, nil},
    [EQUIPMENT_SLOT_BODY      ] = {"Shirt",        nil, nil, nil, nil, nil, nil, nil, nil},
    [EQUIPMENT_SLOT_CHEST     ] = {"Chest",        nil, nil, nil, nil, nil, nil, nil, nil},
    [EQUIPMENT_SLOT_WAIST     ] = {"Waist",        nil, nil, nil, nil, nil, nil, nil, nil},
    [EQUIPMENT_SLOT_LEGS      ] = {"Legs",         nil, nil, nil, nil, nil, nil, nil, nil},
    [EQUIPMENT_SLOT_FEET      ] = {"Feet",         nil, nil, nil, nil, nil, nil, nil, nil},
    [EQUIPMENT_SLOT_WRISTS    ] = {"Wrists",       nil, nil, nil, nil, nil, nil, nil, nil},
    [EQUIPMENT_SLOT_HANDS     ] = {"Hands",        nil, nil, nil, nil, nil, nil, nil, nil},
    [EQUIPMENT_SLOT_BACK      ] = {"Back",         nil, nil, nil, nil, nil, nil, nil, nil},
    [EQUIPMENT_SLOT_MAINHAND  ] = {"Main hand",    nil, nil, nil, nil, nil, nil, nil, nil},
    [EQUIPMENT_SLOT_OFFHAND   ] = {"Off hand",     nil, nil, nil, nil, nil, nil, nil, nil},
    [EQUIPMENT_SLOT_RANGED    ] = {"Ranged",       nil, nil, nil, nil, nil, nil, nil, nil},
    [EQUIPMENT_SLOT_TABARD    ] = {"Tabard",       nil, nil, nil, nil, nil, nil, nil, nil},
}
local Locales = {
    {"Update menu", nil, nil, nil, nil, nil, nil, nil, nil}, -- 1
    {"Remove all transmogrifications", nil, nil, nil, nil, nil, nil, nil, nil},
    {"Remove transmogrifications from all equipped items?", nil, nil, nil, nil, nil, nil, nil, nil},
    {"Using this item for transmogrify will bind it to you and make it non-refundable and non-tradeable.\n \nDo you wish to continue?\n ", nil, nil, nil, nil, nil, nil, nil, nil},
    {"Remove transmogrification from %s?", nil, nil, nil, nil, nil, nil, nil, nil}, --5
    {"Back", nil, nil, nil, nil, nil, nil, nil, nil},
    {"Remove transmogrification", nil, nil, nil, nil, nil, nil, nil, nil},
    {"Transmogrifications removed from equipped items", nil, nil, nil, nil, nil, nil, nil, nil},
    {"You have no transmogrified items equipped", nil, nil, nil, nil, nil, nil, nil, nil},
    {"%s transmogrification removed", nil, nil, nil, nil, nil, nil, nil, nil}, -- 10
    {"No transmogrification on %s slot", nil, nil, nil, nil, nil, nil, nil, nil},
    {"%s transmogrified", nil, nil, nil, nil, nil, nil, nil, nil},
    {"Selected items are not suitable", nil, nil, nil, nil, nil, nil, nil, nil},
    {"Selected item does not exist", nil, nil, nil, nil, nil, nil, nil, nil},
    {"Equipment slot is empty", nil, nil, nil, nil, nil, nil, nil, nil}, -- 15
    {"You don't have enough %ss", nil, nil, nil, nil, nil, nil, nil, nil},
    {"Not enough money", nil, nil, nil, nil, nil, nil, nil, nil},
    {"Manage sets", nil, nil, nil, nil, nil, nil, nil, nil},
    {"How does transmogrification work?\n \nTransmogrification works by applying the look of an item in your bags onto one of your equipped items. I charge "..CurrencyName.." for these services.\n \n ",
     nil,
     nil,
     nil,
     nil,
     nil,
     nil,
     nil,
     nil
     }, -- Extended subtable for explanative dialogues
    {"How does transmogrification work?", nil, nil, nil, nil, nil, nil, nil, nil}, -- 20
    {"Save set", nil, nil, nil, nil, nil, nil, nil, nil},
    {"How do sets work?", nil, nil, nil, nil, nil, nil, nil, nil},
    {"How do sets work?\n \nBy saving your transmogrification sets, you can easily store transmogs you have already paid for and reapply them infinitely for a one-time fee upon saving the set. Simply save your sets and apply them by visiting a transmogrifier at any time to use this service.\n \n ", 
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    nil
    }, -- Extended subtable for explanative dialogues
    {"How does transmogrification work?", nil, nil, nil, nil, nil, nil, nil, nil},
    {"How does transmogrification work?", nil, nil, nil, nil, nil, nil, nil, nil}, -- 25
}

local function LocText(id, p) -- "%s":format("test")
    if Locales[id] then
        local s = Locales[id][p:GetDbcLocale()+1] or Locales[id][1]
        if s then
            return s
        end
    end
    return "Text not found: "..(id or 0)
end
--[[
typedef UNORDERED_MAP<uint32, uint32> transmogData
typedef UNORDERED_MAP<uint32, transmogData> transmogMap
static transmogMap entryMap -- entryMap[pGUID][iGUID] = entry
static transmogData dataMap -- dataMap[iGUID] = pGUID
]]
local entryMap = {}
local dataMap = {}

local function GetSlotName(slot, locale)
    if not SlotNames[slot] then return end
    return locale and SlotNames[slot][locale+1] or SlotNames[slot][1]
end

local function GetFakePrice(item)
    local sellPrice = item:GetSellPrice()
    local minPrice = 10000
    if sellPrice < minPrice then
        sellPrice = minPrice
    end
    return sellPrice
end

function GetSpecialPrice(newItem)
    local cost = newItem:GetSellPrice()
    if cost < 10000 then
        cost = 10000
    end
    return cost
end

local function GetFakeEntry(item)
    local guid = item and item:GetGUIDLow()
    if guid and dataMap[guid] then
        if entryMap[dataMap[guid]] then
            return entryMap[dataMap[guid]][guid]
        end
    end
end

local function DeleteFakeFromDB(itemGUID)
    if dataMap[itemGUID] then
        if entryMap[dataMap[itemGUID]] then
            entryMap[dataMap[itemGUID]][itemGUID] = nil
        end
        dataMap[itemGUID] = nil
    end
    CharDBExecute("DELETE FROM acore_eluna.custom_transmogrification WHERE GUID = "..itemGUID)
end

local function DeleteFakeEntry(item)
    if not GetFakeEntry(item) then
        return false
    end
    item:GetOwner():UpdateUInt32Value(PLAYER_VISIBLE_ITEM_1_ENTRYID + (item:GetSlot() * ITEM_SLOT_MULTIPLIER), item:GetEntry())
    DeleteFakeFromDB(item:GetGUIDLow())
    return true
end

local function SetFakeEntry(item, entry)
    local player = item:GetOwner()
    if player then
        local pGUID = player:GetGUIDLow()
        local iGUID = item:GetGUIDLow()
        player:UpdateUInt32Value(PLAYER_VISIBLE_ITEM_1_ENTRYID + (item:GetSlot() * ITEM_SLOT_MULTIPLIER), entry)
        if not entryMap[pGUID] then
            entryMap[pGUID] = {}
        end
        entryMap[pGUID][iGUID] = entry
        dataMap[iGUID] = pGUID
        CharDBExecute("REPLACE INTO acore_eluna.custom_transmogrification (GUID, FakeEntry, Owner) VALUES ("..iGUID..", "..entry..", "..pGUID..")")
    end
end

local function IsRangedWeapon(Class, SubClass)
    return Class == ITEM_CLASS_WEAPON and (
    SubClass == ITEM_SUBCLASS_WEAPON_BOW or
    SubClass == ITEM_SUBCLASS_WEAPON_GUN or
    SubClass == ITEM_SUBCLASS_WEAPON_THROWN or
    SubClass == ITEM_SUBCLASS_WEAPON_CROSSBOW)
end

local function SuitableForTransmogrification(player, transmogrified, transmogrifier)
    if not transmogrified or not transmogrifier then
        return false
    end
    if not Qualities[transmogrifier:GetQuality()] then
        return false
    end
    if not Qualities[transmogrified:GetQuality()] then
        return false
    end
    if transmogrified:GetDisplayId() == transmogrifier:GetDisplayId() then
        return false
    end
    local fentry = GetFakeEntry(transmogrified)
    if fentry and fentry == transmogrifier:GetEntry() then
        return false
    end
    if not player:CanUseItem(transmogrifier) and not AllowUnusable then
        return false
    end
    local fierClass = transmogrifier:GetClass()
    local fiedClass = transmogrified:GetClass()
    local fierSubClass = transmogrifier:GetSubClass()
    local fiedSubClass = transmogrified:GetSubClass()
    local fierInventoryType = transmogrifier:GetInventoryType()
    local fiedInventoryType = transmogrified:GetInventoryType()
    
    -- Check for invalid inventory types
    if fiedInventoryType == INVTYPE_BAG or
    fiedInventoryType == INVTYPE_RELIC or
    fiedInventoryType == INVTYPE_FINGER or
    fiedInventoryType == INVTYPE_TRINKET or
    fiedInventoryType == INVTYPE_AMMO or
    fiedInventoryType == INVTYPE_QUIVER then
        return false
    end
    if fierInventoryType == INVTYPE_BAG or
    fierInventoryType == INVTYPE_RELIC or -- Mostly nick :) - Not sure if this is working properly, I keep seeing librams
    fierInventoryType == INVTYPE_FINGER or
    fierInventoryType == INVTYPE_TRINKET or
    fierInventoryType == INVTYPE_AMMO or
    fierInventoryType == INVTYPE_QUIVER then
        return false
    end
    
    -- Extended relic filters re invtype check above. Relics/idols/librams/totems/sigils are still included despite invtype_relic filter
    if
    (fierClass == ITEM_CLASS_ARMOR and fierSubClass == 7) or 
    (fierClass == ITEM_CLASS_ARMOR and fierSubClass == 8) or
    (fierClass == ITEM_CLASS_ARMOR and fierSubClass == 9) or
    (fierClass == ITEM_CLASS_ARMOR and fierSubClass == 10) then
        return false
    end
    
    if AllowMixedWeaponsAndOffhands then
        if ((fierClass == ITEM_CLASS_WEAPON and fiedInventoryType == INVTYPE_HELDOFFHAND) or
           (fiedClass == ITEM_CLASS_WEAPON and fierInventoryType == INVTYPE_HELDOFFHAND)) or
           ((fierClass == ITEM_CLASS_ARMOR and fierSubClass == ITEM_SUBCLASS_SHIELD and fiedInventoryType == INVTYPE_HELDOFFHAND) or
           (fiedClass == ITEM_CLASS_ARMOR and fiedSubClass == ITEM_SUBCLASS_SHIELD and fierInventoryType == INVTYPE_HELDOFFHAND)) then
            return true
        end
    end
    
    if fierClass ~= fiedClass then
        if fierClass ~= ITEM_CLASS_WEAPON and fierClass ~= ITEM_CLASS_ARMOR then
            return false
        end
        if fiedClass ~= ITEM_CLASS_WEAPON and fiedClass ~= ITEM_CLASS_ARMOR then
            return false
        end
        if AllowWeaponOnShield then
           if fierClass == ITEM_CLASS_WEAPON and fiedClass == ITEM_CLASS_ARMOR and fiedSubClass == ITEM_SUBCLASS_SHIELD then
                return true
           end
        end
        return false
    end
    
    if IsRangedWeapon(fiedClass, fiedSubClass) ~= IsRangedWeapon(fierClass, fierSubClass) then
        return false
    end
    
    if fierSubClass ~= fiedSubClass and not IsRangedWeapon(fiedClass, fiedSubClass) then
        if fierClass == ITEM_CLASS_ARMOR and not AllowMixedArmorTypes then
            return false
        end
        if fierClass == ITEM_CLASS_WEAPON and not AllowMixedWeaponTypes then
            return false
        end
    end
    
    if (fierInventoryType ~= fiedInventoryType) then
        if (fierClass == ITEM_CLASS_WEAPON and not ((IsRangedWeapon(fiedClass, fiedSubClass) or
            ((fiedInventoryType == INVTYPE_WEAPON or fiedInventoryType == INVTYPE_2HWEAPON
            or fiedInventoryType == INVTYPE_WEAPONOFFHAND or fiedInventoryType == INVTYPE_HELDOFFHAND) and
                (fierInventoryType == INVTYPE_WEAPON or fierInventoryType == INVTYPE_2HWEAPON
                or fierInventoryType == INVTYPE_WEAPONOFFHAND or fierInventoryType == INVTYPE_HELDOFFHAND)) or
            ((fiedInventoryType == INVTYPE_WEAPONMAINHAND or fiedInventoryType == INVTYPE_2HWEAPON
            or fiedInventoryType == INVTYPE_WEAPONOFFHAND or fiedInventoryType == INVTYPE_HELDOFFHAND) and
                (fierInventoryType == INVTYPE_WEAPON or fierInventoryType == INVTYPE_2HWEAPON
                or fierInventoryType == INVTYPE_WEAPONOFFHAND or fierInventoryType == INVTYPE_HELDOFFHAND))))) then
            if AllowMixedWeaponTypes then
                return true
            else
                return false
            end
        end
        if (fierClass == ITEM_CLASS_ARMOR and 
            not (((fierInventoryType == INVTYPE_CHEST or fierInventoryType == INVTYPE_ROBE) and 
                (fiedInventoryType == INVTYPE_CHEST or fiedInventoryType == INVTYPE_ROBE)) or
                (AllowMixedShieldsAndOffhands and
                (fierInventoryType == INVTYPE_SHIELD or fierInventoryType == INVTYPE_HELDOFFHAND) and
                (fiedInventoryType == INVTYPE_SHIELD or fiedInventoryType == INVTYPE_HELDOFFHAND)))) then 
            return false 
        end
    end
    return true
end

local menu_id = math.random(1000)

local sets = {}
function strsplit(delimiter, text)
    local result = {}
    for match in (text..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end
    
local function OnGossipHello(event, player, creature)
    player:GossipClearMenu()
    local guidlow = player:GetGUIDLow()
    player:GossipMenuAddItem(4, "|TInterface/ICONS/INV_Misc_Book_11:31:31:-24:0|t" .. LocText(20, player), HOW, 0)
    for slot = EQUIPMENT_SLOT_START, EQUIPMENT_SLOT_END-1 do
        local transmogrified = player:GetItemByPos(INVENTORY_SLOT_BAG_0, slot)  
        if transmogrified then
            if Qualities[transmogrified:GetQuality()] then
                local slotName = GetSlotName(slot, player:GetDbcLocale())
                if slotName then
                    local entry = transmogrified and GetFakeEntry(transmogrified) or 0
                    if entryMap[guidlow][transmogrified:GetEntry()] then
                        entry = entryMap[guidlow][transmogrified:GetEntry()]
                    end
                    local icon
                    if entry == 21 or entry == 1 then
                        icon = "Interface/ICONS/INV_Misc_QuestionMark"
                    elseif entry > 21 then
                        icon = "Interface/ICONS/" .. itemIconCache[entry] or "Interface/ICONS/INV_Misc_QuestionMark"  -- Use a default icon if not found in cache
                    else
                        icon = itemIconCache[slotName] or "Interface/ICONS/INV_Misc_QuestionMark"
                    end
                    
                    player:GossipMenuAddItem(3, "|T" .. icon .. ":31:31:-24:0|t".. slotName, EQUIPMENT_SLOT_END, slot)
                end
            end
        end
    end
    player:GossipMenuAddItem(4, "|TInterface/RAIDFRAME/UI-RAIDFRAME-MAINASSIST:31:31:-24:0|t" .. LocText(18, player), PRESETS, 0)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_enchant_disenchant:31:31:-24:0|t" .. LocText(2, player), EQUIPMENT_SLOT_END+2, 0, false, LocText(3, player), 0)
    player:GossipMenuAddItem(7, "|TInterface/PaperDollInfoFrame/UI-GearManager-Undo:31:31:-24:0|t" .. LocText(1, player), EQUIPMENT_SLOT_END+1, 0)
    player:GossipSendMenu(12, creature, menu_id)
end

local function OnGossipSelect(event, player, creature, slotid, uiAction, code)
    local lowGUID = player:GetGUIDLow()    
    
    if slotid == HOW then
        player:GossipMenuAddItem(4, "|TInterface/ICONS/INV_Misc_Book_11:31:31:-24:0|t" .. LocText(19, player), HOW, 0)
        player:GossipMenuAddItem(7, "|TInterface/ICONS/inv_misc_map_01:31:31:-24:0|t" .. LocText(6, player), EQUIPMENT_SLOT_END+1, 0)
        player:GossipSendMenu(12, creature, menu_id)
    
    elseif slotid == PRESETS then
        local guidlow = player:GetGUIDLow()
        local playername = player:GetName()
        
        local guidlow = player:GetGUIDLow()
        sets[guidlow] = {}
        
        CharDBQueryAsync("SELECT PresetID, SetName, SetData FROM acore_eluna.custom_transmogrification_sets WHERE Owner = " .. guidlow, -- Asyncing query as a hybrid between performance and load as I'm too lazy to create a dynamic cache
            function(result)
                local player
                for _, p in ipairs(GetStateMap():GetPlayers()) do
                    if p:GetName() == playername then player = p break end
                end
                if result then
                    local index = 1
                    repeat
                        local PresetID = result:GetString(0)
                        local setName = result:GetString(1)
                        local setData = result:GetString(2)
                        sets[guidlow][index] = {presetID = PresetID, name = setName, data = setData}
                        index = index + 1
                    until not result:NextRow()
                end
                local creature = player:GetNearestCreature(10, NPC_Entry) -- Refetching mog NPC
                if creature then
                
                    player:GossipMenuAddItem(2, "|TInterface/ICONS/INV_Misc_Book_11:31:31:-24:0|t" .. LocText(22, player), PRESETS + 1, 0)
            
                    for index, preset in ipairs(sets[guidlow] or {}) do
                        local presetID = preset.presetID
                        local presetName = preset.name
                        player:GossipMenuAddItem(3, "|TInterface/ICONS/INV_Misc_Statue_02:31:31:-24:0|t" .. presetName, PRESETS + 2, presetID)
                    end

                    if #sets[guidlow] < MaxSets then
                        player:GossipMenuAddItem(3, "|TInterface/GuildBankFrame/UI-GuildBankFrame-NewTab:31:31:-24:0|t" .. LocText(21, player), PRESETS + 3, 0)
                    end

                    player:GossipMenuAddItem(7, "|TInterface/ICONS/inv_misc_map_01:31:31:-24:0|t" .. LocText(6, player), EQUIPMENT_SLOT_END + 1, 0)
                    player:GossipSendMenu(12, creature, menu_id)
                end
            end
        )
        
    elseif slotid == PRESETS + 1 then
        player:GossipMenuAddItem(7, "|TInterface/ICONS/INV_Misc_Book_11:31:31:-24:0|t" .. LocText(23, player), PRESETS+1, 0)
        player:GossipMenuAddItem(7, "|TInterface/ICONS/inv_misc_map_01:31:31:-24:0|t" .. LocText(6, player), EQUIPMENT_SLOT_END + 1, 0)
        player:GossipSendMenu(12, creature, menu_id)
    
    elseif slotid == PRESETS + 2 then
        local guidlow = player:GetGUIDLow()
        local setspresent
        for index, preset in ipairs(sets[guidlow] or {}) do
            local presetID = preset.presetID
            local presetName = preset.name
            local presetData = preset.data
            if (presetID - uiAction) == 0 then
                local dataParts = {}
                for part in string.gmatch(presetData, "%S+") do
                    table.insert(dataParts, part)
                end
                for i = 1, #dataParts do
                    dataParts[i] = string.gsub(dataParts[i], "^%s*(.-)%s*$", "%1")
                    local num = tonumber(dataParts[i])
                    if num and num > 24 then
                        setspresent = true
                        local itemId = num
                        local icon
                        if itemId and itemIconCache[itemId] then
                            icon = "Interface/ICONS/" .. itemIconCache[itemId]
                        else
                            icon = "Interface/ICONS/INV_Misc_QuestionMark"
                        end
                        player:GossipMenuAddItem(4, "|T" .. icon .. ":31:31:-24:0|t" .. GetItemLink(itemId), PRESETS + 2, 0)
                    end
                end
                player:GossipMenuAddItem(3, "|TInterface/ICONS/INV_Misc_Statue_02:31:31:-24:0|tUse this set", PRESETS + 21, presetID)
                player:GossipMenuAddItem(3, "|TInterface/PaperDollInfoFrame/UI-GearManager-LeaveItem-Opaque:31:31:-24:0|tDelete set", PRESETS + 22, presetID, false, "Are you sure you want to delete "..presetName.."?")
                break
            end
        end
        
        if not setspresent then
            player:GossipMenuAddItem(7, "|TInterface/ICONS/INV_Misc_Book_11:31:31:-24:0|tNo items found.", PRESETS + 1, 0)
        end
        
        player:GossipMenuAddItem(7, "|TInterface/ICONS/inv_misc_map_01:31:31:-24:0|t" .. LocText(6, player), EQUIPMENT_SLOT_END + 1, 0)
        player:GossipSendMenu(12, creature, menu_id)
    
    elseif slotid == PRESETS + 22 then
        local presetID = uiAction
        local guidlow = player:GetGUIDLow()
        if presetID then
            CharDBExecute("DELETE FROM acore_eluna.custom_transmogrification_sets WHERE Owner = " .. guidlow .. " AND PresetID = " .. presetID)
        end
        OnGossipHello(event, player, creature)
    
    elseif slotid == PRESETS + 21 then
        local guidlow = player:GetGUIDLow()
        for index, preset in ipairs(sets[guidlow] or {}) do
            local presetID = preset.presetID
            local presetName = preset.name
            local presetData = preset.data
            if (presetID - uiAction) == 0 then
                local dataParts = {}
                for part in string.gmatch(presetData, "%S+") do
                    table.insert(dataParts, part)
                end
                for i = 1, #dataParts, 2 do
                    local slot = tonumber(dataParts[i])
                    local itemID = tonumber(dataParts[i + 1])
                    
                    if slot and itemID then
                        local transmogrified = player:GetItemByPos(INVENTORY_SLOT_BAG_0, slot)  
                        SetFakeEntry(transmogrified, itemID)
                    end
                end
                player:EmoteState(66)
                player:RegisterEvent(function(eventId, delay, repeats, player) -- Hack to fix non-updating item display IDs
                    player:EmoteState(0)
                end, 1, 10)
                break
            end
        end
        OnGossipHello(event, player, creature)
    elseif slotid == PRESETS + 3 then
        local cost = 0
        for itemslot = EQUIPMENT_SLOT_START, EQUIPMENT_SLOT_END-1 do
            local transmogrified = player:GetItemByPos(INVENTORY_SLOT_BAG_0, itemslot)  
            if transmogrified then
                if Qualities[transmogrified:GetQuality()] then
                    local slotName = GetSlotName(itemslot, player:GetDbcLocale())
                    if slotName then
                        local entry = transmogrified and GetFakeEntry(transmogrified) or 0
                        local icon
                        if entry ~= 0 then
                            local icon
                            if entry == 1 or entry == 21 then
                                icon = "Interface/ICONS/INV_Misc_QuestionMark"
                            else
                                icon = "Interface/ICONS/" .. itemIconCache[entry] or "Interface/ICONS/INV_Misc_QuestionMark"
                            end
                            cost = cost + GetSpecialPrice(transmogrified)
                            local itemId = transmogrified:GetEntry()
                            player:GossipMenuAddItem(3, "|T" .. icon .. ":31:31:-24:0|t".. slotName, PRESETS + 3, 0)
                        end
                    end
                end
            end
        end
        player:GossipMenuAddItem(3, "|TInterface/GuildBankFrame/UI-GuildBankFrame-NewTab:31:31:-24:0|t" .. LocText(21, player), PRESETS + 30, 1, "Insert set name", "Are you sure you want to save this set?\nIt will cost you:",  cost * SetCostModifier)
        player:GossipMenuAddItem(7, "|TInterface/PaperDollInfoFrame/UI-GearManager-Undo:31:31:-24:0|t" .. LocText(1, player), PRESETS + 3, 0)
        player:GossipMenuAddItem(7, "|TInterface/ICONS/inv_misc_map_01:31:31:-24:0|t" .. LocText(6, player), PRESETS, 0)
        player:GossipSendMenu(12, creature, menu_id)
    
    elseif slotid == PRESETS + 30 then
        local name = code
        local presetID 
        local guid = player:GetGUIDLow()
        local playername = player:GetName()
        
        CharDBQueryAsync("SELECT MAX(PresetID) as PresetID FROM acore_eluna.custom_transmogrification_sets WHERE Owner = " .. guid,
            function(query)
                local player
                for _, p in ipairs(GetStateMap():GetPlayers()) do
                    if p:GetName() == playername then player = p break end
                end
                local presetID = 1
                if query then
                    local row = query:GetRow()
                    if row and row["PresetID"] then
                        presetID = tonumber(row["PresetID"]) + 1
                    end
                end
                
                local setData = {}
                for itemslot = EQUIPMENT_SLOT_START, EQUIPMENT_SLOT_END-1 do
                    local transmogrified = player:GetItemByPos(INVENTORY_SLOT_BAG_0, itemslot)
                    if transmogrified then
                        local entry = GetFakeEntry(transmogrified) or 0
                        if entry ~= 0 then
                            setData[itemslot] = entry
                        end
                    end
                end
                
                local setDataString = ""
                for slot, entry in pairs(setData) do
                    setDataString = setDataString .. slot .. " " .. entry .. " "
                end
                
                CharDBExecute(string.format(
                    "INSERT INTO acore_eluna.custom_transmogrification_sets (`Owner`, `PresetID`, `SetName`, `SetData`) VALUES (%d, %d, '%s', '%s')",
                    guid,
                    presetID,
                    name,
                    setDataString
                ))
                
                player:SendBroadcastMessage("Transmog set '" .. name .. "' saved successfully!")  
            end
        )
        
        OnGossipHello(event, player, creature)
            
    elseif slotid == HIDE then
        local slot = uiAction
        local transmogrified = player:GetItemByPos(INVENTORY_SLOT_BAG_0, uiAction)
        local pGUID = player:GetGUIDLow()
        local iGUID = transmogrified:GetGUIDLow()
        local entry = 21
        player:UpdateUInt32Value(PLAYER_VISIBLE_ITEM_1_ENTRYID + (slot * ITEM_SLOT_MULTIPLIER), 1)
        if not entryMap[pGUID] then
            entryMap[pGUID] = {}
        end
        entryMap[pGUID][iGUID] = entry
        dataMap[iGUID] = pGUID
        CharDBExecute("REPLACE INTO acore_eluna.custom_transmogrification (GUID, FakeEntry, Owner) VALUES ("..iGUID..", 21, "..pGUID..")")

        player:EmoteState(66)
        player:RegisterEvent(function(eventId, delay, repeats, player) -- Hack to fix non-updating item display IDs
            player:EmoteState(0)
        end, 1, 1)
        
        OnGossipHello(event, player, creature)
    elseif slotid == EQUIPMENT_SLOT_END then -- Show items you can use
        local transmogrified = player:GetItemByPos(INVENTORY_SLOT_BAG_0, uiAction)
        local slot = uiAction
        if transmogrified then
            _items[lowGUID] = {} -- Remove this with logix
            local limit = 0
            local price = 0
            if RequireGold == 1 then
                price = GetFakePrice(transmogrified)*GoldModifier
            elseif RequireGold == 2 then
                price = GoldCost
            end
            player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_enggizmos_27:31:31:-24:0|tHide Slot", HIDE, slot, false, "You are hiding the item in this slot.\n \nDo you wish to continue?")

            for i = INVENTORY_SLOT_ITEM_START, INVENTORY_SLOT_ITEM_END-1 do
                if limit > 30 then
                    break
                end
                local transmogrifier = player:GetItemByPos(INVENTORY_SLOT_BAG_0, i)
                if transmogrifier then
                    local display = transmogrifier:GetDisplayId()
                    if SuitableForTransmogrification(player, transmogrified, transmogrifier) then
                        if not _items[lowGUID][display] then
                            itemId = transmogrifier:GetEntry()
                            icon = "Interface/ICONS/" .. itemIconCache[itemId] or "Interface/ICONS/INV_Misc_QuestionMark" 
                            limit = limit + 1
                            _items[lowGUID][display] = {transmogrifier:GetBagSlot(), transmogrifier:GetSlot()}
                            local popup = LocText(4, player).."\n |T" .. icon .. ":31:31:-24:-10|t".. transmogrifier:GetName(player:GetDbcLocale()).." \n \n \n"
                            if RequireToken then
                                popup = popup.."\n"..TokenAmount.." x "..GetName(TokenEntry, player:GetDbcLocale())
                            end
                            player:GossipMenuAddItem(4, "|T" .. icon .. ":31:31:-24:0|t" .. transmogrifier:GetName(player:GetDbcLocale()), uiAction, display, false, popup, price)
                        end
                    end
                end
            end

            for i = INVENTORY_SLOT_BAG_START, INVENTORY_SLOT_BAG_END-1 do
                local bag = player:GetItemByPos(INVENTORY_SLOT_BAG_0, i)
                if bag then
                    for j = 0, bag:GetBagSize()-1 do
                        if limit > 30 then
                            break
                        end
                        local transmogrifier = player:GetItemByPos(i, j)
                        if transmogrifier then
                            local display = transmogrifier:GetDisplayId()
                            if SuitableForTransmogrification(player, transmogrified, transmogrifier) then
                                if not _items[lowGUID][display] then
                                    itemId = transmogrifier:GetEntry()
                                    icon = "Interface/ICONS/" .. itemIconCache[itemId] or "Interface/ICONS/INV_Misc_QuestionMark" 
                                    limit = limit + 1
                                    _items[lowGUID][display] = {transmogrifier:GetBagSlot(), transmogrifier:GetSlot()}
                                    local popup = LocText(4, player).."\n |T" .. icon .. ":31:31:-24:-10|t".. transmogrifier:GetName(player:GetDbcLocale()).." \n \n \n"
                                    if RequireToken then
                                        popup = popup.."\n"..TokenAmount.." x "..GetName(TokenEntry, player:GetDbcLocale())
                                    end
                                    player:GossipMenuAddItem(4, "|T" .. icon .. ":31:31:-24:0|t" .. transmogrifier:GetName(player:GetDbcLocale()), uiAction, display, false, popup, price)
                                end
                            end
                        end
                    end
                end
            end

            player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_enchant_disenchant:31:31:-24:0|t" .. LocText(7, player), EQUIPMENT_SLOT_END+3, uiAction, false, LocText(5, player):format(GetSlotName(uiAction, player:GetDbcLocale())))
            player:GossipMenuAddItem(7, "|TInterface/ICONS/inv_misc_map_01:31:31:-24:0|t" .. LocText(6, player), EQUIPMENT_SLOT_END+1, 0)
            player:GossipSendMenu(12, creature, menu_id)
        else
            OnGossipHello(event, player, creature)
        end
    elseif slotid == EQUIPMENT_SLOT_END+1 then -- Back
        OnGossipHello(event, player, creature)
    elseif slotid == EQUIPMENT_SLOT_END+2 then -- Remove Transmogrifications
        local removed = false
        for slot = EQUIPMENT_SLOT_START, EQUIPMENT_SLOT_END-1 do
            local transmogrifier = player:GetItemByPos(INVENTORY_SLOT_BAG_0, slot)
            if transmogrifier then
                if DeleteFakeEntry(transmogrifier) and not removed then
                    removed = true
                end
            end
        end
        if removed then
            player:SendAreaTriggerMessage(LocText(8, player))
            -- player:PlayDirectSound(3337)
        else
            player:SendNotification(LocText(9, player))
        end
        player:EmoteState(66)
        player:RegisterEvent(function(eventId, delay, repeats, player) -- Hack to fix non-updating item display IDs
            player:EmoteState(0)
        end, 1, 1)
        OnGossipHello(event, player, creature)
    elseif slotid == EQUIPMENT_SLOT_END+3 then -- Remove Transmogrification from single item
        local transmogrifier = player:GetItemByPos(INVENTORY_SLOT_BAG_0, uiAction)
        if transmogrifier then
            if DeleteFakeEntry(transmogrifier) then
                print(transmogrifier:GetName())
                player:SendAreaTriggerMessage(LocText(10, player):format(GetSlotName(uiAction, player:GetDbcLocale())))
                --player:PlayDirectSound(3337)
                player:EmoteState(66)
                player:RegisterEvent(function(eventId, delay, repeats, player) -- Hack to fix non-updating item display IDs
                    player:EmoteState(0)
                end, 1, 1)
            else
                player:SendNotification(LocText(11, player):format(GetSlotName(uiAction, player:GetDbcLocale())))
            end
        end
        OnGossipSelect(event, player, creature, EQUIPMENT_SLOT_END, uiAction)
    else -- Transmogrify
        local lowGUID = player:GetGUIDLow()
        if not RequireToken or player:GetItemCount(TokenEntry) >= TokenAmount then
            local transmogrified = player:GetItemByPos(INVENTORY_SLOT_BAG_0, slotid)
            if transmogrified then
                if _items[lowGUID] and _items[lowGUID][uiAction] and _items[lowGUID][uiAction] then
                    local transmogrifier = player:GetItemByPos(_items[lowGUID][uiAction][1], _items[lowGUID][uiAction][2])
                    if transmogrifier:GetOwnerGUID() == player:GetGUID() and (transmogrifier:IsInBag() or transmogrifier:GetBagSlot() == INVENTORY_SLOT_BAG_0) and SuitableForTransmogrification(player, transmogrified, transmogrifier) then
                        local price
                        if RequireGold == 1 then
                            price = GetFakePrice(transmogrified)*GoldModifier
                        elseif RequireGold == 2 then
                            price = GoldCost
                        end
                        if not price or player:GetCoinage() >= price then
                            if price then
                                player:ModifyMoney(-price)
                            end
                            if RequireToken then
                                player:RemoveItem(TokenEntry, TokenAmount)
                            end
                            SetFakeEntry(transmogrified, transmogrifier:GetEntry())
                            -- transmogrifier:SetNotRefundable(player)
                            transmogrifier:SetBinding(true)
                            -- player:PlayDirectSound(3337)
                            player:SendAreaTriggerMessage(LocText(12, player):format(GetSlotName(slotid, player:GetDbcLocale())))
                        else
                            player:SendNotification(LocText(17, player))
                        end
                    else
                        player:SendNotification(LocText(13, player))
                    end
                else
                    player:SendNotification(LocText(14, player))
                end
            else
                player:SendNotification(LocText(15, player))
            end
        else
            player:SendNotification(LocText(16, player):format(GetName(TokenEntry, player:GetDbcLocale())))
        end
        _items[lowGUID] = {}
        OnGossipSelect(event, player, creature, EQUIPMENT_SLOT_END, slotid)
    end
end

local applyMogOnMapChange = {}

local function OnLogin(event, player)
    local playerGUID = player:GetGUIDLow()
    if event == 28 and not applyMogOnMapChange[playerGUID] then
        return
    end
    local playername = player:GetName()
    applyMogOnMapChange[playerGUID] = nil
    
    entryMap[playerGUID] = {}
    CharDBQueryAsync("SELECT GUID, FakeEntry FROM acore_eluna.custom_transmogrification WHERE Owner = "..playerGUID, function(result)
        local player
        for _, p in ipairs(GetStateMap():GetPlayers()) do
            if p:GetName() == playername then player = p break end
        end
        if result then
            repeat
                local itemGUID = result:GetUInt32(0)
                local fakeEntry = result:GetUInt32(1)
                dataMap[itemGUID] = playerGUID
                entryMap[playerGUID][itemGUID] = fakeEntry
            until not result:NextRow()

            for slot = EQUIPMENT_SLOT_START, EQUIPMENT_SLOT_END-1 do
                if not player then
                    applyMogOnMapChange[playerGUID] = true
                    return
                end
                local item = player:GetItemByPos(INVENTORY_SLOT_BAG_0, slot)
                if item then
                    if entryMap[playerGUID] then
                        if entryMap[playerGUID][item:GetGUIDLow()] then
                            player:SetUInt32Value(PLAYER_VISIBLE_ITEM_1_ENTRYID + (item:GetSlot() * ITEM_SLOT_MULTIPLIER), entryMap[playerGUID][item:GetGUIDLow()])
                        end
                    end
                end
            end
        end
    end)
end

local function OnLogout(event, player)
    local pGUID = player:GetGUIDLow()
    entryMap[pGUID] = nil
end

local function OnEquip(event, player, item, bag, slot)
    local fentry = GetFakeEntry(item)
    if fentry then
        if item:GetOwnerGUID() ~= player:GetGUID() then
            DeleteFakeFromDB(item:GetGUIDLow())
            return
        end
        player:SetUInt32Value(PLAYER_VISIBLE_ITEM_1_ENTRYID + (slot * ITEM_SLOT_MULTIPLIER), fentry)
    end
end

if PrepareDBTable then
    CharDBQuery([[CREATE TABLE IF NOT EXISTS acore_eluna.custom_transmogrification (`GUID` INT(10) UNSIGNED NOT NULL, `FakeEntry` INT(10) UNSIGNED NOT NULL, `Owner` INT(10) UNSIGNED NOT NULL, PRIMARY KEY (`GUID`));]])
    CharDBQuery("DELETE FROM acore_eluna.custom_transmogrification WHERE NOT EXISTS (SELECT 1 FROM item_instance WHERE item_instance.guid = custom_transmogrification.GUID)")
end

---------------------------------------------------------------------------------
-- Transmog item vendor script start
---------------------------------------------------------------------------------

local slotTypes = {
	[10000] = {name = "Head", inventoryType = 1},
	[11000] = {name = "Shoulder", inventoryType = 3},
	[12000] = {name = "Shirt", inventoryType = 4},
	[13000] = {name = "Waist", inventoryType = 6},
	[14000] = {name = "Legs", inventoryType = 7},
	[15000] = {name = "Feet", inventoryType = 8},
	[16000] = {name = "Wrists", inventoryType = 9},
	[18000] = {name = "Hands", inventoryType = 10},
	[19000] = {name = "Back", inventoryType = 16},
	[20000] = {name = "Weapon", inventoryType = {13, 17, 21, 22, 26}},
	[21000] = {name = "Off-hand", inventoryType = {22, 23}},
	[22000] = {name = "Shield", inventoryType = 14},
	[23000] = {name = "Ranged", inventoryType = {15, 26}}
}

function ItemCache.LoadCache()
	ItemCache["Cache"] = {}
	ItemCache["Allowed"] = {}

	local baseRows = {}
	local pending = 12
	local allowed = ItemCache["Allowed"]

	local function done()
		pending = pending - 1
		if pending > 0 then
			return
		end
		local i = 1
		for _, row in ipairs(baseRows) do
			if allowed[row.entry] then
				ItemCache["Cache"][i] = row
				i = i + 1
			end
		end
		table.sort(ItemCache["Cache"], function(a, b)
			return a.name < b.name
		end)
		baseRows = nil
		SetWorldData("TransmogItemCache", {cache = ItemCache["Cache"]})
	end

	local function collectIds(result)
		if result then
			repeat
				local id = result:GetInt32(0)
				if id > 0 then
					allowed[id] = true
				end
			until not result:NextRow()
		end
	end

	-- 1. all items from drops, one query per loot table
	for _, lootTable in ipairs({"creature_loot_template", "gameobject_loot_template", "item_loot_template", "reference_loot_template", "spell_loot_template", "mail_loot_template", "fishing_loot_template"}) do
		local tbl = lootTable
		WorldDBQueryAsync("SELECT DISTINCT Item FROM "..tbl, function(result)
			collectIds(result)
			done()
		end)
	end

	-- 2. all items from npc vendors (blizzlike vendors only, skip custom 100000+ entries)
	WorldDBQueryAsync("SELECT DISTINCT item FROM npc_vendor WHERE entry < 100000", function(result)
		collectIds(result)
		done()
	end)

	-- 3. all items from achis
	WorldDBQueryAsync("SELECT DISTINCT ItemID FROM achievement_reward WHERE ItemID <> 0", function(result)
		collectIds(result)
		done()
	end)

	-- 4. all items from spells (Effect 24 = CREATE_ITEM, matched in Lua)
	WorldDBQueryAsync("SELECT Effect_1, EffectItemType_1, Effect_2, EffectItemType_2, Effect_3, EffectItemType_3 FROM spell_dbc WHERE Effect_1 = 24 OR Effect_2 = 24 OR Effect_3 = 24", function(result)
		if result then
			repeat
				if result:GetUInt32(0) == 24 and result:GetUInt32(1) ~= 0 then
					allowed[result:GetUInt32(1)] = true
				end
				if result:GetUInt32(2) == 24 and result:GetUInt32(3) ~= 0 then
					allowed[result:GetUInt32(3)] = true
				end
				if result:GetUInt32(4) == 24 and result:GetUInt32(5) ~= 0 then
					allowed[result:GetUInt32(5)] = true
				end
			until not result:NextRow()
		end
		done()
	end)

	-- x. any other source: quest rewards and quest choices
	WorldDBQueryAsync("SELECT RewardItem1, RewardItem2, RewardItem3, RewardItem4, RewardChoiceItemID1, RewardChoiceItemID2, RewardChoiceItemID3, RewardChoiceItemID4, RewardChoiceItemID5, RewardChoiceItemID6 FROM quest_template", function(result)
		if result then
			repeat
				for col = 0, 9 do
					local id = result:GetUInt32(col)
					if id ~= 0 then
						allowed[id] = true
					end
				end
			until not result:NextRow()
		end
		done()
	end)

	-- 5. all candidate item IDs from item_template, overlap math happens in done()
	WorldDBQueryAsync("SELECT entry, class, name, subclass, InventoryType, ItemLevel, RequiredLevel, Quality, maxcount FROM item_template WHERE ((InventoryType>0 AND InventoryType NOT IN (28, 27, 24, 18, 19, 12) AND ItemLevel < 200) OR (Name LIKE '%frostmourne%' AND ItemLevel < 201)) AND name NOT LIKE '%deprecated%' AND (Flags & 16) = 0 AND Quality NOT IN (6, 7) AND name NOT LIKE '%Sword2H, Corrupted%' AND name NOT LIKE '%Tigole%'", function(result)
		if result then
			repeat
				local name = result:GetString(2)
				if not (name:find("%(") or name:find("%)") or
						name:find("%[") or name:find("%]") or
						name:lower():find("unused") or name:lower():find("test")) then
					table.insert(baseRows, {
						entry = result:GetUInt32(0),
						class = result:GetUInt32(1),
						name = name,
						subclass = result:GetUInt32(3),
						InventoryType = result:GetUInt32(4),
						itemLevel = result:GetUInt32(5),
						level = result:GetUInt32(6),
						quality = result:GetUInt32(7),
						maxcount = result:GetUInt32(8)
					})
				end
			until not result:NextRow()
		end
		done()
	end)
end

local function GetItemsByClassAndSubclass(class, subclass)
	local items = {}
	for _, item in pairs(ItemCache["Cache"]) do
		if item.class == class and item.subclass == subclass then
			table.insert(items, item)
		end
	end
	return items
end

local function PlayerHasEnoughFreeSlots(player, requiredSlots)
	local freeSlots = 0

	for slot = 23, 38 do
		local item = player:GetItemByPos(255, slot)
		if not item then
			freeSlots = freeSlots + 1
		end
	end

	for bag = 19, 22 do
		local bagItem = player:GetItemByPos(255, bag)
		if bagItem then
			local bagSize = bagItem:GetBagSize()
			for slot = 0, bagSize - 1 do
				local item = player:GetItemByPos(bag, slot)
				if not item then
					freeSlots = freeSlots + 1
				end
			end
		end
	end

	--print("Total free slots found: " .. freeSlots)
	return freeSlots >= requiredSlots
end

local function PlayerHasEnoughCurrency(player, cost)
	local playerCurrency = player:GetItemCount(CURRENCY_ID)
	return playerCurrency >= cost
end

function ItemCache.GenerateSearchMenu(player, object, currentPage)
    local searchTerm = currentSearchTerm or " "
    
    local results = {}
    for _, item in ipairs(ItemCache["Cache"]) do
        if item.name:lower():find(searchTerm:lower()) then
            table.insert(results, {
                name = item.name,
                entry = item.entry
            })
        end
    end
    
    local low = (itemsPerPage * (currentPage - 1)) + 1
    local high = math.min(itemsPerPage * currentPage, #results)
    
    player:GossipClearMenu()
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_spyglass_01:31:31:-24:0|tCurrent search: " .. currentSearchTerm, 0, 9000000 + currentPage)
    for i = low, high do
        local item = results[i]
        if item then
            player:GossipMenuAddItem(4, "|TInterface/ICONS/" .. itemIconCache[item.entry] .. ":31:31:-24:0|t" .. item.name, 0, 2000000 + item.entry)
        end
    end
	
	if currentPage > 1 then
		player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_spy:31:31:-24:0|tPrevious page", 9000000 + currentPage, 9000000 + currentPage - 1)
	end
	
	if high < #results then
		player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_spy:31:31:-24:0|tNext page", 9000000 + currentPage, 9000000 + currentPage + 1)
	end
	
    player:GossipMenuAddItem(4, "|TInterface/ICONS/trade_engineering:31:31:-24:0|tBack to main menu", 0, 0)
	player:GossipSendMenu(12, object)
end

local function ArmorTypeFilter(class, subclass)
	local filteredItems = {}
	for _, item in pairs(ItemCache["Cache"]) do
		if item.class == class and item.subclass == subclass then
			table.insert(filteredItems, item)
		end
	end
	return filteredItems
end

local function SlotTypeFilter(inventoryType)
	local filteredItems = {}
	local itemCount = 0
	local matchingItems = 0

	for _, item in pairs(ItemCache["Cache"]) do
		itemCount = itemCount + 1
		 if type(inventoryType) == "table" then
			for _, invType in ipairs(inventoryType) do
				if item.InventoryType == invType then
					table.insert(filteredItems, item)
					matchingItems = matchingItems + 1
					break
				end
			end
		elseif item.InventoryType == inventoryType then
			table.insert(filteredItems, item)
			matchingItems = matchingItems + 1
		end
	end
	
	if itemCount == 0 then
		print("Warning: ItemCache['Cache'] is empty!")
	elseif matchingItems == 0 then
		print("Warning: No items match the specified inventoryType: " .. tostring(inventoryType))
	end

	return filteredItems
end

function DisplayArmorItems(player, object, items, currentIntid)
	local itemsPerPage = 10
	local baseIntid = math.floor(currentIntid / 100) * 100
	local page = (currentIntid - baseIntid) + 1
	
	if items and #items > 0 then
		local totalPages = math.ceil(#items / itemsPerPage)
		player:GossipClearMenu()
		local startIndex = (page - 1) * itemsPerPage + 1
		local endIndex = math.min(page * itemsPerPage, #items)
		for i = startIndex, endIndex do
			local item = items[i]
			if item and item.name and item.entry then
				player:GossipMenuAddItem(1, "|TInterface/ICONS/" .. itemIconCache[item.entry] .. ":31:31:-24:0|t" .. item.name, 0, 2000000 + item.entry)
			end
		end
		-- Add pagination options
		if page > 1 then
			player:GossipMenuAddItem(7, "|TInterface/ICONS/ability_spy:31:31:-24:0|tPrevious Page", 0, baseIntid + page - 2)
		end
		if page < totalPages then
			player:GossipMenuAddItem(7, "|TInterface/ICONS/ability_spy:31:31:-24:0|tNext Page", 0, baseIntid + page)
		end
		player:GossipMenuAddItem(4, "|TInterface/ICONS/trade_engineering:31:31:-24:0|tBack", 0, 200)
		player:GossipSendMenu(12, object)
	else
		player:GossipClearMenu()
		player:GossipMenuAddItem(0, "|TInterface/ICONS/INV_Misc_QuestionMark:31:31:-24:0|tNo items found.", 0, 0)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/trade_engineering:31:31:-24:0|tBack", 0, 200)
		player:GossipSendMenu(12, object)
	end
end

function DisplaySlotItems(player, object, items, currentIntid)
	local itemsPerPage = 10
	local baseIntid = math.floor(currentIntid / 100) * 100
	local page = (currentIntid - baseIntid) + 1
	
	if items and #items > 0 then
		local totalPages = math.ceil(#items / itemsPerPage)
		player:GossipClearMenu()
		local startIndex = (page - 1) * itemsPerPage + 1
		local endIndex = math.min(page * itemsPerPage, #items)
		for i = startIndex, endIndex do
			local item = items[i]
			if item and item.name and item.entry then
				player:GossipMenuAddItem(1, "|TInterface/ICONS/" .. itemIconCache[item.entry] .. ":31:31:-24:0|t" .. item.name, 0, 2000000 + item.entry)
			end
		end
		if page > 1 then
			player:GossipMenuAddItem(7, "|TInterface/ICONS/ability_spy:31:31:-24:0|tPrevious Page", 0, baseIntid + page - 2)
		end
		if page < totalPages then
			player:GossipMenuAddItem(7, "|TInterface/ICONS/ability_spy:31:31:-24:0|tNext Page", 0, baseIntid + page)
		end
		player:GossipMenuAddItem(4, "|TInterface/ICONS/trade_engineering:31:31:-24:0|tBack", 0, 300)
		player:GossipSendMenu(12, object)
	else
		player:GossipClearMenu()
		player:GossipMenuAddItem(0, "|TInterface/ICONS/INV_Misc_QuestionMark:31:31:-24:0|tNo items found.", 0, 0)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/trade_engineering:31:31:-24:0|tBack", 0, 300)
		player:GossipSendMenu(12, object)
	end
end

local function MogVendorHello(event, player, object)
	player:GossipClearMenu()
	player:GossipMenuAddItem(0, "|TInterface/ICONS/INV_Misc_QuestionMark:31:31:-24:0|tGreetings, what can I do for you?", 0, 5000001)
	player:GossipMenuAddItem(1, "|TInterface/ICONS/inv_scroll_08:31:31:-24:0|tSearch by item name", 0, 6000000, true, "")
	player:GossipMenuAddItem(1, "|TInterface/ICONS/inv_chest_chain:31:31:-24:0|tSearch by armor type", 0, 200)
	player:GossipMenuAddItem(1, "|TInterface/PaperDoll/UI-PaperDoll-Slot-Shoulder:31:31:-24:0|tSearch by item slot", 0, 300)
	player:GossipSendMenu(12, object)
end

local function MogVendorSelect(event, player, object, sender, intid, code)
	if intid == 0 then
		return MogVendorHello(event, player, object)
	
	elseif intid > 9000000 then
		local searchTerm = currentSearchTerm or ""
		
		local results = {}
		for _, item in ipairs(ItemCache["Cache"]) do
			if item.name:lower():find(searchTerm) then
				table.insert(results, item)
			end
		end
		
		local page = intid - 9000000
		local startIndex = (page - 1) * itemsPerPage + 1
		local endIndex = math.min(startIndex + itemsPerPage - 1, #results)
	   
		player:GossipClearMenu()
		player:GossipMenuAddItem(4, "|TInterface/ICONS/trade_engineering:31:31:-24:0|tBack to main menu", 0, 0)
		
		for i = startIndex, endIndex do
			local item = results[i]
			if item then
				player:GossipMenuAddItem(1, "|TInterface/ICONS/" .. itemIconCache[item.entry] .. ":31:31:-24:0|t" .. item.name, 0, 2000000 + item.entry)
			end
		end
		
		if page > 1 then
			player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_spy:31:31:-24:0|tPrevious page", 9000000 + page, 9000000 + page - 1)
		end
		
		if endIndex < #results then
			player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_spy:31:31:-24:0|tNext page", 9000000 + page, 9000000 + page + 1)
		end
		
		player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_spyglass_01:31:31:-24:0|tCurrent search: " .. currentSearchTerm, 0, 9000000 + page)
		player:GossipSendMenu(12, object)
		
	elseif intid == 5000001 then
		player:GossipClearMenu()
		player:GossipMenuAddItem(0, "|TInterface/ICONS/INV_Misc_QuestionMark:31:31:-24:0|tGreetings, what can I do for you?\n \nI am the Ethereal Itemizer. I come from a realm with an unlimited supply of worldly and otherworldy goods, and I possess the ability to peer into the abyss to conjure items long forgotten. My skills are channeled into offering on-demand items for transmogrification. Any item can be inspected by requesting an inspection link before purchasing.\n \n ", 0, 5000001)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/trade_engineering:31:31:-24:0|tBack to main menu", 0, 0)
		player:GossipSendMenu(12, object)
		
	elseif intid == 5000003 then
        MogVendorHello(event, player, object)
        
	elseif intid == 200 then
		-- Main menu
		player:GossipClearMenu()
		player:GossipMenuAddItem(1, "|TInterface/ICONS/inv_chest_cloth_66:31:31:-24:0|tCloth", 0, 8900000)
		player:GossipMenuAddItem(1, "|TInterface/ICONS/inv_chest_leather_14:31:31:-24:0|tLeather", 0, 8800000)
		player:GossipMenuAddItem(1, "|TInterface/ICONS/inv_misc_desecrated_mailchest:31:31:-24:0|tMail", 0, 8700000)
		player:GossipMenuAddItem(1, "|TInterface/ICONS/inv_chest_plate15:31:31:-24:0|tPlate", 0, 8600000)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/trade_engineering:31:31:-24:0|tBack", 0, 5000003)
		player:GossipSendMenu(12, object)
	elseif intid >= 8900000 and intid < 9000000 then
		DisplayArmorItems(player, object, ArmorTypeFilter(4, 1), intid)
	elseif intid >= 8800000 and intid < 8900000 then
		DisplayArmorItems(player, object, ArmorTypeFilter(4, 2), intid)
	elseif intid >= 8700000 and intid < 8800000 then
		DisplayArmorItems(player, object, ArmorTypeFilter(4, 3), intid)
	elseif intid >= 8600000 and intid < 8700000 then
		DisplayArmorItems(player, object, ArmorTypeFilter(4, 4), intid)
	  
	elseif intid == 300 then
		player:GossipClearMenu()
		player:GossipMenuAddItem(1, "|TInterface/PaperDoll/UI-PaperDoll-Slot-Head:31:31:-24:0|tBrowse head", 0, 10000)
		player:GossipMenuAddItem(1, "|TInterface/PaperDoll/UI-PaperDoll-Slot-Shoulder:31:31:-24:0|tBrowse shoulder", 0, 11000)
		player:GossipMenuAddItem(1, "|TInterface/PaperDoll/UI-PaperDoll-Slot-Shirt:31:31:-24:0|tBrowse shirt", 0, 12000)
		player:GossipMenuAddItem(1, "|TInterface/PaperDoll/UI-PaperDoll-Slot-Chest:31:31:-24:0|tBrowse chest", 0, 24000)
		player:GossipMenuAddItem(1, "|TInterface/PaperDoll/UI-PaperDoll-Slot-Chest:31:31:-24:0|tBrowse waist", 0, 13000)
		player:GossipMenuAddItem(1, "|TInterface/PaperDoll/UI-PaperDoll-Slot-Legs:31:31:-24:0|tBrowse legs", 0, 14000)
		player:GossipMenuAddItem(1, "|TInterface/PaperDoll/UI-PaperDoll-Slot-Feet:31:31:-24:0|tBrowse feet", 0, 15000)
		player:GossipMenuAddItem(1, "|TInterface/PaperDoll/UI-PaperDoll-Slot-Wrists:31:31:-24:0|tBrowse wrists", 0, 16000)
		player:GossipMenuAddItem(1, "|TInterface/PaperDoll/UI-PaperDoll-Slot-Hands:31:31:-24:0|tBrowse hands", 0, 18000)
		player:GossipMenuAddItem(1, "|TInterface/PaperDoll/UI-PaperDoll-Slot-Chest:31:31:-24:0|tBrowse back", 0, 19000)
		player:GossipMenuAddItem(1, "|TInterface/PaperDoll/UI-PaperDoll-Slot-MainHand:31:31:-24:0|tBrowse weapon", 0, 20000)
		player:GossipMenuAddItem(1, "|TInterface/PaperDoll/UI-PaperDoll-Slot-SecondaryHand:31:31:-24:0|tBrowse off-hand", 0, 21000)
		player:GossipMenuAddItem(1, "|TInterface/PaperDoll/UI-PaperDoll-Slot-SecondaryHand:31:31:-24:0|tBrowse shield", 0, 22000)
		player:GossipMenuAddItem(1, "|TInterface/PaperDoll/UI-PaperDoll-Slot-Ranged:31:31:-24:0|tBrowse ranged", 0, 23000)
		player:GossipMenuAddItem(4, "|TInterface/ICONS/trade_engineering:31:31:-24:0|tBack", 0, 5000003)
		player:GossipSendMenu(12, object)
        
	elseif intid >= 10000 and intid < 11000 then
		local items = SlotTypeFilter(1)  -- Head
		DisplaySlotItems(player, object, items, intid, 10000)
	elseif intid >= 11000 and intid < 12000 then
		local items = SlotTypeFilter(3)  -- Shoulder
		DisplaySlotItems(player, object, items, intid, 11000)
	elseif intid >= 12000 and intid < 13000 then
		local items = SlotTypeFilter(4)  -- Shirt
		DisplaySlotItems(player, object, items, intid, 12000)
	elseif intid >= 13000 and intid < 14000 then
		local items = SlotTypeFilter(6)  -- Waist
		DisplaySlotItems(player, object, items, intid, 13000)
	elseif intid >= 14000 and intid < 15000 then
		local items = SlotTypeFilter(7)  -- Legs
		DisplaySlotItems(player, object, items, intid, 14000)
	elseif intid >= 15000 and intid < 16000 then
		local items = SlotTypeFilter(8)  -- Feet
		DisplaySlotItems(player, object, items, intid, 15000)
	elseif intid >= 16000 and intid < 17000 then
		local items = SlotTypeFilter(9)  -- Wrists
		DisplaySlotItems(player, object, items, intid, 16000)
	elseif intid >= 18000 and intid < 19000 then
		local items = SlotTypeFilter(10)  -- Hands
		DisplaySlotItems(player, object, items, intid, 18000)
	elseif intid >= 19000 and intid < 20000 then
		local items = SlotTypeFilter(16)  -- Back
		DisplaySlotItems(player, object, items, intid, 19000)
	elseif intid >= 20000 and intid < 21000 then
		local items = SlotTypeFilter({13, 17, 21, 22, 26})  -- Weapon
		DisplaySlotItems(player, object, items, intid, 20000)
	elseif intid >= 21000 and intid < 22000 then
		local items = SlotTypeFilter({22, 23})  -- Off-hand
		DisplaySlotItems(player, object, items, intid, 21000)
	elseif intid >= 22000 and intid < 23000 then
		local items = SlotTypeFilter(14)  -- Shield
		DisplaySlotItems(player, object, items, intid, 22000)
	elseif intid >= 23000 and intid < 24000 then
		local items = SlotTypeFilter({15, 26})  -- Ranged
		DisplaySlotItems(player, object, items, intid, 23000)
	elseif intid >= 24000 and intid < 25000 then
		local items = SlotTypeFilter({5, 20})  -- Ranged
		DisplaySlotItems(player, object, items, intid, 24000)

	elseif intid == 6000000 then
		--print("Search input received. Code: " .. (code or "nil"))
		if code then
			if code ~= "" then
				currentSearchTerm = code:lower()
				print("[Transmog item vendor]: "..player:GetName().." is searching for: " .. currentSearchTerm)
				ItemCache.GenerateSearchMenu(player, object, 1)
			else
				--print("Empty search term received")
				player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_spyglass_01:31:31:-24:0|tPlease enter a valid search term", 0, 5000003)
				player:GossipSendMenu(12, object)
			end
		else
			--print("Search was canceled")
			MogVendorHello(event, player, object)
		end
	elseif intid > 8000000 and intid < 8100000 then
        local itemId = intid - 8000000
        local baseItemCost = math.ceil(itemId / 1000)

        -- Find the item in the ItemCache
        local itemData
        for _, item in ipairs(ItemCache["Cache"]) do
            if item.entry == itemId then
                itemData = item
                break
            end
        end

        if itemData then
            local quality = itemData.quality
            local maxcount = itemData.maxcount
			if maxcount == 0 then
				maxcount = 99
			end
            local itemCost = math.floor(baseItemCost / 3 * 2 + (baseItemCost / 4 * quality^1.4))

            if quality >= 5 then
                itemCost = math.max(itemCost, 100)
            end

            if PlayerHasEnoughCurrency(player, itemCost) then
                if PlayerHasEnoughFreeSlots(player, 1) then
                    if player:GetItemCount(itemId) < maxcount then
						local item = player:GetItemByEntry(itemId)
						player:AddItem(itemId, 1)
                        player:RemoveItem(CURRENCY_ID, itemCost)
                        player:SendBroadcastMessage("You have purchased " .. GetItemLink(itemId) .. " for " .. itemCost .. " " .. CURRENCY_NAME .. ".")
                        print("Player "..player:GetName().." has purchased " .. GetItemLink(itemId) .. " for " .. itemCost .. " " .. CURRENCY_NAME .. ".")
                    else
                        player:SendBroadcastMessage("You cannot have more than " .. maxcount .. " of " .. GetItemLink(itemId) .. ".")
                    end
                    player:GossipComplete()
                else
                    player:SendAreaTriggerMessage("Your bags are full!")
                    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_bag_19:31:31:-24:0|tNot enough bag space!\n \nYou don't have enough bag space to buy " .. itemLink .. ". \n \n ", 0, 0)
                end
            else
                player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_coin_05:31:31:-24:0|tNot enough funds!\n \nYou don't have enough "..CURRENCY_NAME.." to buy " .. itemLink .. ".\nPrice:  " .. itemCost .. " "..CURRENCY_NAME..".\n \n ", 0, 0)
            end
		end
		player:GossipMenuAddItem(4, "|TInterface/ICONS/trade_engineering:31:31:-24:0|tGo back", 0, 0)
		player:GossipSendMenu(12, object)
	elseif intid > 7000000 and intid < 7200000 then -- Send inspection link
		local itemId = intid - 7000000
		local itemLink = GetItemLink(itemId)
		player:SendBroadcastMessage("Inspection link for: " .. itemLink)
		
		player:GossipClearMenu()
		local baseItemCost = math.ceil(itemId / 1000)
		
		-- Find the item in the ItemCache
		local itemData
		for _, item in ipairs(ItemCache["Cache"]) do
			if item.entry == itemId then
				itemData = item
				break
			end
		end
		
		local quality = itemData and itemData.quality or 0
		local itemLevel = itemData and itemData.itemLevel
		local level = itemData and itemData.level or 0
		local itemCost = math.floor((itemId / 1000)/3*2 + (baseItemCost / 4 * quality^1.4))

		if quality >= 5 then
			itemCost = math.max(itemCost, 100)
		end
		
		player:GossipMenuAddItem(0, "|TInterface/ICONS/" .. itemIconCache[itemId] .. ":31:31:-24:0|tInspect " .. itemLink .. "\n \nClick here to receive an inspect link. \n \n ", 0, 7000000 + itemId)
			
		if level == 0 then
			local reqLevel = math.ceil(itemLevel / 2.5)
			if player:GetLevel() < reqLevel then
				player:GossipMenuAddItem(0, "|TInterface/ICONS/achievement_level_80:31:31:-24:0|tRequired level to purchase: ".. math.ceil(itemLevel / 2.5) .."\n \nYou are too low level to purchase this item.\n \n ", 0, 0)
				player:GossipMenuAddItem(4, "|TInterface/ICONS/trade_engineering:31:31:-24:0|tGo back", 0, 0)
				player:GossipSendMenu(12, object)
				return
			end
		end
		
		if PlayerHasEnoughCurrency(player, itemCost) then
			if PlayerHasEnoughFreeSlots(player, 1) then
				player:GossipMenuAddItem(0, "|TInterface/ICONS/" .. itemIconCache[itemId] .. ":31:31:-24:0|tBuy " .. itemLink .. "?\n \nClick here to buy the item.\nPrice:  " .. itemCost .. " "..CURRENCY_NAME.."\n \n ", 0, 8000000 + itemId)
			else
				player:SendAreaTriggerMessage("Your bags are full!")
				player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_bag_19:31:31:-24:0|tNot enough bag space!\n \nYou don't have enough bag space to buy " .. itemLink .. ". \n \n ", 0, 0)
			end
		else
			player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_coin_05:31:31:-24:0|tNot enough funds!\n \nYou don't have enough "..CURRENCY_NAME.." to buy " .. itemLink .. ".\nPrice:  " .. itemCost .. " "..CURRENCY_NAME..".\n \n ", 0, 0)
		end
		
		player:GossipMenuAddItem(4, "|TInterface/ICONS/trade_engineering:31:31:-24:0|tGo back", 0, 0)
		player:GossipSendMenu(12, object)
	elseif intid > 4000000 then
		local page = intid - 4000000
		ItemCache.GenerateSearchMenu(player, object, page)
		
	elseif intid > 2000000 then -- Buy individual item
		local itemId = intid - 2000000
		local itemLink = GetItemLink(itemId)
		local baseItemCost = math.ceil(itemId / 1000)
		
		-- Find the item in the ItemCache
		local itemData
		for _, item in ipairs(ItemCache["Cache"]) do
			if item.entry == itemId then
				itemData = item
				break
			end
		end
		
		local quality = itemData and itemData.quality or 0
		local itemLevel = itemData and itemData.itemLevel
		local level = itemData and itemData.level or 0
		
		local itemCost = math.floor((itemId / 1000)/3*2 + (baseItemCost / 4 * quality^1.4))

		if quality >= 5 then
			itemCost = math.max(itemCost, 100)
		end
		
		player:GossipMenuAddItem(0, "|TInterface/ICONS/" .. itemIconCache[itemId] .. ":31:31:-24:0|tInspect " .. itemLink .. "\n \nClick here to receive an inspect link. \n \n ", 0, 7000000 + itemId)
		
		if level == 0 then
			local reqLevel = math.ceil(itemLevel / 2.5)
			if player:GetLevel() < reqLevel then
				player:GossipMenuAddItem(0, "|TInterface/ICONS/achievement_level_80:31:31:-24:0|tRequired level to purchase: ".. math.ceil(itemLevel / 2.5) .."\n \nYou are too low level to purchase this item.\n \n ", 0, 0)
				player:GossipMenuAddItem(4, "|TInterface/ICONS/trade_engineering:31:31:-24:0|tGo back", 0, 0)
				player:GossipSendMenu(12, object)
				return
			end
		end
		
		if PlayerHasEnoughCurrency(player, itemCost) then
			if PlayerHasEnoughFreeSlots(player, 1) then
				player:GossipMenuAddItem(0, "|TInterface/ICONS/" .. itemIconCache[itemId] .. ":31:31:-24:0|tBuy " .. itemLink .. "?\n \nClick here to buy the item.\nPrice:  " .. itemCost .. " "..CURRENCY_NAME.."\n \n ", 0, 8000000 + itemId)
			else
				player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_bag_19:31:31:-24:0|tNot enough bag space!\n \nYou don't have enough bag space to buy " .. itemLink .. ". \n \n ", 0, 0)
				player:SendAreaTriggerMessage("Your bags are full!")
			end
		else
			player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_coin_05:31:31:-24:0|tNot enough funds!\n \nYou don't have enough "..CURRENCY_NAME.." to buy " .. itemLink .. ". \nPrice:  " .. itemCost .. " "..CURRENCY_NAME..".\n \n ", 0, 0)
		end
		
		player:GossipMenuAddItem(4, "|TInterface/ICONS/trade_engineering:31:31:-24:0|tGo back", 0, 0)
		player:GossipSendMenu(12, object)
	end
end

---------------------------------------------------------------------------------
-- Transmog item vendor events
---------------------------------------------------------------------------------

local function AdoptTransmogItemCache()
    local shared = GetWorldData("TransmogItemCache")
    if type(shared) == "table" and shared.AsTable then
        shared = shared:AsTable()
    end
    if type(shared) ~= "table" or type(shared.cache) ~= "table" then
        return false
    end
    ItemCache["Cache"] = shared.cache
    return true
end

if GetStateMapId() == -1 then
    ItemCache.LoadCache()
else
    CreateLuaEvent(function(eventId)
        if AdoptTransmogItemCache() then
            RemoveEventById(eventId)
        end
    end, 5000, 0)
end

RegisterCreatureGossipEvent(TRANSMOG_VENDOR_NPC_ID, 1, MogVendorHello)
RegisterCreatureGossipEvent(TRANSMOG_VENDOR_NPC_ID, 2, MogVendorSelect)

---------------------------------------------------------------------------------
-- Transmog item vendor events end
---------------------------------------------------------------------------------


---------------------------------------------------------------------------------
-- Transmogrify items event registrations
---------------------------------------------------------------------------------

local function OnRepair(event, packet, player)
    -- Multistate: packet handlers run in the global state, where the mog caches
    -- only hold login-time data, so live mogs are read from the DB. The read is
    -- asynchronous: a sync query here would stall the world thread on DB latency.
    local playerName = player:GetName()
    local repairOwner = player:GetGUIDLow()
    CharDBQueryAsync("SELECT GUID, FakeEntry FROM acore_eluna.custom_transmogrification WHERE Owner = " .. repairOwner, function(result)
        local player = GetPlayerByName(playerName)
        if not player then
            return
        end
        local liveEntries = {}
        if result then
            repeat
                liveEntries[result:GetUInt32(0)] = result:GetUInt32(1)
            until not result:NextRow()
        end
        for slot = EQUIPMENT_SLOT_START, EQUIPMENT_SLOT_END-1 do
            local item = player:GetItemByPos(INVENTORY_SLOT_BAG_0, slot)
            if item then
                local fentry = liveEntries[item:GetGUIDLow()]
                if fentry then
                    local origentry = item:GetEntry()
                    local slot = item:GetSlot()
                    player:SetUInt32Value(PLAYER_VISIBLE_ITEM_1_ENTRYID + (slot * ITEM_SLOT_MULTIPLIER), item:GetEntry())
                    player:RegisterEvent(function(eventId, delay, repeats, player)
                        if player then
                            player:SetUInt32Value(PLAYER_VISIBLE_ITEM_1_ENTRYID + (slot * ITEM_SLOT_MULTIPLIER), fentry)
                        end
                    end, 100, 1)
                end
            end
        end
    end)
end

RegisterPlayerEvent(3, OnLogin)
RegisterPlayerEvent(28, OnLogin) -- On map change, in case player zones into expired/invalid instance
RegisterPlayerEvent(4, OnLogout)
RegisterPlayerEvent(29, OnEquip)
RegisterPacketEvent(0x2A8, 5, OnRepair)

RegisterCreatureGossipEvent(NPC_Entry, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_Entry, 2, OnGossipSelect)

-- Multistate: state-aware catch-up for already-online players (server start or
-- reload). GetPlayersInWorld() only exists in the global state.
for _, player in ipairs(GetStateMapId() == -1 and GetPlayersInWorld() or GetStateMap():GetPlayers()) do
    OnLogin(3, player)
end

---------------------------------------------------------------------------------
-- Transmogrify items event registrations end
---------------------------------------------------------------------------------