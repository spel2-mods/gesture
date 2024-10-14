---@diagnostic disable: lowercase-global

---@param gesture GESTURE
function play_gesture_sound(gesture)
    if options.play_sound then
        local sound_path = GESTURE_SOUND_MAP[gesture]
        if sound_path ~= nil and sound_path ~= "" then
            sound = get_sound(sound_path)
            if sound ~= nil then
                sound:play()
            end
        end
    end
end
