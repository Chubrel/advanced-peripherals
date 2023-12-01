monitor = peripheral.find('monitor')

monitor.setBackgroundColor(colors.red)
monitor.setTextScale(0.5)

while true do
    event, side, x, y = os.pullEvent("monitor_touch")
    monitor.setCursorPos(x, y)
    monitor.write(' ')
end
