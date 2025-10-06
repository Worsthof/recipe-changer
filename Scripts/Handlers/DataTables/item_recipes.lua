local Utils = require("utils")

---@class PalMasterDataTableAccess_ItemRecipe: UPalMasterDataTableAccess_ItemRecipe
---@field BP_FindRow fun(self: PalMasterDataTableAccess_ItemRecipe, RowName: FName, bResult: {bResult: boolean}): FPalItemRecipe

---@type PalMasterDataTableAccess_ItemRecipe
local ItemRecipeDTAccess = nil

-- Maximum number of materials on FPalItemRecipe
---@type int32
local MAX_MATERIAL_COUNT = 5

-- Fetch ItemRecipeDT access
---@return PalMasterDataTableAccess_ItemRecipe
local function GetAccess()
	---@type PalMasterDataTableAccess_ItemRecipe
	return FindFirstOf("PalMasterDataTableAccess_ItemRecipe")
end

-- Sets the access if its not initialized already
---@return boolean
local function InitializeAccess()

	if ItemRecipeDTAccess and ItemRecipeDTAccess:IsValid() then
		Utils.Log("Access found!", "ItemRecipesDT")
		return true
	end

	local access = GetAccess()
	if not access or not access:IsValid() then
		Utils.Log("No instance of PalMasterDataTableAccess_ItemRecipe found!", "ItemRecipesDT")
		return false
	end

	ItemRecipeDTAccess = access
	Utils.Log("Access initialized!", "ItemRecipesDT")

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
		Utils.Log("Product_Count changed to " .. RecipeConfig.OutputAmount, "ItemRecipesDT")
	end

	if RecipeConfig.WorkAmount then
		DTRow.WorkAmount = RecipeConfig.WorkAmount * 100
		Utils.Log("WorkAmount changed to " .. RecipeConfig.WorkAmount .. " sec", "ItemRecipesDT")
	end

	if RecipeConfig.Materials then
		for Key, MaterialConfig in pairs(RecipeConfig.Materials) do
			if Key >= 1 and Key <= MAX_MATERIAL_COUNT then
				local Prop = "Material" .. Key
				if MaterialConfig.Name then
					DTRow[Prop .. "_Id"] = FName(MaterialConfig.Name)
					Utils.Log(Prop .. "_Id" .. " changed to " .. MaterialConfig.Name, "ItemRecipesDT")
				end
				if MaterialConfig.Amount then
					DTRow[Prop .. "_Count"] = MaterialConfig.Amount
					Utils.Log(Prop .. "_Count" .. " changed to " .. MaterialConfig.Amount, "ItemRecipesDT")
				end
			end
		end
	end

	if RecipeConfig.ExpRate then
		DTRow.CraftExpRate = RecipeConfig.ExpRate
		Utils.Log("CraftExpRate changed to " .. RecipeConfig.ExpRate, "ItemRecipesDT")
	end

	DT:AddRow(Name, DTRow)
end

return {
    ModifyRecipe = ModifyRecipe,
    CheckRecipe = CheckRecipe,
    InitializeAccess = InitializeAccess
}