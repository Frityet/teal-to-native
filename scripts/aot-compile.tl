local ansi<const> = require("cyan.ansi")
local colorstring<const> = require("cyan.colorstring")
local fs<const> = require("cyan.fs")
local config<const> = require("cyan.config")
local log<const> = require("cyan.log")
local utilities<const> = require("cyan.util")
local keys<const> = utilities.tab.keys

local root<const> = fs.cwd()
local is_windows<const> = fs.path.separator == "\\"
local build_dir<const> = root.."build/"
local lua_mod_dir<const> = root.."lua_modules/share/lua/5.4/"
local ok, err = build_dir:mkdir()
if err ~= "File exists" then assert(ok, err) end

local function mkdir(path: string): boolean, string
    return fs.path.new(path):mkdir()
end

local cfgs = config.load() as {string:{string | nil}}
local additional_cflags<const> = cfgs.cflags or {}
local additional_ldflags<const> = cfgs.ldflags or {}
local verbose<const> = not not cfgs.aot_verbose

local cflags<const>: {string} = {
    "-I"..(root.."extern/lua-aot/src"):to_real_path(),
    table.unpack(additional_cflags),
}

local ldflags<const>: {string} = {
    "-L"..(root.."extern/lua-aot/src"):to_real_path(), "-llua",
    table.unpack(additional_ldflags),
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

local shell = log.create_logger(
   io.stdout,
   "normal",
   colorstring.highlight({ansi.color.bright.magenta}, "$"),
   colorstring.highlight({ansi.color.bright.magenta}, "...")
)

local function execute(cmd: string | {string})
    local cmd_str = (cmd is {string}) and table.concat(cmd, " ") or cmd as string
    if verbose then shell(cmd_str) end
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

local record CModuleDefinition
    symbol: string
    path:   fs.Path
end

local luaot_path<const> = root.."extern/lua-aot/src/"..(is_windows and "luaot.exe" or "luaot")
local function compile_lua(script: fs.Path, module_name: string, to: fs.Path, is_main: boolean)
    info("Transpiling ", script, " to ", to:relative_to(root))
    local args: {string} = {
        luaot_path:to_real_path(), script:to_real_path(),
        "-m", module_name,
        "-o", to:to_real_path(),
    }

    if is_main then
        table.insert(args, "-e")
        table.insert(args, "-i")
        table.insert(args, is_windows and "windows" or "posix")
    end

    local cmd = table.concat(args, ' ')
    execute(cmd)
end

local function compile_c(c_path: fs.Path, module_list: {string : CModuleDefinition}, to: fs.Path)
    info("Compiling ", c_path:relative_to(root), " to ", to:relative_to(root))

    --get the filename, if it starts with tl_ then it's a luaot module and we should enable `-w`
    local is_tl_mod = not not c_path:tostring():match("tl_")

    local modlist = "-D'LUAOT_INTERNAL_SEARCHER_MODULES="
    local first = true
    for mod, sym in pairs(module_list) do
        if not sym.symbol:match("luaopen_") then sym.symbol = "luaopen_"..sym.symbol end

        modlist = modlist..string.format('%s{ "%s", "%s" }', (first and "" or ", "), mod, sym.symbol)
        first = false
    end
    modlist = modlist.."'"

    if is_tl_mod then
        cflags[#cflags+1] = "-w"
    end

    local cmd = table.concat({
        c_compiler, "-c",
        modlist,
        "-o", to:to_real_path(),
        c_path:to_real_path(),
        table.unpack(cflags)
    }, " ")
    execute(cmd)
end

local function link_objects(obj_paths: {fs.Path}, to: fs.Path)
    info("Linking the object files to ", to:relative_to(root))
    local linkerargs: {string} = {linker, "-o", to:to_real_path()}
    for _, obj_path in ipairs(obj_paths) do
        table.insert(linkerargs, obj_path:to_real_path())
    end

    for _, ldflag in ipairs(ldflags) do
        table.insert(linkerargs, ldflag)
    end

    local cmd = table.concat(linkerargs, " ")
    execute(cmd)
end

local function require_path(path: fs.Path): string
    return (path:tostring():gsub("%.lua$", ""):gsub("/", "."):gsub("%.init$", ""))
end

assert(fs.chdir(build_dir))
local c_modules: {string : CModuleDefinition} = {}
for path in fs.scan_dir("./", { "**/*.lua" }) do
    local mod = require_path(path)
    local symname = string.format("tl_%x", hash(path:to_real_path()))
    local c_out = fs.path.new("tl_"..mod..".c")
    compile_lua(path, symname, c_out, mod == "main")

    c_modules[mod] = {
        symbol = symname,
        path = build_dir..c_out,
    }
end
assert(fs.chdir(root))

--any .c files also are compiled
for path in fs.scan_dir("./src", {"**/*.c"}) do
    local mname = (path:tostring():gsub("%.c$", ""):gsub("/", "."))
    if mname:find("%-") then error("C module names cannot contain hyphens! Module at: "..path:tostring()) end
    local symname = string.format("luaopen_%s", mname:gsub("%.", "_"))
    c_modules[mname] = {
        symbol = symname,
        path = root.."src"..path,
    }
end

assert(fs.chdir(build_dir))
local objdir = fs.path.new("obj")
objdir:mkdir()
local obj_paths: {fs.Path} = {}
for mod, def in pairs(c_modules) do
    local obj_path = objdir..(mod..".o")
    compile_c(def.path, c_modules, obj_path)
    table.insert(obj_paths, obj_path)
end

mkdir "bin"
local bin_path = fs.path.new("bin")..(is_windows and "main.exe" or "main")
link_objects(obj_paths, bin_path)

assert(fs.chdir(root))
