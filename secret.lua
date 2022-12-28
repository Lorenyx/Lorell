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

return secret