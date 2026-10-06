-- Multistate: Icecrown Citadel-only script (map 631).
if not IsCompatibilityMode() and GetStateMapId() ~= 631 then return end

function ManageInsect(eventId, delay, repeats, player)
    local insectGUID = player:GetData("AssignedInsectGUID")
    
    if not insectGUID then
        player:RemoveEventById(eventId)
        return
    end
    
    local insect = nil
    local insects = player:GetCreaturesInRange(100, 37782)
    for _, npc in pairs(insects) do
        if npc:GetGUIDLow() == insectGUID then
            insect = npc
            break
        end
    end
    
    if not insect or insect:IsDead() or player:IsDead() then
        player:SetData("AssignedInsectGUID", nil)
        player:RemoveEventById(eventId)
        return
    end

    local go1 = player:GetNearestGameObject(100, 201372)
    local go2 = player:GetNearestGameObject(100, 201612)
    local go3 = player:GetNearestGameObject(100, 201613)
    local go4 = player:GetNearestGameObject(100, 201614)
    local KillNpc = false
    if (go1 and go1:GetGoState() == 0) or (go2 and go2:GetGoState() == 0) or
       (go3 and go3:GetGoState() == 2) or (go4 and go4:GetGoState() == 2) then
        KillNpc = false
    end

    local currentTime = os.time()
    local remaining = {}

    for _, guid in ipairs(guids) do
        local insect = nil
        for _, npc in pairs(player:GetCreaturesInRange(100, 37782)) do
            if npc:GetGUIDLow() == guid then
                insect = npc
                break
            end
        end

        if insect and not insect:IsDead() and not player:IsDead() then
            if KillNpc then
                insect:Kill(insect)
            else
                insect:SetFacingToObject(player)
                local distance = insect:GetDistance(player)
                
                if insect:GetZ() > insect:GetFloorZ() + 2 then
                    insect:SetDisableGravity(true)
                else
                    insect:SetDisableGravity(false)
                end
                
                if distance > 1 then
                    if insect:GetZ() > insect:GetFloorZ() + 2 then
                        insect:MoveTo(0, insect:GetX(), insect:GetY(), insect:GetFloorZ(), false)
                    elseif insect:IsStopped() then 
                        insect:MoveTo(0, player:GetX(), player:GetY(), player:GetZ(), false)
                    else
                        local dx = player:GetX() - insect:GetX()
                        local dy = player:GetY() - insect:GetY()
                        local targetAngle = math.atan2(dy, dx)
                        local facingAngle = insect:GetO()
                        local diff = math.abs(targetAngle - facingAngle) % (2 * math.pi)
                        if diff > math.pi then diff = 2 * math.pi - diff end
                        if insect:IsStopped() or diff > 0.5 then
                            insect:MoveClear(true)
                            insect:MoveTo(0, player:GetX(), player:GetY(), player:GetZ(), false)
                        end
                    end
                end
                
                table.insert(remaining, guid)
            end
        end
    end

    player:SetData("AssignedInsects", #remaining > 0 and remaining or nil)
    if not player:GetData("AssignedInsects") then
        player:RemoveEventById(eventId)
    end
end

local function AssignInsects(player)
    local insects = player:GetCreaturesInRange(100, 37782)

    for _, insect in pairs(insects) do
        if not insect:IsDead() then
            -- skip if already assigned to someone
            local alreadyAssigned = false
            local playersInRange = insect:GetPlayersInRange(100)
            for _, p in pairs(playersInRange) do
                local existing = p:GetData("AssignedInsects") or {}
                for _, guid in ipairs(existing) do
                    if guid == insect:GetGUIDLow() then
                        alreadyAssigned = true
                        break
                    end
                end
                if alreadyAssigned then break end
            end

            if not alreadyAssigned then
                local validPlayer = nil
                local nearestDistance = 999999

                for _, p in pairs(playersInRange) do
                    local py = p:GetY()
                    if py < 3153 and py > 3075 then
                        local distance = insect:GetDistance(p)
                        if distance < nearestDistance then
                            nearestDistance = distance
                            validPlayer = p
                        end
                    end
                end

                if validPlayer then
                    local existing = validPlayer:GetData("AssignedInsects") or {}
                    table.insert(existing, insect:GetGUIDLow())
                    validPlayer:SetData("AssignedInsects", existing)
                    if #existing == 1 then
                        validPlayer:RegisterEvent(ManageInsect, 300, 1000)
                    end
                end
            end
        end
    end
end

local function InsectLoop(eventId, delay, repeats, player)
    if player:GetMapId() ~= 631 then
        player:RemoveEventById(eventId)
        return
    end
    local px = player:GetX()
    local py = player:GetY()
    local pz = player:GetZ()
    if px >= 4336 and px <= 4374 and py >= 3080 and py <= 3155 and pz >= 355 and pz <= 395 then
        AssignInsects(player)
    end
end

local function OnInsectMapChange(event, player)
    if player:GetMapId() == 631 then
        player:RegisterEvent(InsectLoop, 2000, 0)
    end
end

RegisterPlayerEvent(28, OnInsectMapChange)
require("Multistate").ForEachPlayer(function(player) OnInsectMapChange(nil, player) end)