-- Multistate: spell/GO events fire in map states, but cross-map summons relay
-- through the world state via EMQ, so this file loads in every state.
local Multistate = require("Multistate")
local EMQ = require("EMQ")

local HIGHGUID_PLAYER = 0x0000

local function GetSelectionTargetLow(player)
    if not player then return nil end
    local guid = player:GetSelectionGUID()
    if not guid or GetGUIDLow(guid) == 0 then return nil end
    if GetGUIDType(guid) ~= HIGHGUID_PLAYER then return nil end
    return GetGUIDLow(guid)
end

local function GetSelectedPlayer(player)
    local low = GetSelectionTargetLow(player)
    if not low then return nil end
    return Multistate.FindPlayerByGUID(low)
end

local function RequestCrossMapSummon(caster, targetLow, ritual)
    if not caster or not targetLow then return end
    caster:SendEMQMessage("ShadowsSummonRequest", {
        targetLow = targetLow,
        map = caster:GetMapId(),
        x = caster:GetX(), y = caster:GetY(), z = caster:GetZ(), o = caster:GetO(),
        casterLow = caster:GetGUIDLow(),
        casterName = caster:GetName(),
        ritual = ritual and true or false,
    })
end

-- World relay: sent from a map state, processed in the global state where both
-- player objects are visible. Validates group/combat, then forwards to the
-- target's map for execution.
EMQ.RegisterQueue("ShadowsSummonRequest", function(caster, data)
    if not caster or not data or not data.targetLow then return end
    local target = Multistate.FindPlayerByGUID(data.targetLow)
    if not target then return end
    if not (caster:IsInSameGroupWith(target) or caster:IsInSameRaidWith(target)) then
        caster:SendBroadcastMessage("You can only summon shadows in your group.")
        return
    end
    if target:IsInCombat() then
        caster:SendBroadcastMessage("You cannot summon a shadow while it is in combat.")
        return
    end
    if not data.ritual and not caster:IsBot() then return end
    target:SendEMQMessage("ShadowsSummonExecute", {
        map = data.map, x = data.x, y = data.y, z = data.z, o = data.o,
    })
end)

-- Target-map executor: runs on the target's own map state, which always has a
-- live local object for itself. Far teleports defer safely via YlaDefer.
EMQ.RegisterQueue("ShadowsSummonExecute", function(target, data)
    if not target or not data or not data.map then return end
    if target:IsInCombat() then return end
    target:Teleport(data.map, data.x, data.y, data.z, data.o)
end)

local function CompleteSummonIfShadowNearby(event, player, spell, skipCheck)
    local playersInRange = player:GetPlayersInRange(10, 2, 1)
    
    for _, bot in ipairs(playersInRange) do
        if not bot:IsBot() then return end
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
            
            local targetLow = GetSelectionTargetLow(player)
            if not targetLow then return end
            local target = Multistate.FindPlayerByGUID(targetLow)
            if not target then
                -- Cross-map: caster is a shadow summoning its target, or a
                -- ritual caster summoning a shadow from another map.
                RequestCrossMapSummon(player, targetLow, not player:IsBot())
                return
            end

            if not player:IsBot() then player:CastSpell(target, 7720, true) return end

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
    local targetLow = GetSelectionTargetLow(player)
    if not targetLow then return end
    local bot = Multistate.FindPlayerByGUID(targetLow)
    if not bot then
        -- Cross-map: only shadows initiate 7720 summons; the world relay
        -- validates group/combat before the target map executes.
        if not player:IsBot() then return end
        RequestCrossMapSummon(player, targetLow, false)
        return
    end
    
    local name = bot:GetName()
    if not player:IsBot() then return end
    
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
            FirstPlayerCasting = require("Multistate").FindPlayerByName(FirstPlayerName)
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
                
                if player:IsBot() then
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
                if player:IsBot() and player:IsInSameGroupWith(FirstPlayerCasting) then
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