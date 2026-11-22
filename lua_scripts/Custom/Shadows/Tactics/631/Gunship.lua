if GetStateMapId() ~= 631 then return end

-- OBJECT IDs
-- Bosses
local MURADIN_ENTRY            = 36948
local SAURFANG_ENTRY           = 36939
-- Mages
local ALLY_FIGHT_MAGE_ENTRY    = 37117
local HORDE_FIGHT_MAGE_ENTRY   = 37116
-- Transport game objects
local ORGRIM_ENTRY             = 37215
local SKYBREAKER_ENTRY         = 37540
-- Spells
local ROCKET_PACK_SPELL        = 68645
local ORGRIMS_HAMMER_DECK_AURA = 70121
-- Cannons
local CANNON_ALLY_ENTRY        = 36838
local CANNON_HORDE_ENTRY       = 36839
local CANNON_BLAST_ALLY        = 69399
local CANNON_BLAST_HORDE       = 70172
local INCINERATING_BLAST_ALLY  = 70174
local INCINERATING_BLAST_HORDE = 69401
local CANNON_BLAST_COOLDOWN    = 1000
local RIDE_VEHICLE_SPELL       = 70510
-- Rocket Artillery
local ROCKET_ARTILLERY         = 69679
local ROCKET_ARTILLERY_SPEED   = 16.5
local ROCKET_RADIUS            = 4
local ROCKET_ESCAPE            = 6
local GUNSHIP_SAFE_Z           = 538
-- Trash, misc.
local KORKRON_ENTRIES          = { 36957, 36960 }
local SKYBREAKERS_ENTRIES      = { 36950, 36961 }
local RANGED_TARGET_ENTRIES    = { 36969, 36968 } -- Skybreaker Rifleman, Kor'kron Axethrower
local CANNON_TARGET_ENTRIES    = {
    36982, -- Kor'kron Rocketeer
    36978, -- Skybreaker Mortar Soldier
    36969, -- Skybreaker Rifleman
    36968, -- Kor'kron Axethrower
    SAURFANG_ENTRY,
    MURADIN_ENTRY,
}
local ZAFOD                    = 37184

-- TRANSPORTS
local ORGRIMS_HAMMER = 201812
local SKYBREAKER    = 201811

-- Ally pos
local ALLY_SKYBREAKER_START_POS   = { x = -391, y = 2058, z = 466.6 }
local ALLY_ORGRIM_TANK_JUMP        = { x = -368, y = 2022, z = 467.6 }
local ALLY_HEALER_POS             = { x = -387, y = 2047, z = 467.54 }
local ALLY_ORGRIM_Y_LIMIT          = 2023
local ALLY_SKYBREAKER_Y_LIMIT     = 2041
local ALLY_SKYBREAKER_WALK_LIMIT  = 2045
local ALLY_Y_LIMIT                = 2100
local ALLY_SKYBREAKER_EDGE_Z      = 467.65
local ALLY_SKYBREAKER_DECK_Z      = 466.34
local ALLY_SHIP_EDGE_Z            = 467.55
local ALLY_BAND_X_MIN             = -405
local ALLY_BAND_X_MAX             = -369
local ALLY_BAND_Y_MIN             = 2040
local ALLY_BAND_Y_MAX             = 2053
local JUMP_COOLDOWN               = 2

-- Horde pos
local HORDE_ORGRIM_START_POS       = { x = -414.33, y = 2409.74, z = 472.41 }
local HORDE_SKYBREAKER_TANK_JUMP  = { x = -452.26, y = 2458.43, z = 470.15 }
local HORDE_HEALER_POS            = { x = -432.38, y = 2427.99, z = 472.25 }
local HORDE_SKYBREAKER_Y_LIMIT    = 2453
local HORDE_ORGIM_Y_LIMIT         = 2429
local HORDE_Y_LIMIT               = 2360
local HORDE_SKYBREAKER_JUMP_POS   = { x = -437.62, y = 2454.50, z = 470.60 }
local HORDE_ORGRIM_JUMP_POS        = { x = -433.09, y = 2425.85, z = 471.73 }
local HORDE_ORGRIM_TANK_POS        = { HORDE_ORGRIM_START_POS.x, HORDE_ORGRIM_START_POS.y - 10, HORDE_ORGRIM_START_POS.z }
local HORDE_ORGRIM_TANK_TRANSITION = { x = -436.86, y = 2426.79, z = 471.97 }
local HORDE_MIN_Z                 = 471.5
local HORDE_MAX_Z                 = 490
local HORDE_JUMP_EXEMPT           = 473
local HORDE_SHIP_EDGE_Y           = 2423
local HORDE_SHIP_EDGE_Z           = 471.86655

-- Recovery pos
local RECOVERY_POS                = { x = -549.19196, y = 2211.1797, z = 539.2911 }
local RECOVERY_CHECK_INTERVAL     = 2000

-- Helpers
local function GetCorrectedZ(x, y)
    if not x or not y then return nil end
    if x >= ALLY_BAND_X_MIN and x <= ALLY_BAND_X_MAX and y >= ALLY_BAND_Y_MIN and y <= ALLY_BAND_Y_MAX then
        return ALLY_SKYBREAKER_EDGE_Z
    elseif y > ALLY_BAND_Y_MAX then
        return ALLY_SKYBREAKER_DECK_Z
    end
    return nil
end

local function JumpCooldown(x1, y1, z1, x2, y2, z2)
    local dist = math.sqrt((x2-x1)^2 + (y2-y1)^2 + (z2-z1)^2)
    return dist / 5
end

local MOVE_STALL_TIME = 2000
local JUMP_MAX_TIME = 5000
local JUMP_REACH_TOLERANCE = 3
local JUMP_REACH_Z_TOLERANCE = 1

-- Rockets in flight: { x, y, z, t } where t is the impact time.
local Rockets = {}

local function GetRocketBlocked(x, y, now)
    for guid, rocket in pairs(Rockets) do
        if now >= rocket.t then
            Rockets[guid] = nil
        elseif (x - rocket.x)^2 + (y - rocket.y)^2 < ROCKET_RADIUS^2 then
            return true
        end
    end
    return false
end

local function GetPathBlocked(px, py, x, y, now)
    local dx, dy = x - px, y - py
    local len2 = dx * dx + dy * dy
    for guid, rocket in pairs(Rockets) do
        if now >= rocket.t then
            Rockets[guid] = nil
        else
            local t = 0
            if len2 > 0 then
                t = ((rocket.x - px) * dx + (rocket.y - py) * dy) / len2
                t = math.max(0, math.min(1, t))
            end
            local cx, cy = px + dx * t, py + dy * t
            if (cx - rocket.x)^2 + (cy - rocket.y)^2 < (ROCKET_RADIUS + 1)^2 then
                return true
            end
        end
    end
    return false
end

local function FindEscapeAround(px, py, bx, by, radii, now)
    for _, radius in ipairs(radii) do
        local bestX, bestY, bestDist
        for i = 0, 7 do
            local a = i * math.pi / 4
            local tx, ty = bx + math.cos(a) * radius, by + math.sin(a) * radius
            if not GetRocketBlocked(tx, ty, now) then
                local d = (tx - px)^2 + (ty - py)^2
                if not bestDist or d < bestDist then
                    bestX, bestY, bestDist = tx, ty, d
                end
            end
        end
        if bestX then return bestX, bestY end
    end
    return nil
end

local function MoveToDest(player, x, y, z)
    local px, py, pz = player:GetLocation()
    local now = GetCurrTime()
    if (px - x)^2 + (py - y)^2 + (pz - z)^2 <= 1 then return end

    if GetRocketBlocked(x, y, now) then
        local ex, ey = FindEscapeAround(px, py, x, y, { ROCKET_RADIUS + 1, ROCKET_RADIUS + 3, ROCKET_RADIUS + 5 }, now)
        if ex then x, y = ex, ey end
    end

    if not GetRocketBlocked(px, py, now) and GetPathBlocked(px, py, x, y, now) then
        player:MoveStop()
        return
    end

    local lx = player:Data():Get("GunshipMoveX")
    local ly = player:Data():Get("GunshipMoveY")
    local lz = player:Data():Get("GunshipMoveZ")
    if lx and ly and lz and (x - lx)^2 + (y - ly)^2 + (z - lz)^2 <= 1 then
        local gx, gy, gz = player:Data():Get("GunshipMoveFromX"), player:Data():Get("GunshipMoveFromY"), player:Data():Get("GunshipMoveFromZ")
        local stillNear = gx and gy and gz and (px - gx)^2 + (py - gy)^2 + (pz - gz)^2 <= 4
        if stillNear and now - player:Data():Get("GunshipMoveTime") < MOVE_STALL_TIME then return end
    end

    player:Data():Set("GunshipMoveX", x)
    player:Data():Set("GunshipMoveY", y)
    player:Data():Set("GunshipMoveZ", z)
    player:Data():Set("GunshipMoveFromX", px)
    player:Data():Set("GunshipMoveFromY", py)
    player:Data():Set("GunshipMoveFromZ", pz)
    player:Data():Set("GunshipMoveTime", now)
    player:MoveTo(1, x, y, z, true)
end

local function MoveToUnit(player, unit, range)
    local px, py, pz = player:GetLocation()
    local ux, uy, uz = unit:GetLocation()
    local dx, dy = px - ux, py - uy
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist <= range then return end
    if dist < 0.1 then dx, dy, dist = 1, 0, 1 end
    MoveToDest(player, ux + dx / dist * range, uy + dy / dist * range, uz)
end

local function HandleRocketPack(event, player)
    if not player then return end
    if event == 33 then -- Enter combat
        player:AddAura(69188, player)
    elseif event == 28 and player:HasAura(69188) then -- Change map
        player:RemoveAura(69188) 
    end
end

local function BuildThreat(tank, target)
    local class = tank:GetClass()
    if class == 6 then
        tank:CastSpell(target, 49909, true)
    elseif class == 11 then
        tank:CastSpell(target, 48564, true)
    elseif class == 2 then
        local last = tank:Data():Get("BuildThreatLast")
        if last == 61411 then
            tank:CastSpell(target, 53595, true)
            tank:Data():Set("BuildThreatLast", 53595)
        else
            tank:CastSpell(target, 61411, true)
            tank:Data():Set("BuildThreatLast", 61411)
        end
    elseif class == 1 then
        local last = tank:Data():Get("BuildThreatLast")
        if last == 47488 then
            tank:CastSpell(target, 47498, true)
            tank:Data():Set("BuildThreatLast", 47498)
        else
            tank:CastSpell(target, 47488, true)
            tank:Data():Set("BuildThreatLast", 47488)
        end
    end
end

local function RemovePassengerFromTransport(transport, player)
    if not transport or not player then return end
    local x, y, z, o = player:GetLocation()
    transport:RemovePassenger(player, true)
    player:RemoveMovementFlag(0x00000200)
    player:SendMovementFlagUpdate()
    player:NearTeleport(x, y, z, o)
end

local function AddPassengerToTransport(transport, player)
    if not transport or not player then return end
    local x, y, z, o = player:GetLocation()
    transport:AddPassenger(player, true)
    player:AddMovementFlag(0x00000200)
    player:SendMovementFlagUpdate()
    player:NearTeleport(x, y, z, o)
end

local function AddToEnemyTransport(player, enemy)
    if not enemy or not player then return end
    local transport = enemy:GetTransport()
    if not transport then return end
    local current = player:GetTransport()
    if current then
        if current == transport then return end
        RemovePassengerFromTransport(current, player)
    end
    AddPassengerToTransport(transport, player)
end

local function AddToFactionTransport(player)
    if not player then return end
    local zafod = player:GetNearestCreature(200, ZAFOD)
    if not zafod then return end
    local transport = zafod:GetTransport()
    if not transport then return end
    local current = player:GetTransport()
    if current then
        if current == transport then return end
        RemovePassengerFromTransport(current, player)
    end
    AddPassengerToTransport(transport, player)
end

local function MarkTargetSkull(player, target)
    local tick = (player:Data():Get("GunshipMarkTick") or 0) + 1
    player:Data():Set("GunshipMarkTick", tick)

    if tick % 30 ~= 0 then return end

    if not target then return end

    if target:Data():Get("SkullSet") and (os.time() - (target:Data():Get("SkullSetTime") or 0)) < 6 then return end

    target:Data():Set("SkullSet", true)
    target:Data():Set("SkullSetTime", os.time())
    SetTargetIconDeferred(player, 7, target)
end

local function FindCannonTarget(player)
    for _, entry in ipairs(CANNON_TARGET_ENTRIES) do
        local targets = player:GetCreaturesInRange(200, entry, 1, 1)
        if targets[1] then
            return targets[1]
        end
    end
    return nil
end

local function HandleCannonFire(player)
    local vehicle = player:GetVehicle()
    if not vehicle then return end

    local cannon = vehicle:GetOwner()
    local entry = cannon:GetEntry()
    if entry ~= CANNON_ALLY_ENTRY and entry ~= CANNON_HORDE_ENTRY then return end

    local now = GetCurrTime()
    local data = player:Data()
    local blastReady = now >= (data:Get("GunshipCannonBlastReady") or 0)
    local incineratingReady = cannon:GetPower(3) >= 90 and now >= (data:Get("GunshipIncineratingBlastReady") or 0)
    if not blastReady and not incineratingReady then return end

    local target = FindCannonTarget(player)
    if not target then return end

    cannon:SetFacingToObject(target)

    local cannonBlast, incineratingBlast
    if entry == CANNON_ALLY_ENTRY then
        cannonBlast, incineratingBlast = CANNON_BLAST_ALLY, INCINERATING_BLAST_ALLY
    else
        cannonBlast, incineratingBlast = CANNON_BLAST_HORDE, INCINERATING_BLAST_HORDE
    end

    if blastReady then
        cannon:CastSpellAoF(target:GetX(), target:GetY(), target:GetZ(), cannonBlast, true)
        data:Set("GunshipCannonBlastReady", now + CANNON_BLAST_COOLDOWN)
    end
    if incineratingReady then
        cannon:CastSpellAoF(target:GetX(), target:GetY(), target:GetZ(), incineratingBlast, true)
        data:Set("GunshipIncineratingBlastReady", now + CANNON_BLAST_COOLDOWN)
    end
end

local function HandleCannonEntry(player)
    if player:IsOnVehicle() then return false end
    if IsTank(player) or player:HasHealSpec() then return false end

    local best, bestDist
    for _, entry in ipairs({ CANNON_ALLY_ENTRY, CANNON_HORDE_ENTRY }) do
        for _, cannon in ipairs(player:GetCreaturesInRange(100, entry, 0, 1)) do
            local kit = cannon:GetVehicleKit()
            local ct = cannon:GetTransport()
            if kit and ct and player:GetTransport() == ct and not kit:GetPassenger(0) and not cannon:HasAura(69704) and not cannon:HasAura(69705) then
                local dist = player:GetDistance(cannon)
                if not best or dist < bestDist then
                    best, bestDist = cannon, dist
                end
            end
        end
    end

    if not best then return false end

    player:Data():Set("GunshipJumpActive", false)

    if player:GetDistance(best) > 5 then
        MoveToUnit(player, best, 3)
    else
        player:CastSpell(best, RIDE_VEHICLE_SPELL, true)
    end
    return true
end

local function HandleDpsTarget(player, boarderEntries, rangedEntries, edgeY, edgeZ)
    local isCaster = player:HasCasterSpec()
    local entries = isCaster and rangedEntries or boarderEntries
    local target = player:GetNearestCreature(200, entries[1], 1, 1)
        or player:GetNearestCreature(200, entries[2], 1, 1)
    player:ToShadow():SetTarget(target)
    if not target then return end
    if isCaster then
        if player:GetDistance(target) > 35 and not IsAtPos(player, player:GetX(), edgeY, 2) then
            MoveToDest(player, player:GetX(), edgeY, edgeZ)
        end
    elseif player:GetDistance(target) > 5 then
        MoveToUnit(player, target, 3)
    end
end

local function OnRocketArtillery(event, caster, spell)
    local x, y, z = spell:GetTargetDest()
    if not x then return end

    local dist = math.sqrt((caster:GetX() - x)^2 + (caster:GetY() - y)^2 + (caster:GetZ() - z)^2)
    local impact = GetCurrTime() + dist / ROCKET_ARTILLERY_SPEED * 1000
    Rockets[caster:GetGUIDLow()] = { x = x, y = y, z = z, t = impact }
end

local function HandleRocketAvoidance(player)
    local px, py, pz = player:GetLocation()
    local now = GetCurrTime()
    if not GetRocketBlocked(px, py, now) then return false end

    local destX, destY
    local center = py < 2150 and ALLY_SKYBREAKER_START_POS or HORDE_ORGRIM_START_POS
    destX, destY = FindEscapeAround(px, py, center.x, center.y, { 3, 6, 9, 12 }, now)

    if not destX then
        local ax, ay = 0, 0
        for _, rocket in pairs(Rockets) do
            local dx, dy = px - rocket.x, py - rocket.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist < ROCKET_RADIUS then
                if dist < 0.1 then
                    local a = math.random() * 2 * math.pi
                    dx, dy, dist = math.cos(a), math.sin(a), 1
                end
                ax, ay = ax + dx / dist, ay + dy / dist
            end
        end
        local angle = (ax ~= 0 or ay ~= 0) and math.atan2(ay, ax) or math.random() * 2 * math.pi
        local escape = ROCKET_RADIUS + ROCKET_ESCAPE
        destX, destY = px + math.cos(angle) * escape, py + math.sin(angle) * escape
    end

    RemoveRootAura(player)
    MoveToDest(player, destX, destY, pz)
    return true
end

local function RocketJump(player, x, y, z, noAura)
    AllowSpellCast(player)
    if not noAura then
        local aura = player:AddAura(65985, player)
        if aura then aura:SetDuration(3000) end
    end
    player:CastSpellAoF(x, y, z, ROCKET_PACK_SPELL, true)
    local data = player:Data()
    data:Set("GunshipJumpActive", true)
    data:Set("GunshipJumpStart", GetCurrTime())
    data:Set("GunshipJumpX", x)
    data:Set("GunshipJumpY", y)
    data:Set("GunshipJumpZ", z)
    data:Set("GunshipJumpNoAura", noAura and true or false)
end

local function VerifyJump(player)
    local data = player:Data()
    if not data:Get("GunshipJumpActive") then return false end
    if player:IsOnVehicle() then
        data:Set("GunshipJumpActive", false)
        return false
    end
    local tx, ty, tz = data:Get("GunshipJumpX"), data:Get("GunshipJumpY"), data:Get("GunshipJumpZ")
    local px, py, pz = player:GetLocation()
    if (px - tx)^2 + (py - ty)^2 <= JUMP_REACH_TOLERANCE^2 and math.abs(pz - tz) <= JUMP_REACH_Z_TOLERANCE then
        data:Set("GunshipJumpActive", false)
        return false
    end
    if GetCurrTime() - data:Get("GunshipJumpStart") < JUMP_MAX_TIME then return false end
    RocketJump(player, tx, ty, tz, data:Get("GunshipJumpNoAura"))
    return true
end

local function IsFightInProgress(player, pos)
    local zafod = player:GetNearestCreature(200, ZAFOD)
    if not zafod then return false end
    return zafod:GetDistance(pos.x, pos.y, pos.z) <= 60
end

local function GunshipHordeActions(eventId, delay, repeats, player)
    if player:IsDead() or not player:IsInCombat() or not (player:GetMapId() == 631) then
        StopLuaEvent(player)
        return
    end

    if player:IsOnVehicle() then
        HandleCannonFire(player)
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    local px, py, pz = player:GetLocation()
    local muradin = player:GetNearestCreature(200, MURADIN_ENTRY)

    -- Outside of Orgrim's Hammer main deck? Correct pos.
    if (pz >= 400 and pz <= 469) or py < 2360 or py > 2500 then
        if IsFightInProgress(player, HORDE_ORGRIM_START_POS) then
            player:NearTeleport(HORDE_ORGRIM_START_POS.x, HORDE_ORGRIM_START_POS.y, HORDE_ORGRIM_START_POS.z, player:GetO())
        end
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end
    
    -- Z correction on Orgrim's Hammer deck
    local inOrgrimRect = (px >= -438 and px <= -406) and (py >= 2365 and py <= 2429)
    if inOrgrimRect then
        local minZ = px > -420 and 472 or 473
        if pz + 1 < minZ then
            player:NearTeleport(px, py, minZ, player:GetO())
        end
    end
    
    -- Floor Z misalignment? Correct.
    if py <= HORDE_ORGIM_Y_LIMIT and py >= HORDE_Y_LIMIT and (not player:IsMoving() or not player:IsCasting()) and pz > player:GetFloorZ() + 2 and player:GetFloorZ() > HORDE_MIN_Z and player:GetFloorZ() < HORDE_MAX_Z then
        player:NearTeleport(px, py, player:GetFloorZ(), player:GetO())
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    if pz > HORDE_JUMP_EXEMPT and (py >= HORDE_ORGIM_Y_LIMIT and py <= HORDE_SKYBREAKER_Y_LIMIT) then -- Don't queue multiple commands mid-air, let bot AI fix height bugs
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    if HandleCannonEntry(player) then
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    local mage = nil
    local mages = player:GetCreaturesInRange(200, HORDE_FIGHT_MAGE_ENTRY)
    for _, m in ipairs(mages) do
        if m:IsCasting() and m:GetX() < 440 then
            mage = m
            break
        end
    end

    local mainTank, offTank = IdentifyTanks(muradin)

    local tick = (player:Data():Get("GunshipTick") or 0) + 1
    player:Data():Set("GunshipTick", tick)

    -- Ensure bots are added to correct transports
    if py > HORDE_SKYBREAKER_Y_LIMIT then
        AddToEnemyTransport(player, muradin)
    elseif py < HORDE_ORGIM_Y_LIMIT then
        AddToFactionTransport(player)
    else
        local current = player:GetTransport()
        if current then
            RemovePassengerFromTransport(current, player)
        end
    end

    -- Target prio mage, always
    if mage then MarkTargetSkull(player, mage) end
    
    -- Facing correction
    if player:GetSelection() then player:SetFacingToObject(player:GetSelection()) end

    if HandleRocketAvoidance(player) then
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    -- Off tank: stay on Orgrim at HORDE_ORGRIM_TANK_POS, cycle threat on Skybreaker boarders
    if IsTank(player) and offTank and offTank == player then
        local boarder = player:GetNearestCreature(200, SKYBREAKERS_ENTRIES[1], 1, 1) or player:GetNearestCreature(200, SKYBREAKERS_ENTRIES[2], 1, 1)
        player:ToShadow():SetTarget(boarder)
        local tx, ty = HORDE_ORGRIM_TANK_POS[1], HORDE_ORGRIM_TANK_POS[2]
        if boarder then
            if player:GetDistance(boarder) > 5 then
                MoveToUnit(player, boarder, 3)
            end
        elseif IsAtPos(player, tx, ty, 2) and not GetRocketBlocked(px, py, GetCurrTime()) then
            AddRootAura(player, 2000)
        else
            MoveToDest(player, tx, ty, HORDE_ORGRIM_TANK_POS[3])
        end
        local skullTarget = nil
        for _, entry in ipairs(SKYBREAKERS_ENTRIES) do
            local boarders = player:GetCreaturesInRange(40, entry)
            for _, boarder in ipairs(boarders) do
                player:AddThreat(boarder, 300)
                if (boarder:GetVictim() and boarder:GetVictim() ~= player) then
                    if not IsAtPos(boarder, px, py, 5) then
                        boarder:MoveTo(99, px - 3, py, pz, 0)
                        Taunt(player, boarder, false)
                    elseif boarder:GetVictim() and boarder:GetVictim():GetEntry() == SAURFANG_ENTRY then
                        -- Do nothing, let Saurfang tank
                    end
                end
                if tick % 10 == 0 then
                    player:SetFacingToObject(boarder)
                    BuildThreat(player, boarder)
                end
                if not skullTarget or boarder:GetGUIDLow() < skullTarget:GetGUIDLow() then
                    skullTarget = boarder
                end
            end
        end
        if skullTarget and not mage then MarkTargetSkull(player, skullTarget) end
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    -- Healers: pin to HORDE_HEALER_POS, root 5s on arrival
    if player:HasHealSpec() then
        local tx, ty = HORDE_HEALER_POS.x, HORDE_HEALER_POS.y
        if IsAtPos(player, tx, ty, 1) and not GetRocketBlocked(px, py, GetCurrTime()) then
            AddRootAura(player, 5000)
        else
            MoveToDest(player, tx + math.random(-1, 1), ty + math.random(-1, 1), HORDE_HEALER_POS.z)
        end
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    -- DPS: free roam on Orgrim deck if no mage
    if not mage and py <= 2422 and not (IsTank(player) and mainTank and mainTank == player) then
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    -- DPS and main tank: route back to start if drifted into Orgrim edge zone and no mage
    if not mage and py > 2422 and py <= HORDE_ORGIM_Y_LIMIT then
        MoveToDest(player, HORDE_ORGRIM_START_POS.x, HORDE_ORGRIM_START_POS.y, HORDE_ORGRIM_START_POS.z)
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    -- Jump cooldown gate
    if (player:Data():Get("GunshipJumpCooldown") or 0) > os.time() then
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    -- Between ships: rocket jump toward Skybreaker if mage, toward Orgrim if not
    if py > 2428 and py < HORDE_SKYBREAKER_Y_LIMIT and not (player == mainTank) then
        player:MoveStop()
        if mage and mage:IsCasting() and (not mainTank or mainTank:GetY() > HORDE_SKYBREAKER_Y_LIMIT) then
            RocketJump(player, HORDE_SKYBREAKER_JUMP_POS.x, HORDE_SKYBREAKER_JUMP_POS.y, HORDE_SKYBREAKER_JUMP_POS.z)
        elseif mage then
            AddRootAura(player, 15000)
        elseif not mage and py > 2429 then
            RocketJump(player, HORDE_ORGRIM_START_POS.x, HORDE_ORGRIM_START_POS.y, HORDE_ORGRIM_START_POS.z)
        end
        player:Data():Set("GunshipJumpCooldown", os.time() + JUMP_COOLDOWN)
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    -- Main tank: taunt/threat Muradin on Skybreaker, jump when mage appears
    if IsTank(player) and mainTank and mainTank == player then
        ApplyDamageReductionStacks(player, (20 + player:GetDifficulty()*15), 30000)
        if muradin and py > HORDE_SKYBREAKER_Y_LIMIT then
            player:ToShadow():SetTarget(muradin)
        else
            player:ToShadow():SetTarget(nil)
        end

        -- anyForward check: tank should not jump back if DPS are still on Skybreaker
        if py > HORDE_SKYBREAKER_Y_LIMIT then
            local anyForward = false
            local players = player:GetPlayersInRange(200)
            for _, p in ipairs(players) do
                if not IsTank(p) and p:GetY() > 2446 then
                    anyForward = true
                    break
                end
            end
            
            if not anyForward and not mage then
                RocketJump(player, HORDE_ORGRIM_TANK_TRANSITION.x, HORDE_ORGRIM_TANK_TRANSITION.y, HORDE_ORGRIM_TANK_TRANSITION.z)
                player:Data():Set("GunshipJumpCooldown", os.time() + JUMP_COOLDOWN)
                player:RegisterEvent(GunshipLoop, 200, 1)
                return
            elseif anyForward then
                if IsAtPos(player, HORDE_SKYBREAKER_TANK_JUMP.x, HORDE_SKYBREAKER_TANK_JUMP.y, 2) then
                    AddRootAura(player, 2000)
                else
                    MoveToDest(player, HORDE_SKYBREAKER_TANK_JUMP.x, HORDE_SKYBREAKER_TANK_JUMP.y, HORDE_SKYBREAKER_TANK_JUMP.z)
                end
            end

            -- On Skybreaker (enemy ship): tank Muradin
            if not player:HasAura(ORGRIMS_HAMMER_DECK_AURA) then
                player:AddAura(ORGRIMS_HAMMER_DECK_AURA, player)
            end
            if muradin then
                if not IsAtPos(muradin, px, py - 3, 4) then
                    muradin:MoveTo(999, px, py - 3, pz)
                else
                    AddRootAura(muradin, 2000)
                end
                player:SetFacingToObject(muradin)
                Taunt(player, muradin, true)
                if tick % 8 == 0 then
                    BuildThreat(player, muradin)
                end
            end
            if mage then
                if IsAtPos(player, HORDE_SKYBREAKER_TANK_JUMP.x, HORDE_SKYBREAKER_TANK_JUMP.y, 2) then
                    AddRootAura(player, 2000)
                else
                    MoveToDest(player, HORDE_SKYBREAKER_TANK_JUMP.x, HORDE_SKYBREAKER_TANK_JUMP.y, HORDE_SKYBREAKER_TANK_JUMP.z)
                end
            end
        end

        if mage then
            if py < HORDE_ORGRIM_TANK_TRANSITION.y - 2 then
                UseRocketBoots(player)
                MoveToDest(player, HORDE_ORGRIM_TANK_TRANSITION.x, HORDE_ORGRIM_TANK_TRANSITION.y, HORDE_ORGRIM_TANK_TRANSITION.z)
            elseif py >= HORDE_ORGRIM_TANK_TRANSITION.y - 1 and py <= HORDE_SKYBREAKER_Y_LIMIT then
                RocketJump(player, HORDE_SKYBREAKER_JUMP_POS.x - 3, HORDE_SKYBREAKER_JUMP_POS.y, HORDE_SKYBREAKER_JUMP_POS.z)
                player:Data():Set("GunshipJumpCooldown", os.time() + JUMP_COOLDOWN)
            elseif py > HORDE_SKYBREAKER_Y_LIMIT then
                player:Data():Set("GunshipJumpCooldown", 0)
                if IsAtPos(player, HORDE_SKYBREAKER_TANK_JUMP.x, HORDE_SKYBREAKER_TANK_JUMP.y, 2) then
                    AddRootAura(player, 2000)
                else
                    MoveToDest(player, HORDE_SKYBREAKER_TANK_JUMP.x, HORDE_SKYBREAKER_TANK_JUMP.y, HORDE_SKYBREAKER_TANK_JUMP.z)
                end
            end
        end
    else
        -- DPS

        if not mage then
            HandleDpsTarget(player, SKYBREAKERS_ENTRIES, RANGED_TARGET_ENTRIES, HORDE_SHIP_EDGE_Y, HORDE_SHIP_EDGE_Z)
        elseif player:GetTransport() == mage:GetTransport() then
            player:ToShadow():SetTarget(mage)
            if player:GetDistance(mage) > (player:HasCasterSpec() and 35 or 3) then
                MoveToUnit(player, mage, player:HasCasterSpec() and 30 or 3)
            end
        else
            player:ToShadow():SetTarget(nil)
        end

        -- Save bots from falling through Skybreaker deck
        if py > HORDE_SKYBREAKER_Y_LIMIT then
            if pz < 469 then
                player:NearTeleport(px, py, HORDE_SKYBREAKER_TANK_JUMP.z, player:GetO())
                AddToEnemyTransport(player, muradin)
            end
        end

        -- Fix facing jank
        local target = player:GetSelection()
        if target then player:SetFacingToObject(target) end

        if py < 2422 and mage then
            -- Too far back on Orgrim, walk to jump edge
            MoveToDest(player, -429.911, 2423, 471.86655)
        elseif py > HORDE_SKYBREAKER_Y_LIMIT then
            -- On Skybreaker
            player:Data():Set("GunshipJumpCooldown", 0)
            if not mage then
                if not IsAtPos(player, HORDE_SKYBREAKER_JUMP_POS.x, HORDE_SKYBREAKER_JUMP_POS.y, 2) then
                    MoveToDest(player, HORDE_SKYBREAKER_JUMP_POS.x, HORDE_SKYBREAKER_JUMP_POS.y, HORDE_SKYBREAKER_JUMP_POS.z)
                else
                    RocketJump(player, HORDE_ORGRIM_JUMP_POS.x, HORDE_ORGRIM_JUMP_POS.y, HORDE_ORGRIM_JUMP_POS.z)
                    player:Data():Set("GunshipJumpCooldown", os.time() + JUMP_COOLDOWN)
                end
            end
        end
    end

    player:RegisterEvent(GunshipLoop, 200, 1)
end

local function GunshipAllianceActions(eventId, delay, repeats, player)
    if player:IsDead() or not player:IsInCombat() or not (player:GetMapId() == 631) then
        StopLuaEvent(player)
        return
    end

    if player:IsOnVehicle() then
        HandleCannonFire(player)
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    local px, py, pz = player:GetLocation()
    
    -- Outside of Skybreaker main deck? Correct pos.
    if (pz >= 400 and pz <= 450) or px > -360 or px < -420 then
        if IsFightInProgress(player, ALLY_SKYBREAKER_START_POS) then
            player:NearTeleport(ALLY_SKYBREAKER_START_POS.x, ALLY_SKYBREAKER_START_POS.y, ALLY_SKYBREAKER_START_POS.z, player:GetO())
        end
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end
    
    -- Floor Z misalignment? Correct.
    if py >= ALLY_SKYBREAKER_Y_LIMIT and py <= ALLY_Y_LIMIT and (not player:IsMoving() or not player:IsCasting()) and pz > player:GetFloorZ() + 2 and player:GetFloorZ() > 466 and player:GetFloorZ() < 470 then
        player:NearTeleport(px, py, player:GetFloorZ(), player:GetO())
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    if pz > 468 then -- Don't queue multiple commands mid-air, let bot AI fix height bugs
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    if HandleCannonEntry(player) then
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    local mage = nil
    local mages = player:GetCreaturesInRange(200, ALLY_FIGHT_MAGE_ENTRY)
    for _, m in ipairs(mages) do
        if m:IsCasting() and m:GetX() < -366 then
            mage = m
            break
        end
    end
    local saurfang = player:GetNearestCreature(200, SAURFANG_ENTRY)
    if saurfang and saurfang:GetZ() + 1 < saurfang:GetFloorZ() then
        saurfang:NearTeleport(saurfang:GetX(), saurfang:GetY(), saurfang:GetFloorZ(), saurfang:GetO())
    end
    
    local mainTank, offTank = IdentifyTanks(saurfang)

    local tick = (player:Data():Get("GunshipTick") or 0) + 1
    player:Data():Set("GunshipTick", tick)

    -- Ensure bots are added to transports
    if py < ALLY_ORGRIM_Y_LIMIT then
        AddToEnemyTransport(player, saurfang)
    elseif py > ALLY_SKYBREAKER_Y_LIMIT then
        AddToFactionTransport(player)
    else
        local current = player:GetTransport()
        if current then
            RemovePassengerFromTransport(current, player)
        end
    end
    
    -- Target prio mage, always
    if mage then MarkTargetSkull(player, mage) end

    if HandleRocketAvoidance(player) then
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    -- Off tank stuff
    if IsTank(player) and offTank and offTank == player then
        local boarder = player:GetNearestCreature(200, KORKRON_ENTRIES[1], 1, 1) or player:GetNearestCreature(200, KORKRON_ENTRIES[2], 1, 1)
        player:ToShadow():SetTarget(boarder)
        local tx, ty = ALLY_SKYBREAKER_START_POS.x, ALLY_SKYBREAKER_START_POS.y + 5
        if player:GetSelection() then player:SetFacingToObject(player:GetSelection()) end
        if boarder then
            if player:GetDistance(boarder) > 5 then
                MoveToUnit(player, boarder, 3)
            end
        elseif IsAtPos(player, tx, ty, 2) and not GetRocketBlocked(px, py, GetCurrTime()) then
            AddRootAura(player, 2000)
        else
            MoveToDest(player, tx, ty, GetCorrectedZ(tx, ty) or pz)
        end
        local skullTarget = nil
        for _, entry in ipairs(KORKRON_ENTRIES) do
            local korkrons = player:GetCreaturesInRange(40, entry)
            for _, korkron in ipairs(korkrons) do
                player:AddThreat(korkron, 300)
                if korkron:GetVictim() ~= player then
                    Taunt(player, korkron, false)
                end
                if tick % 10 == 0 then
                    player:SetFacingToObject(korkron)
                    BuildThreat(player, korkron)
                end
                if not skullTarget or korkron:GetGUIDLow() < skullTarget:GetGUIDLow() then
                    skullTarget = korkron
                end
            end
        end
        if skullTarget and not mage then MarkTargetSkull(player, skullTarget) end
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    -- Healer stuff
    if player:HasHealSpec() then
        local tx, ty = ALLY_HEALER_POS.x, ALLY_HEALER_POS.y
        if IsAtPos(player, tx, ty, 4) and not GetRocketBlocked(px, py, GetCurrTime()) then
            AddRootAura(player, 3000)
        else
            MoveToDest(player, tx + math.random(-2.8, 2.8), ty + math.random(-2.8, 2.8), GetCorrectedZ(tx, ty) or pz)
        end
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    -- Keep players on Skybreaker deck if no mage. There's a bit of a stutter due to the edge being higher but I think it's probably OK as is
    if not mage then
        if ((player:HasMeleeSpec() or player:HasTankSpec()) and py <= ALLY_SKYBREAKER_WALK_LIMIT + 5) then
            MoveToDest(player, ALLY_SKYBREAKER_START_POS.x + math.random(-2, 2), ALLY_SKYBREAKER_START_POS.y + math.random(-2, 2), ALLY_SKYBREAKER_START_POS.z)
        elseif (py < ALLY_SKYBREAKER_Y_LIMIT + 2 and py >= ALLY_SKYBREAKER_Y_LIMIT) then
            MoveToDest(player, px, ALLY_SKYBREAKER_WALK_LIMIT + math.random(-0.5, 0.5), 467.55)
        end
    end

    -- Don't jump between Skybreaker and Orgrim if we have recently jumped
    if (player:Data():Get("GunshipJumpCooldown") or 0) > os.time() then
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    -- If we are between ships and no mage is present, jump back to Skybreaker
    if not mage and not mainTank then
        if py >= ALLY_ORGRIM_Y_LIMIT and py <= ALLY_SKYBREAKER_Y_LIMIT then
            local tx, ty = ALLY_SKYBREAKER_START_POS.x, ALLY_SKYBREAKER_START_POS.y
            RocketJump(player, tx, ty, GetCorrectedZ(tx, ty) or pz)
            player:Data():Set("GunshipJumpCooldown", os.time() + JUMP_COOLDOWN)
            player:RegisterEvent(GunshipLoop, 200, 1)
            return
        end
    end

    -- Main tank stuff
    if IsTank(player) and mainTank and mainTank == player then
        ApplyDamageReductionStacks(player, (20 + player:GetDifficulty()*15), 30000)
        if saurfang and py < ALLY_ORGRIM_Y_LIMIT then
            player:ToShadow():SetTarget(saurfang)
        else
            player:ToShadow():SetTarget(nil)
        end
        if py < ALLY_ORGRIM_Y_LIMIT then
            if not player:HasAura(ORGRIMS_HAMMER_DECK_AURA) then
                player:AddAura(ORGRIMS_HAMMER_DECK_AURA, player)
            end
            if saurfang then
                if not IsAtPos(saurfang, px, py - 3, 4) then
                    saurfang:MoveTo(999, px, py - 3, pz)
                else
                    AddRootAura(saurfang, 2000)
                end
                player:SetFacingToObject(saurfang)
                Taunt(player, saurfang, true)
                if tick % 8 == 0 then
                    BuildThreat(player, saurfang)
                end
            end
            if mage then
                if IsAtPos(player, ALLY_ORGRIM_TANK_JUMP.x, ALLY_ORGRIM_TANK_JUMP.y, 2) then
                    AddRootAura(player, 2000)
                else
                    MoveToDest(player, ALLY_ORGRIM_TANK_JUMP.x, ALLY_ORGRIM_TANK_JUMP.y, ALLY_ORGRIM_TANK_JUMP.z)
                end
            end
        end
        if mage then
            if py > ALLY_SKYBREAKER_WALK_LIMIT + 2 then
                local tx, ty = ALLY_SKYBREAKER_START_POS.x, ALLY_SKYBREAKER_Y_LIMIT
                UseRocketBoots(player)
                MoveToDest(player, tx, ty, GetCorrectedZ(tx, ty) or pz)
            elseif py <= ALLY_SKYBREAKER_WALK_LIMIT and py >= ALLY_SKYBREAKER_Y_LIMIT then
                RocketJump(player, ALLY_ORGRIM_TANK_JUMP.x, ALLY_ORGRIM_TANK_JUMP.y, ALLY_ORGRIM_TANK_JUMP.z)
                player:Data():Set("GunshipJumpCooldown", os.time() + JUMP_COOLDOWN)
            elseif py < ALLY_SKYBREAKER_Y_LIMIT then
                if py < ALLY_ORGRIM_Y_LIMIT then
                    player:Data():Set("GunshipJumpCooldown", 0)
                end
            end
        else
            if py < ALLY_SKYBREAKER_Y_LIMIT then
                RemoveRootAura(player)
                local anyForward = false
                local players = player:GetPlayersInRange(200)
                for _, p in ipairs(players) do
                    if not IsTank(p) and p:GetY() < ALLY_ORGRIM_Y_LIMIT then
                        anyForward = true
                        break
                    end
                end
                if not anyForward then
                    RemoveRootAura(player)
                    RocketJump(player, ALLY_SKYBREAKER_START_POS.x, ALLY_SKYBREAKER_START_POS.y - 5, ALLY_SKYBREAKER_START_POS.z, true)
                    player:Data():Set("GunshipJumpCooldown", os.time() + JUMP_COOLDOWN)
                else
                    if IsAtPos(player, ALLY_ORGRIM_TANK_JUMP.x, ALLY_ORGRIM_TANK_JUMP.y, 2) then
                        AddRootAura(player, 2000)
                    else
                        RemoveRootAura(player)
                        MoveToDest(player, ALLY_ORGRIM_TANK_JUMP.x, ALLY_ORGRIM_TANK_JUMP.y, ALLY_ORGRIM_TANK_JUMP.z)
                    end
                end
            end
        end
    else -- DPS stuff

        if not mage then
            HandleDpsTarget(player, KORKRON_ENTRIES, RANGED_TARGET_ENTRIES, ALLY_SKYBREAKER_WALK_LIMIT, ALLY_SHIP_EDGE_Z)
        elseif player:GetTransport() == mage:GetTransport() then
            player:ToShadow():SetTarget(mage)
            if player:GetDistance(mage) > (player:HasCasterSpec() and 35 or 3) then
                MoveToUnit(player, mage, player:HasCasterSpec() and 30 or 3)
            end
        else
            player:ToShadow():SetTarget(nil)
        end

        -- Save bots from falling through Orgrim's Hammer
        if py < ALLY_ORGRIM_Y_LIMIT then
            if pz < 466 then
                player:NearTeleport(px, py, 466.7, player:GetO())
                AddToEnemyTransport(player, saurfang)
            end
        end
        
        -- Fix facing jank
        local target = player:GetSelection()
        if target then player:SetFacingToObject(target) end
        
        local distToTank = math.abs(px - ALLY_ORGRIM_TANK_JUMP.x)
        if py >= ALLY_ORGRIM_Y_LIMIT and py <= ALLY_SKYBREAKER_Y_LIMIT and not mage then
            local tx, ty = ALLY_SKYBREAKER_START_POS.x, ALLY_SKYBREAKER_START_POS.y
            RocketJump(player, tx, ty, GetCorrectedZ(tx, ty) or pz)
            player:Data():Set("GunshipJumpCooldown", os.time() + JUMP_COOLDOWN)
        elseif py > ALLY_SKYBREAKER_WALK_LIMIT and mage then
            MoveToDest(player, px, ALLY_SKYBREAKER_Y_LIMIT, GetCorrectedZ(px, ALLY_SKYBREAKER_Y_LIMIT) or pz)
        elseif py >= ALLY_ORGRIM_Y_LIMIT and py <= ALLY_SKYBREAKER_WALK_LIMIT and mage and mage:IsCasting() then
            if not mainTank or (mainTank and mainTank:GetY() < ALLY_ORGRIM_Y_LIMIT) then
                local tx = ALLY_ORGRIM_TANK_JUMP.x - 12 + math.random(-2, 2)
                local ty = ALLY_ORGRIM_TANK_JUMP.y - 4 - math.random(0, 2)
                RocketJump(player, tx, ty, ALLY_ORGRIM_TANK_JUMP.z)
                player:Data():Set("GunshipJumpCooldown", os.time() + JUMP_COOLDOWN)
            end
        elseif py < ALLY_ORGRIM_Y_LIMIT then
            player:Data():Set("GunshipJumpCooldown", 0)
            if not mage then
                if not IsAtPos(player, px, ALLY_ORGRIM_Y_LIMIT, 2) then
                    MoveToDest(player, px, ALLY_ORGRIM_Y_LIMIT, math.min(pz, ALLY_ORGRIM_TANK_JUMP.z))
                else
                    RocketJump(player, px, py + 30, ALLY_ORGRIM_TANK_JUMP.z)
                    player:Data():Set("GunshipJumpCooldown", os.time() + JUMP_COOLDOWN)
                end
            end
        end
    end

    player:RegisterEvent(GunshipLoop, 200, 1)
end

function GunshipLoop(eventId, delay, repeats, player)
    if player:IsDead() or not player:IsInCombat() then
        StopLuaEvent(player)
        return
    end
    
    if VerifyJump(player) then
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    local py = player:GetY()
    if py < 2150 then
        GunshipAllianceActions(eventId, delay, repeats, player)
    end
    if py > 2150 then
        GunshipHordeActions(eventId, delay, repeats, player)
    end
end

local function GunshipFightOngoing()
    if not GetStateMap() then return false end
    for _, other in ipairs(GetStateMap():GetPlayers()) do
        if other:IsInCombat() then return true end
    end
    return false
end

local function GunshipOnEnterCombat(event, player, creature)
    if player:GetMapId() ~= 631 then return end
    if not player:IsBot() then return end
    if player:GetZ() < 410 or player:GetZ() > 500 then return end
    
    local zafod = player:GetNearestCreature(200, ZAFOD) -- Only start if on/near gunship/Zafod
    if not zafod then return end
    
    player:Dismount() -- Dismount so e.g., Druids don't get stuck mounted
    HandleRocketPack(event, player) -- Add rocket pack visual on enter combat
    
    if player:GetDifficulty() > 1 then ApplyHiddenBuffsToShadows(player) end -- Buff on HC

    player:ToShadow():SuppressMovement(900000)

    -- DPS and tanks: targeting is driven by the script
    if not player:HasHealSpec() then
        player:ToShadow():SuppressTargeting(900000)
    end

    player:Data():Set("GunshipJumpActive", false)
    player:RegisterEvent(GunshipLoop, 200, 1)
end

-- npc_gunshipAI::DamageTaken runs before this hook and clamps lethal damage to
-- GetHealth() - 1, so the ship is left at 1 hp instead of dying.
local function GunshipOnShipDamageTaken(event, creature, attacker, damage)
    if damage < creature:GetHealth() - 1 then return end

    local instanceId = creature:GetInstanceId()
    for _, player in ipairs(creature:GetMap():GetPlayers()) do
        if player:IsBot() and player:GetInstanceId() == instanceId then
            player:NearTeleport(RECOVERY_POS.x, RECOVERY_POS.y, RECOVERY_POS.z, player:GetO())
            AddRootAura(player, 60000)
        end
    end
end

local function RootOnGunshipCaptain(event, player, creature, sender, intid, code, menu_id)
    local players = creature:GetPlayersInRange(500)
    for _, player in ipairs(players) do
        if player:IsBot() then
            AddRootAura(player, 45000)
        end
    end
end

RegisterCreatureGossipEvent(MURADIN_ENTRY, 2, RootOnGunshipCaptain)
RegisterCreatureGossipEvent(SAURFANG_ENTRY, 2, RootOnGunshipCaptain)
RegisterCreatureEvent(ORGRIM_ENTRY, 9, GunshipOnShipDamageTaken)
RegisterCreatureEvent(SKYBREAKER_ENTRY, 9, GunshipOnShipDamageTaken)
RegisterSpellEvent(ROCKET_ARTILLERY, 2, OnRocketArtillery)
RegisterPlayerEvent(33, GunshipOnEnterCombat)

if GetStateMap() then for _, player in ipairs(GetStateMap():GetPlayers()) do GunshipOnEnterCombat(nil, player, nil) end end