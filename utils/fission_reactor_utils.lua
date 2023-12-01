local cc_expect = require('cc.expect')
local expect, field = cc_expect.expect, cc_expect.field
local utils = require('utils')


local function checkFissionReactor(fission_reactor)
    utils.checkPeripheral(fission_reactor, 'Fission Reactor')
end


local function getFissionReactor()
    local fission_reactor = peripheral.find('fissionReactorLogicAdapter')
    checkFissionReactor(fission_reactor)
    return fission_reactor
end


return {
    checkFissionReactor = checkFissionReactor,
    getFissionReactor = getFissionReactor,
}
