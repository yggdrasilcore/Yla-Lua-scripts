local function SendAnniversary(event, player, command)
   
    local args = {}
    for word in command:gmatch("%w+") do
        table.insert(args, word)
    end

    if args[1] ~= "sendanniversary" then
        return
    end
    
    if not args[2] or (player:GetGMRank() < 3) then
        if player:GetGMRank() > 2 then
            player:SendBroadcastMessage("Usage: .sendanniversary <playername>")
        end
        return false
    end

    local playername = args[2]
    
    local sender = player:GetName()
     
    print("starting query on "..playername)
    CharDBQueryAsync("SELECT guid FROM characters WHERE name = '"..playername.."'", 
    function(query)
        print("query done")
        player = GetPlayerByName(sender)
        if not query then
            player:SendBroadcastMessage("Error: Player not found in database.")
            return
        end
        
        local receiverGUIDLow = query:GetUInt32(0)
        local subject = "6 Month Anniversary Gift from Staff"
        local body = string.format([[Greetings, %s!
This month, the server turns 6 months, and we would like to include you in the half-year anniversary. Thank you for all the hard work you are doing by being an active player and member of our community. You are an integral part of our journey and we hope that you will take part in our continued growth as well.
Stay tuned on Discord for more anniversary information!
Best regards,
The Yggdrasil staff.]], playername)

        SendMail(subject, body, receiverGUIDLow, 3, 61, 0, 10000000, 0, 43516, 1, 49426, 40)
        player:SendBroadcastMessage("Anniversary mail sent to " .. playername .. ".")
        print("Anniversary mail sent to " .. playername .. ".")
    end)
    
    return false
end

local function OnPacketReceive(event, packet, player)
    print("246 received")
    local mailbox = packet:ReadGUID()
    local mailId = packet:ReadULong()
    local itemLowGuid = packet:ReadULong()
    print(mailId)
    print(itemLowGuid)
    name = player:GetName()

    CharDBQueryAsync("SELECT itemEntry FROM item_instance WHERE guid = "..itemLowGuid, function(result)
        if result then
            player = GetPlayerByName(name)
            local itemEntry = result:GetUInt32(0)
            print("Real Item ID: " .. itemEntry)
            
            if itemEntry == 43516 and player:HasSpell(58615) then
                player:RemoveItem(43516, 1)
                player:SendBroadcastMessage("You've already mastered the "..GetItemLink(43516).."' controls. The reins are a familiar tool and no longer useful to you.")
            end
        end
    end)
end


local function OnLogin(event, player)
    if player:HasItem(43516) and player:HasSpell(58615) then
        player:RemoveItem(43516, 1)
    end
end

RegisterPacketEvent(0x246, 5, OnPacketReceive)
RegisterPlayerEvent(3, OnLogin)
RegisterPlayerEvent(42, SendAnniversary)