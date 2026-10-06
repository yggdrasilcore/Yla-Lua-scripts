-- Multistate: global-only script (server event 14 fires in the world state).
if GetStateMapId() ~= -1 then return end

local function onStartup(event)
	RunCommand("worldstate sunsreach counter 0 10000")
	RunCommand("worldstate sunsreach counter 1 10000")
	RunCommand("worldstate sunsreach counter 2 10000")
	RunCommand("worldstate sunsreach counter 3 10000")
	RunCommand("worldstate sunsreach counter 4 10000")
	RunCommand("worldstate sunsreach counter 5 10000")
	RunCommand("worldstate sunsreach counter 6 10000")
	RunCommand("worldstate sunsreach counter 7 10000")
	RunCommand("worldstate sunsreach counter 8 10000")
	RunCommand("worldstate sunsreach counter 9 10000")
	RunCommand("worldstate sunsreach gatecounter 0 10000")
	RunCommand("worldstate sunsreach gatecounter 1 10000")
	RunCommand("worldstate sunsreach gatecounter 2 10000")
	RunCommand("worldstate sunsreach gate 3")
	RunCommand("worldstate sunsreach phase 3")
	RunCommand("worldstate sunsreach subphase 15")
end

RegisterServerEvent(14, onStartup)