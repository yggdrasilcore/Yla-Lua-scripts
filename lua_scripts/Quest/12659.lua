if GetStateMapId() == -1 then return end

local function OnUseItem(event, player, item, target)
   if not player:GetSelection() then return false end
   local sel = player:GetSelection()
   if (sel:GetEntry() == 28465 or sel:GetEntry() == 28600) and sel:IsDead() then return true end
   return false
end

RegisterItemEvent(38731, 2, OnUseItem)

WorldDBExecute("UPDATE `conditions` SET `ConditionValue2` = 0 WHERE `ConditionValue2` = 28600 AND `SourceEntry` = 52090 AND `SourceTypeOrReferenceId` = 17;")