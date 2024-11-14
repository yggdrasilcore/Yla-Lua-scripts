local function OnPlayerLogout(event, player)
   local playerGuid = player:GetGUIDLow()
   CreateLuaEvent(function()
       CharDBExecute("UPDATE characters SET online = 0 WHERE guid = " .. playerGuid)
   end, 1000, 1)
end

RegisterPlayerEvent(4, OnPlayerLogout)