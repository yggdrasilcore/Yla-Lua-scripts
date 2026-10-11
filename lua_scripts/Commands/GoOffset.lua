if GetStateMapId() ~= -1 then return end

-- Define the command prefix and name
local commandPrefix = "go"
local commandName = "offset"

-- Helper function to parse input and convert to numbers
local function ParseCommand(message)
    local _, _, x, y, z = string.find(message, commandPrefix .. " " .. commandName .. " ([%d%-%.]+) ([%d%-%.]+) ([%d%-%.]+)")
    if x and y and z then
        return tonumber(x), tonumber(y), tonumber(z)
    end
    local _, _, forward = string.find(message, commandPrefix .. " " .. commandName .. " ([%d%-%.]+)")
    if forward then
        return tonumber(forward)
    end
    return nil
end

local function TeleportOffset(event, player, message, type, language)
    if (message:lower():match("^" .. commandPrefix .. " " .. commandName)) then
        if player:GetGMRank() > 0 then
            local x, y, z = ParseCommand(message)

            if x and y and z then
                local px, py, pz, po = player:GetLocation()
                local newX = px + x
                local newY = py + y
                local newZ = pz + z
                player:Teleport(player:GetMapId(), newX, newY, newZ, po)
                player:SendBroadcastMessage("Teleported to offset location: (" .. newX .. ", " .. newY .. ", " .. newZ .. ")")
            elseif x then
                local px, py, pz, po = player:GetLocation()
                local newX = px + x * math.cos(po)
                local newY = py + x * math.sin(po)
                player:Teleport(player:GetMapId(), newX, newY, pz, po)
                player:SendBroadcastMessage("Teleported " .. x .. " yards forward: (" .. newX .. ", " .. newY .. ", " .. pz .. ")")
            else
                player:SendBroadcastMessage("Invalid command format. Use: " .. commandPrefix .. " " .. commandName .. " X Y Z or " .. commandPrefix .. " " .. commandName .. " DISTANCE")
            end

            -- Block the command from being sent to the chat
            return false
        else
            player:SendBroadcastMessage("You do not have permission to use this command.")
            return false
        end
    end
end

-- Register the command handler
RegisterPlayerEvent(42, TeleportOffset)
