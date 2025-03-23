local AIO = AIO or require("AIO")
if AIO.AddAddon() then
  return
end

function PrintGroupMembers()
   if not IsInGroup() then
       return
   end
   
   local groupType = IsInRaid() and "raid" or "party"
   local numMembers = GetNumGroupMembers()
   local nameList = ""
   
   for i = 1, numMembers do
       local unitID = groupType .. i
       if UnitExists(unitID) and not UnitIsUnit(unitID, "player") and not UnitIsConnected(unitID) then
		   if nameList == "" then
				nameList = nameList.."".. UnitName(unitID)
		   else
				nameList = nameList .. ", " .. UnitName(unitID)
			end
       end
   end
   
   StaticPopupDialogs["SHADOWS_LOGIN_DIALOG"] = {
       text = " \nWe see you have relogged in a shadows group.\n \n \nDo you want to log in your shadows?\n \n \nAvailable shadows: \n \n" .. nameList.."\n ",
       button1 = "Yes",
       button2 = "No",
       OnAccept = function()
           SendChatMessage(".attemptaddbot "..nameList, "GUILD")
       end,
       timeout = 0,
       whileDead = true,
       hideOnEscape = true,
       preferredIndex = 3,
   }
   
   StaticPopup_Show("SHADOWS_LOGIN_DIALOG")
end

local function onShadowsAddonMessage(self, event, prefix, message, channel, sender)
	if prefix == "Shadows" then
        if message and message:find("LOGINCHECK") then
			PrintGroupMembers()
		end
	end
end

local shadowsaddon = CreateFrame("Frame")
shadowsaddon:RegisterEvent("CHAT_MSG_ADDON")
shadowsaddon:SetScript("OnEvent", onShadowsAddonMessage)

SendChatMessage(".shadowslogin", "GUILD")