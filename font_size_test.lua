monitor = peripheral.find('monitor')

scales = {0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5}

for i, v in ipairs(scales) do
    monitor.setTextScale(v)
    local w = monitor.getSize()
    print(string.format("%-4.1f %-4d", v, w))
end
