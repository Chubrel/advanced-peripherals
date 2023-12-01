local cc_expect = require('cc.expect')
local expect, field = cc_expect.expect, cc_expect.field
local utils = require('utils')
local colony_utils = require('colony_utils')
local rs_utils = require('rs_utils')

local TICK_TIME = 5
local REQUEST_EXPIRE_SECONDS = 60
local CRAFT_COMPLETION_EXPIRE_SECONDS = 60
local EXPORT_COMPLETION_EXPIRE_SECONDS = 2 * 60
local DIRECTION = 'up'

local ITEM_EXCEPTIONS = {
    'mekanism:hazmat_mask',
    'mekanism:hazmat_gown',
    'mekanism:hazmat_pants',
    'mekanism:hazmat_boots',
}


local function in_item_exceptions(item)
    for _, value in ipairs(ITEM_EXCEPTIONS) do
        if value == item.id then
            return true
        end
    end
    return false
end


local function colonyBridge(colony, rs_bridge, block_reader)
    local object = {
        colony = colony,
        rs_bridge = rs_bridge,
        block_reader = block_reader,
        items_to_craft = {},
        items_to_export = {},
        requests = {},
        timed_states = {
            executed_craft_orders = {},
            exported_items = {},
        },
        errors = {
            unfulfillable_requests = {},
            cannot_craft = {},
            cannot_export = {},
        },
        runtime = 0,
    }

    function object:add_request(request)
        local colony_bridge = self
        local old_request = self.requests[request.target .. ' ' .. request.name]
        if old_request == nil or old_request:is_expired() then
            
            request.is_fulfilled = false
            request.expire_time = nil
            request.true_count = request.count

            function request:reset_expire_time()
                self.expire_time = colony_bridge.runtime + REQUEST_EXPIRE_SECONDS
            end

            function request:is_expired()
                return self.expire_time < colony_bridge.runtime
            end

            self.requests[request.target .. ' ' .. request.name] = request
        else
            request = old_request
        end

        return request
    end

    function object:add_executed_craft_order(item)
        self.timed_states.executed_craft_orders[item.id .. ' ' .. item.count] = self.runtime + CRAFT_COMPLETION_EXPIRE_SECONDS;
    end

    function object:is_executed_craft_order(item)
        local time = self.timed_states.executed_craft_orders[item.id .. ' ' .. item.count]
        return time ~= nil and time < self.runtime;
    end

    function object:add_exported_item(item)
        self.timed_states.exported_items[item.id .. ' ' .. item.count] = self.runtime + EXPORT_COMPLETION_EXPIRE_SECONDS;
    end

    function object:is_exported_item(item)
        local time = self.timed_states.exported_items[item.id .. ' ' .. item.count]
        return time ~= nil and time < self.runtime;
    end

    function object:add_unfulfillable_request(request)
        local unfulfillable_request = self.errors.unfulfillable_requests[request.name]
        if not unfulfillable_request then
            self.errors.unfulfillable_requests[request.name] = {
                request = request,
                is_notified = false,
            }
        end
    end

    function object:reset_unfulfillable_request(request)
        self.errors.unfulfillable_requests[request.name] = nil
    end

    function object:add_cannot_craft(item)
        local cannot_craft_item = self.errors.cannot_craft[item.id]
        if not cannot_craft_item then
            self.errors.cannot_craft[item.id] = {
                item = item,
                is_notified = false,
            }
        end
    end

    function object:reset_cannot_craft(item)
        self.errors.unfulfillable_requests[item.id] = nil
    end

    function object:add_cannot_export(item)
        local cannot_export_item = self.errors.cannot_export[item.id]
        if not cannot_export_item then
            self.errors.cannot_export = {
                item = item,
                is_notified = false,
            }
        end
    end

    function object:reset_cannot_export(item)
        self.errors.unfulfillable_requests[item.id] = nil
    end

    return object
end


local function checkColonyBridge(colony_bridge)
    colony_utils.checkColony(colony_bridge.colony)
    rs_utils.checkRSBridge(colony_bridge.rs_bridge)
    utils.checkPeripheral(colony_bridge.block_reader, 'Block Reader')
end


local function importItems(colony_bridge)
    for _, item in pairs(colony_bridge.block_reader.getBlockData().Items) do
        local to_import = {
            name = item.id,
            count = item.Count,
        }
        colony_bridge.rs_bridge.importItem(to_import, DIRECTION)
        -- print(_ .. ' ' .. item.id .. ' ' .. item.Count)
        -- for _, direction in ipairs(utils.CARDINAL_DIRECTIONS) do
        --     local n = colony_bridge.rs_bridge.importItem(to_import, direction)
        --     print(direction .. ' ' .. n)
        -- end
    end
end


local function requestItems(colony_bridge)
    local colony = colony_bridge.colony
    local rs_bridge = colony_bridge.rs_bridge
    local requests = colony.getRequests()
    colony_bridge.items_to_export = {}
    colony_bridge.items_to_craft = {}
    --Экспортирует всякий хлам
    local item_to_export = {
        name = 'minecraft:carrot',
        count = 17,
        nbt = {},
    }
    local exported_count = rs_bridge.exportItem(item_to_export, DIRECTION)
    print('Exported ' .. exported_count .. ' ' .. utils.toString(item_to_export))
    for _, request in pairs(requests) do
        colony_bridge:add_request(request)
    end
    for _, request in pairs(colony_bridge.requests) do
        if not request.is_fulfilled then
            request:reset_expire_time()
            for _, item_variant in ipairs(request.items) do
                local item = {
                    request = request,
                    variant = item_variant,
                    id = item_variant.name,
                    nbt = item_variant.nbt,
                    count = request.true_count,
                    display_name = utils.refinedDisplayName(item_variant.displayName),
                    to_craft = false,
                    is_craftable = false,
                    need_craft = false,
                    is_craft_ordered = false,
                    rs_item = nil,
                }
                item.nbt.Damage = nil
                if not in_item_exceptions(item) then
                    local named_item = {
                        name = item.id
                    }
                    local rs_item = rs_bridge.getItem(named_item)
                    if rs_item and (rs_item.nbt == nil or rs_item.nbt.Enchantments == nil) then
                        item.is_craftable = rs_bridge.isItemCraftable(named_item)
                        if rs_item.amount ~= 0 or item.is_craftable then
                            print("RS Item " .. item.id .. ' ' .. rs_item.amount .. ' Need ' .. item.count .. ' Craftable ' .. tostring(item.is_craftable))
                        end
                        item.rs_item = rs_item
                        if rs_item.amount >= item.count then
                            --Экспортирует всякий хлам
                            local item_to_export = {
                                name = item.id,
                                count = item.count,
                                nbt = item.nbt,
                            }
                            local exported_count = rs_bridge.exportItem(item_to_export, DIRECTION)
                            print('Exported ' .. exported_count .. ' ' .. utils.toString(item_to_export))
                            if exported_count ~= 0 then
                                colony_bridge:add_exported_item(item)
                                request.is_fulfilled = true
                                break
                            else
                                item.to_craft = true
                            end
                        end
                        if item.is_craftable then
                            local count_to_craft
                            if rs_item.amount < item.count then
                                count_to_craft = item.count - rs_item.amount
                            elseif item.to_craft then
                                count_to_craft = item.count
                            end
                            item.need_craft = count_to_craft and not rs_bridge.isItemCrafting(named_item) and not colony_bridge:is_executed_craft_order(item)
                            print("Need Craft " .. tostring(item.need_craft) .. ' ' .. tostring(rs_item.amount < item.count) .. ' ' .. tostring(item.to_craft) .. ' Count ' .. count_to_craft .. ' ' .. tostring(rs_bridge.isItemCrafting(named_item)) .. ' ' .. tostring(colony_bridge:is_executed_craft_order(item)))
                            if item.need_craft then
                                local to_craft = {
                                    name = item.id,
                                    count = count_to_craft,
                                }
                                item.is_craft_ordered = rs_bridge.craftItem(to_craft)
                                print("Order Craft " .. tostring(item.is_craft_ordered))
                                if item.is_craft_ordered then
                                    colony_bridge:add_executed_craft_order(item)
                                else
                                    colony_bridge:add_cannot_craft(item)
                                end
                            end
                            break
                        end
                    end
                end
            end
            if not request.is_fulfilled then
                colony_bridge:add_unfulfillable_request(request)
            end
        end
    end
end


local function updateRSItems(colony_bridge)
    
end


local function notifyNilItems(colony_bridge)
    
end


local function exportItems(colony_bridge)
    
end


local function orderCraft(colony_bridge)
    for _, item in ipairs(items) do
        if item.item then

        end
    end
end


local function notifyCannotFulfullRequests(unfulfillable_requests)
    for _, object in pairs(unfulfillable_requests) do
        if not object.is_notified then
            object.is_notified = true
            print('Cannot fulfill request "' .. object.request.name .. '"')
        end
    end
end


local function notifyCannotExport(cannot_export)
    for _, object in pairs(cannot_export) do
        if not object.is_notified then
            object.is_notified = true
            local item = object.item
            print('Cannot export ' .. item.count .. ' ' .. item.name .. ' (' .. item.id .. ') to fulfill request "' .. item.request.name .. '"')
        end
    end
    -- for _, item in ipairs(items) do
    --     if item.need_export and not item.to_craft and item.exported_count == 0 and not errors.cannot_export[item.request.name]  then
    --         errors.unfulfillable_requests[item.request.name] = nil
    --         errors.cannot_craft[item.request.name] = nil
    --         errors.cannot_export[item.request.name] = true
    --         print('Cannot export ' .. item.count .. ' ' .. item.name .. ' (' .. item.id .. ') to fulfill request "' .. item.request.name .. '"')
    --     end
    -- end
end


local function notifyCannotCraft(cannot_craft)
    for _, object in pairs(cannot_craft) do
        if not object.is_notified then
            object.is_notified = true
            local item = object.item
            print('Cannot craft ' .. item.count .. ' ' .. item.name .. ' (' .. item.id .. ') to fulfill request "' .. item.request.name .. '"')
        end
    end
    -- for _, item in pairs(errors) do
    --     if item.need_craft and not item.is_craft_ordered and not errors.cannot_craft[item.request.name] then
    --         errors.unfulfillable_requests[item.request.name] = nil
    --         errors.cannot_craft[item.request.name] = true
    --         print('Cannot craft ' .. item.count .. ' ' .. item.name .. ' (' .. item.id .. ') to fulfill request "' .. item.request.name .. '"')
    --     end
    -- end
end


local function notifyErrors(errors)
    notifyCannotFulfullRequests(errors.unfulfillable_requests)
    notifyCannotExport(errors.cannot_craft)
    notifyCannotCraft(errors.cannot_export)
end


local function main()
    local colony = peripheral.find('colonyIntegrator')
    local rs_bridge = peripheral.find('rsBridge')
    local block_reader = peripheral.find('blockReader')
    local colony_bridge = colonyBridge(colony, rs_bridge, block_reader)
    checkColonyBridge(colony_bridge)
    print('Running colony RS autocraft')

    while true do
        importItems(colony_bridge)
        requestItems(colony_bridge)
        --updateRSItems(colony_bridge)
        --notifyNilItems(colony_bridge)
        --exportItems(colony_bridge)
        --orderCraft(colony_bridge)
        notifyErrors(colony_bridge.errors)
        sleep(TICK_TIME)
        colony_bridge.runtime = colony_bridge.runtime + TICK_TIME
    end
end


return {
    main = main
}
