-- Welcome to Yggdrasil's demon morph module by mostly nick :)

-- Morph vars
local ITEM_ID = 5041
local MorphApplicationDelay = 15
local MAX_REPETITIONS = 1
local MaxMorphSkill = 100
local MorphReqEliteandRare = 50

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
    ["Warbringer"] = 29,
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
    ["Nexus Terror"] = 16,
    ["Crazed Mana-Surge"] = 16,
    ["Arcane Devourer"] = 16,
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

local function CacheCreatures()
    local demonCount = 0

    -- Demon cache
    local demonResults = WorldDBQuery("SELECT entry, name FROM creature_template WHERE type = 3 OR name = 'Arcane Devourer' OR name = 'Tainted Arcane Wrath' OR name = 'Vile Familiar'")

    if demonResults then
        repeat
            local entry = demonResults:GetUInt32(0)
            local name = demonResults:GetString(1)
            demonCache[entry] = {name = name}
            demonCount = demonCount + 1
        until not demonResults:NextRow()
    end

    print("[Warlock Demon Morph Module]: Demon forms cached: "..demonCount)
end

local function LoadPlayerMorphs(player)
    if player:GetClass() ~= 9 then return end -- Only proceed for warlocks

    local guid = player:GetGUIDLow()

    local results = CharDBQuery("SELECT name, id FROM character_morphs WHERE guid = "..guid)

    if results then
        repeat
            local name = results:GetString(0)
            local displayId = results:GetUInt32(1)
            demonCache[displayId] = name
        until not results:NextRow()
    end
end

local function CountTotalMorphs(player)
    local guid = player:GetGUIDLow()
    local result = CharDBQuery("SELECT COUNT(*) FROM character_morphs WHERE guid = "..guid)
    if result then
        return math.min(result:GetUInt32(0), MaxMorphSkill)
    end
    return 0
end

local function OnKillCreature(event, player, creature)
	if player:GetName() == "Nickromancer" then
		print("Player has killed creature!")
	end
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
				if player:GetName() == "Nickromancer" then
					print("Creature is valid demon!")
				end
                break
            end
        end
    end

    -- Check for custom family names
    if not matchedFamily then
        for customName, customFamily in pairs(customFamilyNames) do
            if string.find(string.lower(creatureName), string.lower(customName)) then
                matchedFamily = customFamily
				if player:GetName() == "Nickromancer" then
					print("Creature is valid demon!")
				end
                break
            end
        end
    end

    if matchedFamily then
        local escapedName = string.gsub(creatureName, "'", "''")

        -- Check if the entry already exists
        local query = CharDBQuery("SELECT COUNT(*) FROM character_morphs WHERE guid = " .. guid .. " AND id = " .. displayId)
        if query then
            local count = query:GetUInt32(0)
            if count > 0 then
                -- Entry already exists, do not insert
                return
            end
        end

        -- Insert the new entry if it does not exist
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
        local skillMessage = CountTotalMorphs(player) < MaxMorphSkill and " Your morph skill has increased to " .. CountTotalMorphs(player)+1 .. "." or ""

        player:SendBroadcastMessage("You have captured " .. creatureName .. "'s essence and learned how to morph your " .. familyName .. " into their form." .. skillMessage)
    else
		if player:GetName() == "Nickromancer" then
			print("Creature is NOT valid demon!")
		end
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
                --player:SendBroadcastMessage("Current pet family is " .. pet:GetCreatureFamily())
                -- CharDBExecute("UPDATE character_morphs SET active = 0 WHERE guid = " .. player:GetGUIDLow() .. " AND form = " .. pet:GetCreatureFamily())
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
			-- This is the main menu, intid is the family ID
			local guid = player:GetGUIDLow()
			local results = CharDBQuery("SELECT name, id FROM character_morphs WHERE guid = "..guid.." AND form = "..intid)
			chosenFamily = intid

			if results then
				player:GossipClearMenu()
				
				-- Table to count occurrences of each name
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
				player:GossipSendMenu(1, object, 99)  -- Use the same gossip event ID for the submenu
			else
				player:SendAreaTriggerMessage("You don't have any morphs for this demon!")
				OnPlayerGossipHello(player, object)
			end
		else
			-- This is the submenu, intid is the display ID
			local guid = player:GetGUIDLow()
			
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
			local morphNameResult = CharDBQuery("SELECT name FROM character_morphs WHERE guid = " .. guid .. " AND form = " .. chosenFamily .. " AND id = " .. intid)
			local morphName = "Unknown Morph"
			if morphNameResult then
				morphName = morphNameResult:GetString(0)
			end
			CharDBExecute("UPDATE character_morphs SET active = 0 WHERE guid = "..guid.." AND form = "..chosenFamily)
			CharDBExecute("UPDATE character_morphs SET active = 1 WHERE guid = "..guid.." AND form = "..chosenFamily.." AND id = "..intid)
			player:SendBroadcastMessage("You have morphed your "..familyNames[chosenFamily].." into "..morphName..".")
			
			OnPlayerGossipHello(player, player)
		end
	end
end

local function OnCommand(event, player, command)
    if command:lower() == "demonmorph" then
        OnPlayerGossipHello(player, player)
        return false
    end
end

local function OnPetAddedToWorld(event, player, pet)
    local guid = player:GetGUIDLow()
	local summonedPetFamily = pet:GetCreatureFamily()
	local petName = pet:GetName()
	if petName == "Infernal" then
		summonedPetFamily = 30
	end
	--player:SendBroadcastMessage("Pet is family "..summonedPetFamily)
	print("Player "..player:GetName().." summoned pet in family "..summonedPetFamily..".")
	local queryResult = CharDBQuery("SELECT id FROM character_morphs WHERE guid = " .. guid .. " AND form = " .. summonedPetFamily .. " AND active = 1")
	
	if queryResult then
		-- Extract the ID from the query result
		local chosenMorph = queryResult:GetUInt32(0)
		
		-- Set the display ID of the pet
		pet:SetDisplayId(chosenMorph)
	else
		pet:DeMorph()
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
		if hasMorphItem then
		end
        player:GossipComplete()
    elseif intid == 3 then
        player:GossipComplete()
    end
end

RegisterCreatureGossipEvent(NPC_ID, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ID, 2, OnGossipSelect)


CacheCreatures()
RegisterItemGossipEvent(ITEM_ID, 1, OnItemGossipHello)
RegisterPlayerEvent(7, OnKillCreature)
RegisterPlayerEvent(42, OnCommand)
RegisterPlayerEvent(43, OnPetAddedToWorld)
RegisterPlayerGossipEvent(99, 1, OnPlayerGossipHello)
RegisterPlayerGossipEvent(99, 2, OnItemGossipSelect)
