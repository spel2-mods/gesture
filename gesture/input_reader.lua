
---@alias GESTURE_INPUT integer
GESTURE_INPUT = {
    NONE = 0,
    UP = 1,
    DOWN = 2,
}

---@class InputCandidate
---@field frame_count integer
---@field last_frame integer

InputCandidate = {}

---@return InputCandidate
function InputCandidate:new()
    local o = {
        frame_count = 0,
        last_frame = 0
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---@class InputReader
---@field read fun(self: InputReader, input: INPUTS, frame: integer)
---@field pressed fun(self: InputReader, gesture_input: GESTURE_INPUT, frame: integer): boolean


InputReader = {}

---@return InputReader
function InputReader:new()
    local o = {
        cur = GESTURE_INPUT.NONE,
        last_frame = 0,
        candidates = {}
    }
    for i = 1, 3 do
        o.candidates[i] = InputCandidate:new()
    end
    setmetatable(o, self)
    self.__index = self
    return o
end

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

function InputReader:read(input, frame)
    if test_mask(input, INPUTS.UP) then
        self:push(GESTURE_INPUT.UP, frame)
    elseif test_mask(input, INPUTS.DOWN) then
        self:push(GESTURE_INPUT.DOWN, frame)
    end
end
