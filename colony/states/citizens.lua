local utils = require('utils')
local monitor_utils = require('monitor_utils')
local colony_utils = require('colony_utils')

local tick


local function onTouchCitizenLeftButton()
    colony_info.state.resource_index = colony_info.state.resource_index - 1
end


local function onTouchCitizenRightButton()
    colony_info.state.resource_index = colony_info.state.resource_index + 1
end


local function citizenButton(button)
    utils.sideButton(button, 0.5)
end


local function updateBuildButtonsData()
    buttons.citizenLeft = utils.complexSmallButton(onTouchCitizenLeftButton, utils.listButton, utils.leftButton, citizenButton)
    buttons.citizenRight = utils.complexSmallButton(onTouchCitizenRightButton, utils.listButton, utils.rightButton, citizenButton)
end


local function toggleCitizenButtons()
    local citizens = colony_info.state.citizens
    local no_citizens = #citizens == 0
    local citizen_right
    if not no_citizens then
        citizen_right = colony_info.state.citizen_index == #citizens
    else
        citizen_right = true
    end
    utils.hideButton(buttons.citizenLeft, colony_info.state.citizen_index == 1)
    utils.hideButton(buttons.citizenRight, citizen_right)
end


local function updateCitizenData()
    colony_info.state.citizens = colony_info.colony.getCitizens()

    toggleCitizenButtons()
end


local function writeCitizenData()
    -- female \12 \11 male
    -- age, gender, health, armor, id, isAsleep, happines, isIdle, location, maxHealth, name, skills, saturation, state, toughness, work (level, location, name, type)
    local width, height = colony_info.monitor.getSize()
    local new_line = 2
    local start_x
    local max_x
    local strings
    if #colony_info.state.builder_huts == 0 then
        strings = {
            {str = "No building requests"},
        }
        local max_string_size = #strings[1].str
        start_x, max_x = utils.getTextSpacing(width, max_string_size, 1)
        tick = true
    else
        start_x = 1 + utils.EDGE_SIZE
        max_x = width - utils.EDGE_SIZE
        local builder_hut = colony_info.state.builder_huts[colony_info.state.builder_hut_index]
        strings = {
            {str = colony_info.state.builder_hut_index .. '. Builder Hut at ' .. utils.getCoordinatesString(builder_hut.location)},
        }
        if #builder_hut.citizens ~= 0 then
            local builder_name = builder_hut.citizens[1].name
            local builder = colony_utils.findCitizenByName(colony_info.colony, builder_name)

            table.insert(strings, {str = 'Builder ' .. builder_name .. ' at ' .. utils.getCoordinatesString(builder.location)})

            if #builder_hut.resources ~= 0 then
                local resource = builder_hut.resources[colony_info.state.resource_index]
                local status = {}
                if resource.status == 'DONT_HAVE' then
                    status.str = "Builder don't have a resource"
                    status.text_color = colors.yellow
                elseif resource.status == 'NOT_NEEDED' then
                    status.str = 'Builder have a resource'
                    status.text_color = colors.green
                else
                    error('Unknown builder resource status: ' .. resource.status)
                end

                local extra_strings = {
                    {str = colony_info.state.resource_index .. '. ', new_line = 0},
                    status,
                    {str = resource.displayName},
                    {str = resource.item},
                    {str = 'Needed: ' .. resource.needed},
                    {str = 'Delivering: ' .. resource.delivering},
                    {str = 'Available: ' .. resource.available},
                }
                strings = utils.mergeLists(strings, extra_strings)
            else
                table.insert(strings, {str = 'No building request here'})
            end
        else
            table.insert(strings, {str = 'No builder here'})
        end
        tick = false
    end

    local start_y, max_y = utils.getTextSpacing(height, #strings * new_line - 2, 1)

    local text_data = {
        edges = {{x = start_x, y = start_y}, {x = max_x, y = max_y}},
        new_line = new_line,
        strings = strings,
    }

    monitor_utils.writeTextInRectangle(colony_info.monitor, text_data)
end


local function citizenTickUpdate()
    return tick
end


return {
    updateData = updateCitizenData,
    writeData = writeCitizenData,
    tickUpdate = citizenTickUpdate
}
