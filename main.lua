meta = {
	name = "gesture",
	version = "0.1",
	description = "gesture visualizer",
	author = "fienestar",
    online_safe = true
}

---require "./spel2.lua"
---@diagnostic disable: lowercase-global

MAX_PLAYERS = CONST.MAX_PLAYERS
INPUT_READER_BUFFER_SIZE = 60

---@alias MODE integer
MODE = {
    COMPAT_WITH_VANILA = 1,
    NATURAL_CONTROL = 2,
}

register_option_int("font_size", "font size", "", 32, 16, 256)
register_option_combo("mode", "Mode", "", "Compat with vanila\0Natural Control(experimental, every player must use same mode)\0\0", MODE.COMPAT_WITH_VANILA)

set_callback(function(save_ctx)
    local save_data_str = json.encode({
		["version"] = meta.version,
		["options"] = options
	})
    save_ctx:save(save_data_str)
end, ON.SAVE)

set_callback(function(load_ctx)
    local save_data_str = load_ctx:load()
    if save_data_str ~= "" then
        local save_data = json.decode(save_data_str)
		if save_data.options then
			options = save_data.options
			if options.font_size == nil then
				options.font_size = 32
			end

            if options.mode == nil then
                options.mode = MODE.COMPAT_WITH_VANILA
            end
		end
    end
end, ON.LOAD)

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

GESTURE = {
    NONE = 0,

    HELP = 1,
    WAIT_PLEASE = 2,
    READY_TO_EXIT = 3,
    RESTART_GAME = 4,

    I_AM_DEAD = 5,
    ITEM_LEFT = 6,
    DROP_ITEM = 7,
    AFK = 8,

    OH_NO = 9,
    YAY = 10,
    CHEER_UP = 11,
    SORRY = 12,
}
---@alias GESTURE integer

GESTURE_SELECT_SPACE = {
    { GESTURE.NONE },
    { GESTURE.NONE, GESTURE.HELP, GESTURE.WAIT_PLEASE, GESTURE.READY_TO_EXIT, GESTURE.RESTART_GAME },
    { GESTURE.NONE, GESTURE.I_AM_DEAD, GESTURE.ITEM_LEFT, GESTURE.DROP_ITEM, GESTURE.AFK },
    { GESTURE.NONE, GESTURE.OH_NO, GESTURE.YAY, GESTURE.CHEER_UP, GESTURE.SORRY },
}

GESTURE_CUSTOM_DURATION = {
    [GESTURE.READY_TO_EXIT] = 3600
}

---@param gesture GESTURE
function stringify_gesture(gesture)
    if gesture == GESTURE.NONE then
        return "NONE"
    elseif gesture == GESTURE.HELP then
        return "HELP"
    elseif gesture == GESTURE.WAIT_PLEASE then
        return "WAIT_PLEASE"
    elseif gesture == GESTURE.READY_TO_EXIT then
        return "READY_TO_EXIT"
    elseif gesture == GESTURE.RESTART_GAME then
        return "RESTART_GAME"
    elseif gesture == GESTURE.I_AM_DEAD then
        return "I_AM_DEAD"
    elseif gesture == GESTURE.ITEM_LEFT then
        return "ITEM_LEFT"
    elseif gesture == GESTURE.DROP_ITEM then
        return "DROP_ITEM"
    elseif gesture == GESTURE.AFK then
        return "AFK"
    elseif gesture == GESTURE.OH_NO then
        return "OH_NO"
    elseif gesture == GESTURE.YAY then
        return "YAY"
    elseif gesture == GESTURE.CHEER_UP then
        return "CHEER_UP"
    elseif gesture == GESTURE.SORRY then
        return "SORRY"
    end

    return "INVALID"
end

---@class GestureAnimation
---@field gesture GESTURE
---@field frame_begin integer

---@class GestureInputState
---@field prev_buttons integer
---@field door_frame_begin integer
---@field x integer
---@field y integer

---@alias GESTURE_INPUT integer
GESTURE_INPUT = {
    NONE = 0,
    UP = 1,
    DOWN = 2,
}

---@class InputCandidate
---@field frame_count integer
---@field last_frame integer

---@return InputCandidate
function initial_input_candidate()
    return {
        frame_count = 0,
        last_frame = 0
    }
end

---@class InputReader
---@field buffer integer[]
---@field cur integer
---@field candidates InputCandidate[]

---@return InputReader
function initial_input_reader()
    local InputReader = {
        cur = GESTURE_INPUT.NONE,
        last_frame = 0,
        candidates = array_fillwith(MAX_PLAYERS, initial_input_candidate)
    }

    ---@param gesture_input GESTURE_INPUT
    ---@param frame integer
    function InputReader:push(gesture_input, frame)
        local candidate = self.candidates[gesture_input]
        if frame - candidate.last_frame >= 3 then
            candidate.frame_count = 0
        end

        candidate.frame_count = candidate.frame_count + 1
        candidate.last_frame = frame

        if candidate.frame_count == 3 then
            self.cur = gesture_input
            self.last_frame = frame

            for other = 1, 3 do
                if other ~= gesture_input then
                    self.candidates[other].frame_count = 0
                end
            end
        end
    end

    ---@param input INPUTS
    ---@param frame integer
    function InputReader:read(input, frame)
        if test_mask(input, INPUTS.UP) then
            self:push(GESTURE_INPUT.UP, frame)
        elseif test_mask(input, INPUTS.DOWN) then
            self:push(GESTURE_INPUT.DOWN, frame)
        end
    end

    ---@param gesture_input GESTURE_INPUT
    ---@param frame integer
    ---@return boolean
    function InputReader:pressed(gesture_input, frame)
        return self.last_frame == frame and self.cur == gesture_input
    end

    return InputReader
end

---@return GestureInputState
function initial_gesture_input_state()
    return {
        prev_buttons = 0,
        door_frame_begin = -1,
        x = 0,
        y = 0
    }
end

GESTURE_DISPLAY_FRAMES = 20

---@class PlayerGestureState
---@field cur_ges GestureAnimation
---@field ges_input_state GestureInputState

---@return PlayerGestureState
function initial_player_gesture_state()
    return {
        cur_ges = {
            gesture = GESTURE.NONE,
            frame_begin = -GESTURE_DISPLAY_FRAMES
        },
        ges_input_state = initial_gesture_input_state()
    }
end

---@class SyncStorage
---@field player_ges_states PlayerGestureState[] @size: MAX_PLAYERS

---@return SyncStorage
function initial_sync_storage()
    return {
        player_ges_states = array_fillwith(MAX_PLAYERS, initial_player_gesture_state),
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

---@alias PLAY_TYPE integer
PLAY_TYPE = {
    UNKNOWN = 0,
    LOCAL = 1,
    ONLINE = 2
}

local play_type = PLAY_TYPE.LOCAL
local local_player_slot = 1

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

---@param frame integer
---@param slot integer
---@param input_slot PlayerSlot
---@param gstate PlayerGestureState
function process_player_input(frame, slot, input_slot, gstate)
    local ges_input_state = gstate.ges_input_state
    local prev_buttons = ges_input_state.prev_buttons
    local buttons = input_slot.buttons_gameplay
    local door_pressed = test_mask(buttons, INPUTS.DOOR)
    local prev_door_pressed = test_mask(prev_buttons, INPUTS.DOOR)

    ---@param input INPUTS
    function pressed(input)
        return test_mask(buttons, input) and not test_mask(prev_buttons, input)
    end

    if pressed(INPUTS.DOOR) and (buttons & (INPUTS.LEFT | INPUTS.RIGHT)) == 0 then
        print('pressed door!')
        ges_input_state.door_frame_begin = frame
    elseif door_pressed and prev_door_pressed then
        local initialized = ges_input_state.x ~= 0
        if not initialized then
            if (buttons & (INPUTS.LEFT | INPUTS.RIGHT)) ~= 0 then
                ges_input_state.door_frame_begin = frame + 1
            elseif frame - ges_input_state.door_frame_begin >= 10 then
                ges_input_state.x = 1
                ges_input_state.y = 1
                print('listening input...')
            end
        end

        if initialized then
            if options.mode == MODE.NATURAL_CONTROL and slot == local_player_slot then
                buttons = buttons & ~INPUTS.DOWN

                if ges_input_state.y >= 2 and test_mask(buttons, INPUTS.UP)  then
                    buttons = buttons & ~INPUTS.UP
                end

                if ges_input_state.y == 1 then
                    buttons = buttons & ~INPUTS.LEFT
                end

                if test_mask(buttons, INPUTS.RIGHT) then
                    buttons = (buttons & ~INPUTS.RIGHT) | INPUTS.DOWN
                end
    
                if test_mask(buttons, INPUTS.LEFT) then
                    buttons = (buttons & ~INPUTS.LEFT) | INPUTS.UP
                end
            end
            
            if (buttons & (INPUTS.LEFT | INPUTS.RIGHT)) ~= 0 then
                ges_input_state.x = 0
                ges_input_state.y = 0
                ges_input_state.door_frame_begin = frame + 1
            else
                if pressed(INPUTS.UP) then
                    if ges_input_state.y >= 2 then
                        ges_input_state.y = ges_input_state.y - 1
                    else
                        ges_input_state.x = ges_input_state.x % #GESTURE_SELECT_SPACE + 1
                    end
                elseif pressed(INPUTS.DOWN) then
                    ges_input_state.y = ges_input_state.y % #GESTURE_SELECT_SPACE[ges_input_state.x] + 1
                end

                print('gesture#' .. slot .. ': ' .. ges_input_state.x .. ', ' .. ges_input_state.y)
            end
        end
    elseif prev_door_pressed and not door_pressed then
        if ges_input_state.x ~= 0 then
            local gesture = GESTURE_SELECT_SPACE[ges_input_state.x][ges_input_state.y]
            print('gesture#' .. slot .. ': ' .. stringify_gesture(gesture))
            if gesture ~= GESTURE.NONE then
                gstate.cur_ges = {
                    gesture = gesture,
                    frame_begin = frame
                }
            end

            ges_input_state.x = 0
            ges_input_state.y = 0
        end
    end

    input_slot.buttons_gameplay = buttons
    ges_input_state.prev_buttons = buttons
end

set_callback(function()
    if options.mode ~= MODE.COMPAT_WITH_VANILA then
        return
    end

    local data = get_sync_storage()
    local state = get_state()
    local frame = get_frame()
    for slot = 1, MAX_PLAYERS do
        process_player_input(frame, slot, state.player_inputs.player_slots[slot], data.player_ges_states[slot])
    end
end, ON.GAMEFRAME)

set_callback(function()
    if options.mode ~= MODE.NATURAL_CONTROL then
        return
    end
    
    local data = get_sync_storage()
    local state = get_state()
    local frame = get_frame()
    for slot = 1, MAX_PLAYERS do
        process_player_input(frame, slot, state.player_inputs.player_slots[slot], data.player_ges_states[slot])
    end
end, ON.PRE_UPDATE)

set_callback(function()
    local state = get_local_state()
    local data = get_sync_storage()
    if state.screen == SCREEN.MENU then
        play_type = PLAY_TYPE.LOCAL
    elseif state.screen == SCREEN.ONLINE_LOBBY then
        play_type = PLAY_TYPE.ONLINE
        local_player_slot = online.lobby.local_player_slot
    end
    print('screen: ' .. state.screen)
end, ON.SCREEN)

---@param ctx GuiDrawContext
set_callback(function(ctx)
    local state = get_local_state()
    if state.pause ~= 0 then
		return
	end

    local data = get_sync_storage()
    local frame = get_frame()
    local players = get_players()

    for slot = 1, MAX_PLAYERS do
        local gstate = data.player_ges_states[slot]
        local gesture = gstate.cur_ges.gesture
        local elapsed = frame - gstate.cur_ges.frame_begin
        local duration = GESTURE_CUSTOM_DURATION[gesture] or GESTURE_DISPLAY_FRAMES
        if gesture == GESTURE.NONE or elapsed >= duration then
            goto continue
        end

        local x = -1.15 + slot * 0.32
        local y = 0.75
        local text = stringify_gesture(gesture)
        local font_size = options.font_size
        local width32, _ = draw_text_size(font_size, text)
        ctx:draw_text(x + width32/2, y, font_size, text, rgba(243, 137, 215, 150))

        player = players[slot]

        if player == nil or player.health == 0 then
            player = get_playerghost(slot)
        end

        if player == nil then
            goto continue
        end

        ex, ey, el = get_render_position(player.uid)
        hitbox = get_render_hitbox(player.uid)
        sx, sy = screen_position(hitbox.left, hitbox.bottom)

        ctx:draw_text(sx, sy, font_size, text, rgba(243, 137, 215, 75))
        ::continue::
    end

    local gesture_select_ui_slots = { 1, 2, 3, 4 }
    if play_type == PLAY_TYPE.ONLINE then
        gesture_select_ui_slots = { local_player_slot }
    end
    
    for _, slot in ipairs(gesture_select_ui_slots) do
        local gstate = data.player_ges_states[slot]
        local ges_input_state = gstate.ges_input_state

        if ges_input_state.x == 0 then
            goto continue
        end

        local x = 0
        local y = 0
        if play_type == PLAY_TYPE.LOCAL then
            x = 0
            y = 0
        elseif play_type == PLAY_TYPE.ONLINE then
            x = slot - 1
            y = 0
        end
        local text = ''
        if ges_input_state.x ~= 0 then
            text = stringify_gesture(GESTURE_SELECT_SPACE[ges_input_state.x][ges_input_state.y])
        end
        ctx:draw_text(x, y + 16, 16, text, rgba(255, 255, 255, 255))
        ::continue::
    end
end, ON.GUIFRAME)
