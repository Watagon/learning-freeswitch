--[[
  receive and send DTMF digits
]]

local to_number = "1000"
-- local dtmf_digits = "0123456789"

if not session:ready() then return end

session:answer()
session:execute("spandsp_start_dtmf")
session:sleep(1000)

local function plogln(level, msgs)
    freeswitch.consoleLog(level, msgs .. "\n")
end

local received = session:getDigits(10, '', 600)
plogln("INFO", "Got digits: " .. received)
session:execute("start_dtmf_generate")
local sending = string.reverse(received)
session:execute("send_dtmf", sending .. "@80")
session:sleep(5000)

plogln("NOTICE", "user2user.lua end")

