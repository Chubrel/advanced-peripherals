local cc_expect = require('cc.expect')
local expect, field = cc_expect.expect, cc_expect.field
local utils = require('utils')


local function checkColony(colony)
    utils.checkPeripheral(colony, 'Colony Integrator')
    if not colony.isInColony then error("Colony Integrator block is not in a colony") end
end


local function findCitizenByName(colony, name)
    expect(1, colony, 'table')
    expect(2, name, 'string')
    for _, citizen in ipairs(colony.getCitizens()) do
        if name:find(citizen.name, 1, true) then
            return citizen
        end
    end
end


local function findBuilderHuts(colony)
    expect(1, colony, 'table')
    local builder_huts = {}
    for _, building in ipairs(colony.getBuildings()) do
        if building.type == 'builder' then
            table.insert(builder_huts, building)
        end
    end
    return builder_huts
end

return {
    checkColony = checkColony,
    findCitizenByName = findCitizenByName,
    findBuilderHuts = findBuilderHuts,
}
