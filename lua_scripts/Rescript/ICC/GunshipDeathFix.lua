local function AllianceGunshipDeathFix(player)
    local hasAura = player:HasAura(70121)
    local saurfang = player:GetNearestCreature(1000, 36939, 1)
    local orgrim = player:GetNearestCreature(1000, 37215, 0)
    
    local orgrimDead = not orgrim or orgrim:GetHealth() == 1
    
    if hasAura and saurfang and orgrimDead then
        player:NearTeleport(-549, 2211, 539.29, 6.14)
    end
end

local function HordeGunshipDeathFix(player)
    local hasAura = player:HasAura(70120)
    local muradin = player:GetNearestCreature(1000, 36949, 1)
    local skybreaker = player:GetNearestCreature(1000, 37540, 0)
    
    local skybreakerDead = not skybreaker or skybreaker:GetHealth() == 1
    
    if hasAura and muradin and skybreakerDead then
        player:NearTeleport(-549, 2211, 539.29, 6.14)
    end
end

local function GunshipCheck(eventId, delay, repeats, player)
    if player:GetMapId() ~= 631 then
        player:SetData("GunshipCheckActive", nil)
        player:RemoveEventById(eventId)
        return
    end
    
    local saurfang = player:GetNearestCreature(1000, 36939, 1)
    local muradin = player:GetNearestCreature(1000, 36949, 1)
    
    if saurfang then
        AllianceGunshipDeathFix(player)
    elseif muradin then
        HordeGunshipDeathFix(player)
    end
end

local function OnMapChange(event, player)
    if player:GetMapId() == 631 then
        if not player:GetData("GunshipCheckActive") then
            player:SetData("GunshipCheckActive", true)
            player:RegisterEvent(GunshipCheck, 2000, 0)
        end
    end
end

local function InitGunshipChecks()
    local players = GetPlayersInWorld()
    for _, player in ipairs(players) do
        if player:GetMapId() == 631 then
            if not player:GetData("GunshipCheckActive") then
                player:SetData("GunshipCheckActive", true)
                player:RegisterEvent(GunshipCheck, 2000, 0)
            end
        end
    end
end

InitGunshipChecks()
RegisterPlayerEvent(27, OnMapChange)