-- client.lua / lorell.lua
---------------
-- Client implementation of Lorell
local completion = require "cc.completion"
local config = require "config"
-- USERNAME --
local my_wallet = "TESTUSER"
-- Assume token is there
local secret = fs.open(config._TOKEN, "r").readAll()

local choices = { "help" }
local CMDS = {
    pay = { 
        help = "Usage: pay <player> <value>",
        pattern = "pay %w+ %d+",
        
    },
    balance = {
        help = "Usage: balance",
        pattern = "balance"
    } 
}
-- Add all CMDS to choices
for k in pairs(CMDS) do
    table.insert(choices, k)
end
peripheral.find("modem", rednet.open)
MASTER = rednet.lookup(config.protocol, "MASTER") or 1

----------------------
-- Client functions --
----------------------
function pay(wallet_to, value)
    local content = {
        action = "pay",
        wallet_from = my_wallet,
        wallet_to = wallet_to,
        value = value
    }
    local resp = request(content)
    if not resp then
        return nil
    else
        print("Sent $"..resp.value.." to "..resp.wallet_to)
        return resp
    end -- if resp
end -- function pay()

function balance()
    local content = {
        action = "balance",
        wallet = my_wallet
    }
    local resp = request(content)
    if not resp then
        return nil
    else
        print("Balance: $"..resp.balance)
        return resp
    end -- function balance
end -- function balance

function show_help()
    for key in pairs(CMDS) do
        print(CMDS[key].help)
    end -- for i,#CMDS
end -- function show_help()

--------------
-- Requests --
--------------
function request(data, ok)
    send(data)
    local resp = recv(nil)
    if not resp then
        return nil
    elseif "ERR" == resp.status then
        print("[-]Err: "..resp.reason)
        return nil
    else
        return resp
    end 
end -- function request(data)

--------------------------
-- Rednet I/O functions --
--------------------------
function send(content)
    -- start header
    content.flag = "SYN"
    content.src = os.computerID()
    content.dst = rednet.lookup("LORELL", "MASTER") or 1
    content.secret = secret
    -- end header
    local msg = textutils.serialize(content)
    local resp = rednet.send(MASTER, msg, config.protocol)
    if not resp then
        print("[-]Err: msg not sent")
        return nil
    end -- if not resp
    return resp
end -- function send()

function recv(timeout)
    local srcId, msg, _ = rednet.receive(config.protocol, timeout or config.timeout)
    if not srcId then
        print("[-]Err: No msg recv")
        return nil
    elseif srcId ~= MASTER then
        print("[-]Err: ID mismatch - "..srcId)
        return nil
    end -- if srcId != MASTER
    return textutils.unserialize(msg) 
end -- function recv()

--------------------
-- Util functions --
--------------------

function startswith(s, pattern)
    return s:sub(0, #pattern) == pattern
end -- function startswith

function motd()
    local t = os.time("local")
    if t < 6 then
        print("Welcome, "..my_wallet)
    elseif t < 12 then
        print("Good morning, "..my_wallet)
    elseif t < 18 then
        print("Good afternoon, "..my_wallet)
    elseif t < 24 then
        print("Good evening, "..my_wallet)
    end -- if t < N
end -- function motd 

-------------------------
-- Main Execution Loop --
-------------------------
motd()
while true do
    write(config.client_version.."> ")
    local input = read(nil, nil, function(text) return completion.choice(text, choices) end)
    -- pay function
    if startswith(input, "pay") then
        if not input:match(CMDS.pay.pattern) then
            print("[-]Err: Incorrect command")
            print(CMDS.pay.help)
        else
            local dst = input:sub(#"sub "+1):match("%w+")
            local value = input:match("%d+")
            local resp = pay(dst, value)
        end -- if not input:match()
    -- balance function
    elseif startswith(input, "balance") then
        if not input:match(CMDS.balance.pattern) then
            print("[-]Err: Incorrect command")
            print(CMDS.balance.help)
        else
            local resp = balance()
        end -- if not input:match()
    elseif startswith(input, "help") then
        show_help()
    elseif startswith(input, "exit") then
        return 0
    else
        print("[-]Err: Command not found")
        show_help()
    end -- if startswith()
end -- while true