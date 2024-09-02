local DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/1271259248697020416/d06Mm8lDRGspWsVpAwU1p2ZgJNlDWinTLdnOZqE7krNPLV6R9bjWM8jL5Kif0X6tQlmo"
local idClosed = {}

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

-- Function to check new GM tickets
local function OnTicketOpen()
	print("Opcode 0x206 registered!")
    CreateLuaEvent(function()
    local queryResult = CharDBQuery("SELECT id, name, description, closedBy, viewed, type FROM gm_ticket WHERE viewed = 0 AND type = 0")

    if queryResult then
        local ticketsToUpdate = {}

        repeat
            local id = queryResult:GetUInt32(0)
            local name = queryResult:GetString(1)
            local description = queryResult:GetString(2)
            local closedBy = queryResult:GetInt32(3)  -- Using GetInt32 for signed integer
            local viewed = queryResult:GetUInt8(4)    -- Using GetUInt8 for unsigned tinyint

            -- Detailed logging of retrieved ticket
            --print(string.format("Retrieved ticket ID: %d, Name: %s, Description: %s, ClosedBy: %d", id, name, description, closedBy))

            -- If the ticket ID is not in the idClosed table, process it
            if not idClosed[id] then
                idClosed[id] = true

                SendToDiscord(string.format("**New in-game GM Ticket! ID: %d.** \\nName: %s. \\nDescription: %s", 
                    id, name, description))

                -- Add the ID to the list of tickets to update
                table.insert(ticketsToUpdate, id)
            --else
                --print("Duplicate ticket ID: " .. id .. " detected.")
            end
        until not queryResult:NextRow()

        -- Update the viewed status of processed tickets
        if #ticketsToUpdate > 0 then
            for _, id in ipairs(ticketsToUpdate) do
                print("Updating ticket ID: " .. id .. " to viewed.")
                CharDBExecute("UPDATE gm_ticket SET viewed = 1 WHERE id = " .. id)
            end
        --else
        --    print("No tickets to update.")
        end
    --else
        --print("No new tickets found.")
    end
        RemoveEventById(1)
    end, 200, 1)
end

-- Function to handle ticket closing
local function OnTicketClose(event, player, opcode, packet)
    CreateLuaEvent(function()
        --print("Checking for recently closed tickets!")

        -- Collect IDs from the idClosed table
        local idsToCheck = {}
        for id in pairs(idClosed) do
            table.insert(idsToCheck, id)
        end

        if #idsToCheck > 0 then
            -- Construct the SQL query string
            local queryString = "SELECT id, closedBy FROM gm_ticket WHERE id IN (" .. table.concat(idsToCheck, ", ") .. ") AND closedBy > 0"
            
            -- Execute the query
            local queryResult = CharDBQuery(queryString)
            if queryResult then
                --print("Closed ticket found!")
                repeat
                    local id = queryResult:GetUInt32(0)
                    local closedBy = queryResult:GetInt32(1)  -- Changed to GetInt32 for signed integer
					if idClosed[id] then
						idClosed[id] = nil
						--print("ID: " .. id .. ", Closed by: " .. closedBy)
						SendToDiscord("**Ticket with ID: " .. id .. " closed.** \\nClosed by: " .. closedBy)
					end
                until not queryResult:NextRow()
            --else
                --print("No closed tickets found.")
            end
        end
        
        -- Remove this event
        RemoveEventById(1)
    end, 400, 1)
end

RegisterPacketEvent(0x206, 7, OnTicketOpen)
RegisterPacketEvent(0x218, 7, OnTicketClose)