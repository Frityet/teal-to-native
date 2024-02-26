local mod = require("module")
local cmodule = require("cmodule")
local nestedmod = require("nested.module")

cmodule.hello "World"
for i in mod.range(1, 5) do print(i) end

nestedmod.say("hi")
