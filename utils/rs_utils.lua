local cc_expect = require('cc.expect')
local expect, field = cc_expect.expect, cc_expect.field
local utils = require('utils')


local function checkRSBridge(rs_bridge)
    utils.checkPeripheral(rs_bridge, 'RS Bridge')
end


return {
    checkRSBridge = checkRSBridge
}
