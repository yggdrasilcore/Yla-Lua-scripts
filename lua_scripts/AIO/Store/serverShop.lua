local AIO = require("AIO")

local CustomShop = AIO.AddHandlers("CustomShop", {})

local donationItem = 19322
local voteItem = 20880
local activityItem = 37742

local function payGold(player, totalCost, quantity, itemLink)
    local Gold = math.floor(totalCost / 10000)
    local silver = math.floor((totalCost - (Gold * 10000)) / 100)
    local copper = totalCost - (Gold * 10000) - (silver * 100)
    player:SendBroadcastMessage(
        "You have purchased "
        .. quantity
        .. "x "
        .. itemLink
        .. " for "
        .. Gold
        .. "g "
        .. silver
        .. "s "
        .. copper
        .. "c"
    )
end

local function deductPlayerCurrency(player, costType, totalCost)
    if costType == "Gold" then
        player:ModifyMoney(-totalCost)
    elseif costType == "Honor Tokens" then
        player:SetHonorPoints(player:GetHonorPoints() - totalCost)
    elseif costType == "Arena Tokens" then
        player:SetArenaPoints(player:GetArenaPoints() - totalCost)
    elseif costType == "Community Tokens" then
        player:RemoveItem(donationItem, totalCost)
    elseif costType == "Vote Tokens" then
        player:RemoveItem(voteItem, totalCost)
    elseif costType == "Activity Tokens" then
        player:RemoveItem(activityItem, totalCost)
    end
end

local MAIL_STATIONERY_TEST = 1
local MAIL_STATIONERY_DEFAULT = 41
local MAIL_STATIONERY_GM = 61
local MAIL_STATIONERY_AUCTION = 6
local MAIL_STATIONERY_VAL = 64
local MAIL_STATIONERY_CHR = 65
local MAIL_STATIONERY_ORP = 67

local function getFreeBagSlots(player)
    local freeSlots = 0

    for i = 23, 38 do
        if not player:GetItemByPos(255, i) then
            freeSlots = freeSlots + 1
        end
    end

    for i = 19, 22 do
        local bag = player:GetItemByPos(255, i)
        if bag then
            for x = 0, bag:GetBagSize() - 1 do
                if not player:GetItemByPos(i, x) then
                    freeSlots = freeSlots + 1
                end
            end
        end
    end

    print("Server: You have " .. freeSlots .. " free bag slots.")

    return freeSlots
end


local function purchaseItem(player, itemID, quantity, totalCost, costType)
    local g = player:GetGUIDLow()

   -- Store initial item count, default to 0 if nil
   local initialCount = player:GetItemCount(itemID) or 0
   print("Initial item count:", initialCount)

   -- Attempt to add item
   player:AddItem(itemID, quantity)
   print("Attempting to add item:", itemID, "Quantity:", quantity)

   -- Create a table to store purchase data
   if not purchaseVerification then
       purchaseVerification = {}
       print("purchaseVerification table created")
   end

   -- Store purchase information
   purchaseVerification[g] = {
       itemID = itemID,
       initialCount = initialCount,
       expectedCount = initialCount + quantity,
       quantity = quantity,
       totalCost = totalCost,
       costType = costType,
   }
   print("Purchase information stored for player:", g)

   -- Register event to check item count after 1 second
   player:RegisterEvent(function(eventId, delay, repeats, player)
       local data = purchaseVerification[g]
       if not data then
           print("No purchase data found for player:", g)
           return
       end

       local currentCount = player:GetItemCount(itemID)
       local itemLink = GetItemLink(itemID)
       print("Current item count:", currentCount)
       print("Item link:", itemLink)

       -- If item count increased as expected, process payment
       if currentCount >= data.expectedCount then
           deductPlayerCurrency(player, data.costType, data.totalCost)
           print("Deducting player currency:", data.costType, data.totalCost)

           if data.costType == "Gold" then
               payGold(player, data.totalCost, data.quantity, itemLink)
           else
               player:SendBroadcastMessage(
                   "You have purchased " .. data.quantity .. "x " .. itemLink ..
                   " for " .. data.totalCost .. " " .. data.costType
               )
           end
       else
           player:SendBroadcastMessage("You can't purchase more of this item.")
       end

       -- Clean up verification data
       purchaseVerification[g] = nil
   end, 500, 1)
end

local function purchaseSpell(player, spellID, totalCost, costType)
    if player:HasSpell(spellID) then
        return player:SendBroadcastMessage("You already have this spell.")
    end
    deductPlayerCurrency(player, costType, totalCost)

    player:LearnSpell(spellID)

    if costType == "Gold" then
        payGold(player, totalCost)
    else
        player:SendBroadcastMessage("You have purchased the spell for " .. totalCost .. " " .. costType)
    end
end

local messages = {
    ["Quantity"] = {
        "Quantity cannot be 0 or nil.",
        "Quantity cannot be 0 or nil. Nice try backo",
        "Quantity cannot be 0 or nil. You're not that smart are you?",
        "Is this thing on?",
        "What else would happen?",
        "What can possibly be on the other end?",
        "Yarr there be no quantity here.",
        "Shiver me timbers, there be no quantity here.",
        "By the power of Grayskull, there be no quantity here.",
        "Quantity before quality.",
        "Got some coin for me?",
        "Bring the coin, and I'll bring the goods.",
        "Bring me the booty, and I'll bring you the goods.",
        "Kraken",
        "Shazzbot",
    },
}

local pTime = {}

function CustomShop.addItemOrSpell(player, itemOrSpellID, itemType, quantity, costType, totalCost)
    local g = player:GetGUIDLow()

    if not pTime[g] or pTime[g] < os.time() then
        pTime[g] = os.time() + 2
    else
        return
    end

    if not quantity then
        return
    end

    print(
        "Received AIO.Handle message for itemID:",
        itemOrSpellID,
        "and itemType:",
        itemType .. " and quantity:",
        quantity .. " and costType:",
        costType .. " and totalCost:",
        totalCost
    )

    local playerCurrency
    if costType == "Gold" then
        print("Currency found: "..costType)
        playerCurrency = player:GetCoinage()
    elseif costType == "Honor Tokens" then
        print("Currency found: "..costType)
        playerCurrency = player:GetHonorPoints()
    elseif costType == "Arena Tokens" then
        print("Currency found: "..costType)
        playerCurrency = player:GetArenaPoints()
    elseif costType == "Community Tokens" then
        print("Currency found: "..costType)
        playerCurrency = player:GetItemCount(donationItem, true)
    elseif costType == "Vote Tokens" then
        print("Currency found: "..costType)
        playerCurrency = player:GetItemCount(voteItem, true)
    elseif costType == "Activity Tokens" then
        print("Currency found: "..costType)
        playerCurrency = player:GetItemCount(activityItem, true)
    else
        print("No currency found!")
    end

    -- Debug print to check playerCurrency value
    print("Player currency fetched. Player: "..player:GetName()..". Cost type: "..costType..". playerCurrency: "..tostring(playerCurrency)..".")

    if playerCurrency and playerCurrency >= totalCost then
        if itemType == "item" then
            purchaseItem(player, itemOrSpellID, quantity, totalCost, costType)
        elseif itemType == "spell" then
            purchaseSpell(player, itemOrSpellID, totalCost, costType)
        end
    else
        player:SendBroadcastMessage("You don't have enough currency to purchase this item.")
    end
end
