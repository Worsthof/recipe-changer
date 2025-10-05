-- Recursively merges the contents of the source table into the destination table.
-- Existing keys in the destination are overwritten, unless both values are tables,
-- in which case they are merged recursively.
---
---@param Destination table<string, any>
---@param Source table<string, any>
---@return table
local function MergeTable(Destination, Source)
    for Key, SourceValue in pairs(Source) do
        local DestValue = Destination[Key]

        if type(DestValue) == "table" and type(SourceValue) == "table" then
            Destination[Key] = MergeTable(DestValue, SourceValue)
        else
            Destination[Key] = SourceValue
        end
    end
    return Destination
end

return {
    MergeTable = MergeTable
}