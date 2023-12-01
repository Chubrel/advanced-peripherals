monitor = peripheral.find('monitor')
rs = peripheral.find('rsBridge')

DEFAULT_TEXT_COLOR = colors.white

monitor.clear()
monitor.setTextColor(DEFAULT_TEXT_COLOR)
monitor.setBackgroundColor(default_bg_color)
monitor.setTextScale(0.75)

