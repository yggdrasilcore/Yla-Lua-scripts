local FORGOTTENSHORE = 4185
local BINDING_LIFE_DURATION = 600 -- 10 minutes in seconds
local bindingLifeTimer = {}
local SPELL_BINDING_LIFE = 48809
local bindingLifeCheck = {}

-- Multistate: the item/zone handlers run in map states while the packet
-- handler runs globally, so per-player timestamps live in shared Data().
local MS = require("Multistate")

local function RemoveBindingLife(event, packet, player)
    if not (player:GetAreaId() == FORGOTTENSHORE) then
        return
    end
    local playerName = player:GetName()
    
    if (MS.GetShared(player, "BindingLifeCheck") or 0) > os.time() then
        return
    end

    if player:GetAreaId() == FORGOTTENSHORE and MS.GetShared(player, "BindingLifeTimer")
    and not player:IsInCombat() and not player:HasAura(SPELL_BINDING_LIFE)
    then
        player:RegisterEvent(function(eventid, delay, repeats, player)
            local timestamp = MS.GetShared(player, "BindingLifeTimer")
            if not timestamp then return end
            local elapsedTime = os.time() - timestamp

            if elapsedTime < BINDING_LIFE_DURATION then
                local remainingDuration = BINDING_LIFE_DURATION - elapsedTime
                player:CastSpell(player, 48810, true)
                player:AddAura(SPELL_BINDING_LIFE, player)

                local aura = player:GetAura(SPELL_BINDING_LIFE)
                MS.SetShared(player, "BindingLifeCheck", os.time() + 1)
                if aura then
                    aura:SetDuration(remainingDuration * 1000) -- Convert to milliseconds
                end
            end
        end, 20, 5)
    end
end

local function OnBindingLife(event, player, item, target)
    local playerName = player:GetName()
    if player:GetAreaId() == FORGOTTENSHORE then
        MS.SetShared(player, "BindingLifeTimer", os.time())
    end
end

local function onAreaChange(event, player, newArea, oldArea)
    local playerName = player:GetName()

    if oldArea == FORGOTTENSHORE and MS.GetShared(player, "BindingLifeTimer") then
        MS.ClearShared(player, "BindingLifeTimer")
    end
end

RegisterItemEvent(37570, 2, OnBindingLife)
RegisterPacketEvent(0x2A5, 7, RemoveBindingLife)
RegisterPlayerEvent(27, onAreaChange)
