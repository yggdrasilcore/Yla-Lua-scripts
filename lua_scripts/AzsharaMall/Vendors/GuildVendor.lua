-- Multistate: Azshara Mall-only script (mall map 37).
if not IsCompatibilityMode() and GetStateMapId() ~= 37 then return end

local NPC_ID = 190092 -- Replace with your NPC's ID
local VOTE_TOKEN = 20880
local VOTE_TOKEN_NAME = "Vote Tokens"
local PRICE = 50

local function OnGossipHello(event, player, creature)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/INV_Misc_QuestionMark:32:32:-26:0|t Greetings, what can I do for you?",  0, 1)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/INV_Shirt_GuildTabard_01:32:32:-26:0|t Buy a guild for "..PRICE.." "..VOTE_TOKEN_NAME, 0, 2, true, "What would you like to name your new guild?\n \nAfter entering the new name,\nremember to click 'accept' to continue.\n ")
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_scroll_02:32:32:-26:0|t Rename guild for "..PRICE.." "..VOTE_TOKEN_NAME, 0, 3, true, "What would you like to rename your guild to?\n \nAfter entering the new name,\nremember to click 'accept' to continue.\n ")
    player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:32:32:-26:0|t Nevermind", 0, 9)
    player:GossipSendMenu(12, creature, 60)
    return true
end

local function OnGossipSelect(event, player, creature, sender, intid, code, menu_id)
    if intid == 1 then
        OnGossipHello(event, player, creature)
    elseif intid == 2 then
        if player:IsInGuild() then
            creature:SendUnitWhisper("You can't buy a guild if you're already in a guild!", 0, player)
            player:GossipComplete()
            return false
        end
        if code then
            local guildName = code
            print("Guild Create - Checking guild name: '" .. guildName .. "'")
            print("Guild Create - Guild name length: " .. #guildName)
            
            -- Check each condition separately
            local isLongEnough = #guildName >= 2
            local isShortEnough = #guildName <= 23
            local hasOnlyValidChars = true
            
            for i = 1, #guildName do
                local char = guildName:sub(i,i)
                local isValid = (char >= 'a' and char <= 'z') or (char >= 'A' and char <= 'Z') or char == ' '
                if not isValid then
                    hasOnlyValidChars = false
                    print("Guild Create - Invalid character found: '" .. char .. "' (ASCII: " .. string.byte(char) .. ")")
                    break
                end
            end
            
            print("Guild Create - Is long enough: " .. tostring(isLongEnough))
            print("Guild Create - Is short enough: " .. tostring(isShortEnough))
            print("Guild Create - Has only valid chars: " .. tostring(hasOnlyValidChars))
            
            local isValid = isLongEnough and isShortEnough and hasOnlyValidChars
            print("Guild Create - Is guild name valid: " .. tostring(isValid))
            
            if isValid then
                if player:HasItem(VOTE_TOKEN, PRICE, true) then -- 100g in copper
                    player:RemoveItem(VOTE_TOKEN, PRICE)
                    creature:SendUnitWhisper("Creating guild '" .. guildName .. "' for " .. player:GetName(), 0, player)
                    RunCommand('.guild create ' .. player:GetName() .. ' "' .. guildName .. '"')
                    print('.guild create ' .. player:GetName() .. ' "' .. guildName .. '"')
                    player:GossipComplete()
                else
                    creature:SendUnitWhisper("You don't have enough "..VOTE_TOKEN_NAME.."!", 0, player)
                    OnGossipHello(event, player, creature)
                end
            else
                creature:SendUnitWhisper("Invalid guild name. Use only letters and spaces, between 2 and 23 characters.", 0, player)
                OnGossipHello(event, player, creature)
            end
        else
            OnGossipHello(event, player, creature)
        end
    elseif intid == 3 then
        if not (player:GetGuildRank() == 0) then
            creature:SendUnitWhisper("Only Guild Masters can rename a guild!", 0, player)
            player:GossipComplete()
            return false
        end
        if code then
            local guildName = code
            print("Guild Rename - Checking guild name: '" .. guildName .. "'")
            print("Guild Rename - Guild name length: " .. #guildName)
            
            -- Check each condition separately
            local isLongEnough = #guildName >= 2
            local isShortEnough = #guildName <= 23
            local hasOnlyValidChars = true
            
            for i = 1, #guildName do
                local char = guildName:sub(i,i)
                local isValid = (char >= 'a' and char <= 'z') or (char >= 'A' and char <= 'Z') or char == ' '
                if not isValid then
                    hasOnlyValidChars = false
                    print("Guild Rename - Invalid character found: '" .. char .. "' (ASCII: " .. string.byte(char) .. ")")
                    break
                end
            end
            
            print("Guild Rename - Is long enough: " .. tostring(isLongEnough))
            print("Guild Rename - Is short enough: " .. tostring(isShortEnough))
            print("Guild Rename - Has only valid chars: " .. tostring(hasOnlyValidChars))
            
            local isValid = isLongEnough and isShortEnough and hasOnlyValidChars
            print("Guild Rename - Is guild name valid: " .. tostring(isValid))
            
            if isValid then
                if player:HasItem(VOTE_TOKEN, PRICE, true) then -- 100g in copper
                    player:RemoveItem(VOTE_TOKEN, PRICE)
                    creature:SendUnitWhisper("Your guild "..player:GetGuildName().." has been renamed to '" .. guildName .. "'. The change will be visible after next server restart.", 0, player)
                    RunCommand('.guild rename "'..player:GetGuildName()..'" "' .. guildName .. '"')
                    print('.guild rename "'..player:GetGuildName()..'" "' .. guildName .. '"')
                    player:GossipComplete()
                else
                    creature:SendUnitWhisper("You don't have enough "..VOTE_TOKEN_NAME.."!", 0, player)
                    OnGossipHello(event, player, creature)
                end
            else
                creature:SendUnitWhisper("Invalid guild name. Use only letters and spaces, between 2 and 23 characters.", 0, player)
                OnGossipHello(event, player, creature)
            end
        else
            OnGossipHello(event, player, creature)
        end
    elseif intid == 9 then
        player:GossipComplete()
    end
end

RegisterCreatureGossipEvent(NPC_ID, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ID, 2, OnGossipSelect)