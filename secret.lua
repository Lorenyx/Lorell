-- secret.lua
-------------
local secret = {}

--IMPORTANT: Remove any test users before pushing
local users = {
    -- Add users here
}

function secret.authorize(name, token)
    return users[name] == token
end -- function secret.authorize()

function secret.authenticate(name, token)
    if not users[name] then
        users[name] = token
        return true
    else
        return false
    end -- if not users[name]
end -- function secret.authenticate

return secret