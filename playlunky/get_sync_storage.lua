---@diagnostic disable: lowercase-global

local playluinky_version = require("playlunky.version")

local function init_sync_storage(initial_sync_storage)
    local state = get_local_state()
    state.user_data = initial_sync_storage
end

---@generic SyncStorage
---@param initial_sync_storage SyncStorage
---@return fun(): SyncStorage
return function(initial_sync_storage)
    if playluinky_version ~= PLAYLUNKY_VERSION.NIGHTLY_ONLINE then
        return function()
            return initial_sync_storage
        end
    end

    init_sync_storage(initial_sync_storage)

    return function()
        local state = get_state()
        return state.user_data
    end
end
