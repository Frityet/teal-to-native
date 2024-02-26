#!/bin/sh

set -e

LUAOT_DIR="$(pwd)/extern/lua-aot/src"

CONFIG_54="
---@diagnostic disable: lowercase-global
--DONT EDIT THIS!!

lua_interpreter = 'lua'
variables = {
    LUA_DIR     = '$LUAOT_DIR',
    LUA_INCDIR  = '$LUAOT_DIR',
    LUA_BINDIR  = '$LUAOT_DIR',
    LUA_LIBDIR  = '$LUAOT_DIR',
}
"
LR_DEFAULT_VER="return '5.4'"

make -C extern/lua-aot guess

# base files
luarocks init

# for using extern/lua-aot
echo "$CONFIG_54"       > .luarocks/config-5.4.lua
echo "$LR_DEFAULT_VER"  > .luarocks/default-lua-version.lua

# Setting up ./lua
luarocks init --reset

echo "$CONFIG_54" > .luarocks/config-5.4.lua
echo "$LR_DEFAULT_VER" > .luarocks/default-lua-version.lua
