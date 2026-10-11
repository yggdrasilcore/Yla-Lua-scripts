-- Brewfest event: Shadows throw beer samples at Dark Iron Guzzlers (23709)
-- Improvements:
--  * Max 2 shadows per guzzler, tracked via guzzler:SetData("ShadowAssignees", {[botGuidLow]=os.time()})
--    Stale claims (> CLAIM_TIMEOUT_SEC) are pruned, so if guzzler still alive a new shadow can claim it.
--  * Auto-trigger via CreateLuaEvent that only starts shadows inside 00-05 and 30-35 minute windows
--    while game event 24 (Brewfest) is active. Manual item (33096) trigger kept as fallback.

local GUZZLER_ENTRY = 23709
local BEER_GO_ENTRY = 186189
local BREWFEST_EVENT_ID = 24
local THROW_SPELL_ID = 42436
local ITEM_ENTRY = 33096

local MAX_SHADOWS_PER_GUZZLER = 2
local CLAIM_TIMEOUT_SEC = 3
local SEARCH_RANGE = 100
local THROW_RANGE = 17
local MELEE_PICKUP_RANGE = 5
local LOOP_DELAY_MS = 250
local LOOP_REPEATS = 1200 -- 250ms x 1200 = 5 minutes
local BEER_REFETCH_SEC = 60
local THROW_COOLDOWN_SEC = 3

-- ---------------------------------------------------------------------------
-- Per-guzzler claim helpers (stored on the guzzler itself via SetData + os.time)
-- ---------------------------------------------------------------------------

local function GetClaimTable(guzzler)
    local t = guzzler:GetData("ShadowAssignees")
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
        guzzler:SetData("ShadowAssignees", claims)
        guzzler:SetData("ShadowClaimTime", now) -- store os.time the setdata was saved, per requirement
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
        -- Refresh own claim so it does not expire while actively fighting
        claims[botGuid] = now
        guzzler:SetData("ShadowAssignees", claims)
        guzzler:SetData("ShadowClaimTime", now)
        return true
    end
    if count >= MAX_SHADOWS_PER_GUZZLER then
        return false -- already 2 fresh shadows on it
    end
    claims[botGuid] = now
    guzzler:SetData("ShadowAssignees", claims)
    guzzler:SetData("ShadowClaimTime", now)
    return true
end

local function ReleaseGuzzler(guzzler, bot)
    if not guzzler or not bot then
        return
    end
    local claims = guzzler:GetData("ShadowAssignees")
    if type(claims) ~= "table" then
        return
    end
    local botGuid = bot:GetGUIDLow()
    if claims[botGuid] then
        claims[botGuid] = nil
        guzzler:SetData("ShadowAssignees", claims)
        guzzler:SetData("ShadowClaimTime", os.time())
    end
end

-- Release this bot's stale claim from every guzzler in range except the one we keep.
local function ReleaseFromOtherGuzzlers(bot, keepGuzzler)
    local keepGuid = keepGuzzler and keepGuzzler:GetGUIDLow() or nil
    local others = bot:GetCreaturesInRange(SEARCH_RANGE, GUZZLER_ENTRY, 0, 1) or {}
    for _, g in ipairs(others) do
        if g:GetGUIDLow() ~= keepGuid then
            ReleaseGuzzler(g, bot)
        end
    end
end

-- Prefer closest claimable guzzler. Returns claimed creature or nil.
local function FindClaimableGuzzler(bot)
    local guzzlers = bot:GetCreaturesInRange(SEARCH_RANGE, GUZZLER_ENTRY, 0, 1) or {}
    if #guzzlers == 0 then
        -- Fallback for cores where GetCreaturesInRange hostile/dead filter behaves differently
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
    return nil -- all nearby guzzlers already have 2 fresh shadows on them
end

local function CleanupShadow(bot, eventId)
    local claimedGuid = bot:GetData("ClaimedGuzzlerGUID")
    if claimedGuid then
        -- Best effort: release if still in range, otherwise it expires after CLAIM_TIMEOUT_SEC anyway
        local guzzlers = bot:GetCreaturesInRange(SEARCH_RANGE, GUZZLER_ENTRY, 0, 0) or {}
        for _, g in ipairs(guzzlers) do
            if g:GetGUIDLow() == claimedGuid then
                ReleaseGuzzler(g, bot)
                break
            end
        end
        bot:SetData("ClaimedGuzzlerGUID", nil)
    end
    bot:SetData("GuzzlerEventStarted", false)
    if eventId then
        bot:RemoveEventById(eventId)
    end
end

local function TryStartShadowLoop(bot)
    if not bot or not bot:IsBot() then
        return false
    end
    if bot:GetData("GuzzlerEventStarted") then
        return false
    end
    if bot:IsDead() then
        return false
    end
    bot:SetData("GuzzlerEventStarted", true)
    bot:SetData("ClaimedGuzzlerGUID", nil)
    bot:RegisterEvent(ShadowsFightGuzzlersLoop, LOOP_DELAY_MS, LOOP_REPEATS) -- Repeat for 5 minutes
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
        player:SetData("GuzzlerEventStarted", true)
    end

    -- Claim (max 2 per guzzler, stale claims >3s pruned inside TryClaimGuzzler)
    -- Always run full 5 min: if no claimable guzzler, idle this tick and retry next tick.
    local guzzler = FindClaimableGuzzler(player)
    if not guzzler then
        return
    end

    player:SetData("ClaimedGuzzlerGUID", guzzler:GetGUIDLow())
    ReleaseFromOtherGuzzlers(player, guzzler)

    local fetchedBeer = player:GetData("FetchedBeer")
    if not fetchedBeer then fetchedBeer = 0 end

    if (fetchedBeer + BEER_REFETCH_SEC < os.time()) then -- Get a beer sample if we don't have one
        local nearestBeer = player:GetNearestGameObject(SEARCH_RANGE, BEER_GO_ENTRY)
        if not nearestBeer then
            player:SetData("FetchedBeer", os.time()) -- Failover to ensure shadows can participate in event
        elseif player:GetExactDistance(nearestBeer) >= MELEE_PICKUP_RANGE then
            player:MoveTo(9999, nearestBeer:GetX(), nearestBeer:GetY(), nearestBeer:GetZ(), true)
        elseif player:GetExactDistance(nearestBeer) < MELEE_PICKUP_RANGE then
            player:MoveStop() -- Simulate picked-up beer
            player:SetData("FetchedBeer", os.time())
        end
    elseif player:GetExactDistance(guzzler) > THROW_RANGE then -- Too far from claimed guzzler? Move to it
        player:MoveTo(9999, guzzler:GetX(), guzzler:GetY(), guzzler:GetZ(), true)
    elseif player:GetExactDistance(guzzler) <= THROW_RANGE and not player:IsWithinLoS(guzzler) then
        player:MoveTo(9999, guzzler:GetX(), guzzler:GetY(), guzzler:GetZ(), true)
    elseif player:GetExactDistance(guzzler) <= THROW_RANGE and player:IsWithinLoS(guzzler) then
        player:MoveStop()
        player:SetFacingToObject(guzzler)
        local lastBrewfestSampleDrink = player:GetData("LastBrewfestSampleDrink")
        if not lastBrewfestSampleDrink or (lastBrewfestSampleDrink + THROW_COOLDOWN_SEC < os.time()) then
            player:SetData("LastBrewfestSampleDrink", os.time())
            player:CastSpell(guzzler, THROW_SPELL_ID, false) -- Kill guzzler if near and within LoS
        end
    end
end

local function ShadowsFightGuzzlers(event, player, item, target)
    if player:IsBot() then return end

    if not player:GetNearestCreature(SEARCH_RANGE, GUZZLER_ENTRY) then return end

    for _, bot in ipairs(player:GetPlayersInRange(SEARCH_RANGE)) do
        if bot:IsBot() and not bot:GetData("GuzzlerEventStarted") then
            TryStartShadowLoop(bot)
        end
    end
end

RegisterItemEvent(ITEM_ENTRY, 2, ShadowsFightGuzzlers)

-- ---------------------------------------------------------------------------
-- Timed auto-trigger: only during Brewfest ambush windows (:00-:05 and :30-:35)
-- ---------------------------------------------------------------------------

local function IsInBrewfestAmbushWindow()
    -- GetGameTime() returns unix seconds. % 3600 => seconds past the hour, TZ-independent.
    -- 0-300s = :00-:05, 1800-2100s = :30-:35
    local secsPastHour = GetGameTime() % 3600
    return secsPastHour <= (5 * 60) or (secsPastHour >= 1800 and secsPastHour <= 2100)
end

local granularEventId = nil

local function BrewfestAutoTrigger(eventId, delay, repeats)
    if not IsGameEventActive(BREWFEST_EVENT_ID) then
        return
    end
    if not IsInBrewfestAmbushWindow() then
        return -- only trigger shadows during :00-:05 and :30-:35, per Brewfest Dark Iron schedule
    end

    local started = 0
    for _, p in ipairs(GetPlayersInWorld()) do
        if p and p:IsBot() and not p:GetData("GuzzlerEventStarted") and not p:IsDead() then
            -- GetNearestCreature is cheaper than GetCreaturesInRange, use as pre-filter
            if p:GetNearestCreature(SEARCH_RANGE, GUZZLER_ENTRY) then
                if TryStartShadowLoop(p) then
                    started = started + 1
                    if started >= 20 then
                        break -- throttle: max 20 new shadows per minute-tick to avoid lag spikes
                    end
                end
            end
        end
    end
end

local function BrewfestScheduler()
    if IsGameEventActive(BREWFEST_EVENT_ID) then
        if not granularEventId then
            granularEventId = CreateLuaEvent(BrewfestAutoTrigger, 60 * 1000, 0)
            BrewfestAutoTrigger()
        end
    elseif granularEventId then
        RemoveEventById(granularEventId)
        granularEventId = nil
    end
end

-- Coarse poll: every 15 min check if Brewfest is active, then arm per-minute window checks.
if GetStateMapId() == 0 or GetStateMapId() == 1 then
    CreateLuaEvent(BrewfestScheduler, 15 * 60 * 1000, 0)
    BrewfestScheduler() -- initial check at load so we don't wait 15 min after restart/reload
end
