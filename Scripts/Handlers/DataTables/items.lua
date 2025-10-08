local Utils = require("utils")

---@type string
local LogSection = "ItemsDTH"

---@class ItemElement
---@field Rank int32
---@field Rarity int32
---@field Price int32
---@field MaxStackCount int32
---@field Weight int32
---@field Durability int32
---@field IsNotConsumable boolean
---@field TypeA string
---@field TypeB string

---@type UPalStaticItemDataAsset
local ItemDTAccess = nil

---@type any
local EPalItemTypeA = nil

---@type any
local EPalItemTypeB = nil


---@return any
local function GetItemTypeA()
	if EPalItemTypeA then
		return EPalItemTypeA
	end

	EPalItemTypeA = FindObject("Enum", "EPalItemTypeA", EObjectFlags.RF_NoFlags, EObjectFlags.RF_NoFlags)

	return EPalItemTypeA
end

---@return any
local function GetItemTypeB()
	if EPalItemTypeB then
		return EPalItemTypeB
	end

	EPalItemTypeB = FindObject("Enum", "EPalItemTypeB", EObjectFlags.RF_NoFlags, EObjectFlags.RF_NoFlags)

	return EPalItemTypeB
end

---@param Enum any
---@param EnumValue any
local function GetEnumKey(Enum, EnumValue)
	return Enum:GetNameByValue(EnumValue):ToString():gsub("^[^:]+::", "")
end

-- Fetch ItemProductDT access
---@return UPalStaticItemDataAsset
local function GetAccess()
	---@type UPalStaticItemDataAsset
	return FindFirstOf("PalStaticItemDataAsset")
end

-- Sets the access if its not initialized already
---@return boolean
local function InitializeAccess()

	if ItemDTAccess and ItemDTAccess:IsValid() then
		Utils.Log("Access found!", LogSection)
		return true
	end

	local Access = GetAccess()
	if not Access or not Access:IsValid() then
		Utils.Log("No instance of PalMasterDataTableAccess_ItemProductData found!", LogSection)
		return false
	end

	ItemDTAccess = Access
	Utils.Log("Access initialized!", LogSection)

	return true
end

-- Check if product is exist
---@param Name FName
---@return boolean
local function CheckItem(Name)    
	return ItemDTAccess.StaticItemDataMap:Contains(Name)
end

---@param Object UPalStaticItemDataBase
---@return ItemElement
local function ConstructElement(Object)
	return {
		Rank = tonumber(tostring(Object.Rank)),
		Rarity = tonumber(tostring(Object.Rarity)),
		Price = tonumber(tostring(Object.Price)),
		MaxStackCount = tonumber(tostring(Object.MaxStackCount)),
		Weight = tonumber(tostring(Object.Weight)),
		Durability = tonumber(tostring(Object.Durability)),
		IsNotConsumable = tostring(Object.bNotConsumed) == "true",
		TypeA = GetEnumKey(GetItemTypeA(), Object.TypeA),
		TypeB = GetEnumKey(GetItemTypeB(), Object.TypeB),
	}
end

---@param Name FName
---@return ItemElement
local function GetItem(Name)
	---@type RemoteUnrealParam 
	local Object = ItemDTAccess.StaticItemDataMap:Find(Name)
	return ConstructElement(Object:get())
end

return {
    CheckItem = CheckItem,
    InitializeAccess = InitializeAccess,
	GetItem = GetItem
}