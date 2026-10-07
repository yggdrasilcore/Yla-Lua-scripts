-- Improves the terrible AzerothCore approach to .learn ###. Won't get stuck if NPC is targeted anymore. made by mostly nick :)
-- Multistate: PLAYER_EVENT_ON_COMMAND (42) fires in the global state, but spell
-- learning must execute on the map state, so it is forwarded via EMQ.
local Multistate = require("Multistate")
local EMQ = require("EMQ")

-- Map-state executor (via EMQ, or directly in compatibility mode).
local function DoLearnSpell(player, data)
    if not player then
        return
    end
    local spellId = data.spellId
    if not spellId then
        return
    end
    local sel = player:GetSelection()
    local spellTarget = nil
    if sel and data.targetGuidLow and sel:GetGUIDLow() == data.targetGuidLow and sel:IsPlayer() then
        spellTarget = sel
    elseif data.targetName then
        spellTarget = Multistate.FindPlayerByName(data.targetName)
    end
    if spellTarget then
        spellTarget:LearnSpell(spellId)
    else
        player:LearnSpell(spellId)
    end

    player:RegisterEvent(function(eventId, delay, repeats, player)
        -- Re-resolve the target on the map state (same logic as the original
        -- delayed check, just state-aware).
        local sel = player:GetSelection()
        if data.targetGuidLow and (not sel or sel:GetGUIDLow() ~= data.targetGuidLow) then
            sel = nil
            if data.targetName then
                sel = Multistate.FindPlayerByName(data.targetName)
            end
        end
        if sel and not sel:HasSpell(spellId) then
            player:SendBroadcastMessage("Invalid spell ID. Please provide a valid number.")
        elseif not player:HasSpell(spellId) then
            player:SendBroadcastMessage("Invalid spell ID. Please provide a valid number.")
        end
    end, 20, 1)
end

EMQ.RegisterQueue("CmdLearnSpell", DoLearnSpell)

if GetStateMapId() ~= -1 then return end

local function onCommand(event, player, command)
    if command:match("^%s*learn%s+(%d+)%s*$") then
        if not player then return end
        if player:GetGMRank() == 0 then return false end

        local _, _, spellIdStr = command:find("^%s*learn%s+(%d+)%s*$")
        local spellId = tonumber(spellIdStr)

        if spellId then
            local data = { spellId = spellId }
            local sel = player:GetSelection()
            if sel and sel:IsPlayer() then
                data.targetGuidLow = sel:GetGUIDLow()
                data.targetName = sel:GetName()
            end
            if Multistate.IsCompat() then
                DoLearnSpell(player, data)
            else
                player:SendEMQMessage("CmdLearnSpell", data)
            end
        else
            player:SendBroadcastMessage("Invalid spell ID. Please provide a valid number.")
        end
        return false
    end
end

RegisterPlayerEvent(42, onCommand)
