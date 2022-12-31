local completion = require "cc.completion"
local _REPO = "https://raw.githubusercontent.com/Lorenyx/Lorell/main/"

-- Values to save to 'lorell.ini'
local config = {
    rednet = {
        protocol = "LORELL",
        timeout = "5",
    },
    lorell = {
        purpose = "dev", -- Change to "server", or "client"
        update = ".UPDATE_LORELL",
        token = ".TOKEN_LORELL"
    }
}

-- init functions
function init(purpose)
    init_lib()
    init_config()
    if "client" == purpose then
        init_token()
        init_script({"client.lua"})
    elseif "server" == purpose then
        init_script({"database.lua", "server.lua"})
    elseif "dev" == purpose then
        init_script({"client.lua", "database.lua", "server.lua"})
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
    fs.delete("init.lua")
    write("Rebooting in ")
    textutils.slowPrint("3... 2... 1...", 4)
    os.reboot()
end -- function init

function init_lib()
    local _inifile = "/lib/inifile.lua"
    local _inifile_url = "https://github.com/Lorenyx/inifile/raw/main/inifile.lua"
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
    local _ini = "lorell.ini"
    if not fs.exists(_ini) then
        -- Save inifile with purpose
        inifile = require "lib.inifile"
        inifile.save(_ini, config)
    end -- if not fs.exists
end -- function init_config

function init_token()
    local _token = ".TOKEN_LORELL"
    function _generate()
        -- generate uuid
        -- DO NOT SHARE SEED
        local _seed = os.epoch()
        -- local _seed = os.time() -- FOR TESTING ONLY
        math.randomseed(_seed)
        --> Available letters for encoding
        local A = "abcdefghijklmnopqrstuvwxyz"
        A = A..A:upper().."1234567890"
        assert(#A == (26+26+10), "Alphabet is incorrect length!")
        return string.gsub(string.rep('-', 32), '-', function()
            local k = math.random(#A)
            return A:sub(k,k)
        end) -- function()
    end -- function get_token
    -- Check for token
    if not fs.exists(config.lorell.token) then
        local token, length = _generate()
        assert(length == 32, "Key is incorrect length!")
        assert(io.open(config.lorell.token, "w"))
            :write(token)
            :close()
    end -- if not fs.exists
end -- function init_token

function init_script(script)
    -- Check for client
    function get_script(file)
        if not fs.exists(file) then
            print("Downloading "..file)
            download_file(_REPO..file, file)
        end -- if not exists
    end -- function get_script
    if type(script) == "table" then
        for i, s in ipairs(script) do
            get_script(s)
        end -- for i, s in ipairs
    elseif type(script) == "string" then
        get_script(script)
    end -- if type(script) ==
end -- function init_client

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