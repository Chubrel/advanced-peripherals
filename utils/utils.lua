local cc_expect = require('cc.expect')
local expect, field = cc_expect.expect, cc_expect.field

local LEFT_ARROW_CHAR = '\27'
local RIGHT_ARROW_CHAR = '\26'

local EDGE_SIZE = 2

local EDGE_COLOR = colors.yellow
local LIST_BUTTON_CHAR_COLOR = colors.black
local LIST_BUTTON_BACKGROUND_COLOR = colors.orange
local BACKGROUND_COLOR = colors.black
local TEXT_COLOR = colors.white

local CARDINAL_DIRECTIONS = {'north', 'south', 'west', 'east', 'down', 'up'}
local RELATIVE_DIRECTIONS = {'front', 'back', 'left', 'right', 'down', 'up'}


local function saveTextToFile(text, file_name)
    local file = assert(io.open(file_name, "w"))
    file:write(text)
    file:close()
end


local function saveObjectToFile(object, file_name)
    saveTextToFile(textutils.serialise(object), file_name)
end


local function loadTextFromFile(file_name)
    local file = assert(io.open(file_name, "r"))
    local text = file:read("*all")
    file:close()
    return text
end


local function loadObjectFromFile(file_name)
    return textutils.unserialize(loadTextFromFile(file_name))
end


local function checkPeripheral(peripheral, name)
    expect(1, peripheral, 'table', 'nil')
    expect(2, name, 'string', 'nil')
    local formatted_name
    if name then
        formatted_name = " '" .. name .. "'"
    else
        formatted_name = ''
    end
    if peripheral == nil then
        error("Peripheral" ..  formatted_name .. " have not been found")
    end
end


local vector2 = {}


function vector2.new(x, y)
    expect(1, x, 'number', 'nil')
    expect(2, y, 'number', 'nil')
    local object =
        {
            x = x or 0,
            y = y or 0,
        }
    return object
end


local position = {}


local function applyPositionOperations(object)
    function object:add(vector_)
        return position.fromVector(self.vector + vector_, self.rotation)
    end

    function object:sub(vector_)
        return position.fromVector(self.vector - vector_, self.rotation)
    end

    function object:mul(k)
        return position.fromVector(self.vector * k, self.rotation)
    end

    function object:div(k)
        return position.fromVector(self.vector / k, self.rotation)
    end

    function object:unm()
        return position.fromVector(-self.vector, self.rotation)
    end

    function object:equals(position)
        return self.vector == position.vector and self.rotation == position.rotation
    end

    function object:rotate(rotation)
        return position.fromVector(self.vector, (self.rotation + rotation) % 4)
    end

    function object:turnLeft()
        return self:rotate(1)
    end
    
    function object:turnBack()
        return self:rotate(2)
    end

    function object:turnRight()
        return self:rotate(-1)
    end

    function object:rotateTo(rotation)
        return self.rotate(rotation - self.rotation)
    end

    function object:moveWithRotation(rotation)
        rotation = rotation % 4
        local vector_ = self.vector * 1
        if rotation == 0 then
            vector_.x = vector_.x + 1
        elseif rotation == 1 then
            vector_.z = vector_.z + 1
        elseif rotation == 2 then
            vector_.x = vector_.x - 1
        else
            vector_.z = vector_.z - 1
        end
        return position.fromVector(vector_, rotation)
    end

    function object:moveForward()
        return self:moveWithRotation(self.rotation)
    end

    function object:moveBack()
        return self:moveWithRotation(self.rotation + 2)
    end

    function object:moveAside(side)
        if side ~= 1 or side ~= -1 then
            error('side can be only 1 or -1')
        end
        return self:moveWithRotation(side)
    end

    function object:moveX(y)
        local vector_ = self.vector * 1
        vector_.x = vector_.x + x
        return position.fromVector(vector_, self.rotation)
    end

    function object:moveY(y)
        local vector_ = self.vector * 1
        vector_.y = vector_.y + y
        return position.fromVector(vector_, self.rotation)
    end

    function object:moveZ(z)
        local vector_ = self.vector * 1
        vector_.z = vector_.z + z
        return position.fromVector(vector_, self.rotation)
    end

    function object:moveUp()
        return self:moveY(1)
    end

    function object:moveDown()
        return self:moveY(-1)
    end

    function object:moveTo(vector_)
        return position.fromVector(vector_, self.rotation)
    end

    function object:serialize()
        local pos = {
            vector = self.vector,
            rotation = self.rotation,
        }
        return textutils.serialise(pos)
    end

    local meta = {
        __add = object.add,
        __sub = object.sub,
        __mul = object.mul,
        __div = object.div,
        __unm = object.unm,
        __eq = object.equals,
        __tostring = object.serialize,
    }

    setmetatable(object, meta)
end


function position.fromVector(vector_, rotation)
    local object = {
        vector = vector_ or vector.new(),
        rotation = rotation or 0,
    }
    applyPositionOperations(object)
    return object
end


function position.fromCoords(x, y, z, rotation)
    return position.fromVector(vector.new(x, y, z), rotation)
end


function position.unserialize(text)
    local pos = textutils.unserialize(text)
    return position.fromCoords(pos.vector.x, pos.vector.y, pos.vector.z, pos.rotation)
end


local point = {}


function point.fromPosition(pos, name)
    local object = {
        position = pos or position.fromVector(),
        name = name,
    }
    return object
end


function point.fromVector(vector_, name)
    return point.fromPosition(position.fromVector(vector_, 0))
end


function point.fromCoords(x, y, z, name)
    return point.fromVector(vector.new(x, y, z), name)
end


local function union(...)
    local tables = table.pack(...)
    local result = {}
    for _, t in ipairs(tables) do
        for key, value in pairs(t) do
            result[key] = value
        end
    end
    return result
end


local function mergeLists(...)
    local tables = table.pack(...)
    local result = {}
    local i = 1
    for _, t in ipairs(tables) do
        for _, value in ipairs(t) do
            result[i] = value
            i = i + 1
        end
    end
    return result
end


local function refinedDisplayName(display_name)
    expect(1, display_name, 'string')
    local left_par_index = string.find(display_name, '[[]')
    if left_par_index then
        left_par_index = left_par_index + 1
    else
        left_par_index = 1
    end
    local right_par_index = string.find(display_name, '[]]')
    if right_par_index then
        right_par_index = right_par_index - 1
    else
        right_par_index = -1
    end
    return string.sub(display_name, left_par_index, right_par_index)
end


local function charIterator(str)
    expect(1, str, 'string')
    return str:gmatch('.')
end


local function indexCharIterator(str)
    local char_iterator = charIterator(str)
    local i = 0
    return function ()
        i = i + 1
        local char = char_iterator()
        if char then
            return i, char
        end
    end
end


local function getTextSpacing(size, length, scale)
    expect(1, size, 'number')
    expect(2, length, 'number')
    expect(3, scale, 'number', 'nil')
    scale = scale or 1
    local min = math.floor(scale * ((size - length) / 2 + 1))
    return min, min + length - 1
end


local function fillWithCharCentered(text, length, char)
    expect(1, text, 'string')
    expect(2, length, 'number')
    expect(3, char, 'string', 'nil')
    if char then
        if #char ~= 1 then
            error('Char must contain obly one symbol')
        end
    else
        char = ' '
    end
    local count = (length - #text) / 2
    local left, right = math.ceil(count), math.floor(count)
    return string.rep(char, left) .. text .. string.rep(char, right)
end


local function getMinAndMax(a, b)
    if a > b then
        return b, a
    else
        return a, b
    end
end


local function toString(value, table_modifiers, saved)
    expect(2, table_modifiers, 'table', 'nil')
    expect(3, saved, 'table', 'nil')
    local prepend, append, separator, pointer, ellipsis
    if table_modifiers then
        prepend = field(table_modifiers, 'prepend', 'string', 'nil')
        append = field(table_modifiers, 'append', 'string', 'nil')
        separator = field(table_modifiers, 'separator', 'string', 'nil')
        pointer = field(table_modifiers, 'pointer', 'string', 'nil')
        ellipsis = field(table_modifiers, 'ellipsis', 'string', 'nil')
    end
    prepend = prepend or '{'
    append = append or '}'
    separator = separator or ', '
    pointer = pointer or ': '
    ellipsis = ellipsis or '{...}'
    saved = saved or {}
    if type(value) == "table" then
        if not saved[value] then
            saved[value] = true
            local str = prepend
            local k, v = next(value)
            if k ~= nil then
                str = str .. toString(k, table_modifiers, saved) .. pointer .. toString(v, table_modifiers, saved)
                while true do
                    k, v = next(value, k)
                    if k == nil then
                        break
                    end
                    str = str .. separator .. toString(k, table_modifiers, saved) .. pointer .. toString(v, table_modifiers, saved)
                end
            end
            str = str .. append
            return str
        else
            return ellipsis
        end
    else
        return tostring(value)
    end
end


local function getCoordinatesString(value)
    return toString(value, {
        prepend = '(',
        append = ')',
        separator = ',',
        pointer = '=',
    })
end


-- Data example
-- {strings = {{str = "SomeText", background_color = colors.black, text_color = colors.white, new_line = 0}, },
--     background_color = colors.black, text_color = colors.white, new_line = 0, edges = {{x = 1, y = 2}, {x = 3, y = 4}}}
-- Usage example
-- for x, y, str, text_color, background_color in ColoredTextIterator(data) do ... end
local function coloredTextIterator(data)
    local x1, x2 = getMinAndMax(data.edges[1].x, data.edges[2].x)
    local y1, y2 = getMinAndMax(data.edges[1].y, data.edges[2].y)
    local x, y = x1, y1
    local next_x = x1
    local strings_index = 1
    local remaining_string = ''
    local default_text_color = data.text_color or TEXT_COLOR
    local default_background_color = data.background_color or BACKGROUND_COLOR
    local default_new_line = data.new_line or 1
    local text_color
    local background_color
    local new_line = 0
    return function ()
        x = next_x
        while remaining_string == '' do
            if new_line ~= 0 then
                x, y = x1, y + new_line
            end
            local string_data = data.strings[strings_index]
            if string_data == nil then
                return
            end
            remaining_string = string_data.str
            text_color = string_data.text_color or default_text_color
            background_color = string_data.background_color or default_background_color
            new_line = string_data.new_line or default_new_line
            strings_index = strings_index + 1
        end
        if remaining_string ~= nil then
            if x > x2 then
                if y == y2 then
                    return
                end
                x = x1
                y = y + 1
            end
            local substring_length = x2 - x + 1
            local str = remaining_string:sub(1, substring_length)
            next_x = x + #str
            remaining_string = remaining_string:sub(substring_length + 1, -1)
            return x, y, str, text_color, background_color
        end
    end
end


local function buttonView(pos, char, background_color, text_color)
    local object =
        {
            background_color = background_color or BACKGROUND_COLOR,
            char_color = text_color or TEXT_COLOR,
            char = char or ' ',
            pos = pos or vector2.new(),
        }
    return object
end


local function button(onTouch, views)
    local object =
        {
            onTouch = onTouch,
            views = views or {},
        }
    return object
end


local function listButton(button)
    local view = button.views[1]
    view.background_color = LIST_BUTTON_BACKGROUND_COLOR
    view.char_color = LIST_BUTTON_CHAR_COLOR
end


local function leftButton(button)
    local view = button.views[1]
    local pos = view.pos
    view.char = LEFT_ARROW_CHAR
    pos.x = 1
end


local function rightButton(button)
    local view = button.views[1]
    local pos = view.pos
    view.char = RIGHT_ARROW_CHAR
    pos.x = colony_info.monitor.getSize()
end


local function sideButton(button, height_scale)
    local view = button.views[1]
    local pos = view.pos
    local _, height = colony_info.monitor.getSize()
    pos.y = math.floor(height * height_scale) + 1
end


local function hideButton(button, value)
    if value == nil then
        value = true
    end
    button.invisible = value
    button.stick = value
end


-- Data is similar to ColoredTextIterator
local function coloredTextButton(data)
    local button = button()
    local views = button.views
    for x, y, str, text_color, background_color in coloredTextIterator(data) do
        for i, char in indexCharIterator(str) do
            table.insert(views, {pos = {x = x + i - 1, y = y}, char = char,
                char_color = text_color, background_color = background_color})
        end
    end
    return button
end


local function complexSmallButton(onTouch, ...)
    local button = button()
    local button_modifiers = table.pack(...)
    button.views[1] = button.views[1] or buttonView()
    for _, button_modifier in ipairs(button_modifiers) do
        button_modifier(button)
    end
    button.onTouch = onTouch
    return button
end


return {
    EDGE_SIZE = EDGE_SIZE,
    EDGE_COLOR = EDGE_COLOR,
    TEXT_COLOR = TEXT_COLOR,
    CARDINAL_DIRECTIONS = CARDINAL_DIRECTIONS,
    RELATIVE_DIRECTIONS = RELATIVE_DIRECTIONS,
    BACKGROUND_COLOR = BACKGROUND_COLOR,
    vector2 = vector2,
    position = position,
    point = point,
    saveTextToFile = saveTextToFile,
    saveObjectToFile = saveObjectToFile,
    loadTextFromFile = loadTextFromFile,
    loadObjectFromFile = loadObjectFromFile,
    checkPeripheral = checkPeripheral,
    union = union,
    mergeLists = mergeLists,
    refinedDisplayName = refinedDisplayName,
    charIterator = charIterator,
    indexCharIterator = indexCharIterator,
    getTextSpacing = getTextSpacing,
    fillWithCharCentered = fillWithCharCentered,
    getMinAndMax = getMinAndMax,
    toString = toString,
    getCoordinatesString = getCoordinatesString,
    coloredTextIterator = coloredTextIterator,
    buttonView = button,
    button = button,
    listButton = listButton,
    leftButton = leftButton,
    rightButton = rightButton,
    sideButton = sideButton,
    hideButton = hideButton,
    coloredTextButton = coloredTextButton,
    complexSmallButton = complexSmallButton,
}
