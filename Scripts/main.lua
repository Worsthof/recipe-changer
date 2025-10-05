---@type Config
local Config = require("config")

---@class PalMasterDataTableAccess_ItemRecipe: UPalMasterDataTableAccess_ItemRecipe
---@field BP_FindRow fun(self: PalMasterDataTableAccess_ItemRecipe, RowName: FName, bResult: {bResult: boolean}): FPalItemRecipe

---@type boolean
local IsIniRunning = false

---@type PalMasterDataTableAccess_ItemRecipe
local ItemRecipeDTAccess = nil

-- Maximum number of materials on FPalItemRecipe
---@type int32
local MAX_MATERIAL_COUNT = 5

---@param Message string
local function Log(Message)
	if not Config.Verbose then
		return
	end

	print("[RecipeChanger] " .. Message)
end

-- Fetch ItemRecipeDT access
---@return PalMasterDataTableAccess_ItemRecipe
local function GetAccess()
	---@type PalMasterDataTableAccess_ItemRecipe FindFirstOf
	return FindFirstOf("PalMasterDataTableAccess_ItemRecipe")
end

-- Sets the access if its not initialized already
---@return boolean
local function InitializeAccess()

	if ItemRecipeDTAccess and ItemRecipeDTAccess:IsValid() then
		Log("Access found!")
		return true
	end

	local access = GetAccess()
	if not access or not access:IsValid() then
		Log("No instance of PalMasterDataTableAccess_ItemRecipe found!")
		return false
	end

	ItemRecipeDTAccess = access
	Log("Access initialized!")

	return true
end

-- Attempts to retrieve row via Blueprint method
---@param Name string
---@return {IsExists: boolean, Recipe: FPalItemRecipe}
local function CheckRecipe(Name)
	
	local Out = { bResult = false }

	local Recipe = ItemRecipeDTAccess:BP_FindRow(FName(Name), Out)

	return {["IsExists"] = Out.bResult, ["Recipe"] = Recipe}
end

-- Replacing the recipe with the modified one
---@param Name string
---@param RecipeConfig RecipeConfig
---@param DTRow FPalItemRecipe
local function ModifyRecipe(Name, RecipeConfig, DTRow)
	local DT = ItemRecipeDTAccess.DataTable;

	DT:RemoveRow(Name)

	if RecipeConfig.OutputAmount then
		DTRow.Product_Count = RecipeConfig.OutputAmount
		Log("\t\tProduct_Count changed to " .. RecipeConfig.OutputAmount)
	end

	if RecipeConfig.WorkAmount then
		DTRow.WorkAmount = RecipeConfig.WorkAmount * 100
		Log("\t\tWorkAmount changed to " .. RecipeConfig.WorkAmount .. " sec")
	end

	if RecipeConfig.Materials then
		for Key, MaterialConfig in pairs(RecipeConfig.Materials) do
			if Key >= 1 and Key <= MAX_MATERIAL_COUNT then
				local Prop = "Material" .. Key
				if MaterialConfig.Name then
					DTRow[Prop .. "_Id"] = FName(MaterialConfig.Name)
					Log("\t\t" .. Prop .. "_Id" .. " changed to " .. MaterialConfig.Name)
				end
				if MaterialConfig.Amount then
					DTRow[Prop .. "_Count"] = MaterialConfig.Amount
					Log("\t\t" .. Prop .. "_Count" .. " changed to " .. MaterialConfig.Amount)
				end
			end
		end
	end

	if RecipeConfig.ExpRate then
		DTRow.CraftExpRate = RecipeConfig.ExpRate
		Log("\t\tCraftExpRate changed to " .. RecipeConfig.ExpRate)
	end

	DT:AddRow(Name, DTRow)

end

-- Loads the mod
---@return boolean
local function Initialize()
	if not InitializeAccess() then
		return false
	end

	if not Config or not Config.Recipes then
        Log("Error: Config.lua is missing or 'Recipes' table not found!")
        return true
    end

	---@type string[]
	local FailedNames = {}

	Log("Modifying recipes...")
	for Name, RecipeConfig in pairs(Config.Recipes)
	do		
		Log("Get next recipe for (" .. Name .. ")")

		local Check = CheckRecipe(Name)

		if Check.IsExists then
			Log("Recipe found!")
			ModifyRecipe(Name, RecipeConfig, Check.Recipe)
		else 
			Log("Recipe not found!")
			table.insert(FailedNames, Name)
		end
	end

	Log("Recipe modification done")

	if #FailedNames > 0 then
		Log("The following recipes failed to update:")
		for _,Name in pairs(FailedNames) do
			Log("\t\t" .. Name)
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
	LoopAsync(1000, IniWrapper)
end)

