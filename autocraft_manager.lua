monitor = peripheral.find('monitor')
rs = peripheral.find('rsBridge')

text_colors = {
    good = colors.green,
    bad = colors.red,
    highlight = colors.lightBlue,
    default = colors.white,
}

bg_colors = {
    default = colors.black,
}

NAMES = 'Names'
STORED = 'Stored'
NEEDED = 'Needed'

autocraft_items = {
    {"Iron", "minecraft:iron_ingot", 256},
    {"Redstone", "minecraft:redstone", 256},
    {"Charcoal", "minecraft:charcoal", 128},
    {"Charcoal Block", "quark:charcoal_block", 128},
    {"Uranium Dust", "mekanism:yellow_cake_uranium", 256},
    {"Fluorite", "mekanism:fluorite_gem", 64},
    {"Stuffed Aubergine", "mysticalworld:stuffed_aubergine", 256},
}

function intLength(int)
    return #tostring(int)
end

names_length = #NAMES
needed_length = #NEEDED

for i, v in ipairs(autocraft_items) do
    if #v[1] > names_length then
        names_length = #v[1]
    end
    if intLength(v[3]) > needed_length then
        needed_length = intLength(v[3])
    end
end

function centered(str, length, filler)
    if filler == nil then
        filler = ' '
    end
    if length == nil then
        length = monitor.getSize()
    end
    fill_count = math.floor(((length - #str) / 2))
    return string.rep(' ', fill_count) .. str .. string.rep(' ', length - #str - fill_count)
end

function rfill(str, length, filler)
    if filler == nil then
        filler = ' '
    end
    return str .. string.rep(filler, length - #str)
end

function lfill(str, length, filler)
    if filler == nil then
        filler = ' '
    end
    return string.rep(filler, length - #str) .. str
end

function bfill(str1, str2, length, filler)
    if filler == nil then
        filler = ' '
    end
    return str1 .. string.rep(filler, length - #str1 - #str2) .. str2
end

while true do
    rs_items = rs.listItems()
    table.sort(rs_items, function(a, b) return a.amount < b.amount end)
    needed_items = {}
    stored_length = #STORED
    for i, v in ipairs(rs_items) do
        for j, w in ipairs(autocraft_items) do
            if v.name == w[2] then
                needed_items[j] = v
                if intLength(w.amount) > stored_length then
                    stored_length = intLength(w.amount)
                end
            end
        end
    end

    monitor.clear()
    monitor.setTextScale(1)
    local monitor_width = monitor.getSize()
    monitor.setCursorPos(1, 1)
    monitor.setBackgroundColor(bg_colors.default)
    monitor.setTextColor(text_colors.highlight)
    monitor.write(centered('AUTOCRAFT MANAGER', monitor_width))
    monitor.setCursorPos(1, 3)
    monitor.setTextColor(text_colors.default)
    monitor.write(bfill(NAMES, STORED, monitor_width - needed_length - 1) .. ' ' .. lfill(NEEDED, needed_length))
    for i, v in ipairs(autocraft_items) do
        monitor.setCursorPos(1, i + 3)
        if needed_items[i].amount < v[3] then
            monitor.setTextColor(text_colors.bad)
        else
            monitor.setTextColor(text_colors.good)
        end
        monitor.write(bfill(v[1], tostring(needed_items[i].amount), monitor_width - needed_length - 1) .. ' ' .. lfill(tostring(v[3]), needed_length))
    end
    for i, v in ipairs(needed_items) do
        if v.amount < autocraft_items[i][3] then
            if not rs.isItemCrafting(v.name) then
                local need_to_craft = autocraft_items[i][3] - v.amount
                local craft_items = {
                    name = v.name,
                    amount = need_to_craft,
                }
                rs.craftItem(craft_items)
                print("Crafting " .. need_to_craft .. " " .. autocraft_items[i][1])
            end
        end
    end
    sleep(5)
end
