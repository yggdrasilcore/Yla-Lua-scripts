function StopLuaEvent(unit)
    unit:RemoveEvents()
    unit:SetData("EventActive", nil)
    unit:SetData("CombatTime", nil)
end