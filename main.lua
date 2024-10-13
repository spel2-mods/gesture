---@diagnostic disable: lowercase-global

meta = {
	name = "gesture",
	version = "0.1",
	description = "visualize gesture into chat",
	author = "fienestar",
    online_safe = true
}

require "consts"
require "gesture.consts"
require "gesture.stringify"
require "util.array"
require "playlunky.use_thread_local_version"
playlunky_version = require("playlunky.version")

online_data = require("util.online_data")
options_utils = require("util.option")

options_utils.register_option_combo("mode", "Mode", "", "Compatible with Vanilla\0Natural Control(experimental, every player must use same mode)\0\0", MODE.COMPAT_WITH_VANILA)
options_utils.register_option_bool("play_sound", "play sound", "", true)
options_utils.register_option_bool("use_heart_color", "Use heart color", "", false)
options_utils.register_option_float("font_scale", "font scale", "", 4, 0, 10000)
options_utils.register_option_combo("font_style", "font style", "", "bold\0italic\0\0", 1)
function get_font_style()
    if options.font_style == 1 then
        return VANILLA_FONT_STYLE.BOLD_KO
    else
        return VANILLA_FONT_STYLE.ITALIC_KO
    end
end

require("util.set_option_saveload")()

---@class GestureAnimation
---@field gesture GESTURE
---@field frame_begin integer

---@class GestureInputState
---@field prev_buttons integer
---@field door_frame_begin integer
---@field direction integer
---@field x integer
---@field y integer

---@return GestureInputState
local function initial_gesture_input_state()
    return {
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
local function initial_player_gesture_state()
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

---@type SyncStorage
local initial_sync_storage = {
    player_ges_states = array_fillwith(MAX_PLAYERS, initial_player_gesture_state)
}
get_sync_storage = require("playlunky.get_sync_storage")(initial_sync_storage)

---@class Storage
---@field player_colors Color[] @size: MAX_PLAYERS

_storage = {
    player_colors = array_fillwith(MAX_PLAYERS, function ()
        return Color:new(127, 127, 127, 1)
    end)
}
local function get_storage()
    return _storage
end

---@param cb fun(gesture: GESTURE): boolean
function remove_gestures_if(cb)
    local data = get_sync_storage()
    for slot = 1, MAX_PLAYERS do
        local gstate = data.player_ges_states[slot]
        local gesture = gstate.cur_ges.gesture
        if cb(gesture) then
            gstate.cur_ges = {
                gesture = GESTURE.NONE,
                frame_begin = -GESTURE_DISPLAY_DURATION_DEFAULT
            }
        end
    end
end

function initialize_heart_color()
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

set_callback(function()
    --- remove gesture state on level generation
    remove_gestures_if(function (gesture)
        return not GESTURE_PRESIST_ON_RESTART[gesture]
    end)

    --- initialize color of player's heart
    if not options.use_heart_color then
        get_storage().player_colors = array_fillwith(MAX_PLAYERS, function ()
            return Color:new(127, 127, 127, 1)
        end)
        return
    end

    if get_state().level_count == 0 then
        initialize_heart_color()
    end
end, ON.POST_LEVEL_GENERATION)

---@param frame integer
---@param input_slot PlayerSlot
---@param gstate PlayerGestureState
local function process_player_input(frame, input_slot, gstate)
    local ges_input_state = gstate.ges_input_state
    local prev_buttons = ges_input_state.prev_buttons
    local buttons = input_slot.buttons_gameplay
    local door_pressed = test_mask(buttons, INPUTS.DOOR)
    local prev_door_pressed = test_mask(prev_buttons, INPUTS.DOOR)

    ---@param input INPUTS
    local function pressed(input)
        return test_mask(buttons, input) and not test_mask(prev_buttons, input)
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
                if ges_input_state.direction == 0 then
                    if pressed(INPUTS.UP) then
                        ges_input_state.direction = 1
                    elseif pressed(INPUTS.DOWN) then
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
                    
                    if pressed(UP) then
                        if ges_input_state.y >= 2 then
                            ges_input_state.y = ges_input_state.y - 1
                        else
                            ges_input_state.x = (ges_input_state.x - 1 + ges_input_state.direction + #GESTURE_SELECT_SPACE) % #GESTURE_SELECT_SPACE + 1
                        end
                    elseif pressed(DOWN) then
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

function process_players_input()
    local data = get_sync_storage()
    local state = get_state()
    local frame = get_frame()
    for slot = 1, MAX_PLAYERS do
        process_player_input(frame, state.player_inputs.player_slots[slot], data.player_ges_states[slot])
    end
end

set_callback(function()
    if options.mode ~= MODE.COMPAT_WITH_VANILA then
        return
    end

    process_players_input()
end, ON.GAMEFRAME)

set_callback(function()
    if options.mode ~= MODE.NATURAL_CONTROL then
        return
    end

    process_players_input()
end, ON.PRE_UPDATE)

set_callback(function()
    remove_gestures_if(function (gesture)
        return not GESTURE_PERSIST_ON_TRANSITION[gesture]
    end)
end, ON.TRANSITION)

FADEOUT_TIMER_AT = 30

---@param color Color
---@param timer integer
---@return Color
local function fadeout_direction_color(color, timer)
    color = Color:new(color)
    if timer < FADEOUT_TIMER_AT then
        color.a = color.a * ((timer*timer) / (FADEOUT_TIMER_AT * FADEOUT_TIMER_AT))
    end
    return color
end

---@param ctx VanillaRenderContext
set_callback(function(ctx)
    local FONT = get_font_style()
    local font_scale = options.font_scale / 10000
    local CENTER = VANILLA_TEXT_ALIGNMENT.CENTER

    local data = get_sync_storage()
    local frame = get_frame()
    local players = get_players()

    ---@param text string
    ---@param x number
    ---@param y number
    ---@param scale number
    ---@param color Color
    local function draw_text(text, x, y, scale, color)
        ctx:draw_text(text, x, y, scale, scale, color, CENTER, FONT)
    end

    local function draw_text_size(text, scale)
        return ctx:draw_text_size(text, scale, scale, FONT)
    end

    ---@param text string
    ---@param x number
    ---@param y number
    ---@param scale number
    ---@param color Color
    function draw_floating_text(text, x, y, scale, color)
        local w, h = draw_text_size(scale, text)
        
        if ex+w/2>0.98 then
            ey=ey/ex*(0.98-w/2)
            ex=0.98-w/2
        elseif ex-w/2<-0.98 then
            ey=ey/ex*(-0.98+w/2)
            ex=-0.98+w/2
        end
        if ey-h/2>0.98 then
            ex=ex/ey*(0.98+h/2)
            ey=0.98+h/2
        elseif ey+h/2<-0.98 then
            ex=ex/ey*(-0.98-h/2)
            ey=-0.98-h/2
        end

        draw_text(text, x, y, scale, color)
    end

    local player_colors = get_storage().player_colors

    for slot = 1, MAX_PLAYERS do
        local gstate = data.player_ges_states[slot]
        local ges_input_state = gstate.ges_input_state
        local color = player_colors[slot]

        local get_player_render_position = (function()
            local x, y, l = nil, nil, nil
            local cached = false

            return function()
                if not cached then
                    ---@type Player | PlayerGhost | nil
                    local player = players[slot]
                    if player == nil or player.health == 0 then
                        player = get_playerghost(slot)
                    end
                    
                    if player == nil then
                        cached = true
                        return nil, nil
                    end

                    x, y, l = get_render_position(player.uid)

                    cached = true
                end
                return x, y, l
            end
        end)()

        ---#region GESTURE SELECT UI
        if ges_input_state.x ~= 0 and (slot == online_data.local_player_slot or online_data.play_type == PLAY_TYPE.LOCAL) then
            local BLOCK_HEIGHT = 0.05
            local BLOCK_WIDTH = 0.10

            local fx, fy = 0, 0
            -- don't draw gesture select ui when player is entering the door
            if players[slot] == nil or (players[slot].state ~= CHAR_STATE.ENTERING and players[slot].state ~= CHAR_STATE.EXITING) then
                local rx, ry = get_player_render_position()

                if rx ~= nil then
                    ---@cast ry number
                    fx, fy = screen_position(rx, ry)
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
        if online_data.play_type == PLAY_TYPE.ONLINE then
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
            local rx, ry = get_player_render_position()

            if rx == nil then
                goto continue
            end

            ---@cast ry number
            draw_floating_text(text, rx, ry + 0.1, font_scale * 1.5, fadeout_color)
        end
        ::continue::
        ---#endregion
    end
end, ON.RENDER_POST_HUD)

---@param ctx GuiDrawContext
set_callback(function(ctx)

    if online_data.play_type == PLAY_TYPE.ONLINE and (playlunky_version ~= PLAYLUNKY_VERSION.NIGHTLY_ONLINE or options.mode ~= MODE.COMPAT_WITH_VANILA) then
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
