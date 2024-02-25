local record export end

function export.range(n1: integer, n2: integer): function(): integer
    return coroutine.wrap(function(): integer
        for i = n1, n2 do coroutine.yield(i) end
    end)
end

return export
