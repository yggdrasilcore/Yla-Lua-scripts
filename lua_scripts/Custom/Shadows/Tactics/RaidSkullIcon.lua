local GUARD_TTL = 60
local setGuard = {}

local function GuardKey(icon, targetLow)
    return icon .. ":" .. targetLow
end

function ResetTargetIconGuards(icon)
    for key in pairs(setGuard) do
        if key:match("^" .. icon .. ":") then
            setGuard[key] = nil
        end
    end
end

local function GetPendingIcons(player)
    local pending = player:Data():Get("RaidIconPending")
    if pending and pending.AsTable then
        pending = pending:AsTable()
    end
    if type(pending) ~= "table" then
        pending = {}
    end
    return pending
end

local function ApplyPendingIcons(player)
    local pending = GetPendingIcons(player)
    if next(pending) == nil then return end
    player:Data():Set("RaidIconPending", nil)

    local group = player:GetGroup()
    if not group then return end

    for iconKey, data in pairs(pending) do
        local icon = tonumber(iconKey)
        if icon and data then
            if data.clear then
                ResetTargetIconGuards(icon)
                group:SetTargetIcon(icon, 0, player:GetGUID())
            elseif data.targetLow and data.targetEntry then
                local key = GuardKey(icon, data.targetLow)
                if not (setGuard[key] and (os.time() - setGuard[key]) < GUARD_TTL) then
                    group:SetTargetIcon(icon, GetUnitGUID(data.targetLow, data.targetEntry), player:GetGUID())
                    setGuard[key] = os.time()
                end
            end
        end
    end
end

local function QueuePendingIcon(player, icon, data)
    local pending = GetPendingIcons(player)
    pending[tostring(icon)] = data
    player:Data():Set("RaidIconPending", pending)
    player:RunCommand("ApplyRaidIcon")
end

function SetTargetIconDeferred(setter, icon, target)
    if not setter then return end
    local group = setter:GetGroup()
    if not group then return end
    if target then
        if GetGUIDLow(group:GetTargetIcon(icon)) == target:GetGUIDLow() then
            return
        end
        QueuePendingIcon(setter, icon, {
            targetLow = target:GetGUIDLow(),
            targetEntry = target:GetEntry(),
        })
    else
        if GetGUIDLow(group:GetTargetIcon(icon)) == 0 then
            return
        end
        QueuePendingIcon(setter, icon, { clear = true })
    end
end

local function OnRaidIconCommand(event, player, command)
    if not player then return end

    if command == "ApplyRaidIcon" then
        ApplyPendingIcons(player)
        return false
    end

    if command == "RemoveRaidIcon" or command == "SetRaidIcon" then

        local group = player:GetGroup()
        if not group then return false end

        if command == "RemoveRaidIcon" then
            local members = group:GetMembers()
            for _, member in pairs(members) do
                if member:IsAlive() and member:IsInCombat() then
                    local distance = player:GetDistance(member)
                    if distance <= 500 then return false end
                end
            end

            player:Data():Set("RaidIconPending", nil)
            group:SetTargetIcon(7, 0, player:GetGUID())
            ResetTargetIconGuards(7)
            return false
        end

        local targetGuid = player:GetSelectionGUID()
        if GetGUIDLow(targetGuid) == 0 then return end
        group:SetTargetIcon(7, targetGuid, player:GetGUID())
        setGuard[GuardKey(7, GetGUIDLow(targetGuid))] = os.time()
        return false
    end
end

local function RemoveRaidIconsOnDeath(event, obj1, player)
    if event == 8 and not player:IsBot() then return end -- Ensures we don't process player death twice as this is in event 7 (packet) anyway

    player:RunCommand("RemoveRaidIcon")
end

if GetStateMapId() == -1 then
    RegisterPlayerEvent(42, OnRaidIconCommand) -- Used to defer map event 8 hook clear event to world
    RegisterPacketEvent(0x269, 7, RemoveRaidIconsOnDeath) -- This captures all player deaths but packet events don't work on shadows,
else
    RegisterPlayerEvent(8, RemoveRaidIconsOnDeath) -- This works for all creature kills but not other death (shadows can only be killed by creatures, not gravity/drowning etc.)
end
