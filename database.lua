-- db.lua
-----------------
-- Handles db operations on comptuer
----------------
local db = {}

db.DATA_DIR = "/data/"

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

------------------------------
-- CC: Restitched functions -- 
------------------------------

function db.unpack(wallet)
    path = db.DATA_DIR .. wallet .. ".dat"
    file = fs.open(bwallet, "r")
    if not file then
        return nil
    else
        data = file.readAll()
        file.close()
        return textutils.unserialize(data)
    end -- if not file
end -- function db.unpack


function db.pack(wallet, data)
    path = db.DATA_DIR .. wallet .. ".dat"
    file = fs.open(wallet, "w")
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