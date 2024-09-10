-- Welcome to Yggdrasil's demon morph module by mostly nick :)

-- Morph vars
local ITEM_ID = 5041
local MorphApplicationDelay = 15
local MAX_REPETITIONS = 1
local morphCount = {}
local MaxMorphSkill = 100
local MorphReqEliteandRare = 50
local morphIdCache = {}

-- Vendor vars
local NPC_ID = 190087
local VOTE_TOKEN_ID = 20880
local PETMORPH_ITEM = 5041
local PRICE = 50
local itemName = "Demonic Scroll"
local currencyName = "Vote Tokens"

-- End vars

local familyNames = {
    [15] = "Felhunter",
    [16] = "Voidwalker",
    [17] = "Succubus",
    [19] = "Doomguard",
    [23] = "Imp",
    [29] = "Felguard",
    [30] = "Infernal"
}

local customFamilyNames = {
    ["wrathwalker"] = 29,
    ["Wrathguard"] = 29,
    ["Wrath Master"] = 29,
    ["Reth'Hedron"] = 29,
    ["Death's Might"] = 29,
    ["Illidari Centurion"] = 29,
    ["Illidari Nightlord"] = 29,
    ["Illidan Stormrage"] = 29,
    ["Baelmon"] = 29,
    ["Shocktrooper"] = 29,
    ["Dreadwarden"] = 29,
    ["Terrormaster"] = 29, --Doomguard
    ["Terrorfiend"] = 29, --Doomguard
    ["Dreadbringer"] = 29, --Doomguard
    ["Illidari Fearbringer"] = 29, --Doomguard
    ["Terrordar"] = 29, --Doomguard
    ["Soldier of Terror"] = 29,
    ["Terrorguard"] = 29,
    ["Lothros"] = 29,
    ["Demos"] = 29,
    ["Hellion"] = 29,
    ["Anger Guard"] = 29,
    ["Terror-fire"] = 29,
    ["Terrorslayer"] = 29,
    ["Hederine Slayer"] = 29,
    ["Furnace Guard"] = 29,
    ["Vorakem"] = 29,
    ["Dread Tactician"] = 29,
    ["Jerrikar"] = 29,
    ["Satyr"] = 29,
    ["Felmusk"] = 29,
    ["Jadefire"] = 29,
    ["Xavathras"] = 29,
    ["Fel Handler"] = 29,
    ["Forge Camp Legionnaire"] = 29,
    ["Wrath Herald"] = 29,
    ["Wrath Enforcer"] = 29,
    ["Fel Soldier"] = 29,
    ["Dreadlord"] = 29,
    ["Dreadcaller"] = 29,
    ["Manahound"] = 15,
    ["Netherhound"] = 15,
    ["Fel Guardhound"] = 15,
    ["Felstalker"] = 15,
    ["Felboar"] = 15,
    ["Helboar"] = 15,
    ["hound"] = 15,
    ["Mage Slayer"] = 15,
    ["Felstalker"] = 15,
    ["Collidus"] = 15,
    ["Voidcaller"] = 16,
    ["Voidhunter"] = 16,
    ["Voidwalker"] = 16,
    ["Nexus Terror"] = 16,
    ["Crazed Mana-Surge"] = 16,
    ["Arcane Devourer"] = 16,
    ["Arcanimus"] = 16,
    ["Manawraith"] = 16,
    ["Tainted Arcane Wraith"] = 16,
    ["Doomwhisperer"] = 17,
    ["Sathal"] = 17,
    ["Deathwhisperer"] = 17,
    ["Irespeaker"] = 17,
    ["Painmistress"] = 17,
    ["Hederine Initiate"] = 17,
    ["Priestess"] = 17,
    ["Mother Shahraz"] = 17,
    ["Prophetess"] = 17,
    ["Wrath Speaker"] = 17,
    ["Painlasher"] = 17,
    ["Yalqiz"] = 17,
    ["Sister"] = 17,
    ["Fel Sprite"] = 23,
    ["Imp"] = 23,
    ["Grell"] = 23,
    ["Illidari Agonizer"] = 23,
    ["Vile Familiar"] = 23,
    ["Kraator"] = 30,
    ["Abyssal Flamebringer"] = 30,
    ["Infernal"] = 30,
    ["Supremus"] = 30,
    ["Abyssal Flamewalker"] = 30
}

local demonCache = {}
local playerMorphChoice = {}
local morph15 = {}
local morph16 = {}
local morph17 = {}
local morph19 = {}
local morph23 = {}
local morph29 = {}
local morph30 = {}
local logincheck = {}

local function CacheCreatures()
    local demonCount = 0

    -- Demon cache
    WorldDBQueryAsync("SELECT entry, name FROM creature_template WHERE type = 3 OR name = 'Arcane Devourer' OR name = 'Tainted Arcane Wrath' OR name = 'Vile Familiar' OR name = 'Grell'", function(demonResults)

		if demonResults then
			repeat
				local entry = demonResults:GetUInt32(0)
				local name = demonResults:GetString(1)
				demonCache[entry] = {name = name}
				demonCount = demonCount + 1
			until not demonResults:NextRow()
		end
	end)

    print("[Warlock Demon Morph Module]: Demon forms cached: "..demonCount)
end

local function CountTotalMorphs(player)
    local guid = player:GetGUIDLow()
    if morphCount[guid] then
        return morphCount[guid]
    else
        local result = CharDBQuery("SELECT COUNT(*) FROM character_morphs WHERE guid = "..guid)
        if result then
            morphCount[guid] = math.min(result:GetUInt32(0), MaxMorphSkill)
            return morphCount[guid]
        end
        return 0
    end
end

local function OnKillCreature(event, player, creature)
    if player:GetClass() ~= 9 then return end
    if not player:HasItem(ITEM_ID) then return end
    local guid = player:GetGUIDLow()
    local entry = creature:GetEntry()
    local displayId = creature:GetDisplayId()
    local creatureName = creature:GetName()

    local matchedFamily = nil

    if demonCache[entry] then
        matchedFamily = demonCache[entry].family
    else
        for familyId, familyName in pairs(familyNames) do
            if string.find(string.lower(creatureName), string.lower(familyName)) then
                matchedFamily = familyId
                break
            end
        end
    end

    if not matchedFamily then
        for customName, customFamily in pairs(customFamilyNames) do
            if string.find(string.lower(creatureName), string.lower(customName)) then
                matchedFamily = customFamily
                break
            end
        end
    end

    if matchedFamily then
        local escapedName = string.gsub(creatureName, "'", "''")

		if morphIdCache[guid] then
			local found = false
			for _, id in ipairs(morphIdCache[guid]) do
				if id == displayId then
					found = true
					break
				end
			end

			-- If `displayId` is already in the cache, exit
			if found then
				return
			end
		end
		
        CharDBExecute("INSERT INTO character_morphs (guid, name, id, form, active) VALUES (" .. guid .. ", '" .. escapedName .. "', " .. displayId .. ", " .. (matchedFamily or 0) .. ", 0)")
        
        local familyNames = {
            [15] = "Felhunter",
            [16] = "Voidwalker",
            [17] = "Succubus",
            [19] = "Doomguard",
            [23] = "Imp",
            [29] = "Felguard",
            [30] = "Infernal"
        }

        local familyName = familyNames[matchedFamily] or "demon"
		
		if morphCount[guid] then morphCount[guid] = morphCount[guid] + 1 end
		
        local skillMessage = CountTotalMorphs(player) < MaxMorphSkill and " Your morph skill has increased to " .. CountTotalMorphs(player)+1 .. "." or ""

        player:SendBroadcastMessage("You have captured " .. creatureName .. "'s essence and learned how to morph your " .. familyName .. " into their form." .. skillMessage)
		
		if not morphIdCache[guid] then
            morphIdCache[guid] = {}
        end
		table.insert(morphIdCache[guid], displayId)
	end
end

local function ShowInitialGossipMenu(player)
    player:GossipClearMenu()

    player:GossipMenuAddItem(4, "How does demon morphing work?", 0, 997)

    for familyId, familyName in pairs(familyNames) do
        player:GossipMenuAddItem(0, familyName, 0, familyId)
    end

    player:GossipMenuAddItem(0, "Reset current morph", 0, 998)

	player:GossipSendMenu(1, player, 99)
end

local function OnItemGossipHello(event, player, item, object)
	if player:GetClass() == 9 then
        player:GossipComplete()
        ShowInitialGossipMenu(player)
    return false
	end
end

local function OnPlayerGossipHello(player, object)
    player:GossipClearMenu()

	player:GossipMenuAddItem(4, "How does demon morphing work?", 0, 997)
    for familyId, familyName in pairs(familyNames) do
        player:GossipMenuAddItem(0, familyName, 0, familyId)
    end
    player:GossipMenuAddItem(0, "Reset current morph", 0, 998)

    player:GossipSendMenu(1, object, 99)
end

local function OnItemGossipSelect(event, player, object, sender, intid, code)	
    if intid == 999 then
        OnPlayerGossipHello(player, object)
        return
    end
	if intid == 997 then
		player:GossipClearMenu()
		player:GossipMenuAddItem(0, "Through channeling the spirits of the underworld, you may allow your demon to take on the forms of its enemies. To claim an enemy's form, you must slay it. Every unique form claimed increases your morphing skill by 1. To claim the form of elite or rare creatures, you need to have a morphing skill of at least "..MorphReqEliteandRare, 0, 997)
		player:GossipMenuAddItem(4, "Go back", 0, 999)
		player:GossipSendMenu(1, player, 99)
	end
    if intid == 998 then
		local guid = player:GetGUIDLow()
        local petGUID = player:GetPetGUID()
        if petGUID then
            local nearbyUnits = player:GetCreaturesInRange(100)
            local pet = nil
            for _, unit in ipairs(nearbyUnits) do
                if unit:GetGUID() == petGUID then
                    pet = unit
                    break
                end
            end
            if pet then
                pet:DeMorph()
                CharDBExecute("UPDATE character_morphs SET active = 0 WHERE guid = " .. player:GetGUIDLow() .. " AND form = " .. pet:GetCreatureFamily())
				if pet:GetCreatureFamily() == 15 then
					morph15[guid] = nil
				elseif pet:GetCreatureFamily() == 16 then
					morph16[guid] = nil
				elseif pet:GetCreatureFamily() == 17 then
					morph17[guid] = nil
				elseif pet:GetCreatureFamily() == 19 then
					morph19[guid] = nil
				elseif pet:GetCreatureFamily() == 23 then
					morph23[guid] = nil
				elseif pet:GetCreatureFamily() == 29 then
					morph29[guid] = nil
				elseif pet:GetCreatureFamily() == 30 then
					morph30[guid] = nil
				end
            else
                player:SendBroadcastMessage("Your demon is too far away!")
				OnPlayerGossipHello(player, player)
            end
        else
            player:SendBroadcastMessage("No demon pet found.")
			OnPlayerGossipHello(player, player)
        end
        OnPlayerGossipHello(player, player)
        return
    end
	if intid > 997 or intid < 997 then
		if familyNames[intid] then
			local guid = player:GetGUIDLow()
			local playername = player:GetName()
			CharDBQueryAsync("SELECT name, id FROM character_morphs WHERE guid = "..guid.." AND form = "..intid, function(results)
			chosenFamily = intid
			player = GetPlayerByName(playername)
			
				if results then
					player:GossipClearMenu()
					
					local nameCounts = {}

					repeat
						local name = results:GetString(0)
						local displayId = results:GetUInt32(1)
						
						-- Increment the count for this name
						nameCounts[name] = (nameCounts[name] or 0) + 1
						local displayName = name
						
						-- Append count if there are duplicates
						if nameCounts[name] > 1 then
							displayName = name .. " " .. nameCounts[name] .. ""
						end
						
						player:GossipMenuAddItem(0, displayName, 0, displayId)
					until not results:NextRow()
					
					player:GossipMenuAddItem(4, "Go back", 0, 999)
					player:GossipSendMenu(1, player, 99)  -- Use the same gossip event ID for the submenu
				else
					player:SendAreaTriggerMessage("You don't have any morphs for this demon!")
					OnPlayerGossipHello(player, player)
				end
			end)
		else
			-- This is the submenu, intid is the display ID
			local guid = player:GetGUIDLow()
			local name = player:GetName()
			
			playerMorphChoice[player:GetGUIDLow()] = intid
			local petGUID = player:GetPetGUID()
			if petGUID then
				local nearbyUnits = player:GetCreaturesInRange(100)
				local pet = nil
				for _, unit in ipairs(nearbyUnits) do
					if unit:GetGUID() == petGUID then
						pet = unit
						break
					end
				end
				if pet then
					summonedPetFamily = pet:GetCreatureFamily()
					if summonedPetFamily == chosenFamily then
						pet:SetDisplayId(intid)
					end
				end
			end
			
			CharDBQueryAsync("SELECT name FROM character_morphs WHERE guid = " .. guid .. " AND form = " .. chosenFamily .. " AND id = " .. intid, function(morphNameResult)
				local player = GetPlayerByName(name)
				local morphName = "Unknown Morph"
				if morphNameResult then
					morphName = morphNameResult:GetString(0)
				end
				player:SendBroadcastMessage("You have morphed your "..familyNames[chosenFamily].." into "..morphName..".")
			end)
			
			CharDBExecute("UPDATE character_morphs SET active = (form = " .. chosenFamily .. " AND id = " .. intid .. ") WHERE guid = " .. guid .. " AND form = " .. chosenFamily)
			
			if chosenFamily == 15 then
				morph15[guid] = intid
				morph16[guid] = nil
				morph17[guid] = nil
				morph19[guid] = nil
				morph23[guid] = nil
				morph29[guid] = nil
				morph30[guid] = nil
			elseif chosenFamily == 16 then
				morph15[guid] = nil
				morph16[guid] = intid
				morph17[guid] = nil
				morph19[guid] = nil
				morph23[guid] = nil
				morph29[guid] = nil
				morph30[guid] = nil
			elseif chosenFamily == 17 then
				morph15[guid] = nil
				morph16[guid] = nil
				morph17[guid] = intid
				morph19[guid] = nil
				morph23[guid] = nil
				morph29[guid] = nil
				morph30[guid] = nil
			elseif chosenFamily == 19 then
				morph15[guid] = nil
				morph16[guid] = nil
				morph17[guid] = nil
				morph19[guid] = intid
				morph23[guid] = nil
				morph29[guid] = nil
				morph30[guid] = nil
			elseif chosenFamily == 23 then
				morph15[guid] = nil
				morph16[guid] = nil
				morph17[guid] = nil
				morph19[guid] = nil
				morph23[guid] = intid
				morph29[guid] = nil
				morph30[guid] = nil
			elseif chosenFamily == 29 then
				morph15[guid] = nil
				morph16[guid] = nil
				morph17[guid] = nil
				morph19[guid] = nil
				morph23[guid] = nil
				morph29[guid] = intid
				morph30[guid] = nil
			elseif chosenFamily == 30 then
				morph15[guid] = nil
				morph16[guid] = nil
				morph17[guid] = nil
				morph19[guid] = nil
				morph23[guid] = nil
				morph29[guid] = nil
				morph30[guid] = intid
			end
			OnPlayerGossipHello(player, player)
		end
	end
end

local function OnPetAddedToWorld(event, player, pet)
    local guid = player:GetGUIDLow()
	local summonedPetFamily = pet:GetCreatureFamily()
	local petName = pet:GetName()
	if petName == "Infernal" then
		summonedPetFamily = 30
	end
	
	if summonedPetFamily == 15 and morph15[guid] then
		pet:SetDisplayId(morph15[guid])
	elseif pet:GetCreatureFamily() == 16 and morph16[guid] then
		pet:SetDisplayId(morph16[guid])
	elseif pet:GetCreatureFamily() == 17 and morph17[guid] then
		pet:SetDisplayId(morph17[guid])
	elseif pet:GetCreatureFamily() == 19 and morph19[guid] then
		pet:SetDisplayId(morph19[guid])
	elseif pet:GetCreatureFamily() == 23 and morph23[guid] then
		pet:SetDisplayId(morph23[guid])
	elseif pet:GetCreatureFamily() == 29 and morph29[guid] then
		pet:SetDisplayId(morph29[guid])
	elseif pet:GetCreatureFamily() == 30 and morph30[guid] then
		pet:SetDisplayId(morph30[guid])
	elseif not logincheck[guid] then
		logincheck[guid] = true
		pet:RegisterEvent(function(eventId, delay, repeats, pet) -- Circumvents async db delay on login
			if summonedPetFamily == 15 and morph15[guid] then
				pet:SetDisplayId(morph15[guid])
				pet:RemoveEventById(eventId)
			elseif pet:GetCreatureFamily() == 16 and morph16[guid] then
				pet:SetDisplayId(morph16[guid])
				pet:RemoveEventById(eventId)
			elseif pet:GetCreatureFamily() == 17 and morph17[guid] then
				pet:SetDisplayId(morph17[guid])
				pet:RemoveEventById(eventId)
			elseif pet:GetCreatureFamily() == 19 and morph19[guid] then
				pet:SetDisplayId(morph19[guid])
				pet:RemoveEventById(eventId)
			elseif pet:GetCreatureFamily() == 23 and morph23[guid] then
				pet:SetDisplayId(morph23[guid])
				pet:RemoveEventById(eventId)
			elseif pet:GetCreatureFamily() == 29 and morph29[guid] then
				pet:SetDisplayId(morph29[guid])
				pet:RemoveEventById(eventId)
			elseif pet:GetCreatureFamily() == 30 and morph30[guid] then
				pet:SetDisplayId(morph30[guid])
				pet:RemoveEventById(eventId)
			end
		end, 20, 4)
	end
end

local function OnGossipHello(event, player, object)
	if player:GetClass() == 9 then
		player:GossipClearMenu()
		player:GossipMenuAddItem(0, "I hear you're interested in transforming your demon pets' forms...", 0, 1)
		player:GossipSendMenu(1, object)
	else
		player:SendBroadcastMessage("I only cater to Warlocks.") -- add DK
	end
end

local function OnGossipSelect(event, player, object, sender, intid, code)
    if intid == 1 then

        player:GossipClearMenu()

        player:GossipMenuAddItem(1, "Do you want to buy a "..itemName.." for " .. PRICE .. " "..currencyName.."?", 0, 2)
        player:GossipMenuAddItem(0, "We have nothing to discuss.", 0, 3)

        player:GossipSendMenu(1, object)
    elseif intid == 2 then
        local hasEnoughVT = player:GetItemCount(VOTE_TOKEN_ID) >= 50
        local hasMorphItem = player:GetItemCount(PETMORPH_ITEM) > 0
        if hasEnoughVT and not hasMorphItem then
            player:RemoveItem(VOTE_TOKEN_ID, PRICE)

            player:AddItem(PETMORPH_ITEM, 1)

        elseif hasEnoughVT and hasMorphItem then
            player:SendBroadcastMessage("You already have a "..itemName..".")
		elseif not hasEnoughVT and hasMorphItem then
            player:SendBroadcastMessage("You already have a "..itemName..".")
		elseif not hasEnoughVT and not hasMorphItem then
            player:SendBroadcastMessage("You do not have enough "..currencyName..".")
        end
        player:GossipComplete()
    elseif intid == 3 then
        player:GossipComplete()
    end
end

local function OnReloadEluna(event)
    local players = GetPlayersInWorld()
    for _, player in ipairs(players) do
		if player:HasItem(ITEM_ID) then
			local guid = player:GetGUIDLow()
			local name = player:GetName()
			
			CharDBQueryAsync("SELECT id, form, active FROM character_morphs WHERE guid = " .. guid, function(result)
				if result then
					repeat
						local morphId = result:GetUInt32(0)
						local morphForm = result:GetUInt32(1)
						local isActive = result:GetUInt32(2)
						if not morphIdCache[guid] then
							morphIdCache[guid] = {}
						end
						table.insert(morphIdCache[guid], morphId)

						morphCount[guid] = (morphCount[guid] or 0) + 1
						
						if morphForm == 15 then
							morph15[guid] = morphId
						elseif morphForm == 16 then
							morph16[guid] = morphId
						elseif morphForm == 17 then
							morph17[guid] = morphId
						elseif morphForm == 19 then
							morph19[guid] = morphId
						elseif morphForm == 23 then
							morph23[guid] = morphId
						elseif morphForm == 29 then
							morph29[guid] = morphId
						elseif morphForm == 30 then
							morph30[guid] = morphId
						end

					until not result:NextRow()
				end
			end)
		end
	end
end
		
-- Cache player's morphs on login if they have the required item
local function OnPlayerLogin(event, player)
    if player:HasItem(ITEM_ID) then
		local guid = player:GetGUIDLow()
		local name = player:GetName()
		
        CharDBQueryAsync("SELECT id, form, active FROM character_morphs WHERE guid = " .. guid, function(result)
			player = GetPlayerByName(name)
			if result then
				repeat
					local morphId = result:GetUInt32(0)
					local morphForm = result:GetUInt32(1)
					local isActive = result:GetUInt32(2)
					if not morphIdCache[guid] then
						morphIdCache[guid] = {}
					end
					table.insert(morphIdCache[guid], morphId)

					morphCount[guid] = (morphCount[guid] or 0) + 1
					
					if morphForm == 15 then
						morph15[guid] = morphId
					elseif morphForm == 16 then
						morph16[guid] = morphId
					elseif morphForm == 17 then
						morph17[guid] = morphId
					elseif morphForm == 19 then
						morph19[guid] = morphId
					elseif morphForm == 23 then
						morph23[guid] = morphId
					elseif morphForm == 29 then
						morph29[guid] = morphId
					elseif morphForm == 30 then
						morph30[guid] = morphId
					end

				until not result:NextRow()
			end
		end)
    end
end

local function OnPlayerLogout(event, player)
    local guid = player:GetGUIDLow()
    demonCache[guid] = nil
    playerMorphChoice[guid] = nil
    morphCount[guid] = nil
	logincheck[guid] = nil
	morph15[guid] = nil
	morph16[guid] = nil
	morph17[guid] = nil
	morph19[guid] = nil
	morph23[guid] = nil
	morph29[guid] = nil
	morph30[guid] = nil
	morphIdCache[guid] = nil
end

CacheCreatures()
RegisterPlayerEvent(3, OnPlayerLogin)
RegisterPlayerEvent(4, OnPlayerLogout)
RegisterPlayerEvent(7, OnKillCreature)
RegisterServerEvent(33, OnReloadEluna)
RegisterPlayerEvent(43, OnPetAddedToWorld)
RegisterItemGossipEvent(ITEM_ID, 1, OnItemGossipHello)
RegisterPlayerGossipEvent(99, 1, OnPlayerGossipHello)
RegisterPlayerGossipEvent(99, 2, OnItemGossipSelect)
RegisterCreatureGossipEvent(NPC_ID, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ID, 2, OnGossipSelect)