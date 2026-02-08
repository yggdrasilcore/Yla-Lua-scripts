function StartLuaEvent(unit, eventName)
    if not unit:GetData("EventActive") then
        unit:SetData("EventActive", 1)
        unit:RegisterEvent(eventName, 200, 1)
    end
end