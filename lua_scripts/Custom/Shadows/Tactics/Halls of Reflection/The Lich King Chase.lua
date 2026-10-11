-- Multistate: Halls of Reflection-only script (map 668).
if GetStateMapId() ~= 668 then return end

-- HOR TACTICS

local RISEN_WITCH_DOCTOR_ID = 36941
local SHOOT_TRIGGERED_SPELL = 22666
local LK_ID = 36954
local JAINA_CHASE = 36955
local SYLVANAS_CHASE = 37554

function OnEnterHoR(event, player)
    if not (player:GetMapId() == 668) then return end
    
    player:RegisterEvent(function(event, d, r, player)
        if not (player:GetMapId() == 668) then return end
        ToggleShadowsScript(player, "icc", false)
        ToggleShadowsScript(player, "utgarde keep", false)
     end, 5000, 1)
        
    local LK = player:GetNearestCreature(4000, LK_ID)
    
    if LK then
        -- Multistate: Group API is world-only, defer via EMQ (see Helpers/TargetIcon.lua).
        SetTargetIconDeferred(player, 4, LK)
    end
end

local function LichKingChaseLoop(eventId, delay, repeats, lk)
    if lk:IsInCombat() and (not lk:IsStopped() or lk:HasAura(69780)) then
        local leader = lk:GetNearestCreature(500, 36955) or lk:GetNearestCreature(500, 37554)

        if leader then
            local lx, ly, lz = leader:GetLocation()
            local players = lk:GetPlayersInRange(500)

            for _, player in ipairs(players) do
                if player:IsBot() then
                    local pet = player:GetPet()
                    if pet then
                        local petDist = pet:GetDistance(player)
                        if petDist > 15 then
                            pet:MoveClear()
                            pet:MoveTo(99, player:GetX(), player:GetY(), player:GetZ())
                        end
                    end

                    if IsTank(player) then
                        local nearbyEnemies = player:GetCreaturesInRange(40, 0, 1)
                        if nearbyEnemies then
                            for _, enemy in ipairs(nearbyEnemies) do
                                if enemy:GetVictim() ~= player then
                                    Taunt(player, enemy, false)
                                    enemy:AddThreat(player, math.random(500, 1500))
                                end
                            end
                        end
                    end

                    local dist = player:GetDistance(leader)
                    if dist > 10 then
                        player:MoveTo(1, lx + math.random(1, 2), ly + math.random(1, 2), lz, true)
                    end
                end
            end

            local witchDoctors = lk:GetCreaturesInRange(40, RISEN_WITCH_DOCTOR_ID)
            if witchDoctors then
                for _, wd in ipairs(witchDoctors) do
                    local nearbyPlayers = wd:GetPlayersInRange(40)
                    for _, p in ipairs(nearbyPlayers) do
                        if p:IsBot() then
                            local d = p:GetDistance(wd)
                            if d > 10 and d < 40 then
                                p:CastSpell(wd, SHOOT_TRIGGERED_SPELL, true)
                            end
                        end
                    end
                end
            end
        end
    end

    lk:RegisterEvent(LichKingChaseLoop, 500, 1)
end

local function LichKingChaseOnEnterCombat(event, player, enemy)
    if not (player:GetMapId() == 668) then return end
    if enemy and enemy:GetEntry() == LK_ID then
        StartLuaEvent(enemy, LichKingChaseLoop)
        ApplyHiddenBuffsToShadows(player)
    end
end

RegisterPlayerEvent(33, LichKingChaseOnEnterCombat)
RegisterPlayerEvent(28, OnEnterHoR)