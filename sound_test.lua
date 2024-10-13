sounds = {"Menu/Cancel","Menu/Charsel_deselection","Menu/Charsel_door","Menu/Charsel_navi","Menu/Charsel_quick_navi","Menu/Charsel_quick_nope","Menu/Charsel_quick_open","Menu/Charsel_scroll","Menu/Charsel_selection","Menu/Charsel_selection2","Menu/Dirt_fall","Menu/Journal_sticker","Menu/MM_bar","Menu/MM_navi","Menu/MM_options_sub","Menu/MM_reset","Menu/MM_selection","Menu/MM_set","Menu/MM_toggle","Menu/Navi","Menu/Page_return","Menu/Page_turn","Menu/Selection","Menu/Title_selection","Menu/Title_torch_loop","Menu/Zoom_in","Menu/Zoom_out"}

sound_index = 1

g_prev_buttons = INPUTS.NONE

set_callback(function()
    local buttons = state.player_inputs.player_slot_1.buttons
    local prev_buttons = g_prev_buttons
    g_prev_buttons = buttons

    function pressed(button)
        return test_mask(buttons, button) and not test_mask(prev_buttons, button)
    end

    if pressed(INPUTS.DOWN) then
        sound_index = sound_index + 1
        if sound_index > #sounds then
            sound_index = 1
        end
        print('now playing ' .. sounds[sound_index])
        get_sound(sounds[sound_index]):play()
    end

    if pressed(INPUTS.UP) then
        sound_index = sound_index - 1
        if sound_index < 1 then
            sound_index = #sounds
        end
        print('now playing ' .. sounds[sound_index])
        get_sound(sounds[sound_index]):play()
    end
end, ON.GAMEFRAME)
