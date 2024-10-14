---@diagnostic disable: lowercase-global

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
    local text_map = GESTURE_TEXT_SHORT_MAPS[lang] or GESTURE_TEXT_SHORT_MAPS[LANGUAGE.ENGLISH]
    local text = text_map[gesture] or GESTURE_TEXT_SHORT_MAPS[LANGUAGE.ENGLISH][gesture]

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
    local text_map = GESTURE_GROUP_NAME_MAPS[lang] or GESTURE_GROUP_NAME_MAPS[LANGUAGE.ENGLISH]
    local text = text_map[x] or GESTURE_GROUP_NAME_MAPS[LANGUAGE.ENGLISH][x]

    if text ~= nil then
        return text
    else
        return "INVALID: " .. x
    end
end
