-- Multistate: Azshara Mall-only script (mall map 37).
if GetStateMapId() ~= 37 then return end

local function OnHordePortal(e, g, p)
    if p:IsAlliance() then
        p:SendBroadcastMessage("You cannot use this portal.")
        p:SendAreaTriggerMessage("You cannot use this portal.")
        return true
    end
end

local function OnAllyPortal(e, g, p)
    if not p:IsAlliance() then
        p:SendBroadcastMessage("You cannot use this portal.")
        p:SendAreaTriggerMessage("You cannot use this portal.")
        return true
    end
end

RegisterGameObjectEvent(176499, 14, OnHordePortal)
RegisterGameObjectEvent(176501, 14, OnHordePortal)
RegisterGameObjectEvent(182352, 14, OnHordePortal)
RegisterGameObjectEvent(176500, 14, OnHordePortal)

RegisterGameObjectEvent(176296, 14, OnAllyPortal)
RegisterGameObjectEvent(176497, 14, OnAllyPortal)
RegisterGameObjectEvent(176498, 14, OnAllyPortal)
RegisterGameObjectEvent(182351, 14, OnAllyPortal)