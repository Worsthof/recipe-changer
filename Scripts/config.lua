local JSONParser = require("Libs.dkjson")
local FileHandler = require("file_handler")
local Utils = require("utils")

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

---@class ParsedRecipeConfig
---@field OutputAmount int32|nil
---@field WorkAmount int32|nil
---@field Materials table<string, MaterialConfig>|nil
---@field ExpRate int32|nil

-- The 'Verbose' option is to enable console logging, when set to true it will log details about the recipe changes.
-- Useful for debugging, else it's not relevant, just leave it at false.
---@type boolean 
local Verbose = true

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

---@type Config
local Config = {
    Recipes = {},
    Verbose = Verbose
}

---@param Materials table<string|int32, MaterialConfig>
---@return table<int32, MaterialConfig>
local function CorrectJSONRecipeMaterialKeys(Materials)

    ---@type table<int32, MaterialConfig>
    local CMaterials = {}

    for Key, Value in pairs(Materials) do
        CMaterials[tonumber(Key)] = Value
    end
    
    return CMaterials
end

-- Validate a single recipe's structure
---@param Name string
---@param RecipeConfig table
---@return boolean, string|nil
local function ValidateRecipeConfig(Name, RecipeConfig)
    if type(RecipeConfig) ~= "table" then
        return false, "The entry for '" .. Name .. "' must be a table."
    end

    if RecipeConfig.OutputAmount and type(RecipeConfig.OutputAmount) ~= "number" then
        return false, "In recipe '" .. Name .. "': 'OutputAmount' must be a number."
    end
    if RecipeConfig.WorkAmount and type(RecipeConfig.WorkAmount) ~= "number" then
        return false, "In recipe '" .. Name .. "': 'WorkAmount' must be a number."
    end
    if RecipeConfig.ExpRate and type(RecipeConfig.ExpRate) ~= "number" then
        return false, "In recipe '" .. Name .. "': 'ExpRate' must be a number."
    end

    if RecipeConfig.Materials then
        if type(RecipeConfig.Materials) ~= "table" then
            return false, "In recipe '" .. Name .. "': 'Materials' must be a table."
        end
        for Key, Material in pairs(RecipeConfig.Materials) do
            if not tonumber(Key) then
                return false, "In recipe '" .. Name .. "': A key in 'Materials' is not a number."
            end
            if type(Material) ~= "table" then
                return false, "In recipe '" .. Name .. "': A value in 'Materials' is not a table."
            end
            if Material.Name and type(Material.Name) ~= "string" then
                return false, "In recipe '" .. Name .. "': A material 'Name' must be a string."
            end
            if Material.Amount and type(Material.Amount) ~= "number" then
                return false, "In recipe '" .. Name .. "': A material 'Amount' must be a number."
            end
        end
    end

    return true, nil
end

---@param Content string
---@return table<string, RecipeConfig>|nil, string|nil
local function ParseJSONRecipe(Content)

    local Result, ParsedData = pcall(JSONParser.decode, Content)

    if not Result then
        return nil, "Invalid JSON syntax"
    end

    if type(ParsedData) ~= "table" then
        return nil, "The root of the JSON file must be a table/object."
    end

    for Name, RecipeConfig in pairs(ParsedData) do
        if type(Name) ~= "string" then
            return nil, "A top-level key in the JSON is not a string (a recipe name)."
        end
        
        local IsValid, ErrorMessage = ValidateRecipeConfig(Name, RecipeConfig)
        if not IsValid then
            return nil, ErrorMessage
        end

        if RecipeConfig.Materials then
            RecipeConfig.Materials = CorrectJSONRecipeMaterialKeys(RecipeConfig.Materials)
        end
    end

    return ParsedData
end

local function LoadJSONRecipes()
    ---@type string[]
    local Recipes = FileHandler.GetFilePathsFromDirectory("Recipes", "json")

    ---@type string|nil
    local Content = nil

    ---@type table<string, RecipeConfig>|nil
    local Recipe = nil

    ---@type string[]
    local FailedFiles = {}

    if #Recipes < 1 then
        print("[RecipeChanger][Config] JSON Recipes not found or Recipes DIR not exists!")
        return
    end

    for _,FilePath in pairs(Recipes) do
        Content = FileHandler.ReadFileContent(FilePath)

        if Content then
            Recipe, ErrorMessage = ParseJSONRecipe(Content)

            if Recipe then
                Config.Recipes = Utils.MergeTable(Config.Recipes, Recipe)
            else
                print("[RecipeChanger][Config] Cannot parse content of file (" .. FilePath .. "):" .. ErrorMessage)
                table.insert(FailedFiles, FilePath)
            end
        else
            print("[RecipeChanger][Config] Cannot read content of file (" .. FilePath .. ")")
            table.insert(FailedFiles, FilePath)
        end
    end

    if #FailedFiles > 0 then
        print("[RecipeChanger][Config] The following recipe files failed to load:")
        for _, FilePath in pairs(FailedFiles) do
            print("[RecipeChanger][Config] \t\t" .. FilePath)
        end
    end
end

LoadJSONRecipes()

return Config