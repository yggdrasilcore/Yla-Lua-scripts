-- Group role helpers backed by core group data (no packet sniffing).
-- Replaces the old SMSG_GROUP_LIST parser, which broke on short packets
-- and compared userdata with numbers.

local function SameGUID(a, b)
    if not a or not b then return false end
    return tostring(a) == tostring(b)
end

function IsMainTank(group, player)
    if not group or not player then return false end

    if not IsTank(player) then return false end

    local mainTank = group:GetMainTank()
    return mainTank ~= nil and SameGUID(mainTank:GetGUID(), player:GetGUID())
end

function IsOffTank(group, player)
    if not group or not player then return false end

    if not IsTank(player) then return false end

    local mainAssist = group:GetMainAssist()
    return mainAssist ~= nil and SameGUID(mainAssist:GetGUID(), player:GetGUID())
end

local function OnCheckRoleCommand(event, player, command)
    if command == "checkrole" then
        local target = player:GetSelection()
        if not target or not target:IsPlayer() then
            target = player
        end

        local group = target:GetGroup()
        if not group then
            player:SendBroadcastMessage(target:GetName() .. " is not in a group")
            return false
        end

        local isMainTank = IsMainTank(group, target)
        local isOffTank = IsOffTank(group, target)

        local message = target:GetName() .. ": "
        if isMainTank then
            message = message .. "Main Tank"
        end
        if isOffTank then
            if isMainTank then
                message = message .. ", "
            end
            message = message .. "Off Tank"
        end
        if not isMainTank and not isOffTank then
            message = message .. "No role"
        end

        player:SendBroadcastMessage(message)
        return false
    end
end

RegisterPlayerEvent(42, OnCheckRoleCommand)
