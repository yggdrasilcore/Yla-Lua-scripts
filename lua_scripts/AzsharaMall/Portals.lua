local function OnHordePortal(e, g, p)
    print("Horde portal used")
    if p:IsAlliance() then
        print("Player is ally - stopping use")
        p:SendBroadcastMessage("You cannot use this portal.")
        p:SendAreaTriggerMessage("You cannot use this portal.")
        return true
    end
    print("Allowing use")
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
RegisterGameObjectEvent(176498, 14, OnAllyPortal)
RegisterGameObjectEvent(176498, 14, OnAllyPortal)
RegisterGameObjectEvent(182351, 14, OnAllyPortal)