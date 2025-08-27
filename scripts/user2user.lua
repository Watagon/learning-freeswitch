--[[
  bridging call to 1001
--]]

local function plogln(level, msgs)
    freeswitch.consoleLog(level, msgs .. "\n")
end

plogln("NOTICE", "user2user_bridge.lua start")

session:execute("bridge", "user/1001")

plogln("NOTICE", "user2user_bridge.lua end")

