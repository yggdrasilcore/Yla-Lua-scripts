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

        player:SendEMQMessage("CmdResetTalents", {})

        -- Return false to prevent the message from being sent to others
        return false
    end
end

-- Register the chat event
RegisterPlayerEvent(18, OnChat)
