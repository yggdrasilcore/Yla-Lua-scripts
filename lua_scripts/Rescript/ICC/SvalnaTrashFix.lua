local function CheckWarlordDeath(eventId, delay, repeats, creature)    
    if creature then
        if not creature:IsAlive() or not creature:IsInCombat() then
            -- Remove aura from the creature
            if creature:HasAura(71244) then
                creature:RemoveAura(71244)
            end
            
        elseif creature:IsInCombat() then
            creature:AddAura(71244, creature)
        end
        
        if not creature:IsAlive() then
            -- Stop the event and update creature data
            creature:RemoveEvents()
            if creature:GetData("WarlordCheck") then
                creature:SetData("WarlordCheck", false)
            end
        end
    else
        RemoveEventById(eventId)
    end
end

local function CheckSvalnaFlag(eventId, delay, repeats, creature)
    if creature then
        print("Running svalna check")
        local OBJECT_END = 0x0006
        local UNIT_FIELD_FLAGS = OBJECT_END + 0x0035
             
        if not creature:GetNearestCreature(100, 37133, 0, 1) and 
           not creature:GetNearestCreature(100, 38133, 0, 1) and 
           not creature:GetNearestCreature(100, 37134, 0, 1) and 
           not creature:GetNearestCreature(100, 37132, 0, 1) then
            -- If no creatures are nearby, make attackable
            creature:RemoveFlag(UNIT_FIELD_FLAGS, 0x00000080)
            creature:RemoveEvents()
            creature:SetData("SvalnaCheck", false)
            print("making svalna attackable")
        elseif not creature:HasFlag(UNIT_FIELD_FLAGS, 0x00000080) then
            creature:SetFlag(UNIT_FIELD_FLAGS, 0x00000080) 
            print("Svalna's troops are nearby, making unattackable")
        end
    else
        creature:SetData("SvalnaCheck", false)
        RemoveEventById(eventId)
    end
end

local function OnEnterCombat(event, player, enemy)
    if not enemy then print("Area combat trigger detected!") return end
    print("Svalna CB start")
    
    local npcId = enemy:GetEntry()
    print(npcId)
    
    -- Check if NPC is one of the specified IDs
    if npcId == 38229 or npcId == 38125 or npcId == 37133 or npcId == 38133 or npcId == 37134 or npcId == 37132 or npcId == 37098 or npcId == 37126 then
        
        if not (npcId == 37126) then
            local svalna = enemy:GetNearestCreature(300, 37126)
        else
            svalna = enemy
        end
        
        if svalna then 
            if not svalna:GetData("SvalnaCheck") then
                svalna:SetData("SvalnaCheck", true)
                svalna:RegisterEvent(CheckSvalnaFlag, 2000, 0)  -- 2000ms = 2 seconds, 0 = repeat indefinitely
                print("Starting Svalna check")
            end
        end
        
        -- Get all warlords in 250 yards range
        local warlords = enemy:GetCreaturesInRange(250, 37133, 0, 1) -- assuming 37133 is the warlord ID
        if warlords then
            for _, warlord in pairs(warlords) do
                print("Warlord found!")
                -- Register check event if not already registered
                if not warlord:GetData("WarlordCheck") then
                    warlord:SetData("WarlordCheck", true)
                    warlord:RegisterEvent(CheckWarlordDeath, 2000, 0)  -- 2000ms = 2 seconds, 0 = repeat indefinitely
                end
            end
        end
    end
end

RegisterPlayerEvent(33, OnEnterCombat)