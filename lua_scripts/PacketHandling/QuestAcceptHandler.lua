local MOVE_TO_POS = {x = 6423, y = 433, z = 511, o = 0.7}
local HOME_POS = {x = 6409, y = 422, z = 511.348, o = 0.62}
local eventActive3081 = false

local function HandleQuestAccept(event, packet, player)   
    -- Read packet data (guid, questId, unk1)
    local guid = packet:ReadGUID()
    local questId = packet:ReadULong()
    local unk1 = packet:ReadULong()

    if questId == 10406 then
        player:RegisterEvent(function(eventId, delay, repeats, player)
            Demolitionist = player:GetNearestCreature(50, 20802)
            if not Demolitionist then
                player:CastSpell(player, 35679, false)
            end
        end, 3000)
    end
    
    if questId == 12671 then
        player:RegisterEvent(function(eventId, delay, repeats, player)
            FlyingMachine = player:GetNearestCreature(20, 28710)
            if FlyingMachine then
                if not FlyingMachine:HasAura(52255) then
                    FlyingMachine:AddAura(52255, FlyingMachine)
                end
            end
        end, 155000)
    end
    
    if questId == 13081 then

        if eventActive3081 == true then
            return
        end
        
        eventActive3081 = true
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
            eventActive3081 = false
        end, 45000)
    end
end

RegisterPacketEvent(0x189, 5, HandleQuestAccept)