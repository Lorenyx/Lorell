-- db.lua
-----------------
-- Handles db operations on comptuer
----------------
local db = {}

-- local log4cc = require "lib.log4cc" --TODO: Uncomment in production

local DATA_DIR = "/data/"

-- Module start

function db.create(wallet)
    return nil
end -- function db.create

function db.select(wallet)
    return nil
end -- funcion db.select

function db.update(wallet, key, value)
    return nil
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