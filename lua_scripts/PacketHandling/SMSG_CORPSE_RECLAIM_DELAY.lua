if GetStateMapId() ~= -1 then return end

local function killPlayer(e, d, r, player)
	if player:GetHealth() == 0 then return end -- Don't try to kill if HP is 0 (then player is actually dead, as opposed to the IsDead() flag)
	if not player:Data():Get("DeathSet") or player:Data():Get("DeathSet") < os.time() then
		player:Data():Set("DeathSet", os.time() + 1) -- Prevents c stack overflows in certain packet loops
		player:KillPlayer()
	end
end

local function On0x269(event, packet, player)
    local map = player:GetMapId()
    print("packet 269 sent!")
    if map == 0 or map == 1 or map == 530 or map == 571 then return end -- Don't run on continents
    if player:Data():Get("269Debounce") and player:Data():Get("269Debounce") > os.time() then return end
    player:Data():Set("269Debounce", os.time() + 1)
	if player:GetHealth() > 0 and not (player:HasAura(8326) or player:HasAura(20584)) then
		print("Reviving on 0x269")
		player:ResurrectPlayer()
		player:RegisterEvent(killPlayer, 1100, 1) -- If player is alive 1 second later, it means we gotta try again. KillPlayer() will make this packet fire again.
	end
end

RegisterPacketEvent(0x269, 7, On0x269)

-- Removes former hackfixes that were in place to ensure players didn't get exerted to bugged packet order
WorldDBExecute("DELETE FROM areatrigger WHERE entry = 5001;") -- The Oculus
WorldDBExecute("DELETE FROM areatrigger_teleport WHERE id = 5001;") -- The Oculus