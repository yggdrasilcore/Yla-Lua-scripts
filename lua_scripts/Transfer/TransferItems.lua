if GetStateMapId() ~= -1 then return end

local function QueuedGems(queued)
    local gems = {}
    for _, gem in ipairs({ queued.gem1, queued.gem2, queued.gem3 }) do
        if gem > 0 then
            table.insert(gems, gem)
        end
    end
    return gems
end

local function ApplyItemDetails(item, queued)
    if queued.enchant > 0 then
        item:SetEnchantment(queued.enchant, 0)
    end

    local failed = {}
    local gems = { queued.gem1, queued.gem2, queued.gem3 }
    for socket = 1, 3 do
        local gem = gems[socket]
        if gem > 0 then
            if not item:SetGem(gem, socket - 1) then
                table.insert(failed, gem)
            end
        end
    end

    return failed
end

local function PlaceItem(player, queued, forceBags)
    local item = player:CreateItem(queued.itemid, queued.count)
    if not item then
        return false, {}
    end

    local failedGems = ApplyItemDetails(item, queued)

    local placed

    if forceBags then
        placed = nil
    elseif queued.type >= 11 and queued.type <= 29 then
        placed = player:EquipItem(item, queued.type - 11)
    elseif queued.type == 4 then
        placed = player:EquipBag(item, queued.bag)
    elseif queued.type == 3 then
        if queued.bag == 255 and queued.slot >= 67 and queued.slot < 74 then
            placed = player:PlaceItemInBank(item, 255, queued.slot)
        else
            placed = player:PlaceItemInBank(item, queued.bag, queued.slot)
        end
    elseif queued.type == 1 then
        placed = player:PlaceItemInBags(item, queued.bag, queued.slot)
    end

    if not placed then
        placed = player:PlaceItemInBags(item)
    end

    if not placed then
        placed = player:PlaceItemInBank(item)
    end

    return placed ~= nil, failedGems
end

local function MailGems(mailItems, gems)
    for _, gem in ipairs(gems) do
        table.insert(mailItems, { itemid = gem, count = 1 })
    end
end

local function HandleQueuedItem(player, queued, mailItems, forceBags)
    local placed, failedGems = PlaceItem(player, queued, forceBags)

    if placed then
        MailGems(mailItems, failedGems)
    else
        table.insert(mailItems, queued)
        MailGems(mailItems, QueuedGems(queued))
    end
end

local function SendItemMail(mailItems, guid, mailBody)
    while #mailItems > 0 do
        local args = {}
        for _ = 1, math.min(#mailItems, 12) do
            local item = table.remove(mailItems, 1)
            table.insert(args, item.itemid)
            table.insert(args, item.count)
        end

        SendMail("Items", mailBody, guid, 1, 61, 0, 0, 0, unpack(args))
    end
end

local function OnFirstLogin(event, player) -- OnLogin == characters db flag 32 in column at_login
    if player:GetMapId() == 571 then
        local guid = player:GetGUIDLow()
        local name = player:GetName()
        
        CreateLuaEvent(function() -- Ensure we get the player loaded into server cache so we can store session data to it
            RunCommand(".cache refresh "..name)
            RunCommand(".character customize "..name)
        end, 1000, 1)
        
        local itemCache = {}
        
        itemCache[guid] = {}
        
        CharDBQueryAsync("SELECT itemid, count, type, bag, slot, enchant, gem1, gem2, gem3 FROM ycore_yla.character_login_transfer WHERE guid = " .. guid, function(result) -- Get queued items to add to character
            if result then
                repeat
                    table.insert(itemCache[guid], {
                        itemid = result:GetUInt32(0),
                        count = result:GetUInt32(1),
                        type = result:GetUInt32(2),
                        bag = result:GetUInt32(3),
                        slot = result:GetUInt32(4),
                        enchant = result:GetUInt32(5),
                        gem1 = result:GetUInt32(6),
                        gem2 = result:GetUInt32(7),
                        gem3 = result:GetUInt32(8)
                    })
                    
                until not result:NextRow()
        
                local player = GetPlayerByName(name)
                if not player then return end
                
                local achis = {}
                local equippedItems = {}
                local bagEquips = {}
                local bagItems = {}
                local bankBagEquips = {}
                local bankItems = {}
                local inventoryItems = {}
                local mailItems = {}
                
                for _, item in ipairs(itemCache[guid]) do
                    if item.itemid == 6948 then -- Add hearthstone directly to bag, not mail, as characters created in the DB aren't instantiated with their hearthstone
                        table.insert(inventoryItems, item)
                    elseif item.type == 50 then
                        table.insert(achis, item)
                    elseif item.type >= 11 and item.type <= 29 then
                        table.insert(equippedItems, item)
                    elseif item.type == 4 then
                        table.insert(bagEquips, item)
                    elseif item.type == 3 then
                        if item.bag == 255 and item.slot >= 67 and item.slot < 74 then
                            table.insert(bankBagEquips, item)
                        else
                            table.insert(bankItems, item)
                        end
                    elseif item.type == 1 then
                        table.insert(bagItems, item)
                    elseif item.type == 2 then
                        table.insert(inventoryItems, item)
                    else
                        table.insert(mailItems, item)
                    end
                end

                table.sort(bagEquips, function(a, b) return a.bag < b.bag end)
                table.sort(bankBagEquips, function(a, b) return a.slot < b.slot end)
                table.sort(bagItems, function(a, b)
                    if a.bag == b.bag then return a.slot < b.slot end
                    return a.bag < b.bag
                end)
                table.sort(bankItems, function(a, b)
                    if a.bag == b.bag then return a.slot < b.slot end
                    return a.bag < b.bag
                end)
                table.sort(equippedItems, function(a, b) return a.type < b.type end)

                for _, achi in ipairs(achis) do -- Titles
                    player:SetKnownTitle(achi.itemid)
                end

                for _, item in ipairs(bagEquips) do -- Equipped bags
                    HandleQueuedItem(player, item, mailItems)
                end

                for _, item in ipairs(bankBagEquips) do -- Bank bags
                    HandleQueuedItem(player, item, mailItems)
                end

                for _, item in ipairs(equippedItems) do -- Equipped items
                    if (player:GetClass() == 1 or player:GetClass() == 7)
                    and item.type == 27 then -- Weapon in off hand goes to bag just in case the player can't equip it due to missing talents
                        HandleQueuedItem(player, item, mailItems, true)
                    else
                        HandleQueuedItem(player, item, mailItems)
                    end
                end

                for _, item in ipairs(bagItems) do -- Bag contents
                    HandleQueuedItem(player, item, mailItems)
                end

                for _, item in ipairs(bankItems) do -- Bank contents
                    HandleQueuedItem(player, item, mailItems)
                end

                for _, item in ipairs(inventoryItems) do -- Mostly currencies
                    player:AddItem(item.itemid, item.count)
                end

                local mailBody = "Welcome to Yggdrasil!\n\nWe've recovered the following items from your former account.\n\nEnjoy your stay!\n\nBest,\nThe Yggdrasil staff"

                SendItemMail(mailItems, guid, mailBody)

                CharDBExecute("DELETE FROM ycore_yla.character_login_transfer WHERE guid = " .. guid) --Clean up when we're done, unless the script stops at an error preceding this point
                local player = GetPlayerByName(name)
                if not player then return end
                player:RegisterEvent(function(_,_,_,player)
                    player:SendBroadcastMessage("|cFFA64DFFWelcome to Yggdrasil, "..name.."!\nPlease check your mail to retrieve your items. As a part of your arrival, you will be able to customize your character from next logout.|t")
                end, 10000, 1)
            end
        end)
    end
end

RegisterPlayerEvent(30, OnFirstLogin)
