local function HandleQuestAccept(event, player, quest)   
    local questId = quest:GetId()
    
    if questId == 13263 or questId == 13389 then
        -- Icecrown-only branch (map 571): A Short Fuse accept teleport.
        if GetStateMapId() ~= 571 then return end
        player:CastSpell(player, 76010, true)
        player:NearTeleport(5754, 2055, 504, 5.68)
    end

    if questId == 10406 then
        -- Outland-only branch (map 530): Delivering the Message (Netherstorm) escort check.
        if GetStateMapId() ~= 530 then return end
        player:RegisterEvent(function(eventId, delay, repeats, player)
            local Demolitionist = player:GetNearestCreature(50, 20802)
            if not Demolitionist then
                player:CastSpell(player, 35679, false)
            end
        end, 3000)
    end
    
    if questId == 12671 then
        -- Northrend-only branch (map 571): Reconnaissance Flight (Borean Tundra) vehicle check.
        if GetStateMapId() ~= 571 then return end
        player:RegisterEvent(function(eventId, delay, repeats, player)
            local FlyingMachine = player:GetNearestCreature(20, 28710)
            if FlyingMachine then
                if not FlyingMachine:HasAura(52255) then
                    FlyingMachine:AddAura(52255, FlyingMachine)
                end
            end
        end, 155000)
    end
    
    if questId == 13081 then

        local map = player:GetMap()
        if map and map:Data():Get('Event3081') then
            return
        end
        if map then
            map:Data():Set('Event3081', true)
        end
        print("Correct quest and no overlapping event detected! Checking for portal NPC...")
        -- Find nearest creature
        local creature = player:GetNearestCreature(50, 30656)
        if not creature then
            return
            print("No portal NPC found!")
        end

        -- Store creature's home position for later
        local homeX, homeY, homeZ, homeO = creature:GetHomePosition()
        creature:SetSpeed(1, 0.4)
        -- Move creature to specified position
        creature:MoveTo(0, MOVE_TO_POS.x, MOVE_TO_POS.y, MOVE_TO_POS.z, MOVE_TO_POS.o)

        -- Schedule spell cast and text after 5 seconds
        creature:RegisterEvent(function(eventId, delay, repeats, creature)
            creature:CastSpell(creature, 57676, false)
            creature:SendUnitSay("Hail. I could not help but overhear your conversation. Please allow me to lend some assistance.", 0)
        end, 8000)

        -- Schedule return to home position after 10 more seconds
        creature:RegisterEvent(function(eventId, delay, repeats, creature)
            creature:MoveTo(0, 6409, 422, 511,348, 0.62)
        end, 25000)
        
        creature:RegisterEvent(function(eventId, delay, repeats, creature)
            creature:MoveTo(0, 6410.75, 424.23, 511.28, 0.62)
        end, 33000)
        
        creature:RegisterEvent(function(eventId, delay, repeats, creature)
            local m = creature:GetMap()
            if m then
                m:Data():Set('Event3081', nil)
            end
        end, 45000)
    end
end

RegisterPlayerEvent(63, HandleQuestAccept)
