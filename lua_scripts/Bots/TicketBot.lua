local DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/1271259248697020416/d06Mm8lDRGspWsVpAwU1p2ZgJNlDWinTLdnOZqE7krNPLV6R9bjWM8jL5Kif0X6tQlmo"
local idClosed = {}

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

local function CheckOpenTickets()
	CharDBQueryAsync("SELECT id, name, description, closedBy, viewed, type FROM gm_ticket WHERE viewed = 0 AND type = 0", function(queryResult)

		if queryResult then
			local ticketsToUpdate = {}

			repeat
				local id = queryResult:GetUInt32(0)
				local name = queryResult:GetString(1)
				local description = queryResult:GetString(2)
				local closedBy = queryResult:GetInt32(3)
				local viewed = queryResult:GetUInt8(4)
				
				SendToDiscord(string.format("**New in-game GM Ticket! ID: %d.** \nName: %s. \nDescription: %s", 
					id, name, description))
				table.insert(ticketsToUpdate, id)
			until not queryResult:NextRow()

			-- Update the viewed status of processed tickets
			if #ticketsToUpdate > 0 then
				for _, id in ipairs(ticketsToUpdate) do
					print("Updating ticket ID: " .. id .. " to viewed.")
					CharDBExecute("UPDATE gm_ticket SET viewed = 1 WHERE id = " .. id)
				end
			end
		end
	end)
end

local function CheckClosedTickets()
   CharDBQueryAsync("SELECT id, closedBy FROM gm_ticket WHERE NOT comment = 'Synced' AND closedBy > 0", function(queryResult)
	   if queryResult then
			--print("Closed ticket found!")
			repeat
				local id = queryResult:GetUInt32(0)
				local closedBy = queryResult:GetInt32(1)
				local player = GetPlayerByGUID(closedBy)
				CharDBExecute("UPDATE gm_ticket SET comment = 'Synced' WHERE id = " .. id)
				if player then
					SendToDiscord("**Ticket with ID: " .. id .. " closed.** \nClosed by: " .. player:GetName())
				else
					SendToDiscord("**Ticket with ID: " .. id .. " closed.** \nClosed by GUID: " .. closedBy)
				end
			until not queryResult:NextRow()
		end
	end)
end

local function OnTicketOpen()
    CreateLuaEvent(CheckOpenTickets, 500, 1)
end

local function OnTicketClose(event, player, opcode, packet)
    CreateLuaEvent(CheckClosedTickets, 5000, 1)
end


CreateLuaEvent(CheckOpenTickets, 15 * 60 * 1000, 0)
CreateLuaEvent(CheckClosedTickets, 15 * 60 * 1000, 0)

RegisterPacketEvent(0x206, 7, OnTicketOpen)
RegisterPacketEvent(0x4F2, 7, OnTicketOpen)
RegisterPacketEvent(0x218, 7, OnTicketClose)