--VARIABLES
local ITEM_ID = 17890 -- On-use trigger item
local MorphApplicationDelay = 15-- Delay in MS, if too fast it will throw off the shapeshift
local MorphRepeats = 1 -- In case too fast, try again after a short delay (optional, 1 = only one attempt)
local DBWDelay = 25 -- Delay in DBW proc failsafe
local DBWRepeats = 30100/DBWDelay -- Loops reapplication of morph over the duration of DBW, ie. just over 30 sec. Used to be but set to 1 as this caused issues with certain cat abilities
local InvisibleWeapon = 58976 -- Low-impact disarm spell to correct weapon visibility on cat morphs, applied every 3 sec
local InvisibleWeaponTimer = 800 -- Duration of disarm
local MAX_REPETITIONS = 1 -- Number of times cat form disarm is applied per spell cast (20 covers about 10 seconds of hidden weapon)
local MorphReqRare = 100 -- Skill required to claim morph forms of elites
local MorphReqElite = 50 -- Skill required to claim morph forms of elites
local MaxMorphSkill = 150 -- Max morphing skill cap, not sure if this is attainable at the moment

local creatureCache = {
    [1] = {}, -- Cat form
    [2] = {}, -- Bear form
    [3] = {}, -- Travel form
    [4] = {},  -- Flight form
    [5] = {},  -- Tree form
    [6] = {},  -- Boomkin form
    [7] = {}  -- Boomkin form
}
local catCache = {}
local bearCache = {}
local birdCache = {}
local travelCache = {}
local owlCache = {}
local treeCache = {}
local aquaticCache = {}

local eventIds = {}
local repetitionCount = {}

local formSelections = {}
local morphSelection1 = {}
local morphSelection2 = {}
local morphSelection3 = {}
local morphSelection4 = {}
local morphSelection5 = {}
local morphSelection6 = {}
local morphSelection7 = {}

local morphQueue = {}

local ITEMS_PER_PAGE = 13

local function CacheCreatures()
	local catCount, bearCount, birdCount, travelCount, owlCount, treeCount, aquaticCount = 0, 0, 0, 0, 0, 0, 0

    -- Cat cache
    local catResults = WorldDBQuery("SELECT entry, name FROM creature_template WHERE family = 2 OR ((name LIKE '%panther%' OR name LIKE '%gondria%' OR name LIKE '%loque%') AND type = 1)")
    if catResults then
        repeat
            local entry, name = catResults:GetUInt32(0), catResults:GetString(1)
            catCache[entry] = name
			catCount = catCount + 1
        until not catResults:NextRow()
    end

    -- Bear cache
    local bearResults = WorldDBQuery("SELECT entry, name FROM creature_template WHERE family = 4 OR name LIKE '%arcturis%' OR name LIKE '%grizzly cub%'")
    if bearResults then
        repeat
            local entry, name = bearResults:GetUInt32(0), bearResults:GetString(1)
            bearCache[entry] = name
			bearCount = bearCount + 1
        until not bearResults:NextRow()
    end

    -- Bird cache
    local birdResults = WorldDBQuery("SELECT entry, name FROM creature_template WHERE family IN (7, 26, 30, 33, 34, 37, 38) OR ((name LIKE '%highperch%' OR name LIKE '%wyvern%' OR name LIKE '%heartrazor%') AND type = 1)")
    if birdResults then
        repeat
            local entry, name = birdResults:GetUInt32(0), birdResults:GetString(1)
            birdCache[entry] = name
			birdCount = birdCount +1
        until not birdResults:NextRow()
    end
	
	-- Travel cache
	local travelResults = WorldDBQuery("SELECT entry, name FROM creature_template WHERE family IN (1, 11, 12, 39) OR (((name LIKE '%riding wolf%' OR name LIKE '%caribou%' OR name LIKE '%fawn%' OR name LIKE '%bach%' OR name LIKE '%grazer%' OR name LIKE '%giraffe%' OR name LIKE '%gazelle%' OR name LIKE '%zhevra%' OR name LIKE '%snickerfang%' OR name LIKE '%hyena%' OR name LIKE '%mosshoof%' OR name LIKE '%talbuk%' OR name LIKE '%elk%' OR name LIKE '%stag%' OR name LIKE '%goat%' OR name LIKE '%mustang%' OR name LIKE '%buck%' OR name LIKE '%ram%')) AND type = 1)")
    if travelResults then
        repeat
            local entry, name = travelResults:GetUInt32(0), travelResults:GetString(1)
            travelCache[entry] = name
            travelCount = travelCount + 1
        until not travelResults:NextRow()
    end
	
	-- Owlkin cache
    local owlResults = WorldDBQuery("SELECT entry, name FROM creature_template WHERE name LIKE '%owlkin%' OR name LIKE '%wildkin%' OR name LIKE '%owlbeast%' OR name LIKE '%moonkin%'")
    if owlResults then
        repeat
            local entry, name = owlResults:GetUInt32(0), owlResults:GetString(1)
            owlCache[entry] = name
            owlCount = owlCount + 1
        until not owlResults:NextRow()
    end
	
	-- Tree cache
	local treeResults = WorldDBQuery("SELECT entry, name FROM creature_template WHERE name LIKE '%root-walker%' OR name LIKE '%treant%' OR name LIKE '%withered green keeper%' OR name LIKE '%Withered Ancient%' OR name LIKE '%Wood Ent%' OR name LIKE '%Unbound Ent%' OR name LIKE '%Mangrove Ent%' OR name LIKE '%Dispirited Ent%' OR name LIKE '%sapling%' OR name LIKE '%Darnassian Proector%' OR name LIKE '%Crazed Ancient%' OR name LIKE '%Crystalline Keeper%' OR name LIKE '%Irontree%' OR name LIKE '%tender%' AND type = 4")
    if treeResults then
        repeat
            local entry, name = treeResults:GetUInt32(0), treeResults:GetString(1)
            treeCache[entry] = name
            treeCount = treeCount + 1
        until not treeResults:NextRow()
    end
		-- Aquatic cache
	local aquaticResults = WorldDBQuery("SELECT entry, name FROM creature_template WHERE ((name LIKE '%sewer beast%' OR name LIKE '%mako%' OR name LIKE '%seal%' OR name LIKE '%rippa%' OR name LIKE '%orca%' OR name LIKE '%lake frenzy%' OR name LIKE '%sporewind frenzy%' OR name LIKE '%underbog frenzy%' OR name LIKE '%yellowgill frenzy%' OR name LIKE '%reef frenzy%' OR name LIKE '%canal frenzy%' OR name LIKE '%muck frenzy%' OR name LIKE '%coilfang frenzy%' OR name LIKE '%sharptooth frenzy%' OR name LIKE '%coastal frenzy%' OR name LIKE '%drakkari frenzy%' OR name LIKE '%loch frenzy%' OR name LIKE '%hooktooth%' OR name LIKE '%mudfin%' OR name LIKE '%shark%' OR name LIKE '%thresh%' OR name LIKE '%eel%' OR name LIKE '%hammerhead%' OR name LIKE '%whitetail%' OR name LIKE '%crocolisk%' OR name LIKE '%sawfin%') AND type = 1)")
    if aquaticResults then
        repeat
            local entry, name = aquaticResults:GetUInt32(0), aquaticResults:GetString(1)
            aquaticCache[entry] = name
            aquaticCount = aquaticCount + 1
        until not aquaticResults:NextRow()
    end
	
    print("[Druid Morph Module]: Cat forms cached: "..catCount)
    print("[Druid Morph Module]: Bear forms cached: "..bearCount)
    print("[Druid Morph Module]: Bird forms cached: "..birdCount)
    print("[Druid Morph Module]: Travel forms cached: "..travelCount)
    print("[Druid Morph Module]: Owlkin forms cached: "..owlCount)
	print("[Druid Morph Module]: Tree forms cached: "..treeCount)
	print("[Druid Morph Module]: Aquatic forms cached: "..aquaticCount)
end

local function LoadPlayerMorphs(player)
    if player:GetClass() ~= 11 then return end -- Only proceed for druids
    
    local guid = player:GetGUIDLow()

    if not creatureCache[guid] then
        creatureCache[guid] = {}
    end
    
    local results = CharDBQuery("SELECT name, id, form FROM character_morphs WHERE guid = "..guid)
    
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
end

local function SavePlayerMorph(player, name, displayId, formIndex)
    if player:GetClass() ~= 11 then return end
    local guid = player:GetGUIDLow()
    local escapedName = string.gsub(name, "'", "''") -- Fixes crashes on Loque'Nahak and other NPCs with ' in name
	CharDBExecute("INSERT INTO character_morphs (guid, name, id, form) VALUES ("..guid..", '"..escapedName.."', "..displayId..", "..formIndex..")")
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

local function OnKillCreature(event, player, creature)
    if player:GetClass() ~= 11 then return end  -- Only proceed for druids
    if not player:HasItem(17890) then return end -- Only proceed if player has bought medallion

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
            if creature:GetRank() == 1 then -- Elites
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
					if #creatureCache[guid][3] >= 10 then 
						player:SetSpeed(1, 1.5)
						player:SendBroadcastMessage("Through your exquisite knowledge of travel forms, your travel form speed has increased to 50%.")
					elseif #creatureCache[guid][3] >= 20 then 
						player:SetSpeed(1, 1.6)
						player:SendBroadcastMessage("Through your exquisite knowledge of travel forms, your travel form speed has increased to 60%.")
					elseif #creatureCache[guid][3] >= 30 then 
						player:SetSpeed(1, 1.7)
						player:SendBroadcastMessage("Through your exquisite knowledge of travel forms, your travel form speed has increased to 70%.")
					elseif #creatureCache[guid][3] >= 40 then 
						player:SetSpeed(1, 1.8)
						player:SendBroadcastMessage("Through your exquisite knowledge of travel forms, your travel form speed has increased to 80%.")
					elseif #creatureCache[guid][3] >= 50 then 
						player:SetSpeed(1, 1.9)
						player:SendBroadcastMessage("Through your exquisite knowledge of travel forms, your travel form speed has increased to 90%.")
					end
                end
            elseif creature:GetRank() == 2 or creature:GetRank() == 4 then -- Rares and rare elites
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
            elseif creature:GetRank() ~= 3 then -- Prevents learning boss display IDs as morphs as their models are usually huge
                table.insert(creatureCache[guid][cacheIndex], {name = creatureName, displayId = displayId})
                SavePlayerMorph(player, creatureName, displayId, cacheIndex)
                if CountTotalMorphs(player) < MaxMorphSkill then
                    player:SendBroadcastMessage("You have released "..creatureName.."'s spirit and learned how to morph into their "..formType..". Your morph skill has increased to "..CountTotalMorphs(player)..".")
                else
                    player:SendBroadcastMessage("You have released "..creatureName.."'s spirit and learned how to morph into their "..formType..".")
                end
            end
        end
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
        AddToPlayerCache(1, formTypes[1])
    elseif bearCache[entry] then
        AddToPlayerCache(2, formTypes[2])
    elseif travelCache[entry] then
        AddToPlayerCache(3, formTypes[3])
    elseif birdCache[entry] then
        AddToPlayerCache(4, formTypes[4])
    elseif treeCache[entry] then
        AddToPlayerCache(5, formTypes[5])
    elseif owlCache[entry] then
        AddToPlayerCache(6, formTypes[6])
    elseif aquaticCache[entry] then
        AddToPlayerCache(7, formTypes[7])
    end
end

local function ShowInitialGossipMenu(player)
	player:GossipMenuAddItem(4, "How does morphing work?", 0, 10)
    --player:GossipMenuAddItem(4, "What would you like to morph?", 0, 9)
    player:GossipMenuAddItem(0, "Cat form", 0, 1)
    player:GossipMenuAddItem(0, "Bear form", 0, 2)
    player:GossipMenuAddItem(0, "Travel form", 0, 3)
    player:GossipMenuAddItem(0, "Flight form", 0, 4)
    player:GossipMenuAddItem(0, "Tree form", 0, 5)
    player:GossipMenuAddItem(0, "Boomkin form", 0, 6)
    player:GossipMenuAddItem(0, "Aquatic form", 0, 7)
    player:GossipMenuAddItem(0, "Remove current morph", 0, 8)
    player:GossipMenuAddItem(0, "Morph skill: "..CountTotalMorphs(player).."/"..MaxMorphSkill.."", 0, 9)
    player:GossipSendMenu(1, player, 0)
end

local function ShowGossipPage(player, formId, page)
    local guid = player:GetGUIDLow()

    if not creatureCache[guid] or not creatureCache[guid][formId] or #creatureCache[guid][formId] == 0 then
        player:SendAreaTriggerMessage("You have no available morphs for this form!")
        ShowInitialGossipMenu(player)
        return
    end
    
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

        player:GossipMenuAddItem(2, name, 0, 100000 + creature.displayId)
    end
    
    if page > 1 then
        player:GossipMenuAddItem(4, "Previous Page", 0, 200000 + page - 1)
    end
    
    if endIndex < #creatureCache[guid][formId] then
        player:GossipMenuAddItem(4, "Next Page", 0, 200000 + page + 1)
    end
    
    player:GossipMenuAddItem(4, "Back to main menu", 0, 2000000)
    player:GossipSendMenu(1, player, 0)
end

local function OnGossipSelect(event, player, object, sender, intid, code, menu_id)
    --print("[Druid Morph Module]: OnGossipSelect called with intid:", intid) -- Debug print
	
	if player:IsPvPFlagged() then player:SendAreaTriggerMessage("You can't use druid morphs while flagged for PvP.") return false end

    if intid == 10 then
		player:GossipMenuAddItem(0, "Morphing is an ancient Darnassian magic that permits druids to transmogrify their shapeshifts into the shapes of creatures they have released the spirit from. Killing a valid creature lets you morph your shapeshift of the same type into the newly acquired form. Every unique form claimed increases your morphing skill by 1. To claim the form of elite creatures, you need to have a morphing skill of at least "..MorphReqElite..", and to claim the form of rare creatures, you need a skill of "..MorphReqRare..".", 0, 10)
		player:GossipMenuAddItem(0, "Go back", 0, 9)
		player:GossipSendMenu(1, player, 0)
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
		print("[Druid Morph Module]: Form ID: "..formId..". Display ID: "..displayId..".")
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
			if player:HasAura(9634) or player:HasAura(5487)  then
				player:SetDisplayId(morphSelection2[guid])
			end
			CharDBExecute("UPDATE character_morphs SET active = 0 WHERE guid = "..guid.." AND form = 2")
			CharDBExecute("UPDATE character_morphs SET active = 1 WHERE guid = "..guid.." AND id = "..morphSelection2[guid])
		elseif formId == 3 and creatureCache[formId] then
			morphSelection3[guid] = displayId
			--print("Total entries for GUID " .. guid .. " in formId " .. formId .. ": " .. #creatureCache[guid][formId])

			-- Existing logic for handling formId 3
			if player:HasAura(783) then
				player:SetDisplayId(morphSelection3[guid])
				if player:HasAura(783) then
					player:SetDisplayId(morphSelection3[guid])
					if #creatureCache[guid][formId] >= 50 then 
						player:SetSpeed(1, 1.9)
						player:SendBroadcastMessage("You have morphed your travel form into "..creatureName..". Your travel speed is now 90%.")
					elseif #creatureCache[guid][formId] >= 40 then 
						player:SetSpeed(1, 1.8)
						player:SendBroadcastMessage("You have morphed your travel form into "..creatureName..". Your travel speed is now 80%.")
					elseif #creatureCache[guid][formId] >= 30 then 
						player:SetSpeed(1, 1.7)
						player:SendBroadcastMessage("You have morphed your travel form into "..creatureName..". Your travel speed is now 70%.")
					elseif #creatureCache[guid][formId] >= 20 then 
						player:SetSpeed(1, 1.6)
						player:SendBroadcastMessage("You have morphed your travel form into "..creatureName..". Your travel speed is now 60%.")
					elseif #creatureCache[guid][formId] >= 10 then 
						player:SetSpeed(1, 1.5)
						player:SendBroadcastMessage("You have morphed your travel form into "..creatureName..". Your travel speed is now 50%.")
					else
						player:SendBroadcastMessage("You have morphed your travel form into "..creatureName..".")
					end
				end
			end
			CharDBExecute("UPDATE character_morphs SET active = 0 WHERE guid = "..guid.." AND form = 3")
			CharDBExecute("UPDATE character_morphs SET active = 1 WHERE guid = "..guid.." AND id = "..morphSelection3[guid])
        elseif formId == 4 and creatureCache[formId] then
            morphSelection4[guid] = displayId
            player:SendBroadcastMessage("You have morphed your flight form into "..creatureName..".")
			if player:HasAura(40120) or player:HasAura(33943)  then
				player:SetDisplayId(morphSelection4[guid])
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
            player:SendBroadcastMessage("You have morphed your aquatic form into "..creatureName..".")
			if player:HasAura(1066) then 
				player:SetDisplayId(morphSelection7[guid])
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
	else
		ShowInitialGossipMenu(player)
    end
end

local function OnGossipHello(event, player, object)
    --print("[Druid Morph Module]: OnGossipHello called") -- Debug print
    if player:GetClass() == 11 then -- Check if player is a druid
		if player:IsPvPFlagged() then player:SendAreaTriggerMessage("You can't use druid morphs while flagged for PvP.") return false end
        player:GossipComplete()
        ShowInitialGossipMenu(player)
        return false
    end
    return false
end

local function DBWfix() -- PERFORMANCE KILLER, CHANGE THIS IN THE FUTURE. THIS SCANS ALL PLAYERS FOR GIVEN BUFFS! NOT IDEAL!
    local players = GetPlayersInWorld()
    for _, player in ipairs(players) do
        if (player:GetClass() == 11 and (player:HasAura(71561) or player:HasAura(71484) or player:HasAura(71560) or player:HasAura(71556) or player:HasAura(71485) or player:HasAura(71492))) then return end
        if (player:GetClass() == 11 and not (player:HasAura(71561) or player:HasAura(71484) or player:HasAura(71560) or player:HasAura(71556) or player:HasAura(71485) or player:HasAura(71492))) then
            local guid = player:GetGUIDLow()
			if (player:HasAura(768) or player:HasAura(32356) or player:HasAura(3025)) then -- Cat
				local morphdb1 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 1") -- Load active morph status
				if morphdb1 then 
					morphSelection1[guid] = morphdb1:GetUInt32(0)
				end
				if morphSelection1[guid] then
					player:SetDisplayId(morphSelection1[guid])
				end
			elseif player:HasAura(9634) or player:HasAura(5487) then -- Bear
				local morphdb2 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 2") -- Load active morph status
				if morphdb2 then 
					morphSelection2[guid] = morphdb2:GetUInt32(0)
				end
				if morphSelection2[guid] then
					player:SetDisplayId(morphSelection2[guid])
				end
			elseif player:HasAura(783) then -- Travel
				local morphdb3 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 3") -- Load active morph status
				if morphdb3 then 
					morphSelection3[guid] = morphdb3:GetUInt32(0)
				end
				if morphSelection3[guid] then
					player:SetDisplayId(morphSelection3[guid])
				end
			elseif player:HasAura(40120) or player:HasAura(33943) then -- Fly
				local morphdb4 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 4") -- Load active morph status
				if morphdb4 then 
					morphSelection4[guid] = morphdb4:GetUInt32(0)
				end
				if morphSelection4[guid] then
					player:SetDisplayId(morphSelection4[guid])
				end
			elseif player:HasAura(33891) then -- Tree
				local morphdb5 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 5") -- Load active morph status
				if morphdb5 then 
					morphSelection5[guid] = morphdb5:GetUInt32(0)
				end
				if morphSelection5[guid] then
					player:SetDisplayId(morphSelection5[guid])
				end
			elseif player:HasAura(24858) then -- Boomkin
				local morphdb6 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 6") -- Load active morph status
				if morphdb6 then 
					morphSelection6[guid] = morphdb6:GetUInt32(0)
				end
				if morphSelection6[guid] then
					player:SetDisplayId(morphSelection6[guid])
				end
			elseif player:HasAura(1066) then -- Aquatic
				local morphdb7 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 7") -- Load active morph status
				if morphdb7 then 
					morphSelection7[guid] = morphdb7:GetUInt32(0)
				end
				if morphSelection7[guid] then
					player:SetDisplayId(morphSelection7[guid])
				end
			end
		end
	end
end

local function HideWeapon()
    local players = GetPlayersInWorld()
    for _, player in ipairs(players) do
        if player and type(player) == "userdata" then
            local guid = player:GetGUIDLow()
            if (player:HasAura(768) or player:HasAura(32356) or player:HasAura(3025)) and player:GetDisplayId() == morphSelection1[guid] then
                player:AddAura(InvisibleWeapon, player)
                --print("[Druid Morph Module]: Weapon hidden!")
            else
				if eventIds[guid] then
                    RemoveEventById(eventIds[guid])
                    eventIds[guid] = nil
                    repetitionCount[guid] = nil
				end
			end
            
            if eventIds[guid] then
                repetitionCount[guid] = (repetitionCount[guid] or 0) + 1
				--print(repetitionCount[guid])
                if repetitionCount[guid] >= MAX_REPETITIONS then
                    RemoveEventById(eventIds[guid])
                    eventIds[guid] = nil
                    repetitionCount[guid] = nil
                    print("[Druid Morph Module]: Removed hide weapon event for player: " .. player:GetName())
                end
            end
        end
    end
end

local function Morpher(eventId, delay, repeats, worldobject) -- TO-DO: Reduce server load; Change this to not check every druid with shapeshift applied, but just the one(s) that shapeshift(ed) instead.
	for playerName, _ in pairs(morphQueue) do
	
        local player = GetPlayerByName(playerName)
		
		if player and player ~= nil then
			morphQueue[player:GetName()] = nil
			
			if player:GetClass() == 11 and player:HasItem(17890) and not player:IsPvPFlagged() then 
				local guid = player:GetGUIDLow()
				
				if player:HasAura(71561) or player:HasAura(71484) or player:HasAura(71560) or player:HasAura(71556) or player:HasAura(71485) or player:HasAura(71492) then 
					print("[Druid Morph Module]: DBW stopped morph for "..player:GetName())
				
				elseif player:HasAura(3025) then -- Cat
					local morphdb1 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 1") -- Load active morph status
					if morphdb1 then 
						morphSelection1[guid] = morphdb1:GetUInt32(0)
					end
					if morphSelection1[guid] then
						if morphSelection1[guid] > 0 then
							player:SetDisplayId(morphSelection1[guid])
							print("[Druid Morph Module]: Morpher - Setting cat form of "..player:GetName().." to display ID "..morphSelection1[guid])
							if player:IsInCombat() then
								if eventIds[guid] then
									RemoveEventById(eventIds[guid])
									eventIds[guid] = nil
									repetitionCount[guid] = nil
									print("[Druid Morph Module]: Attempting to remove weapon in combat!")
								end
								eventIds[guid] = CreateLuaEvent(HideWeapon, InvisibleWeaponTimer, 1) -- 0 repetitions = infinite
							elseif not player:IsInCombat() then
								if eventIds[guid] then
									RemoveEventById(eventIds[guid])
									eventIds[guid] = nil
									repetitionCount[guid] = nil
									print("[Druid Morph Module]: Attempting to remove weapon outside of combat!")
								end
								eventIds[guid] = CreateLuaEvent(HideWeapon, InvisibleWeaponTimer, 2)
							end
						end
					end
				elseif player:HasAura(9634) then -- Bear
					local morphdb2 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 2") -- Load active morph status
					if morphdb2 then 
						morphSelection2[guid] = morphdb2:GetUInt32(0)
					end
					if morphSelection2[guid] then
						if morphSelection2[guid] > 0 then
							player:SetDisplayId(morphSelection2[guid])
							print("[Druid Morph Module]: Morpher - Setting bear form of "..player:GetName().." to display ID "..morphSelection2[guid])
						end
					end
				elseif player:HasAura(783) then -- Travel
					local morphdb3 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 3") -- Load active morph status
					if morphdb3 then 
						morphSelection3[guid] = morphdb3:GetUInt32(0)
						if #creatureCache[guid][3] >= 10 then 
							player:SetSpeed(1, 1.5)
						elseif #creatureCache[guid][3] >= 20 then 
							player:SetSpeed(1, 1.6)
						elseif #creatureCache[guid][3] >= 30 then 
							player:SetSpeed(1, 1.7)
						elseif #creatureCache[guid][3] >= 40 then 
							player:SetSpeed(1, 1.8)
						elseif #creatureCache[guid][3] >= 50 then 
							player:SetSpeed(1, 1.9)
						end
						print("[Druid Morph Module]: Morpher - Setting travel form of "..player:GetName().." to display ID "..morphSelection3[guid])
					end
					if morphSelection3[guid] then
						if morphSelection3[guid] > 0 then
							player:SetDisplayId(morphSelection3[guid])
						end
					end
				elseif player:HasAura(40120) or player:HasAura(33943) then -- Fly
					local morphdb4 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 4") -- Load active morph status
					if morphdb4 then 
						morphSelection4[guid] = morphdb4:GetUInt32(0)
					end
					if morphSelection4[guid] then
						if morphSelection4[guid] > 0 then
							player:SetDisplayId(morphSelection4[guid])
							print("[Druid Morph Module]: Morpher - Setting flight form of "..player:GetName().." to display ID "..morphSelection4[guid])
						end
					end
				elseif player:HasAura(33891) then -- Tree
					local morphdb5 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 5") -- Load active morph status
					if morphdb5 then 
						morphSelection5[guid] = morphdb5:GetUInt32(0)
					end
					if morphSelection5[guid] then
						if morphSelection5[guid] > 0 then
							player:SetDisplayId(morphSelection5[guid])
							print("[Druid Morph Module]: Morpher - Setting tree form of "..player:GetName().." to display ID "..morphSelection5[guid])
						end
					end
				elseif player:HasAura(24858) then -- Boomkin
					local morphdb6 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 6") -- Load active morph status
					if morphdb6 then 
						morphSelection6[guid] = morphdb6:GetUInt32(0)
					end
					if morphSelection6[guid] then
						if morphSelection6[guid] > 0 then
							player:SetDisplayId(morphSelection6[guid])
							print("[Druid Morph Module]: Morpher - Setting boomkin form of "..player:GetName().." to display ID "..morphSelection6[guid])
						end
					end
				elseif player:HasAura(1066) then -- Aquatic
					local morphdb7 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 7") -- Load active morph status
					if morphdb7 then 
						morphSelection7[guid] = morphdb7:GetUInt32(0)
					end
					if morphSelection7[guid] then
						if morphSelection7[guid] > 0 then
							player:SetDisplayId(morphSelection7[guid])
							print("[Druid Morph Module]: Morpher - Setting aquatic form of "..player:GetName().." to display ID "..morphSelection7[guid])
						end
					end
				end
			end
		end
	end
end

local function Shapeshift(event, player, spell, skipCheck)
    local spellId = spell:GetEntry()

    if player:HasItem(17890) and player:GetClass() == 11
	and	not player:IsPvPFlagged() and
	(spellId == 768 or spellId == 9634
	or spellId == 5487 or spellId == 783
	or spellId == 40120 or spellId == 33943
	or spellId == 33891 or spellId == 24858
	or spellId == 1066 or spellId == 71561
	or spellId == 71484 or spellId == 71560
	or spellId == 71556 or spellId == 71485 
	or spellId == 71492) then
		
		playerName = player:GetName()
		
		morphQueue[player:GetName()] = playerName
		
		local guid = player:GetGUIDLow()
		local formId = formSelections[guid]
		if formId ~= 0 then
			formid = 0
		end

        if spellId == 768 and morphSelection1[guid] then
            formId = 1 -- Cat Form
			print("[Druid Morph Module]: Shifter - Cat shapeshift called for player: " .. player:GetName().." with form ID "..formId.." and morph "..morphSelection1[guid])
			player:RegisterEvent(Morpher, MorphApplicationDelay, MorphRepeats)
        elseif (spellId == 9634 or spellId == 5487) and morphSelection2[guid] then
            formId = 2 -- Bear Form
			print("[Druid Morph Module]: Shifter - Bear shapeshift called for player: " .. player:GetName().." with form ID "..formId.." and morph "..morphSelection2[guid])
			player:RegisterEvent(Morpher, MorphApplicationDelay, MorphRepeats)
        elseif spellId == 783 and morphSelection3[guid] then
            formId = 3 -- Travel Form
			print("[Druid Morph Module]: Shifter - Travel shapeshift called for player: " .. player:GetName().." with form ID "..formId.." and morph "..morphSelection3[guid])
			player:RegisterEvent(Morpher, MorphApplicationDelay, MorphRepeats)
        elseif (spellId == 40120 or spellId == 33943) and morphSelection4[guid] then
            formId = 4 -- Flight Form
			print("[Druid Morph Module]: Shifter - Flight shapeshift called for player: " .. player:GetName().." with form ID "..formId.." and morph "..morphSelection4[guid])
			player:RegisterEvent(Morpher, MorphApplicationDelay, MorphRepeats)
        elseif spellId == 33891 and morphSelection5[guid] then
            formId = 5 -- Tree Form
			print("[Druid Morph Module]: Shifter - Tree shapeshift called for player: " .. player:GetName().." with form ID "..formId.." and morph "..morphSelection5[guid])
			player:RegisterEvent(Morpher, MorphApplicationDelay, MorphRepeats)
        elseif spellId == 24858 and morphSelection6[guid] then
            formId = 6 -- Boomkin Form
			print("[Druid Morph Module]: Shifter - Boomkin shapeshift called for player: " .. player:GetName().." with form ID "..formId.." and morph "..morphSelection6[guid])
			player:RegisterEvent(Morpher, MorphApplicationDelay, MorphRepeats)
        elseif spellId == 1066 and morphSelection7[guid] then
            formId = 7 -- Aquatic Form	
			print("[Druid Morph Module]: Shifter - Aquatic shapeshift called for player: " .. player:GetName().." with form ID "..formId.." and morph "..morphSelection7[guid])
			player:RegisterEvent(Morpher, MorphApplicationDelay, MorphRepeats)
        elseif (spellId == 71561 or spellId == 71484 or spellId == 71560 or spellId == 71556 or spellId == 71485 or spellId == 71492) then
            if (player:HasAura(768) or player:HasAura(32356) or player:HasAura(3025)) and morphSelection1[guid] then
				player:RegisterEvent(DBWfix, DBWDelay, DBWRepeats)
				--print("[Druid Morph Module]: DBW detected!")
            elseif (player:HasAura(9634) or player:HasAura(5487)) and morphSelection2[guid] then
				player:RegisterEvent(DBWfix, DBWDelay, DBWRepeats)
				--print("[Druid Morph Module]: DBW detected!")
            else
                return
            end
        else
            return
        end
    end
end

local function onLogout(event, player)
	if player:GetClass() == 11 then
		morphQueue[player:GetName()] = nil
	end
end

local function OnLogin(event, player)
	if player:GetClass() == 11 and not player:IsPvPFlagged() then
		local guid = player:GetGUIDLow()

		if player:HasItem(17890) then 
			LoadPlayerMorphs(player) -- Load full list of player morphs from db into cache
			
			local morphdb1 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 1") -- Load active morph status
			if morphdb1 then 
				morphSelection1[guid] = morphdb1:GetUInt32(0)
			end
			local morphdb2 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 2") -- Load active morph status
			if morphdb2 then 
				morphSelection2[guid] = morphdb2:GetUInt32(0)
			end
			local morphdb3 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 3") -- Load active morph status
			if morphdb3 then 
				morphSelection3[guid] = morphdb3:GetUInt32(0)
			end
			local morphdb4 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 4") -- Load active morph status
			if morphdb4 then 
				morphSelection4[guid] = morphdb4:GetUInt32(0)
			end
			local morphdb5 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 5") -- Load active morph status
			if morphdb5 then 
				morphSelection5[guid] = morphdb5:GetUInt32(0)
			end
			local morphdb6 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 6") -- Load active morph status
			if morphdb6 then 
				morphSelection6[guid] = morphdb6:GetUInt32(0)
			end
			local morphdb7 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 7") -- Load active morph status
			if morphdb7 then 
				morphSelection7[guid] = morphdb7:GetUInt32(0)
			end
			
			if (player:HasAura(768) or player:HasAura(32356) or player:HasAura(3025)) then -- Cat
				if morphSelection1[guid] then
					player:SetDisplayId(morphSelection1[guid])
					player:AddAura(InvisibleWeapon, player)
				end
			elseif player:HasAura(9634) or player:HasAura(5487) then -- Bear
				if morphSelection2[guid] then
					player:SetDisplayId(morphSelection2[guid])
				end
			elseif player:HasAura(783) then -- Travel
				if morphSelection3[guid] then
					player:SetDisplayId(morphSelection3[guid])
				end
			elseif player:HasAura(40120) or player:HasAura(33943) then -- Fly
				if morphSelection4[guid] then
					player:SetDisplayId(morphSelection4[guid])
				end
			elseif player:HasAura(33891) then -- Tree
				if morphSelection5[guid] then
					player:SetDisplayId(morphSelection5[guid])
				end
			elseif player:HasAura(24858) then -- Boomkin
				if morphSelection6[guid] then
					player:SetDisplayId(morphSelection6[guid])
				end
			elseif player:HasAura(1066) then -- Aquatic
				if morphSelection7[guid] then
					player:SetDisplayId(morphSelection7[guid])
				end
			else
				return
			end
		end
	end
end

local function ReloadEluna(event)
    local players = GetPlayersInWorld()
    for _, player in ipairs(players) do
        if player:GetClass() == 11 and player:HasItem(17890) then 
			
			local guid = player:GetGUIDLow()
			
			LoadPlayerMorphs(player) -- Load full list of player morphs from db into cache
			if not player:IsPvPFlagged() then
				local morphdb1 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 1") -- Load active morph status
				if morphdb1 then 
					morphSelection1[guid] = morphdb1:GetUInt32(0)
				end
				local morphdb2 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 2") -- Load active morph status
				if morphdb2 then 
					morphSelection2[guid] = morphdb2:GetUInt32(0)
				end
				local morphdb3 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 3") -- Load active morph status
				if morphdb3 then 
					morphSelection3[guid] = morphdb3:GetUInt32(0)
					if player:HasAura(783) and #creatureCache[guid][3] >= 10 then 
						player:SetSpeed(1, 1.5)
					elseif player:HasAura(783) and #creatureCache[guid][3] >= 20 then 
						player:SetSpeed(1, 1.6)
					elseif player:HasAura(783) and #creatureCache[guid][3] >= 30 then 
						player:SetSpeed(1, 1.7)
					elseif player:HasAura(783) and #creatureCache[guid][3] >= 40 then 
						player:SetSpeed(1, 1.8)
					elseif player:HasAura(783) and #creatureCache[guid][3] >= 50 then 
						player:SetSpeed(1, 1.9)
					end
				end
				local morphdb4 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 4") -- Load active morph status
				if morphdb4 then 
					morphSelection4[guid] = morphdb4:GetUInt32(0)
				end
				local morphdb5 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 5") -- Load active morph status
				if morphdb5 then 
					morphSelection5[guid] = morphdb5:GetUInt32(0)
				end
				local morphdb6 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 6") -- Load active morph status
				if morphdb6 then 
					morphSelection6[guid] = morphdb6:GetUInt32(0)
				end
				local morphdb7 = CharDBQuery("SELECT id FROM character_morphs WHERE guid = "..guid.." AND active = 1 AND form = 7") -- Load active morph status
				if morphdb7 then 
					morphSelection7[guid] = morphdb7:GetUInt32(0)
				end
				
				if (player:HasAura(768) or player:HasAura(32356) or player:HasAura(3025)) then -- Cat
					if morphSelection1[guid] then
					player:SetDisplayId(morphSelection1[guid])
						--if not eventIds[guid] then
						--	eventIds[guid] = CreateLuaEvent(HideWeapon, InvisibleWeaponTimer, 2)
						--end
					end
				elseif player:HasAura(9634) or player:HasAura(5487) then -- Bear
					if morphSelection2[guid] then
						player:SetDisplayId(morphSelection2[guid])
					end
				elseif player:HasAura(783) then -- Travel
					if morphSelection3[guid] then
						player:SetDisplayId(morphSelection3[guid])
					end
				elseif player:HasAura(40120) or player:HasAura(33943) then -- Fly
					if morphSelection4[guid] then
						player:SetDisplayId(morphSelection4[guid])
					end
				elseif player:HasAura(33891) then -- Tree
					if morphSelection5[guid] then
						player:SetDisplayId(morphSelection5[guid])
					end
				elseif player:HasAura(24858) then -- Boomkin
					if morphSelection6[guid] then
						player:SetDisplayId(morphSelection6[guid])
					end
				elseif player:HasAura(1066) then -- Aquatic
					if morphSelection7[guid] then
						player:SetDisplayId(morphSelection7[guid])
					end
				end
			end
		end
	end
end

local function OnCombat(event, player, enemy)
	if player:GetClass() == 11 and player:HasItem(17890) then
		if enemy:IsPvPFlagged() then
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
				player:SetSpeed(1.4)
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
		if not enemy:IsPvPFlagged() and player:HasAura(3025) then
			--print("Cat combat detected! Hiding weapon...")
			local guid = player:GetGUIDLow()
			eventIds[guid] = CreateLuaEvent(HideWeapon, InvisibleWeaponTimer, 1) -- 0 repetitions = infinite
		end
	end
end

local function OnMapChange(event, player)
	if player:GetClass() == 11 and player:HasItem(17890)
	and not player:IsPvPFlagged() and (player:HasAura(768)
	or player:HasAura(9634)	or player:HasAura(5487)
	or player:HasAura(783) or player:HasAura(33891)
	or  player:HasAura(24858) or player:HasAura(1066)) then
		--print("Map change of morphable druid detected")
		
		playerName = player:GetName()
		
		morphQueue[player:GetName()] = playerName
		
		CreateLuaEvent(Morpher, 100, 1)
	end
end


CacheCreatures() -- Caching available creatures from world DB on script initialization

RegisterPlayerEvent(3, OnLogin) 
--RegisterPlayerEvent(4, onLogout)
RegisterPlayerEvent(5, Shapeshift) -- On spellcast shapeshifts, to initialize morph application
RegisterPlayerEvent(7, OnKillCreature)
RegisterPlayerEvent(27, OnLogin)
RegisterPlayerEvent(28, OnMapChange)
RegisterPlayerEvent(33, OnCombat)
RegisterItemGossipEvent(ITEM_ID, 1, OnGossipHello)
--RegisterItemGossipEvent(ITEM_ID, 2, OnGossipSelect) 
--RegisterPlayerGossipEvent(0, 1, OnGossipHello)
RegisterPlayerGossipEvent(0, 2, OnGossipSelect)
RegisterServerEvent(33, ReloadEluna) -- On reload eluna	
