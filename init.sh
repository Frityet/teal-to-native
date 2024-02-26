#!/bin/sh

set -e

CONFIG_54="
---@diagnostic disable: lowercase-global
--DONT EDIT THIS!!

lua_interpreter = 'lua'
variables = {
    LUA_DIR = './extern/lua-aot/build',
    LUA_INCDIR = './extern/lua-aot/build/include',
    LUA_BINDIR = './extern/lua-aot/build/bin',
    LUA_LIBDIR = './extern/lua-aot/build/lib',
    LIBFLAG = '', --statically linking
    LIB_EXTENSION = 'a'
}
"
LR_DEFAULT_VER="return '5.4'"

# base files
luarocks init

# for using extern/lua-aot
echo "$CONFIG_54" > .luarocks/config-5.4.lua
echo "$LR_DEFAULT_VER" > .luarocks/default-lua-version.lua

# Setting up ./lua
luarocks init --reset

echo "$CONFIG_54" > .luarocks/config-5.4.lua
echo "$LR_DEFAULT_VER" > .luarocks/default-lua-version.lua

make -C extern/lua-aot PLAT=guess install INSTALL_TOP=../build
