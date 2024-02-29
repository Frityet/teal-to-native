local mod = require("module")
local cmodule = require("cmodule")
local nestedmod = require("nested.module")
local pretty = require("pretty")
cmodule.hello "World"
for i in mod.range(1, 5) do print(i) end
nestedmod.say("hi")

pretty {
    a = 1,
    b = 2,
    c = {
        d = 3,
        e = 4,
        f = {
            g = 5,
            h = 6
        }
    }
}
