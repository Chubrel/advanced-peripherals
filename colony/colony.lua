local cc_expect = require('cc.expect')
local expect, field = cc_expect.expect, cc_expect.field
local utils = require('utils')
local monitor_utils = require('monitor_utils')
local colony_utils = require('colony_utils')
local state = require('states').states

local MIN_MONITOR_WIDTH = 24
local MIN_MONITOR_HEIGHT = 18

local INFO_BUTTON_NAME = 'INFO'
local CITIZEN_BUTTON_NAME = 'CITIZENS'
local REQUEST_BUTTON_NAME = 'REQUESTS'
local BUILD_BUTTON_NAME = 'BUILD'
local UPDATE_BUTTON_NAME = 'UPDATE'

local INFO_BUTTON_BACKGROUND_COLOR = colors.green
local CITIZEN_BUTTON_BACKGROUND_COLOR = colors.brown
local REQUEST_BUTTON_BACKGROUND_COLOR = colors.magenta
local BUILD_BUTTON_BACKGROUND_COLOR = colors.lightBlue
local UPDATE_BUTTON_BACKGROUND_COLOR = colors.red

local TEXT_BUTTON_TEXT_COLOR = colors.black


local function colonyInfo(colony, monitor)
    local object =
        {
            colony = colony,
            monitor = monitor,
            state = state.INFO,
        }
    return object
end


local function checkColonyInfo(colony_info)
    colony_utils.checkColony(colony_info.colony)
    monitor_utils.checkMonitor(colony_info.monitor)
end


local function prepareMonitor(monitor)
    monitor.setBackgroundColor(utils.BACKGROUND_COLOR)
    monitor.setTextColor(utils.TEXT_COLOR)
    monitor.clear()
    monitor_utils.setScale(monitor, MIN_MONITOR_WIDTH, MIN_MONITOR_HEIGHT)
end


local function writeButtons()
    local monitor = colony_info.monitor
    for _, button in pairs(buttons) do
        if button.views ~= nil and not button.invisible then
            for _, view in ipairs(button.views) do
                if not view.invisible then
                    monitor.setBackgroundColor(view.background_color)
                    monitor.setTextColor(view.char_color)
                    monitor.setCursorPos(view.pos.x, view.pos.y)
                    monitor.write(view.char)
                end
            end
        end
    end
end


local function handleEvents()
    local _, _, x, y = os.pullEvent("monitor_touch")
    for _, button in pairs(buttons) do
        if button.views ~= nil and not button.stick then
            for _, view in ipairs(button.views) do
                if view.pos.x == x and view.pos.y == y and not view.stick then
                    button.onTouch()
                    WriteData()
                    return
                end
            end
        end
    end
end


local function onTouchInfoButton()
    colony_info.state = state.INFO

    Update()
end


local function onTouchRequestButton()
    colony_info.state = state.REQUESTS

    Update()
end


local function onTouchBuildButton()
    colony_info.state = state.BUILD

    Update()
end


local function onTouchCitizenButton()
    colony_info.state = state.CITIZENS

    Update()
end


local function onTouchUpdateButton()
    Update()
end


local function mainButton(name, text_color, background_color, height, scale, onTouch)
    local width = colony_info.monitor.getSize()
    local button_x1, button_x2 = utils.getTextSpacing(width, #name, scale)
    local button = utils.coloredTextButton(
        {
            strings = {{str = name}},
            background_color = background_color,
            text_color = text_color,
            edges = {{x = button_x1, y = height}, {x = button_x2, y = height}}
        }
    )
    button.onTouch = onTouch
    return button
end


local function updateMainButtons()
    local _, height = colony_info.monitor.getSize()
    local info_button = mainButton(INFO_BUTTON_NAME, TEXT_BUTTON_TEXT_COLOR, INFO_BUTTON_BACKGROUND_COLOR, height, 0.4, onTouchInfoButton)
    local citizen_button = mainButton(CITIZEN_BUTTON_NAME, TEXT_BUTTON_TEXT_COLOR, CITIZEN_BUTTON_BACKGROUND_COLOR, height, 0.8, onTouchCitizenButton)
    local request_button = mainButton(REQUEST_BUTTON_NAME, TEXT_BUTTON_TEXT_COLOR, REQUEST_BUTTON_BACKGROUND_COLOR, height, 1.2, onTouchRequestButton)
    local build_button = mainButton(BUILD_BUTTON_NAME, TEXT_BUTTON_TEXT_COLOR, BUILD_BUTTON_BACKGROUND_COLOR, height, 1.6, onTouchBuildButton)
    local update_button = mainButton(UPDATE_BUTTON_NAME, TEXT_BUTTON_TEXT_COLOR, UPDATE_BUTTON_BACKGROUND_COLOR, 1, 1, onTouchUpdateButton)

    buttons.info = info_button
    buttons.citizens = citizen_button
    buttons.requests = request_button
    buttons.build = build_button
    buttons.update = update_button
end


local function updateData()
    buttons = {}
    updateMainButtons()
    colony_info.state.updateData()
end


function WriteData()
    prepareMonitor(colony_info.monitor)
    local width, height = colony_info.monitor.getSize()
    monitor_utils.fillFrame(
        colony_info.monitor,
        {
            background_color = colors.yellow,
            char_color = utils.TEXT_COLOR,
            char = ' ',
            outer = {{x = 1, y = 1}, {x = width, y = height}},
            inner = {{x = 1, y = 1}, {x = width, y = height}}
        })
    colony_info.state.writeData()
    writeButtons()
end


function Update()
    updateData()
    WriteData()
end


local function tryUpdate()
    if colony_info.state.tickUpdate() then
        Update()
    end
end


local function main()

    local monitor = peripheral.find("monitor")
    local colony = peripheral.find("colonyIntegrator")
    colony_info = colonyInfo(colony, monitor)
    checkColonyInfo(colony_info)
    print('Running colony information manager')

    Update()

    while true do
        os.sleep(0.25)

        handleEvents()

        tryUpdate()
    end
end


return {
    main = main,
}
