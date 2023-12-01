local info = require('info')
local citizens = require('citizens')
local requests = require('requests')
local build = require('build')

local states =
{
    INFO = {
        writeData = info.writeData,
        updateData = info.updateData,
        tickUpdate = info.tickUpdate,
        requestors = {},
        request_index = 1,
        requestor_index = 1,
        item_index = 1,
    },
    REQUESTS = {
        writeData = requests.writeData,
        updateData = requests.updateData,
        tickUpdate = requests.tickUpdate,
    },
    BUILD = {
        writeData = build.writeData,
        updateData = build.updateData,
        tickUpdate = build.tickUpdate,
        builder_huts = {},
        builder_hut_index = 1,
        resource_index = 1,
    },
    CITIZENS = {
        writeData = citizens.writeData,
        updateData = citizens.updateData,
        tickUpdate = citizens.tickUpdate,
        citizens = {},
        citizen_index = 1,
    },
}

return {
    states = states
}
