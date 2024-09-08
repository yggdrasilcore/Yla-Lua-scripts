local gems = {
    36766, 36767, 36919, 36922, 36925, 36928, 36931, 36934, 40111, 40112, 40113, 40114, 40115, 40116, 40117, 40118, 40119, 40120, 40121, 40122, 40123, 40124, 40125, 40126, 40127, 40128, 40129, 40130, 40131, 40132, 40133, 40134, 40135, 40136, 40137, 40138, 40139, 40140, 40141, 40142, 40143, 40144, 40145, 40146, 40147, 40148, 40149, 40150, 40151, 40152, 40153, 40154, 40155, 40156, 40157, 40158, 40159, 40160, 40161, 40162, 40163, 40164, 40165, 40166, 40167, 40168, 40169, 40170, 40171, 40172, 40173, 40174, 40175, 40176, 40177, 40178, 40179, 40180, 40181, 40182, 42142, 42143, 42144, 42145, 42146, 42148, 42149, 42150, 42151, 42152, 42153, 42154, 42155, 42156, 42157, 42158, 44066, 45862, 45879, 45880, 45881, 45882, 45883, 45987, 49110
}

local CraftedHeadChestLegs245 = {
    42987, 47589, 47590, 47591, 47592, 47593, 47594, 47595, 47596, 47597, 47598, 47599, 47600, 47601, 47602, 47603, 47604, 47605, 47606, 50001, 50038
}

local ilvl200to245 = {
	37835, 39194, 39235, 39283, 39310, 39472, 39717, 39733, 39762, 40187, 40206, 40246, 40270, 40282, 40302, 40305, 40338, 40347, 40362, 40426, 40439, 40474, 40553, 40558, 40733, 40734, 40735, 40736, 40737, 40738, 40739, 40740, 40741, 41168, 41257, 41383, 41384, 41386, 41387, 41388, 41391, 41392, 41394, 41609, 41610, 42100, 42101, 42102, 42103, 42111, 42113, 42435, 42508, 42642, 42643, 42644, 42645, 42646, 42647, 42989, 42990, 43458, 43459, 43461, 43469, 43481, 43484, 43495, 43502, 43565, 43566, 43573, 43582, 43583, 43584, 43585, 43586, 43587, 43588, 43590, 43591, 43592, 43593, 43594, 43595, 43611, 43612, 43613, 44308, 44309, 44310, 44311, 44312, 44313, 44504, 44926, 44930, 44931, 44948, 45085, 45107, 45141, 45167, 45237, 45247, 45274, 45291, 45301, 45316, 45322, 45435, 45450, 45468, 45480, 45493, 45504, 45550, 45551, 45552, 45553, 45554, 45555, 45556, 45557, 45558, 45559, 45560, 45561, 45562, 45563, 45564, 45565, 45566, 45567, 45680, 45704, 45709, 45859, 45874, 45927, 45975, 46009, 48663, 52252
}

local OtherBOEs = {
    37835, 42988, 44253, 44254, 44255, 33350, 43573, 46970, 47089, 47105, 47149, 47223, 47257, 47278, 47291, 47297, 47315, 47570, 47571, 47572, 47573, 47574, 47575, 47576, 47577, 47579, 47580, 47581, 47582, 47583, 47584, 47585, 47586, 47587, 47588, 49890, 49891, 49892, 49893, 49894, 49895, 49896, 49897, 49898, 49899, 49900, 49901, 49902, 49903, 49904, 49905, 49906, 49907, 49967, 49994, 50015, 50020, 50069, 50175, 50182, 50444, 50447, 50449, 50450, 50451, 50452, 50453, 50472
}

local changesCount = 0

local function isInList(item, list)
    for _, v in ipairs(list) do
        if v == item then
            return true
        end
    end
    return false
end

local function isPriceInRange(currentPrice, minPrice, maxPrice)
    return currentPrice >= minPrice and currentPrice <= maxPrice
end

local function ReloadAuctions()
	RunCommand("reload auction")
	print(string.format("Auction adjustment process completed. %d changes made. Auction house tables reloaded.", changesCount))
	changesCount = 0
end

local function AdjustAuctions()
		CharDBQueryAsync("SELECT id, itemguid, buyoutprice, startbid FROM auctionhouse WHERE itemowner = 699 AND buyoutprice > 1000000", function(auctions)
		if not auctions then
			return
		end
		
		repeat
			local auctionId = auctions:GetUInt32(0)
			local itemGuid = auctions:GetUInt32(1)
			local currentBuyout = auctions:GetUInt32(2)
			local currentBid = auctions:GetUInt32(3)
			
		CharDBQueryAsync(string.format("SELECT itemEntry FROM item_instance WHERE guid = %d", itemGuid), function(itemQuery)
			if itemQuery then
				local itemEntry = itemQuery:GetUInt32(0)
				local minPrice, maxPrice, newBuyout, newBid

				if isInList(itemEntry, gems) then
					minPrice, maxPrice = 1000000, 2000000
				elseif isInList(itemEntry, CraftedHeadChestLegs245) then
					minPrice, maxPrice = 28000000, 37000000 -- Darkmoon Card: Greatness with strength is here
				elseif isInList(itemEntry, ilvl200to245) then
					minPrice, maxPrice = 8000000, 12000000 -- The remaining level 80 Darkmoon Cards are here
				elseif isInList(itemEntry, OtherBOEs) then
					minPrice, maxPrice = 12500000, 25000000 -- The other Darkmoon Card: Greatness and Illusion are here
				end

				if minPrice and maxPrice and not isPriceInRange(currentBuyout, minPrice, maxPrice) then
					newBuyout = math.random(minPrice, maxPrice)
					newBid = math.floor(newBuyout * 0.8)
					CharDBExecute(string.format("UPDATE auctionhouse SET buyoutprice = %d, startbid = %d WHERE id = %d", newBuyout, newBid, auctionId))
					print(string.format("Adjusted auction %d for item %d. Old buyout: %d, New buyout: %d, New bid: %d", auctionId, itemEntry, currentBuyout, newBuyout, newBid))
					changesCount = changesCount + 1
					if changesCount == 1 then
						CreateLuaEvent(ReloadAuctions, 1500, 1)
					end
				end
			end
		end)

		until not auctions:NextRow()
	end)
end

local function OnAuctionAdd(event, auctionId, owner, item, expireTime, buyout, startBid, currentBid, bidderGUIDLow)
	print("test all auctions added!")
	if owner:GetGUIDLow() == 699 then
		print("AH bot auction added!")
		CreateLuaEvent(AdjustAuctions, 10, 1)
	end
end

local function ElunaReady(event)
	CreateLuaEvent(AdjustAuctions, 10, 1)
	CreateLuaEvent(AdjustAuctions, 5*60*1000, 0)
end		

RegisterServerEvent(26, OnAuctionAdd)
RegisterServerEvent(33, ElunaReady)

print("Periodic auction adjustment script initialized.")