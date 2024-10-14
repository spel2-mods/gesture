---@diagnostic disable: lowercase-global

---@generic T
---@param t T
---@return T
function shallow_clone_table(t)
    local new_t = {}
    for k, v in pairs(t) do
        new_t[k] = v
    end
    return new_t
end
