local Utils = require("utils")
local ItemDTH = require("Handlers.DataTables.items")
local DMHandler = require("Handlers.dynamic_modifier")

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

---@param Target number|DynamicOperation
---@param Operand number
---@return number
local function GetDynamicValue(Target, Operand)
	if type(Target) == "number" then
		return Target
	end

	return DMHandler.Modify(Target, Operand)
end

-- Modify recipe based on config parameters
---@param RecipeConfig RecipeConfig
---@param DTRow FPalItemRecipe
---@param Item ItemElement|nil
---@overload fun(RecipeConfig: RecipeConfig, DTRow: FPalItemRecipe)
function Modify(RecipeConfig, DTRow, Item)
	if not Item then
		Item = ItemDTH.GetItem(DTRow.Product_Id)
	end

	if RecipeConfig.OutputAmount then
		local OutputAmount = GetDynamicValue(RecipeConfig.OutputAmount, DTRow.Product_Count)

		if OutputAmount > Item.MaxStackCount then
			Utils.Log("OutputAmount is higher than maximum stack count of this item!", "ItemsRecipesDT")
			OutputAmount = Item.MaxStackCount
			Utils.Log("OutputAmount changed to maximum stack count!", "ItemsRecipesDT")
		end

		DTRow.Product_Count = OutputAmount
		Utils.Log("Product_Count changed to " .. OutputAmount, LogSection)
	end

	if RecipeConfig.WorkAmount then
		local WorkAmount = GetDynamicValue(RecipeConfig.WorkAmount, DTRow.WorkAmount / 100)
		
		DTRow.WorkAmount = WorkAmount * 100
		Utils.Log("WorkAmount changed to " .. WorkAmount .. " sec", LogSection)
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
					local MaterialAmount = GetDynamicValue(MaterialConfig.Amount, DTRow[Prop .. "_Count"])

					DTRow[Prop .. "_Count"] = MaterialAmount
					Utils.Log(Prop .. "_Count" .. " changed to " .. MaterialAmount, LogSection)
				end
			end
		end
	end

	if RecipeConfig.ExpRate then
		local ExpRate = GetDynamicValue(RecipeConfig.ExpRate, DTRow.CraftExpRate)

		DTRow.CraftExpRate = ExpRate
		Utils.Log("CraftExpRate changed to " .. ExpRate, LogSection)
	end
end

-- Replacing the recipe with the modified one
---@param Name string
---@param RecipeConfig RecipeConfig
---@param DTRow FPalItemRecipe|nil
---@param Item ItemElement|nil
---@overload fun(Name: string, RecipeConfig: RecipeConfig)
---@overload fun(Name: string, RecipeConfig: RecipeConfig, DTRow: FPalItemRecipe)
local function ModifyRecipe(Name, RecipeConfig, DTRow, Item)
	local DT = ItemRecipeDTAccess.DataTable;

	if not DTRow then
		DTRow = DT:FindRow(Name)
	end

	Modify(RecipeConfig, DTRow, Item)

	DT:RemoveRow(Name)
	DT:AddRow(Name, DTRow)
end

-- Apply modification to every recipe
---@param GlobalConfigs GlobalRecipe[]
local function ModifyGlobalRecipes(GlobalConfigs)
	local DT = ItemRecipeDTAccess.DataTable;

	---@type ItemElement
	local Item = nil

	---@type boolean
	local Doable = nil

	---@type RecipeConfig
	local RecipeConfig = nil

	---@type {Name:string, Data:FPalItemRecipe}[]
	local Rows = DT:GetAllRows()

	for _, Row in pairs(Rows) do
		Utils.Log("Recipe (" .. Row.Name ..  ") updating", LogSection)
		Item = ItemDTH.GetItem(Row.Data.Product_Id)

		RecipeConfig = {}

		for _, Config in ipairs(GlobalConfigs) do
			Doable = true

			if Config.TypeA and Config.TypeA ~= Item.TypeA then
				Doable = false
			end

			if Config.TypeB and Config.TypeB ~= Item.TypeB then
				Doable = false
			end

			if Doable then
				Utils.MergeTable(RecipeConfig, Config.RecipeConfig)
			end
		end

		ModifyRecipe(Row.Name, RecipeConfig, Row.Data, Item)
	end
end

return {
	ModifyGlobalRecipes = ModifyGlobalRecipes,
    ModifyRecipe = ModifyRecipe,
    CheckRecipe = CheckRecipe,
    InitializeAccess = InitializeAccess
}