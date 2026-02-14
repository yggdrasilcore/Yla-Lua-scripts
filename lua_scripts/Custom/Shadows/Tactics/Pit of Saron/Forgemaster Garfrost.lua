
-- POS TACTIC HACKS

local function AddShadowsGarfrostFrostProtection(event, player, enemy)
    if enemy then
        if enemy:GetEntry() == 36494 then -- 36494 is Garfrost
            if isPlayerBot[player:GetName()] then
                player:AddAura(2705400, player)
            end
        else
            if player:HasAura(2705400) then
                player:RemoveAura(2705400)
            end
        end
    else
        if player:HasAura(2705400) then
            player:RemoveAura(2705400)
        end
    end
end  

local function RemoveShadowsGarfrostFrostProtection(event, player)
    if player:HasAura(2705400) then
        player:RemoveAura(2705400)
    end
end

RegisterPlayerEvent(33, AddShadowsGarfrostFrostProtection) -- Enter combat

RegisterPlayerEvent(3, RemoveShadowsGarfrostFrostProtection) -- On login, if stale aura
RegisterPlayerEvent(34, RemoveShadowsGarfrostFrostProtection) -- Leave combat

-- END POS TACTICS HACKS