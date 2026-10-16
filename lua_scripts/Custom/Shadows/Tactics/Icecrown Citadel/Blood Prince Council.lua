if GetStateMapId() ~= 631 then return end

 -- Stops shadows from walking through closed doors
 
local AREA_TICK = 250
local KINETIC_TICK = 1500

local function KeepInBPCArea(eventId, delay, repeats, player)
    if not player:IsAlive() then return end
    
    if not player:IsInCombat() then return end

    local valanar = player:GetNearestCreature(125, 37970) -- Prince Valanar
    if not valanar or not valanar:IsInCombat() then return end

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
    
    if player:GetDistance2d(4658, 2769) <= 78 then
        local px, py, pz = player:GetX(), player:GetY(), player:GetZ()
        if pz > 370 then
            player:NearTeleport(px, py, 364.3, player:GetO())
        else
            local floorZ = player:GetFloorZ()
            if pz <= 370 and pz > 360 and floorZ and floorZ < 365 and floorZ > 360 and math.abs(pz - floorZ) > 1 then
                player:NearTeleport(px, py, floorZ, player:GetO())
            end
        end
    end

    player:RegisterEvent(KeepInBPCArea, AREA_TICK)
end

local function ShootKinetics(eventId, delay, repeats, player)
    if not player:IsAlive() then return end
    
    if not player:IsInCombat() then return end
    
    if player:HasCasterSpec() then
        local bombs = player:GetCreaturesInRange(200, 38454)
        if bombs then
            for _, bomb in ipairs(bombs) do
                local last = bomb:GetData("LastFailsafeAttack")
                if not last or os.time() - last >= 4 then
                    local failsafeSpells = {62249, 38400}
                    local chosenSpell = failsafeSpells[math.random(1, 2)]
                    player:StopSpellCast()
                    player:CastSpell(bomb, chosenSpell, false)
                    player:DealDamage(bomb, math.random(501, 5938), false, 6, chosenSpell)
                    bomb:SetData("LastFailsafeAttack", os.time())
                    break
                end
            end
        end
    end
    
    player:RegisterEvent(ShootKinetics, KINETIC_TICK * math.random(0.9, 1.3))
end

local function OnPlayerEnterCombatWithBQL(event, player, enemy)
    if not enemy then return end

    if not player:IsBot() then return end
    
    if (enemy:GetEntry() == 37970 or enemy:GetEntry() == 37972 or enemy:GetEntry() == 37973) -- Blood princes
    then
        player:RegisterEvent(KeepInBPCArea, AREA_TICK)
        player:RegisterEvent(ShootKinetics, KINETIC_TICK)
    end
end

RegisterPlayerEvent(33, OnPlayerEnterCombatWithBQL)
