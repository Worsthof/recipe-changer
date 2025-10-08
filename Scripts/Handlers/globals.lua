---@class GlobalRecipe
---@field Key string
---@field RecipeConfig RecipeConfig
---@field TypeA string|nil
---@field TypeB string|nil
---@field Level int32
---@field Sort int32|nil

---Counts the number of colons in a key to determine its specificity level.
---@param Key string
---@return number
local function GetKeyLevel(Key)
    local count = 0
    for _ in Key:gmatch(":") do
        count = count + 1
    end
    return count
end

---Sorts the global recipes by their level of specificity and secondary sort.
---@param GlobalRecipes GlobalRecipe[]
---@return GlobalRecipe[]
local function SortGlobals(GlobalRecipes)
    table.sort(GlobalRecipes, function(a, b)
        if a.Level ~= b.Level then
            return a.Level < b.Level
        end

        local aSort = a.Sort or 9999
        local bSort = b.Sort or 9999
        
        return aSort < bSort
    end)

    return GlobalRecipes
end

---Parses a global key to construct a GlobalRecipe object with TypeA and TypeB.
---@param Key string
---@param Config RecipeConfig
---@return GlobalRecipe
local function ConstructGlobal(Key, Config)
    local Global = {
        Key = Key,
        RecipeConfig = Config,
        TypeA = nil,
        TypeB = nil,
        Level = GetKeyLevel(Key),
        Sort = nil
    }

    local Sort = Key:gmatch("^%*([1-9]%d*)")()

    if Sort then
        Global.Sort = tonumber(Sort)
    end

    local Types = {}
    for TypeStr in Key:gmatch(":([^:]+)") do
        table.insert(Types, TypeStr)
    end

    Global.TypeA = Types[1]
    Global.TypeB = Types[2]

    return Global
end

-- Selects all recipes that are global modifiers.
---@param AllRecipes table<string, RecipeConfig>
---@return GlobalRecipe[]
local function ExtractGlobals(AllRecipes)
    ---@type GlobalRecipe[]
    local GlobalRecipes = {}

    ---@type string[]
    local DeletableEntries = {}

    for Key, Config in pairs(AllRecipes) do
        if Key:sub(1, 1) == "*" then
            table.insert(GlobalRecipes, ConstructGlobal(Key, Config))
            table.insert(DeletableEntries, Key)
        end
    end

    for _, Key in pairs(DeletableEntries) do
        AllRecipes[Key] = nil
    end

    return SortGlobals(GlobalRecipes)
end

return {
    ExtractGlobals = ExtractGlobals
}