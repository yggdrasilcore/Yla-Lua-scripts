local LIFEBLOOM_SPELLS = {48451, 48450, 33763}

local function GetHighestKnownLifebloom(player)
    for i = #LIFEBLOOM_SPELLS, 1, -1 do
        if player:HasSpell(LIFEBLOOM_SPELLS[i]) then
            return LIFEBLOOM_SPELLS[i]
        end
    end
    return nil
end

local function GetLowestHpMember(player)
    local group = player:GetGroup()
    if not group then return nil end

    local members = group:GetMembers()
    local target = nil
    local lowestHp = math.huge

    for _, member in ipairs(members) do
        if member and member:IsAlive() then
            if player:IsWithinDist(member, 40) and player:IsWithinLoS(member) then
                local hp = member:GetHealth()
                if hp < lowestHp then
                    lowestHp = hp
                    target = member
                end
            end
        end
    end

    return target
end

local function OnLifebloomTick(eventId, delay, repeats, player)
    if not player:HasHealSpec() then return end
    if not player:HasAura(16870) then return end

    local spellId = GetHighestKnownLifebloom(player)
    if not spellId then return end

    local target = GetLowestHpMember(player)
    if not target then return end

    player:CastSpell(target, spellId, false)
end

local function OnMapChange(event, player)
    if not player:IsBot() then return end
    if player:GetClass() ~= 11 then return end

    if player:GetData("lifebloomeventstarted") then return end

    player:SetData("lifebloomeventstarted", true)
    player:RegisterEvent(OnLifebloomTick, 1000, 0)
end

RegisterPlayerEvent(28, OnMapChange)

CreateLuaEvent(function(e, d, r)
    for _, player in ipairs(GetPlayersInWorld()) do
        OnMapChange(nil, player)
    end
end, 2000)