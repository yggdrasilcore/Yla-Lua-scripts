local TWISTED_NIGHTMARE = 71941

local function GetCoeff(stacks)
    if stacks <= 5 then
        return 5.0
    elseif stacks <= 10 then
        return 4.0
    elseif stacks <= 20 then
        return 2.0
    elseif stacks <= 40 then
        return 0.5
    else
        return 0.25
    end
end

local function CheckHealer(eventId, delay, repeats, healer)
    if not (healer:GetMapId() == 631) then 
        healer:RemoveEventById(eventId)
        return
    end
    
    local x, y, z = healer:GetX(), healer:GetY(), healer:GetZ()
    local dx = x - 4203
    local dy = y - 2483

    if math.sqrt(dx * dx + dy * dy) > 65 or z < 360 then return end

    local aura = healer:GetAura(TWISTED_NIGHTMARE)
    if not aura then return end

    local stacks = aura:GetStackAmount()
    ApplyDamageReductionStacks(healer, math.min(stacks * GetCoeff(stacks), 90.0), 30000) -- Reduce dmg of nightmare aura
    
    if healer:GetHealthPct() < 20 then
        healer:DealHeal(healer, 33324, math.random(20000,30000), false) -- Heal self 25k ish, if low hp and has Nightmare Aura
    end
end

local function OnMapEnter(event, healer)
    if not (healer:GetMapId() == 631) then return end
    if not healer:IsBot() then return end

    healer:RegisterEvent(CheckHealer, 1500, 0)
end

RegisterPlayerEvent(28, OnMapEnter)
for _, player in ipairs(GetPlayersInWorld()) do OnMapEnter(nil, player) end