-- Multistate: Icecrown Citadel-only script (map 631).
if GetStateMapId() ~= 631 then return end

local CREATURE_ID_1 = 36978
local CREATURE_ID_2 = 36982
local SPELL_ID = 69679
local RANGE_CHECK = 300
local MIN_DISTANCE = 60
local MAX_DISTANCE = 180
local lastcheck = 0

local function OnSpawn(event, creature)
    if os.time() < lastcheck + 15 then return end
    
    lastcheck = os.time()
    
    print("Gunship Cannoneer Debug - gunship spawned")
    
    creature:RegisterEvent(function(eventId, delay, repeats, creature)
        if not creature:GetNearestPlayer(400) or not (creature:GetNearestPlayer(400) and creature:GetNearestPlayer(400):IsInCombat()) then
            print("Gunship Cannoneer Debug - aborting gunship check due to no cb")
            creature:RemoveEventById(eventId)
            return
        end
        
        creature:RegisterEvent(function(eventId, delay, repeats, creature)
            if not creature:GetNearestPlayer(400) or not (creature:GetNearestPlayer(400) and creature:GetNearestPlayer(400):IsInCombat()) then
                print("Gunship Cannoneer Debug - aborting gunship check due to no cb")
                creature:RemoveEventById(eventId)
                return
            end
            
            local cannoneers = creature:GetCreaturesInRange(RANGE_CHECK, CREATURE_ID_1)
            print("Gunship Cannoneer Debug - Checking for ally cannoneers...")
            
            if #cannoneers == 0 then
                print("Gunship Cannoneer Debug - No ally cannoneers found, checking for horde cannoneers...")
                cannoneers = creature:GetCreaturesInRange(RANGE_CHECK, CREATURE_ID_2)
            end
            
            if #cannoneers > 0 then
                print("Gunship Cannoneer Debug - cannoneers found, starting events!")
                for _, cannoneer in pairs(cannoneers) do    
                    cannoneer:SetRooted(true)
                    cannoneer:RegisterEvent(function(eventId, delay, calls, cannoneer)
                        local players = cannoneer:GetPlayersInRange(RANGE_CHECK)
                        for _, player in pairs(players) do
                            if cannoneer:GetDistance(player) > MIN_DISTANCE and cannoneer:GetDistance(player) < MAX_DISTANCE and not player:HasAura(70510) then
                                cannoneer:CastSpell(player, SPELL_ID)
                                print("Gunship Cannoneer Debug - player is in right area, shooting!")
                                break
                            end
                        end
                    end, 0, 1)
                end
            end
        end, 9000, 0)
    end, 40000, 1)
end

RegisterCreatureEvent(37547, 5, OnSpawn)