local Utils = require("utils")
local ItemDTH = require("Handlers.DataTables.items")

---@type string
local LogSection = "ItemRecipesDTH"

---@type UPalMasterDataTableAccess_ItemRecipe
local ItemRecipeDTAccess = nil

-- Maximum number of materials on FPalItemRecipe
---@type int32
local MAX_MATERIAL_COUNT = 5

-- Fetch ItemRecipeDT access
---@return UPalMasterDataTableAccess_ItemRecipe
local function GetAccess()
	---@type UPalMasterDataTableAccess_ItemRecipe
	return FindFirstOf("PalMasterDataTableAccess_ItemRecipe")
end

-- Sets the access if its not initialized already
---@return boolean
local function InitializeAccess()

	if ItemRecipeDTAccess and ItemRecipeDTAccess:IsValid() then
		Utils.Log("Access found!", LogSection)
		return true
	end

	local Access = GetAccess()
	if not Access or not Access:IsValid() then
		Utils.Log("No instance of PalMasterDataTableAccess_ItemRecipe found!", LogSection)
		return false
	end

	ItemRecipeDTAccess = Access
	Utils.Log("Access initialized!", LogSection)

	return true
end

-- Check if recipe is exists
---@param Name string
---@return boolean
local function CheckRecipe(Name)
	return ItemRecipeDTAccess.DataTable:FindRow(Name) ~= nil
end

-- Modify recipe based on config parameters
---@param RecipeConfig RecipeConfig
---@param DTRow FPalItemRecipe
function Modify(RecipeConfig, DTRow)
	local Item = ItemDTH.GetItem(DTRow.Product_Id)
	local OutputAmount = RecipeConfig.OutputAmount

	if OutputAmount then
		if OutputAmount > Item.MaxStackCount then
			Utils.Log("OutputAmount is higher than maximum stack count of this item!", "ItemsRecipesDT")
			OutputAmount = Item.MaxStackCount
			Utils.Log("OutputAmount changed to maximum stack count!", "ItemsRecipesDT")
		end
		DTRow.Product_Count = OutputAmount
		Utils.Log("Product_Count changed to " .. OutputAmount, LogSection)
	end

	if RecipeConfig.WorkAmount then
		DTRow.WorkAmount = RecipeConfig.WorkAmount * 100
		Utils.Log("WorkAmount changed to " .. RecipeConfig.WorkAmount .. " sec", LogSection)
	end

	if RecipeConfig.Materials then
		for Key, MaterialConfig in pairs(RecipeConfig.Materials) do
			if Key >= 1 and Key <= MAX_MATERIAL_COUNT then
				local Prop = "Material" .. Key
				if MaterialConfig.Name then
					DTRow[Prop .. "_Id"] = FName(MaterialConfig.Name)
					Utils.Log(Prop .. "_Id" .. " changed to " .. MaterialConfig.Name, LogSection)
				end
				if MaterialConfig.Amount then
					DTRow[Prop .. "_Count"] = MaterialConfig.Amount
					Utils.Log(Prop .. "_Count" .. " changed to " .. MaterialConfig.Amount, LogSection)
				end
			end
		end
	end

	if RecipeConfig.ExpRate then
		DTRow.CraftExpRate = RecipeConfig.ExpRate
		Utils.Log("CraftExpRate changed to " .. RecipeConfig.ExpRate, LogSection)
	end
end

-- Replacing the recipe with the modified one
---@param Name string
---@param RecipeConfig RecipeConfig
---@param DTRow FPalItemRecipe|nil
---@overload fun(Name: string, RecipeConfig: RecipeConfig)
local function ModifyRecipe(Name, RecipeConfig, DTRow)
	local DT = ItemRecipeDTAccess.DataTable;

	if not DTRow then
		DTRow = DT:FindRow(Name)
	end

	DT:RemoveRow(Name)

	Modify(RecipeConfig, DTRow)

	DT:AddRow(Name, DTRow)
end

-- Apply modification to every recipe
---@param RecipeConfig RecipeConfig
local function ModifyAllRecipe(RecipeConfig)
	local DT = ItemRecipeDTAccess.DataTable;

	---@param Name string
	---@param DTRow FPalItemRecipe
	DT:ForEachRow(function(Name, DTRow)
		Utils.Log("Recipe (" .. Name ..  ") updating", LogSection)
		ModifyRecipe(Name, RecipeConfig, DTRow)
	end)
end

return {
	ModifyAllRecipe = ModifyAllRecipe,
    ModifyRecipe = ModifyRecipe,
    CheckRecipe = CheckRecipe,
    InitializeAccess = InitializeAccess
}