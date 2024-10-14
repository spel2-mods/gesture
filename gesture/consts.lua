require "util.table"

GESTURE = {
    NONE = 0,
    [0] = "NONE",

    HELP = 1,
    [1] = "HELP",
    WAIT_PLEASE = 2,
    [2] = "WAIT_PLEASE",
    READY_TO_EXIT = 3,
    [3] = "READY_TO_EXIT",
    RESTART_GAME = 4,
    [4] = "RESTART_GAME",
    NEED_RECONNECT = 5,
    [5] = "NEED_RECONNECT",
    CHECK_MESSENGER = 6,
    [6] = "CHECK_MESSENGER",

    I_AM_DEAD = 7,
    [7] = "I_AM_DEAD",
    ITEM_LEFT = 8,
    [8] = "ITEM_LEFT",
    DISCARD_ITEM = 9,
    [9] = "DISCARD_ITEM",
    AFK = 10,
    [10] = "AFK",

    OH_NO = 11,
    [11] = "OH_NO",
    LOL = 12,
    [12] = "LOL",
    CHEER_UP = 13,
    [13] = "CHEER_UP",
    SORRY = 14,
    [14] = "SORRY",

    READY = 15,
    [15] = "READY",
}
---@alias GESTURE integer

DURATION_2_5S = 150
DURATION_15S = 900
DURATION_60S = 4 * DURATION_15S
DURATION_30D = DURATION_60S * 24 * 30

GESTURE_DISPLAY_DURATION_DEFAULT = {
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

GESTURE_DISPLAY_DURATION = shallow_clone_table(GESTURE_DISPLAY_DURATION_DEFAULT)

GESTURE_PERSIST_ON_TRANSITION_DEFAULT = {
    [GESTURE.NONE] = false,

    [GESTURE.HELP] = false,
    [GESTURE.WAIT_PLEASE] = false,
    [GESTURE.READY_TO_EXIT] = false,
    [GESTURE.RESTART_GAME] = true,
    [GESTURE.NEED_RECONNECT] = true,
    [GESTURE.CHECK_MESSENGER] = true,

    [GESTURE.I_AM_DEAD] = false,
    [GESTURE.ITEM_LEFT] = false,
    [GESTURE.DISCARD_ITEM] = false,
    [GESTURE.AFK] = true,

    [GESTURE.OH_NO] = false,
    [GESTURE.LOL] = false,
    [GESTURE.CHEER_UP] = false,
    [GESTURE.SORRY] = false,

    [GESTURE.READY] = false,
}

GESTURE_PERSIST_ON_TRANSITION = shallow_clone_table(GESTURE_PERSIST_ON_TRANSITION_DEFAULT)

GESTURE_PRESIST_ON_RESTART_DEFAULT = {
    [GESTURE.NONE] = false,

    [GESTURE.HELP] = false,
    [GESTURE.WAIT_PLEASE] = false,
    [GESTURE.READY_TO_EXIT] = false,
    [GESTURE.RESTART_GAME] = false,
    [GESTURE.NEED_RECONNECT] = true,
    [GESTURE.CHECK_MESSENGER] = true,

    [GESTURE.I_AM_DEAD] = false,
    [GESTURE.ITEM_LEFT] = false,
    [GESTURE.DISCARD_ITEM] = false,
    [GESTURE.AFK] = true,

    [GESTURE.OH_NO] = false,
    [GESTURE.LOL] = false,
    [GESTURE.CHEER_UP] = false,
    [GESTURE.SORRY] = false,

    [GESTURE.READY] = false,
}

GESTURE_PRESIST_ON_RESTART = shallow_clone_table(GESTURE_PRESIST_ON_RESTART_DEFAULT)

NO_SOUND = ""
COMPLETED_SOUND = VANILLA_SOUND.MENU_CHARSEL_SELECTION
WARNING_SOUND = VANILLA_SOUND.CUTSCENE_KEY_DROP
IMPORTANT_SOUND = VANILLA_SOUND.MENU_CHARSEL_SELECTION2

GESTURE_SOUND_MAP_DEFAULT = {
    [GESTURE.NONE] = NO_SOUND,
    
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
GESTURE_SOUND_MAP = shallow_clone_table(GESTURE_SOUND_MAP_DEFAULT)

GESTURE_SELECT_SPACE = {
    { GESTURE.NONE },
    { GESTURE.NONE, GESTURE.HELP, GESTURE.WAIT_PLEASE, GESTURE.READY_TO_EXIT, GESTURE.RESTART_GAME, GESTURE.NEED_RECONNECT, GESTURE.CHECK_MESSENGER },
    { GESTURE.NONE, GESTURE.I_AM_DEAD, GESTURE.ITEM_LEFT, GESTURE.DISCARD_ITEM, GESTURE.AFK },
    { GESTURE.NONE, GESTURE.OH_NO, GESTURE.LOL, GESTURE.CHEER_UP, GESTURE.SORRY },
}

LANGUAGE = {
    ENGLISH = 0,
    [0] = "EN",
    KOREAN = 11,
    [11] = "KO",
}

SUPPORTED_LANGUAGES = {
    LANGUAGE.ENGLISH,
    LANGUAGE.KOREAN
}

GESTURE_GROUP = {
    NONE = 0,
    [0] = "NONE",
    GAME = 1,
    [1] = "GAME",
    ETC = 2,
    [2] = "ETC",
    EMOTION = 3,
    [3] = "EMOTION",
}

GESTURE_GROUP_NAME_MAPS_DEFAULT = {
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
    },
}
GESTURE_GROUP_NAME_MAPS = shallow_clone_table(GESTURE_GROUP_NAME_MAPS_DEFAULT)

GESTURE_TEXT_MAPS_DEFAULT = {
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
GESTURE_TEXT_MAPS = shallow_clone_table(GESTURE_TEXT_MAPS_DEFAULT)

GESTURE_TEXT_SHORT_MAPS_DEFAULT = {
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
GESTURE_TEXT_SHORT_MAPS = shallow_clone_table(GESTURE_TEXT_SHORT_MAPS_DEFAULT)
