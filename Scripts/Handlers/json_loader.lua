local JSONParser = require("Libs.dkjson")
local FileHandler = require("Handlers.file_handler")
local Utils = require("utils")
local DMHandler = require("Handlers.dynamic_modifier")

---@alias UnprocessedMaterialConfig { Name?: any, Amount?: any }
---@alias UnprocessedRecipeConfig { OutputAmount?: any, WorkAmount?: any, ExpRate?: any, Materials?: table<number, UnprocessedMaterialConfig> }

---@type string
local LogSection = "JSON"

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

-- Helper function for strict type validation
---@param Value any
---@return boolean
local function IsValidType(Value)
    local ValueType = type(Value)
    if ValueType == "number" then
        return true
    end

    if ValueType == "table" then
        return type(Value.Operator) == "string" and type(Value.Operand) == "number"
    end

    return false
end

-- Validate a single recipe's structure
---@param Name string
---@param RecipeConfig table
---@return boolean, string|nil
local function ValidateRecipeConfig(Name, RecipeConfig)
    if RecipeConfig.OutputAmount and not IsValidType(RecipeConfig.OutputAmount) then
        return false, "In recipe '" .. Name .. "': 'OutputAmount' must be a number or a valid dynamic modifier."
    end
    if RecipeConfig.WorkAmount and not IsValidType(RecipeConfig.WorkAmount) then
        return false, "In recipe '" .. Name .. "': 'WorkAmount' must be a number or a valid dynamic modifier."
    end
    if RecipeConfig.ExpRate and not IsValidType(RecipeConfig.ExpRate) then
        return false, "In recipe '" .. Name .. "': 'ExpRate' must be a number or a valid dynamic modifier."
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
            if Material.Amount and not IsValidType(Material.Amount) then
                return false, "In recipe '" .. Name .. "': A material 'Amount' must be a number or a valid dynamic modifier."
            end
        end
    end

    return true, nil
end

---@param Name string
---@param RecipeConfig UnprocessedRecipeConfig
local function ApplyDynamicModifications(Name, RecipeConfig)
    if RecipeConfig.OutputAmount and type(RecipeConfig.OutputAmount) == "string" then
        RecipeConfig.OutputAmount = DMHandler.GetOperation(RecipeConfig.OutputAmount)
        if not RecipeConfig.OutputAmount then
             Utils.Log("In recipe '" .. Name .. "' the dynamic modifier is invalid for OutputAmount! Attribute removed.", LogSection)
        end
    end
    if RecipeConfig.WorkAmount and type(RecipeConfig.WorkAmount) == "string" then
        RecipeConfig.WorkAmount = DMHandler.GetOperation(RecipeConfig.WorkAmount)
        if not RecipeConfig.WorkAmount then
             Utils.Log("In recipe '" .. Name .. "' the dynamic modifier is invalid for WorkAmount! Attribute removed.", LogSection)
        end
    end
    if RecipeConfig.ExpRate and type(RecipeConfig.ExpRate) == "string" then
        RecipeConfig.ExpRate = DMHandler.GetOperation(RecipeConfig.ExpRate)
        if not RecipeConfig.ExpRate then
             Utils.Log("In recipe '" .. Name .. "' the dynamic modifier is invalid for ExpRate! Attribute removed.", LogSection)
        end
    end
    if RecipeConfig.Materials then
        if type(RecipeConfig.Materials) ~= "table" then
            return nil
        end
        for _, Material in pairs(RecipeConfig.Materials) do
            if type(Material) ~= "table" then
                return nil
            end
            if Material.Amount and type(Material.Amount) == "string" then
                Material.Amount = DMHandler.GetOperation(Material.Amount)
                if not Material.Amount then
                    Utils.Log("In recipe '" .. Name .. "' the dynamic modifier is invalid for Material: '" .. Material.Name .. "'! Attribute removed.", LogSection)
                end
            end
        end
    end
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

        if type(RecipeConfig) ~= "table" then
            return nil, "The entry for '" .. Name .. "' must be a table."
        end

        ApplyDynamicModifications(Name, RecipeConfig)
        
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

---@return table<string, RecipeConfig>|nil
local function GetJSONRecipes()
    if Utils.GetOS() ~= "windows" then
        Utils.Log("JSON recipes are only available on windows operating system!", LogSection)
        return
    end

    ---@type table<string, RecipeConfig>
    local RecipesOutput = {}

    ---@type string[]
    local Recipes = FileHandler.GetFilePathsFromDirectory("../Recipes", "json")

    ---@type string|nil
    local Content = nil

    ---@type table<string, RecipeConfig>|nil
    local Recipe = nil

    ---@type string[]
    local FailedFiles = {}

    if #Recipes < 1 then
        Utils.Log("JSON Recipes not found or Recipes DIR not exists!", LogSection)
        return
    end

    for _,FilePath in pairs(Recipes) do
        Content = FileHandler.ReadFileContent(FilePath)

        if Content then
            Recipe, ErrorMessage = ParseJSONRecipe(Content)

            if Recipe then
                Utils.Log("JSON recipe loaded: " .. FilePath:match("([^/\\]+)$"), LogSection)
                RecipesOutput = Utils.MergeTable(RecipesOutput, Recipe)
            else
                Utils.Log("Cannot parse content of file (" .. FilePath:match("([^/\\]+)$") .. "):" .. ErrorMessage, LogSection)
                table.insert(FailedFiles, FilePath)
            end
        else
            Utils.Log("Cannot read content of file (" .. FilePath .. ")", LogSection)
            table.insert(FailedFiles, FilePath)
        end
    end

    if #FailedFiles > 0 then
        Utils.Log("The following recipe files failed to load:", LogSection)
        for _, FilePath in pairs(FailedFiles) do
            Utils.Log("\t\t" .. FilePath, LogSection)
        end
    end

    return RecipesOutput
end

return {
    GetJSONRecipes = GetJSONRecipes
}