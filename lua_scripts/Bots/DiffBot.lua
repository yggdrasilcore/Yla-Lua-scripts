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
    
    if diff > 100 then
        highDiffCount = highDiffCount + 1
    end
    
    if highDiffCount >= 200 then
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

RegisterServerEvent(13, onServerUpdate)

SendToDiscord("ELUNA server status checker loaded! If you didn't reload ELUNA, this means the worldserver just crashed or restarted.")