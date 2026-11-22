if GetStateMapId() ~= 631 then return end

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
local CONE_HALF_ANGLE          = math.rad(30)
local REAR_MIN_DIST            = 5
local AREA_HALF_ANGLE          = math.rad(22.5)
local AREA_SHIFT_MAX           = math.rad(67.5)
local areaShift                = 0
local botSpots                 = {}
local tickTimer                = 200
local SUPPRESS_MS              = 900000
local MOVE_STALL_TIME          = 2000

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

local function IsBehindBoss(px, py, bx, by, orientation)
    local proj = -((px - bx) * math.cos(orientation) + (py - by) * math.sin(orientation))
    return proj >= REAR_MIN_DIST
end

local function IsValidPos(tx, ty, bx, by, orientation, minDist, maxDist, requireCone, coldflames)
    local dx   = tx - bx
    local dy   = ty - by
    local dist = math.sqrt(dx*dx + dy*dy)

    if dist < minDist or dist > maxDist then return false end
    if not IsInsidePentagon(tx, ty) then return false end
    if not IsInRearHalf(tx, ty, bx, by, orientation) then return false end
    if not IsBehindBoss(tx, ty, bx, by, orientation) then return false end
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

local function MoveToDest(bot, x, y, z)
    local px, py, pz = bot:GetLocation()
    local now = GetCurrTime()
    if (px - x)^2 + (py - y)^2 + (pz - z)^2 <= 1 then return end

    local lx = bot:Data():Get("MarrowgarMoveX")
    local ly = bot:Data():Get("MarrowgarMoveY")
    local lz = bot:Data():Get("MarrowgarMoveZ")
    if lx and ly and lz and (x - lx)^2 + (y - ly)^2 + (z - lz)^2 <= 1 then
        local gx, gy, gz = bot:Data():Get("MarrowgarMoveFromX"), bot:Data():Get("MarrowgarMoveFromY"), bot:Data():Get("MarrowgarMoveFromZ")
        local stillNear = gx and gy and gz and (px - gx)^2 + (py - gy)^2 + (pz - gz)^2 <= 4
        if stillNear and now - bot:Data():Get("MarrowgarMoveTime") < MOVE_STALL_TIME then return end
    end

    bot:Data():Set("MarrowgarMoveX", x)
    bot:Data():Set("MarrowgarMoveY", y)
    bot:Data():Set("MarrowgarMoveZ", z)
    bot:Data():Set("MarrowgarMoveFromX", px)
    bot:Data():Set("MarrowgarMoveFromY", py)
    bot:Data():Set("MarrowgarMoveFromZ", pz)
    bot:Data():Set("MarrowgarMoveTime", now)
    if bot:IsCasting() then
        bot:StopSpellCast()
    end
    bot:MoveTo(1, x, y, z, true)
end

local function FindPosNearUnit(bot, unit, range, bx, by, bz, orientation, a, center, coldflames)
    local ux, uy = unit:GetX(), unit:GetY()
    local px, py = bot:GetX(), bot:GetY()
    local bestX, bestY, bestDist = nil, nil, math.huge

    for radius = 1.5, range, 1.5 do
        for angle = 0, 359, 15 do
            local rad = math.rad(angle)
            local tx  = ux + radius * math.cos(rad)
            local ty  = uy + radius * math.sin(rad)

            if IsValidPos(tx, ty, bx, by, orientation, a.min, a.max, false, coldflames) then
                local diff = math.atan2(ty - by, tx - bx) - center
                while diff >  math.pi do diff = diff - 2 * math.pi end
                while diff < -math.pi do diff = diff + 2 * math.pi end
                if math.abs(diff) <= AREA_HALF_ANGLE then
                    local dist = math.sqrt((px - tx)^2 + (py - ty)^2)
                    if dist < bestDist then
                        bestDist = dist
                        bestX    = tx
                        bestY    = ty
                    end
                end
            end
        end
    end

    return bestX, bestY, bz
end

local function ColdflameClearance(px, py, coldflames, bx, by)
    local best = math.huge
    for _, cf in ipairs(coldflames) do
        local cx, cy = cf:GetLocation()
        local dx = cx - bx
        local dy = cy - by
        local len = math.sqrt(dx * dx + dy * dy)
        if len > 0 then
            dx, dy = dx / len, dy / len
            local ex = px - bx
            local ey = py - by
            local proj = ex * dx + ey * dy
            if proj >= 0 and proj <= len then
                local perp = math.sqrt((ex - proj * dx)^2 + (ey - proj * dy)^2)
                if perp < best then best = perp end
            end
        end
    end
    return best
end

local function FindSpikePos(bot, spike, reach, bx, by, coldflames)
    local ux, uy = spike:GetX(), spike:GetY()
    local px, py = bot:GetX(), bot:GetY()
    local freeX, freeY, freeDist = nil, nil, math.huge
    local bestX, bestY, bestClear = nil, nil, -1

    for radius = 1.5, reach, 1.5 do
        for angle = 0, 359, 15 do
            local rad = math.rad(angle)
            local tx  = ux + radius * math.cos(rad)
            local ty  = uy + radius * math.sin(rad)

            if IsInsidePentagon(tx, ty) then
                if not InColdflame(tx, ty, coldflames, bx, by) then
                    local dist = math.sqrt((px - tx)^2 + (py - ty)^2)
                    if dist < freeDist then
                        freeDist = dist
                        freeX    = tx
                        freeY    = ty
                    end
                else
                    local clear = ColdflameClearance(tx, ty, coldflames, bx, by)
                    if clear > bestClear then
                        bestClear = clear
                        bestX     = tx
                        bestY     = ty
                    end
                end
            end
        end
    end

    if freeX then return freeX, freeY end
    return bestX, bestY
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
            if bestX then MoveToDest(bot, bestX, bestY, bz) end
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

                if bestX then MoveToDest(bot, bestX, bestY, bz) end
                handled = true
            end
        end

    end
end

local function MarrowgarSetBonestormTargets(marrowgar, botTanks, botDPS)
    local spike = GetNearestBoneSpike(marrowgar)

    for _, tank in ipairs(botTanks) do
        tank:ToShadow():SetTarget(marrowgar)
    end

    for _, bot in ipairs(botDPS) do
        bot:ToShadow():SetTarget(spike or marrowgar)
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
                    MoveToDest(tank, vx, vy, vz)
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
            MoveToDest(tank, tankPos[1], tankPos[2], tankPos[3])
        end

        tank:ToShadow():SetTarget(marrowgar)

        local v = marrowgar:GetVictim()
        if v and v ~= tank then
            marrowgar:AddThreat(tank, 10000 + math.random(-500, 500))
            Taunt(tank, marrowgar, true)
        end
    end
end

local function SlotValid(bx, by, orientation, x, y, a, coldflames, tankX, tankY)
    if not IsValidPos(x, y, bx, by, orientation, a.min, a.max, false, coldflames) then return false end
    if a.healer and math.sqrt((x - tankX)^2 + (y - tankY)^2) > HEALER_TANK_MAX_DIST then return false end
    return true
end

local function InWedge(x, y, bx, by, center)
    local diff = math.atan2(y - by, x - bx) - center
    while diff >  math.pi do diff = diff - 2 * math.pi end
    while diff < -math.pi do diff = diff + 2 * math.pi end
    return math.abs(diff) <= AREA_HALF_ANGLE
end

local function PosValid(bx, by, orientation, x, y, a, coldflames, tankX, tankY, center)
    return SlotValid(bx, by, orientation, x, y, a, coldflames, tankX, tankY) and InWedge(x, y, bx, by, center)
end

local function PickSlot(bx, by, orientation, center, a, coldflames, tankX, tankY)
    local ang = center + a.off
    local ca, sa = math.cos(ang), math.sin(ang)

    local x, y = bx + a.dist * ca, by + a.dist * sa
    if SlotValid(bx, by, orientation, x, y, a, coldflames, tankX, tankY) then return x, y end

    local bestX, bestY, bestGap = nil, nil, math.huge
    for d = a.min, a.max, 0.5 do
        local tx, ty = bx + d * ca, by + d * sa
        if SlotValid(bx, by, orientation, tx, ty, a, coldflames, tankX, tankY) then
            local gap = math.abs(d - a.dist)
            if gap < bestGap then
                bestGap = gap
                bestX   = tx
                bestY   = ty
            end
        end
    end

    return bestX, bestY
end

-- ============================================================
-- Non-Tank Handler
-- ============================================================

local function MarrowgarHandleNonTanks(marrowgar, botHealers, botDPS, botTanks, coldflames)
    local bx, by, bz  = marrowgar:GetLocation()
    local orientation = marrowgar:GetO()

    local tankAnchorX, tankAnchorY = tankPos[1], tankPos[2]
    if botTanks[1] then
        tankAnchorX, tankAnchorY = botTanks[1]:GetX(), botTanks[1]:GetY()
    end

    local spike = GetNearestBoneSpike(marrowgar)

    local groups = {}
    local function AddToRay(bot, minDist, maxDist, healer, dps)
        local key = minDist .. "-" .. maxDist .. (healer and "h" or "")
        groups[key] = groups[key] or {}
        table.insert(groups[key], {bot = bot, min = minDist, max = maxDist, healer = healer, dps = dps})
    end

    for _, bot in ipairs(botHealers) do
        AddToRay(bot, RANGED_MIN_DIST, RANGED_MAX_DIST, true)
    end

    for _, bot in ipairs(botDPS) do
        bot:ToShadow():SetTarget(spike or marrowgar)
        local minDist, maxDist = GetBotDistances(bot)
        AddToRay(bot, minDist, maxDist, false, true)
    end

    local assignments = {}
    for _, group in pairs(groups) do
        table.sort(group, function(x, y) return x.bot:GetGUIDLow() < y.bot:GetGUIDLow() end)
        local n = #group
        for i, a in ipairs(group) do
            a.dist = a.min + (a.max - a.min) * (i - 0.5) / n
            table.insert(assignments, a)
        end
    end

    table.sort(assignments, function(x, y) return x.bot:GetGUIDLow() < y.bot:GetGUIDLow() end)
    local count = #assignments
    for i, a in ipairs(assignments) do
        a.off = -AREA_HALF_ANGLE + 2 * AREA_HALF_ANGLE * (i - 0.5) / count
    end

    local base = orientation + math.pi
    local invalidCount, offSum = 0, 0

    for _, a in ipairs(assignments) do
        local spot   = botSpots[a.bot:GetGUIDLow()]
        local center = base + areaShift
        a.spikeBound = spike ~= nil and a.dps == true
        a.fresh    = spot == nil
        a.realOk   = PosValid(bx, by, orientation, a.bot:GetX(), a.bot:GetY(), a, coldflames, tankAnchorX, tankAnchorY, center)
        a.targetOk = spot ~= nil and PosValid(bx, by, orientation, spot.x, spot.y, a, coldflames, tankAnchorX, tankAnchorY, center)
        a.stale    = not a.spikeBound and not a.fresh and not a.realOk and (not a.targetOk or not a.bot:IsMoving())
        if a.stale then
            invalidCount = invalidCount + 1
            offSum       = offSum + a.off
        end
    end

    if invalidCount > 0 then
        local dir        = offSum > 0 and -1 or (offSum < 0 and 1 or (areaShift > 0 and -1 or 1))
        local startDelta = (invalidCount / count) * 2 * AREA_HALF_ANGLE
        local stepDelta  = math.rad(3)

        local function CountInvalid(shift)
            local n = 0
            for _, a in ipairs(assignments) do
                local ang = base + shift + a.off
                local x, y = bx + a.dist * math.cos(ang), by + a.dist * math.sin(ang)
                if not a.spikeBound and not SlotValid(bx, by, orientation, x, y, a, coldflames, tankAnchorX, tankAnchorY) then n = n + 1 end
            end
            return n
        end

        local bestShift, bestN = nil, math.huge
        for _, sgn in ipairs({dir, -dir}) do
            local delta = (sgn == dir) and startDelta or stepDelta
            while true do
                local shift = areaShift + sgn * delta
                if math.abs(shift) > AREA_SHIFT_MAX then break end
                local n = CountInvalid(shift)
                if n < bestN then
                    bestN     = n
                    bestShift = shift
                end
                if n == 0 then break end
                delta = delta + stepDelta
            end
            if bestN == 0 then break end
        end

        if bestShift then areaShift = bestShift end
    elseif areaShift ~= 0 then
        local allValid = true
        for _, a in ipairs(assignments) do
            local x, y = bx + a.dist * math.cos(base + a.off), by + a.dist * math.sin(base + a.off)
            if not a.spikeBound and not SlotValid(bx, by, orientation, x, y, a, coldflames, tankAnchorX, tankAnchorY) then
                allValid = false
                break
            end
        end
        if allValid then areaShift = 0 end
    end

    for _, a in ipairs(assignments) do
        local bot  = a.bot
        local guid = bot:GetGUIDLow()

        if a.spikeBound then
            local ranged = bot:HasCasterSpec() or bot:GetClass() == 3
            local reach  = ranged and 35 or 5
            local px, py = bot:GetX(), bot:GetY()
            if bot:GetDistance(spike) <= reach and not InColdflame(px, py, coldflames, bx, by) then
                botSpots[guid] = {x = px, y = py}
            else
                local tx, ty = FindSpikePos(bot, spike, reach, bx, by, coldflames)
                if tx then
                    botSpots[guid] = {x = tx, y = ty}
                    MoveToDest(bot, tx, ty, bz)
                end
            end
        elseif a.stale or (a.fresh and not a.realOk) then
            local tx, ty = PickSlot(bx, by, orientation, base + areaShift, a, coldflames, tankAnchorX, tankAnchorY)
            if not tx then
                tx, ty = FindNearestValidPos(bot, bx, by, bz, orientation, a.min, a.max, false, coldflames)
            end
            if not tx then
                tx, ty = FindNearestValidPos(bot, bx, by, bz, orientation, REAR_MIN_DIST, 40, false, coldflames)
            end
            if tx then
                botSpots[guid] = {x = tx, y = ty}
                MoveToDest(bot, tx, ty, bz)
            end
        else
            local spot = botSpots[guid]

            if a.realOk and not a.targetOk then
                spot = {x = bot:GetX(), y = bot:GetY()}
                botSpots[guid] = spot
            end

            if (bot:GetX() - spot.x)^2 + (bot:GetY() - spot.y)^2 > 4 then
                MoveToDest(bot, spot.x, spot.y, bz)
            end
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

    if IsBonestorm(marrowgar) then
        MarrowgarSetBonestormTargets(marrowgar, botTanks, botDPS)
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
    areaShift = 0
    botSpots  = {}
    for _, player in ipairs(marrowgar:GetPlayersInRange(100)) do
        local shadow = player:ToShadow()
        if shadow then
            shadow:SuppressMovement(SUPPRESS_MS)
            if not player:HasHealSpec() then
                shadow:SuppressTargeting(SUPPRESS_MS)
            end
            shadow:SetTarget(marrowgar)
            shadow:ToggleCombatStrategy("-icc")
        end
        if player:GetDifficulty() > 1 then ApplyHiddenBuffsToShadows(player) end
    end

    StartLuaEvent(marrowgar, MarrowgarLoop)
end

RegisterCreatureEvent(MARROWGAR_ENTRY, 1, MarrowgarOnEnterCombat)

local function MarrowgarOnLeaveCombat(event, marrowgar)
    for _, player in ipairs(marrowgar:GetPlayersInRange(200)) do
        local shadow = player:ToShadow()
        if shadow then
            shadow:ClearMovementSuppression()
            shadow:ClearTargetingSuppression()
            shadow:ToggleCombatStrategy("+icc")
        end
    end
end

RegisterCreatureEvent(MARROWGAR_ENTRY, 2, MarrowgarOnLeaveCombat)

local function MarrowgarOnDied(event, marrowgar, killer)
    StopLuaEvent(marrowgar)
    for _, player in ipairs(marrowgar:GetPlayersInRange(200)) do
        local shadow = player:ToShadow()
        if shadow then
            local target = shadow:GetTarget()
            if target and target:GetGUIDLow() == marrowgar:GetGUIDLow() then
                shadow:ClearTarget()
            end
            shadow:ClearMovementSuppression()
            shadow:ClearTargetingSuppression()
            shadow:ToggleCombatStrategy("+icc")
        end
    end
end

RegisterCreatureEvent(MARROWGAR_ENTRY, 4, MarrowgarOnDied)

if GetStateMap() then
    for _, player in ipairs(GetStateMap():GetPlayers()) do
        if player:IsAlive() and player:IsInCombat() and IsInsidePentagon(player:GetX(), player:GetY()) then
            local marrowgar = player:GetNearestCreature(100, MARROWGAR_ENTRY)
            if marrowgar and marrowgar:IsInCombat() then
                MarrowgarOnEnterCombat(nil, marrowgar, nil)
                return
            end
        end
    end
end

