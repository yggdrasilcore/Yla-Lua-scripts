local AIO = AIO or require("AIO")
if AIO.AddAddon() then
   return
end

local worldframe = CreateFrame("Frame")
worldframe:RegisterEvent("CHAT_MSG_ADDON")
worldframe:SetScript("OnEvent", function(self, event, prefix, message, channel, sender)
	if prefix == "NewCharacterJoinWorld" then
		SlashCmdList["JOIN"]("world")
	end
end)

local originalSendChatMessage = SendChatMessage
SendChatMessage = function(msg, chatType, language, channel)
	if chatType == "CHANNEL" and channel == GetChannelName("world") and UnitLevel("player") < 10 then
        print("You must be at least level 10 to chat in this channel.")
		return
	end
	originalSendChatMessage(msg, chatType, language, channel)
end