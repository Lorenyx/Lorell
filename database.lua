-- database.lua
-----------------
-- Handles db operations on comptuer
----------------
local db = {}

--TODO: Uncomment in production
-- local log4cc = require "lib.log4cc" 
-- log4cc.config.file.enabled = true
-- log4cc.config.file.fileName = "/log/db.txt"

local DATA_DIR = "/data/"

local DEFAULT_WALLET = { --TODO: Turn into function to return wallet
    balance=100
}

------------------------
-- Database functions --
------------------------

function db.create(wallet)
    if wallet_exists(wallet) then
        log4cc.error("Attempted CREATE for existing wallet ("..wallet..")")
        return nil
    end -- if wallet_exists
    log4cc.info("CREATE ("..wallet..")")
    return db.commit(wallet, DEFAULT_WALLET)
end -- function db.create

function db.select(wallet)
    if not wallet_exists(wallet) then
        return nil
    end -- if not wallet_exists
    return db.load(wallet)
end -- funcion db.select

function db.update(wallet, key, value)
    if not wallet_exists(wallet) then
        log4cc.error("Attempted UPDATE for non-existing wallet ("..wallet..") with ("..key..","..value..")")
        return nil
    end -- if not wallet_exists
    data = db.load(wallet)
    data[key] = value
    log4cc.info("UPDATE ("..wallet..") with ("..key..","..value..")")
    return db.commit(wallet, data)
end -- function db.update

-- function db.delete(wallet)
--     return nil
-- end -- function db.delete

----------------------
-- Helper functions --
----------------------
function to_path(wallet)
    return DATA_DIR..wallet..".dat"
end -- function to_path

function wallet_exists(wallet)
    path = to_path(wallet)
    return fs.exists(path)
end -- function wallet_exists

------------------------------
-- CC: Restitched functions -- 
------------------------------

-- Open user with name wallet
function db.load(wallet)
    path = to_path(wallet)
    file = fs.open(path, "r")
    -- File does not exist
    if not file then
        return nil
    else
        data = file.readAll()
        file.close()
        return textutils.unserialize(data)
    end -- if not file
end -- function db.unpack


-- Save the user with table of data
function db.commit(wallet, data)
    path = to_path(wallet)
    file = fs.open(path, "w")
    -- File does not exist
    if not file then
        return nil
    else
        text = textutils.serialize(data)
        file.write(text)
        file.close()
        return true
    end -- if not file
end -- function db.pack

-- Module end
return db