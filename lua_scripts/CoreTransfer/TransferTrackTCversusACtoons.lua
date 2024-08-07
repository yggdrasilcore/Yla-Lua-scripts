local function OnFirstLogin(event, player)
    local guid = player:GetGUIDLow()

    -- Check if the player already has an entry in the transferlog
    local query = CharDBQuery("SELECT 1 FROM transferlog WHERE guid = " .. guid)

    if not query then
        -- Insert the player's GUID into the transferlog table
        CharDBExecute("INSERT INTO transferlog (guid, newcharacter) VALUES (" .. guid .. ", 1)")
    end
end

RegisterPlayerEvent(30, OnFirstLogin)

print("Transfer tracker loaded!") --for console debugging