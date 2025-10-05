-- Gets the absolute directory path of the script.
---@return string
local function GetScriptDirectory()
    local scriptPath = debug.getinfo(1, "S").source
    local scriptDir = scriptPath:match("@?(.*[\\/])")

    return scriptDir or ""
end

--  Scans a directory using the 'dir' command.
---@param Dir string
---@param Extension string
---@return string[]
local function GetFilePathsFromDirectory(Dir, Extension)
    local DirPath = (GetScriptDirectory() .. Dir):gsub("/", "\\")
    local CMD = 'dir "' .. DirPath .. '\\*.' .. Extension .. '" /b /a-d'
    local Pipe = io.popen(CMD)
    if not Pipe then
        return {}
    end

    local Content = Pipe:read("*a")
    Pipe:close()

    local FoundFiles = {}

    for FileName in Content:gmatch("([^\n]*)\n?") do
        table.insert(FoundFiles, DirPath .. "\\" .. FileName)
    end

    return FoundFiles
end

--- Reads the entire content of a file into a string.
---@param FilePath string
---@return string|nil, string|nil
local function ReadFileContent(FilePath)

    local File, ErrorMessage = io.open(FilePath, "r")
    if not File then
        return nil, "Failed to open file: " .. (ErrorMessage or "permission denied")
    end

    local Content = File:read("*a")
    
    File:close()

    return Content, nil
end

---@class FileHandler
return {
    GetFilePathsFromDirectory = GetFilePathsFromDirectory,
    ReadFileContent = ReadFileContent
};