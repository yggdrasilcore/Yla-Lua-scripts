if GetStateMapId() ~= -1 then return end

if not (GetRealmID() == 1) then return end -- Only on prod

local function onStartup(event)
    CharDBQueryAsync("SELECT value FROM ycore_yla.persistent_storage WHERE entry = 'dirty_shutdown'", function(query)
        if query and query:GetString(0) == "1" then
            CharDBExecute("DELETE FROM ycore_yla.persistent_storage WHERE entry = 'dirty_shutdown'")
            return
        end
        SendToDiscord("Unscheduled worldserver restart detected! This is most likely a crash or a compose recreate without a gracefully shutdown!")
    end)
end

local function onShutdown(event)
    if event == 11 then
        CharDBExecute("INSERT INTO ycore_yla.persistent_storage (entry, value, comment) VALUES ('dirty_shutdown', '1', 'Worldserver not gracefully shut down')")
    elseif event == 12 then
        CharDBExecute("DELETE FROM ycore_yla.persistent_storage WHERE entry = 'dirty_shutdown'")
    end
end

RegisterServerEvent(11, onShutdown)
RegisterServerEvent(12, onShutdown)
RegisterServerEvent(14, onStartup)