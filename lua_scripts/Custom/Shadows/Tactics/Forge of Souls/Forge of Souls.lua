local BRONJAHM_ID           = 36497
local BRONJAHM_CENTER_POS   = { 5297, 2506, 686.07 }
local BRONJAHM_RADIUS       = 22
local DRAIN_SOUL            = 68839
local SOUL_FRAGMENT_ID      = 36535

local DEVOURER_ID           = 36502
local DEVOURER_POS          = { 5652, 2495, 708.94 }
local DEVOURER_RADIUS       = 30
local MIRRORED_SOUL         = 69023
local MIRRORED_SOUL_TARGET  = 69051
local PACIFY                = 19951
local WAILING_SCREAM        = 68875
local WELL_OF_SOULS_ID      = 36536

local TICK_TIMER            = 500 -- ms

local function GetFarthestPosFromTarget(target)
    local tx, ty = target:GetX(), target:GetY()
    local cx, cy = BRONJAHM_CENTER_POS[1], BRONJAHM_CENTER_POS[2]
    local dx, dy = tx - cx, ty - cy
    local len = math.sqrt(dx * dx + dy * dy)
    if len == 0 then
        return cx + BRONJAHM_RADIUS, cy
    end
    local nx, ny = dx / len, dy / len
    return cx - nx * (BRONJAHM_RADIUS - 2), cy - ny * (BRONJAHM_RADIUS - 2)
end

local function GetPerpendicularPosFromTarget(fragment, tank)
    local tx, ty = fragment:GetX(), fragment:GetY()
    local cx, cy = BRONJAHM_CENTER_POS[1], BRONJAHM_CENTER_POS[2]
    local dx, dy = tx - cx, ty - cy
    local len = math.sqrt(dx * dx + dy * dy)
    if len == 0 then
        return cx + BRONJAHM_RADIUS - 2, cy
    end
    local nx, ny = dx / len, dy / len
    -- Perpendicular axis
    local px, py = -ny, nx
    -- Which side of the perpendicular axis is the tank currently on?
    local tkx, tky = tank:GetX(), tank:GetY()
    local dot = (tkx - cx) * px + (tky - cy) * py
    local side = (dot >= 0) and 1 or -1
    return cx + px * side * (BRONJAHM_RADIUS - 2), cy + py * side * (BRONJAHM_RADIUS - 2)
end

local function BronjahmTactics(player)
    local Bronjahm = player:GetNearestCreature(50, BRONJAHM_ID)
    
    if not Bronjahm then return end
    if not Bronjahm:IsInCombat() then return end

    if Bronjahm:GetDistance2d(BRONJAHM_CENTER_POS[1], BRONJAHM_CENTER_POS[2]) > (BRONJAHM_RADIUS + 5) then return end -- Odd position, bail out
    
    if Bronjahm:GetHealthPct() < 50 then
        if not IsAtPos(player, BRONJAHM_CENTER_POS[1] - 2, BRONJAHM_CENTER_POS[2], 5) then
            player:MoveTo(0, BRONJAHM_CENTER_POS[1], BRONJAHM_CENTER_POS[2], BRONJAHM_CENTER_POS[3])
        end
    else
        local SoulFragment = player:GetNearestCreature(50, SOUL_FRAGMENT_ID)
        
        -- Always mark Soul Fragments with skull to make shadows focus them
        if SoulFragment then
            local group = player:GetGroup()
            if group then
                if not SoulFragment:GetData("SkullSet") then
                    SoulFragment:SetData("SkullSet", true)
                    group:SetTargetIcon(7, SoulFragment:GetGUID(), player:GetGUID())
                end
            end
        end
        
        -- Tank stuff
        if IsTank(player) and not player:HasAura(DRAIN_SOUL) then -- Tank stuff
            local tank = player
            local BronjahmSoulFragment = Bronjahm:GetVictim()
            
            if not (BronjahmSoulFragment == tank) and not Bronjahm:IsCasting() then
                Taunt(tank, Bronjahm, false)
            end
            
            if SoulFragment then
                -- Make tank always move to pos within radius farthest from soul fragment pos
                local fx, fy = GetPerpendicularPosFromTarget(SoulFragment, tank)
                if not IsAtPos(tank, fx, fy, 3) then
                    tank:MoveTo(0, fx, fy, BRONJAHM_CENTER_POS[3])
                    UseDefensive(player) -- Tank will move with back to boss, add defensives
                end
            else
                if not IsAtPos(tank, BRONJAHM_CENTER_POS[1] - 2, BRONJAHM_CENTER_POS[2], 3) then
                    tank:MoveTo(0, BRONJAHM_CENTER_POS[1] - 2, BRONJAHM_CENTER_POS[2], BRONJAHM_CENTER_POS[3])
                else
                    if not IsAtPos(Bronjahm, BRONJAHM_CENTER_POS[1] + 2, BRONJAHM_CENTER_POS[2], 3) then
                        Bronjahm:MoveTo(0, BRONJAHM_CENTER_POS[1] - 2, BRONJAHM_CENTER_POS[2], BRONJAHM_CENTER_POS[3])
                    end
                end
            end
            
        else -- Healers and DPS stuff
            if player:HasAura(DRAIN_SOUL) then
                -- Make player move to location in platform farthest from Bronjahm pos
                local fx, fy, fz = GetFarthestPosFromTarget(Bronjahm)
                if not IsAtPos(player, fx, fy, 3) then
                    -- Urgent move, so we stop spell casting for this tick
                    DisableSpellCast(player, 0.5)
                    player:MoveTo(0, fx, fy, BRONJAHM_CENTER_POS[3])
                end
            end
        end
    end
end

local function DevourerTactics(player)
    local Devourer = player:GetNearestCreature(100, DEVOURER_ID)
    if not Devourer then return end
    if not Devourer:IsInCombat() then return end
    
    -- Part 1: Mirrored soul
    if Devourer:HasAura(MIRRORED_SOUL) then
        local pacify = player:AddAura(PACIFY, player)
        if pacify then pacify:SetDuration(8000) end
    end
    
    if player:HasAura(MIRRORED_SOUL_TARGET) then
        UseDefensive(player)
    end
    
    -- Part 2: Wailing Scream and Wells handling
    if Devourer:HasAura(WAILING_SCREAM) then
        UseDefensive(player)
    end
    
    local invalidPositions = {}

    local wells = player:GetCreaturesInRange(50, WELL_OF_SOULS_ID)
    if wells then
        for _, well in ipairs(wells) do
            table.insert(invalidPositions, { x = well:GetX(), y = well:GetY(), r = 6 })
        end
    end

    local coneInvalid = Devourer:HasAura(WAILING_SCREAM)
    local facing = Devourer:GetO()

    local function IsInCone(x, y)
        local dx, dy = x - Devourer:GetX(), y - Devourer:GetY()
        local angle = math.atan2(dy, dx)
        local diff = math.abs((angle - facing + math.pi) % (2 * math.pi) - math.pi)
        return diff < (math.pi / 4)
    end

    local function IsInvalidPos(x, y)
        for _, zone in ipairs(invalidPositions) do
            local dx, dy = x - zone.x, y - zone.y
            if math.sqrt(dx * dx + dy * dy) < zone.r then return true end
        end
        if coneInvalid and IsInCone(x, y) then return true end
        return false
    end

    if not IsInvalidPos(player:GetX(), player:GetY()) then return end

    local isHealer = player:HasHealSpec()
    local isCaster = player:HasCasterSpec()
    local isRanged = isHealer or isCaster
    local minRange = isRanged and 10 or 2
    local maxRange = isRanged and 30 or 10

    local cx, cy = Devourer:GetX(), Devourer:GetY()
    local px, py = player:GetX(), player:GetY()

    local bestX, bestY, bestDist = nil, nil, math.huge
    local steps = 16
    for r = minRange, maxRange, 2 do
        for i = 0, steps - 1 do
            local angle = (2 * math.pi * i) / steps
            local x = cx + math.cos(angle) * r
            local y = cy + math.sin(angle) * r
            if not IsInvalidPos(x, y) then
                local dx, dy = x - px, y - py
                local d = math.sqrt(dx * dx + dy * dy)
                if isRanged then
                    local dToBoss = r
                    if dToBoss < bestDist then
                        bestDist = dToBoss
                        bestX, bestY = x, y
                    end
                else
                    if d < bestDist then
                        bestDist = d
                        bestX, bestY = x, y
                    end
                end
            end
        end
        if bestX and isRanged then break end
    end

    if bestX then
        player:MoveTo(0, bestX, bestY, DEVOURER_POS[3])
    end
end

local function StartFoSTactics(event, d, r, player)
    if not (player:GetMapId() == 632) then player:RemoveEventById(event) end
    
    BronjahmTactics(player)
    DevourerTactics(player)
end

local function OnEnterFoS(event, player)
    if not player:IsBot() then return end
    if not (player:GetMapId() == 632) then
        if player:HasAura(PACIFY) then player:RemoveAura(PACIFY) end
        return
    end
    
    player:RegisterEvent(StartFoSTactics, TICK_TIMER, 0)
end

RegisterPlayerEvent(28, OnEnterFoS)
for _, player in ipairs(GetPlayersInWorld()) do OnEnterFoS(nil, player) end