-- Function to check if the player is a GM
local function IsPlayerGM(player)
    if player then
        return player:IsGM()
    else
        return false
    end
end

-- Function to parse the chat command and learn the specified talent
local function OnChat(event, player, message, type, language)
    -- Check if the message starts with the command '#learn('
    if message:sub(1, 7) == "#learn(" then
        if not IsPlayerGM(player) then
            player:SendBroadcastMessage("You must be a GM to use this command!")
            return false
        end

        -- Extract the arguments from the command
        local talentID, rank = message:match("#learn%((%d+),(%d+)%)")

        -- If the arguments are successfully extracted
        if talentID and rank then
            -- Convert talentID and rank to numbers
            talentID = tonumber(talentID)
            rank = tonumber(rank)

            -- Check if the conversion was successful
            if talentID and rank then
                local target = player:GetSelection()
                local success = false
                local beforePoints, afterPoints

                -- Check if there's a target selected
                if target then
                    beforePoints = target:ToPlayer():GetFreeTalentPoints()
                    success = target:ToPlayer():LearnTalent(talentID, rank)
                    afterPoints = target:ToPlayer():GetFreeTalentPoints()
                else
                    beforePoints = player:GetFreeTalentPoints()
                    success = player:LearnTalent(talentID, rank)
                    afterPoints = player:GetFreeTalentPoints()
                end
                if beforePoints == afterPoints then
                    player:Say("Failed to learn talent ID=" .. talentID .. " Rank=" .. rank .. ".", 0)
                end
            else
                player:SendBroadcastMessage("Invalid talentID or rank.")
            end
        else
            player:SendBroadcastMessage("Invalid command format. Use #learn(talentID,rank).")
        end

        -- Prevent the chat message from being sent to other players
        return false
    end
end

-- Register the chat event to listen for messages
RegisterPlayerEvent(18, OnChat)