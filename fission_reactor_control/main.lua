local fission_reactor_utils = require('fission_reactor_utils')

local REACTOR_WATER_SCRAM_THRESHOLD_PERCENT = 0.9
local REACTOR_WATER_ACTIVATION_THRESHOLD_PERCENT = 0.999
local REACTOR_WASTE_SCRAM_THRESHOLD_PERCENT = 0.9
local REACTOR_WASTE_ACTIVATION_THRESHOLD_PERCENT = 0.001
local REACTOR_HEATED_COOLANT_SCRAM_THRESHOLD_PERCENT = 0.5
local REACTOR_HEATED_COOLANT_THRESHOLD_PERCENT = 0.001


local function main()
    local fission_reactor = fission_reactor_utils.getFissionReactor()
    print('Running fission reactor control')
    while true do
        local coolant_percent = fission_reactor.getCoolantFilledPercentage()
        local waste_percent = fission_reactor.getWasteFilledPercentage()
        local heated_coolant_percent = fission_reactor.getHeatedCoolantFilledPercentage()
        local is_active = fission_reactor.getStatus()
        if is_active then
            if coolant_percent < REACTOR_WATER_SCRAM_THRESHOLD_PERCENT or waste_percent > REACTOR_WASTE_SCRAM_THRESHOLD_PERCENT or heated_coolant_percent > REACTOR_HEATED_COOLANT_SCRAM_THRESHOLD_PERCENT then
                fission_reactor.scram()
            end
        else
            if coolant_percent > REACTOR_WATER_ACTIVATION_THRESHOLD_PERCENT and waste_percent < REACTOR_WASTE_ACTIVATION_THRESHOLD_PERCENT and heated_coolant_percent < REACTOR_HEATED_COOLANT_THRESHOLD_PERCENT then
                fission_reactor.activate()
            end
        end
        os.sleep(0.2)
    end
end


return {
    main = main
}
