-- Multistate: ticket events fire in the global (WORLD) state,
-- so this script is global-only.
if GetStateMapId() ~= -1 then return end

local DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/1271259248697020416/d06Mm8lDRGspWsVpAwU1p2ZgJNlDWinTLdnOZqE7krNPLV6R9bjWM8jL5Kif0X6tQlmo"

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
    HttpRequest("POST", DISCORD_WEBHOOK_URL, payload, "application/json", function(status, body, headers)
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
    local closer = ticket:GetAssignedPlayer()
    local closerName = closer and closer:GetName() or ("GUID: " .. tostring(ticket:GetAssignedToGUID()))
    SendToDiscord(string.format("**Ticket with ID: %d closed.** \nClosed by: %s",
        ticket:GetId(), closerName))
end

local function OnTicketResolved(event, ticket)
    local resolver = ticket:GetAssignedPlayer()
    local resolverName = resolver and resolver:GetName() or ("GUID: " .. tostring(ticket:GetAssignedToGUID()))
    SendToDiscord(string.format("**Ticket with ID: %d resolved.** \nResolved by: %s",
        ticket:GetId(), resolverName))
end

RegisterTicketEvent(1, OnTicketCreate)
RegisterTicketEvent(3, OnTicketClosed)
RegisterTicketEvent(4, OnTicketResolved)
