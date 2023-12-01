local cc_expect = require('cc.expect')
local expect, field = cc_expect.expect, cc_expect.field
local utils = require('utils')
local position = utils.position
local point = utils.point

local RF_TO_FUEL = 575
local FUEL_SLOT = 2
local TOOL_SLOT = 1
local LAST_SLOT = 16
local MAIN_POINT_NAME = 'main'
local SAVED_POINT_NAME = 'point'
local DIG_FUEL_CONSUMPTION_RATE = 2
local SUCK_FUEL_CONSUMPTION_RATE = 1
local WARP_FUEL_CONSUMPTION_RATE = 1
local DIG_HEIGHT = 30
local TURTLE_RANGE = 3
local START_POSITION = position.fromVector()
local ZERO_VECTOR = vector.new()
local POSITION_FILE_NAME = 'position.txt'


local function GetInventorySlots()
    local slots = {FUEL_SLOT}
    for i = math.max(FUEL_SLOT, TOOL_SLOT) + 1, LAST_SLOT do
        slots[i] = i
    end
    return slots
end


local INVENTORY_SLOTS = GetInventorySlots()


local function isCooldownError(text)
    if string.find(text, 'cooldown') then
        return true
    end
    return false
end


local function refuel(automata)
    turtle.select(FUEL_SLOT)
    local need_fuel
    repeat
        need_fuel = MAX_FUEL_LEVEL - automata.getFuelLevel()
        local result = automata.chargeTurtle(need_fuel)
    until need_fuel == 0 or not result
    return need_fuel == 0
end


local function moveForward(automata)
    if turtle.forward() then
        automata.position = automata.position:moveForward()
        return true
    end
    return false
end


local function moveBack(automata)
    if turtle.back() then
        automata.position = automata.position:moveBack()
        return true
    end
    return false
end


local function moveUp(automata)
    if turtle.up() then
        automata.position = automata.position:moveUp()
        return true
    end
    return false
end


local function moveDown(automata)
    if turtle.down() then
        automata.position = automata.position:moveDown()
        return true
    end
    return false
end


local function rotate(automata, rotation)
    rotation = rotation % 4
    automata.position = automata.position:rotate(rotation)
    if rotation == 1 then
        turtle.turnRight()
    elseif rotation == 2 then
        turtle.turnRight()
        turtle.turnRight()
    elseif rotation == 3 then
        turtle.turnLeft()
    end
end


local function rotateTo(automata, rotation)
    rotate(automata, rotation - automata.position.rotation)
end


local function moveHorizontally(automata, steps, rotation)
    if steps >= 0 then
        for _ = 1, steps do
            if not moveForward(automata) then
                return false
            end
        end
    else
        for _ = -1, steps, -1 do
            if not moveBack(automata) then
                return false
            end
        end
    end
    return true
end


local function moveX(automata, x)
    local abs_x = math.abs(x)
    moveHorizontally(automata, abs_x, x / abs_x - 1)
end


local function moveY(automata, y)
    if y >= 0 then
        for _ = 1, y do
            if not moveUp(automata) then
                return false
            end
        end
    else
        for _ = -1, y, -1 do
            if not moveDown(automata) then
                return false
            end
        end
    end
    return true
end


local function moveZ(automata, z)
    local abs_z = math.abs(z)
    moveHorizontally(automata, abs_z, z / abs_z)
end


local function moveTo(automata, pos)
    local move = pos - automata.position
    repeat
        local last_move = move
        moveX(automata, move.vector.x)
        moveY(automata, move.vector.y)
        moveZ(automata, move.vector.z)
        move = pos - automata.position
        if move.vector == ZERO_VECTOR then
            return true
        elseif last_move.vector == move.vector then
            return false
        end
    until false
end


local function savePoint(automata, point_name)
    automata.savePoint(point_name)
    local point_ = point.fromPosition(automata.position, point_name)
    automata.saved_points[point_name] = point_
end


local function saveMainPoint(automata)
    savePoint(automata, MAIN_POINT_NAME)
end


local function saveExtraPoint(automata)
    savePoint(automata, SAVED_POINT_NAME)
    utils.saveTextToFile(automata.saved_points[SAVED_POINT_NAME].position:serialize(), POSITION_FILE_NAME)
end


local function warpToPoint(automata, point_name)
    automata.setFuelConsumptionRate(WARP_FUEL_CONSUMPTION_RATE)
    while not automata.warpToPoint(point_name) do
    end
    automata.position = automata.saved_points[point_name].position
end


local function waitCooldown(automata, operation)
    local cooldown = automata.getOperationCooldown(operation)
    if cooldown > 0 then
        os.sleep(cooldown / 1000 + 0.01)
    end
end


local function mineRotationGenerator()
    local length = 0
    local side = 1
    local index = 1
    local rotations = {}
    local function subGenerator()
        local rotations_ = {side, side}
        for _ = 1, length do
            table.insert(rotations_, 0)
        end
        table.insert(rotations_, side)
        for _ = 1, 2 * length + 1 do
            table.insert(rotations_, 0)
        end
        table.insert(rotations_, side)
        for _ = 1, length do
            table.insert(rotations_, 0)
        end
        length = length + 1
        side = -side
        return rotations_
    end
    local function generator()
        local rotation = rotations[index]
        if not rotation then
            rotations = subGenerator()
            index = 1
            rotation = rotations[index]
        end
        index = index + 1
        return rotation
    end
    return generator
end


local function restock(automata)
    for _, slot in pairs(INVENTORY_SLOTS) do
        turtle.select(slot)
        turtle.dropDown()
    end
    turtle.select(FUEL_SLOT)
    turtle.suckUp(1)
end


local function returnToBase(automata)
    saveExtraPoint(automata)
    if automata.saved_points[MAIN_POINT_NAME] then
        warpToPoint(automata, MAIN_POINT_NAME)
    else
        if not moveTo(automata, START_POSITION) then
            error('Cannot get to destination')
        end
        saveMainPoint(automata)
    end
    restock(automata)
    warpToPoint(automata, SAVED_POINT_NAME)
end


local function suck(automata)
    automata.setFuelConsumptionRate(SUCK_FUEL_CONSUMPTION_RATE)
    return automata.collectItems()
end


local function isInventoryFull(automata)
    return turtle.getItemCount(LAST_SLOT) ~= 0
end


local function hasBlockToDig(automata)
    return automata.lookAtBlock()
end


local function mineSuckOne(automata)
    automata.setFuelConsumptionRate(DIG_FUEL_CONSUMPTION_RATE)
    turtle.select(TOOL_SLOT)
    if hasBlockToDig(automata) then
        repeat
            local result, err = automata.digBlock()
            if result then
                suck(automata)
                if isInventoryFull(automata) then
                    returnToBase(automata)
                end
                return true
            end
        until not (hasBlockToDig(automata) and isCooldownError(err))
    end
    return false
end


local function digSuckLineInRange(automata)
    for _ = 1, TURTLE_RANGE do
         if not mineSuckOne(automata) then
            return
         end
    end
end


local function mine(automata, rotation)
    digSuckLineInRange(automata)
    rotate(automata, rotation)
    mineSuckOne(automata)
    rotate(automata, rotation)
    digSuckLineInRange(automata)
    return -rotation
end


local function tunnel(automata)
    local y = -1
    local rotation = 1
    while true do
        repeat
            refuel(automata)
            rotate(automata, -rotation)
            rotation = mine(automata, rotation)
            y = -y
            if not moveY(automata, y) then
                y = -y
                if not moveY(automata, y) then
                    break
                end
            end
            rotation = mine(automata, rotation)
            for _ = 3, DIG_HEIGHT do
                if not moveY(automata, y) then
                    break
                end
                rotation = mine(automata, rotation)
            end
        until true
        rotateTo(automata, 0)
        moveForward(automata)
    end
end


local function main(is_start)
    print('Running tunnel mining')
    Automata = peripheral.find('endAutomata')
    utils.checkPeripheral(Automata, 'End Automata')
    MAX_FUEL_LEVEL = Automata.getMaxFuelLevel()
    Automata.saved_points = {}
    if turtle.getItemCount(TOOL_SLOT) == 0 then
        error('Automata has no tool')
    end
    if is_start then
        Automata.position = START_POSITION
        saveMainPoint(Automata)
    else
        Automata.position = position.unserialize(utils.loadTextFromFile(POSITION_FILE_NAME))
    end

    tunnel(Automata)
end


return {
    main = main
}
