local AIO = AIO or require("AIO")
if AIO.AddAddon() then
	return
end

function ProcessGroupMembers()
	if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
		return
	end
	
	local inRaid = GetNumRaidMembers() > 0
	local groupType = inRaid and "raid" or "party"
	local numMembers = inRaid and GetNumRaidMembers() or GetNumPartyMembers()
	local nameList = ""
	local validBots = {}
	if ShadowsValidBots and ShadowsValidBots ~= "" then
		for botName in string.gmatch(ShadowsValidBots, "([^,]+)") do
			validBots[string.trim(botName)] = true
		end
	end
	
	for i = 1, numMembers do
		local unitID = groupType .. i
		local unitName = UnitName(unitID)
		if UnitExists(unitID) and not UnitIsUnit(unitID, "player") and not UnitIsConnected(unitID) and validBots[unitName] then
			if nameList == "" then
				nameList = unitName
			else
				nameList = nameList .. ", " .. unitName
			end
		end
	end
	
	if nameList == "" then return end
	
	StaticPopupDialogs["SHADOWS_LOGIN_DIALOG"] = {
		text = " \nWe see you have relogged in a shadows group.\n \n \nDo you want to log in your shadows?\n \n \nAvailable shadows: \n \n" .. nameList.."\n ",
		button1 = "Yes",
		button2 = "No",
		OnAccept = function()
			SendChatMessage(".attemptaddbot "..nameList, "GUILD")
			SendAddonMessage("ShadowsLoginShowBar", "SHOW_BAR", "GUILD")
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	
	StaticPopup_Show("SHADOWS_LOGIN_DIALOG")
end

ShadowsValidBots = ""

local function onShadowsAddonMessage(self, event, prefix, message, channel, sender)
	if prefix == "Shadows" then
		ShadowsValidBots = message
		ProcessGroupMembers()
	end
end

local shadowsaddon = CreateFrame("Frame")
shadowsaddon:RegisterEvent("CHAT_MSG_ADDON")
shadowsaddon:SetScript("OnEvent", onShadowsAddonMessage)

function QueryServerForValidBots()
	if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
		return
	end
	SendChatMessage(".shadowslogin", "GUILD")
end

QueryServerForValidBots()