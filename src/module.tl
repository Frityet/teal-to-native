local lfs = require("lfs")

local record export end

local wrap = coroutine.wrap as function<TArgs, TRet>(func: function(TArgs): TRet | nil): function(): TRet

function export.recurse_dir(dir: string): function(): string
    return wrap(function(): string
        local function impl(dir: string): string
            for entry in lfs.dir(dir) do
                if entry ~= "." and entry ~= ".." then
                    local path = dir.."/"..entry
                    local attr = lfs.attributes(path)
                    if attr.mode == "directory" then
                        impl(path)
                    else
                        coroutine.yield(path)
                    end
                end
            end
        end

        impl(dir)
    end)
end

return export
