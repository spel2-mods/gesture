local module = {}

module.default_values = {}

---@generic T
---@param cb T @extends function
---@param default_value_at integer
---@return T
local function wrap_register_option(cb, default_value_at)
    return function(...)
        local args = {...}
        local name = args[1]
        local default_value = args[default_value_at]
        module.default_values[name] = default_value
        return cb(...)
    end
end

module.register_option_int = wrap_register_option(register_option_int, 4)
module.register_option_float = wrap_register_option(register_option_float, 4)
module.register_option_bool = wrap_register_option(register_option_bool, 4)
module.register_option_string = wrap_register_option(register_option_string, 4)
module.register_option_combo = wrap_register_option(register_option_combo, 5)

---@generic T
---@param _ T @extends function
---@param default_value_at integer
---@return T
local function wrap_register_hidden_option(_, default_value_at)
    return function(...)
        local args = {...}
        local name = args[1]
        local default_value = args[default_value_at]
        module.default_values[name] = default_value
    end
end

--- options only can be edited via save file
--- same interface as register_option_*
module.register_hidden_option_int = wrap_register_hidden_option(register_option_int, 4)
module.register_hidden_option_float = wrap_register_hidden_option(register_option_float, 4)
module.register_hidden_option_bool = wrap_register_hidden_option(register_option_bool, 4)
module.register_hidden_option_string = wrap_register_hidden_option(register_option_string, 4)
module.register_hidden_option_combo = wrap_register_hidden_option(register_option_combo, 5)

---@param name string
---@param value any
module.register_hidden_option = function(name, value)
    module.default_values[name] = value
end

---@param name string
function module.unregister_option(name)
    module.default_values[name] = nil
    return unregister_option(name)
end

function module.load_default_options()
    for name, default_value in pairs(module.default_values) do
        if options[name] == nil then
            options[name] = default_value
        end
    end
end

return module
