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
    -- EMQ icon gating (Helpers/TargetIcon.lua) is per icon+target: drop the
    -- guards for 7 so the next pull re-marks instead of waiting out the TTL.
    if ResetTargetIconGuards then ResetTargetIconGuards(7) end
end

EMQ.RegisterQueue("SkullIconClear", function(player, data)
    DoSkullClear(player)
end)

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
