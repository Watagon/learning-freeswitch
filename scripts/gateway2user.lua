--[[
  bridgeing call from gateway to user
]]

local function plogln(level, msgs)
    freeswitch.consoleLog(level, msgs .. "\n")
end

session:execute("bridge", "user/1001")

plogln("NOTICE", "gateway2user.lua end")

