meta = {
	name = "gesture",
	version = "0.1",
	description = "gesture visualizer",
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

GESTURE_DISPLAY_FRAMES = 10

---@alias GESTURE_INPUT integer
NONE = 0
UP = 1
DOWN = 2
ATTACK = 3

GESTURES = {
    NONE = -1,

    -- UP + DOWN + ..
    HELP = 0,
    WAIT_PLEASE = 1,
    READY_TO_EXIT = 2,
    RESTART_GAME = 3,

    -- ATTACK + 
    I_AM_DEAD = 4,
    ITEM_LEFT = 5,
    DROP_ITEM = 6,
    AFK = 7,

    -- DOWN + UP + ..
    OH_NO = 8,
    YAY = 9,
    CHEER_UP = 10,
    SORRY = 11,
}

---@param gesture integer
function stringify_gesture(gesture)
    if gesture == GESTURES.NONE then
        return "NONE"
    elseif gesture == GESTURES.HELP then
        return "HELP"
    elseif gesture == GESTURES.WAIT_PLEASE then
        return "WAIT_PLEASE"
    elseif gesture == GESTURES.READY_TO_EXIT then
        return "READY_TO_EXIT"
    elseif gesture == GESTURES.RESTART_GAME then
        return "RESTART_GAME"
    elseif gesture == GESTURES.I_AM_DEAD then
        return "I_AM_DEAD"
    elseif gesture == GESTURES.ITEM_LEFT then
        return "ITEM_LEFT"
    elseif gesture == GESTURES.DROP_ITEM then
        return "DROP_ITEM"
    elseif gesture == GESTURES.AFK then
        return "AFK"
    elseif gesture == GESTURES.OH_NO then
        return "OH_NO"
    elseif gesture == GESTURES.YAY then
        return "YAY"
    elseif gesture == GESTURES.CHEER_UP then
        return "CHEER_UP"
    elseif gesture == GESTURES.SORRY then
        return "SORRY"
    end
    return "INVALID"
end



GESTURE_BUFFER_LENGTH = 10
GESTURE_TIMEOUT_FRAMES = 90
GESTURE_INPUT_KEEP_FRAMES = 3

GESTURE_DECISION_TREE = {
    NO_HINT = 1,
    [UP] = {
        NO_HINT = 1,
        [DOWN] = {
            [UP] = {
                [UP] = GESTURES.HELP,
                [DOWN] = GESTURES.WAIT_PLEASE
            },
            [DOWN] = {
                [UP] = GESTURES.READY_TO_EXIT,
                [DOWN] = GESTURES.RESTART_GAME
            }
        }
    },

    [ATTACK] = {
        NO_HINT = 1,
        [DOWN] = {
            [UP] = {
                [UP] = GESTURES.HELP,
                [DOWN] = GESTURES.WAIT_PLEASE
            },
            [DOWN] = {
                [UP] = GESTURES.READY_TO_EXIT,
                [DOWN] = GESTURES.RESTART_GAME
            }
        }
    },

    [DOWN] = {
        NO_HINT = 1,
        [UP] = {
            [UP] = {
                [UP] = GESTURES.OH_NO,
                [DOWN] = GESTURES.YAY
            },
            [DOWN] = {
                [UP] = GESTURES.CHEER_UP,
                [DOWN] = GESTURES.SORRY
            }
        }
    }
}

---@param inputs table<integer, integer>
---@param input_frame_count integer
---@return integer | table | nil
function get_gesture_node(inputs, input_frame_count)
    local cur = GESTURE_DECISION_TREE
    local last = #inputs
    
    if input_frame_count < GESTURE_INPUT_KEEP_FRAMES then
        last = last - 1
    end

    for i = 1, last do
        local input = inputs[i]
        if input == NONE then
            goto continue
        end

        cur = cur[input]
        if cur == nil then
            return nil
        end

        if type(cur) == "number" then
            return cur
        end

        ::continue::
    end

    return cur
end

---@class GestureInputState
---@field inputs table<integer, integer>
---@field index integer
---@field frame_count integer
---@field is_end boolean

function initial_gesture_input_state()
    return {
        inputs = array(GESTURE_BUFFER_LENGTH, NONE),
        index = 0,
        frame_count = 0,
        is_end = false
    }
end

---@class Gesture
---@field gesture_id integer
---@field frame_begin integer

---@class PlayerGestureState
---@field current_gesture Gesture
---@field gesture_input_state GestureInputState

---@return PlayerGestureState
function initial_player_gesture_state()
    return {
        current_gesture = {
            gesture_id = GESTURES.NONE,
            frame_begin = -GESTURE_DISPLAY_FRAMES
        },
        gesture_input_state = initial_gesture_input_state()
    }
end

---@class SyncStorage
---@field player_gesture_states table<integer, PlayerGestureState>
---@field local_player_slot integer

---@return SyncStorage
function initial_sync_storage()
    return {
        player_gesture_states = array(4, initial_gesture_input_state()),
        local_player_slot = 1,
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

local _storage = {}
function get_storage()
    return _storage
end

---@param state StateMemory
---@param frame integer
---@param sync_storage SyncStorage
---@param slot integer
function read_gesture_from_player_input(state, frame, sync_storage, slot)
    local i = sync_storage.[slot]
    local input = state.player_inputs.player_slots[slot].buttons

    if input & INPUTS.UP == INPUTS.UP then
        input = UP
    elseif input & INPUTS.WHIP == INPUTS.WHIP then
        input = ATTACK
    elseif input & INPUTS.DOWN == INPUTS.DOWN then
        input = DOWN
    else
        return
    end

    if sync_storage.player_last_input_frame[slot] + GESTURE_TIMEOUT_FRAMES < frame then
        i = 0
    end

    if i ~= 0 then
        if sync_storage.player_input[slot][i] == input then
            sync_storage.player_input_frame_count[slot] = sync_storage.player_input_frame_count[slot] + 1
        else
            if sync_storage.player_input_frame_count[slot] >= GESTURE_INPUT_KEEP_FRAMES then
                if i > GESTURE_MAX_LENGTH then
                    i = 0
                end
                i = i + 1
                sync_storage.player_input_frame_count[slot] = 1
            end
            sync_storage.player_input[slot][i] = input
            sync_storage.player_input_frame_count[slot] = 1
        end

        local node = get_gesture_node(
            sync_storage.player_input[slot],
            sync_storage.player_input_frame_count[slot]
        )

        if type(node) == "number" then
            if sync_storage.player_current_gesture[slot] == node then
                if sync_storage.player_current_gesture_frame_begin[slot] - frame < GESTURE_DISPLAY_FRAMES then
                    sync_storage.player_current_gesture_frame_begin[slot] = frame
                end
            else
                sync_storage.player_current_gesture[slot] = node
                sync_storage.player_current_gesture_frame_begin[slot] = frame
            end

        end

        if type(node) ~= "table" then
            i = 0
        end
    else
        i = 1
        sync_storage.player_input[slot][i] = input
        sync_storage.player_input_frame_count[slot] = 1
    end

    debug_str = ""
    for j = 1, i do
        debug_str = debug_str .. stringify_gesture_input(sync_storage.player_input[slot][j]) .. " "
    end
    debug_str = debug_str .. sync_storage.player_input_frame_count[slot] .. ' ' .. i
    debug_str = debug_str .. ' ' .. stringify_gesture(sync_storage.player_current_gesture[slot])

    print(debug_str)

    sync_storage.player_last_input_frame[slot] = frame
    sync_storage.player_input_index[slot] = i
end

-- read emotion from player input
set_callback(function()
    local sync_storage = get_sync_storage()
    local state = get_state()
    local frame = get_frame()

    for slot = 1, 4 do
        read_gesture_from_player_input(state, frame, sync_storage, slot)
    end
end, ON.FRAME)

function stringify_gesture_input(input)
    if input == UP then
        return "UP"
    elseif input == DOWN then
        return "DOWN"
    elseif input == ATTACK then
        return "ATTACK"
    end
    return "INVALID"
end

function stringify_hint(node)
    local output = {}
    local output_index = 1
    function helper(cur, key)
        if type(cur) == "number" then
            output[output_index] = key .. "-" .. stringify_gesture(cur)
        end

        for k, v in pairs(cur) do
            if k ~= "NO_HINT" then
                helper(v, key .. "-" .. stringify_gesture_input(k))
            end
        end
    end

    helper(node, "")

    return table.concat(output, " | ")
end

set_callback(function(ctx)
	local sync_storage = get_sync_storage()
    local frame = get_frame()
	
	for i = 1, 4 do
        local node = get_gesture_node(
            sync_storage.player_input[i],
            sync_storage.player_input_frame_count[i]
        )
        local gesture = sync_storage.player_current_gesture[i]
        local frame_begin = sync_storage.player_current_gesture_frame_begin[i]

        if frame - frame_begin < GESTURE_DISPLAY_FRAMES then
            local x = -0.98 + (i - 1) * 0.3
            local y = -1 - 5.5 * 0.1
            local color = rgba(243, 137, 215, 75)

            ctx:draw_text(x, y, 0.1, stringify_gesture(gesture), color)
            print('gesture: ' .. stringify_gesture(gesture))
        elseif type(node) == "table" and node.NO_HINT == nil then
            local x = -0.98 + (i - 1) * 0.3
            local y = -1 - 5.5 * 0.1
            local color = rgba(243, 137, 215, 75)

            ctx:draw_text(x, y, 0.1, stringify_hint(node), color)
            print('hint: ' .. stringify_hint(node))
        end
    end
end, ON.GUIFRAME)
