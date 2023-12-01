local fission_reactor_utils = require('fission_reactor_utils')


local function main()
    local fission_reactor = fission_reactor_utils.getFissionReactor()
    local max_burn_rate = fission_reactor.getMaxBurnRate()
    local min_burn_rate = 0
    local burn_rate = fission_reactor.getBurnRate()
    local last_coolant_percent = fission_reactor.getCoolantFilledPercentage()
    print('Running fission reactor burn rate manager')
    while true do
        local coolant_percent = fission_reactor.getCoolantFilledPercentage()
        local is_active = fission_reactor.getStatus()
        local fuel = fission_reactor.getFuel()
        if is_active and fuel ~= 0 then
            if last_coolant_percent <= coolant_percent then
                burn_rate = math.min(burn_rate + 0.01, max_burn_rate)
            else
                burn_rate = math.max(burn_rate - 0.25, min_burn_rate)
            end
            fission_reactor.setBurnRate(burn_rate)
        end
        last_coolant_percent = coolant_percent
        os.sleep(0.2)
    end
end


return {
    main = main
}
