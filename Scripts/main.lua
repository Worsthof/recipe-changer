local Config = require("config")
local Utils = require("utils")
local JSONLoader = require("Handlers.json_loader")
local GlobalsHandler = require("Handlers.globals")
local ItemRecipeDTH = require("Handlers.DataTables.item_recipes")
local ItemDTH = require("Handlers.DataTables.items")

---@type string
local LogSection = "Main"

---@type boolean
local IsIniRunning = false

-- Loads the mod
---@return boolean
local function Initialize()
	if not ItemRecipeDTH:InitializeAccess() or not ItemDTH:InitializeAccess() then
		return false
	end

	---@type table<string, RecipeConfig>|nil
	local Recipes = JSONLoader.GetJSONRecipes()

	if not Config or not Recipes then
        Utils.Log("Error: Config.lua is missing or 'Recipes' table not found!", LogSection)
        return true
    end

	---@type string[]
	local FailedNames = {}

	local GlobalRecipes = GlobalsHandler.ExtractGlobals(Recipes)

	if #GlobalRecipes > 0 then
    	Utils.Log("Global modification start...", LogSection)
		ItemRecipeDTH.ModifyGlobalRecipes(GlobalRecipes)
		Utils.Log("Global modification finished...", LogSection)
	end

	Utils.Log("Modifying recipes...", LogSection)
	for Name, RecipeConfig in pairs(Recipes)
	do		
		Utils.Log("Get next recipe for (" .. Name .. ")", LogSection)

		if ItemRecipeDTH.CheckRecipe(Name) then
			Utils.Log("Recipe found!", LogSection)
			ItemRecipeDTH.ModifyRecipe(Name, RecipeConfig)
		else 
			Utils.Log("Recipe not found!", LogSection)
			table.insert(FailedNames, Name)
		end
	end

	Utils.Log("Recipe modification done", LogSection)

	if #FailedNames > 0 then
		Utils.Log("The following recipes failed to update:", LogSection)
		for _,Name in pairs(FailedNames) do
			Utils.Log("\t\t" .. Name, LogSection)
		end
	end

	return true
end

-- Wraps initialization method, prevents concurrent running
---@return boolean
local function IniWrapper()
	if IsIniRunning then
		return false
	end

	IsIniRunning = true

	local ReturnValue = Initialize()

	IsIniRunning = false

	return ReturnValue
end

ExecuteInGameThread(function()
	LoopAsync(5000, IniWrapper)
end)


