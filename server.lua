-- server.lua
--------------
-- Receives communications from client and responds
--------------

local DEFAULT = {
    dst =  rednet.lookup("LORELL", "MASTER") or 1,
    proto = "LORELL",
    timeout = 30,
    version = "v0.0.8"
}

-- secret.lua
-------------
--IMPORTANT: Remove any test users before pushing
local users = {
    -- Add users here
}

function authorize(name, token)
    return users[name] == token
end -- function authorize()


--TODO: Uncomment in production
-- local log4cc = require "lib.log4cc" 
-- log4cc.config.file.enabled = true
-- log4cc.config.file.fileName = "/log/server.txt"

local db = require "database"
----------------------
-- Server functions --
----------------------
function pay(data)
    -- Check that has permissions
    if not authorize(data.wallet_from, data.secret) then
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
    resp = {
        action = "reply.pay",
        value = value,
        wallet_to = data.wallet_to,
        balance = debit
    }
    return reply_ok(data.src, resp)
end -- function pay

function balance(data)
    -- Check if authorized
    if not authorize(data.wallet, data.secret) then
        return reply_err(data.src, "Not authorized!")
    end
    -- Access wallets
    local wallet = db.select(data.wallet)
    if not wallet then
        return reply_err(data.src, "Wallet not found!")
    end -- if not wallet
    local resp = {
        action = "reply.balance",
        balance = wallet.balance
    }
    return reply_ok(data.src, resp)
end -- function balance

---------------
-- Responses -- 
---------------
function reply_ok(dst, data)
    data.status = 0
    return send(dst, data)
end -- function reply()

function reply_err(dst, reason)
    local data = {
        status = 1,
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
    if not data.status then
        data.status = 0
    end -- if not data.status
    -- end header
    local msg = textutils.serialize(data)
    local resp = rednet.send(dstId, msg, DEFAULT.proto)
    if not resp then
        print("[-] Err: msg not sent")
        return nil
    end -- if not resp
    return resp
end -- function send()

function recv(timeout)
    local srcId, msg, _ = rednet.receive(DEFAULT.proto)
    if not srcId then
        print("[-] Err: No msg recv")
        return nil
    end -- if not srcId
    return textutils.unserialize(msg) 
end -- function recv()

---------------------------
-- Server Execution Loop --
---------------------------
peripheral.find("modem", rednet.open)
print("Running "..DEFAULT.version)
while true do
    local data = recv(nil) -- wait for msg
    -- print('Received: '..data.action)
    if not data then
        -- do nothing
    elseif data.action == "pay" then
        pay(data)
    elseif data.action == "balance" then
        balance(data)
    end -- if data.action
end -- while true