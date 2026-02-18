WorldDBExecute("DELETE FROM spell_linked_spell WHERE spell_trigger IN (69381, 69378)") -- Wipe DB links for faulty Drums scripts
WorldDBExecute("DELETE FROM spell_script_names WHERE spell_id IN (69377)") -- Wipe DB link to faulty Runescroll of Fortitude script

local function CastOnGroup(player, spellId)
    local group = player:GetGroup()
    if not group then
        player:CastSpell(player, spellId, true)
        local pet = player:GetPet()
        if pet then
            player:CastSpell(pet, spellId, true)
        end
        return
    end

    local members = group:GetMembers()
    for _, member in ipairs(members) do
        player:CastSpell(member, spellId, true)
        local pet = member:GetPet()
        if pet then
            player:CastSpell(pet, spellId, true)
        end
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