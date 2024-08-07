local cooldown = 300 -- 5 minutes in seconds
local lastUsed = 0
local combatLeaveMessages = { "#cl", "#leavecombat" }

-- Check if the chat command is for leaving combat
local function OnChatMsg(msg, _, _, _, isEmote)
  for _, message in pairs(combatLeaveMessages) do
    if msg == message and not isEmote then
      local currentTime = GetTime()
      
      -- Check for cooldown
      if currentTime - lastUsed < cooldown then
        SendChatMessage("You cannot use this command for another ".. (cooldown - (currentTime - lastUsed)) .." seconds.", CHAT_SAY_PARTY)
        return
      end
      
      -- Hide target frame
      Eluna.UnitFrame("target").Hide()
      
      -- Stop auto-attacks (optional)
      Eluna.UnitAttack("player", "stop")
      
      -- Stun the player for 3 seconds
      Eluna.UnitAffect("player", "stun", 3)
      
      -- Update last used time
      lastUsed = currentTime
      
      -- Exit the loop after finding a match
      break
    end
  end
end


RegisterPlayerEvent(42, OnChatMsg)

print("Combat leaver #cl loaded!") --for console debugging
