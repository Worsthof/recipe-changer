---@class Config
---@field Verbose boolean

-- The 'Verbose' option is to enable console logging, when set to true it will log details about the recipe changes.
-- Useful for debugging, else it's not relevant, just leave it at false.
---@type boolean 
local Verbose = true

---@type Config
local Config = {
    Verbose = Verbose
}

return Config