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

local function OnTicketOpen()
	print("Opcode 0x206 registered!")
    CreateLuaEvent(function()
        CharDBQueryAsync("SELECT id, name, description, closedBy, viewed, type FROM gm_ticket WHERE viewed = 0 AND type = 0", function(queryResult)

            if queryResult then
                local ticketsToUpdate = {}

                repeat
                    local id = queryResult:GetUInt32(0)
                    local name = queryResult:GetString(1)
                    local description = queryResult:GetString(2)
                    local closedBy = queryResult:GetInt32(3)
                    local viewed = queryResult:GetUInt8(4)
                    
                    if not idClosed[id] then
                        idClosed[id] = true

                        SendToDiscord(string.format("**New in-game GM Ticket! ID: %d.** \\nName: %s. \\nDescription: %s", 
                            id, name, description))
                        table.insert(ticketsToUpdate, id)
                    end
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
        RemoveEventById(1)
    end, 500, 1)
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
           CharDBQueryAsync("SELECT id, closedBy FROM gm_ticket WHERE id IN (" .. table.concat(idsToCheck, ", ") .. ") AND closedBy > 0", function(queryResult)
			   if queryResult then
					--print("Closed ticket found!")
					repeat
						local id = queryResult:GetUInt32(0)
						local closedBy = queryResult:GetInt32(1)  -- Changed to GetInt32 for signed integer
                        local player = GetPlayerByGUID(closedBy)
						if idClosed[id] then
							idClosed[id] = nil
							--print("ID: " .. id .. ", Closed by: " .. closedBy)
                            if player then
                                SendToDiscord("**Ticket with ID: " .. id .. " closed.** \\nClosed by: " .. player:GetName())
                            else
                                SendToDiscord("**Ticket with ID: " .. id .. " closed.** \\nClosed by GUID: " .. closedBy)
                            end
                        end
					until not queryResult:NextRow()
				end
			end)
		end
        RemoveEventById(1)
    end, 5000, 1)
end

RegisterPacketEvent(0x206, 7, OnTicketOpen)
RegisterPacketEvent(0x4F2, 7, OnTicketOpen)
RegisterPacketEvent(0x218, 7, OnTicketClose)