local utils = require('utils')
local monitor_utils = require('monitor_utils')
local colony_utils = require('colony_utils')

local tick


local function onTouchBuilderHutLeftButton()
    colony_info.state.builder_hut_index = colony_info.state.builder_hut_index - 1
    colony_info.state.resource_index = 1
end


local function onTouchResourceLeftButton()
    colony_info.state.resource_index = colony_info.state.resource_index - 1
end


local function onTouchBuilderHutRightButton()
    colony_info.state.builder_hut_index = colony_info.state.builder_hut_index + 1
    colony_info.state.resource_index = 1
end


local function onTouchResourceRightButton()
    colony_info.state.resource_index = colony_info.state.resource_index + 1
end


local function builderHutButton(button)
    utils.sideButton(button, 0.33)
end


local function resourceButton(button)
    utils.sideButton(button, 0.66)
end


local function updateBuildButtonsData()
    buttons.builderHutLeft = utils.complexSmallButton(onTouchBuilderHutLeftButton, utils.listButton, utils.leftButton, builderHutButton)
    buttons.resourceLeft = utils.complexSmallButton(onTouchResourceLeftButton, utils.listButton, utils.leftButton, resourceButton)
    buttons.builderHutRight = utils.complexSmallButton(onTouchBuilderHutRightButton, utils.listButton, utils.rightButton, builderHutButton)
    buttons.resourceRight = utils.complexSmallButton(onTouchResourceRightButton, utils.listButton, utils.rightButton, resourceButton)
end


local function toggleBuildButtons()
    local builder_huts = colony_info.state.builder_huts
    local no_builder_huts = #builder_huts == 0
    local resources
    local builder_hut_right, resource_right
    if not no_builder_huts then
        resources = builder_huts[colony_info.state.builder_hut_index].resources
        builder_hut_right = colony_info.state.builder_hut_index == #builder_huts
        resource_right = colony_info.state.resource_index == #resources
    else
        builder_hut_right, resource_right = true, true
    end
    utils.hideButton(buttons.builderHutLeft, colony_info.state.builder_hut_index == 1)
    utils.hideButton(buttons.resourceLeft, colony_info.state.resource_index == 1)
    utils.hideButton(buttons.builderHutRight, builder_hut_right)
    utils.hideButton(buttons.resourceRight, resource_right)
end


local function updateBuildData()
    colony_info.state.builder_huts = colony_utils.findBuilderHuts(colony_info.colony)
    colony_info.state.builder_hut_index = 1
    colony_info.state.resource_index = 1
    for _, builder_hut in ipairs(colony_info.state.builder_huts) do
        builder_hut.resources = colony_info.colony.getBuilderResources(builder_hut.location)
    end

    updateBuildButtonsData()
end


local function writeBuildText()
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


local function writeBuildData()
    writeBuildText()
    toggleBuildButtons()
end


local function buildTickUpdate()
    return tick
end


return {
    updateData = updateBuildData,
    writeData = writeBuildData,
    tickUpdate = buildTickUpdate
}
