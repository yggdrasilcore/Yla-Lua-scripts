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
    
    if diff > 50 then
        highDiffCount = highDiffCount + 1
    end
    
    if highDiffCount >= 200 then
        print("ALERT! Diff: "..diff)
        
        -- Prepare alert message for Discord
        local playerCount = #GetPlayersInWorld()
        local eventCount = #GetActiveGameEvents()
		local message
		
		if eventCount > 50 then
			message = string.format("High server diff alert! Diff: %d ms, Players online: %d, Active Eluna events: %d. Consider reloading ELUNA!", diff, playerCount, eventCount)
		else
			message = string.format("High server diff alert! Diff: %d ms, Players online: %d, Active Eluna events: %d. Consider restarting!", diff, playerCount, eventCount)
        end
		
        -- Send alert to Discord
        SendToDiscord(message)
        
        -- Resets event
        lastalert = os.time()
        highDiffCount = 0
    end
end

RegisterServerEvent(13, onServerUpdate)
print("Diff tracker loaded!")