--VARIABLES
local ITEM_ID = 17890 -- On-use trigger item
local MorphApplicationDelay = 15-- Delay in MS, if too fast it will throw off the shapeshift
local MorphRepeats = 1 -- In case too fast, try again after a short delay (optional, 1 = only one attempt)
local DBWDelay = 25 -- Delay in DBW proc failsafe
local DBWRepeats = 30100/DBWDelay -- Loops reapplication of morph over the duration of DBW, ie. just over 30 sec. I had this set to 1 previously but it caused issues with certain cat abilities
local InvisibleWeapon = 58976 -- Low-impact disarm spell to correct weapon visibility on cat morphs, applied every 3 sec
local InvisibleWeaponTimer = 800 -- Duration of disarm
local MAX_REPETITIONS = 1 -- Number of times cat form disarm is applied per spell cast (20 covers about 10 seconds of hidden weapon). (Possibly temporarily set to 1 to reduce loan?)
local MorphReqRare = 100 -- Skill required to claim morph forms of elites
local MorphReqElite = 50 -- Skill required to claim morph forms of elites
local MaxMorphSkill = 300 -- Max morphing skill cap, just used to reward players

FastFlightMounts = {40192, 59976, 72808, 58615, 64927, 65439, 72807, 63956, 44317, -- 310% mounts
44744, 63796, 3363, 69395, 32345, 60021, 67336, 63963, 37015, 49193, 60024, 71810} -- 310% mounts

local creatureCache = {
    [1] = {}, -- Cat form
    [2] = {}, -- Bear form
    [3] = {}, -- Travel form
    [4] = {},  -- Flight form
    [5] = {},  -- Tree form
    [6] = {},  -- Boomkin form
    [7] = {}  -- Boomkin form
}

catCache = {}
bearCache = {}
birdCache = {}
travelCache = {}
owlCache = {}
treeCache = {}
aquaticCache = {}

catCount, bearCount, birdCount, travelCount, owlCount, treeCount, aquaticCount = 0, 0, 0, 0, 0, 0, 0

local repetitionCount = {}

local formSelections = {}
local morphSelection1 = {}
local morphSelection2 = {}
local morphSelection3 = {}
local morphSelection4 = {}
local morphSelection5 = {}
local morphSelection6 = {}
local morphSelection7 = {}
local searchQueries = {} -- Store search queries by player GUID
local searchResults = {} -- Store search results by player GUID

local ITEMS_PER_PAGE = 13

local function CacheCreatures()

    WorldDBQueryAsync([[
       SELECT entry, name 
       FROM creature_template 
       WHERE (family = 2 
          OR ((name LIKE '%panther%' 
          OR name LIKE '%gondria%' 
          OR name LIKE '%loque%') 
          AND type = 1))
          AND name NOT LIKE '%(%'
          AND name NOT LIKE '%"%'
          AND name NOT LIKE '%[%'
          AND name NOT LIKE '%DESIGNER%'
          AND name NOT LIKE '%UNUSED%'
          AND name NOT LIKE '%TEST%'
          AND name NOT LIKE '%STABLED%'
          AND name NOT LIKE '%TAMED%'
          AND name NOT LIKE '%TOTEM%'
    ]], function(catResults)
        if catResults then
            repeat
                local entry, name = catResults:GetUInt32(0), catResults:GetString(1)
                catCache[entry] = name
                catCount = catCount + 1
            until not catResults:NextRow()
        end
    end)

    WorldDBQueryAsync([[
       SELECT entry, name 
       FROM creature_template 
       WHERE (family = 4 
          OR name LIKE '%arcturis%' 
          OR name LIKE '%grizzly cub%')
          AND name NOT LIKE '%(%'
          AND name NOT LIKE '%"%'
          AND name NOT LIKE '%[%'
          AND name NOT LIKE '%UNUSED%'
          AND name NOT LIKE '%TEST%'
          AND name NOT LIKE '%STABLED%'
          AND name NOT LIKE '%TAMED%'
          AND name NOT LIKE '%TOTEM%'
    ]], function(bearResults)
        if bearResults then
            repeat
                local entry, name = bearResults:GetUInt32(0), bearResults:GetString(1)
                bearCache[entry] = name
                bearCount = bearCount + 1
            until not bearResults:NextRow()
        end
    end)

    WorldDBQueryAsync([[
       SELECT entry, name 
       FROM creature_template 
       WHERE (family IN (7, 26, 30, 33, 34, 37, 38) 
          OR ((name LIKE '%highperch%' 
          OR name LIKE '%wyvern%' 
          OR name LIKE '%heartrazor%') 
          AND type = 1))
          AND name NOT LIKE '%(%'
          AND name NOT LIKE '%"%'
          AND name NOT LIKE '%[%'
          AND name NOT LIKE '%UNUSED%'
          AND name NOT LIKE '%TEST%'
          AND name NOT LIKE '%STABLED%'
          AND name NOT LIKE '%TAMED%'
          AND name NOT LIKE '%TOTEM%'
    ]], function(birdResults)
        if birdResults then
            repeat
                local entry, name = birdResults:GetUInt32(0), birdResults:GetString(1)
                birdCache[entry] = name
                birdCount = birdCount + 1
            until not birdResults:NextRow()
        end
    end)
    
    WorldDBQueryAsync([[
       SELECT entry, name 
       FROM creature_template 
       WHERE (family IN (1, 11, 12, 39) 
          OR ((name LIKE '%riding wolf%' 
          OR name LIKE '%caribou%' 
          OR name LIKE '%fawn%' 
          OR name LIKE '%bach%' 
          OR name LIKE '%grazer%' 
          OR name LIKE '%giraffe%' 
          OR name LIKE '%gazelle%' 
          OR name LIKE '%zhevra%' 
          OR name LIKE '%snickerfang%' 
          OR name LIKE '%hyena%' 
          OR name LIKE '%tundra scavenger%' 
          OR name LIKE '%mosshoof%' 
          OR name LIKE '%talbuk%' 
          OR name LIKE '%elk%' 
          OR name LIKE '%stag%' 
          OR name LIKE '%mammoth%' 
          OR name LIKE '%elekk%' 
          OR name LIKE '%feathermoon%' 
          OR name LIKE '%hippogryph%' 
          OR name LIKE '%goat%' 
          OR name LIKE '%mustang%' 
          OR name LIKE '%buck%' 
          OR name LIKE '%ram%'
          OR name LIKE '%twilight serpent%') 
          AND type = 1))
          AND name NOT LIKE '%(%'
          AND name NOT LIKE '%"%'
          AND name NOT LIKE '%[%'
          AND name NOT LIKE '%UNUSED%'
          AND name NOT LIKE '%TEST%'
          AND name NOT LIKE '%STABLED%'
          AND name NOT LIKE '%TAMED%'
          AND name NOT LIKE '%REMA%'
          AND name NOT LIKE '%TOTEM%'
    ]], function(travelResults)
        if travelResults then
            repeat
                local entry, name = travelResults:GetUInt32(0), travelResults:GetString(1)
                travelCache[entry] = name
                travelCount = travelCount + 1
            until not travelResults:NextRow()
        end
    end)
    
    WorldDBQueryAsync([[
       SELECT entry, name 
       FROM creature_template 
       WHERE (name LIKE '%owlkin%' 
          OR name LIKE '%wildkin%' 
          OR name LIKE '%owlbeast%' 
          OR name LIKE '%moonkin%')
          AND name NOT LIKE '%(%'
          AND name NOT LIKE '%"%'
          AND name NOT LIKE '%[%'
          AND name NOT LIKE '%UNUSED%'
          AND name NOT LIKE '%TEST%'
          AND name NOT LIKE '%STABLED%'
          AND name NOT LIKE '%TAMED%'
          AND name NOT LIKE '%TOTEM%'
    ]], function(owlResults)
        if owlResults then
            repeat
                local entry, name = owlResults:GetUInt32(0), owlResults:GetString(1)
                owlCache[entry] = name
                owlCount = owlCount + 1
            until not owlResults:NextRow()
        end
    end)
    
    WorldDBQueryAsync([[
       SELECT entry, name 
       FROM creature_template 
       WHERE (name LIKE '%root-walker%' 
          OR name LIKE '%treant%' 
          OR name LIKE '%withered green keeper%' 
          OR name LIKE '%Withered Ancient%' 
          OR name LIKE '%Wood Ent%' 
          OR name LIKE '%Unbound Ent%' 
          OR name LIKE '%Mangrove Ent%' 
          OR name LIKE '%Dispirited Ent%' 
          OR name LIKE '%sapling%' 
          OR name LIKE '%Darnassian Proector%' 
          OR name LIKE '%Crazed Ancient%' 
          OR name LIKE '%Crystalline Keeper%' 
          OR name LIKE '%Irontree%' 
          OR name LIKE '%Force of Nature%' 
          OR name LIKE '%Deeprot%' 
          OR name LIKE '%tender%')
          AND type = 4
          AND name NOT LIKE '%(%'
          AND name NOT LIKE '%"%'
          AND name NOT LIKE '%[%'
          AND name NOT LIKE '%UNUSED%'
          AND name NOT LIKE '%TEST%'
          AND name NOT LIKE '%STABLED%'
          AND name NOT LIKE '%TAMED%'
          AND name NOT LIKE '%TOTEM%'
    ]], function(treeResults)
        if treeResults then
            repeat
                local entry, name = treeResults:GetUInt32(0), treeResults:GetString(1)
                treeCache[entry] = name
                treeCount = treeCount + 1
            until not treeResults:NextRow()
        end
    end)
    
    WorldDBQueryAsync([[
       SELECT entry, name 
       FROM creature_template 
       WHERE (name LIKE '%sewer beast%' 
          OR name LIKE '%mako%' 
          OR name LIKE '%seal%' 
          OR name LIKE '%rippa%' 
          OR name LIKE '%orca%' 
          OR name LIKE '%lake frenzy%' 
          OR name LIKE '%sporewind frenzy%' 
          OR name LIKE '%underbog frenzy%' 
          OR name LIKE '%yellowgill frenzy%' 
          OR name LIKE '%reef frenzy%' 
          OR name LIKE '%canal frenzy%' 
          OR name LIKE '%muck frenzy%' 
          OR name LIKE '%coilfang frenzy%' 
          OR name LIKE '%sharptooth frenzy%' 
          OR name LIKE '%coastal frenzy%' 
          OR name LIKE '%drakkari frenzy%' 
          OR name LIKE '%loch frenzy%' 
          OR name LIKE '%hooktooth%' 
          OR name LIKE '%mudfin%' 
          OR name LIKE '%shark%' 
          OR name LIKE '%thresh%' 
          OR name LIKE '%eel%' 
          OR name LIKE '%hammerhead%' 
          OR name LIKE '%whitetail%' 
          OR name LIKE '%crocolisk%' 
          OR name LIKE '%sawfin%')
          AND type = 1
          AND name NOT LIKE '%(%'
          AND name NOT LIKE '%"%'
          AND name NOT LIKE '%[%'
          AND name NOT LIKE '%UNUSED%'
          AND name NOT LIKE '%TEST%'
          AND name NOT LIKE '%STABLED%'
          AND name NOT LIKE '%TAMED%'
          AND name NOT LIKE '%TOTEM%'
    ]], function(aquaticResults)
        if aquaticResults then
            repeat
                local entry, name = aquaticResults:GetUInt32(0), aquaticResults:GetString(1)
                aquaticCache[entry] = name
                aquaticCount = aquaticCount + 1
            until not aquaticResults:NextRow()
        end
    end)
end

local function LoadPlayerMorphs(player)
    if isPlayerBot[player:GetName()] then return end
    if player:GetClass() ~= 11 then return end -- Only proceed for druids
    
    local guid = player:GetGUIDLow()

    if not creatureCache[guid] then
        creatureCache[guid] = {}
    end
    
    CharDBQueryAsync("SELECT name, id, form FROM character_morphs WHERE guid = "..guid, function(results)
        if results then
            repeat
                local name = results:GetString(0)
                local displayId = results:GetUInt32(1)
                local formIndex = results:GetUInt32(2)
                
                if not creatureCache[guid][formIndex] then
                    creatureCache[guid][formIndex] = {}
                end
                
                local exists = false
                for _, entry in ipairs(creatureCache[guid][formIndex]) do
                    if entry.displayId == displayId then
                        exists = true
                        break
                    end
                end
                
                if not exists then
                    table.insert(creatureCache[guid][formIndex], {name = name, displayId = displayId})
                end
            until not results:NextRow()
        end
    end)
end

local function SavePlayerMorph(player, name, displayId, formIndex)
    if player:GetClass() ~= 11 then return end
    local guid = player:GetGUIDLow()
    local escapedName = string.gsub(name, "'", "''") -- Fixes crashes on Loque'Nahak and other NPCs with ' in name
    CharDBExecute("REPLACE INTO character_morphs (guid, name, id, form) VALUES ("..guid..", '"..escapedName.."', "..displayId..", "..formIndex..")")
end

local function CountTotalMorphs(player)
    local guid = player:GetGUIDLow()
    local total = 0

    if creatureCache[guid] then
        for _, cache in pairs(creatureCache[guid]) do
            total = total + #cache
        end
    end

    return math.min(total, MaxMorphSkill)
end

local function CheckIfNeedToApplyMorph(event, player)
    if player:GetClass() == 11 and player:HasItem(17890)
    and not player:IsPvPFlagged() and (player:HasAura(768)
    or player:HasAura(9634)    or player:HasAura(5487)
    or player:HasAura(783) or player:HasAura(33891)
    or player:HasAura(24858) or player:HasAura(1066)) then
        player:RegisterEvent(Morpher, 100, 1)
    end
end

local function OnKillCreature(event, player, creature)
    if player:GetClass() ~= 11 then return end
    if not player:HasItem(17890) then return end

    local guid = player:GetGUIDLow()
    if not creatureCache[guid] then
        creatureCache[guid] = {}
    end
    
    local entry = creature:GetEntry()
    local displayId = creature:GetDisplayId()
    local creatureName = creature:GetName()
    
    if creature:GetEntry() == 32485 or creature:GetEntry() == 27483 or creature:GetEntry() == 6584 or creature:GetEntry() == 6498 or creature:GetEntry() == 6500 then
        entry = 33505
        displayId = 28647
        creatureName = "Devilsaur"
    elseif creature:GetEntry() == 20931 or creature:GetEntry() == 6499 then
        entry = 40404
        displayId = 31831
        creatureName = "Ironhide Devilsaur"
    elseif creature:GetEntry() == 32517 then
        entry = 33510
        displayId = 28649
        creatureName = "Loque'nahak"
    else 
        creatureName = creatureName
        displayId = displayId
        entry = entry
    end
    
    local function AddToPlayerCache(cacheIndex, formType)
        if not creatureCache[guid][cacheIndex] then
            creatureCache[guid][cacheIndex] = {}
        end

        local exists = false
        for _, entry in ipairs(creatureCache[guid][cacheIndex]) do
            if entry.displayId == displayId then
                exists = true
                break
            end
        end

        if not exists then
            if creature:GetRank() == 1 then
                if CountTotalMorphs(player) < MorphReqElite then
                    player:SendBroadcastMessage("You need to have a morph skill of "..MorphReqElite.." before you can learn elite morphs. Your skill is currently "..CountTotalMorphs(player)..".")
                else
                    table.insert(creatureCache[guid][cacheIndex], {name = creatureName, displayId = displayId})
                    SavePlayerMorph(player, creatureName, displayId, cacheIndex)
                    if CountTotalMorphs(player) < MaxMorphSkill then
                        player:SendBroadcastMessage("You have released "..creatureName.."'s spirit and learned how to morph into their "..formType..". Your morph skill has increased to "..CountTotalMorphs(player)..".")
                    else
                        player:SendBroadcastMessage("You have released "..creatureName.."'s spirit and learned how to morph into their "..formType..".")
                    end
                end
            elseif creature:GetRank() == 2 or creature:GetRank() == 4 then
                if CountTotalMorphs(player) < MorphReqRare then
                    player:SendBroadcastMessage("You need to have a morph skill of "..MorphReqRare.." before you can learn rare morphs. Your skill is currently "..CountTotalMorphs(player)..".")
                else
                    table.insert(creatureCache[guid][cacheIndex], {name = creatureName, displayId = displayId})
                    SavePlayerMorph(player, creatureName, displayId, cacheIndex)
                    if CountTotalMorphs(player) < MaxMorphSkill then
                        player:SendBroadcastMessage("You have released "..creatureName.."'s spirit and learned how to morph into their "..formType..". Your morph skill has increased to "..CountTotalMorphs(player)..".")
                    else
                        player:SendBroadcastMessage("You have released "..creatureName.."'s spirit and learned how to morph into their "..formType..".")
                    end
                end
            elseif creature:GetRank() ~= 3 then
                table.insert(creatureCache[guid][cacheIndex], {name = creatureName, displayId = displayId})
                SavePlayerMorph(player, creatureName, displayId, cacheIndex)
                if CountTotalMorphs(player) < MaxMorphSkill then
                    player:SendBroadcastMessage("You have released "..creatureName.."'s spirit and learned how to morph into their "..formType..". Your morph skill has increased to "..CountTotalMorphs(player)..".")
                else
                    player:SendBroadcastMessage("You have released "..creatureName.."'s spirit and learned how to morph into their "..formType..".")
                end
            end
        end
        
        return not exists
    end

    local formTypes = {
        [1] = "Cat form",
        [2] = "Bear form",
        [3] = "Travel form",
        [4] = "Flight form",
        [5] = "Tree form",
        [6] = "Moonkin form",
        [7] = "Aquatic form"
    }

    if catCache[entry] then
        if not AddToPlayerCache(1, formTypes[1]) then return end
    elseif bearCache[entry] then
        if not AddToPlayerCache(2, formTypes[2]) then return end
    elseif travelCache[entry] then
        if not AddToPlayerCache(3, formTypes[3]) then return end
        
        local playerFormCount = #creatureCache[guid][3]
        if playerFormCount == 10 or playerFormCount == 20 or playerFormCount == 30 or playerFormCount == 40 or playerFormCount == 50 then
            local speedIncrease = (playerFormCount + 40)
            player:SendBroadcastMessage("Through your exquisite knowledge of travel forms, your travel form speed has increased to "..speedIncrease.."%.")
        end
        
    elseif birdCache[entry] then
        if not AddToPlayerCache(4, formTypes[4]) then return end
        
        local playerFormCount = #creatureCache[guid][4]
        if playerFormCount == 5 or playerFormCount == 10 or playerFormCount == 15 or playerFormCount == 20 or playerFormCount == 25 then
            
            local baseSpeed = 150
            if player:HasSpell(40120) then baseSpeed = 280 end
            for _, fastMountId in ipairs(FastFlightMounts) do
                if player:HasSpell(fastMountId) then
                    baseSpeed = 310
                    break
                end
            end
            
            local tier = math.floor(playerFormCount / 5)
            local speedIncrease = baseSpeed + (tier * 5)
            
            local formName = player:HasSpell(40120) and "swift flight form" or "flight form"
            player:SendBroadcastMessage("Through your exquisite knowledge of flight forms, your "..formName.." speed has increased to "..speedIncrease.."%.")
        end
        
    elseif treeCache[entry] then
        if not AddToPlayerCache(5, formTypes[5]) then return end
    elseif owlCache[entry] then
        if not AddToPlayerCache(6, formTypes[6]) then return end
    elseif aquaticCache[entry] then
        if not AddToPlayerCache(7, formTypes[7]) then return end
            
        local playerFormCount = #creatureCache[guid][7]
        if playerFormCount == 5 or playerFormCount == 10 or playerFormCount == 15 or playerFormCount == 20 or playerFormCount == 25 or playerFormCount == 30 or playerFormCount == 35 or playerFormCount == 40 then
            local speedIncrease = (playerFormCount + 50)
            player:SendBroadcastMessage("Through your exquisite knowledge of aquatic forms, your aquatic form speed has increased to "..speedIncrease.."%.")
        end
    end
    CheckIfNeedToApplyMorph(_, player)
end

local function ShowInitialGossipMenu(player)
    local guid = player:GetGUIDLow()
    
    -- Function to get active morph name
    local function getActiveMorphName(formId)
        local morphSelection = nil
        if formId == 1 then morphSelection = morphSelection1[guid]
        elseif formId == 2 then morphSelection = morphSelection2[guid]
        elseif formId == 3 then morphSelection = morphSelection3[guid]
        elseif formId == 4 then morphSelection = morphSelection4[guid]
        elseif formId == 5 then morphSelection = morphSelection5[guid]
        elseif formId == 6 then morphSelection = morphSelection6[guid]
        elseif formId == 7 then morphSelection = morphSelection7[guid]
        end
        
        if not morphSelection or morphSelection == 0 then
            return "Default"
        end
        
        -- Find the morph name
        if creatureCache[guid] and creatureCache[guid][formId] then
            for _, creature in ipairs(creatureCache[guid][formId]) do
                if creature.displayId == morphSelection then
                    return creature.name
                end
            end
        end
        return "Unknown"
    end

    player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_questionmark:32:32:-25:0|tHow does morphing work?", 0, 10)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_spyglass_02:32:32:-25:0|tSearch morphs", 0, 11)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_druid_catform:32:32:-25:0|tCat form: " .. getActiveMorphName(1), 0, 1)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_racial_bearform:32:32:-25:0|tBear form: " .. getActiveMorphName(2), 0, 2)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_druid_travelform:32:32:-25:0|tTravel form: " .. getActiveMorphName(3), 0, 3)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_druid_flightform:32:32:-25:0|tFlight form: " .. getActiveMorphName(4), 0, 4)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_druid_treeoflife:32:32:-25:0|tTree form: " .. getActiveMorphName(5), 0, 5)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_nature_forceofnature:32:32:-25:0|tBoomkin form: " .. getActiveMorphName(6), 0, 6)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_druid_aquaticform:32:32:-25:0|tAquatic form: " .. getActiveMorphName(7), 0, 7)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_nature_earthbind:32:32:-25:0|tRemove current morph", 0, 8)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/achievement_quests_completed_daily_08:32:32:-25:0|tMorph skill: "..CountTotalMorphs(player).."/"..MaxMorphSkill.."", 0, 9)
    player:GossipSendMenu(12, player, 0)
end

local function SearchMorphs(player, searchTerm)
    local guid = player:GetGUIDLow()
    local results = {}
    
    if not creatureCache[guid] then
        return results
    end
    
    searchTerm = string.lower(searchTerm)
    
    -- Search through all forms
    for formId = 1, 7 do
        if creatureCache[guid][formId] then
            for _, creature in ipairs(creatureCache[guid][formId]) do
                local creatureName = string.lower(creature.name)
                if string.find(creatureName, searchTerm) then
                    table.insert(results, {
                        name = creature.name,
                        displayId = creature.displayId,
                        formId = formId
                    })
                end
            end
        end
    end
    
    return results
end

local function ShowSearchResults(player, page)
    local guid = player:GetGUIDLow()
    local results = searchResults[guid] or {}
    
    if #results == 0 then
        player:SendAreaTriggerMessage("No morphs found matching your search!")
        ShowInitialGossipMenu(player)
        return
    end
    
    -- Sort results alphabetically
    table.sort(results, function(a, b)
        return a.name < b.name
    end)
    
    player:GossipClearMenu()
    local startIndex = (page - 1) * ITEMS_PER_PAGE + 1
    local endIndex = math.min(startIndex + ITEMS_PER_PAGE - 1, #results)
    
    local formTypes = {
        [1] = "Cat", [2] = "Bear", [3] = "Travel", [4] = "Flight",
        [5] = "Tree", [6] = "Boomkin", [7] = "Aquatic"
    }
    
    local formIcons = {
        [1] = "|TInterface/ICONS/ability_druid_catform:32:32:-25:0|t",
        [2] = "|TInterface/ICONS/ability_racial_bearform:32:32:-25:0|t",
        [3] = "|TInterface/ICONS/ability_druid_travelform:32:32:-25:0|t",
        [4] = "|TInterface/ICONS/ability_druid_flightform:32:32:-25:0|t",
        [5] = "|TInterface/ICONS/ability_druid_treeoflife:32:32:-25:0|t",
        [6] = "|TInterface/ICONS/spell_nature_forceofnature:32:32:-25:0|t",
        [7] = "|TInterface/ICONS/ability_druid_aquaticform:32:32:-25:0|t"
    }
    
    for i = startIndex, endIndex do
        local result = results[i]
        local formType = formTypes[result.formId]
        local icon = formIcons[result.formId]
        player:GossipMenuAddItem(4, icon .. result.name .. " (" .. formType .. ")", 0, 300000 + result.displayId + (result.formId * 1000000))
    end
    
    if page > 1 then
        player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_map_01:32:32:-25:0|tPrevious Page", 0, 400000 + page - 1)
    end
    
    if endIndex < #results then
        player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_map_01:32:32:-25:0|tNext Page", 0, 400000 + page + 1)
    end
    
    player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_spyglass_02:32:32:-25:0|tNew search", 0, 11)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-25:0|tBack to main menu", 0, 2000000)
    player:GossipSendMenu(12, player, 0)
end

local function ShowGossipPage(player, formId, page)
    local guid = player:GetGUIDLow()

    if not creatureCache[guid] or not creatureCache[guid][formId] or #creatureCache[guid][formId] == 0 then
        player:SendAreaTriggerMessage("You have no available morphs for this form!")
        ShowInitialGossipMenu(player)
        return
    end

    -- Sort the creatureCache alphabetically by name
    table.sort(creatureCache[guid][formId], function(a, b)
        return a.name < b.name
    end)
    
    player:GossipClearMenu()
    local startIndex = (page - 1) * ITEMS_PER_PAGE + 1
    local endIndex = math.min(startIndex + ITEMS_PER_PAGE - 1, #creatureCache[guid][formId])

    local nameCount = {}

    for i = startIndex, endIndex do
        local creature = creatureCache[guid][formId][i]
        local name = creature.name

        if not nameCount[name] then
            nameCount[name] = 1
        else
            nameCount[name] = nameCount[name] + 1
            name = name .. " " .. nameCount[name]
        end
        if formId == 1 then
            player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_druid_catform:32:32:-25:0|t" .. name, 0, 100000 + creature.displayId)
        elseif formId == 2 then
            player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_racial_bearform:32:32:-25:0|t" .. name, 0, 100000 + creature.displayId)
        elseif formId == 3 then
            player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_druid_travelform:32:32:-25:0|t" .. name, 0, 100000 + creature.displayId)
        elseif formId == 4 then
            player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_druid_flightform:32:32:-25:0|t" .. name, 0, 100000 + creature.displayId)
        elseif formId == 5 then
            player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_druid_treeoflife:32:32:-25:0|t" .. name, 0, 100000 + creature.displayId)
        elseif formId == 6 then
            player:GossipMenuAddItem(4, "|TInterface/ICONS/spell_nature_forceofnature:32:32:-25:0|t" .. name, 0, 100000 + creature.displayId)
        elseif formId == 7 then
            player:GossipMenuAddItem(4, "|TInterface/ICONS/ability_druid_aquaticform:32:32:-25:0|t" .. name, 0, 100000 + creature.displayId)
        end
    end
    
    if page > 1 then
        player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_map_01:32:32:-25:0|tPrevious Page", 0, 200000 + page - 1)
    end
    
    if endIndex < #creatureCache[guid][formId] then
        player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_map_01:32:32:-25:0|tNext Page", 0, 200000 + page + 1)
    end
    
    player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-25:0|tBack to main menu", 0, 2000000)
    player:GossipSendMenu(12, player, 0)
end

local function OnGossipSelect(event, player, object, sender, intid, code, menu_id)
    if player:IsPvPFlagged() then player:SendAreaTriggerMessage("You can't use druid morphs while flagged for PvP.") return false end

    if intid == 10 then
        player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_questionmark:32:32:-25:0|tHow does morphing work?\n \nMorphing is an ancient Darnassian magic that permits druids to transmogrify their shapeshifts into the shapes of creatures they have released the spirit from.\n \nKilling a valid creature lets you morph your shapeshift of the same type into the newly acquired form. Every unique form claimed increases your morphing skill by 1.\n \nTo claim the form of elite creatures, you need to have a morphing skill of at least "..MorphReqElite..", and to claim the form of rare creatures, you need a skill of "..MorphReqRare..".\n \nFor a full list of creatures whose forms you can claim unless an identical form has already been claimed, consult your Twiggy and ask him about Yggdrasil's features.\n ", 0, 10)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tGo back", 0, 9)
        player:GossipSendMenu(12, player, 0)
    elseif intid == 8 then
        ShowInitialGossipMenu(player)
        local guid = player:GetGUIDLow()
        if player:HasAura(768) then -- Cat
            morphSelection1[guid] = 0
            CharDBExecute("UPDATE character_morphs SET active = 0 WHERE guid = "..guid.." AND form = 1")
            player:RemoveAura(768)
            player:AddAura(768, player)
            
        elseif player:HasAura(9634) or player:HasAura(5487) then -- Bear
            morphSelection2[guid] = 0
            CharDBExecute("UPDATE character_morphs SET active = 0 WHERE guid = "..guid.." AND form = 2")
            if player:HasAura(9634) then
                player:RemoveAura(9634)
                player:AddAura(9634, player)
            elseif player:HasAura(5487) then
                player:RemoveAura(5487)
                player:AddAura(5487, player)
            end
            
        elseif player:HasAura(783) then -- Travel
            morphSelection3[guid] = 0
            CharDBExecute("UPDATE character_morphs SET active = 0 WHERE guid = "..guid.." AND form = 3")
            player:RemoveAura(783)
            player:AddAura(783, player)
            
        elseif player:HasAura(40120) or player:HasAura(33943) then  -- Bird
            morphSelection4[guid] = 0
            CharDBExecute("UPDATE character_morphs SET active = 0 WHERE guid = "..guid.." AND form = 4")
            if player:HasAura(40120) then
                player:RemoveAura(40120)
                player:AddAura(40120, player)
            elseif player:HasAura(33943) then
                player:RemoveAura(33943)
                player:AddAura(33943, player)
            end
            
        elseif player:HasAura(33891) then  -- Tree
            morphSelection5[guid] = 0
            CharDBExecute("UPDATE character_morphs SET active = 0 WHERE guid = "..guid.." AND form = 5")
            player:RemoveAura(33891)
            player:AddAura(33891, player)
            
        elseif player:HasAura(24858) then -- Boomkin 
            morphSelection6[guid] = 0
            CharDBExecute("UPDATE character_morphs SET active = 0 WHERE guid = "..guid.." AND form = 6")
            player:RemoveAura(24858)
            player:AddAura(24858, player)
            
        elseif player:HasAura(1066) then -- Aquatic 
            morphSelection7[guid] = 0
            CharDBExecute("UPDATE character_morphs SET active = 0 WHERE guid = "..guid.." AND form = 7")
            player:RemoveAura(1066)
            player:AddAura(1066, player)
        end
        
    elseif intid >= 1 and intid <= 7 then
        formSelections[player:GetGUIDLow()] = intid  -- Store selected form
        ShowGossipPage(player, intid, 1)  -- Show the initial page for the selected form
    elseif intid >= 100000 and intid < 200000 then
        local formId = formSelections[player:GetGUIDLow()]
        local displayId = intid - 100000 -- Converts gossip menu ID to display ID
        local guid = player:GetGUIDLow()
        
        if creatureCache[guid] and creatureCache[guid][formId] then
            for _, creature in ipairs(creatureCache[guid][formId]) do
                if creature.displayId == displayId then
                    creatureName = creature.name
                    break
                end
            end
        end
        
        if formId == 1 and creatureCache[formId] then
            morphSelection1[guid] = displayId
            player:SendBroadcastMessage("You have morphed your cat form into "..creatureName..".")
            if player:HasAura(768) or player:HasAura(32356) or player:HasAura(3025) then
                player:SetDisplayId(morphSelection1[guid])
            end
            CharDBExecute("UPDATE character_morphs SET active = 0 WHERE guid = "..guid.." AND form = 1")
            CharDBExecute("UPDATE character_morphs SET active = 1 WHERE guid = "..guid.." AND id = "..morphSelection1[guid])
        elseif formId == 2 and creatureCache[formId] then
            morphSelection2[guid] = displayId
            player:SendBroadcastMessage("You have morphed your bear form into "..creatureName..".")
            if player:HasAura(9634) or player:HasAura(5487) then
                player:SetDisplayId(morphSelection2[guid])
            end
            CharDBExecute("UPDATE character_morphs SET active = 0 WHERE guid = "..guid.." AND form = 2")
            CharDBExecute("UPDATE character_morphs SET active = 1 WHERE guid = "..guid.." AND id = "..morphSelection2[guid])
        elseif formId == 3 and creatureCache[formId] then
            morphSelection3[guid] = displayId
            
            local morphCount = #creatureCache[guid][formId]
            
            if morphCount >= 10 then
                local tier = math.min(math.floor(morphCount / 10), 5)
                local travelSpeed = 1.4 + (tier * 0.1)
                local travelSpeedPct = 40 + (tier * 10)
                player:SetSpeed(1, travelSpeed)
                player:SendBroadcastMessage("You have morphed your travel form into "..creatureName..". Your travel speed is now "..travelSpeedPct.."%.")
            else
                player:SendBroadcastMessage("You have morphed your travel form into "..creatureName..".")
            end
            
            if player:HasAura(783) then
                player:SetDisplayId(morphSelection3[guid])
            end
            
            CharDBExecute("UPDATE character_morphs SET active = 0 WHERE guid = "..guid.." AND form = 3")
            CharDBExecute("UPDATE character_morphs SET active = 1 WHERE guid = "..guid.." AND id = "..morphSelection3[guid])
        elseif formId == 4 and creatureCache[formId] then
            morphSelection4[guid] = displayId
            if player:HasAura(40120) or player:HasAura(33943)  then
                player:SetDisplayId(morphSelection4[guid])
            end
            
            local formName = player:HasSpell(40120) and "swift flight form" or "flight form"
            
            if #creatureCache[guid][4] >= 5 then
                local morphs = #creatureCache[guid][4]
                local tier = math.min(math.floor(morphs / 5), 5)
                local baseSpeed = 2.5
                if player:HasSpell(40120) then baseSpeed = 3.8 end
                for _, fastMountId in ipairs(FastFlightMounts) do
                    if player:HasSpell(fastMountId) then
                        baseSpeed = 4.1
                        break
                    end
                end
                local flightSpeed = baseSpeed + (tier * 0.05)
                player:SetSpeed(6, flightSpeed)
                
                local baseSpeed = 150
                if player:HasSpell(40120) then baseSpeed = 280 end
                for _, fastMountId in ipairs(FastFlightMounts) do
                    if player:HasSpell(fastMountId) then
                        baseSpeed = 310
                        break
                    end
                end
                
                local speedIncrease = baseSpeed + (tier * 5)
                
                player:SendBroadcastMessage("You have morphed your "..formName.." into "..creatureName..". Your flight speed is now "..speedIncrease.."%.")
            else
                player:SendBroadcastMessage("You have morphed your "..formName.." into "..creatureName..".")
            end
         
            CharDBExecute("UPDATE character_morphs SET active = 0 WHERE guid = "..guid.." AND form = 4")
            CharDBExecute("UPDATE character_morphs SET active = 1 WHERE guid = "..guid.." AND id = "..morphSelection4[guid])
        elseif formId == 5 and creatureCache[formId] then
            morphSelection5[guid] = displayId
            player:SendBroadcastMessage("You have morphed your tree form into "..creatureName..".")
            if player:HasAura(33891)  then
                player:SetDisplayId(morphSelection5[guid])
            end
            CharDBExecute("UPDATE character_morphs SET active = 0 WHERE guid = "..guid.." AND form = 5")
            CharDBExecute("UPDATE character_morphs SET active = 1 WHERE guid = "..guid.." AND id = "..morphSelection5[guid])
        elseif formId == 6 and creatureCache[formId] then
            morphSelection6[guid] = displayId
            player:SendBroadcastMessage("You have morphed your boomkin form into "..creatureName..".")
            if player:HasAura(24858) then 
                player:SetDisplayId(morphSelection6[guid])
            end
            CharDBExecute("UPDATE character_morphs SET active = 0 WHERE guid = "..guid.." AND form = 6")
            CharDBExecute("UPDATE character_morphs SET active = 1 WHERE guid = "..guid.." AND id = "..morphSelection6[guid])
        elseif formId == 7 and creatureCache[formId] then
            morphSelection7[guid] = displayId
            
            local morphCount = #creatureCache[guid][formId]
            
            if player:HasAura(1066) then 
                player:SetDisplayId(morphSelection7[guid])
            end
            
            if morphCount >= 5 then
                local tier = math.min(math.floor(morphCount / 5), 8)
                local aquaticSpeed = 1.5 + (tier * 0.05) * 0.75
                local aquaticSpeedPct = 50 + (tier * 5)
                player:SetSpeed(3, aquaticSpeed)
                player:SendBroadcastMessage("You have morphed your aquatic form into "..creatureName..". Your aquatic speed is now "..aquaticSpeedPct.."%.")
            else
                player:SendBroadcastMessage("You have morphed your aquatic form into "..creatureName..".")
            end
            
            CharDBExecute("UPDATE character_morphs SET active = 0 WHERE guid = "..guid.." AND form = 7")
            CharDBExecute("UPDATE character_morphs SET active = 1 WHERE guid = "..guid.." AND id = "..morphSelection7[guid])
        end
        player:GossipComplete()
    elseif intid >= 200000 and intid < 300000 then
        local formId = formSelections[player:GetGUIDLow()]
        if formId then
            local page = intid - 200000
            ShowGossipPage(player, formId, page)
        end
    elseif intid == 2000000 then
        ShowInitialGossipMenu(player)  -- Back to main menu
    elseif intid == 9 then
        ShowInitialGossipMenu(player)
    elseif intid == 11 then -- Search morphs - request text input
        player:GossipMenuAddItem(5, "Enter search term:", 0, 12, true) -- 5 = input box, true = text input
        player:GossipSendMenu(12, player, 0)
        
    elseif intid == 12 then -- Process search input
        if code and code ~= "" then
            local guid = player:GetGUIDLow()
            searchResults[guid] = SearchMorphs(player, code)
            ShowSearchResults(player, 1)
        else
            player:SendAreaTriggerMessage("Please enter a search term!")
            ShowInitialGossipMenu(player)
        end
        
    elseif intid >= 1000000 and intid < 10000000 then -- Search result selection
        local adjustedId = intid - 300000
        local formId = math.floor(adjustedId / 1000000)
        local displayId = adjustedId - (formId * 1000000)
        local guid = player:GetGUIDLow()
        
        formSelections[guid] = formId
        
        local creatureName = "Unknown"
        
        -- Find creature name
        if creatureCache[guid] and creatureCache[guid][formId] then
            for _, creature in ipairs(creatureCache[guid][formId]) do
                if creature.displayId == displayId then
                    creatureName = creature.name
                    break
                end
            end
        end

        if formId == 1 then
            morphSelection1[guid] = displayId
            player:SendBroadcastMessage("You have morphed your cat form into "..creatureName..".")
            if player:HasAura(768) or player:HasAura(32356) or player:HasAura(3025) then
                player:SetDisplayId(morphSelection1[guid])
            end
            CharDBExecute("UPDATE character_morphs SET active = 0 WHERE guid = "..guid.." AND form = 1")
            CharDBExecute("UPDATE character_morphs SET active = 1 WHERE guid = "..guid.." AND id = "..morphSelection1[guid])
        elseif formId == 2 then
            morphSelection2[guid] = displayId
            player:SendBroadcastMessage("You have morphed your bear form into "..creatureName..".")
            if player:HasAura(9634) or player:HasAura(5487) then
                player:SetDisplayId(morphSelection2[guid])
            end
            CharDBExecute("UPDATE character_morphs SET active = 0 WHERE guid = "..guid.." AND form = 2")
            CharDBExecute("UPDATE character_morphs SET active = 1 WHERE guid = "..guid.." AND id = "..morphSelection2[guid])
        elseif formId == 3 then
            morphSelection3[guid] = displayId
            
            local morphCount = #creatureCache[guid][formId]
            
            if morphCount >= 10 then
                local tier = math.min(math.floor(morphCount / 10), 5)
                local travelSpeed = 1.4 + (tier * 0.1)
                local travelSpeedPct = 40 + (tier * 10)
                player:SetSpeed(1, travelSpeed)
                player:SendBroadcastMessage("You have morphed your travel form into "..creatureName..". Your travel speed is now "..travelSpeedPct.."%.")
            else
                player:SendBroadcastMessage("You have morphed your travel form into "..creatureName..".")
            end
            
            if player:HasAura(783) then
                player:SetDisplayId(morphSelection3[guid])
            end
            
            CharDBExecute("UPDATE character_morphs SET active = 0 WHERE guid = "..guid.." AND form = 3")
            CharDBExecute("UPDATE character_morphs SET active = 1 WHERE guid = "..guid.." AND id = "..morphSelection3[guid])
        elseif formId == 4 then
            morphSelection4[guid] = displayId
            if player:HasAura(40120) or player:HasAura(33943) then
                player:SetDisplayId(morphSelection4[guid])
            end
            
            local formName = player:HasSpell(40120) and "swift flight form" or "flight form"
            
            if #creatureCache[guid][4] >= 5 then
                local morphs = #creatureCache[guid][4]
                local tier = math.min(math.floor(morphs / 5), 5)
                local baseSpeed = 2.5
                if player:HasSpell(40120) then baseSpeed = 3.8 end
                for _, fastMountId in ipairs(FastFlightMounts) do
                    if player:HasSpell(fastMountId) then
                        baseSpeed = 4.1
                        break
                    end
                end
                local flightSpeed = baseSpeed + (tier * 0.05)
                player:SetSpeed(6, flightSpeed)
                
                local baseSpeed = 150
                if player:HasSpell(40120) then baseSpeed = 280 end
                for _, fastMountId in ipairs(FastFlightMounts) do
                    if player:HasSpell(fastMountId) then
                        baseSpeed = 310
                        break
                    end
                end
                
                local speedIncrease = baseSpeed + (tier * 5)

                player:SendBroadcastMessage("You have morphed your "..formName.." into "..creatureName..". Your flight speed is now "..speedIncrease.."%.")
            else
                player:SendBroadcastMessage("You have morphed your "..formName.." into "..creatureName..".")
            end
            
            CharDBExecute("UPDATE character_morphs SET active = 0 WHERE guid = "..guid.." AND form = 4")
            CharDBExecute("UPDATE character_morphs SET active = 1 WHERE guid = "..guid.." AND id = "..morphSelection4[guid])
        elseif formId == 5 then
            morphSelection5[guid] = displayId
            player:SendBroadcastMessage("You have morphed your tree form into "..creatureName..".")
            if player:HasAura(33891) then
                player:SetDisplayId(morphSelection5[guid])
            end
            CharDBExecute("UPDATE character_morphs SET active = 0 WHERE guid = "..guid.." AND form = 5")
            CharDBExecute("UPDATE character_morphs SET active = 1 WHERE guid = "..guid.." AND id = "..morphSelection5[guid])
        elseif formId == 6 then
            morphSelection6[guid] = displayId
            player:SendBroadcastMessage("You have morphed your boomkin form into "..creatureName..".")
            if player:HasAura(24858) then 
                player:SetDisplayId(morphSelection6[guid])
            end
            CharDBExecute("UPDATE character_morphs SET active = 0 WHERE guid = "..guid.." AND form = 6")
            CharDBExecute("UPDATE character_morphs SET active = 1 WHERE guid = "..guid.." AND id = "..morphSelection6[guid])
        elseif formId == 7 then
            morphSelection7[guid] = displayId
            
            local morphCount = #creatureCache[guid][formId]
            
            if player:HasAura(1066) then 
                player:SetDisplayId(morphSelection7[guid])
            end
            
            if morphCount >= 5 then
                local tier = math.min(math.floor(morphCount / 5), 8)
                local aquaticSpeed = 1.5 + (tier * 0.05) * 0.75
                local aquaticSpeedPct = 50 + (tier * 5)
                player:SetSpeed(3, aquaticSpeed)
                player:SendBroadcastMessage("You have morphed your aquatic form into "..creatureName..". Your aquatic speed is now "..speedPct.."%.")
            else
                player:SendBroadcastMessage("You have morphed your aquatic form into "..creatureName..".")
            end
            
            CharDBExecute("UPDATE character_morphs SET active = 0 WHERE guid = "..guid.." AND form = 7")
            CharDBExecute("UPDATE character_morphs SET active = 1 WHERE guid = "..guid.." AND id = "..morphSelection7[guid])
        end
        player:GossipComplete()
        
    elseif intid >= 400000 and intid < 500000 then -- Search pagination
        local page = intid - 400000
        ShowSearchResults(player, page)
    else
        ShowInitialGossipMenu(player)
    end
end

local function OnGossipHello(event, player, object)
    if player:GetClass() == 11 then -- Check if player is a druid
        if player:IsPvPFlagged() then player:SendAreaTriggerMessage("You can't use druid morphs while flagged for PvP.") return false end
        player:GossipComplete()
        ShowInitialGossipMenu(player)
        return false
    end
    return false
end

local function DBWfix(eventId, delay, repeats, player)
    if player:HasAura(71561) or player:HasAura(71484)
    or player:HasAura(71560) or player:HasAura(71556)
    or player:HasAura(71485) or player:HasAura(71492)
    then
        return -- If DBW still active, don't change display ID as it will reset once DBW buff ends
    else
        local guid = player:GetGUIDLow()
        if (player:HasAura(768) or player:HasAura(32356) or player:HasAura(3025)) then -- Cat
            if not morphSelection1[guid] then
                local morphdb1 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 1") -- Load active morph status as a failsafe
                if morphdb1 then 
                    morphSelection1[guid] = morphdb1:GetUInt32(0)
                end
            end
            player:SetDisplayId(morphSelection1[guid])
            player:RemoveEventById(eventId)
        elseif player:HasAura(9634) or player:HasAura(5487) then -- Bear
            if not morphSelection2[guid] then
                local morphdb2 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 2") -- Load active morph status
                if morphdb2 then 
                    morphSelection2[guid] = morphdb2:GetUInt32(0)
                end
            end
            player:SetDisplayId(morphSelection2[guid])
            player:RemoveEventById(eventId)
        elseif player:HasAura(783) then -- Travel
            if not morphSelection3[guid] then
                local morphdb3 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 3") -- Load active morph status
                if morphdb3 then 
                    morphSelection3[guid] = morphdb3:GetUInt32(0)
                end
            end
            player:SetDisplayId(morphSelection3[guid])
            player:RemoveEventById(eventId)
        elseif player:HasAura(40120) or player:HasAura(33943) then -- Fly
            if not morphSelection4[guid] then
                local morphdb4 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 4") -- Load active morph status
                if morphdb4 then 
                    morphSelection4[guid] = morphdb4:GetUInt32(0)
                end
            end
            player:SetDisplayId(morphSelection4[guid])
            player:RemoveEventById(eventId)
        elseif player:HasAura(33891) then -- Tree
            if not morphSelection5[guid] then
                local morphdb5 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 5") -- Load active morph status
                if morphdb5 then 
                    morphSelection5[guid] = morphdb5:GetUInt32(0)
                end
            end
            player:SetDisplayId(morphSelection5[guid])
            player:RemoveEventById(eventId)
        elseif player:HasAura(24858) then -- Boomkin
            if not morphSelection6[guid] then
                local morphdb6 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 6") -- Load active morph status
                if morphdb6 then 
                    morphSelection6[guid] = morphdb6:GetUInt32(0)
                end
            end
            player:SetDisplayId(morphSelection6[guid])
            player:RemoveEventById(eventId)
        elseif player:HasAura(1066) then -- Aquatic
            if not morphSelection7[guid] then
                local morphdb7 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 7") -- Load active morph status
                if morphdb7 then 
                    morphSelection7[guid] = morphdb7:GetUInt32(0)
                end
            end
            player:SetDisplayId(morphSelection7[guid])
            player:RemoveEventById(eventId)
        end
    end
end

local function HideWeapon(eventId, delay, repeats, player) 
    if player then
        local guid = player:GetGUIDLow()
        
        if (player:HasAura(768) or player:HasAura(32356) or player:HasAura(3025)) and (morphSelection1[guid] and (player:GetDisplayId() == morphSelection1[guid])) then
            player:AddAura(InvisibleWeapon, player)
        else
            player:RemoveEventById(eventId)
            repetitionCount[guid] = nil
        end
        
        repetitionCount[guid] = (repetitionCount[guid] or 0) + 1
        
        if repetitionCount[guid] >= MAX_REPETITIONS then
            player:RemoveEventById(eventId)
            repetitionCount[guid] = nil
        end
    else
        RemoveEventById(eventId)
    end
end

function Morpher(eventId, delay, repeats, player)
    if player and player:GetClass() == 11 and player:HasItem(17890) and not player:IsPvPFlagged() and player:IsAlive() then
        local guid = player:GetGUIDLow()
        
        if player:HasAura(3025) then -- Cat
            if not morphSelection1[guid] then
                local morphdb1 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 1") -- Load active morph status
                if morphdb1 then 
                    morphSelection1[guid] = morphdb1:GetUInt32(0)
                end
            end
            if morphSelection1[guid] and morphSelection1[guid] > 0 then
                player:SetDisplayId(morphSelection1[guid])
                if player:IsInCombat() then
                    player:RegisterEvent(HideWeapon, InvisibleWeaponTimer, 1)
                elseif not player:IsInCombat() then
                    player:RegisterEvent(HideWeapon, InvisibleWeaponTimer, 2)
                end
            end
        elseif player:HasAura(9634) or player:HasAura(5487) then -- Bear
            if not morphSelection1[guid] then
                local morphdb2 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 2") -- Load active morph status
                if morphdb2 then 
                    morphSelection2[guid] = morphdb2:GetUInt32(0)
                end
            end
            if morphSelection2[guid] then
                if morphSelection2[guid] > 0 then
                    player:SetDisplayId(morphSelection2[guid])
                end
            end
        elseif player:HasAura(783) then -- Travel
            if not morphSelection3[guid] then
                local morphdb3 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 3")
                if morphdb3 then 
                    morphSelection3[guid] = morphdb3:GetUInt32(0)
                end
            end
            if morphSelection3[guid] then
                if morphSelection3[guid] > 0 then
                    player:SetDisplayId(morphSelection3[guid])
                    
                    local creatureName = "Unknown"
                    if creatureCache[guid] and creatureCache[guid][3] then
                        for _, creature in ipairs(creatureCache[guid][3]) do
                            if creature.displayId == morphSelection3[guid] then
                                creatureName = creature.name
                                break
                            end
                        end
                    end
                    
                    if creatureCache[guid] and creatureCache[guid][3] then
                        local morphCount = #creatureCache[guid][3]
                        if morphCount >= 10 then
                            local tier = math.min(math.floor(morphCount / 10), 5)
                            local travelSpeed = 1.4 + (tier * 0.1)
                            player:SetSpeed(1, travelSpeed)
                        end
                    end
                end
            end
        elseif player:HasAura(40120) or player:HasAura(33943) then -- Fly
            if not morphSelection4[guid] then
                local morphdb4 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 4")
                if morphdb4 then 
                    morphSelection4[guid] = morphdb4:GetUInt32(0)
                end
            end
            if morphSelection4[guid] then
                if morphSelection4[guid] > 0 then
                    player:SetDisplayId(morphSelection4[guid])
                    if creatureCache[guid] and creatureCache[guid][4] and #creatureCache[guid][4] >= 5 then
                        local morphs = #creatureCache[guid][4]
                        local tier = math.min(math.floor(morphs / 5), 5)
                        local baseSpeed = 2.5
                        if player:HasSpell(40120) then baseSpeed = 3.8 end
                        for _, fastMountId in ipairs(FastFlightMounts) do
                            if player:HasSpell(fastMountId) then
                                baseSpeed = 4.1
                                break
                            end
                        end
                        local flightSpeed = baseSpeed + (tier * 0.05)
                        player:SetSpeed(6, flightSpeed)
                    end
                end
            end
        elseif player:HasAura(33891) then -- Tree
            if not morphSelection5[guid] then
                local morphdb5 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 5") -- Load active morph status
                if morphdb5 then 
                    morphSelection5[guid] = morphdb5:GetUInt32(0)
                end
            end
            if morphSelection5[guid] then
                if morphSelection5[guid] > 0 then
                    player:SetDisplayId(morphSelection5[guid])
                end
            end
        elseif player:HasAura(24858) then -- Boomkin
            if not morphSelection6[guid] then
                local morphdb6 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 6") -- Load active morph status
                if morphdb6 then 
                    morphSelection6[guid] = morphdb6:GetUInt32(0)
                end
            end
            if morphSelection6[guid] then
                if morphSelection6[guid] > 0 then
                    player:SetDisplayId(morphSelection6[guid])
                end
            end
        elseif player:HasAura(1066) then -- Aquatic
            if not morphSelection7[guid] then
                local morphdb7 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 7") -- Load active morph status
                if morphdb7 then 
                    morphSelection7[guid] = morphdb7:GetUInt32(0)
                end
            end
            if morphSelection7[guid] then
                if morphSelection7[guid] > 0 then
                    player:SetDisplayId(morphSelection7[guid])
                    if creatureCache[guid] and creatureCache[guid][7] and #creatureCache[guid][7] >= 5 then
                        local morphs = #creatureCache[guid][7]
                        local tier = math.min(math.floor(morphs / 5), 8)
                        local aquaticSpeed = 1.5 + (tier * 0.05) * 0.75
                        player:SetSpeed(3, aquaticSpeed)
                    end
                end
            end
        end
    end
end

local function Shapeshift(event, player, spell, skipCheck)
    local spellId = spell:GetEntry()
    if not player:HasItem(17890) then return end
    if not (player:GetClass() == 11) then return end
    if player:IsPvPFlagged() then return end
    
    if
    (spellId == 768 or spellId == 9634
    or spellId == 5487 or spellId == 783
    or spellId == 40120 or spellId == 33943
    or spellId == 33891 or spellId == 24858
    or spellId == 1066
    -- DBW below
    --or spellId == 71561 or spellId == 71492
    --or spellId == 71484 or spellId == 71560
    --or spellId == 71556 or spellId == 71485 
    )
    then
        
        local playerName = player:GetName()
        
        local guid = player:GetGUIDLow()
        local formId = formSelections[guid]
        if formId ~= 0 then
            formid = 0
        end

        if spellId == 768 and morphSelection1[guid] then
            formId = 1 -- Cat Form
            player:RegisterEvent(Morpher, MorphApplicationDelay, MorphRepeats)
        elseif (spellId == 9634 or spellId == 5487) and morphSelection2[guid] then
            formId = 2 -- Bear Form
            player:RegisterEvent(Morpher, MorphApplicationDelay, MorphRepeats)
        elseif spellId == 783 and morphSelection3[guid] then
            formId = 3 -- Travel Form
            player:RegisterEvent(Morpher, MorphApplicationDelay, MorphRepeats)
        elseif (spellId == 40120 or spellId == 33943) and morphSelection4[guid] then
            formId = 4 -- Flight Form
            player:RegisterEvent(Morpher, MorphApplicationDelay, MorphRepeats)
        elseif spellId == 33891 and morphSelection5[guid] then
            formId = 5 -- Tree Form
            player:RegisterEvent(Morpher, MorphApplicationDelay, MorphRepeats)
        elseif spellId == 24858 and morphSelection6[guid] then
            formId = 6 -- Boomkin Form
            player:RegisterEvent(Morpher, MorphApplicationDelay, MorphRepeats)
        elseif spellId == 1066 and morphSelection7[guid] then
            formId = 7 -- Aquatic Form    
            player:RegisterEvent(Morpher, MorphApplicationDelay, MorphRepeats)

        else
            return
        end
    end
end

local function onLogout(event, player) -- Clean up cache on logout
    if player:GetClass() == 11 and player:HasItem(17890) then
        local guid = player:GetGUIDLow()
        repetitionCount[guid] = nil 
        creatureCache[guid] = nil 
        formSelections[guid] = nil 
        morphSelection1[guid] = nil 
        morphSelection2[guid] = nil 
        morphSelection3[guid] = nil 
        morphSelection4[guid] = nil 
        morphSelection5[guid] = nil 
        morphSelection6[guid] = nil 
        morphSelection7[guid] = nil
        searchQueries[guid] = nil
        searchResults[guid] = nil
    end
end

local function OnLogin(event, player)
    if player:GetClass() == 11 and player:HasItem(17890) and not player:IsPvPFlagged() then 
        local guid = player:GetGUIDLow()
        local playername = player:GetName()
 
        LoadPlayerMorphs(player) -- Load full list of player morphs from db into cache
        
        CharDBQueryAsync("SELECT id, form FROM character_morphs WHERE guid = "..guid.." AND active = 1", function(morphdb)
            if morphdb then
                local player = GetPlayerByName(playername)
                if not player then return end
                repeat
                    local id = morphdb:GetUInt32(0)
                    local form = morphdb:GetUInt32(1)
                    
                    if form == 1 then
                        morphSelection1[guid] = id
                    elseif form == 2 then
                        morphSelection2[guid] = id
                    elseif form == 3 then
                        morphSelection3[guid] = id
                    elseif form == 4 then
                        morphSelection4[guid] = id
                    elseif form == 5 then
                        morphSelection5[guid] = id
                    elseif form == 6 then
                        morphSelection6[guid] = id
                    elseif form == 7 then
                        morphSelection7[guid] = id
                    end
                until not morphdb:NextRow()
                
                if not morphdb:NextRow() then
                    if (player:HasAura(768)    or player:HasAura(9634)
                    or player:HasAura(5487)    or player:HasAura(783)
                    or player:HasAura(33891) or player:HasAura(24858)
                    or player:HasAura(1066)) or player:HasAura(40120) 
                    then
                        player:RegisterEvent(Morpher, 20, 1)
                    end
                end
            end
        end)
    end
end

local function ReloadEluna(event)
    local players = GetPlayersInWorld()
    for _, player in ipairs(players) do
        if player:GetClass() == 11 and player:HasItem(17890) and not player:IsPvPFlagged() then 
            local guid = player:GetGUIDLow()
            local playername = player:GetName()
     
            LoadPlayerMorphs(player) -- Load full list of player morphs from db into cache
            
            CharDBQueryAsync("SELECT id, form FROM character_morphs WHERE guid = "..guid.." AND active = 1", function(morphdb)
                if morphdb then
                    local player = GetPlayerByName(playername)
                    repeat
                        local id = morphdb:GetUInt32(0)
                        local form = morphdb:GetUInt32(1)
                        
                        if form == 1 then
                            morphSelection1[guid] = id
                        elseif form == 2 then
                            morphSelection2[guid] = id
                        elseif form == 3 then
                            morphSelection3[guid] = id
                        elseif form == 4 then
                            morphSelection4[guid] = id
                        elseif form == 5 then
                            morphSelection5[guid] = id
                        elseif form == 6 then
                            morphSelection6[guid] = id
                        elseif form == 7 then
                            morphSelection7[guid] = id
                        end
                    until not morphdb:NextRow()
                    
                    if not morphdb:NextRow() then
                        if (player:HasAura(768)    or player:HasAura(9634)
                        or player:HasAura(5487)    or player:HasAura(783)
                        or player:HasAura(33891) or player:HasAura(24858)
                        or player:HasAura(1066) or player:HasAura(40120)) and
                        not (player:GetDisplayId() == (
                            morphSelection1[guid] or morphSelection2[guid] or 
                            morphSelection3[guid] or morphSelection4[guid] or 
                            morphSelection5[guid] or morphSelection6[guid] 
                            or morphSelection7[guid]))
                        then
                            player:RegisterEvent(Morpher, 20, 1)
                        end
                    end
                end
            end)
        end
    end
end

local function OnCombat(event, player, enemy)
    if player:GetClass() == 11 and player:HasItem(17890) then
        if enemy and enemy:IsPvPFlagged() then
            player:DeMorph()
            if player:HasAura(768) then -- Cat
                player:AddAura(768, player)
            elseif player:HasAura(9634) or player:HasAura(5487) then
                if player:HasAura(9634) then
                    player:AddAura(9634, player)
                elseif player:HasAura(5487) then
                    player:AddAura(5487, player)
                end
            elseif player:HasAura(783) then -- Travel
                player:AddAura(783, player)
            elseif player:HasAura(40120) or player:HasAura(33943) then  -- Bird
                if player:HasAura(40120) then
                    player:AddAura(40120, player)
                elseif player:HasAura(33943) then
                    player:AddAura(33943, player)
                end
            elseif player:HasAura(33891) then  -- Tree
                player:AddAura(33891, player)
            elseif player:HasAura(24858) then -- Boomkin 
                player:AddAura(24858, player)
            elseif player:HasAura(1066) then -- Aquatic 
                player:AddAura(1066, player)
            end
        end
        if (not enemy or (enemy and not enemy:IsPvPFlagged())) and player:HasAura(3025) then
            local guid = player:GetGUIDLow()
            player:RegisterEvent(HideWeapon, InvisibleWeaponTimer, 1) -- 0 repetitions = infinite
        end
    end
end

local function DBMMorph(event, player, command)
    if command == "dbmmorph" then
        if player:IsAlive() then
            player:RegisterEvent(Morpher, 0)
        end
        return false
    end
end

CacheCreatures() -- Caching available creatures from world DB on script initialization

RegisterPlayerEvent(3, OnLogin) 
RegisterPlayerEvent(4, onLogout)
RegisterSpellEvent(768, 2, Shapeshift)
RegisterSpellEvent(9634, 2, Shapeshift)
RegisterSpellEvent(5487, 2, Shapeshift)
RegisterSpellEvent(783, 2, Shapeshift)
RegisterSpellEvent(40120, 2, Shapeshift)
RegisterSpellEvent(33943, 2, Shapeshift)
RegisterSpellEvent(33891, 2, Shapeshift)
RegisterSpellEvent(24858, 2, Shapeshift)
RegisterSpellEvent(1066, 2, Shapeshift)
RegisterPlayerEvent(7, OnKillCreature)
RegisterPlayerEvent(28, CheckIfNeedToApplyMorph)
RegisterPlayerEvent(33, OnCombat)
RegisterPlayerEvent(42, DBMMorph)
RegisterItemGossipEvent(ITEM_ID, 1, OnGossipHello)
RegisterPlayerGossipEvent(0, 2, OnGossipSelect)
RegisterServerEvent(33, ReloadEluna) -- On reload eluna    
