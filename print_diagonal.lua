monitor = peripheral.find('monitor')

monitor.setBackgroundColor(colors.black)
monitor.clear()
monitor.setTextScale(0.5)

function print_diagonal(color)
    monitor.setBackgroundColor(color)

    for i = 1, monitor.getSize() do
        monitor.setCursorPos(i, i)
        monitor.write(' ')
    end
end

print_diagonal(0x00ffff)
