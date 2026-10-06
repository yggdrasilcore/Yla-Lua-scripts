-- Multistate: global-only script (all hooks fire in the world state).
if GetStateMapId() ~= -1 then return end

local function controllednpcspellcast(event, packet, player)
    if not player then
        return
    end
    
    local guid = packet:ReadGUID()  -- Read the GUID first
    local castCount = packet:ReadUByte()  -- Read the cast count (uint8)
    local spellId = packet:ReadULong()  -- Read the spell ID (uint32)
    local castFlags = packet:ReadUByte()  -- Read the cast flags (uint8)

    if spellId == 52694 then -- Ability to remove Eye of Acherus (NPC ID 28511)
        player:RemoveAura(51852)
    end
    if spellId == 56704 then -- Quest 13003, Wild Wyrm dodge
        player:AddAura(56704, player)
    end
    if spellId == 58912 then -- Quest 13395 / 13236 Deathstorm player immunity
        if not player:GetSelection() or player:GetSelection():ToPlayer() or player:GetSelection():IsDead() then 
            player:RegisterEvent(function(eventId, delay, repeats, player)
                player:SendNotification("No target")
                local arthas = player:GetNearestCreature(50, 31268)
                if arthas then
                    arthas:InterruptSpell(1)
                end
            end, 500)
        end
        local immunity = player:AddAura(29230, player)
        immunity:SetDuration(11000)
    end
end

RegisterPacketEvent(0x1F0, 5, controllednpcspellcast)