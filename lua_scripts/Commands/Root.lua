-- Multistate: PLAYER_EVENT_ON_COMMAND (42) fires in the global state, but aura
-- changes must execute on the map state, so they are forwarded via EMQ. The
-- target is re-resolved on the map state (selections usually persist, which also
-- covers non-player targets that cannot be found by name).
local Multistate = require("Multistate")
local EMQ = require("EMQ")

-- Map-state executor (via EMQ, or directly in compatibility mode).
local function DoRootCommand(player, data)
    if not player then
        return
    end
    local target = player
    local sel = player:GetSelection()
    if sel and data.targetGuidLow and sel:GetGUIDLow() == data.targetGuidLow then
        target = sel
    elseif data.targetName then
        target = Multistate.FindPlayerByName(data.targetName) or player
    end
    if data.remove then
        target:RemoveAura(38505)
    else
        if target:HasAura(38505) then
            target:RemoveAura(38505)
        else
            player:AddAura(38505, target)
        end
    end
end

EMQ.RegisterQueue("CmdRoot", DoRootCommand)

if GetStateMapId() ~= -1 then return end

local function OnRootCommand(event, player, command)
    if command == "root" then
        if player:GetGMRank() == 0 then return false end
        local target = player:GetSelection()
        local data = { remove = false }
        if target then
            data.targetGuidLow = target:GetGUIDLow()
            data.targetName = target:GetName()
        end
        if Multistate.IsCompat() then
            DoRootCommand(player, data)
        else
            player:SendEMQMessage("CmdRoot", data)
        end
        return false
    elseif command == "unroot" then
        if player:GetGMRank() == 0 then return false end
        local target = player:GetSelection()
        local data = { remove = true }
        if target then
            data.targetGuidLow = target:GetGUIDLow()
            data.targetName = target:GetName()
        end
        if Multistate.IsCompat() then
            DoRootCommand(player, data)
        else
            player:SendEMQMessage("CmdRoot", data)
        end
        return false
    end
end

RegisterPlayerEvent(42, OnRootCommand)
