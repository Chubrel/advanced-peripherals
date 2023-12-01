monitor = peripheral.find('monitor')

function setScale(string_length)
    for i = 5, 0.5, -0.5 do
        monitor.setTextScale(i)
        if string_length <= monitor.getSize() then
            break
        end
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

phrases = {
    "Maybe a cup of tea?", 
    "Lucy, tea!",
    "Well planned - half done.", 
    "Every word has a meaning ...",
    "Life is always happening now.",
    "We are ripples in time.",
    "Life requires movement.",
}

while true do
    for i, str in ipairs(phrases) do
        monitor.clear()
        setScale(#str)
        width, height = monitor.getSize()
        monitor.setCursorPos(1, math.ceil(height / 2))
        monitor.write(centered(str))
        sleep(2)
    end
end
