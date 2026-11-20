if GetStateMapId() ~= -1 then return end

if not (GetRealmID() == 1) then return end -- Only on prod

local WebhookConfig = require("Internal/WebhookConfig")

local function SanitizeForJSON(str)
    -- Replace control and non-ASCII characters
    str = str:gsub('[%z\1-\31\127-\255]', ' ')

    -- JSON escapes (backslash must be first)
    str = str:gsub('\\', '\\\\')
          :gsub('"', '\\"')
          :gsub('\n', '\\n')
          :gsub('\r', '\\r')
          :gsub('\t', '\\t')

    return str
end

local function SendToDiscord(message)
    message = SanitizeForJSON(message)
    if #message > 1900 then
        message = message:sub(1, 1900) .. ' [truncated]'
    end
    local payload = '{"content": "' .. message .. '", "allowed_mentions": {"parse": []}}'
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
