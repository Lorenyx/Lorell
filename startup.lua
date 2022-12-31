-- default program for "myLorell" devices
local inifile = require "lib.inifile"
local config = inifile.parse("lorell.ini")
--> URL to download files
local _REPO_URL = "https://raw.githubusercontent.com/Lorenyx/Lorell/main/"


function init()
    _REPO_URL = _REPO_URL..config.purpose.."/"
    if "client" == config.purpose then
        start_client()
    elseif "server" == config.purpose then
        start_server()
    end -- if == config.purpose
end -- function init

function start_client()
    if not fs.exists(config)


function download_file(url, file)
    shell.run("wget", _URL..url, file)
end -- function get_script

-- Main Execution
init()