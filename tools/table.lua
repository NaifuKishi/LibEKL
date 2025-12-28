local addonInfo, privateVars = ...

---------- init namespace ---------

if not LibEKL then LibEKL = {} end
if not LibEKL.Tools then LibEKL.Tools = {} end

LibEKL.Tools.Table = {}

local data         = privateVars.data
local internalFunc = privateVars.internalFunc

---------- init local variables ---------

local stringLower   = string.lower
local stringFind    = string.find
local tableInsert   = table.insert
local tableRemove   = table.remove
local tableSort     = table.sort

-- ========== TABLE HANDLING ========== --

-- Checks if an element is a member of a table.
-- @param checkTable The table to check.
-- @param element The element to check for.
-- @return true if the element is a member of the table, false otherwise.
function LibEKL.Tools.Table.IsMember (checkTable, element)
    if type(checkTable) ~= "table" then
        LibEKL.Tools.Error.Display("LibEKL.Tools.Table", "checkTable must be a table", 2)
        return false
    end
   
    if checkTable == nil then 
        LibEKL.Tools.Error.Display("LibEKL.Tools.Table", "checkTable is nil", 2)
        return false 
    end

    for idx, value in pairs(checkTable) do
        if value == element then return true end
    end

    return false   
end

-- Gets the position of an element in a table.
-- @param checkTable The table to check.
-- @param element The element to find.
-- @return The position of the element, or -1 if not found.
function LibEKL.Tools.Table.GetTablePos (checkTable, element)
    if type(checkTable) ~= "table" then
        LibEKL.Tools.Error.Display("LibEKL.Tools.Table", "checkTable must be a table", 2)
        return -1
    end

    for idx, value in pairs (checkTable) do
        if value == element then return idx end
    end
    
    return -1
end

-- Adds an element to a table if it is not already a member.
-- @param checkTable The table to add to.
-- @param element The element to add.
function LibEKL.Tools.Table.AddValue (checkTable, element)
    if type(checkTable) ~= "table" then
        LibEKL.Tools.Error.Display("LibEKL.Tools.Table", "checkTable must be a table", 2)
        return
    end

    if not LibEKL.Tools.Table.IsMember (checkTable, element) then
        tableInsert(checkTable, element)
    end
end


-- Removes an element from a table.
-- @param checkTable The table to remove from.
-- @param element The element to remove.
-- @return The modified table.
function LibEKL.Tools.Table.RemoveValue (checkTable, element)
    if type(checkTable) ~= "table" then
        LibEKL.Tools.Error.Display("LibEKL.Tools.Table", "checkTable must be a table", 2)
        return checkTable
    end

    local pos = LibEKL.Tools.Table.GetTablePos (checkTable, element)
    if pos ~= -1 then tableRemove(checkTable, pos) end
    
    return checkTable
end

-- Gets the sorted keys of a table.
-- @param tableData The table to get keys from.
-- @return A table of sorted keys.
function LibEKL.Tools.Table.GetSortedKeys (tableData)
    if type(tableData) ~= "table" then
        LibEKL.Tools.Error.Display("LibEKL.Tools.Table", "tableData must be a table", 2)
        return {}
    end

    local tempTable = {}
     
    for k, _ in pairs(tableData) do tableInsert(tempTable, k) end

    tableSort(tempTable, function (a, b) return stringLower(tostring(a)) < stringLower(tostring(b)) end)
    return tempTable
end


-- Merges two tables.
-- @param table1 The first table.
-- @param table2 The second table.
function LibEKL.Tools.Table.Merge (table1, table2)
    if type(table1) ~= "table" or type(table2) ~= "table" then
        LibEKL.Tools.Error.Display("LibEKL.Tools.Table", "table1 and table2 must be tables", 2)
        return
    end

    for _, v in pairs (table2) do tableInsert (table1, v) end
end

-- Merges two tables with indexed keys.
-- @param table1 The first table.
-- @param table2 The second table.
function LibEKL.Tools.Table.MergeIndexed (table1, table2)
    if type(table1) ~= "table" or type(table2) ~= "table" then
        LibEKL.Tools.Error.Display("LibEKL.Tools.Table", "table1 and table2 must be tables", 2)
        return
    end

    for k, v in pairs (table2) do table1[k] = v end
end

-- Gets the key of a value in a table.
-- @param tableData The table to search.
-- @param value The value to find.
-- @return The key of the value, or nil if not found
function LibEKL.Tools.Table.GetKeyByValue (tableData, value)
    if type(tableData) ~= "table" then
        LibEKL.Tools.Error.Display("LibEKL.Tools.Table", "tableData must be a table", 2)
        return nil
    end

    for k, v in pairs (tableData) do
        if v == value then return k end
    end
    
    return nil
end

-- Copies a table.
-- @param tableToCopy The table to copy.
-- @return A copy of the table.
function LibEKL.Tools.Table.Copy (tableToCopy)
    if type(tableToCopy) ~= "table" then
        LibEKL.Tools.Error.Display("LibEKL.Tools.Table", "tableToCopy must be a table", 2)
        return tableToCopy
    end

    local lookup_table = {}

    local function _copy(tableToCopy)
        if type(tableToCopy) ~= "table" then
            return tableToCopy
        elseif lookup_table[tableToCopy] then
            return lookup_table[tableToCopy]
        end
        local new_table = {}
        lookup_table[tableToCopy] = new_table
        for index, value in pairs(tableToCopy) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(tableToCopy))
    end

    return _copy(tableToCopy)
     
end

-- Gets the size of a table.
-- @param checkTable The table to check.
-- @return The size of the table.
function LibEKL.Tools.Table.GetSize (checkTable)
    if type(checkTable) ~= "table" then
        LibEKL.Tools.Error.Display("LibEKL.Tools.Table", "checkTable must be a table", 2)
        return 0
    end
  
    local count = 0
    for _ in pairs(checkTable) do count = count + 1 end
    return count   
end

-- Serializes a table to a string.
-- @param inTable The table to serialize.
-- @return A string representation of the table.
function LibEKL.Tools.Table.Serialize (inTable)
    if type(inTable) ~= "table" then
        LibEKL.Tools.Error.Display("LibEKL.Tools.Table", "inTable must be a table", 2)
        return inTable
    end

    local retValue = ""
    local isFirst = true

    for k, v in pairs (inTable) do
        if isFirst == false then retValue = retValue .. ',' end
    
        if type(k) == 'string' then
            if stringFind(k, " ") or stringFind(k, "-") or stringFind (k, ".", 1, true) then
                retValue = retValue .. '["' .. k .. '"]= '
            else
                retValue = retValue .. k .. '= '
            end
        end
    
        if type(v) == 'table' then
            retValue = retValue .. "{" .. LibEKL.Tools.Table.Serialize (v) .. "}"
        elseif type(v) == 'string' then
            retValue = retValue .. '"' .. v .. '"'
        elseif type(v) == 'boolean' then
            if v == true then
                retValue = retValue .. "true"
            else
                retValue = retValue .. "false"
            end
        elseif type(v) == 'function' then
            retValue = retValue .. '{function}'
        else
            retValue = retValue .. v
        end
        
        isFirst = false
    end
    
    return retValue
end

-- Gets the first element of a table.
-- @param checkTable The table to check.
-- @return The key and value of the first element, or nil if the table is empty.
function LibEKL.Tools.Table.GetFirstElement (checkTable)
    if type(checkTable) ~= "table" then
        LibEKL.Tools.Error.Display("LibEKL.Tools.Table", "checkTable must be a table", 2)
        return nil, nil
    end

    for key, content in pairs (checkTable) do
        return key, content
    end
    
    return nil, nil
end

-- Gets the last element of a table.
-- @param checkTable The table to check.
-- @return The key and value of the last element, or nil if the table is empty.
function LibEKL.Tools.Table.GetLastElement (checkTable)
    if type(checkTable) ~= "table" then
        LibEKL.Tools.Error.Display("LibEKL.Tools.Table", "checkTable must be a table", 2)
        return nil, nil
    end
    
    local retKey, retContent

    for key, content in pairs (checkTable) do
        retKey, retContent = key, content
    end
    
    return retKey, retContent

end