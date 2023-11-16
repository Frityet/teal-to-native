local mod = require("module")

local wrap = coroutine.wrap as function<TArgs, TRet>(func: function(TArgs): TRet): function(): TRet

local function range(n1: integer, n2: integer | nil): function(): integer
    return wrap(function(): integer
        for i = n1, n2 do coroutine.yield(i) end
    end)
end

for f in mod.recurse_dir '.' do
    print(f)
end

-- for i in range(1, 100) do print(i) end
