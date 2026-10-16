-- Multistate: map-only script (all hooks fire in map states).
if GetStateMapId() == -1 then return end

local function TreeFormWatchdogLoop(eventId, delay, repeats, player)
    if not player:IsBot() then player:RemoveEventById(eventId) return end
    if not player:IsInCombat() then return end
    if player:HasSpell(33891) and not player:HasAura(33891) then
        player:CastSpell(player, 33891, true)
    end
end

local function OnPlayerMapChange(event, player)
    if player:IsBot() and player:GetClass() == 11 then
        player:RegisterEvent(TreeFormWatchdogLoop, 3000, 0)
    end
end

RegisterPlayerEvent(28, OnPlayerMapChange)
if GetStateMap() then
    for _, player in ipairs(GetStateMap():GetPlayers()) do
        OnPlayerMapChange(nil, player)
    end
end