 -- Stops shadows from walking through closed doors

local function KeepInBPCArea(eventId, delay, repeats, player)
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
    player:RegisterEvent(KeepInBPCArea, 200, 1)
end

local function OnPlayerKillBQL(event, player, enemy)
    if not enemy then return end
    
    if enemy:GetEntry() == 37970
    or enemy:GetEntry() == 37972
    or enemy:GetEntry() == 37973
    and player:IsBot()
    then
        player:RegisterEvent(KeepInBPCArea, 200, 1)
    end
end

RegisterPlayerEvent(33, OnPlayerKillBQL)