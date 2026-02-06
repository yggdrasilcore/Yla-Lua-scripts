local ShrinkSpells = {}

local function PopulateShrinkSpells()
    local query = [[
        SELECT Id
        FROM spell_dbc
        WHERE (EffectAura_1 IN (61, 239)
           OR EffectAura_2 IN (61, 239)
           OR EffectAura_3 IN (61, 239))
        AND (AttributesEx & 4) = 0
        AND (AttributesEx & 16) = 0
        AND (AttributesEx & 16384) = 0
        AND (AttributesEx & 536870912) = 0
        AND Name_Lang_enUS NOT IN ("Defile", "Harvested Soul", "Harvest Soul", "Ball of Flames Proc", "Invocation of Blood", "Visual")
        AND Name_Lang_enUS NOT LIKE "%Bug%"
        AND Name_Lang_enUS NOT LIKE "% - %"
        AND Name_Lang_enUS NOT LIKE "%[%"
        AND Name_Lang_enUS NOT LIKE "%Battle Standard%"
        AND Name_Lang_enUS NOT LIKE "%\\%%"
        AND Name_Lang_enUS NOT REGEXP "[0-9]"
        AND Name_Lang_enUS NOT LIKE "%Effect%"
        AND Name_Lang_enUS NOT LIKE "%:%"
        AND Name_Lang_enUS NOT LIKE "%!%"
        AND LOWER(Name_Lang_enUS) NOT LIKE "%quest%"
        AND LOWER(Name_Lang_enUS) NOT LIKE "%combat%"
        AND Name_Lang_enUS NOT LIKE "%(%"
        AND Name_Lang_enUS NOT LIKE "%Summon%"
    ]]
    
    WorldDBQueryAsync(query, function(query)
        if query then
            repeat
                local spellId = query:GetUInt32(0)
                ShrinkSpells[spellId] = true
            until not query:NextRow()
        end
    end)
end

PopulateShrinkSpells()

local function OnChangeMap(event, player)
    player:RegisterEvent(function(e, d, r, player)
        for spellId, _ in pairs(ShrinkSpells) do
            if player:HasAura(spellId) then
                local aura = player:GetAura(spellId)
                if aura then
                    local maxDuration = aura:GetMaxDuration()
                    local stacks = aura:GetStackAmount()
                    local duration = aura:GetDuration()
                    player:RemoveAura(spellId)
                    player:AddAura(spellId, player)
                    local newAura = player:GetAura(spellId)
                    if newAura then
                        newAura:SetMaxDuration(maxDuration)
                        newAura:SetStackAmount(stacks)
                        newAura:SetDuration(duration)
                    end
                end
            end
        end
    end, 100)
end

RegisterPlayerEvent(28, OnChangeMap)