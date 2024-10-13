meta = {
	name = "gesture",
	version = "0.1",
	description = "visualize gesture into chat",
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

options_default_value = {}

---@generic T
---@param cb T @extends function
---@param default_value_at integer
---@return T
function wrap(cb, default_value_at)
    return function(...)
        local args = {...}
        local name = args[1]
        local default_value = args[default_value_at]
        options_default_value[name] = default_value
        return cb(...)
    end
end

s_register_option_int = wrap(register_option_int, 4)
s_register_option_float = wrap(register_option_float, 4)
s_register_option_bool = wrap(register_option_bool, 4)
s_register_option_string = wrap(register_option_string, 4)
s_register_option_combo = wrap(register_option_combo, 5)

---@param name string
function s_unregister_option(name)
    options_default_value[name] = nil
    return unregister_option(name)
end

s_register_option_combo("mode", "Mode", "", "Compatible with Vanilla\0Natural Control(experimental, every player must use same mode)\0\0", MODE.COMPAT_WITH_VANILA)
s_register_option_bool("play_sound", "play sound", "", true)
s_register_option_bool("use_heart_color", "Use heart color", "", false)
s_register_option_float("font_scale", "font scale", "", 4, 0, 10000)

set_callback(function(save_ctx)
    local save_data_str = json.encode({
		["version"] = meta.version,
		["options"] = options
	})
    save_ctx:save(save_data_str)
end, ON.SAVE)

function load_default_options()
    for name, default_value in pairs(options_default_value) do
        if options[name] == nil then
            options[name] = default_value
        end
    end
end

set_callback(function(load_ctx)
    local save_data_str = load_ctx:load()
    if save_data_str ~= "" then
        local save_data = json.decode(save_data_str)
		if save_data.options then
			options = save_data.options
			load_default_options()
		end
    end
end, ON.LOAD)

load_default_options()

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
    NEED_RECONNECT = 5,
    CHECK_MESSENGER = 6,

    I_AM_DEAD = 7,
    ITEM_LEFT = 8,
    DISCARD_ITEM = 9,
    AFK = 10,

    OH_NO = 11,
    LOL = 12,
    CHEER_UP = 13,
    SORRY = 14,

    READY = 15,
}
---@alias GESTURE integer

DURATION_2_5S = 150
DURATION_15S = 900
DURATION_60S = 4 * DURATION_15S
DURATION_30D = DURATION_60S * 24 * 30
GESTURE_DISPLAY_DURATION_DEFAULT = DURATION_2_5S

GESTURE_DISPLAY_DURATION = {
    [GESTURE.NONE] = 0,

    [GESTURE.HELP] = DURATION_60S,
    [GESTURE.WAIT_PLEASE] = DURATION_60S,
    [GESTURE.READY_TO_EXIT] = DURATION_60S,
    [GESTURE.RESTART_GAME] = DURATION_60S,
    [GESTURE.NEED_RECONNECT] = DURATION_30D,
    [GESTURE.CHECK_MESSENGER] = DURATION_30D,

    [GESTURE.I_AM_DEAD] = DURATION_15S,
    [GESTURE.ITEM_LEFT] = DURATION_15S,
    [GESTURE.DISCARD_ITEM] = DURATION_15S,
    [GESTURE.AFK] = DURATION_30D,

    [GESTURE.OH_NO] = DURATION_2_5S,
    [GESTURE.LOL] = DURATION_2_5S,
    [GESTURE.CHEER_UP] = DURATION_2_5S,
    [GESTURE.SORRY] = DURATION_2_5S,

    [GESTURE.READY] = DURATION_30D,
}

GESTURE_PERSIST_ON_TRANSITION = {
    [GESTURE.RESTART_GAME] = true,
    [GESTURE.AFK] = true,
    [GESTURE.NEED_RECONNECT] = true,
    [GESTURE.CHECK_MESSENGER] = true
}

GESTURE_PRESIST_ON_RESTART = {
    [GESTURE.AFK] = true,
    [GESTURE.NEED_RECONNECT] = true,
    [GESTURE.CHECK_MESSENGER] = true
}

NO_SOUND = {}
COMPLETED_SOUND = { get_sound(VANILLA_SOUND.MENU_CHARSEL_SELECTION) }
WARNING_SOUND = { get_sound(VANILLA_SOUND.CUTSCENE_KEY_DROP) }
IMPORTANT_SOUND = { get_sound(VANILLA_SOUND.MENU_CHARSEL_SELECTION2) }

GESTURE_SOUND = {
    [GESTURE.HELP] = WARNING_SOUND,
    [GESTURE.WAIT_PLEASE] = WARNING_SOUND,
    [GESTURE.READY_TO_EXIT] = COMPLETED_SOUND,
    [GESTURE.RESTART_GAME] = IMPORTANT_SOUND,
    [GESTURE.NEED_RECONNECT] = IMPORTANT_SOUND,
    [GESTURE.CHECK_MESSENGER] = IMPORTANT_SOUND,

    [GESTURE.I_AM_DEAD] = WARNING_SOUND,
    [GESTURE.ITEM_LEFT] = WARNING_SOUND,
    [GESTURE.DISCARD_ITEM] = COMPLETED_SOUND,
    [GESTURE.AFK] = NO_SOUND,

    [GESTURE.OH_NO] = NO_SOUND,
    [GESTURE.LOL] = NO_SOUND,
    [GESTURE.CHEER_UP] = NO_SOUND,
    [GESTURE.SORRY] = NO_SOUND,
}

GESTURE_SELECT_SPACE = {
    { GESTURE.NONE },
    { GESTURE.NONE, GESTURE.HELP, GESTURE.WAIT_PLEASE, GESTURE.READY_TO_EXIT, GESTURE.RESTART_GAME, GESTURE.NEED_RECONNECT, GESTURE.CHECK_MESSENGER },
    { GESTURE.NONE, GESTURE.I_AM_DEAD, GESTURE.ITEM_LEFT, GESTURE.DISCARD_ITEM, GESTURE.AFK },
    { GESTURE.NONE, GESTURE.OH_NO, GESTURE.LOL, GESTURE.CHEER_UP, GESTURE.SORRY },
}

LANGUAGE = {
    ENGLISH = 0,
    KOREAN = 11
}

GESTURE_DIR_NAME = {
    [LANGUAGE.KOREAN] = {
        "",
        "게임",
        "기타",
        "감정"
    },
    [LANGUAGE.ENGLISH] = {
        "",
        "Game",
        "Etc",
        "Emotion"
    }
}

GESTURE_TEXT_MAPS = {
    [LANGUAGE.KOREAN] = {
        [GESTURE.NONE] = "NONE",

        [GESTURE.HELP] = "도와주세요!",
        [GESTURE.WAIT_PLEASE] = "기다려주세요!",
        [GESTURE.READY_TO_EXIT] = "나갈 준비 완료",
        [GESTURE.RESTART_GAME] = "다시 시작할까요?",
        [GESTURE.NEED_RECONNECT] = "리방해야해요",
        [GESTURE.CHECK_MESSENGER] = "글을 확인해주세요",

        [GESTURE.I_AM_DEAD] = "죽었어요",
        [GESTURE.ITEM_LEFT] = "템이 남았어요",
        [GESTURE.DISCARD_ITEM] = "템은 버려도 괜찮아요",
        [GESTURE.AFK] = "자리 비움",

        [GESTURE.OH_NO] = "저런",
        [GESTURE.LOL] = "신난다~",
        [GESTURE.CHEER_UP] = "힘내요!",
        [GESTURE.SORRY] = "미안해요",

        [GESTURE.READY] = "준비",
    },
    [LANGUAGE.ENGLISH] = {
        [GESTURE.NONE] = "NONE",

        [GESTURE.HELP] = "Help!",
        [GESTURE.WAIT_PLEASE] = "Wait please!",
        [GESTURE.READY_TO_EXIT] = "Ready to exit",
        [GESTURE.RESTART_GAME] = "Restart the game?",
        [GESTURE.NEED_RECONNECT] = "Need reconnect",
        [GESTURE.CHECK_MESSENGER] = "Check messenger",

        [GESTURE.I_AM_DEAD] = "I'm dead",
        [GESTURE.ITEM_LEFT] = "Item left",
        [GESTURE.DISCARD_ITEM] = "Discard item",
        [GESTURE.AFK] = "AFK",

        [GESTURE.OH_NO] = "Oh no",
        [GESTURE.LOL] = "Yay",
        [GESTURE.CHEER_UP] = "Cheer up",
        [GESTURE.SORRY] = "Sorry",
        
        [GESTURE.READY] = "Ready",
    },
}

gesture_text_short_map = {
    [LANGUAGE.KOREAN] = {
        [GESTURE.NONE] = "",

        [GESTURE.HELP] = "도움",
        [GESTURE.WAIT_PLEASE] = "대기",
        [GESTURE.READY_TO_EXIT] = "준비",
        [GESTURE.RESTART_GAME] = "재시작",
        [GESTURE.NEED_RECONNECT] = "리방",
        [GESTURE.CHECK_MESSENGER] = "글",

        [GESTURE.I_AM_DEAD] = "죽음",
        [GESTURE.ITEM_LEFT] = "템",
        [GESTURE.DISCARD_ITEM] = "버려요",
        [GESTURE.AFK] = "자리 비움",

        [GESTURE.OH_NO] = "저런",
        [GESTURE.LOL] = "신난다",
        [GESTURE.CHEER_UP] = "힘내요",
        [GESTURE.SORRY] = "미안",

        [GESTURE.READY] = "준비"
    },
    [LANGUAGE.ENGLISH] = {
        [GESTURE.NONE] = "",

        [GESTURE.HELP] = "Help",
        [GESTURE.WAIT_PLEASE] = "Wait",
        [GESTURE.READY_TO_EXIT] = "Ready",
        [GESTURE.RESTART_GAME] = "Restart",
        [GESTURE.NEED_RECONNECT] = "Reconnect",
        [GESTURE.CHECK_MESSENGER] = "Confirm",

        [GESTURE.I_AM_DEAD] = "Dead",
        [GESTURE.ITEM_LEFT] = "Item",
        [GESTURE.DISCARD_ITEM] = "Discard",
        [GESTURE.AFK] = "AFK",

        [GESTURE.OH_NO] = "Oh no",
        [GESTURE.LOL] = "Yay",
        [GESTURE.CHEER_UP] = "Cheer up",
        [GESTURE.SORRY] = "Sorry",

        [GESTURE.READY] = "Ready"
    }
}

---@param gesture GESTURE
---@return string
function stringify_gesture(gesture)
    local lang = get_setting(GAME_SETTING.LANGUAGE)
    local text_map = GESTURE_TEXT_MAPS[lang] or GESTURE_TEXT_MAPS[LANGUAGE.ENGLISH]
    local text = text_map[gesture] or GESTURE_TEXT_MAPS[LANGUAGE.ENGLISH][gesture]
    
    if text ~= nil then
        return text
    else
        return "INVALID: " .. gesture
    end
end

---@param gesture GESTURE
---@return string
function stringify_gesture_short(gesture)
    local lang = get_setting(GAME_SETTING.LANGUAGE)
    local text_map = gesture_text_short_map[lang] or gesture_text_short_map[LANGUAGE.ENGLISH]
    local text = text_map[gesture] or gesture_text_short_map[LANGUAGE.ENGLISH][gesture]

    if text ~= nil then
        return text
    else
        return "INVALID: " .. gesture
    end
end

---@param x integer
---@return string
function stringify_gesture_dir(x)
    local lang = get_setting(GAME_SETTING.LANGUAGE)
    local text_map = GESTURE_DIR_NAME[lang] or GESTURE_DIR_NAME[LANGUAGE.ENGLISH]
    local text = text_map[x] or GESTURE_DIR_NAME[LANGUAGE.ENGLISH][x]

    if text ~= nil then
        return text
    else
        return "INVALID: " .. x
    end
end

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
---@field read fun(self: InputReader, input: INPUTS, frame: integer)
---@field pressed fun(self: InputReader, gesture_input: GESTURE_INPUT, frame: integer): boolean

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

---@class GestureAnimation
---@field gesture GESTURE
---@field frame_begin integer

---@class GestureInputState
---@field reader InputReader
---@field prev_buttons integer
---@field door_frame_begin integer
---@field direction integer
---@field x integer
---@field y integer

---@return GestureInputState
function initial_gesture_input_state()
    return {
        reader = initial_input_reader(),
        prev_buttons = 0,
        door_frame_begin = -1,
        direction = 0,
        x = 0,
        y = 0
    }
end

---@class PlayerGestureState
---@field cur_ges GestureAnimation
---@field ges_input_state GestureInputState

---@return PlayerGestureState
function initial_player_gesture_state()
    return {
        cur_ges = {
            gesture = GESTURE.NONE,
            frame_begin = -GESTURE_DISPLAY_DURATION_DEFAULT
        },
        ges_input_state = initial_gesture_input_state()
    }
end

---@class SyncStorage
---@field player_ges_states PlayerGestureState[] @size: MAX_PLAYERS

---@return SyncStorage
function initial_sync_storage()
    return {
        player_ges_states = array_fillwith(MAX_PLAYERS, initial_player_gesture_state)
    }
end

---@class Storage
---@field player_colors Color[] @size: MAX_PLAYERS

_storage = {
    player_colors = array_fillwith(MAX_PLAYERS, function ()
        return Color.new(127, 127, 127, 1)
    end)
}
function get_storage()
    return _storage
end

set_callback(function()
    --- remove gesture state on level generation
    local data = get_sync_storage()
    for slot = 1, MAX_PLAYERS do
        local gstate = data.player_ges_states[slot]
        local gesture = gstate.cur_ges.gesture
        if not GESTURE_PRESIST_ON_RESTART[gesture] then
            gstate.cur_ges = {
                gesture = GESTURE.NONE,
                frame_begin = -GESTURE_DISPLAY_DURATION_DEFAULT
            }
        end
    end

    --- initialize color of player's heart
    if not options.use_heart_color then
        get_storage().player_colors = array_fillwith(MAX_PLAYERS, function ()
            return Color.new(127, 127, 127, 1)
        end)
        return
    end

    local state = get_state()

    if state.level_count == 0 then
        local data = get_storage()
        local players = get_players()
        for slot = 1, MAX_PLAYERS do
            local player = players[slot]
            if player then
                data.player_colors[slot] = Color:new(get_character_heart_color(player.type.id))
                data.player_colors[slot].a = 1
            end
        end
    end
end, ON.POST_LEVEL_GENERATION)

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

---@return StateMemory
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

    ---@param input INPUTS
    ---@param frame integer
    function updown_pressed(input, frame)
        return pressed(input)

        --[[if input == INPUTS.UP then
            return ges_input_state.reader:pressed(GESTURE_INPUT.UP, frame)
        else
            return ges_input_state.reader:pressed(GESTURE_INPUT.DOWN, frame)
        end]]--
    end

    if pressed(INPUTS.DOOR) and (buttons & (INPUTS.LEFT | INPUTS.RIGHT)) == 0 then
        ges_input_state.door_frame_begin = frame
    elseif door_pressed and prev_door_pressed then
        local initialized = ges_input_state.x ~= 0
        if not initialized then
            if (buttons & (INPUTS.LEFT | INPUTS.RIGHT)) ~= 0 then
                ges_input_state.door_frame_begin = frame + 1
            elseif frame - ges_input_state.door_frame_begin >= 5 then
                ges_input_state.direction = 0
                ges_input_state.x = 1
                ges_input_state.y = 1
            end
        end

        if initialized then
            if options.mode == MODE.NATURAL_CONTROL then
                if ges_input_state.direction == 1 then
                    buttons = buttons & ~INPUTS.DOWN
                elseif ges_input_state.direction == -1 then
                    buttons = buttons & ~INPUTS.UP
                end

                if ges_input_state.y >= 2 and (buttons & (INPUTS.UP | INPUTS.DOWN)) ~= 0  then
                    buttons = buttons & ~(INPUTS.UP | INPUTS.DOWN)
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

                input_slot.buttons_gameplay = buttons
            end
            
            if (buttons & (INPUTS.LEFT | INPUTS.RIGHT)) ~= 0 then
                ges_input_state.direction = 0
                ges_input_state.x = 0
                ges_input_state.y = 0
                ges_input_state.door_frame_begin = frame + 1
            else
                --local reader = ges_input_state.reader
                --reader:read(buttons, frame)

                if ges_input_state.direction == 0 then
                    if updown_pressed(INPUTS.UP, frame) then
                        ges_input_state.direction = 1
                    elseif updown_pressed(INPUTS.DOWN, frame) then
                        ges_input_state.direction = -1
                    end
                end

                if ges_input_state.direction ~= 0 then
                    local UP = INPUTS.UP
                    local DOWN = INPUTS.DOWN

                    if ges_input_state.direction == -1 then
                        UP = INPUTS.DOWN
                        DOWN = INPUTS.UP
                    end
                    
                    if updown_pressed(UP, frame) then
                        if ges_input_state.y >= 2 then
                            ges_input_state.y = ges_input_state.y - 1
                        else
                            ges_input_state.x = (ges_input_state.x - 1 + ges_input_state.direction + #GESTURE_SELECT_SPACE) % #GESTURE_SELECT_SPACE + 1
                        end
                    elseif updown_pressed(DOWN, frame) then
                        ges_input_state.y = ges_input_state.y % #GESTURE_SELECT_SPACE[ges_input_state.x] + 1
                    end
                end
            end
        end
    elseif prev_door_pressed and not door_pressed then
        if ges_input_state.x ~= 0 then
            local gesture = GESTURE_SELECT_SPACE[ges_input_state.x][ges_input_state.y]
            gstate.cur_ges = {
                gesture = gesture,
                frame_begin = frame
            }

            ges_input_state.direction = 0
            ges_input_state.x = 0
            ges_input_state.y = 0

            if options.play_sound then
                local sounds = GESTURE_SOUND[gesture]
                    if sounds ~= nil then
                    for _, sound in ipairs(sounds) do
                        sound:play()
                    end
                end
            end
        end
    end

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
    if state.screen == SCREEN.MENU then
        play_type = PLAY_TYPE.LOCAL
    elseif state.screen == SCREEN.ONLINE_LOBBY then
        play_type = PLAY_TYPE.ONLINE
        local_player_slot = online.lobby.local_player_slot
    end
end, ON.SCREEN)

set_callback(function()
    local data = get_sync_storage()

    for slot = 1, MAX_PLAYERS do
        local gstate = data.player_ges_states[slot]
        local gesture = gstate.cur_ges.gesture
        if not GESTURE_PERSIST_ON_TRANSITION[gesture] then
            gstate.cur_ges = {
                gesture = GESTURE.NONE,
                frame_begin = -GESTURE_DISPLAY_DURATION_DEFAULT
            }
        end
    end
end, ON.TRANSITION)

FADEOUT_TIMER_AT = 30

---@param color Color
---@param timer integer
---@return Color
function fadeout_direction_color(color, timer)
    color = Color:new(color)
    if timer < FADEOUT_TIMER_AT then
        color.a = color.a * ((timer*timer) / (FADEOUT_TIMER_AT * FADEOUT_TIMER_AT))
    end
    return color
end

---@param ctx VanillaRenderContext
set_callback(function(ctx)
    local FONT = VANILLA_FONT_STYLE.ITALIC
    local font_scale = options.font_scale / 10000
    local CENTER = VANILLA_TEXT_ALIGNMENT.CENTER

    local data = get_sync_storage()
    local frame = get_frame()
    local players = get_players()

    function draw_text(text, x, y, scale, color)
        ctx:draw_text(text, x, y, scale, scale, color, CENTER, FONT)
    end

    function draw_text_with_shadow(text, x, y, scale, color)
        ctx:draw_text(text, x, y, scale * 1.1, scale * 1.1, Color:new(0, 0, 0, 255), CENTER, FONT)
        ctx:draw_text(text, x, y, scale, scale, color, CENTER, FONT)
    end

    local player_colors = get_storage().player_colors

    for slot = 1, MAX_PLAYERS do
        local gstate = data.player_ges_states[slot]
        local ges_input_state = gstate.ges_input_state
        local color = player_colors[slot]

        ---#region GESTURE SELECT UI
        if ges_input_state.x ~= 0 and (slot == local_player_slot or play_type == PLAY_TYPE.LOCAL) then
            local BLOCK_HEIGHT = 0.05
            local BLOCK_WIDTH = 0.10

            local state = get_state()
            local fx, fy = screen_position(state.camera.focus_x, state.camera.focus_y)

            if state.camera.focused_entity_uid == -1 then
                fx, fy = 0, 0
            end

            if play_type == PLAY_TYPE.LOCAL then
                local player = players[slot]
                if player then
                    local hitbox = get_render_hitbox(player.uid)
                    local sx, sy = screen_position((hitbox.left + hitbox.right) / 2, (hitbox.top + hitbox.bottom) / 2)
                    fx, fy = sx, sy
                end
            end

            local color_disabled = Color:new(127, 127, 127, 1)
            local color_enabled = Color:new(243, 137, 215, 1)

            --- draw dir
            for gx = 1, #GESTURE_SELECT_SPACE do
                local x = fx
                local y = fy + 0.12 + (gx - 1) * BLOCK_HEIGHT
                local text = stringify_gesture_dir(gx)
                local dir_color = color_disabled

                if gx == ges_input_state.x and ges_input_state.y == 1 then
                    dir_color = color_enabled
                end

                draw_text(text, x, y, font_scale, dir_color)
            end

            --- draw select
            local gx = ges_input_state.x
            for gy = 1, #GESTURE_SELECT_SPACE[gx] do
                local x = fx + (gy - 1) * BLOCK_WIDTH
                local y = fy + 0.12 + (gx - 1) * BLOCK_HEIGHT
                local text = stringify_gesture_short(GESTURE_SELECT_SPACE[gx][gy])
                local select_color = color_disabled

                if gy == ges_input_state.y then
                    select_color = color_enabled
                end

                draw_text(text, x, y, font_scale, select_color)
            end
        end
        ---#endregion
        
        ---#region DISPLAY GESTURE
        local gesture = gstate.cur_ges.gesture
        local elapsed = frame - gstate.cur_ges.frame_begin
        local duration = GESTURE_DISPLAY_DURATION[gesture] or GESTURE_DISPLAY_DURATION_DEFAULT
        if gesture == GESTURE.NONE or elapsed >= duration then
            goto continue
        end

        local state = get_state()

        if state.screen == SCREEN.TRANSITION and gesture == GESTURE.READY_TO_EXIT then
            gesture = GESTURE.READY
        end

        local fadeout_color = fadeout_direction_color(color, duration - elapsed)
        local text = stringify_gesture(gesture)

        --- displays under the player's heart
        if play_type == PLAY_TYPE.ONLINE then
            local x = -1.15 + slot * 0.32 + 0.10
            local y = 0.648
            draw_text(text, x, y, font_scale * 1.2, fadeout_color)
        else
            local x = -1.15 + slot * 0.32
            local y = 0.72
            draw_text(text, x, y, font_scale * 1.2, fadeout_color)
        end

        --- displays over player's head
        if state.screen ~= SCREEN.TRANSITION then
            ---@type Player | PlayerGhost | nil
            local player = players[slot]

            if player == nil or player.health == 0 then
                player = get_playerghost(slot)
            end

            if player == nil then
                goto continue
            end

            ex, ey, el = get_render_position(player.uid)
            hitbox = get_render_hitbox(player.uid)
            sx, sy = screen_position((hitbox.left + hitbox.right) / 2, hitbox.top + (hitbox.top - hitbox.bottom) * 0.75)

            draw_text(text, sx, sy, font_scale * 1.5, fadeout_color)
        end
        ::continue::
        ---#endregion
    end
end, ON.RENDER_POST_HUD)

---@param ctx GuiDrawContext
set_callback(function(ctx)

    if play_type == PLAY_TYPE.ONLINE and (playlunky_version ~= PLAYLUNKY_VERSION.NIGHTLY_ONLINE or options.mode ~= MODE.COMPAT_WITH_VANILA) then
        local state = get_state()
        if state.screen == SCREEN.ONLINE_LOBBY then
            local text = nil
            local color = 0

            if playlunky_version ~= PLAYLUNKY_VERSION.NIGHTLY_ONLINE then
                text = "[chat] When using this mod online, the Playlunky online build must be used."
                color = rgba(255, 0, 0, 128)
            elseif options.mode ~= MODE.COMPAT_WITH_VANILA then
                text = "[chat] All players must be on the same version of Playlunky and have the same online mod enabled.\nIf you don't want to do that, use 'Compatible with Vanilla'"
                color = rgba(255, 255, 0, 128)
            end

            if text ~= nil then
                ctx:draw_text(-0.9, -0.7, options.font_scale * 8, text, color)
            end
        end
    end
end, ON.GUIFRAME)
