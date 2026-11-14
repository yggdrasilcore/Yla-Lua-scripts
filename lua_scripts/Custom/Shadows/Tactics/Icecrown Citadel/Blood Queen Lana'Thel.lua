if not (GetStateMapId() == 631) then return end

-- ============================================================
-- Blood-Queen Lana'thel (ICC, map 631)
-- Spell IDs from boss_blood_queen_lana_thel.cpp
-- ============================================================

local BLOOD_QUEEN_ENTRY          = 37955

-- Boss spells
local SPELL_VAMPIRIC_BITE_10N    = 70946
local SPELL_VAMPIRIC_BITE_25N    = 71475
local SPELL_VAMPIRIC_BITE_10H    = 71476
local SPELL_VAMPIRIC_BITE_25H    = 71477
local SPELL_ESSENCE_OF_BLOOD_QUEEN   = 70867
local SPELL_ESSENCE_OF_THE_BLOOD_QUEEN_PLR = 70879

local FRENZIED_BLOODTHIRST_SPELLS = { 70877, 71474, 71949, 72151, 72648, 72649, 72650 }
local SPELL_PACT_OF_THE_DARKFALLEN = 71340
local SPELL_SWARMING_SHADOWS     = 71264
local SPELL_SWARMING_SHADOWS_TRAIL = 71265
local SPELL_INCITE_TERROR        = 73070
local SWARMING_SHADOWS_NPC       = 38163

-- Shadow abilities used by this script
local SPELL_TREMOR_TOTEM         = 8143
local SPELL_FEAR_WARD            = 6346
local SPELL_MASS_DISPEL          = 32375
local SPELL_EVERY_MAN_FOR_HIMSELF = 59752

-- CLASS_PRIEST, CLASS_SHAMAN, RACE_HUMAN
local CLASS_PRIEST               = 5
local CLASS_SHAMAN               = 7
local RACE_HUMAN                 = 1

-- Positions
local CENTER                     = {4596, 2769, 400}
local TANK_GROUND                = {4603, 2769, 400}

-- Radii
local ROOM_RADIUS                = 37
local HEALER_RADIUS              = 10
local AIR_RADIUS                 = 25
local RANGED_MIN                 = 15
local RANGED_MAX                 = 30
local RANGED_LIMIT               = 40
local HEALER_MAX_RADIUS          = 15
local SEPARATION                 = 7
local POSITION_REFRESH_MS        = 5000

local PULL_DURATION              = 10
local SUPPRESS_MS                = 900000
local MESH_STEP                  = 2
local ANGLE_STEP                 = 10

local AIR_PHASE_INTERVAL         = 124000

local function InRoom(p)
    return p:GetX() > 4537 and p:GetX() < 4635
        and p:GetY() > 2729 and p:GetY() < 2808
        and math.abs(p:GetZ() - CENTER[3]) <= 5
end

-- ============================================================
-- Room mesh
-- ============================================================

local function BuildBaseMesh(boss)
    local mesh = {}
    local steps = math.floor(ROOM_RADIUS / MESH_STEP)
    for ix = -steps, steps do
        for iy = -steps, steps do
            local dx, dy = ix * MESH_STEP, iy * MESH_STEP
            if dx * dx + dy * dy <= ROOM_RADIUS * ROOM_RADIUS then
                local x, y = CENTER[1] + dx, CENTER[2] + dy
                table.insert(mesh, {
                    x = x,
                    y = y,
                    z = boss:GetMap():GetNearestFloor(x, y, 405),
                })
            end
        end
    end
    boss:Data():Set("BQBaseMesh", mesh)
end

local function UpdateMesh(boss, SwarmingShadows)
    if not boss:Data():Get("BQBaseMesh") then BuildBaseMesh(boss) end
    local parts = {}
    for _, d in ipairs(SwarmingShadows) do
        table.insert(parts, string.format("%.1f:%.1f", d:GetX(), d:GetY()))
    end
    table.sort(parts)
    local sig = table.concat(parts, "|")
    if sig == boss:Data():Get("BQMeshSignature") then return end
    boss:Data():Set("BQMeshSignature", sig)
    local mesh = boss:Data():Get("BQBaseMesh"):AsTable()
    local valid = {}
    for i, p in ipairs(mesh) do
        valid[i] = true
        for _, d in ipairs(SwarmingShadows) do
            local dx, dy = p.x - d:GetX(), p.y - d:GetY()
            if dx * dx + dy * dy < 25 then
                valid[i] = false
                break
            end
        end
    end
    boss:Data():Set("BQMeshValid", valid)
end

local function ClampToRoom(x, y)
    local dx, dy = x - CENTER[1], y - CENTER[2]
    local d = math.sqrt(dx * dx + dy * dy)
    if d <= ROOM_RADIUS then return x, y end
    return CENTER[1] + dx / d * ROOM_RADIUS, CENTER[2] + dy / d * ROOM_RADIUS
end

local function IsPosValid(x, y, SwarmingShadows)
    for _, d in ipairs(SwarmingShadows) do
        if d:GetExactDistance2d(x, y) < 5 then
            return false
        end
    end
    return true
end

local function GetSafePos(boss, x, y, maxSearchRadius, SwarmingShadows)
    x, y = ClampToRoom(x, y)
    local map = boss:GetMap()
    if IsPosValid(x, y, SwarmingShadows) then
        return {x, y, map:GetNearestFloor(x, y, 405)}
    end
    if not boss:Data():Get("BQBaseMesh") then BuildBaseMesh(boss) end
    local mesh = boss:Data():Get("BQBaseMesh"):AsTable()
    local valid = boss:Data():Get("BQMeshValid")
    if valid then valid = valid:AsTable() else valid = {} end
    local maxSq = maxSearchRadius and (maxSearchRadius * maxSearchRadius) or math.huge
    local best, bestSq = nil, math.huge
    for i, p in ipairs(mesh) do
        if valid[i] then
            local dx, dy = p.x - x, p.y - y
            local d2 = dx * dx + dy * dy
            if d2 <= maxSq and d2 < bestSq and IsPosValid(p.x, p.y, SwarmingShadows) then
                bestSq = d2
                best = p
            end
        end
    end
    if best then
        return {best.x, best.y, best.z}
    end
    return {x, y, map:GetNearestFloor(x, y, 405)}
end

-- Closest candidate to an ideal point (or, in spread mode, the candidate
-- farthest from everyone) that stays `separation` away from occupied units.
-- Falls back to the most separated candidate when the spacing cannot be met.
local function FindBestSpot(boss, cx, cy, minRadius, maxRadius, idealX, idealY, spread, occupied, SwarmingShadows, filter, separation)
    separation = separation or SEPARATION
    local best, bestScore = nil, nil
    local fallback, fallbackD = nil, -1
    local angleCount = math.floor(360 / ANGLE_STEP)
    for radius = minRadius, maxRadius do
        for ai = 0, angleCount - 1 do
            local angle = ai * ANGLE_STEP * math.pi / 180
            local x = cx + math.cos(angle) * radius
            local y = cy + math.sin(angle) * radius
            if IsPosValid(x, y, SwarmingShadows) and (not filter or filter(x, y)) then
                local minD = math.huge
                for _, p in ipairs(occupied) do
                    local d = math.sqrt((x - p.x) ^ 2 + (y - p.y) ^ 2)
                    if d < minD then minD = d end
                end
                if minD >= separation then
                    local score
                    if spread then
                        score = minD
                    else
                        score = math.sqrt((x - idealX) ^ 2 + (y - idealY) ^ 2)
                    end
                    if not best or (spread and score > bestScore + 1e-6)
                        or (not spread and score < bestScore - 1e-6) then
                        best, bestScore = {x, y}, score
                    end
                end
                if minD > fallbackD then
                    fallback, fallbackD = {x, y}, minD
                end
            end
        end
    end
    local spot = best or fallback
    if spot then
        spot[3] = boss:GetMap():GetNearestFloor(spot[1], spot[2], 405)
    end
    return spot
end

-- ============================================================
-- Role positions
-- ============================================================

local function IsBehindBoss(boss, x, y)
    local bo = boss:GetO()
    return (x - boss:GetX()) * math.cos(bo) + (y - boss:GetY()) * math.sin(bo) <= 0
end

-- Ranged must be inside 25 yd of center and within 40 yd of the nearest healer.
local function NearHealer(x, y, healerPos)
    local count = 0
    for _, hp in pairs(healerPos) do
        count = count + 1
        if math.sqrt((x - hp[1]) ^ 2 + (y - hp[2]) ^ 2) <= RANGED_LIMIT then
            return true
        end
    end
    return count == 0
end

local function NearBoss(boss, x, y)
    return boss:GetExactDistance2d(x, y) <= RANGED_LIMIT
end

local function IsSpotValid(boss, role, x, y, SwarmingShadows, healerPos)
    if not IsPosValid(x, y, SwarmingShadows) then return false end
    local d = math.sqrt((x - CENTER[1]) ^ 2 + (y - CENTER[2]) ^ 2)
    if role == "healer" then
        return d <= HEALER_MAX_RADIUS + 0.5
    elseif role == "melee" then
        return boss:GetExactDistance2d(x, y) <= 10.5 and IsBehindBoss(boss, x, y)
    elseif role == "ranged" then
        return NearHealer(x, y, healerPos or {})
            and NearBoss(boss, x, y)
    elseif role == "air" then
        return math.abs(d - AIR_RADIUS) <= 1
    end
    return true
end

-- Players carrying link, Swarming Shadows, Frenzied Bloodthirst or the
-- vampire essence are not avoided when spreading: a bot that has them nearby
-- stands still instead of running away.
local function IgnoresSpread(p)
    if p:HasAura(SPELL_PACT_OF_THE_DARKFALLEN)
        or p:HasAura(SPELL_SWARMING_SHADOWS)
        or p:HasAura(SPELL_SWARMING_SHADOWS_TRAIL)
        or p:HasAura(SPELL_ESSENCE_OF_BLOOD_QUEEN)
        or p:HasAura(SPELL_ESSENCE_OF_THE_BLOOD_QUEEN_PLR) then
        return true
    end
    for _, id in ipairs(FRENZIED_BLOODTHIRST_SPELLS) do
        if p:HasAura(id) then return true end
    end
    return false
end

-- Spots are sticky: a bot keeps its assigned spot until that spot becomes
-- invalid or is within 5 yd of a higher-priority unit. Assignment runs
-- healer -> melee -> ranged, so on a conflict ranged DPS move first, melee
-- DPS second and healers third. Real players and tanks are never moved.
local function ComputePositions(boss, bots, allPlayers, botHealers, botMelee, botRanged,
                                storedHealer, storedMelee, storedRanged, storedAir, SwarmingShadows, airPhase)
    local function Copy(tbl)
        local out = {}
        if tbl then
            for k, v in pairs(tbl) do out[k] = v end
        end
        return out
    end

    local healerPos = Copy(storedHealer)
    local meleePos = Copy(storedMelee)
    local rangedPos = Copy(storedRanged)
    local airPos = Copy(storedAir)

    -- Placement order: healers first (perimeter of the 15-yd ring), melee
    -- second (fanned out behind the boss), ranged last (15-30 yd of center).
    -- Higher rank is placed first; lower-ranked roles fit around them.
    local RANK = { healer = 3, melee = 2, air = 2, ranged = 1 }

    local roleByKey = {}
    for _, h in ipairs(botHealers) do roleByKey[tostring(h:GetGUID())] = "healer" end
    if airPhase then
        for _, bot in ipairs(bots) do
            if not bot:HasHealSpec() then roleByKey[tostring(bot:GetGUID())] = "air" end
        end
    else
        for _, m in ipairs(botMelee) do roleByKey[tostring(m:GetGUID())] = "melee" end
        for _, r in ipairs(botRanged) do roleByKey[tostring(r:GetGUID())] = "ranged" end
    end

    local function Prune(tbl, role)
        for key in pairs(tbl) do
            if roleByKey[key] ~= role then tbl[key] = nil end
        end
    end
    Prune(healerPos, "healer")
    Prune(meleePos, "melee")
    Prune(rangedPos, "ranged")
    Prune(airPos, "air")

    local function GetStored(role, key)
        if role == "healer" then return healerPos[key] end
        if role == "melee" then return meleePos[key] end
        if role == "ranged" then return rangedPos[key] end
        if role == "air" then return airPos[key] end
    end

    local function SetStored(role, key, spot)
        if role == "healer" then healerPos[key] = spot end
        if role == "melee" then meleePos[key] = spot end
        if role == "ranged" then rangedPos[key] = spot end
        if role == "air" then airPos[key] = spot end
    end

    -- Units at or above `minRank` are treated as placed and are avoided;
    -- lower-ranked roles are placed later, so their old/actual positions are
    -- deliberately ignored. Real players and tanks are always avoided and
    -- never moved.
    local function Occupied(selfKey, minRank)
        local occupied = {}
        for _, p in ipairs(allPlayers) do
            local key = tostring(p:GetGUID())
            if p:IsAlive() and key ~= selfKey and not IgnoresSpread(p) then
                local role = roleByKey[key]
                if role and RANK[role] < minRank then
                    -- Lower priority: it will move out of the way later.
                else
                    local pos = role and GetStored(role, key)
                    if pos and IsSpotValid(boss, role, pos[1], pos[2], SwarmingShadows, healerPos) then
                        table.insert(occupied, {x = pos[1], y = pos[2]})
                    else
                        table.insert(occupied, {x = p:GetX(), y = p:GetY()})
                    end
                end
            end
        end
        return occupied
    end

    local function Conflicts(x, y, occupied, separation)
        for _, o in ipairs(occupied) do
            if math.sqrt((x - o.x) ^ 2 + (y - o.y) ^ 2) < separation then
                return true
            end
        end
        return false
    end

    local function Assign(role, list, find)
        local rank = RANK[role]
        local separation = SEPARATION
        for _, bot in ipairs(list) do
            local key = tostring(bot:GetGUID())
            local spot = GetStored(role, key)
            local forced = bot:Data():Get("BQRespot")
            local occupied = Occupied(key, rank)
            local keep = spot
                and IsSpotValid(boss, role, spot[1], spot[2], SwarmingShadows, healerPos)
                and not Conflicts(spot[1], spot[2], occupied, separation)
            if forced or not keep then
                spot = find(bot, occupied)
                if spot then SetStored(role, key, spot) end
            end
        end
    end

    -- Healers first: spread around the perimeter of the 15-yd ring.
    Assign("healer", botHealers, function(bot, occupied)
        local ang = math.atan2(bot:GetY() - CENTER[2], bot:GetX() - CENTER[1])
        local tx = CENTER[1] + math.cos(ang) * HEALER_MAX_RADIUS
        local ty = CENTER[2] + math.sin(ang) * HEALER_MAX_RADIUS
        return FindBestSpot(boss, CENTER[1], CENTER[2], 0, HEALER_MAX_RADIUS,
                            tx, ty, false, occupied, SwarmingShadows)
    end)

    if airPhase then
        local air = {}
        for _, bot in ipairs(bots) do
            if roleByKey[tostring(bot:GetGUID())] == "air" then table.insert(air, bot) end
        end
        Assign("air", air, function(bot, occupied)
            local bx, by = bot:GetX(), bot:GetY()
            local ang = math.atan2(by - CENTER[2], bx - CENTER[1])
            local tx = CENTER[1] + math.cos(ang) * AIR_RADIUS
            local ty = CENTER[2] + math.sin(ang) * AIR_RADIUS
            return FindBestSpot(boss, CENTER[1], CENTER[2], AIR_RADIUS, AIR_RADIUS,
                                tx, ty, false, occupied, SwarmingShadows)
        end)
    else
        -- Melee second: fan out on the ring 10 yd behind the boss.
        Assign("melee", botMelee, function(bot, occupied)
            local bx, by = boss:GetX(), boss:GetY()
            local ang = math.atan2(bot:GetY() - by, bot:GetX() - bx)
            local tx = bx + math.cos(ang) * 10
            local ty = by + math.sin(ang) * 10
            return FindBestSpot(boss, bx, by, 1, 10,
                                tx, ty, false, occupied, SwarmingShadows,
                                function(x, y) return IsBehindBoss(boss, x, y) end)
        end)
        -- Ranged last: closest spot to center inside the 15-30 yd band that
        -- is within 40 yd of the boss and of a healer.
        Assign("ranged", botRanged, function(_, occupied)
            local limits = function(x, y)
                return NearBoss(boss, x, y) and NearHealer(x, y, healerPos)
            end
            local spot = FindBestSpot(boss, CENTER[1], CENTER[2], RANGED_MIN, RANGED_MAX,
                                      CENTER[1], CENTER[2], false, occupied, SwarmingShadows, limits)
            if spot then return spot end
            return FindBestSpot(boss, CENTER[1], CENTER[2], 0, RANGED_MAX,
                                CENTER[1], CENTER[2], false, occupied, SwarmingShadows, limits)
        end)
    end

    return healerPos, meleePos, rangedPos, airPos
end

local function HasSpotFor(tbl, list)
    for _, p in ipairs(list) do
        if not tbl[tostring(p:GetGUID())] then return false end
    end
    return true
end

local function SpotsBlocked(SwarmingShadows, ...)
    for _, tbl in ipairs({...}) do
        for _, pos in pairs(tbl) do
            if not IsPosValid(pos[1], pos[2], SwarmingShadows) then return true end
        end
    end
    return false
end

-- ============================================================
-- Swarming Shadows trail
-- ============================================================

local SWARM_STEP_YARDS           = 5      -- arc length between waypoints
local SWARM_LENGTH_YARDS         = 40     -- total run along the edge
local SWARM_SAFE                 = 5      -- trail closer than this blocks a point
local SWARM_DETOUR               = 5      -- inward step used to clear a blocked point
local SWARM_MIN_RADIUS           = ROOM_RADIUS - 2 * SWARM_DETOUR

-- A point on the 37-yard edge at the given angle. If the trail is in the way,
-- pull the point inward one 5-yard step at a time, but only as far as needed.
local function SwarmEdgePoint(angle, SwarmingShadows, bot)
    local radius = ROOM_RADIUS
    local x, y = 0, 0
    while radius >= SWARM_MIN_RADIUS do
        x = CENTER[1] + math.cos(angle) * radius
        y = CENTER[2] + math.sin(angle) * radius
        local blocked = false
        for _, t in ipairs(SwarmingShadows) do
            if t:GetExactDistance2d(x, y) < SWARM_SAFE then
                blocked = true
                break
            end
        end
        if not blocked then break end
        radius = radius - SWARM_DETOUR
    end
    return x, y, bot:GetMap():GetNearestFloor(x, y, 405)
end

-- Worst trail clearance along one direction of the 40-yard edge run.
local function SwarmClearance(angle, dir, SwarmingShadows)
    local step = SWARM_STEP_YARDS / ROOM_RADIUS
    local minD = math.huge
    for i = 1, math.floor(SWARM_LENGTH_YARDS / SWARM_STEP_YARDS) do
        local a = angle + dir * step * i
        local x = CENTER[1] + math.cos(a) * ROOM_RADIUS
        local y = CENTER[2] + math.sin(a) * ROOM_RADIUS
        for _, t in ipairs(SwarmingShadows) do
            local dd = t:GetExactDistance2d(x, y)
            if dd < minD then minD = dd end
        end
    end
    return minD
end

-- Trail the 37-yard edge for 40 yards. The direction is picked once at the
-- start, as the side of the edge with the most clearance from existing
-- shadows, so the run does not steer into the other swarmers' trail.
local function GetSwarmWaypoint(bot, SwarmingShadows)
    local dx = bot:GetX() - CENTER[1]
    local dy = bot:GetY() - CENTER[2]
    if dx == 0 and dy == 0 then dx = 1 end
    local angle = math.atan2(dy, dx)

    local start = bot:Data():Get("BQSwarmStart")
    local dir = bot:Data():Get("BQSwarmDir")
    if not start or not dir then
        start = angle
        dir = (SwarmClearance(angle, -1, SwarmingShadows) >= SwarmClearance(angle, 1, SwarmingShadows)) and -1 or 1
        bot:Data():Set("BQSwarmStart", start)
        bot:Data():Set("BQSwarmDir", dir)
    end

    -- Distance covered along the edge since the aura was applied.
    local delta = angle - start
    while delta > math.pi do delta = delta - 2 * math.pi end
    while delta < -math.pi do delta = delta + 2 * math.pi end
    if math.abs(delta) * ROOM_RADIUS >= SWARM_LENGTH_YARDS then
        return nil
    end

    -- Aim one step ahead of the bot's current angle so it keeps hugging the ring.
    local step = SWARM_STEP_YARDS / ROOM_RADIUS
    return SwarmEdgePoint(angle + dir * step, SwarmingShadows, bot)
end

-- ============================================================
-- Bite
-- ============================================================

local function HasFrenziedBloodthirst(unit)
    for _, id in ipairs(FRENZIED_BLOODTHIRST_SPELLS) do
        if unit:HasAura(id) then return true end
    end
    return false
end

local function RemoveFrenziedBloodthirst(unit)
    for _, id in ipairs(FRENZIED_BLOODTHIRST_SPELLS) do
        unit:RemoveAura(id)
    end
end

local function GetVampiricBiteSpell(bot)
    local difficulty = bot:GetMap():GetDifficulty()
    if difficulty == 3 then return SPELL_VAMPIRIC_BITE_25H end
    if difficulty == 2 then return SPELL_VAMPIRIC_BITE_10H end
    if difficulty == 1 then return SPELL_VAMPIRIC_BITE_25N end
    if difficulty == 0 then return SPELL_VAMPIRIC_BITE_10N end
end

-- Only after a successful bite cast: consume every Frenzied Bloodthirst aura.
local function OnVampiricBiteCast(event, caster, spell)
    if caster:IsBot() then
        RemoveFrenziedBloodthirst(caster)
    end
end

RegisterSpellEvent(SPELL_VAMPIRIC_BITE_10N, 2, OnVampiricBiteCast)
RegisterSpellEvent(SPELL_VAMPIRIC_BITE_25N, 2, OnVampiricBiteCast)
RegisterSpellEvent(SPELL_VAMPIRIC_BITE_10H, 2, OnVampiricBiteCast)
RegisterSpellEvent(SPELL_VAMPIRIC_BITE_25H, 2, OnVampiricBiteCast)

local function IsBiteable(p, bot)
    return not (p == bot) and p:IsAlive()
        and not p:HasAura(SPELL_ESSENCE_OF_BLOOD_QUEEN)
        and not p:HasAura(SPELL_ESSENCE_OF_THE_BLOOD_QUEEN_PLR)
        and not HasFrenziedBloodthirst(p)
end

local function GetBiteTarget(bot, allPlayers)
    local melee, meleeHp = nil, -1
    local near, nearDist = nil, math.huge
    local tank, tankDist = nil, math.huge
    for _, p in ipairs(allPlayers) do
        if IsBiteable(p, bot) then
            local d = bot:GetExactDistance2d(p)
            if IsTank(p) or p:HasHealSpec() then
                if d < tankDist then
                    tankDist = d
                    tank = p
                end
            else
                if d <= 5 then
                    local hp = p:GetHealth()
                    if hp > meleeHp then
                        meleeHp = hp
                        melee = p
                    end
                end
                if d < nearDist then
                    nearDist = d
                    near = p
                end
            end
        end
    end
    return melee or near or tank
end

-- ============================================================
-- Pact of the Darkfallen
-- ============================================================

local function GetPactMidpoint(boss, allPlayers)
    local linked, sx, sy = 0, 0, 0
    for _, p in ipairs(allPlayers) do
        if p:IsAlive() and p:HasAura(SPELL_PACT_OF_THE_DARKFALLEN) then
            linked = linked + 1
            sx = sx + p:GetX()
            sy = sy + p:GetY()
        end
    end
    if linked == 0 then return nil end
    return {sx / linked, sy / linked,
            boss:GetMap():GetNearestFloor(sx / linked, sy / linked, 405)}
end

-- ============================================================
-- Tanks
-- ============================================================

local function GetSafeTankGround(boss, SwarmingShadows)
    local pushFrom, pushDist = nil, math.huge
    for _, d in ipairs(SwarmingShadows) do
        local tankDist = d:GetExactDistance2d(TANK_GROUND[1], TANK_GROUND[2])
        if tankDist < 5 and tankDist < pushDist then
            pushDist = tankDist
            pushFrom = d
        end
        if boss:GetExactDistance2d(d) < 10 then
            pushFrom = d
            break
        end
    end
    if not pushFrom then
        return GetSafePos(boss, TANK_GROUND[1], TANK_GROUND[2], 15, SwarmingShadows)
    end
    local dx = TANK_GROUND[1] - pushFrom:GetX()
    local dy = TANK_GROUND[2] - pushFrom:GetY()
    local d = math.sqrt(dx * dx + dy * dy)
    if d < 0.01 then dx, dy, d = 1, 0, 1 end
    local x = pushFrom:GetX() + dx / d * 12
    local y = pushFrom:GetY() + dy / d * 12
    local ox, oy = x - TANK_GROUND[1], y - TANK_GROUND[2]
    local od = math.sqrt(ox * ox + oy * oy)
    if od > 10 then
        x = TANK_GROUND[1] + ox / od * 10
        y = TANK_GROUND[2] + oy / od * 10
    end
    return GetSafePos(boss, x, y, 15, SwarmingShadows)
end

local function GetDesiredTankPosition(boss, botTanks, mainTank, offTank, inPull, SwarmingShadows)
    local desired = {}
    local function Move(tank, x, y)
        if math.sqrt((tank:GetX() - x) ^ 2 + (tank:GetY() - y) ^ 2) > 3 then
            desired[tostring(tank:GetGUID())] = {x, y, boss:GetMap():GetNearestFloor(x, y, 405)}
        end
    end

    local function RightOf(x, y, o)
        local rx = x + math.sin(o) * 1.5
        local ry = y - math.cos(o) * 1.5
        local dx, dy = rx - CENTER[1], ry - CENTER[2]
        if dx * dx + dy * dy <= ROOM_RADIUS * ROOM_RADIUS then
            return rx, ry
        end
        return x, y
    end

    if inPull then
        if mainTank and mainTank:IsBot() then Taunt(mainTank, boss, true) end
        if boss:GetExactDistance2d(CENTER[1], CENTER[2]) > 7 then
            for _, tank in ipairs(botTanks) do Move(tank, CENTER[1], CENTER[2]) end
        else
            local ground = GetSafeTankGround(boss, SwarmingShadows)
            for _, tank in ipairs(botTanks) do Move(tank, ground[1], ground[2]) end
        end
        return desired
    end

    if mainTank and mainTank:IsBot() then
        local ground = GetSafeTankGround(boss, SwarmingShadows)
        local ox, oy = RightOf(ground[1], ground[2], mainTank:GetO())
        for _, tank in ipairs(botTanks) do
            if offTank and tank:GetGUID() == offTank:GetGUID() and tank:GetGUID() ~= mainTank:GetGUID() then
                desired[tostring(tank:GetGUID())] =
                    {ox, oy, boss:GetMap():GetNearestFloor(ox, oy, 405)}
            else
                Move(tank, ground[1], ground[2])
            end
        end
    elseif mainTank and offTank and offTank:IsBot() then
        local rx, ry = RightOf(mainTank:GetX(), mainTank:GetY(), mainTank:GetO())
        if rx == mainTank:GetX() and ry == mainTank:GetY() then
            desired[tostring(offTank:GetGUID())] =
                {mainTank:GetX(), mainTank:GetY(), mainTank:GetZ()}
        else
            desired[tostring(offTank:GetGUID())] =
                {rx, ry, boss:GetMap():GetNearestFloor(rx, ry, 405)}
        end
    end
    return desired
end

-- ============================================================
-- Movement
-- ============================================================

local function MoveBot(boss, bot, pos, tolerance, SwarmingShadows, silence)
    local x, y = ClampToRoom(pos[1], pos[2])
    local safe = GetSafePos(boss, x, y, 15, SwarmingShadows)
    if not safe then return end
    local atPos = IsAtPos(bot, safe[1], safe[2], tolerance)
    if atPos then
        bot:Data():Set("BQMoveTarget", nil)
        return
    end

    local forceFlag = silence and 1 or 0
    local last = bot:Data():Get("BQMoveTarget")
    if last then
        last = last:AsTable()
        local threshold = silence and 2.5 or 1.0
        if last[4] == forceFlag
            and math.abs(last[1] - safe[1]) <= threshold
            and math.abs(last[2] - safe[2]) <= threshold
            and bot:IsMoving() then
            return
        end
    end

    if silence then
        MoveImmediately(bot, safe[1], safe[2], safe[3])
    else
        bot:MoveTo(1, safe[1], safe[2], safe[3], true)
    end
    bot:Data():Set("BQMoveTarget", {safe[1], safe[2], safe[3], forceFlag})
end

-- Direct move for mechanics that must silence the bot and take over movement
-- (swarming shadows trail). Only re-issued when the waypoint actually changes.
local function MoveSwarmer(bot, x, y, z, tolerance)
    local last = bot:Data():Get("BQSwarmTarget")
    if last then
        last = last:AsTable()
        if math.abs(last[1] - x) <= tolerance
            and math.abs(last[2] - y) <= tolerance
            and bot:IsMoving() then
            return
        end
    end
    if bot:IsMoving() then
        bot:MoveTo(1, x, y, z, true)
    else
        MoveImmediately(bot, x, y, z)
    end
    bot:Data():Set("BQSwarmTarget", {x, y, z})
end

-- ============================================================
-- Aura reactions
-- ============================================================

local function HasSwarmingShadows(unit)
    return unit:HasAura(SPELL_SWARMING_SHADOWS)
        or unit:HasAura(SPELL_SWARMING_SHADOWS_TRAIL)
end

local function OnSwarmingShadowsApply(event, unit, aura)
    if not unit:IsBot() then return end
    ApplyDamageReductionStacks(unit, 60, 15000)
    unit:SetSpeed(1, 1.0)
    -- Only start a fresh run on the first aura; the second aura must not
    -- restart or reverse a run that is already in progress.
    if not unit:Data():Get("BQSwarmStart") then
        unit:Data():Set("BQSwarmDir", nil)
        unit:Data():Set("BQSwarmReturn", nil)
    end
end
RegisterAuraEvent(SPELL_SWARMING_SHADOWS, 1, OnSwarmingShadowsApply)
RegisterAuraEvent(SPELL_SWARMING_SHADOWS_TRAIL, 1, OnSwarmingShadowsApply)

local function OnSwarmingShadowsRemove(event, unit, aura, mode)
    if not unit:IsBot() then return end
    -- Only stop once both the warning and the trail aura are gone.
    if HasSwarmingShadows(unit) then return end
    -- Abort the remaining edge path; the bot returns to a fresh safe spot
    -- chosen by the normal role logic from where the aura dropped.
    unit:Data():Set("BQSwarmStart", nil)
    unit:Data():Set("BQSwarmDir", nil)
    unit:Data():Set("BQSwarmTarget", nil)
    unit:Data():Set("BQSwarmReturn", true)
    unit:Data():Set("BQRespot", true)
end
RegisterAuraEvent(SPELL_SWARMING_SHADOWS, 2, OnSwarmingShadowsRemove)
RegisterAuraEvent(SPELL_SWARMING_SHADOWS_TRAIL, 2, OnSwarmingShadowsRemove)

local function OnInciteTerrorApply(event, unit, aura)
    if not unit:IsBot() then return end
    if unit:GetRace() == RACE_HUMAN then
        unit:CastSpell(unit, SPELL_EVERY_MAN_FOR_HIMSELF, true)
    end
end

RegisterAuraEvent(SPELL_INCITE_TERROR, 1, OnInciteTerrorApply)

local function OnPactOfTheDarkfallenApply(event, unit, aura)
    if not unit:IsBot() then return end
    ApplyDamageReductionStacks(unit, 60, 15000)
end
RegisterAuraEvent(SPELL_PACT_OF_THE_DARKFALLEN, 1, OnPactOfTheDarkfallenApply)

local function PrepareAirPhase(boss)
    local map = boss:GetMap()
    local bots = {}
    for _, p in ipairs(map and map:GetPlayers() or {}) do
        if p:IsBot() and p:IsAlive() and p:IsInCombat() and InRoom(p) then
            table.insert(bots, p)
        end
    end

    local swarmTarget = nil
    for _, bot in ipairs(bots) do
        if HasSwarmingShadows(bot) then
            swarmTarget = bot
            break
        end
    end

    if swarmTarget then
        for _, bot in ipairs(bots) do
            if bot:GetClass() == CLASS_PRIEST
                and not bot:HasSpellCooldown(SPELL_FEAR_WARD) then
                bot:CastSpell(swarmTarget, SPELL_FEAR_WARD, false)
                break
            end
        end
    end

    local priests = {}
    for _, bot in ipairs(bots) do
        if bot:GetClass() == CLASS_PRIEST then
            table.insert(priests, bot)
        end
    end
    if #priests > 0 then
        local caster = priests[math.random(#priests)]
        caster:CastSpellAoF(CENTER[1], CENTER[2], CENTER[3], SPELL_MASS_DISPEL, true)
    end

    for _, bot in ipairs(bots) do
        if bot:GetClass() == CLASS_SHAMAN then
            bot:CastSpell(bot, SPELL_TREMOR_TOTEM, true)
        end
    end
end

-- ============================================================
-- Main loop
-- ============================================================

local function CleanupBQ(boss)
    local map = boss:GetMap()
    for _, p in ipairs(map and map:GetPlayers() or {}) do
        local shadow = p:ToShadow()
        if shadow then
            shadow:ClearMovementSuppression()
            shadow:ToggleCombatStrategy("+icc")
            p:Data():Set("BQHealerPos", nil)
            p:Data():Set("BQMeleePos", nil)
            p:Data():Set("BQRangedPos", nil)
            p:Data():Set("BQAirPos", nil)
            p:Data():Set("BQMoveTarget", nil)
            p:Data():Set("BQSwarmTarget", nil)
            p:Data():Set("BQSwarmReturn", nil)
            p:Data():Set("BQSwarmStart", nil)
            p:Data():Set("BQSwarmDir", nil)
        end
    end
    boss:Data():Set("BQCombatStart", nil)
    boss:Data():Set("BQCombatTime", nil)
    boss:Data():Set("BQAirPrep", nil)
    boss:Data():Set("BQBaseMesh", nil)
    boss:Data():Set("BQHealerSpots", nil)
    boss:Data():Set("BQMeleeSpots", nil)
    boss:Data():Set("BQRangedSpots", nil)
    boss:Data():Set("BQAirSpots", nil)
    boss:Data():Set("BQPositionTime", nil)
    boss:Data():Set("BQPositionAir", nil)
end

-- Keeps a baseline damage reduction on every bot. Higher values applied by
-- other mechanics (Swarming Shadows, Pact of the Darkfallen, etc.) are never
-- overwritten with the lower baseline.
local function ApplyBaselineDamageReduction(bot)
    local difficulty = bot:GetDifficulty()
    local stacks
    if difficulty == 0 or difficulty == 2 then
        stacks = 25
    elseif difficulty == 3 then
        stacks = 15
    else
        return
    end
    local aura = bot:GetAura(699100)
    if not aura or aura:GetStackAmount() < stacks then
        ApplyDamageReductionStacks(bot, stacks, 15000)
    end
end

local function BQLoop(eventId, delay, repeats, boss)
    if boss:IsDead() or not boss:IsInCombat() then
        CleanupBQ(boss)
        StopLuaEvent(boss)
        return
    end

    local combatTime = (boss:Data():Get("BQCombatTime") or 0) + 200
    boss:Data():Set("BQCombatTime", combatTime)

    local SwarmingShadows = boss:GetCreaturesInRange(100, SWARMING_SHADOWS_NPC)
    UpdateMesh(boss, SwarmingShadows)

    local nearby = boss:GetPlayersInRange(100)
    local allPlayers = {}
    for _, p in ipairs(nearby) do
        if InRoom(p) then table.insert(allPlayers, p) end
    end
    local bots = {}
    for _, p in ipairs(allPlayers) do
        if p:IsAlive() and p:IsInCombat() and p:IsBot() then
            table.insert(bots, p:ToShadow())
        end
    end
    if #bots == 0 then
        return
    end

    local now = os.time()
    local combatStart = boss:Data():Get("BQCombatStart") or now
    boss:Data():Set("BQCombatStart", combatStart)
    local inPull = (now - combatStart) < PULL_DURATION
    local airPhase = boss:HasAura(SPELL_INCITE_TERROR)

    if not airPhase and combatTime >= AIR_PHASE_INTERVAL - 2000 then
        if not boss:Data():Get("BQAirPrep") then
            boss:Data():Set("BQAirPrep", true)
            PrepareAirPhase(boss)
        end
    elseif airPhase or combatTime < AIR_PHASE_INTERVAL - 2000 then
        boss:Data():Set("BQAirPrep", nil)
    end

    local mainTank, offTank = IdentifyTanks(boss)

    local botTanks, botHealers, botMelee, botRanged = {}, {}, {}, {}
    for _, bot in ipairs(bots) do
        if IsTank(bot) then
            table.insert(botTanks, bot)
        elseif bot:HasHealSpec() then
            table.insert(botHealers, bot)
        elseif bot:HasMeleeSpec() then
            table.insert(botMelee, bot)
        else
            table.insert(botRanged, bot)
        end
    end
    local function SortByName(a, b) return a:GetName() < b:GetName() end
    table.sort(botTanks, SortByName)
    table.sort(botHealers, SortByName)
    table.sort(botMelee, SortByName)
    table.sort(botRanged, SortByName)

    for _, bot in ipairs(bots) do
        ApplyBaselineDamageReduction(bot)
    end

    if inPull and not boss:Data():Get("BQPullThreatApplied") then
        if mainTank then boss:AddThreat(mainTank, 10000) end
        if offTank and offTank:IsBot() then boss:AddThreat(offTank, 8000) end
        boss:Data():Set("BQPullThreatApplied", true)
    end

    local healerPos = boss:Data():Get("BQHealerSpots")
    local meleePos = boss:Data():Get("BQMeleeSpots")
    local rangedPos = boss:Data():Get("BQRangedSpots")
    local airPos = boss:Data():Get("BQAirSpots")
    healerPos = healerPos and healerPos:AsTable() or {}
    meleePos = meleePos and meleePos:AsTable() or {}
    rangedPos = rangedPos and rangedPos:AsTable() or {}
    airPos = airPos and airPos:AsTable() or {}

    -- Recalculate at most every 5 seconds, or immediately when a Swarming
    -- Shadows trail invalidates one of the assigned spots.
    local lastCalc = boss:Data():Get("BQPositionTime") or -POSITION_REFRESH_MS
    local respot = false
    for _, bot in ipairs(bots) do
        if bot:Data():Get("BQRespot") then respot = true break end
    end
    local needCalc = not HasSpotFor(healerPos, botHealers)
        or boss:Data():Get("BQPositionAir") ~= airPhase
        or respot
        or combatTime - lastCalc >= POSITION_REFRESH_MS
        or SpotsBlocked(SwarmingShadows, healerPos)
    if not needCalc then
        if airPhase then
            needCalc = SpotsBlocked(SwarmingShadows, airPos)
            if not needCalc then
                for _, bot in ipairs(bots) do
                    if not bot:HasHealSpec() and not airPos[tostring(bot:GetGUID())] then
                        needCalc = true
                        break
                    end
                end
            end
        else
            needCalc = not HasSpotFor(meleePos, botMelee)
                or not HasSpotFor(rangedPos, botRanged)
                or SpotsBlocked(SwarmingShadows, meleePos, rangedPos)
        end
    end
    if needCalc then
        healerPos, meleePos, rangedPos, airPos = ComputePositions(
            boss, bots, allPlayers, botHealers, botMelee, botRanged,
            healerPos, meleePos, rangedPos, airPos, SwarmingShadows, airPhase)
        for _, bot in ipairs(bots) do bot:Data():Set("BQRespot", nil) end
        boss:Data():Set("BQHealerSpots", healerPos)
        boss:Data():Set("BQMeleeSpots", meleePos)
        boss:Data():Set("BQRangedSpots", rangedPos)
        boss:Data():Set("BQAirSpots", airPos)
        boss:Data():Set("BQPositionTime", combatTime)
        boss:Data():Set("BQPositionAir", airPhase)
    end

    local tankDesired = airPhase and {}
        or GetDesiredTankPosition(boss, botTanks, mainTank, offTank, inPull, SwarmingShadows)

    -- When the shadow main tank is on the tank spot, pull the boss onto the
    -- center spot.
    if not inPull and not airPhase and mainTank and mainTank:IsBot()
        and mainTank:GetExactDistance2d(TANK_GROUND[1], TANK_GROUND[2]) <= 3
        and boss:GetExactDistance2d(CENTER[1], CENTER[2]) > 1.5 then
        boss:MoveTo(99, CENTER[1], CENTER[2], CENTER[3], true)
    end

    local pactMid = GetPactMidpoint(boss, allPlayers)

    for _, bot in ipairs(bots) do
        local guidKey = tostring(bot:GetGUID())

        if not bot:IsMovementSuppressed() then
            bot:SuppressMovement(SUPPRESS_MS)
        end

        local isSwarmer = HasSwarmingShadows(bot)
        local isPact = bot:HasAura(SPELL_PACT_OF_THE_DARKFALLEN)
        local isBloodthirst = HasFrenziedBloodthirst(bot)
        local desired = nil
        local silence = false

        if isSwarmer then
            DisableSpellCast(bot, 0.2)
            local x, y, z = GetSwarmWaypoint(bot, SwarmingShadows)
            if x then MoveSwarmer(bot, x, y, z, 1.0) end
        end

        if not isSwarmer and isPact and pactMid
            and bot:GetExactDistance2d(pactMid[1], pactMid[2]) > 2 then
            desired = pactMid
            silence = true
        end

        if not isSwarmer and not isPact and isBloodthirst then
            local target = GetBiteTarget(bot, allPlayers)
            if target then
                if bot:GetExactDistance2d(target) <= 5 then
                    bot:SetFacingToObject(target)
                    bot:CastSpell(target, GetVampiricBiteSpell(bot), true)
                else
                    local tx, ty = target:GetX(), target:GetY()
                    local dx, dy = bot:GetX() - tx, bot:GetY() - ty
                    local d = math.sqrt(dx * dx + dy * dy)
                    if d < 0.01 then dx, dy, d = 1, 0, 1 end
                    desired = {tx + dx / d * 3, ty + dy / d * 3}
                    silence = true
                end
            end
        end

        if not isSwarmer and not isPact and not isBloodthirst then
            if airPhase then
                if bot:HasHealSpec() then
                    desired = healerPos[guidKey]
                else
                    desired = airPos[guidKey]
                end
            elseif IsTank(bot) then
                desired = tankDesired[guidKey]
            elseif bot:HasHealSpec() then
                desired = healerPos[guidKey]
            elseif bot:HasMeleeSpec() then
                desired = meleePos[guidKey]
            else
                desired = rangedPos[guidKey]
            end
        end

        -- After the swarm ends the bot keeps following its freshly assigned
        -- sticky spot; just drop the return marker.
        if bot:Data():Get("BQSwarmReturn") then
            bot:Data():Set("BQSwarmReturn", nil)
        end

        if desired then
            if silence then DisableSpellCast(bot, 0.2) end
            MoveBot(boss, bot, desired, 1.0, SwarmingShadows, silence)
        end
    end
end

-- ============================================================
-- Events
-- ============================================================

local function BQOnEnterCombat(event, boss, target)
    if not boss or not (boss:GetEntry() == BLOOD_QUEEN_ENTRY) then return end

    for _, player in ipairs(boss:GetPlayersInRange(100)) do
        local shadow = player:ToShadow()
        if shadow then
            shadow:SuppressMovement(SUPPRESS_MS)
            shadow:ToggleCombatStrategy("-icc")
        end

        if player:GetDifficulty() > 1 then
            ApplyHiddenBuffsToShadows(player)
        end
    end

    if boss:Data():Get("EventActive") then
        print("BQ enter: loop already running")
        return
    end

    BuildBaseMesh(boss)
    local map = boss:GetMap()
    for _, p in ipairs(map and map:GetPlayers() or {}) do
        if p:IsBot() then
            p:Data():Set("BQHealerPos", nil)
        end
    end

    boss:Data():Set("BQCombatTime", 0)
    boss:Data():Set("BQCombatStart", os.time())
    boss:Data():Set("BQPullThreatApplied", nil)
    boss:Data():Set("BQAirPrep", nil)
    boss:Data():Set("BQMeshSignature", nil)
    boss:Data():Set("BQHealerSpots", nil)
    boss:Data():Set("BQMeleeSpots", nil)
    boss:Data():Set("BQRangedSpots", nil)
    boss:Data():Set("BQAirSpots", nil)
    boss:Data():Set("BQPositionTime", nil)
    boss:Data():Set("BQPositionAir", nil)
    StartLuaEvent(boss, BQLoop, 200, 0)
end
RegisterCreatureEvent(BLOOD_QUEEN_ENTRY, 1, BQOnEnterCombat)

local function BQOnBossLoopEnd(event, boss)
    CleanupBQ(boss)
    StopLuaEvent(boss)
end
RegisterCreatureEvent(BLOOD_QUEEN_ENTRY, 2, BQOnBossLoopEnd) -- leave combat (evade)
RegisterCreatureEvent(BLOOD_QUEEN_ENTRY, 5, BQOnBossLoopEnd) -- leave combat (evade)

local function BQOnLeaveCombat(event, player)
    if not (player:GetMapId() == 631) then return end
    local shadow = player:ToShadow()
    if shadow then
        shadow:ClearMovementSuppression()
        shadow:ToggleCombatStrategy("+icc")
    end
end
RegisterPlayerEvent(34, BQOnLeaveCombat)
