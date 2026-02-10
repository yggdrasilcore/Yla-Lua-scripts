local PLAYER_DISPEL_SPELLS = {370,475,527,528,552,988,1152,2782,2893,3137,4526,4975,4977,4978,4983,4987,6528,8012,8170,8171,8172,8946,8947,10872,14129,14134,14253,15090,15729,16072,16908,17012,17201,18461,19476,19658,19801,20426,20427,20428,21076,23258,23859,24022,25756,26677,27495,27496,27609,27626,27847,28133,28787,28788,29200,29380,30281,30415,30416,30449,31825,31826,32375,32400,32592,32633,33625,36461,38082,38306,39078,39302,39897,43241,43577,43813,45149,47795,48205,48367,48706,49087,50068,50146,51886,52025,55598,55625,55677,55691,56131,56163,56170,56364,56536,56601,56988,57183,57190,57767,61255,62416,62422,63499,65546,66056,66057,66116,67518,68621,68622,68623,68624,68625,68626,68627,68628,68629,70477,70548,71693,71694,72734}

local RemovedPlayerSpells = {}

function DisableDispels(player)
    if not player then return end
    
    if not isPlayerBot[player:GetName()] then return end
    
    if player:GetData("DispelsDisabled") then return end
    
    local guidLow = player:GetGUIDLow()
    local playerName = player:GetName():gsub("'", "''")
    
    local playerSpellsToRemove = {}
    table.sort(PLAYER_DISPEL_SPELLS)
    
    for _, spellId in ipairs(PLAYER_DISPEL_SPELLS) do
        if player:HasSpell(spellId) then
            table.insert(playerSpellsToRemove, spellId)
        end
    end
    
    if #playerSpellsToRemove > 0 then
        local values = {}
        for _, spellId in ipairs(playerSpellsToRemove) do
            table.insert(values, string.format("(%d, '%s', %d, 0, NULL)", guidLow, playerName, spellId))
            player:RemoveSpell(spellId)
        end
        
        CharDBExecute("REPLACE INTO acore_eluna.disable_shadows_dispels (guid, name, spell_id, is_pet, pet_name) VALUES " .. table.concat(values, ", "))
        player:SetData("DispelsDisabled", true)
    end
end

local function OnMapChange(event, player)
    if not player then return end
    
    if not isPlayerBot[player:GetName()] then return end
    
    player:SetData("DispelsDisabled", false)
    
    local guidLow = player:GetGUIDLow()
    local guid = player:GetGUID()
    
    CharDBQueryAsync(
        string.format("SELECT spell_id FROM acore_eluna.disable_shadows_dispels WHERE guid = %d AND is_pet = 0", guidLow),
        function(query)
            local player = GetPlayerByGUID(guid)
            if not player then return end
            
            if query then
                local spellsToLearn = {}
                repeat
                    local spellId = query:GetUInt32(0)
                    table.insert(spellsToLearn, spellId)
                until not query:NextRow()
                
                table.sort(spellsToLearn)
                
                local allLearned = true
                for _, spellId in ipairs(spellsToLearn) do
                    player:LearnSpell(spellId)
                    if not player:HasSpell(spellId) then
                        allLearned = false
                    end
                end
                
                if allLearned then
                    CharDBExecute(string.format(
                        "DELETE FROM acore_eluna.disable_shadows_dispels WHERE guid = %d AND is_pet = 0",
                        guidLow
                    ))
                    RemovedPlayerSpells[guidLow] = nil
                end
            end
        end
    )
end

local function OnLeaveCombat(event, player)
    local guidLow = player:GetGUIDLow()
    
    if player:GetData("DispelsDisabled") then
        local cachedSpells = RemovedPlayerSpells[guidLow]
        if cachedSpells then
            table.sort(cachedSpells)
            
            local allLearned = true
            for _, spellId in ipairs(cachedSpells) do
                player:LearnSpell(spellId)
                if not player:HasSpell(spellId) then
                    allLearned = false
                end
            end
            
            if allLearned then
                CharDBExecute(string.format(
                    "DELETE FROM acore_eluna.disable_shadows_dispels WHERE guid = %d AND is_pet = 0",
                    guidLow
                ))
                RemovedPlayerSpells[guidLow] = nil
                player:SetData("DispelsDisabled", false)
            end
        end
    end
end

RegisterPlayerEvent(28, OnMapChange)
RegisterPlayerEvent(34, OnLeaveCombat)