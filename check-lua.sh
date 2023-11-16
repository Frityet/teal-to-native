#!/bin/sh

set -e

LUA=$1
LUAOT_LUA=$2

LUA_VER="$($LUA -v)"
LUAOT_VER="$($LUAOT_LUA -v)"

if [ "$LUA_VER" != "$LUAOT_VER" ]; then
    >&2 printf "\x1b[33mWarning: %s provided by host (%s) does not match LuaOT %s\n\x1b[0m\x1b[31mTHIS MAY CAUSE CRASHING\x1b[0m\n" "$LUA_VER" "$LUA" "$LUAOT_VER"
fi
