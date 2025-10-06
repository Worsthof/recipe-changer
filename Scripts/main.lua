local Config = require("config") Config.Initialize()
local Utils = require("utils")
local ItemRecipeDTH = require("Handlers.DataTables.item_recipes")

---@type boolean
local IsIniRunning = false

-- Loads the mod
---@return boolean
local function Initialize()
	if not ItemRecipeDTH.InitializeAccess() then
		return false
	end

	if not Config or not Config.Recipes then
        Utils.Log("Error: Config.lua is missing or 'Recipes' table not found!", "Main")
        return true
    end

	---@type string[]
	local FailedNames = {}

	Utils.Log("Modifying recipes...", "Main")
	for Name, RecipeConfig in pairs(Config.Recipes)
	do		
		Utils.Log("Get next recipe for (" .. Name .. ")", "Main")

		local Check = ItemRecipeDTH.CheckRecipe(Name)

		if Check.IsExists then
			Utils.Log("Recipe found!", "Main")
			ItemRecipeDTH.ModifyRecipe(Name, RecipeConfig, Check.Recipe)
		else 
			Utils.Log("Recipe not found!", "Main")
			table.insert(FailedNames, Name)
		end
	end

	Utils.Log("Recipe modification done", "Main")

	if #FailedNames > 0 then
		Utils.Log("The following recipes failed to update:", "Main")
		for _,Name in pairs(FailedNames) do
			Utils.Log("\t\t" .. Name, "Main")
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


