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
        for _, p in ipairs(GetStateMap():GetPlayers()) do
            if p:GetName() == data.targetName then target = p break end
        end
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
        player:SendEMQMessage("CmdRoot", data)
        return false
    elseif command == "unroot" then
        if player:GetGMRank() == 0 then return false end
        local target = player:GetSelection()
        local data = { remove = true }
        if target then
            data.targetGuidLow = target:GetGUIDLow()
            data.targetName = target:GetName()
        end
        player:SendEMQMessage("CmdRoot", data)
        return false
    end
end

RegisterPlayerEvent(42, OnRootCommand)
