@echo off
setlocal

set CONFIG_54=---@diagnostic disable: lowercase-global^^^
--DONT EDIT THIS!!^^^
^^^
lua_interpreter = 'lua.exe'^^^
variables = {^^^
    LUA_DIR = '.\extern\lua-aot\build',^^^
    LUA_INCDIR = '.\extern\lua-aot\build\include',^^^
    LUA_BINDIR = '.\extern\lua-aot\build\bin',^^^
    LUA_LIBDIR = '.\extern\lua-aot\build\lib',^^^
    LIBFLAG = '', --statically linking^^^
    LIB_EXTENSION = 'a'^^^
}

set LR_DEFAULT_VER=return '5.4'

:: Assuming GNU make is available in your PATH
cd extern\lua-aot
make PLAT=guess
cd ..\..

:: base files
luarocks init

:: for using extern/lua-aot
echo %CONFIG_54% > .luarocks\config-5.4.lua
echo %LR_DEFAULT_VER% > .luarocks\default-lua-version.lua

:: Setting up .\lua.bat
luarocks init --reset

echo %CONFIG_54% > .luarocks\config-5.4.lua
echo %LR_DEFAULT_VER% > .luarocks\default-lua-version.lua

endlocal
