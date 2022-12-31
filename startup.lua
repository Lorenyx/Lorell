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

-- Clear screen and start
term.clear()
shell.run(config.lorell.purpose)