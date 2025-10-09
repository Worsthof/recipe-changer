local Config = require("config")

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

---@param Message string
---@param Section string|nil
---@overload fun(Message: string)
local function Log(Message, Section)
	if not Config.Verbose then
		return
	end

    local prefix = "[Tweaksmith]"

    if Section then
        prefix = prefix .. "[" .. Section .. "]"
    end

	print(prefix .. " " .. Message)
end

-- Returns the running operating system name
---@return string
local function GetOS()
    if string.find(package.cpath, "%.dll") then
        return "windows"
    elseif string.find(package.cpath, "%.so") then
        return "linux"
    elseif string.find(package.cpath, "%.dylib") then
        return "mac"
    else
        return "other"
    end
end

return {
    MergeTable = MergeTable,
    Log = Log,
    GetOS = GetOS
}