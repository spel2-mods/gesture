---@alias PLAY_TYPE integer
PLAY_TYPE = {
    UNKNOWN = 0,
    LOCAL = 1,
    ONLINE = 2
}

local online_data = {
    play_type = PLAY_TYPE.LOCAL,
    local_player_slot = 1
}

set_callback(function()
    local state = get_local_state()
    if state.screen == SCREEN.MENU then
        online_data.play_type = PLAY_TYPE.LOCAL
    elseif state.screen == SCREEN.ONLINE_LOBBY then
        online_data.play_type = PLAY_TYPE.ONLINE
        online_data.local_player_slot = online.lobby.local_player_slot
    end
end, ON.SCREEN)

return online_data
