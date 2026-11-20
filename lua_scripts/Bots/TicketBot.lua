if GetStateMapId() ~= -1 then return end

if not (GetRealmID() == 1) then return end -- Only on prod

local WebhookConfig = require("Internal/WebhookConfig")

local function SanitizeForJSON(str)
    -- Replace any non-printable or control characters with spaces
    str = str:gsub('[%z\1-\31\127-\255]', ' ')
    
    -- Basic JSON escapes
    str = str:gsub('\\', '\\\\')
          :gsub('"', '\\"')
          :gsub('\n', '\\n')
          :gsub('\r', '\\r')
          :gsub('\t', '\\t')
          :gsub('\b', '\\b')
          :gsub('\f', '\\f')
          :gsub('/', '\\/')
    
    -- Remove any remaining problematic characters
    str = str:gsub('[^%w%s%p]', '')
    
    return str
end

local function SendToDiscord(message)
    message = SanitizeForJSON(message)
    local payload = '{"content": "' .. message .. '"}'
    HttpRequest("POST", WebhookConfig.ticket, payload, "application/json", function(status, body, headers)
        if status == 204 then
            print("Message successfully sent to Discord!")
        else
            print("Failed to send message to Discord. Status: " .. status)
            print("Response body: " .. body)
        end
    end)
end

local function OnTicketCreate(event, ticket)
    SendToDiscord(string.format("**New in-game GM Ticket! ID: %d.** \nName: %s. \nDescription: %s",
        ticket:GetId(), ticket:GetPlayerName(), ticket:GetMessage()))
end

local function OnTicketClosed(event, ticket)
    SendToDiscord(string.format("**Ticket with ID: %d closed.**", ticket:GetId()))
end

local function OnTicketResolved(event, ticket)
    SendToDiscord(string.format("**Ticket with ID: %d resolved.**", ticket:GetId()))
end

RegisterTicketEvent(1, OnTicketCreate)
RegisterTicketEvent(3, OnTicketClosed)
RegisterTicketEvent(4, OnTicketResolved)
