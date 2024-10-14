local option_utils = require "util.option"

--- only for json_encode_save_data
--- I don't want to split lines and add indent recursively..
---@param tbl table<string, string|boolean|number|nil>
local function json_encode_flat_table_pretty(tbl)
    local output = ""
    local kv_pairs = {}

    for key, value in pairs(tbl) do
        kv_pairs[#kv_pairs+1] = {key, value}
    end

    table.sort(kv_pairs, function(a, b) return a[1] < b[1] end)

    for i, kv_pair in pairs(kv_pairs) do
        local key_str = json.encode(kv_pair[1])
        local value_str = json.encode(kv_pair[2])
        output = output .. '\n    ' .. key_str .. ': ' .. value_str
        if i ~= #kv_pairs then
            output = output .. ","
        end
    end

    if output == "" then
        return "{}"
    else
        return "{" .. output .. "\n  }"
    end
end

local function json_encode_save_data(save_format_version)
    local output = "{"
    output = output .. '\n  "version": ' .. json.encode(save_format_version) .. ","
    output = output .. '\n  "options": ' .. json_encode_flat_table_pretty(options)
    output = output .. "\n}"
    return output
end

---@param save_format_version string
---@param cb fun(save_format_version: string)
return function(save_format_version, cb)
    --- Pretty encoding is not supported, json.encode() only encodes to a compact format :(
    --- https://github.com/rxi/json.lua
    set_callback(function(save_ctx)
        local save_data_str = json_encode_save_data(save_format_version)
        save_ctx:save(save_data_str)
    end, ON.SAVE)

    set_callback(function(load_ctx)
        local save_data_str = load_ctx:load()
        if save_data_str ~= "" then
            local save_data = json.decode(save_data_str)
            if save_data.options then
                options = save_data.options
                option_utils.load_default_options()
                cb(save_format_version)
            end
        end
    end, ON.LOAD)

    option_utils.load_default_options()
end
