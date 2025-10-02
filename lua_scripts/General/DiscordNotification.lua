DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/1250058781799481407/oBiVwgFyrHiNPgNfISKKXIT1rHGMZ30I8ofXvUZp7dVE6MDwVR92xToo1UVs8nE2o-Ug"

function SendToDiscord(message)
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