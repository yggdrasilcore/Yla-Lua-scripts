if GetStateMapId() ~= -1 then return end

local function OnWhisper(event, player, message, type, lang, receiver)
    if message == "" or message:match("^%s*$") then
        return false
    end
end

RegisterPlayerEvent(19, OnWhisper)  -- 19 is PLAYER_EVENT_ON_WHISPER