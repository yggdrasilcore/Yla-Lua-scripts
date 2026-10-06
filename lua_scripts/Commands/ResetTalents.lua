-- Multistate: PLAYER_EVENT_ON_CHAT (18) fires in the global state, but resetting
-- talents mutates the player on its map, so it is forwarded via EMQ. The
-- cooldown table is only touched by the (global) chat handler.
local MS = require("Multistate")
local EMQ = require("EMQ")

-- Table to store the last usage time for each player
local lastUsage = {}

-- Map-state executor (via EMQ, or directly in compatibility mode).
local function DoResetTalents(player)
    if not player then
        return
    end
    -- Reset the player's talents
    player:ResetTalents()

    -- Send a confirmation message to the player
    player:SendBroadcastMessage("Your talents have been reset.")
end

EMQ.RegisterQueue("CmdResetTalents", function(player, data) DoResetTalents(player) end)

if GetStateMapId() ~= -1 then return end

local function OnChat(event, player, msg, Type, lang)
    -- Check if the message is #resettalents
    if msg == "#resettalents" then
        local playerGuid = player:GetGUIDLow()
        local currentTime = os.time()
        
        -- Check if player has used the command before
        if lastUsage[playerGuid] then
            -- Calculate time difference
            local timeDiff = currentTime - lastUsage[playerGuid]
            
            -- Check if enough time has passed (5 seconds cooldown)
            if timeDiff < 5 then
                -- Inform player about remaining cooldown
                local remainingTime = math.ceil(5 - timeDiff)
                player:SendBroadcastMessage("Please wait " .. remainingTime .. " seconds before resetting your talents again.")
                return false
            end
        end
        
        -- Update last usage time for this player
        lastUsage[playerGuid] = currentTime

        if MS.IsCompat() then
            DoResetTalents(player)
        else
            player:SendEMQMessage("CmdResetTalents", {})
        end

        -- Return false to prevent the message from being sent to others
        return false
    end
end

-- Register the chat event
RegisterPlayerEvent(18, OnChat)
