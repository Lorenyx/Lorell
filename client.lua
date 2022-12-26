-- client.lua
---------------
-- Client implementation of Lorell
-- On ATM machines should be renamed as "startup.lua"

-- USERNAME --
local my_wallet = "TESTUSER"

local completion = require "cc.completion"
local choices = { "help", "pay", "balance", "exit" }
local CMDS = {
    pay = { 
        help = "Usage: pay <player> <value>",
        pattern = "pay %w+ %d+"
    },
    balance = {
        help = "Usage: balance",
        pattern = "balance"
    } 
}

local DEFAULT = {
    dst =  rednet.lookup("LORELL", "MASTER") or 1,
    proto = "LORELL",
    timeout = 10,
    version = "v0.0.4"
}

----------------------
-- Client functions --
----------------------
function pay(wallet_to, value)
    local data = {
        action = "pay",
        wallet_from = my_wallet,
        wallet_to = wallet_to,
        value = value
    }
    send(data)
    local resp = recv(nil)
    if not resp then
        return nil
    elseif resp.status ~= 0 then
        print("[-] Err: "..resp.reason)
        return nil
    else
        print("Sent $"..resp.value.." to "..resp.wallet_to)
        return resp
    end -- if resp.status ~= 0
end -- function pay()

function balance()
    local data = {
        action = "balance",
        wallet = my_wallet
    }
    send(data)
    local resp = recv(nil)
    if not resp then
        return nil
    elseif resp.status ~= 0 then
        print("[-] Err: "..resp.reason)
        return nil
    else
        print("Balance: $"..resp.balance)
        return resp
    end -- if resp.status ~= 0
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
    local srcId, msg, _ = rednet.receive(DEFAULT.proto, timeout or DEFAULT.timeout)
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
    write(DEFAULT.version.."> ")
    local input = read(nil, nil, function(text) return completion.choice(text, choices) end)
    -- pay function
    if startswith(input, "pay") then
        if not input:match(CMDS.pay.pattern) then
            print("[-] Err: Incorrect command")
            print(CMDS.pay.help)
        else
            local dst = input:sub(#"sub "+1):match("%w+")
            local value = input:match("%d+")
            local resp = pay(dst, value)
        end -- if not input:match()
    -- balance function
    elseif startswith(input, "balance") then
        if not input:match(CMDS.balance.pattern) then
            print("[-] Err: Incorrect command")
            print(CMDS.balance.help)
        else
            local resp = balance()
        end -- if not input:match()
    elseif startswith(input, "help") then
        show_help()
    elseif startswith(input, "exit") then
        return 0
    else
        print("[-] Err: Command not found")
        show_help()
    end -- if startswith()
end -- while true