if GetStateMapId() == -1 then return end

local function UseRockFalcon(event, player, item, target)
    if not target or not (target:GetEntry() == 24747) then
        return false
    end
    if target and target:GetEntry() == 24747 then -- Fjord Hawk
        if player:GetData("lastHawkTime") and player:GetData("lastHawkTime") > os.time() then
            return
        end
        player:RemoveItem(34102, 1) --Removes fjord grub
        player:RegisterEvent(function(eventId, delay, repeats, player)
            player:AddItem(34120, 1) -- Fjord Hawk quest item
        end, 3000, 1) -- Takes about 3 sec for bird to return
        player:SetData("lastHawkTime", os.time() + 10)
    end
end

RegisterItemEvent(34121, 2, UseRockFalcon)