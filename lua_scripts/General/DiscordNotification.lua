local WebhookConfig = require("Internal/WebhookConfig")

local lastSent = 0

function SendToDiscord(message)
    local now = os.time()
    if now - lastSent < 5 then return end

    local delay = now - lastSent
    if lastSent ~= 0 and delay > 1 then
        message = message .. " (original time: " .. os.date("%H:%M:%S", now - delay) .. ")"
    end

    lastSent = now

    local payload = '{"content": "' .. message .. '"}'
    HttpRequest("POST", WebhookConfig.notification, payload, "application/json", function(status, body, headers)
        if status == 204 then
            print("Message successfully sent to Discord!")
        else
            print("Failed to send message to Discord. Status: " .. status)
            print("Response body: " .. body)
        end
    end)
end