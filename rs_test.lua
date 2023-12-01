local monitor = peripheral.find('monitor')
local rs = peripheral.find('rsBridge')
local speaker = peripheral.find("speaker")

while true do
    list = rs.listItems()
    local item_count = 0
    for i, item in ipairs(list) do
        item_count = item_count + item.amount
    end

    if math.floor((item_count / rs.getMaxItemDiskStorage()) * 100) > 100 / 1.25--[[item_count / rs.getMaxItemDiskStorage() > 0.8]] then
        speaker.playSound("minecraft:block.bell.use")
    end

    sleep(2)
end
