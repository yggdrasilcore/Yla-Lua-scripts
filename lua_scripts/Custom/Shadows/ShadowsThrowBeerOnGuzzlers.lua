local GUZZLER_ENTRY = 23709
local BEER_GO_ENTRY = 186189
local THROW_SPELL_ID = 42436
local ITEM_ENTRY = 33096

local MAX_SHADOWS_PER_GUZZLER = 2
local CLAIM_TIMEOUT_SEC = 3
local SEARCH_RANGE = 100
local THROW_RANGE = 17
local MELEE_PICKUP_RANGE = 5
local LOOP_DELAY_MS = 250
local LOOP_REPEATS = 1200
local BEER_REFETCH_SEC = 60
local THROW_COOLDOWN_SEC = 3

local function IsInBrewfestAmbushWindow()
    local secsPastHour = GetGameTime() % 3600
    return secsPastHour <= (5 * 60) or (secsPastHour >= 1800 and secsPastHour <= 2100)
end

local function GetClaimTable(guzzler)
    local t = guzzler:Data():Get("ShadowAssignees")
    if type(t) ~= "table" then
        t = {}
    end
    return t
end

local function PruneClaims(guzzler, now)
    local claims = GetClaimTable(guzzler)
    local count = 0
    local changed = false
    for guidLow, timestamp in pairs(claims) do
        if type(timestamp) ~= "number" or (now - timestamp) > CLAIM_TIMEOUT_SEC then
            claims[guidLow] = nil
            changed = true
        else
            count = count + 1
        end
    end
    if changed then
        guzzler:Data():Set("ShadowAssignees", claims)
        guzzler:Data():Set("ShadowClaimTime", now)
    end
    return claims, count
end

local function TryClaimGuzzler(guzzler, bot)
    if not guzzler or not guzzler:IsAlive() then
        return false
    end
    local now = os.time()
    local claims, count = PruneClaims(guzzler, now)
    local botGuid = bot:GetGUIDLow()
    if claims[botGuid] then
        claims[botGuid] = now
        guzzler:Data():Set("ShadowAssignees", claims)
        guzzler:Data():Set("ShadowClaimTime", now)
        return true
    end
    if count >= MAX_SHADOWS_PER_GUZZLER then
        return false
    end
    claims[botGuid] = now
    guzzler:Data():Set("ShadowAssignees", claims)
    guzzler:Data():Set("ShadowClaimTime", now)
    return true
end

local function ReleaseGuzzler(guzzler, bot)
    if not guzzler then
        return
    end
    local ok, claims = pcall(function() return guzzler:Data():Get("ShadowAssignees") end)
    if not ok or type(claims) ~= "table" then
        return
    end
    local botGuid = bot:GetGUIDLow()
    if claims[botGuid] then
        claims[botGuid] = nil
        pcall(function()
            guzzler:Data():Set("ShadowAssignees", claims)
            guzzler:Data():Set("ShadowClaimTime", os.time())
        end)
    end
end

local function ReleaseFromOtherGuzzlers(bot, keepGuzzler)
    local keepGuid = keepGuzzler and keepGuzzler:GetGUIDLow() or nil
    local others = bot:GetCreaturesInRange(SEARCH_RANGE, GUZZLER_ENTRY, 0, 1) or {}
    for _, g in ipairs(others) do
        if g:GetGUIDLow() ~= keepGuid then
            ReleaseGuzzler(g, bot)
        end
    end
end

local function FindClaimableGuzzler(bot)
    local guzzlers = bot:GetCreaturesInRange(SEARCH_RANGE, GUZZLER_ENTRY, 0, 1) or {}
    if #guzzlers == 0 then
        local nearest = bot:GetNearestCreature(SEARCH_RANGE, GUZZLER_ENTRY)
        if nearest and nearest:IsAlive() then
            guzzlers = { nearest }
        else
            return nil
        end
    end
    table.sort(guzzlers, function(a, b)
        return bot:GetExactDistance(a) < bot:GetExactDistance(b)
    end)
    for _, g in ipairs(guzzlers) do
        if g:IsAlive() and TryClaimGuzzler(g, bot) then
            return g
        end
    end
    return nil
end

local function CleanupShadow(bot, eventId)
    local claimedGuid = bot:Data():Get("ClaimedGuzzlerGUID")
    if claimedGuid then
        local guzzlers = bot:GetCreaturesInRange(SEARCH_RANGE, GUZZLER_ENTRY, 0, 0) or {}
        for _, g in ipairs(guzzlers) do
            if g:GetGUIDLow() == claimedGuid then
                ReleaseGuzzler(g, bot)
                break
            end
        end
        bot:Data():Set("ClaimedGuzzlerGUID", nil)
    end
    bot:Data():Set("GuzzlerEventStarted", false)
    if eventId then
        bot:RemoveEventById(eventId)
    end
end

local function TryStartShadowLoop(bot)
    if not bot or not bot:IsBot() then
        return false
    end
    if bot:Data():Get("GuzzlerEventStarted") then
        return false
    end
    if bot:IsDead() then
        return false
    end
    bot:Data():Set("GuzzlerEventStarted", true)
    bot:Data():Set("ClaimedGuzzlerGUID", nil)
    bot:RegisterEvent(ShadowsFightGuzzlersLoop, LOOP_DELAY_MS, LOOP_REPEATS)
    return true
end

function ShadowsFightGuzzlersLoop(event, delays, repeats, player)
    if not player or not player:IsAlive() then
        if player then
            CleanupShadow(player, event)
        end
        return
    end

    if repeats <= 1 then
        CleanupShadow(player, nil)
        return
    else
        player:Data():Set("GuzzlerEventStarted", true)
    end

    local guzzler = FindClaimableGuzzler(player)
    if not guzzler then
        return
    end

    player:Data():Set("ClaimedGuzzlerGUID", guzzler:GetGUIDLow())
    ReleaseFromOtherGuzzlers(player, guzzler)

    local fetchedBeer = player:Data():Get("FetchedBeer")
    if not fetchedBeer then fetchedBeer = 0 end

    if (fetchedBeer + BEER_REFETCH_SEC < os.time()) then
        local nearestBeer = player:GetNearestGameObject(SEARCH_RANGE, BEER_GO_ENTRY)
        if not nearestBeer then
            player:Data():Set("FetchedBeer", os.time())
        elseif player:GetExactDistance(nearestBeer) >= MELEE_PICKUP_RANGE then
            player:MoveTo(9999, nearestBeer:GetX(), nearestBeer:GetY(), nearestBeer:GetZ(), true)
        elseif player:GetExactDistance(nearestBeer) < MELEE_PICKUP_RANGE then
            player:MoveStop()
            player:Data():Set("FetchedBeer", os.time())
        end
    elseif player:GetExactDistance(guzzler) > THROW_RANGE then
        player:MoveTo(9999, guzzler:GetX(), guzzler:GetY(), guzzler:GetZ(), true)
    elseif player:GetExactDistance(guzzler) <= THROW_RANGE and not player:IsWithinLoS(guzzler) then
        player:MoveTo(9999, guzzler:GetX(), guzzler:GetY(), guzzler:GetZ(), true)
    elseif player:GetExactDistance(guzzler) <= THROW_RANGE and player:IsWithinLoS(guzzler) then
        player:MoveStop()
        player:SetFacingToObject(guzzler)
        local lastBrewfestSampleDrink = player:Data():Get("LastBrewfestSampleDrink")
        if not lastBrewfestSampleDrink or (lastBrewfestSampleDrink + THROW_COOLDOWN_SEC < os.time()) then
            player:Data():Set("LastBrewfestSampleDrink", os.time())
            player:CastSpell(guzzler, THROW_SPELL_ID, false)
        end
    end
end

local function ShadowsFightGuzzlers(event, player, item, target)
    if player:IsBot() then return end

    if not IsInBrewfestAmbushWindow() then return end

    if not player:GetNearestCreature(SEARCH_RANGE, GUZZLER_ENTRY) then return end

    for _, bot in ipairs(player:GetPlayersInRange(SEARCH_RANGE)) do
        if bot:IsBot() and not bot:Data():Get("GuzzlerEventStarted") then
            TryStartShadowLoop(bot)
        end
    end
end

if GetStateMapId() == 0 or GetStateMapId() == 1 then
    RegisterItemEvent(ITEM_ENTRY, 2, ShadowsFightGuzzlers)
end