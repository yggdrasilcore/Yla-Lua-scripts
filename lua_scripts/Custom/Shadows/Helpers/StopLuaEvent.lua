function StopLuaEvent(unit)
    unit:RemoveEvents()
    unit:Data():Set("EventActive", nil)
    unit:Data():Set("CombatTime", nil)
end