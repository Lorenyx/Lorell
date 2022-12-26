-- client.lua
---------------
-- Client implementation of Lorell
-- On ATM machines should be renamed as "startup.lua"

local completion = require "cc.completion"
local choices = { "help", "pay", "balance" }
local CMDS = {
    pay = { 
        help = "Usage: pay <player> <amount>",
        pattern = "pay %w+ %d+"
    },
    balance = {
        help = "Usage: balance",
        pattern = "balance"
    } 
}
-- USERNAME --
local my_wallet = "TESTUSER"

local DEFAULT = {
    dst =  rednet.lookup("LORELL", "MASTER") or 1,
    proto = "LORELL",
    timeout = 30,
}

----------------------
-- Client functions --
----------------------
function pay(wallet_to, amount)
    local data = {
        action = "pay",
        wallet_from = my_wallet,
        wallet_to = wallet_to,
        amount = amount
    }
    return send(data)
end -- function pay()

function balance()
    local data = {
        action = "balance",
        wallet = my_wallet
    }
    send(data)
    local resp = recv(nil)
    return resp.balance or nil
end -- function balance

function show_help()
    for key in pairs(CMDS) do
        print(CMDS[key].help)
    end -- for i,#CMDS
end -- function show_help()

--------------------------
-- Rednet I/O functions --
--------------------------
function send(data)
    -- start header
    data.src = os.computerID()
    data.dst = dstID
    -- end header
    local msg = textutils.serialize(data)
    local resp = rednet.send(DEFAULT.dst, msg, DEFAULT.proto)
    if not resp then
        print("[-] Err: msg not sent")
        return nil
    end -- if not resp
    return resp
end -- function send()

function recv(timeout)
    if not timeout:
        local srcId, msg, _ = rednet.receive(DEFAULT.proto)
    else
        local srcId, msg, _ = rednet.receive(DEFAULT.proto, timeout)
    end -- if not timeout
    if not srcId then
        print("[-] Err: No msg recv")
        return nil
    elseif srcId ~= DEFAULT.dst then
        print("[-] Err: ID mismatch - "..srcId)
        return nil
    end -- if srcId != DEFAULT.dst
    return textutils.unserialize(msg) 
end -- function recv()

--------------------
-- Util functions --
--------------------

function startswith(s, pattern)
    return s:sub(0, #pattern) == pattern
end -- function startswith

-------------------------
-- Main Execution Loop --
-------------------------
peripheral.find("modem", rednet.open)
-- Loop
while true do
    write("> ")
    local input = read(nil, nil, function(text) return completion.choice(text, choices) end)
    -- pay function
    if startswith(input, "pay") then
        if not input:match(CMDS.pay.pattern) then
            print("[-] Err: Incorrect command")
            print(CMDS.pay.help)
        else
            local dst = input:match("%w+")
            local amount = input:match("%d+")
            pay(dst, amount)
        end -- if not input:match()
    -- balance function
    elseif startswith(input, "balance") then
        if not input:match(CMDS.balance.pattern) then
            print("[-] Err: Incorrect command")
            print(CMDS.balance.help)
        else
            balance()
        end -- if not input:match()
    elseif startswith(input, "help") then
        show_help()
    elseif startswith(input, "exit") then
        exit()
    else
        print("[-] Err: Command not found")
        show_help()
    end -- if startswith()
end -- while true