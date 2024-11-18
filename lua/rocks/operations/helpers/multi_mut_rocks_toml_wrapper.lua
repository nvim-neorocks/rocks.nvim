local fs = require("rocks.fs")

---@class MutRocksTomlRefWithPath
---@field config MutRocksTomlRef Config metatable
---@field path? string The path to the configuration

---@class MultiMutRocksTomlWrapper: MutRocksTomlRef
local MultiMutRocksTomlWrapper = {}

--- Table accessor: Retrieve the value of the key from the first matching inner table
---@param self MultiMutRocksTomlWrapper
---@param key string|integer
---@return any
MultiMutRocksTomlWrapper.__index = function(self, key)
    -- Give preference to class methods/fields
    if MultiMutRocksTomlWrapper[key] then
        return MultiMutRocksTomlWrapper[key]
    end
    -- Find the key within the config tables
    for _, tbl in ipairs(self.configs) do
        if tbl.config[key] ~= nil then
            if type(tbl.config[key]) == "table" then
                if not self.cache[key] then
                    self.cache[key] = MultiMutRocksTomlWrapper.new(vim.iter(self.configs)
                        :filter(function(v)
                            return type(v.config[key]) == "table"
                        end)
                        :fold({}, function(acc, v)
                            table.insert(acc, { config = v.config[key], path = v.path })
                            return acc
                        end))
                end
                return self.cache[key]
            else
                return tbl.config[key]
            end
        end
    end
    return nil
end

--- Table field assignment: Set value of the key from the first matching inner
--- table or the first table if not found in any
---@param self MultiMutRocksTomlWrapper
---@param key string|integer
---@param value any
MultiMutRocksTomlWrapper.__newindex = function(self, key, value)
    for _, tbl in ipairs(self.configs) do
        if tbl.config[key] ~= nil then
            tbl.config[key] = value
            return
        end
    end
    -- If key not found in any table, add it to the last table which should the base config
    self.configs[#self.configs].config[key] = value
end

--- Run a function against the config tables
---@param self MultiMutRocksTomlWrapper
---@param func fun(configs: MutRocksTomlRefWithPath[])
MultiMutRocksTomlWrapper.__call = function(self, func)
    func(self.configs)
end

--- Write the config tables to their appropriate paths in an async context
---@type async fun(self: MultiMutRocksTomlWrapper)
MultiMutRocksTomlWrapper._write_await = function(self)
    for _, tbl in ipairs(self.configs) do
        if tbl.path ~= nil then
            fs.write_file_await(tbl.path, "w", tostring(tbl.config))
        end
    end
end

--- Function to create a new wrapper
---@param configs MutRocksTomlRefWithPath[] A list of rocks toml configs
---@return MultiMutRocksTomlWrapper
function MultiMutRocksTomlWrapper.new(configs)
    assert(#configs > 0, "Must provide at least one rocks toml config")
    local self = { cache = {}, configs = configs }
    setmetatable(self, MultiMutRocksTomlWrapper)
    return self
end

return MultiMutRocksTomlWrapper
