local function CompleteSummonIfShadowNearby(event, player, spell, skipCheck)
    local playersInRange = player:GetPlayersInRange(10, 2, 1)
    
    for _, bot in ipairs(playersInRange) do
        local botName = bot:GetName()
        if not isPlayerBot[botName] then return end
        if not (player:IsInSameGroupWith(bot) or player:IsInSameRaidWith(bot)) then return end
        
        local rootAura = bot:AddAura(32113, bot)
        rootAura:SetDuration(5000)
        bot:CastSpell(FirstPlayerCasting, 45789, true)
        
        bot:RegisterEvent(function(e, d, r, bot)
            if bot:IsInCombat() then return end
            bot:StopSpellCast()
        end, 5000)
        
        player:RegisterEvent(function(e, d, r, player)
            if not player:IsCasting() then return end
            player:StopSpellCast()
            
            local targetGuid = player:GetData("Target")
            if not targetGuid then return end
    
            local target = GetPlayerByGUID(targetGuid)
            if not target then return end

            local name = target:GetName()
            if not isPlayerBot[name] then player:CastSpell(target, 7720, true) return end

            local bot = target
            if not (player:IsInSameGroupWith(bot) or player:IsInSameRaidWith(bot)) then player:SendBroadcastMessage("You can only summon shadows in your group.") return end
            
            if bot:IsInCombat() then player:SendBroadcastMessage("You cannot summon a shadow while it is in combat.") return end
            
            bot:Teleport(player:GetMapId(), player:GetX(), player:GetY(), player:GetZ(), player:GetO())
        end, 5000)
        
        break
    end
end

RegisterSpellEvent(23598, 2, CompleteSummonIfShadowNearby)

local function SummonShadows(event, player, spell, skipCheck)
    local targetGuid = player:GetData("Target")
    if not targetGuid then return end
    
    local bot = GetPlayerByGUID(targetGuid)
    if not bot then return end
    
    local name = bot:GetName()
    if not isPlayerBot[name] then return end
    
    if not (player:IsInSameGroupWith(bot) or player:IsInSameRaidWith(bot)) then player:SendBroadcastMessage("You can only summon shadows in your group.") return end
    
    if bot:IsInCombat() then player:SendBroadcastMessage("You cannot summon a shadow while it is in combat.") return end
    
    bot:Teleport(player:GetMapId(), player:GetX(), player:GetY(), player:GetZ(), player:GetO())
end
RegisterSpellEvent(7720, 2, SummonShadows)

local function OnCastRitualOfSummoning(event, portal)
    local FirstPlayerName
    local castingPlayers = {}
    local consecutiveSeconds = 0
    local lastCastingSet = {}
    
    local function CheckPlayersCastingRitualOfSummoning(e, d, r, portal)
        local playersInRange = portal:GetPlayersInRange(10, 2, 1)
        local currentCasting = {}
        local castingCount = 0
        local botsCasting = {}
        local FirstPlayerCasting = nil
        local casterSpells = {}
        
        if FirstPlayerName then
            FirstPlayerCasting = GetPlayerByName(FirstPlayerName)
        end
        
        for _, player in ipairs(playersInRange) do
            local isCasting = false
            local spellId = nil
            local name = player:GetName()
            
            local spell = player:GetCurrentSpell(2)
            if spell then
                local entry = spell:GetEntry()
                if entry == 698 or entry == 45789 then
                    isCasting = true
                    spellId = entry
                    table.insert(casterSpells, {player = player, spell = spell})
                end
            end
            
            if isCasting then
                if not FirstPlayerName and spellId == 698 then
                    FirstPlayerName = player:GetName()
                    FirstPlayerCasting = player
                end
                
                if isPlayerBot[name] then
                    table.insert(botsCasting, name)
                end
                
                table.insert(currentCasting, player:GetGUIDLow())
                castingCount = castingCount + 1
            end
        end
        
        if castingCount < 3 and FirstPlayerCasting then
            local botsNeeded = 3 - castingCount
            local botsMadeToCast = 0
            
            for _, player in ipairs(playersInRange) do
                if botsMadeToCast >= botsNeeded then break end
                
                local name = player:GetName()
                if isPlayerBot[name] and player:IsInSameGroupWith(FirstPlayerCasting) then
                    local alreadyCasting = false
                    for _, castingBot in ipairs(botsCasting) do
                        if castingBot == name then
                            alreadyCasting = true
                            break
                        end
                    end
                    
                    if not alreadyCasting then
                        player:CastSpell(player, 45789, true)
                        botsMadeToCast = botsMadeToCast + 1
                        player:RegisterEvent(function(e, d, r, player)
                            player:StopSpellCast()
                        end, 20000)
                    end
                end
            end
        end
        
        if castingCount == 3 then
            table.sort(currentCasting)
            table.sort(lastCastingSet)
            
            local same = #currentCasting == #lastCastingSet
            if same then
                for i = 1, #currentCasting do
                    if currentCasting[i] ~= lastCastingSet[i] then
                        same = false
                        break
                    end
                end
            end
            
            if same then
                consecutiveSeconds = consecutiveSeconds + 1
                if consecutiveSeconds >= 10 then
                    if FirstPlayerCasting then
                        for _, data in ipairs(casterSpells) do
                            data.spell:Cancel()
                        end
                        FirstPlayerCasting:CastSpell(target, 61993, true)
                        portal:Despawn()
                    end
                end
            else
                consecutiveSeconds = 1
                lastCastingSet = currentCasting
            end
        else
            consecutiveSeconds = 0
            lastCastingSet = {}
        end
    end
    
    CheckPlayersCastingRitualOfSummoning(nil, nil, nil, portal)
    portal:RegisterEvent(CheckPlayersCastingRitualOfSummoning, 2000, 120)
end

RegisterGameObjectEvent(194108, 2, OnCastRitualOfSummoning)