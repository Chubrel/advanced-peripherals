local chat = peripheral.find('chatBox')

poem = [[
They come in waves,
my feelings for you.
And not pretty whitecaps
dancing at my feet.
But when I least expect it.
When life seems to be
a quiet stream of continuity.
They come to disrupt.
So forceful they pull me under,
so that I am drowning and once again,
can't catch my breath.
]]

sleep(1)
for s in poem:gmatch("[^\n]+") do
    chat.sendMessage(s, "Poet")
    sleep(0.5 + 0.05 * #s)
end
