 -- Stops shadows from walking through closed doors
 
local TICK = 500

local function KeepInBPCArea(eventId, delay, repeats, player)
    if not player:IsAlive() then return end
    
    if not player:IsInCombat() then player:RemoveEventById(eventId) return end
    if player:GetNearestGameObject(15, 201378) then
        UseRocketBoots(player)
        MoveImmediately(player, 4658, 2798, 361.18)
    elseif player:GetNearestGameObject(15, 201377) then
        UseRocketBoots(player)
        MoveImmediately(player, 4658, 2740, 361.18)
    elseif player:GetNearestGameObject(15, 201376) then
        UseRocketBoots(player)
        MoveImmediately(player, 4609, 2769, 361.17)
    end
    
    player:RegisterEvent(KeepInBPCArea, TICK)
end

local function ShootKinetics(eventId, delay, repeats, player)
    if not player:IsAlive() then return end
    
    if player:HasCasterSpec() then
        local bombs = player:GetCreaturesInRange(200, 38454)
        if bombs then
            for _, bomb in ipairs(bombs) do
                local last = bomb:GetData("LastFailsafeAttack")
                if not last or os.time() - last >= 5 then
                    local failsafeSpells = {62249, 38400}
                    local chosenSpell = failsafeSpells[math.random(1, 2)]
                    player:CastSpell(bomb, chosenSpell, false)
                    player:DealDamage(bomb, math.random(501, 5938), false, 6, chosenSpell)
                    bomb:SetData("LastFailsafeAttack", os.time())
                    break
                end
            end
        end
    end
    player:RegisterEvent(ShootKinetics, TICK * math.random(9, 11))
end

local function OnPlayerEnterCombatWithBQL(event, player, enemy)
    if not enemy then return end

    if not player:IsBot() then return end
    
    if (enemy:GetEntry() == 37970 or enemy:GetEntry() == 37972 or enemy:GetEntry() == 37973) -- Blood princes
    then
        player:RegisterEvent(KeepInBPCArea, TICK)
        player:RegisterEvent(ShootKinetics, TICK)
    end
end

RegisterPlayerEvent(33, OnPlayerEnterCombatWithBQL)
