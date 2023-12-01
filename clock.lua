local monitor = peripheral.find('monitor')

function setScale(string_length)
    for i = 5, 0.5, -0.5 do
        monitor.setTextScale(i)
        if string_length <= monitor.getSize() then
            break
        end
    end
end

local local_utc = 3

setScale(8)
monitor.setTextColor(colors.yellow)

while true do
    monitor.setCursorPos(1, 1)
    local date_table = os.date("!*t")
    monitor.write(string.format("%02d:%02d:%02d", (date_table.hour + local_utc) % 24, date_table.min, date_table.sec))
    sleep(1)
end
