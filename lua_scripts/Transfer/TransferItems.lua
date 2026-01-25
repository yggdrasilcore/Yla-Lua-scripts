local function OnFirstLogin(event, player) -- OnLogin == characters db flag 32 in column at_login
    if player:GetLevel() > 55 then
        local guid = player:GetGUIDLow()
        local name = player:GetName()
        
        CreateLuaEvent(function() -- Ensure we get the player loaded into server cache so we can store session data to it
            RunCommand(".cache refresh "..name)
            RunCommand(".character customize "..name)
        end, 1000, 1)
        
        local itemCache = {}
        
        itemCache[guid] = {}
        
        CharDBQueryAsync("SELECT itemid, count, type FROM character_login_transfer WHERE guid = " .. guid, function(result) -- Get queued items to add to character
            if result then
                repeat
                    local itemid = result:GetUInt32(0)
                    local count = result:GetUInt32(1)
                    local type = result:GetUInt32(2)

                    table.insert(itemCache[guid], {
                        itemid = itemid,
                        count = count,
                        type = type
                    })
                    
                until not result:NextRow()
        
                local player = GetPlayerByGUID(guid)
                if not player then return end
                
                local achis = {}
                local equipItems = {}
                local inventoryItems = {}
                local mailItems = {}
                
                for _, item in ipairs(itemCache[guid]) do
                    if item.type == 50 then
                        table.insert(achis, item) 
                    elseif item.type < 50 and item.type > 10 then
                        table.insert(equipItems, item) 
                    elseif item.type == 2 or item.itemid == 6948 then -- Add hearthstone directly to bag, not mail, as characters created in the DB aren't instantiated with their hearthstone
                        table.insert(inventoryItems, item) 
                    elseif not (item.itemid == 6948) then
                        table.insert(mailItems, item) 
                    end
                end

                for _, achi in ipairs(achis) do -- Titles
                    player:SetKnownTitle(achi.itemid)
                end
                
                for _, item in ipairs(equipItems) do -- Equipped items
                    local tempSlotId = item.type
                    if tempSlotId > 10 then 
                        local realSlotId = tempSlotId - 11
                        if (player:GetClass() == 1 or player:GetClass() == 7)
                        and realSlotId == 16 then -- Weapon in off hand goes to bag just in case the player can't equip it due to missing talents
                            player:AddItem(item.itemid)
                        else
                            player:EquipItem(item.itemid, realSlotId)
                        end
                    end
                end
                
                for _, item in ipairs(inventoryItems) do -- Mostly currencies
                    player:AddItem(item.itemid, item.count)
                end
                    
            local mailBody = "Welcome to Yggdrasil!\n\nWe've recovered the following items from your former account.\n\nEnjoy your stay!\n\nBest,\nThe Yggdrasil staff"

            while #mailItems > 11 do
                local p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12 = nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil

                for i = 1, 12 do
                    local mailItem = mailItems[1]
                    if not mailItem then break end

                    if i == 1 then 
                        p1, c1 = mailItem.itemid, mailItem.count
                        --print("p1: " .. p1 .. ", c1: " .. c1)
                    elseif i == 2 then 
                        p2, c2 = mailItem.itemid, mailItem.count
                        --print("p2: " .. p2 .. ", c2: " .. c2)
                    elseif i == 3 then 
                        p3, c3 = mailItem.itemid, mailItem.count
                        --print("p3: " .. p3 .. ", c3: " .. c3)
                    elseif i == 4 then 
                        p4, c4 = mailItem.itemid, mailItem.count
                        --print("p4: " .. p4 .. ", c4: " .. c4)
                    elseif i == 5 then 
                        p5, c5 = mailItem.itemid, mailItem.count
                        --print("p5: " .. p5 .. ", c5: " .. c5)
                    elseif i == 6 then 
                        p6, c6 = mailItem.itemid, mailItem.count
                        --print("p6: " .. p6 .. ", c6: " .. c6)
                    elseif i == 7 then 
                        p7, c7 = mailItem.itemid, mailItem.count
                        --print("p7: " .. p7 .. ", c7: " .. c7)
                    elseif i == 8 then 
                        p8, c8 = mailItem.itemid, mailItem.count
                        --print("p8: " .. p8 .. ", c8: " .. c8)
                    elseif i == 9 then 
                        p9, c9 = mailItem.itemid, mailItem.count
                        --print("p9: " .. p9 .. ", c9: " .. c9)
                    elseif i == 10 then 
                        p10, c10 = mailItem.itemid, mailItem.count
                        --print("p10: " .. p10 .. ", c10: " .. c10)
                    elseif i == 11 then 
                        p11, c11 = mailItem.itemid, mailItem.count
                        --print("p11: " .. p11 .. ", c11: " .. c11)
                    elseif i == 12 then 
                        p12, c12 = mailItem.itemid, mailItem.count
                        --print("p12: " .. p12 .. ", c12: " .. c12)
                    end

                    table.remove(mailItems, 1)
                end

                SendMail("Items", mailBody, guid, 1, 61, 0, 0, 0, p1, c1, p2, c2, p3, c3, p4, c4, p5, c5, p6, c6, p7, c7, p8, c8, p9, c9, p10, c10, p11, c11, p12, c12)
            end

                -- Send remaining mail items if any
                if #mailItems > 0 then
                   local itemCount = math.min(#mailItems, 12)
                   
                   if itemCount == 1 then
                       SendMail("Items", mailBody, guid, 1, 61, 0, 0, 0, 
                           mailItems[1].itemid, mailItems[1].count)
                   elseif itemCount == 2 then
                       SendMail("Items", mailBody, guid, 1, 61, 0, 0, 0, 
                           mailItems[1].itemid, mailItems[1].count,
                           mailItems[2].itemid, mailItems[2].count)
                   elseif itemCount == 3 then
                       SendMail("Items", mailBody, guid, 1, 61, 0, 0, 0, 
                           mailItems[1].itemid, mailItems[1].count,
                           mailItems[2].itemid, mailItems[2].count,
                           mailItems[3].itemid, mailItems[3].count)
                   elseif itemCount == 4 then
                       SendMail("Items", mailBody, guid, 1, 61, 0, 0, 0, 
                           mailItems[1].itemid, mailItems[1].count,
                           mailItems[2].itemid, mailItems[2].count,
                           mailItems[3].itemid, mailItems[3].count,
                           mailItems[4].itemid, mailItems[4].count)
                   elseif itemCount == 5 then
                       SendMail("Items", mailBody, guid, 1, 61, 0, 0, 0, 
                           mailItems[1].itemid, mailItems[1].count,
                           mailItems[2].itemid, mailItems[2].count,
                           mailItems[3].itemid, mailItems[3].count,
                           mailItems[4].itemid, mailItems[4].count,
                           mailItems[5].itemid, mailItems[5].count)
                   elseif itemCount == 6 then
                       SendMail("Items", mailBody, guid, 1, 61, 0, 0, 0, 
                           mailItems[1].itemid, mailItems[1].count,
                           mailItems[2].itemid, mailItems[2].count,
                           mailItems[3].itemid, mailItems[3].count,
                           mailItems[4].itemid, mailItems[4].count,
                           mailItems[5].itemid, mailItems[5].count,
                           mailItems[6].itemid, mailItems[6].count)
                   elseif itemCount == 7 then
                       SendMail("Items", mailBody, guid, 1, 61, 0, 0, 0, 
                           mailItems[1].itemid, mailItems[1].count,
                           mailItems[2].itemid, mailItems[2].count,
                           mailItems[3].itemid, mailItems[3].count,
                           mailItems[4].itemid, mailItems[4].count,
                           mailItems[5].itemid, mailItems[5].count,
                           mailItems[6].itemid, mailItems[6].count,
                           mailItems[7].itemid, mailItems[7].count)
                   elseif itemCount == 8 then
                       SendMail("Items", mailBody, guid, 1, 61, 0, 0, 0, 
                           mailItems[1].itemid, mailItems[1].count,
                           mailItems[2].itemid, mailItems[2].count,
                           mailItems[3].itemid, mailItems[3].count,
                           mailItems[4].itemid, mailItems[4].count,
                           mailItems[5].itemid, mailItems[5].count,
                           mailItems[6].itemid, mailItems[6].count,
                           mailItems[7].itemid, mailItems[7].count,
                           mailItems[8].itemid, mailItems[8].count)
                   elseif itemCount == 9 then
                       SendMail("Items", mailBody, guid, 1, 61, 0, 0, 0, 
                           mailItems[1].itemid, mailItems[1].count,
                           mailItems[2].itemid, mailItems[2].count,
                           mailItems[3].itemid, mailItems[3].count,
                           mailItems[4].itemid, mailItems[4].count,
                           mailItems[5].itemid, mailItems[5].count,
                           mailItems[6].itemid, mailItems[6].count,
                           mailItems[7].itemid, mailItems[7].count,
                           mailItems[8].itemid, mailItems[8].count,
                           mailItems[9].itemid, mailItems[9].count)
                   elseif itemCount == 10 then
                       SendMail("Items", mailBody, guid, 1, 61, 0, 0, 0, 
                           mailItems[1].itemid, mailItems[1].count,
                           mailItems[2].itemid, mailItems[2].count,
                           mailItems[3].itemid, mailItems[3].count,
                           mailItems[4].itemid, mailItems[4].count,
                           mailItems[5].itemid, mailItems[5].count,
                           mailItems[6].itemid, mailItems[6].count,
                           mailItems[7].itemid, mailItems[7].count,
                           mailItems[8].itemid, mailItems[8].count,
                           mailItems[9].itemid, mailItems[9].count,
                           mailItems[10].itemid, mailItems[10].count)
                   elseif itemCount == 11 then
                       SendMail("Items", mailBody, guid, 1, 61, 0, 0, 0, 
                           mailItems[1].itemid, mailItems[1].count,
                           mailItems[2].itemid, mailItems[2].count,
                           mailItems[3].itemid, mailItems[3].count,
                           mailItems[4].itemid, mailItems[4].count,
                           mailItems[5].itemid, mailItems[5].count,
                           mailItems[6].itemid, mailItems[6].count,
                           mailItems[7].itemid, mailItems[7].count,
                           mailItems[8].itemid, mailItems[8].count,
                           mailItems[9].itemid, mailItems[9].count,
                           mailItems[10].itemid, mailItems[10].count,
                           mailItems[11].itemid, mailItems[11].count)
                   elseif itemCount == 12 then
                       SendMail("Items", mailBody, guid, 1, 61, 0, 0, 0, 
                           mailItems[1].itemid, mailItems[1].count,
                           mailItems[2].itemid, mailItems[2].count,
                           mailItems[3].itemid, mailItems[3].count,
                           mailItems[4].itemid, mailItems[4].count,
                           mailItems[5].itemid, mailItems[5].count,
                           mailItems[6].itemid, mailItems[6].count,
                           mailItems[7].itemid, mailItems[7].count,
                           mailItems[8].itemid, mailItems[8].count,
                           mailItems[9].itemid, mailItems[9].count,
                           mailItems[10].itemid, mailItems[10].count,
                           mailItems[11].itemid, mailItems[11].count,
                           mailItems[12].itemid, mailItems[12].count)
                   end
                end
                CharDBExecute("DELETE FROM character_login_transfer WHERE guid = " .. guid) --Clean up when we're done, unless the script stops at an error preceding this point
                local player = GetPlayerByName(name)
                player:RegisterEvent(function(_,_,_,player)
                    player:SendBroadcastMessage("|cFFA64DFFWelcome to Yggdrasil, "..name.."!\nPlease check your mail to retrieve your items. As a part of your arrival, you will be able to customize your character from next logout.|t")
                end, 10000, 1)
            end
        end)
    end
end

RegisterPlayerEvent(30, OnFirstLogin)