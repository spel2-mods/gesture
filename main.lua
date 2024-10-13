meta = {
	name = "test: send random data using journal key",
	version = "0.1",
	description = "gesture -> send data -> emotion",
	author = "fienestar",
    online_safe = true
}

---require "./spel2.lua"
---@diagnostic disable: lowercase-global

function array(n, v)
    local t = {}
    for i = 1, n do
        t[i] = v
    end
    return t
end

local EMOTION_FRAME_DURATION = 6
--- 101 000 ~ 101 110
--- reserve 101 111 for future use
local EMOTION_UI_DURATION = 6
local EMOTION_COOLDOWN_DURATION = EMOTION_FRAME_DURATION * 2 - 1

---@class SyncStorage
---@field player_input table
---@field player_emotion table
---@field write_frame_begin integer

---@return SyncStorage
function initial_sync_storage()
    return {
        player_input = {
            [1] = array(EMOTION_FRAME_DURATION, INPUTS.NONE),
            [2] = array(EMOTION_FRAME_DURATION, INPUTS.NONE),
            [3] = array(EMOTION_FRAME_DURATION, INPUTS.NONE),
            [4] = array(EMOTION_FRAME_DURATION, INPUTS.NONE)
        },
        player_emotion = {
            [1] = { 0, -EMOTION_UI_DURATION },
            [2] = { 0, -EMOTION_UI_DURATION },
            [3] = { 0, -EMOTION_UI_DURATION },
            [4] = { 0, -EMOTION_UI_DURATION }
        },
        write_frame_begin = -EMOTION_FRAME_DURATION,
    }
end

--#region base.lua

---@alias PLAYLUNKY_VERSION integer
PLAYLUNKY_VERSION = {
    STABLE = 0,
    NIGHTLY = 1,
    NIGHTLY_ONLINE = 2
}

---@type PLAYLUNKY_VERSION
local playlunky_version = PLAYLUNKY_VERSION.STABLE

get_state = function()
    return state
end

if get_local_state then
    get_state = get_local_state
    playlunky_version = PLAYLUNKY_VERSION.NIGHTLY
end

get_players = function()
    return players
end

if get_local_players then
    get_players = get_local_players
end

function init_user_data()
    get_local_state().user_data = initial_sync_storage()
end

if pcall(init_user_data) then
    playlunky_version = PLAYLUNKY_VERSION.NIGHTLY_ONLINE
end

local _sync_storage = initial_sync_storage()

---@return SyncStorage
function get_sync_storage()
    if playlunky_version == PLAYLUNKY_VERSION.NIGHTLY_ONLINE then
        return get_local_state().user_data
    else
        return _sync_storage
    end
end

--#endregion

--print("playlunky_version: " .. playlunky_version)

EMOTION_INPUT_STATE = {
    NONE = 0,
    PRESS_DOOR_WITHOUT_ARROW_KEY = 1,
    PRESS_DOOR_WITH_SELECT_KEY = 2
}

local _storage = {
    current_emotion = 0,
    prev_input = INPUTS.NONE,
    emotion_input_state = EMOTION_INPUT_STATE.NONE,
    local_player_slot = 1
}
function get_storage()
    return _storage
end

--- 101..
local HEADER_BIT_LENGTH = 3
local HEADER = 5
local HEADER_BIT = HEADER << (EMOTION_FRAME_DURATION - HEADER_BIT_LENGTH)
local CONTENT_BIT_LENGTH = EMOTION_FRAME_DURATION - HEADER_BIT_LENGTH
local CONTENT_BIT = (1 << CONTENT_BIT_LENGTH) - 1
local INPUTS_EMOTION_MEMU = INPUTS.DOOR
local INPUTS_ANY_SELECT = INPUTS.LEFT | INPUTS.RIGHT | INPUTS.UP | INPUTS.DOWN
local INPUTS_PROTOCOL_1 = INPUTS.JOURNAL

---@param state StateMemory
---@param frame integer
---@param sync_storage SyncStorage
---@param slot integer
function read_emotion_from_player_input(state, frame, sync_storage, slot)
    local player_input = sync_storage.player_input[slot]
    local frame_index = frame % EMOTION_FRAME_DURATION

    player_input[frame_index] = state.player_inputs.player_slots[slot].buttons_gameplay

    local data = 0
    local i = 1
    local j = (frame + 1) % EMOTION_FRAME_DURATION
    while i <= EMOTION_FRAME_DURATION do
        data = data << 1
        if (player_input[i] & INPUTS_PROTOCOL_1) == INPUTS_PROTOCOL_1 then
            data = data | 1
        end
        i = i + 1
        j = (j % EMOTION_FRAME_DURATION) + 1
    end

    ---print(toBinary(data))

    if (data & HEADER_BIT) == HEADER_BIT then
        local emotion = data & CONTENT_BIT
        sync_storage.player_emotion[slot] = { emotion, frame }
        print("GOT EMOTION FROM #" .. slot .. ": " .. emotion)
    end
end

-- read emotions from player input
set_callback(function()
    local sync_storage = get_sync_storage()
    local state = get_state()
    local frame = get_frame()

    for slot = 1, 4 do
        read_emotion_from_player_input(state, frame, sync_storage, slot)
    end
end, ON.GAMEFRAME)

-- write emotion to player input
set_callback(function()
    local sync_storage = get_sync_storage()
    local storage = get_storage()
    local frame = get_frame()
    local state = get_state()

    if state.world == 1 and state.level == 1 then
        storage.local_player_slot = online.lobby.local_player_slot
    end

    local local_player_slot = storage.local_player_slot
    local input = state.player_inputs.player_slots[local_player_slot].buttons_gameplay
    local prev_input = storage.prev_input
    storage.prev_input = input

    if frame >= sync_storage.write_frame_begin + EMOTION_COOLDOWN_DURATION then
        local journal_enabled = true
        if storage.emotion_input_state == EMOTION_INPUT_STATE.NONE then
            if (input & INPUTS_ANY_SELECT) == 0 and (input & INPUTS_EMOTION_MEMU) == INPUTS_EMOTION_MEMU then
                journal_enabled = false
                storage.emotion_input_state = EMOTION_INPUT_STATE.PRESS_DOOR_WITHOUT_ARROW_KEY
                print("start emotion input")
            end
        else
            if (input & INPUTS_EMOTION_MEMU) == 0 then
                storage.emotion_input_state = EMOTION_INPUT_STATE.NONE
                print("cancel emotion input")
            end
            journal_enabled = false

            if storage.emotion_input_state == EMOTION_INPUT_STATE.PRESS_DOOR_WITHOUT_ARROW_KEY then
                if (input & INPUTS_ANY_SELECT) ~= 0 then
                    storage.emotion_input_state = EMOTION_INPUT_STATE.PRESS_DOOR_WITH_SELECT_KEY
                end
            elseif (input & INPUTS_ANY_SELECT) == 0 and storage.emotion_input_state == EMOTION_INPUT_STATE.PRESS_DOOR_WITH_SELECT_KEY then
                storage.emotion_input_state = EMOTION_INPUT_STATE.NONE
                sync_storage.write_frame_begin = frame
                if (prev_input & INPUTS.UP) == INPUTS.UP then
                    storage.current_emotion = 0
                elseif (prev_input & INPUTS.RIGHT) == INPUTS.RIGHT then
                    storage.current_emotion = 1
                elseif (prev_input & INPUTS.DOWN) == INPUTS.DOWN then
                    storage.current_emotion = 2
                elseif (prev_input & INPUTS.LEFT) == INPUTS.LEFT then
                    storage.current_emotion = 3
                else
                    print("invalid input key")
                
                end
                print("matched emotion: " .. storage.current_emotion)
            end
        end

        set_journal_enabled(journal_enabled)
    end
end, ON.PRE_UPDATE)

set_callback(function()
    local sync_storage = get_sync_storage()
    local storage = get_storage()
    local state = get_state()
    if state.world == 1 and state.level == 1 then
        storage.local_player_slot = online.lobby.local_player_slot
    end
    local local_player_slot = storage.local_player_slot
    local player = get_players()[local_player_slot]

    player:set_pre_process_input(function(player)
        local frame = get_frame()

        if frame < sync_storage.write_frame_begin + EMOTION_COOLDOWN_DURATION then
            set_journal_enabled(false)

            local player_input_slot = state.player_inputs.player_slots[local_player_slot]
            local input = player_input_slot.buttons_gameplay
            input = input & ~INPUTS_PROTOCOL_1
            player_input_slot.buttons_gameplay = input
            
            local emotion_write_frame = frame - sync_storage.write_frame_begin

            if emotion_write_frame < 0 then
                sync_storage.write_frame_begin = frame
                emotion_write_frame = 0
            end
            
            print("emotion_write_frame: " .. emotion_write_frame)
            
            if emotion_write_frame < EMOTION_FRAME_DURATION then
                local output = 0

                -- assert(HEADER_BIT == 5)
                if emotion_write_frame < HEADER_BIT_LENGTH then
                    output = (emotion_write_frame+1) % 2 -- (HEADER_BIT & (1 << (EMOTION_FRAME_DURATION - emotion_write_frame))) >> (EMOTION_FRAME_DURATION - emotion_write_frame)
                elseif emotion_write_frame < EMOTION_FRAME_DURATION then
                    output = storage.current_emotion & (1 << (EMOTION_FRAME_DURATION - emotion_write_frame))
                end

                if output == 1 then
                    player_input_slot.buttons_gameplay = input | INPUTS_PROTOCOL_1
                end
            end
        end

        return false
    end)
end, ON.LEVEL)

set_callback(function(ctx)
	local state = get_state()
	
	if state.screen ~= SCREEN.LEVEL or state.level < 5 or state.pause ~= 0 then
		return
	end

	-- gui code here
    --[[
    example text
    local width32, _ = draw_text_size(FONT_SIZE, text)
	ctx:draw_text(x + width32/2, y, FONT_SIZE, text, rgba(243, 137, 215, 75))
    ]]--
end, ON.GUIFRAME)
