-- database.lua
-----------------
-- Handles db operations on comptuer
----------------
local db = {}

--TODO: Uncomment in production
local log4cc = require "lib.log4cc" 
log4cc.config.file.enabled = true
log4cc.config.file.fileName = "/log/db.txt"

local DATA_DIR = "/data/"

local DEFAULT = {
    balance = 100
}
------------------------
-- Database functions --
------------------------

function db.create(wallet)
    if wallet_exists(wallet) then
        -- log4cc.error("Attempted CREATE for existing wallet ("..wallet..")")
        return nil
    end -- if wallet_exists
    log4cc.info("CREATE ("..wallet..")")
    return db.commit(wallet, {name=wallet, balance=DEFAULT.balance})
end -- function db.create

function db.select(wallet)
    if not wallet_exists(wallet) then
        return nil
    end -- if not wallet_exists
    return db.load(wallet)
end -- funcion db.select

function db.query(key)
    local wallets = db.load_all()
    if key == "all" or key == "*" then
        return wallets
    elseif key == "users" or key == "names" then
        return db.query_names(wallets)
    elseif key == "balances" then
        return db.query_balances(wallets)
    end -- if key == "str"
end -- function db.query

function db.query_names(wallets)
    for i=1, #wallets do
        wallets[i] = wallets[i]["name"]
    end -- for i=1, #wallets
    return wallets
end -- function db.query_wallets
--> Aliases
db.query_wallets = db.query_names

function db.query_balances(wallets)
    for i=1, #wallets do
        wallets[i] = wallets[i]["balance"]
    end -- for i=1, #wallets
    return wallets
end -- function db.query_balances

function db.update(wallet, key, value, quiet)
    if not wallet_exists(wallet) then
        return nil
    end -- if not wallet_exists
    local data = db.load(wallet)
    data[key] = value
    local _ = not quiet and log4cc.info("UPDATE ("..wallet..") with ("..key..","..value..")")
    return db.commit(wallet, data)
end -- function db.update

function db.deposit(wallet, value, quiet)
    if not wallet_exists(wallet) then
        return nil
    end -- if not wallet_exists
    local data = db.load(wallet)
    data.balance = data.balance + value
    local _ = not quiet and log4cc.info("DEPOSIT $"..value.." into ("..wallet..")")
    return db.commit(wallet, data)
end -- function db.deposit

function db.withdraw(wallet, value, quiet)
    if not wallet_exists(wallet) then
        return nil
    end -- if not wallet_exists
    local data = db.load(wallet)
    data.balance = data.balance - value
    local _ = not quiet and log4cc.info("WITHDRAW $"..value.." from ("..wallet..")")
    return db.commit(wallet, data)
end -- function db.deposit

function db.transfer(wallet_from, wallet_to, value, quiet)
    -- Check that wallets exists
    if not wallet_exists(wallet_from) or 
        not wallet_exists(wallet_to) then
        return nil
    end -- if not wallet_exists()
    -- Access both wallets
    local _ = not quiet and log4cc.info("TRANSFER $"..value.." from ("..wallet_from..") to ("..wallet_to..")")
    return db.deposit(wallet_to, value, true) and db.withdraw(wallet_from, value, true)
end -- function db.transfer


-- function db.delete(wallet)
--     return nil
-- end -- function db.delete

----------------------
-- Helper functions --
----------------------
function to_path(wallet)
    return DATA_DIR..wallet..".dat"
end -- function to_path

function to_wallet(path)
    return path:sub(1, -#".dat"-1)
end -- function to_wallet

function wallet_exists(wallet)
    local path = to_path(wallet)
    return fs.exists(path)
end -- function wallet_exists

------------------------------
-- CC: Restitched functions -- 
------------------------------

-- Open user with name wallet
function db.load(wallet)
    local path = to_path(wallet)
    local file = fs.open(path, "r")
    -- File does not exist
    if not file then
        return nil
    else
        local data = file.readAll()
        file.close()
        return textutils.unserialize(data)
    end -- if not file
end -- function db.unpack

function db.load_all()
    local wallets = fs.list(DATA_DIR)
    for i=1, #wallets do
        -- remove file type
        wallets[i] = db.load(to_wallet(wallets[i]))
    end -- for i=1, #wallets
    return wallets
end -- function load_all

-- Save the user with table of data
function db.commit(wallet, data)
    local path = to_path(wallet)
    local file = fs.open(path, "w")
    -- File does not exist
    if not file then
        return nil
    else
        local text = textutils.serialize(data)
        file.write(text)
        file.close()
        return true
    end -- if not file
end -- function db.pack

-- Module end
return db