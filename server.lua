-- server.lua
--------------
-- Receives communications from client and responds
--------------

local DEFAULT = {
    dst =  rednet.lookup("LORELL", "MASTER") or 1,
    proto = "LORELL",
    timeout = 30,
}
--TODO: Uncomment in production
-- local log4cc = require "lib.log4cc" 
-- log4cc.config.file.enabled = true
-- log4cc.config.file.fileName = "/log/server.txt"

local db = require "database"

----------------------
-- Server functions --
----------------------
function pay(data)
    local sender = db.select(data.wallet_from)
    local amount = data.amount
    -- Check that enough funds
    if not sender then
        return reply_err(data.src, "Sender wallet not found!")
    elseif sender.balance < amount then
        return reply_err(data.src, "Not enough funds!")
    end -- if sender.balance < data.amount
    -- Check receiver exists
    local receiver = db.select(data.wallet_to)
    if not receiver then
        return reply_err(data.src, "Receiver wallet not found!")
    end
    -- Update funds for users
    local debit = sender.balance - amount
    db.update(data.wallet_from, "amount", debit)
    local credit = receiver.balance + amount
    db.update(data.wallet_to, "amount", credit)
    -- send response
    local resp = {
        action = "reply.pay",
        new_amount = debit
    }
    return reply_ok(data.src, resp)
end -- function pay

function balance(data)
    local wallet = db.select(data.wallet)
    if not wallet then
        return reply_err(data.src, "Wallet not found!")
    end -- if not wallet
    local resp = {
        action = "reply.balance",
        amount = wallet.balance
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
while true do
    local data = recv(nil) -- wait for msg
    print('Received: '..data.action)
    if not data then
        -- do nothing
    elseif data.action == "pay" then
        pay(data)
    elseif data.action == "balance" then
        balance(data)
    end -- if data.action
end -- while true