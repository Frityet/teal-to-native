local mod = require("module")
local cmodule = require("cmodule")

cmodule.hello "World"
for i in mod.range(1, 5) do print(i) end
