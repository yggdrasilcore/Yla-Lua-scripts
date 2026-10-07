-- Multistate: PLAYER_EVENT_ON_COMMAND (42) fires in the global state. Reads stay
-- direct; faction changes execute on the map state via EMQ.
local Multistate = require("Multistate")
local EMQ = require("EMQ")

-- Map-state executor (via EMQ, or directly in compatibility mode).
local function DoSetFaction(player, data)
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
    if target and target:IsPlayer() then
        target:SetFaction(data.factionId)
        player:SendBroadcastMessage("Set " .. (target == player and "your" or "selected player's") .. " faction to: " .. data.factionId)
    else
        player:SendBroadcastMessage("Your faction is: " .. player:GetFaction())
    end
end

EMQ.RegisterQueue("CmdSetFaction", DoSetFaction)

if GetStateMapId() ~= -1 then return end

local function GetFactionCommand(event, player, command)
    if command == "getfaction" then
        local target = player:GetSelection()
        if target and target:IsPlayer() then
            player:SendBroadcastMessage("Selected player's faction is: " .. target:GetFaction())
        else
            player:SendBroadcastMessage("Your faction is: " .. player:GetFaction())
        end
        return false
    end
end

RegisterPlayerEvent(42, GetFactionCommand)

local function SetFactionCommand(event, player, command)
    -- Split the command into parts
    local args = {}
    for word in command:gmatch("%w+") do
        table.insert(args, word)
    end

    -- Check if command is "setfaction" and has a faction number
    if args[1] == "setfaction" and args[2] then
        -- Convert the second argument to a number
        local factionId = tonumber(args[2])

        if not factionId then
            player:SendBroadcastMessage("Please provide a valid faction number.")
            return false
        end

        -- Get target or use player if no target
        local data = { factionId = factionId }
        local target = player:GetSelection()
        if target and target:IsPlayer() then
            data.targetGuidLow = target:GetGUIDLow()
            data.targetName = target:GetName()
        end
        if Multistate.IsCompat() then
            DoSetFaction(player, data)
        else
            player:SendEMQMessage("CmdSetFaction", data)
        end
        return false
    end
end

RegisterPlayerEvent(42, SetFactionCommand)
