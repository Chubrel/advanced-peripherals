local utils = require('utils')
local monitor_utils = require('monitor_utils')


local function updateInfoData()
end


local function writeInfoData()
    local new_line = 2
    local width, height = colony_info.monitor.getSize()
    local start_x = 1 + utils.EDGE_SIZE
    local max_x = width - utils.EDGE_SIZE
    local max_length = max_x  - start_x + 1

    local colony = colony_info.colony

    local active = {}
    if colony.isActive() then
        active.str = 'Active'
        active.text_color = colors.green
    else
        active.str = 'Not Active'
        active.text_color = colors.red
    end
    active.str = utils.fillWithCharCentered(active.str, max_length)

    local underAttack = {}
    if colony.isUnderAttack() then
        underAttack.str = 'Nam pizda'
        underAttack.text_color = colors.red
    else
        underAttack.str = 'Colony is safe'
        underAttack.text_color = colors.green
    end
    underAttack.str = utils.fillWithCharCentered(underAttack.str, max_length)

    local strings = {
        {str = utils.fillWithCharCentered('Colony ' .. colony.getColonyName(), max_length)},
        active,
        {str = utils.fillWithCharCentered('Population: ' .. colony.amountOfCitizens(), max_length)},
        {str = utils.fillWithCharCentered('Max Population: ' .. colony.maxOfCitizens(), max_length)},
        underAttack,
        {str = utils.fillWithCharCentered('Happines: ' .. string.format('%.2f', colony.getHappiness()), max_length)},
    }

    local start_y, max_y = utils.getTextSpacing(height, #strings * new_line, 1)

    local text_data = {
        edges = {{x = start_x, y = start_y}, {x = max_x, y = max_y}},
        new_line = new_line,
        strings = strings
    }

    monitor_utils.writeTextInRectangle(colony_info.monitor, text_data)
end


local function infoTickUpdate()
    return true
end


return {
    updateData = updateInfoData,
    writeData = writeInfoData,
    tickUpdate = infoTickUpdate
}
