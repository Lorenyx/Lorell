local inifile = require "lib.inifile"
local config = inifile.parse("lorell.ini")

-- check for update on client
if fs.exists(config.lorell.update) then
    print("Updating client...")
    -- delete files
    fs.delete("client.lua")
    fs.delete(config.lorell.update)
    -- download files
    shell.run("wget", "https://raw.githubusercontent.com/Lorenyx/Lorell/main/client.lua")
end -- if fs.exists(config.lorell.update)

if ccemux then 
    local random = math.random
    ccemux.attach("back", "wireless_modem", {
        -- The range of this modem
        range = 64,
        -- Whether this is an ender modem
        interdimensional = false,
        -- The current world's name. Sending messages between worlds requires an interdimensional modem
        world = "main",
        -- The position of this wireless modem within the world
        posX = random(32), posY = random(32), posZ = random(32),
    })
end -- if ccemux

-- Clear screen and start
term.clear()
shell.run(config.lorell.purpose)