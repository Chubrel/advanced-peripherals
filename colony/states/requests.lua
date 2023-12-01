local utils = require('utils')
local monitor_utils = require('monitor_utils')
local colony_utils = require('colony_utils')

local tick = false


local function onTouchCitizenLeftButton()
    colony_info.state.requestor_index = colony_info.state.requestor_index - 1
    colony_info.state.request_index = 1
    colony_info.state.item_index = 1
end


local function onTouchRequestLeftButton()
    colony_info.state.request_index = colony_info.state.request_index - 1
    colony_info.state.item_index = 1
end


local function onTouchItemLeftButton()
    colony_info.state.item_index = colony_info.state.item_index - 1
end


local function onTouchCitizenRightButton()
    colony_info.state.requestor_index = colony_info.state.requestor_index + 1
    colony_info.state.request_index = 1
    colony_info.state.item_index = 1
end


local function onTouchRequestRightButton()
    colony_info.state.request_index = colony_info.state.request_index + 1
    colony_info.state.item_index = 1
end


local function onTouchItemRightButton()
    colony_info.state.item_index = colony_info.state.item_index + 1
end


local function citizenButton(button)
    utils.sideButton(button, 0.25)
end


local function requestButton(button)
    utils.sideButton(button, 0.5)
end


local function itemButton(button)
    utils.sideButton(button, 0.75)
end


local function updateRequstButtonsData()
    local left_citizen_button = utils.complexSmallButton(onTouchCitizenLeftButton, utils.listButton, utils.leftButton, citizenButton)
    local left_request_button = utils.complexSmallButton(onTouchRequestLeftButton, utils.listButton, utils.leftButton, requestButton)
    local left_item_button = utils.complexSmallButton(onTouchItemLeftButton, utils.listButton, utils.leftButton, itemButton)
    local right_citizen_button = utils.complexSmallButton(onTouchCitizenRightButton, utils.listButton, utils.rightButton, citizenButton)
    local right_request_button = utils.complexSmallButton(onTouchRequestRightButton, utils.listButton, utils.rightButton, requestButton)
    local right_item_button = utils.complexSmallButton(onTouchItemRightButton, utils.listButton, utils.rightButton, itemButton)

    buttons.citizenLeft = left_citizen_button
    buttons.requestLeft = left_request_button
    buttons.itemLeft = left_item_button
    buttons.citizenRight = right_citizen_button
    buttons.requestRight = right_request_button
    buttons.itemRight = right_item_button
end


local function toggleRequestButtons()
    local requestors = colony_info.state.requestors
    local no_requestors = #requestors == 0
    local requests
    local items
    local citizen_right, request_right, item_right
    if not no_requestors then
        requests = requestors[colony_info.state.requestor_index].requests
        items = requests[colony_info.state.request_index].items
        citizen_right = #requestors == colony_info.state.requestor_index
        request_right = #requests == colony_info.state.request_index
        item_right = #items == colony_info.state.item_index
    else
        citizen_right, request_right, item_right = true, true, true
    end
    utils.hideButton(buttons.citizenLeft, colony_info.state.requestor_index == 1)
    utils.hideButton(buttons.requestLeft, colony_info.state.request_index == 1)
    utils.hideButton(buttons.itemLeft, colony_info.state.item_index == 1)
    utils.hideButton(buttons.citizenRight, citizen_right)
    utils.hideButton(buttons.requestRight, request_right)
    utils.hideButton(buttons.itemRight, item_right)
end


local function writeRequestText()
    local width, height = colony_info.monitor.getSize()
    local new_line = 2
    local start_x
    local max_x
    local strings
    if #colony_info.state.requestors == 0 then
        strings = {
            {str = "No requests"},
            {str = " Good job!"},
        }
        local max_string_size = #strings[1].str
        start_x, max_x = utils.getTextSpacing(width, max_string_size, 1)
        tick = true
    else
        local requestor = colony_info.state.requestors[colony_info.state.requestor_index]
        local request = requestor.requests[colony_info.state.request_index]
        local item = request.items[colony_info.state.item_index]

        strings = {
            {str = colony_info.state.requestor_index .. '. ' .. requestor.name},
            {str = colony_info.state.request_index .. '. ' .. request.name},
            {str = colony_info.state.item_index .. '. ' .. request.count .. ' ' .. item.name .. utils.toString(item.nbt)},
        }

        if request.name ~= request.desc then
            table.insert(strings, 3, {str = request.desc})
            strings[2].new_line = 0
        end
        start_x = 1 + utils.EDGE_SIZE
        max_x = width - utils.EDGE_SIZE
        tick = false
    end
    
    local start_y, max_y = utils.getTextSpacing(height, #strings * new_line - 2, 1)

    local text_data = {
        edges = {{x = start_x, y = start_y}, {x = max_x, y = max_y}},
        new_line = new_line,
        strings = strings
    }

    monitor_utils.writeTextInRectangle(colony_info.monitor, text_data)
end


local function updateRequestData()
    colony_info.state.request_index = 1
    colony_info.state.requestor_index = 1
    colony_info.state.item_index = 1
    local requests = colony_info.colony.getRequests()
    colony_info.state.requestors = {}
    for _, request in ipairs(requests) do
        local requestor = colony_utils.findCitizenByName(colony_info.colony, request.target)
        if requestor == nil then
            requestor = {name = request.target}
        end
        request.requestor = requestor
        if requestor.requests then
            table.insert(requestor.requests, request)
        else
            table.insert(colony_info.state.requestors, requestor)
            requestor.requests = {request}
        end
    end

    updateRequstButtonsData()
end


local function writeRequestData()
    writeRequestText()
    toggleRequestButtons()
end


local function requestTickUpdate()
    return tick
end


return {
    updateData = updateRequestData,
    writeData = writeRequestData,
    tickUpdate = requestTickUpdate
}
