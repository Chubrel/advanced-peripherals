local cc_expect = require('cc.expect')
local expect, field = cc_expect.expect, cc_expect.field
local utils = require('utils')


local function checkMonitor(monitor)
    utils.checkPeripheral(monitor, 'Monitor')
end


local function setScale(monitor, min_width, min_height)
    if min_width == nil then
        min_width = 1
    end
    if min_height == nil then
        min_height = 1
    end
    for i = 5, 0.5, -0.5 do
        monitor.setTextScale(i)
        local width, height = monitor.getSize()
        if min_width <= width and min_height <= height then
            break
        end
    end
end


-- Data is similar to ColoredTextIterator
local function writeTextInRectangle(monitor, data)
    for x, y, str, text_color, background_color in utils.coloredTextIterator(data) do
        monitor.setCursorPos(x, y)
        monitor.setTextColor(text_color)
        monitor.setBackgroundColor(background_color)
        monitor.write(str)
    end
end


-- Data example
-- {char = '.', char_color = colors.white, background_color = colors.gray, edges = {{x = 1, y = 2}, {x = 3, y = 4}}}
local function fillRectangle(monitor, data)
    monitor.setBackgroundColor(data.background_color or utils.BACKGROUND_COLOR)
    monitor.setTextColor(data.char_color or utils.TEXT_COLOR)
    local x1, x2 = utils.getMinAndMax(data.edges[1].x, data.edges[2].x)
    local y1, y2 = utils.getMinAndMax(data.edges[1].y, data.edges[2].y)
    local char = data.char or ' '
    local str = char:rep(x2 - x1 + 1)
    for y = y1, y2 do
        monitor.setCursorPos(x1, y)
        monitor.write(str)
    end
end


-- Data example
-- {background_color = colors.gray, char = ' ', char_color = colors.black
--  outer = {{x = 1, y = 2}, {x = 7, y = 8}}, inner = {{x = 3, y = 4}, {x = 5, y = 6}}}
local function fillFrame(monitor, data)
    local outer_x1, outer_x2 = data.outer[1].x, data.outer[2].x
    local outer_y1, outer_y2 = data.outer[1].y, data.outer[2].y
    local inner_x1, inner_x2 = data.inner[1].x, data.inner[2].x
    local inner_y1, inner_y2 = data.inner[1].y, data.inner[2].y
    local char = data.char
    local char_color = data.char_color
    local background_color = data.background_color
    fillRectangle(
        monitor,
        {
            background_color = background_color,
            char_color = char_color,
            char = char,
            edges = {{x = outer_x1, y = outer_y1}, {x = inner_x1, y = inner_y2 - 1}}
        })
    fillRectangle(
        monitor,
        {
            background_color = background_color,
            char_color = char_color,
            char = char,
            edges = {{x = inner_x1 + 1, y = outer_y1}, {x = outer_x2, y = inner_y1}}
        })
    fillRectangle(
        monitor,
        {
            background_color = background_color,
            char_color = char_color,
            char = char,
            edges = {{x = outer_x1, y = inner_y2}, {x = inner_x2 - 1, y = outer_y2}}
        })
    fillRectangle(
        monitor,
        {
            background_color = background_color,
            char_color = char_color,
            char = char,
            edges = {{x = inner_x2, y = inner_y1 + 1}, {x = outer_x2, y = outer_y2}}
        })
end


return {
    checkMonitor = checkMonitor,
    setScale = setScale,
    writeTextInRectangle = writeTextInRectangle,
    fillRectangle = fillRectangle,
    fillFrame = fillFrame,
}
