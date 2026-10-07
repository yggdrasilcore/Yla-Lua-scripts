-- Multistate: RegisterItemEvent handlers fire in map states, but Group member
-- listing is world-only, so group-wide drum casts are forwarded to the global
-- state via EMQ.
local Multistate = require("Multistate")
local EMQ = require("EMQ")

-- Global executor (Group API is world-only). Pets are resolved here as well so
-- the whole group iteration stays in one state.
local function DoCastOnGroup(player, data)
    if not player or not data or not data.spellId then
        return
    end
    local spellId = data.spellId
    local group = player:GetGroup()
    if not group then
        player:CastSpell(player, spellId, true)
        local pet = player:GetPet()
        if pet then
            player:CastSpell(pet, spellId, true)
        end
        return
    end

    local members = nil
    -- Multistate: Group member listing is world-only; this executor runs in the
    -- global state (or compat mode), where it exists.
    if GetStateMapId() == -1 then
        members = group:GetMembers()
    end
    if not members then
        player:CastSpell(player, spellId, true)
        return
    end
    for _, member in ipairs(members) do
        player:CastSpell(member, spellId, true)
        local pet = member:GetPet()
        if pet then
            player:CastSpell(pet, spellId, true)
        end
    end
end

EMQ.RegisterQueue("DrumsCastOnGroup", DoCastOnGroup)

-- Multistate: map-only script (all hooks fire in map states; the EMQ queue
-- above must still register in every state, hence the gate sits below it).
if not IsCompatibilityMode() and GetStateMapId() == -1 then return end

WorldDBExecute("DELETE FROM spell_linked_spell WHERE spell_trigger IN (69381, 69378)") -- Wipe DB links for faulty Drums scripts
WorldDBExecute("DELETE FROM spell_script_names WHERE spell_id IN (69377)") -- Wipe DB link to faulty Runescroll of Fortitude script

local function CastOnGroup(player, spellId)
    local data = { spellId = spellId }
    if Multistate.IsCompat() or Multistate.IsWorld() then
        DoCastOnGroup(player, data)
    else
        player:SendEMQMessage("DrumsCastOnGroup", data)
    end
end

local function OnUseDrumsOfTheWild(event, player, item, target)
    CastOnGroup(player, 72588)
end

local function OnUseDrumsOfForgottenKings(event, player, item, target)
    CastOnGroup(player, 72586)
end

local function OnUseRunescrollOfFortitude(event, player, item, target)
    CastOnGroup(player, 72590)
end

RegisterItemEvent(49634, 2, OnUseDrumsOfTheWild)
RegisterItemEvent(49633, 2, OnUseDrumsOfForgottenKings)
RegisterItemEvent(49632, 2, OnUseRunescrollOfFortitude)
