function CombatCheck(eventId, delay, repeats, sindragosa)
   if sindragosa:IsDead() or not sindragosa:IsInCombat() then
       RemoveEventById(eventId)
       return
   end
   
   if sindragosa:GetZ() > 217 then
       local iceTargets = sindragosa:GetCreaturesInRange(1000, 36890)
       
       if #iceTargets > 0 then
           local player = sindragosa:GetNearestPlayer()
           if not player or not player:IsAlive() then
               local players = sindragosa:GetPlayersInRange(1000)
               for i = 1, #players do
                   if players[i]:IsAlive() then
                       player = players[i]
                       break
                   end
               end
           end
           
           if player and player:IsAlive() then
               local hasDebuff = player:HasAura(70084) or player:HasAura(71050) or 
                                 player:HasAura(71051) or player:HasAura(71052)
               local group = player:GetGroup()
               
               if group then
                   for i = 1, #iceTargets do
                       if not hasDebuff and iceTargets[i]:GetHealthPct() < 30 then
                           group:SetTargetIcon(5, iceTargets[i], player)
                       elseif hasDebuff then
                           group:SetTargetIcon(0, iceTargets[i], player)
                       end
                   end
               end
           end
       end
       return
   end
   
   if not (sindragosa:GetZ() < 217) then
       return
   end
   
   local target = sindragosa:GetVictim()
   if not target or not target:ToPlayer() then
       return
   end
   
   target:AddAura(64556, target)
end

function OnSindyCombat(event, player, enemy)
   if enemy and enemy:GetEntry() == 36853 then
       enemy:RegisterEvent(CombatCheck, 500, 0)
   end
end

RegisterPlayerEvent(33, OnSindyCombat)