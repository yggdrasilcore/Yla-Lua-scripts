local DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/1250058781799481407/oBiVwgFyrHiNPgNfISKKXIT1rHGMZ30I8ofXvUZp7dVE6MDwVR92xToo1UVs8nE2o-Ug"

-- Function to send a message to the Discord server
local function SendToDiscord(message)
    local payload = '{"content": "' .. message .. '"}'
    HttpRequest("POST", DISCORD_WEBHOOK_URL, payload, "application/json", function(status, body, headers)
        if status == 204 then
            print("Message successfully sent to Discord!")
        else
            print("Failed to send message to Discord. Status: " .. status)
            print("Response body: " .. body)
        end
    end)
end

local highDiffCount = 0
local lastalert = 0

local function onServerUpdate(event, diff)
    if os.time() - lastalert < 300 then  -- 5-minute grace period
        return  -- Do not track high diff during grace period
    end
    
    if diff > 300 then
        highDiffCount = highDiffCount + 1
    end
    
    if highDiffCount >= 500 then
        print("ALERT! Diff: "..diff)
        
        -- Prepare alert message for Discord
        local playerCount = #GetPlayersInWorld()
		local message
        
        message = string.format("High server diff alert! Diff: %d ms, Players online: %d. Consult the logs to learn why.", diff, playerCount)
		
        -- Send alert to Discord
        SendToDiscord(message)
        
        -- Resets event
        lastalert = os.time()
        highDiffCount = 0
    end
end

local function onStartup(event)
    CharDBQueryAsync("SELECT value FROM acore_eluna.persistent_storage WHERE entry = 'dirty_shutdown'", function(query)
        if query and query:GetString(0) == "1" then
            CharDBExecute("DELETE FROM acore_eluna.persistent_storage WHERE entry = 'dirty_shutdown'")
            return
        end
        SendToDiscord("Unscheduled worldserver restart detected! This is most likely a crash or a compose recreate without a gracefully shutdown!")
    end)
end

local function onShutdown(event)
    if event == 11 then
        CharDBExecute("INSERT INTO acore_eluna.persistent_storage (entry, value, comment) VALUES ('dirty_shutdown', '1', 'Worldserver not gracefully shut down')")
    elseif event == 12 then
        CharDBExecute("DELETE FROM acore_eluna.persistent_storage WHERE entry = 'dirty_shutdown'")
    end
end

RegisterServerEvent(11, onShutdown)
RegisterServerEvent(13, onServerUpdate)
RegisterServerEvent(12, onShutdown)
RegisterServerEvent(14, onStartup)