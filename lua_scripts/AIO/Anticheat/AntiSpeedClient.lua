local AIO = AIO or require("AIO")
if AIO.AddAddon() then
	return
end
local AntiSpeed = CreateFrame("Frame", "AntiSpeed")
AntiSpeed.timer = 0
AntiSpeed.serverSpeeds = {}
AntiSpeed.failCount = 0

local function onAntiCheatMessage(self, event, prefix, message, channel, sender)
    if prefix == "AIO_AntiCheat_Speed" then
        local speeds = {strsplit(",", message)}
        for i = 0, 8 do
            self.serverSpeeds[i] = tonumber(speeds[i + 1])
        end
    end
end

AntiSpeed:RegisterEvent("CHAT_MSG_ADDON")
AntiSpeed:SetScript("OnEvent", onAntiCheatMessage)
AntiSpeed:SetScript("OnUpdate", function(self, elapsed)
    self.timer = self.timer + elapsed
    if self.timer > 1 then
        self.timer = 0
        
        if UnitOnTaxi("player") then
            self.failCount = 0
            return
        end
        
        local clientSpeed = GetUnitSpeed("player")
        
        if clientSpeed > 0 and next(self.serverSpeeds) then
            local matched = false
            local closestSpeed = nil
            local closestDiff = 999
            
            for i = 0, 8 do
                if self.serverSpeeds[i] then
                    local diff = math.abs(clientSpeed - self.serverSpeeds[i])
                    if diff < closestDiff then
                        closestDiff = diff
                        closestSpeed = self.serverSpeeds[i]
                    end
                    if diff < 0.05 then
                        matched = true
                        break
                    end
                end
            end
            
            if not matched then
                self.failCount = self.failCount + 1
                if self.failCount >= 3 then
					SendChatMessage(".AntiCheatAlert SpeedHack", "GUILD")
                    self.failCount = 0
                end
            else
                self.failCount = 0
            end
        end
    end
end)