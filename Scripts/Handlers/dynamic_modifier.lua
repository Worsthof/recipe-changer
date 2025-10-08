---@class DynamicOperation
---@field Operator string
---@field Operand float

---@type string
local Pattern = "^::([^:]+)::([%d.]+)$"

---@param Input float
---@param Operand float
---@return float
local function Add(Input, Operand)
    return Input + Operand
end

---@param Input float
---@param Operand float
---@return float
local function Substract(Input, Operand)
    return Input - Operand
end

---@param Input float
---@param Operand float
---@return float
local function Multiply(Input, Operand)
    return Input * Operand
end

---@type table<string, function>
local Operations = {
    ["ADD"] = Add,
    ["SUBSTRACT"] = Substract,
    ["MULTIPLY"] = Multiply
}

---@param Modifier string
---@return DynamicOperation|nil
local function Parse(Modifier)
    local Operator, Operand = Modifier:match(Pattern)

    if Operator == nil or Operand == nil then
        return nil
    end

    return {Operator = Operator:upper(), Operand = tonumber(Operand)}
end

---@param Operator string
---@return boolean
local function ValidateOperator(Operator)
    return Operations[Operator] ~= nil
end

---@param Modifier string
---@return DynamicOperation|nil
local function GetOperation(Modifier)
    if type(Modifier) ~= "string" then
        return nil
    end

    local Operation = Parse(Modifier)

    if not Operation then
        return nil
    end

    if not ValidateOperator(Operation.Operator) then
        return nil
    end

    return Operation
end

---@param Operation DynamicOperation
---@param Input float
---@return float
local function Modify(Operation, Input)
    return Operations[Operation.Operator](Input, Operation.Operand)
end

return {
    GetOperation = GetOperation,
    Modify = Modify
}