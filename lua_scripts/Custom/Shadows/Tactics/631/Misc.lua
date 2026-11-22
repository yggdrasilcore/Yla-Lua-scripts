if GetStateMapId() ~= 631 then return end

local function ShadowsLeaveCombat(event, player)
    if not player:IsBot() then return end
    player:ToShadow():ClearMovementSuppression()
    player:ToShadow():ClearTargetingSuppression()
    player:ToShadow():ToggleCombatStrategy("+icc")
    RemoveRootAura(player)
end

RegisterPlayerEvent(34, ShadowsLeaveCombat)