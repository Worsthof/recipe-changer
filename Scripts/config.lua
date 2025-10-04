---@class Config
---@field Recipes table<string, RecipeConfig>
---@field Verbose boolean

---@class MaterialConfig
---@field Name string|nil
---@field Amount int32|nil

---@class RecipeConfig
---@field OutputAmount int32|nil
---@field WorkAmount int32|nil
---@field Materials table<int32, MaterialConfig>|nil
---@field ExpRate int32|nil

-- =========================================================================
--  RECIPE CONFIGURATION INSTRUCTIONS
-- =========================================================================

-- The 'Recipes' table is used to override existing Palworld item recipe properties.
--
-- The KEY of the entry MUST be the exact Name of the item recipe you want to change.
-- (e.g., "AssaultRifleBullet", "PalSphere", "Wood", etc.)
--
-- All fields (OutputAmount, WorkAmount, Materials, ExpRate) are OPTIONAL.
-- Only include the fields you want to change.
--
-- EXAMPLE: Changing the recipe for "PalSphere"
--
--  ["PalSphere"] = {
--      -- Number of Pal Spheres produced per craft 
--      OutputAmount = 10,
--
--      -- Work time required in sec, keep in mind this time will be affected by work speed
--      WorkAmount = 10,
--
--      -- Multiplier for the experience granted upon crafting.
--      -- The value appears to be scaled, likely representing a percentage or a factor of the base XP.
--      -- Observed Scaling on crafting Assault Rifle Ammo:
--          - ExpRate = 1   -> 29 XP
--          - ExpRate = 100 -> 2954 XP (suggests a direct proportional relationship: 1 unit = ~29 XP)
--      ExpRate = 100,
--
--      -- Modify the materials required. Keys must be 1, 2, 3, 4, or 5.
--      Materials = {
--          -- Material 1: Change "Wood" amount to 5
--          [1] = { Name = "Wood", Amount = 5 },
--          
--          -- Material 2: Change "Stone" amount to 10
--          [2] = { Name = "Stone", Amount = 10 },
--          
--          -- Material 3: REMOVE the third material (set Name to "None", Amount to 0)
--          [3] = { Name = "None", Amount = 0 }, 
--      },
--  },
--
-- The 'Verbose' option is to enable console logging, when set to true it will log details about the recipe changes.
-- Useful for debugging, else it's not relevant, just leave it at false.

---@type Config
local config = {
    Recipes = {
        ["PalSphere"] = {
            OutputAmount = 10,
            WorkAmount = 10,
            ExpRate = 1,
            Materials = {
                [1] = { Name = "Wood", Amount = 5 },
                [2] = { Name = "Stone", Amount = 10 },
                [3] = { Name = "None", Amount = 0 }, 
            },
        },
    },
    Verbose = false
}

return config