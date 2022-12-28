-- default program for "myLorell" devices
--> URL to download client script
local _URL = "https://raw.githubusercontent.com/Lorenyx/Lorell/main/client.lua"
--> name of client script
local _SCRIPT = "lorell.lua"
--> name of update notifaction
local _UPDATE = ".UPDATE_LORELL"
--> name of token file
local _TOKEN = ".TOKEN_LORELL"


function init()
    init_token()
    init_client()
    shell.run(_SCRIPT)
end -- function init


function init_client()
    -- nested function
    function get_script()
        shell.run("wget", _URL, _SCRIPT)
    end -- function get_script
    -- Check for client
    if not fs.exists(_SCRIPT) then
        print("Downloading client...")
        get_script()
    elseif fs.exists(_UPDATE) then
        print("Updating client...")
        fs.delete(_SCRIPT)
        fs.delete(_UPDATE)
        get_script()
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
    if not fs.exists(_TOKEN) then
        local token, length = get_token()
        assert(length == 32, "Key is incorrect length!")
        local f = fs.open(_TOKEN, "w")
        f.write(token)
    end -- if not fs.exists
end -- function init_token()
-- Main Execution
init()