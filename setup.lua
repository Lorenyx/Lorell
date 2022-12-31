local completion = require "cc.completion"
local _REPO = "https://raw.githubusercontent.com/Lorenyx/Lorell/main/"

-- init functions
function init(purpose)
    init_lib()
    init_config(purpose)
    if "client" == purpose then
        init_token()
        init_client()
    elseif "server" == purpose then
        init_database()
        init_server()
    elseif "test" == purpose then
        init_client()
        init_server()
        init_database()
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
    else
        printError("Unknown purpose.")
        return
    end
    -- remove file at completion
    fs.delete("setup.lua")
    write("Rebooting in ")
    textutils.slowPrint("3... 2... 1...", 4)
    os.reboot()
end -- function init

function init_lib()
    local _inifile = "/lib/inifile.lua"
    local _inifile_url = "https://github.com/bartbes/inifile/raw/main/inifile.lua"
    local _ecc = "/lib/ecc.lua"
    local _ecc_url = "https://pastebin.com/raw/ZGJGBJdg"
    -- Check for lib.inifile
    if not fs.exists("/lib/inifile.lua") then
        download_file(_inifile_url, _inifile)
    elseif not fs.exists("/lib/ecc.lua") then
        download_file(_ecc_url, _ecc)
    end -- if not fs.exists
end -- function init_lib

function init_config(purpose)
    local _lorellini = "lorell.ini"
    if not fs.exists(_lorellini) then
        print("Downloading lorell.ini ...")
        download_file(_REPO.._lorellini, _lorellini)
    end
    local inifile = require "lib.inifile"
    config = inifile.parse(_lorellini)
    config.lorell.purpose = purpose
end -- funciton init_config


-- Util functions -- 
function download_file(url, file)
    shell.run("wget", url, file)
end -- function get_script


-- Main loop
while true do
    write("Purpose? ")
    local input = read(nil, nil, function(text) 
        return completion.choice(text, {"server", "client"})
    end)
    init(input)
end