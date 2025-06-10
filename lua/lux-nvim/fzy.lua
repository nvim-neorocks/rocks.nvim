---@mod rocks.fzy fzy helpers
---
---@brief [[
---
--- Provides an adapter to fzy
---
---@brief ]]

local fzy_adapter = {}

local fzy = require("fzy")

---@alias index integer
---@alias fzy_position integer
---@alias score number
---@alias FzyResult { [1]: index, [2]: fzy_position[], [3]: score }
---@alias FzyResults FzyResult[]

---Fuzzy-filter a list of items.
---@param query string The query to fuzzy-match.
---@param items string[] The items to search.
---@param opts? FuzzyFilterOpts Filtering options.
---@return string[] matching_items
function fzy_adapter.fuzzy_filter(query, items, opts)
    opts = opts or { sort = true }
    local fzy_results = fzy.filter(query, items) or {}
    if opts.sort then
        table.sort(fzy_results, function(a, b)
            ---@cast a FzyResult
            ---@cast b FzyResult
            local score_a = a[3]
            local score_b = b[3]
            return score_a > score_b
        end)
    end
    return vim.iter(fzy_results)
        :map(function(fzy_result)
            ---@cast fzy_result FzyResult
            local idx = fzy_result[1]
            return items[idx]
        end)
        :totable()
end

return fzy_adapter
