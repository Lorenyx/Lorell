-- client.lua
---------------
-- Client implementation of Lorell
-- On ATM machines should be renamed as "startup.lua"

local completion = require "cc.completion"
local choices = { "pay", "balance" }
-- USERNAME --
local SRC = "TESTUSER"
local PROTO = "LORELL"
local HOST = rednet.lookup(PROTO, "MASTER") or 1
local DEFAULT_TIMEOUT = 30

----------------------
-- Client functions --
----------------------
function pay(dst, amount)
    data = {
        src = SRC,
        dst = dst,
        action = "pay",
        amount = amount
    }
    return send(data)
end -- function pay()

function balance()
    data = {
        src = SRC,
        action = "balance",
    }
    send(data)
    resp = recv(nil)
    return resp.balance or nil
end -- function balance

--------------------------
-- Rednet I/O functions --
--------------------------
function send(data)
    msg = textutils.serialize(data)
    resp = rednet.send(HOST, msg, PROTO)
    if not resp then
        print("[-] Err: msg not sent")
        return nil
    end -- if not resp
    return resp
end -- function send()

function recv(timeout)
    local srcId, msg, _ = rednet.recveive(PROTO, timeout or DEFAULT_TIMEOUT)
    if not srcId then
        print("[-] Err: No msg recv")
        return nil
    elseif srcId != HOST then
        print("[-] Err: ID mismatch - "..srcId)
        return nil
    end -- if srcId != HOST
    return textutils.unserialize(msg) 
end -- function recv()

-------------------------
-- Main Execution Loop --
-------------------------
peripheral.find("modem", rednet.open)
-- Loop
while true do
    input = read(nil, nil, function(text) return completion.choice(text, choices) end, "$ ")
    -- pay function
    if input:sub(0, #"pay") == "pay" then
        

end -- while true

