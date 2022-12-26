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
    -- src_wallet = db.select(data.src)
    -- dst_wallet = db.select(data.dst)
    -- -- Check that enough funds
    -- if src_wallet.balance < data.amount then
end -- function pay

function balance(data)
    local wallet = db.select(data.wallet)
    if not wallet then
        return reply_err(data.src, "Wallet not found")
    end -- if not wallet
    local resp = {
        action = "reply.balance",
        wallet = data.wallet,
        amount = wallet.balance
    }
    reply_ok(data.src, data)
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
    local srcId, msg, _ = rednet.receive(DEFAULT.proto, timeout or DEFAULT.timeout)
    if not srcId then
        print("[-] Err: No msg recv")
        return nil
    end -- if srcId != DEFAULT.dst
    return textutils.unserialize(msg) 
end -- function recv()

---------------------------
-- Server Execution Loop --
---------------------------
peripheral.find("modem", rednet.open)
while true do
    local data = recv(nil) -- wait for msg
    if data.action == "pay" then
        pay(data)
    elseif data.action == "balance" then
        balance(data)
    end -- if data.action
end -- while true