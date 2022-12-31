-- client.lua / lorell.lua
---------------
-- Client implementation of Lorell
local completion = require "cc.completion"
local config = require "config"
config.client_version = "v0.0.8"
-- USERNAME --
local my_wallet = "TESTUSER"
-- Assume token is there
local secret = fs.open(config._TOKEN, "r").readAll()

local choices = { "help", "clear" }
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

function clear_term()
    term.clear()
    term.setCursorPos(1,1)
end -- function clear
--------------
-- Requests --
--------------
function request(data, ok)
    send(data)
    local resp = recv(nil)
    if not resp then
        return nil
    elseif "ERR" == resp.status then
        printError("[-]Err: "..resp.reason)
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
        printError("[-]Err: msg not sent")
        return nil
    end -- if not resp
    return resp
end -- function send()

function recv(timeout)
    local srcId, msg, _ = rednet.receive(config.protocol, timeout or config.timeout)
    if not srcId then
        printError("[-]Err: No msg recv")
        return nil
    elseif srcId ~= MASTER then
        printError("[-]Err: ID mismatch - "..srcId)
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
    clear_term()
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

function check_version(first_check)
    if first_check then
        print("Checking version...")
    end -- if first_check
    local content = {
        action = "version",
        version = config.client_version
    }
    local resp = request(content)
    if not resp then
        return nil
    elseif resp.out_of_date then
        local f = fs.open(config._UPDATE, "w")
        f.write("TRUE") -- ensures file is created
        f.close()
        printError("Update available!")
        printError("Rebooting system!")
        textutils.slowPrint("In 3... 2... 1...")
        os.reboot()
    end -- resp.out_dated
end -- function check_version

function fill_choices()
    local content = {
        action = "query/wallets"
    }
    local resp = request(content)
    if not resp then
        return nil
    else
        for k, v in pairs(resp.wallets) do
            table.insert(choices, "pay "..v)
        end -- for k in pairs
    end -- if not resp
end -- function fill_choices

function init()
    check_version()
    fill_choices()
    motd()
end -- function init

-------------------------
-- Main Execution Loop --
-------------------------
init()
-- local history = {} -- optimization is the root of all evil
while true do
    write(config.client_version.."> ")
    local input = read(nil, history, function(text) return completion.choice(text, choices) end)
    -- pay function
    if startswith(input, "pay") then
        if not input:match(CMDS.pay.pattern) then
            printError("[-]Err: Incorrect command")
            print(CMDS.pay.help)
        else
            local dst = input:sub(#"sub "+1):match("%w+")
            local value = input:match("%d+")
            local resp = pay(dst, value)
        end -- if not input:match()
    -- balance function
    elseif startswith(input, "balance") then
        if not input:match(CMDS.balance.pattern) then
            printError("[-]Err: Incorrect command")
            print(CMDS.balance.help)
        else
            local resp = balance()
        end -- if not input:match()
    elseif startswith(input, "help") then
        show_help()
    elseif "clear" == input then
        clear_term()
    elseif startswith(input, "exit") then
        return 0
    else
        printError("[-]Err: Command not found")
        show_help()
    end -- if startswith()
    -- Check for updates
    check_version() --TODO: parallel check
end -- while true