-- Brewfest event

local function ShadowsFightGuzzlersLoop(event, delays, repeats, player)
    local nearestGuzzler = player:GetNearestCreature(100, 23709) 

    if not nearestGuzzler then
        player:SetData("GuzzlerEventStarted", false)
        player:RemoveEventById(event) -- Remove event early if no more guzzlers
        return
    end
    
    player:SetData("GuzzlerEventStarted", true)
    
    local fetchedBeer = player:GetData("FetchedBeer")
    if not fetchedBeer then fetchedBeer = 0 end

    if (fetchedBeer + 60 < os.time()) then -- Get a beer sample if we don't have one
        local nearestBeer = player:GetNearestGameObject(100, 186189)
        if not nearestBeer then
            player:SetData("FetchedBeer", os.time()) -- Failover to ensure shadows can participate in event
        elseif player:GetExactDistance(nearestBeer) > 5 then
            player:MoveTo(9999, nearestBeer:GetX(), nearestBeer:GetY(), nearestBeer:GetZ(), true)
        elseif player:GetExactDistance(nearestBeer) < 3 then
            player:MoveStop() -- Simulate picked-up beer
            player:SetData("FetchedBeer", os.time())
        end
    elseif player:GetExactDistance(nearestGuzzler) > 17 then -- Too far from nearest guzzler? Move to it
        player:MoveTo(9999, nearestGuzzler:GetX(), nearestGuzzler:GetY(), nearestGuzzler:GetZ(), true)
    elseif player:GetExactDistance(nearestGuzzler) < 12 and player:IsWithinLoS(nearestGuzzler) then
        player:MoveStop()
        player:SetFacingToObject(nearestGuzzler)
        local lastBrewfestSampleDrink = player:GetData("LastBrewfestSampleDrink")
        if not lastBrewfestSampleDrink or (lastBrewfestSampleDrink + 3 < os.time()) then
            player:SetData("LastBrewfestSampleDrink", os.time())
            player:CastSpell(nearestGuzzler, 42436, false) -- Kill guzzler if near and within LoS
        end
    end
end

local function ShadowsFightGuzzlers(event, player, item, target)
    if player:IsBot() then return end
    
    if not player:GetNearestCreature(100, 23709)  then return end
    
    for _, bot in ipairs(player:GetPlayersInRange(100)) do
        if bot:IsBot() and not bot:GetData("GuzzlerEventStarted") then
            bot:RegisterEvent(ShadowsFightGuzzlersLoop, 250, 240) -- Repeat for 60 seconds (250 ms x 240 times)
        end
    end
end

RegisterItemEvent(33096, 2, ShadowsFightGuzzlers)