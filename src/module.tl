local record export end

local wrap = coroutine.wrap as function<TArgs, TRet>(func: function(TArgs): TRet | nil): function(): TRet

function export.range(n1: integer, n2: integer): function(): integer
    return wrap(function(): integer
        for i = n1, n2 do coroutine.yield(i) end
    end)
end

return export
