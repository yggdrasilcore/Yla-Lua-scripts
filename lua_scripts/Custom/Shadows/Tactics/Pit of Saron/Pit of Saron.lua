local MAP_ID            = 658

local GARFROST_ID       = 36494
local FROST_RESISTANCE  = 2705400

local ICK_ID            = 36476
-- To-do Ick

local TYRANNUS_ID       = 36658
local TYRANNUS_POS      = { 1016, 154, 628.16 }
local TYRANNUS_RADIUS   = 60
local OVERLORDS_BRAND   = 69172
local PACIFY            = 19951
local MARK_OF_RIMEFANG  = 69275

local TICK_TIMER        = 500 -- ms

local function GarfrostTactics(player)
    local Garfrost = player:GetNearestCreature(100, GARFROST_ID)
    if not Garfrost then return end
    
    if Garfrost and not player:HasAura(FROST_RESISTANCE) then
        player:AddAura(FROST_RESISTANCE, player)
    end

    if not Garfrost and player:HasAura(FROST_RESISTANCE) then
        player:AddAura(FROST_RESISTANCE, player)
    end
end

local function IckTactics(player)
    local Ick = player:GetNearestCreature(100, ICK_ID)
    if not Ick then return end
    
    ApplyDamageReductionStacks(player, 80, 30000) -- Fix Ick later
end

local function TyrannusTactics(player)
    local Tyrannus = player:GetNearestCreature(100, TYRANNUS_ID)
    if not Tyrannus then return end
    
    if player:HasAura(OVERLORDS_BRAND) then -- Silence and pacify muted targets
        DisableSpellCast(8000)
        local pacify = player:AddAura(PACIFY, player)
        if pacify then pacify:SetDuration(8000) end
    end
    
    if player:HasAura(MARK_OF_RIMEFANG) then
        local px, py, pz = player:GetPosition()
        local tooClose = false
        for _, nearby in ipairs(player:GetPlayersInRange(20)) do
            local nx, ny = nearby:GetPosition()
            local dist = math.sqrt((px-nx)^2 + (py-ny)^2)
            if dist < 10 then
                tooClose = true
                local dx, dy = px-nx, py-ny
                local len = math.sqrt(dx*dx + dy*dy)
                local tx = px + (dx/len) * (10 - dist + 2)
                local ty = py + (dy/len) * (10 - dist + 2)
                local tz = player:GetMap():GetHeight(tx, ty)
                player:MoveTo(0, tx, ty, tz)
                break
            end
        end
        if not tooClose then
            AddRootAura(player, 500)
        end
    end
end

local function StartFoSTactics(event, d, r, player)
    if not (player:GetMapId() == MAP_ID) then player:RemoveEventById(event) end
    
    GarfrostTactics(player)
    IckTactics(player)
    TyrannusTactics(player)
end

local function OnEnterFoS(event, player)
    if not player:IsBot() then return end
    
    if not (player:GetMapId() == MAP_ID) then
        if player:HasAura(PACIFY) then player:RemoveAura(PACIFY) end
        if player:HasAura(FROST_RESISTANCE) then player:RemoveAura(FROST_RESISTANCE) end
        return
    end
    
    player:RegisterEvent(StartFoSTactics, TICK_TIMER, 0)
end

RegisterPlayerEvent(28, OnEnterFoS)
for _, player in ipairs(GetPlayersInWorld()) do OnEnterFoS(nil, player) end