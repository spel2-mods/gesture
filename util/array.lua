---@diagnostic disable: lowercase-global

---@generic T
---@param n integer
---@param v T
---@return T[] @size: n
function array(n, v)
    local t = {}
    for i = 1, n do
        t[i] = v
    end
    return t
end

---@generic T
---@param n integer
---@param cb fun(): T
---@return T[] @size: n
function array_fillwith(n, cb)
    local t = {}
    for i = 1, n do
        t[i] = cb()
    end
    return t
end
