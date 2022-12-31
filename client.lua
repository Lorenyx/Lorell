-- client.lua
---------------
-- Client implementation of Lorell
local completion = require "cc.completion"
local inifile = require "lib.inifile"

-- file version
local config = inifile.parse("lorell.ini")
local client_version = "v0.1.0"
-- Assume token is there
local secret = fs.open(config.lorell.token, "r").readAll()
local MASTER_NODE = 0 -- location of server

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


----------------------
-- Client functions --
----------------------
function pay(wallet_to, value)
    local content = {
        action = "pay",
        wallet_from = config.lorell.wallet,
        wallet_to = wallet_to,
        value = value
    }
    return send(content)
end -- function pay()

function ack_pay(resp)
    print("Sent $"..resp.value.." to "..resp.wallet_to)
end -- function reply_pay

function balance()
    local content = {
        action = "balance",
        wallet = config.lorell.wallet
    }
    return send(content)
end -- function balance

function ack_balance(resp)
    print("Balance: $"..resp.balance)
end -- function ack_balance

function deposit(resp)
    print("Received $"..resp.value.." from "..resp.wallet_from)
end -- function deposit

function withdraw(resp)
    print(resp.wallet_to.." withdrew $"..resp.value)
end -- function deposit

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
-- Should not be called once loop starts to 
function send_and_recv(data, ok)
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
end -- function send_and_recv(data)

--------------------------
-- Rednet I/O functions --
--------------------------
function send(content)
    -- start header
    content.flag = "SYN"
    content.src = os.computerID()
    content.dst = rednet.lookup("LORELL", "MASTER") or MASTER_NODE
    content.secret = secret
    -- end header
    local msg = textutils.serialize(content)
    local resp = rednet.send(content.dst, msg, config.rednet.protocol)
    if not resp then
        printError("[-]Err: msg not sent")
        return nil
    end -- if not resp
    return resp
end -- function send()

function recv(timeout)
    local srcId, msg, _ = rednet.receive(config.rednet.protocol, timeout or config.rednet.timeout)
    if not srcId then
        return nil
    else 
        return textutils.unserialize(msg) 
    end -- if not srcId
end -- function recv()

--------------------
-- Util functions --
--------------------

function startswith(s, pattern)
    return s:sub(0, #pattern) == pattern
end -- function startswith

function motd()
    local t = os.time("local") - 6
    clear_term()
    if t < 6 then
        print("Welcome, "..config.lorell.wallet)
    elseif t < 12 then
        print("Good morning, "..config.lorell.wallet)
    elseif t < 18 then
        print("Good afternoon, "..config.lorell.wallet)
    elseif t < 24 then
        print("Good evening, "..config.lorell.wallet)
    end -- if t < N
end -- function motd 

function check_version(first_check)
    if first_check then
        print("Checking version...")
    end -- if first_check
    local content = {
        action = "version",
        version = client_version
    }
    local resp = send_and_recv(content)
    if not resp then
        return nil
    elseif resp.out_of_date then
        io.open(config.lorell.update, "w")
            :write("TRUE") -- ensures file is created
            :close()
        printError("Update available!")
        printError("Rebooting system!")
        textutils.slowPrint("In 3... 2... 1...", 6)
        os.reboot()
    end -- resp.out_dated
end -- function check_version

function fill_choices()
    local content = {
        action = "query/wallets"
    }
    local resp = send_and_recv(content)
    if not resp then
        return nil
    else
        for k, v in pairs(resp.wallets) do
            table.insert(choices, "pay "..v)
        end -- for k in pairs
    end -- if not resp
end -- function fill_choices


function keyboard_listener()
    while true do
        write(client_version.."> ")
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
end -- funciton keyboard_listener

function network_listener()
    while true do
        local resp = recv()
        if not resp then
             -- Skip response
        elseif "ACK" == resp.flag then
            if "pay" == resp.action then
                ack_pay(resp)
            elseif "balance" == resp.action then
                ack_balance(resp)
            end -- if "" == resp.action
        elseif "SYN" == resp.flag then
            if "deposit" == resp.action then
                deposit(resp)
            elseif "withdraw" == resp.action then
                withdraw(resp)
            end -- if "" == resp.action
        elseif "ERR" == resp.flag then
            printError("[-]Err: "..resp.reason)
        end  -- if not resp
    end -- while true
end -- function network_listener

-------------------------
-- Main Execution Loop --
-------------------------
function init()
    peripheral.find("modem", rednet.open)
    MASTER_NODE = rednet.lookup(config.rednet.protocol, "MASTER")
    check_version()
    fill_choices()
    motd()
    parallel.waitForAny(network_listener, keyboard_listener)
end -- function init

init()