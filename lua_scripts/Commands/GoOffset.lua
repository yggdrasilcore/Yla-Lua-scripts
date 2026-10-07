-- Multistate: PLAYER_EVENT_ON_COMMAND (42) fires in the global state, but the
-- teleport must execute on the player's map state, so it is forwarded via EMQ.
local Multistate = require("Multistate")
local EMQ = require("EMQ")

-- Define the command prefix and name
local commandPrefix = "go"
local commandName = "offset"

-- Helper function to parse input and convert to numbers
local function ParseCommand(message)
    local _, _, x, y, z = string.find(message, commandPrefix .. " " .. commandName .. " ([%d%-%.]+) ([%d%-%.]+) ([%d%-%.]+)")
    return tonumber(x), tonumber(y), tonumber(z)
end

-- Map-state executor: runs on the player's map thread (via EMQ, or directly in
-- compatibility mode).
local function DoTeleportOffset(player, data)
    if not player then
        return
    end
    -- Get the player's current position
    local px, py, pz, po = player:GetLocation()

    -- Calculate the new position
    local newX = px + data.x
    local newY = py + data.y
    local newZ = pz + data.z

    -- Teleport the player to the new position
    player:Teleport(player:GetMapId(), newX, newY, newZ, po)

    -- Notify the player
    player:SendBroadcastMessage("Teleported to offset location: (" .. newX .. ", " .. newY .. ", " .. newZ .. ")")
end

EMQ.RegisterQueue("CmdGoOffset", DoTeleportOffset)

if GetStateMapId() ~= -1 then return end

-- Function to handle the command
local function TeleportOffset(event, player, message, type, language)
    -- Check if the message starts with the command
    if (message:lower():match("^" .. commandPrefix .. " " .. commandName)) then
        -- Only allow GMs to use this command
        if player:GetGMRank() > 0 then
            -- Parse the message to get the X, Y, Z offsets
            local x, y, z = ParseCommand(message)

            if x and y and z then
                local data = { x = x, y = y, z = z }
                if Multistate.IsCompat() then
                    DoTeleportOffset(player, data)
                else
                    player:SendEMQMessage("CmdGoOffset", data)
                end
            else
                player:SendBroadcastMessage("Invalid command format. Use: " .. commandPrefix .. " " .. commandName .. " X Y Z")
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
