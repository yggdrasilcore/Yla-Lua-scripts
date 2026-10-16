local EVENT_INTERVAL_MIN = 10 * 60 * 1000 -- 10 minutes in milliseconds
local EVENT_INTERVAL_MAX = 20 * 60 * 1000 -- 20 minutes in milliseconds
local SPAWN_NPC_ID = 32838
local SPELL_ID_1 = 51347
local SPELL_ID_2 = 61995
local HALLOWEEN_MASKS = {75214, 75219, 75220, 75228, 75229, 75230}
local TRANSFORM_AURA = 26662

-- Function to check if current time is within Halloween period
local function IsHalloweenPeriod()
    local time = os.date("*t")
    
    -- Check if we're between October 18th and October 31st
    if time.month == 10 then
        if time.day >= 16 and time.day <= 31 then
            -- On October 18th, only start after 01:00
            if time.day == 18 and time.hour < 1 then
                return false
            end
            -- On October 31st, only run until 23:59
            if time.day == 31 and time.hour >= 24 then
                return false
            end
            return true
        end
    end
    return false
end

-- Function to handle normal event logic
local function NormalBonkTime(eventId, delay, repeats)
    -- Get all players in the world
    local targetplayer
    local players = GetPlayersInWorld()
    local eligiblePlayers = {}

    -- Find eligible players in Dalaran with Z > 640
    for _, player in pairs(players) do
        if player:GetZoneId() == 4395 and player:GetZ() > 640 then
            table.insert(eligiblePlayers, player)
        end
    end

    -- If there are eligible players, pick one randomly
    if #eligiblePlayers > 0 then
        local randomIndex = math.random(#eligiblePlayers)
        local chosenPlayer = eligiblePlayers[randomIndex]

        -- Spawn NPC
        local npc = chosenPlayer:SpawnCreature(SPAWN_NPC_ID, chosenPlayer:GetX(), chosenPlayer:GetY(), chosenPlayer:GetZ(), chosenPlayer:GetO(), 1, 40000)
        targetplayer = chosenPlayer:GetName()
        
        if npc then
            
            npc:MoveRandom(10)
            npc:CastSpell(npc, SPELL_ID_1)
            npc:SetSpeed(1, 0.4)
            
            npc:RegisterEvent(function(eventId, delay, repeats, npc)
                chosenPlayer = nil
                for _, p in ipairs(GetStateMap():GetPlayers()) do
                    if p:GetName() == targetplayer then chosenPlayer = p break end
                end
                if chosenPlayer then
                    npc:MoveFollow(chosenPlayer, 0.2, 2.8)
                    if chosenPlayer:IsMounted() then
                        npc:SetSpeed(1, chosenPlayer:GetSpeed(1)*0.2)
                    else
                        npc:SetSpeed(1, 1.6)
                    end
                end
            end, 10000, 1)
            
            npc:RegisterEvent(function(eventId, delay, repeats, npc)
                chosenPlayer = nil
                for _, p in ipairs(GetStateMap():GetPlayers()) do
                    if p:GetName() == targetplayer then chosenPlayer = p break end
                end
                if chosenPlayer then
                    npc:SetRooted(true)
                    npc:SendUnitEmote("Minigob Manabonk tickles ".. chosenPlayer:GetName()..".")
                    npc:SendUnitSay("Hee hee! Gotcha!", 0)
                end
            end, 12000, 1)
            
            npc:RegisterEvent(function(eventId, delay, repeats, npc)
                chosenPlayer = nil
                for _, p in ipairs(GetStateMap():GetPlayers()) do
                    if p:GetName() == targetplayer then chosenPlayer = p break end
                end
                if chosenPlayer then
                    npc:EmoteState(11) -- laugh
                    npc:SetFaction(1194)
                end
            end, 12500, 1)
            
            npc:RegisterEvent(function(eventId, delay, repeats, npc)
                chosenPlayer = nil
                for _, p in ipairs(GetStateMap():GetPlayers()) do
                    if p:GetName() == targetplayer then chosenPlayer = p break end
                end
                if chosenPlayer then
                    npc:SetRooted(false)
                    npc:SetSpeed(0, 2)
                    npc:SetSpeed(1, 1.6)
                    npc:MoveTo(1, npc:GetX()-5+math.random(3,7), npc:GetY()-5+math.random(3,7), npc:GetZ(), true)
                end
            end, 15000, 1)
            
            npc:RegisterEvent(function(eventId, delay, repeats, npc)
                targetplayer = nil
                if npc:IsAlive() and not npc:IsInCombat() then
                    npc:CastSpell(npc, SPELL_ID_2)
                    npc:DespawnOrUnsummon(1000)
                end
            end, 21000, 1)
        end
    end

    -- Schedule next normal event
    local nextEventDelay = math.random(EVENT_INTERVAL_MIN, EVENT_INTERVAL_MAX)
    CreateLuaEvent(NormalBonkTime, nextEventDelay, 1)
end

-- Function to handle Halloween event logic
local function BonkTime(eventId, delay, repeats)
    local targetplayer
    -- Only proceed if we're in the Halloween period
    if not IsHalloweenPeriod() then
        -- Not halloween? Schedule normal bonk instead
        CreateLuaEvent(NormalBonkTime, 1000, 1)  -- Start normal bonk after 1 second
        return
    end

    local players = GetPlayersInWorld()
    local eligiblePlayers = {}
    
    for _, player in pairs(players) do
        if player:GetZoneId() == 4395 and player:GetZ() > 640 then
            table.insert(eligiblePlayers, player)
        end
    end
    
    if #eligiblePlayers > 0 then
        local randomIndex = math.random(#eligiblePlayers)
        local chosenPlayer = eligiblePlayers[randomIndex]
        local npc = chosenPlayer:SpawnCreature(SPAWN_NPC_ID, chosenPlayer:GetX(), chosenPlayer:GetY(), chosenPlayer:GetZ(), chosenPlayer:GetO(), 1, 40000)
        targetplayer = chosenPlayer:GetName()
        
        if npc then
            local randomItem = HALLOWEEN_MASKS[math.random(#HALLOWEEN_MASKS)]
            npc:AddAura(randomItem, npc)
            
            npc:MoveRandom(10)
            npc:CastSpell(npc, SPELL_ID_1)
            npc:SetSpeed(1, 0.4)
            
            npc:RegisterEvent(function(eventId, delay, repeats, npc)
                chosenPlayer = nil
                for _, p in ipairs(GetStateMap():GetPlayers()) do
                    if p:GetName() == targetplayer then chosenPlayer = p break end
                end
                if chosenPlayer then
                    npc:MoveFollow(chosenPlayer, 0.2, 2.8)
                    if chosenPlayer:IsMounted() then
                        npc:SetSpeed(1, chosenPlayer:GetSpeed(1)*0.2)
                    else
                        npc:SetSpeed(1, 1.6)
                    end
                end
            end, 10000, 1)
            
            npc:RegisterEvent(function(eventId, delay, repeats, npc)
                chosenPlayer = nil
                for _, p in ipairs(GetStateMap():GetPlayers()) do
                    if p:GetName() == targetplayer then chosenPlayer = p break end
                end
                if chosenPlayer then
                    npc:SetRooted(true)
                    npc:SendUnitSay("Trick or treat!", 0)
                end
            end, 12000, 1)
            
            npc:RegisterEvent(function(eventId, delay, repeats, npc)
                chosenPlayer = nil
                for _, p in ipairs(GetStateMap():GetPlayers()) do
                    if p:GetName() == targetplayer then chosenPlayer = p break end
                end
                if chosenPlayer then
                    npc:EmoteState(11)
                    npc:SetFaction(679)
                end
            end, 12500, 1)
            
            npc:RegisterEvent(function(eventId, delay, repeats, npc)
                chosenPlayer = nil
                for _, p in ipairs(GetStateMap():GetPlayers()) do
                    if p:GetName() == targetplayer then chosenPlayer = p break end
                end
                if chosenPlayer then
                    npc:SetRooted(false)
                    npc:SetSpeed(0, 2)
                    npc:SetSpeed(1, 1.6)
                    npc:MoveTo(1, npc:GetX()-5+math.random(3,7), npc:GetY()-5+math.random(3,7), npc:GetZ(), true)
                end
            end, 15000, 1)
            
            npc:RegisterEvent(function(eventId, delay, repeats, npc)
                targetplayer = nil
                if npc:IsAlive() and not npc:IsInCombat() then
                    npc:CastSpell(npc, SPELL_ID_2)
                    npc:DespawnOrUnsummon(1000)
                end
            end, 21000, 1)
        end
    end
    
    -- Schedule next Halloween event
    local nextEventDelay = math.random(EVENT_INTERVAL_MIN, EVENT_INTERVAL_MAX)
    CreateLuaEvent(BonkTime, nextEventDelay, 1)
end

local function OnEnterCombat(event, creature, target)
    if not IsHalloweenPeriod() then
        return
    end
    creature:RemoveEvents()
    creature:SetLootMode(2)
    creature:SetRooted(false)
    creature:MoveClear()
    creature:MoveChase(target)
    creature:SetFaction(128)
    creature:SendUnitYell("Haha! Tricked you!", 0)
    creature:AddAura(TRANSFORM_AURA, creature)
    creature:SetReactState(2)
    creature:SetLevel(90)
    creature:SetScale(3)
    creature:SetMaxHealth(38593)
    creature:SetHealth(38593)
    
    creature:RegisterEvent(function(eventId, delay, repeats, creature)
        if creature and creature:IsAlive() then
            creature:CastSpell(creature, 42921, true) -- Cast arcane explosion on repeat
        else
            creature:RemoveEvents()
        end
    end, math.random(5000, 15000), 0)
end

local function OnLeaveCombat(event, creature, target)
    if creature then
        creature:DespawnOrUnsummon()
    end
    creature:RemoveEvents()
end

local initialDelay = math.random(EVENT_INTERVAL_MIN, EVENT_INTERVAL_MAX)
if GetStateMapId() == -1 then
    CreateLuaEvent(BonkTime, initialDelay, 1)
end
RegisterCreatureEvent(SPAWN_NPC_ID, 1, OnEnterCombat)
RegisterCreatureEvent(SPAWN_NPC_ID, 2, OnLeaveCombat)