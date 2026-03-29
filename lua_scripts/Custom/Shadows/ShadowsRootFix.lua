local function RootWatchdogLoop(eventId, delay, repeats, player)
    if not player:IsBot() then player:RemoveEventById(eventId) return end
    if player:IsRooted() and not player:HasUnitState(0x00000400) then
        player:RemoveMovementFlag(0x800)
    end
end

local function OnPlayerMapChange(event, player)
    player:RegisterEvent(RootWatchdogLoop, 5000, 0)
end

RegisterPlayerEvent(28, OnPlayerMapChange)

for _, player in ipairs(GetPlayersInWorld()) do
    player:RegisterEvent(RootWatchdogLoop, 5000, 0)
end