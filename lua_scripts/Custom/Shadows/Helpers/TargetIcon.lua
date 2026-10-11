-- Shared helper: defer Group:SetTargetIcon to the world state via EMQ.
-- Group API is world-only; map hooks must not call it directly.
-- Loads in every state: the queue below runs world-side (on the sender's
-- world timer), SetTargetIconDeferred() is called map-side.
local EMQ = require("EMQ")

-- World-side dedupe: per icon+target, so multi-sender bursts (whole group
-- marks the same target) collapse to one SetTargetIcon, while a lost
-- message never wedges anything — the next send retries. Re-setting an
-- icon is harmless, so entries expire instead of latching forever.
local GUARD_TTL = 60
local setGuard = {}

local function GuardKey(icon, targetLow)
    return icon .. ":" .. targetLow
end

function ResetTargetIconGuards(icon)
    for key in pairs(setGuard) do
        if key:match("^" .. icon .. ":") then
            setGuard[key] = nil
        end
    end
end

EMQ.RegisterQueue("ShadowsSetTargetIcon", function(player, data)
    if not player or not data or not data.icon then return end
    local group = player:GetGroup()
    if not group then return end
    if data.clear then
        ResetTargetIconGuards(data.icon)
        group:SetTargetIcon(data.icon, 0, player:GetGUID())
        return
    end
    if not (data.targetLow and data.targetEntry) then return end
    local key = GuardKey(data.icon, data.targetLow)
    if setGuard[key] and (os.time() - setGuard[key]) < GUARD_TTL then
        return
    end
    group:SetTargetIcon(data.icon, GetUnitGUID(data.targetLow, data.targetEntry), player:GetGUID())
    setGuard[key] = os.time()
end)

-- Map-side: ask the world state to set a raid target icon.
-- setter must be a grouped player (its world-side group is used).
-- target is a creature, or nil to clear the icon.
-- Short-circuits when the icon is already correct: group icon state is
-- readable in any state (GetTargetIcon is METHOD_REG_ALL) and is the
-- source of truth clients render, so a matching mark means no send.
function SetTargetIconDeferred(setter, icon, target)
    if not setter then return end
    local group = setter:GetGroup()
    if not group then return end
    if target then
        if GetGUIDLow(group:GetTargetIcon(icon)) == target:GetGUIDLow() then
            return -- already marked with this icon
        end
        setter:SendEMQMessage("ShadowsSetTargetIcon", {
            icon = icon,
            targetLow = target:GetGUIDLow(),
            targetEntry = target:GetEntry(),
        })
    else
        if GetGUIDLow(group:GetTargetIcon(icon)) == 0 then
            return -- already clear
        end
        setter:SendEMQMessage("ShadowsSetTargetIcon", { icon = icon, clear = true })
    end
end
