local AIO = AIO or require("AIO")
if AIO.AddAddon() then
   return
end

local TwiggyHandlers = AIO.AddHandlers("TwiggyFix", {})

local function ApplyTwiggyTooltip(tooltip)
   tooltip:ClearLines()
   tooltip:AddLine("|cffffffffTwiggy|r")
   tooltip:AddLine("|cffffffffInstant|r")
   tooltip:AddLine("Right Click to summon and dismiss")
   tooltip:AddLine("Twiggy, your personal branch and")
   tooltip:AddLine("assistant of Yggdrasil.")
   tooltip:Show()
end

local function ModifyTwiggyTooltip(tooltip)
   local name, _, spellId = GameTooltip:GetSpell()
   if spellId == 40405 then
       ApplyTwiggyTooltip(tooltip)
   end
end

-- Hook the spell link insertion
local oldChatEdit_InsertLink = ChatEdit_InsertLink
function ChatEdit_InsertLink(text, ...)
   if text and text:find("spell:40405") then
       text = text:gsub("Lucky", "Twiggy")
   end
   return oldChatEdit_InsertLink(text, ...)
end

function TwiggyHandlers.Initialize(player)
   GameTooltip:HookScript("OnTooltipSetSpell", ModifyTwiggyTooltip)
   
   -- Hook clicked links OK
   local oldSetItemRef = SetItemRef
   function SetItemRef(link, text, button, chatFrame)
       oldSetItemRef(link, text, button, chatFrame)
       if link:find("spell:40405") then
           ApplyTwiggyTooltip(ItemRefTooltip)
       end
   end
   
   local function filterFunc(_, _, msg, ...)
       if msg and msg:find("spell:40405") then
           local newMsg = msg:gsub("Lucky", "Twiggy")
           return false, newMsg, ...
       end
       return false
   end

   local oldSendChatMessage = SendChatMessage
   function SendChatMessage(msg, ...)
       if msg and msg:find("spell:40405") then
           msg = msg:gsub("Lucky", "Twiggy")
       end
       oldSendChatMessage(msg, ...)
   end

   -- Register all chat filters
   ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", filterFunc)
   ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", filterFunc)
   ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", filterFunc)
   ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", filterFunc)
   ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", filterFunc)
   ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", filterFunc)
end