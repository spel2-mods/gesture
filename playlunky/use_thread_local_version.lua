---@diagnostic disable: lowercase-global

---@return StateMemory
get_state = function()
    return state
end

if get_local_state then
    get_state = get_local_state
end

get_players = function()
    return players
end

if get_local_players then
    get_players = get_local_players
end
