-- server.lua
--------------
-- Receives communications from client and responds
--------------
local inifile = require "lib.inifile"
local config = inifile.parse("lorell.ini")
local db = require "database"

server_version = "v0.1.4"
client_version = "v0.0.9"

----------------------
-- Server functions --
----------------------
function pay(data)
    -- Check that has permissions
    if not db.authorize(data.wallet_from, data.secret) then
        return reply_err(data.src, "Not authorized!")
    end
    -- Access wallets
    local sender = db.select(data.wallet_from)
    local receiver = db.select(data.wallet_to)
    local value = tonumber(data.value)
    -- Check that value is >1
    if value < 1 then
        return reply_err(data.src, "Value is negative!")
    -- Check that enough funds
    elseif not sender then
        return reply_err(data.src, "Sender wallet not found!")
    -- Check receiver exists
    elseif not receiver then
        return reply_err(data.src, "Receiver wallet not found!")
    -- Check that sender has enough funds
    elseif sender.balance < value then
        return reply_err(data.src, "Not enough funds!")
    -- Check not sending funds to self
    elseif data.wallet_from == data.wallet_to then
        return reply_err(data.src, "Cannot send funds to self!")
    end 
    -- Update funds for users
    db.transfer(data.wallet_from, data.wallet_to, value)
    -- send response
    local content = {
        action = data.action,
        value = value,
        wallet_to = data.wallet_to,
        balance = debit
    }
    return reply_ok(data.src, content)
end -- function pay

function balance(data)
    -- Check if authorized
    if not db.authorize(data.wallet, data.secret) then
        return reply_err(data.src, "Not authorized!")
    end
    -- Access wallets
    local wallet = db.select(data.wallet)
    if not wallet then
        return reply_err(data.src, "Wallet not found!")
    end -- if not wallet
    local content = {
        type = "ACK",
        action = "balance",
        balance = wallet.balance
    }
    return reply_ok(data.src, content)
end -- function balance

function version(data)
    local content = {
        action = "version",
        out_of_date = (data.version ~= client_version)
    }
    return reply_ok(data.src, content)
end -- function version

function query(data)
    local content = {}
    content.action = data.action
    if "query/version" == data.action then
        content.version = client_version
    elseif "query/names" == data.action then
        content.names = db.query_names()
    elseif "query/wallets" == data.action then
        content.wallets = db.query_wallets()
    else
        return reply_err(data.src, "Query not implemented!")
    end -- if data.action ==
    return reply_ok(data.src, content)
end -- function query
---------------
-- Responses -- 
---------------
function reply_ok(dst, content)
    content.flag = "ACK"
    content.status = "OK"
    return send(dst, content)
end -- function reply()

function reply_err(dst, reason)
    local data = {
        flag = "FIN",
        status = "ERR",
        reason = reason
    }
    return send(dst, data)
end -- function error()

--------------------------
-- Rednet I/O functions --
--------------------------
function send(dstId, data)
    -- Append header
    data.src = os.computerID()
    data.dst = dstID
    -- end header
    local msg = textutils.serialize(data)
    local resp = rednet.send(dstId, msg, config.rednet.protocol)
    if not resp then
        print("[-] Err: msg not sent")
        return nil
    end -- if not resp
    return resp
end -- function send()

function recv(timeout)
    local srcId, msg, _ = rednet.receive(config.rednet.protocol)
    if not srcId then
        print("[-] Err: No msg recv")
        return nil
    end -- if not srcId
    return textutils.unserialize(msg) 
end -- function recv()

--------------------
-- Util functions --
--------------------
function startswith(s, pattern)
    return s:sub(0, #pattern) == pattern
end -- function startswith

---------------------------
-- Server Execution Loop --
---------------------------
peripheral.find("modem", rednet.open)
rednet.host(config.rednet.protocol, "MASTER")
print("Running "..server_version)

while true do
    local data = recv(nil) -- wait for msg
    if not data then
        -- do nothing
    elseif startswith(data.action, "query") then
        query(data)
    elseif "pay" == data.action then
        pay(data)
    elseif "balance" == data.action then
        balance(data)
    elseif "version" == data.action then
        version(data)
    end -- if data.action
end -- while true