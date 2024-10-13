---@alias PLAYLUNKY_VERSION integer
PLAYLUNKY_VERSION = {
    STABLE = 1,
    NIGHTLY = 2,
    NIGHTLY_ONLINE = 3
}

---@type PLAYLUNKY_VERSION
local playluinky_version = PLAYLUNKY_VERSION.STABLE

if get_local_state ~= nil then
    playluinky_version = PLAYLUNKY_VERSION.NIGHTLY

    local state = get_local_state()
    if state.user_data == nil then
        if pcall(function() state.user_data = {} end) then
            playluinky_version = PLAYLUNKY_VERSION.NIGHTLY_ONLINE
            state.user_data = nil
        end
    else
        playluinky_version = PLAYLUNKY_VERSION.NIGHTLY_ONLINE
    end
end

return playluinky_version
