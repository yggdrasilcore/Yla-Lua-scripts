local MARROWGAR_ENTRY  = 36612
local COLDFLAME_ENTRY  = 36672
local BONE_SPIKE_IDS   = {36619, 38711, 38712}
local BONESTORM_AURA   = 69076

local tankPos          = {-413,  2211, 42}
local bossPos          = {-401,  2211, 42.07}
local raidCenter       = {-379,  2211, 42}

local pentagon = {
    {-427, 2210, 42},
    {-389, 2284, 42},
    {-344, 2211, 42},
    {-363, 2166, 42},
    {-400, 2151, 43},
}

local COLDFLAME_DANGER         = 5
local BONESTORM_SPREAD_RADIUS  = 30
local BONESTORM_MELEE_MIN_DIST = 7
local BONESTORM_RANGE_MIN_DIST = 10
local MELEE_MIN_DIST           = 10
local MELEE_MAX_DIST           = 15
local RANGED_MIN_DIST          = 15
local RANGED_MAX_DIST          = 20
local HUNTER_MIN_DIST          = 25
local HUNTER_MAX_DIST          = 26
local HEALER_TANK_MAX_DIST     = 40
local CONE_HALF_ANGLE          = math.rad(22.5)
local tickTimer                = 200
local SUPPRESS_MS              = 900000

-- ============================================================
-- Helpers
-- ============================================================

local function GetColdflames(marrowgar)
    return marrowgar:GetCreaturesInRange(200, COLDFLAME_ENTRY)
end

local function InColdflame(px, py, coldflames, bossX, bossY)
    for _, cf in ipairs(coldflames) do
        local cx, cy = cf:GetLocation()
        local dx = cx - bossX
        local dy = cy - bossY
        local len = math.sqrt(dx * dx + dy * dy)
        if len > 0 then dx, dy = dx / len, dy / len end
        local ex = px - bossX
        local ey = py - bossY
        local proj = ex * dx + ey * dy
        local perpX = ex - proj * dx
        local perpY = ey - proj * dy
        local perpDist = math.sqrt(perpX * perpX + perpY * perpY)
        local lineLen = math.sqrt((cx - bossX)^2 + (cy - bossY)^2)
        if proj >= 0 and proj <= lineLen and perpDist < COLDFLAME_DANGER then
            return true
        end
    end
    return false
end

local function IsBonestorm(marrowgar)
    return marrowgar:HasAura(BONESTORM_AURA)
end

local function GetNearestBoneSpike(marrowgar)
    local nearest, nearestDist = nil, math.huge
    for _, entry in ipairs(BONE_SPIKE_IDS) do
        local spike = marrowgar:GetNearestCreature(100, entry, 0)
        if spike then
            local d = marrowgar:GetDistance(spike)
            if d < nearestDist then
                nearestDist = d
                nearest     = spike
            end
        end
    end
    return nearest
end

local function IsInsidePentagon(px, py)
    local inside = false
    local n      = #pentagon
    local j      = n
    for i = 1, n do
        local xi, yi = pentagon[i][1], pentagon[i][2]
        local xj, yj = pentagon[j][1], pentagon[j][2]
        if ((yi > py) ~= (yj > py)) and (px < (xj - xi) * (py - yi) / (yj - yi) + xi) then
            inside = not inside
        end
        j = i
    end
    return inside
end

local function IsInRearCone(bx, by, orientation, tx, ty)
    local dx            = tx - bx
    local dy            = ty - by
    local angleToPoint  = math.atan2(dy, dx)
    local relativeAngle = angleToPoint - orientation

    while relativeAngle >  math.pi do relativeAngle = relativeAngle - 2 * math.pi end
    while relativeAngle < -math.pi do relativeAngle = relativeAngle + 2 * math.pi end

    return math.abs(relativeAngle) > (math.pi - CONE_HALF_ANGLE)
end

local function IsInRearHalf(px, py, bossX, bossY, bossO)
    local angle = math.atan2(py - bossY, px - bossX)
    local diff  = angle - bossO
    while diff >  math.pi do diff = diff - 2 * math.pi end
    while diff < -math.pi do diff = diff + 2 * math.pi end
    return math.abs(diff) > math.pi * 0.5
end

local function IsValidPos(tx, ty, bx, by, orientation, minDist, maxDist, requireCone, coldflames)
    local dx   = tx - bx
    local dy   = ty - by
    local dist = math.sqrt(dx*dx + dy*dy)

    if dist < minDist or dist > maxDist then return false end
    if not IsInsidePentagon(tx, ty) then return false end
    if requireCone and not IsInRearCone(bx, by, orientation, tx, ty) then return false end
    if InColdflame(tx, ty, coldflames, bx, by) then return false end

    return true
end

local function FindNearestValidPos(bot, bx, by, bz, orientation, minDist, maxDist, requireCone, coldflames)
    local bestX, bestY, bestDist = nil, nil, math.huge
    local px, py = bot:GetX(), bot:GetY()

    for radius = minDist, maxDist, 0.5 do
        for angle = 0, 359, 3 do
            local rad = math.rad(angle)
            local tx  = bx + radius * math.cos(rad)
            local ty  = by + radius * math.sin(rad)

            if IsValidPos(tx, ty, bx, by, orientation, minDist, maxDist, requireCone, coldflames) then
                local dx   = px - tx
                local dy   = py - ty
                local dist = math.sqrt(dx*dx + dy*dy)
                if dist < bestDist then
                    bestDist = dist
                    bestX    = tx
                    bestY    = ty
                end
            end
        end
    end

    return bestX, bestY, bz
end

local function GetBotDistances(bot)
    if bot:GetClass() == 3 then
        return HUNTER_MIN_DIST, HUNTER_MAX_DIST
    elseif bot:HasMeleeSpec() then
        return MELEE_MIN_DIST, MELEE_MAX_DIST
    else
        return RANGED_MIN_DIST, RANGED_MAX_DIST
    end
end

-- ============================================================
-- Bone Spike Marking
-- ============================================================

local function MarrowgarMarkBoneSpike(marrowgar, allPlayers)
    local spike = GetNearestBoneSpike(marrowgar)
    if not spike then return end

    local spikeGUID = spike:GetGUID()

    for _, player in ipairs(allPlayers) do
        if player:IsAlive() then
            local group = player:GetGroup()
            if group then
                if group:GetTargetIcon(7) == spikeGUID then return end
                group:SetTargetIcon(7, spikeGUID, player:GetGUID())
                return
            end
        end
    end
end

-- ============================================================
-- Bonestorm Handler
-- ============================================================

local function MarrowgarBonestormMove(marrowgar, bots, coldflames)
    local bx, by, bz = marrowgar:GetLocation()

    for _, bot in ipairs(bots) do
        local px, py = bot:GetX(), bot:GetY()
        local handled = false

        if InColdflame(px, py, coldflames, bx, by) then
            local minDist = (bot:HasTankSpec() or bot:HasMeleeSpec()) and BONESTORM_MELEE_MIN_DIST or BONESTORM_RANGE_MIN_DIST
            local bestX, bestY, bestDist = nil, nil, math.huge
            for radius = minDist, BONESTORM_SPREAD_RADIUS, 2 do
                for a = 0, 355, 10 do
                    local rad = math.rad(a)
                    local tx  = raidCenter[1] + radius * math.cos(rad)
                    local ty  = raidCenter[2] + radius * math.sin(rad)
                    if IsInsidePentagon(tx, ty) and not InColdflame(tx, ty, coldflames, bx, by) then
                        local d = math.sqrt((tx-px)^2 + (ty-py)^2)
                        if d < bestDist then
                            bestDist = d
                            bestX, bestY = tx, ty
                        end
                    end
                end
                if bestX then break end
            end
            if bestX then MoveImmediately(bot, bestX, bestY, bz) end
            handled = true
        end

        if not handled then
            local minDist = (bot:HasTankSpec() or bot:HasMeleeSpec()) and BONESTORM_MELEE_MIN_DIST or BONESTORM_RANGE_MIN_DIST
            local dx      = px - bx
            local dy      = py - by
            local dist    = math.sqrt(dx*dx + dy*dy)

            if dist < minDist then
                local angle = math.atan2(dy, dx)
                if angle == 0 then angle = math.random() * math.pi * 2 end
                local prefX = raidCenter[1] + math.cos(angle) * (minDist + 3)
                local prefY = raidCenter[2] + math.sin(angle) * (minDist + 3)

                local bestX, bestY = nil, nil
                if IsInsidePentagon(prefX, prefY) and not InColdflame(prefX, prefY, coldflames, bx, by) then
                    bestX = prefX
                    bestY = prefY
                else
                    local bestDist = math.huge
                    for radius = minDist, BONESTORM_SPREAD_RADIUS, 2 do
                        for a = 0, 355, 10 do
                            local rad = math.rad(a)
                            local tx  = raidCenter[1] + radius * math.cos(rad)
                            local ty  = raidCenter[2] + radius * math.sin(rad)
                            if IsInsidePentagon(tx, ty) and not InColdflame(tx, ty, coldflames, bx, by) then
                                local ddx = tx - px
                                local ddy = ty - py
                                local d   = math.sqrt(ddx*ddx + ddy*ddy)
                                if d < bestDist then
                                    bestDist = d
                                    bestX    = tx
                                    bestY    = ty
                                end
                            end
                        end
                    end
                end

                if bestX then MoveImmediately(bot, bestX, bestY, bz) end
                handled = true
            end
        end

        if not handled then
            AddRootAura(bot, 3000)
        end
    end
end

-- ============================================================
-- Tank Handler
-- ============================================================

local function MarrowgarHandleTanks(marrowgar, botTanks)
    if #botTanks == 0 then return end

    local victim = marrowgar:GetVictim()

    if victim and victim:IsPlayer() and not victim:IsBot() then
        if not IsAtPos(victim, tankPos[1], tankPos[2], 5) then
            local vx, vy, vz = victim:GetLocation()
            for _, tank in ipairs(botTanks) do
                ApplyDamageReductionStacks(tank, (20 + tank:GetDifficulty()*15), 30000)
                if not IsAtPos(tank, vx, vy, 3) then
                    UseRocketBoots(tank)
                    MoveImmediately(tank, vx, vy, vz)
                else
                    AddRootAura(tank, 2000)
                end
            end
            return
        end
    end

    if victim and victim:IsPlayer() and IsAtPos(victim, tankPos[1], tankPos[2], 5) then
        if not IsAtPos(marrowgar, bossPos[1], bossPos[2], 7) then
            marrowgar:MoveTo(1, bossPos[1], bossPos[2], bossPos[3], true)
        end
    end

    for _, tank in ipairs(botTanks) do
        ApplyDamageReductionStacks(tank, (20 + tank:GetDifficulty()*15), 30000)

        if not IsAtPos(tank, tankPos[1], tankPos[2], 3) then
            UseRocketBoots(tank)
            MoveImmediately(tank, tankPos[1], tankPos[2], tankPos[3])
        else
            AddRootAura(tank, 2000)
        end

        local v = marrowgar:GetVictim()
        if v and v ~= tank then
            marrowgar:AddThreat(tank, 10000 + math.random(-500, 500))
            Taunt(tank, marrowgar, true)
        end
    end
end

-- ============================================================
-- Non-Tank Handler
-- ============================================================

local function MarrowgarHandleNonTanks(marrowgar, botHealers, botDPS, botTanks, coldflames)
    local bx, by, bz  = marrowgar:GetLocation()
    local orientation = marrowgar:GetO()

    local tankAnchorX = botTanks[1]:GetX()
    local tankAnchorY = botTanks[1]:GetY()

    local spike = GetNearestBoneSpike(marrowgar)

    local function HandleBot(bot, minDist, maxDist, checkHealerRange)
        local px, py = bot:GetX(), bot:GetY()

        if InColdflame(px, py, coldflames, bx, by) then
            local tx, ty, tz = FindNearestValidPos(bot, bx, by, bz, orientation, minDist, maxDist, true, coldflames)
            if tx then MoveImmediately(bot, tx, ty, tz) end
            return
        end

        if checkHealerRange then
            local tdx = px - tankAnchorX
            local tdy = py - tankAnchorY
            if math.sqrt(tdx*tdx + tdy*tdy) > HEALER_TANK_MAX_DIST then
                local tx, ty, tz = FindNearestValidPos(bot, bx, by, bz, orientation, minDist, maxDist, true, coldflames)
                if tx then MoveImmediately(bot, tx, ty, tz) end
                return
            end
        end

        if IsValidPos(px, py, bx, by, orientation, minDist, maxDist, true, coldflames) then
            AddRootAura(bot, 2000)
        else
            local tx, ty, tz = FindNearestValidPos(bot, bx, by, bz, orientation, minDist, maxDist, true, coldflames)
            if tx then MoveImmediately(bot, tx, ty, tz) end
        end
    end

    for _, bot in ipairs(botHealers) do
        HandleBot(bot, RANGED_MIN_DIST, RANGED_MAX_DIST, true)
    end

    for _, bot in ipairs(botDPS) do
        local minDist, maxDist = GetBotDistances(bot)
        if spike then
            local px, py = bot:GetX(), bot:GetY()
            local inRearHalf     = IsInRearHalf(px, py, bx, by, orientation)
            local target         = bot:GetTarget()
            local targetingSpike = target and target:GetGUID() == spike:GetGUID()
            if InColdflame(px, py, coldflames, bx, by) or not inRearHalf or not targetingSpike then
                local tx, ty, tz = FindNearestValidPos(bot, bx, by, bz, orientation, minDist, maxDist, false, coldflames)
                if tx then MoveImmediately(bot, tx, ty, tz) end
            end
        else
            HandleBot(bot, minDist, maxDist, false)
        end
    end
end

-- ============================================================
-- Main Loop
-- ============================================================

local function MarrowgarLoop(eventId, delay, repeats, marrowgar)
    if marrowgar:IsDead() or not marrowgar:IsInCombat() then
        StopLuaEvent(marrowgar)
        return
    end

    local allPlayers = marrowgar:GetPlayersInRange(100)
    local bots       = {}

    for _, player in ipairs(allPlayers) do
        if player:IsAlive() and player:IsInCombat() and player:IsBot() then
            table.insert(bots, player)
        end
    end

    if #bots == 0 then
        StopLuaEvent(marrowgar)
        return
    end

    for _, bot in ipairs(bots) do
        local shadow = bot:ToShadow()
        if not shadow:IsMovementSuppressed() then
            shadow:SuppressMovement(SUPPRESS_MS)
        end
    end

    local coldflames = GetColdflames(marrowgar)

    local botTanks   = {}
    local botHealers = {}
    local botDPS     = {}

    for _, bot in ipairs(bots) do
        if bot:HasTankSpec() then
            table.insert(botTanks, bot)
        elseif bot:HasHealSpec() then
            table.insert(botHealers, bot)
        else
            table.insert(botDPS, bot)
        end
    end

    MarrowgarMarkBoneSpike(marrowgar, allPlayers)

    if IsBonestorm(marrowgar) then
        MarrowgarBonestormMove(marrowgar, bots, coldflames)
    else
        MarrowgarHandleTanks(marrowgar, botTanks)
        MarrowgarHandleNonTanks(marrowgar, botHealers, botDPS, botTanks, coldflames)
    end

    marrowgar:RegisterEvent(MarrowgarLoop, tickTimer, 1)
end

-- ============================================================
-- Enter / Leave Combat
-- ============================================================

local function MarrowgarOnEnterCombat(event, marrowgar, target)
    for _, player in ipairs(marrowgar:GetPlayersInRange(100)) do
        local shadow = player:ToShadow()
        if shadow then
            shadow:SuppressMovement(SUPPRESS_MS)
            shadow:ToggleCombatStrategy("-icc")
        end
        if player:GetDifficulty() > 1 then ApplyHiddenBuffsToShadows(player) end
    end

    StartLuaEvent(marrowgar, MarrowgarLoop)
end

RegisterCreatureEvent(MARROWGAR_ENTRY, 1, MarrowgarOnEnterCombat)

local function MarrowgarOnLeaveCombat(event, marrowgar)
    local map = marrowgar:GetMap()
    for _, player in ipairs(map:GetPlayers()) do
        local shadow = player:ToShadow()
        if shadow then
            shadow:ClearMovementSuppression()
            shadow:ToggleCombatStrategy("+icc")
        end
    end
end

RegisterCreatureEvent(MARROWGAR_ENTRY, 2, MarrowgarOnLeaveCombat)