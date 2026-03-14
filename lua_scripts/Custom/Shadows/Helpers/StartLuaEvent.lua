function StartLuaEvent(unit, eventName)
    if not unit:GetData("EventActive") then
        unit:SetData("EventActive", 1)
        unit:SetData("CombatTime", 0)
        unit:SetData("CombatStart", os.time())
        unit:RegisterEvent(eventName, 200, 1)
    end
end