@echo off
setlocal

set "CONFIG_54=---@diagnostic disable: lowercase-global^
--DONT EDIT THIS!!^
^
lua_interpreter = 'lua.exe'^
variables = {^
    LUA_BINDIR = '.\extern\lua-aot\src',^
    LUA_DIR = '.\extern\lua-aot\',^
    LUA_INCDIR = '.\extern\lua-aot\src',^
    LUA_LIBDIR = '.\extern\lua-aot\src'^
}"

set "LR_DEFAULT_VER=return '5.4'"

luarocks init

echo %CONFIG_54% > .luarocks\config-5.4.lua
echo %LR_DEFAULT_VER% > .luarocks\default-lua-version.lua

make -C extern\lua-aot mingw

endlocal
