-- client.lua
---------------
-- Client implementation of Lorell
-- On ATM machines should be renamed as "startup.lua"

local completion = require "cc.completion"
local choices = { "/help", "/pay", "/balance" }
local CMDS = {
    pay = { 
        help = "Usage: /pay <player> <amount>",
        pattern = "/pay %w+ %d+"
    },
    balance = {
        help = "Usage: /balance",
        pattern = "/balance"
    } 
}
-- USERNAME --
local my_wallet = "TESTUSER"

local DEFAULT = {
    dst =  rednet.lookup(PROTO, "MASTER") or 1
    proto = "LORELL"
    timeout = 30,
}

----------------------
-- Client functions --
----------------------
function pay(wallet_to, amount)
    data = {
        action = "pay",
        wallet_from = my_wallet
        wallet_to = wallet_to
        amount = amount
    }
    return send(data)
end -- function pay()

function balance()
    data = {
        action = "balance",
        wallet = my_wallet
    }
    send(data)
    resp = recv(nil)
    return resp.balance or nil
end -- function balance

function show_help()
    for i,#CMDS do
        print(CMDS[i].help)
    end -- for i,#CMDS
end -- function show_help()

-------------------------
-- Main Execution Loop --
-------------------------
peripheral.find("modem", rednet.open)
-- Loop
while true do
    input = read(nil, nil, function(text) return completion.choice(text, choices) end, "$ ")
    -- pay function
    if startswith(input, "/pay") then
        if not input:match(CMDS.pay.pattern) then
            print("[-] Err: Incorrect command")
            print(CMDS.pay.help)
        else
            dst = input:match("%w+")
            amount = input:match("%d+")
            pay(dst, amount)
        end -- if not input:match
    -- balance function
    elseif startswith(input, "/balance") then
        if not input:match(CMDS.balance.pattern) then
            print("[-] Err: Incorrect command")
            print(CMDS.balance.help)
        else
            balance()
    elseif startswith(input, "/help") then
        show_help()
    else
        print("[-] Err: Command not found")
        show_help()
    end -- if startswith()
end -- while true

--------------------------
-- Rednet I/O functions --
--------------------------
function send(data)
    -- start header
    data.src = os.computerID()
    data.dst = dstID
    -- end header
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

--------------------
-- Util functions --
--------------------

function startswith(s, pattern)
    return s:sub(0, #pattern) == pattern
end -- function startswith