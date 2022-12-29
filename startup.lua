-- default program for "myLorell" devices
local config = nil
--> URL to download client script
local _URL = "https://raw.githubusercontent.com/Lorenyx/Lorell/main/"
local CLIENT = "client.lua"
local CONFIG = "config.lua"


function init()
    init_config()
    config = require "config"
    init_token()
    init_client()
    shell.run("clear")
    shell.run(config._SCRIPT)
end -- function init


function init_config()
    if not fs.exists(CONFIG) then
        print("Downloading config...")
        download_file(CONFIG, CONFIG)
    end -- if not fs.exists
end -- function init_config


function init_client()
    -- Check for client
    if not fs.exists(config._SCRIPT) then
        print("Downloading client...")
        download_file(CLIENT, config._SCRIPT)
    elseif fs.exists(config._UPDATE) then
        print("Updating client...")
        fs.delete(config._SCRIPT)
        fs.delete(config._UPDATE)
        download_file(CLIENT, config._SCRIPT)
        download_file(CONFIG, CONFIG)
    end -- if not exists
end -- function init_client


function init_token()
    function get_token()
        -- generate uuid
        -- DO NOT SHARE SEED
        local _seed = os.epoch()
        -- local _seed = os.time() -- FOR TESTING ONLY
        math.randomseed(_seed)
        --> Available letters for encoding
        local A = "abcdefghijklmnopqrstuvwxyz"
        A = A..A:upper().."1234567890"
        assert(#A == (26+26+10), "Alphabet is incorrect length!")
        return string.gsub(string.rep('x', 32), 'x', function()
            local k = math.random(#A)
            return string.format('%s', A:sub(k,k+1))
        end) -- function()
    end -- function get_token
    -- Check for token
    if not fs.exists(config._TOKEN) then
        local token, length = get_token()
        assert(length == 32, "Key is incorrect length!")
        local f = fs.open(config._TOKEN, "w")
        f.write(token)
        f.close()
    end -- if not fs.exists
end -- function init_token()


function download_file(url, file)
    shell.run("wget", _URL..url, file)
end -- function get_script

-- Main Execution
init()