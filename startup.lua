-- default program for "myLorell" devices
local _key = "<KEY_HERE>"

if not fs.exists("cloud.lua") then
    print("Downloading cloud.lua")
    shell.run("wget", "https://cloud-catcher.squiddev.cc/cloud.lua")
end -- if not exists

if not fs.exists("client.lua") then
    print("Downloading client.lua")
    shell.run("wget", "https://raw.githubusercontent.com/Lorenyx/Lorell/main/client.lua")
end -- if not exists

shell.run("cloud.lua", _key)
shell.run("client.lua")