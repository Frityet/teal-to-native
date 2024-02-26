local ansi<const> = require("cyan.ansi")
local colorstring<const> = require("cyan.colorstring")
local fs<const> = require("cyan.fs")
local log<const> = require("cyan.log")
local utilities<const> = require("cyan.util")
local keys<const> = utilities.tab.keys

local root<const> = fs.cwd()
local is_windows<const> = fs.path.separator == "\\"
local build_dir<const> = root.."build-aot/"
local ok, err = build_dir:mkdir()
if err ~= "File exists" then assert(ok, err) end

local function mkdir(path: string): boolean, string
    return fs.path.new(path):mkdir()
end

--local mod <const> = path:tostring():gsub("%.tl$", ""):gsub("/", "."):gsub("%.init$", "")
local function module_name(path: fs.Path): string
    return (path:tostring():gsub("%.lua$", ""):gsub("/", "."):gsub("%.init$", ""))
end

local cflags<const>: {string} = {
    "-std=c99",
    "-w",
    "-Os",
    "-I"..(root.."extern/lua-aot/src"):to_real_path(),
}

local ldflags<const>: {string} = {
    "-L"..(root.."extern/lua-aot/src"):to_real_path(),
    "-llua",
    "-fPIC",
    "-flto",
}

local c_compiler, linker: string, string do
    local prog, err = io.popen((is_windows and ".\\luarocks.bat" or "./luarocks").." config variables.CC")
    if not prog then
        log.warn("Failed to get the C compiler!\n\tReason: ", err)
    end

    c_compiler = prog:read("*l")

    prog, err = io.popen((is_windows and ".\\luarocks.bat" or "./luarocks").." config variables.LD")
    if not prog then
        log.warn("Failed to get the linker!\n\tReason: ", err)
    end

    linker = prog:read("*l")
end

local info = log.create_logger(
   io.stdout,
   "normal",
   colorstring.highlight({ansi.color.bright.cyan}, "LuaAOT"),
   colorstring.highlight({ansi.color.bright.cyan}, "...")
)

local function execute(cmd: string | {string})
    local cmd_str = (cmd is {string}) and table.concat(cmd, " ") or cmd as string
    -- shell(cmd_str)
    local ok, err = os.execute(cmd_str)
    if not ok then
        error("Failed to execute "..cmd_str.."!\n\tReason: "..err)
    end
end

local function hash(s: string): integer
    local h = 0
    for i = 1, #s do
        h = (h * 31) + s:byte(i)
    end
    return h
end

local luaot_path<const> = root.."extern/lua-aot/src/"..(is_windows and "luaot.exe" or "luaot")
local function compile_lua(script: fs.Path, out_dir: fs.Path, is_main: boolean): string, string | nil
    local out = out_dir..(string.format("%x", hash(tostring(script)))..'.c')
    info("Compiling ", script, " to ", out)
    local args: {string} = {
        luaot_path:to_real_path(), script:to_real_path(),
        "-m", module_name(script),
        "-o", out:to_real_path(),
    }

    if is_main then
        table.insert(args, "-e")
        table.insert(args, "-i")
        table.insert(args, is_windows and "windows" or "posix")
    end

    local cmd = table.concat(args, ' ')
    execute(cmd)
    return out:to_real_path()
end

assert(fs.chdir("build"))
local c_module_paths: {string} = {}
for path in fs.scan_dir("./", { "**/*.lua" }) do
    local c_path, err = compile_lua(path, build_dir, path:match("**/main.lua"))
    if not c_path then
        log.warn("Failed to compile ", path, "!\n\tReason: ", err)
        return
    else
        table.insert(c_module_paths, c_path)
    end
end
assert(fs.chdir(root))

for path in fs.scan_dir("./src", {"**/*.c"}) do
    table.insert(c_module_paths, (root.."src"..path):to_real_path())
end

assert(fs.chdir(build_dir))
mkdir "obj"
local obj_paths: {string} = {}
for _, c_path in ipairs(c_module_paths) do
    local obj_path = fs.path.new("obj")..(c_path:match("([^/\\]+)$")..".o")
    info("Compiling ", c_path, " to ", obj_path)
    local cmd = table.concat({
        c_compiler, "-c",
        "-o", obj_path:to_real_path(),
        c_path,
        table.unpack(cflags)
    }, " ")
    execute(cmd)
    table.insert(obj_paths, obj_path:to_real_path())
end

mkdir "bin"
local bin_path = fs.path.new("bin")..(is_windows and "main.exe" or "main")
info("Linking the object files to ", bin_path)
local linkerargs: {string} = {linker, "-o", bin_path:to_real_path()}
for _, obj_path in ipairs(obj_paths) do
    table.insert(linkerargs, obj_path)
end

for _, ldflag in ipairs(ldflags) do
    table.insert(linkerargs, ldflag)
end

local cmd = table.concat(linkerargs, " ")
execute(cmd)

assert(fs.chdir(root))
