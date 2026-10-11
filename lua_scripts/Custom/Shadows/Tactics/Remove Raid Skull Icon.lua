
-- Multistate: the packet handler runs in the global state (Group API is
-- world-only), while PLAYER_EVENT_ON_KILLED_BY_CREATURE (8) fires in map
-- states, so the map side forwards to the global state via EMQ.
local EMQ = require("EMQ")

local function DoSkullClear(player)
    if not player then
        return
    end
    local group = player:GetGroup()
    if not group then return end

    local members = group:GetMembers()
    for _, member in pairs(members) do
        if member:IsAlive() and member:IsInCombat() then
            local distance = player:GetDistance(member)
            if distance <= 100 then
                return
            end
        end
    end

    group:SetTargetIcon(7, 0, player:GetGUID())
end

EMQ.RegisterQueue("SkullIconClear", function(player, data)
    DoSkullClear(player)
end)

-- Multistate: map-only script (death events fire on every map; the EMQ queue
-- above must still register in every state, hence the gate sits below it).
if GetStateMapId() == -1 then return end

local function RemoveRaidIconsOnDeath(event, obj1, player)
    if event == 8 and not player:IsBot() then return end -- Ensures we don't process player death twice as this is in event 7 (packet) anyway

    if GetStateMapId() == -1 then
        DoSkullClear(player)
    else
        player:SendEMQMessage("SkullIconClear", {})
    end
end

RegisterPacketEvent(0x269, 7, RemoveRaidIconsOnDeath) -- This captures all player deaths but packet events don't work on shadows,
RegisterPlayerEvent(8, RemoveRaidIconsOnDeath) -- This works for all creature kills but not other death (shadows can only be killed by creatures, not gravity/drowning etc.)

-- END RAID ICONS SHADOW HANDLING
