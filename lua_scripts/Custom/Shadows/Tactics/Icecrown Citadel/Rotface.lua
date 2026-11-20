if GetStateMapId() ~= 631 then return end

local ROTFACE_ENTRY = 36627

local function RotfaceZCheckLoop(eventId, delay, repeats, player)
    if not player then return end

    local rotface = player:GetNearestCreature(100, ROTFACE_ENTRY, 0, 1)
    if not rotface then return end

    if not player:IsBot() then return end

    if player:GetZ() < 359.5 then
        player:NearTeleport(player:GetX(), player:GetY(), 361, player:GetO())
    end

    player:RegisterEvent(RotfaceZCheckLoop, 2000, 1, player)
end

local function RotfaceOnEnterCombat(event, player, enemy)
    if enemy and enemy:GetEntry() == ROTFACE_ENTRY then
        player:RegisterEvent(RotfaceZCheckLoop, 2000, 1, player)
    end
end

RegisterPlayerEvent(33, RotfaceOnEnterCombat)